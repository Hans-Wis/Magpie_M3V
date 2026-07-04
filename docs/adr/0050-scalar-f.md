# ADR-0050 — 列 1:scalar F(RV32IMF)— 功能補齊最後一項

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04「列 1 scalar F」)。
  Mode:PL design + Grok pre-critique(全採納)+ Codex per-slice review。
- Date: 2026-07-04
- Relates: ADR-0036/0049(vector-CSR 機具 = 模板)、ADR-0045/0048(trace port)。

## Coral 對照(§2 第 1 問)

Kelvin scalar = RV32IM**F**_Zbb。本 ADR 把 NPU sequencer profile 升到 RV32IMF(`EN_F`
參數,host 維持 0)。**自建**:IEEE-754 單精度全部自寫(不 import HardFloat)。
權威 = Spike lockstep `--isa=rv32imf_*`。

## 契約(§2 第 2 問)

- **fexu** 模組(F regfile 32×32 + EX 組合運算;WB commit 同 scalar kill rules),
  仿 vexu 整合形。flw/fsw 走**既有 scalar LSU**(f3=010 於 LOAD/STORE-FP,原 vexu
  拒收路徑改道)。
- **fcsr 契約 = vector-CSR 同構**:fflags(0x001)sticky-set 於 WB(≈vxsat)+ 年齡序
  讀 overlay;frm(0x002)eff 值雙窗轉發(≈vxrm);fcsr(0x003)別名互映;
  **mstatus.FS[14:13]**(≈VS):Off→F ops illegal、F 副作用→Dirty、SD 併入。
- **rm 解析於 execute**:rm=101/110 或 rm=111 且 frm 無效 → illegal(Spike 同)。
- **語義基準(Grok 表)**:canonical qNaN=0x7FC00000;fmin/fmax = IEEE-2019
  minimumNumber(±0 序、單 sNaN → 另一操作數 + NV、雙 NaN → canonical);
  fcvt.w.s NaN→0x7FFFFFFF+NV / 越界飽和+NV,wu 對應;fcvt.s.w 精確無 NX、不精確
  NX;feq 僅 sNaN NV,flt/fle 任何 NaN NV;flw/fsw 無 fflags。
- **切片**:F1 搬移/sgnj/比較/classify/min-max/cvt/flw-fsw/fcsr+FS;F2 fadd/fsub/fmul
  (全 rm 全旗標);F3 FMA(**單一捨入;有效位路徑 ≥74b 或全對齊 sticky-OR**——Grok (c)
  寬度規則);F4 fdiv/fsqrt(radix-2 逐位,~28-32 拍預算,drained-hold 槽,無部分
  fflags commit,replay 自指令起點)。**嚴格分片把關:F2 捨入路徑證完才進 F3**。
- **DV 可見性(Grok (e) 採納)**:RVFI trace 擴 **f-reg 寫欄**(rvfi_f_valid/f_rd/
  f_wdata)——lockstep comparator 逐 commit 直接比 F 寫 vs Spike log(fmv.x.w probes
  降級為輔助);fcsr checkpoint 沿 P0④ 紀律。

## 驗證計畫(§2 第 3 問)

phase_22 harness 擴 F:comparator 比對 x-rd + **f-rd** + CSR checkpoints。每片
directed(Grok corner 清單:F1 全 fclass 格/cvt 飽和/±0 與 sNaN 對/feq-flt NaN 矩陣;
F2 全 rm×NaN 傳播×∞±∞×0×∞×subnormal+NX;F3 與 mul+add 相異的 fused 案例+極端指數差;
F4 div-by-zero/sqrt(-1)/subnormal 商/中途 kill-replay)+ random 語料擴 F ops。
gate_60+(per slice)。

## F1 結果(2026-07-05)

fexu(F regfile + F1 組合運算)+ 完整 fcsr/FS 契約落地,**vector-CSR 機具鏡射策略全面成功**
——bring-up 修的四個洞全是同構已知型:①F-reg RAW stall(鏡 vector conservative 規則)
②fflags/FS 的 ID 讀 overlay 年齡序(含 younger-csrw guard,S2 教訓直接套)③csr.v 同位址
WB bypass 名單漏 F 群 ④MEM 窗跨別名轉發(3A 塊鏡像)。F-reg 寫以 rd=64+f 列進 commit
trace(RVFI 埠加 rvfi_f_*),comparator 對 Spike f-寫逐筆位元比對。
f1 directed **135/135 全符**(flw/fsw、sgnj NaN payload、feq/flt NaN 矩陣、min/max
IEEE-2019 規則、fclass 全格、fcvt 全捨入×飽和×NV/NX、動態 rm 轉發 corner、fcsr 別名、
FS dirty);全部 vector targets 在 rv32imf ISA 下重綠(mstatus.FS 兩側一致);全套 0 新增
失敗(一個 M1 源碼錨點 gate 隨 mstatus 版型治理更新)。F2/F3/F4 續。
