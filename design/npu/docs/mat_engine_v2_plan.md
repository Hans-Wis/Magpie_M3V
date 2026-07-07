# mat_engine v2 — 工程方案規劃(Solution Plan)

- **Status:** PLAN(可實作)· 2026-07-07 · Claude(PL)整合
- **決策記錄:** `docs/adr/0067-mat-engine-v2.md`(方向 + LANES SKU + PPA)
- **架構草稿源:** `design/npu/docs/mat_engine_v2.md`(Grok);本 plan **取其結構、修其順序與 framing、補 activation-stationary 與應用尺度依據**,作為工程執行的權威計畫。
- **量測依據:** `docs/reports/2026-07-07_gemma270m_m3v_perf_baseline.md` · `docs/reports/gemma_opt_ledger.md`
- **鐵律:** MAC 數學(S_RUN/S_RSC)**凍結**;E1 CSR-stream 等價 + bit-exact gate 為驗收權威。

---

## §1 一句話方案

把 GEMM 的**編排**從「韌體逐 tile 發命令 + 自旋等待」搬進**硬體 job sequencer**:韌體發**一個 GEMM job**
(TCM descriptor + 一個 GO),硬體 `ml_tile_seq` 展開 tile 迴圈、經 `ml_cmd_fifo` 餵 `mat_engine`,
`ml_overlap` 在計算時預取下一 tile 權重、且 **activation 常駐 TCM 只載一次**。**MAC 數學不動**;
非線性續走 RVV/CQ handler(軟體軌並行)。SKU 參數 `LANES∈{1,2,4}` 給客戶 64/128/256 MAC 面積/功耗檔位。

## §2 為什麼(實測 + 應用尺度)

| 事實(measured)| 數字 |
|---|---|
| 一層 wall-clock | 349,824 cyc,scalar core **89%** |
| 256-MAC 真 busy | **0.29%**(1,104 cyc)|
| **GEMM 編排成本律** | **core\* ≈ 100 + 1,119 × tiles**(截距≈0)→ **~1,120 cyc/tile 純韌體固定稅** |
| activation 重載 | `lower_layer_v2` 每輸出 tile 重新 DMA 同一份 activation(額外 DMA)|

**韌體改不掉這條律**(向量化碰不到、融合只減 step 不減 tile)。**應用尺度更致命**:per-tile 稅 = O(tiles),
Gemma-3 270M **LM head**[·×640]×[640×262144]/token → ~32,768 tile × ~33 CQ-op × 187 cyc ≈
**~2 億 cyc/token 純編排**(真 MAC 僅 ~65 萬)。**→ 硬體 sequencer 在真應用是必要,非可選。**

## §3 架構(資料流)

```
  Host cpu_m1  ──ring@0x8000──►  NPU sequencer (scalar spine, 凍結)
                                     │  cq_sequencer.c: 消 CQ、發 ML job、非線性 handler
                                     ▼  ML_JOB_ADDR(job blob ptr in TCM) + ML_JOB_GO
   ┌─────────────────────────── npu_ml_ctrl (v2 新控制殼) ───────────────────────────┐
   │  ml_job_regs   job descriptor 暫存                                              │
   │  ml_tile_seq   展開 GEMM job → tile 迴圈(算 a/b/out 位址、K-chunk、bank 輪替)   │
   │  ml_cmd_fifo   引擎 micro-op 佇列(depth 8);pop 條件 = !mat_busy                │
   │  ml_overlap    計算時預取下一 tile 權重 DMA;activation 常駐(只載一次/row-group)│
   │  legacy_bypass  mux:ML_V2_EN=0 或 bypass=1 → 舊韌體 CSR 路(gate 全綠不變)      │
   └──────────────┬───────────────────────────────┬────────────────────┬────────────┘
                  │ mat_csr_* (cmd/bank/a/b/mult…) │ dma_req            │
                  ▼                                ▼                    ▼
            mat_engine v1 (S_RUN + S_RSC, 凍結)   npu_dma          npu_tcm (activation 常駐區)
                  ▲
   RVV vexu ──int32 vector──►(MAT_REQUANT_VEC job = LOADVEC+RESCALE,ADR-0066 已建 E1a)
```

