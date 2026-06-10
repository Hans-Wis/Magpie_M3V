# Phase 3.1 Trap / IRQ Lockstep

Status: `trap-irq-lockstep-pass` after `make -C flow/v2_pipeline/phase_03_01_trap_irq_lockstep -B trap_irq_lockstep.log`
and `tests/gates/gate_03_01_trap_irq_lockstep.py` pass.

This phase extends the bounded Spike lockstep path into the high-risk
compressed-instruction interrupt case.

## Checks

- Prefix commits before IRQ match Spike on `pc`, `instr`, `rd`, and `wdata`.
- IRQ is injected while the 16-bit instruction at `PC=0x80` is active.
- Trap event saves `mepc=0x82`.
- Handler observes `mcause=0x8000000b`.
- Handler observes `mstatus=0x80` after MIE is stacked into MPIE and MIE is
  cleared.
- `mret` resumes to `0x82`.

## Limits

- Spike is used for the pre-IRQ commit prefix. External IRQ timing is checked
  by a deterministic expected-event model.
- This is not random DV, full CSR lockstep, or coverage closure.
