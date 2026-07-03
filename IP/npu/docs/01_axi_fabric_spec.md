# M3V Phase 1 — AXI4-Lite fabric (control plane) spec

Status: **Phase 1 in progress — control-plane + data-plane (DMA) bricks DONE & verified** (2026-07-03).
Gates: `gate_20_axi_fabric.py` (control), `gate_25_npu_dma.py` (data). Scope: `docs/adr/0031-m3v-hybrid-npu-scope.md`.

## 1. Where this plugs into the frozen host

The frozen `axil_bridge.v` (in `IP/cpu_m1/rtl/`, untouched) already exposes the host cpu_m1 as
**two AXI4-Lite masters**: `m_axi_i_*` (read-only I) and `m_axi_d_*` (read+write D), single-outstanding.
The M3V fabric hangs off the **D master** — that is the path by which host firmware configures the NPU.

```
cpu_m1 (frozen) ── axil_bridge.v ──> m_axi_d_* (AXI4-Lite master, single-outstanding)
                                          │
                                    axil_1to2.v  (NEW, IP/npu/rtl)
                                    ├── 0x3xxx_xxxx ─> npu_axil_regs.v  (NPU control CSRs)
                                    └── else        ─> host subsystem (RAM/CLINT/PLIC/UART)
```

## 2. Control-plane memory map (frozen for Phase 1)

NPU window = `addr[31:28] == 0x3`. NPU CSR bank (word-addressed):

| offset | reg | acc | meaning |
|---|---|---|---|
| 0x00 | ID | RO | `0x4E505530` ("NPU0") — host presence check |
| 0x04 | CTRL | RW | [0]=start [1]=irq_clear [2]=soft_reset |
| 0x08 | STATUS | RO | [0]=busy [1]=done (driven by npu_core in Phase 2) |
| 0x0C | CONFIG | RW | kernel/descriptor pointer (weight base, etc.) |
| 0x10 | SCRATCH | RW | round-trip sanity |

(0x3001_xxxx ITCM/DTCM window and 0x4000_xxxx shared-mem/DMA are Phase 1 data-plane / Phase 2.)

## 3. RTL delivered

| file | role |
|---|---|
| `IP/npu/rtl/axil_1to2.v` | 1-master → 2-slave AXI4-Lite router by address (single-outstanding, matches host bridge) |
| `IP/npu/rtl/npu_axil_regs.v` | NPU AXI4-Lite **slave** CSR bank; drives `npu_start`/`npu_config`, samples `npu_busy`/`npu_done` |
| `IP/npu/dv/tb/axil_mem16.v` | passthrough mem slave (stands in for host subsystem) |
| `IP/npu/dv/tb/tb_axil_fabric.v` | host-master BFM + transaction scoreboard (8 checks) |

**Verified**: Verilator lint (0 errors) + Verilator sim → `AXIL_FABRIC_PASS`, 8/8 checks
(ID, SCRATCH/CONFIG round-trip, npu_start/config wiring, STATUS RO, 0x3 vs passthrough routing,
no cross-talk).

## 4. Assumptions / limits (honest)

- **Single-outstanding** read and write, matching the frozen host bridge. A multi-outstanding /
  burst interconnect is not needed for the AXI4-Lite control plane.
- `wstrb` is honored (byte-strobe merge, since Phase 1.5 §7); `prot` is ignored.
- This is the **control plane only**. The **data plane** (AXI4-full + burst + DMA double-buffer for
  weight/activation streaming, NPU as AXI master to shared mem) is the next Phase 1 slice — that is
  where the roofline bandwidth is won (ADR-0031 §3).

## 5. Data plane — AXI4-full + DMA (DONE)

`npu_dma.v` is an **AXI4-full INCR read-burst master**, host-programmed over the AXI4-Lite fabric:

| CSR (NPU window) | reg | meaning |
|---|---|---|
| 0x20 | DMA_SRC | shared-mem byte address (word-aligned) |
| 0x24 | DMA_DST | local buffer start (word index) |
| 0x28 | DMA_LEN | beats (32-bit words) to move |
| 0x2C | DMA_CTRL | write bit0 = GO (1-cycle pulse) |
| 0x08[3:2] | STATUS | dma_done, dma_busy |

