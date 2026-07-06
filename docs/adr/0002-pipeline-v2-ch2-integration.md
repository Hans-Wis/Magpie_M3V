# ADR-0002 — Magpie_M1 active pipeline CPU IP from Ch2 lab08e

- Status: **accepted**
- Date: 2026-06-07
- Deciders: user + Codex
- Supersedes: ADR-0001 for active implementation scope

## Context

ADR-0001 originally kept Magpie_M1 v1 as `RV32IM_Zicsr` with an in-order
multi-cycle FSM. The project direction is now productization: turn Ch2 `lab08e`
from a lab result into the practical Magpie_M1 CPU IP. ADR-0001 remains as
history, but ADR-0002 is the active implementation baseline.

Ch2 contains several pipeline variants. `lab08e` is selected as the v2
practical IP target because it is the most complete performance-oriented lab
result:

- Source: `~/project/lab/CPU/Ch2/lab08e`
- Core: 4-stage RV32IMC + Zicsr + Zifencei pipeline
- Features: CSR, IRQ path, load-use/muldiv stall, forwarding, flush/redirect,
  branch predictor, RAS, compressed decoder, pre-fetch residue buffer
- Ch2 result: 85 MHz formal PASS, WNS +0.017 ns

`lab08b` remains a smaller RV32IM pipeline checkpoint, but the Magpie_M1 active
IP target is `lab08e`: 4-stage + BP + RAS + RV32C + pre-fetch.

## Decision

1. Supersede the ADR-0001 FSM implementation baseline. Do not pursue FSM as a
   parallel sign-off track.
2. Promote Ch2 `lab08e` as the active Magpie_M1 implementation target under
   `design/cpu_m1/rtl/`.
3. Keep the copied Ch2 RTL as an integrated target reference. It is not yet
   qualified as Magpie_M1 sign-off RTL until wrappers, commit trace, DV,
   coverage, lint, and PPA gates close.
4. Active ISA scope is `RV32IMC_Zicsr_Zifencei`.
5. Require a pipeline gate plan before qualifying this variant:
   - interface wrapper to Magpie_M1 `imem/dmem valid-ready` contract,
   - directed pipeline hazard/forwarding/stall/flush tests,
   - directed RV32C/pre-fetch/RAS/BP tests,
   - Spike lockstep using a single RV32IMC architectural commit stream,
   - line/toggle/function coverage closure,
   - lint/synth/PPA review.
6. Require a complete Magpie_M1 verification report; copied Ch2 results are
   provenance and comparison data, not Magpie_M1 qualification evidence.
7. Use `lab08b` only as a reduced checkpoint/debug reference, not as a second
   product line.

## Entry Criteria

- ADR-0002 accepted and `gate_00_spec` aligned to the active lab08e scope.
- Ch2 lab08e provenance and copied files are recorded in the IP metadata.
- The full verification report shell exists and states copied RTL is not
  qualification evidence.

## Exit Criteria

- Pipeline wrapper matches the CPU IP memory/interface contract.
- Pipeline tests cover:
  - compressed instruction decode and PC +2/+4 behavior,
  - cross-boundary pre-fetch and fallback,
  - RAS return prediction and recovery,
  - branch predictor update and redirect,
  - RAW forwarding,
  - load-use stall,
  - mul/div busy stall,
  - branch/jump redirect,
  - flush and wrong-path suppression,
  - CSR/trap/IRQ commit-boundary behavior.
- Spike lockstep passes for supported directed/random programs.
- Line coverage is 100%, or every uncovered line has reason, reachability,
  closure plan or waiver.
- No unwaived high/critical lint issue.
- `docs/v2_pipeline_full_verification_report.md` is complete and points to
  Magpie_M1-owned logs, VCDs, coverage, lint/PPA reports, waivers, and rerun
  commands.

## Consequences

- The project now has one active CPU IP productization line: Ch2 `lab08e`.
- Pipeline hazards/forwarding/flush/RV32C/pre-fetch/RAS/BP are mandatory
  qualification gates.
- ADR-0001 is superseded for implementation and kept only for historical
  context.
- Ch2 `lab08e` is now the active practical IP target; `lab08b` remains useful as a
  reduced RV32IM checkpoint for debug.
- Copying lab08e RTL into the IP tree is only the integration starting point.
  Qualification requires Magpie_M1-owned verification evidence and a complete
  verification report.

## References

- `~/project/lab/CPU/Ch2/lab08e/README.md`
- `~/project/lab/CPU/Ch2/lab08e/rtl`
- `~/project/lab/CPU/Ch2/lab08b/README.md` — reduced RV32IM checkpoint
- `docs/adr/0001-isa-scope.md`
