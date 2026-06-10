# P07 mul unit coverage summary

Status: implemented and measured. Do not mark gate green.

## Stimulus

- Standalone clocked TB: `IP/cpu_m1/dv/tb/tb_mul_unit.v`
- DUT: `IP/cpu_m1/rtl/mul.v`
- Operations: `MUL`, `MULH`, `MULHU`, `MULHSU`
- Operand classes: sign combinations `++`, `+-`, `-+`, `--`; corner magnitudes; walking-bit operands; deterministic LCG randoms
- Handshake: reset, start, wait for done, read result, back-to-back transactions, and start-while-busy ignored case
- Golden: independent 64-bit RV32 product model with low/high result selection by operation

## Results

- Verilator PASS: `PASS: mul unit 2321/2321 vectors`
- VCS PASS: `PASS: mul unit 2321/2321 vectors`

## Coverage

### Verilator, module `mul`

- Line: `3/3`, `100.00%`
- Toggle: `610/612`, `99.67%`

Uncovered Verilator toggle points:

- `md_op[2]:0->1`
- `md_op[2]:1->0`

This is structural for the requested RV32 multiply operations: valid multiply `md_op` values are `3'b000` through `3'b011`, so `md_op[2]` is unreachable without driving non-multiply encodings into the multiplier. All `product_w[65:0]` bits toggled in both directions.

### VCS/URG, module `mul`

- Line: `18/18`, `100.00%`
- Branch: `10/10`, `100.00%`
- Condition/expression: `20/20`, `100.00%`
- Toggle bits: `610/612`, `99.67%`

## Commands

```sh
cd flow/v2_pipeline/phase_p07_mul
make verilator
make urg
```

## Token Record

No active Codex goal/token budget was available from the session goal tool.
