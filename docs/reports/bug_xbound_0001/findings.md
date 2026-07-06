# BUG-XBOUND-0001 — consecutive cross-boundary 32-bit fetch (RVC) divergence

- Status: **FIXED** (J9 2026-06-08T15:34 — `consecutive_cross` FSM transition, ADR-0007; 4→58
  matched commits, no regression / 179 gates. Verified again 2026-06-09 by 4-agent co-review:
  Codex confirmed checked-out core.v already carries the repair; actions.jsonl J9/J11 corroborate;
  J11 reached 114,216 commits zero-divergence. This header previously read OPEN — stale doc debt,
  now corrected.)
- Follow-on note: the c.lui mismatch (idx59) recorded later was a HARNESS bug in
  `spike_commit.py` (base-norm), not RTL — see `j10_rvc_lui_evidence.md`.
- **Open lead — RESOLVED / DISPROVEN (2026-06-11, `gate_03_11_stall_xboundary_lockstep`)**: the
  clue was that a load-use/muldiv `stall` (or redirect) landing ON a consecutive cross-boundary run
  holds `cross_assemble`/`residue` while `i_mem_addr` reverts to the held PC, so the resumed
  `{cur_half_lo, residue}` might use a stale `cur_half_lo`. **Not a live bug.** Two guards cover it:
  (1) a load-use/muldiv stall drives `i_mem_en=0` (`core.v:309`), freezing the prefetched BRAM word
  so `cur_half_lo` and registered `residue` stay consistent across the stall (FSM `core.v:328-330`
  holds `cross_assemble` through stalls "so BRAM data stays valid"); (2) `pc_redirect` clears
  `cross_assemble` entirely (`core.v:313`) and re-warms. Proven empirically: directed program
  (`flow/v2_pipeline/phase_03_11_stall_xboundary/firmware.S`) drives 16 cross-boundary 32-bit instrs
  with load-use, mul, div, forward-redirect (+wrong-path suppression) and backward-redirect all
  landing ON the run, via both the prefetch-armed and redirect-fallback cross paths → **39/39 commits
  matched Spike, 0 divergence**. (Clue surfaced by Gemini corpus review 2026-06-09; closed by Claude
  2026-06-11. The riscv-dv arith+RVC farm physically cannot reach this corner, hence the directed gate.)
- Status (historical, pre-fix): **OPEN** (found 2026-06-08 by riscv-dv large-scale lockstep, J8)
- Severity: **high** (common code pattern; blocks riscv-dv ≥100k lockstep; correctness)
- Found by: Codex gpt-5.5 (riscv-dv pyflow → cpu_m1 Verilator → Spike lockstep)
- Do NOT assign to Spark — delicate RTL (cross-boundary fetch).

## Symptom (external evidence)
DUT and Spike agree on commits 0–3, diverge at commit idx 4:

| idx | pc   | instr      | meaning              | DUT | Spike |
|-----|------|------------|----------------------|-----|-------|
| 0   | 0x00 | f14022f3   | csrr x5, mhartid     | ✅  | ✅ |
| 1   | 0x04 | 00004301   | c.li (compressed)    | ✅  | ✅ |
| 2   | 0x06 | 00628263   | beq (32-bit)         | ✅  | ✅ |
| 3   | 0x0a | 00000f97   | auipc x31,0 (32-bit) | ✅ rd31 wd=0x0a | ✅ rd31 wd=0x0a |
| 4   | 0x0e | 00cf8f93   | addi x31,x31,0xc     | ❌ **no commit (DUT illegal/trap)** | ✅ rd31 wd=0x16 |

DUT stops (decodes illegal → traps) at `addi@0x0e`, a legal instruction Spike retires.

## Root-cause hypothesis
The compressed `c.li@0x4` (2 bytes) shifts subsequent alignment to **odd half-word**, so
pc 0x6 / 0xa / 0xe are **consecutive high-half (cross-boundary) 32-bit instructions**.
The lab08e `residue` / `cross_assemble` pre-fetch path (in `design/cpu_m1/rtl/core.v`
+ `ifu.v`) handles 1–2 such instructions but **mis-assembles a RUN** of them, so the
3rd (`addi@0x0e`) is assembled from wrong bytes → decodes illegal → trap.

This is NOT a harness bug: Codex fixed the Spike side (0→5 commits) and the two models
agree bit-exactly for 4 commits before the DUT stops. NOT a misalign/mem_wrapper issue
(mem_stall=0 here).

## Next-session plan
1. **Confirm**: re-run the repro, observe the DUT's internal `instr_assembled` / `cross_assemble`
   / `residue` / `cur_half_*` at pc=0x0e. Verify the assembled bits ≠ 0x00cf8f93.
2. **Root-cause** the residue/pre-fetch state machine for back-to-back cross-boundary 32-bit
   (lines around `upcoming_cross` / `at_cross_boundary` / `cross_assemble` in core.v 100–223).
   Likely the residue for the NEXT cross-boundary isn't set up while consuming the current one.
3. **Fix** clean-room (no copying external cores) + **ADR** (it's a microarch deviation/fix).
4. **Validate**: the riscv-dv repro now matches Spike; re-run the full suite (176 gates),
   gate_03_08 lockstep, functional coverage (must stay 100%), then resume J8 toward ≥100k.

## Repro
- Program + traces: `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/runs/seed_2026060801/`
- Divergence detail: `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/divergence/seed_2026060801_divergence.json`
- Harness: `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/run_riscvdv_lockstep.py` (--start-seed 2026060801)
- riscv-dv: `SOC/Magpie_X6/vendored/riscv-dv` rev 80e7a00; gcc riscv-none-elf-13.2.0; spike 1.1.1-dev.

## Why missed before
81-commit lockstep + directed tests used mostly aligned 32-bit instrs; none hit
"compressed instr shifts to odd-half, then a run of cross-boundary 32-bit instrs".
This is exactly what riscv-dv random alignment surfaces at scale.
