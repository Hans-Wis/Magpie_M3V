# 電路充分性證明 — MobileNet / Gemma-3 LLM(Magpie_M3V)

> 日期 2026-07-06 · HEAD `cb97603` · **目的:先證明現有電路(datapath)足以支撐 MobileNet
> 與 Gemma-3 LLM 的熱點運算,避免「缺電路 → 大量軟體 emulation → 效能崩」的陷阱。**
> 方法 = 逐 primitive 對應到硬體 datapath + 標註**是否已有 gate 硬證** + **效率分級**
> (是否落到 scalar-serial 慢速軟體)。code-first(vexu.v/mat_engine.v/fexu.v/npu_top.v)。

## 0. 結論(先講)

**電路充分。** MobileNet 與 Gemma-3 的**每一個熱點 primitive 都對應到已被 gate 證過的
硬體 datapath**(mat_engine 矩陣 / RVV 向量 / scalar-F),**沒有任何高頻迴圈落到
scalar-serial 軟體 emulation**。兩個效率注意點(非阻塞):
1. **depthwise conv** 走 mat_engine block-diagonal = **~1/8 MAC 利用率**(已驗 gate_82)。
2. **LLM activation(gelu/exp)必須走「向量多項式」而非「LUT gather」**:本電路**無 indexed
   load、vrgather 限 m1 ≤16 lane** → 256-entry LUT 只能 scalar-serial(慢);但**向量多項式
   所需 op(vmul/vmacc/vadd/vsra/vsmul/vssra)全部已證** → activation 可全向量、零 scalar
   瓶頸。**這是本審計最關鍵的效能結論。**

## 1. 三條 datapath + 效率分級

| datapath | 位置 | 適用 | 平行度 |
|---|---|---|---|
| **mat_engine** | npu_top `u_mat`(獨立 int8 8×8→256-MAC + gemmlowp requant)| 所有 GEMM | **矩陣平行**(256 MAC/cyc)|
| **RVV vexu** | sequencer core 內(`EN_RVV=1`)| elementwise / reduce / mask / permute / **向量多項式 activation** | **向量平行**(≤16 e8 lane/op)|
| **scalar-F** | sequencer core 內(`EN_F=1`,fexu)| rsqrt / 少量純量超越函數 | **純量序列**(1/op)|

**效率分級(對熱點迴圈)**:🟩 矩陣平行 · 🟦 向量平行 · 🟨 純量但低頻(可接受)·
🟥 純量-serial 高頻(**效能陷阱,要避免**)。

## 2. MobileNet(CNN)— 逐 primitive

| primitive | datapath | 分級 | 電路硬證 |
|---|---|---|---|
| pointwise 1×1 conv / FC | mat_engine GEMM | 🟩 | gate_48/49/50 |
| **depthwise 3×3**(block-diagonal conv)| mat_engine GEMM | 🟩(**~1/8 util**)| **gate_82** |
| per-channel requant | mat_engine RESCALE_PC | 🟩 | gate_50 |
| pooling(max/avg)| RVV vle/vmax / 寬化和+vnclip | 🟦 | gate_59 |
| bias fold / ReLU clamp | mat_engine(fold + clamp)| 🟩 | gate_48 |
| im2col / 2D-DMA gather | npu_dma(sequencer loop)| 🟩(burst)| gate_51 |

**MobileNet 判定:電路充分,全硬體路,零 🟥。** 唯一效率注意 = depthwise 1/8 util
(可接受;若要拉高利用率是未來 mat_engine 微架構優化,非缺電路)。

## 3. Gemma-3 LLM — 逐 primitive

