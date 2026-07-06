# V5 — 首份 Verilator code coverage 報告(ADR-0063)

> 日期 2026-07-06 · in-sandbox · DUT = `tb_npu_lockstep`(npu_top + cpu_m1 core + vexu +
> fexu + mat_engine + dma + tcm)· 刺激 = phase_22 向量回歸(34 targets)· 工具
> `flow/coverage/verilator/{run_cov.sh, codecov_report.py}` · 基準 `codecov_report.json` ·
> gate_91。**G1:code coverage = 完整度,非正確性(lockstep 才是權威;每個 run 都 phase_22
> lockstep 驗過)。**

## 方法
Verilator `--coverage-line --coverage-toggle` 建 DUT → 逐 phase_22 firmware 跑 → 每 run 出
`coverage.dat` → `verilator_coverage` 合併 → per-file line/toggle %。

## 首份結果(向量回歸刺激)

| 模組 | line | toggle | 判讀 |
|---|---|---|---|
| **vexu.v** | **98%** (53/54) | **99%** (92912/94050) | ⭐ 向量單元(最大新 RTL)——**V1 指令覆蓋閉合直接驅動** |
| **fexu.v** | **93%** (55/59) | **95%** (2015/2128) | ⭐ scalar-F(f1/f2 frand)|
| lsu.v | 100% (18/18) | 100% (396/396) | 記憶體介面 |
| core.v | 66% (62/94) | 56% (6571/11716) | pipeline 主幹(host+NPU 路混合)|
| npu_top.v | 72% (13/18) | 34% (1859/5542) | NPU 頂層(offload 路未刺激)|
| **mat_engine.v** | 17% (4/24) | 19% (3945/20838) | ⚠️ 向量回歸不走 CQ/mat 路 |
| **npu_dma.v** | 15% (2/13) | 4% (39/924) | ⚠️ 需 offload 刺激 |
| **npu_axil_regs.v** | 11% (10/92) | 6% (161/2482) | ⚠️ 需 CQ/CSR 刺激 |
| bmu.v | 6% (2/33) | 97% (520/536) | ⚠️ host Zba/Zbb/Zbs 未刺激 |
| csr.v / idu.v / div.v / pmp.v / trigger.v | 26-40% | 17-85% | ⚠️ host-scalar 路未刺激 |
| **TOTAL** | **48%** (361/749) | **73%** (114612/156548) | |

## 判讀(誠實界)
**這個 DUT + 向量刺激的職責 = 向量/FP datapath**,已達標:
- **vexu 98%/99%、fexu 93%/95%** —— V1 的指令覆蓋閉合(所有 op-form)直接把 RTL 結構打透。
  vexu 僅 1 行 / ~1138 toggle net 未覆蓋(defensive/reset 位,V5 尾端 triage)。

**低覆蓋模組 = 刺激缺口,非電路問題**,分兩類 backlog:
1. **NPU-offload 路(mat_engine/dma/npu_axil_regs)**:向量回歸不走 CQ/mat/DMA → 需
   **tflm/CQ harness**(gate_29/50/51/82、phase_21/23)的 coverage 併入。
2. **host-scalar 路(bmu/csr/idu/div/pmp/trigger/bp/ras)**:向量 NPU firmware 是 rv32im+
   向量,不觸 host Zba/Zbb/Zbs/trap/BP → 需 **host rv32imc 測試**(phase_03/04)的 coverage 併入。

## 下一步(V5 續 = 併入多刺激源)
1. **mat_engine/dma/CQ**:對 `tb_npu_tflm_model`(gate_50/82)+ phase_23(mat)+ phase_21(CQ)
   建 coverage DUT,跑其回歸,併入 merged。
2. **host-scalar**:對 phase_03/04 host 回歸建 coverage,併入 → bmu/csr/idu/div/bp/ras 拉高。
3. **合併總報告**:多 DUT coverage 不能裸合(不同 top);分模組取「該模組被其負責 harness
   覆蓋的最高值」→ per-module effective。
