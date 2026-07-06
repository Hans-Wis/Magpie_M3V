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

## 對 V1 的呼應
V1(指令覆蓋)與 V5(code 覆蓋)互證:**op-level 指令 100% → vexu code 98%/99%**。指令覆蓋
拉高直接反映在 RTL 結構覆蓋,兩者一致,無假綠。
