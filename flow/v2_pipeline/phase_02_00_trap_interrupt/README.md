# Phase 2.0 Trap / Interrupt

Status: `directed-sim-pass` after `tests/gates/gate_02_00_trap_interrupt.py`
passes and the directed Verilator artifacts in this directory are present.

This phase captures the current lab08e M-mode CSR, trap, MRET, and machine
external interrupt contract as Magpie_M1-owned evidence. It checks the RTL
structure, Verilator lint result, and one directed IRQ timing case targeting the
known high-risk 16-bit `mepc` path. It does not close complete CSR coverage or
architectural equivalence.

## Checked Contract

- CSR constants for `mstatus`, `mie`, `mtvec`, `mscratch`, `mepc`, `mcause`,
  `mip`, `cycle`, and `instret`.
- CSR operations `CSRRW`, `CSRRS`, `CSRRC` and immediate forms through IDU
  decode.
- `mret` decode as a legal SYSTEM instruction.
- `mtvec` direct mode with MODE bits forced to zero.
- IRQ pending generation from external pulse, `mstatus.MIE`, and `mie.MEIE`.
- Trap entry saves `mepc`, writes external-interrupt `mcause`, disables MIE, and
  clears pending when no new pulse arrives.
- Trap exit restores MIE from MPIE and sets MPIE.
- Commit-boundary IRQ handling in `core.v`, including RF/CSR side-effect
  suppression on IRQ entry.
- Redirect priority: IRQ -> MRET -> RAS mismatch -> branch predictor recovery.
- 16-bit-aware next-PC path for interrupt `mepc`.
- Illegal SYSTEM instructions latch the simplified `trap` output instead of
  entering the IRQ path.

## Directed Simulation

The directed harness instantiates `core` directly, bypassing BTN debounce so
the test can inject an external IRQ on a specific pipeline instruction.

- Target instruction: `PC=0x80`, 16-bit `c.addi s0, 1`.
- Expected interrupt return address: `mepc=0x82`.
- Expected cause: `mcause=0x8000000b`.
- Handler stores `mepc` and `mcause` to MMIO marker addresses.
- After `mret`, firmware stores resume marker `0x0000600d`.

Passing log excerpt:

```text
inject IRQ on 16-bit target pc=00000080 instr=00140413
irq entry trap_pc=00000082 mtvec=00000100
handler stored mepc=00000082
handler stored mcause=8000000b
mret resume marker=0000600d
PASS: directed IRQ on 16-bit instruction saved mepc=00000082 mcause=8000000b and mret resumed
```

## Not Closed In This Phase

- Complete CSR read/write simulation beyond the directed IRQ setup path.
- Additional IRQ timing corners, including branch/JAL/JALR interrupted commit.
- Spike lockstep.
- Google RISC-V DV.
- Line/toggle/functional coverage.

## Gate

```sh
python -m pytest tests/gates/gate_02_00_trap_interrupt.py
```

Simulation command:

```sh
make -C flow/v2_pipeline/phase_02_00_trap_interrupt -B sim.log
```
