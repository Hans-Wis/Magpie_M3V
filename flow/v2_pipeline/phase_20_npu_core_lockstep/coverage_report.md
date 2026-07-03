# ADR-0034 NPU strip-coverage report (Verilator line coverage)

- bp.v: 0 coverage points (generate-off at elaboration) ✓
- ras.v: 0 coverage points (generate-off at elaboration) ✓
- cdec.v: 0 coverage points (generate-off at elaboration) ✓

| file | covered | total | % |
|---|---|---|---|
| alu.v | 13 | 14 | 92.9% |
| axil_decerr.v | 6 | 7 | 85.7% |
| bmu.v | 3 | 48 | 6.2% |
| core.v | 354 | 495 | 71.5% |
| cpu_m1_top.v | 16 | 26 | 61.5% |
| csr.v | 50 | 189 | 26.5% |
| div.v | 46 | 51 | 90.2% |
| idu.v | 61 | 130 | 46.9% |
| ifu.v | 6 | 6 | 100.0% |
| npu_axil_regs.v | 38 | 116 | 32.8% |
| npu_dma.v | 6 | 64 | 9.4% |
| npu_tcm.v | 11 | 19 | 57.9% |
| npu_top.v | 19 | 25 | 76.0% |
| pmp.v | 5 | 40 | 12.5% |
| rfu.v | 10 | 12 | 83.3% |
| tb_npu_lockstep.v | 55 | 55 | 100.0% |
| trigger.v | 28 | 104 | 26.9% |

## core.v residual uncovered lines (stripped-config triage)

