---
status: proposed
date: 2026-07-08
governs: Magpie-M3V 兩核 offload SoC 系統框架 — M1A host + M3V NPU domain + AXI crossbar +
         大 SRAM(代 DDR)+ PLIC + 周邊;offload 契約(producer/consumer)與整合/驗證計畫
supersedes: []
references: ADR-0032(cpu_m1 參數化 spine)· ADR-0034(NPU core 進 socket)· ADR-0035(command
            queue producer/consumer)· ADR-0038(trap-to-host)· ADR-0044(ITCM/DTCM sizing)·
            ADR-0063(coverage 分層 DUT:T2 soc top)· ADR-0067(mat_engine v2 加速)
authority: 介面/契約已由既有 gate(CSR/DMA/CQ/mat)驗;SoC 整合 e2e 為本 ADR 待建目標,權威=
           full-model bit-exact vs TFLM golden(functional)+ 既有單元 gate(系統)
---

# ADR-0068 — Magpie-M3V SoC 系統框架(兩核 offload)

> ⛔ §2 鐵律交付物(架構確認)。本文 = 元件 + AXI 拓撲 + 位址圖 + offload 契約 + 驗證計畫 + 待建清單。
> 架構圖見規格書 `docs/Magpie-M3V-RV_NPU_Design_Spec.html` 圖 3.2(SoC crossbar)。

## §0 決策摘要

Magpie-M3V 為**兩核 offload SoC**:**host cpu_m1(M1A 全開)**經 AXI 配置並餵資料給 **M3V NPU domain**;
M3V 經自身 AXI master(DMA)串流資料、算完經 IRQ/mailbox 回報 host。三條路:

```
① 控制/程式：M1A ──AXI(master→slave)──▶ M3V CSR(0x3000) + ITCM(0x3002)   配置 · 載程式 · doorbell
② 資料：     M1A ──AXI──▶ SRAM(0x8000) ; M3V ──AXI(master/DMA)──▶ SRAM     weights · CQ · 結果
③ 回報：     M3V ──IRQ→PLIC + mailbox──▶ M1A                              done · err
```

## §1 Context

M1A 與 M3V-NPU-sequencer 為**同一參數化 RV32 spine**(ADR-0032:host 全開;NPU = stripped
run-to-completion,ADR-0034 已進 socket)。offload 契約 = command-queue ring producer/consumer
(ADR-0035)。缺的是把「真 M1A + AXI interconnect + 大 SRAM + PLIC」兜成一個 **soc_m3v_top**
(ADR-0063 標記為 T2 整合 DUT)——現況 host 由 TB 扮演,尚無真兩核 top。

## §2 元件 + AXI 拓撲

| 角色 | 元件 | AXI |
|---|---|---|
| **Master** | M1A host CPU(cpu_m1 全開;RV32IMC+F+Zba/Zbb/Zbs+Zicond)| master |
| **Master** | M3V `npu_dma`(NPU 內部 DMA 引擎)| master |
| **Slave** | **大 SRAM @0x8000**(代 DDR:weights + CQ ring + 結果)| slave |
| **Slave** | M3V NPU domain 之 CSR(0x3000)/ DTCM(0x3001)/ ITCM(0x3002)| slave |
| **Slave** | PLIC(彙整 NPU done/err IRQ → M1A)| slave |
| **Slave** | 周邊:UART / Timer / GPIO;debug:JTAG / DMI | slave |
| **Interconnect** | AXI4 crossbar(2 master × N slave,依位址路由)| — |

**關鍵:M3V 同時是 slave**(被 M1A 配置 CSR/TCM)**+ master**(自己 DMA 讀寫 SRAM)——雙角色。

## §3 位址圖(實作真值)

| 區 | 位址 | 大小 | 存取 |
|---|---|---|---|
| NPU CSR | `0x3000_xxxx` | — | M1A 寫 CQ_RING_BASE/SIZE、CTRL.start、TAIL doorbell;讀 STATUS/ERR_CAUSE |
| NPU DTCM | `0x3001_xxxx` | 32 KB | (可選)M1A 初始化;NPU 資料工作區 |
| NPU ITCM | `0x3002_xxxx` | 8 KB | M1A 載 sequencer 程式(`0x3003+` = decode err) |
| **SRAM(代 DDR)** | `0x8000_xxxx` | 足夠裝全模型 | M1A 寫 weights+CQ;M3V DMA 讀 + 寫回結果 |
| mailbox / core-local | `0x0001` / `0x0002_xxxx` | — | NPU 內部(sequencer↔host mailbox / ML_JOB CSR)|

