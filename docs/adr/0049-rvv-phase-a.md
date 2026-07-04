# ADR-0049 — 列 2:RVV Phase-A 補全(workload 導向子集,非 Coral backend 重寫)

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04:Phase A 必做清單 + 「與
  Grok/Codex 討論」——兩份顧問分析歸檔於 scratchpad,裁定入本 ADR)。
- Date: 2026-07-04
- Relates: ADR-0036(3B-3D 子集 + tail-undisturbed/vstart-illegal 契約)、ADR-0043(2D
  DMA)、P0④(vector-CSR checkpoint 契約)。

## 範圍裁定(User + Grok + Codex 三方一致)

**做**(TFLM/Gemma int8 缺口):S1 mask 族、S2 saturating、S3 LMUL m2/m4、S4 POOL
runtime。**不做**:Coral 級 rvv_backend/硬體 VCQ/雙 VALU(≈重做,違自建路線)、4-wide
scalar(IPC 非瓶頸)、**vlse/vsse RTL**(Grok:pooling/im2col 在本設計上「2D-DMA 排布 +
unit-stride vle + vmax/vredsum」勝出;gate_51 已驗 DMA 路;S4 改為 **DMA-tile ≡ RVV golden
等價引理**,除非 AOT codegen 證明 inline strided 熱點)。

## 切片契約

**S1 — mask 執行 + mask-dest ops + min/max(vexu-only,單暫存器寫,core 零改動)**
- masked arithmetic(vm=0):per-lane enable = `vm | v0[i]`;masked-off body =
  **undisturbed**(Spike 同;Grok 表格確認無衝突)。
- mask logicals(OPMVV,f6=011000..011111,vm=1 必要):vmand/vmnand/vmandn/vmxor/
  vmor/vmnor/vmorn/vmxnor——對 bits 0..vl-1 運算。
- 整數比較 → mask dest(1 bit/element):vmseq/vmsne(vv/vx/vi)、vmslt[u](vv/vx)、
  vmsle[u](vv/vx/vi)、vmsgt[u](vx/vi)——form 合法性入 q_illegal。
- vmin[u]/vmax[u](vv/vx)——max pool 直接需要。
- **mask-dest tail 政策**:先實作 undisturbed(與全域契約一致);spec 允許 agnostic——
  由 lockstep 對 Spike 仲裁(3B 前例:此 build 的 agnostic 即 undisturbed)。
- vstart≠0 對所有新算術/mask ops = illegal(沿用契約,Spike 仲裁)。

**S2 — saturating(vxsat/vxrm)**:vsadd[u]/vssub[u](置 vxsat)、vaadd[u]/vasub[u]
(vxrm 四模式捨入)、vssrl/vssra、vnclip[u]。vexu 新增 `vxsat_set` → csr;**注意 3A 修過
的 vx 別名組雙窗轉發**(EX/MEM + WB 同拍)。Checkpoint 加密度(Grok (b)):設 vxsat 的
指令後必查、不設的也查(防假置位)、vcsr 寫清 vxsat 的 directed corner、vill ladder 重跑。

**S3 — LMUL m2/m4(單 commit 原子性,Grok+Codex 同裁)**:vexu 內 **multi-beat**(如
vmem 的 drained 模式)算完整 group 存**內部 staging**;WB 的單一 commit 訊號觸發 vexu
同拍寫整組(VRF 在 vexu 內,可同緣寫 2/4 個暫存器)——kill/replay 丟整組,無部分 commit;
**不裂 uop**(per-commit lockstep 不變)。非法:群組未對齊 vd/vs、EMUL>8。

**S4 — POOL runtime kernels**:max pool = 2D-DMA 排布 + vle + vmax(+S1);avg pool =
vaadd/加總 + shift(+S2)。等價引理 gate:DMA-tile 路徑輸出 ≡ NumPy pooling golden
bit-exact,並與 TFLM reference pooling 對照。

## 驗證(每片:Spike lockstep + P0④ checkpoint 契約延續)

沿用 phase_22 harness(directed + random);random 語料按 Grok (e) corner 清單擴:
S1 vl∈{0,1,VLMAX-1,VLMAX}×mask{全0,全1,交錯}×比較符號邊界(-1/0/MAX)×v0 hazard;
S2 INT8_MIN/MAX 邊界、vxsat 跨兩指令 sticky、四 vxrm;S3 m2/m4×SEW{8,16,32}、奇 vd
非法、beat-1 vs beat-N-1 trap replay(原子性)。green-wash 守衛:mask-tail 若與 Spike
分歧必須以分歧修約(不許縮測);S3 期間 random 生成器暫不發 mid-group trap 直到原子性
gate 綠(Grok (c))。

