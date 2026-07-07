# Gemma-3 270M → M3V:架構優化實驗台帳(benchmark-driven)

> **用途**:固定 benchmark = §baseline;每個改善實驗記一列,對比 **vs baseline** + **vs 前一次**,
> 逐次逼近架構最佳執行方式。**鐵律**:每個實驗的 keep/revert 由「**bit-exact 綠 + profiler cycle delta**」
> 兩軌共同裁定——縮 scope / 破 bit-exact / 只在 TB 關功能一律 revert。
> **量測 harness**:`python sim/tools/profile_gemma_layer.py`(Verilator,建 npu_top+cpu_m1,跑 22-step 鏈)。
> **正確性 harness**:`sim/gates/gate_gemma3_layer_rtl.py` + S0–S5 分步 gate(bit-exact vs Tier-C golden)。
> **完整基準分析**:`docs/reports/2026-07-07_gemma270m_m3v_perf_baseline.md`(SSOT)。

---

## Baseline(固定 benchmark)

| 項目 | 值 |
|---|---|
| **一層 wall-clock** | **349,824 cyc**（HEAD @108f2af，profiler 重現 ±0，**已鎖定**）|
| 初始（Cycle-1 前）| 375,672 cyc |
| scalar core | ~89% wall（GEMM 33.3% / nonlinear 66.7%）|
| mat busy | 5,658（MAC 1,104 / requant 4,290）|
| dma busy | 34,955（10.0%）|
| representative dims | seq 4 · hidden 64 · nh 4 · hd 16 · ffn 128 |

**逐-step core\*（重現確認,前 5 大熱點）**:ewise_mul **36,547** · QK-norm_q 29,857 · RoPE_q 25,835 ·
RMSNorm(×4 各 ~23.8-24.1k) · gate/up_proj 各 18,002。**單步之冠 = ewise_mul 36,966 total。**

---

## 實驗紀錄

| # | 實驗 | 改動層 | 攻擊 | vs baseline | vs prev | bit-exact | 判定 |
|---|---|---|---|---:|---:|---|---|
| **E0** | baseline（RVV Cycle-1 residual）| RVV firmware | residual | — | — | ✅ gate 綠 | **BENCHMARK** |
| **E1** | **ADR-0066 MAT_REQUANT_VEC — ewise_mul requant 卸給 mat_engine 64-bit** | RTL(+S_LV)+ SSOT + firmware + runtime | ewise_mul 36,966（單步之冠）| *(進行中)* | *(進行中)* | pending | 🔄 進行中 |

---

## 實驗細節

### E0 — Baseline
- **內容**:HEAD 現況。RVV Cycle-1 已把 residual 19,251×2 → 6,306(3.05×),layer 375,672 → 349,824。
- **證據**:profiler 重現 **349,824(±0)**;S0–S5 gate 全綠。
- **狀態**:固定 benchmark。後續所有實驗對此列比。

### E1 — ADR-0066 MAT_REQUANT_VEC（ewise_mul requant 卸載）
- **假設**:ewise_mul(36,966,全層單步之冠)的 core* 是純量逐元素 srdhm(`__ashrdi3` per-element
  function call)。改成 RVV 算 int32 `a·b` 前段 + mat_engine 現成 64-bit srdhm 後段(新 CMD_LOADVEC +
  CQ opcode 14),預期單步 36,966 → **~10-15k(保守 2-4×)~ 2.5-4k(樂觀)**。
- **為何是 bit-exact by construction**:走的就是 CMD_RESCALE datapath,ewise golden 本來就 mat_engine 同源。
- **改動**:①SSOT yaml(opcode 14 + CMD_LOADVEC)→ regen 3 artifact(gate_35 regen-diff)②mat_engine.v
  加 S_LV(照 review §2 修正:param_bad + t_a_re + padded-64 契約)③firmware handler ④runtime lowering。
- **驗證**:單元 bit-exact(64 相異 int32 vs mat_golden.requant,防退化廣播/transpose)→ gate_gemma3_s0
  byte-identical → profiler 量 ewise_mul 單步 + layer delta。
- **步序(a/b 拆分,增量 de-risk)**:
  - **E1a ✅ 完成且全綠(2026-07-07,Codex 實作 + Claude 獨立驗證)**:SSOT(opcode 14 + CMD_LOADVEC=3'd5)
    + mat_engine.v `S_LV=4'd9`(el_grp 8-window 線性載 acc[0..63]、t_a_re 含 S_LV、param_bad clause、
    review §2 修正全含)+ firmware `CQ_OP_MAT_REQUANT_VEC` handler(含 out_base 還原)+ 單元 TB。
    **驗證(Claude 獨立跑)**:①單元 bit-exact `checks=134`(64 相異 int32 含 I32_MIN/MAX/負 corner,
    逐 byte vs mat_golden.rescale,distinct+>48-varied 斷言防廣播/transpose,param_bad 兩項)②gate_35
    regen-diff 4 passed ③lint 0 新 warning ④**additive-safety 回歸 gate_45/46 = 3 passed(舊 GEMM/RESCALE
    bit-exact 不變,確認純 additive)**。RTL diff 人工複審正確(S_LV 無 transpose/off-by-one)。
    **硬體 requant-offload 路 bit-exact 已證。**
  - **E1b(待 E1a 綠)**:runtime ewise_mul lowering = RVV int32 `a·b` 前段 + MAT_REQUANT_VEC 描述子;
    gate_gemma3_s0 byte-identical → profiler 量 ewise_mul 單步 + layer delta → 填 E1 列(vs baseline/prev)。
- **descriptor packing(定案,比 ADR 草稿精簡:per-tensor 免 TCM param blob)**:W0=op14+ACC(bank)+RPT;
  W1=mult_q31;W2=(rsp<<16)|clamp[rsp=(out_zp<<8)|shift,clamp=(clamp_max<<8)|clamp_min];W3=(src<<16)|dst。
  handler 設 out_base=dst 後還原 0x800(防 state 污染 GEMM RESCALE)。

---

## 決策日誌(為何選這個實驗)

- **2026-07-07 · E0 鎖定 + E1 選定**:baseline profiler 重現 **349,824 ±0**。原 roadmap #1 = GEMM
  de-spin,但 **root-cause 重排了它**:
  - `_chunks` 已最佳(K=64→1 chunk);gate_proj = 16 tiles × 6 CQ-op = 96 op,**core* 18,002 = 每-op
    韌體固定稅 ~187 cyc**(descriptor fetch + csr_write noinline + loop),與引擎/DMA 不重疊。
  - **單純融合 q/k/v 只省 step 級固定稅(~2%)**——op 數是 per-tile,融合不減 op。真正砍 GEMM core* =
    砍每-op 韌體成本 = **高 blast radius 共享韌體**(影響全部 tflm/mobilenet/mlperf/gemma gate)。
  - **結論:GEMM 是「小 ROI + 高風險」,不宜當 E1。** 逐-step 看,**ewise_mul 單步 36,966 = 全層最大單體**,
    ADR-0066 已三方 review=ACCEPT、bit-exact by construction、攻最大熱點 → **ROI/風險雙勝,選為 E1**。
    (GEMM 每-op 韌體瘦身 + activation-stationary 留作後續實驗,待 E1 建立迴圈信心後再碰共享韌體。)
