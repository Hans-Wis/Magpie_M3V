# ADR-0051 — 矩陣引擎微架構優化(架構確認,Route A)

- Status: **PROPOSED**(§2 架構確認;User 裁示 2026-07-05「始架構優化評估」)。
  **這是評估/確認,尚未落 RTL**——經 review accepted 後才進實作(§2 鐵律)。
- Date: 2026-07-05
- Mode: Fable 設計 + Grok 架構複核(全文歸檔 scratchpad + 本 ADR 綜整)+ 我方獨立分析。
- Relates: ADR-0037(mat_engine v0.1)、ADR-0040(256-MAC + Class B 埠偏離)、
  ADR-0042(per-channel requant)、ADR-0044(記憶體/埠偏離)。
  前置分析:`docs/reviews/2026-07-04_control_path_and_mac_scaling_grok.md`。

---

## §1 Coral 對照(§2 第 1 問)

我們維持「scalar 編排 + 外掛加速器 + 單發 256-MAC」形狀(Route A),**不**複製 Coral
的 4-wide MAC 或硬體 VCQ。優化目標不是改變功能對等,而是讓已驗證的 mat_engine 達到
可簽核的時脈/吞吐。Coral 對照的意義在此階段是:埠寬(Coral 單 128-bit vs 我們 2×256b,
Class B 偏離已記)與吞吐數字(256 MAC/cycle 對齊)——本階段**保吞吐、暫不追埠寬對等**
(見 §4 判斷 3)。

---

## §2 現況 critical path 分析(事實 + 誠實界)

`mat_engine.v` 兩個組合熱點(行號對 2026-07-05 HEAD):

| 候選 | 結構 | 需求 | 疑似限制 |
|---|---|---|---|
| **S_RUN**(197-206) | 2×256b TCM mux → 256×(int8×int8→int17)→ 64×(4:1 signed tree 17→32b)→ 64×(acc+psum)**同拍** | 1 rep/cycle 持續 | 寬×深×繞線 + **loop-carried 累加**(連續 rep 同 bank,禁止直接 retime 最後那個 add) |
| **S_RSC**(117-135) | 單一 32×32→64b signed 乘 + SRDHM nudge + RoundingDivideByPOT + clamp | 1 element/cycle | 單一深乘法器(~6-8 有用邏輯級),窄、無 loop carry |

> ⚠️ **誠實界(§4)**:cpu_m1_top 有 DC trial(~699MHz),但 **npu_top/mat_engine 從未
> synthesis**——上表「疑似限制」是**結構推論,非量測**。故本 ADR 第一項實作前置動作 =
> **先量路徑**(見 §4 執行序 step 0/2)。
>
> **step 0/2 已完成(2026-07-05,真 Synopsys DC + TSMC28,取代 yosys 估計)**:見下 §2.5。
> **量測直接推翻本節「S_RUN 首要嫌疑」的推論**——保留原文以存誠實界紀錄:先量再動擋掉了
> 一次誤判。

## §2.5 量測結果(Synopsys DC X-2025.06-SP2 + TSMC 28HPC+,2026-07-05)

flow = `flow/dc_tsmc28/`(照 lab `rv32_lab18` 結構;`tcbn28hpcplusbwp40p140` tt 0.9V 25C
= **cpu_m1 那次 699MHz 的同一顆庫**)。mat_engine 純 std cell(內部無 SRAM)。方法:256-bit
`t_a/t_b_rdata` input_delay≈0(等同 ADR S0 registered-read 模型),兩組 clock 目標交叉驗證。

| 目標 clk | 結果 | worst path 終點 | 意義 |
|---|---|---|---|
| 2.0ns(500MHz) | slack 0(達標)| S_RUN(`rep_i→acc_reg`)與 S_RSC(`rs_mult→pack_q`)**並列 slack 0** | DC 一達標就用慢 cell 平衡,兩路皆 0 → 僅證 Fmax≥500MHz |
| **1.2ns(積極)** | **WNS −0.17、255 違規** | **30/30 worst 全 `→pack_q_reg`(S_RSC requant)** | **真 critical path = requant;S_RUN 完全掉出 worst-30** |

**量測定論(數字取代推論)**:
1. **mat_engine Fmax ≈ 730 MHz**(critical path 1.25ns 邏輯 + ~0.12 uncertainty/setup ≈ 1.37ns
   min period)。面積 85.7K µm²(max effort)/ 76.6K(relaxed),~97K cells。
2. **真 critical path = S_RSC 的 32×32 signed requant 乘法**(`acc_el * cur_mult` → 64b →
   SRDHM → RoundingDivideByPOT → pack_q)。worst path = `el_i_reg→pack_q_reg[30]`,64 level,
   cell 鏈是典型 FA1D/XNR2/AOI 乘法器 partial-product tree + 進位。**S_RUN 的 256-MAC 累加
   在積極時序下不是瓶頸**(掉出 worst-30)。
