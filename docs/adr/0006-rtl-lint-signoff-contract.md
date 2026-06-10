# ADR-0006 — Stage 5.0 RTL lint sign-off contract (Spyglass)

- Status: Proposed (2026-06-08) — staged while stage 2.1 (mem_wrapper) is in flight;
  promote to Accepted once `cpu_m1_top` lands and gate_02_01 is green.
- Deciders: Claude (architect), User
- Flow stage: 5.0 `lint` (gate_05_00_lint)
- Depends on: ADR-0005 (the lint top is `cpu_m1_top`).

## Context

All gates through stage 4 are coverage/lockstep on the bare `core`. Before any
synth/PPA the IP needs an RTL lint sign-off. Spyglass is licensed; per platform
ADR-0008/0009 it may run directly on a host that has the tool+license (no
sandbox), but every run must record provenance + log/state for the IDE, and the
producer must not self-approve its own report (platform-0007).

History (X6 slice 26): a `parse_spyglass` false-pass bug (regex matched singular
"error" not "errors") once green-washed a real FAIL. The condense/parse step is
a known risk surface here.

## Decision

1. **Lint top = `cpu_m1_top`** (post-2.1 wrapper), with the full ch2_lab08e
   filelist + `cpu_m1_top.v`. Single clock, single reset → CDC is trivial but
   the goal is still run for evidence, not skipped.
2. **Goals**: `lint/lint_rtl` + STARC (`lint/lint_turbo` or methodology STARC
   policy). morelint is advisory-only (X6 showed morelint generates large noise
   counts); morelint findings are triaged, not blocking.
3. **Verdict rule (faithful)**: blocking = any unwaived **error/fatal** in base
   lint or STARC. Warnings + morelint = advisory, listed not blocking. If
   Spyglass/license is absent → status `waived/unavailable`, never faked green.
4. **Waivers**: every waiver needs a one-line reason + ADR reference; no blanket
   waivers. Waiver file committed under the phase dir.
5. **Parse safety**: the condense step must count plural-aware
   (`\b\d+\s+error(s)?\b`) and cross-check the Spyglass summary line against the
   moresimple per-rule table — do not trust a single regex (X6 lesson).
6. **Roles (co-work)**: Codex runs Spyglass + produces raw moresimple/log
   (own tokens); Gemini condenses to a violation-class table; Claude triages
   classes → waiver/fix and writes the verdict; Codex does not approve its own
   IDE report.

## Gate (gate_05_00_lint)

- Assert the Spyglass run artifacts exist (cmd log, moresimple report, provenance).
- Parse error/fatal counts plural-safely; verdict per §3.
- `pipeline.record_step(... stage="lint", gate="gate_05_00_lint" ...)` with
  status pass/fail/waived and the provenance (tool version, host, command).

## Consequences

- First licensed-EDA step on the M1 line; needs a host with Spyglass+license.
- CDC is near-trivial now (single clock) but the goal-run leaves an audit trail
  for when async crossings appear (e.g., a future bus/peripheral).
- Synth/PPA (stage 5.1, DC, TSMC 28HPC+) follows in a separate ADR once lint is
  clean or waived.
