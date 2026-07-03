# ADR-0034 — Phase 2 Step 4: NPU scalar core into the npu_top socket (TCM fetch)

- Status: **ACCEPTED** (per-phase architecture confirmation, CLAUDE.md §2; User standing
  directive 2026-07-03 "繼續" on roadmap option (a)). Architect = Grok (contract + DV plan,
  2026-07-03, full answer in this ADR); integrator/approver = Claude PL.
- Date: 2026-07-03
- Relates: ADR-0031 (scope), ADR-0032 (cpu_m1 parameterization + NPU verification bar),
  ADR-0033 (writeback DMA). Coral references: `docs/reviews/2026-07-03_coral_gap_review.md`,
  de-blackbox lab `~/project/lab/CPU/Ch5_NPU` (Apache-2.0 CoralNPU, observation only).
- **Honesty note**: the usual Gemini full-context review is **not-run** this session (API key
  unavailable — stored only in the prior session scratchpad). The Coral comparison below is
  grounded in the de-blackbox lab RTL evidence + the committed gap review instead. Backfill a
  Gemini pass when the key is re-supplied; flagged, not skipped silently. **Backfill DONE 2026-07-04**: Gemini full-context review completed (docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md) — verdict: consistent, no unbacked claims.

## Context

Phase 2 Step 2 delivered the parameterized single-spine cpu_m1 (`EN_RVC/EN_BP/EN_RAS`,
host-equivalent, lockstep-verified). `npu_top` is a verified socket (AXI-Lite CSR/TCM/DECERR
decode, bidirectional DMA, level IRQ) whose `npu_busy`/`npu_done` CSR inputs are still tied 0.
Step 4 = instantiate the stripped core inside `npu_top`, fetching from the real `npu_tcm`,
and prove it with Spike rv32im lockstep. This is the Coral offload shape: host loads program →
releases core via CSR → run-to-completion → status/IRQ.

## Coral comparison (replaceability argument)

Evidence from the de-blackbox lab (`04_core_assembly_debug.sv`): Kelvin's host-facing block has
`statusReg = {30'h0, io_fault, io_halted}` and `io_cg = resetReg[1]` — host loads ITCM over the
AXI slave, releases the core by writing a control register (clock-gate/reset release), the core
runs to completion and reports `halted` (via `mpause`) + `fault`; IRQ to host.

| mechanism | Coral (Kelvin) | M3V Step 4 | delta / impact on replaceability |
|---|---|---|---|
| program load | host AXI slave → ITCM | host AXI-Lite → TCM @0x3001_xxxx (verified fabric) | none (same shape) |
| start | CSR write releases clock-gate (`io_cg=resetReg[1]`) | `CTRL.start` gates core `resetn` | reset-gating vs clock-gating: same host contract; clock gating is a recorded P1 scope-cut |
| completion | core executes `mpause` → `io_halted` → status | core stores to DONE mailbox → `done_latch` → `STATUS.npu_done` + IRQ | Kelvin uses a custom instruction; we use an MMIO store (standard rv32im, no custom opcode). Host-visible surface (CSR status + IRQ) is equivalent — SW ships its own crt0 either way |
| fault report | `io_fault` in statusReg | deferred to P0⑤ (NPU trap-to-host ERR_CAUSE) | recorded gap, not silently claimed |
| memory | ITCM 8KB / DTCM 32KB split | unified 4KB TCM this step | sizing/split = recorded P1; host window (64KB) already fits the final shape |

## Decision — contract

**1. Instantiation.** `npu_top` instantiates `cpu_m1_top` with `EN_RVC=0, EN_BP=0, EN_RAS=0,
RESET_PC=32'h0`. "FETCH_SRC=TCM" (ADR-0032 table) is realized as **integration wiring** — the
wrapper's valid/ready `ibus`/`dbus` are served by new TCM core ports — not a core RTL parameter.
The host spine is untouched (host equivalence trivially preserved; still re-verified by gates).

**2. Core-local address map** (Harvard, flat):

| region | core view | behavior |
|---|---|---|
| unified TCM | `0x0000_0000`.. (wraps modulo TCM size on the core ports) | code + data |
| DONE mailbox | `0x0001_0000` (dbus decode `addr[16]==1`) | write with `wstrb[0] & wdata[0]` sets `done_latch`; always ready; reads return 0; never SLVERR/trap |

**3. Start/stop/re-run.** `core_resetn = resetn & CTRL.start` (registered level — release is
synchronous; host must load TCM *before* setting start, guarded by gate). `npu_busy = start &
~done_latch`; `npu_done = done_latch`; `done_latch` cleared on `start` falling edge.
Re-run = start 0 → reload → start 1. Hook left for P0⑤: `CTRL.soft_reset` reserved as a
1-cycle core-reset pulse (not implemented this step; still honest `not-run`).