Flow: host writes SRC/DST/LEN → GO → DMA issues INCR bursts (each **≤256 beats AND never crossing a
4 KB boundary**, longer transfers chunked) from shared memory into the NPU local buffer → sets
STATUS.dma_done. Single-outstanding (one burst in flight).

**Verified** (`tb_npu_dma.v`, 303 checks, `NPU_DMA_PASS`): a 300-beat transfer whose source
**crosses a 4 KB boundary** is split into 3 legal bursts (24 + 256 + 20) and every copied word
matches the weight-memory pattern. This is the bandwidth path the roofline (ADR-0031 §3) needs.

## 6. Sealed Phase 1 subsystem — `npu_top` (DONE)

`npu_top.v` is the integrated NPU IP: one AXI4-Lite slave (NPU window) decoded on `addr[16]` into
**CSR (0x3000_xxxx)** and **TCM (0x3001_xxxx)**; the DMA (AXI4-full master) streams shared-mem
weights **into the TCM**; a **level IRQ** rises to the host on completion.

```
host fabric ─AXI4-Lite─> npu_top
                          ├─ 0x3000_xxxx ─> npu_axil_regs (CSR + DMA descriptor) ── irq ─> host
                          ├─ 0x3001_xxxx ─> npu_tcm (ITCM/DTCM; host-loadable + DMA write port)
                          └─ npu_dma ─AXI4-full─> shared weight mem;  DMA data ─> npu_tcm
```

**Verified** (`tb_npu_top.v`, `gate_27_npu_top`, 23 checks, `NPU_TOP_PASS`): CSR ID, TCM host
load/readback, CSR/TCM decode, DMA-into-TCM stream, IRQ assert on `dma_done` + clear via CTRL, and
the host-loaded TCM region survives the DMA region (no clobber).

**Freeze guard** (`gate_10_host_noregress`): `IP/cpu_m1/rtl/` must stay byte-identical to
`m1a-rtl-freeze-v1.0` — any host edit trips CI.

`npu_top` is the stable socket the **Phase 2 cpu_m1-derived NPU core** plugs into (beside CSR/TCM).

## 7. Phase 1.5 — bus-protocol hardening (DONE, `gate_28_axi_adversarial`)

Multi-agent review (Codex, self-verified) found the Phase-1 gates passed happy-path only. Fixed +
proven by an **adversarial Verilator testbench** (`tb_axi_adversarial.v`, `tb_dma_err.v`):

| bug | fix |
|---|---|
| AXI-Lite **W-before-AW** misroute/deadlock (`axil_1to2`, `npu_top`) | hold W until the write route is known (`w_known = w_busy \| s_awvalid`) |
| **WSTRB ignored** (CSR + TCM) | byte-strobe `merge()` — keep old bytes where WSTRB=0 |
| **decode aliasing** (`0x3002_xxxx`→CSR ID) | 3-way decode CSR/TCM/**DECERR**; out-of-window → SLVERR (`axil_decerr.v`) |
| TCM **address wrap** | out-of-range offset → SLVERR (no wrap) |
| DMA **`LEN=0`** → ARLEN underflow to 0xff | `LEN=0` is a no-op, no burst |
| DMA **RRESP ignored** | latch read SLVERR → `STATUS[5]=dma_err`, still terminates |

Sim engine is **Verilator** (`--binary --timing`) in-sandbox; **VCS** is the signoff track
(OUTSIDE-SANDBOX, run via the licensed-EDA path). iverilog is not used on this project.

## 8. Deferred (Phase 2 or throughput tuning)

- [ ] Double-buffer ping-pong / multi-outstanding bursts (overlap fetch with compute) — throughput.
- [ ] DMA DST-overflow guard (currently a SW contract: host ensures `dst+len ≤ TCM`).
- [ ] (later) formal AXI property check on `axil_1to2` / `npu_dma`, mirroring the host's `phase_p_axi`.
