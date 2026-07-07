# mat_engine v2 · Phase B 設計 — activation-stationary + weight double-buffer(for review)

- **Status:** DESIGN(待 Grok 架構 + Codex RTL-reality review)· 2026-07-07 · Claude
- **上位:** ADR-0067 · Phase A(`npu_ml_ctrl`,已達標 3.12×,commits d360a03/6df51ed/3958919)
- **鐵律:** MAC 數學凍結;ML_V2_EN=0 → 韌體路零回歸;**Phase B 改變交易流(不再 E1-等價),故驗證=bit-exact 輸出 + cycle**(非交易比對)。

---

## §1 為什麼 Phase B(gate_67 實測背書)

Phase A 把 q_proj 13,350→4,282,**省的 100% 是編排稅**(core* 9,052→194)。實測分解:

| 組成 | cyc | % ML | 說明 |
|---|---:|---:|---|
| **dma** | **3,408** | **80%** | ⭐ 新瓶頸 |
| mat | 680 | 16% | MAC+requant,不可再省 |
| other | 194 | 4% | 硬體 handshake |

**DMA 3,408 拆解(每 tile LOAD_W 400w × 8 = 3200w + store 128w)**:每 tile 的 400w blob =
header(padding 到 A_OFF=0x240=**144w**)+ **activation 128w** + weights 128w。其中:
- **activation 逐 tile 重載**:q_proj 8 tiles 用**同一份輸入**,activation 128w × 8 = **1,024w 冗餘**(應載一次=128w)。
- header padding 144w × 8 = ~1,150w(次要,佈局重整才省)。

→ **B1 = activation-stationary**:activation 載一次進常駐 TCM,per-tile 只 DMA [param+weights]。省 ~1,024w ≈ ~900-1,000 cyc。**dma 3,408→~2,400,total 4,282→~3,300(~1.3×)**。
→ **B2 = weight double-buffer**(次要,seq=4 DMA-bound 下小,production compute-heavy 下大):tile N compute 時預取 tile N+1 權重,藏 mat(680)於 DMA 後。

## §2 Phase B scope(B1 優先)

**B1(做)**:activation-stationary。**B2(設計但可延)**:weight double-buffer overlap(需 2 acc bank + 2 weight TCM region)。**不做**:header padding 重整(佈局大改,另議);K>64 多 chunk(Phase A.2)。

## §3 B1 設計 — activation-stationary

### 3.1 runtime blob 佈局改動(新 lower 變體)
現行:per-tile blob = [header(fold+param)|activation|weights]。**新**:
- **activation blob**(128w = 8 rows × 64 K × int8 = 512B)放 shared 固定位址 `SHARED_ACT`,**tile 迴圈前載一次**到常駐 TCM `TCM_ACT`(不被 per-tile 覆蓋)。
- **per-tile blob** = [header(fold+param)|weights](272w),放 `SHARED_BLOB + tile*stride`。
- golden 不變(同樣的 GEMM,只是 DMA 少載冗餘 activation)。

### 3.2 FSM 改動(npu_ml_ctrl)
- 新 `S_LOADA`(job 開始、tile 迴圈前一次):DMA `SHARED_ACT` → `TCM_ACT`(128w),wait done。
- per-tile `S_LDW`:DMA per-tile [header|weights] → `TCM_WEIGHT`(272w,新 LOAD_LEN)。
- `S_OP`:`a_addr = TCM_ACT`(常駐 activation)、`b_addr = TCM_WEIGHT + weight_off`(per-tile 權重)。
- 其餘(LOADACC/RESCALE_PC/STORE)不變。
- 新凍結常數:`SHARED_ACT`、`TCM_ACT`、新 LOAD_LEN(272)、weight_off。

### 3.3 TCM 佈局(避免衝突)
`TCM_ACT` 常駐區不可與 per-tile weight blob DMA 區、mat OUT(0x800)、CQ scratch 重疊。候選:activation 128w 放 TCM_WEIGHT 之上或獨立區(需查 npu_tcm 容量 + bank budget ADR-0044)。**開放問題**:放哪最省 bank 衝突?

## §4 B2 設計(weight double-buffer,可延)
2 acc bank(0/1 交替)+ 2 weight TCM region。tile N:OP/RESCALE 用 bank N%2、weight region N%2;同時 `ml_overlap` 預取 tile N+1 weights DMA 到 region (N+1)%2。RESCALE→STORE 用 bank N%2。**hazard**:同 bank 累加序列化(Phase A 已守);跨 bank overlap 需 DMA 與 mat 並行——但 npu_dma 與 mat_engine 是獨立引擎,可並行(Phase A 是序列化 wait,B2 解除)。需 cmd FIFO 或雙-issue FSM。**seq=4 收益小(DMA≫mat),production 大**——故可延到 B1 量完再評估。

## §5 驗證(gate_67 擴充)
- **bit-exact**(權威,取代 E1 交易比對——B1 交易流已異於韌體):q_proj 8-tile 過 B1 路 → SHARED_DST 512 bytes == golden(同 Phase A gate_67 golden)。
- **cycle**:ML_V2_CYCLES + breakdown(mat/dma/other),證 dma 降 ~900、total ~3,300。
- **回歸**:ML_V2_EN=0 gate_45/46 綠;Phase A 路(若保留為 mode)仍 4,282。
- **green-wash 守衛**:golden 不改;dma 降幅要對得上「省的是 activation 重載」(breakdown 佐證);不得只縮 LOAD_LEN 而漏載真權重(bit-exact 會抓)。

## §6 開放問題(給 review)
1. **activation-stationary 的 TCM 常駐區放哪**(容量 + bank budget ADR-0044 不違規)?load 一次 vs 每 n_groups 一次(seq>8 多 group 時 activation 隨 group 變)?
2. **B1 是否值得先做 vs 直接 B2**?實測 B1 省 ~900(DMA-bound 主因),B2 seq=4 省 ~680 但 production scale。傾向 **B1 先**(單純、量得到、DMA-bound 直接命中)。
3. **B1 改 lower 變體 vs 參數化現行 lower**?新變體較乾淨但多一份 codegen;參數化省碼但複雜。
4. **Phase A 路保留否**(ML_V2_EN 選 A vs B,或 B 取代 A)?傾向 B 取代 A(A 是 B 的退化,B1 純贏)。
5. header padding(144w/tile)要不要順手收(佈局重整,再省 ~1,150w)?傾向**分開**(B1 先證 activation-stationary,padding 另議)。

**下一步:review 定案 → 出實作規格(runtime 變體 + npu_ml_ctrl S_LOADA + 常數)→ Codex/我實作 → gate_67 擴 bit-exact + cycle。**
