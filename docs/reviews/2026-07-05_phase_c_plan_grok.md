# Phase-C (multiply + reduction) — Grok architecture confirmation (2026-07-05)

Sub-slice order **C1→C3→C2→C4→C5**. Verbatim Grok output below (ADR-0055 Phase-C).

## 1. Recommended sub-slice order (cheapest / highest reuse first)

| Order | Slice | Rationale |
|-------|-------|-----------|
| **1** | **C1** same-width mul | Foundational `SEW×SEW→2SEW` product + low/high extract; all later slices hang off it. `vwmul` already proves the wide product path. |
| **2** | **C3** non-sum reductions | Pure control extension of existing `vredsum` FSM + already-green min/max and bitwise ops. No 3-read, no widening EMUL. Fast lockstep win, de-risks reduction corner cases early. |
| **3** | **C2** MAC | Reuses C1 product + scalar add/sub; cost is 3-read sequencing and vd-overlap read-before-write on `vmadd`/`vnmsub`. |
| **4** | **C4** widening full | Largest surface area (`vwaddu/sub`, `vwmacc*`, `vwredsum*`); `vwmul`/`vwadd.wv` shrink risk but EMUL×2 dest grouping and 2SEW WB commit are the hard part. |
| **5** | **C5** `vsmul` | Niche semantics (fixed-point `>>SEW`, `vxrm`); depends on C1 mul hardware but is the least reused and most spec-sensitive slice. |

**C1 → C3 → C2 → C4 → C5**

---

## 2. C1: funct6 / sign matrix / OPMVX / encoding

**Sign matrix** (per element; form full `2·SEW` product, then slice):

| Instr | f6 (OPMVV/VX) | vs1 | vs2 / rs1 | Extract |
|-------|---------------|-----|-----------|---------|
| `vmul` | `100101` | signed | signed | `[SEW-1:0]` (truncate) |
| `vmulh` | `100111` | signed | signed | `[2·SEW-1:SEW]` |
| `vmulhu` | `100100` | unsigned | unsigned | `[2·SEW-1:SEW]` |
| `vmulhsu` | `100110` | signed | **unsigned** | `[2·SEW-1:SEW]` |

**OPMVX rs1 subtlety** (SEW ≤ 32, XLEN=32): scalar is always `rs1[SEW-1:0]` first, then typed:
- Signed scalar ops (`vmul`, `vmulh`): sign-extend from `rs1[SEW-1]` to internal `SEW` operand.
- Unsigned scalar ops (`vmulhu`): zero-extend (low `SEW` bits only).
- `vmulhsu.vx`: vector = signed, **rs1 = unsigned** (no sign-extend on rs1).

At **SEW=32**, signed and unsigned both use full `rs1[31:0]` — no extension ambiguity.

**Encoding collisions** — safe via **funct3** disjointness on `opcode=1010111`:

| f6 | Also used as | Disambiguator |
|----|--------------|---------------|
| `100101` | `vsll` | OPIVX (`funct3=100`) vs OPMVV/VX (`010`/`110`) |
| `100111` | `vmv1r` | OPIVI (`011`) vs OPMVV (`010`) |

Decode = `{opcode, funct3, f6}` — no Phase-C hazard if existing OPIVX/OPIVI decode trees stay separate from OPMV*.

---

## 3. C2 MAC: operand roles and vd overlap

| Instr | Formula (per active element) | Multiplicand(s) | Addend |
|-------|------------------------------|-----------------|--------|
| `vmacc` | `vd ← vd + vs1×vs2` | vs1, vs2 | old **vd** |
| `vnmsac` | `vd ← vd − vs1×vs2` | vs1, vs2 | old **vd** |
| `vmadd` | `vd ← vs1×vd + vs2` | **vs1**, old **vd** | vs2 |
| `vnmsub` | `vd ← −(vs1×vd) + vs2` | **vs1**, old **vd** | vs2 |

OPMVX: scalar replaces **vs1** in all four (standard OPMVX convention).

**vd overlap — legal and required:**
- `vmacc` / `vnmsac`: **vd may equal vs1 and/or vs2** (accumulator semantics).
- `vmadd` / `vnmsub`: **vd may equal vs1** (vd is multiplicand); **vd may equal vs2** (addend read before overwrite). All accumulator-class overlaps are spec-legal — do **not** fire generic “vd overlaps vs*” illegality.

Implementation contract: **read old vd before multiply** on `vmadd`/`vnmsub`; per-element or per-group atomicity must match Spike commit order.

---

## 4. Phase-C-specific trap / illegality corners

Beyond your generic rules (tail undisturbed, `vstart≠0` → illegal on arithmetic body ops, masked body op writing **v0** → illegal):

| Corner | Applies to | Rule |
|--------|------------|------|
| **Widening EMUL** | C4 | `vd` must be `2·SEW` / `EMUL_dest = 2·EMUL_src`; wrong `vtype` → **illegal** (not silent truncate). |
| **`vwredsum*`** | C4 | Dest is **scalar** (`vd` EMUL=1, 2·SEW); source vectors at `SEW`. Same `vstart` ban as other arithmetic reductions. |
| **`vsmul`** | C5 | Fractional signed mul + `vxrm` rounding; treat **SEW=8 as illegal** unless Spike `zve32x` proves otherwise — product spec target is e16/e32. Distinct from integer `vmul` (shift/round path, saturation via `vxsat` policy per spec). |
| **Reduction `vl=0`** | C3/C4 | Identity element: `vredand`→all-1s, `vredor/xor`→0, `vredmin/max*`→`vs2[0]` only; dest = `vs2[0]` (sum path already models this). |
| **`vs2` in reductions** | C3/C4 | `vs2` is vector register but only **element 0** used — must be readable under current `vl`/LMUL rules; inactive high elements undisturbed. |
| **MAC dest overlap** | C2/C4 | Overlap is **legal** — illegal only if you reuse generic OPIVV overlap check. |
| **`vmul` at SEW=32** | C1 | Not illegal; `vmul` = low half, `vmulh*` = high half of 64-bit product. |
| **Masked MAC/mul** | C1/C2 | Masked-off elements: **vd undisturbed** (accumulator state preserved) — same tail policy as other masked body ops. |

No new `vstart` exception for reductions or MAC; widening ops inherit the same arithmetic `vstart=0` requirement as `vwmul`/`vwadd.wv`.
