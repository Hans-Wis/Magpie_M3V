# Magpie_M1 — Phase 0 Benchmark Baseline (M1A evaluation, measured)

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · design_id = `cpu_m1`
Environment: cycle-exact Verilator sim (`tb_bench`, 256KB unified **1-cycle** memory = ideal-TCM
timing, same model as the lockstep farm TB), rdcycle/rdinstret CSRs. RTL @ this repo SHA.
CoreMark: EEMBC coremark @ `1f483d5` (cloned, benchmark harness only — not shipped IP).
Build: riscv64-unknown-elf-gcc 13.2.0, `-O2 -march=rv32imc_zicsr_zifencei -mabi=ilp32 -nostdlib`.

## 1. CoreMark (the headline)

| metric | value |
|---|---|
| Iterations / cycles | 10 / 4,043,648 |
| **CoreMark/MHz** | **2.47** |
| instret / **CPI** | 3,133,381 / **1.29** (IPC 0.775) |
| Absolute CoreMark @699 MHz (DC-trial Fmax) | **≈1729** |
| Cortex-M55 reference | 4.2 CoreMark/MHz; @~400 MHz (28nm typical) ≈ **1680** |

**Validation honesty:** all CRCs match the known-good table (seedcrc 0xe9f5, crclist 0xe714,
crcmatrix 0x1fd7, crcstate 0x8e3a; performance-run seeds 0/0/0x66; no `[0]ERROR` lines). The single
`Errors detected` line is the EEMBC **run-length rule** (`time < 10 secs` → error++), which exists for
physical-board timer resolution; in cycle-exact simulation the tick source is exact, so the rule is
N/A — documented, not silenced. This is an **engineering number** (sim, ideal 1-cycle memory, DC-trial
frequency), not an EEMBC-reportable score.

**Read:** per-MHz M1 trails M55 1.7× (2.47 vs 4.2 — single-issue vs Armv8.1-M). But at 28HPC+ M1's
frequency headroom (699 vs ~400 MHz) puts **absolute CoreMark at parity/slightly ahead (≈1729 vs
≈1680)** before any M1A work.

## 2. Roofline microkernels (`roofline.c`)

| kernel | measured | derived |
|---|---|---|
| LOADSTREAM (8× unrolled lw) | 32768 B / 18445 cyc | **1.78 B/cycle** sustained (loop IPC = 1.0; raw lw ceiling 4 B/c → 2.8 GB/s @699 MHz) |
| MACSTREAM (int32 mul+add) | 32768 MAC / 217106 cyc | **6.63 cycles/MAC** — mul.v 2-cycle blocking dominates |
| GEMV_I8 (scalar int8 dot) | 4096 MAC / 45067 cyc | **11.0 cycles/MAC** → **0.127 GOPS @699 MHz** |

## 3. Gap quantification vs the M55 bar (now measured, no estimates)

| domain | M1 measured | M55(+U55) bar | gap |
|---|---|---|---|
| Scalar per-MHz | 2.47 | 4.2 | 1.7× behind |
| Scalar absolute @28nm | ≈1729 | ≈1680 | **parity/win already** |
| int8 MAC throughput | 0.127 GOPS | Helium ~3.2 GOPS @400 MHz | 25× behind |
| ML with NPU | — | +U55-128 ≈ 102 GOPS | ~800× behind |

## 4. What this buys the M1A plan (docs/reports/m1a_performance_evaluation.md)

- **1-cycle MUL** directly attacks the 6.63 c/MAC (→ ~3 c/MAC, ~2.2×) and lifts CoreMark matrix part.
- **RVV Zve32x VLEN=128 dual-beat (8 int8 MAC/c)** @699 MHz = **5.6 GOPS > M55 Helium's 3.2** → DSP win.
- **TC-GEMV**: to clearly beat M55+U55-128 (~102 GOPS) needs ≥128 int8 MAC/c @699 MHz (**179 GOPS
  peak**) — which demands **128 B/cycle weight feed** (TCM banking; only on-chip-resident weights can
  sustain it; external-memory streaming caps real tokens/s — roofline honesty per evaluation §3).
- Positioning available **today**: "absolute-CoreMark parity with Cortex-M55-class @28nm at <16 mW
  (DC-trial)" — workload-named, benchmark-backed, with the sim/ideal-mem caveat stated.

Artifacts: `flow/v2_pipeline/phase_b0_benchmarks/{coremark_run.log,roofline_run.log,port_m1/,tb_bench.v,Makefile,roofline.c}`.
Reproduce: `make all && make roofline_run.log` in that directory.
