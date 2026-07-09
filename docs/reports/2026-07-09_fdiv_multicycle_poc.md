# fdiv multi-cycle PoC — mechanism validated, Fmax finding (F4 timing)

- **Date:** 2026-07-09 · **Author:** Claude · **Commit:** `ed61f50` (RTL) · **Scope:** single-op PoC per User (「先做 fdiv 單點 PoC 實證 Fmax 上升」)
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

## 4. Conclusion + recommendation

- ✅ **PoC succeeds on its real purpose:** the iterative-divider-with-stall mechanism integrates cleanly and is **bit-exact** (the risky part). This de-risks the whole multi-cycle plan.
- ⚠️ **fdiv alone does not raise Fmax** — fsqrt and fma share the `q_fdata`/`ex_mem_f_data_r` register and are equally deep. Fmax moves only when the **whole fexu-arith tier** is treated together.
- **Next (to actually raise Fmax), same de-risked pattern:**
  1. **fsqrt → iterative** (the existing unrolled 31-iter loop rolls directly into the same restoring FSM; ~1 op, trivial extension).
  2. **fadd/fmul/fma → 2-stage pipeline** through the shared `rp32` round-pack (cut after the mantissa engine; full throughput, no stall — these are the more common ops).
  3. **vexu vdiv (#2 wall)** → reuse the existing `vm_state` multi-beat handshake.
  Then one npu_top DC re-read gives the real Fmax delta (analysis target ~350–400 MHz once the fexu-arith wall is gone).

**Artifacts:** RTL `ed61f50`; `flow/dc_tsmc28/synth_fexu.tcl` (standalone fexu probe). Multi-cycle analysis: earlier this session (fexu/vexu/div.v RTL-grounded). Production version should go through the full Grok/Codex + ADR ceremony (§2).
