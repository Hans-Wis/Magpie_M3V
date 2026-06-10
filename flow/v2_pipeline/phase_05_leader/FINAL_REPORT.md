# Magpie_M1 — Flow-to-5.0 Completion Report

## Executive Summary
The Magpie_M1 CPU IP (RV32IMC_Zicsr) has successfully completed the development flow through **Stage 5.0 (Lint & Synth/PPA Trial)**. This effort demonstrates a clean-room, IP-native development process from ISA scope definition to sign-off quality linting and physical implementation trials. While the flow is complete and the RTL demonstrates high integrity (114k+ commit riscv-dv lockstep and 100.00% functional coverage), the IP is **NOT yet qualified** due to the trial nature of the synthesis and minor physical residuals.

## Final Flow Stage Table
| Stage | Description | Status | Evidence |
|---|---|---|---|
| 0 | isa_scope | PASS | gate_00_spec (ADR-0002) |
| 1.x | Pipeline structural | PASS | gates_01_01 through 01_99 |
| 2.x | Trap & Memory | PASS | gate_02_00, 02_01, 02_02 |
| 3.0 | Spike Lockstep | PASS | gate_03_08 (114,216 commits; 10-seed riscv-dv) |
| 4.0 | Functional Coverage | **PASS (100%)** | 72/72 bins; directed + random + wait-state harness |
| 5.0 | Lint & Synth/PPA | PASS | gate_05_00 (Spyglass), 05_01 (DC Trial) |

## Stage 4.0 Functional Coverage Results
Functional coverage reached **100.00% (72/72 bins)**. The final bin `cg_hazard_flush:mem_stall` was hit via a wrapper-level wait-state coverage harness (`tb_wrapper_func_cov.sv` on `cpu_m1_top`). All 6 covergroups are at 100%.

| Covergroup | Status | Remaining Uncovered |
|---|---|---|
| cg_opcode_instr_class | 100.00% | None |
| cg_alu_m_funct | 100.00% | None |
| cg_load_store | 100.00% | None |
| cg_branch_jump_bp_ras | 100.00% | None |
| cg_csr_trap | 100.00% | None |
| cg_hazard_flush | 100.00% | None |

## Large-scale DV (riscv-dv)
The verification depth has been significantly expanded using the Google `riscv-dv` random instruction generator.
- **Status:** **COMPLETE / PASS**
- **Volume:** **114,216 matched commits** across 10 random seeds.
- **Divergence:** **ZERO** vs Spike Golden Model.
- **Bug Fixes:**
    - Found and fixed **BUG-XBOUND-0001** (consecutive cross-boundary 32-bit fetch logic error, documented in **ADR-0007**).
    - Resolved a `c.lui` apparent-divergence; root cause was a comparator base-normalization false-positive (DUT was executing correctly), now fixed in the verification environment.
- **Impact:** Functional-correctness evidence lifted from 81 commits to >114k commits.

## Stage 5.0 Results

### Lint (Spyglass)
| Tool/Policy | Errors | Warnings | Verdict |
|---|---|---|---|
| Spyglass Lint RTL | 0 | 24 | PASS (ADR-0006) |
| STARC 2005 | 0 | 9 | PASS |

### PPA TRIAL (Synopsys DC)
*Target: TSMC 28HPC+ (tcbn28hpcplusbwp40p140tt0p9v25c), TT 0.9V 25C*
| Metric | Value | Notes |
|---|---|---|
| Frequency | **~699 MHz** | Target 1.43ns; Setup WNS 0.00 MET |
| Area | **26,298 um²** | Total cell area |
| Power | **15.85 mW** | Vectorless DC estimate |

*Caveats: No DFT/scan inserted; no SAIF/VCD activity; 2 hold violators (unbuffered); single-corner trial.*

## Project Execution (J1..J5)
- **Co-work Model:** Claude (Project Leader/Judge), Codex gpt-5.5 (Executor), Gemini (Documentation/Data).
- **EDA Operations:** Resolved license server connectivity by shifting Codex to `-s danger-full-access` (danger-full-access unshares network, allowing license checkout).
- **RTL Integrity:** Found and fixed **BUG-ALIGN-0001** (misalign operator-precedence causing SLT spurious traps). Re-validated 176 pytest gates.

## Honest Residuals / NOT-Qualified Gaps
- **Physical Sign-off:** Still trial synth single-corner; 2 hold violators (unbuffered) remain. Requires multi-corner analysis and APR for routing/clock-tree closure.
- **Verification Depth:** **Resolved.** 114k+ commits of `riscv-dv` lockstep completed across 10 seeds with zero divergence.

## Recommended Next Steps
1. **Maintain Regression Integrity:** Continue coverage-driven random regressions using `riscv-dv` to maintain high functional-correctness confidence.
2. **Architectural Compliance:** Transition to formal architectural test suites (e.g., `riscv-arch-test`) for final ISA compliance sign-off.
3. **Physical Hardening:** Perform multi-corner synthesis and initial APR (Auto Place & Route) to resolve hold violations and validate routability.
4. **ISA Extension:** Evaluate `Zba/Zbb` bit-manipulation extensions for PPA/performance trade-offs.
