# P08 div unit coverage summary

Status: implemented and measured. Do not mark gate green.

## Stimulus

- Standalone clocked TB: `IP/cpu_m1/dv/tb/tb_div_unit.v`
- DUT: `IP/cpu_m1/rtl/div.v`
- Operations: `DIV`, `DIVU`, `REM`, `REMU`
- Golden: independent RV32 division/remainder model using explicit RISC-V divide-by-zero and signed-overflow special cases before mathematical signed/unsigned `/` and `%`
- Operand matrix: all four ops, signed quadrants, divide-by-zero, signed overflow, small/large/equal/divisor-greater classes, quotient-width classes, walking-bit operands, deterministic LCG randoms
- Handshake: reset, idle soak, start/done, start while WORK ignored, start while DONE ignored, back-to-back transactions, reset from WORK, reset from FIXUP

## Results

- Verilator PASS: `PASS: div unit 3249/3249 vectors`
- VCS PASS: `PASS: div unit 3249/3249 vectors`

## Coverage

### Verilator, module `div`

- Line: `72/73`, `98.63%`
- Toggle: `685/686`, `99.85%`

Uncovered Verilator points:

- `div.v:134 default: state <= IDLE;` is not executed.
  Proposed waiver, not applied: `{"design_id":"cpu_m1","leaf":"P08_div","metric":"line","hierarchy":"div.state_default","structural_basis":"state_is_2bit_and_all_four_encodings_are_named_legal_states_IDLE_WORK_FIXUP_DONE","waiver":"exclude","reviewer":"TBD","date":"2026-06-09"}`
- `md_op[2]` does not toggle in either direction. Valid divider opcodes are `3'b100` through `3'b111`, so bit 2 is structurally constant high for this leaf.
  Proposed waiver, not applied: `{"design_id":"cpu_m1","leaf":"P08_div","metric":"toggle","hierarchy":"div.md_op[2]","structural_basis":"valid_divider_opcode_set_has_md_op_bit2_constant_one","waiver":"exclude","reviewer":"TBD","date":"2026-06-09"}`

### VCS / URG, module `div`

- Line: `41/42`, `97.62%`
- Branch: `19/20`, `95.00%`
- Condition/expression: `71/71`, `100.00%`
- Toggle bits: `684/686`, `99.71%`
- FSM state: `4/4`, `100.00%`
- FSM arc/transition: `6/6`, `100.00%`

Uncovered VCS/URG points:

- `div.v:134 default: state <= IDLE;` is the only uncovered line and the only uncovered branch target.
  Proposed waiver, not applied: `{"design_id":"cpu_m1","leaf":"P08_div","metric":"branch","hierarchy":"div.state_default","structural_basis":"state_is_2bit_and_all_four_encodings_are_named_legal_states_IDLE_WORK_FIXUP_DONE_no_illegal_binary_encoding_exists","waiver":"exclude","reviewer":"TBD","date":"2026-06-09"}`
- `md_op[2]` toggle is uncovered. Same structural basis as Verilator.

## FSM Coverage

Actual RTL FSM map from `div.v`:

- `S_IDLE` in charter maps to RTL `IDLE`.
- `S_RUN` in charter maps to RTL `WORK`.
- `S_DONE` in charter maps to RTL `DONE`.
- `S_ZERODIV` is not a state in RTL; divide-by-zero is latched in `IDLE`, iterates through `WORK`, and selects the special result in `FIXUP`.
- RTL adds `FIXUP`, a one-cycle result select state.

URG FSM states:

- `IDLE`: covered
- `WORK`: covered
- `FIXUP`: covered
- `DONE`: covered

URG FSM transitions:

- `IDLE->WORK`: covered
- `WORK->FIXUP`: covered
- `FIXUP->DONE`: covered
- `DONE->IDLE`: covered
- `WORK->IDLE`: covered by reset while in WORK
- `FIXUP->IDLE`: covered by reset while in FIXUP

Charter arc inventory:

- A0 `S_IDLE->S_RUN`: covered as `IDLE->WORK`, 3251 hits
- A1 `S_IDLE->S_ZERODIV`: structural, no RTL `S_ZERODIV`; zero-div vectors map to `IDLE->WORK`
- A2 `S_IDLE->S_IDLE`: covered, 3263 hits
- A3 `S_RUN->S_RUN`: covered as `WORK->WORK`, 100750 hits
- A4 `S_RUN->S_DONE`: covered as `WORK->FIXUP->DONE`, 3249 hits
- A5 divisor==1 early-out: RTL has no early-out; predicate covered, 349 hits through normal `WORK->FIXUP`
- A6 dividend==0 early-out: RTL has no early-out; predicate covered, 177 hits through normal `WORK->FIXUP`
- A7 `|dividend| <= |divisor|` early-out: RTL has no early-out; predicate covered through normal `WORK->FIXUP`
- A8 signed overflow: covered, 12 hits through normal `WORK->FIXUP`
- A9 `S_DONE->S_IDLE`: covered as `DONE->IDLE`, 3249 hits
- A10 direct `S_DONE->S_RUN`: structural/unreachable; `DONE` ignores `start` and always returns to `IDLE`
- A11 `S_ZERODIV->S_DONE`: structural map to `FIXUP->DONE`; covered, 3249 hits
- A12 `S_ZERODIV->S_IDLE`: structural map to `DONE->IDLE`; covered, 3249 hits
- A13 signed/unsigned opcode mux on launch: covered as `IDLE->WORK`, 3251 hits
- A14 signed restore/remainder-negative internal loop: covered through signed WORK loop vectors, 100750 loop hits
- A15 unsigned borrow/no-subtract internal loop: covered through unsigned WORK loop vectors, 100750 loop hits

Proposed FSM structural waiver candidates, not applied:

- `{"design_id":"cpu_m1","leaf":"P08_div","metric":"fsm_arc","arc":"IDLE->ZERODIV","structural_basis":"rtl_has_no_zero_div_state_zero_div_flag_is_processed_via_WORK_FIXUP","waiver":"exclude","reviewer":"TBD","date":"2026-06-09"}`
- `{"design_id":"cpu_m1","leaf":"P08_div","metric":"fsm_arc","arc":"DONE->WORK","structural_basis":"DONE_case_unconditionally_sets_state_IDLE_and_ignores_start","waiver":"exclude","reviewer":"TBD","date":"2026-06-09"}`

## Commands

```sh
cd flow/v2_pipeline/phase_p08_div
make verilator
make urg
```

## Token Record

No active Codex goal/token budget was available from the session goal tool.
