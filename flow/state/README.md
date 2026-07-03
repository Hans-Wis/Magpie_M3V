# flow/state — Magpie_M3V (design_id = cpu_m3v)

MCP state (`*.state.json`) + `actions.jsonl` for AI Design IDE discovery.

**This directory starts EMPTY of evidence.** M3V is a full-history fork of Magpie_M1A at
tag `m1a-rtl-freeze-v1.0` (fork SHA 51a6fe0). Per `docs/M1A_DESIGN_FREEZE.md` and CLAUDE.md §9,
**M1A / M1 / M1V Tier-2 evidence is NOT claimable by cpu_m3v** — every gate, lockstep, and
coverage result must be re-earned on this line under the `cpu_m3v` identity.

- The frozen M1A scalar core under `IP/cpu_m1/` is the host; it is re-verified only as a
  scalar no-regression guard, never re-claimed as new evidence.
- All net-new ML work (GEMV TCU / TCM / DMA) lands under `IP/npu/` and earns its own gates.

`gate_00_identity_m3v` enforces this separation mechanically.
