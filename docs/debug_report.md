# Magpie_M1 — Debug Report (key findings & error resolutions)

> Cross-project knowledge transfer. Captures the **reusable** lessons from the M1 per-island coverage
> campaign (P00→P18) — tooling traps, coverage methodology, waiver discipline, EDA-license gotchas,
> ISS limitations, and spec fixes. Other CPU/IP projects (X3/X6, future cores) can read this to avoid
> re-discovering the same things.
>
> Date: 2026-06-09 · Authority for correctness = Spike per-commit lockstep + pytest gates · Honesty
> guardrails: report-faithfully, producer≠approver, every waiver verified vs RTL, dual-number RAW+ADJUSTED.

---

## A. Coverage tooling traps (cov_metrics / Verilator / VCS-URG)

1. **URG column order is `<TOTAL> <COVERED> <PCT>`, not `<hit> <total>`.**
   `parse_urg` originally read group1=hit, group2=total. This is **masked whenever hit==total** (alu/lsu/mul
   all 100%), and only surfaced at div (`Branches 20 19 95` → 19/20=95%) where it produced an impossible
   107% (20/19). Fix: parse total-first, **and cross-check the parsed hit/total against URG's own reported
   pct** (raise if |computed−reported|>1.5). A self-checking parser would have caught it on day one.

2. **Verilator toggle point identity = `(object, line)` per-module UNION; do NOT include hierarchy `h`.**
   Including the testbench hierarchy path over-counts per-instance (13058 → 67518 toggle points). Union by
   (object,line) so the same RTL point under different TB instances counts once. Module = file basename
   (DUT basenames are unique).

3. **Line coverage = LCOV `.info` SOURCE-LINES, not `.dat` `t=line` BLOCKS.**
   Verilator `.dat` `t=line` points are basic *blocks* (e.g. 216), not source lines (e.g. 1432). The
   customer "line 100%" metric is source lines → parse `coverage.info` (`SF:`/`DA:`).

4. **VCS branch/expr/FSM is licensed-tool-only — Verilator cannot produce it.** URG `States`/`Transitions`
   rows give FSM state/arc. A module with **no encoded FSM state register** (e.g. `csr.v`) yields *no FSM
   shape* in URG → FSM is **N/A**, not a failure (don't let a charter demand FSM100 on combinational/
   register-update logic).

5. **branch can be N/A.** A module of pure boolean `assign`s (e.g. `hazard.v`) has no `if/case` → URG has
   no branch row. Treat missing branch/expr as N/A (present-then-assert), like FSM-N/A.

---

## B. Waiver discipline — structural vs green-wash (the most important lesson)

**Rule:** a coverage point may be waived as STRUCTURAL only if it is **RTL-hardwired constant** — cite the
exact RTL line. A point that is merely *unstimulated* is **REACHABLE** → close it with stimulus, never waive.

- **Legit structural** (verified vs RTL, all `spike_impact: none`):
  - `idu`: `csr_zimm={27'b0,…}` zero-ext; `imm_u={…,12'b0}`, `imm_b/j` bit0; `funct3` default unreachable
    (3-bit funct3 fully 8/8 decoded — *corrected a Grok charter that assumed illegal-funct3 coverable*).
  - `div`: `default: state<=IDLE` (state is reg[1:0], all 4 encodings used); `md_op[2]` const (divider
    only sees DIV-class opcodes, mul routed elsewhere).
  - `csr`: `mstatus_val`/`mie`/`mip` WPRI bits hardwired 0; `mtvec` MODE `2'b00`.
  - `cdec`: RV64/FP `default:illegal` arms (out of RV32IMC ISA scope); compressed-imm `N'b0` format bits;
    `rd_rs1_p/rs2_p={2'b01,…}` reg-pair.
  - `ifu`: `pc_inc = is_16bit?2:4` → bits[0] and [31:3] constant.
  - `core.v` integration: PC reg bit0 (instruction alignment, PC always even).

- **GREEN-WASH — REJECTED** (the cautionary case):
  - `ras` first submission: toggle 45% + a proposed waiver for `push_val/ras_top/stack[31:14]` citing a
    "16KB firmware map". **Rejected**: at *unit* scope `push_val` is a **free input** — the upper bits are
    real flops, drivable by walking-1/`0xFFFFFFFC`/full-range addresses. The "firmware map" is a stimulus/
    SKU choice, not module structure. Re-dispatched with full-range addresses → **45% → genuine 100%, zero
    waiver**. Had the waiver been accepted, ras would have "passed" at 45%-real + a bogus exclusion.
  - **Discriminator:** *unit* free-input high bits = reachable (drive them). *Integration* PC bits bounded
    by the real memory map = SKU-bound (legit `uncoverable-without-X`, attribute to the IF slice / a
    larger-memory SKU) — different from a unit stimulus choice.

- **Mechanics:** dual-number RAW+ADJUSTED always (never adjusted-only); blanket-waiver ban in code
  (`WAIVER_MAX_FRAC=0.90`, catch-all signal_re with no bit-range rejected); only `approved:true` waivers
  apply; producer (Codex) proposes, **approver (Claude) verifies each vs RTL** before `approved:true`.

---

## C. EDA license — the #1 recurring operational trap

