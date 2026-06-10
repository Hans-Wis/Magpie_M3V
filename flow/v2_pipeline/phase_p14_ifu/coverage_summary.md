# P14 IFU Unit Coverage Summary

Gate: `gate_01_14_ifu_unit`

Status: **not green**. Directed standalone unit stimulus passes and closes IFU
line, condition, and branch coverage in both Verilator and VCS/URG. Raw DUT
toggle coverage remains below the 95% target only because VCS counts constant
bits of the local `pc_inc` wire; those bits are structurally hardwired by the
RTL expression cited below. No PC/target bus bits are waived.

## Commands

```sh
cd flow/v2_pipeline/phase_p14_ifu
make clean verilator urg
```

## Results

- Verilator vector result: `PASS: ifu unit 125/125 vectors`
- VCS vector result: `PASS: ifu unit 125/125 vectors`
- Verilator annotated `ifu.v` line records: `3/3 = 100.00%`
- Verilator annotated `ifu.v` toggle line records: `14/14 = 100.00%`
- VCS/URG `ifu` line: `3/3 = 100.00%`
- VCS/URG `ifu` condition: `10/10 = 100.00%`
- VCS/URG `ifu` branch: `9/9 = 100.00%`
- VCS/URG `ifu` raw toggle: `402/462 bits = 87.01%`
- VCS/URG `ifu` port toggle: `334/334 bits = 100.00%`
- VCS/URG `ifu` toggle excluding structural `pc_inc` constants:
  `402/402 bits = 100.00%`
- VCS/URG FSM: not reported; URG emitted `Warning-[UCAPI-SNF] Shape Not Found`
  because `ifu.v` has no explicit encoded FSM shape.

## Stimulus Notes

- `tb_ifu_unit.v` is a clocked standalone IFU unit testbench with an independent
  golden model for PC reset, PC hold, PC mux priority, and sequential PC
  increment.
- Sequential fetch covers both RV32I `+4` and RV32C `+2` increments through the
  public `is_16bit` input.
- Redirect, RAS, and BP target paths are each selected independently, and mux
  priority is checked for redirect over stall/RAS/BP, stall over RAS/BP, and RAS
  over BP.
- Unit-scope PC and target buses are treated as free inputs. The stimulus drives
  full-range targets including walking-1 values, `32'hFFFF_FFFC`,
  `32'hAAAA_AAAA`, `32'h5555_5555`, complemented RAS targets, and BP targets
  XORed with `32'hA5A5_5A5A`.
- Halfword PC cases use redirect targets with `PC[1]=1`, then verify both
  RV32C `+2` progression and `+4` fallback progression from that state.
- Top-of-address-space wrap cases check `32'hFFFF_FFFC + 4` and
  `32'hFFFF_FFFE + 2`.

## Uncovered Classification

STRUCTURAL:

- VCS raw toggle misses `pc_inc[0]` and `pc_inc[31:3]`. These are hardwired by
  `wire [31:0] pc_inc = is_16bit ? 32'd2 : 32'd4;` at
  `IP/cpu_m1/rtl/ifu.v:50`: bit 1 toggles for `+2`, bit 2 toggles for `+4`,
  and all other bits are constant zero. This accounts for the raw DUT toggle
  shortfall from `462` total bits to the reachable `402` non-structural bits.

REACHABLE-still-uncovered:

- None in final `ifu` module line, condition, branch, port-toggle, `pc_reg`, or
  non-structural toggle coverage.

INTEGRATION-DEFERRED:

- Cross-boundary prefetch residue assembly and real fetch-response handshake
  timing are not implemented in `IP/cpu_m1/rtl/ifu.v`. The standalone IFU only
  contains PC state, PC increment, and PC mux logic at `IP/cpu_m1/rtl/ifu.v:47`
  through `IP/cpu_m1/rtl/ifu.v:60`. Residue assembly/fallback with instruction
  memory response timing must be covered by the P16 core IF slice.

No address bits are waived on firmware-range or memory-map grounds. The earlier
Gemini 16KB rationale is not used here because `redirect_target`,
`ras_predict_target`, and `bp_predict_target` are public unit-scope inputs and
all their bits are controllable in this bench.

Token record: no active Codex goal token budget was available from the runtime
for this turn.
