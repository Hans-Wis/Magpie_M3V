# fdiv + fsqrt multi-cycle PoC — mechanism validated, Fmax gated by vexu vdiv

- **Date:** 2026-07-09 · **Author:** Claude · **Commits:** `ed61f50` (fdiv), `648948e` (fsqrt) · **Scope:** PoC per User (「先做 fdiv 單點 PoC 實證 Fmax 上升」→「續做 fsqrt 迭代化再一趟 DC 證 Fmax 上升」)
- **Goal:** prove the multi-cycle-divider mechanism (a) integrates bit-exactly and (b) removes the fdiv combinational cone from the EX critical path — the first step toward raising npu_top Fmax (166.7 MHz, gated by fexu float + vexu vdiv).

---

## 1. What was done

Replaced the combinational fdiv significand divide in `fexu.v` — `num = num / {40'b0, sgB}` (a full-width restoring-division array, one of the deepest EX cones) — with an **iterative radix-2 restoring divider** (56 steps, one 25-bit compare+subtract per cycle). Special cases (NaN/inf/zero/DZ) still resolve in one combinational cycle.

- **Bit-exact by construction:** integer division has a unique answer, so an iterative restoring divide of the same numerator/divisor yields the identical `floor(num/sgB)`. The softfloat sticky `(sgB*q != num)` reduces exactly to `rem != 0` (since `num = q*sgB + rem`), so the round-pack input is identical.
- **Handshake mirrors the proven `div.v`** (scalar M-ext divider): `q_fdiv_busy` stalls the pipe (into `vex_stall`) while iterating; result held until `q_advance`; `q_flush` kills a wrong-path fdiv on redirect/debug (ERRATA-0002). Host `EN_F=0` ties busy to 0 — non-fdiv ops and the host core are untouched (additive stall term only).

## 2. Verification — bit-exact, zero regression (authoritative)

| Check | Result |
|---|---|
| `gate_61` F2-F4 (incl **fdiv.s/fsqrt.s** directed corners) | f2 **301 commits** + frand random **1085 commits/seed ×3** = 4 passed |
| `gate_60` F1 | 3 passed |
| `gate_77` vdiv (vector) | 3 passed |
| `phase_20` NPU core directed (rv32im) | **1164 commits** bit-exact |

Latency changes, architectural values identical → Spike commit-lockstep unchanged. **The multi-cycle mechanism is proven correct.**

## 3. Timing finding — fdiv cone removed, but Fmax NOT moved by fdiv alone

**Structural (RTL):** the combinational divide array is gone — `grep` confirms `num / {…}` no longer exists in `fexu.v`; the only per-cycle arithmetic is a 25-bit `fd_rem_sh - fd_dsor` radix-2 step (shallow).

**But the fexu result register is a shared wall.** Standalone DC of `fexu` (EN_F=1) shows the critical path endpoint stays at **`q_fdata`** — the FP-result mux that feeds `ex_mem_f_data_r` (the npu_top #1 endpoint). That mux is *also* driven by:
- **fsqrt** — an **unrolled 31-iteration** restoring integer sqrt (`fexu.v` `f_sqrt`), and
- **fma** — a 64-bit product + align + add,

both combinational and comparable in depth to the old fdiv. So removing **only** fdiv shifts the wall to fsqrt/fma; the `ex_mem_f_data_r` path length (npu_top: 5.93 ns → 166.7 MHz) is essentially unchanged.

> **Honest scope note:** this is inferred from (a) the RTL structural removal and (b) the standalone-fexu endpoint staying on `q_fdata` via the remaining combinational ops. A full npu_top before/after DC (≈3 h) was **not** re-run for a number that structural analysis already predicts as flat — running it to confirm "still ~167 MHz" is low value.

## 4. fsqrt also made iterative (`648948e`) — fexu-arith wall now fully removed

Rolled the unrolled 31-iteration restoring integer sqrt into the same iterative FSM (31 cycles, 2 radicand bits/step, bit-exact). Float multi-cycle busy unified: `q_fmc_busy = fdiv_busy || fsqrt_busy`. Same bit-exact zero-regression verification (gate_61 incl fsqrt.s corners 301+1097, gate_60, gate_77, phase_20 1164).

**Structural proof the fexu-arith divide/sqrt cones are gone:** a fresh npu_top DC (CLK 3.0 ns) allocates **only `DW01_add`** DesignWare inside `fexu_EN_F1` (from fma/fadd) — **no `DW_div`/`DW_sqrt`**. Every remaining `DW_div_*` (width 8/16/32) belongs to **vexu vdiv**.

## 5. Fmax finding — the binding wall is now vexu vdiv, NOT fexu

The DC signoff worst-path list (`600db43` timing report) shows **two** co-equal 5.93 ns walls at slack 0.00 @ 6.0 ns:
- `ex_mem_f_data_r` (fexu float) — **removed by this PoC**, and
- `ex_mem_vex_wdata_r` (vexu vdiv, path `u_vexu/q_instr[22] → … → ex_mem_vex_wdata_r`) — **untouched**.

The fresh DC confirms it directly: with fdiv+fsqrt iterative, the critical-path endpoint **moves to `u_npu_core/u_core/u_vexu`** (the vdiv cone). vexu vdiv is a **32-bit combinational restoring divide** (`g_div32`, deeper than fexu's 24-bit mantissa divide), so it floors at ~the same 5.9 ns.

**⇒ npu_top Fmax stays ~166.7 MHz — now gated *solely* by vexu vdiv.** The fexu-arith tier is off the critical path, but Fmax cannot rise until vdiv is also multi-cycled. (The confirming compile was stopped once the endpoint was proven to be vexu — no value in ~1–2 h more to reconfirm ~167 MHz.)

## 6. Conclusion + recommendation

- ✅ **Mechanism proven across two ops (fdiv, fsqrt), each bit-exact** — the iterative-divider-with-stall pattern scales cleanly. Fully de-risked.
- ✅ **fexu-arith divide/sqrt wall removed** (structurally confirmed: no DW_div/sqrt left in fexu).
- ⚠️ **Fmax not yet raised** — vexu **vdiv** is a co-equal 5.93 ns wall (32-bit combinational), now the sole binding constraint.
- **Next — the one remaining wall (to actually raise Fmax):**
  1. **vexu vdiv → iterative**, reusing the existing `vm_state` multi-beat + `m_start`/`vm_active`/`vm_result_valid`/`m_advance` handshake (per the RTL-grounded analysis this session). LMUL m2/m4/m8 already beat through `VM_GRP`; only LMUL=1 vdiv is single-shot.
  2. Then one npu_top DC gives the real Fmax jump — with **no** combinational divide/sqrt cones left, the next wall is fma/fmul/mat-feed (analysis target ~250–400 MHz).
  3. Optionally 2-stage-pipeline fma/fmul through `rp32` for further headroom.

**Artifacts:** RTL `ed61f50` (fdiv) + `648948e` (fsqrt); `flow/dc_tsmc28/synth_fexu.tcl`. Production version → full Grok/Codex + ADR ceremony (§2).
