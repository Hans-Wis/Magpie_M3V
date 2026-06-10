# Phase 1.2 Decode / Execute RV32IMC

Status: structural-lint-pass target, not yet directed-sim-qualified.

This phase fixes the first Magpie_M1-owned decode/execute contract for the
active Ch2 lab08e target:

- RV32I decode controls and immediate formats in `idu.v`
- ALU operation coverage and fast branch comparators in `alu.v`
- x0 invariant and 2R1W register-file contract in `rfu.v`
- RV32M multiply/divide datapaths and RISC-V corner behavior in `mul.v`/`div.v`
- core integration for decode, execute, mul/div stall, writeback, and RF write

Current evidence:

- `tests/gates/gate_01_02_decode_execute_rv32imc.py`
- Verilator lint-only on local lab08e RTL top `core`

Not yet closed:

- Directed RV32I/M/C simulation suite
- Python commit checker / scoreboard
- Spike lockstep
- Line/toggle/functional coverage
