# RMSNorm → RVV Zve32x — 最大單筆軟體省(~24k/op ×4,零 RTL)· for review

- **Status:** DESIGN(待 Grok + Codex review)· 2026-07-08 · Claude
- **上位:** perf baseline roadmap #4(RMSNorm 家族 ~134k)· ADR-0062(S1 RMSNorm CQ op)· 承 Zve32x RTL 全完成(Phase B-F)
- **鐵律:** 零 RTL(RVV RTL 已在);功能權威 = gate_gemma3_s1_rtl bit-exact vs(重寫的)golden + gemma layer 全鏈不破;nonlinear-in-RTL green-wash 守衛保留。

---

## §0 現況 + 熱點

RMSNorm ×4/層(in / post-attn / pre-ffn / post-ffn),各 **~24k cyc,全 scalar core**(mat=0/dma=203/**core*≈24,073**)= perf baseline 非線性大宗(roadmap #4 家族 ~134k)。現為 CQ op **MAT_RMSNORM**,在 sequencer core(**EN_RVV=1,in-core vexu**)以**純量**執行(cq_sequencer.c:471)。**cost driver**:scale/requant loop(505-512)**每元素 64-bit**(`t/acc/vv` int64)→ `__ashrdi3`/`__muldi3` libgcc call × H(=640)× CPI。

現有兩迴圈:
1. **sum-of-squares**(494-497):`for i: sum_sq += src[i]*src[i]`(int8²,32-bit 累加)。
2. **scale/requant**(505-512):`vv = ((src[i]*y_adj*wq[i]>>14)*OUT_NUM+rbias)>>rsh` → sat int8。**64-bit 鏈**(y_adj Q31 × int8 → 39-bit)。

## §1 Coral 對照

Coral 走閉源 IREE,非線性亦向量化(RVV)。我們用開源 clang-RVV 把 RMSNorm 向量化 = 對齊 Coral 的向量化非線性路(§3 軟體列)。

## §2 RVV-native 向量化計畫(vexu ops 已確認)

sequencer core 跑 RVV(riscv_vector.h intrinsics,pattern = `rvv_zve32x_smoke/vdot_i8.c`)。

1. **sum-of-squares(精確,無 rounding 改)**:`vwmul.vv(src,src)` int8→int16 + `vwadd.wv` 累加→int32 + `vredsum` → int32 `sum_sq`。**與純量逐 k 位元相同**(int8² 精確)。= vdot_i8 pattern。
2. **rsqrt(不變,per-row 純量)**:`mean_sq = sum_sq/H` → `rsqrt_q31(...)` 保留純量(每 row 一次,便宜;coeff 仍由 golden param blob,零 firmware 常數)。
3. **scale/requant(RVV-native rounding,取代 64-bit 鏈)**:
   - **vsmul**(C5,`sat(round((vs2*vs1)>>(SEW-1)))`,SEW=32)= **RVV-native SRDHM**(= `round((a*b)>>31)` Q31)。
   - **vssra**(scaling shift right + round,vxrm)= RDBPOT 最終 shift。
   - **vnclip / min-max** → int8 飽和。
   - 重構:y_adj(per-row Q31)× OUT_NUM(per-row)合成 per-row 純量 scale `M_row`;wq[i](per-element Q2.14)per-element。每元素:`x[i]` widen → `× wq[i]`(vwmul/vmul)→ `vsmul(·, M_row)`(Q31 round)→ `vssra(shift)` → sat int8。
   - **rounding 差異**:vsmul/vssra 在 >>31 / >>shift 處 round,與純量 exact 64-bit 累加**位元不同** → **RMSNorm Gemma-private,允許改 rounding**(report §140/roadmap #4)→ **重寫 golden 匹配 vsmul/vssra 語義**。

## §3 Golden 重寫(gemma_quant_s1.py)

- rsqrt_q31 不變(coeff 契約不動)。
- scale/requant 的 numpy golden 改為 **vsmul/vssra bit-accurate model**:vsmul = `sat(round_half_?( (vs2*vs1) / 2^31 ))`(依 vxrm,預設 rnu=round-to-nearest-up)、vssra = `round((x)>>shift)`(vxrm)、vnclip 飽和。
- 重生成 s1 golden(gemma_quant_s1)→ gate_gemma3_s1_rtl 的 golden 隨之更新;**gemma layer 全鏈(gate_gemma3_layer)重驗**(RMSNorm 餵下游,rounding 改要全鏈 bit-exact vs 新 golden)。
- **provenance**:golden 由 numpy vsmul/vssra model 生,firmware 用 RVV intrinsics 跑同語義,兩者共 vxrm/rounding 定義(SSOT）。

## §4 驗證計畫

- **gate_gemma3_s1_rtl bit-exact**:RMSNorm(+residual)在 NPU core 經 RVV MAT_RMSNORM,對**重寫 golden** byte-identical(nonlinear-in-RTL green-wash 守衛:必真在 core RVV,非 host)。
- **gemma layer 全鏈**:gate_gemma3_layer_rtl(S0-S5)對更新 golden bit-exact(RMSNorm rounding 改的下游影響全吸收)。
- **cycle 實測**:MAT_RMSNORM 單 op profiler 24k → ? (預期大降,64-bit per-element 鏈消除)。填 perf 台帳(RMSNorm 家族 delta)。
- **Spike lockstep(可選)**:RVV RMSNorm kernel 對 Spike zve32x 並跑確認 RVV 語義(vsmul/vssra vxrm)。
- **green-wash 守衛**:RMSNorm 必真在 core RVV(vexu)非 host/純量假冒;golden 由 RVV 語義 model 生(非事後對齊 RTL 輸出);rounding 改記 ADR(誠實界:非「bit-exact 保留」而是「Gemma-private rounding 改 + 新 golden 背書」)。

## §5 開放問題(給 review)

1. **Q-format 重構**:y_adj(Q31)× OUT_NUM × wq(Q2.14)如何最省地映射到 vsmul/vssra 運算元(per-row scalar vs per-element vector 拆分)?vsmul 是 vv 還 vx?中間精度(ELEN=32)夠嗎(x*wq 中間值範圍)?
2. **rounding 改的準確度**:vsmul/vssra rounding vs exact 64-bit 對 Gemma 端到端準確度影響?(RMSNorm Gemma-private 可改,但要確認不劣化 model 輸出——gemma layer 全鏈 golden 重驗即背書,但需確認是「重定義正確」非「湊 RTL」。)
3. **vxrm 模式**:vsmul/vssra 用哪個 rounding(rnu/rne/rdn/rod)?golden model 與 firmware 須同一 vxrm。
4. **LMUL / vl 策略**:H=640,LMUL 選擇(m1/m2/m4)+ vsetvl 迴圈;fractional-LMUL 記憶體議題(memory 記 latent)避開。
5. **sum-sq 是否也重寫 golden**:sum-sq 向量化精確(int8²),golden 不需改;只 scale/requant 改。確認 sum-sq 路 exact。
6. **範圍**:先做 1 個 RMSNorm(post-attn,gate_gemma3_s1)證 RVV-native + 省 cycle,再套 ×4?傾向先 1 證概念 + golden,再泛化。

## §6 Review resolutions(Grok APPROVE-WITH-CHANGES + Codex needs-changes,2026-07-08)

兩份收斂,方向 APPROVE。定案(含 vexu file:line by Codex,Q-format by Grok):

1. **Zve32x-legal scale-loop 序列(Codex #5 精修 Grok #1)**:
   ```
   per-row scalar: P = int64(y_adj)*OUT_NUM; 選 k 使 M=round(P/2^k) 入 int32、S=30+sh-k∈0..31; 設 vxrm
   per-chunk vector: x16=vsext(vle8 src); prod32=vwmul.vv(x16, vle16 wq)  // exact, ~22-bit
                     q32=vsmul.vx(prod32, M)   // round((prod*M)>>31), vexu.v:942 SEW32 vxrm
                     q32=vssra.vx(q32, S)       // rounded shift, vexu.v:1589, S∈0..31
                     vmax(-128); vmin(127); out8=vncvt int32→int16→int8; vse8
   ```
2. **P0 vnclip int32→int8 直接不可(Codex #3)**:vnclip 只 2*SEW→SEW(dst 8/16;SEW32 illegal,vexu.v:478)→ **用 vmax/vmin + vncvt**(GCC 已對 MAT_EWISE_ADD_REQUANT 這樣做)。**修正 §2 用 vnclip 的錯**。
3. **vsmul/vssra 確認(Codex #1/#2)**:vsmul=SEW32 SRDHM `round((vs2*vs1)>>31)`+vxrm(vexu.v:342/942,reset rnu);vssra=rounding scaling shift SEW32(vexu.v:1589,shift 0..31)。**vxrm=rnu(0)**(Grok #3,配 scalar rbias round-half-up)。
4. **sum-of-squares exact(Codex #4)**:vwmul.vv(src,src)+vwadd.wv+vredsum;widening 需 fractional LMUL dst EMUL≤m1 → e8mf4→e16mf2→e32m1(4 lanes/loop),H stripmine;`H*127²` 入 int32 = 精確,**golden 不改此路**。
5. **P0 firmware GCC(Codex #6)**:sequencer Makefile = GCC 13.2 rv32im_zve32x(非 clang);GCC intrinsic(`__riscv_vsmul_vx/vssra_vx/vncvt`)**無顯式 rounding operand → 靠 vxrm CSR**;**firmware 必 CSR asm 設 vxrm=0 於 kernel 前**。避直接 GCC vnclip_wx_i8(probe 出可疑 vsetvli)。
6. **P0 M/S normalization 證(Codex #5)**:每 RMSNorm blob 證 k/S 範圍(M 入 int32、S∈0..31、vmul(q,OUT_NUM) 無 int32 溢位——real checkpoint worst-row);golden 實作同一 normalization。
7. **P0 H=640 編碼(Codex #8)——但不阻 RTL 驗證**:W0.RPT 8-bit(rpt&0xFF)→ H>255 靜默截。**現 gate_gemma3_s1/layer 用 hidden=64(representative dims)→ RTL bit-exact 驗證不受影響**。**H=640 是全模型路註記**(chunk H≤255 或加寬 descriptor 欄位,留全模型 codegen)。**M3-RMSNorm 先在 hidden=64 驗**。
8. **golden 重寫紀律(Grok #5 + Codex green-wash)**:順序 = ①`rvv_bitmodel.py`(純 spec:vxrm round/vsmul/vssra/vncvt,無 RTL import)②Spike microtest 驗 bitmodel(vsmul/vssra corner (2^30,2)/(-2^30-1,2)/exact-half,對 gate_73/gate_57 既有 Spike lockstep)③`gemma_quant_s1` 重寫 scale/requant 用 bitmodel(rsqrt 不變)④gate vs **新 golden**。**golden 先於/同 commit RTL;flip report old→new golden on real tensors(count+max delta,期望低);layer chain 對新 golden 0-diff**。**誠實界:非「bit-exact 保留」而是「Gemma-private rounding 重定義 + Spike-backed golden 背書」(ADR 記,deprecate 舊 64-bit golden 附 rationale)**。
9. **Coral 對照(Grok #6)**:RVV-native RMSNorm(改 rounding)**仍算功能取代**(Coral RMSNorm 是其自有量化實作,非交換標準;Gemma-private 不受 TFLM-compliance 鎖)。措辭:「Gemma S1 RMSNorm RVV-native int8 契約,對 Spike-backed golden + layer chain bit-exact」,**不宣稱 byte-identical to Coral**。
10. **rsqrt 保留純量(Grok #4)**:per-row 一次,便宜;向量化跨 row 是別的 tiling(留 optimization pass)。
11. **範圍**:先 1 個 RMSNorm(post-attn,gate_gemma3_s1 hidden=64)證 RVV-native + 省 cycle + golden,再套 ×4 + 全 layer。**不重排 (src*wq)>>14 於 y_adj 前**(Grok #1 critical:y_adj 須在 descale 前)。

**M3-RMSNorm 觸及**:cq_sequencer.c(MAT_RMSNORM handler RVV 重寫 + vxrm CSR)· gemma_quant_s1.py + 新 rvv_bitmodel.py(golden)· Spike microtest gate · gate_gemma3_s1/layer 重驗 · ADR。

**下一步:實作(firmware RVV kernel + rvv_bitmodel golden + Spike microtest)→ gate_gemma3_s1(hidden=64)bit-exact vs 新 golden + layer chain + cycle 實測 + flip report + disasm 守衛(含 vwmul/vsmul/vssra 無 64-bit helper loop)→ commit + ADR。**
