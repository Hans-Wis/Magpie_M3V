# Magpie_M1 — Design Report & RV-CPU Project Playbook

> A RV32IMC_Zicsr_Zifencei, M-mode embedded CPU IP + subsystem. This report serves two audiences:
> **(A) engineers** reviewing the design, and **(B) AI agents / teams** starting a *new* RISC-V CPU
> project who want a proven, repeatable methodology. The "how we built and verified it" sections are
> deliberately written as a transferable **playbook**, not just M1-specific notes. Date: 2026-06-10.

---

## 摘要 (Abstract)

Magpie_M1 is a clean greenfield RV32IMC M-mode core taken from RTL to a **commercially-credible IP**:
**official riscv-arch-test 74/74 (100%)**, **Tier-2 structural coverage** on 13 island modules +
Spike-lockstep-verified integration, **VC Formal proofs** (core 22/22 + AXI 18/18), **Spyglass lint
0/0**, **multi-corner DC 699.30 MHz** (TSMC28HPC+), **configurable RV32IMC/RV32IMAC + optional PMP**, and a **verified AXI4-Lite master** + **FPGA/ASIC
subsystem**. Three real bugs (one green-wash coverage trap, two RV32C compliance bugs) were caught by
the discipline below — *all missed by random-stimulus lockstep alone*. The methodology, not the chip, is
the product: it is captured here so a non-author can replay it.

---

## 1. 設計目標與定位 (Goals & Positioning)

- **Product**: RV32IMC_Zicsr_Zifencei, **M-mode only**, single-hart, in-order embedded CPU IP. Delivered
  as a **core** (native or AXI4-Lite) and a **drop-in subsystem** (CPU + AXI + memory + boot ROM).
- **North Star**: prove + strengthen a *transferable* CPU-IP development flow. M1 is the clean greenfield
  example; the deliverable is the flow (gates + skills + harness + IDE), not the silicon.
- **Out of scope (deliberate, different SKU)**: S/U mode, MMU, F/D, RVA22, UVM/RVVI, multi-port
  AXI burst, full UPF. The SoC tier (pads/PLL/DDR/APR) consumes M1 as a `cpu_subsys` instance.

---

## 2. 架構 (Architecture)

4-stage in-order pipeline (IF / ID-EX / MEM / WB-class), single-hart. 13 RTL "island" modules under a
`core.v` integrator, plus the AXI bridge and SoC blocks:

| Group | Modules | Role |
|---|---|---|
| Leaf datapath | `alu` `lsu` `rfu` `forward` `hazard` `mul` `div` | compute, regfile, forwarding, stalls, M-ext |
| Decode | `idu` `cdec` | 32-bit decode + RV32C → 32-bit expander |
| Stateful | `csr` `ras` `bp` `ifu` | M-mode CSR/trap, return-addr stack, branch predictor, fetch |
| Integrator | `core.v` | pipeline glue: forward mux, stall, flush, **RV32C cross-boundary prefetch** |
| Bus / SoC | `cpu_m1_axil_top` `axil_bridge` `axil_bootrom` `axil_dp_bram` `cpu_m1_fpga_top` `clint` `plic` `uart` | AXI4-Lite master + memory + CLINT/PLIC/UART subsystem |
| Debug | `dm` `dtm` `trigger` + core debug-mode | RISC-V Debug v0.13.2: JTAG → DM → core; SW+HW breakpoints + watchpoints |

Key microarchitecture: full forwarding (EX/MEM + EX/WB), load-use + mul/div busy stalls, branch predictor
+ RAS, and a **residue-buffer cross-boundary prefetch** that assembles 32-bit instructions straddling a
4-byte boundary with 0-cycle penalty on the predicted path.

---

## 3. 關鍵設計決策 (Key Decisions — see ADRs)

| ADR | Decision |
|---|---|
| 0002 | Active ISA scope = RV32IMC_Zicsr_Zifencei, M-only (Ch2 lab08e pipeline baseline) |
| 0015 | `mstatus.MPP` is read-only WARL = M (M-only hart) — *found via Spyglass lint* |
| 0016 | Compressed HINTs (C.LI/SLLI/MV/ADD/LUI rd=x0) execute as NOP, reserved trap — *found via lint + arch-test* |
| 0017 | `at_cross_boundary` gated off during `redirect_warmup` (stale-fetch fix) — *found via arch-test* |
| 0018 | M1 as a CPU subsystem (FPGA BRAM / ASIC T28 SRAM variants); X3 consumes it as `cpu_subsys` |
| 0019 | CLINT MTIP/MSIP interrupt extension (priority MEI>MSI>MTI) — RTOS-capable |
| 0020 | PLIC + UART peripheral subsystem (MEIP level path; first-party X3 RTL) |
| 0021 | RISC-V Debug MVD — DM + DTM + core debug-mode (adapted from first-party X1) |
| 0022 | Debug Trigger Module — HW breakpoints + watchpoints (mcontrol6) |
| 0023 | RV32A atomics — optional (parameter RV32A); RV32IMC↔RV32IMAC |
| 0024 | PMP — optional (parameter PMP_ENTRIES); adapted ibex_pmp.sv (Apache) |
| 0001(ws) | Clean-room → license-compliant reuse (workspace governance) |