**新 RTL 模組**(control-only,~500 行,`mat_engine.v` 數學零改):
| 模組 | 檔 | 職責 |
|---|---|---|
| `npu_ml_ctrl` | `design/npu/rtl/npu_ml_ctrl.v` | 頂殼:job kick/status/err、legacy mux、arb |
| `ml_tile_seq` | `design/npu/rtl/ml_tile_seq.v` | GEMM job → tile 命令鏈(位址算術 + bank 輪替)|
| `ml_cmd_fifo` | `design/npu/rtl/ml_cmd_fifo.v` | 引擎 micro-op FIFO(解耦 issue rate 與韌體)|
| `ml_overlap` | `design/npu/rtl/ml_overlap.v` | 權重 double-buffer + activation 常駐(Phase B)|

## §4 關鍵設計決策(比 Grok 草稿新增/修正)

1. **Activation-stationary(新增,重要)**:`lower_layer_v2` 現況每 tile 重載 activation。v2 `ml_tile_seq`
   應**每 row-group 只載一次 activation 進常駐 TCM 區**,per-tile 只串權重(`mat_engine` MAT_OP 的
   a_addr/b_addr 本就獨立可指)。同時砍 DMA 重載 + per-tile LOAD_W 開銷。
2. **Job-based 介面**:韌體發 1 個 job(非 N 個 CQ-op)。job blob 在 TCM(可擴 per-channel param),
   CSR 只放指標(§5)。
3. **Bank 輪替 for overlap**:4 個 acc bank;tile N 用 bank b、tile N+1 用 bank b+1,使「N rescale」與
   「N+1 load/OP」重疊(同一 bank 累加 hazard 維持序列化,Phase A 保守)。
4. **LANES SKU 正交**:`mat_engine` 已參數化 `LANES∈{1,2,4}`(已驗 bit-exact);v2 控制殼與 LANES 無耦合。
5. **framing 誠實**:v2 = 新硬體控制子系統(非「輕度修改」);MAC datapath 才是「凍結不動」的那塊。
6. **順序**:軟體軌(RVV 非線性/RMSNorm golden)與硬體軌並行,**不互卡**。

## §5 介面契約

**Job descriptor(TCM blob,SSOT `design/npu/schema/ml_job.yaml` → `ml_job.h`/`.vh`)**:
```
ml_gemm_job_t { job_type; flags{irq,last,store_en}; M; N; K; a_base; b_base; out_base;
                bank; rpt_total; mult/rsp/clamp(或 pc param ptr); w_dma_src; w_dma_len; }
```
**新 CSR(core-local mirror,`cq_defs.vh`)**:`ML_JOB_ADDR`(RW ptr)· `ML_JOB_GO`(WO pulse)·
`ML_JOB_STATUS`(RO {busy,done,err,err_code})· `ML_JOB_CFG`([0]=legacy_bypass)。
**FIFO entry** = 一次 mat_engine invocation(cmd/bank/rpt/a/b/mult/rsp/clamp/out_base),1:1 對應今日 CSR 序列。

## §6 分階段建置(可獨立 gated,無 big-bang)

| Phase | 交付 | 退出 gate(measured)|
|---|---|---|
| **0 · 已就緒** | ADR-0067 sign-off · LANES PPA(跑中)· **CMD_LOADVEC/MAT_REQUANT_VEC 已建(E1a,gate_45/46 綠)** | — |
| **A · GEMM job sequencer(核心)** | `npu_ml_ctrl`+`ml_tile_seq`+`ml_cmd_fifo`;`ML_JOB_*` CSR + `ml_job.h` SSOT;韌體 `cq_emit_gemm_job()`;PoC = **k_proj 一條**;`legacy_bypass` default=1 | ① **`gate_67_ml_v2_equiv`**:ML_JOB 路 vs 直接 CSR = **相同 mat CSR 交易流**(E1)② gate_45 + gemma_layer bit-exact(legacy)③ profiler:k_proj step **≥2×** |
| **B · overlap + activation-stationary + requant job** | `ml_overlap`(權重 double-buffer + activation 常駐);`MAT_REQUANT_VEC` 併為 job type;韌體 ewise/RoPE → RVV 前段 + requant job | ① gate_gemma3_s0/s2 byte-identical ② profiler:gate_proj **≥2×**、ewise_mul 有感 ③ DMA busy 降(activation 不重載)|
| **C · 全層融合 + 軟體軌** | 單一 in-NPU 層 micro-program(22 步→1 kick,中間值常駐 DTCM);**軟體軌並行**:RMSNorm RVV-native golden(另開 ADR)、RoPE/gelu/softmax 向量化 | ① 全層 profiler **≥2×** vs 349,824 ② S0–S5 bit-exact |
| **D · defer** | 多 job queue | 僅當 A–C 後仍 engine-starved(profile 顯示不會)|

