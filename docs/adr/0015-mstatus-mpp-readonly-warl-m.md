# ADR-0015 — `mstatus.MPP` is read-only WARL = M on the M-only hart

- Status: accepted
- Date: 2026-06-09
- Deciders: Claude (PL), Grok (advisor)
- Context tools: Spyglass lint (early signoff) flagged it; Grok adjudicated.

## Context

Magpie_M1 is an **M-mode-only** RV32IMC_Zicsr_Zifencei hart (ADR-0002): no S/U mode. Previously
`mstatus.MPP` (`mstatus[12:11]`) was a writable register: a CSR write to `mstatus` stored
`new_val[12:11]` verbatim, and trap-entry/mret forced it to `2'b11`. Spyglass flagged the redundant
constant assignments (`STARC05-2.2.3.3 InitValUsingNBA`, `W415a` multiple-assignment, csr.v:196/200).

Per the RISC-V Privileged spec, for a hart that implements **only M-mode**, `MPP` is **WARL** and the
only supported value is **M (`2'b11`)** — it must read `2'b11` always, and a write of a non-M value
must **not** stick. Storing a non-M `MPP` (as the old RTL allowed) is a latent spec violation, even
though current lockstep never exercised it (the only `mstatus` writes in firmware touch `MIE`/`MPIE`,
never `MPP`).

## Decision

`mstatus.MPP` is **hardwired read-only `2'b11`** in `csr.v`. The CSR write path does **not** update
`MPP`; trap-entry / `mret` do not need to set it. `mstatus_val[12:11]` is the constant `2'b11`.

The P11 golden model and coverage are updated to match: `mstatus_val[12:11]` becomes a structural
constant (waived as `M-only MPP hardwired`). A **directed unit assertion** (write `MPP=2'b00`, read back
`2'b11`) guards the WARL behavior and catches any Spike-config drift.

## Consequences

- **+** Spec-correct (M-only WARL); the two Spyglass warnings are eliminated at the source (no reg, no
  multi-assign), not waived.
- **+** Cleaner hand-off story: "MPP is read-only constant M per spec", not "we store illegal MPP".
- **−** Behavior change (stored → constant). Verified no lockstep regression because no test writes MPP.
- **Spike**: default Spike (`rv64ima_zicsr`, U-present) would *store* a written `MPP`; a Spike-lockstep
  test that writes `MPP≠M` and reads it back would diverge. We therefore keep the WARL check as a
  **DUT-only directed assertion** (not a lockstep vector) and confirm no lockstep firmware writes MPP.
  If a future test needs through-MPP lockstep, configure Spike M-only (`--priv=m` / no-U).