4. **尾端 triage + waiver**:vexu 殘 1 行 / reset toggle → 靜態不可達 waiver(ADR-ID)。
- gate_91 已凍結 **vexu≥95%/95%、fexu≥90%/90%**(此 DUT 職責),並斷言 backlog 模組在報告內
  (防未來全併報告悄悄漏)。**只准 ratchet up。**

## V5 續:併入 tflm/CQ + host 刺激(3-DUT 組合)
新增兩個 coverage DUT,把 offload / host-scalar 路拉起來。**多 DUT 組合方法(誠實界)**:
同源檔案在多 DUT 實例化,naive 併合會稀釋 toggle(非-owner DUT 的未刺激實例、參數不同→不同
net 簽名 → 灌大分母)。故:**line = 跨 DUT 併集(任一 DUT 執行到即算)= effective;toggle =
取各模組 owning DUT group 的最大 toggle%**。工具 `combine_cov.py`(vec/tflm/host 三組)。

| 模組 | line(union)| toggle(owner)| owner | 前(僅向量)|
|---|---|---|---|---|
| **vexu.v** | 98% | **99%** | vec | 98%/99% |
| **fexu.v** | 93% | 95% | vec | 93%/95% |
| **mat_engine.v** | **75%** | **94%** | tflm | ⬆ 17%/19% |
| **npu_dma.v** | **77%** | 58% | tflm | ⬆ 15%/4% |
| **npu_axil_regs.v** | **59%** | — | tflm | ⬆ 11%/6% |
| npu_tcm/npu_top | 80% / 78% | | tflm | ⬆ |
| alu / bp / lsu / mul | 100% | | vec/host | ⬆ |
| div.v | 80% | | host | ⬆ 40% |
| core.v | 72% | | vec | ⬆ 66% |
| **TOTAL line(union)** | **64%**(537/838)| | | ⬆ 48% |

**tflm 刺激(dwsep DW+PW + cnn conv+FC)把 mat_engine/dma/axil/tcm 從 ~15% 拉到 59-80%**;
host 刺激(RVC/CSR/random/trap)把 div/idu/bp 拉高。

## V5 backlog #2 閉合(完成)= bmu/idu 長尾補完
新增兩個 host 直接測試(clone rv32imc lockstep harness,DUT 驗證 vs Spike):
- **`phase_03_21_isacov_bmu`**(march=rv32imc_**zba_zbb_zbs**_zicsr):全套 Zba(sh1/2/3add)+
  Zbb(andn/orn/xnor/clz/ctz/cpop/min[u]/max[u]/sext.b/sext.h/zext.h/rol/ror/rori/orc.b/rev8)+
  Zbs(bclr[i]/bext[i]/binv[i]/bset[i])。lockstep 36c PASS。→ **bmu.v 6%→94%(31/33)/toggle 99%**。
- **`phase_03_22_isacov_csr`**:CSR R/W(misa/mtvec/mscratch/mstatus/mie + csrrs/csrrc)+
  trap round-trip(ecall→handler 讀 mcause/mepc/mtval→mret)。lockstep 26c PASS。**避非確定性
  CSR**(mcycle/minstret/time)+ 讀 mvendorid/marchid/mimpid 到 x0(exercised 不比對,impl-specific
  差異)。**misa 需 spike isa 對齊 host(含 Zb*)否則 bit-B 差**。

**側收穫:idu.v 49%→86%**(Zb*+CSR firmware 打進更多 decode 路)。cdec.v toggle→85%。

| 模組 | 前 | 後 |
|---|---|---|
| **bmu.v** | 6% | **94%** |
| **idu.v** | 49% | **86%** |
| **TOTAL line** | 64% | **72%**(601/838)|

## csr-corner 測試(補,不 waive)= csr 41%→45%
`phase_03_22_isacov_csr` firmware 加測**可達的 CSR arm**(不 waive,誠實測):mcause/mtval
寫、pmpcfg0/pmpaddr0/7 讀。lockstep 37c PASS。**兩個 DUT↔Spike 分歧(記錄,非 bug)**:
- **U-shadow counter `cycle`(0xC00)在 M-only**:DUT 允許讀(實 U 影子),**M-only Spike trap
  illegal**——spec 上 M-mode 恆可讀 0xC00,Spike 無 U-mode 較嚴。→ 不 lockstep-測(記錄)。
