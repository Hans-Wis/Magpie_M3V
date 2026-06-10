// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_equiv.h for the primary calling header

#include "Vtb_axil_equiv__pch.h"

void Vtb_axil_equiv_cpu_m1_top___eval_initial__TOP__tb_axil_equiv__DOT__u_native(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___eval_initial__TOP__tb_axil_equiv__DOT__u_native\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[0U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[1U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[2U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[3U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[4U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[5U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[6U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[7U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[8U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[9U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[10U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[11U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[12U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[13U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[14U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[15U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[16U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[17U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[18U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[19U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[20U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[21U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[22U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[23U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[24U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[25U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[26U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[27U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[28U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[29U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[30U] = 0U;
    vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[31U] = 0U;
}

void Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_native__0(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_native__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__d_fire;
    __PVT__d_fire = 0;
    IData/*31:0*/ __PVT__u_core__DOT__redirect_target;
    __PVT__u_core__DOT__redirect_target = 0;
    IData/*31:0*/ __PVT__u_core__DOT__csr_rdata;
    __PVT__u_core__DOT__csr_rdata = 0;
    CData/*0:0*/ __PVT__u_core__DOT__wb_take_irq;
    __PVT__u_core__DOT__wb_take_irq = 0;
    CData/*0:0*/ u_core__DOT____VdfgExtracted_ha4e5ab41__0;
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_13;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_18;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_0;
    __VdfgRegularize_h98839c81_1_0 = 0;
    // Body
    vlSelfRef.__PVT__mem_stall = (((IData)(vlSelfRef.__PVT__i_busy) 
                                   | ((~ (IData)(vlSelfRef.__PVT__primed)) 
                                      | (IData)(vlSelfRef.__PVT__d_busy))) 
                                  & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn));
    vlSelfRef.__PVT__u_core__DOT__bp_upd_valid = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_trap_exit = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14));
    vlSelfRef.__PVT__u_core__DOT__any_stall = ((IData)(vlSelfRef.__PVT__u_core__DOT__stall) 
                                               | ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                                                  | ((IData)(vlSelfRef.__PVT__u_core__DOT__warmup) 
                                                     | ((IData)(vlSelfRef.__PVT__mem_stall) 
                                                        | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup)))));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    __PVT__u_core__DOT__wb_take_irq = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                       & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                          & (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                                             & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13))));
    vlSelfRef.u_core__DOT__rfu_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
                                     & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                        & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                           & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                              & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13)))));
    vlSelfRef.u_core__DOT__wb_instr_retired = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
                                                     & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    vlSelfRef.__PVT__u_core__DOT__wb_csr_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                                     & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = ((IData)(__PVT__u_core__DOT__wb_take_irq) 
                                                 | ((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap) 
                                                    | (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)));
    __PVT__u_core__DOT__csr_rdata = (((((((((0x0300U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U)) 
                                            | (0x0304U 
                                               == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))) 
                                           | (0x0305U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))) 
                                          | (0x0340U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U))) 
                                         | (0x0341U 
                                            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                >> 0x00000014U))) 
                                        | (0x0342U 
                                           == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x00000014U))) 
                                       | (0x0343U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))) 
                                      | (0x0344U == 
                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                          >> 0x00000014U)))
                                      ? ((0x0300U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val
                                          : ((0x0304U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 << 0x0000000bU)
                                              : ((0x0305U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? 
                                                 (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                  << 2U)
                                                  : 
                                                 ((0x0340U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch
                                                   : 
                                                  ((0x0341U 
                                                    == 
                                                    (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))
                                                    ? vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg
                                                    : 
                                                   ((0x0342U 
                                                     == 
                                                     (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))
                                                     ? vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg
                                                     : 
                                                    ((0x0343U 
                                                      == 
                                                      (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U))
                                                      ? vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg
                                                      : 
                                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                                      << 0x0000000bU))))))))
                                      : ((0x0c00U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt)
                                          : ((0x0c80U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? (IData)(
                                                        (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt 
                                                         >> 0x20U))
                                              : ((0x0c02U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt)
                                                  : 
                                                 ((0x0c82U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? (IData)(
                                                             (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt 
                                                              >> 0x20U))
                                                   : 0U)))));
    if (((IData)(vlSelfRef.__PVT__u_core__DOT__wb_csr_we) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r) 
            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                >> 0x00000014U)))) {
        if ((((((((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)) 
                  || (0x0304U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                 || (0x0305U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                || (0x0340U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
               || (0x0341U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
              || (0x0342U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
             || (0x0343U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)))) {
            __PVT__u_core__DOT__csr_rdata = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
        }
    }
    vlSelfRef.__PVT__u_core__DOT__wb_trap_enter = (
                                                   (~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                   & (IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0));
    vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb 
        = ((~ ((IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0) 
               | (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14))) 
           & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r));
    __PVT__u_core__DOT__redirect_target = 0U;
    vlSelfRef.__PVT__u_core__DOT__pc_redirect = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
        if (u_core__DOT____VdfgExtracted_ha4e5ab41__0) {
            __PVT__u_core__DOT__redirect_target = (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                   << 2U);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r))) {
            __PVT__u_core__DOT__redirect_target = vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict) {
            __PVT__u_core__DOT__redirect_target = (0xfffffffeU 
                                                   & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r))) {
            __PVT__u_core__DOT__redirect_target = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r)
                                                    ? 
                                                   (0xfffffffeU 
                                                    & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r)
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r)
                                                      ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r)));
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        }
    }
    vlSelfRef.__PVT__u_core__DOT__id_csr_rdata = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r) 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r) 
                                                         == 
                                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                          >> 0x00000014U))))
                                                   ? 
                                                  ((1U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                    ? vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r
                                                    : 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                     ? 
                                                    (vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r 
                                                     | vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r)
                                                     : 
                                                    ((3U 
                                                      == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                      ? 
                                                     ((~ vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r) 
                                                      & vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)))
                                                   : __PVT__u_core__DOT__csr_rdata);
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)))));
    vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__md_start = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_started)) 
                                              & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17) 
                                                 & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid)) 
                                                    & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                                       & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16)))));
    vlSelfRef.__PVT__i_fire = (1U & (((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                      & (~ (IData)(vlSelfRef.__PVT__i_busy))) 
                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
                                        | ((IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup) 
                                           | ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                              | (IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary))))));
    vlSelfRef.__PVT__core_d_mem_wstrb = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r) 
                                          & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                             & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r)
                                          : 0U);
    __PVT__d_fire = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                      & (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                          | (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r)) 
                         & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                            & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r))))) 
                     & ((~ (IData)(vlSelfRef.__PVT__d_busy)) 
                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    vlSelfRef.__PVT__u_core__DOT__ras_pop = (((IData)(
                                                      (0x00008067U 
                                                       == 
                                                       (0x000fffffU 
                                                        & vlSelfRef.__PVT__u_core__DOT__instr_assembled))) 
                                              | ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w) 
                                                 & (0x8082U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))) 
                                             & ((0U 
                                                 != vlSelfRef.__PVT__u_core__DOT__ras_top) 
                                                & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
                                                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__d_xfer = ((IData)(__PVT__d_fire) 
                               | (IData)(vlSelfRef.__PVT__d_busy));
    vlSelfRef.__PVT__u_core__DOT__ras_push = (IData)(
                                                     ((((0x000000efU 
                                                         == 
                                                         (0x00000fffU 
                                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                        & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid)) 
                                                       & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall))) 
                                                      & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18)));
    vlSelfRef.__PVT__u_core__DOT__next_pc_w = ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)
                                                ? __PVT__u_core__DOT__redirect_target
                                                : ((IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)
                                                    ? vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ras_top
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken)
                                                      ? vlSelfRef.__PVT__u_core__DOT__bp_predict_target
                                                      : 
                                                     (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                      + 
                                                      ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
                                                        ? 2U
                                                        : 4U))))));
    __VdfgRegularize_h98839c81_1_0 = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                      & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16) 
                                         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken) 
                                                | (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop))) 
                                            & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18))));
    vlSelfRef.__PVT__u_core__DOT__consecutive_cross 
        = ((((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble) 
             & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (IData)(__VdfgRegularize_h98839c81_1_0));
    vlSelfRef.__PVT__u_core__DOT__upcoming_cross = 
        (((((~ (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
          & (IData)(__VdfgRegularize_h98839c81_1_0)) 
         & (3U != (3U & vlSelfRef.__PVT__i_rdata_q)));
    vlSelfRef.__PVT__core_i_mem_addr = ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary)
                                         ? ((IData)(2U) 
                                            + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                         : ((IData)(vlSelfRef.__PVT__u_core__DOT__consecutive_cross)
                                             ? ((IData)(6U) 
                                                + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                             : ((IData)(vlSelfRef.__PVT__u_core__DOT__upcoming_cross)
                                                 ? 
                                                ((IData)(4U) 
                                                 + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                 : vlSelfRef.__PVT__u_core__DOT__next_pc_w)));
}

extern const VlUnpacked<CData/*1:0*/, 32> Vtb_axil_equiv__ConstPool__TABLE_hdb09954d_0;

void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__0(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit0;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit0 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit1;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit1 = 0;
    CData/*4:0*/ __Vtableidx3;
    __Vtableidx3 = 0;
    CData/*0:0*/ __Vdly__i_busy;
    __Vdly__i_busy = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__md_result_valid;
    __Vdly__u_core__DOT__md_result_valid = 0;
    CData/*2:0*/ __Vdly__u_core__DOT__u_ras__DOT__ptr;
    __Vdly__u_core__DOT__u_ras__DOT__ptr = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__u_mul__DOT__high_out;
    __Vdly__u_core__DOT__u_mul__DOT__high_out = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__u_mul__DOT__busy;
    __Vdly__u_core__DOT__u_mul__DOT__busy = 0;
    CData/*1:0*/ __Vdly__u_core__DOT__u_div__DOT__state;
    __Vdly__u_core__DOT__u_div__DOT__state = 0;
    CData/*5:0*/ __Vdly__u_core__DOT__u_div__DOT__iter;
    __Vdly__u_core__DOT__u_div__DOT__iter = 0;
    IData/*31:0*/ __Vdly__u_core__DOT__u_div__DOT__quotient;
    __Vdly__u_core__DOT__u_div__DOT__quotient = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie;
    __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v1 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1 = 0;
    IData/*25:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v1 = 0;
    CData/*1:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1 = 0;
    CData/*1:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1 = 0;
    IData/*25:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1 = 0;
    CData/*0:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__lru__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__lru__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v1 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0;
    __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0 = 0;
    CData/*2:0*/ __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0;
    __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v0;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v0 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1;
    __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v1;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v1 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2;
    __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2 = 0;
    CData/*2:0*/ __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2;
    __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v2;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v2 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v3;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v3 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0;
    __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0;
    __VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1 = 0;
    VlWide<3>/*95:0*/ __Vtemp_3;
    VlWide<3>/*95:0*/ __Vtemp_4;
    VlWide<3>/*95:0*/ __Vtemp_6;
    VlWide<3>/*95:0*/ __Vtemp_7;
    VlWide<3>/*95:0*/ __Vtemp_8;
    // Body
    if (VL_UNLIKELY((((IData)(vlSelfRef.__PVT__u_core__DOT__cdec_illegal) 
                      & (0U != vlSelfRef.__PVT__u_core__DOT__cdec_expanded))))) {
        VL_WRITEF_NX("[%0t] %%Error: core.v:156: Assertion failed in %Ntb_axil_equiv.u_native.u_core: ADR-0016 invariant: cdec_illegal asserted but expanded=%x != 0\n",0,
                     64,VL_TIME_UNITED_Q(1),-9,vlSymsp->name(),
                     32,vlSelfRef.__PVT__u_core__DOT__cdec_expanded);
        VL_STOP_MT("../../../IP/cpu_m1/rtl/../../../IP/cpu_m1/rtl/core.v", 156, "");
    }
    __Vdly__u_core__DOT__u_ras__DOT__ptr = vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v0 = 0U;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v1 = 0U;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v2 = 0U;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v3 = 0U;
    __Vdly__i_busy = vlSelfRef.__PVT__i_busy;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v1 = 0U;
    __Vdly__u_core__DOT__u_mul__DOT__high_out = vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__high_out;
    __Vdly__u_core__DOT__u_mul__DOT__busy = vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy;
    __Vdly__u_core__DOT__u_div__DOT__state = vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state;
    __Vdly__u_core__DOT__u_div__DOT__iter = vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter;
    __Vdly__u_core__DOT__u_div__DOT__quotient = vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient;
    __Vdly__u_core__DOT__md_result_valid = vlSelfRef.__PVT__u_core__DOT__md_result_valid;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0 = 0U;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1 = 0U;
    __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie;
    if (vlSymsp->TOP.tb_axil_equiv__DOT__resetn) {
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt 
            = (1ULL + vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt);
        if (vlSelfRef.u_core__DOT__wb_instr_retired) {
            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt 
                = (1ULL + vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt);
        }
        if (((IData)(vlSelfRef.__PVT__u_core__DOT__ras_push) 
             & (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop))) {
            if ((0U != (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))) {
                __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0 
                    = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
                __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0 
                    = vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__top_idx;
                __VdlySet__u_core__DOT__u_ras__DOT__stack__v0 = 1U;
            } else {
                __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1 
                    = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
                __VdlySet__u_core__DOT__u_ras__DOT__stack__v1 = 1U;
            }
        } else if (vlSelfRef.__PVT__u_core__DOT__ras_push) {
            __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2 
                = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
            __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2 
                = vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr;
            __VdlySet__u_core__DOT__u_ras__DOT__stack__v2 = 1U;
            __Vdly__u_core__DOT__u_ras__DOT__ptr = 
                (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr)));
        } else if (vlSelfRef.__PVT__u_core__DOT__ras_pop) {
            if ((0U != (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))) {
                __Vdly__u_core__DOT__u_ras__DOT__ptr 
                    = (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                             - (IData)(1U)));
            }
        }
        if (vlSelfRef.__PVT__i_busy) {
            __Vdly__i_busy = 0U;
        }
        if (vlSelfRef.__PVT__d_busy) {
            vlSelfRef.__PVT__d_busy = 0U;
        }
        if (vlSelfRef.__PVT__u_core__DOT__bp_upd_valid) {
            __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0 
                = (1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way)));
            __VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0 
                = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                  >> 1U));
            __VdlySet__u_core__DOT__u_bp__DOT__lru__v0 = 1U;
            if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way)))) {
                __VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0 
                    = vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__cnt_next;
                __VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0 
                    = (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                       >> 6U);
                __VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_target_r;
                __VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__target0__v0 = 1U;
            }
            if (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way) {
                __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0 
                    = vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__cnt_next;
                __VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0 = 1U;
                __VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0 
                    = (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                       >> 6U);
                __VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_target_r;
                __VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__target1__v0 = 1U;
            }
        }
        if (((IData)(vlSelfRef.u_core__DOT__rfu_we) 
             & (0U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r)))) {
            __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0 
                = vlSelfRef.u_core__DOT__rfu_wr_data;
            __VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0 
                = vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r;
            __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0 = 1U;
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_csr_we) {
            if ((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie 
                    = (1U & (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                             >> 3U));
            }
            if ((0x0300U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                if ((0x0304U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                    if ((0x0305U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                        if ((0x0340U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch 
                                = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
                        }
                    }
                    if ((0x0305U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                            = (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                               >> 2U);
                    }
                }
                if ((0x0304U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie 
                        = (1U & (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                                 >> 0x0bU));
                }
            }
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_trap_enter) {
            __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = 0U;
        } else if (vlSelfRef.__PVT__u_core__DOT__wb_trap_exit) {
            __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie 
                = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie;
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_csr_we) {
            if ((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie 
                    = (1U & (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                             >> 7U));
            }
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_trap_enter) {
            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie 
                = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie;
        } else if (vlSelfRef.__PVT__u_core__DOT__wb_trap_exit) {
            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            if (vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) {
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_addr_lo_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_ls_funct3_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_md_result_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_md_result_r;
            }
            vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r));
        }
        if (vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_taken_r 
                = vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r = 1U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_target_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wdata_r 
                = ((0U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) ? 
                   ((vlSelfRef.__PVT__u_core__DOT__rs2_val 
                     << 0x00000018U) | ((0x00ff0000U 
                                         & (vlSelfRef.__PVT__u_core__DOT__rs2_val 
                                            << 0x00000010U)) 
                                        | ((0x0000ff00U 
                                            & (vlSelfRef.__PVT__u_core__DOT__rs2_val 
                                               << 8U)) 
                                           | (0x000000ffU 
                                              & vlSelfRef.__PVT__u_core__DOT__rs2_val))))
                    : ((1U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))
                        ? ((vlSelfRef.__PVT__u_core__DOT__rs2_val 
                            << 0x00000010U) | (0x0000ffffU 
                                               & vlSelfRef.__PVT__u_core__DOT__rs2_val))
                        : vlSelfRef.__PVT__u_core__DOT__rs2_val));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r 
                = (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r 
                = (3U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r 
                = (((0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                    & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9) 
                       & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15)))
                    ? (((0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                        & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                           & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid)))
                        ? (0x0000000fU & ((0U == (7U 
                                                  & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x0000000cU)))
                                           ? ((IData)(1U) 
                                              << (IData)(vlSelfRef.__PVT__u_core__DOT__store_addr_lo))
                                           : ((1U == 
                                               (7U 
                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x0000000cU)))
                                               ? ((IData)(3U) 
                                                  << 
                                                  (2U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__store_addr_lo)))
                                               : ((2U 
                                                   == 
                                                   (7U 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x0000000cU)))
                                                   ? 0x0fU
                                                   : 0U))))
                        : 0U) : 0U);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                   & (((0x63U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                       | (0x6fU == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) 
                      & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                         & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                   & (((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken) 
                       != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken)) 
                      | ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras) 
                                | (vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target 
                                   == ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr)
                                        ? (0xfffffffeU 
                                           & vlSelfRef.__PVT__u_core__DOT__alu_result)
                                        : vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm)))) 
                            & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken) 
                               & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken))))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_target_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r 
                = vlSelfRef.__PVT__u_core__DOT__id_csr_wdata;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_addr_lo_r 
                = (3U & vlSelfRef.__PVT__u_core__DOT__alu_result);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r 
                = vlSelfRef.__PVT__u_core__DOT__id_wb_sel;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r 
                = vlSelfRef.__PVT__u_core__DOT__id_csr_rdata;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r 
                = (3U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000cU));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_ls_funct3_r 
                = (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000cU));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr) 
                   & ((1U == (3U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                    >> 0x0000000cU))) 
                      | (0U != vlSelfRef.__PVT__u_core__DOT__id_csr_wdata)));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r 
                = (0x30200073U == vlSelfRef.__PVT__u_core__DOT__if_ex_instr);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r 
                = ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9) 
                   & (((1U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))
                        ? vlSelfRef.__PVT__u_core__DOT__alu_result
                        : (IData)(((0x00002000U == 
                                    (0x00007000U & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                   & (0U != (3U & vlSelfRef.__PVT__u_core__DOT__alu_result))))) 
                      & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15)));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r 
                = ((0x33U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                   | ((0x13U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                      | ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
                         | ((0x6fU == (0x0000007fU 
                                       & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                            | ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                               | ((3U == (0x0000007fU 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                  | (IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr)))))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_md_result_r 
                = vlSelfRef.__PVT__u_core__DOT__md_result_q;
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r = 0U;
        }
        if ((((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
              | (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_valid = 0U;
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit 
                = vlSelfRef.__PVT__u_core__DOT__is_16bit_w;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target 
                = vlSelfRef.__PVT__u_core__DOT__ras_top;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras 
                = vlSelfRef.__PVT__u_core__DOT__ras_pop;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken) 
                   | (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop));
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop)
                    ? vlSelfRef.__PVT__u_core__DOT__ras_top
                    : vlSelfRef.__PVT__u_core__DOT__bp_predict_target);
            vlSelfRef.__PVT__u_core__DOT__if_ex_valid = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))) {
            if (vlSelfRef.__PVT__u_core__DOT__md_done) {
                vlSelfRef.__PVT__u_core__DOT__md_result_q 
                    = ((IData)(vlSelfRef.__PVT__u_core__DOT__md_active_is_div)
                        ? vlSelfRef.__PVT__u_core__DOT__div_result
                        : vlSelfRef.__PVT__u_core__DOT__mul_result);
            }
        }
        vlSelfRef.__PVT__u_core__DOT__mul_done = 0U;
        if (vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending) {
            vlSelfRef.__PVT__u_core__DOT__mul_done = 1U;
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending = 0U;
        } else if ((((~ (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000eU)) & (IData)(vlSelfRef.__PVT__u_core__DOT__md_start)) 
                    & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy)))) {
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opa_r 
                = ((3U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) ? (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs1_val))
                    : (((QData)((IData)((vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                         >> 0x0000001fU))) 
                        << 0x00000020U) | (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs1_val))));
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opb_r 
                = (((3U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                  >> 0x0000000cU))) 
                    | (2U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                    >> 0x0000000cU))))
                    ? (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs2_val))
                    : (((QData)((IData)((vlSelfRef.__PVT__u_core__DOT__rs2_val 
                                         >> 0x0000001fU))) 
                        << 0x00000020U) | (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs2_val))));
            __Vdly__u_core__DOT__u_mul__DOT__high_out 
                = (0U != (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                >> 0x0000000cU)));
            __Vdly__u_core__DOT__u_mul__DOT__busy = 1U;
        } else if (vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy) {
            vlSelfRef.__PVT__u_core__DOT__mul_result 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__high_out)
                    ? vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[1U]
                    : vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[0U]);
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending = 1U;
            __Vdly__u_core__DOT__u_mul__DOT__busy = 0U;
        }
        vlSelfRef.__PVT__u_core__DOT__div_done = 0U;
        if ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state))) {
            if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state))) {
                vlSelfRef.__PVT__u_core__DOT__div_done = 1U;
                __Vdly__u_core__DOT__u_div__DOT__state = 0U;
            } else {
                vlSelfRef.__PVT__u_core__DOT__div_result 
                    = ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__div_by_zero)
                        ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem)
                            ? vlSelfRef.__PVT__u_core__DOT__u_div__DOT__orig_a
                            : 0xffffffffU) : ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__overflow)
                                               ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem)
                                                   ? 0U
                                                   : 0x80000000U)
                                               : ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem)
                                                   ? 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_rem)
                                                    ? 
                                                   (- vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)
                                                    : vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)
                                                   : 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_quot)
                                                    ? 
                                                   (- vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient)
                                                    : vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient))));
                __Vdly__u_core__DOT__u_div__DOT__state = 3U;
            }
        } else if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state))) {
            __Vdly__u_core__DOT__u_div__DOT__iter = 
                (0x0000003fU & ((IData)(1U) + (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter)));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                = (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                   << 1U);
            if ((1U & (IData)((vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w 
                               >> 0x00000020U)))) {
                __Vdly__u_core__DOT__u_div__DOT__quotient 
                    = (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient 
                       << 1U);
                vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder 
                    = (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem);
            } else {
                __Vdly__u_core__DOT__u_div__DOT__quotient 
                    = (1U | (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient 
                             << 1U));
                vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder 
                    = (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w);
            }
            if ((0x1fU == (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter))) {
                __Vdly__u_core__DOT__u_div__DOT__state = 2U;
            }
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__md_start) 
                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                       >> 0x0000000eU))) {
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                = ((((4U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))) 
                     | (6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))) 
                    & (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                       >> 0x1fU)) ? (- vlSelfRef.__PVT__u_core__DOT__rs1_val)
                    : vlSelfRef.__PVT__u_core__DOT__rs1_val);
            __Vdly__u_core__DOT__u_div__DOT__quotient = 0U;
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__orig_a 
                = vlSelfRef.__PVT__u_core__DOT__rs1_val;
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem 
                = ((6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) 
                   | (7U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__div_by_zero 
                = (0U == vlSelfRef.__PVT__u_core__DOT__rs2_val);
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__overflow 
                = ((((4U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))) 
                     | (6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))) 
                    & (0x80000000U == vlSelfRef.__PVT__u_core__DOT__rs1_val)) 
                   & (0xffffffffU == vlSelfRef.__PVT__u_core__DOT__rs2_val));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__divisor 
                = ((((4U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))) 
                     | (6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))) 
                    & (vlSelfRef.__PVT__u_core__DOT__rs2_val 
                       >> 0x1fU)) ? (- vlSelfRef.__PVT__u_core__DOT__rs2_val)
                    : vlSelfRef.__PVT__u_core__DOT__rs2_val);
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_quot 
                = (IData)(((0x00004000U == (0x00007000U 
                                            & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                           & (((vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                ^ vlSelfRef.__PVT__u_core__DOT__rs2_val) 
                               >> 0x1fU) & (0U != vlSelfRef.__PVT__u_core__DOT__rs2_val))));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_rem 
                = (IData)(((0x00006000U == (0x00007000U 
                                            & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                           & (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                              >> 0x0000001fU)));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder = 0U;
            __Vdly__u_core__DOT__u_div__DOT__iter = 0U;
            __Vdly__u_core__DOT__u_div__DOT__state = 1U;
        }
        if (vlSelfRef.__PVT__u_core__DOT__pc_redirect) {
            vlSelfRef.__PVT__u_core__DOT__md_started = 0U;
            __Vdly__u_core__DOT__md_result_valid = 0U;
        } else if (vlSelfRef.__PVT__u_core__DOT__md_done) {
            vlSelfRef.__PVT__u_core__DOT__md_started = 0U;
            __Vdly__u_core__DOT__md_result_valid = 1U;
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid))) {
            __Vdly__u_core__DOT__md_result_valid = 0U;
        } else if (vlSelfRef.__PVT__u_core__DOT__md_start) {
            vlSelfRef.__PVT__u_core__DOT__md_started = 1U;
            vlSelfRef.__PVT__u_core__DOT__md_active_is_div 
                = (1U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000eU));
        }
    } else {
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt = 0ULL;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt = 0ULL;
        __Vdly__u_core__DOT__u_ras__DOT__ptr = 0U;
        __VdlySet__u_core__DOT__u_ras__DOT__stack__v3 = 1U;
        __Vdly__i_busy = 0U;
        vlSelfRef.__PVT__d_busy = 0U;
        __VdlySet__u_core__DOT__u_bp__DOT__lru__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__target0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__target1__v1 = 1U;
        __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1 = 1U;
        __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_md_result_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_valid = 0U;
        vlSelfRef.__PVT__u_core__DOT__md_result_q = 0U;
        __Vdly__u_core__DOT__u_mul__DOT__busy = 0U;
        vlSelfRef.__PVT__u_core__DOT__mul_done = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending = 0U;
        __Vdly__u_core__DOT__u_mul__DOT__high_out = 0U;
        __Vdly__u_core__DOT__u_div__DOT__state = 0U;
        vlSelfRef.__PVT__u_core__DOT__div_done = 0U;
        vlSelfRef.__PVT__u_core__DOT__md_started = 0U;
        vlSelfRef.__PVT__u_core__DOT__md_active_is_div = 0U;
        __Vdly__u_core__DOT__md_result_valid = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending 
        = ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn) 
           && ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_trap_enter)) 
               & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending)));
    if (vlSelfRef.__PVT__d_xfer) {
        vlSelfRef.__PVT__d_rdata_q = vlSymsp->TOP.tb_axil_equiv__DOT__native_mem
            [vlSymsp->TOP.tb_axil_equiv__DOT__n_didx];
    }
    if ((1U & ((~ (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn)) 
               | (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 0U;
        vlSelfRef.__PVT__u_core__DOT__residue = 0U;
    } else if (vlSelfRef.__PVT__u_core__DOT__consecutive_cross) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 1U;
        vlSelfRef.__PVT__u_core__DOT__residue = (vlSelfRef.__PVT__i_rdata_q 
                                                 >> 0x00000010U);
    } else if (vlSelfRef.__PVT__u_core__DOT__upcoming_cross) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 1U;
        vlSelfRef.__PVT__u_core__DOT__residue = (vlSelfRef.__PVT__i_rdata_q 
                                                 >> 0x00000010U);
    } else if ((((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup))) 
                & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 1U;
        vlSelfRef.__PVT__u_core__DOT__residue = (vlSelfRef.__PVT__i_rdata_q 
                                                 >> 0x00000010U);
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)))) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr = __Vdly__u_core__DOT__u_ras__DOT__ptr;
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[__VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0] 
            = __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0;
    }
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[0U] 
            = __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1;
    }
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v2) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[__VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2] 
            = __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2;
    }
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v3) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[7U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__lru__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[__VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__lru__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[__VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[__VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[0U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[1U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[2U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[3U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[4U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[5U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[6U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[7U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[8U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[9U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[10U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[11U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[12U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[13U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[14U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[15U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[16U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[17U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[18U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[19U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[20U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[21U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[22U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[23U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[24U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[25U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[26U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[27U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[28U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[29U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[30U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[31U] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[__VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[0U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[1U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[2U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[3U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[4U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[5U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[6U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[7U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[8U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[9U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[10U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[11U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[12U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[13U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[14U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[15U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[16U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[17U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[18U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[19U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[20U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[21U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[22U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[23U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[24U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[25U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[26U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[27U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[28U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[29U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[30U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[31U] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[__VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[__VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[__VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[__VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[__VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_rfu__DOT__regs__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[__VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0] 
            = __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0;
    }
    if (__VdlySet__u_core__DOT__u_rfu__DOT__regs__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[0U] = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__top_idx 
        = (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                 - (IData)(1U)));
    if ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r))) {
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel 
            = (0x000000ffU & ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r))
                               ? (vlSelfRef.__PVT__d_rdata_q 
                                  >> 0x00000018U) : 
                              (vlSelfRef.__PVT__d_rdata_q 
                               >> 0x00000010U)));
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel 
            = (0x0000ffffU & (vlSelfRef.__PVT__d_rdata_q 
                              >> 0x00000010U));
    } else {
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel 
            = (0x000000ffU & ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r))
                               ? (vlSelfRef.__PVT__d_rdata_q 
                                  >> 8U) : vlSelfRef.__PVT__d_rdata_q));
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel 
            = (0x0000ffffU & vlSelfRef.__PVT__d_rdata_q);
    }
    if ((1U & ((~ (IData)(vlSelfRef.__PVT__primed)) 
               | ((IData)(vlSelfRef.__PVT__i_fire) 
                  | (IData)(vlSelfRef.__PVT__i_busy))))) {
        vlSelfRef.__PVT__i_rdata_q = vlSymsp->TOP.tb_axil_equiv__DOT__native_mem
            [(0x0007ffffU & (((IData)(vlSelfRef.__PVT__primed)
                               ? ((IData)(vlSelfRef.__PVT__i_busy)
                                   ? vlSelfRef.__PVT__i_addr_q
                                   : vlSelfRef.__PVT__core_i_mem_addr)
                               : 0U) >> 2U))];
    }
    if ((1U & (~ (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn)))) {
        vlSelfRef.__PVT__d_addr_q = 0U;
        vlSelfRef.__PVT__d_wdata_q = 0U;
        vlSelfRef.__PVT__d_wstrb_q = 0U;
        vlSelfRef.__PVT__i_addr_q = 0U;
        vlSelfRef.__PVT__primed = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie 
        = __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie;
    vlSelfRef.__PVT__i_busy = __Vdly__i_busy;
    vlSelfRef.__PVT__u_core__DOT__ras_top = ((0U == (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))
                                              ? 0U : vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack
                                             [(7U & 
                                               ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                                                - (IData)(1U)))]);
    __PVT__u_core__DOT__u_bp__DOT__wr_hit0 = (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0
                                              [(0x0000001fU 
                                                & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                   >> 1U))] 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                      >> 1U))] 
                                                 == 
                                                 (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                  >> 6U)));
    __PVT__u_core__DOT__u_bp__DOT__wr_hit1 = (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1
                                              [(0x0000001fU 
                                                & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                   >> 1U))] 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                      >> 1U))] 
                                                 == 
                                                 (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                  >> 6U)));
    if (vlSelfRef.__PVT__i_boot) {
        vlSelfRef.__PVT__primed = 1U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way 
        = ((IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit1) 
           | ((~ (IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit0)) 
              & vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru
              [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                               >> 1U))]));
    __Vtableidx3 = (((((IData)(vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way)
                        ? vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1
                       [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                        >> 1U))] : vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0
                       [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                        >> 1U))]) << 3U) 
                     | ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_taken_r) 
                        << 2U)) | (((IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit1) 
                                    << 1U) | (IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit0)));
    vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__cnt_next 
        = Vtb_axil_equiv__ConstPool__TABLE_hdb09954d_0
        [__Vtableidx3];
    vlSelfRef.__PVT__i_boot = (1U & (~ (IData)(vlSelfRef.__PVT__primed)));
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__high_out 
        = __Vdly__u_core__DOT__u_mul__DOT__high_out;
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy 
        = __Vdly__u_core__DOT__u_mul__DOT__busy;
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state 
        = __Vdly__u_core__DOT__u_div__DOT__state;
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter 
        = __Vdly__u_core__DOT__u_div__DOT__iter;
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient 
        = __Vdly__u_core__DOT__u_div__DOT__quotient;
    vlSelfRef.__PVT__u_core__DOT__md_result_valid = __Vdly__u_core__DOT__md_result_valid;
    VL_EXTENDS_WQ(66,33, __Vtemp_3, vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opa_r);
    __Vtemp_4[0U] = __Vtemp_3[0U];
    __Vtemp_4[1U] = __Vtemp_3[1U];
    __Vtemp_4[2U] = (3U & __Vtemp_3[2U]);
    VL_EXTENDS_WQ(66,33, __Vtemp_6, vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opb_r);
    __Vtemp_7[0U] = __Vtemp_6[0U];
    __Vtemp_7[1U] = __Vtemp_6[1U];
    __Vtemp_7[2U] = (3U & __Vtemp_6[2U]);
    VL_MULS_WWW(66, __Vtemp_8, __Vtemp_4, __Vtemp_7);
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[0U] 
        = __Vtemp_8[0U];
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[1U] 
        = __Vtemp_8[1U];
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[2U] 
        = (3U & __Vtemp_8[2U]);
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
        = (((QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)) 
            << 1U) | (QData)((IData)((vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                                      >> 0x0000001fU))));
    vlSelfRef.__PVT__u_core__DOT__md_done = ((IData)(vlSelfRef.__PVT__u_core__DOT__md_active_is_div)
                                              ? (IData)(vlSelfRef.__PVT__u_core__DOT__div_done)
                                              : (IData)(vlSelfRef.__PVT__u_core__DOT__mul_done));
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w 
        = (0x00000001ffffffffULL & (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
                                    - (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__divisor))));
}

extern const VlUnpacked<CData/*2:0*/, 64> Vtb_axil_equiv__ConstPool__TABLE_hde2d3e75_0;

void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__1(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__1\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__d_fire;
    __PVT__d_fire = 0;
    IData/*31:0*/ __PVT__u_core__DOT__redirect_target;
    __PVT__u_core__DOT__redirect_target = 0;
    IData/*31:0*/ __PVT__u_core__DOT__id_imm;
    __PVT__u_core__DOT__id_imm = 0;
    CData/*3:0*/ __PVT__u_core__DOT__id_alu_op;
    __PVT__u_core__DOT__id_alu_op = 0;
    CData/*0:0*/ __PVT__u_core__DOT__id_is_muldiv;
    __PVT__u_core__DOT__id_is_muldiv = 0;
    IData/*31:0*/ __PVT__u_core__DOT__ex_mem_fwd_val;
    __PVT__u_core__DOT__ex_mem_fwd_val = 0;
    IData/*31:0*/ __PVT__u_core__DOT__alu_op_b;
    __PVT__u_core__DOT__alu_op_b = 0;
    CData/*0:0*/ __PVT__u_core__DOT__alu_cmp_eq;
    __PVT__u_core__DOT__alu_cmp_eq = 0;
    CData/*0:0*/ __PVT__u_core__DOT__alu_cmp_lt_s;
    __PVT__u_core__DOT__alu_cmp_lt_s = 0;
    CData/*0:0*/ __PVT__u_core__DOT__alu_cmp_lt_u;
    __PVT__u_core__DOT__alu_cmp_lt_u = 0;
    IData/*31:0*/ __PVT__u_core__DOT__csr_rdata;
    __PVT__u_core__DOT__csr_rdata = 0;
    CData/*0:0*/ __PVT__u_core__DOT__wb_take_irq;
    __PVT__u_core__DOT__wb_take_irq = 0;
    CData/*0:0*/ u_core__DOT____VdfgExtracted_ha4e5ab41__0;
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_13;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_18;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 0;
    SData/*11:0*/ __PVT__u_core__DOT__u_cdec__DOT__imm_addi;
    __PVT__u_core__DOT__u_cdec__DOT__imm_addi = 0;
    IData/*31:0*/ u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0;
    u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 = 0;
    IData/*19:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6 = 0;
    CData/*5:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7 = 0;
    SData/*11:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9 = 0;
    SData/*9:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__rd_hit1;
    __PVT__u_core__DOT__u_bp__DOT__rd_hit1 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok;
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1;
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2;
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok;
    __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_0;
    __VdfgRegularize_h98839c81_1_0 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_1;
    __VdfgRegularize_h98839c81_1_1 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_3;
    __VdfgRegularize_h98839c81_1_3 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_4;
    __VdfgRegularize_h98839c81_1_4 = 0;
    CData/*5:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val 
        = (0x00001800U | (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie) 
                           << 7U) | ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie) 
                                     << 3U)));
    if (vlSymsp->TOP.tb_axil_equiv__DOT__resetn) {
        if (vlSelfRef.__PVT__u_core__DOT__wb_csr_we) {
            if ((0x0300U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                if ((0x0304U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                    if ((0x0305U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                        if ((0x0340U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                            if ((0x0341U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                if ((0x0342U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg 
                                        = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
                                }
                                if ((0x0342U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                    if ((0x0343U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                        vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                                            = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
                                    }
                                }
                            }
                            if ((0x0341U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg 
                                    = (0xfffffffeU 
                                       & vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val);
                            }
                        }
                    }
                }
            }
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_trap_enter) {
            if (vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap) {
                if (vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ecall_r) {
                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 0x0000000bU;
                    vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg = 0U;
                } else if (vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ebreak_r) {
                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 3U;
                    vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                        = vlSelfRef.u_core__DOT__ex_wb_pc_r;
                } else {
                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 2U;
                    vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                        = vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r;
                }
            } else {
                vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg 
                    = ((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)
                        ? ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_store_r)
                            ? 6U : 4U) : 0x8000000bU);
                vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                    = vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r;
            }
            vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg 
                = (((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap) 
                    | (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap))
                    ? vlSelfRef.u_core__DOT__ex_wb_pc_r
                    : ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_branch_taken_r)
                        ? vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r
                        : ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jal_r)
                            ? vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r
                            : ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jalr_r)
                                ? (0xfffffffeU & vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r)
                                : vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r))));
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            vlSelfRef.u_core__DOT__ex_wb_valid_r = vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb;
            vlSelfRef.u_core__DOT__ex_wb_illegal_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r));
            if (vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) {
                vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r;
                vlSelfRef.u_core__DOT__ex_wb_pc_r = vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r;
            } else {
                vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r = 0U;
            }
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_store_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_branch_taken_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jalr_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jal_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ecall_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ebreak_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r));
        }
        if (vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r 
                = (1U & (~ ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
                            | ((0x6fU == (0x0000007fU 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                               | (((0x63U == (0x0000007fU 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                   & ((0U == (7U & 
                                              (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x0000000cU))) 
                                      | ((1U == (7U 
                                                 & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x0000000cU))) 
                                         | ((4U == 
                                             (7U & 
                                              (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x0000000cU))) 
                                            | ((5U 
                                                == 
                                                (7U 
                                                 & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x0000000cU))) 
                                               | ((6U 
                                                   == 
                                                   (7U 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x0000000cU))) 
                                                  | (7U 
                                                     == 
                                                     (7U 
                                                      & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                         >> 0x0000000cU))))))))) 
                                  | ((3U == (0x0000007fU 
                                             & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                     | ((0x23U == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                        | ((0x13U == 
                                            (0x0000007fU 
                                             & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                           | ((0x33U 
                                               == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                              | ((0x0fU 
                                                  == 
                                                  (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                 | ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                                                    | ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr) 
                                                       | (0x30200073U 
                                                          == vlSelfRef.__PVT__u_core__DOT__if_ex_instr)))))))))))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r 
                = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                  >> 7U));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r 
                = (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r 
                = vlSelfRef.__PVT__u_core__DOT__branch_taken;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r 
                = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r 
                = vlSelfRef.__PVT__u_core__DOT__id_is_jalr;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r 
                = (0x6fU == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r 
                = vlSelfRef.__PVT__u_core__DOT__alu_result;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r 
                = (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                   >> 0x00000014U);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_instr;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r 
                = (0x00000073U == vlSelfRef.__PVT__u_core__DOT__if_ex_instr);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r 
                = (0x00100073U == vlSelfRef.__PVT__u_core__DOT__if_ex_instr);
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r = 0U;
        }
        if ((((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
              | (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_pc = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_instr = 0U;
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_pc 
                = vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg;
            vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                = vlSelfRef.__PVT__u_core__DOT__instr_assembled;
        }
        vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
            = vlSelfRef.__PVT__u_core__DOT__next_pc_w;
    } else {
        vlSelfRef.u_core__DOT__ex_wb_valid_r = 0U;
        vlSelfRef.u_core__DOT__ex_wb_illegal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r = 0U;
        vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 0U;
        vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg = 0U;
        vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_store_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_branch_taken_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jalr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r = 0U;
        vlSelfRef.u_core__DOT__ex_wb_pc_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ecall_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ebreak_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pc = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_instr = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
        = ((1U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r))
            ? vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r
            : ((2U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r))
                ? (vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r 
                   | vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r)
                : ((3U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r))
                    ? ((~ vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r) 
                       & vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r)
                    : vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r)));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap 
        = ((IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 
        ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
            & (0U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))));
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r) 
         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                | (0U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r)))) 
            & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)));
    vlSelfRef.u_core__DOT__rfu_wr_data = ((4U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                           ? ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                               ? vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_wb_md_result_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r))
                                           : ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                               ? ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                                   ? 
                                                  ((4U 
                                                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                    ? 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                     ? vlSelfRef.__PVT__d_rdata_q
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                      ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel)
                                                      : (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel)))
                                                    : 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                     ? vlSelfRef.__PVT__d_rdata_q
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                      ? 
                                                     (((- (IData)(
                                                                  (1U 
                                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel) 
                                                                      >> 0x0000000fU)))) 
                                                       << 0x00000010U) 
                                                      | (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel))
                                                      : 
                                                     (((- (IData)(
                                                                  (1U 
                                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel) 
                                                                      >> 7U)))) 
                                                       << 8U) 
                                                      | (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel)))))
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r)
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r)));
    vlSelfRef.__PVT__mem_stall = (((IData)(vlSelfRef.__PVT__i_busy) 
                                   | ((~ (IData)(vlSelfRef.__PVT__primed)) 
                                      | (IData)(vlSelfRef.__PVT__d_busy))) 
                                  & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn));
    __PVT__u_core__DOT__ex_mem_fwd_val = ((4U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                           ? ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                               ? vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_mem_md_result_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r))
                                           : ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                               ? ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r)
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r)));
    vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r) 
              & ((0xfffffffeU & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                 != vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_target_r)));
    vlSelfRef.__PVT__u_core__DOT__bp_upd_valid = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_trap_exit = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    __PVT__u_core__DOT__wb_take_irq = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                       & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                          & (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                                             & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13))));
    vlSelfRef.__PVT__u_core__DOT__ras_push_val = (vlSelfRef.__PVT__u_core__DOT__if_ex_pc 
                                                  + 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit)
                                                    ? 2U
                                                    : 4U));
    vlSelfRef.u_core__DOT__rfu_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
                                     & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                        & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                           & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                              & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13)))));
    vlSelfRef.u_core__DOT__wb_instr_retired = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
                                                     & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    vlSelfRef.__PVT__u_core__DOT__wb_csr_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                                     & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = ((IData)(__PVT__u_core__DOT__wb_take_irq) 
                                                 | ((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap) 
                                                    | (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)));
    vlSelfRef.__PVT__u_core__DOT__warmup = (1U & (~ (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn)));
    vlSelfRef.__PVT__u_core__DOT__redirect_warmup = 
        ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn) 
         & (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9 
        = ((3U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __PVT__u_core__DOT__id_alu_op = 0U;
    if ((0x13U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = ((0x00004000U 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                          ? ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 2U
                                                  : 3U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 
                                                 ((0x40000000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 7U
                                                   : 6U)
                                                  : 4U))
                                          : ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 9U
                                                  : 8U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 5U
                                                  : 0U)));
    } else if ((0x33U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = ((0x00004000U 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                          ? ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 2U
                                                  : 3U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 
                                                 ((0x40000000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 7U
                                                   : 6U)
                                                  : 4U))
                                          : ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 9U
                                                  : 8U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 5U
                                                  : 
                                                 ((0x40000000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 1U
                                                   : 0U))));
    } else if ((0x63U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = ((0x00004000U 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                          ? ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? 9U : 8U)
                                          : 0x0aU);
    } else if ((0x37U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = 0x0bU;
    }
    vlSelfRef.__PVT__u_core__DOT__id_is_csr = ((0x73U 
                                                == 
                                                (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                               & (0U 
                                                  != 
                                                  (7U 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x0000000cU))));
    vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 
        = ((0x37U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x17U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    vlSelfRef.__PVT__u_core__DOT__id_is_jalr = (IData)(
                                                       (0x00000067U 
                                                        == 
                                                        (0x0000707fU 
                                                         & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __VdfgRegularize_h98839c81_1_4 = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r) 
                                      == (0x0000001fU 
                                          & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                             >> 0x00000014U)));
    __VdfgRegularize_h98839c81_1_3 = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r) 
                                      == (0x0000001fU 
                                          & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                             >> 0x0000000fU)));
    __PVT__u_core__DOT__id_is_muldiv = (IData)((0x02000033U 
                                                == 
                                                (0xfe00007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __PVT__u_core__DOT__csr_rdata = (((((((((0x0300U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U)) 
                                            | (0x0304U 
                                               == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))) 
                                           | (0x0305U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))) 
                                          | (0x0340U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U))) 
                                         | (0x0341U 
                                            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                >> 0x00000014U))) 
                                        | (0x0342U 
                                           == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x00000014U))) 
                                       | (0x0343U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))) 
                                      | (0x0344U == 
                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                          >> 0x00000014U)))
                                      ? ((0x0300U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val
                                          : ((0x0304U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 << 0x0000000bU)
                                              : ((0x0305U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? 
                                                 (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                  << 2U)
                                                  : 
                                                 ((0x0340U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch
                                                   : 
                                                  ((0x0341U 
                                                    == 
                                                    (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))
                                                    ? vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg
                                                    : 
                                                   ((0x0342U 
                                                     == 
                                                     (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))
                                                     ? vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg
                                                     : 
                                                    ((0x0343U 
                                                      == 
                                                      (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U))
                                                      ? vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg
                                                      : 
                                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                                      << 0x0000000bU))))))))
                                      : ((0x0c00U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt)
                                          : ((0x0c80U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? (IData)(
                                                        (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt 
                                                         >> 0x20U))
                                              : ((0x0c02U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt)
                                                  : 
                                                 ((0x0c82U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? (IData)(
                                                             (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt 
                                                              >> 0x20U))
                                                   : 0U)))));
    if (((IData)(vlSelfRef.__PVT__u_core__DOT__wb_csr_we) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r) 
            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                >> 0x00000014U)))) {
        if ((((((((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)) 
                  || (0x0304U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                 || (0x0305U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                || (0x0340U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
               || (0x0341U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
              || (0x0342U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
             || (0x0343U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)))) {
            __PVT__u_core__DOT__csr_rdata = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
        }
    }
    vlSelfRef.__PVT__u_core__DOT__wb_trap_enter = (
                                                   (~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                   & (IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0));
    vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb 
        = ((~ ((IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0) 
               | (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14))) 
           & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r));
    __PVT__u_core__DOT__redirect_target = 0U;
    vlSelfRef.__PVT__u_core__DOT__pc_redirect = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
        if (u_core__DOT____VdfgExtracted_ha4e5ab41__0) {
            __PVT__u_core__DOT__redirect_target = (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                   << 2U);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r))) {
            __PVT__u_core__DOT__redirect_target = vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict) {
            __PVT__u_core__DOT__redirect_target = (0xfffffffeU 
                                                   & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r))) {
            __PVT__u_core__DOT__redirect_target = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r)
                                                    ? 
                                                   (0xfffffffeU 
                                                    & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r)
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r)
                                                      ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r)));
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        }
    }
    __VdfgRegularize_h98839c81_1_1 = ((0x6fU == (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                      | (IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr));
    __PVT__u_core__DOT__id_imm = ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5)
                                   ? (0xfffff000U & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                   : ((0x6fU == (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))
                                       ? ((((0x00000ffeU 
                                             & ((- (IData)(
                                                           (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000001fU))) 
                                                << 1U)) 
                                            | (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x0000001fU)) 
                                           << 0x00000014U) 
                                          | ((((0x000001feU 
                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x0000000bU)) 
                                               | (1U 
                                                  & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))) 
                                              << 0x0000000bU) 
                                             | (0x000007feU 
                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))))
                                       : (((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                                           | ((3U == 
                                               (0x0000007fU 
                                                & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                              | (0x13U 
                                                 == 
                                                 (0x0000007fU 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))))
                                           ? (((- (IData)(
                                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                           >> 0x0000001fU))) 
                                               << 0x0000000cU) 
                                              | (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U))
                                           : ((0x23U 
                                               == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))
                                               ? ((
                                                   (- (IData)(
                                                              (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                               >> 0x0000001fU))) 
                                                   << 0x0000000cU) 
                                                  | ((0x00000fe0U 
                                                      & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                         >> 0x00000014U)) 
                                                     | (0x0000001fU 
                                                        & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                           >> 7U))))
                                               : ((0x63U 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))
                                                   ? 
                                                  (((- (IData)(
                                                               (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                                >> 0x0000001fU))) 
                                                    << 0x0000000dU) 
                                                   | ((((2U 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000001eU)) 
                                                        | (1U 
                                                           & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                              >> 7U))) 
                                                       << 0x0000000bU) 
                                                      | ((0x000007e0U 
                                                          & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                             >> 0x00000014U)) 
                                                         | (0x0000001eU 
                                                            & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                               >> 7U)))))
                                                   : 0U)))));
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2 
        = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_ok) 
           & (IData)(__VdfgRegularize_h98839c81_1_4));
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1 
        = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_ok) 
           & (IData)(__VdfgRegularize_h98839c81_1_3));
    __Vtableidx1 = ((((IData)(__PVT__u_core__DOT__id_is_muldiv) 
                      << 5U) | (((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr) 
                                 << 4U) | ((3U == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                           << 3U))) 
                    | (((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                        << 2U) | (((0x6fU == (0x0000007fU 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                   << 1U) | (0x17U 
                                             == (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)))));
    vlSelfRef.__PVT__u_core__DOT__id_wb_sel = Vtb_axil_equiv__ConstPool__TABLE_hde2d3e75_0
        [__Vtableidx1];
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17 
        = ((IData)(__PVT__u_core__DOT__id_is_muldiv) 
           & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid));
    __PVT__u_core__DOT__u_bp__DOT__rd_hit1 = (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1
                                              [(0x0000001fU 
                                                & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                   >> 1U))] 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                      >> 1U))] 
                                                 == 
                                                 (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                  >> 6U)));
    vlSelfRef.__PVT__u_core__DOT__is_16bit_w = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble)) 
                                                & ((2U 
                                                    & vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                    ? 
                                                   (3U 
                                                    != 
                                                    (3U 
                                                     & (vlSelfRef.__PVT__i_rdata_q 
                                                        >> 0x00000010U)))
                                                    : 
                                                   (3U 
                                                    != 
                                                    (3U 
                                                     & vlSelfRef.__PVT__i_rdata_q))));
    vlSelfRef.__PVT__u_core__DOT__cinstr = (0x0000ffffU 
                                            & ((2U 
                                                & vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                ? (vlSelfRef.__PVT__i_rdata_q 
                                                   >> 0x00000010U)
                                                : vlSelfRef.__PVT__i_rdata_q));
    vlSelfRef.__PVT__u_core__DOT__id_csr_rdata = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r) 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r) 
                                                         == 
                                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                          >> 0x00000014U))))
                                                   ? 
                                                  ((1U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                    ? vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r
                                                    : 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                     ? 
                                                    (vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r 
                                                     | vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r)
                                                     : 
                                                    ((3U 
                                                      == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                      ? 
                                                     ((~ vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r) 
                                                      & vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)))
                                                   : __PVT__u_core__DOT__csr_rdata);
    vlSelfRef.__PVT__core_d_mem_wstrb = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r) 
                                          & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                             & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r)
                                          : 0U);
    __PVT__d_fire = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                      & (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                          | (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r)) 
                         & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                            & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r))))) 
                     & ((~ (IData)(vlSelfRef.__PVT__d_busy)) 
                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
    vlSelfRef.__PVT__u_core__DOT__at_cross_boundary 
        = (IData)(((((0x00030000U == (0x00030000U & vlSelfRef.__PVT__i_rdata_q)) 
                     & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                        >> 1U)) & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
    vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm 
        = (__PVT__u_core__DOT__id_imm + vlSelfRef.__PVT__u_core__DOT__if_ex_pc);
    vlSelfRef.__PVT__u_core__DOT__rs2_val = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2)
                                              ? __PVT__u_core__DOT__ex_mem_fwd_val
                                              : (((IData)(__PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok) 
                                                  & ((~ (IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2)) 
                                                     & ((0x0000001fU 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x00000014U)) 
                                                        == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))))
                                                  ? vlSelfRef.u_core__DOT__rfu_wr_data
                                                  : 
                                                 ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U)))
                                                   ? 0U
                                                   : vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs
                                                  [
                                                  (0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))])));
    vlSelfRef.__PVT__u_core__DOT__rs1_val = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1)
                                              ? __PVT__u_core__DOT__ex_mem_fwd_val
                                              : (((IData)(__PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok) 
                                                  & ((~ (IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1)) 
                                                     & ((0x0000001fU 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000000fU)) 
                                                        == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))))
                                                  ? vlSelfRef.u_core__DOT__rfu_wr_data
                                                  : 
                                                 ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x0000000fU)))
                                                   ? 0U
                                                   : vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs
                                                  [
                                                  (0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x0000000fU))])));
    vlSelfRef.__PVT__u_core__DOT__stall = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                            & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                                               & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r) 
                                                     & ((0U 
                                                         != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r)) 
                                                        & ((IData)(__VdfgRegularize_h98839c81_1_3) 
                                                           | (IData)(__VdfgRegularize_h98839c81_1_4))))))) 
                                           | ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                                              & ((IData)(__PVT__u_core__DOT__id_is_muldiv) 
                                                 & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid)) 
                                                    & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17)))));
    vlSelfRef.__PVT__u_core__DOT__bp_predict_target 
        = ((IData)(__PVT__u_core__DOT__u_bp__DOT__rd_hit1)
            ? vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1
           [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))] : vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0
           [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))]);
    vlSelfRef.__PVT__u_core__DOT__bp_predict_taken 
        = ((vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0
            [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                             >> 1U))] & ((vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0
                                          [(0x0000001fU 
                                            & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                               >> 1U))] 
                                          == (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                              >> 6U)) 
                                         & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0
                                            [(0x0000001fU 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                 >> 1U))] 
                                            >> 1U))) 
           | ((IData)(__PVT__u_core__DOT__u_bp__DOT__rd_hit1) 
              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1
                 [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                  >> 1U))] >> 1U)));
    vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 0U;
    u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
        = (0x00042403U | (((((8U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                    >> 2U)) | (7U & 
                                               ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                >> 0x0000000aU))) 
                            << 0x00000017U) | (0x00400000U 
                                               & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                  << 0x00000010U))) 
                          | ((0x00038000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                             << 8U)) 
                             | (0x00000380U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               << 5U)))));
    __PVT__u_core__DOT__u_cdec__DOT__imm_addi = ((0x00000fe0U 
                                                  & ((- (IData)(
                                                                (1U 
                                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                                    >> 0x0000000cU)))) 
                                                     << 5U)) 
                                                 | (0x0000001fU 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 2U)));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13 
        = (((((4U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                     >> 6U)) | (3U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 9U))) << 7U) 
            | (((2U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                       >> 5U)) | (1U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                        >> 7U))) << 5U)) 
           | ((0x00000010U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              << 2U)) | ((8U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                >> 8U)) 
                                         | (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                  >> 3U)))));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6 
        = (0x00045413U | ((0x00038000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                          << 8U)) | 
                          (0x00000380U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7 
        = ((0x00000038U & ((- (IData)((1U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                             >> 0x0000000cU)))) 
                           << 3U)) | ((6U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                             >> 4U)) 
                                      | (1U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               >> 2U))));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9 
        = (0x63U | ((0x00000c00U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)) 
                    | ((0x00000300U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                       << 5U)) | (0x00000080U 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                     >> 5U)))));
    vlSelfRef.__PVT__d_xfer = ((IData)(__PVT__d_fire) 
                               | (IData)(vlSelfRef.__PVT__d_busy));
    vlSelfRef.__PVT__u_core__DOT__md_start = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_started)) 
                                              & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17) 
                                                 & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid)) 
                                                    & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                                       & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16)))));
    __PVT__u_core__DOT__alu_op_b = (((0x13U == (0x0000007fU 
                                                & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                     | ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
                                        | ((3U == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                           | ((0x23U 
                                               == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                              | (IData)(__VdfgRegularize_h98839c81_1_1)))))
                                     ? __PVT__u_core__DOT__id_imm
                                     : vlSelfRef.__PVT__u_core__DOT__rs2_val);
    vlSelfRef.__PVT__u_core__DOT__store_addr_lo = (3U 
                                                   & (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                      + __PVT__u_core__DOT__id_imm));
    vlSelfRef.__PVT__u_core__DOT__id_csr_wdata = ((0x00004000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 
                                                  (0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x0000000fU))
                                                   : vlSelfRef.__PVT__u_core__DOT__rs1_val);
    vlSelfRef.__PVT__u_core__DOT__ras_push = (IData)(
                                                     ((((0x000000efU 
                                                         == 
                                                         (0x00000fffU 
                                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                        & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid)) 
                                                       & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall))) 
                                                      & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18)));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)))));
    vlSelfRef.__PVT__i_fire = (1U & (((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                      & (~ (IData)(vlSelfRef.__PVT__i_busy))) 
                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
                                        | ((IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup) 
                                           | ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                              | (IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary))))));
    vlSelfRef.__PVT__u_core__DOT__any_stall = ((IData)(vlSelfRef.__PVT__u_core__DOT__stall) 
                                               | ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                                                  | ((IData)(vlSelfRef.__PVT__u_core__DOT__warmup) 
                                                     | ((IData)(vlSelfRef.__PVT__mem_stall) 
                                                        | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup)))));
    vlSelfRef.__PVT__u_core__DOT__cdec_expanded = 0U;
    if ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
        if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        } else if ((0x00008000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                    vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                }
            } else if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0cU)))) {
                if ((0U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                           >> 2U)))) {
                    if ((0U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               >> 7U)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                }
            }
        } else if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            } else if ((0U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              >> 7U)))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            }
        } else if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        } else if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))) {
            if ((0x00008000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                    if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                  >> 0x0000000dU)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x00012023U | ((((0x000000c0U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    >> 1U)) 
                                                | ((0x00000020U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 7U)) 
                                                   | (0x0000001fU 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 2U)))) 
                                               << 0x00000014U) 
                                              | (0x00000e00U 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
                    }
                } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                     >> 0x0000000dU)))) {
                    if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = ((0U == (0x0000001fU 
                                       & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                          >> 2U))) ? 
                               ((0U == (0x0000001fU 
                                        & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                           >> 7U)))
                                 ? 0x00100073U : (0x00e7U 
                                                  | (0x000f8000U 
                                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                        << 8U))))
                                : (0x33U | ((0x01f00000U 
                                             & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                << 0x00000012U)) 
                                            | ((0x000f8000U 
                                                & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                   << 8U)) 
                                               | (0x00000f80U 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))));
                    } else if ((0U == (0x0000001fU 
                                       & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                          >> 2U)))) {
                        if ((0U != (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                   >> 7U)))) {
                            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                                = (0x0067U | (0x000f8000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)));
                        }
                    } else {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x33U | ((0x01f00000U 
                                         & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                            << 0x00000012U)) 
                                        | (0x00000f80U 
                                           & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
                    }
                }
            } else if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                    if ((0U != (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               >> 7U)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x00012003U | ((((0x00000030U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    << 2U)) 
                                                | ((8U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 9U)) 
                                                   | (7U 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 4U)))) 
                                               << 0x00000016U) 
                                              | (0x00000f80U 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
                    }
                }
            } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0000000dU)))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0cU)))) {
                    vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                        = (0x00001013U | ((0x01f00000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x000f8000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000f80U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))));
                }
            }
        }
    } else if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                          >> 0x0000000eU)))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                    if ((0x00000800U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                            if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                            }
                        }
                    } else if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                        }
                    } else if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                }
            }
            if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                        ? (0x00041000U | ((0x80000000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000013U)) 
                                          | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7) 
                                              << 0x00000019U) 
                                             | ((0x00038000U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    << 8U)) 
                                                | (IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9)))))
                        : (0x00040000U | ((0x80000000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000013U)) 
                                          | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7) 
                                              << 0x00000019U) 
                                             | ((0x00038000U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    << 8U)) 
                                                | (IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9))))));
            } else if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = (0x006fU | ((((0x00000800U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13) 
                                                  << 1U) 
                                                 | (1U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 0x0000000cU)))) 
                                   << 0x00000014U) 
                                  | (0x000ff000U & 
                                     ((- (IData)((1U 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                     >> 0x0000000cU)))) 
                                      << 0x0000000bU))));
            } else if ((0x00000800U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                    if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                  >> 0x0cU)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = ((0x00000040U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                                ? ((0x00000020U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                                    ? (0x00847433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))))
                                    : (0x00846433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))))
                                : ((0x00000020U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                                    ? (0x00844433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))))
                                    : (0x40840433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))))));
                    }
                } else {
                    vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                        = (0x00047413U | (((IData)(__PVT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                           << 0x00000014U) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))));
                }
            } else if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0cU)))) {
                    vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                        = (0x40000000U | ((0x01f00000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6));
                }
            } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0cU)))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = ((0x01f00000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                       << 0x00000012U)) 
                       | u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6);
            }
        } else if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((2U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                           >> 7U)))) {
                    if ((IData)((0U == (0x107cU & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                    if ((1U & (~ (IData)((0U == (0x107cU 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x00010113U | (((- (IData)(
                                                          (1U 
                                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                              >> 0x0000000cU)))) 
                                               << 0x0000001dU) 
                                              | ((((6U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 2U)) 
                                                   | (1U 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 5U))) 
                                                  << 0x0000001aU) 
                                                 | ((0x02000000U 
                                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                        << 0x00000017U)) 
                                                    | (0x01000000U 
                                                       & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                          << 0x00000012U))))));
                    }
                } else {
                    if ((IData)((0U == (0x107cU & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                    if ((1U & (~ (IData)((0U == (0x107cU 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x37U | (((- (IData)(
                                                    (1U 
                                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                        >> 0x0000000cU)))) 
                                         << 0x00000011U) 
                                        | ((0x0001f000U 
                                            & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               << 0x0000000aU)) 
                                           | (0x00000f80U 
                                              & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))));
                    }
                }
            } else {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = (0x13U | (((IData)(__PVT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                 << 0x00000014U) | 
                                (0x00000f80U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
            }
        } else {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                    ? (0x00efU | ((((0x00000800U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13) 
                                                  << 1U) 
                                                 | (1U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 0x0000000cU)))) 
                                   << 0x00000014U) 
                                  | (0x000ff000U & 
                                     ((- (IData)((1U 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                     >> 0x0000000cU)))) 
                                      << 0x0000000bU))))
                    : (0x13U | (((IData)(__PVT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                 << 0x00000014U) | 
                                ((0x000f8000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                 | (0x00000f80U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))));
        }
    } else if ((0U == (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                             >> 0x0000000dU)))) {
        if ((0U == (0x000000ffU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                   >> 5U)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        }
        if ((0U != (0x000000ffU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                   >> 5U)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = (0x00010413U | ((((0x000003c0U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((
                                                   (6U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 0x0000000aU)) 
                                                   | (1U 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 5U))) 
                                                  << 3U) 
                                                 | (4U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 4U)))) 
                                   << 0x00000014U) 
                                  | (0x00000380U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      << 5U))));
        }
    } else {
        if ((2U != (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                          >> 0x0000000dU)))) {
            if ((6U != (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            }
        }
        if ((2U == (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                          >> 0x0000000dU)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0;
        } else if ((6U == (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0000000dU)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = (0x00842023U | ((((0x00003f80U & 
                                     (u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
                                      >> 0x00000012U)) 
                                    | (0x0000001cU 
                                       & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) 
                                   << 0x00000012U) 
                                  | ((0x00038000U & 
                                      ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                       << 8U)) | (0x00000f80U 
                                                  & (u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
                                                     >> 0x0000000dU)))));
        }
    }
    __PVT__u_core__DOT__alu_cmp_eq = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                      == __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_s = VL_LTS_III(32, vlSelfRef.__PVT__u_core__DOT__rs1_val, __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_u = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                        < __PVT__u_core__DOT__alu_op_b);
    vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__instr_assembled = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble)
          ? ((vlSelfRef.__PVT__i_rdata_q << 0x00000010U) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__residue))
          : ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
              ? vlSelfRef.__PVT__u_core__DOT__cdec_expanded
              : vlSelfRef.__PVT__i_rdata_q));
    vlSelfRef.__PVT__u_core__DOT__alu_result = ((8U 
                                                 & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                 ? 
                                                ((4U 
                                                  & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                  ? 0U
                                                  : 
                                                 ((2U 
                                                   & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? __PVT__u_core__DOT__alu_op_b
                                                    : (IData)(__PVT__u_core__DOT__alu_cmp_eq))
                                                   : 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? (IData)(__PVT__u_core__DOT__alu_cmp_lt_u)
                                                    : (IData)(__PVT__u_core__DOT__alu_cmp_lt_s))))
                                                 : 
                                                ((4U 
                                                  & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                  ? 
                                                 ((2U 
                                                   & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   VL_SHIFTRS_III(32,32,5, vlSelfRef.__PVT__u_core__DOT__rs1_val, 
                                                                  (0x0000001fU 
                                                                   & __PVT__u_core__DOT__alu_op_b))
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    >> 
                                                    (0x0000001fU 
                                                     & __PVT__u_core__DOT__alu_op_b)))
                                                   : 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    << 
                                                    (0x0000001fU 
                                                     & __PVT__u_core__DOT__alu_op_b))
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    ^ __PVT__u_core__DOT__alu_op_b)))
                                                  : 
                                                 ((2U 
                                                   & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    | __PVT__u_core__DOT__alu_op_b)
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    & __PVT__u_core__DOT__alu_op_b))
                                                   : 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    - __PVT__u_core__DOT__alu_op_b)
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    + __PVT__u_core__DOT__alu_op_b)))));
    vlSelfRef.__PVT__u_core__DOT__branch_taken = ((0x63U 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                  & (((0x63U 
                                                       == 
                                                       (0x0000007fU 
                                                        & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                      & ((1U 
                                                          == 
                                                          (7U 
                                                           & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                              >> 0x0000000cU))) 
                                                         | ((5U 
                                                             == 
                                                             (7U 
                                                              & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                                 >> 0x0000000cU))) 
                                                            | (7U 
                                                               == 
                                                               (7U 
                                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                                   >> 0x0000000cU)))))) 
                                                     ^ 
                                                     ((0U 
                                                       == 
                                                       (3U 
                                                        & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                           >> 0x0000000dU)))
                                                       ? (IData)(__PVT__u_core__DOT__alu_cmp_eq)
                                                       : 
                                                      ((2U 
                                                        == 
                                                        (3U 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000000dU)))
                                                        ? (IData)(__PVT__u_core__DOT__alu_cmp_lt_s)
                                                        : (IData)(__PVT__u_core__DOT__alu_cmp_lt_u)))));
    vlSelfRef.__PVT__u_core__DOT__ras_pop = (((IData)(
                                                      (0x00008067U 
                                                       == 
                                                       (0x000fffffU 
                                                        & vlSelfRef.__PVT__u_core__DOT__instr_assembled))) 
                                              | ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w) 
                                                 & (0x8082U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))) 
                                             & ((0U 
                                                 != vlSelfRef.__PVT__u_core__DOT__ras_top) 
                                                & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
                                                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__branch_taken) 
            | (IData)(__VdfgRegularize_h98839c81_1_1)));
    vlSelfRef.__PVT__u_core__DOT__next_pc_w = ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)
                                                ? __PVT__u_core__DOT__redirect_target
                                                : ((IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)
                                                    ? vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ras_top
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken)
                                                      ? vlSelfRef.__PVT__u_core__DOT__bp_predict_target
                                                      : 
                                                     (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                      + 
                                                      ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
                                                        ? 2U
                                                        : 4U))))));
    __VdfgRegularize_h98839c81_1_0 = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                      & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16) 
                                         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken) 
                                                | (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop))) 
                                            & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18))));
    vlSelfRef.__PVT__u_core__DOT__consecutive_cross 
        = ((((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble) 
             & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (IData)(__VdfgRegularize_h98839c81_1_0));
    vlSelfRef.__PVT__u_core__DOT__upcoming_cross = 
        (((((~ (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
          & (IData)(__VdfgRegularize_h98839c81_1_0)) 
         & (3U != (3U & vlSelfRef.__PVT__i_rdata_q)));
    vlSelfRef.__PVT__core_i_mem_addr = ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary)
                                         ? ((IData)(2U) 
                                            + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                         : ((IData)(vlSelfRef.__PVT__u_core__DOT__consecutive_cross)
                                             ? ((IData)(6U) 
                                                + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                             : ((IData)(vlSelfRef.__PVT__u_core__DOT__upcoming_cross)
                                                 ? 
                                                ((IData)(4U) 
                                                 + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                 : vlSelfRef.__PVT__u_core__DOT__next_pc_w)));
}

void Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __PVT__u_core__DOT__redirect_target;
    __PVT__u_core__DOT__redirect_target = 0;
    IData/*31:0*/ __PVT__u_core__DOT__csr_rdata;
    __PVT__u_core__DOT__csr_rdata = 0;
    CData/*0:0*/ __PVT__u_core__DOT__wb_take_irq;
    __PVT__u_core__DOT__wb_take_irq = 0;
    CData/*0:0*/ u_core__DOT____VdfgExtracted_ha4e5ab41__0;
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_13;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_18;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_0;
    __VdfgRegularize_h98839c81_1_0 = 0;
    // Body
    vlSelfRef.__PVT__mem_stall = (((IData)(vlSelfRef.__PVT__i_busy) 
                                   | ((~ (IData)(vlSelfRef.__PVT__primed)) 
                                      | (IData)(vlSelfRef.__PVT__d_busy))) 
                                  & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn));
    vlSelfRef.dbus_ready = (((2U == (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)) 
                             & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_rvalid)) 
                            | ((3U == (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)) 
                               & ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_bvalid) 
                                  & (((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done) 
                                      | ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_awvalid) 
                                         & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_awready))) 
                                     & ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done) 
                                        | ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_wvalid) 
                                           & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_wready)))))));
    vlSelfRef.__PVT__u_core__DOT__bp_upd_valid = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_trap_exit = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14));
    vlSelfRef.__PVT__u_core__DOT__any_stall = ((IData)(vlSelfRef.__PVT__u_core__DOT__stall) 
                                               | ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                                                  | ((IData)(vlSelfRef.__PVT__u_core__DOT__warmup) 
                                                     | ((IData)(vlSelfRef.__PVT__mem_stall) 
                                                        | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup)))));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    __PVT__u_core__DOT__wb_take_irq = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                       & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                          & (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                                             & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13))));
    vlSelfRef.u_core__DOT__rfu_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
                                     & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                        & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                           & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                              & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13)))));
    vlSelfRef.u_core__DOT__wb_instr_retired = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
                                                     & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    vlSelfRef.__PVT__u_core__DOT__wb_csr_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                                     & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = ((IData)(__PVT__u_core__DOT__wb_take_irq) 
                                                 | ((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap) 
                                                    | (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)));
    __PVT__u_core__DOT__csr_rdata = (((((((((0x0300U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U)) 
                                            | (0x0304U 
                                               == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))) 
                                           | (0x0305U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))) 
                                          | (0x0340U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U))) 
                                         | (0x0341U 
                                            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                >> 0x00000014U))) 
                                        | (0x0342U 
                                           == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x00000014U))) 
                                       | (0x0343U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))) 
                                      | (0x0344U == 
                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                          >> 0x00000014U)))
                                      ? ((0x0300U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val
                                          : ((0x0304U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 << 0x0000000bU)
                                              : ((0x0305U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? 
                                                 (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                  << 2U)
                                                  : 
                                                 ((0x0340U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch
                                                   : 
                                                  ((0x0341U 
                                                    == 
                                                    (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))
                                                    ? vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg
                                                    : 
                                                   ((0x0342U 
                                                     == 
                                                     (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))
                                                     ? vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg
                                                     : 
                                                    ((0x0343U 
                                                      == 
                                                      (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U))
                                                      ? vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg
                                                      : 
                                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                                      << 0x0000000bU))))))))
                                      : ((0x0c00U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt)
                                          : ((0x0c80U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? (IData)(
                                                        (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt 
                                                         >> 0x20U))
                                              : ((0x0c02U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt)
                                                  : 
                                                 ((0x0c82U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? (IData)(
                                                             (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt 
                                                              >> 0x20U))
                                                   : 0U)))));
    if (((IData)(vlSelfRef.__PVT__u_core__DOT__wb_csr_we) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r) 
            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                >> 0x00000014U)))) {
        if ((((((((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)) 
                  || (0x0304U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                 || (0x0305U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                || (0x0340U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
               || (0x0341U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
              || (0x0342U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
             || (0x0343U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)))) {
            __PVT__u_core__DOT__csr_rdata = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
        }
    }
    vlSelfRef.__PVT__u_core__DOT__wb_trap_enter = (
                                                   (~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                   & (IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0));
    vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb 
        = ((~ ((IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0) 
               | (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14))) 
           & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r));
    __PVT__u_core__DOT__redirect_target = 0U;
    vlSelfRef.__PVT__u_core__DOT__pc_redirect = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
        if (u_core__DOT____VdfgExtracted_ha4e5ab41__0) {
            __PVT__u_core__DOT__redirect_target = (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                   << 2U);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r))) {
            __PVT__u_core__DOT__redirect_target = vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict) {
            __PVT__u_core__DOT__redirect_target = (0xfffffffeU 
                                                   & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r))) {
            __PVT__u_core__DOT__redirect_target = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r)
                                                    ? 
                                                   (0xfffffffeU 
                                                    & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r)
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r)
                                                      ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r)));
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        }
    }
    vlSelfRef.__PVT__u_core__DOT__id_csr_rdata = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r) 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r) 
                                                         == 
                                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                          >> 0x00000014U))))
                                                   ? 
                                                  ((1U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                    ? vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r
                                                    : 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                     ? 
                                                    (vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r 
                                                     | vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r)
                                                     : 
                                                    ((3U 
                                                      == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                      ? 
                                                     ((~ vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r) 
                                                      & vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)))
                                                   : __PVT__u_core__DOT__csr_rdata);
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)))));
    vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__md_start = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_started)) 
                                              & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17) 
                                                 & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid)) 
                                                    & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                                       & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16)))));
    vlSelfRef.__PVT__core_d_mem_wstrb = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r) 
                                          & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                             & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r)
                                          : 0U);
    vlSelfRef.__PVT__i_fire = (1U & (((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                      & (~ (IData)(vlSelfRef.__PVT__i_busy))) 
                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
                                        | ((IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup) 
                                           | ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                              | (IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary))))));
    vlSelfRef.__PVT__d_fire = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                & (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                                    | (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r)) 
                                   & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                      & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r))))) 
                               & ((~ (IData)(vlSelfRef.__PVT__d_busy)) 
                                  & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    vlSelfRef.__PVT__u_core__DOT__ras_pop = (((IData)(
                                                      (0x00008067U 
                                                       == 
                                                       (0x000fffffU 
                                                        & vlSelfRef.__PVT__u_core__DOT__instr_assembled))) 
                                              | ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w) 
                                                 & (0x8082U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))) 
                                             & ((0U 
                                                 != vlSelfRef.__PVT__u_core__DOT__ras_top) 
                                                & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
                                                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__ras_push = (IData)(
                                                     ((((0x000000efU 
                                                         == 
                                                         (0x00000fffU 
                                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                        & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid)) 
                                                       & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall))) 
                                                      & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18)));
    vlSelfRef.__PVT__u_core__DOT__next_pc_w = ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)
                                                ? __PVT__u_core__DOT__redirect_target
                                                : ((IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)
                                                    ? vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ras_top
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken)
                                                      ? vlSelfRef.__PVT__u_core__DOT__bp_predict_target
                                                      : 
                                                     (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                      + 
                                                      ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
                                                        ? 2U
                                                        : 4U))))));
    __VdfgRegularize_h98839c81_1_0 = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                      & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16) 
                                         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken) 
                                                | (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop))) 
                                            & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18))));
    vlSelfRef.__PVT__u_core__DOT__consecutive_cross 
        = ((((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble) 
             & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (IData)(__VdfgRegularize_h98839c81_1_0));
    vlSelfRef.__PVT__u_core__DOT__upcoming_cross = 
        (((((~ (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
          & (IData)(__VdfgRegularize_h98839c81_1_0)) 
         & (3U != (3U & vlSelfRef.__PVT__i_rdata_q)));
    vlSelfRef.__PVT__core_i_mem_addr = ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary)
                                         ? ((IData)(2U) 
                                            + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                         : ((IData)(vlSelfRef.__PVT__u_core__DOT__consecutive_cross)
                                             ? ((IData)(6U) 
                                                + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                             : ((IData)(vlSelfRef.__PVT__u_core__DOT__upcoming_cross)
                                                 ? 
                                                ((IData)(4U) 
                                                 + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                 : vlSelfRef.__PVT__u_core__DOT__next_pc_w)));
}

void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit0;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit0 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit1;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit1 = 0;
    CData/*4:0*/ __Vtableidx6;
    __Vtableidx6 = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__md_result_valid;
    __Vdly__u_core__DOT__md_result_valid = 0;
    CData/*2:0*/ __Vdly__u_core__DOT__u_ras__DOT__ptr;
    __Vdly__u_core__DOT__u_ras__DOT__ptr = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__u_mul__DOT__high_out;
    __Vdly__u_core__DOT__u_mul__DOT__high_out = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__u_mul__DOT__busy;
    __Vdly__u_core__DOT__u_mul__DOT__busy = 0;
    CData/*1:0*/ __Vdly__u_core__DOT__u_div__DOT__state;
    __Vdly__u_core__DOT__u_div__DOT__state = 0;
    CData/*5:0*/ __Vdly__u_core__DOT__u_div__DOT__iter;
    __Vdly__u_core__DOT__u_div__DOT__iter = 0;
    IData/*31:0*/ __Vdly__u_core__DOT__u_div__DOT__quotient;
    __Vdly__u_core__DOT__u_div__DOT__quotient = 0;
    CData/*0:0*/ __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie;
    __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v1 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1 = 0;
    IData/*25:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__target1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v1 = 0;
    CData/*1:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1 = 0;
    CData/*1:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1 = 0;
    IData/*25:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1 = 0;
    CData/*0:0*/ __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0;
    __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0;
    __VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__lru__v0;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_bp__DOT__lru__v1;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v1 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0;
    __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0 = 0;
    CData/*2:0*/ __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0;
    __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v0;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v0 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1;
    __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v1;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v1 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2;
    __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2 = 0;
    CData/*2:0*/ __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2;
    __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v2;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v2 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_ras__DOT__stack__v3;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v3 = 0;
    IData/*31:0*/ __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0;
    __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0 = 0;
    CData/*4:0*/ __VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0;
    __VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0 = 0;
    CData/*0:0*/ __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1 = 0;
    VlWide<3>/*95:0*/ __Vtemp_3;
    VlWide<3>/*95:0*/ __Vtemp_4;
    VlWide<3>/*95:0*/ __Vtemp_6;
    VlWide<3>/*95:0*/ __Vtemp_7;
    VlWide<3>/*95:0*/ __Vtemp_8;
    // Body
    if (VL_UNLIKELY((((IData)(vlSelfRef.__PVT__u_core__DOT__cdec_illegal) 
                      & (0U != vlSelfRef.__PVT__u_core__DOT__cdec_expanded))))) {
        VL_WRITEF_NX("[%0t] %%Error: core.v:156: Assertion failed in %Ntb_axil_equiv.u_axi.u_cpu.u_core: ADR-0016 invariant: cdec_illegal asserted but expanded=%x != 0\n",0,
                     64,VL_TIME_UNITED_Q(1),-9,vlSymsp->name(),
                     32,vlSelfRef.__PVT__u_core__DOT__cdec_expanded);
        VL_STOP_MT("../../../IP/cpu_m1/rtl/../../../IP/cpu_m1/rtl/core.v", 156, "");
    }
    __Vdly__u_core__DOT__u_ras__DOT__ptr = vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v0 = 0U;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v1 = 0U;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v2 = 0U;
    __VdlySet__u_core__DOT__u_ras__DOT__stack__v3 = 0U;
    vlSelfRef.__Vdly__i_busy = vlSelfRef.__PVT__i_busy;
    vlSelfRef.__Vdly__d_busy = vlSelfRef.__PVT__d_busy;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__lru__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target0__v1 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v0 = 0U;
    __VdlySet__u_core__DOT__u_bp__DOT__target1__v1 = 0U;
    __Vdly__u_core__DOT__u_mul__DOT__high_out = vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__high_out;
    __Vdly__u_core__DOT__u_mul__DOT__busy = vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy;
    __Vdly__u_core__DOT__u_div__DOT__state = vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state;
    __Vdly__u_core__DOT__u_div__DOT__iter = vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter;
    __Vdly__u_core__DOT__u_div__DOT__quotient = vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient;
    __Vdly__u_core__DOT__md_result_valid = vlSelfRef.__PVT__u_core__DOT__md_result_valid;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0 = 0U;
    __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1 = 0U;
    __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie;
    if (vlSymsp->TOP.tb_axil_equiv__DOT__resetn) {
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt 
            = (1ULL + vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt);
        if (vlSelfRef.u_core__DOT__wb_instr_retired) {
            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt 
                = (1ULL + vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt);
        }
        if (((IData)(vlSelfRef.__PVT__u_core__DOT__ras_push) 
             & (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop))) {
            if ((0U != (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))) {
                __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0 
                    = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
                __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0 
                    = vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__top_idx;
                __VdlySet__u_core__DOT__u_ras__DOT__stack__v0 = 1U;
            } else {
                __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1 
                    = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
                __VdlySet__u_core__DOT__u_ras__DOT__stack__v1 = 1U;
            }
        } else if (vlSelfRef.__PVT__u_core__DOT__ras_push) {
            __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2 
                = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
            __VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2 
                = vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr;
            __VdlySet__u_core__DOT__u_ras__DOT__stack__v2 = 1U;
            __Vdly__u_core__DOT__u_ras__DOT__ptr = 
                (7U & ((IData)(1U) + (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr)));
        } else if (vlSelfRef.__PVT__u_core__DOT__ras_pop) {
            if ((0U != (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))) {
                __Vdly__u_core__DOT__u_ras__DOT__ptr 
                    = (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                             - (IData)(1U)));
            }
        }
        if (((IData)(vlSelfRef.__PVT__i_fire) & (~ (IData)(vlSelfRef.ibus_ready)))) {
            vlSelfRef.__Vdly__i_busy = 1U;
        } else if (((IData)(vlSelfRef.__PVT__i_busy) 
                    & (IData)(vlSelfRef.ibus_ready))) {
            vlSelfRef.__Vdly__i_busy = 0U;
        }
        if (((IData)(vlSelfRef.__PVT__d_fire) & (~ (IData)(vlSelfRef.dbus_ready)))) {
            vlSelfRef.__Vdly__d_busy = 1U;
            vlSelfRef.__PVT__d_wstrb_q = vlSelfRef.__PVT__core_d_mem_wstrb;
        } else if (((IData)(vlSelfRef.__PVT__d_busy) 
                    & (IData)(vlSelfRef.dbus_ready))) {
            vlSelfRef.__Vdly__d_busy = 0U;
        }
        if (vlSelfRef.__PVT__u_core__DOT__bp_upd_valid) {
            __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0 
                = (1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way)));
            __VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0 
                = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                  >> 1U));
            __VdlySet__u_core__DOT__u_bp__DOT__lru__v0 = 1U;
            if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way)))) {
                __VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__valid0__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0 
                    = vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__cnt_next;
                __VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__counter0__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0 
                    = (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                       >> 6U);
                __VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__tag0__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_target_r;
                __VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__target0__v0 = 1U;
            }
            if (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way) {
                __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0 
                    = vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__cnt_next;
                __VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__counter1__v0 = 1U;
                __VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__valid1__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0 
                    = (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                       >> 6U);
                __VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__tag1__v0 = 1U;
                __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_target_r;
                __VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0 
                    = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                      >> 1U));
                __VdlySet__u_core__DOT__u_bp__DOT__target1__v0 = 1U;
            }
        }
        if (((IData)(vlSelfRef.u_core__DOT__rfu_we) 
             & (0U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r)))) {
            __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0 
                = vlSelfRef.u_core__DOT__rfu_wr_data;
            __VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0 
                = vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r;
            __VdlySet__u_core__DOT__u_rfu__DOT__regs__v0 = 1U;
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_csr_we) {
            if ((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie 
                    = (1U & (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                             >> 3U));
            }
            if ((0x0300U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                if ((0x0304U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                    if ((0x0305U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                        if ((0x0340U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch 
                                = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
                        }
                    }
                    if ((0x0305U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                            = (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                               >> 2U);
                    }
                }
                if ((0x0304U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie 
                        = (1U & (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                                 >> 0x0bU));
                }
            }
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_trap_enter) {
            __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = 0U;
        } else if (vlSelfRef.__PVT__u_core__DOT__wb_trap_exit) {
            __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie 
                = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie;
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_csr_we) {
            if ((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie 
                    = (1U & (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
                             >> 7U));
            }
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_trap_enter) {
            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie 
                = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie;
        } else if (vlSelfRef.__PVT__u_core__DOT__wb_trap_exit) {
            vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            if (vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) {
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_addr_lo_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_ls_funct3_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_md_result_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_md_result_r;
            }
            vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r));
        }
        if (vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_taken_r 
                = vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r = 1U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_target_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r 
                = (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r 
                = (3U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r 
                = (((0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                    & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9) 
                       & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15)))
                    ? (((0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                        & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                           & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid)))
                        ? (0x0000000fU & ((0U == (7U 
                                                  & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x0000000cU)))
                                           ? ((IData)(1U) 
                                              << (IData)(vlSelfRef.__PVT__u_core__DOT__store_addr_lo))
                                           : ((1U == 
                                               (7U 
                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x0000000cU)))
                                               ? ((IData)(3U) 
                                                  << 
                                                  (2U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__store_addr_lo)))
                                               : ((2U 
                                                   == 
                                                   (7U 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x0000000cU)))
                                                   ? 0x0fU
                                                   : 0U))))
                        : 0U) : 0U);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                   & (((0x63U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                       | (0x6fU == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) 
                      & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                         & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                   & (((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken) 
                       != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken)) 
                      | ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras) 
                                | (vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target 
                                   == ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr)
                                        ? (0xfffffffeU 
                                           & vlSelfRef.__PVT__u_core__DOT__alu_result)
                                        : vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm)))) 
                            & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken) 
                               & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken))))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_target_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r 
                = vlSelfRef.__PVT__u_core__DOT__id_csr_wdata;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_addr_lo_r 
                = (3U & vlSelfRef.__PVT__u_core__DOT__alu_result);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r 
                = vlSelfRef.__PVT__u_core__DOT__id_wb_sel;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r 
                = vlSelfRef.__PVT__u_core__DOT__id_csr_rdata;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r 
                = (3U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000cU));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_ls_funct3_r 
                = (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000cU));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr) 
                   & ((1U == (3U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                    >> 0x0000000cU))) 
                      | (0U != vlSelfRef.__PVT__u_core__DOT__id_csr_wdata)));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r 
                = (0x30200073U == vlSelfRef.__PVT__u_core__DOT__if_ex_instr);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r 
                = ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9) 
                   & (((1U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))
                        ? vlSelfRef.__PVT__u_core__DOT__alu_result
                        : (IData)(((0x00002000U == 
                                    (0x00007000U & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                   & (0U != (3U & vlSelfRef.__PVT__u_core__DOT__alu_result))))) 
                      & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15)));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r 
                = ((0x33U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                   | ((0x13U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                      | ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
                         | ((0x6fU == (0x0000007fU 
                                       & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                            | ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                               | ((3U == (0x0000007fU 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                  | (IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr)))))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_md_result_r 
                = vlSelfRef.__PVT__u_core__DOT__md_result_q;
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r = 0U;
        }
        if ((((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
              | (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_valid = 0U;
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit 
                = vlSelfRef.__PVT__u_core__DOT__is_16bit_w;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target 
                = vlSelfRef.__PVT__u_core__DOT__ras_top;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras 
                = vlSelfRef.__PVT__u_core__DOT__ras_pop;
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken) 
                   | (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop));
            vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop)
                    ? vlSelfRef.__PVT__u_core__DOT__ras_top
                    : vlSelfRef.__PVT__u_core__DOT__bp_predict_target);
            vlSelfRef.__PVT__u_core__DOT__if_ex_valid = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))) {
            if (vlSelfRef.__PVT__u_core__DOT__md_done) {
                vlSelfRef.__PVT__u_core__DOT__md_result_q 
                    = ((IData)(vlSelfRef.__PVT__u_core__DOT__md_active_is_div)
                        ? vlSelfRef.__PVT__u_core__DOT__div_result
                        : vlSelfRef.__PVT__u_core__DOT__mul_result);
            }
        }
        vlSelfRef.__PVT__u_core__DOT__mul_done = 0U;
        if (vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending) {
            vlSelfRef.__PVT__u_core__DOT__mul_done = 1U;
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending = 0U;
        } else if ((((~ (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000eU)) & (IData)(vlSelfRef.__PVT__u_core__DOT__md_start)) 
                    & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy)))) {
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opa_r 
                = ((3U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) ? (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs1_val))
                    : (((QData)((IData)((vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                         >> 0x0000001fU))) 
                        << 0x00000020U) | (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs1_val))));
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opb_r 
                = (((3U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                  >> 0x0000000cU))) 
                    | (2U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                    >> 0x0000000cU))))
                    ? (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs2_val))
                    : (((QData)((IData)((vlSelfRef.__PVT__u_core__DOT__rs2_val 
                                         >> 0x0000001fU))) 
                        << 0x00000020U) | (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__rs2_val))));
            __Vdly__u_core__DOT__u_mul__DOT__high_out 
                = (0U != (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                >> 0x0000000cU)));
            __Vdly__u_core__DOT__u_mul__DOT__busy = 1U;
        } else if (vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy) {
            vlSelfRef.__PVT__u_core__DOT__mul_result 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__high_out)
                    ? vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[1U]
                    : vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[0U]);
            vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending = 1U;
            __Vdly__u_core__DOT__u_mul__DOT__busy = 0U;
        }
        vlSelfRef.__PVT__u_core__DOT__div_done = 0U;
        if ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state))) {
            if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state))) {
                vlSelfRef.__PVT__u_core__DOT__div_done = 1U;
                __Vdly__u_core__DOT__u_div__DOT__state = 0U;
            } else {
                vlSelfRef.__PVT__u_core__DOT__div_result 
                    = ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__div_by_zero)
                        ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem)
                            ? vlSelfRef.__PVT__u_core__DOT__u_div__DOT__orig_a
                            : 0xffffffffU) : ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__overflow)
                                               ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem)
                                                   ? 0U
                                                   : 0x80000000U)
                                               : ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem)
                                                   ? 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_rem)
                                                    ? 
                                                   (- vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)
                                                    : vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)
                                                   : 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_quot)
                                                    ? 
                                                   (- vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient)
                                                    : vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient))));
                __Vdly__u_core__DOT__u_div__DOT__state = 3U;
            }
        } else if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state))) {
            __Vdly__u_core__DOT__u_div__DOT__iter = 
                (0x0000003fU & ((IData)(1U) + (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter)));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                = (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                   << 1U);
            if ((1U & (IData)((vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w 
                               >> 0x00000020U)))) {
                __Vdly__u_core__DOT__u_div__DOT__quotient 
                    = (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient 
                       << 1U);
                vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder 
                    = (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem);
            } else {
                __Vdly__u_core__DOT__u_div__DOT__quotient 
                    = (1U | (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient 
                             << 1U));
                vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder 
                    = (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w);
            }
            if ((0x1fU == (IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter))) {
                __Vdly__u_core__DOT__u_div__DOT__state = 2U;
            }
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__md_start) 
                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                       >> 0x0000000eU))) {
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                = ((((4U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))) 
                     | (6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))) 
                    & (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                       >> 0x1fU)) ? (- vlSelfRef.__PVT__u_core__DOT__rs1_val)
                    : vlSelfRef.__PVT__u_core__DOT__rs1_val);
            __Vdly__u_core__DOT__u_div__DOT__quotient = 0U;
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__orig_a 
                = vlSelfRef.__PVT__u_core__DOT__rs1_val;
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__ret_rem 
                = ((6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) 
                   | (7U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__div_by_zero 
                = (0U == vlSelfRef.__PVT__u_core__DOT__rs2_val);
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__overflow 
                = ((((4U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))) 
                     | (6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))) 
                    & (0x80000000U == vlSelfRef.__PVT__u_core__DOT__rs1_val)) 
                   & (0xffffffffU == vlSelfRef.__PVT__u_core__DOT__rs2_val));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__divisor 
                = ((((4U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU))) 
                     | (6U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))) 
                    & (vlSelfRef.__PVT__u_core__DOT__rs2_val 
                       >> 0x1fU)) ? (- vlSelfRef.__PVT__u_core__DOT__rs2_val)
                    : vlSelfRef.__PVT__u_core__DOT__rs2_val);
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_quot 
                = (IData)(((0x00004000U == (0x00007000U 
                                            & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                           & (((vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                ^ vlSelfRef.__PVT__u_core__DOT__rs2_val) 
                               >> 0x1fU) & (0U != vlSelfRef.__PVT__u_core__DOT__rs2_val))));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sign_rem 
                = (IData)(((0x00006000U == (0x00007000U 
                                            & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                           & (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                              >> 0x0000001fU)));
            vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder = 0U;
            __Vdly__u_core__DOT__u_div__DOT__iter = 0U;
            __Vdly__u_core__DOT__u_div__DOT__state = 1U;
        }
        if (vlSelfRef.__PVT__u_core__DOT__pc_redirect) {
            vlSelfRef.__PVT__u_core__DOT__md_started = 0U;
            __Vdly__u_core__DOT__md_result_valid = 0U;
        } else if (vlSelfRef.__PVT__u_core__DOT__md_done) {
            vlSelfRef.__PVT__u_core__DOT__md_started = 0U;
            __Vdly__u_core__DOT__md_result_valid = 1U;
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid))) {
            __Vdly__u_core__DOT__md_result_valid = 0U;
        } else if (vlSelfRef.__PVT__u_core__DOT__md_start) {
            vlSelfRef.__PVT__u_core__DOT__md_started = 1U;
            vlSelfRef.__PVT__u_core__DOT__md_active_is_div 
                = (1U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                         >> 0x0000000eU));
        }
    } else {
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt = 0ULL;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt = 0ULL;
        __Vdly__u_core__DOT__u_ras__DOT__ptr = 0U;
        __VdlySet__u_core__DOT__u_ras__DOT__stack__v3 = 1U;
        vlSelfRef.__Vdly__i_busy = 0U;
        vlSelfRef.__Vdly__d_busy = 0U;
        __VdlySet__u_core__DOT__u_bp__DOT__lru__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__valid0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__counter1__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__counter0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__tag0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__valid1__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__tag1__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__target0__v1 = 1U;
        __VdlySet__u_core__DOT__u_bp__DOT__target1__v1 = 1U;
        __VdlySet__u_core__DOT__u_rfu__DOT__regs__v1 = 1U;
        __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie = 0U;
        vlSelfRef.__PVT__d_wstrb_q = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_md_result_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras_target = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_mret_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_ras = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_taken = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pred_target = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_valid = 0U;
        vlSelfRef.__PVT__u_core__DOT__md_result_q = 0U;
        __Vdly__u_core__DOT__u_mul__DOT__busy = 0U;
        vlSelfRef.__PVT__u_core__DOT__mul_done = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__done_pending = 0U;
        __Vdly__u_core__DOT__u_mul__DOT__high_out = 0U;
        __Vdly__u_core__DOT__u_div__DOT__state = 0U;
        vlSelfRef.__PVT__u_core__DOT__div_done = 0U;
        vlSelfRef.__PVT__u_core__DOT__md_started = 0U;
        vlSelfRef.__PVT__u_core__DOT__md_active_is_div = 0U;
        __Vdly__u_core__DOT__md_result_valid = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending 
        = ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn) 
           && ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_trap_enter)) 
               & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending)));
    if ((1U & ((~ (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn)) 
               | (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 0U;
        vlSelfRef.__PVT__u_core__DOT__residue = 0U;
    } else if (vlSelfRef.__PVT__u_core__DOT__consecutive_cross) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 1U;
        vlSelfRef.__PVT__u_core__DOT__residue = (vlSelfRef.__PVT__i_rdata_q 
                                                 >> 0x00000010U);
    } else if (vlSelfRef.__PVT__u_core__DOT__upcoming_cross) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 1U;
        vlSelfRef.__PVT__u_core__DOT__residue = (vlSelfRef.__PVT__i_rdata_q 
                                                 >> 0x00000010U);
    } else if ((((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup))) 
                & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 1U;
        vlSelfRef.__PVT__u_core__DOT__residue = (vlSelfRef.__PVT__i_rdata_q 
                                                 >> 0x00000010U);
    } else if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)))) {
        vlSelfRef.__PVT__u_core__DOT__cross_assemble = 0U;
    }
    if (((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__dbus_req) 
         & (IData)(vlSelfRef.dbus_ready))) {
        vlSelfRef.__PVT__d_rdata_q = vlSymsp->TOP.tb_axil_equiv__DOT__a_d_rdata;
    }
    vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr = __Vdly__u_core__DOT__u_ras__DOT__ptr;
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[__VdlyDim0__u_core__DOT__u_ras__DOT__stack__v0] 
            = __VdlyVal__u_core__DOT__u_ras__DOT__stack__v0;
    }
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[0U] 
            = __VdlyVal__u_core__DOT__u_ras__DOT__stack__v1;
    }
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v2) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[__VdlyDim0__u_core__DOT__u_ras__DOT__stack__v2] 
            = __VdlyVal__u_core__DOT__u_ras__DOT__stack__v2;
    }
    if (__VdlySet__u_core__DOT__u_ras__DOT__stack__v3) {
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack[7U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__lru__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[__VdlyDim0__u_core__DOT__u_bp__DOT__lru__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__lru__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__lru__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[__VdlyDim0__u_core__DOT__u_bp__DOT__valid0__v0] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[__VdlyDim0__u_core__DOT__u_bp__DOT__counter1__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__counter1__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[0U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[1U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[2U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[3U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[4U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[5U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[6U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[7U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[8U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[9U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[10U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[11U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[12U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[13U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[14U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[15U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[16U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[17U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[18U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[19U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[20U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[21U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[22U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[23U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[24U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[25U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[26U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[27U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[28U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[29U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[30U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1[31U] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[__VdlyDim0__u_core__DOT__u_bp__DOT__counter0__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__counter0__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__counter0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[0U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[1U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[2U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[3U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[4U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[5U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[6U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[7U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[8U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[9U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[10U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[11U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[12U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[13U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[14U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[15U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[16U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[17U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[18U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[19U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[20U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[21U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[22U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[23U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[24U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[25U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[26U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[27U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[28U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[29U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[30U] = 1U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0[31U] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[__VdlyDim0__u_core__DOT__u_bp__DOT__tag0__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__tag0__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[__VdlyDim0__u_core__DOT__u_bp__DOT__valid1__v0] = 1U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__valid1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[__VdlyDim0__u_core__DOT__u_bp__DOT__tag1__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__tag1__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__tag1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target0__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[__VdlyDim0__u_core__DOT__u_bp__DOT__target0__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__target0__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target0__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target1__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[__VdlyDim0__u_core__DOT__u_bp__DOT__target1__v0] 
            = __VdlyVal__u_core__DOT__u_bp__DOT__target1__v0;
    }
    if (__VdlySet__u_core__DOT__u_bp__DOT__target1__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[0U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[1U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[2U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[3U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[4U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[5U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[6U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[7U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[8U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[9U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[10U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[11U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[12U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[13U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[14U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[15U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[16U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[17U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[18U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[19U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[20U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[21U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[22U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[23U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[24U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[25U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[26U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[27U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[28U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[29U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[30U] = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1[31U] = 0U;
    }
    if (__VdlySet__u_core__DOT__u_rfu__DOT__regs__v0) {
        vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[__VdlyDim0__u_core__DOT__u_rfu__DOT__regs__v0] 
            = __VdlyVal__u_core__DOT__u_rfu__DOT__regs__v0;
    }
    if (__VdlySet__u_core__DOT__u_rfu__DOT__regs__v1) {
        vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs[0U] = 0U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__top_idx 
        = (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                 - (IData)(1U)));
    if (((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__ibus_req) 
         & (IData)(vlSelfRef.ibus_ready))) {
        vlSelfRef.__PVT__i_rdata_q = vlSymsp->TOP.tb_axil_equiv__DOT__a_i_rdata;
    }
    if ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r))) {
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel 
            = (0x000000ffU & ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r))
                               ? (vlSelfRef.__PVT__d_rdata_q 
                                  >> 0x00000018U) : 
                              (vlSelfRef.__PVT__d_rdata_q 
                               >> 0x00000010U)));
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel 
            = (0x0000ffffU & (vlSelfRef.__PVT__d_rdata_q 
                              >> 0x00000010U));
    } else {
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel 
            = (0x000000ffU & ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_addr_lo_r))
                               ? (vlSelfRef.__PVT__d_rdata_q 
                                  >> 8U) : vlSelfRef.__PVT__d_rdata_q));
        vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel 
            = (0x0000ffffU & vlSelfRef.__PVT__d_rdata_q);
    }
    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie 
        = __Vdly__u_core__DOT__u_csr__DOT__mstatus_mie;
    vlSelfRef.__PVT__u_core__DOT__ras_top = ((0U == (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))
                                              ? 0U : vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack
                                             [(7U & 
                                               ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                                                - (IData)(1U)))]);
    __PVT__u_core__DOT__u_bp__DOT__wr_hit0 = (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0
                                              [(0x0000001fU 
                                                & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                   >> 1U))] 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                      >> 1U))] 
                                                 == 
                                                 (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                  >> 6U)));
    __PVT__u_core__DOT__u_bp__DOT__wr_hit1 = (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1
                                              [(0x0000001fU 
                                                & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                   >> 1U))] 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                      >> 1U))] 
                                                 == 
                                                 (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                                  >> 6U)));
    vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way 
        = ((IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit1) 
           | ((~ (IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit0)) 
              & vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru
              [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                               >> 1U))]));
    __Vtableidx6 = (((((IData)(vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way)
                        ? vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1
                       [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                        >> 1U))] : vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0
                       [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                        >> 1U))]) << 3U) 
                     | ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_taken_r) 
                        << 2U)) | (((IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit1) 
                                    << 1U) | (IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit0)));
    vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__cnt_next 
        = Vtb_axil_equiv__ConstPool__TABLE_hdb09954d_0
        [__Vtableidx6];
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__high_out 
        = __Vdly__u_core__DOT__u_mul__DOT__high_out;
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__busy 
        = __Vdly__u_core__DOT__u_mul__DOT__busy;
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__state 
        = __Vdly__u_core__DOT__u_div__DOT__state;
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__iter 
        = __Vdly__u_core__DOT__u_div__DOT__iter;
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__quotient 
        = __Vdly__u_core__DOT__u_div__DOT__quotient;
    vlSelfRef.__PVT__u_core__DOT__md_result_valid = __Vdly__u_core__DOT__md_result_valid;
    VL_EXTENDS_WQ(66,33, __Vtemp_3, vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opa_r);
    __Vtemp_4[0U] = __Vtemp_3[0U];
    __Vtemp_4[1U] = __Vtemp_3[1U];
    __Vtemp_4[2U] = (3U & __Vtemp_3[2U]);
    VL_EXTENDS_WQ(66,33, __Vtemp_6, vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__opb_r);
    __Vtemp_7[0U] = __Vtemp_6[0U];
    __Vtemp_7[1U] = __Vtemp_6[1U];
    __Vtemp_7[2U] = (3U & __Vtemp_6[2U]);
    VL_MULS_WWW(66, __Vtemp_8, __Vtemp_4, __Vtemp_7);
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[0U] 
        = __Vtemp_8[0U];
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[1U] 
        = __Vtemp_8[1U];
    vlSelfRef.__PVT__u_core__DOT__u_mul__DOT__product_w[2U] 
        = (3U & __Vtemp_8[2U]);
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
        = (((QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)) 
            << 1U) | (QData)((IData)((vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                                      >> 0x0000001fU))));
    vlSelfRef.__PVT__u_core__DOT__md_done = ((IData)(vlSelfRef.__PVT__u_core__DOT__md_active_is_div)
                                              ? (IData)(vlSelfRef.__PVT__u_core__DOT__div_done)
                                              : (IData)(vlSelfRef.__PVT__u_core__DOT__mul_done));
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w 
        = (0x00000001ffffffffULL & (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
                                    - (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__divisor))));
}

void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __PVT__u_core__DOT__redirect_target;
    __PVT__u_core__DOT__redirect_target = 0;
    IData/*31:0*/ __PVT__u_core__DOT__id_imm;
    __PVT__u_core__DOT__id_imm = 0;
    CData/*3:0*/ __PVT__u_core__DOT__id_alu_op;
    __PVT__u_core__DOT__id_alu_op = 0;
    CData/*0:0*/ __PVT__u_core__DOT__id_is_muldiv;
    __PVT__u_core__DOT__id_is_muldiv = 0;
    IData/*31:0*/ __PVT__u_core__DOT__ex_mem_fwd_val;
    __PVT__u_core__DOT__ex_mem_fwd_val = 0;
    IData/*31:0*/ __PVT__u_core__DOT__alu_op_b;
    __PVT__u_core__DOT__alu_op_b = 0;
    CData/*0:0*/ __PVT__u_core__DOT__alu_cmp_eq;
    __PVT__u_core__DOT__alu_cmp_eq = 0;
    CData/*0:0*/ __PVT__u_core__DOT__alu_cmp_lt_s;
    __PVT__u_core__DOT__alu_cmp_lt_s = 0;
    CData/*0:0*/ __PVT__u_core__DOT__alu_cmp_lt_u;
    __PVT__u_core__DOT__alu_cmp_lt_u = 0;
    IData/*31:0*/ __PVT__u_core__DOT__csr_rdata;
    __PVT__u_core__DOT__csr_rdata = 0;
    CData/*0:0*/ __PVT__u_core__DOT__wb_take_irq;
    __PVT__u_core__DOT__wb_take_irq = 0;
    CData/*0:0*/ u_core__DOT____VdfgExtracted_ha4e5ab41__0;
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_13;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 0;
    CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_18;
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 0;
    SData/*11:0*/ __PVT__u_core__DOT__u_cdec__DOT__imm_addi;
    __PVT__u_core__DOT__u_cdec__DOT__imm_addi = 0;
    IData/*31:0*/ u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0;
    u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 = 0;
    IData/*19:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6 = 0;
    CData/*5:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7 = 0;
    SData/*11:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9 = 0;
    SData/*9:0*/ u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13;
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__rd_hit1;
    __PVT__u_core__DOT__u_bp__DOT__rd_hit1 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok;
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1;
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2;
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok;
    __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_0;
    __VdfgRegularize_h98839c81_1_0 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_1;
    __VdfgRegularize_h98839c81_1_1 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_3;
    __VdfgRegularize_h98839c81_1_3 = 0;
    CData/*0:0*/ __VdfgRegularize_h98839c81_1_4;
    __VdfgRegularize_h98839c81_1_4 = 0;
    CData/*5:0*/ __Vtableidx4;
    __Vtableidx4 = 0;
    // Body
    vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val 
        = (0x00001800U | (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie) 
                           << 7U) | ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie) 
                                     << 3U)));
    vlSelfRef.__PVT__d_busy = vlSelfRef.__Vdly__d_busy;
    vlSelfRef.__PVT__i_busy = vlSelfRef.__Vdly__i_busy;
    if (vlSymsp->TOP.tb_axil_equiv__DOT__resetn) {
        if (vlSelfRef.__PVT__u_core__DOT__wb_csr_we) {
            if ((0x0300U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                if ((0x0304U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                    if ((0x0305U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                        if ((0x0340U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                            if ((0x0341U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                if ((0x0342U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg 
                                        = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
                                }
                                if ((0x0342U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                    if ((0x0343U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                        vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                                            = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
                                    }
                                }
                            }
                            if ((0x0341U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) {
                                vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg 
                                    = (0xfffffffeU 
                                       & vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val);
                            }
                        }
                    }
                }
            }
        }
        if (vlSelfRef.__PVT__u_core__DOT__wb_trap_enter) {
            if (vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap) {
                if (vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ecall_r) {
                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 0x0000000bU;
                    vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg = 0U;
                } else if (vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ebreak_r) {
                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 3U;
                    vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                        = vlSelfRef.u_core__DOT__ex_wb_pc_r;
                } else {
                    vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 2U;
                    vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                        = vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r;
                }
            } else {
                vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg 
                    = ((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)
                        ? ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_store_r)
                            ? 6U : 4U) : 0x8000000bU);
                vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg 
                    = vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r;
            }
            vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg 
                = (((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap) 
                    | (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap))
                    ? vlSelfRef.u_core__DOT__ex_wb_pc_r
                    : ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_branch_taken_r)
                        ? vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r
                        : ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jal_r)
                            ? vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r
                            : ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jalr_r)
                                ? (0xfffffffeU & vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r)
                                : vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r))));
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            vlSelfRef.u_core__DOT__ex_wb_valid_r = vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb;
            vlSelfRef.u_core__DOT__ex_wb_illegal_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r));
            if (vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) {
                vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r;
                vlSelfRef.u_core__DOT__ex_wb_pc_r = vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r;
                vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r 
                    = vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r;
            } else {
                vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r = 0U;
            }
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_store_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_branch_taken_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jalr_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jal_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ecall_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r));
            vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ebreak_r 
                = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb) 
                   && (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r));
        }
        if (((IData)(vlSelfRef.__PVT__d_fire) & (~ (IData)(vlSelfRef.dbus_ready)))) {
            vlSelfRef.__PVT__d_addr_q = vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r;
            vlSelfRef.__PVT__d_wdata_q = vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wdata_r;
        }
        if (((IData)(vlSelfRef.__PVT__i_fire) & (~ (IData)(vlSelfRef.ibus_ready)))) {
            vlSelfRef.__PVT__i_addr_q = vlSelfRef.__PVT__core_i_mem_addr;
        }
        if (vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r 
                = (1U & (~ ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
                            | ((0x6fU == (0x0000007fU 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                               | (((0x63U == (0x0000007fU 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                   & ((0U == (7U & 
                                              (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x0000000cU))) 
                                      | ((1U == (7U 
                                                 & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x0000000cU))) 
                                         | ((4U == 
                                             (7U & 
                                              (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x0000000cU))) 
                                            | ((5U 
                                                == 
                                                (7U 
                                                 & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x0000000cU))) 
                                               | ((6U 
                                                   == 
                                                   (7U 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x0000000cU))) 
                                                  | (7U 
                                                     == 
                                                     (7U 
                                                      & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                         >> 0x0000000cU))))))))) 
                                  | ((3U == (0x0000007fU 
                                             & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                     | ((0x23U == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                        | ((0x13U == 
                                            (0x0000007fU 
                                             & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                           | ((0x33U 
                                               == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                              | ((0x0fU 
                                                  == 
                                                  (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                 | ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                                                    | ((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr) 
                                                       | (0x30200073U 
                                                          == vlSelfRef.__PVT__u_core__DOT__if_ex_instr)))))))))))));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r 
                = (0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                  >> 7U));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wdata_r 
                = ((0U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) ? 
                   ((vlSelfRef.__PVT__u_core__DOT__rs2_val 
                     << 0x00000018U) | ((0x00ff0000U 
                                         & (vlSelfRef.__PVT__u_core__DOT__rs2_val 
                                            << 0x00000010U)) 
                                        | ((0x0000ff00U 
                                            & (vlSelfRef.__PVT__u_core__DOT__rs2_val 
                                               << 8U)) 
                                           | (0x000000ffU 
                                              & vlSelfRef.__PVT__u_core__DOT__rs2_val))))
                    : ((1U == (7U & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                     >> 0x0000000cU)))
                        ? ((vlSelfRef.__PVT__u_core__DOT__rs2_val 
                            << 0x00000010U) | (0x0000ffffU 
                                               & vlSelfRef.__PVT__u_core__DOT__rs2_val))
                        : vlSelfRef.__PVT__u_core__DOT__rs2_val));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r 
                = (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r 
                = vlSelfRef.__PVT__u_core__DOT__branch_taken;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r 
                = vlSelfRef.__PVT__u_core__DOT__ras_push_val;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r 
                = vlSelfRef.__PVT__u_core__DOT__id_is_jalr;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r 
                = (0x6fU == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr));
            vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r 
                = vlSelfRef.__PVT__u_core__DOT__alu_result;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_pc;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r 
                = (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                   >> 0x00000014U);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r 
                = vlSelfRef.__PVT__u_core__DOT__if_ex_instr;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r 
                = (0x00000073U == vlSelfRef.__PVT__u_core__DOT__if_ex_instr);
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r 
                = (0x00100073U == vlSelfRef.__PVT__u_core__DOT__if_ex_instr);
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r = 0U;
            vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r = 0U;
        }
        if ((((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
              | (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_pc = 0U;
            vlSelfRef.__PVT__u_core__DOT__if_ex_instr = 0U;
        } else if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)))) {
            vlSelfRef.__PVT__u_core__DOT__if_ex_pc 
                = vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg;
            vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                = vlSelfRef.__PVT__u_core__DOT__instr_assembled;
        }
        vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
            = vlSelfRef.__PVT__u_core__DOT__next_pc_w;
    } else {
        vlSelfRef.u_core__DOT__ex_wb_valid_r = 0U;
        vlSelfRef.u_core__DOT__ex_wb_illegal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r = 0U;
        vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg = 0U;
        vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg = 0U;
        vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg = 0U;
        vlSelfRef.__PVT__d_addr_q = 0U;
        vlSelfRef.__PVT__d_wdata_q = 0U;
        vlSelfRef.__PVT__i_addr_q = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_illegal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_store_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_branch_taken_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jalr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_jal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r = 0U;
        vlSelfRef.u_core__DOT__ex_wb_pc_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_instr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ecall_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_wb_is_ebreak_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_store_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_instr_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ecall_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__ex_mem_is_ebreak_r = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_pc = 0U;
        vlSelfRef.__PVT__u_core__DOT__if_ex_instr = 0U;
        vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg = 0U;
    }
    if ((1U & (~ (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn)))) {
        vlSelfRef.__PVT__primed = 0U;
    }
    if (((IData)(vlSelfRef.__PVT__i_boot) & (IData)(vlSelfRef.ibus_ready))) {
        vlSelfRef.__PVT__primed = 1U;
    }
    vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val 
        = ((1U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r))
            ? vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r
            : ((2U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r))
                ? (vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r 
                   | vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r)
                : ((3U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_op_r))
                    ? ((~ vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_wdata_r) 
                       & vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r)
                    : vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r)));
    vlSelfRef.dbus_ready = (((2U == (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)) 
                             & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_rvalid)) 
                            | ((3U == (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)) 
                               & ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_bvalid) 
                                  & (((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done) 
                                      | ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_awvalid) 
                                         & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_awready))) 
                                     & ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done) 
                                        | ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_wvalid) 
                                           & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_d_wready)))))));
    vlSelfRef.ibus_ready = ((2U == (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state)) 
                            & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_i_rvalid));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap 
        = ((IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 
        ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
            & (0U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))));
    vlSelfRef.__PVT__i_boot = (1U & (~ (IData)(vlSelfRef.__PVT__primed)));
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r) 
         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                | (0U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r)))) 
            & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)));
    vlSelfRef.u_core__DOT__rfu_wr_data = ((4U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                           ? ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                               ? vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_wb_md_result_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_rdata_r))
                                           : ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                               ? ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                                   ? 
                                                  ((4U 
                                                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                    ? 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                     ? vlSelfRef.__PVT__d_rdata_q
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                      ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel)
                                                      : (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel)))
                                                    : 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                     ? vlSelfRef.__PVT__d_rdata_q
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_ls_funct3_r))
                                                      ? 
                                                     (((- (IData)(
                                                                  (1U 
                                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel) 
                                                                      >> 0x0000000fU)))) 
                                                       << 0x00000010U) 
                                                      | (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel))
                                                      : 
                                                     (((- (IData)(
                                                                  (1U 
                                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel) 
                                                                      >> 7U)))) 
                                                       << 8U) 
                                                      | (IData)(vlSelfRef.__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel)))))
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_4_r)
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_wb_pc_plus_imm_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_wb_alu_result_r)));
    vlSelfRef.__PVT__mem_stall = (((IData)(vlSelfRef.__PVT__i_busy) 
                                   | ((~ (IData)(vlSelfRef.__PVT__primed)) 
                                      | (IData)(vlSelfRef.__PVT__d_busy))) 
                                  & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn));
    __PVT__u_core__DOT__ex_mem_fwd_val = ((4U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                           ? ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                               ? vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_mem_md_result_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r))
                                           : ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                               ? ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r)
                                               : ((1U 
                                                   & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_wb_sel_r))
                                                   ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                   : vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r)));
    vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r) 
              & ((0xfffffffeU & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                 != vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_target_r)));
    vlSelfRef.__PVT__u_core__DOT__bp_upd_valid = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_trap_exit = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    __PVT__u_core__DOT__wb_take_irq = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                       & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                          & (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                                             & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13))));
    vlSelfRef.__PVT__u_core__DOT__ras_push_val = (vlSelfRef.__PVT__u_core__DOT__if_ex_pc 
                                                  + 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit)
                                                    ? 2U
                                                    : 4U));
    vlSelfRef.u_core__DOT__rfu_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
                                     & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                        & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                           & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                              & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13)))));
    vlSelfRef.u_core__DOT__wb_instr_retired = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
                                                     & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    vlSelfRef.__PVT__u_core__DOT__wb_csr_we = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_we_r) 
                                               & ((~ (IData)(__PVT__u_core__DOT__wb_take_irq)) 
                                                  & ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                                     & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                                        & (~ (IData)(vlSelfRef.__PVT__mem_stall))))));
    u_core__DOT____VdfgExtracted_ha4e5ab41__0 = ((IData)(__PVT__u_core__DOT__wb_take_irq) 
                                                 | ((IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap) 
                                                    | (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap)));
    vlSelfRef.__PVT__u_core__DOT__warmup = (1U & (~ (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn)));
    vlSelfRef.__PVT__u_core__DOT__redirect_warmup = 
        ((IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn) 
         & (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9 
        = ((3U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __PVT__u_core__DOT__id_alu_op = 0U;
    if ((0x13U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = ((0x00004000U 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                          ? ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 2U
                                                  : 3U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 
                                                 ((0x40000000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 7U
                                                   : 6U)
                                                  : 4U))
                                          : ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 9U
                                                  : 8U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 5U
                                                  : 0U)));
    } else if ((0x33U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = ((0x00004000U 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                          ? ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 2U
                                                  : 3U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 
                                                 ((0x40000000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 7U
                                                   : 6U)
                                                  : 4U))
                                          : ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 9U
                                                  : 8U)
                                              : ((0x00001000U 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                  ? 5U
                                                  : 
                                                 ((0x40000000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 1U
                                                   : 0U))));
    } else if ((0x63U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = ((0x00004000U 
                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                          ? ((0x00002000U 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                              ? 9U : 8U)
                                          : 0x0aU);
    } else if ((0x37U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))) {
        __PVT__u_core__DOT__id_alu_op = 0x0bU;
    }
    vlSelfRef.__PVT__u_core__DOT__id_is_csr = ((0x73U 
                                                == 
                                                (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                               & (0U 
                                                  != 
                                                  (7U 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x0000000cU))));
    vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 
        = ((0x37U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x17U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    vlSelfRef.__PVT__u_core__DOT__id_is_jalr = (IData)(
                                                       (0x00000067U 
                                                        == 
                                                        (0x0000707fU 
                                                         & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __VdfgRegularize_h98839c81_1_4 = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r) 
                                      == (0x0000001fU 
                                          & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                             >> 0x00000014U)));
    __VdfgRegularize_h98839c81_1_3 = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r) 
                                      == (0x0000001fU 
                                          & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                             >> 0x0000000fU)));
    __PVT__u_core__DOT__id_is_muldiv = (IData)((0x02000033U 
                                                == 
                                                (0xfe00007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __PVT__u_core__DOT__csr_rdata = (((((((((0x0300U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U)) 
                                            | (0x0304U 
                                               == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))) 
                                           | (0x0305U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))) 
                                          | (0x0340U 
                                             == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U))) 
                                         | (0x0341U 
                                            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                >> 0x00000014U))) 
                                        | (0x0342U 
                                           == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x00000014U))) 
                                       | (0x0343U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))) 
                                      | (0x0344U == 
                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                          >> 0x00000014U)))
                                      ? ((0x0300U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val
                                          : ((0x0304U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 << 0x0000000bU)
                                              : ((0x0305U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? 
                                                 (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                  << 2U)
                                                  : 
                                                 ((0x0340U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mscratch
                                                   : 
                                                  ((0x0341U 
                                                    == 
                                                    (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))
                                                    ? vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg
                                                    : 
                                                   ((0x0342U 
                                                     == 
                                                     (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))
                                                     ? vlSelfRef.u_core__DOT__u_csr__DOT__mcause_reg
                                                     : 
                                                    ((0x0343U 
                                                      == 
                                                      (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U))
                                                      ? vlSelfRef.u_core__DOT__u_csr__DOT__mtval_reg
                                                      : 
                                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                                      << 0x0000000bU))))))))
                                      : ((0x0c00U == 
                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt)
                                          : ((0x0c80U 
                                              == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                              ? (IData)(
                                                        (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__cycle_cnt 
                                                         >> 0x20U))
                                              : ((0x0c02U 
                                                  == 
                                                  (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt)
                                                  : 
                                                 ((0x0c82U 
                                                   == 
                                                   (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? (IData)(
                                                             (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__instret_cnt 
                                                              >> 0x20U))
                                                   : 0U)))));
    if (((IData)(vlSelfRef.__PVT__u_core__DOT__wb_csr_we) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r) 
            == (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                >> 0x00000014U)))) {
        if ((((((((0x0300U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)) 
                  || (0x0304U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                 || (0x0305U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
                || (0x0340U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
               || (0x0341U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
              || (0x0342U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r))) 
             || (0x0343U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_csr_addr_r)))) {
            __PVT__u_core__DOT__csr_rdata = vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__new_val;
        }
    }
    vlSelfRef.__PVT__u_core__DOT__wb_trap_enter = (
                                                   (~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                   & (IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0));
    vlSelfRef.__PVT__u_core__DOT__ex_mem_advance_to_wb 
        = ((~ ((IData)(u_core__DOT____VdfgExtracted_ha4e5ab41__0) 
               | (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14))) 
           & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r));
    __PVT__u_core__DOT__redirect_target = 0U;
    vlSelfRef.__PVT__u_core__DOT__pc_redirect = 0U;
    if ((1U & (~ (IData)(vlSelfRef.__PVT__mem_stall)))) {
        if (u_core__DOT____VdfgExtracted_ha4e5ab41__0) {
            __PVT__u_core__DOT__redirect_target = (vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                   << 2U);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r))) {
            __PVT__u_core__DOT__redirect_target = vlSelfRef.u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict) {
            __PVT__u_core__DOT__redirect_target = (0xfffffffeU 
                                                   & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r);
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                    & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_mispredict_r))) {
            __PVT__u_core__DOT__redirect_target = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jalr_r)
                                                    ? 
                                                   (0xfffffffeU 
                                                    & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r)
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_branch_taken_r)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_jal_r)
                                                      ? vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_imm_r
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_pc_plus_4_r)));
            vlSelfRef.__PVT__u_core__DOT__pc_redirect = 1U;
        }
    }
    __VdfgRegularize_h98839c81_1_1 = ((0x6fU == (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                      | (IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr));
    __PVT__u_core__DOT__id_imm = ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5)
                                   ? (0xfffff000U & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                   : ((0x6fU == (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))
                                       ? ((((0x00000ffeU 
                                             & ((- (IData)(
                                                           (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000001fU))) 
                                                << 1U)) 
                                            | (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                               >> 0x0000001fU)) 
                                           << 0x00000014U) 
                                          | ((((0x000001feU 
                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x0000000bU)) 
                                               | (1U 
                                                  & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))) 
                                              << 0x0000000bU) 
                                             | (0x000007feU 
                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))))
                                       : (((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                                           | ((3U == 
                                               (0x0000007fU 
                                                & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                              | (0x13U 
                                                 == 
                                                 (0x0000007fU 
                                                  & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))))
                                           ? (((- (IData)(
                                                          (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                           >> 0x0000001fU))) 
                                               << 0x0000000cU) 
                                              | (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                 >> 0x00000014U))
                                           : ((0x23U 
                                               == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))
                                               ? ((
                                                   (- (IData)(
                                                              (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                               >> 0x0000001fU))) 
                                                   << 0x0000000cU) 
                                                  | ((0x00000fe0U 
                                                      & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                         >> 0x00000014U)) 
                                                     | (0x0000001fU 
                                                        & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                           >> 7U))))
                                               : ((0x63U 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.__PVT__u_core__DOT__if_ex_instr))
                                                   ? 
                                                  (((- (IData)(
                                                               (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                                >> 0x0000001fU))) 
                                                    << 0x0000000dU) 
                                                   | ((((2U 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000001eU)) 
                                                        | (1U 
                                                           & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                              >> 7U))) 
                                                       << 0x0000000bU) 
                                                      | ((0x000007e0U 
                                                          & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                             >> 0x00000014U)) 
                                                         | (0x0000001eU 
                                                            & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                               >> 7U)))))
                                                   : 0U)))));
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2 
        = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_ok) 
           & (IData)(__VdfgRegularize_h98839c81_1_4));
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1 
        = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_ok) 
           & (IData)(__VdfgRegularize_h98839c81_1_3));
    __Vtableidx4 = ((((IData)(__PVT__u_core__DOT__id_is_muldiv) 
                      << 5U) | (((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_csr) 
                                 << 4U) | ((3U == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                           << 3U))) 
                    | (((IData)(vlSelfRef.__PVT__u_core__DOT__id_is_jalr) 
                        << 2U) | (((0x6fU == (0x0000007fU 
                                              & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                   << 1U) | (0x17U 
                                             == (0x0000007fU 
                                                 & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)))));
    vlSelfRef.__PVT__u_core__DOT__id_wb_sel = Vtb_axil_equiv__ConstPool__TABLE_hde2d3e75_0
        [__Vtableidx4];
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17 
        = ((IData)(__PVT__u_core__DOT__id_is_muldiv) 
           & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid));
    __PVT__u_core__DOT__u_bp__DOT__rd_hit1 = (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid1
                                              [(0x0000001fU 
                                                & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                   >> 1U))] 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag1
                                                 [(0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                      >> 1U))] 
                                                 == 
                                                 (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                  >> 6U)));
    vlSelfRef.__PVT__u_core__DOT__is_16bit_w = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble)) 
                                                & ((2U 
                                                    & vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                    ? 
                                                   (3U 
                                                    != 
                                                    (3U 
                                                     & (vlSelfRef.__PVT__i_rdata_q 
                                                        >> 0x00000010U)))
                                                    : 
                                                   (3U 
                                                    != 
                                                    (3U 
                                                     & vlSelfRef.__PVT__i_rdata_q))));
    vlSelfRef.__PVT__u_core__DOT__cinstr = (0x0000ffffU 
                                            & ((2U 
                                                & vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                ? (vlSelfRef.__PVT__i_rdata_q 
                                                   >> 0x00000010U)
                                                : vlSelfRef.__PVT__i_rdata_q));
    vlSelfRef.__PVT__u_core__DOT__id_csr_rdata = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                                   & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_we_r) 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_addr_r) 
                                                         == 
                                                         (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                          >> 0x00000014U))))
                                                   ? 
                                                  ((1U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                    ? vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r
                                                    : 
                                                   ((2U 
                                                     == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                     ? 
                                                    (vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r 
                                                     | vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r)
                                                     : 
                                                    ((3U 
                                                      == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_op_r))
                                                      ? 
                                                     ((~ vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_wdata_r) 
                                                      & vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)
                                                      : vlSelfRef.__PVT__u_core__DOT__ex_mem_csr_rdata_r)))
                                                   : __PVT__u_core__DOT__csr_rdata);
    vlSelfRef.__PVT__core_d_mem_wstrb = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r) 
                                          & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                             & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)))
                                          ? (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_store_wstrb_r)
                                          : 0U);
    vlSelfRef.__PVT__d_fire = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                & (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                                    | (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_store_r)) 
                                   & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                      & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_misaligned_r))))) 
                               & ((~ (IData)(vlSelfRef.__PVT__d_busy)) 
                                  & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_18 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
    vlSelfRef.__PVT__u_core__DOT__at_cross_boundary 
        = (IData)(((((0x00030000U == (0x00030000U & vlSelfRef.__PVT__i_rdata_q)) 
                     & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                        >> 1U)) & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
    vlSelfRef.__PVT__u_core__DOT__if_ex_pc_plus_imm 
        = (__PVT__u_core__DOT__id_imm + vlSelfRef.__PVT__u_core__DOT__if_ex_pc);
    vlSelfRef.__PVT__u_core__DOT__rs2_val = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2)
                                              ? __PVT__u_core__DOT__ex_mem_fwd_val
                                              : (((IData)(__PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok) 
                                                  & ((~ (IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs2)) 
                                                     & ((0x0000001fU 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x00000014U)) 
                                                        == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))))
                                                  ? vlSelfRef.u_core__DOT__rfu_wr_data
                                                  : 
                                                 ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U)))
                                                   ? 0U
                                                   : vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs
                                                  [
                                                  (0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))])));
    vlSelfRef.__PVT__u_core__DOT__rs1_val = ((IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1)
                                              ? __PVT__u_core__DOT__ex_mem_fwd_val
                                              : (((IData)(__PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok) 
                                                  & ((~ (IData)(__PVT__u_core__DOT__u_forward__DOT__em_fwd_rs1)) 
                                                     & ((0x0000001fU 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000000fU)) 
                                                        == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))))
                                                  ? vlSelfRef.u_core__DOT__rfu_wr_data
                                                  : 
                                                 ((0U 
                                                   == 
                                                   (0x0000001fU 
                                                    & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                       >> 0x0000000fU)))
                                                   ? 0U
                                                   : vlSelfRef.__PVT__u_core__DOT__u_rfu__DOT__regs
                                                  [
                                                  (0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x0000000fU))])));
    vlSelfRef.__PVT__u_core__DOT__stall = (((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
                                            & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                                               & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r) 
                                                     & ((0U 
                                                         != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r)) 
                                                        & ((IData)(__VdfgRegularize_h98839c81_1_3) 
                                                           | (IData)(__VdfgRegularize_h98839c81_1_4))))))) 
                                           | ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
                                              & ((IData)(__PVT__u_core__DOT__id_is_muldiv) 
                                                 & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid)) 
                                                    & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17)))));
    vlSelfRef.__PVT__u_core__DOT__bp_predict_target 
        = ((IData)(__PVT__u_core__DOT__u_bp__DOT__rd_hit1)
            ? vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target1
           [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))] : vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__target0
           [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))]);
    vlSelfRef.__PVT__u_core__DOT__bp_predict_taken 
        = ((vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__valid0
            [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                             >> 1U))] & ((vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__tag0
                                          [(0x0000001fU 
                                            & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                               >> 1U))] 
                                          == (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                              >> 6U)) 
                                         & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter0
                                            [(0x0000001fU 
                                              & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                 >> 1U))] 
                                            >> 1U))) 
           | ((IData)(__PVT__u_core__DOT__u_bp__DOT__rd_hit1) 
              & (vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__counter1
                 [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                  >> 1U))] >> 1U)));
    vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 0U;
    u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
        = (0x00042403U | (((((8U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                    >> 2U)) | (7U & 
                                               ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                >> 0x0000000aU))) 
                            << 0x00000017U) | (0x00400000U 
                                               & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                  << 0x00000010U))) 
                          | ((0x00038000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                             << 8U)) 
                             | (0x00000380U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               << 5U)))));
    __PVT__u_core__DOT__u_cdec__DOT__imm_addi = ((0x00000fe0U 
                                                  & ((- (IData)(
                                                                (1U 
                                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                                    >> 0x0000000cU)))) 
                                                     << 5U)) 
                                                 | (0x0000001fU 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 2U)));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13 
        = (((((4U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                     >> 6U)) | (3U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 9U))) << 7U) 
            | (((2U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                       >> 5U)) | (1U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                        >> 7U))) << 5U)) 
           | ((0x00000010U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              << 2U)) | ((8U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                >> 8U)) 
                                         | (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                  >> 3U)))));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6 
        = (0x00045413U | ((0x00038000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                          << 8U)) | 
                          (0x00000380U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7 
        = ((0x00000038U & ((- (IData)((1U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                             >> 0x0000000cU)))) 
                           << 3U)) | ((6U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                             >> 4U)) 
                                      | (1U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               >> 2U))));
    u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9 
        = (0x63U | ((0x00000c00U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)) 
                    | ((0x00000300U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                       << 5U)) | (0x00000080U 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                     >> 5U)))));
    vlSelfRef.__PVT__u_core__DOT__md_start = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_started)) 
                                              & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_17) 
                                                 & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__md_result_valid)) 
                                                    & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                                                       & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16)))));
    __PVT__u_core__DOT__alu_op_b = (((0x13U == (0x0000007fU 
                                                & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                     | ((IData)(vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
                                        | ((3U == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                           | ((0x23U 
                                               == (0x0000007fU 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                              | (IData)(__VdfgRegularize_h98839c81_1_1)))))
                                     ? __PVT__u_core__DOT__id_imm
                                     : vlSelfRef.__PVT__u_core__DOT__rs2_val);
    vlSelfRef.__PVT__u_core__DOT__store_addr_lo = (3U 
                                                   & (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                      + __PVT__u_core__DOT__id_imm));
    vlSelfRef.__PVT__u_core__DOT__id_csr_wdata = ((0x00004000U 
                                                   & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)
                                                   ? 
                                                  (0x0000001fU 
                                                   & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                      >> 0x0000000fU))
                                                   : vlSelfRef.__PVT__u_core__DOT__rs1_val);
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_15 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)))));
    vlSelfRef.__PVT__i_fire = (1U & (((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                      & (~ (IData)(vlSelfRef.__PVT__i_busy))) 
                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect) 
                                        | ((IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup) 
                                           | ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                              | (IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary))))));
    vlSelfRef.__PVT__u_core__DOT__any_stall = ((IData)(vlSelfRef.__PVT__u_core__DOT__stall) 
                                               | ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                                                  | ((IData)(vlSelfRef.__PVT__u_core__DOT__warmup) 
                                                     | ((IData)(vlSelfRef.__PVT__mem_stall) 
                                                        | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup)))));
    vlSelfRef.__PVT__u_core__DOT__ras_push = (IData)(
                                                     ((((0x000000efU 
                                                         == 
                                                         (0x00000fffU 
                                                          & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                        & (IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid)) 
                                                       & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall))) 
                                                      & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18)));
    vlSelfRef.__PVT__u_core__DOT__cdec_expanded = 0U;
    if ((2U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
        if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        } else if ((0x00008000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                    vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                }
            } else if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0cU)))) {
                if ((0U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                           >> 2U)))) {
                    if ((0U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               >> 7U)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                }
            }
        } else if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            } else if ((0U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              >> 7U)))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            }
        } else if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        } else if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))) {
            if ((0x00008000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                    if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                  >> 0x0000000dU)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x00012023U | ((((0x000000c0U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    >> 1U)) 
                                                | ((0x00000020U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 7U)) 
                                                   | (0x0000001fU 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 2U)))) 
                                               << 0x00000014U) 
                                              | (0x00000e00U 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
                    }
                } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                     >> 0x0000000dU)))) {
                    if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = ((0U == (0x0000001fU 
                                       & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                          >> 2U))) ? 
                               ((0U == (0x0000001fU 
                                        & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                           >> 7U)))
                                 ? 0x00100073U : (0x00e7U 
                                                  | (0x000f8000U 
                                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                        << 8U))))
                                : (0x33U | ((0x01f00000U 
                                             & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                << 0x00000012U)) 
                                            | ((0x000f8000U 
                                                & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                   << 8U)) 
                                               | (0x00000f80U 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))));
                    } else if ((0U == (0x0000001fU 
                                       & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                          >> 2U)))) {
                        if ((0U != (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                   >> 7U)))) {
                            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                                = (0x0067U | (0x000f8000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)));
                        }
                    } else {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x33U | ((0x01f00000U 
                                         & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                            << 0x00000012U)) 
                                        | (0x00000f80U 
                                           & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
                    }
                }
            } else if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                    if ((0U != (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               >> 7U)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x00012003U | ((((0x00000030U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    << 2U)) 
                                                | ((8U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 9U)) 
                                                   | (7U 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 4U)))) 
                                               << 0x00000016U) 
                                              | (0x00000f80U 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
                    }
                }
            } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0000000dU)))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0cU)))) {
                    vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                        = (0x00001013U | ((0x01f00000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x000f8000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000f80U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))));
                }
            }
        }
    } else if ((1U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
        if ((0x00008000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                          >> 0x0000000eU)))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                    if ((0x00000800U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                            if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                            }
                        }
                    } else if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                        }
                    } else if ((0x00001000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                }
            }
            if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                        ? (0x00041000U | ((0x80000000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000013U)) 
                                          | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7) 
                                              << 0x00000019U) 
                                             | ((0x00038000U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    << 8U)) 
                                                | (IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9)))))
                        : (0x00040000U | ((0x80000000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000013U)) 
                                          | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7) 
                                              << 0x00000019U) 
                                             | ((0x00038000U 
                                                 & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                    << 8U)) 
                                                | (IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9))))));
            } else if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = (0x006fU | ((((0x00000800U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13) 
                                                  << 1U) 
                                                 | (1U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 0x0000000cU)))) 
                                   << 0x00000014U) 
                                  | (0x000ff000U & 
                                     ((- (IData)((1U 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                     >> 0x0000000cU)))) 
                                      << 0x0000000bU))));
            } else if ((0x00000800U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                    if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                  >> 0x0cU)))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = ((0x00000040U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                                ? ((0x00000020U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                                    ? (0x00847433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))))
                                    : (0x00846433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))))
                                : ((0x00000020U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                                    ? (0x00844433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))))
                                    : (0x40840433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))))));
                    }
                } else {
                    vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                        = (0x00047413U | (((IData)(__PVT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                           << 0x00000014U) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))));
                }
            } else if ((0x00000400U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0cU)))) {
                    vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                        = (0x40000000U | ((0x01f00000U 
                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6));
                }
            } else if ((1U & (~ ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0cU)))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = ((0x01f00000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                       << 0x00000012U)) 
                       | u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6);
            }
        } else if ((0x00004000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
            if ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) {
                if ((2U == (0x0000001fU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                           >> 7U)))) {
                    if ((IData)((0U == (0x107cU & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                    if ((1U & (~ (IData)((0U == (0x107cU 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x00010113U | (((- (IData)(
                                                          (1U 
                                                           & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                              >> 0x0000000cU)))) 
                                               << 0x0000001dU) 
                                              | ((((6U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 2U)) 
                                                   | (1U 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 5U))) 
                                                  << 0x0000001aU) 
                                                 | ((0x02000000U 
                                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                        << 0x00000017U)) 
                                                    | (0x01000000U 
                                                       & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                          << 0x00000012U))))));
                    }
                } else {
                    if ((IData)((0U == (0x107cU & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
                    }
                    if ((1U & (~ (IData)((0U == (0x107cU 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))))) {
                        vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                            = (0x37U | (((- (IData)(
                                                    (1U 
                                                     & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                        >> 0x0000000cU)))) 
                                         << 0x00000011U) 
                                        | ((0x0001f000U 
                                            & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                               << 0x0000000aU)) 
                                           | (0x00000f80U 
                                              & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))));
                    }
                }
            } else {
                vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                    = (0x13U | (((IData)(__PVT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                 << 0x00000014U) | 
                                (0x00000f80U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))));
            }
        } else {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = ((0x00002000U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))
                    ? (0x00efU | ((((0x00000800U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((IData)(u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13) 
                                                  << 1U) 
                                                 | (1U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 0x0000000cU)))) 
                                   << 0x00000014U) 
                                  | (0x000ff000U & 
                                     ((- (IData)((1U 
                                                  & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                     >> 0x0000000cU)))) 
                                      << 0x0000000bU))))
                    : (0x13U | (((IData)(__PVT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                 << 0x00000014U) | 
                                ((0x000f8000U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                 | (0x00000f80U & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))))));
        }
    } else if ((0U == (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                             >> 0x0000000dU)))) {
        if ((0U == (0x000000ffU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                   >> 5U)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
        }
        if ((0U != (0x000000ffU & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                   >> 5U)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = (0x00010413U | ((((0x000003c0U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((
                                                   (6U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 0x0000000aU)) 
                                                   | (1U 
                                                      & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                         >> 5U))) 
                                                  << 3U) 
                                                 | (4U 
                                                    & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                                       >> 4U)))) 
                                   << 0x00000014U) 
                                  | (0x00000380U & 
                                     ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                      << 5U))));
        }
    } else {
        if ((2U != (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                          >> 0x0000000dU)))) {
            if ((6U != (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                vlSelfRef.__PVT__u_core__DOT__cdec_illegal = 1U;
            }
        }
        if ((2U == (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                          >> 0x0000000dU)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0;
        } else if ((6U == (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                 >> 0x0000000dU)))) {
            vlSelfRef.__PVT__u_core__DOT__cdec_expanded 
                = (0x00842023U | ((((0x00003f80U & 
                                     (u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
                                      >> 0x00000012U)) 
                                    | (0x0000001cU 
                                       & (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr))) 
                                   << 0x00000012U) 
                                  | ((0x00038000U & 
                                      ((IData)(vlSelfRef.__PVT__u_core__DOT__cinstr) 
                                       << 8U)) | (0x00000f80U 
                                                  & (u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
                                                     >> 0x0000000dU)))));
        }
    }
    __PVT__u_core__DOT__alu_cmp_eq = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                      == __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_s = VL_LTS_III(32, vlSelfRef.__PVT__u_core__DOT__rs1_val, __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_u = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                        < __PVT__u_core__DOT__alu_op_b);
    vlSelfRef.__PVT__u_core__DOT__id_advance_to_ex_mem 
        = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__instr_assembled = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble)
          ? ((vlSelfRef.__PVT__i_rdata_q << 0x00000010U) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__residue))
          : ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
              ? vlSelfRef.__PVT__u_core__DOT__cdec_expanded
              : vlSelfRef.__PVT__i_rdata_q));
    vlSelfRef.__PVT__u_core__DOT__alu_result = ((8U 
                                                 & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                 ? 
                                                ((4U 
                                                  & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                  ? 0U
                                                  : 
                                                 ((2U 
                                                   & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? __PVT__u_core__DOT__alu_op_b
                                                    : (IData)(__PVT__u_core__DOT__alu_cmp_eq))
                                                   : 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? (IData)(__PVT__u_core__DOT__alu_cmp_lt_u)
                                                    : (IData)(__PVT__u_core__DOT__alu_cmp_lt_s))))
                                                 : 
                                                ((4U 
                                                  & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                  ? 
                                                 ((2U 
                                                   & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   VL_SHIFTRS_III(32,32,5, vlSelfRef.__PVT__u_core__DOT__rs1_val, 
                                                                  (0x0000001fU 
                                                                   & __PVT__u_core__DOT__alu_op_b))
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    >> 
                                                    (0x0000001fU 
                                                     & __PVT__u_core__DOT__alu_op_b)))
                                                   : 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    << 
                                                    (0x0000001fU 
                                                     & __PVT__u_core__DOT__alu_op_b))
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    ^ __PVT__u_core__DOT__alu_op_b)))
                                                  : 
                                                 ((2U 
                                                   & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                   ? 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    | __PVT__u_core__DOT__alu_op_b)
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    & __PVT__u_core__DOT__alu_op_b))
                                                   : 
                                                  ((1U 
                                                    & (IData)(__PVT__u_core__DOT__id_alu_op))
                                                    ? 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    - __PVT__u_core__DOT__alu_op_b)
                                                    : 
                                                   (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                                    + __PVT__u_core__DOT__alu_op_b)))));
    vlSelfRef.__PVT__u_core__DOT__branch_taken = ((0x63U 
                                                   == 
                                                   (0x0000007fU 
                                                    & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                  & (((0x63U 
                                                       == 
                                                       (0x0000007fU 
                                                        & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
                                                      & ((1U 
                                                          == 
                                                          (7U 
                                                           & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                              >> 0x0000000cU))) 
                                                         | ((5U 
                                                             == 
                                                             (7U 
                                                              & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                                 >> 0x0000000cU))) 
                                                            | (7U 
                                                               == 
                                                               (7U 
                                                                & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                                   >> 0x0000000cU)))))) 
                                                     ^ 
                                                     ((0U 
                                                       == 
                                                       (3U 
                                                        & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                           >> 0x0000000dU)))
                                                       ? (IData)(__PVT__u_core__DOT__alu_cmp_eq)
                                                       : 
                                                      ((2U 
                                                        == 
                                                        (3U 
                                                         & (vlSelfRef.__PVT__u_core__DOT__if_ex_instr 
                                                            >> 0x0000000dU)))
                                                        ? (IData)(__PVT__u_core__DOT__alu_cmp_lt_s)
                                                        : (IData)(__PVT__u_core__DOT__alu_cmp_lt_u)))));
    vlSelfRef.__PVT__u_core__DOT__ras_pop = (((IData)(
                                                      (0x00008067U 
                                                       == 
                                                       (0x000fffffU 
                                                        & vlSelfRef.__PVT__u_core__DOT__instr_assembled))) 
                                              | ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w) 
                                                 & (0x8082U 
                                                    == (IData)(vlSelfRef.__PVT__u_core__DOT__cinstr)))) 
                                             & ((0U 
                                                 != vlSelfRef.__PVT__u_core__DOT__ras_top) 
                                                & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)) 
                                                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)))));
    vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__branch_taken) 
            | (IData)(__VdfgRegularize_h98839c81_1_1)));
    vlSelfRef.__PVT__u_core__DOT__next_pc_w = ((IData)(vlSelfRef.__PVT__u_core__DOT__pc_redirect)
                                                ? __PVT__u_core__DOT__redirect_target
                                                : ((IData)(vlSelfRef.__PVT__u_core__DOT__any_stall)
                                                    ? vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg
                                                    : 
                                                   ((IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop)
                                                     ? vlSelfRef.__PVT__u_core__DOT__ras_top
                                                     : 
                                                    ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken)
                                                      ? vlSelfRef.__PVT__u_core__DOT__bp_predict_target
                                                      : 
                                                     (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                      + 
                                                      ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
                                                        ? 2U
                                                        : 4U))))));
    __VdfgRegularize_h98839c81_1_0 = ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__stall)) 
                                      & ((IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16) 
                                         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__bp_predict_taken) 
                                                | (IData)(vlSelfRef.__PVT__u_core__DOT__ras_pop))) 
                                            & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_18))));
    vlSelfRef.__PVT__u_core__DOT__consecutive_cross 
        = ((((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble) 
             & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (IData)(__VdfgRegularize_h98839c81_1_0));
    vlSelfRef.__PVT__u_core__DOT__upcoming_cross = 
        (((((~ (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.__PVT__i_rdata_q))) 
           & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
          & (IData)(__VdfgRegularize_h98839c81_1_0)) 
         & (3U != (3U & vlSelfRef.__PVT__i_rdata_q)));
    vlSelfRef.__PVT__core_i_mem_addr = ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary)
                                         ? ((IData)(2U) 
                                            + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                         : ((IData)(vlSelfRef.__PVT__u_core__DOT__consecutive_cross)
                                             ? ((IData)(6U) 
                                                + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                             : ((IData)(vlSelfRef.__PVT__u_core__DOT__upcoming_cross)
                                                 ? 
                                                ((IData)(4U) 
                                                 + vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                 : vlSelfRef.__PVT__u_core__DOT__next_pc_w)));
}
