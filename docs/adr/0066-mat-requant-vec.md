---
status: proposed
date: 2026-07-07
supersedes: []
governs: MAT_REQUANT_VEC — expose mat_engine's existing 64-bit srdhm requant to standalone
         int32 vectors (nonlinear-op requant offload), via a CMD_LOADVEC extension + fused RESCALE
authority: bit-exact vs the EXISTING mat_engine RESCALE (same gemmlowp srdhm/rdbpot) + the
           frozen Gemma goldens (gemma_quant / gemma_quant_s2) + profiler cycle deltas
references: docs/reports/2026-07-07_gemma_layer_cycle_profile.md (measured baseline); ADR-0053
            (requant pipe); ADR-0040/0042 (mat_engine); ADR-0062 (Gemma layer, ewise_mul/RoPE)
---

# ADR-0066 — MAT_REQUANT_VEC:把 mat_engine 現成的 64-bit requant 接給非線性 op(架構確認草稿)

> ⛔ §2 鐵律交付物。**尚未落 RTL**;本文 = Coral 對照 + 契約 + 驗證計畫 + 量測前後投影,經 review 才實作。
> PoC 範圍先只做 **ewise_mul 一個 op**,量到實測 cycle 再決定是否擴到 RoPE。

## §0 動機(實測背書,非臆測)

`profile_gemma_layer.py` 實測一個 Gemma-3 decoder layer(post-RVV-Cycle-1,total **349,824** cycle):
- 非線性 scalar op 佔 ~67%;**MAC 引擎真 busy 只 0.29% wall-clock**;`ewise_mul` **36,966** + `RoPE`
  (q 26,121 + k 6,957 = **33,078**)= **70,044(20% wall)**。
- 這兩個 op 卡住 RVV 向量化的原因是結尾的 gemmlowp **srdhm** requant 需 **64-bit 中間值**,而 Zve32x
  是 **ELEN=32**;srdhm 的 round-half-away + trunc-toward-zero 也不對任何 RVV rounding mode。

**關鍵發現(讀 `mat_engine.v` line 117–145)**:mat_engine 的 RESCALE 段**本來就有一份專用 64-bit
srdhm**:`ab = acc_el * $signed(cur_mult)`(32×32→**64**,line 124)+ nudge/s_sum/q_tz 全 64-bit
(line 132–134)+ rdbpot(line 136–139),**與 golden gemmlowp bit-exact**(ADR-0053)。**ELEN=32 的牆
只是 RVV 的,mat_engine 沒這堵牆。** 故不需「把 mat_engine 加寬成 64-bit」——64-bit 乘法已存在;要做的是
**把這條 requant 接出來服務任意 int32 向量**。

## §1 Coral 對照

Coral/Kelvin 的 activation/requant 跑在**硬體 requant-activation 單元 + 自訂 ML 指令**(閉源
coral-opt 產出)。本 ADR **借用「硬體 requant 服務非線性」這個架構想法**(§4 provenance:Coral
Apache-2.0,借想法記 ADR),但做成**本線的外掛 CQ-driven 風格 + 重用已驗證的 mat_engine srdhm**,
標準 ISA 不動、開源可驗。差異對「可取代」無害:輸出 bit-exact 不變,只是把 requant 從 sequencer 純量
搬到既有硬體。**不複製** Kelvin 的 4-wide / VCQ / 自訂 ISA(ADR-0049 已裁定不做)。

## §2 設計

### 2.1 RTL 改動(additive,不動 S_RUN / S_RSC / 現有 RESCALE)

現有 `CMD_LOADACC`(S_LA,line 253–256)是**廣播**:載 8 個 int32、把 word c 複製到全部 8 列(GEMM
bias-fold 用)。requant 任意向量需要載 **64 個相異 int32**。加一個 mode:

- **新 `CMD_LOADVEC = 3'd5`** + 新狀態 **`S_LV`**(多拍 8-window 載入):8 個 cycle,第 w 拍讀 256-bit
  window(`t_a_rdata`)寫 `acc[bank][w*8 + 0..7]`,`a_ptr += 32`——**重用 S_RUN 的 a_ptr 掃描 pattern**。
  `param_bad`:bank≥4 或 `a_addr[4:0]≠0`(32B 對齊,同 LOADACC)。
