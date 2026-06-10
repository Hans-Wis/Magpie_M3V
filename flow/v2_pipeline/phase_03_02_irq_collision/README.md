# Phase 3.2 - IRQ Collision Contract Directed Regression

Purpose: qualify the local Magpie_M1 external IRQ pulse contract introduced by
ADR-0003.

This phase is not a Spike lockstep phase. It is a directed Verilator regression
for collision semantics around the CSR `ext_pending` latch:

- a pulse sampled in the same cycle as `trap_enter` is treated as acknowledged
  with that trap entry and is not queued as a second interrupt;
- a pulse sampled after `trap_enter` while M-mode interrupts are disabled is
  latched pending and causes a second IRQ after `mret` restores MIE.

The test intentionally uses the current pulse-based Magpie_M1 IRQ input. A
future level-sensitive or claim/clear interrupt wrapper may replace this
contract and should update ADR-0003.

Run:

```sh
make -C flow/v2_pipeline/phase_03_02_irq_collision -B sim.log
python -m pytest tests/gates/gate_03_02_irq_collision.py
```

Expected result:

```text
PASS: IRQ collision contract validated
```
