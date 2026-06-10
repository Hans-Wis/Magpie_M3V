# Phase 4.7 Claude Code Advisory Review

Status: advisory-pass-with-finding-fixed

Invocation policy:

- Review mode: independent one-shot advisory review.
- Session handling: no fixed `--session-id`; Claude generated session
  `fee39bf3-74fb-4649-88d0-e592631010b1`.
- Prompt delivery: stdin.
- Output format: `--output-format json`.
- Permission mode: `dontAsk` with explicit read-only allow list.
- Working directory / access root: `/home/edauser/project/SOC/Magpie_M1`.
- PID: `346383`.
- Output: `/tmp/magpie_m1_claude_review_04_07.out`.
- Error log: `/tmp/magpie_m1_claude_review_04_07.err`.
- Status: `/tmp/magpie_m1_claude_review_04_07.status` (`exit_code=0`).
- Claude result UUID: `8263a31a-9396-457b-8ab7-b042700680a3`.

Prompt:

```text
Review Magpie_M1 Phase 4.7 CSR/IDU residual coverage evidence. Concise findings only. Do not edit files. Verify evidence from repo files before giving findings. Return verdict and findings.
```

Claude verdict:

> PASS (evidence is sound and honestly scoped) - with one RTL behavior worth
> flagging.

Verified by Claude:

- Phase 4.7 coverage numbers were computed from Verilator artifacts, not
  hardcoded.
- `module_delta.csv` independently sums to the headline DUT coverage delta.
- Phase 4.7 is honestly reported as `coverage-delta-pass`, not sign-off.
- VCD policy is followed: focused dump by default, full dump behind
  `+full_vcd`.
- The full-DUT percentage is a merge of Phase 4.7 CSR/IDU hits onto the
  Phase 4.6 base, not a fresh full-design simulation.

Finding:

- `BUG-IDU-0001`: reserved BRANCH funct3 encodings `010` / `011` were decoded
  as valid branches (`illegal=0`). Claude found this because the original
  Phase 4.7 reserved-branch default stimulus expected `illegal=0`.

Fix:

- `IP/cpu_m1/rtl/idu.v` now adds
  `branch_funct3_valid`.
- `known_opcode` now accepts branch instructions only when funct3 is one of
  BEQ/BNE/BLT/BGE/BLTU/BGEU.
- The Phase 4.7 testbench still covers the reserved branch default ALU arm, but
  now expects `illegal=1`.
- `docs/v2_pipeline_bug_taxonomy.md` records `BUG-IDU-0001`.

Post-fix evidence:

- Phase 4.7 rerun:
  `PASS: CSR/IDU residual coverage merged; DUT line 1051/1055 (99.62%, +9); DUT toggle 8306/12250 (67.80%, +10); csr=91/91 (100.00%); idu=90/92 (97.83%)`
- Reserved branch decode log:
  `decode reserved branch funct3 default instr=00203263 alu=10 branch=1 invert=0 br_type=1 illegal=1`

Codex disposition:

- Phase 4.7 remains accepted as `coverage-delta-pass`, not sign-off.
- Claude review was completed and produced one valid finding.
- The finding was fixed and regression evidence was refreshed.
- Coverage is still not closed: remaining line residuals are defensive defaults,
  toggle coverage is below target, and functional bins are not implemented.