- 估 ~15–20 行 RTL。**不加寬 acc**(仍 int32;line 124 的乘法已是 64-bit)。

**三方 review 修正(2026-07-07,Grok ACCEPT + Codex,兩方獨立抓到同一 High)——落 RTL 前必修:**
- **[HIGH · tail 契約] `S_LV` 固定載 64、`S_RSC` 固定出 64 byte——不看 RPT。** `CMD_RESCALE` 一律
  `el_iss=0..63` 寫 16 word / 64 byte(line 221–246,本 ADR 不動它)。故 **len<64 的尾塊會覆蓋
  `dst[len..63]`、`S_LV` 也照讀 256 byte**。**裁定 = padded-64 契約**(對齊既有 GEMM tail-padding 紀律,
  維持 S_RSC 一字不改 = 最 additive):**runtime 把 src 補到 64 個 int32(尾 lane 填 0)、dst 區保證有
  64 byte,消費端只取前 RPT**。RPT 只是 runtime 拆塊/消費長度,**不進 RTL**。(若日後要真 RPT-early-stop,
  另需改 S_LV/S_RSC 計數 = 更大改動,本 PoC 不做。)
- **[MED · param_bad] `CMD_LOADVEC` 要自己的 `param_bad` 分支**(line 158–172):`bank≥4 || a_addr[4:0]≠0`。
  否則 cmd=5 雖現由 default(line 205)trap,加了 S_LV 後 `arg_bank>=4` 會經 `bank_q<=arg_bank[1:0]`
  (line 182)靜默 alias 進 bank 0–3。
- **[MED · t_a_re] `t_a_re` 要含 `state==S_LV`**(line 151):TCM 讀是組合(npu_tcm.v:66),S_RUN 已是
  「讀當前 a_ptr 同拍 +32」;S_LV 照抄。漏了 `t_a_re` 會繞過 ADR-0044 bank-budget checker(npu_tcm.v:148)、
  且未來 gated-SRAM 版會壞。
- **[CLEAN 已確認] 無 transpose**(src[w*8+c]→acc[w*8+c]→dst byte el_iss,線性);**per-tensor bit-exact
  無殘留態**(RESCALE 強制 `pc_mode<=0` line 199、`el_iss/rq_v` 每次 GO reset line 187–188);
  **cmd=5 與 opcode 14 皆空位**(mat_engine.v:63 / cq_defs.vh:17)。

### 2.2 CQ 契約(SSOT `command_descriptor_v0_1.yaml` → .vh/.h/cq_codec)

**新 CQ op `MAT_REQUANT_VEC`(value 14)** — 一個 descriptor 處理 ≤64 個元素(一個 bank):

| word | 欄位 |
|---|---|
| W0 | OPCODE=14, **ACC=bank**(既有 W0[11:8],handler 需要,原草稿漏), RPT=len(≤64) |
| W1 | src_tcm_byte(int32 向量,32B 對齊;runtime 已補到 64 lane) |
| W2 | dst_tcm_byte(int8 輸出) |
| W3 | param_tcm_byte → blob `[mult_q31(u32), (out_zp<<8)|shift(u32), (clamp_max<<8)|(clamp_min&0xFF)(u32)]` |

**Firmware handler**:`CQ_OP_MAT_REQUANT_VEC` = 沿用現有 rescale 韌體樣式——
`csr_write(MAT_A, src)`→`mat_run(CMD_LOADVEC, bank, 1)`→ 寫 `MAT_MULT/MAT_RSP/MAT_CLAMP/MAT_OUT`
→`mat_run(CMD_RESCALE, bank, 1)`。len>64 由 runtime 拆多個 descriptor(每 64 一塊,不同 src/dst 偏移)。
邊界檢查同既有(shift∈[31,62]、dst 對齊、src/dst < 0xF00)。

### 2.3 為何 bit-exact 是「天生的」

