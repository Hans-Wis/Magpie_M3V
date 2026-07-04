# ADR-0048 — 列 8 完成:trace v1(insn + mem trace + mtval/mstatus)

- Status: **ACCEPTED**(功能補齊路線圖順位 2;ADR-0045 的 v1 完成清單兌現)。
  Mode:PL design + Codex post-review。
- Date: 2026-07-04
- Relates: ADR-0045(v0 lite + 完成清單)、ADR-0032(core 必改必驗)。

## 契約(§2)

在 v0 bundle 之上新增(core.v 僅 +5 個 WB pipe regs,其餘 wire-out):
- `rvfi_insn`:**WB 級指令位元**(`ex_wb_instr_r` 已存在——零新管線邏輯);v0 的離線
  ITCM join 從此僅為 fallback。
- `rvfi_trap_mtval`(隨 `rvfi_trap` 有效)+ `rvfi_mstatus`(architectural read view,
  csr.v 新輸出)。
- **mem trace**:`rvfi_mem_re/we/addr/wdata/wstrb`(MEM→WB pipe;load 結果本就在
  `rvfi_rd_wdata`)。與 retire 對齊(`re/we` 以 `rvfi_valid` 資格)。
- 單退休(single-issue 核的構造性質,非缺口)。

## 驗證 + 結果

1. **lockstep 加逐 commit 斷言**:`rvfi_insn === ITCM join` 於**每一筆** commit(directed
   1164 + random 10,809 全符)——insn 欄位以全語料自證,Spike 匹配同時重確認。
2. **gate_53 v1 檢查**:trap@0x14 時 `rvfi_insn == 0xFFFFFFFF`(非法字本體)、
   `rvfi_trap_cause == 2`、`rvfi_trap_mtval == 指令位元`;**mem trace 逐筆看到 handler
   的兩筆 MMIO store**,最後一筆 addr==ERR_CAUSE mirror(0x0002_0058)、
   data==0x80000002——與 ADR-0038 trap 契約互證。
3. core.v 介面/管線改動 → host flows tie-off 更新,全套 0 新增失敗。

**列 8 → GREEN-leaning**:insn-complete、mem trace、trap CSR 視圖、lockstep 權威——
ADR-0045 v1 清單全兌現;殘餘(RVVI 多退休格式化、外部 debugger 介面封裝)屬工具鏈
整合,非 RTL 缺口。

## Codex review 處置(2 發現)

1. **AMO(RV32A)mem-trace 漏拍**:`amo_mem_hold` 期間 beat 不落在 transfer 取樣點。
   **範圍界定**:本線兩個 profile(host RV32IM_Zbb、NPU rv32im sequencer)皆無 A;
   trace v1 明文限 IM profile,A-profile beat trace 隨未來 A 工作補(埠註解同步)。
2. **rvfi_mstatus 非 post-commit**:trap 沿上讀到的是 trap 前值(csr 同拍更新)。
   **語義改判**:明文定義為 **pre-commit view**(RVFI 規格本就區分 pre/post 視圖);
   post-trap 值於下一事件可見。埠註解與本 ADR 同步修正。
