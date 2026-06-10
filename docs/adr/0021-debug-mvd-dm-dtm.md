# ADR-0021 — RISC-V Debug MVD (Debug Module + DTM)

- Status: accepted (design); implementation gated by no-regression + OpenOCD smoke
- Date: 2026-06-10
- Deciders: Claude (PL), Grok (core debug-mode advice). Adapts first-party **Magpie_X1 ADR-0025** + reuses
  X1's `rtl/debug/dm.v`/`dtm.v` (Magpie first-party). Permissive references (ibex Apache-2.0, Rocket
  Apache-2.0) observed for the debug-mode pattern per the new license-compliant-reuse policy (ADR-0001).

## Context

M1 has no external debug — only observe-only `dbg_pc/instr/state`. Real productization needs JTAG/OpenOCD/
GDB. The whole MVD was already designed + implemented first-party in Magpie_X1 (ADR-0025, RV64); this ADR
adapts it to M1 (RV32IMC, M-only, 4-stage).

## Decision — two slices (per X1 ADR-0025)

### Slice A — DM + DMI-direct + core debug-mode (the delicate core part)
- **csr.v** (I lead): add **dcsr (0x7B0)** {cause, step, ebreakm, prv=M}, **dpc (0x7B1)**, **dscratch0
  (0x7B2)**, **dret** support (port from X1 `csru.v`). RV32: data halves vs X1's 64-bit.
- **core.v debug-mode** (I lead, per Grok): one `debug_mode` flop.
  1. **Halt entry**: latch `dm_halt_req`, enter debug **only on a valid WB retire** (reuse the existing
     `wb_take_irq` valid-commit gate); **`dpc ← pc_next`** (next architectural PC, like mepc); set
     `debug_mode`, flush IF/ID/EX/MEM, redirect/idle fetch. Never double-commit, never lose a branch.
  2. **Debug mode**: IRQ masked; `ebreak` mux — `!debug_mode` → existing `MCAUSE_BREAKPOINT`; `debug_mode`
     → no trap, stay/re-enter (ebreakm). SW breakpoints (ebreak) cover GDB.
  3. **dret**: `debug_mode←0`, `pc←dpc`, mret-style flush; no MPP/MIE restore; arm `step_pending` if
     `dcsr.step`.
  4. **Single-step**: allow exactly one `wb_valid` retire then re-halt before the next reaches WB; `dpc`
     from the commit PC+len (not stale IF/EX redirect; C cross-boundary uses commit length).
  5. **Abstract GPR/CSR**: **direct backdoor** while halted (DM `acc_en/regno/wdata/rdata` → regfile +
     CSR ports; pipeline idle) — no program buffer for MVD (X1's proven approach).
- **dm.v** (Codex, adapt X1 first-party): DMI (7b-addr/32b-data) + dmcontrol/dmstatus/hartinfo/abstractcs/
  command(cmdtype=0 access-register)/data0..1 + the `acc` backdoor to the core. RV32 (aarsize=2).
- **Cosim** (Codex): `dm_cosim.py` — DMI R/W + halt/resume/step/read-reg; directed test: halt → read x1/
  pc → write x2 → resume; step N.

### Slice B — JTAG TAP (DTM) + OpenOCD
- **dtm.v** (Codex, adapt X1): JTAG TAP FSM + IR/DR + IDCODE/DTMCS/DMI (spec §6); TCK/TMS/TDI/TDO.
- OpenOCD remote-bitbang smoke: `halt; resume; reg x1; step` against the FPGA/sim. (Install OpenOCD.)

### Out of scope (V3)
Trigger module (mcontrol6 HW breakpoints), system-bus access (SBA), program buffer, multi-hart.

## Verification (mandatory)
- **Highest-risk corner first** (Grok): `dm_halt_req` while EX/MEM has a redirect + WB retiring a
  predecessor → no double-commit, no lost branch, `dpc` = architecturally-next PC (the 4-stage + predictor
  + C-prefetch hardest case — same subsystem as the cross-boundary bugs).
- DMI-direct directed: halt/resume/step/read+write GPR+CSR.
- OpenOCD smoke (Slice B). **No regression**: 273 gates + arch-test 74/74 + CLINT/PLIC/UART directed.

## Provenance (license-compliant reuse, ADR-0001)
- `dm.v`/`dtm.v` adapted from **Magpie_X1** (first-party) — origin `adapted`, X1 ADR-0025 + commit recorded.
- Core debug-mode pattern: original M1 RTL informed by X1 + ibex (Apache-2.0) — origin `original`.
- OpenOCD = external host tool (BSD/GPL host-side, not in the IP deliverable).

## Consequences
- **+** Real JTAG/OpenOCD/GDB debug → major productization step; the FPGA bitstream becomes debuggable.
- **−** Most invasive core change yet (debug = internal mode state, halt-at-boundary, step). Delicate;
  PL-led core part + full re-verify. Mitigated by heavy first-party (X1) reuse + Grok-validated design.