`MAT_REQUANT_VEC` 的 requant 用的就是 `CMD_RESCALE` 那條 datapath(line 121–145):同一個
`acc_el * mult`(64-bit)、同一個 nudge/trunc srdhm、同一個 rdbpot、同一個 zp+clamp。而 ewise_mul 的
golden requant(`gemma_quant.requant` → `mat_golden.srdhm/rdbpot`)**本來就是 mat_engine 的 authority**
(ADR-0062:「requant 修到 mat_engine 同源」)。所以 **RTL requant == golden requant 是恆等式**,不是巧合。

## §3 對 ewise_mul / RoPE 的重用

**拆法 = 「RVV 算 int32 elementwise 前段」+「mat_engine 硬體 srdhm 後段」**:

| op | 前段(RVV,int32-safe,不撞 ELEN=32) | 後段(MAT_REQUANT_VEC) |
|---|---|---|
| **ewise_mul** | `prod_i = a_i * b_i`(int8×int8→int16→int32,vwmul+vwcvt),存 int32 到 TCM | requant(mult=qmul(s_gelu·s_up/s_prod),shift,zp=0,clamp[-128,127]) |
| **RoPE** | `acc_i = src_i·cos_q15_i + rot_i·sin_q15_i`(int32,vmul/vmacc;rot 用 vrgather 或 slide 取半旋轉),存 int32 | requant(mult,shift 同 RoPE golden) |

前段全部 int32 放得下(ewise:a·b ≤ 2^14;RoPE:src·cos ≤ 2^7·2^15 = 2^22),**RVV 乾淨可向量化**;後段
64-bit srdhm 走硬體。**兩段合起來 = 現行純量 handler 的 bit-exact 等價**。

> RoPE 的 rotate-half 索引(`rot_i = -src[i+half] / src[i-half]`)在 RVV 可用 `vslidedown`/`vslideup`
> (已驗 D2)或 gather 實現;若 PoC 發現 slide 在 fractional-LMUL 有坑,退回純量取 rot、只向量化 mul+requant。

## §4 驗證計畫

**權威 = bit-exact + profiler cycle,雙軌**:

1. **正確性(bit-exact,不可協商)**:
   - `MAT_REQUANT_VEC` 單元:對隨機 int32 向量,RTL 輸出 == `mat_golden.requant`(逐元素,含 zp/clamp/
     sat/round corner:INT_MIN·mult、負值 trunc-toward-zero、shift∈{31,62} 邊界)。
   - `gate_gemma3_s0_geglu`(ewise_mul 步)/ `gate_gemma3_s2_rtl`(RoPE 步)**沿用現有 golden**——
     改用新路徑後**每 checkpoint 仍 byte-identical**(golden 一字不改;這是 bit-exact 天生的驗收)。
   - `gate_gemma3_layer_rtl` 全鏈重跑綠(x_mid/x_out byte-identical)。
   - **回歸**:S0/S1/S2/S3 + TFLM FC/CNN/MobileNet + 既有 mat gate(gate_45/46/48–52)全綠——證
     CMD_LOADVEC 是純 additive、沒動 GEMM/RESCALE/LOADACC。
2. **效能(profiler)**:`profile_gemma_layer.py` 前後對比 total + ewise_mul/RoPE 單步 cycle。
3. **green-wash 守衛**:①不得改 golden(ewise/RoPE requant 契約凍結,改了即退)②CMD_LOADVEC 的
   bit-exact 要對「64 個相異值」測(防退化成廣播假綠)③RTL requant 不得走 TB 捷徑,必經 mat_engine
   ④shift/對齊/bank 邊界 err ladder ⑤`gate` 用明確檔路徑跑(非 pytest 預設)。

## §5 profiler 量測前後(measured baseline + **projected** after)

Baseline = 實測(post-RVV-Cycle-1,HEAD @9e29d29)。After = **投影**(假設:RVV 前段 ~600–1500 cyc/op;
硬體 requant = ceil(N/64) 塊 × ~60 cyc[LOADVEC 8 + RESCALE 34 + 搬運];CQ orchestration ~1–2k/op):

