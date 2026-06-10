# ADR-0014 — Independent IP-deliverable structure (rtl / dv / sim)

- Status: Accepted (2026-06-09)
- Deciders: User (directive), Claude (PL). Refs: docs/reports/customer_signoff_strategy.md (3-agent),
  ADR-0012 (two-SKU), ADR-0002 (lab08e integration provenance).

## Context
The active RTL lived under `IP/cpu_m1/rtl/pipeline_v2/ch2_lab08e/` — a path carrying lab heritage —
while `IP/cpu_m1/dv/{tb,sim}` and `dv/fixtures/` were empty shells; all DV/sim lived inside
`flow/v2_pipeline/phase_*` (development record). The 3-agent customer-standard review (Grok/Codex/
Gemini) flagged this "dv/ empty packaging gap": there was no curated, independently-deliverable IP
structure to hand a customer.

## Decision
Reorganize the cpu_m1 IP into a clean, independently-deliverable structure with three pillars:

```
IP/cpu_m1/
├── rtl/                 ← flat deliverable RTL (16 modules + def.vh), extracted from ch2_lab08e
│   ├── *.v, def.vh
│   ├── filelist.f, cpu_m1.f   single source of truth
│   └── variants/ch2_lab08b/   roadmap-reference variant (RV32IM, kept for provenance)
├── dv/                  ← verification deliverable (curated from flow/)
│   ├── tb/  lib/  cov/  tests/  vplan/
│   └── vplan/VPLAN.md + DV_SIGNOFF_CHECKLIST.md
├── sim/                 ← build/run filelist (rtl + dv tb)
└── docs/                spec + (future) databook/integration-guide
```

- RTL extracted from `rtl/pipeline_v2/ch2_lab08e/` to a flat `rtl/`; lab08b → `rtl/variants/`.
  The lab08e *origin* is retained as provenance in `ip.json` variant metadata (clean-room discipline),
  but the deliverable path no longer carries the lab name.
- All 56 references (Makefiles, gates, runners, .sh, filelists, ip.json) updated `rtl/pipeline_v2/
  ch2_lab08e` → `rtl`. **Full gate suite re-verified: 189 passed / 1 xfailed (no regression).**
- `flow/v2_pipeline/phase_*` remains the executable development record; `dv/` + `sim/` are the curated
  hand-off view (copies of canonical TB/comparator/coverage + V-Plan + signoff checklist).

## Consequences
- Positive: cpu_m1 is now an independently-navigable IP deliverable (rtl/dv/sim) addressing the
  packaging gap; V-Plan + DV signoff checklist exist (honest status). Closes a Tier-1 deliverable item.
- Accepted: dv/ curated artifacts are COPIES of flow/ canonical files (single-source-of-truth remains
  flow/ for execution); a future step may invert this (dv/ canonical, flow/ consumes) once the
  deliverable TB is the one-button regression.
- ip.json variant `v2_pipeline_ch2_lab08e` key kept (provenance); RTL path is clean.
