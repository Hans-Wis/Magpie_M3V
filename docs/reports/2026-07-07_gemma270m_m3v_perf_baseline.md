# Gemma-3 270M → M3V NPU:計算效能基準與優化計畫(2026-07-07)

> **本文用途 = 單一權威起點。** 過去散落於 profile report / ADR-0066 / RVV Cycle-1 commit / memory 的
> Gemma 效能分析在此整併;之後談 Gemma 效能一律以本文為準,舊筆記僅作歷史。
> **狀態**:功能正確性 = 完成(S0–S5 全層 bit-exact on RTL);計算效能 = 優化進行中(Cycle 1 已落地)。
> **權威**:所有 `measured` 數字來自 `sim/tools/profile_gemma_layer.py`(Verilator,tb_npu_tflm_model
> cycle counter);所有 `projected` 明確標示。正確性安全網 = S0–S5 bit-exact gate。

---

## §1 一眼看懂現況

| 面向 | 狀態 | 一句話 |
|---|---|---|
| **功能正確性** | ✅ 完成 | 一個 Gemma-3 decoder layer 的 S0–S5 全鏈在真 NPU RTL 上 bit-exact(vs Tier-C golden)|
| **效能基準** | ✅ 已量測 | 一層 = **375,672 cyc**(初始)→ **349,824 cyc**(RVV Cycle-1 後,現 HEAD)|
| **瓶頸定性** | ✅ 已定論(推翻數個賽前臆測)| **scalar sequencer core = 89% wall;256-MAC 陣列不是瓶頸(真 busy 0.29%)** |
| **優化** | 🔄 進行中 | Cycle 1(residual 3×)done;下一波受 64-bit requant 牆 + orchestration 稅所限 |

**representative dims**(所有量測):`seq=4, hidden=64, nh=4, head_dim=16, intermediate=128`。這是
**機制完整、dim-independent** 的代表尺寸(同 ADR-0061/0062 紀律);真 270M 尺寸只改 host codegen 的迴圈
次數,不改電路路徑。§8 說明哪些量隨真尺寸變化。

---

## §2 已建置且已驗證(功能面 = 計算效能的地基)

一層 = 22 個 step。GEMM 走 mat_engine(256-MAC);非線性走 sequencer 韌體(scalar rv32im[+RVV]),
**全部在 NPU 內、非 host**(green-wash 鐵律)。每個 op 都有 bit-exact gate 背書。

| 類別 | steps | CQ op | 驗證 |
|---|---|---|---|
| GEMM | q/k/v/o_proj、QKᵀ、AV、gate/up/down_proj | MAT_LOAD_W/OP/RESCALE/STORE | gate_45/46/48–52 |
| RMSNorm(×3)| in / post-attn / pre-ffn / post-ffn | MAT_RMSNORM(rsqrt Q31 定點多項式)| gate_gemma3_s1 |
| RoPE | q / k | MAT_ROPE(neox,int32 Q15)| gate_gemma3_s2 |
| Softmax | 1 | MAT_SOFTMAX(EXP-LUT + uint32 divide)| gate_gemma3_s3 |
| GeGLU 非線性 | gelu_LUT / ewise_mul | MAT_ACT_LUT / MAT_EWISE_MUL | gate_gemma3_s0 |
| Residual(×2)| residual_1 / residual_2 | MAT_EWISE_ADD_REQUANT | gate_gemma3_s1 |

→ **一層完整 bit-exact = 已達成(ADR-0062)。效能是接下來唯一的工作。**

---

## §3 效能基準(measured)

### 3.1 頭條數字（初始 baseline 375,672)

| 指標 | cyc | % wall |
|---|---:|---:|
| **Wall-clock（一層 doorbell→DONE 總和）** | **375,672** | 100% |
| 非線性 steps | 259,119 | **69.0%** |
| GEMM steps | 116,553 | 31.0% |
| — 其中 mat_engine 真 busy | 5,658 | **僅 1.5%** |
| DMA busy(全)| 34,955 | 9.3% |
| **scalar sequencer core active** | ~335,059 | **~89%** |

