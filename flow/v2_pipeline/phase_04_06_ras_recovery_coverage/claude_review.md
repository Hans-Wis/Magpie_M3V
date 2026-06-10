# Phase 4.6 Claude Code Advisory Review

Status: advisory-pass-with-caveats

Invocation policy:

- Review mode: independent one-shot advisory review.
- Session handling: no fixed `--session-id`; Claude generated session
  `ade64823-0a71-47b2-a34f-be41566a880e`.
- Prompt delivery: stdin, to avoid variadic CLI options consuming the prompt.
- Output format: `--output-format json`.
- Permission mode: `dontAsk` with explicit read-only allow list.
- Working directory / access root: `/home/edauser/project/SOC/Magpie_M1`.
- PID: `319453`.
- Output: `/tmp/magpie_m1_claude_review.out`.
- Error log: `/tmp/magpie_m1_claude_review.err`.
- Status: `/tmp/magpie_m1_claude_review.status` (`exit_code=0`).
- Claude result UUID: `cabd3b35-97ac-40f1-b097-efeaa3f6dc85`.

Read-only tool boundary:

```bash
--permission-mode dontAsk \
--allowedTools "Read,Grep,Glob,Bash(git diff:*),Bash(git log:*),Bash(git status:*),Bash(cat:*),Bash(grep:*),Bash(sed:*),Bash(head:*),Bash(tail:*),Bash(wc:*),Bash(ls:*),Bash(find:*)"
```

Prompt:

```text
Review Magpie_M1 Phase 4.6 evidence. Concise findings only. Do not edit files. Verify evidence from repo files before giving findings. Return verdict and findings.
```

Result:

Claude Code returned JSON successfully. Verdict:

> PASS (as `coverage-delta-pass`, not sign-off) - evidence is genuine and
> honestly scoped.

Verified by Claude:

- All 17 required Phase 4.6 artifacts are present and non-empty.
- `sim.log` contains the RAS mispredict, recovery redirect, good-path
  `mmio[00000000] <= 00000406`, and PASS marker.
- The wrong-path predicted return commit marker is absent, and no `FAIL:` is
  present.
- `firmware.disasm` contains the poisoned-return pattern: predicted return
  writes `bad00bad`, actual return writes `0x406`, and `poison_ret` does
  `mv ra,t0; ret`.
- `module_delta.csv`, `ras_recovery_coverage.log`, and the report agree on
  DUT line coverage `1042/1054` with `+7` delta and DUT toggle coverage
  `8296/12246` with `+61` delta.
- The baseline chains to Phase 4.4 merged coverage:
  `1035/1054` line and `8235` normalized toggle.
- `core.v` and `ras.v` line coverage reached `100%`.
- `wave.vcd` is focused-size evidence, and the testbench gates full dump behind
  `full_vcd`.
- The report correctly keeps Phase 4.6 as `coverage-delta-pass`, not coverage
  closure or sign-off.

Caveats recorded by Claude:

1. The original producer-not-approver step had previously failed because the
   first Claude attempts produced no findings. This corrected run now serves as
   the advisory review and found no correctness issues in the evidence.
2. Coverage is still not closed: DUT line is `98.86%`, DUT toggle is `67.74%`,
   and functional coverage bins are not implemented.
3. The gate is a snapshot checker rather than a full recomputation from raw
   `coverage.dat`. This is mitigated by the internally consistent CSV/log/report
   chain and the Phase 4.4 baseline match.

Historical failed attempts:

- First fixed-session attempt timed out with no findings.
- Second retry used fixed PID `306601` and wrote
  `/tmp/magpie_m1_claude_review.out` / `.err`; both files were empty.
- Root cause was likely a combination of fixed `--session-id` reuse and CLI
  prompt parsing / headless permission setup. The corrected invocation avoids a
  fixed session id, uses stdin for the prompt, emits JSON, pins cwd/add-dir, and
  explicitly allows only read-only tools.

Codex disposition:

- Phase 4.6 remains accepted as `coverage-delta-pass`, not sign-off.
- Claude advisory review now supports that disposition with caveats.
- No RTL or verification artifacts were edited by Claude.