---

## 4. 驗證方法論 (Verification Methodology) — THE PLAYBOOK

This is the reusable core. For a **new** RV CPU, replay these in order:

### 4.1 Per-island Tier-2 ladder (close coverage bottom-up)
Whole-core toggle/expr is an opaque mountain (a mature core sits ~65–75%). **Decompose** the core into
leaf / decode / stateful islands; close *each* to **Tier-2** (line 100 · branch 100 · expr ≥95 · toggle
≥95 · FSM 100) with a standalone unit TB + **Verilator** (line/toggle) + **VCS/URG** (branch/expr/FSM).
Only then attempt integration. Tooling: `platform/lib/cov_metrics.py` + the `coverage-ladder` skill
generate the waiver-aware, skip-guarded gates.

### 4.2 Dual-number RAW + ADJUSTED; structural waivers only
Always report RAW (tool output) and ADJUSTED (after waivers). A point is **STRUCTURAL** (waivable) only
if it is **RTL-hardwired constant — cite the line**. A free input that is merely *unstimulated* is
**REACHABLE — close it, never waive** (the green-wash trap, §5). **producer ≠ approver**: the implementer
proposes a waiver; a *different* reviewer verifies it against the RTL before approving; every waiver
`spike_impact:none`; a single waiver may not exclude >90% of a module (blanket-ban enforced in code).

### 4.3 Delta-integration (don't re-climb the mountain)
Integration slices own **only** the `core.v` integrator's *incremental* coverage, never whole-core. The
correctness authority is **Spike per-commit lockstep** (PC/GPR/CSR at each retire). Residual is attributed
by owner (reachable / structural / cross-slice / SKU-bound). The whole-core riscv-dv farm is a *separate*
milestone, never an integration-gate substitute.

### 4.4 Three independent signoff axes (they catch different bugs)
- **Spike lockstep** over directed + riscv-dv random stimulus — architectural equivalence.
- **VC Formal (FPV)** — prove invariants (x0=0, comparator equivalence, forwarding gating, CSR WARL, AXI
  handshakes). *Found that x0=0 comes from the read-mux, not storage.*
- **riscv-arch-test** (official compliance) — the corner cases random stimulus rarely hits.
- **Spyglass lint** *early* — a spec-audit surface, not just style (it found 2 real spec bugs).

> **Central lesson**: lockstep-over-random-stimulus passed while **3 real bugs hid**. Formal + official
> compliance + lint each caught what the others missed. Run all of them.

---

## 5. 發現的 Bug 與教訓 (Bugs Found & Lessons)

| Bug | Found by | Root cause | Lesson |
|---|---|---|---|
| **ras green-wash** | reviewer (Claude) rejecting a Codex waiver | a unit free-input's high bits were *unstimulated*, proposed as "structural" (16KB firmware) | unit free inputs are REACHABLE — drive them; 45% "covered + bogus waiver" → real 100% |
| **parse_urg column order** | div's 19/20 (hit≠total) | URG row is `<TOTAL> <hit>`, not `<hit> <total>` — masked while hit==total | self-checking parsers (cross-check pct) catch column bugs |
| **mstatus.MPP writable** | Spyglass lint | M-only hart stored illegal MPP | lint is a spec audit; fix the source, don't waive |
| **C.LUI rd=0 trap** | riscv-arch-test clui-01 | a 5th compressed HINT mis-classified as illegal | official compliance catches hint/reserved corners |
| **cross-boundary +2/+4** | riscv-arch-test cbnez/cj | `at_cross_boundary` fired on stale fetch during `redirect_warmup` | any new fetch/redirect signal must respect `redirect_warmup` |

---

## 6. Co-work 模型 (4-agent execution) — for AI-agent projects

