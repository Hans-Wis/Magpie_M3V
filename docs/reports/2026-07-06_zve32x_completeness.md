# Zve32x Drop-in 完整度報告 — Magpie_M3V NPU

> 日期 2026-07-06 · design_id `cpu_m3v` · HEAD `be545da` · 權威 = Spike lockstep
> `--isa=rv32imf_zve32x_zvl128b`(phase_22)· 資料來源 = `IP/cpu_m1/rtl/vexu.v` decode
> (code-first,§6)+ ADR-0036/0049/0055-0060。

## 0. 結論(誠實界)

**Zve32x 的「計算面」= 完整**:所有整數算術、定點、比較→mask、mask 邏輯/掃描、
reduction、permutation、LMUL 全檔位(mf8..m8)皆實作並經 Spike lockstep 逐位驗證。
**唯一系統性缺口 = 非-unit-stride 記憶體定址**(strided / indexed / fault-only-first /
mask-ld-st / whole-register-ld-st)。

**可宣稱**:任何**只用 unit-stride 記憶體**的 Zve32x 程式(= TFLM 自動向量化 CNN 推論的
絕大多數)可 **drop-in**。
**不可宣稱**:用 strided/indexed/ff 記憶體定址的 Zve32x 程式尚無法 drop-in(見 §3)。

---

## 1. 完整實作清單(逐類,對 Zve32x spec)

Zve32x = 嵌入式向量,SEW ∈ {8,16,32},純整數(無 FP 向量=Zve32f、無 64-bit 元素=Zve64)。
✅=實作+lockstep · ⚠️=實作但有 scope-cut · ❌=未做。

