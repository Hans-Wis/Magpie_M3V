# ADR-0026 — Magpie_M1A scope: performance line vs Cortex-M55 (scalar + DSP + edge-LLM)

- Status: **accepted** (rev 2 — integrates the three-agent review; see Review log)
- Date: 2026-06-11
- Deciders: PL (Claude) + User
- Reviewers: Grok (DV/roadmap) · Codex (adversarial, repo-evidence) · Gemini (corpus consistency) —
  raw findings archived in `docs/reports/adr0026_reviews/`
- Inputs: `docs/reports/m1a_performance_evaluation.md` (Grok-ranked roadmap, M55 bar web-confirmed),
  `docs/reports/m1_benchmark_baseline.md` (measured: CoreMark/MHz 2.47, CPI 1.29, GEMV int8 11.0 c/MAC),
  `docs/M1_DESIGN_FREEZE.md` (fork base `m1-rtl-freeze-v1.0`), ADR-0002 (4-stage Ch2 lab08e baseline),
  ADR-0023/0024 (RV32A / PMP optional — unchanged by this ADR), ADR-0005 (valid/ready mem wrapper).

## Context

M1 (RV32IMC_Zicsr_Zifencei, 4-stage in-order single-issue, 699 MHz / 26.3 kµm² / 15.9 mW @TSMC28HPC+
DC trial) is design-frozen with a Tier-2-candidate package. M1A must beat Cortex-M55 incl DSP and
edge-LLM. Measured gap: scalar per-MHz 2.47 vs 4.2; absolute CoreMark ≈1729 vs ≈1680 — **engineering
numbers (Verilator sim, ideal 1-cycle memory, DC-trial frequency; carried as a mandatory caveat on
every CoreMark claim)**. int8 MAC 0.127 GOPS vs Helium ~3.2 (25×) vs +U55-128 ~102 GOPS (~800×).
The CoreMark gap is **instruction count** (ISA work density), not CPI; edge-LLM is **bandwidth-bound**.

## Decision

### D1 — Keep the 4-stage in-order spine; M1A targets workload-absolute wins, not per-MHz parity
M55 is also 4-stage in-order; M1's spine delivers 699 vs ~400 MHz at 28nm (ADR-0002 lineage). The
evaluation's note that per-MHz CoreMark parity (4.2) "likely needs dual-issue" is **acknowledged and
deliberately de-scoped**: M1A's claims are absolute/workload-level (D4); **dual-issue = M1B-class work,
out of M1A scope**. This supersedes any ambiguity in the evaluation doc.

### D2 — Phased scope (each phase ADR'd + gated; prior phase green first)

