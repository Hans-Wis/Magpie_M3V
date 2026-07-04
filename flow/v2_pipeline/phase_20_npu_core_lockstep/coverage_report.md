# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 485 | 710 | 68.3% |
| cpu_m1_top.v | 16 | 26 | 61.5% |
| csr.v | 59 | 299 | 19.7% |
| div.v | 46 | 51 | 90.2% |
| fexu.v | 79 | 128 | 61.7% |
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
| vexu.v | 122 | 200 | 61.0% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:648: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:778: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:781: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:813: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:816: `(ex_wb_valid_r && ex_wb_csr_we_r && (ex_wb_csr_addr_r == `CSR_VSTART)) ?`
  - core.v:825: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VXRM)) ?`
  - core.v:827: `(ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == `CSR_VCSR)) ?`
  - core.v:829: `(ex_wb_valid_r  && ex_wb_csr_we_r  && (ex_wb_csr_addr_r == `CSR_VXRM))  ?`
  - core.v:831: `(ex_wb_valid_r  && ex_wb_csr_we_r  && (ex_wb_csr_addr_r == `CSR_VCSR))  ?`
  - core.v:839: `(ex_mem_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:842: `(ex_wb_csr_addr_r == `CSR_MSTATUS)) ?`
  - core.v:1131: `function [31:0] amo_compute;`
  - core.v:1135: `begin`
  - core.v:1136: `case (op)`
  - core.v:1137: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:1138: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:1139: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:1140: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:1141: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1142: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:1143: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1144: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:1145: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1228: `assign d_mem_wstrb = ((EN_RVV != 0) && vexu_vm_active) ?`
  - core.v:1244: `function is_vector_csr_addr;`
  - core.v:1246: `begin`
  - core.v:1247: `is_vector_csr_addr = (addr == `CSR_VSTART) ||`
  - core.v:1252: `(addr == `CSR_VTYPE)  ||`
  - core.v:1257: `function is_vector_ro_csr_addr;`
  - core.v:1259: `begin`
  - core.v:1260: `is_vector_ro_csr_addr = (addr == `CSR_VL) ||`
  - core.v:1261: `(addr == `CSR_VTYPE) ||`
  - core.v:1513: `case (id_csr_addr)`
  - core.v:1514: ``CSR_VSTART: id_csr_rdata = 32'h0;`
  - core.v:1515: ``CSR_VL    : id_csr_rdata = ex_mem_vcfg_vl_r;`
  - core.v:1516: ``CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;`
  - core.v:1517: `default    : ;`
  - core.v:1527: `id_csr_rdata = id_csr_rdata | {27'b0, ex_wb_f_flags_r};`
  - core.v:1537: `id_csr_rdata = id_csr_rdata | 32'h1;`
  - core.v:1544: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1545: `case (id_csr_addr)`
  - core.v:1546: ``CSR_VCSR: begin`
  - core.v:1547: `if (ex_mem_csr_addr_r == `CSR_VXSAT)`
  - core.v:1548: `id_csr_rdata = {csr_rdata[31:1], ex_mem_csr_next_val[0]};`
  - core.v:1549: `if (ex_mem_csr_addr_r == `CSR_VXRM)`
  - core.v:1550: `id_csr_rdata = {csr_rdata[31:3], ex_mem_csr_next_val[1:0], csr_rdata[0]};`
  - core.v:1552: ``CSR_VXSAT: if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1553: `id_csr_rdata = {31'b0, ex_mem_csr_next_val[0]};`
  - core.v:1554: ``CSR_VXRM : if (ex_mem_csr_addr_r == `CSR_VCSR)`
  - core.v:1555: `id_csr_rdata = {30'b0, ex_mem_csr_next_val[2:1]};`
  - core.v:1556: ``CSR_MSTATUS:`
  - core.v:1557: `if ((ex_mem_csr_addr_r == `CSR_VSTART) || (ex_mem_csr_addr_r == `CSR_VXSAT) ||`
  - core.v:1559: `id_csr_rdata = csr_rdata | 32'h8000_0000 |`
  - core.v:1561: `default: ;`
  - core.v:1565: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1570: `id_csr_rdata = id_csr_rdata | 32'h1;`
  - core.v:1575: `(ex_mem_csr_addr_r != id_csr_addr)) begin`
  - core.v:1576: `case (id_csr_addr)`
  - core.v:1577: ``CSR_FCSR: begin`
  - core.v:1578: `if (ex_mem_csr_addr_r == `CSR_FFLAGS)`
  - core.v:1579: `id_csr_rdata = {id_csr_rdata[31:5], ex_mem_csr_next_val[4:0]};`
  - core.v:1580: `if (ex_mem_csr_addr_r == `CSR_FRM)`
  - core.v:1581: `id_csr_rdata = {id_csr_rdata[31:8], ex_mem_csr_next_val[2:0],`
  - core.v:1582: `id_csr_rdata[4:0]};`
  - core.v:1584: ``CSR_FFLAGS: if (ex_mem_csr_addr_r == `CSR_FCSR)`
  - core.v:1585: `id_csr_rdata = {27'b0, ex_mem_csr_next_val[4:0]};`
  - core.v:1586: ``CSR_FRM   : if (ex_mem_csr_addr_r == `CSR_FCSR)`
  - core.v:1587: `id_csr_rdata = {29'b0, ex_mem_csr_next_val[7:5]};`
  - core.v:1588: ``CSR_MSTATUS:`
  - core.v:1589: `if ((ex_mem_csr_addr_r == `CSR_FFLAGS) ||`
  - core.v:1592: `id_csr_rdata = id_csr_rdata | 32'h8000_0000 |`
  - core.v:1594: `default: ;`
  - core.v:1600: `id_csr_rdata = id_csr_rdata | {27'b0, ex_mem_f_flags_r};`
  - core.v:1603: `id_csr_rdata = id_csr_rdata | 32'h8000_0000 |`
  - core.v:1607: `if (id_csr_addr == `CSR_VSTART) id_csr_rdata = 32'h0;`
  - core.v:1608: `if (id_csr_addr == `CSR_MSTATUS)`
  - core.v:1609: `id_csr_rdata = csr_rdata | 32'h8000_0000 | (32'h3 << `MSTATUS_VS_LO_BIT);`
  - core.v:1700: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1701: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1702: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1703: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1704: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1705: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1706: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1707: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1708: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1709: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1710: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1711: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1712: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1713: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1714: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1715: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1716: `ex_mem_vcfg_we_r         <= 1'b0;`
  - core.v:1717: `ex_mem_vex_we_r          <= 1'b0;`
  - core.v:1718: `ex_mem_vex_sat_r         <= 1'b0;`
  - core.v:1719: `ex_mem_vex_grp_w_r       <= 1'b0;`
  - core.v:1720: `ex_mem_f_we_r            <= 1'b0;`
  - core.v:1721: `ex_mem_f_flw_r           <= 1'b0;`
  - core.v:1722: `ex_mem_f_exec_r          <= 1'b0;`
  - core.v:1723: `ex_mem_vex_flag_r        <= 1'b0;`
  - core.v:1724: `ex_mem_vex_mem_r         <= 1'b0;`
  - core.v:1725: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1726: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1727: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1728: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1729: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1730: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1731: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1732: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1733: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1734: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1735: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1736: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1737: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1738: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1904: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1905: `amo_state <= AMO_DONE;`
  - core.v:1906: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1907: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1908: `if (ex_mem_sc_fail) begin`
  - core.v:1909: `amo_state     <= AMO_DONE;`
  - core.v:1910: `amo_result_r  <= 32'h1;`
  - core.v:1911: `amo_res_valid <= 1'b0;`
  - core.v:1912: `end else begin`
  - core.v:1913: `case (amo_state)`
  - core.v:1914: `AMO_IDLE: begin`
  - core.v:1915: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1916: `amo_state     <= AMO_DONE;`
  - core.v:1917: `amo_result_r  <= 32'h0;`
  - core.v:1918: `amo_res_valid <= 1'b0;`
  - core.v:1919: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1920: `amo_state <= AMO_LOAD;`
  - core.v:1923: `AMO_LOAD: begin`
  - core.v:1924: `amo_result_r <= d_mem_rdata;`
  - core.v:1925: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1926: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1927: `amo_state     <= AMO_DONE;`
  - core.v:1928: `amo_res_valid <= 1'b1;`
  - core.v:1929: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1930: `end else begin`
  - core.v:1931: `amo_state <= AMO_STORE;`
  - core.v:1934: `AMO_STORE: begin`
  - core.v:1935: `amo_state     <= AMO_DONE;`
  - core.v:1936: `amo_res_valid <= 1'b0;`
  - core.v:1938: `default: begin`
  - core.v:1939: `if (ex_mem_advance_to_wb) begin`
  - core.v:1940: `amo_state <= AMO_IDLE;`
  - core.v:1950: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1951: `amo_res_valid <= 1'b0;`
  - core.v:2014: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:2015: `ex_wb_valid_r           <= 1'b0;`
  - core.v:2016: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:2017: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:2018: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:2019: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:2020: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:2021: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:2022: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:2023: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:2024: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:2025: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:2026: `ex_wb_vcfg_we_r         <= 1'b0;`
  - core.v:2027: `ex_wb_vex_we_r          <= 1'b0;`
  - core.v:2028: `ex_wb_vex_sat_r         <= 1'b0;`
  - core.v:2029: `ex_wb_vex_grp_w_r       <= 1'b0;`
  - core.v:2030: `ex_wb_f_we_r            <= 1'b0;`
  - core.v:2031: `ex_wb_f_flw_r           <= 1'b0;`
  - core.v:2032: `ex_wb_f_exec_r          <= 1'b0;`
  - core.v:2033: `ex_wb_vex_flag_r        <= 1'b0;`
  - core.v:2034: `ex_wb_vex_mem_r         <= 1'b0;`
  - core.v:2035: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:2036: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:2037: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:2038: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:2039: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:2040: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:2041: `ex_wb_instr_r           <= 32'h0;`
  - core.v:2042: `ex_wb_mem_re_r          <= 1'b0;`
  - core.v:2043: `ex_wb_mem_we_r          <= 1'b0;`
  - core.v:2044: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:2045: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:2046: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:2047: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:2048: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:2049: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:2050: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:2051: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:2052: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:2214: `wb_data_mux = amo_result_r;`
  - core.v:2220: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:2236: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:2237: `wb_take_data_trap ?`
  - core.v:2239: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:2240: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:2241: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:2242: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:2248: `ex_wb_instr_r) :`
  - core.v:2273: `end else if (debug_resume_redirect) begin`
  - core.v:2274: `pc_redirect     = 1'b1;`
  - core.v:2275: `redirect_target = dpc_o;`
  - core.v:2279: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:2280: `pc_redirect     = 1'b1;`
  - core.v:2281: `redirect_target = mepc_o;`
  - core.v:2282: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:2283: `pc_redirect     = 1'b1;`
  - core.v:2284: `redirect_target = dpc_o;`
  - core.v:2285: `end else if (debug_halt_enter) begin`
  - core.v:2286: `pc_redirect     = 1'b1;`
  - core.v:2287: `redirect_target = debug_halt_pc_w;`
  - core.v:2288: `end else if (mem_ras_mispredict) begin`
  - core.v:2290: `pc_redirect     = 1'b1;`
  - core.v:2291: `redirect_target = mem_ras_actual_target;`
  - core.v:2303: `ex_mem_pc_plus_4_r;`
  - core.v:2327: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:2329: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:2330: `DBG_ENTRY_TRIG_ST) :`
  - core.v:2347: `debug_halt_pending <= 1'b1;`
  - core.v:2349: `debug_halt_pending <= 1'b0;`
  - core.v:2351: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:2352: `debug_mode <= 1'b0;`
  - core.v:2353: `debug_step_pending <= dcsr_step;`
  - core.v:2355: `debug_mode <= 1'b1;`
  - core.v:2356: `debug_step_pending <= 1'b0;`
  - core.v:2365: `32'h0;`

Status: pass

