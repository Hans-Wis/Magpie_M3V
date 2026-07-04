# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 453 | 649 | 69.8% |
| cpu_m1_top.v | 16 | 26 | 61.5% |
| csr.v | 56 | 267 | 21.0% |
| div.v | 46 | 51 | 90.2% |
| idu.v | 61 | 130 | 46.9% |
| ifu.v | 6 | 6 | 100.0% |
| mat_engine.v | 8 | 74 | 10.8% |
| npu_axil_regs.v | 48 | 162 | 29.6% |
| npu_dma.v | 6 | 75 | 8.0% |
| npu_tcm.v | 24 | 48 | 50.0% |
| npu_top.v | 28 | 40 | 70.0% |
| pmp.v | 5 | 40 | 12.5% |
| rfu.v | 10 | 12 | 83.3% |
| tb_npu_lockstep.v | 60 | 67 | 89.6% |
| trigger.v | 28 | 104 | 26.9% |
| vexu.v | 114 | 167 | 68.3% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:639: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:769: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:772: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:804: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:807: `(ex_wb_valid_r && ex_wb_csr_we_r && (ex_wb_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:816: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VXRM)) ?`
  - core.v:818: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VCSR)) ?`
  - core.v:820: `(ex_wb_valid_r  && ex_wb_csr_we_r  && (ex_wb_csr_addr_r == `CSR_VXRM))  ?`
  - core.v:822: `(ex_wb_valid_r  && ex_wb_csr_we_r  && (ex_wb_csr_addr_r == `CSR_VCSR))  ?`
  - core.v:1054: `function [31:0] amo_compute;`
  - core.v:1058: `begin`
  - core.v:1059: `case (op)`
  - core.v:1060: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:1061: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:1062: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:1063: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:1064: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1065: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1066: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1067: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1068: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1151: `assign d_mem_wstrb = ((EN_RVV != 0) && vexu_vm_active) ?`
  - core.v:1167: `function is_vector_csr_addr;`
  - core.v:1169: `begin`
  - core.v:1170: `is_vector_csr_addr = (addr == `CSR_VSTART) ||`
  - core.v:1175: `(addr == `CSR_VTYPE)  ||`
  - core.v:1180: `function is_vector_ro_csr_addr;`
  - core.v:1182: `begin`
  - core.v:1183: `is_vector_ro_csr_addr = (addr == `CSR_VL) ||`
  - core.v:1184: `(addr == `CSR_VTYPE) ||`
  - core.v:1430: `case (id_csr_addr)`
  - core.v:1431: ``CSR_VSTART: id_csr_rdata = 32'h0;`
  - core.v:1432: ``CSR_VL    : id_csr_rdata = ex_mem_vcfg_vl_r;`
  - core.v:1433: ``CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;`
  - core.v:1434: `default    : ;`
  - core.v:1446: `id_csr_rdata = id_csr_rdata | 32'h1;`
  - core.v:1453: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1454: `case (id_csr_addr)`
  - core.v:1455: ``CSR_VCSR: begin`
  - core.v:1456: `if (ex_mem_csr_addr_r == `CSR_VXSAT)`
  - core.v:1457: `id_csr_rdata = {csr_rdata[31:1], ex_mem_csr_next_val[0]};`
  - core.v:1458: `if (ex_mem_csr_addr_r == `CSR_VXRM)`
  - core.v:1459: `id_csr_rdata = {csr_rdata[31:3], ex_mem_csr_next_val[1:0], csr_rdata[0]};`
  - core.v:1461: ``CSR_VXSAT: if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1462: `id_csr_rdata = {31'b0, ex_mem_csr_next_val[0]};`
  - core.v:1463: ``CSR_VXRM : if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1464: `id_csr_rdata = {30'b0, ex_mem_csr_next_val[2:1]};`
  - core.v:1465: ``CSR_MSTATUS:`
  - core.v:1466: `if ((ex_mem_csr_addr_r == `CSR_VSTART) || (ex_mem_csr_addr_r == `CSR_VXSAT) ||`
  - core.v:1468: `id_csr_rdata = csr_rdata | 32'h8000_0000 |`
  - core.v:1470: `default: ;`
  - core.v:1474: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1479: `id_csr_rdata = id_csr_rdata | 32'h1;`
  - core.v:1482: `if (id_csr_addr == `CSR_VSTART) id_csr_rdata = 32'h0;`
  - core.v:1483: `if (id_csr_addr == `CSR_MSTATUS)`
  - core.v:1484: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1571: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1572: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1573: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1574: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1575: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1576: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1577: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1578: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1579: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1580: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1581: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1582: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1583: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1584: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1585: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1586: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1587: `ex_mem_vcfg_we_r         <= 1'b0;`
  - core.v:1588: `ex_mem_vex_we_r          <= 1'b0;`
  - core.v:1589: `ex_mem_vex_sat_r         <= 1'b0;`
  - core.v:1590: `ex_mem_vex_flag_r        <= 1'b0;`
  - core.v:1591: `ex_mem_vex_mem_r         <= 1'b0;`
  - core.v:1592: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1593: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1594: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1595: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1596: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1597: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1598: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1599: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1600: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1601: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1602: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1603: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1604: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1605: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1756: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1757: `amo_state <= AMO_DONE;`
  - core.v:1758: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1759: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1760: `if (ex_mem_sc_fail) begin`
  - core.v:1761: `amo_state     <= AMO_DONE;`
  - core.v:1762: `amo_result_r  <= 32'h1;`
  - core.v:1763: `amo_res_valid <= 1'b0;`
  - core.v:1764: `end else begin`
  - core.v:1765: `case (amo_state)`
  - core.v:1766: `AMO_IDLE: begin`
  - core.v:1767: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1768: `amo_state     <= AMO_DONE;`
  - core.v:1769: `amo_result_r  <= 32'h0;`
  - core.v:1770: `amo_res_valid <= 1'b0;`
  - core.v:1771: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1772: `amo_state <= AMO_LOAD;`
  - core.v:1775: `AMO_LOAD: begin`
  - core.v:1776: `amo_result_r <= d_mem_rdata;`
  - core.v:1777: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1778: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1779: `amo_state     <= AMO_DONE;`
  - core.v:1780: `amo_res_valid <= 1'b1;`
  - core.v:1781: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1782: `end else begin`
  - core.v:1783: `amo_state <= AMO_STORE;`
  - core.v:1786: `AMO_STORE: begin`
  - core.v:1787: `amo_state     <= AMO_DONE;`
  - core.v:1788: `amo_res_valid <= 1'b0;`
  - core.v:1790: `default: begin`
  - core.v:1791: `if (ex_mem_advance_to_wb) begin`
  - core.v:1792: `amo_state <= AMO_IDLE;`
  - core.v:1802: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1803: `amo_res_valid <= 1'b0;`
  - core.v:1862: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1863: `ex_wb_valid_r           <= 1'b0;`
  - core.v:1864: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:1865: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:1866: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:1867: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:1868: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:1869: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:1870: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:1871: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:1872: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:1873: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:1874: `ex_wb_vcfg_we_r         <= 1'b0;`
  - core.v:1875: `ex_wb_vex_we_r          <= 1'b0;`
  - core.v:1876: `ex_wb_vex_sat_r         <= 1'b0;`
  - core.v:1877: `ex_wb_vex_flag_r        <= 1'b0;`
  - core.v:1878: `ex_wb_vex_mem_r         <= 1'b0;`
  - core.v:1879: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:1880: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:1881: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:1882: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:1883: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:1884: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:1885: `ex_wb_instr_r           <= 32'h0;`
  - core.v:1886: `ex_wb_mem_re_r          <= 1'b0;`
  - core.v:1887: `ex_wb_mem_we_r          <= 1'b0;`
  - core.v:1888: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:1889: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:1890: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:1891: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:1892: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:1893: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:1894: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1895: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:1896: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:2039: `wb_data_mux = amo_result_r;`
  - core.v:2045: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:2061: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:2062: `wb_take_data_trap ?`
  - core.v:2064: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:2065: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:2066: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:2067: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:2073: `ex_wb_instr_r) :`
  - core.v:2098: `end else if (debug_resume_redirect) begin`
  - core.v:2099: `pc_redirect     = 1'b1;`
  - core.v:2100: `redirect_target = dpc_o;`
  - core.v:2104: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:2105: `pc_redirect     = 1'b1;`
  - core.v:2106: `redirect_target = mepc_o;`
  - core.v:2107: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:2108: `pc_redirect     = 1'b1;`
  - core.v:2109: `redirect_target = dpc_o;`
  - core.v:2110: `end else if (debug_halt_enter) begin`
  - core.v:2111: `pc_redirect     = 1'b1;`
  - core.v:2112: `redirect_target = debug_halt_pc_w;`
  - core.v:2113: `end else if (mem_ras_mispredict) begin`
  - core.v:2115: `pc_redirect     = 1'b1;`
  - core.v:2116: `redirect_target = mem_ras_actual_target;`
  - core.v:2128: `ex_mem_pc_plus_4_r;`
  - core.v:2152: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:2154: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:2155: `DBG_ENTRY_TRIG_ST) :`
  - core.v:2172: `debug_halt_pending <= 1'b1;`
  - core.v:2174: `debug_halt_pending <= 1'b0;`
  - core.v:2176: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:2177: `debug_mode <= 1'b0;`
  - core.v:2178: `debug_step_pending <= dcsr_step;`
  - core.v:2180: `debug_mode <= 1'b1;`
  - core.v:2181: `debug_step_pending <= 1'b0;`
  - core.v:2190: `32'h0;`

Status: pass