**4. TCM porting/arbitration** (deviation from Grok's phase-switched priority, PL decision):
reads need **no arbitration** — the reg array serves per-port reads combinationally
(core-I, core-D, DMA-R; sim/FPGA true multiport, ASIC banking/2-port macro = recorded P1).
Writes get one grant/cycle with **fixed priority `dma_w > core_dbus > host`** — rationale:
`npu_dma.buf_we` has no backpressure (a lost beat is lost data), the core tolerates stalls
natively via `mem_stall` (`dbus_ready=0` on a DMA-write cycle), the host has full AXI
handshake. Grok's phase-switching adds mode state for no correctness gain (with start=0 the
core is in reset and its ports are quiescent).

**5. TCM sizing.** Stay 4KB unified (Coral 8K/32K split = P1). Bump trigger: random lockstep
programs fail to fit in ≥2 seeds, or coverage closure needs more.

## Verification plan (authority = Spike lockstep, per ADR-0032)

Spike `--isa=rv32im_zicsr_zifencei` (**no C** — green-wash guard), DUT linked at `RESET_PC=0`,
Spike at `0x8000_0000` (existing dual-linker + comparator normalization). `ebreak` remains the
**sole lockstep terminator**; the DONE mailbox is *not* an EOF marker (mapped as benign RAM in
Spike so a stray store never traps). Random body loop-wrapped so program+data+stack ≤ 4KB while
commits scale.

| gate | content | pass bar |
|---|---|---|
| `gate_30_npu_core_integration` | elab both configs; **no instruction commit while start=0** (the ADR-0005 wrapper's boot-prime request line idles high by design — reset gating is the execution guard, observed via `core_resetn`); boot-from-TCM with program loaded *via host AXI path*; mailbox DONE → busy/done CSR readback; start-fall clears done; re-run with a different image; DONE→level IRQ→irq_clear | all directed checks pass |
| `gate_31_npu_core_directed_lockstep` | directed rv32im in-TCM: smoke ≥500 commits; mul/div busy; branch/jalr (redirect only on EX resolve — ADR-0032 strip risk) | 100% commit-trace match vs Spike |
| `gate_32_npu_core_random_lockstep` | riscv_rand (C disabled), **≥8 seeds × ≥10,000 commits/seed** | 0 divergences |
| `gate_33_npu_core_arbitration` | DMA write burst overlapped with running core (fetch+load/store); both complete, no X, TCM golden intact | scoreboard pass |
| host no-regress | full existing gate suite | 17/17 stays green |

Coverage bar (`gate_34_npu_core_strip_coverage`, ADR-0032's ≥95% on `!EN_*` branches measured
on the `npu_top` instance): **closed** — bp/ras/cdec contribute zero coverage points in the
NPU elaboration (generate-off proven at RTL level, not TB-disabled), no EN_* guard line is
uncovered, ifu.v (the live EN_RVC-parameterized module) = 100% line. Residual uncovered core.v
lines are triaged in `phase_20_npu_core_lockstep/coverage_report.md` (debug-module / trap
corners / BP-RAS-mispredict arms unreachable by construction when `EN_BP=EN_RAS=0`).

**Result (2026-07-03):** gates 30–34 all green. Directed lockstep 1164/1164 commits matched;
random lockstep 8 seeds × 10,809 commits each (86k+ commits), 0 divergences; arbitration
scoreboard passed with real overlap (core retired instructions while the DMA engine was busy).
Existing suite: no regression (the only failing gate files are pre-existing M1-era artifact
gates, verified failing at the pre-change HEAD too).

**Supersedes**: the uncommitted prior-session draft `0034-npu-core-alive.md` (same Step-4 scope,
PROPOSED, never accepted). Its stricter options — retire-gated `tohost` done, IDLE/RUN/DONE FSM
with hard host/DMA port isolation during RUN — were considered and recorded here as P1 hardening
candidates (host-access-while-busy policy, P0⑤ abort); the accepted contract above is the
simpler reset-gated variant Grok signed off this session.

**Green-wash guards (Claude enforces):** no C/Zca in `--isa`; the fetch path must be the real
`npu_tcm` ports (no IMEM stand-in); TB must not set start before the load completes; no TB-side
feature disabling; random programs must not use the mailbox as EOF; coverage from the integrated
instance, not the standalone wrapper.

## Top risks → directed catch

1. Fetch-before-load (boot-prime pulls garbage) → `no fetch while start=0` check + AXI-load boot test.
2. ADR-0032 strip residue (EX-only redirect, 4B reset alignment) → branch/jalr directed + smoke.
3. Write-arbitration data loss (DMA beat vs core store) → arbitration scoreboard.
4. `done_latch` vs start race (sticky done breaks re-run) → re-run + immediate-fall directed.
5. Spike/DUT PC normalization drift at `pc=0` → first-commit check per seed before the 10k runs.

## Labor division (per CLAUDE.md §5)

Grok arch/DV (done, this ADR) → Codex surgical RTL (`npu_top.v`, `npu_tcm.v` only; self-check
Verilator lint + smoke) → Claude authoritative gates/lockstep + sole commit.
