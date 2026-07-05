# ADR-0054 — 完整 Zve32x roadmap(產品規格規劃)

- Status: **PROPOSED**(規劃;User 裁示 2026-07-05「規劃 A. 完整 Zve32x,這樣才能當產品規格」)。
  這是**多階段路線圖規劃**,非單一實作;每階段仍走 §2 紀律(arch confirm → Codex → Spike lockstep)。
- Date: 2026-07-05
- Mode: Fable 規劃 + coverage inventory(general agent 精讀 vexu.v/idu.v/csr.v/gates 產出)。
- Relates: ADR-0036(vector CSR + vset)、ADR-0049(RVV Phase-A S1-S4)、§3 向量列。

---

## §1 目標與定位

**product-spec 定位**:實作**完整 Zve32x**(整數 embedded vector,元素 ≤32-bit,無向量 FP),
使 NPU 可宣稱「任何 Coral Zve32x 程式的 drop-in」——不只 TFLM 特定 workload。**天花板仍是
Zve32x,不碰 RVV 1.0**(向量 FP / 64-bit 元素 / RV64V 都不做,Coral 也沒有)。

**誠實界**:完整 Zve32x 是**大工程**(數十條指令,含數個昂貴硬體項)。本 ADR 給分階段路線,
讓「開多大、先做哪些」成為排序決策;不承諾一次做完。

## §2 現況(coverage inventory,權威=vexu.v 解碼)

現 vexu 實作的是 **TFLM int8 推論子集**:config(vset* + 全 vector CSR + vill)、unit-stride
load/store(vle/vse 8/16/32)、vadd/vsub、vmin[u]/vmax[u]、**全 8 個 compare→mask**、8 個 mask
logical、S2 定點(vsadd[u]/vssub[u]/vaadd[u]/vasub[u]/vssrl/vssra/vnclip[u])、vwmul.vv/vwadd.wv、
vredsum.vs、vmv.x.s/vmv.s.x、vmerge、vmv.v.*、LMUL m1/mf*/m2/m4(**m8 禁**)。tail 恆 undisturbed
(match 本 Spike build);arithmetic vstart≠0 = illegal(Spike-matched)。

**這遠非完整 Zve32x**——缺:全部 bitwise/shift、一般 multiply/MAC、多數 widening/narrowing、
非-sum reductions、全部 mask-scan、全部 permutation、strided/indexed/segment/ff memory、vdiv。

## §3 缺口 → 分階段(cost/risk 分層)

### Phase-B — 整數核心補齊(便宜、高值、低風險)
純 decode + datapath 項複用,無新結構。**應優先**(補完後 vexu 才算「通用整數向量」)。
- **bitwise**:vand/vor/vxor(vv/vx/vi)
- **shift**:vsll/vsrl/vsra(vv/vx/vi)
- **vrsub**(vx/vi)
- **narrowing shift**:vnsrl/vnsra(**複用既有 vnclip datapath**,去掉 clip)
- **extension**:vzext.vf2/vf4、vsext.vf2/vf4
- **carry/borrow**:vadc/vsbc/vmadc/vmsbc
- **whole-register move**:vmv1r/2r/4r/8r.v
- risk:低(同形 ALU + generate loop);verify:Spike lockstep `--isa=zve32x_zvl128b` directed 網格
  + random 語料擴這些 f6。

### Phase-C — 乘法 + reduction 補齊(中等)
需乘法器複用 + reduction tree 擴充。
- **multiply**:vmul/vmulh/vmulhu/vmulhsu
- **MAC**:vmacc/vnmsac/vmadd/vnmsub(**kernel 高值**)
- **widening 全套**:vwaddu/vwsub[u]/vwadd.vv/.vx/vwmulu/vwmulsu/vwmacc[u/su/us]
- **vsmul**(定點分數乘,複用 vxrm 捨入)
- **reductions**:vredand/or/xor/minu/min/maxu/max、vwredsum[u](擴 vredsum 迴圈)
- risk:中(mulh 高位/widening-MAC 符號語意需逐項對 Spike);verify:directed corner(符號矩陣)
  + random。

