# P12 RAS Unit Coverage Summary

Gate: `gate_01_12_ras_stateful`

Status: **not marked green**. Directed standalone unit stimulus passes and closes
RAS RTL line and toggle coverage without waivers.

## Command

```sh
cd flow/v2_pipeline/phase_p12_ras
make clean verilator urg
```

## Results

- Verilator vector result: `PASS: ras unit 126/126 vectors`
- VCS vector result: `PASS: ras unit 126/126 vectors`
- Verilator `ras.v` line: `24/24 = 100.00%`
- Verilator `ras.v` toggle points: `660/660 = 100.00%`
- Verilator upper-bit check for `push_val[31:14]`, `ras_top[31:14]`,
  and `stack[0:7][31:14]`: `360/360 = 100.00%`
- VCS/URG `ras` line: `100.00%`
- VCS/URG `ras` cond: `100.00%`
- VCS/URG `ras` branch: `100.00%`
- VCS/URG `ras` toggle: `100.00%`
- VCS FSM: not reported; URG emitted `Warning-[UCAPI-SNF] Shape Not Found`
  because `ras.v` has no explicit encoded FSM register.

## Stimulus Notes

- Independent golden stack model mirrors the implemented 3-bit circular pointer,
  including reset, push, pop, empty pop, natural wrap, overwrite, and same-cycle
  push+pop semantics.
- Full-width payload coverage now treats `push_val` as a free unit input:
  all eight physical stack slots receive `32'hFFFF_FFFF` followed by
  `32'h0000_0000`.
- Walking-1 and complement stimulus drives `(32'h1 << i)` and
  `~(32'h1 << i)` for `i = 0..31`.
- Fixed full-range payloads are also pushed:
  `32'hFFFF_FFFC`, `32'hDEAD_BEEF`, `32'hAAAA_AAAA`, `32'h5555_5555`,
  `32'h8000_0000`, and `32'h7FFF_FFFC`.
- The existing depth-8 fill, empty pop, visible LIFO pop sweep, wrap/overwrite,
  and same-cycle push+pop coverage remains in place.

## Uncovered Toggles

None observed in final Verilator `ras.v` toggle enumeration.

Token record: no active Codex goal token budget/counter was available in this
session (`get_goal` returned `goal: null`).