### 3.2 逐 step（measured,375,672 baseline）

`mat`=引擎 busy,`dma`=DMA/writeback busy,`ret`=退休指令數,`core*`=total−mat−dma(核心 active,含 spin-poll)。

| step | 類 | total | mat | dma | core* |
|---|---|---:|---:|---:|---:|
| RMSNorm_in | 非線性 | 24,276 | 0 | 203 | 24,073 |
| q_proj | GEMM | 13,347 | 680 | 3,618 | 9,049 |
| k_proj | GEMM | 3,492 | 170 | 906 | 2,416 |
| v_proj | GEMM | 3,492 | 170 | 906 | 2,416 |
| QK-norm_q | 非線性 | 30,087 | 0 | 233 | 29,854 |
| QK-norm_k | 非線性 | 7,899 | 0 | 83 | 7,816 |
| **RoPE_q** | 非線性 | **26,121** | 0 | 289 | 25,832 |
| **RoPE_k** | 非線性 | **6,957** | 0 | 139 | 6,818 |
| QKᵀ | GEMM | 3,072 | 146 | 518 | 2,408 |
| softmax | 非線性 | 6,948 | 0 | 249 | 6,699 |
| AV | GEMM | 5,751 | 284 | 905 | 4,562 |
| o_proj | GEMM | 13,347 | 680 | 3,618 | 9,049 |
| RMSNorm_postattn | 非線性 | 24,051 | 0 | 203 | 23,848 |
| residual_1 | 非線性 | 19,251† | 0 | 235 | 19,016 |
| RMSNorm_preffn | 非線性 | 24,342 | 0 | 203 | 24,139 |
| gate_proj | GEMM | 26,598 | 1,360 | 7,236 | 18,002 |
| up_proj | GEMM | 26,598 | 1,360 | 7,236 | 18,002 |
| gelu_LUT | 非線性 | 8,991 | 0 | 355 | 8,636 |
| **ewise_mul** | 非線性 | **36,966** | 0 | 419 | 36,547 |
| down_proj | GEMM | 20,856 | 808 | 6,963 | 13,085 |
| RMSNorm_postffn | 非線性 | 23,979 | 0 | 203 | 23,776 |
| residual_2 | 非線性 | 19,251† | 0 | 235 | 19,016 |

† residual 經 **RVV Cycle-1** 已 19,251 → **6,306**(3.05×);故現況一層 = **349,824**。其餘 step 未動。

### 3.3 mat_engine 內部拆解（5,658 busy cyc)

- **S_RUN(真 MAC):1,104 cyc = 0.29% wall** — 整層的矩陣工作只花 1,104 拍。
- **S_RSC(requant):4,290 cyc = 引擎 busy 的 76%(≈4× MAC)**。
- 其他(LOADACC/CFG):264。
- **空間打包率 50%**:141,312 有效 MAC / 282,624 slot;一半 lane 算 0 = seq=4→8 padding 假影,
  seq 為 8 倍數時消失。

---

## §4 根因分析(實測，推翻數個賽前臆測)

1. **scalar sequencer core 是唯一瓶頸(~89% wall)** — 非線性計算(69%)+ GEMM 編排都卡在它。
2. **GEMM step 是「編排綁死」不是「矩陣綁死」**(推翻賽前猜測):e.g. gate_proj total 26,598 vs
   mat 1,360 + dma 7,236 → **~18,000 拍是核心同步 spin-poll `wait_done`**。韌體把 LOAD_W→OP→RESCALE→STORE
   序列化,引擎/DMA 零重疊。
3. **256-MAC 陣列不是瓶頸,加 MAC 沒用**:整層矩陣只 1,104 拍;512-MAC 陣列只省 ~550 / 375,672。50% 空間
   浪費是 seq=4 假影(真 seq 消失)。**引擎 idle 98.5% 的真因 = (a) requant 佔它自己 busy 的 4× (b) 卡在
   DMA + scalar spin-poll 後面**。
