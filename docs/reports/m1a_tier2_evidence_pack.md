# Magpie_M1A — Tier-2 Evidence Pack (commercial-quality campaign)

Rev 1.2 (acceptance-ready; ERRATA-0002 fixed, post-fix re-earn CLEAN, line=100%) · 2026-06-12 · design_id = `cpu_m1a` · Authority = Spike per-commit
lockstep + pytest gates · Plan: `m1a_commercial_quality_plan.md` (3-agent consensus) ·
**Every row = FRESH M1A evidence unless marked INHERIT** (M1 evidence is never claimed —
`gate_00_identity_m1a`). DV-lead/customer signature: PENDING at the final SHA lock.

## §01 Code coverage (effective-signoff methodology, exclusion lists re-derived for the new RTL)

| metric | raw | in-SKU effective | bar | M1 baseline | verdict |
|---|---|---|---|---|---|
| **Line** | 75.7% | **100.0%** (in-SKU debt = 0, FINAL post-fix+pragma build) | ≥90 | 90.0 | ✅ **CLOSED** |
| Toggle | 60.2% | **92.9%** | ≥90 | 92.4 | ✅ exceeds M1 |
| Branch | 70.4% | **94.8%** | ≥90 | 93.1 | ✅ exceeds M1 |
| Expression | 61.0% | **95.3%** | ≥90/95 | 95.3 | ✅ at M1 (named 10-point debt list) |

**Line-100% methodology (customer-clean):** real stimulus closure (RV32C ops via sp-independent
aligned scratch, div spec-edges, CSR-forward pairs, rotating reserved-encoding probes at the
empirically-proven safe density with per-program caps) + **CS-COV-1 source pragmas** on
unreachable-by-construction defensive arms (self-documenting in the RTL — the one-line policy note
replaces a waiver appendix) + ENV-WAIT-STATE excluded-WITH-EVIDENCE (the 3 `core_mem_stall` hold
lines are exercised green in the wrapper wait-mode environment; random farm `mem_stall` would
violate the ADR-0005 contract — measured). Diverged seeds' coverage is NEVER counted (2 dropped).
**OPEN: INVESTIGATION-0001** — zb seed 2026073308 diverged (same-program different-wdata at idx
196); its coverage discarded; root-cause owed (potential real finding, disclosed not swallowed).

Evidence: `coverage_merged/m1a_farm.dat` (24 seeds, every seed lockstep-clean: 8 base + 3
CSR-pattern + 3 RAS-nested + 10 Zb/illegal-probe), snapshots
`toggle_signoff_snapshot.json` / `lbe_signoff_snapshot.json`, gates 04_10/04_11 (9/9, live
re-derive drift checks). New-RTL stimulus = `inject_zb.py` (31 op variants + reserved-encoding
probes covering the decode-tightening arms).

## §02 ISA / functional

| row | evidence | verdict |
|---|---|---|
| riscv-arch-test | **74/74** fresh, re-run on the ERRATA-0002-fixed RTL | ✅ |
| Zb arch-test suite | NOT in the vendored arch-test — **documented deviation**; substitute = `phase_a2` directed (57-commit full lockstep, all 26 ops + misa.B) + illegal negatives (4 reserved encodings, mcause=2) + farm Zb injection at scale (31k+ commits with Zb in-stream) | ⬜ deviation |
| Lockstep | **85k+ commits 0-div on the FINAL (ERRATA-0002-fixed) RTL** (GOLD-4 ~40k + top-up 46,755); A1/A2 each 102k on prior RTL; A3 dtcm-in-the-loop; full directed suite (9 phases) re-run green on final RTL | ✅ |
| Wrapper equivalence | **REPAIR-0001 complete** — tb_mem_wrapper fully repaired (4 inherited decays incl common-mode instr-reconstruction corruption), A/B(×6)/C/D + 81-commit harness lockstep green; cross-checked vs frozen M1 | ✅ (was not-run) |
| ERRATA-0001 | **FIXED** (hazard.operand_stall gates md_start) + permanent regression (`phase_a1_mul_directed` §9) | ✅ |
| ERRATA-0002 | **FIXED** (div.v flush input kills wrong-path-started division on redirect) + permanent regression (`phase_a2` illegal: probe→div, quotient asserted); root-caused from INVESTIGATION-0001 (arithmetic proof of stale-operand) | ✅ |
| INVESTIGATION-0002 | 1 zb coverage seed (2026075307) watchdog-timed-out (non-termination, NOT a wdata divergence) under dense injection; coverage excluded per the iron rule; likely program-length, triage inconclusive (re-run path issue) — flagged for next rev, line=100% does NOT depend on it | 🟡 open/disclosed |
| misa-writability parity | found by Zb injection (Spike misa writable vs DUT WARL read-only); harness neutralizes generated misa writes identically both sides — documented | ✅ |

