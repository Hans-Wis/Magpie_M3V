# E1b ewise_mul + RoPE → RVV(設計確認,§2)

Status: ACCEPTED-to-implement(User 裁示 2026-07-10「#1+#3 並行」;#3 範圍經查證
收斂:QK-norm 復用 MAT_RMSNORM 已 RVV 化,剩 ewise_mul + RoPE;softmax 屬 #4)
Date: 2026-07-10 · 模式 = RMSNorm→RVV 已證模板(rounding 重定義 + 獨立 Spike-
validated golden;`rmsnorm_rvv_design.md` §6 先例)

## 1. 現況與目標(真尺寸微基準,gate_95)

| kernel | 現況 scalar | RVV 目標 | 每層省 |
|---|---|---|---|
| ewise_mul @2048(FFN GeGLU) | 93,252 | ~15k | ~78k |
| rope @160 ×5 | 53,185 | ~15k | ~38k |

合計 -116k/層 → 非線性 287–353k → **~170–235k**,壓進所有 DDR 牆情境之下
(正式報告 §4-4);prefill 直接受益。

## 2. E1b ewise_mul(`CQ_OP_MAT_EWISE_MUL` handler 向量化,零 RTL)

- 數學:`dst=sat8(rdbpot(srdhm(a·b, mult), shift-31))`,mult/shift **per-tensor
  常數** → 與 RMSNorm scale 鏈同構:
  `vle8(a),vle8(b) → vwmul(i8×i8→i16) → vwcvt→i32 → vsmul.vx(M) → vssra.vx(S)
  → vmax/vmin → vncvt → vse8`,vxrm=rnu。
- **rounding 重定義**(Gemma-private,同 RMSNorm 政策):scalar srdhm+rdbpot 的
  雙段捨入 → vsmul(rnu)+vssra(rnu) 單鏈;`(M,S)` 由 `(mult,shift)` 換算
  (M=mult、S=shift-31+31?——實作時凍結換算式並入 golden)。
- **A/B 對照**(Grok 原建議):(a) RVV 全鏈 in-core;(b) RVV 乘積 + E1a
  `MAT_REQUANT_VEC` 引擎 requant。gate 同時量測兩案,取優者為 default
  (預期 (a) 勝——免 CQ 往返;(b) 留檔)。

## 3. RoPE(`CQ_OP_MAT_ROPE` handler 向量化,零 RTL)

- 數學:`acc = s[i]·cs[i] + rot·sn[i]`,rot = `-s[i+half]`(i<half)/
  `s[i-half]`(否則);mult/shift per-tensor 常數。
- 向量化:**兩段迴圈免 slide/免 strided** —— 段一 i∈[0,half):rot 指標 =
  `s+half`(unit-stride,取負經 vrsub);段二 i∈[half,hd):rot 指標 = `s`。
  乘積:`vwcvt(i8→i16)` 後 `vwmul(i16×i16→i32)` 兩路 + `vadd` → 同 §2 requant
  鏈。全 unit-stride,LMUL 檔位沿 RMSNorm(e8mf4/i32m1)。
- rounding 重定義同 §2 政策。

## 4. 驗證(權威;green-wash 守衛)

1. `rvv_bitmodel.py` 擴充 ewise_mul/rope(**純 spec 推導,不 import RTL**)+
   `gate_rvv_bitmodel_spike` 對 Spike 驗 bitmodel 本身。
2. gemma golden 鏈(`gemma_quant.py`/`_s2`)切換到新 rounding;**flip 計數**
   報告(RMSNorm 先例:0/256 = 重定義實質 no-op;若 flip>0 需 layer e2e 端
   bit-exact 重收斂 + 誠實記錄)。
3. gates:`gate_46/48/49/50/82/83` 層鏈 bit-exact 重跑 + RVV 全檔零回歸
   (b1..f 批)+ `gate_95` 微基準重量測(省幅落帳)。
4. disasm 守衛:無 `__muldi3/__ashrdi3` 殘留於兩 handler 熱路。
5. lockstep:phase_22 f/vrand 批次確認 vexu 行為未動(純韌體變更)。

## 5. 誠實界

per-tensor 常數 M/S 是本設計可行前提(per-element 動態 M/S 不在 Zve32x 上
向量化——不適用此二 kernel,已查證);softmax(除法)不在本輪;H=640 全模型
descriptor 課題(W0.RPT 8-bit)另案。
