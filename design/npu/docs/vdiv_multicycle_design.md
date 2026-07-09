# vexu vdiv multi-cycle — architecture design confirmation (§2)

**Goal:** remove the vexu integer-divide combinational cone — the *last* npu_top
Fmax wall after fdiv+fsqrt were made iterative (see
`docs/reports/2026-07-09_fdiv_multicycle_poc.md`). DC signoff shows
`ex_mem_vex_wdata_r` (vexu vdiv) is a co-equal 5.93 ns wall; with fexu-arith
now iterative it is the sole binding constraint (endpoint moved to `u_vexu`,
only `DW_div_*` width 8/16/32 remain).

## 1. Current structure (vexu.v, HEAD 648948e)

- `g_div8/16/32` (lines ~823-867): per-lane **combinational** `a/b`, `a%b`
  (Verilog `/` `%`), with RISC-V special cases: `bz` (÷0 → all-1s quotient /
  dividend remainder), `sov` (signed MIN/−1 → MIN quotient / 0 remainder). Op
  mux `op_vdivu/vdiv/vremu/vrem`, then `active` mask vs `vd_old`.
  `res_vdiv = vsew? res_vdiv8/16/32`.
- **LMUL=1 vdiv**: `is_grp = (grp_parts!=1)&&…` is false → **NOT in the FSM**,
  pure combinational, `q_wdata` in one cycle.
- **LMUL m2/m4/m8 vdiv**: `is_grp` true → `VM_GRP` sequences one register-part
  per cycle into `grp_stage[grp_p]`, but **each part still does the combinational
  divide**. So the cone exists per beat regardless of LMUL.
- Handshake (already present): `m_start` / `m_stall` / `m_advance` / `vm_active`
  / `vm_result_valid=vm_done_r`; `m_flush` kills wrong-path.

## 2. Proposed change — per-lane radix-2 bit-serial divider (SEW cycles)

Keep ALL the tricky bit-exact logic (special cases `bz`/`sov`, op-mux, `active`
masking) **combinational and unchanged**; only replace the deep `/`,`%` with a
registered iterative result.

- **One unsigned radix-2 restoring divider per lane, all lanes in parallel,
  SEW iterations** (8/16/32). Per cycle each lane does one shift + (SEW+1)-bit
  compare/subtract — shallow. All lanes lockstep on a shared iteration counter.
- **Signed via magnitude + fixup** (mirrors scalar `div.v`): feed the divider
  `dvd_mag = signed_op ? |as| : a`, `dsr_mag = signed_op ? |bs| : b`; it yields
  unsigned `qmag`, `rmag`. Reconstruct:
  - `udiv=qmag, urem=rmag` (unsigned);
  - `sdiv = (sign_a^sign_b) ? −qmag : qmag`, `srem = sign_a ? −rmag : rmag`
    (RISC-V round-toward-zero). This is bit-exact to Verilog `as/bs`,`as%bs`.
  - special cases `bz`/`sov` still override combinationally (unchanged).
- **Result** `res_vdiv` now comes from the **registered** `qmag/rmag` (valid when
  the divide finishes), not a combinational `/`.

## 3. FSM integration (the risky part — Grok review focus)

Two entry paths need a multi-cycle divide hold:
- **LMUL=1**: today single-cycle combinational commit. Add a divide-iteration
  hold so the op stays in EX for SEW cycles before `q_wdata` is captured.
- **VM_GRP (LMUL>1)**: each part must run SEW divide-cycles before
  `grp_stage[grp_p] <= part_res` and advancing `grp_p`.

**Option A (preferred): a shared divide-iteration counter `div_it` gating beat
advance.** A lane-parallel divider runs while `div_busy = (op_vdivr && q_valid &&
!div_done)`; the FSM part-advance (`grp_p++` in VM_GRP, or the LMUL=1 commit)
waits until `div_done` (div_it==SEW). Route `div_busy` into the pipe stall the
same way vexu already asserts `vm_active`/holds (into `vex_stall`/`m_stall`).
Reuse `m_flush` to reset the divider (wrong-path).

**Cycle budget:** LMUL=1 → SEW cycles; LMUL=k → k·SEW cycles. Rare op; fine.

## 4. Contract

- **Latency-only change; architectural values identical.** Same op / SEW / LMUL /
  vstart / mask / special-case results as the current combinational divide.
- Handshake reuses the existing `m_start`/`m_stall`/`m_advance`/`vm_active` +
  `m_flush`. No new top-level ports beyond what already exists (a `div_busy`
  term OR'd into the vexu-side stall).
- No change to non-divide vexu ops (mul/add/mac/reduction/…): the divider only
  engages for `op_vdivr`.

## 5. Verification plan (authoritative, bit-exact zero-regression)

- `gate_77_rvv_e1_vdiv` (directed vdivu/vdiv/vremu/vrem, all SEW, special cases
  bz/sov, LMUL groups) — must stay bit-exact vs Spike `rv32imf_zve32x`.
- `vrand` random corpora (multi-seed) through `phase_22` lockstep — ≥ current
  commit floors, all bit-exact.
- Full RVV regression (gate_56..81) + `phase_20` NPU + gate_60/61 F — zero
  regression (the change is vexu-divide-local).
- **DC re-read** (`synth_npu_top FAST=1`): confirm no `DW_div` cone left; the
  critical-path endpoint moves off `u_vexu` vdiv; report Fmax (target: next wall
  = fma/mat-feed, ~250–400 MHz).

## 6. Green-wash guards

- Latency changed but **result bit-exact** — lockstep is the authority (not "lint
  passes"). No test-scope reduction.
- **Deadlock guard:** the divide-busy stall must always terminate (div_it reaches
  SEW); add a `gate_force`-style check that the FSM cannot hang.
- Signed magnitude/fixup path must be exercised with negative operands + MIN/−1
  (`sov`) + ÷0 (`bz`) directed corners (green-wash: random rarely hits sov/bz).