## §03 Formal

| row | evidence | verdict |
|---|---|---|
| SVA re-prove | **VC Formal 40/40 proven, 0 failed** on M1A RTL (alu 3 + rfu 4 + forward 8 + lsu 1 + csr-partial 6 = 22 core binds; + AXI4-Lite 18/18); logs in `phase_p_formal/logs/` + `phase_p_axi/` (2026-06-12) | ✅ |
| mul props | old props target the REWRITTEN mul (stateless) — **N/A-rebind-needed, documented gap** (no fake green) | ⬜ gap-documented |
| bmu props | NEW module — **prop gap documented**; covered by directed+farm lockstep evidence | ⬜ gap-documented |

## §06 Static signoff

| row | evidence | verdict |
|---|---|---|
| Spyglass CDC/RDC | **0 unsync / 0 RDC** (re-run, full filelist); 1 Propagate_Resets setup warning documented; X-prop subset all 0 | ✅ |
| Spyglass lint | **CLEAN, 0 errors** (re-run on ERRATA-0002 RTL); 92 style warnings tracked for the DV-lead waiver policy (W415a 46/STARC 28/W528 9/…) | ✅ |
| DC SLOW smoke | **699.30 MHz WNS 0.00 (≥650 PASS)**; area 30515µm² = **+12.73% vs like-for-like 27069.84 (≤+15% PASS)**; power 13.65 mW; re-run on ERRATA-0002 RTL | ✅ |

## §05/§09 Process & docs

| row | disposition |
|---|---|
| VPLAN / DV_SIGNOFF_CHECKLIST / FEATURE_FREEZE | re-issue with M1A ISA (RV32IMC+Zb+Zicond), perf baseline (CoreMark/MHz 3.23 O3+Zb; 2.74 O2), guardrails — STALE list per Gemini audit |
| vcd_review_policy / exclusion discipline / signoff strategy | **INHERIT** with rev note (process unchanged) |
| benchmarks | `m1_benchmark_baseline.md` + A1/A2 records; CoreMark log made SELF-CONSISTENT (flags string was hardcoded -O2 while the run was O3+Zb — Gemini audit catch; flags now passed at build, rerun reproduces 3097358 cycles = 3.23/MHz) |
| SoC subsystem rows (CLINT/PLIC/UART/JTAG) | directed-only as on M1 — honest not-inherited status carried verbatim |
| **Legacy gate-suite reconciliation** | GAP (REPAIR-class, disclosed): on the fresh M1A workspace ~21 of 264 pytest gates fail — NONE is an RTL-correctness defect. Two classes: (a) **stale source-text assertions** on M1-era RTL that A1/A2/A3 legitimately changed (e.g. gate asserts mul.v `done_pending` — removed by the A1 stateless rewrite; idu `illegal = !known_opcode` — extended by A2 `| bmu_slot_illegal`); (b) **inherited pre-fork unit-TB compile bit-rot** (debug-port-era missing pins — same class as REPAIR-0001; fixed for p02/p03/p04/03_05/03_06/04_01-03 via TB lint waivers, rest pending). These gates passed historically on committed artifacts from older RTL generations. Per ADR-0026 D3 the gate assertions must be RE-DERIVED for the M1A RTL — a bounded maintenance pass, NOT a signoff blocker for the re-earned core evidence above. |
| Final acceptance | Gemini corpus audit + Grok hold-list at a locked SHA — after the gate reconciliation pass |

## Mutual-review ledger (producer ≠ approver)

| item | producer | reviewer | outcome |
|---|---|---|---|
| campaign plan | Claude | Grok+Codex+Gemini | consensus order |
| REPAIR-0001 | Claude | frozen-M1 cross-check + harness lockstep | green |
| coverage methodology | Claude | gates' live re-derive + (final) Grok | 9/9 |
| Zb injector + misa gap | Claude | lockstep itself + documented | fixed |
| lint/CDC/DC/formal runs | Codex | Claude (verdict integration) + Gemini (log condensation when large) | CDC/RDC clean; lint fixes landed |
| final pack | Claude+Gemini | Grok hold-list + User | PENDING |