**Phase ordering note (review-integrated):** the evaluation ranked memory first *for end-ML payoff*.
Phase A deliberately runs **A1 (MUL) first as the smallest-risk RTL slice** to validate the entire
ADR→RTL→lockstep→gate loop on the new line; A3 (memory) has a larger design surface and lands within
the same phase. End-ML payoff ordering is unaffected (B/C consume A3's groundwork).

| sub-phase | scope | authoritative KPI / exit | lockstep |
|---|---|---|---|
| **A1 MUL throughput** | **Decouple M-unit issue**: today `core.v:662` (`md_busy`) + `hazard.v` (`muldiv_stall`) serialize the WHOLE pipe on every mul/div; the 33×33 multiplier datapath in `mul.v` already evaluates combinationally between flops — so the work is **issue/result decoupling (back-to-back issue, throughput 1, latency 2) + scoreboard/consumer-bypass + forwarding**, NOT the multiplier itself. This supersedes the evaluation's "1-cycle MUL" shorthand. Div: early-termination (separate, may slip to A1.1). | **MACSTREAM 6.63 → ≤3.5 c/MAC** (authoritative); GEMV_I8 delta reported; CoreMark claims deferred to A2 | Spike-native (timing-invisible); **gates: new issue/scoreboard directed + muldiv-hazard regression + RV32C cross-boundary regression (BUG-XBOUND class) + lockstep ≥100k + DC smoke** |
| **A2 scalar ISA** | **Zba+Zbb+Zbs+Zicond** decode/ALU. Instr-count budget (gate-checked): list pointer-chase → sh1add/sh3add; state-machine compares → min/max/sext/zext; matrix indexing → sh*add; target = **−15% dynamic instr count on CoreMark hot loops** | CoreMark/MHz 2.47 → **≥2.9** (sim/ideal-mem caveat attached) | Spike-native `rv32imc_zba_zbb_zbs_zicond_zicsr_zifencei` (string validated locally); **gates: toolchain-acceptance (gcc asm + Spike parity + riscv-dv config) BEFORE RTL merge; illegal-op negative tests; misa.B exposure policy decided WITH Spike parity; per-extension functional-coverage bins** |
| **A3 memory** (KPI AMENDED 2026-06-12, Grok-concurred — see note below) | **dtcm.v dual-bank TCM macro** (IP-delivered memory, core RTL untouched): 32-bit core-port semantics IDENTICAL behind the valid/ready contract (banks interleaved on addr[2]); **64-bit wide read port as the documented Phase-B interface** (vector LSU / GEMV weight feed), directed-exercised (mandatory — a stub without directed exercise is dead logic). **IFU-64 fetch widening DEFERRED to Phase B** (touches the RV32C cross-boundary prefetch = BUG-XBOUND territory; scalar fetch is not the limiter at CPI 1.20) | (a) wide-port directed **8 B/c sustained**; (b) **ZERO scalar regression** (lockstep + CoreMark/MACSTREAM unchanged); (c) wrapper-equivalence green | dtcm-in-the-loop directed lockstep + wrapper-equivalence regression (phase_02_01) + byte-lane/backpressure directed |
| **B vector** (own ADR before any RTL) | RVV 1.0 **Zve32x VLEN=128 dual-beat** beside the spine; vector LSU on TCM | ~8 int8 MAC/c (≈5.6 GOPS @699 MHz — **estimate only**; re-derived in the Phase B ADR after compiler/ABI/vtype-vl-vstart compare are locked) | Spike RVV + **vector-retire equivalence ADR is a hard precondition** |
| **C GEMV** (own ADR) | TC int8/int4 GEMV 64→128 MAC, custom-0; weights TCM-resident; DMA double-buffer | roofline-disclosed GOPS + tinyLLM tokens/s demo | Spike `--extension` plugin; **per-commit retire contract (beats, CSR side-effects) defined in the ADR — undefined = lockstep trap** |
| **D NPU** (optional SKU) | U55-class 256-MAC companion | contract-driven | split authority (CPU lockstep + bit-accurate model + boundary cosim), documented deviation |

Active after this ADR: **Phase A (A1→A2→A3)**.

**PPA guardrails (per-SUB-PHASE, not end-of-phase):** DC smoke after each of A1/A2/A3 —
frequency ≥ **650 MHz**, cumulative Phase A area ≤ **+15%**, power ≤ **18 mW** (baseline 15.9).

### D3 — Verification principles carry over (with named additions)
Authority = Spike per-commit lockstep + pytest gates (M1 §2/§3 verbatim). Per phase: riscv-dv regen
on the new ISA string, lockstep ≥100k commits 0-div, effective-coverage methodology (exclusion lists
**re-derived** for new RTL), lint/CDC clean, **plus the named gates in the D2 table** (toolchain
acceptance, illegal-op negatives, misa policy, per-extension functional bins, wrapper equivalence).
M1 evidence never claimed (`gate_00_identity_m1a`; `gate_00_spec` now asserts `cpu_m1a` on this line).

### D4 — Honest marketing gates
No "beats M55" claim without named workload + benchmark evidence **on this line**, and every CoreMark
figure carries the sim/ideal-memory/DC-trial caveat until silicon-accurate numbers exist. Order of
claims: absolute CoreMark (after A2) → µRISCV-NN kernels (after B) → tinyLLM tokens/s with disclosed
bandwidth roofline (after C).

## Consequences

- `ip.json` updated with this ADR: `commercial.sku1_mvp.isa` → RV32IMC+Zba/Zbb/Zbs/Zicond (Phase A2
  target), `microarchitecture` features += pipelined-mul/Zb*/Zicond (planned), `gate_map` += m1a
  identity + Phase A planned gates (status **not-run** until each sub-phase opens — honest taxonomy §9).
- `gate_00_spec` patched on this line (`cpu_m1a`) — was a live failure caught by the Codex review.
- First RTL work = A1 (core.v/hazard.v/mul.v issue-decoupling). Gate before merge per D2 row.
- Risks: forwarding/hazard rewrite is THE divergence surface (mitigation: BUG-XBOUND-class regression
  + 100k lockstep per sub-phase); Zb* ALU mux timing erosion (mitigation: per-sub-phase DC smoke);
  vector-retire equivalence engineering (mitigation: hard ADR precondition before B).

**PPA guardrail baseline correction (2026-06-12, from the DC run):** the "+15% area vs 26.3kµm²"
absolute base came from the M1 trial whose DC filelist was MISSING trigger.v (black-boxed). The
like-for-like baseline (same corrected filelist on frozen M1) is **27069.84µm²**; M1A measures
30397.37µm² = **+12.29% → guardrail PASS**. Frequency 699.30MHz all corners (≥650 PASS); power
SLOW 13.63 / TT 16.76mW PASS, FF corner 18.31mW vs the ≤18 figure noted as the max-leakage-corner
caveat (M1's 15.85 baseline was not an FF number; per-corner comparison documented, not waived
silently).

**A3 KPI amendment (2026-06-12, post-acceptance, Grok-concurred):** the original "loadstream 1.78 →
≥3.5 B/c" KPI was **unachievable by the stated scope** — the 1.78 B/c limit is scalar ISSUE physics
(8 lw + 8 consuming adds + loop = 18 cyc/32B at IPC 1.0; lw ceiling 4 B/c), not memory bandwidth.
Dual-bank TCM buys the FUTURE vector/GEMV wide feed, so the honest KPI is the wide-port demonstration
+ zero scalar regression (above). ifu-64 deferral and stub-discipline per the same review.

## Review log

| reviewer | verdict | disposition |
|---|---|---|
| Grok | ACCEPT-WITH-CHANGES (5) | all integrated: A1 KPI=MACSTREAM; hazard/RV32C regressions added; A2 toolchain gate + instr budget; A3 contract pinned; per-sub-phase PPA + power guardrail |
| Codex | ACCEPT-WITH-CHANGES (9: 3 HIGH, 4 MED, 2 LOW) | all integrated: A1 reframed to issue-decoupling (mul datapath already 1-cycle combinational); gate_00_spec identity fixed; valid/ready wording; A3 gates enumerated; A1-first justification added; D3 named gates; B claims softened; CoreMark caveat mandatory |
| Gemini | INCONSISTENT(3) | all integrated: MUL-wording supersession explicit; dual-issue de-scope explicit (D1); ip.json keys updated per list; missing references added to Inputs |