4. **非線性比賽前臆測貴 10×**:64-bit int 運算 + freestanding `__ashrdi3`(變數 64-bit shift)被編成
   **每元素一次 function call**,塞在 RMSNorm/RoPE/requant 內迴圈 + CPI。

---

## §5 requant 牆(為何 RVV 單獨收不了尾)

RMSNorm / RoPE / ewise-mul(佔非線性大宗)全部結尾是 gemmlowp **SRDHM** requant,需 **64-bit 中間值**
(`acc·mult` 可達 2^56):

- **Zve32x 是 ELEN=32** — 沒有 64-bit 向量元素,拿不到那個乘積的高半。
- **SRDHM 的 round-half-away + truncate-toward-zero 不對應任何 RVV rounding mode**(`vsmul`/`vssra`
  都不合)→ 一指令替換不 bit-exact。

**關鍵發現**:`mat_engine.v` line 124 `ab = acc_el * $signed(cur_mult)` **本來就是 32×32→64**,
且與 gemmlowp golden bit-exact(ADR-0053)。**這堵牆只是 RVV 的,mat_engine 沒這堵牆。**

---

## §6 架構原則:協作分工,不是取代(沿 64-bit 縫合線)

> mat-engine 與 RVV 誰都取代不了對方。**沿 64-bit 邊界切成前後段**:

| 段 | 工作 | 交給誰 | 為什麼 |
|---|---|---|---|
| 前段(≤32-bit SIMD)| elementwise 乘、RoPE 旋轉 add/mul、rsqrt 多項式 | **RVV Zve32x** | 純資料並行、32-bit 寬,原生 |
| 後段(64-bit)| SRDHM requant + rdbpot | **mat_engine** | 已有 bit-exact 64-bit 單元;RVV 因 ELEN=32 拿不到 |

**逐-op 路由(由「誰擁有 requant golden」決定,非一刀切)**:

| op | requant golden 歸屬 | 路由 |
|---|---|---|
| ewise_mul、RoPE | **mat_engine 同源**(共享權威,rounding 不能改)| RVV 前段 + **mat_engine 後段**(ADR-0066)|
| RMSNorm 家族 | **Gemma-private**(本線自有)| **可改 rounding**,重寫成 RVV-native,**全留 RVV**(另開 ADR)|

兩個方向都取代不了對方的原因就是 64-bit:RVV 往後段 → 撞 ELEN=32 牆;mat_engine 往前段 → elementwise
塞不進 outer-product 陣列(對角矩陣化 = ≤12.5% 利用率,同 depthwise 坑)。

---

## §7 優化路線圖(依 measured 價值排序)

**優化迴圈** = `profile_gemma_layer.py`(計分)+ S0–S5 bit-exact gate(安全網)。每輪:量 → 改 → 驗 bit-exact → 再量。