出貨版:SRAM 為外部 DRAM(edge:小 TCM + DRAM 串流)。驗證版:大 on-AXI SRAM 代 DDR(見 §5)。

## §4 Offload 契約(producer/consumer,承 ADR-0035)

1. **M1A(producer)**:載 NPU 程式 → ITCM(0x3002);載 weights + CQ 描述子環 → SRAM(0x8000)。
2. **M1A**:寫 NPU CSR:`CQ_RING_BASE`/`CQ_RING_SIZE` → `CTRL.start` → 脈 **`CQ_TAIL` doorbell**。
3. **M3V(consumer)**:sequencer 消 CQ ring(DMA 自 SRAM)→ 驅動 mat_engine(HW tile sequencer,
   ADR-0067)/ vexu / requant → DMA 串流 weights → 結果 DMA writeback 至 SRAM。`HEAD` 逐 descriptor。
4. **M3V**:`STATUS.done` + **IRQ → PLIC → M1A** + mailbox。err → `ERR_CAUSE` latch + ERR IRQ(ADR-0038)。
5. **M1A**:讀 SRAM 取結果;或依 IRQ 續下一批。

**流控**:ring FULL/wrap(ADR-0035)、fence-before-doorbell、abort/soft_reset(ADR-0038)、
hard_reset(ADR-0047)語義沿用,不因 SoC 整合改變。

## §5 驗證計畫(兩級)

- **L1 · 單元/子系統(已有)**:CSR fabric(gate_20)、DMA(gate_25/27/29)、CQ ring/equiv/consume
  (gate_35-39)、mat/RVV/TFLM/gemma e2e——皆 representative dims、**真 32KB TCM + 真 DMA/CQ**。host 由 TB 扮演。
- **L2 · SoC 整合 e2e(待建)**:`soc_m3v_top`(真 M1A + AXI crossbar + 大 SRAM + PLIC)。
  - **大 SRAM 代 DDR**:TB 記憶體 model size 到裝整個 Gemma-3 270M(int8 ~270MB);M3V 走**真 DMA/CQ/
    tile-sequencer 串流**。→ full-model compute **+ 系統(串流)**同時驗,架構為真。
  - **誠實界**:(a) functional bit-exact 不受記憶體 model timing 影響;(b) cycle 數為**理想記憶體 best-case**
    (真 DDR-bound 效能需接有 latency/bandwidth 的記憶體 model);(c) 270MB SRAM 為**驗證 stand-in 非出貨
    記憶體**(出貨=小 TCM + DDR 串流)。
  - **權威**:full-model 輸出對 TFLM golden bit-exact(每中間層先驗,沿 gemma S0-S5 紀律)。

## §6 現況 vs 待建

| ✅ 已有(驗過)| ⚠️ 待建 |
|---|---|
| M3V NPU domain(npu_top:AXI slave CSR/TCM + AXI master DMA)| **soc_m3v_top 整合**(真 M1A 實例 + crossbar + SRAM + PLIC 連線)|
| M1A(cpu_m1 全開,host lockstep 綠)| AXI4 crossbar(2M×N,addr decode + 仲裁)|
| Offload 契約(CQ ring/doorbell/IRQ/mailbox/trap)| PLIC 整合(NPU IRQ 線)+ 周邊/debug 掛載 |
| host 由 TB 驅動的功能驗證 | 真 M1A 當 producer 的 e2e(取代 TB-host)+ full-model runtime + 真 270M weights + golden |

## §7 開放問題 / 下一步

1. **crossbar 用現成(如既有 axil_1to2 / 參考 SoC `design/cpu_m1/soc/`)還是新寫 2M×N?**——傾向先復用/擴既有。
2. **soc_m3v_top 先做「真 M1A + M3V + 大 SRAM + 一條 IRQ」最小整合**,證兩核 e2e,再堆 PLIC/周邊。
3. **驗證載具**:大 SRAM 代 DDR(functional)先行;DDR-timing model 為效能簽核後續。
4. **full-model runtime**(18 層 + embedding + LM head + KV-cache)+ 真 270M weights 抽取 = 另一大工序,獨立追蹤。

**下一步:review(Grok 架構 / Codex 整合實況)→ 定 crossbar 復用方案 → 出 soc_m3v_top 最小整合實作規格。**
