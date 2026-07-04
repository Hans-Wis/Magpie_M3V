# ADR-0045 — 列 8:RVFI/RVVI-lite trace port(v0)

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04「列 8 RVVI trace port」)。
  Mode:PL design + Grok pre-critique(裁定採納:**列 8 標 PARTIAL,不因 lite v0 轉綠**)+
  Codex post-review(2 發現,已修)。
- Date: 2026-07-04
- Relates: ADR-0032(core 必改必驗)、ADR-0038(trap 契約)、ADR-0044(ITCM join 前提)。

## Coral 對照(§2 第 1 問)

Kelvin 暴露 RVVI(debugger-facing、insn-complete)。v4 §08 SSOT:NPU scalar/RVV 驗證軌 =
**RVVI/RVFI lockstep**。本 ADR 落地 v0 = **commit-order 的 scalar + post-commit vector 狀態,
以 Spike lockstep 為權威**;完整 RVVI(insn/mem/CSR/hart state)列 P1+ 完成清單。
**依 Grok 裁定:列 8 升 🟡 PARTIAL(非綠)**,綠燈門檻 = v1 bundle(見下)。

## 契約(§2 第 2 問)

**Port(npu_top 邊界,core.v 純 wire-out、零新管線邏輯)**:
- scalar:`rvfi_valid`(= `wb_instr_retired`,真退休)、`rvfi_pc`、`rvfi_trap`(sync/data
  trap **於 WB 接受時單拍脈衝**——與 `wb_trap_enter` 同資格 `!core_mem_stall`;Codex #2)、
  `rvfi_trap_cause`(mcause 碼)、`rvfi_intr`、`rvfi_rd_addr/rd_wdata`(x0 遮罩)、
  `rvfi_order`(npu_top 計數 retire+trap 事件,`!npu_start` 歸零)。
- vector(RVVI-lite):`rvvi_v_valid/v_vd/v_wdata[128]`(vexu WB commit)+ post-commit
  `vl/vtype`。**有效範圍 = 實作子集(LMUL≤1、tail-undisturbed、vstart≠0 算術 illegal)**
  ——此子集內 WB 寫 = architectural retire(Grok (d) 條件滿足)。
- **v0 非目標(v1 完成清單)**:`rvfi_insn`(v0 以 pc→insn 對靜態 ITCM 離線 join;健全性
  由 ADR-0044 禁自修改碼契約保證;不加 ITCM trace 讀埠——會破壞剛建立的埠預算誠實)、
  mem trace、`mtval`/`mstatus` diff、多退休。External debugger 需 v1。

## 驗證(§2 第 3 問)+ 結果

**權威 = lockstep 換源**:phase_20 TB 的採樣路徑改為**只讀 port**(gate_53 grep 守衛:TB 內
零 `u_core.` 層級窺視),clean rebuild 重跑 **directed 1164 + random 10,809 commits 全符**
——trace 流本身承載 lockstep 證明。gate_53 另證:trap@0x14 單脈衝 + 前 5 retires +
`order == retires+traps` + scalar 韌體下 rvvi 靜默。

**Codex 處置**:#1 TB 終止條件曾放寬到任意 trap(comparator 只比對到 DUT 長度 → data trap
截斷可假綠)→ 終止改為 cause∈{illegal, ebreak}(語料終結子),data trap 續跑、分歧由
comparator 誠實抓;#2 `rvfi_trap` 未帶 WB-accept 資格(stall 時多拍脈衝)→ 加
`!core_mem_stall` + 匯出 `rvfi_trap_cause`(同時滿足 Grok (c) 的 mcause 需求)。
核心介面改動 → host flows(phase_02/03)tie-off 後全綠,全套 0 新增失敗。
