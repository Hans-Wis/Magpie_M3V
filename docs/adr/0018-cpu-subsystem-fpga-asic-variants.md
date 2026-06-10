# ADR-0018 — Magpie_M1 as a CPU Subsystem (FPGA + ASIC variants)

- Status: accepted
- Date: 2026-06-10
- Deciders: Claude (PL), 3-agent consensus (Grok strategy, Gemini overlap, Codex effort), user direction
- Supersedes nothing; extends the core IP charter (CLAUDE.md) with a subsystem deliverable tier.

## Context

M1 is a verified RV32IMC M-mode core with a verified AXI4-Lite master (`cpu_m1_axil_top`). Customers
integrating a core spend months on the CLINT/PLIC/CSR/AXI/boot glue. A **CPU subsystem** tier (between
bare core IP and a full SoC) packages that glue as a drop-in compute block — the ARM-Cortex-M-subsystem
model. The first-party Magpie_X3 peripherals (CLINT/PLIC/UART/ROM, native-bus = M1-dbus-compatible) and
its TSMC28 dual-port SRAM macro are reusable.

## Decision

Deliver M1 as a **CPU subsystem** in two build-targeted variants sharing one AXI wrapper:

| | FPGA (`cpu_m1_fpga_top`) | ASIC (`cpu_m1_asic_top`) |
|---|---|---|
| RAM | dual-port block RAM (`axil_dp_bram`) | TSMC28 1RW1R SRAM macro (`axil_sram_t28`) |
| Boot ROM | LUT `axil_bootrom` (lui+jalr → RAM_BASE; `BOOT_DEBUG` spin) | same |
| I/D share | dual-port — no arbiter (port A = I read, port B = D read+write) | same |
| Build | Vivado (PYNQ-Z2 xc7z020) | DC TSMC28HPC+ |

**Boundary vs Magpie_X3 (anti-cannibalization)**: M1-subsystem = reusable compute+interrupt+AXI block; it
**stops at one AXI master + a documented IRQ/timer contract**. X3 = customer SoC SKU that **consumes M1 as
a `cpu_subsys` instance** and owns everything touching silicon floorplan (pads, PLL, DDR, interconnect
matrix, APR/STA). Never the reverse; M1 must not become a mini-X3.

**Subsystem++ roadmap (separate increment, ADR to follow)**: add CLINT (MTIP/MSIP), PLIC (MEIP routing),
UART — reusing the X3 peripheral RTL — to make M1 RTOS-capable. This requires a core change (csr.v MTIP/MSIP
extension, Rust+RTL paired per ADR-0044) and is gated by full re-verification (273 gates + lockstep +
arch-test must not regress).

## Consequences

- **+** A licensable subsystem tier with measured perf (CoreMark 2.690/MHz, IPC 0.779) + FPGA bitstream +
  ASIC area/Fmax — a much faster customer eval than a bare core.
- **+** Reuses verified parts (the AXI bridge: native-vs-AXI identical + 18/18 FPV; the FPGA subsystem:
  boot→run→MMIO PASS) and first-party X3 IP (provenance recorded).
- **+** Strengthens the North Star: a new staged flow (`cpu_core → cpu_subsystem`) proves the platform
  flow scales one hop outward, without becoming the SoC line.
- **−** The CLINT increment touches the verified core (interrupt model) — must be paired + fully re-verified.
- **−** The ASIC SRAM macro is 2 KB (512×32); larger memories need tiling (deferred).