## S1 結果(2026-07-04)

vexu 新增:masked arithmetic(lane enable `vm|v0[i]`,masked-off undisturbed)、
vmin[u]/vmax[u]、8 個 mask logicals、整數比較→mask dest(form 合法性)。**vexu-only,
core.v 零改動**(單暫存器寫路徑不變,如 Codex 結構分析預測)。
驗證:phase_22 `s1` directed 87 commits(corners:vl∈{0,1,VLMAX}、全0/全1 mask、
簽名邊界、mask-dest tail@vl=1、**masked-v0-dest illegal 終結子**)+ `vrand` 隨機
1060 commits(語料含 67 比較/23 mask 邏輯/62 min-max/44 masked,gate_56 斷言下限)
對 Spike 全符;VRF triage tap 471 筆;既有 grid/vill/valu/vmem 重綠;linker 區
4K→8K(ITCM 容量)。**Codex 抓到 1 High(Spike 實跑確認)**:masked body op 寫 v0
(dest 與 mask 重疊)RTL 原本放行、Spike 必 trap → q_illegal 補 guard + s1 終結子
覆蓋。mask-dest tail 政策 = undisturbed,與此 Spike build 一致(lockstep 仲裁)。

## S2 結果(2026-07-04)

vexu 新增:vsadd[u]/vssub[u](逐 lane sat flag,僅 active lanes 置 vxsat)、
vaadd[u]/vasub[u](vxrm 四模式)、vssrl/vssra(變動 shift 捨入)、vnclip[u](寬→窄
+ clip,fractional-LMUL 規則同 widening)。core.v:`eff_vxrm`(MEM+WB csr-next-val
雙窗——3A 教訓套用到新 consumer)、vex_sat 管線 + `wb_vxsat_set`(與 vector 寫同 kill
資格)、ID 讀 overlay 按年齡序。csr.v:vxrm_o + vxsat_set sticky。
驗證:s2 directed 110 commits(INT8 邊界、csrr-緊跟-sat、csrw-vxrm-緊跟-vaadd、四捨入
模式、masked 不置位、vnclip 邊界、vl=0、**sat;csrw-clear;csrr 年齡序 corner**)+
vrand 1386 commits(vxrm churn + sticky/clear probes,gate_57 語料下限)全符;全 targets
重綠。**Bring-up 抓到 2**:vaadd 取位 [8:2](多移一位)、OPMVV 的 operand-b 掉到 scalar
路徑(單元 TB 隔離定位)。**Codex 1 真發現(修+corner)**:WB-sat overlay 壓過較年輕的
MEM csrw 清除(年齡序 guard)。其餘捨入公式/vssra wrap/vnclip 重建/vasubu 語義經 Codex
對 RVV 1.0 規格逐項驗證 CLEAN。

## S3 結果(2026-07-04)

LMUL m2/m4 依裁定落地:vexu 內 **VM_GRP multi-beat**(drained-start 復用 vmem hold;每拍
一 part 入 staging;part 視圖 = 暫存器索引 + 元素窗 + v0 位移全部隨 part 平移)+ **WB 原子
群寫**(part0 走管線為權威值,parts 1..N-1 從 staging 同緣寫;w_grp/w_parts 隨管線帶 kill
資格;mask-dest 比較單暫存器寫,q_grp_w 排除)。合法性:m8 仍禁、群組對齊(vd/vs2/vs1)、
widen/redsum/nclip 維持自身規則、**vmem 維持 EMUL≤1(vlmax_el 補整數 LMUL 乘項)**。
驗證:s3 directed 72 commits(部件邊界 vl、跨部件遮罩、後部件飽和、群組比較、奇-vd 終結子)
+ s3i(OPMVV .vv 未對齊 vs1 illegal)+ vrand 1324 commits(m2/m4 configs、對齊暫存器池)
+ kernel/全 targets 重綠。**Bring-up 抓到 2 個真 bug**:①STORE-FP opcode 經 f6 aliasing
滑進 is_grp(其他使用點都有 is_vmem 優先序,新路徑漏了)→ vse@m4 靜默不落 store;
②e16/m2+vse16(EMUL=2)滑過 legality → 群組記憶體越界寫錯源。**Codex 1 真發現**:
OPMVV .vv(vaadd 族)vs1 對齊檢查漏(aligned random 池的盲區,與 S1 同類)→ 修 + s3i。
gate_42 的 3B 誠實界守衛隨 S3 更新(m8 仍禁)。