3. **premise 推翻**:「mat_engine 256-MAC 是 npu_top critical path、先流水 S_RUN」**不成立**
   ——mat_engine ~730MHz **快於 cpu_m1 ~699MHz**,整個引擎不是系統瓶頸;且引擎內部的瓶頸是
   requant 非 MAC。**若照原 ADR 只流水 S_RUN,等於優化一條非關鍵路徑,requant 會立刻變新
   天花板,Fmax 原地不動。** 這正是 §4「先量再動」的價值實證。

**判斷**:S_RUN 是 npu_top Fmax 首要嫌疑(寬組合樹 + 同拍回授),**先切**;S_RSC 是次要
且**條件性**(僅當 requant-bound 或 synth 證明其 slack ≤ S_RUN 才動)。**不先切 S_RSC**
——它已 1/cycle,削它無益,而軟體仍在每 op 燒 ~10 拍 store。

---

## §3 契約:S_RUN 流水化 + 累加 hazard 安全方案(§2 第 2 問)

**核心不變量:最終 acc 值必須逐位等同今日**(mat_golden.py 權威),只准改「何時算完」。

### 3.1 流水段(3 stage + 組合累加)

```
S0 RD  : reg{bank,rep,lane_en,tcm_addr} → 組合 TCM 讀(既有 2×256b,不動)
S1 MUL : reg t_a/t_b_rdata[255:0]       → 256× int8×int8→int17(lane_en 遮罩留此)
S2 TREE: reg prod[255:0]                → 64× 4:1 signed tree → psum[63:0](32b)
S3 ACC : 組合 acc_in + psum → acc_next;僅 acc 陣列寫入 register
```

- register 放 讀→乘、乘→樹、樹→累加 之間;**不**在 4:1 樹內插 register(保今日
  逐級加寬拓樸 → 中間位元逐位不變)。
- 累加保持**單一組合 32b add**(淺,非關鍵路徑),只 register acc 寫回。

### 3.2 loop-carried 累加 = forwarding 非 bubble

連續 rep 打同 bank;rep k 需 rep k-1 的 `acc_next` 非 stale `acc_reg`。每 (bank,cell) 維護:
- `acc_reg[bank][ci]`:架構 acc(語義不變)。
- `acc_fwd[bank][ci]` + `acc_fwd_v[bank]`:上一個完成的 S3 之值(bypass register)。

```
acc_in[ci]   = acc_fwd_v[bank] ? acc_fwd[bank][ci] : acc_reg[bank][ci]
acc_next[ci] = acc_in[ci] + psum[ci]            // lane_en 只在 S1 遮罩,關閉 lane 貢獻 0
S3 尾:acc_reg<=acc_next; acc_fwd<=acc_next; acc_fwd_v<=1
```

bank 切換 / ACC_CLR / 新 CMD_OP 首 rep:清 `acc_fwd_v[new_bank]`,用 acc_reg。單發入 S0
→ 每拍僅一 rep 在 S3 → 從**上一拍**的 acc_fwd register 轉發即足,**零 bubble**。
drain:CMD_OP 末 rep / FENCE 時,擋新 issue 直到 `inflight[bank]==0`(每 bank 3-entry 計數)。

### 3.3 延遲與 bit-exact 論證

| 指標 | 值 |
|---|---|
| pipeline fill(首 rep → 首 acc 寫) | **4 拍**(S0..S3) |
| 穩態 issue rate | **1 rep/cycle** |
| loop-carry 罰則 | **0**(bypass) |

**逐位相同**:forwarding 代數上 `acc[k]=acc[k-1]+psum[k]`,同今日 32b 二補數加;psum 計算
與樹拓樸不變;lane_en 仍在 S1;rep 序由單發入 S0 保序。∴ 最終 acc == mat_golden.py。

### 3.4 拒絕的替代(記錄)

- 全 4-stage 含 registered acc:同 bank 鏈每 rep 1 bubble(除非複雜多 entry bypass),
  淺 add 下無 Fmax 收益卻掉 IPC。
- 跨 rep partial-sum 重結合:破壞逐 rep 累加序,無跨全點積鏈的溢位頭空間論證 → 不可。

---

## §4 驗證計畫 + 執行序(§2 第 3 問)+ 路線判斷

### 路線判斷(本 repo 本階段)
**Route A SELECTED**(scalar 編排 + 外掛 mat_engine + 流水內部)。
B(多引擎/Coral 4-wide)REJECTED = 換平台;C(CPU 向量化 MAC)REJECTED = 破加速器形狀。

### 埠寬判斷(§2 第 3 問之 128b)
**維持 2×256b + 流水;本階段不縮 128b。** 縮 128b → 需 ≥2 讀拍餵 256 MAC(≤0.5 rep/cycle)
除非加 weight-stationary micro-buffer(那是餵料協定改動,非既有 outer-product datapath 優化)。
128b 只在有明確 weight-stationary 時才划算 → **簽核後**做面積/功耗審計時再議,非 Fmax。

