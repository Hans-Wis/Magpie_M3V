# Phase-B Architecture Review — Zve32x Integer-Core Completeness

Authority: Spike `--isa=zve32x_zvl128b`. Below flags only where naive encoding/semantics diverge from Spike.

---

## 1. f6 + form legality

**B1 — all correct**

| insn | f6 | vv | vx | vi |
|------|-----|:--:|:--:|:--:|
| vand/vor/vxor | 001001/001010/001011 | ✓ | ✓ | ✓ |
| vrsub | 000011 | **no** | ✓ | ✓ |
| vsll/vsrl/vsra | 100101/101000/101001 | ✓ | ✓ | ✓ |

`vrsub.vv` does not exist. `b` = `rs1` (vx) or `simm5` (vi); `r = b - a` where `a = vs2[i]`.

**B2 — correct, funct3 split matters**

| insn | f6 | funct3 | forms |
|------|-----|--------|-------|
| vnsrl/vnsra | 101100/101101 | OPIVV/VX/VI (000/100/011) | `.wv` / `.wx` / `.wi` |
| vzext/vsext | 010010 | **OPMVV only** (010) | no vx/vi |

`f6=010010` collision between `vsbc` (OPIVV) and `vzext` (OPMVV) is legal — decode must gate on `f3`, not `f6` alone.

**vext vs1 uimm field** (not a register):

| insn | vs1[4:0] |
|------|----------|
| vzext.vf8 | 00010 |
| vsext.vf8 | 00011 |
| vzext.vf4 | 00100 |
| vsext.vf4 | 00101 |
| vzext.vf2 | 00110 |
| vsext.vf2 | 00111 |

**B3 — correct f6**

| insn | f6 | forms |
|------|-----|-------|
| vadc | 010000 | vvm/vxm/vim only |
| vmadc | 010001 | vvm/vxm/vim |
| vsbc | 010010 | vvm/vxm/vim only |
| vmsbc | 010011 | vvm/vxm/vim |

**B4 — correct**: OPIVI `f6=100111`; only vi form (whole-register moves have no vv/vx).

---

## 2. Shift semantics

**Mask width**: yes — shift amount = `src[log2(SEW)-1:0]` (SHW = 3/4/5 @ SEW 8/16/32). Applies to `vs1[i]` (vv), `rs1` (vx), immediate (vi).

**vi immediate**: spec = **uimm5**, not simm5. Taking `imm[19:15][SHW-1:0]` after `sext(imm5)` is **bit-identical** to uimm5 for all SHW ≤ 5 — upper sext bits are discarded. **No corner case** where sext vs zext changes the masked amount.

**Still flag for clarity**: vi shifts should be documented as uimm5; vrsub/vand/vor/vxor vi still need **sext(imm5)** for the operand, not uimm5.

**vx**: `rs1[SHW-1:0]` (XLEN=32; Zve32x has no SEW=64).