### 1.1 配置 / CSR — ✅ 完整
| 項目 | 狀態 | 證據 |
|---|---|---|
| vsetvli / vsetivli / vsetvl | ✅ | ADR-0036 gate_40 |
| vstart/vxsat/vxrm/vcsr/vl/vtype/vlenb + vill + mstatus.VS | ✅ | ADR-0036 gate_41 |
| LMUL mf8/mf4/mf2/m1/m2/m4/**m8** | ✅ | vset general path + ADR-0059(m8)gate_80 |

### 1.2 整數算術 — ✅ 完整
| 群組 | 指令 | 狀態 | 證據 |
|---|---|---|---|
| add/sub | vadd vsub vrsub (vv/vx/vi) | ✅ | 3B / B1 |
| bitwise | vand vor vxor | ✅ | B1 gate_62 |
| shift | vsll vsrl vsra | ✅ | B1 |
| min/max | vminu vmin vmaxu vmax | ✅ | S1 gate_56 |
| multiply | vmul vmulh vmulhu vmulhsu | ✅ | C1 gate_66 |
| divide | vdivu vdiv vremu vrem | ✅ | E1 gate_77(組合除法,timing deviation 如 F4)|
| MAC | vmacc vnmsac vmadd vnmsub | ✅ | C2 gate_68 |
| widening mul | vwmul vwmulu vwmulsu | ✅ | C4b gate_70 |
| widening add/sub | vwadd[u] vwsub[u] (.vv/.vx/.wv/.wx) | ✅ | C4a gate_69 |
| widening MAC | vwmaccu vwmacc vwmaccsu vwmaccus | ✅ | C4c gate_71 |
| carry/borrow | vadc vsbc vmadc vmsbc | ✅ | B3 gate_64 |
| ext | vzext/vsext .vf2/.vf4 | ✅ | B2b gate_63 |
| narrowing shift | vnsrl vnsra | ✅ | B2a gate_63 |

### 1.3 定點 — ✅ 完整
| 群組 | 指令 | 狀態 | 證據 |
|---|---|---|---|
| sat add/sub | vsaddu vsadd vssubu vssub | ✅ | S2 gate_57 |
| averaging | vaaddu vaadd vasubu vasub | ✅ | S2(op_avg)|
| sat mul | vsmul | ✅ | C5 gate_73 |
| scaling shift | vssrl vssra | ✅ | S2 |
| narrowing clip | vnclipu vnclip | ✅ | S2 |

### 1.4 比較 / mask — ✅ 完整
| 群組 | 指令 | 狀態 | 證據 |
|---|---|---|---|
| compare→mask | vmseq vmsne vmsltu vmslt vmsleu vmsle vmsgtu vmsgt | ✅ | S1 |
| mask logical | vmand vmnand vmandn vmxor vmor vmnor vmorn vmxnor | ✅ | S1 |
| mask scan | vcpop.m vfirst.m vmsbf/vmsof/vmsif.m viota.m vid.v | ✅ | D1a/D1b gate_74/75 |

### 1.5 Reduction — ✅ 完整(scope: m1 + vm=1)
| 群組 | 指令 | 狀態 | 證據 |
|---|---|---|---|
| single-width | vredsum vredand vredor vredxor vredminu/min vredmaxu/max | ✅ | C3 gate_67 |
| widening sum | vwredsum vwredsumu | ✅ | C4d gate_72 |
| ⚠️ masked reduction (vm=0) | — | ❌ defer | scope-cut(誠實界,ADR-0060 §1) |

### 1.6 Permutation / move — ✅ 幾近完整
| 群組 | 指令 | 狀態 | 證據 |
|---|---|---|---|
| scalar move | vmv.x.s vmv.s.x | ✅ | 3D |
| broadcast/merge | vmv.v.x/.v.i/.v.v vmerge | ✅ | 3B |
| slide | vslideup vslidedown vslide1up vslide1down | ✅ | D2 gate_76 |
| gather | vrgather.vv/.vx/.vi | ✅ | E3 gate_79 |
| ⚠️ gather ei16 | vrgatherei16 | ❌ defer | 16-bit index EMUL 群組(ADR-0058)|
| compress | vcompress.vm | ✅ | **E4 gate_81(本報告日)** |
| whole-reg move | vmv1r/2r/4r/8r | ✅ | B4 gate_65 |

### 1.7 記憶體 — ⚠️ **僅 unit-stride(+segment);其餘缺**
| 定址模式 | 指令 | 狀態 | 證據 / 缺口 |
|---|---|---|---|
| unit-stride | vle8/16/32.v vse8/16/32.v | ✅ | 3C gate_43(EEW≠SEW、resumable vstart)|
| segment unit-stride | vlseg\<nf\>e / vsseg\<nf\>e (nf2-8, m1/m2/m4) | ✅ | E2 gate_78 |
| **strided** | vlse8/16/32 vsse8/16/32 | ❌ | **未做**(decode 只認 mop=00)|
| **indexed** | vluxei/vloxei/vsuxei/vsoxei | ❌ | **未做** |
| **fault-only-first** | vle8/16/32ff | ❌ | **未做**(需 vl CSR 副作用)|
| mask ld/st | vlm.v vsm.v | ❌ | 未做(低值)|
| whole-reg ld/st | vl1r/2r/4r/8r vs1r/... | ❌ | 未做(低值)|
| strided/indexed segment | vlsseg/vluxseg/... | ❌ | 未做 |

---

## 2. 覆蓋率統計(對 Zve32x spec)

- **計算類(算術+定點+比較+mask+reduction+permute)**:實作 **~100%**
  (缺 vrgatherei16、masked-reduction 兩個誠實 scope-cut)。
- **記憶體類(6 種定址模式)**:實作 **2/6**(unit-stride + unit-stride-segment);
  缺 strided / indexed / fault-only-first / mask-ld-st / whole-reg-ld-st。
- **LMUL**:mf8..m8 **全檔位**。

---

## 3. Drop-in 分析:哪類 Zve32x 程式可 / 不可

| 程式類別 | Drop-in? | 說明 |
|---|---|---|
| 純算術 kernel(dot/GEMV/element-wise/activation) | ✅ | 全算術 + unit-stride,完整支援 |
| compare/mask/select(ReLU、clamp、argmax head) | ✅ | compare→mask + mask-scan + vcompress 齊 |
| unit-stride CNN(pointwise/1x1、pooling) | ✅ | unit-stride vle/vse + reduction |
| depthwise conv(spatial 3×3 per-channel) | ⚠️ | **編譯器若 emit RVV strided load → 不 drop-in**;若走 host im2col + 2D-DMA + mat_engine(本 NPU 既有路)→ 可(見 MobileNet e2e 報告)|
| gather/scatter(embedding、sparse) | ❌ | 需 indexed load(未做)|
| 變長迴圈(strlen 式) | ❌ | 需 fault-only-first(未做)|

**關鍵判斷(MobileNet 可行性分析已裁決,2026-07-06)**:TFLM int8 CNN 推論的**熱路徑
= 算術 + unit-stride**,已完整。**depthwise conv 不需要 strided/indexed RVV、不需要新
硬體**——經既有 **host im2col + 2D-DMA(sequencer firmware loop)+ mat_engine
(diagonal-block 或 N=1-per-channel 映射)** 即可表達(~1/8 陣列利用率,零 RTL 改動)。
真正的缺口是**純 host 軟體**(depthwise lowering、SAME padding + stride-2、multi-layer
driver),非 datapath。故:
- **走 NPU offload 路(mat_engine + 2D-DMA)= 不需 strided/indexed**。
- 僅當選擇 **compiler-vectorized RVV 路** 才需 strided vlse/vsse(那條路是替代方案,非必要)。

**⇒ 使用者裁示「若真需要 strided/indexed 再回頭做」的條件:MobileNet 走 offload 路
= 不觸發**(strided/indexed 維持 deferred scope-cut,誠實界)。

---

## 4. 缺口回補計畫(若 e2e 證明需要)
Grok ROI 序(`docs/reviews/2026-07-06_phase_e_tail_plan_grok.md`):
1. **strided vlse/vsse**(最高 ROI,vmem FSM 擴充 + resumable vstart)
2. **indexed vluxei/vsuxei**(vmem FSM 復用 segment + index 讀)
3. defer:fault-only-first(vl CSR 副作用)、masked-reduction、vrgatherei16、
   mask-ld-st、whole-reg-ld-st(低值,非 TFLM 熱路徑)。

---

## 5. 誠實界聲明
- 每個 ✅ 都有具名 gate + Spike lockstep 逐位證據(非「看起來像」)。
- scope-cut(⚠️/❌)明示未做,DUT 對這些編碼 **trap illegal**(誠實 stricter,非假執行)。
- 「drop-in」限定於 **unit-stride 記憶體 + 全計算類** 的 Zve32x 程式;非-unit-stride
  記憶體定址尚未支援,不在宣稱範圍內。
