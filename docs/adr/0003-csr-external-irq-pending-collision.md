# ADR-0003 - CSR external IRQ pending collision handling

- Status: **accepted**
- Date: 2026-06-07
- Deciders: user + Codex
- Related: ADR-0002

## Context

Magpie_M1 uses Ch2 `lab08e` as the active pipeline CPU IP baseline. During
Phase 3.1 trap/IRQ lockstep work, a directed test injected a one-cycle external
IRQ pulse on a 16-bit compressed instruction at `PC=0x80`. The test verified the
high-risk trap values:

- `mepc=0x82`, proving the interrupted compressed instruction used `PC+2`.
- `mcause=0x8000000b`, machine external interrupt.
- handler-observed `mstatus=0x80`.
- `mret` resumed at `0x82`.

The same phase exposed an IRQ pending collision in the copied lab08e CSR RTL.
The original lab08e `csr.v` used `pulse > trap_enter > hold` priority for
`ext_pending`. If `irq_external_pulse` overlaps trap entry, `ext_pending` can
remain set and the core can immediately re-enter IRQ after `mret`.

That original priority is also intentional for another case: a true new IRQ
pulse arriving in the same cycle as trap entry should not be lost. The current
Magpie_M1 input is a one-cycle pulse plus one sticky pending bit, not a full
level-based external interrupt controller with a source-visible MEIP level and
source clear/claim handshake. With only this interface, a same-cycle pulse can
be ambiguous: it may be the still-visible pulse that caused the current trap, or
it may be a second event that should remain pending.

## Decision

For the current Magpie_M1 Phase 3.1 baseline, keep the local CSR change that
gives trap-entry hardware acknowledgement priority:

```verilog
ext_pending <=
    trap_enter         ? 1'b0 :
    irq_external_pulse ? 1'b1 :
                         ext_pending;
```

This makes the directed single-IRQ compressed-instruction case deterministic and
prevents repeated IRQ after `mret`.

This is a local Magpie_M1 RTL deviation from Ch2 `lab08e`; it is not treated as
byte-identical imported RTL. The deviation must remain recorded in `ip.json`,
the verification report, and the bug taxonomy.

## Current Pulse Contract Regression

Phase 3.2 closes the current Magpie_M1 pulse contract with a directed
regression:

- a pulse sampled in the same cycle as `trap_enter` is treated as acknowledged
  with the current trap entry and is not queued as a second interrupt;
- a pulse sampled after `trap_enter` while MIE is disabled is latched pending and
  causes a second IRQ after `mret`;
- the observed Phase 3.2 sequence has exactly two IRQ entries:
  first `mepc=0x82`, second `mepc=0x84`.

The remaining architecture item is not a regression against the current pulse
contract. It is a future wrapper/interface decision: replace the pulse-only
model with an explicit external interrupt level or a claim/clear handshake in
the Magpie_M1 wrapper contract, then re-evaluate whether CSR should implement
`(pending & !trap_enter) | irq_level_or_new_event` style behavior.

## Consequences

- Phase 3.1 remains valuable evidence for the known `mepc=PC+2` compressed IRQ
  risk.
- Phase 3.1 is not full IRQ subsystem sign-off.
- `csr.v` is now local-modified relative to lab08e.
- Phase 3.2 provides a directed regression for the current pulse contract.
- A future level-based or claim/clear interrupt wrapper remains a separate
  architecture decision.

## References

- `IP/cpu_m1/rtl/csr.v`
- `~/project/lab/CPU/Ch2/lab08e/rtl/csr.v`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep`
- `flow/v2_pipeline/phase_03_02_irq_collision`
- `tests/gates/gate_03_01_trap_irq_lockstep.py`
- `tests/gates/gate_03_02_irq_collision.py`
- `docs/v2_pipeline_bug_taxonomy.md`
