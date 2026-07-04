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

## F2-F4 結果(2026-07-05)— row 1 關閉

fadd/fsub/fmul(F2)、fmadd/fmsub/fnmadd/fnmsub(F3)、fdiv/fsqrt(F4)一次落地,
路線 = **忠實轉寫 Berkeley softfloat-3**(Spike 自身的浮點權威,故 lockstep 逐位可證):
- `rp32` 共用捨入器 = roundPackToF32(tininess **after** rounding;RNE/RMM=+0x40、
  RDN/RUP 依號 +0x7F;round-add 以 32-bit 寬和避免 31-bit 截斷;pack 用加法讓
  mantissa 進位自然滾入 exponent)。
- F2 = addMagsF32/subMagsF32(subnormal 以 `(eA!=0)?(xA|hidden):(xA<<1)` 倍增訣);
  F3 = mulAddF32 64-bit 對齊和單一捨入路徑(shortShiftRightJam64);
  F4 div = 全寬商 + 餘數-jam sticky(`q[5:0]==0 → q |= (sgB*q != num)`);
  fsqrt = 奇偶摺疊 radicand + restoring 整數開方 + 同款 sticky。
- **ADR 偏離紀錄**:原計畫 F4 為 radix-2 多拍(~28-32 cycle);實作為**組合邏輯**
  (sim-level 正確性先行)。時序收斂(pipeline/多拍化)歸 Phase 7 harden,屆時憑
  本 ADR 的 lockstep 證據做等價重驗。

bring-up 修四洞(全屬既知型):①fma_negc 多了一個 XOR(fnmadd/fnmsub 加數號反)
②fsqrt radicand 移位 30/31 應為 37/38 且 E 奇偶反 ③fsqrt expZ 混入 unsigned concat
毒化 signed 運算(3D 教訓重演)④rp32 round-add 在 s=0x7FFF_FFFE 溢位截斷。

**Codex review 抓到第五洞(High,random 語料盲區)**:equal-exponent `fsub` 相消路徑
(subMags,expDiff==0)。softfloat `subMagsF32` 在算 `expZ = expA - shiftDist` 前先
`if (expA) --expA;`——因為 packToF32UI 是加法式(`(exp<<23)+sig`),正規化後 sig 的
leading-1 落在 bit 23 會**進位滾入指數欄**;若不預減 expA,結果高一個指數。例:
`1.5 - 1.25` 應 `0x3E800000`(0.25),舊碼算成 `0x3F000000`(0.5);`(min_normal+1ulp)
- min_normal` 應 `0x00000001`,舊碼算成 `0x00000002`。**random 幾乎不採樣「兩浮點同指數」
故漏,directed 的 fsub corner 又都落在 0/跨指數**——靠 review 抓。修法照 softfloat 預減
expA(underflow 分支 shiftDist 亦用預減後的 expA)。gate_61 加相消 directed corner
(1.5-1.25、pi 同指數差、subnormal-underflow、subnormal-subnormal)鎖此路徑,f2 升
269→301 commits 全符。**教訓:等指數相消是 random 的結構盲區,凡「同指數運算」路徑需
directed 專打**。Codex 另提 Medium:`srj64(...)[30:0]` 函式呼叫直接位選 Verilator/VCS
收但 yosys/iverilog 拒 → 6 處全改先存 64-bit temp 再位選(yosys `read_verilog -sv`
now parses clean),為 Phase 7 Spyglass 簽核鋪路。

**證據(gate_61)**:f2 directed corner **269/269**(Grok 清單:全靜態+動態 rm、NaN 傳播、
∞∓∞、0×∞、OF/UF 梯 per-rm、fused-vs-split FMA 含極端指數差與 0×∞+qNaN、DZ/NV/
subnormal 商、sqrt exact/NX/NV);random 語料 **5 seeds 共 ~5,524 commits**(specials
密度 35%,含 sNaN/inf/subnormal/±0/近溢位指數/rm churn)——每筆 f-寫逐位、每個
fflags probe 逐位 vs Spike `rv32imf_zve32x_zvl128b`。全 14 個 phase_22 targets 重綠;
phase_20 directed 1164 + random 10,809 重綠(TB 暫時 TRIAGE 碼已清)。
**§3 row 1(純量 ISA)升 GREEN:RV32IMF 完整,Coral Kelvin scalar profile 對齊。**
