// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_equiv.h for the primary calling header

#include "Vtb_axil_equiv__pch.h"

extern const VlUnpacked<CData/*2:0*/, 64> Vtb_axil_equiv__ConstPool__TABLE_hde2d3e75_0;
extern const VlUnpacked<CData/*1:0*/, 32> Vtb_axil_equiv__ConstPool__TABLE_hdb09954d_0;

VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_native__0(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_native__0\n"); );
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
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit0;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit0 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit1;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit1 = 0;
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
    CData/*4:0*/ __Vtableidx3;
    __Vtableidx3 = 0;
    VlWide<3>/*95:0*/ __Vtemp_3;
    VlWide<3>/*95:0*/ __Vtemp_4;
    VlWide<3>/*95:0*/ __Vtemp_6;
    VlWide<3>/*95:0*/ __Vtemp_7;
    VlWide<3>/*95:0*/ __Vtemp_8;
    // Body
    vlSelfRef.__PVT__i_boot = (1U & (~ (IData)(vlSelfRef.__PVT__primed)));
    vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__top_idx 
        = (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                 - (IData)(1U)));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9 
        = ((3U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    vlSelfRef.__PVT__u_core__DOT__ras_push_val = (vlSelfRef.__PVT__u_core__DOT__if_ex_pc 
                                                  + 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit)
                                                    ? 2U
                                                    : 4U));
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
    vlSelfRef.__PVT__u_core__DOT__md_done = ((IData)(vlSelfRef.__PVT__u_core__DOT__md_active_is_div)
                                              ? (IData)(vlSelfRef.__PVT__u_core__DOT__div_done)
                                              : (IData)(vlSelfRef.__PVT__u_core__DOT__mul_done));
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
        = (((QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)) 
            << 1U) | (QData)((IData)((vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                                      >> 0x0000001fU))));
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
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val 
        = (0x00001800U | (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie) 
                           << 7U) | ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie) 
                                     << 3U)));
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
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
    vlSelfRef.__PVT__u_core__DOT__ras_top = ((0U == (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))
                                              ? 0U : vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack
                                             [(7U & 
                                               ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                                                - (IData)(1U)))]);
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
    vlSelfRef.__PVT__u_core__DOT__at_cross_boundary 
        = (IData)(((((0x00030000U == (0x00030000U & vlSelfRef.__PVT__i_rdata_q)) 
                     & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                        >> 1U)) & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
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
    vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 
        = ((0x37U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x17U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 
        ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
            & (0U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))));
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
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r) 
         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                | (0U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r)))) 
            & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)));
    vlSelfRef.__PVT__u_core__DOT__id_is_jalr = (IData)(
                                                       (0x00000067U 
                                                        == 
                                                        (0x0000707fU 
                                                         & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
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
    vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r) 
              & ((0xfffffffeU & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                 != vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_target_r)));
    vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap 
        = ((IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
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
    vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.__PVT__u_core__DOT__cinstr = (0x0000ffffU 
                                            & ((2U 
                                                & vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                ? (vlSelfRef.__PVT__i_rdata_q 
                                                   >> 0x00000010U)
                                                : vlSelfRef.__PVT__i_rdata_q));
    vlSelfRef.__PVT__mem_stall = (((IData)(vlSelfRef.__PVT__i_busy) 
                                   | ((~ (IData)(vlSelfRef.__PVT__primed)) 
                                      | (IData)(vlSelfRef.__PVT__d_busy))) 
                                  & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn));
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w 
        = (0x00000001ffffffffULL & (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
                                    - (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__divisor))));
    vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way 
        = ((IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit1) 
           | ((~ (IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit0)) 
              & vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru
              [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                               >> 1U))]));
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
    vlSelfRef.__PVT__u_core__DOT__bp_upd_valid = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_trap_exit = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
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
    __PVT__u_core__DOT__wb_take_irq = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                       & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                          & (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                                             & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13))));
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
    vlSelfRef.__PVT__u_core__DOT__any_stall = ((IData)(vlSelfRef.__PVT__u_core__DOT__stall) 
                                               | ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                                                  | ((IData)(vlSelfRef.__PVT__u_core__DOT__warmup) 
                                                     | ((IData)(vlSelfRef.__PVT__mem_stall) 
                                                        | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup)))));
    vlSelfRef.__PVT__u_core__DOT__instr_assembled = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble)
          ? ((vlSelfRef.__PVT__i_rdata_q << 0x00000010U) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__residue))
          : ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
              ? vlSelfRef.__PVT__u_core__DOT__cdec_expanded
              : vlSelfRef.__PVT__i_rdata_q));
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
    __PVT__u_core__DOT__alu_cmp_eq = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                      == __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_s = VL_LTS_III(32, vlSelfRef.__PVT__u_core__DOT__rs1_val, __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_u = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                        < __PVT__u_core__DOT__alu_op_b);
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
    vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__branch_taken) 
            | (IData)(__VdfgRegularize_h98839c81_1_1)));
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

VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0\n"); );
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
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit0;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit0 = 0;
    CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_hit1;
    __PVT__u_core__DOT__u_bp__DOT__wr_hit1 = 0;
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
    CData/*4:0*/ __Vtableidx6;
    __Vtableidx6 = 0;
    VlWide<3>/*95:0*/ __Vtemp_3;
    VlWide<3>/*95:0*/ __Vtemp_4;
    VlWide<3>/*95:0*/ __Vtemp_6;
    VlWide<3>/*95:0*/ __Vtemp_7;
    VlWide<3>/*95:0*/ __Vtemp_8;
    // Body
    vlSelfRef.__PVT__i_boot = (1U & (~ (IData)(vlSelfRef.__PVT__primed)));
    vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__top_idx 
        = (7U & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                 - (IData)(1U)));
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_9 
        = ((3U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x23U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    vlSelfRef.ibus_ready = ((2U == (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state)) 
                            & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__a_i_rvalid));
    vlSelfRef.__PVT__u_core__DOT__ras_push_val = (vlSelfRef.__PVT__u_core__DOT__if_ex_pc 
                                                  + 
                                                  ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_is_16bit)
                                                    ? 2U
                                                    : 4U));
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
    vlSelfRef.__PVT__u_core__DOT__md_done = ((IData)(vlSelfRef.__PVT__u_core__DOT__md_active_is_div)
                                              ? (IData)(vlSelfRef.__PVT__u_core__DOT__div_done)
                                              : (IData)(vlSelfRef.__PVT__u_core__DOT__mul_done));
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
        = (((QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__remainder)) 
            << 1U) | (QData)((IData)((vlSelfRef.__PVT__u_core__DOT__u_div__DOT__dividend 
                                      >> 0x0000001fU))));
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
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_mret_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.u_core__DOT__u_csr__DOT__mstatus_val 
        = (0x00001800U | (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie) 
                           << 7U) | ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie) 
                                     << 3U)));
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
    vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_16 
        = (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
    vlSelfRef.__PVT__u_core__DOT__ras_top = ((0U == (IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr))
                                              ? 0U : vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__stack
                                             [(7U & 
                                               ((IData)(vlSelfRef.__PVT__u_core__DOT__u_ras__DOT__ptr) 
                                                - (IData)(1U)))]);
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
    vlSelfRef.__PVT__u_core__DOT__at_cross_boundary 
        = (IData)(((((0x00030000U == (0x00030000U & vlSelfRef.__PVT__i_rdata_q)) 
                     & (vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg 
                        >> 1U)) & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble))) 
                   & (~ (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup))));
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
    vlSelfRef.u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 
        = ((0x37U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)) 
           | (0x17U == (0x0000007fU & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
    __PVT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 
        ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_we_r) 
            & (0U != (IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_rd_idx_r))));
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
    __PVT__u_core__DOT__u_forward__DOT__em_fwd_ok = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_we_r) 
         & ((~ ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_is_load_r) 
                | (0U == (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_rd_idx_r)))) 
            & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r)));
    vlSelfRef.__PVT__u_core__DOT__id_is_jalr = (IData)(
                                                       (0x00000067U 
                                                        == 
                                                        (0x0000707fU 
                                                         & vlSelfRef.__PVT__u_core__DOT__if_ex_instr)));
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
    vlSelfRef.__PVT__u_core__DOT__mem_ras_mispredict 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_valid_r) 
           & ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_r) 
              & ((0xfffffffeU & vlSelfRef.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                 != vlSelfRef.__PVT__u_core__DOT__ex_mem_pred_ras_target_r)));
    vlSelfRef.__PVT__u_core__DOT__wb_take_sync_trap 
        = ((IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
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
    vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap 
        = ((IData)(vlSelfRef.__PVT__u_core__DOT__ex_wb_is_misaligned_r) 
           & (IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r));
    vlSelfRef.__PVT__u_core__DOT__cinstr = (0x0000ffffU 
                                            & ((2U 
                                                & vlSelfRef.__PVT__u_core__DOT__u_ifu__DOT__pc_reg)
                                                ? (vlSelfRef.__PVT__i_rdata_q 
                                                   >> 0x00000010U)
                                                : vlSelfRef.__PVT__i_rdata_q));
    vlSelfRef.__PVT__mem_stall = (((IData)(vlSelfRef.__PVT__i_busy) 
                                   | ((~ (IData)(vlSelfRef.__PVT__primed)) 
                                      | (IData)(vlSelfRef.__PVT__d_busy))) 
                                  & (IData)(vlSymsp->TOP.tb_axil_equiv__DOT__resetn));
    vlSelfRef.__PVT__u_core__DOT__u_div__DOT__sub_w 
        = (0x00000001ffffffffULL & (vlSelfRef.__PVT__u_core__DOT__u_div__DOT__shifted_rem 
                                    - (QData)((IData)(vlSelfRef.__PVT__u_core__DOT__u_div__DOT__divisor))));
    vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__wr_way 
        = ((IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit1) 
           | ((~ (IData)(__PVT__u_core__DOT__u_bp__DOT__wr_hit0)) 
              & vlSelfRef.__PVT__u_core__DOT__u_bp__DOT__lru
              [(0x0000001fU & (vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_pc_r 
                               >> 1U))]));
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
    vlSelfRef.__PVT__u_core__DOT__bp_upd_valid = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.__PVT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.__PVT__u_core__DOT__wb_trap_exit = ((~ (IData)(vlSelfRef.__PVT__mem_stall)) 
                                                  & (IData)(vlSelfRef.u_core__DOT____VdfgRegularize_hbfa0e40b_0_14));
    u_core__DOT____VdfgRegularize_hbfa0e40b_0_13 = 
        (1U & ((~ (IData)(vlSelfRef.__PVT__u_core__DOT__wb_take_data_trap)) 
               & (~ (IData)(vlSelfRef.__PVT__mem_stall))));
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
    __PVT__u_core__DOT__wb_take_irq = ((IData)(vlSelfRef.u_core__DOT__ex_wb_valid_r) 
                                       & ((~ (IData)(vlSelfRef.u_core__DOT__ex_wb_illegal_r)) 
                                          & (((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__ext_pending) 
                                              & ((IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                 & (IData)(vlSelfRef.__PVT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                                             & (IData)(u_core__DOT____VdfgRegularize_hbfa0e40b_0_13))));
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
    vlSelfRef.__PVT__u_core__DOT__any_stall = ((IData)(vlSelfRef.__PVT__u_core__DOT__stall) 
                                               | ((IData)(vlSelfRef.__PVT__u_core__DOT__at_cross_boundary) 
                                                  | ((IData)(vlSelfRef.__PVT__u_core__DOT__warmup) 
                                                     | ((IData)(vlSelfRef.__PVT__mem_stall) 
                                                        | (IData)(vlSelfRef.__PVT__u_core__DOT__redirect_warmup)))));
    vlSelfRef.__PVT__u_core__DOT__instr_assembled = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__cross_assemble)
          ? ((vlSelfRef.__PVT__i_rdata_q << 0x00000010U) 
             | (IData)(vlSelfRef.__PVT__u_core__DOT__residue))
          : ((IData)(vlSelfRef.__PVT__u_core__DOT__is_16bit_w)
              ? vlSelfRef.__PVT__u_core__DOT__cdec_expanded
              : vlSelfRef.__PVT__i_rdata_q));
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
    __PVT__u_core__DOT__alu_cmp_eq = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                      == __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_s = VL_LTS_III(32, vlSelfRef.__PVT__u_core__DOT__rs1_val, __PVT__u_core__DOT__alu_op_b);
    __PVT__u_core__DOT__alu_cmp_lt_u = (vlSelfRef.__PVT__u_core__DOT__rs1_val 
                                        < __PVT__u_core__DOT__alu_op_b);
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
    vlSelfRef.__PVT__u_core__DOT__ex_bp_upd_taken = 
        ((IData)(vlSelfRef.__PVT__u_core__DOT__if_ex_valid) 
         & ((IData)(vlSelfRef.__PVT__u_core__DOT__branch_taken) 
            | (IData)(__VdfgRegularize_h98839c81_1_1)));
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

VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
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
}

VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___ctor_var_reset(Vtb_axil_equiv_cpu_m1_top* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+          Vtb_axil_equiv_cpu_m1_top___ctor_var_reset\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16707436170211756652ull);
    vlSelf->resetn = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8624841754543469506ull);
    vlSelf->trap = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18214934560881419504ull);
    vlSelf->ibus_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4728280238163139141ull);
    vlSelf->ibus_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7818720444615025944ull);
    vlSelf->ibus_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10625525792707634439ull);
    vlSelf->ibus_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13824897308939690201ull);
    vlSelf->dbus_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4119656625637298439ull);
    vlSelf->dbus_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8555123167331676470ull);
    vlSelf->dbus_we = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11428982153371631309ull);
    vlSelf->dbus_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1443727012420006035ull);
    vlSelf->dbus_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9784125303306473671ull);
    vlSelf->dbus_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17098717719526010175ull);
    vlSelf->dbus_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10636091878541624289ull);
    vlSelf->irq_external_pulse = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13928215328814940397ull);
    vlSelf->dbg_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4205037871569850614ull);
    vlSelf->dbg_instr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5102080412507105400ull);
    vlSelf->dbg_state = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 9035414299298431771ull);
    vlSelf->__PVT__core_i_mem_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8084817670266254575ull);
    vlSelf->__PVT__core_d_mem_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1789529629920172854ull);
    vlSelf->__PVT__i_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9340679651569923311ull);
    vlSelf->__PVT__i_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9344979234194300238ull);
    vlSelf->__PVT__i_rdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17679083828540234897ull);
    vlSelf->__PVT__d_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8743646663199159392ull);
    vlSelf->__PVT__d_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1660500052239739285ull);
    vlSelf->__PVT__d_wdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14696515695544001685ull);
    vlSelf->__PVT__d_wstrb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6930045633666226545ull);
    vlSelf->__PVT__d_rdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6998223711218741535ull);
    vlSelf->__PVT__primed = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 228240992272248296ull);
    vlSelf->__PVT__mem_stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10055551849590167079ull);
    vlSelf->__PVT__i_boot = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16623958572544096646ull);
    vlSelf->__PVT__i_fire = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8799392039153456591ull);
    vlSelf->__PVT__d_fire = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16230583277536304104ull);
    vlSelf->__PVT__d_xfer = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10608537948074680948ull);
    vlSelf->__PVT__u_core__DOT__warmup = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16431743488483697277ull);
    vlSelf->__PVT__u_core__DOT__next_pc_w = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13014397825085544386ull);
    vlSelf->__PVT__u_core__DOT__pc_redirect = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5825090752002067444ull);
    vlSelf->__PVT__u_core__DOT__stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6226658976738168842ull);
    vlSelf->__PVT__u_core__DOT__redirect_warmup = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13574822328197427216ull);
    vlSelf->__PVT__u_core__DOT__bp_predict_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10177504895931236070ull);
    vlSelf->__PVT__u_core__DOT__bp_predict_target = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4722523482662774813ull);
    vlSelf->__PVT__u_core__DOT__bp_upd_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12479648488208430044ull);
    vlSelf->__PVT__u_core__DOT__ras_top = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3405411481027389122ull);
    vlSelf->__PVT__u_core__DOT__ras_push = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8132974879220474193ull);
    vlSelf->__PVT__u_core__DOT__ras_push_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8682742738779931961ull);
    vlSelf->__PVT__u_core__DOT__ras_pop = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1215241864052683435ull);
    vlSelf->__PVT__u_core__DOT__residue = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 14702982531313646739ull);
    vlSelf->__PVT__u_core__DOT__cross_assemble = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16260163724018489134ull);
    vlSelf->__PVT__u_core__DOT__at_cross_boundary = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14021787136739339387ull);
    vlSelf->__PVT__u_core__DOT__upcoming_cross = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10862156140008091364ull);
    vlSelf->__PVT__u_core__DOT__consecutive_cross = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9028406564094090398ull);
    vlSelf->__PVT__u_core__DOT__is_16bit_w = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11070184269567160263ull);
    vlSelf->__PVT__u_core__DOT__any_stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10012248788646449871ull);
    vlSelf->__PVT__u_core__DOT__cinstr = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 13037644718470564890ull);
    vlSelf->__PVT__u_core__DOT__cdec_expanded = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11491664421125736751ull);
    vlSelf->__PVT__u_core__DOT__cdec_illegal = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15119228496774823964ull);
    vlSelf->__PVT__u_core__DOT__instr_assembled = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14614329831154242552ull);
    vlSelf->__PVT__u_core__DOT__if_ex_instr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15674176515057427711ull);
    vlSelf->__PVT__u_core__DOT__if_ex_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10640439230436367957ull);
    vlSelf->__PVT__u_core__DOT__if_ex_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5185186930379853352ull);
    vlSelf->__PVT__u_core__DOT__if_ex_pred_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 811719465166826692ull);
    vlSelf->__PVT__u_core__DOT__if_ex_pred_ras = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10024696664832928258ull);
    vlSelf->__PVT__u_core__DOT__if_ex_pred_target = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5307255406813656032ull);
    vlSelf->__PVT__u_core__DOT__if_ex_pred_ras_target = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2160713056518529657ull);
    vlSelf->__PVT__u_core__DOT__if_ex_is_16bit = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1893651187148466797ull);
    vlSelf->__PVT__u_core__DOT__id_wb_sel = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 15916282590168202140ull);
    vlSelf->__PVT__u_core__DOT__id_is_jalr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16078988946137131145ull);
    vlSelf->__PVT__u_core__DOT__id_is_csr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11528317930990634959ull);
    vlSelf->u_core__DOT__rfu_we = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10498998442770964277ull);
    vlSelf->u_core__DOT__rfu_wr_data = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7855467198425623676ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_valid_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7607127945235000173ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_pc_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6518448482358989550ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_alu_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10393743662730013228ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_md_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5596178000479633603ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_pc_plus_4_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11037975135295613825ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_pc_plus_imm_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10502875259192900980ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_csr_rdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17702914072251867044ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_rd_idx_r = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 10204775299381979090ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_rd_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 956872955435500160ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_wb_sel_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 15379146365833348327ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_load_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9392080410427152364ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_store_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5960910503160114179ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_ls_funct3_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 493773007322846333ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_addr_lo_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 5767431627540586895ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_store_wdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3552568673943289534ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_store_wstrb_r = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 18380911330657058500ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_mret_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2579237750003404927ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_misaligned_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9212244527897900609ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_misaligned_store_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17216751604964311014ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_csr_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 905778801797393976ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_csr_addr_r = VL_SCOPED_RAND_RESET_I(12, __VscopeHash, 2922420410385877010ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_csr_op_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 8767250602313267357ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_csr_wdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17946775428564198594ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_branch_taken_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 220124744757003901ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_jal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4761176313029784720ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_jalr_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9205904577799197359ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_illegal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6653374802652674883ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_ecall_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6919181402940779588ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_is_ebreak_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1104283482250206770ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_instr_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5344367871601695420ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_mispredict_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10476020856903608068ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_bp_upd_valid_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8073444220547920597ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_bp_upd_pc_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7550922723737569586ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_bp_upd_taken_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 34567732580606686ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_bp_upd_target_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9736445422086926366ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_pred_ras_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6538754473045953604ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_pred_ras_target_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9408697496610153552ull);
    vlSelf->__PVT__u_core__DOT__id_advance_to_ex_mem = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13831540664678799248ull);
    vlSelf->__PVT__u_core__DOT__rs1_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7244490819497681513ull);
    vlSelf->__PVT__u_core__DOT__rs2_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12767491851179312941ull);
    vlSelf->__PVT__u_core__DOT__alu_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 436381652877752028ull);
    vlSelf->__PVT__u_core__DOT__branch_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 607914387110559045ull);
    vlSelf->__PVT__u_core__DOT__if_ex_pc_plus_imm = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1518494026839511667ull);
    vlSelf->__PVT__u_core__DOT__ex_bp_upd_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17812820034094586450ull);
    vlSelf->__PVT__u_core__DOT__mul_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11449413755524650650ull);
    vlSelf->__PVT__u_core__DOT__div_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4527686186190173033ull);
    vlSelf->__PVT__u_core__DOT__mul_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4593153980237703576ull);
    vlSelf->__PVT__u_core__DOT__div_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7728147201095556756ull);
    vlSelf->__PVT__u_core__DOT__md_started = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6035282415297906045ull);
    vlSelf->__PVT__u_core__DOT__md_active_is_div = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3693013364708808109ull);
    vlSelf->__PVT__u_core__DOT__md_result_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10178824234281239384ull);
    vlSelf->__PVT__u_core__DOT__md_result_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1902426096898539878ull);
    vlSelf->__PVT__u_core__DOT__md_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12034568090296644263ull);
    vlSelf->__PVT__u_core__DOT__md_start = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8604555128052543716ull);
    vlSelf->__PVT__u_core__DOT__store_addr_lo = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3752150966305002125ull);
    vlSelf->__PVT__u_core__DOT__id_csr_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17478255435261554819ull);
    vlSelf->__PVT__u_core__DOT__id_csr_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9532818950229746539ull);
    vlSelf->__PVT__u_core__DOT__wb_csr_we = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18048610125800355611ull);
    vlSelf->__PVT__u_core__DOT__wb_trap_enter = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5051079487648393575ull);
    vlSelf->__PVT__u_core__DOT__wb_trap_exit = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7910371771136261347ull);
    vlSelf->u_core__DOT__wb_instr_retired = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6742610162925571869ull);
    vlSelf->u_core__DOT__ex_wb_valid_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3681462618043485085ull);
    vlSelf->u_core__DOT__ex_wb_pc_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14421154024592856249ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_alu_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3261685106260186651ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_md_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11045205717222308322ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_pc_plus_4_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2424390107082676459ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_pc_plus_imm_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4996563170491645228ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_csr_rdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10957636796850598051ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_rd_idx_r = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 17234951502355572556ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_rd_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3296170466062605759ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_wb_sel_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10766063654568570931ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_misaligned_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13810033243530289530ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_misaligned_store_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3633161588489941540ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_ls_funct3_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10822347455259200812ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_addr_lo_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 10660347758974413621ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_mret_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1319463498644638578ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_csr_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11118069442234641635ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_csr_addr_r = VL_SCOPED_RAND_RESET_I(12, __VscopeHash, 10713226717194099176ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_csr_op_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2374361835831066183ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_csr_wdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9537889756975993615ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_branch_taken_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6989361162865412943ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_jal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1660972136517985316ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_jalr_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6504892953041898157ull);
    vlSelf->u_core__DOT__ex_wb_illegal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8742572200907594723ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_ecall_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5809368925617122598ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_is_ebreak_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8622495554817985601ull);
    vlSelf->__PVT__u_core__DOT__ex_wb_instr_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11411089300892331827ull);
    vlSelf->__PVT__u_core__DOT__mem_ras_mispredict = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6446278701943524564ull);
    vlSelf->__PVT__u_core__DOT__wb_take_data_trap = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10901036280751098177ull);
    vlSelf->__PVT__u_core__DOT__wb_take_sync_trap = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11551725321248463750ull);
    vlSelf->__PVT__u_core__DOT__ex_mem_advance_to_wb = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1584983613429836962ull);
    vlSelf->u_core__DOT____VdfgRegularize_hbfa0e40b_0_9 = 0;
    vlSelf->u_core__DOT____VdfgRegularize_hbfa0e40b_0_14 = 0;
    vlSelf->u_core__DOT____VdfgRegularize_hbfa0e40b_0_15 = 0;
    vlSelf->u_core__DOT____VdfgRegularize_hbfa0e40b_0_16 = 0;
    vlSelf->u_core__DOT____VdfgRegularize_hbfa0e40b_0_17 = 0;
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__valid0[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2225134757747446779ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__tag0[__Vi0] = VL_SCOPED_RAND_RESET_I(26, __VscopeHash, 15083132480378904573ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__target0[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16168533140512081754ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__counter0[__Vi0] = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 11995157391776749913ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__valid1[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 54675578432913136ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__tag1[__Vi0] = VL_SCOPED_RAND_RESET_I(26, __VscopeHash, 12302279104537289680ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__target1[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1335457141991696813ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__counter1[__Vi0] = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 12255556411217075959ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_bp__DOT__lru[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7444633163361686738ull);
    }
    vlSelf->__PVT__u_core__DOT__u_bp__DOT__wr_way = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5153532952764243928ull);
    vlSelf->__PVT__u_core__DOT__u_bp__DOT__cnt_next = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 430292710749529987ull);
    for (int __Vi0 = 0; __Vi0 < 8; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_ras__DOT__stack[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 576250720452730967ull);
    }
    vlSelf->__PVT__u_core__DOT__u_ras__DOT__ptr = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 17309736219855786494ull);
    vlSelf->__PVT__u_core__DOT__u_ras__DOT__top_idx = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 15333122275576309624ull);
    vlSelf->__PVT__u_core__DOT__u_ifu__DOT__pc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14193917195336712192ull);
    vlSelf->u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 = 0;
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->__PVT__u_core__DOT__u_rfu__DOT__regs[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4279646642466808441ull);
    }
    vlSelf->__PVT__u_core__DOT__u_mul__DOT__busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10152101123090607992ull);
    vlSelf->__PVT__u_core__DOT__u_mul__DOT__done_pending = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15081060141780143655ull);
    vlSelf->__PVT__u_core__DOT__u_mul__DOT__opa_r = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 7896871661210024740ull);
    vlSelf->__PVT__u_core__DOT__u_mul__DOT__opb_r = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 14841339101152289140ull);
    vlSelf->__PVT__u_core__DOT__u_mul__DOT__high_out = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15826089104087969537ull);
    VL_SCOPED_RAND_RESET_W(66, vlSelf->__PVT__u_core__DOT__u_mul__DOT__product_w, __VscopeHash, 9632354245213644442ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 1904739762312502463ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__iter = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 14620151670366708519ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__dividend = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7901758624684094585ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__divisor = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9663620511032959098ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__quotient = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4922914458699722076ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__remainder = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6245250337567529808ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__orig_a = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 18243025160152933985ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__ret_rem = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16797540258062392876ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__sign_quot = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17345630944911087560ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__sign_rem = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14773835606874473147ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__div_by_zero = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14147741087452370391ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__overflow = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1851056484164406573ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__shifted_rem = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 6380374378737358143ull);
    vlSelf->__PVT__u_core__DOT__u_div__DOT__sub_w = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 6168876703156050250ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__mie_meie = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 914421500445811313ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__mstatus_mie = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14551894107228939686ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__mstatus_mpie = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 403677494578550293ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__mtvec_base = VL_SCOPED_RAND_RESET_I(30, __VscopeHash, 5311212296033966945ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__mscratch = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11564503036056789236ull);
    vlSelf->u_core__DOT__u_csr__DOT__mepc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8155402222432820965ull);
    vlSelf->u_core__DOT__u_csr__DOT__mcause_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11964881509808144112ull);
    vlSelf->u_core__DOT__u_csr__DOT__mtval_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1311468297349478860ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__ext_pending = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10290844215157992597ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__cycle_cnt = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 3328070315217509167ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__instret_cnt = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 8845381906161725442ull);
    vlSelf->__PVT__u_core__DOT__u_csr__DOT__new_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2753047914214481318ull);
    vlSelf->u_core__DOT__u_csr__DOT__mstatus_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4734608959392523412ull);
    vlSelf->__PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 17340317421768462385ull);
    vlSelf->__PVT__u_core__DOT__u_lsu_wb__DOT__half_sel = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 16854150357892957967ull);
    vlSelf->__Vdly__i_busy = 0;
    vlSelf->__Vdly__d_busy = 0;
}