### Phase-D — mask-scan + slides(中-難)
需 scan FSM / 跨 lane 位移。
- **mask population/scan**:vcpop.m、vfirst.m、vmsbf.m/vmsif.m/vmsof.m、viota.m、vid.v
- **slides**:vslideup/vslidedown/vslide1up/vslide1down
- risk:中-難(mask-scan 序列邏輯;slide 跨 lane 需 MEM-side 或 shift 網);verify:directed
  (vstart/vl 邊界、mask 交互)+ lockstep。

### Phase-E — permutation crossbar + 複雜 memory(昂貴,新硬體)
最貴的一類,每項近乎一個子單元。
- **gather/compress**:vrgather/vrgatherei16、vcompress.vm(全跨-lane crossbar)
- **indexed**:vluxei/vloxei/vsuxei/vsoxei(index address-gen 單元)
- **segment**:vlseg*/vsseg*(nf-strided sub-transfer FSM)
- **fault-only-first**:vle*ff(trap-on-element-0 + vl-trim)
- **strided RTL**:vlse/vsse(現走 2D-DMA detour;**決策**:產品規格是否需真 RTL,或 DMA 等價
  可接受並文件化)
- **whole-register / mask load**:vl1r…vs8r、vlm/vsm
- **vdiv/vrem**:vdivu/vdiv/vremu/vrem(iterative,per-lane 多拍;可複用 scalar divider 序列化)
- risk:高(新 address-gen/crossbar/trap 語意/iterative 除法);每項各自 §2 arch confirm。

### Phase-F — m8 LMUL(scaling)
擴 S3 的 multi-beat 群組到 8;群組對齊/WB 原子群寫延伸。verify:m8 網格 lockstep。

## §4 驗證計畫(全階段共用)

- **權威 = Spike lockstep `--isa=zve32x_zvl128b`**(phase_22 harness;現已含 vector CSR
  checkpoint 紀律)。每片 directed 網格(全 vv/vx/vi form × SEW × LMUL × mask)+ random 語料。
- **spec-conformance 註記(產品級需明確)**:①tail policy 目前恆 undisturbed;完整 Zve32x 若要
  agnostic(vta),需本 Spike build 的 `--isa` 對齊確認 ②arithmetic vstart≠0 目前 illegal(Spike-
  matched);spec 允許,若要放行需 Spike 語意對照。這兩項是**規格宣稱邊界**,列明避免過度宣稱。
- green-wash:m8/群組對齊/widen-overlap 等既有非法性守衛(gate_42 誠實界)隨每階段更新。

## §5 排序建議(non-binding,待 User 裁示)

1. **Phase-B 先**(便宜、把 vexu 從「TFLM 子集」升到「通用整數向量」——最大單位覆蓋增益/成本)。
2. **Phase-C 次**(乘法/MAC/reduction——通用 kernel 需要)。
3. **Phase-D**(mask-scan/slides)。
4. **Phase-E** 逐項評估(昂貴;strided 可能維持 DMA 等價、gather/compress/indexed/segment 各自
   ADR;vdiv 用 scalar divider 序列化控成本)。
5. **Phase-F**(m8)最後或按需。

**effort 誠實界**:B/C 相對機械(數週級,主要是 decode + datapath + 大量 lockstep 網格);
D 中等;**E 是主體工作量**(每項近一個子單元 + arch confirm);F 取決於 m2/m4 機具可延伸度。
完整 Zve32x = B+C+D+E+F 全綠 + spec-conformance 兩註記收斂,才可宣稱「完整 Zve32x 產品規格」。

## §6 review 後才實作

本 ADR = 路線圖。每個 Phase 開工前另出該 Phase 的 §2 架構確認(Coral/spec 對照 + 契約 + 驗證),
Grok 複核 → Codex 外科實作 → 我跑 Spike lockstep → commit。**沒有 per-phase 架構確認不落 RTL。**
