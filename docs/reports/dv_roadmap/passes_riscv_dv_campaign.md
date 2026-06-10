# Campaign: passes RISC-V DV (Magpie_M1) — operating model + goal

Status: ACTIVE (opened 2026-06-09). PL = Claude Code (sole committer + acceptance-of-record).
ISA = RV32IMC_Zicsr_Zifencei, M-mode. Authority = Spike per-commit lockstep + pytest gates.

## GOAL (acceptance bar = "B / full ISA", User decision 2026-06-09)
A defensible, **unqualified** "passes RISC-V DV" claim for RV32IMC_Zicsr_Zifencei requires ALL of:
1. **Full instruction mix** under riscv-dv random gen: load/store (incl unaligned), branch/jump,
   CSR (M-mode), RV32M, RV32C, **FENCE.I (Zifencei)**, sync traps (illegal/ecall/ebreak/mret).
2. **Async interrupts (Zicsr/CLINT-class)**: MTI/MSI/MEI via **deterministic retire-count injection**
   on BOTH DUT and Spike + per-event trap_event comparison (P1.1, p11_interrupts_and_triage.md).
3. **Standard riscv-dv test categories** applicable to the ISA (arithmetic, rand_instr, loop,
   jump_stress, csr; NOT mmu/amo/floating = out of ISA scope, scoped-out with rationale).
4. **Scale**: multi-seed, **>=100k matched commits**, **zero unresolved real divergence**.
5. **Functional coverage tied** to the enabled classes; no silent waivers; no cold-zone hand-wave.
6. **Honest gen config** in-repo (only A/F/D/V + privileged-S/U excluded, with stated rationale);
   provenance (git_rev + rtl_cksum + tool versions) per campaign; gate enforces scope honesty.

Out of scope (explicit, with rationale in this doc): A/F/D/V extensions, S/U-mode + MMU/Sv32,
PMP — none are in RV32IMC_Zicsr_Zifencei.

## CURRENT STATE (recon 2026-06-09, rev 3860f24)
- testlist J18 already FULL-MIX for the synchronous side: load/store + branch/jump + CSR + M + RVC
  + sync-trap ALL enabled (`--no_load_store`/`--no_branch_jump` removed; `--no_csr_instr=0`;
  `--enable_unaligned_load_store=1`). gate_03_09 enforces this scope honesty.
- Still EXCLUDED: `--no_fence=1` (FENCE.I) and `--enable_interrupt=0` (async IRQ).
- Latest green campaign = synctrap_100k: 120 seeds / 104,729 commits / zero divergence.
- BUG-XBOUND-0001 = FIXED (J9, consecutive_cross, ADR-0007). Open Layer-1 lead: stall/redirect ×
  consecutive cross-boundary may resume with stale cur_half_lo (Gemini 2026-06-09, unverified).
- Infra: dv_farm.py (parallel gen+sim+compare farm, --integrity guardrail), config/m1_riscvdv/.

## WORK STREAMS (current J18 -> B) — sized by wave-1 co-review (2026-06-09)
- WS1 LOCK [Claude]: xbound directed regression (single/double/TRIPLE + stall + redirect variants).
  Codex verdict: stall-case **GUARDED** (consecutive_cross gated on !stall; IF/EX holds; i_mem_en
  keeps held fetch; resumes {cur_half_lo,residue} at held if_pc = intended). redirect variant
  (pc_redirect clears cross_assemble/residue, core.v:231) = "more delicate" → directed test. So
  WS1 = write PASSING regression to lock J9 + a redirect directed case. gate_03_09 re-verified PASS.
- WS2 FENCE.I [Claude]: Codex verdict **READY** — is_fence decoded (idu.v:102), in known_opcode
  (idu.v:243) → retires as architected NOP; no I-cache so no flush. Action = flip `--no_fence=0`
  + fence.i coverpoint + lockstep smoke. LOW RISK, first concrete step.
- WS3 ASYNC IRQ (P1.1) [Claude RTL + ADR]: Codex verdict **HARD GAP — real RTL+ADR work**:
  RTL has only irq_external_pulse / mie[11]/mip[11] (MEI). MISSING: timer_irq_i->mip[7] (MTI),
  software_irq_i->mip[3] (MSI), MTIE/MSIE, MTI/MSI causes, priority; AND no trap_event port
  (mepc/mcause/mstatus_before-after/handler_entry/mret stream — wb_instr_retired exists internally,
  core.v:1064, but not a first-class iface). Contract = Grok IR-1/2/3 + trap_event fields
  (acceptance_spec_B.md §3). NEEDS ADR (clean-room microarch addition). Campaign center of gravity.
- WS4 CATEGORIES+SCALE: add rand_instr/loop/jump_stress/csr; multi-seed, per-cat >=10k, agg >=100k.
- WS5 TRAP-PATH: largely CLOSED — all RTL trap bugs FIXED (mepc ADR-0011, xbound ADR-0007, M-unit
  ADR-0009); only nested-trap mret-resume WAIVED as harness non-reentrant-handler artifact. Grok §4
  triage procedure guards future cases.
- WS6 COVERAGE: gaps = fence.i + each IRQ cause MISSING (Gemini); rest EXISTS. Tie to enabled classes.

## 4-AGENT OPERATING MODEL (script-farm + blackboard + async peers, per commit 3860f24)
Hub-and-spoke, NOT star-serial. The slow external tools (riscv-dv gen / sim / spike) are the
parallel cost and run in the farm; agents never sit in the driver path.

| Agent | Weapon / lane | Queue (independent — never blocks on Codex) | May NOT |
|---|---|---|---|
| **Claude (PL/hub)** | MCP+repo+clean-room; ONLY code-changer + committer + gate/blackboard owner; per-wave independent acceptance (sha/gate/lockstep) | dispatch, triage synthesis, RTL/test edits, record_step, commit, trigger regression | — |
| **Codex** | read-only bug-hunter / RTL-readiness review at FIXED points AFTER landed changes | RTL-readiness for WS2/WS3, root-cause leads, review landed diffs | run sim / drive farm / self-sign lockstep |
| **Grok** | spec + DV-architecture + roadmap + deep-dive (trace reconstruction) | acceptance spec, phase plan, IRQ-determinism spec, trap-path triage strategy, risk register | commit / decide gate |
| **Gemini** | ~1M corpus / shard / coverage enumeration / log condensation | gen-config deltas, coverage-gap maps, whole-corpus compliance, big-log condensation | architecture decisions / gate verdicts |

Sync points (non-negotiable): (1) dispatch, (2) per-batch triage huddle, (3) fix+commit (Claude
only), (4) closeout rollup. Each farm worker writes shard_status with git_rev + rtl_cksum.

## GUARDRAILS (non-negotiable, per umbrella §2 + project §3)
producer≠approver (Claude accepts; agents advise) · report-faithfully (no fabrication; unrun =
waived/unavailable) · per-run provenance · Layer-1 honesty (findings = clues, NEVER gate
assertions) · authority = Spike lockstep + pytest · licensed EDA via Codex needs
`-s danger-full-access` (OSS verilator/spike unrestricted) · disk hygiene §10 (clean regenerable
trace/obj_dir; never accumulate unbounded golden+dut traces).