| primitive | datapath | 分級 | 電路硬證 / 說明 |
|---|---|---|---|
| Q/K/V/O 投影、gate/up/down、QKᵀ、AV(**全 GEMM,~90%+ FLOPs**)| mat_engine | 🟩 | gate_45/50(int8 GEMM+requant)|
| int4 權重解包 | RVV vand/vsrl/vor | 🟦 | gate_62(bitwise)|
| residual add / scale | RVV vadd / vsmul.vx | 🟦 | gate_62/73 |
| RMSNorm:平方+reduce | RVV vwmul + vredsum/vwredsum | 🟦 | gate_70/67/72 |
| RMSNorm:**rsqrt** | **scalar-F** fsqrt+fdiv | 🟨(**per-token 低頻**,O(seq) 非 O(seq·hidden))| gate_60/61 |
| RMSNorm:× (1+w) scale | RVV vmul.vx | 🟦 | gate_66 |
| RoPE:rotate + sin/cos | RVV vmul/vadd/vslide + **預算表**(TCM)| 🟦 | gate_66/62/76 |
| causal + sliding mask | RVV vmslt/vmseq + mask logic + **vmerge(-INF)** | 🟦 | gate_56 |
| softmax:max / sum reduce | RVV vredmax / vredsum | 🟦 | gate_67 |
| softmax:**exp** / MLP **gelu**(超越函數)| **RVV 向量多項式**(vmul/vmacc/vadd/vsra Horner + range-reduce shift/mask)| 🟦(**關鍵:避開 LUT-scalar**)| 所需 op 全證 gate_62/66/68;LUT 路 = 🟥(見下)|
| softmax:倒數(1/sum)| RVV vdiv 或 Newton | 🟦 | gate_77(vdiv)|
| gelu⊙up、attn⊙v elementwise | RVV vmul | 🟦 | gate_66 |
| embedding lookup(單 token)| **host contiguous-row DMA** | 🟩(burst)| gate_51 路 |
| KV-cache 讀寫(head_dim 連續佈局)| RVV vle/vse unit-stride + scalar 外迴圈 | 🟦 | gate_43 |

**Gemma-3 判定:電路充分。** 全部熱點(GEMM + elementwise + reduce + activation)= 🟩/🟦
硬體平行路。唯一 🟨 = rsqrt(scalar-F,但 per-token 低頻,非瓶頸)。

## 4. 🟥 掃描:哪些「若做錯」會落到高頻 scalar-serial?

只有 **一處**,且有向量替代:

| 潛在 🟥 | 為何 | 避開法(全向量,已證)|
|---|---|---|
| **activation via 256-entry LUT**(gelu/exp)| **無 indexed-load(vluxei);vrgather 限 m1 ≤16 lane** → 表跨 16 暫存器無法向量 gather → 每元素 scalar `lw` = O(N) serial | **改用向量多項式**:Horner(vmul/vmacc/vadd)+ range-reduction(vsra/vand),對整個向量一次算 degree 次 → O(degree) 向量指令,非 O(N) scalar。**所有 op 已證**(gate_62/66/68)。 |

**結論:只要 activation 走向量多項式(而非 LUT),Gemma-3 無任何高頻 scalar-serial 迴圈。**
這正是本電路的正確 kernel 策略,且完全在既有硬體能力內。

## 5. 對照 Coral(parity,非缺口)
Coral Kelvin 同為 **Zve32x 整數向量 + MAC 陣列 + scalar-F**,亦無向量超越函數硬體、亦
用整數 activation(LUT/poly)+ scalar 輔助。故本電路的分工與效率分級**與 Coral 同級**——
凡 Coral 做得到的,本電路同樣硬體路做得到。

## 6. 誠實界 + 建議
- **已證(硬 gate)**:mat_engine GEMM+requant(gate_45/50)、depthwise on mat(gate_82)、
  全 Zve32x op(gate_62-81)、scalar-F fsqrt/fdiv(gate_60/61)、pooling/DMA(gate_59/51)。
  **primitive 層級電路已全數硬證。**
- **未證(composition,非電路)**:把這些 primitive 組成完整 LLM kernel(softmax/gelu-poly/
  RMSNorm 的 firmware)尚未寫——但**用的都是已證 op**,是 **kernel 軟體工作,非缺電路**。
- **建議下一步(可選,強化證據)**:做**一個向量多項式 activation kernel(gelu 或 exp)
  RVV lockstep bit-exact + 精度 bound** 的實測,把「activation 全向量、非 scalar-LUT」
  從論證升級為 RTL 實證(mirror gate_82 對 depthwise 的角色)。這是唯一尚未有 composed
  硬證的 Gemma primitive。

**底線:現有電路足以支撐 MobileNet 與 Gemma-3 的所有熱點於硬體平行路;不存在「缺電路
必須大量 scalar 軟體 emulation」的高頻瓶頸(唯一風險 activation-LUT 有全向量替代)。
剩餘是 kernel 軟體,不是電路。**
