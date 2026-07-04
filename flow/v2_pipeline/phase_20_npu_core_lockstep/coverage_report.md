# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 436 | 622 | 70.1% |
| cpu_m1_top.v | 16 | 26 | 61.5% |
| csr.v | 56 | 267 | 21.0% |
| div.v | 46 | 51 | 90.2% |
| idu.v | 61 | 130 | 46.9% |
| ifu.v | 6 | 6 | 100.0% |
| mat_engine.v | 7 | 63 | 11.1% |
| npu_axil_regs.v | 42 | 139 | 30.2% |
| npu_dma.v | 6 | 64 | 9.4% |
| npu_tcm.v | 11 | 20 | 55.0% |
| npu_top.v | 19 | 25 | 76.0% |
| pmp.v | 5 | 40 | 12.5% |
| rfu.v | 10 | 12 | 83.3% |
| tb_npu_lockstep.v | 57 | 61 | 93.4% |
| trigger.v | 28 | 104 | 26.9% |
| vexu.v | 42 | 71 | 59.2% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:607: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:737: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:740: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:772: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:775: `(ex_wb_valid_r && ex_wb_csr_we_r && (ex_wb_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:1004: `function [31:0] amo_compute;`
  - core.v:1008: `begin`
  - core.v:1009: `case (op)`
  - core.v:1010: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:1011: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:1012: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:1013: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:1014: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1015: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1016: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1017: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1018: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1101: `assign d_mem_wstrb = ((EN_RVV != 0) && vexu_vm_active) ?`
  - core.v:1117: `function is_vector_csr_addr;`
  - core.v:1119: `begin`
  - core.v:1120: `is_vector_csr_addr = (addr == `CSR_VSTART) ||`
  - core.v:1125: `(addr == `CSR_VTYPE)  ||`
  - core.v:1130: `function is_vector_ro_csr_addr;`
  - core.v:1132: `begin`
  - core.v:1133: `is_vector_ro_csr_addr = (addr == `CSR_VL) ||`
  - core.v:1134: `(addr == `CSR_VTYPE) ||`
  - core.v:1373: `case (id_csr_addr)`
  - core.v:1374: ``CSR_VSTART: id_csr_rdata = 32'h0;`
  - core.v:1375: ``CSR_VL    : id_csr_rdata = ex_mem_vcfg_vl_r;`
  - core.v:1376: ``CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;`
  - core.v:1377: `default    : ;`
  - core.v:1386: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1387: `case (id_csr_addr)`
  - core.v:1388: ``CSR_VCSR: begin`
  - core.v:1389: `if (ex_mem_csr_addr_r == `CSR_VXSAT)`
  - core.v:1390: `id_csr_rdata = {csr_rdata[31:1], ex_mem_csr_next_val[0]};`
  - core.v:1391: `if (ex_mem_csr_addr_r == `CSR_VXRM)`
  - core.v:1392: `id_csr_rdata = {csr_rdata[31:3], ex_mem_csr_next_val[1:0], csr_rdata[0]};`
  - core.v:1394: ``CSR_VXSAT: if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1395: `id_csr_rdata = {31'b0, ex_mem_csr_next_val[0]};`
  - core.v:1396: ``CSR_VXRM : if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1397: `id_csr_rdata = {30'b0, ex_mem_csr_next_val[2:1]};`
  - core.v:1398: ``CSR_MSTATUS:`
  - core.v:1399: `if ((ex_mem_csr_addr_r == `CSR_VSTART) || (ex_mem_csr_addr_r == `CSR_VXSAT) ||`
  - core.v:1401: `id_csr_rdata = csr_rdata | 32'h8000_0000 |`
  - core.v:1403: `default: ;`
  - core.v:1407: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1410: `if (id_csr_addr == `CSR_VSTART) id_csr_rdata = 32'h0;`
  - core.v:1411: `if (id_csr_addr == `CSR_MSTATUS)`
  - core.v:1412: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1498: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1499: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1500: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1501: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1502: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1503: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1504: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1505: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1506: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1507: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1508: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1509: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1510: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1511: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1512: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1513: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1514: `ex_mem_vcfg_we_r         <= 1'b0;`
  - core.v:1515: `ex_mem_vex_we_r          <= 1'b0;`
  - core.v:1516: `ex_mem_vex_flag_r        <= 1'b0;`
  - core.v:1517: `ex_mem_vex_mem_r         <= 1'b0;`
  - core.v:1518: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1519: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1520: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1521: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1522: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1523: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1524: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1525: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1526: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1527: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1528: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1529: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1530: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1531: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1680: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1681: `amo_state <= AMO_DONE;`
  - core.v:1682: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1683: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1684: `if (ex_mem_sc_fail) begin`
  - core.v:1685: `amo_state     <= AMO_DONE;`
  - core.v:1686: `amo_result_r  <= 32'h1;`
  - core.v:1687: `amo_res_valid <= 1'b0;`
  - core.v:1688: `end else begin`
  - core.v:1689: `case (amo_state)`
  - core.v:1690: `AMO_IDLE: begin`
  - core.v:1691: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1692: `amo_state     <= AMO_DONE;`
  - core.v:1693: `amo_result_r  <= 32'h0;`
  - core.v:1694: `amo_res_valid <= 1'b0;`
  - core.v:1695: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1696: `amo_state <= AMO_LOAD;`
  - core.v:1699: `AMO_LOAD: begin`
  - core.v:1700: `amo_result_r <= d_mem_rdata;`
  - core.v:1701: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1702: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1703: `amo_state     <= AMO_DONE;`
  - core.v:1704: `amo_res_valid <= 1'b1;`
  - core.v:1705: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1706: `end else begin`
  - core.v:1707: `amo_state <= AMO_STORE;`
  - core.v:1710: `AMO_STORE: begin`
  - core.v:1711: `amo_state     <= AMO_DONE;`
  - core.v:1712: `amo_res_valid <= 1'b0;`
  - core.v:1714: `default: begin`
  - core.v:1715: `if (ex_mem_advance_to_wb) begin`
  - core.v:1716: `amo_state <= AMO_IDLE;`
  - core.v:1726: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1727: `amo_res_valid <= 1'b0;`
  - core.v:1783: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1784: `ex_wb_valid_r           <= 1'b0;`
  - core.v:1785: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:1786: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:1787: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:1788: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:1789: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:1790: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:1791: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:1792: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:1793: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:1794: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:1795: `ex_wb_vcfg_we_r         <= 1'b0;`
  - core.v:1796: `ex_wb_vex_we_r          <= 1'b0;`
  - core.v:1797: `ex_wb_vex_flag_r        <= 1'b0;`
  - core.v:1798: `ex_wb_vex_mem_r         <= 1'b0;`
  - core.v:1799: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:1800: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:1801: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:1802: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:1803: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:1804: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:1805: `ex_wb_instr_r           <= 32'h0;`
  - core.v:1806: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:1807: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:1808: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:1809: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:1810: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:1811: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:1812: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1813: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:1814: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:1947: `wb_data_mux = amo_result_r;`
  - core.v:1953: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:1969: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:1970: `wb_take_data_trap ?`
  - core.v:1972: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:1973: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:1974: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:1975: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:1981: `ex_wb_instr_r) :`
  - core.v:2006: `end else if (debug_resume_redirect) begin`
  - core.v:2007: `pc_redirect     = 1'b1;`
  - core.v:2008: `redirect_target = dpc_o;`
  - core.v:2012: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:2013: `pc_redirect     = 1'b1;`
  - core.v:2014: `redirect_target = mepc_o;`
  - core.v:2015: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:2016: `pc_redirect     = 1'b1;`
  - core.v:2017: `redirect_target = dpc_o;`
  - core.v:2018: `end else if (debug_halt_enter) begin`
  - core.v:2019: `pc_redirect     = 1'b1;`
  - core.v:2020: `redirect_target = debug_halt_pc_w;`
  - core.v:2021: `end else if (mem_ras_mispredict) begin`
  - core.v:2023: `pc_redirect     = 1'b1;`
  - core.v:2024: `redirect_target = mem_ras_actual_target;`
  - core.v:2036: `ex_mem_pc_plus_4_r;`
  - core.v:2060: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:2062: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:2063: `DBG_ENTRY_TRIG_ST) :`
  - core.v:2080: `debug_halt_pending <= 1'b1;`
  - core.v:2082: `debug_halt_pending <= 1'b0;`
  - core.v:2084: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:2085: `debug_mode <= 1'b0;`
  - core.v:2086: `debug_step_pending <= dcsr_step;`
  - core.v:2088: `debug_mode <= 1'b1;`
  - core.v:2089: `debug_step_pending <= 1'b0;`
  - core.v:2098: `32'h0;`

Status: pass

