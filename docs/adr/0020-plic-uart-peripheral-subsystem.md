# ADR-0020 — PLIC + UART peripheral subsystem

- Status: accepted (design); implementation gated by 273-gate no-regression
- Date: 2026-06-10
- Deciders: Claude (PL); reuses first-party Magpie_X3 PLIC/UART RTL
- Extends ADR-0018 (subsystem) + ADR-0019 (CLINT). Completes the M1 peripheral subsystem.

## Context

ADR-0019 added CLINT (MTIP/MSIP). The remaining standard embedded peripherals are **PLIC** (external
interrupt routing → MEIP) and **UART** (console). The first-party X3 RTL (`plic.v`, `uart.v`) is native-bus
(`en/addr/wstrb/wdata/rdata`) = M1-dbus-compatible. The X3 PLIC was *designed* to OR `meip_o` into the
core's `mip[11]` — exactly M1's need.

## Decision

1. **MEIP level path** (core change, done): csr.v gains a `meip` level input; `mip[11]` pending =
   `ext_pending | meip` (legacy pulse-sticky **OR** PLIC level). `irq_mei = (ext_pending|meip) & MEIE`.
   The PLIC's level `meip_o` cannot use the legacy pulse path (edge-detect fires once); the level path is
   required. Bare core ties `meip=0` (backward compatible). core.v gains a `meip` input → csr.
2. **Peripheral blocks**: instantiate X3 `plic.v` + `uart.v` on the D-bus behind an `addr_decoder`.
   Memory map: RAM `0x2000_0000`, CLINT `0x0200_0000`, **PLIC `0x0C00_0000`**, **UART `0x1000_0000`**.
3. **Wiring**: `plic.meip_o → core.meip`; CLINT `mtip/msip → core`; UART `tx_irq_o` is a PLIC source
   (interrupt-driven console) and `tx_byte_o/tx_strobe_o` drive the serial out. Subsystem top
   `cpu_m1_soc_top` (extends `cpu_m1_clint_top`).
4. **MEIP claim/complete**: SW services the external interrupt via the PLIC claim/complete registers;
   `meip_o` (hence `mip[11]`) deasserts when no source is pending+enabled — no trap-entry auto-clear of
   the level (unlike the legacy sticky `ext_pending`).

## Verification

- Directed PLIC: assert an external source → `meip_o` → `mip[11]` → trap `mcause=0x8000_000B` → handler
  claims/completes → `meip` deasserts → mret. PASS.
- Directed UART: THR write → `tx_strobe_o`/`tx_byte_o` emits the byte; TB captures the string.
- Full subsystem boot: program drives UART + takes a PLIC interrupt.
- **No regression**: 273 gates + arch-test 74/74 + CLINT directed unchanged (propagate `meip=0` to all
  core/cpu_m1_top/csr instances — miss none → x-prop false fail).

## Consequences

- **+** Completes a usable embedded SoC: CPU + memory + boot ROM + CLINT + PLIC + UART — RTOS + console.
- **+** Pure reuse of first-party X3 peripherals (provenance recorded); only the small `meip` level path
  touches the core.
- **−** Another core-input addition (`meip`) → must propagate the tie-off; verified by no-regression.
