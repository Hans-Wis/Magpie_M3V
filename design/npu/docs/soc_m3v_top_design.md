# soc_m3v_top 整合設計 — 兩核 SoC(M1A host + M3V NPU)· for review

- **Status:** DESIGN(待 Grok 架構 + Codex 整合實況 review)· 2026-07-08 · Claude
- **上位:** ADR-0068(SoC 系統框架)
- **鐵律:** **全用本地 IP**(`design/cpu_m1` + `design/npu`),不參考 repo 外目錄(避免打包遺漏);功能權威 = full-model bit-exact + 既有單元 gate。

---

## §0 localization 確認(打包自足)

M1A 相關 IP **全在本 repo**,無外部 RTL 參考:
- **host / core**:`design/cpu_m1/rtl/`(core/idu/alu/bmu/bp/cdec/csr/def.vh/div/dtcm/fexu/forward/hazard/ifu/lsu/mul/pmp/ras/rfu/trigger/vexu + cpu_m1_top + cpu_m1_axil_top + axil_bridge)。
- **SoC 積木**:`design/cpu_m1/soc/`(addr_decoder / plic / clint / uart / dm / dtm / **axil_sram_t28** / axil_bootrom / axil_dp_bram / 各 soc_top)。
- **NPU**:`design/npu/rtl/`(npu_top + mat_engine + npu_ml_ctrl + npu_dma + npu_tcm + npu_axil_regs + axil_1to2 + axil_decerr)。

> ⚠️ 唯一 repo 外參考 = `flow/v2_pipeline/phase_p_*` 的 **M1-grandparent ASIC 簽核腳本**(硬編 `/project/SOC/Magpie_M1/...` compiled DB / phase dir)——**非 IP、licensed-EDA 簽核流、不進功能打包**(EXTERNAL_DEPS.md §5 已記)。soc_m3v_top **不依賴它們**。

## §1 整合難點(誠實)

現有 `cpu_m1_soc_top` 用 M1 **native valid/ready dbus + addr_decoder**(非 AXI),且 map 為 RISC-V 標準
(CLINT 0x0200 / PLIC 0x0c00 / UART 0x1000 / RAM 0x2000)——**與 M3V offload map(NPU 0x3000 / SRAM 0x8000)
不同**。且 NPU 是 AXI:**slave = AXI-lite**(host 配置 CSR/TCM)、**master = AXI4-full**(DMA burst)。故不能
直接把 npu_top 塞進 cpu_m1_soc_top,需新 top + 橋接。

## §2 soc_m3v_top 結構(全本地復用)

```
   cpu_m1_axil_top（host,AXI-lite master;= cpu_m1_top + axil_bridge）
        │ AXI-lite (control/config)
        ▼
   ┌─ AXI-lite interconnect（addr-routed,M3V map）──┐
   │   0x3000 → npu_top.s_axi（NPU CSR/TCM slave）    │
   │   0x8000 → SRAM（host 寫 weights/CQ）            │
   │   0x0c00 → plic（讀 pending / claim）            │
   │   0x1000 → uart（選配）                          │
   └──────────────────────────────────────────────┘
   npu_top.m_axi（AXI4-full master, DMA）──┐
                                           ▼
                        ┌─ SRAM 2-master arbiter ─┐
   host lite 寫 ───────▶│  axi_full_sram（大,代 DDR）│◀─── NPU full 讀寫
                        └────────────────────────┘
   npu_top.irq ──▶ plic ──▶ cpu_m1.irq_external / meip
```

**模組復用/新增**:
| 模組 | 來源 | 動作 |
|---|---|---|
| host | `cpu_m1_axil_top`(本地)| 復用(AXI-lite master)|
| NPU | `npu_top`(本地)| 復用(slave + master 埠都在)|
| SRAM | `axil_sram_t28`(本地,lite)| **擴為 AXI4-full**(NPU DMA burst)或新 `axi_full_sram`;參數化大小 |
| PLIC | `plic`(本地)| 復用;接 npu_top.irq |
| interconnect | `addr_decoder`(本地,native)| **改/新寫 AXI-lite 版**(M3V map)|
| SRAM 仲裁 | — | **新寫 2-master AXI arbiter**(host lite + NPU full;lite 視為 len=0 full)|
| **soc_m3v_top** | — | **新寫頂層**(兜上述 + reset/clk/IRQ)|

**新 RTL ≈ interconnect(lite,M3V map)+ SRAM full 化 + 2-master arbiter + top wiring**,~300-400 行,全本地依賴。

## §3 位址圖(soc_m3v_top,承 ADR-0068)

| slave | 位址 | bus | 主 |
|---|---|---|---|
| NPU CSR / DTCM / ITCM | 0x3000 / 0x3001 / 0x3002 | lite | host |
| SRAM(代 DDR)| 0x8000 | lite(host 寫)+ full(NPU DMA)| host + NPU |
| PLIC | 0x0c00 | lite | host |
| UART(選配)| 0x1000 | lite | host |

## §4 最小整合先行(minimal-first)

**M1:真兩核 e2e 最小可跑** = host + npu_top + 大 SRAM + 一條 IRQ→PLIC。不含 UART/debug/CLINT(後掛)。
驗證:host 韌體(跑在真 cpu_m1)當 producer——寫 weights/CQ 到 SRAM、配置 NPU CSR、脈 doorbell、
等 IRQ、讀結果——**取代現行 TB-as-host**,對既有 gate_46/gemma golden bit-exact。

**M2**:掛 PLIC 多源 / UART / debug(dm/dtm)/ CLINT,補周邊。
**M3**:full-model(大 SRAM 代 DDR 裝 270M + full runtime + 真 weights)。

## §5 驗證計畫

- **soc smoke**:host 韌體單筆 GEMM offload e2e(host→SRAM→NPU DMA→算→writeback→IRQ→host 讀)bit-exact vs golden。
- **等價**:同一 workload,soc_m3v_top(真 host producer)輸出 == 現行 TB-host 路(gate_46 golden)。
- **回歸**:npu_top 單元 gate 全綠(soc 不改 npu_top 內部)。
- **green-wash 守衛**:host 必為真 cpu_m1(非 TB 直寫 CSR);IRQ 必經真 PLIC;SRAM 必經真 arbiter(非後門)。

## §6 開放問題(給 review)

1. **SRAM full 化 vs lite+full 雙埠**:host 寫用 lite(degenerate full len=0)進 full SRAM,還是 SRAM 開 lite+full 雙埠?傾向前者(單一 full SRAM + 2-master arbiter,host lite→full 橋)。
2. **interconnect 復用 addr_decoder(native)改 AXI-lite 版 vs 新寫**:傾向新寫小 AXI-lite decoder(M3V map),addr_decoder 留 M1 native SoC 用。
3. **host 用 cpu_m1_axil_top(AXI-lite)vs cpu_m1_top + 手接 axil_bridge**:傾向 cpu_m1_axil_top(已封裝)。
4. **reset/clk domain**:單 clk 單 domain(同現況);NPU 的 domain_rstn / hard_reset(ADR-0047)由 host CSR 驅動,soc 不新增 domain。
5. **最小整合的 host 韌體**:新寫 producer 韌體(對標現行 cq_host.py 的 ABI)跑在真 cpu_m1;ITCM/DTCM 由 host 載入。

**下一步:review(Grok 架構 / Codex 整合實況——尤其 AXI lite/full 橋接與 arbiter 的真實作點)→ 定 §6 → 出 soc_m3v_top 最小整合實作規格 → 實作 + soc smoke bit-exact。**
