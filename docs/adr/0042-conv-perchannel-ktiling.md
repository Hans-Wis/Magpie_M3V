# ADR-0042 — 列 7 收綠切片:CONV_2D + per-channel requant + K>64 tiling

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04「進行 1+2」之 1)。
  Mode:PL design + Grok pre-critique + Codex post-review。
- Date: 2026-07-04
- Relates: ADR-0037/0040(引擎)、ADR-0039/0041(FC lowering / AOT runtime)。

## Coral 對照(§2 第 1 問)

Coral 的主力 workload 是 CNN(MobileNet 類):CONV_2D int8 **per-channel** 量化是
TFLite/TFLM 的預設與大宗。缺 CONV/per-channel,「功能取代」對真實模型不成立。Coral 的
conv 也是壓到矩陣引擎(im2col/隱式 im2col);我們取顯式 **host-side im2col**(AOT runtime
產 A 矩陣),矩陣引擎契約零改動——與 ADR-0041 的 AOT 分工一致。POOL 留給 vector core
(deferred,誠實記錄)。

## 契約(§2 第 2 問)

1. **per-channel RESCALE(引擎新命令 RESCALE_PC,cmd=4)**:CQ `MAT_RESCALE` 以
   **W0.RPT=1** 選擇 per-channel 模式(RPT=0 維持 per-tensor);W1 從 Q31 乘數改為
   **32B 對齊 TCM ptr** → param block:words 0-7 = 8× Q31 mult(一個 256b 窗讀取)、
   words 8-9 = 8× shift bytes(第二讀 @ptr+32)。shift 於 fetch 時逐一驗 31..62,違者
   err_param(MAT_PARAM)。**zp 與 clamp 維持 per-tensor(W2/W3)**——TFLite per-channel
   只有 scale 逐通道(weight zp=0、output zp per-tensor)。datapath 以 column index
   `el[2:0]` 選 cur_mult/cur_shift;INT32_MIN×0x80000000 sat 檢查隨 cur_mult。
2. **K>64 tiling(runtime-only)**:K 切成 ≤64 chunks;每 chunk 發 `MAT_CFG(k=8·chunk)` +
   `MAT_OP(rpt=chunk)` 累加同一 bank(引擎跨 OP 累加本就成立);LOADACC fold 只在最前。
   mod-2³² 環代數 ⇒ chunk 分組與 TFLM 逐 k 順序位元等價(同 ADR-0039 論證)。
3. **CONV_2D lowering(host-side im2col)**:A 矩陣 rows = 輸出像素(8 個一組,尾組
   pad,棄置)、cols = kh·kw·cin **zero-pad 到 8 的倍數**(pad 權重=0 ⇒ 該 lane 乘積恆 0,
   fold 只加總真實權重 ⇒ pad 的 a-byte 內容無關);b/fold/param 按 cout tile(8 通道)。
   每 (pixel-group, cout-tile) job = LOAD_W(blob:fold+param+a_g+b)→ ACC_CLR(fold) →
   per-chunk CFG/OP → RESCALE_PC → STORE(dst_{g,t})。stride/padding:v0 支援 stride 1、
   VALID padding、dilation 1(超界 raise)。FC batch-1:rows pad 到 8、棄置。
4. **SSOT**:MAT_RESCALE 的 RPT=1 模式 + W1 語義入 YAML note;codec `rescale(per_channel
   =...)`;TB ring size 由 meta 檔帶入(conv 一組 job 16 descriptors → ring 32)。

## 驗證計畫(§2 第 3 問)

- **單元(gate_45 part3)**:mat_golden 增 per-channel golden(8 組隨機 mult/shift ×
  隨機 acc,64 bytes 全比)+ shift 越界 err probe。位元權威 = 既有 gemmlowp golden 逐欄。
- **e2e(gate_50)**:真 Keras CNN(input [1,6,6,8] → Conv 3×3 cout=8 **per-channel**
  (K=72:chunks 64+8)→ flatten → Dense(8)(K=128:2 chunks))全 int8 .tflite;
  golden = TFLite **BUILTIN_REF** interpreter 含中間層;conv 輸出(RTL)先驗 bit-exact,
  再以 **RTL 實際輸出** flatten 餵 FC,最終 bit-exact;provenance 重生成。
- Green-wash 守衛:conv 中間層先驗、per-channel scales 必須真的逐通道相異(斷言,
  避免退化成 per-tensor 假覆蓋)、K-chunk 數斷言 ≥2、SSOT regen-diff。

## 結果 + review 處置

gate_45 part3(8 per-channel tiles + shift 越界/對齊 probes)、gate_50(真 CNN:conv per-channel
8 組相異 scale、K=72/128 chunking、conv 中間層先驗 bit-exact、RTL 實際輸出鏈接 FC、最終
bit-exact、provenance byte-級)全綠。Grok 採納:fold 只加真實權重不變量、param fetch 原子性
(busy-lock + 每次 refetch)、err 毒化 job(cq_halt)、shift 越界 DV。Codex(與 ADR-0043 合審):
本 ADR 範圍無 RTL 發現;SSOT scatter 編碼與容量/wrap 檢查歸 ADR-0043 處置。
