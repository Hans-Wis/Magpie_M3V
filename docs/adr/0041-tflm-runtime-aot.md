# ADR-0041 — Phase 6 續:TFLM runtime 整合(AOT 編譯形)— 真 .tflite 模型多 op e2e

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04「先(b) 再做(a)」)。
  Mode:PL design + Codex/Grok review。
- Date: 2026-07-04
- Relates: ADR-0039(FC lowering 契約)、ADR-0040(256 MAC)。

## Coral 對照(§2 第 1 問)

Coral 的軟體路徑是 **AOT 編譯**:.tflite → edgetpu_compiler/IREE(閉源)→ 裝置可執行流。
我們的開源對等物同形:**離線** `.tflite → 抽取器(TF 只在離線端)→ 中立 model.json + 權威
golden 向量**;**線上** `tflm_runtime.py`(不依賴 TF)把 model.json 逐 op 下降成 CQ 批次 +
TCM blob,跑在真 RTL 上。Host runtime 是「載入編譯產物 + doorbell + 收 IRQ」——正是 Coral
libedgetpu 的角色分工。**golden 權威 = TFLite Interpreter 強制 reference kernels
(`OpResolverType.BUILTIN_REF`,即 TFLM 參考語義)**,含中間層張量(preserve_all_tensors)。

## 契約(§2 第 2 問)

1. **模型**:真 Keras→TFLite 全 int8 量化 2 層 MLP:input int8 [8,16] → Dense(24, fused
   ReLU) → Dense(8) → [8,8]。刻意選形:N1=24 = **3 個 column tiles**(引擎 8 欄)、
   K2=24(RPT=24)、batch=8(陣列全利用)、fused ReLU(clamp=max(-128,zp),127)。
   `.tflite` + model.json + golden 檢入 repo(供 gate 無 TF 也能跑);另設 provenance 測項
   (有 TF 時重生成並比對,無 TF 標 skip——誠實 not-run,不假綠)。
2. **Runtime lowering(泛化 ADR-0039)**:每層一個 LOAD_W blob(fold×tiles + a 共用 +
   b×tiles)+ ring:CFG、LOAD_W、每 tile(LOADACC fold_t → OP(a,b_t) → RESCALE → STORE
   dst_t);ring size 16。requant 參數走 **TFLM `QuantizeMultiplier`**(double frexp →
   Q31+shift;僅支援右移 → engine shift=31−s ∈[31,62],左移即 raise)。per-channel 權重
   量化:全等 scale 才收斂,否則 raise(scope 誠實)。K≤64/層(K-tiling 留擴充)。
3. **多 op 鏈接(關鍵誠實點)**:layer2 的輸入 = **layer1 在 RTL 上的實際輸出**(gate 從
   TB dump 讀回、host 端 repack 成 a-向量 blob)——repack 在 host(v0),on-NPU transpose
   (vector core)列為後續。層間張量 = int8 requantized,經 shared mem 往返,同 Coral 卸載形。

## 驗證計畫(§2 第 3 問)

gate_49:round 1 跑 layer1(真 RTL 全迴圈)→ **先斷言 layer1 輸出 == Interpreter 中間層
bit-exact** → 用 RTL 實際輸出 repack → round 2 跑 layer2 → 最終輸出 == Interpreter 輸出
bit-exact。TB(tb_npu_tflm_model)meta-driven(TAIL 數/結果位址/字數自檔案),結果 dump 回
host 供鏈接。Green-wash 守衛:中間層先驗(不許只對最終值)、provenance 測項、descriptor 只准
經 SSOT codec、per-channel/左移 raise 而非靜默。

## 結果 + Codex review 處置(4 發現)

gate_49 三測項全綠:fc1(14 descriptors、3 tiles)RTL 輸出 == 中間層 bit-exact;fc2 以 RTL
實際輸出鏈接 == 最終輸出 bit-exact;provenance 重生成(model/golden/.tflite byte-級)相符。
Codex:#1 High——QuantizeMultiplier 用 python banker's round(TFLite 是 half-away)且
shift<-31 應 flush-to-zero 而非 raise → 修正 + flush 測項;#2 per-channel 用 allclose 會
靜默收斂 → 改 exact 相等;#3 provenance 漏比 .tflite → 補 byte 比對;#4 本模型 fc1 zp=-128
使 ReLU clamp 與 int8 下界重合(量化 ReLU 層的構造性結果)→ 記錄:非虛空的 fused-ReLU clamp
覆蓋在 gate_48 relu corner(act_min=0)。

**§3 列 7(軟體)升 GREEN-leaning**;餘:CONV/POOL op、per-channel requant、K>64 tiling、
on-NPU repack。
