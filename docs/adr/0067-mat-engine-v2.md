---
status: proposed
date: 2026-07-07
authors: Grok (v2 architecture draft) · Claude (evaluation + LANES SKU + PPA) · User (裁示)
governs: mat_engine v2 = 「凍結 MAC datapath + 新控制殼(autonomous GEMM tile sequencer)」+
         SKU 參數 LANES∈{1,2,4}(64/128/256 MAC)供客戶選面積/功耗檔位
supersedes: []
references: design/npu/docs/mat_engine_v2.md (Grok 架構草稿全文);
            docs/reports/2026-07-07_gemma270m_m3v_perf_baseline.md (perf SSOT);
            docs/reports/gemma_opt_ledger.md (優化台帳);
            ADR-0037/0040/0042 (mat_engine v1 datapath, frozen);
            ADR-0052 (CQ autonomous MAT_OP, E1/E2/E3 等價框架);
            ADR-0053 (requant 2-stage pipe, DC critical path);
            ADR-0066 (MAT_REQUANT_VEC / CMD_LOADVEC — 本 ADR 的 Phase-B 依賴,已於 E1a 實作驗證);
            ADR-0051 (DC TSMC28 flow, flow/dc_tsmc28/)
authority: mat_golden.py + Gemma S0–S5 gate + gate_45..52 語義不變(E1 CSR-stream 等價);
           PPA = 真 Synopsys DC + TSMC28（flow/dc_tsmc28/）
---

# ADR-0067 — mat_engine v2:控制殼(autonomous tile sequencer)+ LANES SKU(64/128/256 MAC)

> ⛔ §2 鐵律交付物。**status: proposed** — 架構確認,經 review + PPA 坐實才落 RTL。
> Grok 架構草稿全文在 `design/npu/docs/mat_engine_v2.md`;本 ADR = **決策 + 評估 + LANES SKU + PPA**。

## §0 決策摘要

1. **接受 v2 方向**:mat_engine v2 = **凍結 v1 MAC datapath(S_RUN/S_RSC)+ 新硬體控制殼
   `npu_ml_ctrl`**(autonomous GEMM tile sequencer + cmd FIFO + DMA overlap),攻**per-tile 韌體編排稅**,
   不動 MAC 數學。此方向與 Claude 的「韌體極限」獨立分析收斂(見 §1)。
2. **新增 SKU 參數 `LANES∈{1,2,4}` → 64/128/256 MAC**(synth-time),讓客戶按 workload 選**面積/功耗**檔位。
3. **誠實修正**:v2 **不是「輕度修改」**——datapath 輕(MAC 凍結),但它是一個 **~500 行的新硬體控制
   子系統**,把 GEMM 編排從已驗證的韌體搬進必須驗證的硬體 FSM(驗證負擔 + 未來 lowering 僵化)。
4. **執行順序**:軟體軌(RVV 非線性 + RMSNorm golden 重寫,零 RTL)與硬體軌(v2 Phase A)**並行**;
   Phase A 先在單一 GEMM(k_proj)PoC 用 **E1 CSR-stream 等價**驗證。**不把軟體卡在硬體後面**
   (Grok 草稿把 RMSNorm 放 Phase C 最後,ROI 順序反了)。

## §1 Context — 為何要 v2(實測背書)

`profile_gemma_layer.py` 實測一層 = **349,824 cyc**,scalar core **~89% wall**,256-MAC 真 busy **0.29%**。
Claude 從實測反推 GEMM 編排成本律(同類不同大小 GEMM 回歸):

> **GEMM core\* ≈ 100 + 1,119 × tiles**(截距 ≈0)→ **~1,120 cyc/tile 幾乎全是 per-tile 韌體固定稅**
> (每 tile ~6 CQ-op × ~187 cyc:LOAD_W+ACC_CLR+CFG+OP+RESCALE+STORE)。

**這是韌體改不掉的硬底**(向量化碰不到、融合只減 step 不減 tile)。**唯一能拆它的是硬體**——讓引擎自己
走 tile、免每-tile 韌體 round-trip。這正是 v2 Phase A。