### double-buffer vs descriptor batching(§2 第 4 問)
根因 = 軟體序列化(單發核每 MAT_OP ≥3 store A/B/CTRL)≈10+ 拍,**非** GO→MAC 硬體延遲。
- **#1 descriptor batching / autonomous MAT_OP**:把 {ptr_a,ptr_b,ctrl,reps,bank} 埋進 CQ
  128b descriptor(或每層載一次 shadow reg),sequencer 自走 reps 免逐 op scalar store。
  CPU 只 doorbell + ring advance。省 ~10 拍/op → ~0-1 amortized。**短 K 時主導 wall-clock**。
- **#2 operand double-buffer(TCM 側 ping-pong)**:僅在 read 有 register 化時藏 1 拍;
  CPU 仍卡 store 時無用。
- **#3 engine 側 double-buffer(acc)**:**無益**——同 bank 累加本質序列,forwarding 已解 RAW。

### 執行序(**2026-07-05 依 §2.5 量測重排**)+ 驗證 hook + green-wash 守衛

> 原序(step 0 yosys → step 1 流水 S_RUN → step 2 DC…)已作廢:DC 量測證 mat_engine
> ~730MHz(快於 cpu_m1),且引擎內瓶頸是 requant 非 MAC。**流水 S_RUN 從「強制第一」降為
> 「選配/暫不做」**。重排如下:

| 序 | 工作 | 強制性 | 驗證 hook / 守衛 |
|---|---|---|---|
| **0** | **mat_engine DC TSMC28 Fmax + 路徑定位** | ✅ **已完成**(§2.5) | Fmax≈730MHz、critical=S_RSC requant、S_RUN 非瓶頸 |
| **1** | **npu_top 全 DC**(含 TCM SRAM macro / AXI-Lite CSR / DMA path) | **強制** | 找**系統級**真瓶頸(mat_engine 已非嫌疑);需 SRAM .db(見 lab sram/ 流程) |
| **2** | **CQ autonomous MAT_OP**(消 per-op A/B/CTRL store,~10 拍/op 軟體稅) | **強制**(**perf 最高 ROI**——Grok+量測皆指此非 MAC 路徑) | gate_35..39 CQ 等價 + gate_48/49/50 TFLM e2e bit-exact |
| **3** | **S_RSC requant 2-stage pipe**(reg 32×32 乘積 → reg round/sat/pack) | **條件**(僅當 step 1 證 npu_top 想推 >730MHz 且路徑仍在 requant) | mat_golden.py rescale 向量 bit-exact |
| **4** | **S_RUN 3-stage pipe + acc_fwd bypass**(§3 契約仍有效,備用) | **選配/暫不做**(非關鍵路徑;僅若未來 tile/lane 擴張使 MAC 重回關鍵才啟用) | mat_golden.py 全 corner 不變 + throughput 重 baseline |
| **5** | **TCM read register / 128b weight-stationary** | **Defer**(簽核後面積/功耗) | 需新 ADR + 餵料契約 |
| **6** | **VCS / Spyglass / coverage 簽核** | **強制終點** | 既有簽核 gate |

**§3 的 S_RUN 3-stage + acc_fwd 契約不作廢**——它是正確的 MAC 流水方案,只是**量測證明現在不需要**;
若未來擴 tile/lane 或 npu_top synth 顯示 MAC 重回關鍵路徑,直接取用(備用契約)。

**green-wash 守衛(本階段特有)**:
1. **throughput gate 重定 baseline 不得掩蓋回歸**——必須明文 assert:(a) 穩態 == 1 rep/cycle、
   (b) fill == 剛好 pipeline 深度(4 拍)、(c) 總 cycle == fill + reps。不准只把數字調大放行。
2. **bit-exact 是硬門檻**:pipeline/forwarding 任何改動後 mat_golden.py 全 corner 必逐位綠;
   一格不符即退。
3. **路徑定位先於流水**(step 0 先於 step 1):不得「猜路徑在 S_RUN」就動——先量。
4. VCS/DC 在 **sandbox 外**(§5 引擎政策),yosys/spike 在內。

---

## §5 review 後才實作(§2 第 4 問)

本 ADR = 架構確認。**accepted 後**:step 0(yosys 路徑定位)先跑產證據 → 若證實 S_RUN
為路徑,Codex 外科實作 step 1(3-stage pipe + acc_fwd)→ 我方跑 mat_golden bit-exact +
throughput 重驗 → commit → step 2 外部 DC → 依 slack 決 step 3/4。**沒有路徑證據與 review
不落 RTL。**

---

## 附:與 Grok 架構複核的收斂

Grok(架構師角色,§5)全文歸檔 session scratchpad。核心判斷四方一致:①先切 S_RUN
②3-stage + 組合累加 forwarding(4 拍 fill、1 rep/cycle、bit-exact)③維持 2×256b
④descriptor batching ≫ double-buffer。我方獨立補強 = **step 0 in-sandbox yosys 先量路徑**
(誠實界:目前 critical path 是推論非量測)+ throughput 重 baseline 的 green-wash 守衛。
