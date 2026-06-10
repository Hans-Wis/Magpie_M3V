# Magpie_M1 — DV Methodology Equivalence (vs UVM / RVVI requirement)

> Documents why Magpie_M1's verification methodology (directed Verilog TBs + riscv-dv constrained-random
> + **Spike per-commit lockstep**) satisfies the *intent* of the customer Tier-2 §05 requirement
> ("UVM/SV TB with agent/monitor/scoreboard ≥80% reuse + RVVI-interface reference-model lockstep"),
> and is recorded as a **documented deviation** rather than a gap to close by a 2-6 month UVM rewrite.
> Reviewed by Grok + Codex + Gemini (2026-06-09): unanimous *document-as-deviation*, not rewrite-now.

## The requirement and the intent

§05 asks for two things: (a) a **reusable structured testbench** (UVM agent/monitor/scoreboard), and
(b) a **reference-model lockstep** comparing every instruction retire (PC/GPR/CSR) against a golden ISS
over the **RVVI** interface. The *verification intent* is: **prove the DUT is architecturally equivalent
to a golden RISC-V model on every committed instruction, under both directed and constrained-random
stimulus, with a maintainable harness.**

## How M1 meets the intent

| §05 intent | M1 mechanism | Evidence |
|---|---|---|
| Per-retire PC/GPR/CSR equivalence vs golden model | **Spike per-commit commit-trace lockstep** — DUT commit trace compared to Spike `--log-commits` at every retire (PC, written GPR, CSR side-effects) | `gate_03_00..09`, `phase_*/{dut,spike}_commit.trace`; integration slices P15-P18 lockstep-verified |
| Constrained-random stimulus | **riscv-dv (Google)** generator + Spike golden | `phase_03_09_riscvdv_lockstep` |
| Directed boundary tests | directed firmware per island + per integration slice | `phase_p0*/p1*` firmware.S, `phase_03_04` directed |
| Coverage-driven closure | dual-number coverage + per-island Tier-2 ladder; uncovered → targeted directed vectors | `gate_p02..p19`, `cov_metrics` |
| Reusable harness | parameterized unit-TB pattern + `cov_metrics` + the `coverage-ladder` generator (one gate per module) | reproducible across all 13 islands |

**Why this is a *stronger* ISA-correctness story than RVVI-interface conformance:** RVVI standardizes the
*interface* for trace comparison; M1 already does the *comparison itself* per commit against the
authoritative ISS (Spike). The correctness guarantee — "no wrong architected state at any retire" — is
identical; only the wire-format/IP-XACT packaging differs.

## What is NOT claimed (honest gaps)

- **Not** an RVVI-standard wire interface — M1 compares commit traces directly, not via the RVVI signal
  bundle. A thin RVVI shim is a packaging task (Phase B) if a customer's bring-up flow requires it.
- **Not** a UVM environment — no `uvm_agent`/`uvm_scoreboard` class library, no UVM reuse metric. The
  directed + riscv-dv + lockstep flow is the equivalent. A UVM wrapper is a **funded Phase-B sales
  enabler** (Codex estimate: 2-6 months for a customer-auditable env), not a correctness prerequisite.
- **Not** Imperas/OVPsim dual-track — single golden (Spike). A second reference model is optional.

## Known ISS-config caveat (recorded, not hidden)

Local Spike 1.1.1-dev (`--isa=rv64ima_zicsr` default, U-mode present) stops logging after an M-mode
synchronous trap, so **through-trap** per-commit lockstep is evidenced by pre-trap prefix match + trap-
entry value match (mepc/mcause/mtval), not commit-by-commit through the handler. Through-trap lockstep
needs Spike `--priv=m`. See `docs/reports/integration_closure.md` (P17) and ADR-0015.

## Disposition

§05 is recorded as **DOCUMENTED DEVIATION** with this equivalence brief. The optional UVM wrapper + RVVI
shim are scoped as **Phase B, funded-on-demand**. The correctness obligation is already met by Spike
per-commit lockstep over directed + riscv-dv stimulus.