| Agent | Role | Guardrail |
|---|---|---|
| **Claude** | integrator / PL / **only committer**; independent verify (sha/gate/lockstep); writes/edits | keeps the honesty boundary |
| **Codex** (gpt-5.5) | surgical bug-hunt + single-module implement + licensed-EDA runs | may shrink scope → PL checks completeness |
| **Grok** | DV-architect / roadmap / spec adjudication (web search) | charters are *hints* — verify vs RTL |
| **Gemini** | corpus / large-context analysis / independent recompute | condense big logs → small decisions |

Non-negotiables: **producer ≠ approver** (the agent that produces cannot self-approve), **report-faithfully**
(no fabricated numbers; "didn't run" = `waived/unavailable`), per-run provenance, correctness authority =
Spike lockstep + gates. Licensed EDA via Codex needs `-s danger-full-access` (license server @127.0.0.1;
sandbox `--unshare-net` breaks it).

---

## 7. 結果 (Results)

| Axis | Result |
|---|---|
| Compliance | **riscv-arch-test 74/74 = 100%** (RV32I 39 + RV32M 8 + RV32C 27) |
| Code coverage | 13 islands **Tier-2** + integration lockstep-verified (merged core.v branch 96%) |
| Functional coverage | riscvISACOV-mapped operand/value/immediate 100% (1 mem-bound exclusion) |
| Formal | core **22/22** + AXI4-Lite **18/18** PROVEN (VC Formal FPV, 0 CEX) |
| Lint | Spyglass **0 errors / 0 warnings** (reviewed waivers) |
| PPA | multi-corner DC TSMC28HPC+ **699.30 MHz** (TT/SLOW/FAST, WNS=0), ~26.8 kµm², 13–17.5 mW |
| AXI | native-vs-AXI commit traces byte-identical @0/3 wait states |
| Subsystem (FPGA) | AXI→dual-port BRAM + boot ROM, boot→run→MMIO PASS; **PYNQ-Z2 passing bitstream @ 50 MHz** (4 817 LUT, LED blink) |
| Subsystem (ASIC) | AXI→TSMC28 1RW1R SRAM macro, boot→MMIO PASS; DC 699.30 MHz, 42 682 µm² (logic 27 167 + macro 15 515) |
| Subsystem (RTOS) | **CLINT MTIP/MSIP** (ADR-0019) timer/sw IRQ + **PLIC** (MEIP, claim/complete) + **UART** console (ADR-0020); directed + highest-risk-flush corner PASS, no regression |
| Debug | **RISC-V Debug** (ADR-0021/0022): real OpenOCD over JTAG — halt/resume/single-step, GPR/CSR access, SW+**HW breakpoints** (`halted due to breakpoint`) + **watchpoints**; RV32C-cross-boundary trigger corner PASS, 273 gates no regression |
| Performance | **CoreMark 2.690/MHz** (CRC-validated; Codex measured = Gemini recomputed = in Grok's RV32IMC band), **IPC 0.779 / CPI 1.284** |
| Gates | 53 pytest gates, 273 pass / 1 xfail |

---

## 8. 給新 RV CPU 計畫的步驟 (Step-by-step for a new RV CPU)

1. **ADR the ISA scope first** (don't write RTL until the scope + microarch contract are decided).
2. **Bring up a core**; get it to **Spike per-commit lockstep** on directed + riscv-dv ASAP — that is the
   correctness authority, not "looks like it runs".
3. **Per-island Tier-2 ladder**: decompose, close each leaf/decode/stateful module to Tier-2 with a unit
   TB + Verilator + VCS/URG; dual-number, structural-only waivers, producer≠approver. Use the
   `coverage-ladder` skill + `cov_metrics` to generate gates.
4. **Delta-integration slices** under Spike lockstep; attribute residual honestly; do NOT re-climb whole-core.
5. **Run the three independent axes**: VC Formal on key invariants, **official riscv-arch-test**, Spyglass
   lint early. Expect them to find bugs lockstep didn't.
6. **SoC-readiness**: an AXI4-Lite master bridge (verify native-vs-AXI equivalence + formal handshake
   props), then a subsystem (memory + boot ROM), FPGA (Vivado) and ASIC (DC multi-corner) flows.
7. **Hand-off**: a signoff evidence pack mapping the result to the customer standard, with honest 3-layer
   positioning (Closed / Near-term / Deliberate-non-goals) — every claim a re-runnable gate.

> Artifacts: `docs/adr/`, `docs/reports/` (signoff pack, integration closure, debug report, this report),
> `platform/lib/cov_metrics.py`, `platform/skills/coverage-ladder/`, `tests/gates/`. The flow is reusable.