**Licensed Synopsys/Cadence via Codex MUST use `-s danger-full-access`, never `-s workspace-write`.**
This host's license server is at **`127.0.0.1`** (`SNPSLMD_LICENSE_FILE/LM_LICENSE_FILE=…@127.0.0.1`).
`workspace-write` runs the tool under `--unshare-net` → the sandbox's `127.0.0.1` is a *different* loopback
than the host's `lmgrd`/`snpslmd` → checkout fails and **presents as a license wait/queue/contention**
(it is actually network isolation). `danger-full-access` doesn't unshare the net → license works.
**Verify per run:** grep for `license_outcome=available` / a real `urgReport` / `sg_shell` completion
before trusting any EDA number. (OSS — verilator/iverilog/yosys/spike — works under either sandbox.)

---

## D. ISS (Spike) limitations & config

1. **Spike 1.1.1-dev stops logging after an M-mode synchronous trap** (before the `mtvec` handler). So
   **through-trap per-commit lockstep cannot be claimed green** (P17): the evidence is *pre-trap lockstep
   match* + *trap-entry value match* (`mepc`/`mcause`/`mtval` vs Spike). Known from prior J14/J18. Don't
   green-wash a "trap path verified" claim into commit-by-commit lockstep.

2. **Spike default ISA (`rv64ima_zicsr`) presents U-mode**, so it *stores* a written `mstatus.MPP`. An
   M-only DUT that pins MPP=M would **diverge** on a through-MPP lockstep test. Mitigation: keep MPP-WARL
   checks as **DUT-only directed assertions** (not lockstep vectors), or run Spike `--priv=m`. In practice
   no M-only firmware writes MPP (only MIE/MPIE), so pinning never diverges on real tests.

---

## E. Integration-coverage methodology (delta, not whole-core)

The whole-core toggle climb is a mountain (core.v sat at ~68–73% from existing lockstep — the "WS6"
problem). **Decompose:** unit/island gates close each leaf module to Tier-2 (line100/branch100/expr≥95/
toggle≥95/FSM100, after justified waivers); integration slices (P15 datapath / P16 IF / P17 trap / P18
BP-RAS) then own **only the core.v integrator delta** for their region — never re-measure leaf internals,
never run a blank-slate whole-core farm for gate acceptance. Each slice: directed firmware + **Spike
per-commit lockstep** (mismatch = FAIL, not waive) + attribute uncovered as reachable(close)/structural
(cite RTL)/cross-slice(name owner). Merge `base ∪ P15..P18` for the final number (M1: merged core.v
≈ line 96% / branch 79% across the 4 slices, residual attributed by owner).

---

## F. Spec fixes found via lint (example: `mstatus.MPP`)

Spyglass (early, static — independent of sim) surfaced 2 csr.v warnings (`STARC05-2.2.3.3 InitValUsingNBA`
+ `W415a`) on `mstatus_mpp`. Root cause was a **latent spec violation**: an M-mode-only hart must keep
`mstatus.MPP` read-only WARL = M (`2'b11`); the RTL had it as a *writable* reg storing `new_val[12:11]`.
Fix (ADR-0015, spec-correct — not a waiver): `mstatus_mpp` → `localparam 2'b11`, drop the 4 NBA assigns;
mirror in golden; add a structural waiver for the now-constant `mstatus_val[12:11]` 1→0 edge; validate
WARL by a directed write of MPP=0 → readback 11. Lesson: **early lint is a spec-audit tool**, not just
style; fix the source, don't waive the symptom.

---

## G. Operational hygiene

- **Disk:** after each gate, delete regenerable build (`obj_dir`, `vcs/csrc`, `vcs/simv*`); KEEP
  `coverage*`, `vcs/urgReport`, lockstep `*_commit.trace`, reports. Stayed at 35% disk the whole campaign.
- **Pre-built gate skip-guard:** a gate for a not-yet-run phase must `pytest.mark.skipif(coverage absent)`
  → it shows *skipped/not-run*, never a false fail or false pass.
- **Pipeline parallelism (4-agent):** while Codex runs a slow tool, Grok charters the next phase + Gemini
  pre-analyzes its uncovered points + Claude pre-builds the gate. Non-colliding Codex jobs (different
  files/phase dirs) run concurrently. No agent idle waiting on one Codex.
- **Charters are hints, not truth:** Grok charters were corrected twice by Claude's RTL verification
  (idu funct3-default; csr FSM-N/A). Always verify a charter claim against the RTL before acting.

---

## H. Status snapshot (2026-06-09)

- 13 island/unit modules at Tier-2 (alu/lsu/rfu/forward/hazard/mul/div · idu/cdec · csr/ras/bp/ifu).
- Integration: P15 datapath ✓ (lockstep PASS, delta +519), P16 IF ✓ (cross-boundary lockstep PASS,
  BUG-XBOUND-0001 green), P18 BP/RAS ✓ (lockstep PASS), P17 trap *partial* (Spike through-trap limit).
- VCS branch/expr added to P15-P18 (merged core.v ≈ line 96% / branch 79%).
- Spyglass (early): 0 errors, 24 warnings (mstatus_mpp 4 cleared via ADR-0015).
- Waiver files: every entry approved by Claude after RTL verification; 1 green-wash rejected.
