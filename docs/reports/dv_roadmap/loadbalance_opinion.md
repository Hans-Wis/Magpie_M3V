**Critique of the proposed model + recommended best arrangement**

### Agreement / disagreement on the 4 points

1. **Independent queues (Grok/Gemini always have 1-2 non-dependent tasks; Claude does prep + integration)**  
   **Agree in principle.** Starvation is real and wasteful. However, "always have work" is dangerous if the work is speculative on a moving target. Queues must be explicitly labeled `safe / speculative / blocked-on-X`.

2. **Parallelize Codex on non-colliding files/areas**  
   **Disagree as stated.** This is the highest-risk item. In RTL (especially pipeline control, hazard, CSR side-effects, exception priority, and compressed fetch), file ownership is a weak boundary. "Non-colliding" is rarely true at the semantic level even when files differ. Parallel Codex edits are likely to produce subtle, non-mergeable interactions that only appear under lockstep or coverage.

3. **Parallelize the real bottleneck (riscv-dv + Verilator sim via pre-generated seed pool + parallel sims)**  
   **Strong agree.** This is the highest-leverage change. The current waste (Codex or Claude blocked on wall-clock generation/simulation) is the clearest pathology. This class of work is embarrassingly parallel, cacheable, and has clear independence boundaries (different seeds/configs).

4. **Event-driven integration (Claude integrates as results land; only hard serialization is commit)**  
   **Agree with heavy qualification.** Event-driven is better than batch-wait. The qualification is that integration is not cheap for the single committer. "As they land" must not mean "Claude context-switches into full verification on every partial result."

### Strongest failure mode

**Claude becomes the serialized verification + semantic-integration bottleneck, while parallel Codex work creates a flood of near-miss patches that each require expensive re-validation or produce latent bugs.**

Secondary but related: optimistic parallel edits create "integration debt" that violates the project's producer≠approver rule and report-faithfully discipline. One bad merge or missed interaction can invalidate hours of parallel work and force re-simulation of an entire seed corpus.

### Answers to the five questions

**1. Is this the right model? Biggest risk?**  
It is directionally right on throughput but structurally incomplete for a 1-committer, high-semantic-coupling domain like CPU RTL. The biggest risk is **unbounded speculative work + verification amplification** at the single integration point. Parallelism upstream without strong early-kill and narrow integration contracts just moves the queue from "Codex thinking" to "Claude verifying conflicting changes."

**2. How should Claude avoid becoming the new bottleneck?**  
- Enforce a small WIP limit (2–3 in-flight Codex changes max).  
- Require **pre-integration artifacts** from every agent: (a) targeted minimal regression list, (b) expected delta on key metrics (commit trace diff, coverage delta, hazard cases), (c) one-sentence "why this cannot affect X/Y/Z".  
- Use staged verification: fast syntactic/lint/quick-directed first (minutes), full Spike lockstep + coverage only for survivors.  
- Make Codex/Gemini do as much self-contained proof as possible before handing to Claude (e.g., a small directed test that would have caught the interaction).  
- Claude's job is **accept/reject + minimal fix**, not "debug and finish the patch."

**3. Right granularity + dependency discipline for Codex partitioning?**  
Granularity rule: partition by **stable interface contract**, not by file.  
Safe units (examples):  
- A single new instruction's decode + ALU op (if the decoder/ALU interface is frozen).  
- A self-contained peripheral or CSR with its own test harness.  
- Purely additive monitor / coverage collector.  

Unsafe (do not parallelize): hazard logic, forwarding network, exception priority encoder, compressed fetch + pre-fetch residue, trap entry/exit, memory misalign policy.  

Discipline:  
- Maintain a small "owned module + interface" table updated by Claude.  
- Any cross-boundary change requires an explicit "contract change" token held by Claude.  
- Use short-lived feature branches or patch series with clear "depends-on" metadata.  
- Over-partitioning is better than under-partitioning; a 30-minute Codex task that is truly isolated is preferable to a 4-hour one that touches two modules.

**4. riscv-dv throughput: concrete parallelization and expected speedup**  
Best practical structure (low effort, high return):

- **Two-stage pipeline**: (generate ELF/hex + signature) → (run sim + lockstep compare). The generate stage is CPU-light and IO-light; the sim stage is the heavy one.
- Use a **seed pool + manifest** (a small JSON or text file listing seed + config + expected properties). Pre-generate N seeds in parallel with a simple process pool or GNU parallel / `make -j`.
- Cache generated artifacts keyed by (seed, config hash, generator version). Re-use when possible.
- Run Verilator/Spike pairs in parallel (one per core or with a concurrency cap). Each job is independent.
- Separate "quick smoke" config (small instruction count, few seeds) from "full campaign."

Expected results vs effort:
- 4–8× wall-clock reduction on the generation+simulation phase itself with modest code (a small driver script + manifest) — often the difference between "Codex waits 20–40 min" and "Codex gets results in 5–8 min."
- Diminishing returns beyond host core count + memory bandwidth; watch for filesystem contention on waveform/trace files.
- Effort: 1–2 hours of harness work to make the stages cleanly separable and cacheable; very high ROI.

**5. Simpler/better topology for a 1-committer constraint?**

**Recommended refined model (better than the proposal):**

- **Single trunk + small controlled speculation queue (WIP ≤ 3)** with explicit stages:  
  Explore (Grok/Gemini) → Isolated Implement (Codex, narrow contract) → Self-contained Evidence (quick tests + impact note) → Claude Review & Commit.

- **Fast-fail lane**: Every parallel Codex task must produce a cheap "canary" (directed test or lint + one key directed case) that can kill it in <5 min before full simulation.

- **Producer-consumer with backpressure**: Codex/Gemini/Grok emit "candidate patches" into a visible queue (even a markdown table or small state file). Claude pulls when ready. No unbounded fan-out.

- **Heavy parallelization only on the external slow path** (riscv-dv/Verilator) and on **read-only analysis** (Gemini corpus sweeps, Grok spec diffs). Keep write parallelism low and highly partitioned.

- **Optional but powerful**: Claude maintains a "known-good interface snapshot" and a small set of golden directed tests that any incoming change must pass locally before the patch is even presented for integration.

This keeps the 1-committer integrity invariant while extracting most of the available parallelism from the slow external tools and from non-conflicting read/analysis work. The core discipline is **narrow contracts + early cheap evidence + small WIP**, not "everyone has a queue and we integrate when things land."