- **`mtval` bit31**:DUT 存全 32-bit,Spike 遮 bit31(皆合法 WARL 選擇,差異)。→ 寫 arm 覆蓋,
  readback 讀到 x0 不比對。

**csr 誠實剩餘拆解(不 waive,分類報告)**:
| csr 剩餘 ~76 行 | 性質 | 處置 |
|---|---|---|
| ~50 = **Debug-Module CSR 介面**(csr_debug_read + debug_csr_we block,由 `dm_acc_*` 驅動)| **只可達於 debug-mode DM abstract command;現無 debug lockstep harness** | **backlog #4:需 debug-mode DV**(非 waiver——DM 是真的,可達,只是無刺激)|
| ~10 = **PMP-write body `if(PMP_ENTRIES!=0)`** | **PMP_ENTRIES=0 靜態不可達(dead)** | **合法 unreachable(config-scoped waiver 候選,同 pmp.v)** |
| ~5 = U-shadow counters / WARL 分歧 | DUT↔Spike 分歧 | 記錄 |

## V5 backlog #4 閉合(debug-mode DV)= csr 45%→53%、trigger 37%→70%
**既有 debug DV harness 直接復用**(非從頭建):`phase_06_00_debug_mvd`(core debug-mode +
`soc/dm.v` Debug Module,DMI-direct 驅動 halt + abstract CSR access)、`phase_06_02_debug_trigger`
(trigger cross/aligned/store)。自建 coverage DUT(避改 M1 gated Makefile,加 -Wno-PINMISSING/
-Wno-WIDTHEXPAND 消 M3V core RVFI-port 漣漪),跑 → 收 coverage → combine。
- **csr.v 45%→53%**(debug-CSR 介面 csr_debug_read/debug_csr_we 被 DM abstract 命令打進)
- **trigger.v 37%→70%**(trigger match/fire 邏輯)
- **dm.v 57%**(新入報告 = Debug Module 本身)
- **TOTAL line 72%→77%**(708/924)
- **證明**:debug-CSR 介面**可達可覆蓋**(非死路)→ 先前「needs debug DV」的 backlog 已閉。
  csr 剩殘 = ①debug DV 只 abstract-access 少數 CSR,其餘 csr_debug arm 需擴 DV 刺激(增量可補)
  ②PMP-write body(PMP_ENTRIES=0 dead)③U-shadow/WARL 分歧。

## 剩餘(backlog #3 + 合法 unreachable)
| 模組 | line | 性質 |
|---|---|---|
| csr.v | 45% | Debug-DM 介面(backlog #4 需 debug DV)+ PMP-body(unreachable)+ 分歧 |
| pmp.v / trigger.v | 20% / 37% | **PMP_ENTRIES=0 靜態不可達 + no-DM**(ADR-0024/0022 + core.v:973 RTL 註解 + review)→ **合法 unreachable waiver 候選(需獨立 review + config-scoped)** |
| npu_axil_regs.v | 59% | **error-ladder 路**(gate_29/38/47/54)→ **backlog #3**(併入 error 閘)|
| cdec.v / ras.v | 44% / 50% | compressed-decode corner / RAS 遞迴——低值 |

## 對 V1 的呼應
V1(指令覆蓋)與 V5(code 覆蓋)互證:**op-level 指令 100% → vexu code 98%/99%**。指令覆蓋
拉高直接反映在 RTL 結構覆蓋,兩者一致,無假綠。gate_91 凍結 vexu/fexu/mat_engine/npu_dma/
alu/lsu/div/core 的 owning 覆蓋門檻 + 斷言 backlog 模組在報告內,只准 ratchet up。可重跑
`flow/coverage/verilator/run_cov.sh`(建 3 DUT + 跑 + combine)。