**Narrowing shift amount (B2)**: **different width** — source is 2×SEW wide → mask is **`log2(2×SEW)` bits** (4/5/**6** @ SEW 8/16/32). At SEW=32, narrowing needs **6** bits; regular `vsrl` needs 5. **Spike-mismatch risk** if B1 SHW reused for vnsrl/vnsra.

---

## 3. vrsub

Confirmed: **vx/vi only**. `r[i] = (scalar/imm) - vs2[i]`. No vv.

---

## 4. B2 narrowing + vext roles

**vnsrl.wv / vnsra.wv**

- `vs2`: 2×SEW source elements (register group at 2×SEW view).
- `vs1[i]`: per-element shift amount (SEW-wide lane); masked to `log2(2×SEW)` bits.
- `vd[i]`: low SEW bits of `(vs2[i] >> shamt)` (logical / arithmetic).

**vnsrl.wx / .wi**: same source; scalar `rs1` or uimm5 shift for all elements.

**EMUL / overlap (Spike `require_nooverlap`)**

- Dest EMUL = src EMUL / 2 (halving). Spike enforces `vd` not overlapping `vs2`/`vs1` under group mapping.
- Proposal “≤ m1” is fine as implementation scope if only invoked when net dest EMUL = 1; at LMUL=2→1 narrowing is spec-legal — don’t blanket-illegal if Spike allows it.

**vext** (OPMVV, `vd`/`vs2` only; `vs1` = variant uimm)

- `vzext.vf2`: SEW/2 → SEW zero-extend; dest EMUL = 2 × src EMUL.
- `vf4`: SEW/4 → SEW; dest EMUL = 4 × src EMUL.
- `vf8`: SEW/8 → SEW; dest EMUL = 8 × src EMUL.

**SEW legality @ Zve32x (SEW ∈ {8,16,32})**

| insn | legal? |
|------|--------|
| vf2 @ e8/e16/e32 | ✓ (4/8/16-bit src) |
| vf4 @ e8/e16/e32 | ✓ (2/4/8-bit src) |
| vf8 @ e8/e16/e32 | ✓ (1/2/4-bit src) |

No “vf4 illegal at e8”. **vf8 is in Zve32x** (not stripped). Illegality is via **EMUL>8** or **vill**, not SEW alone at e8.

**4b confirmed**: vnsrl/vnsra = OPI*; vzext/vsext = OPMVV only.

---

## 5. B3 carry/borrow — highest semantic risk

**vm bit meaning (inverted from body-mask intuition)**

| insn | vm=0 (“.vvm” suffix in asm) | vm=1 |
|------|----------------------------|------|
| **vadc** | **legal**: `vd[i] = vs2[i] + vs1[i] + v0.LSUM[i]` | **reserved → illegal** |
| **vsbc** | **legal**: `vd[i] = vs2[i] - vs1[i] - v0.LSUM[i]` | **reserved → illegal** |
| **vmadc** | **legal**: carry-out of `vs2 + vs1 + v0.LSUM` → `vd.LSUM[i]` | **legal**: carry-out of `vs2 + vs1` (no carry-in) |
| **vmsbc** | **legal**: borrow-out with v0 borrow-in | **legal**: borrow-out, no borrow-in |

`v0.LSUM[i]` = mask bit as **scalar carry/borrow in** (0/1), **not** body predication.

**All elements always computed** — no mask-off undisturbed behavior; inactive-body-mask rules do not apply.

**Illegality Spike checks (must implement)**

- `vadc`/`vsbc` with **vm=1** → illegal.
- **vd overlap**: `vd == vs1` or `vd == vs2` → illegal (vadc/vsbc/vmadc/vmsbc).
- **vmadc/vmsbc with vm=0**: **`vd == v0` illegal** (v0 is carry-in).
- **vadc/vsbc with vm=0**: **`vd == v0` also illegal** in Spike (v0 simultaneously carry-in and dest).
- vmadc/vmsbc with **vm=1**: `vd == v0` is **legal** (v0 not used as carry-in).
- `vadc`/`vsbc`/`vmadc`/`vmsbc`: **`vd` is integer dest** for adc/sbc; **mask dest** (v0 or other `v0.t` group) for m-adc/m-sbc — Spike types this strictly.

**Proposal gaps to fix**

- “vadc/vsbc use masked form” is correct but **must not** route through normal predicated execute (all lanes active).
- State explicitly: **unmasked vadc does not exist** (reserved, not “add without carry”).
- vim/vxm carry-in still from **v0.LSUM[i]** when vm=0.

---

## 6. B4 `vmv<nr>r.v`

**Encoding**: `simm5` = nr−1; legal values **0,1,3,7** → nr **1,2,4,8**; other simm5 → **illegal**.

**Behavior**

- Copies `vd..vd+nr−1` ← `vs2..vs2+nr−1` (full VLEN per reg).
- Ignores **vl**, **vtype** fields (LMUL/SEW/TA/MA) except **vill=1 → illegal**.
- **vd** and **vs2** must be **nr-aligned** (index % nr == 0).

**vstart** (Spike ≠ global “vstart≠0 illegal” policy)

- `vstart >= evl` → **noop** (no writes).
- `vstart > 0` → elements `i < vstart` in dest regs **undisturbed**; copy from element `vstart` onward.

**Conflict with existing vexu contract**: project rule “arithmetic vstart≠0 = illegal” **must not apply** to `vmv<nr>r.v` or Spike will diverge. Carve out whole-register moves.

**nr=8 @ Zve32x**: **legal** if `vd`/`vs2` 8-aligned and enough architectural regs (32 regs). Not an Zve32x omission. Independent of your m8 arithmetic ban.

---

## 7. Sub-slice order + risk

**Recommended order**

1. **B1** (bitwise/shift/vrsub) — lowest risk; extends existing OPI* mux + beats_op.
2. **B4** (vmvnr) — simple datapath; **vstart carve-out** is the only trap.
3. **B2** (vnsrl/vnsra + vext) — new EMUL/overlap + **6-bit** narrowing shamt.
4. **B3** (carry) — **last**; vm-bit polarity, illegality matrix, vd/v0 overlap.

**Spike-mismatch risk ranking**

| Rank | Slice | Why |
|------|-------|-----|
| 1 | **B3** | vm=0/1 inverted rules; vadc vm=1 reserved; v0 as carry-in not predicate; vd==v0/vs1/vs2 illegality |
| 2 | **B2** | `log2(2×SEW)` shamt; EMUL halving overlap; vext EMUL expansion |
| 3 | **B4** | vstart partial-copy vs global vstart-illegal |
| 4 | **B1** | vi-shift uimm5 naming only; logic is fine if SHW mask applied |

**Pre-RTL checklist**: extend decode with `(f6, f3)` tuple for `010010`; separate narrowing SHW from ordinary SHW; B3 illegality table as Spike gate cases before lockstep vectors.