| # | 動作 | 攻擊目標(measured)| 投影 | 狀態 |
|---|---|---|---|---|
| **0** | **RVV residual add 向量化** | residual 19,251×2 | residual 3.05× | ✅ **完成**(@b4258c7,layer 375,672→349,824)|
| **1** | **GEMM orchestration de-spin**(引擎跑時發下一塊 LOAD_W、停同步 poll、double-buffer weight)| ~76k GEMM spin-poll + 藏 35k DMA | GEMM step ~2–3× | ⭐ **最高優先**(Grok 裁定 #1)|
| **2** | **ADR-0066 MAT_REQUANT_VEC**(ewise_mul + RoPE requant 卸給 mat_engine 64-bit)| 70,044(20% wall)| **~2–4×**(見下)| review ACCEPT,**待落 RTL** |
| **3** | **融合 Q/K/V + gate/up GEMM**(共享輸入一次載入、攤提 requant setup)| GEMM round-trip | 中 | 規劃 |
| **4** | **RMSNorm 家族**(~134k,最大宗;移除 per-element `__ashrdi3`,golden 重寫成 RVV-native rounding)| 134k | 顯著 | 另開 ADR(未寫)|
| **5** | **softmax 倒數乘法**取代 per-element uint32 divide | softmax(隨 seq² 成長)| 真 seq 下顯著 | 規劃 |

**#1 + #2 疊加粗估**:非線性 259k→~70k、GEMM 116k→~50k → **一層 ~3×**,全在已驗證 datapath 上、由 S0–S5
golden 守護。

### 7.1 ADR-0066 三方 review 結論(2026-07-07)

- **Grok(架構)= ACCEPT**:「64-bit seam 是正確切線,無更好結構」。
- **Codex(RTL 實作實況)**:~20 行 additive,full-64 chunk 的 datapath/timing/order/state 皆 sound。
- **兩方獨立收斂於同一 HIGH + Codex 兩 MED(已全數落回 ADR §2)**:
  - **[HIGH] tail 契約**:`CMD_RESCALE` 一律出 64 byte 不看 RPT → **padded-64 契約**(runtime 補 src 到
    64 lane、只取前 RPT,RTL 不改 S_RSC)。
  - **[MED] W0 補 `ACC=bank`**(用既有 W0[11:8]);**[MED] `CMD_LOADVEC` 加自己的 param_bad + `t_a_re`
    含 `S_LV`**(否則繞過 ADR-0044 bank-budget checker)。
  - CLEAN:無 transpose、pc_mode/el_iss/rq_v 無殘留、cmd5 + opcode 14 皆空位。
- **ROI 現實(Grok 修正,誠實界)**:原草稿 **10–15× 是樂觀上限**。seq=4 每 op ~8 descriptor,每個
  ~1–2k orchestration 稅 → **實際 ~2–4×**;10–15× 只有 descriptor overhead 降到 ~200 cyc 才成立。
  **故 ADR-0066 須與 #1 de-spin 同一里程碑、並行做**——否則小 shape 下量到的加速會 underwhelm。

---

## §8 誠實界(這份報告不宣稱的東西)

- **representative dims ≠ 真 270M 尺寸**。量測是機制驗證;真尺寸下**隨 seq/hidden 變化的量**:GEMM 空間
  打包率(seq=4 的 50% 浪費消失)、softmax(隨 seq² 成長)、descriptor 數(隨向量長度線性)。**引擎 vs
  核心的定性比例(89% scalar)在真尺寸下方向不變**,但絕對數會重量測。
- **§7 的 projected 全是投影**,未落地前不算數;每輪落地都要 profiler 實測 + bit-exact 重驗才更新。
- **未做**:整層 fuse 成單一 in-NPU CQ program(中間值全留 DTCM、免 host round-trip)= #3 之後的更大題;
  真 270M 端到端(多層 + KV-cache + 多 token)= host runtime,不在本文電路層範圍。
- **本文只談計算效能**,不談面積/功耗(Phase 7 PPA 簽核另計)。

---

## §9 參考(SSOT 指標,終結混亂)

| 主題 | 權威來源 |
|---|---|
| 逐 step profile 原始量測 | `docs/reports/2026-07-07_gemma_layer_cycle_profile.md` |
| 功能面 S0–S5 bit-exact | ADR-0062;memory `gemma3-layer-e2e` |
| requant 卸載架構確認 + review | `docs/adr/0066-mat-requant-vec.md`(status: proposed,review 已納入)|
| requant pipe / mat_engine | ADR-0053(2-stage pipe)、ADR-0040/0042(256-MAC + per-channel)|
| RVV Cycle-1 residual | commit @b4258c7 |
| 重跑 harness | `python sim/tools/profile_gemma_layer.py`(Verilator,建 npu_top+cpu_m1,跑 22-step 鏈)|