**應用尺度 justification(Grok 草稿低估了、本 ADR 補上)**:per-tile 稅是 O(tiles),tiles 隨真模型爆炸。
Gemma-3 270M **LM head** = [·×640]×[640×**262144**] 每 token → ~32,768 tile × ~33 CQ-op × 187 cyc
≈ **~2 億 cyc/token 純編排稅**(vs 真 MAC ~65 萬 cyc,編排 = 計算 56×)。**在真應用尺度,autonomous
sequencer 不是可選優化,是應用可行性的必要條件。** (此為外推;per-tile 律已實測,tile 數為算術,絕對值待 re-profile。)

## §2 Decision A — v2 控制殼(見 mat_engine_v2.md §3–§7)

採用 Grok 草稿的模組切分(`npu_ml_ctrl` / `ml_tile_seq` / `ml_cmd_fifo` / `ml_overlap`)、E1/E2/E3
等價框架、legacy_bypass default(零回歸)、§10 scope-cut(拒絕:加寬 acc 64-bit、512-MAC、第二引擎、
Norm/Softmax 塞進 MAC)。**MAC 數學(S_RUN/S_RSC)凍結。** 修正 Grok 草稿兩點:
- **framing**:標成「新控制子系統」非「輕度修改」;主 justification 用 §1 應用尺度 per-tile 稅。
- **順序**:軟硬並行;Phase A 先 k_proj PoC。
- **依賴已就緒**:草稿 §6 Phase-B 的 `CMD_LOADVEC` **已於 ADR-0066 E1a 實作 + bit-exact 驗證**
  (單元 134 checks + gate_45/46 回歸綠),不需重做。

## §3 Decision B — LANES SKU(64/128/256 MAC)⭐ 本 ADR 新增

### 3.1 動機與幾何

MAC 陣列 busy 0.29%(seq=4)——**閒置的 MAC 是面積/功耗的浪費**。mat_engine = **8×8 輸出 tile ×
`LANES` 個 K-step 融合/拍**(ADR-0040)。參數化很自然:

| SKU | `LANES` | MAC/cyc | 幾何 |
|---|---|---:|---|
| 256(現況)| 4 | 256 | 8×8 tile × **4** K/拍 |
| 128 | 2 | 128 | 8×8 tile × **2** K/拍 |
| 64 | 1 | 64 | 8×8 tile × **1** K/拍 |

減 LANES = 減 K 方向並行乘法器 + 加法樹(+ 窄化 TCM 讀埠使用)。**MAC 陣列是主要面積 → 真省。**

### 3.2 這是「面積/功耗」取捨,不是免費(誠實界)

減 MAC **不提速**(甚至 compute-bound 時變慢);它拿「反正閒著的 MAC」換面積功耗。是否掉速看**算術強度**:

| workload | 特性 | 減到 64 MAC |
|---|---|---|
| **Decode(1 token/次)/ LM head** | 權重串流、**頻寬綁定** | ✅ 幾乎不掉速(DMA 是地板)→ **64 SKU 最佳** |
| **Prefill(大 seq)/ batch 大** | 權重重用、**計算綁定** | ⚠️ compute 慢 ∝ 1/LANES → 要 256 |

→ edge 推論(batch=1 decode)絕大多數頻寬綁定 → **64 MAC 幾乎不掉速、面積功耗大省**。**這正是「讓客戶
選」的理由**:不同 workload 最佳 MAC 數不同。對標 Coral(固定邊緣 int8 decode)→ 預設 64/128 即足,
256 當高階選項 = 對 Coral 的**面積/功耗優勢**。

### 3.3 正交性 + bit-exact

- **與 v2 sequencer 正交**:v2 修編排(89% 瓶頸),LANES 調 MAC 面積功耗。兩者疊加不衝突。
- **不修 50% 空間浪費**(那是 M<8 padding,seq 為 8 倍數時消失;屬空間 tile,LANES 調時間 K)。
- **不提 Fmax**(critical path 是 requant S_RSC,ADR-0053,非 MAC)。
- **bit-exact 不破**:整數累加對 2³² 可結合,4-lane 樹 vs 1-lane 逐加逐位相同 → **同一份 golden/gate 驗所有
  LANES**。(gate_45 golden-exact @LANES=4 已為 refactor 把關;LANES=1/2 by construction 相同。)

### 3.4 PPA 三檔實測(真 Synopsys DC + TSMC28 28HPC+ tt0.9v25c,`synth_mat_lanes.tcl`,CLK=1.2ns)

