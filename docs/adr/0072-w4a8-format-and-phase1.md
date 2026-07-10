# 0072 — W4A8:格式 SSOT + Phase-1 架構(DMA dequant,引擎凍結)

- Status: **proposed(架構確認先行;RTL 動工 gated on 真權重 L2 評估 + Grok 契約 review)**
- Date: 2026-07-10
- Deciders: User(裁示 Phase-0→①②並行)、Grok(路線評估)、Claude(PL)
- 依據:`docs/reviews/2026-07-10_w4a8_grok.md`(建議路徑)· `docs/reports/2026-07-10_w4a8_phase0.md`
  (吞吐 GO / 精度待真權重)· `docs/reports/2026-07-10_ddr_wall_formal.md`(牆的校準)

## Context

Decode 權重串流牆(×16 校準)使 50–60 tok/s 必須減字節。Grok 判定 W4A8 +
burst + 部分 residency 為最便宜路徑;Phase-0 確認位元組帳(W4 g=64 → 27.8@G2
/ 52.4@近pin tok/s),精度需真權重定案(真 gemma-3-270m:18 層、H=640、
head_dim=256、inter=2048、5:1 sliding:full)。

## Decision — 格式 SSOT(凍結;g 可配置)

### 1. W4 打包格式(`w4 pack v1`)

- **數值域**:對稱 int4,**[-7,+7]**(排除 -8,保對稱;4-bit 二補數存放)。
- **打包**:2 nibble/byte,**little-endian nibble 序**(低 nibble = 較低 K index),
  K(輸入維)連續打包 —— 寫死,PTQ 導出器/RTL unpack/NumPy golden 三方共用。
- **分組**:沿 K 維,**g ∈ {32, 64} 可配置(default 64)**;g 與 mat_engine
  K-chunk=64 對齊(g=32 為精度後備,2 group/chunk)。
- **scale 表**:與權重 blob **分離**;每 group 一筆 **int16 乘數 M_g** + 每
  tensor 一個全域 **SH(移位)**:
  `w8_equiv[i] = clamp(round_half_up((w4[i] × M_g) >> SH), -127, 127)`
  —— dequant 目標是**現行 int8 數值域**(per-tensor scale 不變),使 mat_engine
  / requant(SRDHM 鏈)/ TFLM 側 activation 契約**全部凍結**。PTQ 導出器負責
  選 M_g/SH 使 `w4·s_g/s_tensor` 誤差最小(L1 golden 同式)。
- **blob 佈局**:與 streaming-tile 契約(DDR 牆修訂序 §3)聯合凍結 —— 權重按
  tile 串流序連續、col-low page-hit 對齊;本 ADR 先凍 nibble/scale 語意,tile
  序在 streaming 契約 ADR 定案(joint 事項,不得各自為政)。

### 2. 架構(Grok 方案 a)

- **npu_dma 新 descriptor 模式 `W4_DEQUANT`**:欄位 = w4 blob 位址、scale 表
  位址、g_log2、目的 TCM。DMA 讀取路徑上 unpack nibble → `(×M_g)>>SH` → int8
  → 既有 WPB TCM 寫路。**mat_engine / npu_tcm / requant / CQ 其餘 op 零改動**。
- 引擎內 group-scale MAC、TCM 存 int4(方案 b)明確**不做**(第二期才議)。
- 並聯項(獨立設計,不入本 ADR):軟體熱層 residency、burst 拉長(目標有效
  ≥4.0 B/cyc,否則 W4 增益被 efficiency 稀釋 —— Grok 警示)。

## Verification(雙層 golden,誠實界重構)

- **L1 結構正確性(gate 權威)**:repo 內 PTQ 導出器 + pack 寫入器 + NumPy
  參考(`w4 → w8_equiv → 既有 int8 GEMM+requant`)——RTL **bit-exact**。
  gates:`gate_w4_pack_unpack`(nibble/邊界/odd-K/scale 極值)、
  `gate_w4_dma_scoreboard`(AXI→TCM int8 映像 == golden)、
  `gate_w4_matmul_tile`(單 tile e2e)、**int8 舊路零回歸**(gate_45/46 不動)。
- **L2 模型品質(獨立報告,不進 lockstep)**:真權重 harness 必須評估
  **composed 方案**(w4→int8-grid 再量化,即生產路徑,含第二次捨入),不是
  純 fp32 dequant;指標 = PPL/logit-KL/top-1 一致率 vs bf16 基線,g=64 與 g=32
  並列。**不宣稱 bit-exact TFLM int8**。
- green-wash 守衛:禁「與 int8 差不多」當 gate;禁 TB 軟 dequant 冒充 RTL。

## RTL 動工前置(全部滿足才開 D 步)

1. 真權重 L2:g=64 或 g=32 掉分可接受(User 裁示閾值)。
2. Grok 契約 review 本 ADR(格式/描述符/驗證計畫)。
3. streaming-tile 契約 ADR 同步凍結 blob tile 序。

## Consequences

- 權重流量 4.96→2.63MB/層(g=64);50–60 tok/s 路徑成立(配 burst+residency)。
- 新增 PTQ 導出器成為權重側 SSOT 工具鏈(L1 golden 所有權在 repo,不再依賴
  TFLM 對權重的 bit 權威;TFLM 仍是 A8/activation 與既有 int8 模型的權威)。
- 失敗回退:g=32(+6% 流量)→ 仍不可 → residency/x32(Grok 決策樹)。
