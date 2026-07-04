# M3V NPU — Phase 0 ISA / ABI / memory-map contract (CoralNPU parity)

Status: **Phase 0 — contract locked, toolchain proven on ISS** (2026-07-03). Gate:
`tests/gates/gate_p0_toolchain_iss.py`. Scope decision: `docs/adr/0031-m3v-hybrid-npu-scope.md`.

## 1. ISA contract

| item | value | note |
|---|---|---|
| Full parity target | `RV32IMF_Zve32x_Zicsr_Zifencei_Zbb`, VLEN=128 | = CoralNPU datasheet string |
| **Phase 0/1 target** | **`rv32im_zve32x_zvl128b`** (integer-only) | scalar **F deferred** (User 2026-07-03); `Zvl128b` pins VLEN=128 |
| Vector | RVV 1.0 **Zve32x** — integer EEW ≤ 32, no vector float | matches CoralNPU vector config |
| Delta vs cpu_m1 host | add **Zve32x** (F added later); **C not required** | CoralNPU has no compressed; toolchain won't emit it |
| ABI | `ilp32` | integer ABI (no `f`/`d` regs until F added → then `ilp32f`) |

## 2. Config parity (CoralNPU datasheet)

| item | value |
|---|---|
| ITCM / DTCM | 8 KB / 32 KB |
| Bus | AXI4 master + slave |
| Matrix/GEMV engine | 256 MAC/cycle (M3V: **64 first → 256**) — **not in the open CoralNPU emit**, net-new |
| Vector-only throughput | Zve32x VLEN=128 ≈ 8 int8 MAC/c (the GEMV array is the real MAC muscle) |

## 3. Two-core AXI memory map (draft — host cpu_m1 view)

| region | base (draft) | who | via |
|---|---|---|---|
| Host cpu_m1 code/data | `0x8000_0000` | host | frozen host bus |
| NPU control CSR window | `0x3000_0000` | host → NPU AXI **slave** | AXI4-Lite (host master exists, vcformal-checked) |
| NPU local ITCM/DTCM window | `0x3001_0000` | host loads NPU program/data | AXI4-Lite/-full |
| Shared weight/activation mem | `0x4000_0000` | host + NPU AXI **master** | AXI4-full + DMA (net-new) |
| NPU→host completion IRQ | — | NPU → host | level/MSI (TBD Phase 1) |

(Addresses are a Phase 0 placeholder; frozen in the Phase 1 AXI-fabric spec.)

## 4. Toolchain — "make Google's NPU toolchain apply" (HONEST result)

- Google's real `coral-opt` (MLIR) + CoralNPU IREE runtime are **closed-source / commercial
  (Synaptics Torq), unavailable here** (M1V hit this, wrote a stand-in). **We do not depend on them.**
- Because CoralNPU is standard `RV32 + Zve32x`, the **open** toolchain applies once the ISA matches:
  - `clang --target=riscv32 -march=rv32im_zve32x_zvl128b -mabi=ilp32` — RVV codegen (integrated
    assembler emits vector ops; no gas RVV dependency).
  - `riscv64-linux-gnu-gcc` / GNU `ld` — bare-metal link (HTIF crt0).
  - `spike --isa=rv32im_zve32x_zvl128b` — ISS golden (VLEN=128).
  - Reference: M1V stand-in StableHLO→RV32 emitter; TFLM (open) for the int8 op path (Phase 3+).

## 5. Phase 0 PROOF (reproducible)

`IP/npu/sw/rvv_zve32x_smoke/` — int8 RVV dot product, `dot([1..8],[2..9]) = 240`:

- clang lowers `vdot_i8.c` to real RVV: `vsetvli e8,mf4` → `vle8.v` → `vwmul.vv` (int8×int8→int16)
  → `vwadd.wv` (→int32) → `vredsum.vs`.
- Linked bare-metal, run on Spike ISS → **HTIF exit code 240** ✅ (`crt0.S` sets `mstatus.VS` to
  enable the vector unit — else `vsetvli` traps illegal).
- **Meaning**: the NPU software contract is executable on a golden model *before any RTL exists*.
  Phase 2+ RTL is verified against this same ISS.

## 6. Remaining Phase 0 items

- [ ] Host benchmark baseline (reuse M1A `docs/reports/m1_benchmark_baseline.md`: CoreMark/MHz 2.47).
- [ ] GEMV roofline table (weight-stream GB/s vs MAC/s) to size the 64→256 array against the
      bandwidth wall (report §3: edge-LLM is bandwidth-bound).
- [ ] TFLM single int8 op on the ISS (extends the smoke kernel toward a real ML op).
- [ ] Freeze the AXI memory map (§3) into the Phase 1 fabric spec.

## ADR-0043 — Host producer ABI(RING_OVERRUN / flush-before-doorbell)

- **RING_OVERRUN 防範 = 生產者紀律**(device 端偵測 deferred,ADR-0035):producer 依
  `free = (HEAD - TAIL - 1) mod SIZE` 計算空間(恆留一空槽),空間不足時**拒絕寫入**,
  絕不讓 TAIL 追上 HEAD。參考實作 `IP/npu/sw/host/cq_host.py::CqProducer`(gate_51)。
- **flush-before-doorbell**:descriptor 與 payload 寫入 shared memory 後、TAIL doorbell
  之前,host 必須執行 cache flush / memory fence——NPU DMA 讀的是記憶體,不是 host 快取。
  `CqProducer.commit()` 固定順序:fence hook → doorbell(順序由 gate_51 斷言)。現行 DV
  host 無快取,fence 為佔位;SoC 整合(Phase 7)時接真 flush。
- **2D/strided DMA**(sequencer firmware,RTL 零改動):`MAT.LOAD_W W2 = src row stride
  (bytes,0=連續)` gather;`MAT.STORE W3[31:16] = dst row stride(words,0=連續)`
  scatter。stride 未對齊 / 小於 row bytes → `MAT_PARAM`。
