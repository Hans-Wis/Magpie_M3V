---
status: accepted
date: 2026-07-06
governs: /sim benchmark harness + functional verification + architecture performance analysis
authority: Spike lockstep + bit-accurate NumPy/BUILTIN_REF golden + AXI scoreboard; not-run stays not-run
---

# ADR-0064 — Benchmark `/sim` harness + 功能驗證 & 架構效能分析(pivot)

User 裁示(2026-07-06):coverage 階段凍結(ADR-0063 V1/V5 checkpoint),轉入 **① 四個 benchmark
的功能驗證(MobileNet / MLPerf Tiny / Gemma-3 270M / SmolLM2 135M)確認 M3V 功能正確,建 `/sim`
harness;② 架構效能提升分析**。DV/架構計畫 Grok 全文
`docs/reviews/2026-07-06_benchmark_pivot_plan_grok.md`。

## §0 鐵律
- **功能權威不變**:Spike lockstep + bit-exact golden(int8)/ tolerance(LLM fp)+ scoreboard。
- **誠實界**:`not-run` 保持 `not-run`;RTL-e2e 與 NumPy-golden 與 analysis-only **明示分級**,不混。
- **效能不取代功能**:先功能綠(F1)再優化(P2);效能報告先量再改(承 ADR-0051 教訓)。

## §1 `/sim` harness(`flow/sim/`)
```
flow/sim/ bench.yaml(SSOT:model/phase/golden/verify/gates/perf)· run_bench.py(統一入口)
          lib/(golden loader / cycle_probe / report)· cnn/(各 CNN bench)· llm/(gemma/smollm2 slice)
```
- **functional mode(default)**:Verilator DUT + Spike lockstep + tensor diff vs golden。
- **perf mode(`--perf`)**:同 firmware,取 cycle count + mat_busy/cq/dma/vexu counter → perf_report。
- `bench.yaml` 每項帶 **`rtl_e2e: true/false`** 誠實 flag + `verify: bit_exact|lockstep|tolerance|analysis`。

## §2 功能-正確性矩陣(誠實現況)
| bench | RTL e2e today | golden | 判準 |
|---|---|---|---|
| TFLM FC/MLP | ✅ gate_48/49 | BUILTIN_REF | int8 bit-exact |
| CNN conv+FC(stride-1 VALID)| ✅ gate_50 | BUILTIN_REF | int8 bit-exact |
| **MobileNet DW-sep block** | ✅ gate_82 | BUILTIN_REF | int8 bit-exact |
| MLPerf **AD**(FC-AE)| 🟡 FC 可,需 build script | NumPy(待建)| int8 bit-exact e2e |
| MLPerf **KWS**(DS-CNN)| 🟡 layer-wise(stride-1)| NumPy(待建)| per-op → e2e |
| MLPerf **VWW**(MobileNetV1)| 🔴 **stride-2 depthwise** 阻塞 | ref(analysis)| not-run 直到 stride-2 |
| MLPerf **IC**(ResNet-8)| 🔴 **stride-2 + residual add** 阻塞 | ref(analysis)| not-run |
| **Gemma-3 270M** | 🔴 需 S0..S5 RTL slice(ADR-0062 只 golden)| NumPy Tier-C | slice lockstep |
| **SmolLM2 135M** | 🔴 同 LLM stack,重用 Gemma slice | 同 | 同 |

**缺口(全域)**:im2col **stride-2/padding**(現只 VALID/stride-1)、**fused residual add**、LLM S-slices。

## §3 架構效能分析法 + 改進 lever(ROI 排序)
- **量測(RTL,非侵入 probe,復用 gate_53/54 trace)**:cycles_total / mat_busy / mat_stall(CQ empty/
  DMA wait)/ cq_dispatch / dma_rd-wr / vexu_busy。**衍生**:`MAC_util = MACs / (cycles×256)`、
  `DW_waste = 1 − effective_DW_MACs/mat_busy_MACs`(block-diagonal 1/8 罰則)、CQ_overhead、DMA_bound。
- **lever ROI**:
  | lever | 狀態 | CNN | LLM | 估 speedup |
  |---|---|---|---|---|
  | **原生 depthwise / 1×1 fast path** | 未做 | **高**(消 block-diag 1/8 浪費)| 低 | DW 層 2–8× |
  | **stride-2 im2col(硬體)** | 未做 | **高**(VWW/ResNet)| 低 | 解阻塞 |
  | **activation LUT vs polynomial** | poly | 中 | **高**(GeGLU/GELU)| 1.5–3× |
  | **LLM weight streaming / double-buffer** | scope-cut | 低 | **關鍵** | 2–5× |
  | CQ batching | ✅ ADR-0052 | 低 | 中 | done |
  | requant pipe | ✅ ADR-0053 | 低 | 低 | done |
  | S_RUN sequencer pipe | standby | 低 | 中 | 10–15% |
- **class 瓶頸圖**:CNN 主宰=depthwise MAC 浪費→stride-2→DMA staging;LLM 主宰=weight streaming 頻寬
  →GeGLU activation→FC mat_util。

## §4 sequencing(must-have F1 → 優化 P2)
- **F1 功能(must-have)**:F1.0 `/sim` harness → F1.1 MLPerf AD e2e → F1.2 MobileNet block 進 harness
  → F1.3 KWS DS-CNN → F1.4 stride-2 **functional**(SW expand 先,非 perf-representative)→ F1.5 LLM S0
  (GeGLU int8 Tier-C)→ F1.6 Gemma S1-S5 → SmolLM2 重用。**F1 exit:四 family 各 ≥1 bit-exact RTL 證據點。**
- **P1 效能分析(F1.1 後平行)**:cycle_probe + 對 RTL-runnable bench 出 perf_report + MAC_util;LLM 出
  analytical model(weight bytes/cycle budget);ROI backlog。
- **P2 優化(F1 綠後)**:①原生 depthwise(CNN ROI#1)②stride-2 im2col ③LLM activation LUT + weight
  double-buffer ④S_RUN pipe(若 P1 report 顯示)。

## §5 gate + 產物
- gate band 續 `gate_9x`(coverage 佔 90/91;benchmark 用 `gate_93..`)。
- 產物:`flow/sim/`、`perf_report.json`/`docs/reports/perf_*`、功能矩陣。**F1.0/F1.2 本 ADR 落地**。
