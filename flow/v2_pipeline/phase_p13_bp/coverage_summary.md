# P13 BP Unit Coverage Summary

Gate: `gate_01_13_bp_unit`

Status: **not green**. Directed standalone unit stimulus passes and closes BP
line, condition, branch, and toggle coverage in both Verilator and VCS/URG.
This report records the measured result only; no waiver is requested or applied.

## Commands

```sh
cd flow/v2_pipeline/phase_p13_bp
make clean verilator urg
```

## Results

- Verilator vector result: `PASS: bp unit 1318/1318 vectors`
- VCS vector result: `PASS: bp unit 1318/1318 vectors`
- Verilator `bp.v` line records: `59/59 = 100.00%`
- Verilator `bp.v` branch/toggle records: `899/899 = 100.00%`
- Verilator `bp.v` toggle-filter records: `872/872 = 100.00%`
- VCS/URG `bp` line: `22/22 = 100.00%`
- VCS/URG `bp` condition: `56/56 = 100.00%`
- VCS/URG `bp` branch: `19/19 = 100.00%`
- VCS/URG `bp` toggle: `424/424 bits = 100.00%`
- VCS/URG FSM: not reported; URG emitted `Warning-[UCAPI-SNF] Shape Not Found`
  because `bp.v` has no explicit encoded FSM shape.

## Stimulus Notes

- `tb_bp_unit.v` is a clocked standalone BP unit testbench with an independent
  golden predictor model for valid, tag, target, LRU, and 2-bit counters.
- The test drives all 32 implemented sets and both ways using only public
  predict/update ports.
- The test repeatedly aliases each set with distinct tags, including all-zero,
  all-one, alternating, high-address, and `0xFFFF_FFxx`-class PCs.
- Targets include full-width patterns such as walking low bits,
  `32'hFFFF_FFFC`, `32'hDEAD_BEEF`, `32'hAAAA_AAAA`, `32'h5555_5555`,
  `32'h8000_0000`, and `32'h7FFF_FFFC`.
- Both replacement directions are exercised through LRU miss selection, both
  ways are hit-updated, valid bits are set by update and cleared by reset, and
  the 2-bit saturating counters visit strongly/weakly taken and not-taken
  states.

## RTL Index Note

The source header says the predictor is indexed by `PC[6:2]`, but the
implemented RTL uses:

- `IDX_LSB = 1` at `IP/cpu_m1/rtl/bp.v:46`
- `rd_idx = if_pc[IDX_LSB +: IDX_BITS]` at `IP/cpu_m1/rtl/bp.v:69`
- `wr_idx = upd_pc[IDX_LSB +: IDX_BITS]` at `IP/cpu_m1/rtl/bp.v:85`

Therefore the measured hardware index is `PC[5:1]`. The unit stimulus covers
all 32 physical indices of the implemented RTL and also toggles the ignored
`if_pc[0]`/`upd_pc[0]` port bits.

## Uncovered Classification

STRUCTURAL:

- None in final `bp` module coverage.

REACHABLE-still-uncovered:

- None in final `bp` module coverage.

No array, tag, target, set, counter, valid, or LRU bits are waived. The earlier
Gemini 16KB-map rationale is not used here because `valid0/1`, `tag0/1`,
`target0/1`, `counter0/1`, and `lru` are real unit-scope flops declared at
`IP/cpu_m1/rtl/bp.v:54` through `IP/cpu_m1/rtl/bp.v:64` and written from the
public update path at `IP/cpu_m1/rtl/bp.v:127` through
`IP/cpu_m1/rtl/bp.v:137`.

Token record: no active Codex goal token budget was available from the runtime
for this turn.
