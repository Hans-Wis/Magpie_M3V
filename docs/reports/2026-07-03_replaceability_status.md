# Coral 可替代性狀態確認(2026-07-03,HEAD 47b1d14)

**問題**:目前設計是否已可「功能取代」Google Coral NPU?
**結論(誠實界,CLAUDE.md §3/§4)**:**還不可以。** 8 列對等清單 0 列全綠(第 5 列「卸載」最接近,scalar 層已端到端)。「可取代」宣稱的門檻 = 整清單綠燈 + 逐項權威證據;目前狀態 = **卸載骨架已對齊、計算引擎(RVV/矩陣)未建**。

## §3 清單逐項判定(Claude PL;Gemini 全上下文覆核見附錄)

| # | 面向 | 狀態 | 證據 / 缺口 |
|---|---|---|---|
| 1 | 純量 ISA(RV32IMF_Zbb) | 🟡 PARTIAL | rv32im sequencer 已 lockstep 驗證(gate_31/32,8×10.8k commits);Zbb 在 RTL(bmu)但未入 NPU lockstep 語料;**F deferred**(記錄在案的 scope-cut,補回才算綠) |
| 2 | 向量 RVV Zve32x + vtype/vl/vstart/vxsat lockstep | 🟡 PARTIAL(2026-07-04 升級) | **Phase 3 出口已達**:P0④ 契約上線(gate_40/41);TFLM int8 kernel 子集(vset*/vle/vse/vwmul/vwadd/vredsum/vmv.*)lockstep 全驗,Phase 0 kernel 於 RTL 跑出 240(gate_44)。缺:完整 Zve32x 覆蓋(mask/saturating/strided/LMUL>1,記錄性延後) |
| 3 | 矩陣(256-MAC outer-product + acc + requant) | 🟡 PARTIAL-strong(2026-07-04 升級) | **ADR-0040**:引擎升 **256 MAC/cycle**(stripmine 4 outer products/拍,8×8×32b acc ×4 banks,TFLite-exact requant)——Coral 公開算力數字對齊;throughput gate 實測 rpt=64→17 拍。誠實偏離(Class B):2×256-bit 讀埠 vs Coral 128-bit(banked-SRAM 假設,Phase 7 PPA 收斂)。餘:per-channel quant、>8×8 tile 排程 |
| 4 | 記憶體(ITCM 8K/DTCM 32K,128-bit) | 🟢 GREEN-leaning(2026-07-04 升級) | **ADR-0044**:ITCM 8KB(取指+0x3002 host 窗)/ DTCM 32KB Harvard 分割(鏡像載入契約,lockstep 免改);DTCM = 8-way banked 2R1W 結構模型 + 逐拍 bank 預算 checker(真 CQ batch 零違規、靈敏度已證)。誠實偏離:物理埠規格(Coral 單 128b vs 我們 8×32b 聚合)與 SRAM macro 對映歸 Phase 7 |
| 5 | 卸載(doorbell→DMA→compute→writeback→IRQ) | 🟢 GREEN-leaning(2026-07-04 升級) | **ADR-0043**:雙向 DMA + CQ ring + DONE/ERR/FULL 之上補齊 **2D/strided gather/scatter**(sequencer 迴圈、sanitizer 階梯含容量/wrap 守衛)、**host producer ABI**(RING_OVERRUN=生產者紀律、CqFull、fence-before-doorbell 契約入 00_isa_contract)。餘:SoC 真快取 flush(Phase 7)、device 端 overrun 偵測(deferred) |
| 6 | 例外/控制(traps + abort/reset) | 🟡 PARTIAL(2026-07-04 升級) | **P0⑤ 完成(ADR-0038)**:core trap→host(ERR_PC/ERR_CAUSE latch-once 對、ERR IRQ)、真 soft_reset/abort(burst-邊界 drain、AXI 乾淨、證據持久、ABORTED 入 fault namespace)、復原流程 gate_47 全驗。餘:hard-reset 區分、trap 向量豐富度(記錄) |
| 7 | 軟體(TF→編譯→NPU 執行) | 🟢 GREEN-leaning(2026-07-04 四升) | ADR-0041 MLP 之上,**ADR-0042:真 int8 CNN**(Conv2D **per-channel**(RESCALE_PC)+ K=72/128 **chunking** + host im2col)conv 中間層與最終輸出對 BUILTIN_REF 全 bit-exact(gate_50)。餘:POOL/更多 op、on-NPU repack、大模型 |
| 8 | 除錯(RVVI/RVFI) | 🟡 PARTIAL(2026-07-04 升級,原紅燈) | **ADR-0045**:RVFI/RVVI-lite trace port(npu_top 邊界;scalar retire/pc/trap+cause/intr/rd、vector WB commit+vl/vtype、order 計數)——**權威證據 = phase_20 lockstep 換源自 port 重跑全符(directed 1164 + random 10,809)**+ trap 可見性 gate_53。依 Grok 裁定 lite v0 不轉綠:v1 完成清單 = rvfi_insn、mem trace、mtval/mstatus、多退休(debugger-attach 級) |

**達成宣稱所需的最小剩餘工作(依關鍵序)**:P0② CQ(進行中)→ P0④ vector-CSR lockstep 契約 + Phase 3 RVV EXU → P0③ 矩陣 acc+requant(Phase 4/5,NumPy golden)→ P0⑤ traps/abort → Phase 6 TFLM e2e → P1(ITCM/DTCM、F、RVVI/RVFI)。

## 附錄:Gemini 全上下文覆核狀態

**已回補(2026-07-04)**:Gemini 全上下文覆核完成(`docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md`)——逐列 CONFIRM 本報告判定,bottom-line 一致(向量/矩陣未建前不可宣稱取代)。原 quota-blocked 記錄保留如下。**原註**。2026-07-03 深夜以 User 提供的 key 嘗試
執行(ADR-0034 回補 review + 本清單交叉檢查 + Coral CQ dossier):該 key 為免費層,
gemini-3.5-flash 每日 20 requests,首次 agentic(--yolo)多輪呼叫即耗盡,其後所有單發
重試均 429。**待每日配額重置後回補**(已備妥單發內嵌全檔 prompt,
session scratchpad `gemini_inline_prompt.txt`)。本報告判定在回補前的證據基礎 =
Spike lockstep / scoreboard gates(第 1/5/7 列)+ 既有 Gemini 產出之
`2026-07-03_coral_gap_review.md` + Ch5 de-blackbox lab。