同一 clock(requant 限制,三檔同 Fmax、皆 slack 0 達時序),差異純 MAC-tree:

| SKU | LANES | MAC | 面積(µm²) | 面積 vs 256 | 功耗(mW) | 功耗 vs 256 | 說明 |
|---|---|---:|---:|---:|---:|---:|---|
| **256** | 4 | 256 | **83,868** | 1.00× | **50.77** | 1.00× | 現況;prefill/batch/compute-bound |
| **128** | 2 | 128 | **61,644** | **0.74×(−26%)** | **36.18** | **0.71×(−29%)** | 平衡檔 |
| **64** | 1 | 64 | **50,515** | **0.60×(−40%)** | **29.16** | **0.57×(−43%)** | decode/edge 最佳(對標 Coral)|

**關鍵發現(誠實界)**:面積/功耗**不隨 MAC 數線性下降**(256→64 是 4× 少 MAC,但面積只 −40%)。因為
mat_engine 的 **acc 4-bank(4×64×32b flop = noncomb 16,446 µm²)+ requant datapath(S_RSC)+ FSM/TCM port
邏輯是 LANES-independent 固定成本**;只有 MAC 乘法樹隨 LANES 縮。→ **64 SKU 省 ~40% 面積 / ~43% 功耗**
(可觀但受固定開銷 bound,非 −75%)。**進一步榨取需整合層窄化 TCM 讀埠**(256b→64b @LANES=1),列後續。
> report_power 用 DC 預設 activity(相對比較足夠;真 SAIF 動態功耗待 gate-level sim)。報告:`reports/dc_mat_lanes/L{1,2,4}/`。

### 3.5 整合 + 驗證(LANES 貫穿全鏈,非只 mat_engine)⭐

**避免「設了參數但只 MAC 變、其他沒動」——LANES 已延伸到整合層與驗證:**
- **整合**:`npu_top` 加 `parameter MAT_LANES=4` → `mat_engine #(.LANES(MAT_LANES))`;`tb_npu_cq_mat` 加
  `MAT_LANES` 貫穿。頂層設 LANES 真的配置 MAC(default 4 行為 byte-identical)。
- **驗證(`gate_84_mat_lanes_sku`,Claude 獨立跑 2 passed)**:①mat_engine golden-exact TB 在 **LANES=1/2/4
  各自 rebuild** 皆 `MAT_ENGINE_PASS` + 全 part counts + 0 errors(整數累加可結合 → 三檔逐位相同,同一 golden)
  ②**npu_top e2e 在 `-GMAT_LANES=1` 真跑**,`NPU_CQ_MAT_PASS` + tile byte-for-byte vs mat_golden(證整合路
  非只獨立 MAC)。回歸:default gate_45/46 = 3 passed 不變。

## §4 驗證計畫

- **v2 控制殼**:E1(mat CSR-stream 等價,gate_67_ml_v2_equiv)+ E2(HEAD/IRQ/ERR gate_35–39)+
  gate_45/gemma3_layer bit-exact(legacy path)+ profiler 證 ≥2×(Phase A on k_proj)。
- **LANES SKU**:同一 bit-exact gate 跑三個 LANES build(gate_45 golden-exact 為權威)+ 三份 DC PPA。
- **green-wash 守衛**:不改 mat_golden 遮分歧;legacy path 全程綠;throughput 宣稱與 bit-exact 宣稱分開;
  PPA 宣稱必附 DC 報告路徑。

## §5 Consequences

- **正面**:攻真瓶頸(編排)+ 給客戶 PPA 檔位;對 Coral 面積/功耗有優勢。MAC 數學零風險(凍結)。
- **代價**:v2 是新硬體控制子系統(~500 行 + 等價驗證 + lowering 僵化)。LANES=1/2 掉 prefill 吞吐
  (datasheet 誠實標)。
- **偏離**:借 Coral「低開銷串流命令發射」想法(control-plane parity,非 backend port);記 provenance。

## §6 下一步

1. 三檔 PPA 填表(本輪跑中)。2. Grok/Codex review 本 ADR。3. Phase A:k_proj PoC(ml_tile_seq +
cmd_fifo)+ gate_67 E1 等價。4. 軟體軌並行(RVV 非線性 / RMSNorm golden,另 ADR)。
