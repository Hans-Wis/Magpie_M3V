# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 430 | 613 | 70.1% |
| cpu_m1_top.v | 16 | 26 | 61.5% |
| csr.v | 56 | 267 | 21.0% |
| div.v | 46 | 51 | 90.2% |
| idu.v | 61 | 130 | 46.9% |
| ifu.v | 6 | 6 | 100.0% |
| npu_axil_regs.v | 38 | 116 | 32.8% |
| npu_dma.v | 6 | 64 | 9.4% |
| npu_tcm.v | 11 | 19 | 57.9% |
| npu_top.v | 19 | 25 | 76.0% |
| pmp.v | 5 | 40 | 12.5% |
| rfu.v | 10 | 12 | 83.3% |
| tb_npu_lockstep.v | 57 | 61 | 93.4% |
| trigger.v | 28 | 104 | 26.9% |
| vexu.v | 16 | 18 | 88.9% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:606: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:736: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:739: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:771: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:774: `(ex_wb_valid_r && ex_wb_csr_we_r && (ex_wb_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:958: `function [31:0] amo_compute;`
  - core.v:962: `begin`
  - core.v:963: `case (op)`
  - core.v:964: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:965: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:966: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:967: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:968: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:969: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:970: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:971: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:972: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1065: `function is_vector_csr_addr;`
  - core.v:1067: `begin`
  - core.v:1068: `is_vector_csr_addr = (addr == `CSR_VSTART) ||`
  - core.v:1073: `(addr == `CSR_VTYPE)  ||`
  - core.v:1078: `function is_vector_ro_csr_addr;`
  - core.v:1080: `begin`
  - core.v:1081: `is_vector_ro_csr_addr = (addr == `CSR_VL) ||`
  - core.v:1082: `(addr == `CSR_VTYPE) ||`
  - core.v:1320: `case (id_csr_addr)`
  - core.v:1321: ``CSR_VSTART: id_csr_rdata = 32'h0;`
  - core.v:1322: ``CSR_VL    : id_csr_rdata = ex_mem_vcfg_vl_r;`
  - core.v:1323: ``CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;`
  - core.v:1324: `default    : ;`
  - core.v:1333: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1334: `case (id_csr_addr)`
  - core.v:1335: ``CSR_VCSR: begin`
  - core.v:1336: `if (ex_mem_csr_addr_r == `CSR_VXSAT)`
  - core.v:1337: `id_csr_rdata = {csr_rdata[31:1], ex_mem_csr_next_val[0]};`
  - core.v:1338: `if (ex_mem_csr_addr_r == `CSR_VXRM)`
  - core.v:1339: `id_csr_rdata = {csr_rdata[31:3], ex_mem_csr_next_val[1:0], csr_rdata[0]};`
  - core.v:1341: ``CSR_VXSAT: if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1342: `id_csr_rdata = {31'b0, ex_mem_csr_next_val[0]};`
  - core.v:1343: ``CSR_VXRM : if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1344: `id_csr_rdata = {30'b0, ex_mem_csr_next_val[2:1]};`
  - core.v:1345: ``CSR_MSTATUS:`
  - core.v:1346: `if ((ex_mem_csr_addr_r == `CSR_VSTART) || (ex_mem_csr_addr_r == `CSR_VXSAT) ||`
  - core.v:1348: `id_csr_rdata = csr_rdata | 32'h8000_0000 |`
  - core.v:1350: `default: ;`
  - core.v:1354: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1357: `if (id_csr_addr == `CSR_VSTART) id_csr_rdata = 32'h0;`
  - core.v:1358: `if (id_csr_addr == `CSR_MSTATUS)`
  - core.v:1359: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1444: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1445: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1446: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1447: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1448: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1449: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1450: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1451: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1452: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1453: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1454: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1455: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1456: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1457: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1458: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1459: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1460: `ex_mem_vcfg_we_r         <= 1'b0;`
  - core.v:1461: `ex_mem_vex_we_r          <= 1'b0;`
  - core.v:1462: `ex_mem_vex_flag_r        <= 1'b0;`
  - core.v:1463: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1464: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1465: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1466: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1467: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1468: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1469: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1470: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1471: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1472: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1473: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1474: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1475: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1476: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1623: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1624: `amo_state <= AMO_DONE;`
  - core.v:1625: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1626: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1627: `if (ex_mem_sc_fail) begin`
  - core.v:1628: `amo_state     <= AMO_DONE;`
  - core.v:1629: `amo_result_r  <= 32'h1;`
  - core.v:1630: `amo_res_valid <= 1'b0;`
  - core.v:1631: `end else begin`
  - core.v:1632: `case (amo_state)`
  - core.v:1633: `AMO_IDLE: begin`
  - core.v:1634: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1635: `amo_state     <= AMO_DONE;`
  - core.v:1636: `amo_result_r  <= 32'h0;`
  - core.v:1637: `amo_res_valid <= 1'b0;`
  - core.v:1638: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1639: `amo_state <= AMO_LOAD;`
  - core.v:1642: `AMO_LOAD: begin`
  - core.v:1643: `amo_result_r <= d_mem_rdata;`
  - core.v:1644: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1645: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1646: `amo_state     <= AMO_DONE;`
  - core.v:1647: `amo_res_valid <= 1'b1;`
  - core.v:1648: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1649: `end else begin`
  - core.v:1650: `amo_state <= AMO_STORE;`
  - core.v:1653: `AMO_STORE: begin`
  - core.v:1654: `amo_state     <= AMO_DONE;`
  - core.v:1655: `amo_res_valid <= 1'b0;`
  - core.v:1657: `default: begin`
  - core.v:1658: `if (ex_mem_advance_to_wb) begin`
  - core.v:1659: `amo_state <= AMO_IDLE;`
  - core.v:1669: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1670: `amo_res_valid <= 1'b0;`
  - core.v:1725: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1726: `ex_wb_valid_r           <= 1'b0;`
  - core.v:1727: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:1728: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:1729: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:1730: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:1731: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:1732: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:1733: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:1734: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:1735: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:1736: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:1737: `ex_wb_vcfg_we_r         <= 1'b0;`
  - core.v:1738: `ex_wb_vex_we_r          <= 1'b0;`
  - core.v:1739: `ex_wb_vex_flag_r        <= 1'b0;`
  - core.v:1740: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:1741: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:1742: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:1743: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:1744: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:1745: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:1746: `ex_wb_instr_r           <= 32'h0;`
  - core.v:1747: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:1748: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:1749: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:1750: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:1751: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:1752: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:1753: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1754: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:1755: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:1886: `wb_data_mux = amo_result_r;`
  - core.v:1892: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:1908: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:1909: `wb_take_data_trap ?`
  - core.v:1911: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:1912: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:1913: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:1914: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:1920: `ex_wb_instr_r) :`
  - core.v:1945: `end else if (debug_resume_redirect) begin`
  - core.v:1946: `pc_redirect     = 1'b1;`
  - core.v:1947: `redirect_target = dpc_o;`
  - core.v:1951: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:1952: `pc_redirect     = 1'b1;`
  - core.v:1953: `redirect_target = mepc_o;`
  - core.v:1954: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:1955: `pc_redirect     = 1'b1;`
  - core.v:1956: `redirect_target = dpc_o;`
  - core.v:1957: `end else if (debug_halt_enter) begin`
  - core.v:1958: `pc_redirect     = 1'b1;`
  - core.v:1959: `redirect_target = debug_halt_pc_w;`
  - core.v:1960: `end else if (mem_ras_mispredict) begin`
  - core.v:1962: `pc_redirect     = 1'b1;`
  - core.v:1963: `redirect_target = mem_ras_actual_target;`
  - core.v:1975: `ex_mem_pc_plus_4_r;`
  - core.v:1999: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:2001: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:2002: `DBG_ENTRY_TRIG_ST) :`
  - core.v:2019: `debug_halt_pending <= 1'b1;`
  - core.v:2021: `debug_halt_pending <= 1'b0;`
  - core.v:2023: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:2024: `debug_mode <= 1'b0;`
  - core.v:2025: `debug_step_pending <= dcsr_step;`
  - core.v:2027: `debug_mode <= 1'b1;`
  - core.v:2028: `debug_step_pending <= 1'b0;`
  - core.v:2037: `32'h0;`

Status: pass

