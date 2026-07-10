# DDR 牆 Step-1 — latency model + 真尺寸實測(設計確認,§2)

Status: ACCEPTED(User 裁示 2026-07-10「按修訂序執行 第一步先做 DDR-latency model + 真尺寸實測」)
依據: `docs/reviews/2026-07-10_perf_ddr_budget_grok.md`(修訂攻擊序)+ Magpie_DDR 偵察
(DDR4-3200 ×16、128b AXI 單 outstanding、G2 目標 ≤6 cyc/col、現況 ~13)。

## 目的(誠實界修復)

現有全部效能數字(307k/層、q_proj 1,129、11.8×)都在 **1 拍 shared-SRAM 替身**下量測
= 對 DDR 牆低估一個數量級。本步產出兩組**數據**,供攻擊序最終定案:

- **A. BW-bound 投影 → 實測**:ml_v2 q_proj 軌在參數化 DDR-latency model 下重量測
  (presets:`G1_NOW`=13 cyc/col、`G2_TARGET`=6、`IDEAL`=1/現況 SRAM)。
- **B. 真尺寸 compute 實測**:H=640 非線性 kernel 微基準(in-core,mcycle),對
  ~431k cyc/層串流牆比大小 → 定 RVV 鏈的必要範圍(Grok 估 ~250k,toy 線性外推
  >600k,分歧靠實測解)。

## A. `axi_ddr_latency_model.v` 契約(TB 元件,`design/npu/dv/tb/`)

- AXI4-full slave,**drop-in 替換 `axi_full_sram`**(同埠形 + 參數),行為對齊
  Magpie_DDR G0/G2 契約:
  - `T_FIRST_HIT`(page-hit 首 beat 延遲,default 24 cyc)/ `T_FIRST_MISS`
    (miss=PRE+ACT+CAS,default 48)/ `COL_CYC`(beat 間隔:13/6/1)
  - page 模型:`PAGE_BYTES`=2KB,col-low 映射(連續位址 = page-hit 流);
    跨 page = miss 延遲
  - **單 outstanding**(第二筆 AR/AW 在前筆完成前 hold arready/awready)
  - **burst 紀律 checker**:INCR only、len≤256、不跨 4KB —— 違規 `$fatal`
    (Grok gate 表「Burst 紀律」)
  - **BW 記帳**:`$display("DDR_MODEL_STATS bytes_rd=%d bytes_wr=%d busy=%d eff_bpc=%f")`
    at finish
- 不模擬:refresh、bank 交錯、W→R turnaround(記錄為抽象;signoff 掛真 Magpie_DDR)。

## B. 真尺寸微基準(`design/npu/sw/perf_h640/` + gate)

- NPU core(RV32IMF+Zve32x)ITCM 韌體,DTCM 放 H=640 資料,`mcycle` 圍測:
  1. `rmsnorm_rvv`(現行 S1 RVV 鏈,loop 到 640;**in-core 免 descriptor**)
  2. `qk_norm_scalar`(現行 scalar 路徑)
  3. `ewise_mul_scalar`(現行)
  4. `rope_scalar`(現行 64-bit srdhm 路徑)
  5. `softmax_scalar`(uint32 divide 路徑,seq=4 與 seq=64 兩檔)
- 產出表:cyc/op @H=640 + 每層合計 vs 431k 牆;結論 = RVV 鏈必要範圍。
- 誠實界:微基準單 kernel 量測(無 CQ 編排稅);與 e2e 層數字分開陳述。

## 驗證/交付

- `gate_94_ddr_latency_model`:model 單元(hit/miss/col 間隔/單 outstanding/4KB
  checker 觸發)+ ml_v2 q_proj 三 preset 重量測 bit-exact(**故意插 stall 仍 exact**
  = overlap 前置正確性基線)。
- `gate_95_realsize_compute`:微基準跑通 + 數字落 report。
- 報告:`docs/reports/2026-07-10_ddr_wall_realsize_baseline.md`(A+B 數據 + 攻擊序
  定案建議);ledger 更新。
- 功能 lockstep 不動(perf gate 與功能 gate 分家,Grok 守衛)。
