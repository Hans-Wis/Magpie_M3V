# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 438 | 624 | 70.2% |
| cpu_m1_top.v | 16 | 26 | 61.5% |
| csr.v | 56 | 267 | 21.0% |
| div.v | 46 | 51 | 90.2% |
| idu.v | 61 | 130 | 46.9% |
| ifu.v | 6 | 6 | 100.0% |
| mat_engine.v | 8 | 74 | 10.8% |
| npu_axil_regs.v | 48 | 160 | 30.0% |
| npu_dma.v | 6 | 75 | 8.0% |
| npu_tcm.v | 24 | 48 | 50.0% |
| npu_top.v | 28 | 40 | 70.0% |
| pmp.v | 5 | 40 | 12.5% |
| rfu.v | 10 | 12 | 83.3% |
| tb_npu_lockstep.v | 60 | 64 | 93.8% |
| trigger.v | 28 | 104 | 26.9% |
| vexu.v | 42 | 71 | 59.2% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:623: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:753: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:756: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:788: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:791: `(ex_wb_valid_r && ex_wb_csr_we_r && (ex_wb_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:1020: `function [31:0] amo_compute;`
  - core.v:1024: `begin`
  - core.v:1025: `case (op)`
  - core.v:1026: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:1027: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:1028: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:1029: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:1030: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1031: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1032: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1033: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1034: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1117: `assign d_mem_wstrb = ((EN_RVV != 0) && vexu_vm_active) ?`
  - core.v:1133: `function is_vector_csr_addr;`
  - core.v:1135: `begin`
  - core.v:1136: `is_vector_csr_addr = (addr == `CSR_VSTART) ||`
  - core.v:1141: `(addr == `CSR_VTYPE)  ||`
  - core.v:1146: `function is_vector_ro_csr_addr;`
  - core.v:1148: `begin`
  - core.v:1149: `is_vector_ro_csr_addr = (addr == `CSR_VL) ||`
  - core.v:1150: `(addr == `CSR_VTYPE) ||`
  - core.v:1389: `case (id_csr_addr)`
  - core.v:1390: ``CSR_VSTART: id_csr_rdata = 32'h0;`
  - core.v:1391: ``CSR_VL    : id_csr_rdata = ex_mem_vcfg_vl_r;`
  - core.v:1392: ``CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;`
  - core.v:1393: `default    : ;`
  - core.v:1402: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1403: `case (id_csr_addr)`
  - core.v:1404: ``CSR_VCSR: begin`
  - core.v:1405: `if (ex_mem_csr_addr_r == `CSR_VXSAT)`
  - core.v:1406: `id_csr_rdata = {csr_rdata[31:1], ex_mem_csr_next_val[0]};`
  - core.v:1407: `if (ex_mem_csr_addr_r == `CSR_VXRM)`
  - core.v:1408: `id_csr_rdata = {csr_rdata[31:3], ex_mem_csr_next_val[1:0], csr_rdata[0]};`
  - core.v:1410: ``CSR_VXSAT: if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1411: `id_csr_rdata = {31'b0, ex_mem_csr_next_val[0]};`
  - core.v:1412: ``CSR_VXRM : if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1413: `id_csr_rdata = {30'b0, ex_mem_csr_next_val[2:1]};`
  - core.v:1414: ``CSR_MSTATUS:`
  - core.v:1415: `if ((ex_mem_csr_addr_r == `CSR_VSTART) || (ex_mem_csr_addr_r == `CSR_VXSAT) ||`
  - core.v:1417: `id_csr_rdata = csr_rdata | 32'h8000_0000 |`
  - core.v:1419: `default: ;`
  - core.v:1423: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1426: `if (id_csr_addr == `CSR_VSTART) id_csr_rdata = 32'h0;`
  - core.v:1427: `if (id_csr_addr == `CSR_MSTATUS)`
  - core.v:1428: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1514: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1515: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1516: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1517: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1518: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1519: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1520: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1521: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1522: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1523: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1524: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1525: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1526: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1527: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1528: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1529: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1530: `ex_mem_vcfg_we_r         <= 1'b0;`
  - core.v:1531: `ex_mem_vex_we_r          <= 1'b0;`
  - core.v:1532: `ex_mem_vex_flag_r        <= 1'b0;`
  - core.v:1533: `ex_mem_vex_mem_r         <= 1'b0;`
  - core.v:1534: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1535: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1536: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1537: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1538: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1539: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1540: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1541: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1542: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1543: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1544: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1545: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1546: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1547: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1696: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1697: `amo_state <= AMO_DONE;`
  - core.v:1698: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1699: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1700: `if (ex_mem_sc_fail) begin`
  - core.v:1701: `amo_state     <= AMO_DONE;`
  - core.v:1702: `amo_result_r  <= 32'h1;`
  - core.v:1703: `amo_res_valid <= 1'b0;`
  - core.v:1704: `end else begin`
  - core.v:1705: `case (amo_state)`
  - core.v:1706: `AMO_IDLE: begin`
  - core.v:1707: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1708: `amo_state     <= AMO_DONE;`
  - core.v:1709: `amo_result_r  <= 32'h0;`
  - core.v:1710: `amo_res_valid <= 1'b0;`
  - core.v:1711: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1712: `amo_state <= AMO_LOAD;`
  - core.v:1715: `AMO_LOAD: begin`
  - core.v:1716: `amo_result_r <= d_mem_rdata;`
  - core.v:1717: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1718: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1719: `amo_state     <= AMO_DONE;`
  - core.v:1720: `amo_res_valid <= 1'b1;`
  - core.v:1721: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1722: `end else begin`
  - core.v:1723: `amo_state <= AMO_STORE;`
  - core.v:1726: `AMO_STORE: begin`
  - core.v:1727: `amo_state     <= AMO_DONE;`
  - core.v:1728: `amo_res_valid <= 1'b0;`
  - core.v:1730: `default: begin`
  - core.v:1731: `if (ex_mem_advance_to_wb) begin`
  - core.v:1732: `amo_state <= AMO_IDLE;`
  - core.v:1742: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1743: `amo_res_valid <= 1'b0;`
  - core.v:1799: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1800: `ex_wb_valid_r           <= 1'b0;`
  - core.v:1801: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:1802: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:1803: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:1804: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:1805: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:1806: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:1807: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:1808: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:1809: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:1810: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:1811: `ex_wb_vcfg_we_r         <= 1'b0;`
  - core.v:1812: `ex_wb_vex_we_r          <= 1'b0;`
  - core.v:1813: `ex_wb_vex_flag_r        <= 1'b0;`
  - core.v:1814: `ex_wb_vex_mem_r         <= 1'b0;`
  - core.v:1815: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:1816: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:1817: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:1818: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:1819: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:1820: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:1821: `ex_wb_instr_r           <= 32'h0;`
  - core.v:1822: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:1823: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:1824: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:1825: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:1826: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:1827: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:1828: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1829: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:1830: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:1963: `wb_data_mux = amo_result_r;`
  - core.v:1969: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:1985: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:1986: `wb_take_data_trap ?`
  - core.v:1988: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:1989: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:1990: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:1991: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:1997: `ex_wb_instr_r) :`
  - core.v:2022: `end else if (debug_resume_redirect) begin`
  - core.v:2023: `pc_redirect     = 1'b1;`
  - core.v:2024: `redirect_target = dpc_o;`
  - core.v:2028: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:2029: `pc_redirect     = 1'b1;`
  - core.v:2030: `redirect_target = mepc_o;`
  - core.v:2031: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:2032: `pc_redirect     = 1'b1;`
  - core.v:2033: `redirect_target = dpc_o;`
  - core.v:2034: `end else if (debug_halt_enter) begin`
  - core.v:2035: `pc_redirect     = 1'b1;`
  - core.v:2036: `redirect_target = debug_halt_pc_w;`
  - core.v:2037: `end else if (mem_ras_mispredict) begin`
  - core.v:2039: `pc_redirect     = 1'b1;`
  - core.v:2040: `redirect_target = mem_ras_actual_target;`
  - core.v:2052: `ex_mem_pc_plus_4_r;`
  - core.v:2076: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:2078: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:2079: `DBG_ENTRY_TRIG_ST) :`
  - core.v:2096: `debug_halt_pending <= 1'b1;`
  - core.v:2098: `debug_halt_pending <= 1'b0;`
  - core.v:2100: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:2101: `debug_mode <= 1'b0;`
  - core.v:2102: `debug_step_pending <= dcsr_step;`
  - core.v:2104: `debug_mode <= 1'b1;`
  - core.v:2105: `debug_step_pending <= 1'b0;`
  - core.v:2114: `32'h0;`

Status: pass

