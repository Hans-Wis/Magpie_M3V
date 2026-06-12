# Magpie_M1A — Tier-2 Evidence Pack (commercial-quality campaign)

Rev 1.0 (acceptance-ready) · 2026-06-12 · design_id = `cpu_m1a` · Authority = Spike per-commit
lockstep + pytest gates · Plan: `m1a_commercial_quality_plan.md` (3-agent consensus) ·
**Every row = FRESH M1A evidence unless marked INHERIT** (M1 evidence is never claimed —
`gate_00_identity_m1a`). DV-lead/customer signature: PENDING at the final SHA lock.

## §01 Code coverage (effective-signoff methodology, exclusion lists re-derived for the new RTL)

| metric | raw | in-SKU effective | bar | M1 baseline | verdict |
|---|---|---|---|---|---|
| Toggle | 60.0% | **92.9%** | ≥90 | 92.4 | ✅ exceeds M1 |
| Line | 71.6% | **91.7%** | ≥90 | 90.0 | ✅ exceeds M1 |
| Branch | 68.5% | **92.7%** | ≥90 | 93.1 | ✅ above bar (−0.4 vs M1) |
| Expression | 57.8% | **92.8%** | ≥90/95 | 95.3 | ✅ above 90 bar (below M1's 95.3 — debt list documented, 17 points) |

Evidence: `coverage_merged/m1a_farm.dat` (24 seeds, every seed lockstep-clean: 8 base + 3
CSR-pattern + 3 RAS-nested + 10 Zb/illegal-probe), snapshots
`toggle_signoff_snapshot.json` / `lbe_signoff_snapshot.json`, gates 04_10/04_11 (9/9, live
re-derive drift checks). New-RTL stimulus = `inject_zb.py` (31 op variants + reserved-encoding
probes covering the decode-tightening arms).

## §02 ISA / functional

| row | evidence | verdict |
|---|---|---|
| riscv-arch-test | **148/148** fresh (`phase_p_archtest/summary*.json`, 2026-06-12) | ✅ |
| Zb arch-test suite | NOT in the vendored arch-test — **documented deviation**; substitute = `phase_a2` directed (57-commit full lockstep, all 26 ops + misa.B) + illegal negatives (4 reserved encodings, mcause=2) + farm Zb injection at scale (31k+ commits with Zb in-stream) | ⬜ deviation |
| Lockstep | A1 **102,150** + A2 **102,163** commits 0-div on the A2 ISA; A3 dtcm-in-the-loop full lockstep; through-trap/msip/bp_way1/xbound/muldiv/trap_irq directed re-run green on final RTL | ✅ |
| Wrapper equivalence | **REPAIR-0001 complete** — tb_mem_wrapper fully repaired (4 inherited decays incl common-mode instr-reconstruction corruption), A/B(×6)/C/D + 81-commit harness lockstep green; cross-checked vs frozen M1 | ✅ (was not-run) |
| ERRATA-0001 | **FIXED on this line** (hazard.operand_stall gates md_start) + permanent regression in `phase_a1_mul_directed` §9 | ✅ |
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
| Spyglass CDC | `cdc_verify_struct` 0 unwaived (fresh, incl bmu/dtcm/trigger in filelist) | ✅ |
| Spyglass RDC | 0 unwaived (fresh) | ✅ |
| Spyglass lint | **CLEAN-ERRORS (0 errors)** final rerun 2026-06-12 10:33; fix trail: run1 found filelist bbox + pmp W122 + bmu W216 → fixed; run2 newly-linted trigger.v 2× W122 → fixed (explicit fn args); remaining warning families (W415a/STARC style) listed for waiver policy, not silent | ✅ |
| DC multi-corner | **Fmax 699.30MHz ALL corners (WNS 0.00) ✅**; area 30397µm² = **+12.29% vs like-for-like M1 baseline 27069.84 (filelist-corrected) → ≤+15% PASS** (ADR base-number corrected — old 26.3k was the trigger-less filelist); power SLOW 13.63/TT 16.76 PASS, FF 18.31 noted (max-leakage corner, baseline not FF) | ✅ w/ documented baseline correction |

## §05/§09 Process & docs

| row | disposition |
|---|---|
| VPLAN / DV_SIGNOFF_CHECKLIST / FEATURE_FREEZE | re-issue with M1A ISA (RV32IMC+Zb+Zicond), perf baseline (CoreMark/MHz 3.23 O3+Zb; 2.74 O2), guardrails — STALE list per Gemini audit |
| vcd_review_policy / exclusion discipline / signoff strategy | **INHERIT** with rev note (process unchanged) |
| benchmarks | `m1_benchmark_baseline.md` + A1/A2 commit records (CoreMark matrix, MACSTREAM, GEMV) — all sim/ideal-mem caveated |
| SoC subsystem rows (CLINT/PLIC/UART/JTAG) | directed-only as on M1 — honest not-inherited status carried verbatim |
| Final acceptance | Gemini corpus audit + Grok hold-list at a locked SHA + full gate regression + identity gate — LAST step |

## Mutual-review ledger (producer ≠ approver)

| item | producer | reviewer | outcome |
|---|---|---|---|
| campaign plan | Claude | Grok+Codex+Gemini | consensus order |
| REPAIR-0001 | Claude | frozen-M1 cross-check + harness lockstep | green |
| coverage methodology | Claude | gates' live re-derive + (final) Grok | 9/9 |
| Zb injector + misa gap | Claude | lockstep itself + documented | fixed |
| lint/CDC/DC/formal runs | Codex | Claude (verdict integration) + Gemini (log condensation when large) | CDC/RDC clean; lint fixes landed |
| final pack | Claude+Gemini | Grok hold-list + User | PENDING |
