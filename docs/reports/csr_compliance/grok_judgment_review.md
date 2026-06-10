**Adversarial Review: Magpie_M1 riscv-dv Lockstep Judgments**

### JUDGMENT 1 — Spike "halts at ecall" root cause
**Verdict:** PARTIAL

**Counter-argument / failure mode:** The "proof" (one 100k-instruction run succeeding) is anecdotal and does not characterize the instruction inflation caused by trap handlers, mret sequences, mtvec setup, or repeated synchronous traps. The `len(dut)*8 + 20000` heuristic is an arbitrary multiplier with no grounding in worst-case trap density. A program with 50–100 traps (common in random streams that hit ecall/ecall-in-handler, misaligned loads, illegal instr, etc.) can easily exceed the budget even if the user code is short. Non-terminating loops inside handlers (or before tohost) turn this into silent truncation rather than a clean exit. Long-running seeds or seeds with high trap-to-instruction ratios remain at risk.

**Concrete improvement:** Remove fixed-instruction budgeting for the golden run. Drive Spike via the same architectural exit condition the DUT is supposed to hit (tohost write or a dedicated end-of-test CSR write). If a hard cap is still needed for safety, make it `max(len(dut) * K + C, absolute_floor)` where K and C are derived from measured handler lengths in the actual test suite, and always emit a warning + separate "truncated" artifact when the cap is hit so the seed is not counted toward the zero-divergence claim.

### JUDGMENT 2 — terminal-alignment harness fix
**Verdict:** DISAGREE (material risk)

**Counter-argument / failure mode:** The assumption that `write_tohost` is always exactly an auipc+sw pair (or any fixed 2-instruction sequence) is fragile across harness variants, compiler options, and inlining. More critically, truncating the DUT trace at the first observed PC match can *hide* a real divergence: a bug that causes the DUT to compute a bad target and land inside (or jump over) the exit stub will produce an early `write_tohost` PC; keeping only up to `i+2` makes the prefix look matching while the actual control-flow error is discarded. PC aliasing, compressed instruction boundaries, multiple stores to the tohost address, or a relocated exit stub all break the heuristic. The claim "no masking because compare_commits still checks up to the shared exit" is false once the trace has already been surgically shortened.

**Concrete improvement:** Do not truncate the DUT trace for comparison. Instead:
1. Run both sides until each independently detects the architectural exit event (store to tohost address with the expected payload).
2. Compare the *prefix* up to the last commit that both sides agree is still user code (i.e., before either side has entered its exit sequence).
3. Separately assert that both sides performed a tohost write with matching payload, and that final architectural state (GPRs, key CSRs, PC at the store) is consistent.
4. Log the exact commit index of truncation/exit detection per side and flag any seed where the exit points differ by more than a small, documented window.

### JUDGMENT 3 — initial mischaracterization
**Verdict:** AGREE (the history is a process failure)

**Counter-argument / failure mode:** Declaring a 1134 vs 516 commit gap "benign terminal asymmetry" before inspecting the actual diverging commits is a classic DV anti-pattern. Length mismatch is never self-explanatory when traps, mret, and privilege changes are involved; the first mismatch after an mret is almost always the interesting signal, not the trailing garbage.

**Concrete improvement:** Institute a mandatory "length delta triage" rule before any seed is labeled pass or "benign": extract the last N (minimum 8–10) commits on both sides around the length divergence, diff them with PC, instr bits, privilege, mcause, mepc, and mstatus visible, and require a one-line root-cause classification ("nested trap resumption mismatch", "early tohost due to bad branch", "handler length difference", etc.). No seed may contribute to a "zero divergence" total until this classification exists and has been reviewed. This check must be automated in the harness + post-processing script, not left to human inspection.

### JUDGMENT 4 — "2/5 seeds passing proves sync-trap lockstep works"
**Verdict:** DISAGREE (clear overclaim)

**Counter-argument / failure mode:** 2/5 pass (40%) on a tiny sample is not evidence of functionality; it is evidence that the feature is not yet reliable. When 3/5 seeds (each exercising 6 sync traps) diverge at nested trap resumption, the correct interpretation is "sync-trap lockstep is broken for at least one class of nested trap sequences." Passing two seeds proves the basic mret-to-handler path can sometimes line up; failing three proves it does not do so consistently.

**Concrete improvement (honest customer statement):** "Sync-trap and nested-trap behavior was exercised across 5 seeds (30 trap events). Two seeds achieved full per-commit lockstep through all traps, mret, and tohost exit. Three seeds diverged at nested trap resumption (DUT mret resumed into a handler that Spike did not take, or took a different handler). Root cause identified and fixes in progress; sync-trap lockstep is not yet claimed functional. Additional directed + random trap-nesting stress is required before this class of events can be included in the instruction-stream lockstep claim."

### JUDGMENT 5 — overall claim posture
**Verdict:** PARTIAL (mostly honest on its face, but credibility is still fragile)

**Counter-argument / failure mode:** The scoped statement ("103,766 commits / 31 seeds / zero divergence on full-mix RV32IMC_Zicsr instruction-stream, sync-trap-streams + interrupts out of scope") is defensible *provided* the scoping is never elided and the terminal-alignment mechanisms used for those 31 seeds are themselves trustworthy. The biggest latent risk is that the same harness techniques criticized in J1/J2 (instruction budgeting + PC-based truncation at write_tohost) were active during the 103k run. If any of those 31 seeds triggered truncation or budget exhaustion, the "zero divergence" count is partially synthetic. A secondary risk is seed diversity: 31 riscv-dv seeds, even "full-mix", can still share common biases (limited trap nesting depth, similar memory access patterns, under-exercised C + trap interactions, etc.). The earlier arith-only honesty correction is good precedent, but the claim still rests on un-audited harness filtering.

**Single biggest strengthening action:** Publish (or archive in the repo) the exact riscv-dv configuration, full seed list, Spike version + exact flags, harness version, per-seed raw commit counts *before* any truncation, whether truncation was applied, trap counts and max nesting depth per seed, and the final architectural state at exit for each seed. Add at least one 500k–1M commit run (or multiple 200k+ runs) with a deliberately trap-heavy constraint set and require it to pass the improved terminal-alignment rules above before re-asserting the 100k+ claim at the next milestone.

### Additional outright wrong / high-risk items to revisit now
- The terminal-alignment logic (J2) is the single highest-risk artifact still sitting in the harness. Any "zero divergence" numbers collected while it was active should be re-qualified or at minimum footnoted with "subject to exit-stub truncation heuristic."
- The pattern of first declaring count/length anomalies "benign" and only later doing per-commit + trap-context inspection (J3) indicates a missing automated gate. This is a methodological hole, not just a one-time slip.
- Continued reliance on any fixed-instruction or fixed-length heuristic for golden vs DUT alignment will eventually produce a silent false pass on a long or trap-dense seed. This should be treated as technical debt to be removed, not tuned.