Classes: debug-module paths (no DM in NPU socket), trap/CSR corners not in the
rv32im lockstep corpus, and BP/RAS-mispredict arms that are unreachable by
construction when EN_BP=EN_RAS=0 (EX resolve is the only redirect).

  - core.v:593: ``WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;`
  - core.v:799: `function [31:0] amo_compute;`
  - core.v:803: `begin`
  - core.v:804: `case (op)`
  - core.v:805: ``AMO_OP_SWAP: amo_compute = rs2_val_f;`
  - core.v:806: ``AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;`
  - core.v:807: ``AMO_OP_OR  : amo_compute = old_val | rs2_val_f;`
  - core.v:808: ``AMO_OP_AND : amo_compute = old_val & rs2_val_f;`
  - core.v:809: ``AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:810: ``AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;`
  - core.v:811: ``AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:812: ``AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;`
  - core.v:813: `default     : amo_compute = old_val + rs2_val_f;`
  - core.v:1188: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1189: `ex_mem_valid_r           <= 1'b0;`
  - core.v:1190: `ex_mem_rd_we_r           <= 1'b0;`
  - core.v:1191: `ex_mem_is_load_r         <= 1'b0;`
  - core.v:1192: `ex_mem_is_mul_r          <= 1'b0;`
  - core.v:1193: `ex_mem_is_store_r        <= 1'b0;`
  - core.v:1194: `ex_mem_is_amo_r          <= 1'b0;`
  - core.v:1195: `ex_mem_amo_is_lr_r       <= 1'b0;`
  - core.v:1196: `ex_mem_amo_is_sc_r       <= 1'b0;`
  - core.v:1197: `ex_mem_amo_op_r          <= 4'h0;`
  - core.v:1198: `ex_mem_store_wstrb_r     <= 4'h0;`
  - core.v:1199: `ex_mem_is_mret_r         <= 1'b0;`
  - core.v:1200: `ex_mem_is_dret_r         <= 1'b0;`
  - core.v:1201: `ex_mem_is_misaligned_r   <= 1'b0;`
  - core.v:1202: `ex_mem_is_misaligned_store_r <= 1'b0;`
  - core.v:1203: `ex_mem_csr_we_r          <= 1'b0;`
  - core.v:1204: `ex_mem_is_branch_taken_r <= 1'b0;`
  - core.v:1205: `ex_mem_is_jal_r          <= 1'b0;`
  - core.v:1206: `ex_mem_is_jalr_r         <= 1'b0;`
  - core.v:1207: `ex_mem_illegal_r         <= 1'b0;`
  - core.v:1208: `ex_mem_is_ecall_r        <= 1'b0;`
  - core.v:1209: `ex_mem_is_ebreak_r       <= 1'b0;`
  - core.v:1210: `ex_mem_instr_r           <= 32'h0;`
  - core.v:1211: `ex_mem_mispredict_r      <= 1'b0;`
  - core.v:1212: `ex_mem_bp_upd_valid_r    <= 1'b0;`
  - core.v:1213: `ex_mem_pred_ras_r        <= 1'b0;`
  - core.v:1214: `ex_mem_trigger_hit_r     <= 1'b0;`
  - core.v:1215: `ex_mem_trigger_idx_r     <= 2'd0;`
  - core.v:1216: `ex_mem_pmp_if_fault_r    <= 1'b0;`
  - core.v:1217: `ex_mem_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1352: `if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin`
  - core.v:1353: `amo_state <= AMO_DONE;`
  - core.v:1354: `end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&`
  - core.v:1355: `!debug_mode && !mem_side_effect_block) begin`
  - core.v:1356: `if (ex_mem_sc_fail) begin`
  - core.v:1357: `amo_state     <= AMO_DONE;`
  - core.v:1358: `amo_result_r  <= 32'h1;`
  - core.v:1359: `amo_res_valid <= 1'b0;`
  - core.v:1360: `end else begin`
  - core.v:1361: `case (amo_state)`
  - core.v:1362: `AMO_IDLE: begin`
  - core.v:1363: `if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin`
  - core.v:1364: `amo_state     <= AMO_DONE;`
  - core.v:1365: `amo_result_r  <= 32'h0;`
  - core.v:1366: `amo_res_valid <= 1'b0;`
  - core.v:1367: `end else if (ex_mem_amo_needs_load) begin`
  - core.v:1368: `amo_state <= AMO_LOAD;`
  - core.v:1371: `AMO_LOAD: begin`
  - core.v:1372: `amo_result_r <= d_mem_rdata;`
  - core.v:1373: `amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);`
  - core.v:1374: `if (ex_mem_amo_is_lr_r) begin`
  - core.v:1375: `amo_state     <= AMO_DONE;`
  - core.v:1376: `amo_res_valid <= 1'b1;`
  - core.v:1377: `amo_res_addr  <= ex_mem_alu_result_r[31:2];`
  - core.v:1378: `end else begin`
  - core.v:1379: `amo_state <= AMO_STORE;`
  - core.v:1382: `AMO_STORE: begin`
  - core.v:1383: `amo_state     <= AMO_DONE;`
  - core.v:1384: `amo_res_valid <= 1'b0;`
  - core.v:1386: `default: begin`
  - core.v:1387: `if (ex_mem_advance_to_wb) begin`
  - core.v:1388: `amo_state <= AMO_IDLE;`
  - core.v:1398: `(d_mem_addr[31:2] == amo_res_addr)) begin`
  - core.v:1399: `amo_res_valid <= 1'b0;`
  - core.v:1447: `end else if (debug_mode || debug_halt_enter) begin`
  - core.v:1448: `ex_wb_valid_r           <= 1'b0;`
  - core.v:1449: `ex_wb_rd_we_r           <= 1'b0;`
  - core.v:1450: `ex_wb_is_load_r         <= 1'b0;`
  - core.v:1451: `ex_wb_is_amo_r          <= 1'b0;`
  - core.v:1452: `ex_wb_amo_is_sc_r       <= 1'b0;`
  - core.v:1453: `ex_wb_is_store_r        <= 1'b0;`
  - core.v:1454: `ex_wb_is_misaligned_r       <= 1'b0;`
  - core.v:1455: `ex_wb_is_misaligned_store_r <= 1'b0;`
  - core.v:1456: `ex_wb_is_mret_r         <= 1'b0;`
  - core.v:1457: `ex_wb_is_dret_r         <= 1'b0;`
  - core.v:1458: `ex_wb_csr_we_r          <= 1'b0;`
  - core.v:1459: `ex_wb_is_branch_taken_r <= 1'b0;`
  - core.v:1460: `ex_wb_is_jal_r          <= 1'b0;`
  - core.v:1461: `ex_wb_is_jalr_r         <= 1'b0;`
  - core.v:1462: `ex_wb_illegal_r         <= 1'b0;`
  - core.v:1463: `ex_wb_is_ecall_r        <= 1'b0;`
  - core.v:1464: `ex_wb_is_ebreak_r       <= 1'b0;`
  - core.v:1465: `ex_wb_instr_r           <= 32'h0;`
  - core.v:1466: `ex_wb_trigger_hit_r     <= 1'b0;`
  - core.v:1467: `ex_wb_trigger_idx_r     <= 2'd0;`
  - core.v:1468: `ex_wb_trigger_exec_r    <= 1'b0;`
  - core.v:1469: `ex_wb_trigger_load_r    <= 1'b0;`
  - core.v:1470: `ex_wb_trigger_store_r   <= 1'b0;`
  - core.v:1471: `ex_wb_pmp_if_fault_r    <= 1'b0;`
  - core.v:1472: `ex_wb_pmp_if_mtval_r    <= 32'h0;`
  - core.v:1473: `ex_wb_pmp_data_fault_r  <= 1'b0;`
  - core.v:1474: `ex_wb_pmp_data_store_r  <= 1'b0;`
  - core.v:1584: `wb_data_mux = amo_result_r;`
  - core.v:1590: ``WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;`
  - core.v:1606: ``MCAUSE_ILLEGAL_INSTRUCTION) :`
  - core.v:1607: `wb_take_data_trap ?`
  - core.v:1609: `(ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :`
  - core.v:1610: ``MCAUSE_LOAD_ACCESS_FAULT) :`
  - core.v:1611: `(ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :`
  - core.v:1612: ``MCAUSE_LOAD_ADDR_MISALIGNED)) :`
  - core.v:1618: `ex_wb_instr_r) :`
  - core.v:1643: `end else if (debug_resume_redirect) begin`
  - core.v:1644: `pc_redirect     = 1'b1;`
  - core.v:1645: `redirect_target = dpc_o;`
  - core.v:1649: `end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin`
  - core.v:1650: `pc_redirect     = 1'b1;`
  - core.v:1651: `redirect_target = mepc_o;`
  - core.v:1652: `end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin`
  - core.v:1653: `pc_redirect     = 1'b1;`
  - core.v:1654: `redirect_target = dpc_o;`
  - core.v:1655: `end else if (debug_halt_enter) begin`
  - core.v:1656: `pc_redirect     = 1'b1;`
  - core.v:1657: `redirect_target = debug_halt_pc_w;`
  - core.v:1658: `end else if (mem_ras_mispredict) begin`
  - core.v:1660: `pc_redirect     = 1'b1;`
  - core.v:1661: `redirect_target = mem_ras_actual_target;`
  - core.v:1673: `ex_mem_pc_plus_4_r;`
  - core.v:1697: `assign debug_entry_reason    = wb_take_trigger ?`
  - core.v:1699: `ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :`
  - core.v:1700: `DBG_ENTRY_TRIG_ST) :`
  - core.v:1717: `debug_halt_pending <= 1'b1;`
  - core.v:1719: `debug_halt_pending <= 1'b0;`
  - core.v:1721: `if (debug_dret_exit || debug_resume_exit) begin`
  - core.v:1722: `debug_mode <= 1'b0;`
  - core.v:1723: `debug_step_pending <= dcsr_step;`
  - core.v:1725: `debug_mode <= 1'b1;`
  - core.v:1726: `debug_step_pending <= 1'b0;`
  - core.v:1735: `32'h0;`

Status: pass

