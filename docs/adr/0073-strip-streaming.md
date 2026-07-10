# 0073 — v2 strip-streaming:權重 DDR 串流 + 2×40KB ping-pong + A.2(K>64)

- Status: accepted(User 裁示「#1+#3 並行」;架構 review = Grok 通過,
  `docs/reviews/2026-07-10_strip_streaming_grok.md`;設計 SSOT =
  `design/npu/docs/streaming_tile_design.md` 含 §6 凍結項)
- Date: 2026-07-10

## Decision(契約凍結)

### 1. Strip 幾何與 blob 佈局
- strip = 全-K × N=64 tile 條;`STRIP_BYTES = K×64`(K=640 → 40KB ≤ bank 容量)。
- DDR blob:`W_BASE`(**4KB 對齊,HW enforce**)起,strip 緊排(strip s 位址 =
  `W_BASE + s×STRIP_BYTES`)、strip 內 K-major —— 免跨 4KB 驗證 by construction。

### 2. CSR 契約(npu_ml_ctrl 擴充;「descriptor」= 此組 CSR + kick)
| CSR | 欄位 | 說明 |
|---|---|---|
| `ML_MODE` | bit0 STRIP_EN | 0 = legacy K=64 路(**零回歸**) |
| `ML_W_BASE` | [31:0] | DDR byte 位址,[11:0] 必 0 |
| `ML_STRIP_BYTES` | [16:0] | ≤ 40,960 |
| `ML_N_STRIPS` | [11:0] | = ceil(N/64),0 = illegal |
| `ML_K_CHUNKS` | [7:0]+[6:0] | chunk 數 + `K_TAIL`(末 chunk 有效長 1..64) |
| `ML_N_TAIL` | [6:0] | 末 strip 有效寬 1..64(residual 政策凍結;本模型全 64) |
**Illegal 表**(kick 時檢,違者 ERR 不 hang):STRIP_EN 且 {W_BASE 未對齊 /
N_STRIPS=0 / STRIP_BYTES=0 或 >40960 / K_CHUNKS=0 / K_TAIL,N_TAIL∉[1,64] /
與 legacy `n_tiles` 路同時 kick}。

### 3. 資料路
- **新 `npu_strip_buf.v`**:2×40KB 單埠寫(DMA 側,W=DMA_DATA_W)/ 256b 讀
  (mat 側,鏡射 npu_tcm 權重讀埠介面);bank 所有權硬互斥。
- **npu_top mux**:mat_engine B-operand 讀路 = STRIP_EN ? strip_buf : TCM
  (legacy);activation 讀路(TCM)與 writeback 路不變。
- **npu_dma burst 鏈模式**:一次 strip 預取命令 → HW 自動連發
  `ceil(STRIP_BYTES/4KB)` 條 INCR-256 burst(**硬體續 AR,禁軟體逐 burst**),
  單 outstanding 背靠背;目的 = strip_buf 指定 bank。

### 4. 執行語意
- job start:PREFILL bank0(同步)→ 進入 pipeline:compute(strip s, bank A)
  ∥ prefetch(strip s+1, bank B)。
- **rendezvous(compute-done ∧ prefetch-done)= 唯一 bank 交換點**(RTL 斷言
  無搶跑);末 strip 停止 prefetch。
- **ACC clear = strip 邊界**;strip 內 K-chunk 連續累加(A.2);strip 末
  RESCALE_PC + STORE(沿 Phase-A 交易序)。
- 命令邊界 bank 狀態 reset;`soft_reset/abort` 清 burst 鏈 + bank valid +
  ACC + rendezvous 狀態(沿 ADR-0038/0047 drain 紀律)。
- prefetch bus ERR:drain compute、ACC/bank 作廢、`ERR_CAUSE=ML_STRIP_DMA_ERR`
  (新碼)、job 終止 GO 清。

### 5. 驗證(效能/功能分列 —— green-wash 守衛)
- `gate_97_strip_stream`:同一 GEMM strip 路 vs legacy 路結果 bit-exact +
  ddr_latency_model 三 preset bit-exact + **隨機 stall 注入**仍 exact;
  另列 perf assert:**B/cyc ≥ 4.0 @G2-cal(COL_CYC=3,128b)**。
- `gate_98_strip_orchestration`:strip launch 編排稅 ≤ ~2k core*/proj 級 +
  gate_67/45/46 legacy 零回歸。
- 誠實界:2-AR / 半-K strip / 權重回 DTCM 本階段不做(Grok);KV/act 與
  weight 流 decode 時間軸互斥(非並發目標)。

## Consequences
80KB SRAM(預算內);真尺寸 gate/up 320-tile 編排稅 → strip 級(~10 launch);
q_proj 軌預期 dma efficiency 2.86→≥4.0 B/cyc;fresh Fmax/DC 影響待 strip_buf
快掃(非 signoff)。
