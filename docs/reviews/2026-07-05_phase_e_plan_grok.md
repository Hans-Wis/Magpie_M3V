# Phase-E — Grok architecture confirmation (2026-07-05)

E1 vdiv = do now (localized, Spike-clear, combinational OK like F4). E2 segment = DEFER (full vmem-FSM rewrite, high green-wash risk, low TFLM/Coral payoff). ADR-0058.

# Phase-E Architecture Review: E1 `vdiv` / E2 Segment Memory

**Scope:** Zve32x VLEN128, Spike lockstep authority, functional parity before timing. Phase-A–D complete; E1 is vexu-local; E2 is vmem-FSM invasive.

---

## Q1 — E1: `vdivu` / `vdiv` / `vremu` / `vrem`

### Exact per-element semantics (RISC-V V §11.3, inherits M-extension rules)

**Operand order (fixed):**

| Instr | Per active element `i` |
|---|---|
| `vdivu{.vv\|.vx}` | `vd[i] = vs2[i] ÷ᵤ vs1[i]` |
| `vdiv{.vv\|.vx}` | `vd[i] = vs2[i] ÷ₛ vs1[i]` |
| `vremu{.vv\|.vx}` | `vd[i] = vs2[i] modᵤ vs1[i]` |
| `vrem{.vv\|.vx}` | `vd[i] = vs2[i] modₛ vs1[i]` |

`vs2` = dividend, `vs1` = divisor (scalar `rs1` for `.vx`). Spike is ground truth; golden table below.

**Special cases (per element, adopt M-extension exactly):**

| Case | `vdivu` | `vdiv` | `vremu` | `vrem` |
|---|---|---|---|---|
| `vs1[i] == 0` | `vd[i] = all 1s` | `vd[i] = -1` | `vd[i] = vs2[i]` | `vd[i] = vs2[i]` |
| Signed overflow: `vs2[i] = −2^(SEW−1)`, `vs1[i] = −1` | N/A | `vd[i] = vs2[i]` | N/A | `vd[i] = 0` |
| Normal | trunc toward 0 | trunc toward 0 | `vs2 − quot·vs1` | `vs2 − quot·vs1` |

Unsigned div-by-zero quotient = `UINT_MAX` (all 1s). Signed div-by-zero quotient = `−1`. Remainder on div-by-zero always returns **dividend** `vs2[i]` for both signed/unsigned — not 0.

No other hidden cases: `vs1=1`, `vs2=0`, sign combos follow integer divide.

### Encoding (`f6 = 1000xx`, OPMVV/OPMVX)

| `funct6` | Mnemonic |
|---|---|
| `100000` | `vdivu` |
| `100001` | `vdiv` |
| `100010` | `vremu` |
| `100011` | `vrem` |

- **OPMVV** (`funct3=010`): `.vv` — `vd, vs2, vs1`
- **OPMVX** (`funct3=110`): `.vx` — `vd, vs2, rs1`

Same shape as other OPIVV/OPIVX integer ops. No widening (`vta/vma` tail-agnostic applies normally). `vill`/illegal `vtype` → trap as today.

### Masking / `vstart` / tail

| Policy | Behavior |
|---|---|
| **`vstart`** | Elements `i < vstart`: `vd[i]` **undisturbed** (no write, no side effect) |
| **`vl`** | Active set = `vstart ≤ i < vl` |
| **`vm=1`** | Unmasked; all active elements execute |
| **`vm=0`** | `v0[i]` masks; inactive elements preserve `vd[i]` |
| **Tail** (`i ≥ vl`) | Undisturbed (default `vta=0`) or agnostic per `vtype` — same as B1/B2 |
| **`vd=v0` with `vm=0`** | **Illegal** — add to `q_illegal` (same guard as B1/B2) |

Divide is **not** a mask-producing op; no `v0` destination path.

### `beats_op` / EMUL (`m1`–`m8`) applicability

- **In-scope for E1:** all arithmetic EMUL. `vdiv*` is narrow OPIVV/OPIVX at SEW — no widening, no cross-lane reduction.
- Operand/dest register groups follow standard `vd.vs2.vs1` EMUL alignment (same rules as `vadd.vv`).
- **`beats_op(m2/m4)`:** stripe elements across sub-registers exactly as existing vexu beat scheduler does for B1/B2 — no new beat contract. Each beat = one element slice at current EMUL.
- **Out-of-scope reminder:** `m2+` **memory** ops remain cut; E1 does not touch vmem.

### Implementation posture — combinational divide OK

**Yes.** Single-cycle (or fixed-latency) combinational per-element divider/multiplexed across lanes is acceptable for **functional lockstep**, documented as timing deviation — same pattern as ADR-0050 F4 scalar-F combinational path:

> *"E1-div: per-element combinational integer div/rem; product target = pipelined/iterative; lockstep contract = Spike bit-exact per element."*

Micro-arch notes:
- SEW=8/16/32/64 each needs width-matched div/rem or unified 32b core with sign/zero ext.
- Special-case detect (`vs1==0`, `MIN/-1`) should be **compare + mux** before/alongside divider — do not rely on divider hardware exceptions.
- `.vx`: broadcast `rs1` once per beat; same special-case logic.

