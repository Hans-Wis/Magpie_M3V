# Claude Code Advisory Review Runbook

This runbook records the working headless Claude Code invocation for
read-only advisory review in Magpie_M1.

## Recommended Mode

Use an independent one-shot review for each phase unless the reviewer must
remember prior phase context.

- Recommended: omit `--session-id`; let Claude create a fresh session.
- Also valid: pass a newly generated UUID per run.
- Avoid: reusing the same fixed `--session-id` for multiple one-shot reviews.
- If a continuous review conversation is required, create the session once with
  `--session-id`, then use `--resume <uuid>` on later reviews.

## Working Invocation

Run from the Magpie_M1 root, or set both `cd` and `--add-dir` to the project
root. Feed the prompt through stdin so variadic CLI options cannot consume the
prompt argument.

```bash
cd /home/edauser/project/SOC/Magpie_M1

out=/tmp/magpie_m1_claude_review.out
err=/tmp/magpie_m1_claude_review.err
pidf=/tmp/magpie_m1_claude_review.pid
statusf=/tmp/magpie_m1_claude_review.status

: > "$out"
: > "$err"

prompt="Review Magpie_M1 Phase X.Y evidence. Concise findings only. Do not edit files. Verify evidence from repo files before giving findings. Return verdict and findings."

printf "%s\n" "$prompt" | \
  /home/edauser/.local/bin/claude -p \
    --output-format json \
    --permission-mode dontAsk \
    --allowedTools "Read,Grep,Glob,Bash(git diff:*),Bash(git log:*),Bash(git status:*),Bash(cat:*),Bash(grep:*),Bash(sed:*),Bash(head:*),Bash(tail:*),Bash(wc:*),Bash(ls:*),Bash(find:*)" \
    --add-dir /home/edauser/project/SOC/Magpie_M1 \
    > "$out" 2> "$err" &

pid=$!
printf "%s\n" "$pid" > "$pidf"
wait "$pid"
rc=$?
printf "exit_code=%s\n" "$rc" > "$statusf"
exit "$rc"
```

## Permission Boundary

`dontAsk` is safe only when paired with an explicit allow list. Without
`--allowedTools`, headless Claude may silently deny operations that would have
required a prompt, causing a review that appears to run but does not inspect the
evidence.

The standard read-only allow list is:

```text
Read,Grep,Glob,
Bash(git diff:*),Bash(git log:*),Bash(git status:*),
Bash(cat:*),Bash(grep:*),Bash(sed:*),Bash(head:*),Bash(tail:*),
Bash(wc:*),Bash(ls:*),Bash(find:*)
```

Do not allow write-capable commands for an advisory reviewer.

## Required Outputs

Every run should preserve:

- PID file: `/tmp/magpie_m1_claude_review.pid`
- JSON stdout: `/tmp/magpie_m1_claude_review.out`
- stderr: `/tmp/magpie_m1_claude_review.err`
- exit status: `/tmp/magpie_m1_claude_review.status`
- phase artifact: `flow/.../claude_review.md`

The phase artifact should record:

- invocation mode
- generated or resumed session id
- PID
- out/err/status paths
- tool allow list
- prompt
- verdict
- findings and caveats
- whether Claude edited files; advisory reviews should say no

## Validation

After the run:

```bash
cat /tmp/magpie_m1_claude_review.status
wc -c /tmp/magpie_m1_claude_review.out /tmp/magpie_m1_claude_review.err
python -m json.tool /tmp/magpie_m1_claude_review.out >/tmp/magpie_m1_claude_review.pretty.json
```

Expected success shape:

- `exit_code=0`
- stderr is empty or contains only non-fatal diagnostics
- stdout is valid JSON
- JSON `type` is `result`
- JSON `subtype` is `success`
- JSON `is_error` is `false`
- JSON includes `session_id` and `result`

## Known Failure Modes

### Fixed Session Reuse

Reusing the same fixed `--session-id` for separate one-shot reviews can fail
because the session already exists or is active. Use no `--session-id`, a new
UUID, or `--resume <uuid>` for a deliberate continuous review thread.

### Prompt Consumed by Variadic Options

Options such as `--tools` and `--allowedTools` can consume following arguments
depending on shell quoting and CLI parsing. If Claude exits with:

```text
Error: Input must be provided either through stdin or as a prompt argument when using --print
```

feed the prompt through stdin as shown above.

### Headless `dontAsk` Denials

`dontAsk` does not mean "allow everything." It means do not ask interactively.
Any operation outside the allow list may be denied, sometimes without useful
review content. Keep the allow list explicit and read-only.

### Wrong Working Directory

`claude -p` uses the current working directory as project context. If the
process starts outside Magpie_M1 and no `--add-dir` is provided, Claude may not
be able to inspect evidence files. Always `cd` to the project root or pass
`--add-dir /home/edauser/project/SOC/Magpie_M1`.

## Phase 4.6 Reference Run

The corrected Phase 4.6 run used this method and completed successfully:

- PID: `319453`
- Status: `exit_code=0`
- stderr: `0 bytes`
- stdout: valid JSON, `6157 bytes`
- Claude session: `ade64823-0a71-47b2-a34f-be41566a880e`
- Verdict: `PASS as coverage-delta-pass, not sign-off`
- Artifact:
  `flow/v2_pipeline/phase_04_06_ras_recovery_coverage/claude_review.md`