| 項目 | before(實測) | after(投影) | 備註 |
|---|---:|---:|---|
| ewise_mul(512 elem) | 36,966 | ~2,500–4,000 | RVV a·b + 8×requant 塊 → **~10–15×** |
| RoPE_q+k(320 elem) | 33,078 | ~4,000–6,000 | RVV dot + 5×requant 塊 → **~6–8×** |
| 兩者小計 | **70,044** | **~6,500–10,000** | 省 ~60k |
| **layer total** | **349,824** | **~290,000–303,000** | **~1.15–1.2× 再加速**(疊 Cycle-1 residual 後,對原始 375,672 = **~1.24–1.30×**) |

**ROI 現實(Grok review 修正,誠實界)**:上表 10–15× 是**樂觀上限**。在 seq=4(~512/320 elem)每 op 要
~8 個 descriptor,若每 descriptor 的 CSR/CQ/firmware/spin overhead 是 **~1–2k cycle**(與 profile 的 GEMM
spin-poll 一致),光 orchestration 就 ~8–16k/op → **實際約 2–4×,非 10–15×**。10–15× 只有在 descriptor
overhead 降到 **~200 cyc**(批次 CQ、免 spin-poll、攤提 param 寫)才成立。故 layer 349k→290–303k 的投影
**須與 descriptor de-spin 同一里程碑**才達得到;單獨做本 ADR 在小 shape 下加速會 underwhelm。**優先序裁定
(Grok)**:GEMM orchestration de-spin = **#1**(89% wall 稅、且是本 ADR 卸載的共同稅基)、本 ADR = **#2**,
**並行做、非序列**。

**誠實界**:此步只解 ewise_mul+RoPE(70k)。**RMSNorm 家族(~134k)不在本 ADR**——它的 requant 是
per-row y_adj + per-element wq 的寬鏈,要映上 RESCALE 需**重寫 golden 成 per-row M 乘子 + srdhm
rounding**(另開 ADR);softmax(exp-LUT/divide)也不走 requant 路。整層 ~2–3× 的天花板要 MAT_REQUANT_VEC
+ RMSNorm 重寫 + GEMM 融合三者合力,本 ADR 是其中一塊。

## §6 範圍 / 偏離 / 風險

- **不加寬 acc 到 64-bit**(line 124 乘法已 64-bit;加寬 acc 是白費面積)——這是本 ADR 對「優化成 64-bit」
  問法的明確裁定。
- **out-of-scope**:RMSNorm(需 golden 重寫)、softmax、per-channel requant 向量版(先只 per-tensor)、
  len>64 的單描述子(runtime 拆塊)。
- **風險**:動 mat_engine RTL(雖 additive)——`param_bad`/state 機需完整回歸;`t_a_rdata` 讀時序沿用
  S_LA/S_RUN 已驗路徑,降風險。DC 時序:S_LV 是載入態(非 critical path,critical path 仍 MAC,ADR-0053)。
- **偏離記錄**:借 Coral 硬體-requant 想法(§1,§4 provenance)。

## §7 狀態 / 下一步

- **status: proposed — review 完成、findings 已納入 §2/§5(2026-07-07)**。Grok(架構)= **ACCEPT**
  「64-bit seam 是正確切線、無更好結構」;Codex(RTL 實作實況)= 小 additive ~20 行,datapath/timing/order/
  state 對 full-64 chunk 皆 sound。**兩方獨立收斂於同一 High(tail 契約)+ Codex 兩 Med(W0.ACC / param_bad)
  已全數落回 §2.1/§2.2**。Gemini full-context 一致性由 Claude 代跑(opcode 14 / cmd 5 空位、golden 同源
  確認)。**架構確認通過 → 可落 RTL(照修正後 §2)**。
- **PoC 序**:①SSOT 加 MAT_REQUANT_VEC + CMD_LOADVEC RTL → ②單元 bit-exact(隨機 int32 向量 vs
  mat_golden.requant)→ ③改 ewise_mul 走新路,`gate_gemma3_s0_geglu` 綠 + profiler 量 → ④若達投影,
  再擴 RoPE + `gate_gemma3_s2_rtl`。**先 ewise_mul 一個 op 量到實測再決定擴不擴。**
