# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 447 | 635 | 70.4% |
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
| vexu.v | 92 | 121 | 76.0% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:638: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:768: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:771: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:803: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:806: `(ex_wb_valid_r && ex_wb_csr_we_r && (ex_wb_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:1035: `function [31:0] amo_compute;`
  - core.v:1039: `begin`
  - core.v:1040: `case (op)`
  - core.v:1041: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:1042: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:1043: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:1044: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:1045: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1046: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1047: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1048: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1049: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1132: `assign d_mem_wstrb = ((EN_RVV != 0) && vexu_vm_active) ?`
  - core.v:1148: `function is_vector_csr_addr;`
  - core.v:1150: `begin`
  - core.v:1151: `is_vector_csr_addr = (addr == `CSR_VSTART) ||`
  - core.v:1156: `(addr == `CSR_VTYPE)  ||`
  - core.v:1161: `function is_vector_ro_csr_addr;`
  - core.v:1163: `begin`
  - core.v:1164: `is_vector_ro_csr_addr = (addr == `CSR_VL) ||`
  - core.v:1165: `(addr == `CSR_VTYPE) ||`
  - core.v:1409: `case (id_csr_addr)`
  - core.v:1410: ``CSR_VSTART: id_csr_rdata = 32'h0;`
  - core.v:1411: ``CSR_VL    : id_csr_rdata = ex_mem_vcfg_vl_r;`
  - core.v:1412: ``CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;`
  - core.v:1413: `default    : ;`
  - core.v:1422: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1423: `case (id_csr_addr)`
  - core.v:1424: ``CSR_VCSR: begin`
  - core.v:1425: `if (ex_mem_csr_addr_r == `CSR_VXSAT)`
  - core.v:1426: `id_csr_rdata = {csr_rdata[31:1], ex_mem_csr_next_val[0]};`
  - core.v:1427: `if (ex_mem_csr_addr_r == `CSR_VXRM)`
  - core.v:1428: `id_csr_rdata = {csr_rdata[31:3], ex_mem_csr_next_val[1:0], csr_rdata[0]};`
  - core.v:1430: ``CSR_VXSAT: if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1431: `id_csr_rdata = {31'b0, ex_mem_csr_next_val[0]};`
  - core.v:1432: ``CSR_VXRM : if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1433: `id_csr_rdata = {30'b0, ex_mem_csr_next_val[2:1]};`
  - core.v:1434: ``CSR_MSTATUS:`
  - core.v:1435: `if ((ex_mem_csr_addr_r == `CSR_VSTART) || (ex_mem_csr_addr_r == `CSR_VXSAT) ||`
  - core.v:1437: `id_csr_rdata = csr_rdata | 32'h8000_0000 |`
  - core.v:1439: `default: ;`
  - core.v:1443: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1446: `if (id_csr_addr == `CSR_VSTART) id_csr_rdata = 32'h0;`
  - core.v:1447: `if (id_csr_addr == `CSR_MSTATUS)`
  - core.v:1448: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1534: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1535: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1536: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1537: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1538: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1539: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1540: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1541: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1542: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1543: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1544: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1545: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1546: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1547: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1548: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1549: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1550: `ex_mem_vcfg_we_r         <= 1'b0;`
  - core.v:1551: `ex_mem_vex_we_r          <= 1'b0;`
  - core.v:1552: `ex_mem_vex_flag_r        <= 1'b0;`
  - core.v:1553: `ex_mem_vex_mem_r         <= 1'b0;`
  - core.v:1554: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1555: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1556: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1557: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1558: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1559: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1560: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1561: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1562: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1563: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1564: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1565: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1566: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1567: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1716: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1717: `amo_state <= AMO_DONE;`
  - core.v:1718: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1719: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1720: `if (ex_mem_sc_fail) begin`
  - core.v:1721: `amo_state     <= AMO_DONE;`
  - core.v:1722: `amo_result_r  <= 32'h1;`
  - core.v:1723: `amo_res_valid <= 1'b0;`
  - core.v:1724: `end else begin`
  - core.v:1725: `case (amo_state)`
  - core.v:1726: `AMO_IDLE: begin`
  - core.v:1727: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1728: `amo_state     <= AMO_DONE;`
  - core.v:1729: `amo_result_r  <= 32'h0;`
  - core.v:1730: `amo_res_valid <= 1'b0;`
  - core.v:1731: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1732: `amo_state <= AMO_LOAD;`
  - core.v:1735: `AMO_LOAD: begin`
  - core.v:1736: `amo_result_r <= d_mem_rdata;`
  - core.v:1737: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1738: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1739: `amo_state     <= AMO_DONE;`
  - core.v:1740: `amo_res_valid <= 1'b1;`
  - core.v:1741: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1742: `end else begin`
  - core.v:1743: `amo_state <= AMO_STORE;`
  - core.v:1746: `AMO_STORE: begin`
  - core.v:1747: `amo_state     <= AMO_DONE;`
  - core.v:1748: `amo_res_valid <= 1'b0;`
  - core.v:1750: `default: begin`
  - core.v:1751: `if (ex_mem_advance_to_wb) begin`
  - core.v:1752: `amo_state <= AMO_IDLE;`
  - core.v:1762: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1763: `amo_res_valid <= 1'b0;`
  - core.v:1821: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1822: `ex_wb_valid_r           <= 1'b0;`
  - core.v:1823: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:1824: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:1825: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:1826: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:1827: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:1828: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:1829: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:1830: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:1831: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:1832: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:1833: `ex_wb_vcfg_we_r         <= 1'b0;`
  - core.v:1834: `ex_wb_vex_we_r          <= 1'b0;`
  - core.v:1835: `ex_wb_vex_flag_r        <= 1'b0;`
  - core.v:1836: `ex_wb_vex_mem_r         <= 1'b0;`
  - core.v:1837: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:1838: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:1839: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:1840: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:1841: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:1842: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:1843: `ex_wb_instr_r           <= 32'h0;`
  - core.v:1844: `ex_wb_mem_re_r          <= 1'b0;`
  - core.v:1845: `ex_wb_mem_we_r          <= 1'b0;`
  - core.v:1846: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:1847: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:1848: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:1849: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:1850: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:1851: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:1852: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1853: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:1854: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:1994: `wb_data_mux = amo_result_r;`
  - core.v:2000: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:2016: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:2017: `wb_take_data_trap ?`
  - core.v:2019: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:2020: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:2021: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:2022: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:2028: `ex_wb_instr_r) :`
  - core.v:2053: `end else if (debug_resume_redirect) begin`
  - core.v:2054: `pc_redirect     = 1'b1;`
  - core.v:2055: `redirect_target = dpc_o;`
  - core.v:2059: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:2060: `pc_redirect     = 1'b1;`
  - core.v:2061: `redirect_target = mepc_o;`
  - core.v:2062: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:2063: `pc_redirect     = 1'b1;`
  - core.v:2064: `redirect_target = dpc_o;`
  - core.v:2065: `end else if (debug_halt_enter) begin`
  - core.v:2066: `pc_redirect     = 1'b1;`
  - core.v:2067: `redirect_target = debug_halt_pc_w;`
  - core.v:2068: `end else if (mem_ras_mispredict) begin`
  - core.v:2070: `pc_redirect     = 1'b1;`
  - core.v:2071: `redirect_target = mem_ras_actual_target;`
  - core.v:2083: `ex_mem_pc_plus_4_r;`
  - core.v:2107: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:2109: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:2110: `DBG_ENTRY_TRIG_ST) :`
  - core.v:2127: `debug_halt_pending <= 1'b1;`
  - core.v:2129: `debug_halt_pending <= 1'b0;`
  - core.v:2131: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:2132: `debug_mode <= 1'b0;`
  - core.v:2133: `debug_step_pending <= dcsr_step;`
  - core.v:2135: `debug_mode <= 1'b1;`
  - core.v:2136: `debug_step_pending <= 1'b0;`
  - core.v:2145: `32'h0;`

Status: pass