**Verification:** directed grid over `(SEW, LMUL, vm, vstart, vl)` × corner operands `(0, ±1, MIN, MAX, MIN/-1, divisor=0)` × `.vv`/`.vx`; then `vrand` under `zve32x_zvl128b`.

---

## Q2 — E2: Segment loads/stores (`vlseg` / `vsseg`)

### Memory layout (AoS interleave)

Segment ops treat memory as **structure array**. For `vlseg<nf>e<eew>.v`:

```
addr(rs1 + (i * nf + f) * (EEW/8))  →  vd[f][i]
```

```
mem: [e0.f0, e0.f1, …, e0.f(nf−1), e1.f0, e1.f1, …]
      |←—— nf × EEW ——→|
```

Unit stride in **composite element** space; stride between vector elements = `nf × EEW/8` bytes. This is **not** SoA; it is field-interleaved AoS — the common RGB/RGBA pattern.

`vsseg<nf>e<eew>.v` is symmetric: read `vs3[f][i]` (register group `{vs3..vs3+nf−1}`) and store with same interleave.

### How it maps to today's unit-stride vmem FSM

**Poor fit.** Existing FSM (Phase-A/D) is built around:

1. One **destination register** (or one logical field) per element
2. Address += `EEW/8` per element
3. One beat → one reg slice → one mem word

Segment requires:

| Dimension | Unit-stride today | Segment E2 |
|---|---|---|
| Registers touched | 1 (`vd`) | **`nf` registers** (`vd..vd+nf−1`) |
| Mem ops per vector element | 1 | **`nf` contiguous loads/stores** |
| Address step per element | `EEW/8` | **`nf × EEW/8`** |
| EMUL | `LMUL` | **effective `EMUL × nf`** (register group grows) |
| `vstart`/`vl` | 1D index | Same logical `i`, but **field sub-loop** `f ∈ [0,nf)` |
| Store data source | `vs3` single | **`vs3` group** |

FSM needs a new outer/inner nest: **element loop × field loop**, multi-reg write enable, and group-aware `vstart` (element `i` partially loaded if interrupted mid-segment is spec-visible — all fields for an element should commit together per spec intent; practical impl must not reorder fields within an element).

### EMUL / `nf` constraints

- `nf ∈ {1,…,8}` encoded as `nf-1` in instruction (segment load/store family).
- **Register group:** `nf × LMUL` effective EMUL for destination/source group; must satisfy `nf × LMUL ≤ 8` (and no `vill` from `vsetvl`).
- Example: `e32`, `LMUL=4`, `nf=4` → EMUL=16 → **illegal** (`vill`).
- Zve32x VLEN128: `vlmax` shrinks as EMUL grows; segment burns register file budget fast.
- **EEW ≠ SEW** (e.g. `vlseg3e8.v` with `SEW=32`) adds **width conversion** on load — another path not in unit-stride e32-only fast path.

### What's hard (ranked)

1. **FSM rewrite** — dual-loop, multi-reg scoreboard, not a decode shim
2. **EMUL/register-group decode** — `vd`, `vd+1`, … span beats; conflicts with existing single-`vd` writeback
3. **Masking + `vstart`** — mask applies per element across all `nf` fields atomically; mid-segment restart is painful
4. **AXI/TCM alignment** — `nf × EEW` multi-beat bursts vs current single-word pattern; potential misalign at `rs1`
5. **EEW ≠ SEW** segment — narrowing/widening on load (Phase-B interaction)
6. **Lockstep** — Spike mem image must match interleave; firmware `mno-relax` already required; segment TBs need structured golden buffers

### Recommendation: **defer / scope-cut E2 for Phase-E**

| | E1 `vdiv` | E2 segment |
|---|---|---|
| Unit | vexu only | vmem FSM + reg-group + possibly DMA alignment |
| Coral/TFLM need | Moderate (general integer) | **Low** — TFLM kernels use unit-stride + strided (Phase-D); AoS rare |
| Risk | Low (localized, Spike-clear) | High (FSM surgery, easy green-wash) |
| Phase-E fit | **Do now** | **Defer → Phase-E′ or P1** |

**Proposed Phase-E slice:**
- **E1:** `vdivu/vdiv/vremu/vrem` — `.vv`/`.vx`, all EMUL, lockstep grid + vrand
- **E2:** Record as ADR scope-cut with escape hatch: *"implement only `nf=2, eew=sew, LMUL=1, vm=1, vstart=0` stub"* if a specific kernel appears — otherwise ship after unit-stride FSM gains generic multi-field support (or alongside indexed/gather in E later items)

**E2 prerequisite (if ever un-deferred):** vmem spec amendment defining segment as **element-major, field-minor** nested loop; register-group write contract; Spike segment litmus per `(nf, LMUL, EEW, SEW)` corner.

---

## Summary verdict

| Item | Decision |
|---|---|
| **E1 semantics** | M-extension per element; operand order `vs2` div/mod `vs1`; table above is Spike contract |
| **E1 encoding** | OPMVV/OPMVX `1000xx`; standard mask/vstart/tail |
| **E1 timing** | Combinational per-element OK; document like F4 |
| **E2** | **Defer** — AoS interleave incompatible with single-field unit-stride FSM; high cost, low Coral/TFLM payoff |
| **Phase-E MVP** | E1 only → gate → commit; E2 → ADR scope-cut + revisit with FSM refactor |
