# 架構效能分析(首份)— Magpie_M3V benchmark

> 日期 2026-07-06 · ADR-0064 P1 · 現況 = **analytical + 首個 RTL 錨點**(誠實界:標明 analytical
> vs 實測)· mat_engine = int8 8×8 → 256 MAC/cyc(4 fused k-lanes,ADR-0040)· ~1.0GHz(ADR-0053)。

## 0. 方法(P1)
- **cycle 量測(RTL,非侵入 probe,復用 gate_53/54 trace)**:`cycles_total`、`mat_busy`(MAC
  陣列動)、`mat_stall`(CQ empty / DMA wait)、`cq_dispatch`、`dma_rd/wr`、`vexu_busy`。
- **衍生指標**:
  - `MAC_util = MACs_useful / (cycles_total × 256)`
  - `array_util = MACs_useful / MACs_computed`（8×8 陣列每拍用了幾格）
  - `DW_waste = 1 − array_util`（block-diagonal depthwise 罰則）
  - `CQ_overhead = cq_dispatch / cycles_total` · `DMA_bound = dma_stall / cycles_total`
- **perf mode**:`run_bench.py --perf`(TODO:接 cycle_probe;本報告先 analytical + dims 錨點)。

## 1. Per-op 陣列利用率(實測 dims 錨點)
| op | 映射 | MACs useful | MACs computed | **array_util** |
|---|---|---|---|---|
| **depthwise 3×3**(MobileNet block)| **block-diagonal conv**(cout=8,K=72)| 1152 | 9216 | **12.5%(1/8)** ⚠️ |
| pointwise 1×1 | 純 GEMM(cout=8,K=8)| 1024 | 1024 | **100%** ✅ |
| standard conv(gate_50,K=72)| im2col GEMM | 全 | 全 | **100%** ✅ |
| FC / MLP(gate_48/49)| GEMM | 全 | 全 | **100%** ✅ |
| LLM 投影 / attention matmul | GEMM(K-chunk)| 全 | 全 | **~100%** ✅(CQ batch 後)|

**關鍵發現(CNN)**:**depthwise 是唯一 1/8 陣列利用率的算子**——block-diagonal 把 per-channel
kernel 攤成 channel-masked 權重,8×8 陣列每拍只用對角 1 格,7/8 浪費。pointwise / conv / FC / LLM
GEMM 都是 100%。→ **CNN 的 depthwise 層是 MAC 效率瓶頸**,其餘無浪費。

## 2. Class 瓶頸圖
```
CNN(MobileNet / MLPerf DS-CNN / VWW):
  主宰 → depthwise MAC 浪費(1/8 array_util,block-diagonal)
  次   → stride-2 im2col 缺(VWW/ResNet 需 SW expand,慢)→ DMA input staging
  已解 → CQ batch(ADR-0052)· requant pipe(ADR-0053)

LLM(Gemma-3 270M / SmolLM2 135M):
  主宰 → weight streaming 頻寬(270M/135M params,32KB DTCM 裝不下 → DMA stream)
  次   → GeGLU/SiLU activation(vexu 向量多項式)+ RMSNorm(reduce + scalar-F rsqrt)
  三   → FC mat_util(CQ batch + 256 MAC/cyc 已好)
```

## 3. 改進 lever(ROI 排序)
| lever | 狀態 | CNN | LLM | 估 speedup | 目標 benchmark |
|---|---|---|---|---|---|
| **① 原生 depthwise / 1×1 fast path** | 未做 | **高** | 低 | **DW 層 2–8×**（消 1/8 浪費 → 接近 100%）| MobileNet, KWS, VWW |
| **② stride-2 im2col(硬體)** | 未做 | **高** | 低 | 解阻塞 + 免 SW expand | VWW, ResNet-8 |
| **③ activation LUT vs polynomial** | poly | 中 | **高** | 1.5–3×(act-bound slice)| Gemma GeGLU / SmolLM2 SiLU |
| **④ LLM weight streaming / double-buffer** | scope-cut | 低 | **關鍵** | 2–5×(memory-bound proj)| Gemma, SmolLM2 |
| CQ batching | ✅ ADR-0052 | 低 | 中 | done | — |
| requant pipe | ✅ ADR-0053 | 低 | 低 | done | — |
| S_RUN sequencer pipe | standby | 低 | 中 | 10–15% | 長 FC chain |
| residual add fusion | 未做 | ResNet only | 低 | 1.1× | ResNet-8 |

## 4. 建議(先量再改,ADR-0051 教訓)
- **CNN ROI #1 = 原生 depthwise MAC 路**(lever ①):目前 depthwise 只有 12.5% 陣列利用率,原生
  depthwise datapath(per-channel accumulate,不攤 block-diagonal)可把 depthwise 層拉到接近 100%
  → **MobileNet / DS-CNN depthwise 層 2–8× 加速**。這是 CNN 類最大的單一提升。
- **LLM ROI #1 = weight streaming double-buffer**(lever ④):LLM 是 memory-bandwidth-bound(權重
  遠大於 DTCM),double-buffer 讓 DMA 預取下一 tile 權重與當前 MAC 重疊 → 2–5×。
- **LLM ROI #2 = activation**(lever ③):GeGLU/SiLU 若量測顯示 act-bound,polynomial 已零硬體;
  要更快才評估 mat_engine 融合 activation LUT(ADR-0060 討論)。
- **順序(P2,F1 功能綠後)**:① depthwise 原生 → ② stride-2 im2col → ③④ LLM 路。**每項先在 perf_report
  用 MAC_util 錨定收益再動 RTL**(承 ADR-0051「先量再動」擋 wrong-path)。

## 5. 誠實界
- 本報告 §1 的 array_util 是**實測 dims 計算**(MobileNet block 12.5% 已由 gate_82 dims 確認);
  cycle-level MAC_util / DMA_bound / CQ_overhead 待 `cycle_probe` 實測(P1.1,標 analytical)。
- LLM 效能全 **analytical**(RTL S-slices 未建,ADR-0062);weight-byte/cycle budget 待 P1.2 model。
- 改進估值(2–8× 等）為**架構分析上界**,非實測;P2 每項落地後以 perf_report 實測驗證。
