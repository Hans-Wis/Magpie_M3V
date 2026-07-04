# Coral 可替代性狀態確認(2026-07-03,HEAD 47b1d14)

**問題**:目前設計是否已可「功能取代」Google Coral NPU?
**結論(誠實界,CLAUDE.md §3/§4)**:**還不可以。** 8 列對等清單 0 列全綠(第 5 列「卸載」最接近,scalar 層已端到端)。「可取代」宣稱的門檻 = 整清單綠燈 + 逐項權威證據;目前狀態 = **卸載骨架已對齊、計算引擎(RVV/矩陣)未建**。

## §3 清單逐項判定(Claude PL;Gemini 全上下文覆核見附錄)

| # | 面向 | 狀態 | 證據 / 缺口 |
|---|---|---|---|
| 1 | 純量 ISA(RV32IMF_Zbb) | 🟡 PARTIAL | rv32im sequencer 已 lockstep 驗證(gate_31/32,8×10.8k commits);Zbb 在 RTL(bmu)但未入 NPU lockstep 語料;**F deferred**(記錄在案的 scope-cut,補回才算綠) |
| 2 | 向量 RVV Zve32x + vtype/vl/vstart/vxsat lockstep | 🟡 PARTIAL(2026-07-04 升級) | **Phase 3 出口已達**:P0④ 契約上線(gate_40/41);TFLM int8 kernel 子集(vset*/vle/vse/vwmul/vwadd/vredsum/vmv.*)lockstep 全驗,Phase 0 kernel 於 RTL 跑出 240(gate_44)。缺:完整 Zve32x 覆蓋(mask/saturating/strided/LMUL>1,記錄性延後) |
| 3 | 矩陣 256-MAC + 8×8×32b acc + requant | 🟡 PARTIAL(2026-07-04 升級) | **64-MAC 外積引擎 + 4×8×8×32b acc + TFLite-exact requant 已落**(ADR-0037):gate_45 單元 1629 checks 對 NumPy golden 位元精確、gate_46 CQ 全鏈卸載 byte-exact。缺:64→256 MAC 放大、16 banks、weight-stationary、多 tile(記錄性延後) |
| 4 | 記憶體 ITCM 8K / DTCM 32K,128-bit | 🔴 MISSING(P1) | 現為 unified 4KB TCM、32-bit port。sizing/split 已記 P1(ADR-0034) |
| 5 | 卸載 doorbell→DMA→compute→writeback→IRQ | 🟡 PARTIAL(最接近) | doorbell(CTRL.start)✅ 權重 DMA ✅ scalar compute ✅ writeback ✅ DONE IRQ ✅(gate_29/30..34);**缺 command-queue ring(P0②,本步進行中)**;compute 僅 scalar |
| 6 | 例外/控制(traps + abort/reset) | 🔴 MISSING | P0⑤/P1:ERR_CAUSE、真 soft_reset/abort 未實作(ADR-0035 起 stub) |
| 7 | 軟體(開源 clang-RVV + TFLM + CQ encoder) | 🟡 PARTIAL | clang RVV → Spike ISS ✅(gate_p0);CQ encoder 隨 P0② SSOT 落;TFLM e2e = Phase 6 |
| 8 | 除錯(RVVI/RVFI trace port) | 🔴 MISSING(P1) | 未建 |

**達成宣稱所需的最小剩餘工作(依關鍵序)**:P0② CQ(進行中)→ P0④ vector-CSR lockstep 契約 + Phase 3 RVV EXU → P0③ 矩陣 acc+requant(Phase 4/5,NumPy golden)→ P0⑤ traps/abort → Phase 6 TFLM e2e → P1(ITCM/DTCM、F、RVVI/RVFI)。

## 附錄:Gemini 全上下文覆核狀態

**已回補(2026-07-04)**:Gemini 全上下文覆核完成(`docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md`)——逐列 CONFIRM 本報告判定,bottom-line 一致(向量/矩陣未建前不可宣稱取代)。原 quota-blocked 記錄保留如下。**原註**。2026-07-03 深夜以 User 提供的 key 嘗試
執行(ADR-0034 回補 review + 本清單交叉檢查 + Coral CQ dossier):該 key 為免費層,
gemini-3.5-flash 每日 20 requests,首次 agentic(--yolo)多輪呼叫即耗盡,其後所有單發
重試均 429。**待每日配額重置後回補**(已備妥單發內嵌全檔 prompt,
session scratchpad `gemini_inline_prompt.txt`)。本報告判定在回補前的證據基礎 =
Spike lockstep / scoreboard gates(第 1/5/7 列)+ 既有 Gemini 產出之
`2026-07-03_coral_gap_review.md` + Ch5 de-blackbox lab。