## §7 驗證策略(E1/E2/E3,承 ADR-0052)

| 級 | 定義 | 權威 |
|---|---|---|
| **E1** | mat_engine **CSR 交易流相同**(硬體發 vs 韌體發,時序可不同)| `mat_golden.py`、gate_46、新 gate_67 |
| **E2** | HEAD/IRQ/FENCE/ERR/abort 語義不變 | gate_35–39、ADR-0038/0047 |
| **E3** | descriptor-fetch DMA 可不同(log-only) | 非 fail |

新 TB:`tb_ml_v2_equiv.v`(ML_JOB vs CSR 位元比對)· `tb_ml_tile_seq.v`(位址算術/rpt tail/bank 規則)。
**green-wash 守衛**:不改 mat_golden 遮分歧 · legacy path 全程綠 · throughput 與 bit-exact 分開宣稱 ·
profiler 未重跑不得宣稱加速。

## §8 LANES SKU — 已完成貫穿全鏈(見 ADR-0067 §3)

`LANES∈{1,2,4}` → 64/128/256 MAC。**面積/功耗取捨**(非提速):decode/頻寬綁定 → 64 幾乎不掉速;
prefill/計算綁定 → 需 256。與 v2 控制殼**正交**,可獨立出貨。

**已完成(非只 mat_engine——貫穿整合 + 驗證)**:
- **RTL**:`mat_engine.v` 參數化 K-fusion;`npu_top` `MAT_LANES` → `.LANES()`;`tb_npu_cq_mat` 貫穿。
- **DC PPA 實測**(TSMC28,CLK 1.2ns,三檔皆達時序):256=83,868µm²/50.77mW · 128=**−26%面積/−29%功耗** ·
  64=**−40%面積/−43%功耗**。(不線性:acc-bank+requant+FSM 是 LANES-independent 固定成本;MAC 樹才隨 LANES 縮。)
- **驗證 `gate_84_mat_lanes_sku`(2 passed)**:LANES=1/2/4 各 rebuild golden-exact bit-exact + npu_top e2e
  @MAT_LANES=1 byte-for-byte;default gate_45/46 回歸綠。
- **後續**:整合層窄化 TCM 讀埠(256b→64b @LANES=1)再榨面積。

## §9 資源/風險

- **面積**:控制殼 +3–5k gate(FSM+FIFO+regs),對 256-MAC 陣列微小。**critical path 不變**(requant 限,ADR-0053)。
- **記憶體**:job blob ≤128B + activation 常駐區(監控 gate_52 ITCM/DTCM 預算)。
- **風險**:①硬體 CQ-consumer 必須 E1 等價(驗證負擔)②未來 GEMM lowering 改動可能要動 RTL(彈性損失,
  故 legacy path 永久保留)③abort/hard_reset 下 FIFO drain 規則(sticky abort 清 FIFO,`mat_engine.abort_i` 不變)。

## §10 里程碑序(建議)

1. **本輪**:LANES PPA 填表 + commit checkpoint(ADR-0066/0067 + E1a + LANES 參數化 + 報告/台帳)。
2. **A**:k_proj job sequencer PoC → gate_67 E1 等價 → profiler ≥2× → review。
3. **並行軟體軌**:RMSNorm RVV golden ADR + 實作(最大單筆 134k,零 RTL)。
4. **B**:overlap + activation-stationary + ewise/RoPE requant job。
5. **C**:全層 fuse + 收斂 profiler ≥2×。

**預期(投影,待 re-profile)**:A+B(硬體)+ 軟體軌 → 一層 349,824 → **~150k(軟體極限)→ ~110k(+v2 硬體)**;
應用尺度(LM head/production seq)v2 的相對收益更大。
