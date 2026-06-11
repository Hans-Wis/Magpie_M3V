# Magpie_M1 — Bug Tracking Summary (Tier-2 §05 deliverable)

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · design_id = `cpu_m1`
Severity 1–2 DUT bugs found during bring-up + DV, with root cause, fix, ADR, and the regression that
locks each closed. Authority for "fixed" = Spike per-commit lockstep + the named pytest gate (no
"looks right"). Source records: `docs/v2_pipeline_bug_taxonomy.md`, `docs/reports/bug_xbound_0001/`,
and the ADRs cited below.

| ID | Sev | Title | Root cause | Fix (ADR) | Regression lock |
|---|---|---|---|---|---|
| BUG-XBOUND-0001 | 1 | Consecutive cross-boundary 32-bit (RVC) fetch divergence | RVC pushed PC to odd half; back-to-back high-half 32-bit instrs mis-assembled; `addi@0x0e` mis-flagged illegal | `consecutive_cross` FSM transition (ADR-0007) | riscv-dv 105k-commit lockstep 0-div; `gate_03_09` |
| BUG-XBOUND-OPEN | 2 | stall/redirect on a cross-boundary run → stale `cur_half_lo` | (DISPROVEN — guarded by `i_mem_en=0` stall-freeze + `pc_redirect` clear) | none needed (verified, ADR-0007 §) | `gate_03_11_stall_xboundary` (39/39 vs Spike) |
| BUG-XBOUND-WARMUP | 2 | `at_cross_boundary` active during `redirect_warmup` | fallback cross path fired during warmup after redirect | gate `at_cross_boundary` off in warmup (ADR-0017) | `gate_03_09`, `gate_01_01` |
| BUG-ALIGN-0001 | 2 | misalign `&&` vs `?:` precedence → spurious SLT trap | C operator precedence: `a && b ? c : d` mis-parsed in align-error expr | parenthesize align-error (ADR-0011 context) | `gate_02_02_misalign_trap` (mcause 4/6) |
| BUG-MUNIT-LATCH | 2 | M-unit (mul/div) result not latched stably across stall | combinational result consumed after unit advanced | result latch + stable-done contract (ADR-0004, ADR-0009) | `gate_03_07_muldiv_hazard`, `gate_p07/p08` |
| BUG-MUNIT-REDIR | 2 | M-unit in-flight not killed on redirect | div in-flight survived a flush → wrong writeback | redirect-kill (ADR-0009) | `gate_01_03_pipeline_hazard`, `gate_03_07` |
| BUG-CSR-IRQ-COLL | 2 | CSR external-IRQ-pending collision | simultaneous CSR write + external IRQ pending mis-prioritized | collision handling (ADR-0003) | `gate_03_02_irq_collision`, `gate_04_01` |
| BUG-BTB-MISPREDICT | 2 | BTB target mispredict recovery | wrong-target predict not recovered to correct PC | mispredict recovery (ADR-0008) | `gate_01_04_bp_ras_redirect`, `gate_04_02` |
| BUG-MEPC-PRECISION | 2 | imprecise `mepc` / WARL mask on 16-bit instr trap | mepc low bit / WARL mask on compressed-instr trap | precise mepc + WARL mask (ADR-0011) | `gate_02_03_mepc_directed`, `gate_03_12` |
| BUG-MSTATUS-MPP | 2 | `mstatus.MPP` writable on M-only hart | MPP accepted non-M values | MPP read-only WARL=M (ADR-0015) | `gate_02_00_trap_interrupt`, `gate_03_12` |
| BUG-CDEC-RESERVED | 2 | reserved compressed encoding not trapped | some reserved RVC encodings expanded to non-illegal | reserved→illegal, HINT→NOP (ADR-0016) | `gate_04_04_illegal_munit_coverage`, `gate_p10_cdec` |
| HARNESS-CLUI | 3 | c.lui idx59 mismatch (NOT RTL) | `spike_commit.py` base-norm bug | harness base-norm fix | `docs/reports/bug_xbound_0001/j10_rvc_lui_evidence.md` |
| LINT-SPEC-x2 | 3 | 2 spec bugs caught by Spyglass lint | (lint-surfaced, fixed) | ADR-0006 lint contract | `gate_05_00_lint` (0/0) |

## Notes
- All Sev-1/2 RTL bugs above are closed with a named regression gate that re-runs on
  `python3 -m pytest tests/gates/ -q`; none are waived.
- The single tracked open coverage item (whole-core toggle, `gate_04_09` xfail) is a coverage gap,
  not a functional bug — see `coverage_report.md` §2.
- "Found by" provenance (Codex / riscv-dv farm / Gemini corpus review / directed) is in the per-bug
  ADR and `docs/v2_pipeline_bug_taxonomy.md`.
