# Strip 模式推廣到真 rail(設計確認,§2;ADR-0073 addendum)

Status: ACCEPTED-to-implement(User 裁示 2026-07-10「strip 模式推廣到 gemma/tflm
真 rail」;契約承 ADR-0073,本檔僅收斂推廣面)
原則:**同輸出、換運輸** —— 全部既有 golden(gate_46/gemma/tflm)一個位元組都
不改;GEMM 步的執行從「逐-tile 通用 CQ op 鏈」換成「單一 strip job」。

## 1. CQ SSOT 新 op(gate_35 regen-diff 守衛)

`MAT_STRIP_GEMM`(value **15**):
- `W1` = W_BASE(shared/DDR byte 位址,4KB 對齊 —— sanitizer 檢)
- `W2` = `(N_STRIPS[11:0]<<17) | STRIP_BYTES[16:0]`
- `W3` = `(K_CHUNKS[7:0]<<24) | (K_TAIL[6:0]<<17) | (N_TAIL[6:0]<<10) | out_dst64[9:0]`
  (out 目的 = shared byte 位址 / 64;block 本就 64B 對齊)
- 語意:sequencer 驗參(沿 ADR-0073 illegal 表 + 4KB 對齊 + out 界內)→ 寫
  ml_ctrl CSR(0x94..0xA8 + 新 **ML_OUT_BASE 0xAC**)→ GO → poll ML_STATUS.DONE;
  ml 錯(含 ML_STRIP_DMA_ERR=9)→ `cq_halt(CQ_ERR_MAT_PARAM 家族新碼 STRIP_ERR)`。
- **TCM 前置契約(凍結,沿 ADR-0073/D4)**:activation per-chunk 塊 @`OP_A_ADDR
  +c×0x200`;strip 參數 @`0x1200` 64B-stride per 全域 sub-tile —— 由 firmware
  prep(既有 memcpy 模式)在發 op 前備妥;op notes 寫明。

## 2. RTL delta(唯一一處,ml_ctrl)

`ML_OUT_BASE`(0xAC,RW):strip 模式 STORE 目的基址(sub-tile 塊 @base+
(s×8+t)×64)。reset = 舊 DST_BASE 值(**legacy/gate_97 零回歸**)。其餘 RTL 零改。

## 3. Host lowering(軟體)

- 共用 helper `strip_blob.py`(design/npu/sw/gemma 或 tools):任意 [N,K] int8
  權重 → ADR-0073/D4 凍結佈局 blob(offset(c,t)=c×4096+t×512,[k][8])+ 64B
  參數塊序列;gemma 與 tflm lowering 共用。
- 首批遷移 rail:①gate_46 的 q_proj-class CQ 矩陣 rail(K=64,N=64=1 strip
  ×8 sub-tile);②gemma FFN gate/up(toy N=128 = **2 strips,真 multi-strip +
  prefetch/rendezvous 上真 rail**)。其餘 gemma/tflm GEMM 步同 helper 逐步換,
  不在本輪強制。

## 4. 驗證

1. `gate_35` SSOT regen byte-identical(schema 改必跑)。
2. `gate_46` 新增 strip 變體測項:同一輸入走 MAT_STRIP_GEMM,**輸出位元組 ==
   既有 golden**(golden 檔零改動);原逐-tile 測項保留(通用路零回歸)。
3. gemma gate/up strip rail 測項:bit-exact vs 既有 layer golden 對應段。
4. 零回歸批:gate_36/37/38(CQ 行為)、gate_97/98(合成 strip)、e2e 常備批。
5. 誠實界:本輪 shared-SRAM 為 DDR 替身(真 DDR 掛接 = Magpie_DDR 線);未遷
   移的 GEMM 步仍走通用路(two-tier 誠實延續)。
