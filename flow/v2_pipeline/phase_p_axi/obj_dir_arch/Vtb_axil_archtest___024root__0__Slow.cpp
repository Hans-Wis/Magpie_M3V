// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_archtest.h for the primary calling header

#include "Vtb_axil_archtest__pch.h"

void Vtb_axil_archtest___024root___timing_ready(Vtb_axil_archtest___024root* vlSelf);

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_static(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_static\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_archtest__DOT__clk = 0U;
    vlSelfRef.tb_axil_archtest__DOT__resetn = 0U;
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__fd = 0;
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16693995711324529500ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__word_idx = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16635539270624831082ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__offset = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 22748860666973548ull);
    vlSelfRef.__Vtrigprevexpr___TOP__tb_axil_archtest__DOT__clk__0 = 0U;
    Vtb_axil_archtest___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_static__TOP(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_static__TOP\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_archtest__DOT__clk = 0U;
    vlSelfRef.tb_axil_archtest__DOT__resetn = 0U;
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__fd = 0;
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16693995711324529500ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__word_idx = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16635539270624831082ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__dump_signature__Vstatic__offset = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 22748860666973548ull);
}

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_initial__TOP(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_initial__TOP\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[0U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[1U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[2U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[3U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[4U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[5U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[6U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[7U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[8U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[9U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[10U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[11U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[12U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[13U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[14U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[15U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[16U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[17U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[18U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[19U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[20U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[21U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[22U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[23U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[24U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[25U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[26U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[27U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[28U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[29U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[30U] = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[31U] = 0U;
}

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_final(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_final\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_archtest___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_axil_archtest___024root___eval_phase__stl(Vtb_axil_archtest___024root* vlSelf);

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_settle(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_settle\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vtb_axil_archtest___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("tb_axil_archtest.v", 3, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vtb_axil_archtest___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_triggers_vec__stl(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_triggers_vec__stl\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool Vtb_axil_archtest___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_archtest___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_axil_archtest___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vtb_axil_archtest___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___trigger_anySet__stl\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

extern const VlUnpacked<CData/*2:0*/, 64> Vtb_axil_archtest__ConstPool__TABLE_hde2d3e75_0;
extern const VlUnpacked<CData/*1:0*/, 32> Vtb_axil_archtest__ConstPool__TABLE_hdb09954d_0;

VL_ATTR_COLD void Vtb_axil_archtest___024root___stl_sequent__TOP__0(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___stl_sequent__TOP__0\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target = 0;
    IData/*31:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_imm;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_imm = 0;
    CData/*3:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_muldiv;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_muldiv = 0;
    IData/*31:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_fwd_val;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_fwd_val = 0;
    IData/*31:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_eq;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_eq = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_s;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_s = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_u;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_u = 0;
    IData/*31:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__csr_rdata;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__csr_rdata = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgExtracted_ha4e5ab41__0;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgExtracted_ha4e5ab41__0 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_18;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_18 = 0;
    SData/*11:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT__imm_addi;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT__imm_addi = 0;
    IData/*31:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 = 0;
    IData/*19:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6 = 0;
    CData/*5:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7 = 0;
    SData/*11:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9 = 0;
    SData/*9:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__rd_hit1;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__rd_hit1 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit0;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit0 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit1;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit1 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_ok;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_ok = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs1;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs1 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs2;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs2 = 0;
    CData/*0:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__wb_fwd_ok;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__wb_fwd_ok = 0;
    CData/*7:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel = 0;
    SData/*15:0*/ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel = 0;
    CData/*0:0*/ __VdfgRegularize_he50b618e_0_0;
    __VdfgRegularize_he50b618e_0_0 = 0;
    CData/*0:0*/ __VdfgRegularize_he50b618e_0_1;
    __VdfgRegularize_he50b618e_0_1 = 0;
    CData/*0:0*/ __VdfgRegularize_he50b618e_0_3;
    __VdfgRegularize_he50b618e_0_3 = 0;
    CData/*0:0*/ __VdfgRegularize_he50b618e_0_4;
    __VdfgRegularize_he50b618e_0_4 = 0;
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
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_boot 
        = (1U & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__primed)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__top_idx 
        = (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__ptr) 
                 - (IData)(1U)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_9 
        = ((3U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
           | (0x23U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__ibus_ready 
        = ((2U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__i_state)) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__i_rvalid));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_push_val 
        = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pc 
           + ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_is_16bit)
               ? 2U : 4U));
    VL_EXTENDS_WQ(66,33, __Vtemp_3, vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__opa_r);
    __Vtemp_4[0U] = __Vtemp_3[0U];
    __Vtemp_4[1U] = __Vtemp_3[1U];
    __Vtemp_4[2U] = (3U & __Vtemp_3[2U]);
    VL_EXTENDS_WQ(66,33, __Vtemp_6, vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__opb_r);
    __Vtemp_7[0U] = __Vtemp_6[0U];
    __Vtemp_7[1U] = __Vtemp_6[1U];
    __Vtemp_7[2U] = (3U & __Vtemp_6[2U]);
    VL_MULS_WWW(66, __Vtemp_8, __Vtemp_4, __Vtemp_7);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__product_w[0U] 
        = __Vtemp_8[0U];
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__product_w[1U] 
        = __Vtemp_8[1U];
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__product_w[2U] 
        = (3U & __Vtemp_8[2U]);
    vlSelfRef.tb_axil_archtest__DOT__i_arready = ((~ 
                                                   ((IData)(vlSelfRef.tb_axil_archtest__DOT__i_mem__DOT__rd_busy) 
                                                    | (IData)(vlSelfRef.tb_axil_archtest__DOT__i_rvalid))) 
                                                  & (IData)(vlSelfRef.tb_axil_archtest__DOT__resetn));
    vlSelfRef.tb_axil_archtest__DOT__d_arready = ((~ 
                                                   ((IData)(vlSelfRef.tb_axil_archtest__DOT__d_mem__DOT__rd_busy) 
                                                    | (IData)(vlSelfRef.tb_axil_archtest__DOT__d_rvalid))) 
                                                  & (IData)(vlSelfRef.tb_axil_archtest__DOT__resetn));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_done 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_active_is_div)
            ? (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__div_done)
            : (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__mul_done));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__shifted_rem 
        = (((QData)((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__remainder)) 
            << 1U) | (QData)((IData)((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__dividend 
                                      >> 0x0000001fU))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op = 0U;
    if ((0x13U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))) {
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op 
            = ((0x00004000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                ? ((0x00002000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                    ? ((0x00001000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                        ? 2U : 3U) : ((0x00001000U 
                                       & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                       ? ((0x40000000U 
                                           & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                           ? 7U : 6U)
                                       : 4U)) : ((0x00002000U 
                                                  & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                  ? 
                                                 ((0x00001000U 
                                                   & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                   ? 9U
                                                   : 8U)
                                                  : 
                                                 ((0x00001000U 
                                                   & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                   ? 5U
                                                   : 0U)));
    } else if ((0x33U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))) {
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op 
            = ((0x00004000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                ? ((0x00002000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                    ? ((0x00001000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                        ? 2U : 3U) : ((0x00001000U 
                                       & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                       ? ((0x40000000U 
                                           & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                           ? 7U : 6U)
                                       : 4U)) : ((0x00002000U 
                                                  & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                  ? 
                                                 ((0x00001000U 
                                                   & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                   ? 9U
                                                   : 8U)
                                                  : 
                                                 ((0x00001000U 
                                                   & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                   ? 5U
                                                   : 
                                                  ((0x40000000U 
                                                    & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                                                    ? 1U
                                                    : 0U))));
    } else if ((0x63U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))) {
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op 
            = ((0x00004000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                ? ((0x00002000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
                    ? 9U : 8U) : 0x0aU);
    } else if ((0x37U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))) {
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op = 0x0bU;
    }
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_csr 
        = ((0x73U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
           & (0U != (7U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                           >> 0x0000000cU))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_14 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_mret_r) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r));
    vlSelfRef.tb_axil_archtest__DOT__d_awvalid = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_aw_done)) 
                                                  & (3U 
                                                     == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_state)));
    vlSelfRef.tb_axil_archtest__DOT__d_wvalid = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_w_done)) 
                                                 & (3U 
                                                    == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_state)));
    vlSelfRef.tb_axil_archtest__DOT__d_awready = ((IData)(vlSelfRef.tb_axil_archtest__DOT__resetn) 
                                                  & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__d_mem__DOT__aw_seen)) 
                                                     & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__d_bvalid))));
    vlSelfRef.tb_axil_archtest__DOT__d_wready = ((IData)(vlSelfRef.tb_axil_archtest__DOT__resetn) 
                                                 & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__d_mem__DOT__w_seen)) 
                                                    & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__d_bvalid))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__new_val 
        = ((1U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_op_r))
            ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_wdata_r
            : ((2U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_op_r))
                ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_rdata_r 
                   | vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_wdata_r)
                : ((3U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_op_r))
                    ? ((~ vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_wdata_r) 
                       & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_rdata_r)
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_rdata_r)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit0 
        = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__valid0
           [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                            >> 1U))] & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__tag0
                                        [(0x0000001fU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                             >> 1U))] 
                                        == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                            >> 6U)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit1 
        = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__valid1
           [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                            >> 1U))] & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__tag1
                                        [(0x0000001fU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                             >> 1U))] 
                                        == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                            >> 6U)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_16 
        = (1U & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_warmup))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_top 
        = ((0U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__ptr))
            ? 0U : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__stack
           [(7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__ptr) 
                   - (IData)(1U)))]);
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__rd_hit1 
        = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__valid1
           [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))] & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__tag1
                                        [(0x0000001fU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                                             >> 1U))] 
                                        == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                                            >> 6U)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__at_cross_boundary 
        = (IData)(((((0x00030000U == (0x00030000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q)) 
                     & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                        >> 1U)) & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cross_assemble))) 
                   & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_warmup))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__is_16bit_w 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cross_assemble)) 
           & ((2U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg)
               ? (3U != (3U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q 
                               >> 0x00000010U))) : 
              (3U != (3U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 
        = ((0x37U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
           | (0x17U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__wb_fwd_ok 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r) 
           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_rd_we_r) 
              & (0U != (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_rd_idx_r))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_fwd_val 
        = ((4U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r))
            ? ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r))
                ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r
                : ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r))
                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_md_result_r
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_rdata_r))
            : ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r))
                ? ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r))
                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_4_r)
                : ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r))
                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_imm_r
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_ok 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_we_r) 
           & ((~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_load_r) 
                  | (0U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_idx_r)))) 
              & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_jalr 
        = (IData)((0x00000067U == (0x0000707fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)));
    if ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_addr_lo_r))) {
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel 
            = (0x000000ffU & ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_addr_lo_r))
                               ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q 
                                  >> 0x00000018U) : 
                              (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q 
                               >> 0x00000010U)));
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel 
            = (0x0000ffffU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q 
                              >> 0x00000010U));
    } else {
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel 
            = (0x000000ffU & ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_addr_lo_r))
                               ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q 
                                  >> 8U) : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q));
        tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel 
            = (0x0000ffffU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q);
    }
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__mem_ras_mispredict 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r) 
           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pred_ras_r) 
              & ((0xfffffffeU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r) 
                 != vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pred_ras_target_r)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_sync_trap 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_illegal_r) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r));
    __VdfgRegularize_he50b618e_0_4 = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_idx_r) 
                                      == (0x0000001fU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                             >> 0x00000014U)));
    __VdfgRegularize_he50b618e_0_3 = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_idx_r) 
                                      == (0x0000001fU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                             >> 0x0000000fU)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_muldiv 
        = (IData)((0x02000033U == (0xfe00007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_data_trap 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_misaligned_r) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr 
        = (0x0000ffffU & ((2U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg)
                           ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q 
                              >> 0x00000010U) : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall 
        = (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_busy) 
            | ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__primed)) 
               | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_busy))) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__resetn));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__sub_w 
        = (0x00000001ffffffffULL & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__shifted_rem 
                                    - (QData)((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__divisor))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__dbus_ready 
        = (((2U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_state)) 
            & (IData)(vlSelfRef.tb_axil_archtest__DOT__d_rvalid)) 
           | ((3U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_state)) 
              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__d_bvalid) 
                 & (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_aw_done) 
                     | ((IData)(vlSelfRef.tb_axil_archtest__DOT__d_awvalid) 
                        & (IData)(vlSelfRef.tb_axil_archtest__DOT__d_awready))) 
                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_w_done) 
                       | ((IData)(vlSelfRef.tb_axil_archtest__DOT__d_wvalid) 
                          & (IData)(vlSelfRef.tb_axil_archtest__DOT__d_wready)))))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_way 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit1) 
           | ((~ (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit0)) 
              & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__lru
              [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                               >> 1U))]));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_target 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__rd_hit1)
            ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__target1
           [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))] : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__target0
           [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                            >> 1U))]);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_taken 
        = ((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__valid0
            [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                             >> 1U))] & ((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__tag0
                                          [(0x0000001fU 
                                            & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                                               >> 1U))] 
                                          == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                                              >> 6U)) 
                                         & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__counter0
                                            [(0x0000001fU 
                                              & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                                                 >> 1U))] 
                                            >> 1U))) 
           | ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__rd_hit1) 
              & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__counter1
                 [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                                  >> 1U))] >> 1U)));
    __VdfgRegularize_he50b618e_0_1 = ((0x6fU == (0x0000007fU 
                                                 & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                                      | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_jalr));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_imm 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5)
            ? (0xfffff000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
            : ((0x6fU == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))
                ? ((((0x00000ffeU & ((- (IData)((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                 >> 0x0000001fU))) 
                                     << 1U)) | (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                >> 0x0000001fU)) 
                    << 0x00000014U) | ((((0x000001feU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                             >> 0x0000000bU)) 
                                         | (1U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))) 
                                        << 0x0000000bU) 
                                       | (0x000007feU 
                                          & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                             >> 0x00000014U))))
                : (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_jalr) 
                    | ((3U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                       | (0x13U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))))
                    ? (((- (IData)((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                    >> 0x0000001fU))) 
                        << 0x0000000cU) | (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                           >> 0x00000014U))
                    : ((0x23U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))
                        ? (((- (IData)((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                        >> 0x0000001fU))) 
                            << 0x0000000cU) | ((0x00000fe0U 
                                                & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U)) 
                                               | (0x0000001fU 
                                                  & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                     >> 7U))))
                        : ((0x63U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr))
                            ? (((- (IData)((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                            >> 0x0000001fU))) 
                                << 0x0000000dU) | (
                                                   (((2U 
                                                      & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                         >> 0x0000001eU)) 
                                                     | (1U 
                                                        & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                           >> 7U))) 
                                                    << 0x0000000bU) 
                                                   | ((0x000007e0U 
                                                       & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                          >> 0x00000014U)) 
                                                      | (0x0000001eU 
                                                         & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                            >> 7U)))))
                            : 0U)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_data_mux 
        = ((4U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r))
            ? ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r))
                ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_alu_result_r
                : ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r))
                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_md_result_r
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_rdata_r))
            : ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r))
                ? ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r))
                    ? ((4U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_ls_funct3_r))
                        ? ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_ls_funct3_r))
                            ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q
                            : ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_ls_funct3_r))
                                ? (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel)
                                : (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel)))
                        : ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_ls_funct3_r))
                            ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q
                            : ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_ls_funct3_r))
                                ? (((- (IData)((1U 
                                                & ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel) 
                                                   >> 0x0000000fU)))) 
                                    << 0x00000010U) 
                                   | (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__half_sel))
                                : (((- (IData)((1U 
                                                & ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel) 
                                                   >> 7U)))) 
                                    << 8U) | (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_lsu_wb__DOT__byte_sel)))))
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_pc_plus_4_r)
                : ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r))
                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_pc_plus_imm_r
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_alu_result_r)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs2 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_ok) 
           & (IData)(__VdfgRegularize_he50b618e_0_4));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs1 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_ok) 
           & (IData)(__VdfgRegularize_he50b618e_0_3));
    __Vtableidx1 = ((((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_muldiv) 
                      << 5U) | (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_csr) 
                                 << 4U) | ((3U == (0x0000007fU 
                                                   & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                                           << 3U))) 
                    | (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_jalr) 
                        << 2U) | (((0x6fU == (0x0000007fU 
                                              & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                                   << 1U) | (0x17U 
                                             == (0x0000007fU 
                                                 & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_wb_sel 
        = Vtb_axil_archtest__ConstPool__TABLE_hde2d3e75_0
        [__Vtableidx1];
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_17 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_muldiv) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 0U;
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
        = (0x00042403U | (((((8U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                    >> 2U)) | (7U & 
                                               ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                >> 0x0000000aU))) 
                            << 0x00000017U) | (0x00400000U 
                                               & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                  << 0x00000010U))) 
                          | ((0x00038000U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                             << 8U)) 
                             | (0x00000380U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                               << 5U)))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT__imm_addi 
        = ((0x00000fe0U & ((- (IData)((1U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                             >> 0x0000000cU)))) 
                           << 5U)) | (0x0000001fU & 
                                      ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                       >> 2U)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13 
        = (((((4U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                     >> 6U)) | (3U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                      >> 9U))) << 7U) 
            | (((2U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                       >> 5U)) | (1U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                        >> 7U))) << 5U)) 
           | ((0x00000010U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                              << 2U)) | ((8U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                >> 8U)) 
                                         | (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                  >> 3U)))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6 
        = (0x00045413U | ((0x00038000U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                          << 8U)) | 
                          (0x00000380U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7 
        = ((0x00000038U & ((- (IData)((1U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                             >> 0x0000000cU)))) 
                           << 3U)) | ((6U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                             >> 4U)) 
                                      | (1U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                               >> 2U))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9 
        = (0x63U | ((0x00000c00U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)) 
                    | ((0x00000300U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                       << 5U)) | (0x00000080U 
                                                  & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                     >> 5U)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_upd_valid 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall)) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_valid_r));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_trap_exit 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall)) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_14));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_13 
        = (1U & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_data_trap)) 
                 & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall))));
    __Vtableidx3 = (((((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_way)
                        ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__counter1
                       [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                        >> 1U))] : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__counter0
                       [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r 
                                        >> 1U))]) << 3U) 
                     | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_taken_r) 
                        << 2U)) | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit1) 
                                    << 1U) | (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_hit0)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__cnt_next 
        = Vtb_axil_archtest__ConstPool__TABLE_hdb09954d_0
        [__Vtableidx3];
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pc_plus_imm 
        = (tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_imm 
           + vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pc);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs2_val 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs2)
            ? tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_fwd_val
            : (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__wb_fwd_ok) 
                & ((~ (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs2)) 
                   & ((0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                      >> 0x00000014U)) 
                      == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_rd_idx_r))))
                ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_data_mux
                : ((0U == (0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                          >> 0x00000014U)))
                    ? 0U : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs
                   [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                    >> 0x00000014U))])));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
        = ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs1)
            ? tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_fwd_val
            : (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__wb_fwd_ok) 
                & ((~ (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_forward__DOT__em_fwd_rs1)) 
                   & ((0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                      >> 0x0000000fU)) 
                      == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_rd_idx_r))))
                ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_data_mux
                : ((0U == (0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                          >> 0x0000000fU)))
                    ? 0U : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs
                   [(0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                    >> 0x0000000fU))])));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall 
        = (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r) 
            & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid) 
               & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_load_r) 
                  & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_we_r) 
                     & ((0U != (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_idx_r)) 
                        & ((IData)(__VdfgRegularize_he50b618e_0_3) 
                           | (IData)(__VdfgRegularize_he50b618e_0_4))))))) 
           | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid) 
              & ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_muldiv) 
                 & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_result_valid)) 
                    & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_17)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded = 0U;
    if ((2U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
        if ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
        } else if ((0x00008000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            if ((0x00004000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                if ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                }
            } else if ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
            } else if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                 >> 0x0cU)))) {
                if ((0U == (0x0000001fU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                           >> 2U)))) {
                    if ((0U == (0x0000001fU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                               >> 7U)))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                    }
                }
            }
        } else if ((0x00004000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            if ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
            } else if ((0U == (0x0000001fU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              >> 7U)))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
            }
        } else if ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
        } else if ((0x00001000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
        }
        if ((1U & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))) {
            if ((0x00008000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                if ((0x00004000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                    if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                  >> 0x0000000dU)))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = (0x00012023U | ((((0x000000c0U 
                                                 & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                    >> 1U)) 
                                                | ((0x00000020U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 7U)) 
                                                   | (0x0000001fU 
                                                      & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                         >> 2U)))) 
                                               << 0x00000014U) 
                                              | (0x00000e00U 
                                                 & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))));
                    }
                } else if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                     >> 0x0000000dU)))) {
                    if ((0x00001000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = ((0U == (0x0000001fU 
                                       & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                          >> 2U))) ? 
                               ((0U == (0x0000001fU 
                                        & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                           >> 7U)))
                                 ? 0x00100073U : (0x00e7U 
                                                  | (0x000f8000U 
                                                     & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                        << 8U))))
                                : (0x33U | ((0x01f00000U 
                                             & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                << 0x00000012U)) 
                                            | ((0x000f8000U 
                                                & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                   << 8U)) 
                                               | (0x00000f80U 
                                                  & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))));
                    } else if ((0U == (0x0000001fU 
                                       & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                          >> 2U)))) {
                        if ((0U != (0x0000001fU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                   >> 7U)))) {
                            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                                = (0x0067U | (0x000f8000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)));
                        }
                    } else {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = (0x33U | ((0x01f00000U 
                                         & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                            << 0x00000012U)) 
                                        | (0x00000f80U 
                                           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))));
                    }
                }
            } else if ((0x00004000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                    if ((0U != (0x0000001fU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                               >> 7U)))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = (0x00012003U | ((((0x00000030U 
                                                 & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                    << 2U)) 
                                                | ((8U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 9U)) 
                                                   | (7U 
                                                      & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                         >> 4U)))) 
                                               << 0x00000016U) 
                                              | (0x00000f80U 
                                                 & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))));
                    }
                }
            } else if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                 >> 0x0000000dU)))) {
                if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                              >> 0x0cU)))) {
                    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                        = (0x00001013U | ((0x01f00000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x000f8000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000f80U 
                                                & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))));
                }
            }
        }
    } else if ((1U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
        if ((0x00008000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                          >> 0x0000000eU)))) {
                if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                    if ((0x00000800U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                        if ((0x00000400U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                            if ((0x00001000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                            }
                        }
                    } else if ((0x00000400U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                        if ((0x00001000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                        }
                    } else if ((0x00001000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                    }
                }
            }
            if ((0x00004000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                    = ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))
                        ? (0x00041000U | ((0x80000000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000013U)) 
                                          | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7) 
                                              << 0x00000019U) 
                                             | ((0x00038000U 
                                                 & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                    << 8U)) 
                                                | (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9)))))
                        : (0x00040000U | ((0x80000000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000013U)) 
                                          | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_7) 
                                              << 0x00000019U) 
                                             | ((0x00038000U 
                                                 & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                    << 8U)) 
                                                | (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_9))))));
            } else if ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                    = (0x006fU | ((((0x00000800U & 
                                     ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13) 
                                                  << 1U) 
                                                 | (1U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 0x0000000cU)))) 
                                   << 0x00000014U) 
                                  | (0x000ff000U & 
                                     ((- (IData)((1U 
                                                  & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                     >> 0x0000000cU)))) 
                                      << 0x0000000bU))));
            } else if ((0x00000800U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                if ((0x00000400U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                    if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                  >> 0x0cU)))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = ((0x00000040U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))
                                ? ((0x00000020U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))
                                    ? (0x00847433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))))
                                    : (0x00846433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))))
                                : ((0x00000020U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))
                                    ? (0x00844433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))))
                                    : (0x40840433U 
                                       | ((0x00700000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))))));
                    }
                } else {
                    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                        = (0x00047413U | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                           << 0x00000014U) 
                                          | ((0x00038000U 
                                              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                             | (0x00000380U 
                                                & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))));
                }
            } else if ((0x00000400U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                              >> 0x0cU)))) {
                    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                        = (0x40000000U | ((0x01f00000U 
                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                              << 0x00000012U)) 
                                          | tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6));
                }
            } else if ((1U & (~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                 >> 0x0cU)))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                    = ((0x01f00000U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                       << 0x00000012U)) 
                       | tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_6);
            }
        } else if ((0x00004000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
            if ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) {
                if ((2U == (0x0000001fU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                           >> 7U)))) {
                    if ((IData)((0U == (0x107cU & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                    }
                    if ((1U & (~ (IData)((0U == (0x107cU 
                                                 & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = (0x00010113U | (((- (IData)(
                                                          (1U 
                                                           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                              >> 0x0000000cU)))) 
                                               << 0x0000001dU) 
                                              | ((((6U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 2U)) 
                                                   | (1U 
                                                      & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                         >> 5U))) 
                                                  << 0x0000001aU) 
                                                 | ((0x02000000U 
                                                     & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                        << 0x00000017U)) 
                                                    | (0x01000000U 
                                                       & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                          << 0x00000012U))))));
                    }
                } else {
                    if ((IData)((0U == (0x107cU & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
                    }
                    if ((1U & (~ (IData)((0U == (0x107cU 
                                                 & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))))) {
                        vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                            = (0x37U | (((- (IData)(
                                                    (1U 
                                                     & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                        >> 0x0000000cU)))) 
                                         << 0x00000011U) 
                                        | ((0x0001f000U 
                                            & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                               << 0x0000000aU)) 
                                           | (0x00000f80U 
                                              & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))));
                    }
                }
            } else {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                    = (0x13U | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                 << 0x00000014U) | 
                                (0x00000f80U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))));
            }
        } else {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                = ((0x00002000U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))
                    ? (0x00efU | ((((0x00000800U & 
                                     ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgRegularize_h04bc4170_0_13) 
                                                  << 1U) 
                                                 | (1U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 0x0000000cU)))) 
                                   << 0x00000014U) 
                                  | (0x000ff000U & 
                                     ((- (IData)((1U 
                                                  & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                     >> 0x0000000cU)))) 
                                      << 0x0000000bU))))
                    : (0x13U | (((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT__imm_addi) 
                                 << 0x00000014U) | 
                                ((0x000f8000U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                 << 8U)) 
                                 | (0x00000f80U & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))))));
        }
    } else if ((0U == (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                             >> 0x0000000dU)))) {
        if ((0U == (0x000000ffU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                   >> 5U)))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
        }
        if ((0U != (0x000000ffU & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                   >> 5U)))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                = (0x00010413U | ((((0x000003c0U & 
                                     ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                      >> 1U)) | (((
                                                   (6U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 0x0000000aU)) 
                                                   | (1U 
                                                      & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                         >> 5U))) 
                                                  << 3U) 
                                                 | (4U 
                                                    & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                                       >> 4U)))) 
                                   << 0x00000014U) 
                                  | (0x00000380U & 
                                     ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                      << 5U))));
        }
    } else {
        if ((2U != (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                          >> 0x0000000dU)))) {
            if ((6U != (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                              >> 0x0000000dU)))) {
                vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = 1U;
            }
        }
        if ((2U == (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                          >> 0x0000000dU)))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                = tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0;
        } else if ((6U == (7U & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                 >> 0x0000000dU)))) {
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded 
                = (0x00842023U | ((((0x00003f80U & 
                                     (tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
                                      >> 0x00000012U)) 
                                    | (0x0000001cU 
                                       & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr))) 
                                   << 0x00000012U) 
                                  | ((0x00038000U & 
                                      ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr) 
                                       << 8U)) | (0x00000f80U 
                                                  & (tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_cdec__DOT____VdfgExtracted_hefb8a80e__0 
                                                     >> 0x0000000dU)))));
        }
    }
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_irq 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r) 
           & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_illegal_r)) 
              & (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__ext_pending) 
                  & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mie_meie) 
                     & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mstatus_mie))) 
                 & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_13))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b 
        = (((0x13U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
            | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5) 
               | ((3U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                  | ((0x23U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                     | (IData)(__VdfgRegularize_he50b618e_0_1)))))
            ? tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_imm
            : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs2_val);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__store_addr_lo 
        = (3U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                 + tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_imm));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_csr_wdata 
        = ((0x00004000U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)
            ? (0x0000001fU & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                              >> 0x0000000fU)) : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__any_stall 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall) 
           | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__at_cross_boundary) 
              | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__warmup) 
                 | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall) 
                    | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_warmup)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__instr_assembled 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cross_assemble)
            ? ((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q 
                << 0x00000010U) | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__residue))
            : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__is_16bit_w)
                ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded
                : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_csr_we 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_we_r) 
           & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_irq)) 
              & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r) 
                 & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_illegal_r)) 
                    & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall))))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgExtracted_ha4e5ab41__0 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_irq) 
           | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_data_trap) 
              | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_sync_trap)));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_eq 
        = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
           == tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b);
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_s 
        = VL_LTS_III(32, vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val, tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b);
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_u 
        = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
           < tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b);
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__csr_rdata 
        = (((((((((0x0300U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                               >> 0x00000014U)) | (0x0304U 
                                                   == 
                                                   (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))) 
                 | (0x0305U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                >> 0x00000014U))) | 
                (0x0340U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                             >> 0x00000014U))) | (0x0341U 
                                                  == 
                                                  (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))) 
              | (0x0342U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                             >> 0x00000014U))) | (0x0343U 
                                                  == 
                                                  (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))) 
            | (0x0344U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                           >> 0x00000014U))) ? ((0x0300U 
                                                 == 
                                                 (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                  >> 0x00000014U))
                                                 ? 
                                                (0x00001800U 
                                                 | (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mstatus_mpie) 
                                                     << 7U) 
                                                    | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mstatus_mie) 
                                                       << 3U)))
                                                 : 
                                                ((0x0304U 
                                                  == 
                                                  (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                   >> 0x00000014U))
                                                  ? 
                                                 ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mie_meie) 
                                                  << 0x0000000bU)
                                                  : 
                                                 ((0x0305U 
                                                   == 
                                                   (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                    >> 0x00000014U))
                                                   ? 
                                                  (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mtvec_base 
                                                   << 2U)
                                                   : 
                                                  ((0x0340U 
                                                    == 
                                                    (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                     >> 0x00000014U))
                                                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mscratch
                                                    : 
                                                   ((0x0341U 
                                                     == 
                                                     (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                      >> 0x00000014U))
                                                     ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mepc_reg
                                                     : 
                                                    ((0x0342U 
                                                      == 
                                                      (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                       >> 0x00000014U))
                                                      ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mcause_reg
                                                      : 
                                                     ((0x0343U 
                                                       == 
                                                       (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                                        >> 0x00000014U))
                                                       ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mtval_reg
                                                       : 
                                                      ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__ext_pending) 
                                                       << 0x0000000bU))))))))
            : ((0x0c00U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                            >> 0x00000014U)) ? (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__cycle_cnt)
                : ((0x0c80U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                >> 0x00000014U)) ? (IData)(
                                                           (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__cycle_cnt 
                                                            >> 0x20U))
                    : ((0x0c02U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                    >> 0x00000014U))
                        ? (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__instret_cnt)
                        : ((0x0c82U == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                        >> 0x00000014U))
                            ? (IData)((vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__instret_cnt 
                                       >> 0x20U)) : 0U)))));
    if (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_csr_we) 
         & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r) 
            == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                >> 0x00000014U)))) {
        if ((((((((0x0300U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r)) 
                  || (0x0304U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r))) 
                 || (0x0305U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r))) 
                || (0x0340U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r))) 
               || (0x0341U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r))) 
              || (0x0342U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r))) 
             || (0x0343U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r)))) {
            tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__csr_rdata 
                = vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__new_val;
        }
    }
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_trap_enter 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall)) 
           & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgExtracted_ha4e5ab41__0));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_advance_to_wb 
        = ((~ ((IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgExtracted_ha4e5ab41__0) 
               | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_14))) 
           & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target = 0U;
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect = 0U;
    if ((1U & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall)))) {
        if (tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgExtracted_ha4e5ab41__0) {
            tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target 
                = (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mtvec_base 
                   << 2U);
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r) 
                    & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_mret_r))) {
            tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target 
                = vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect = 1U;
        } else if (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__mem_ras_mispredict) {
            tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target 
                = (0xfffffffeU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r);
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect = 1U;
        } else if (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r) 
                    & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_mispredict_r))) {
            tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target 
                = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_jalr_r)
                    ? (0xfffffffeU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r)
                    : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_branch_taken_r)
                        ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_imm_r
                        : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_jal_r)
                            ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_imm_r
                            : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_4_r)));
            vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect = 1U;
        }
    }
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_result 
        = ((8U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
            ? ((4U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                ? 0U : ((2U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                         ? ((1U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                             ? tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b
                             : (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_eq))
                         : ((1U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                             ? (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_u)
                             : (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_s))))
            : ((4U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                ? ((2U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                    ? ((1U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                        ? VL_SHIFTRS_III(32,32,5, vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val, 
                                         (0x0000001fU 
                                          & tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b))
                        : (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           >> (0x0000001fU & tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b)))
                    : ((1U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                        ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           << (0x0000001fU & tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b))
                        : (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           ^ tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b)))
                : ((2U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                    ? ((1U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                        ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           | tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b)
                        : (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           & tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b))
                    : ((1U & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_alu_op))
                        ? (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           - tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b)
                        : (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val 
                           + tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_op_b)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__branch_taken 
        = ((0x63U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
           & (((0x63U == (0x0000007fU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
               & ((1U == (7U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                >> 0x0000000cU))) | 
                  ((5U == (7U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                 >> 0x0000000cU))) 
                   | (7U == (7U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000cU)))))) 
              ^ ((0U == (3U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                               >> 0x0000000dU))) ? (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_eq)
                  : ((2U == (3U & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                                   >> 0x0000000dU)))
                      ? (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_s)
                      : (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_cmp_lt_u)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_csr_rdata 
        = (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r) 
            & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_we_r) 
               & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_addr_r) 
                  == (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr 
                      >> 0x00000014U)))) ? ((1U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_op_r))
                                             ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_wdata_r
                                             : ((2U 
                                                 == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_op_r))
                                                 ? 
                                                (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_rdata_r 
                                                 | vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_wdata_r)
                                                 : 
                                                ((3U 
                                                  == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_op_r))
                                                  ? 
                                                 ((~ vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_wdata_r) 
                                                  & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_rdata_r)
                                                  : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_rdata_r)))
            : tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__csr_rdata);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_15 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall)) 
           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)) 
                 & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__warmup)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_advance_to_ex_mem 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__any_stall)) 
           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid) 
              & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__warmup)) 
                 & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_start 
        = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_started)) 
           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_17) 
              & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_result_valid)) 
                 & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)) 
                    & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_16)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__core_d_mem_wstrb 
        = (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_store_r) 
            & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)) 
               & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r)))
            ? (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_store_wstrb_r)
            : 0U);
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_fire 
        = (1U & (((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall)) 
                  & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_busy))) 
                 & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect) 
                    | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_warmup) 
                       | ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall)) 
                          | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__at_cross_boundary))))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_fire 
        = (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r) 
            & (((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_load_r) 
                | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_store_r)) 
               & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)) 
                  & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_misaligned_r))))) 
           & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_busy)) 
              & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall))));
    tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_18 
        = (1U & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)) 
                 & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_pop 
        = (((IData)((0x00008067U == (0x000fffffU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__instr_assembled))) 
            | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__is_16bit_w) 
               & (0x8082U == (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr)))) 
           & ((0U != vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_top) 
              & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__any_stall)) 
                 & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_bp_upd_taken 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid) 
           & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__branch_taken) 
              | (IData)(__VdfgRegularize_he50b618e_0_1)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__dbus_wstrb 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_busy)
            ? (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_wstrb_q)
            : (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__core_d_mem_wstrb));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__ibus_req 
        = (1U & ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__primed)) 
                 | ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_fire) 
                    | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_busy))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__dbus_req 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_fire) 
           | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_busy));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_push 
        = (IData)(((((0x000000efU == (0x00000fffU & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr)) 
                     & (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid)) 
                    & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall))) 
                   & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_18)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__next_pc_w 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect)
            ? tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_target
            : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__any_stall)
                ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg
                : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_pop)
                    ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_top
                    : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_taken)
                        ? vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_target
                        : (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                           + ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__is_16bit_w)
                               ? 2U : 4U))))));
    __VdfgRegularize_he50b618e_0_0 = ((~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall)) 
                                      & ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_16) 
                                         & ((~ ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_taken) 
                                                | (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_pop))) 
                                            & (IData)(tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_18))));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__consecutive_cross 
        = ((((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cross_assemble) 
             & (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                >> 1U)) & (0x00030000U == (0x00030000U 
                                           & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q))) 
           & (IData)(__VdfgRegularize_he50b618e_0_0));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__upcoming_cross 
        = (((((~ (vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg 
                  >> 1U)) & (0x00030000U == (0x00030000U 
                                             & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q))) 
             & (~ (IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cross_assemble))) 
            & (IData)(__VdfgRegularize_he50b618e_0_0)) 
           & (3U != (3U & vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q)));
    vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__core_i_mem_addr 
        = ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__at_cross_boundary)
            ? ((IData)(2U) + vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg)
            : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__consecutive_cross)
                ? ((IData)(6U) + vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg)
                : ((IData)(vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__upcoming_cross)
                    ? ((IData)(4U) + vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg)
                    : vlSelfRef.tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__next_pc_w)));
}

VL_ATTR_COLD void Vtb_axil_archtest___024root___eval_stl(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_stl\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        Vtb_axil_archtest___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD bool Vtb_axil_archtest___024root___eval_phase__stl(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___eval_phase__stl\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtb_axil_archtest___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_axil_archtest___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vtb_axil_archtest___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vtb_axil_archtest___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vtb_axil_archtest___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_archtest___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_axil_archtest___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge tb_axil_archtest.clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_axil_archtest___024root___ctor_var_reset(Vtb_axil_archtest___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_archtest___024root___ctor_var_reset\n"); );
    Vtb_axil_archtest__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    VL_SCOPED_RAND_RESET_W(1024, vlSelf->tb_axil_archtest__DOT__firmware_hex, __VscopeHash, 4390323418214985355ull);
    VL_SCOPED_RAND_RESET_W(1024, vlSelf->tb_axil_archtest__DOT__signature_path, __VscopeHash, 2061198316963232942ull);
    vlSelf->tb_axil_archtest__DOT__max_cycles = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8254908452222438500ull);
    vlSelf->tb_axil_archtest__DOT__wait_states = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13033056243892443925ull);
    vlSelf->tb_axil_archtest__DOT__watchdog = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4692952383871559272ull);
    vlSelf->tb_axil_archtest__DOT__stop_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11984913914402280368ull);
    vlSelf->tb_axil_archtest__DOT__sig_begin = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13254714054076848675ull);
    vlSelf->tb_axil_archtest__DOT__sig_end = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14159558221701824147ull);
    vlSelf->tb_axil_archtest__DOT__i_arready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3543197105484069914ull);
    vlSelf->tb_axil_archtest__DOT__i_rvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9922593902323654595ull);
    vlSelf->tb_axil_archtest__DOT__i_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8835766757647846975ull);
    vlSelf->tb_axil_archtest__DOT__d_arready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11998382177814879322ull);
    vlSelf->tb_axil_archtest__DOT__d_rvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16387339711464955602ull);
    vlSelf->tb_axil_archtest__DOT__d_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16686570335492295431ull);
    vlSelf->tb_axil_archtest__DOT__d_awvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7982047791577351205ull);
    vlSelf->tb_axil_archtest__DOT__d_awready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10236789380483574894ull);
    vlSelf->tb_axil_archtest__DOT__d_wvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7512157179236195032ull);
    vlSelf->tb_axil_archtest__DOT__d_wready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4401324499849434557ull);
    vlSelf->tb_axil_archtest__DOT__d_bvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14647157754975889200ull);
    vlSelf->tb_axil_archtest__DOT__unused_i_bvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5732243293934069688ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__ibus_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6099803530145006457ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__ibus_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12106300238151280938ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__dbus_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7862610423046694891ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__dbus_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4504607608758414472ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__dbus_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10942210954041168762ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__core_i_mem_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13403602637487158309ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__core_d_mem_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 443748730740648267ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4734700408764412529ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2676390637257347770ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_rdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17568696442673606191ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13546866049118012415ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8670289626824133262ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_wdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8678446950586235896ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_wstrb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15609848474178727781ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_rdata_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5555340252955243558ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__primed = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 611903370921819077ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__mem_stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8344738676928233115ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_boot = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4769127870679250670ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__i_fire = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6506558572078648430ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__d_fire = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7011133773444426504ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__warmup = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2850709057028767987ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__next_pc_w = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17080258756391621508ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__pc_redirect = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11838984313323015952ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18304081099931785801ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__redirect_warmup = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15571135026550794595ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 373101952880874821ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_predict_target = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7579798837837248966ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__bp_upd_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1670592484887590483ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_top = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7880730361322753238ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_push = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11171777104035355579ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_push_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15114156920538089192ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ras_pop = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16786304132732540241ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__residue = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 15508536852512098687ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cross_assemble = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 35236851577503267ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__at_cross_boundary = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11859323248901880192ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__upcoming_cross = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17090357884413496824ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__consecutive_cross = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2428719629618756115ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__is_16bit_w = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9062122145211280614ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__any_stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3954845691426936838ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cinstr = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 16270238673784930479ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_expanded = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17184150170442142453ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__cdec_illegal = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13556362489814874511ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__instr_assembled = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15264212654909739446ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_instr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17508636734815561058ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16778485310764558543ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10083145712671076361ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pred_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 99098945776764792ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pred_ras = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4470161400503192284ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pred_target = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15668814550099578600ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pred_ras_target = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 18421796471057930177ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_is_16bit = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8073119842396709256ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_wb_sel = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 4446784092022820569ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_jalr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3164285697610007525ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_is_csr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9017986004988682320ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_valid_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12935998467138499049ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5507734951139664747ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_alu_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 517071867567452547ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_md_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11223528435891785666ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_4_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8393799392376269257ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pc_plus_imm_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15557213369079624178ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_rdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17070000320288784541ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_idx_r = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 10517237140107601531ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_rd_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17420384809829724469ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_wb_sel_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 6929959388666287305ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_load_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16413468641709115706ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_store_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4593311847017563761ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_ls_funct3_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 7636633627322483840ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_addr_lo_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 11814001207624139642ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_store_wdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14359204725550102724ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_store_wstrb_r = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 212577244832393662ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_mret_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9006813202836045352ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_misaligned_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5541516182335595541ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_misaligned_store_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 234203409566937944ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8240137569029525182ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_addr_r = VL_SCOPED_RAND_RESET_I(12, __VscopeHash, 15497051791098548907ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_op_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 13001835811356147106ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_csr_wdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14251579129323255827ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_branch_taken_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 215178429670049751ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_jal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10973046615350476595ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_jalr_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1050867547455667142ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_illegal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18191001694747516864ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_ecall_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11923318545080978543ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_is_ebreak_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7897843186735813358ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_instr_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14722494170933800345ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_mispredict_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16843113363819858743ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_valid_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6015661904587498651ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_pc_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2592561036259068169ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_taken_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1655686544948527820ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_bp_upd_target_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16811706878826181939ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pred_ras_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 95284517462624849ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_pred_ras_target_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2654344909611154958ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_advance_to_ex_mem = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4378452866044765117ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs1_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10123444382768080277ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__rs2_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 780360929340364749ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__alu_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11039228196699846472ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__branch_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10153190825969178883ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__if_ex_pc_plus_imm = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 887526586518313784ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_bp_upd_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8070467338709735657ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__mul_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17105901718839930924ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__div_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6145098304021056237ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__mul_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1702219930263155822ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__div_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7719202224081037619ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_started = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3382367927336031310ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_active_is_div = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 285975932764425574ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_result_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18138564182107237286ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_result_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 320927518709714532ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 495732724091306708ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__md_start = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2446402313487341001ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__store_addr_lo = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 1682538471714480345ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_csr_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6437064167178013144ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__id_csr_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11809560732916387167ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_csr_we = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4900522134856459166ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_trap_enter = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5975781912127997083ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_trap_exit = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14840174913971395138ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_valid_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18130818589083092297ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_pc_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5264112412368909745ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_alu_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3300010252112234499ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_md_result_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5801494295311627119ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_pc_plus_4_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8473665332470636784ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_pc_plus_imm_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13615791518269685856ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_rdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16077838390924669408ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_rd_idx_r = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 4105284144952345271ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_rd_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3631173685481328425ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_wb_sel_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 16518187402923576973ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_misaligned_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15156574905016955681ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_misaligned_store_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9880190106868191478ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_ls_funct3_r = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 13849244176441217024ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_addr_lo_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 9225171030659604622ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_mret_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 332251475359871056ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_we_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16025190284950012728ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_addr_r = VL_SCOPED_RAND_RESET_I(12, __VscopeHash, 354122669529508885ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_op_r = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3290309997531963757ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_csr_wdata_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2734360557993122345ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_branch_taken_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13834488068122169147ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_jal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10667172132061861049ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_jalr_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 586916379848556627ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_illegal_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2569586518328175143ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_ecall_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14640874357491366467ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_is_ebreak_r = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10405130190365150480ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_wb_instr_r = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11435126102128210066ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_irq = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14569748300805161018ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__mem_ras_mispredict = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2015687180800958742ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_data_trap = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9789423199904832915ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_take_sync_trap = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6909561484731384680ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__ex_mem_advance_to_wb = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7797522813985008199ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__wb_data_mux = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4443157029098054779ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_9 = 0;
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_13 = 0;
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_14 = 0;
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_15 = 0;
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_16 = 0;
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT____VdfgRegularize_h705a9e90_0_17 = 0;
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__valid0[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11519360663436121928ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__tag0[__Vi0] = VL_SCOPED_RAND_RESET_I(26, __VscopeHash, 16443967359777351859ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__target0[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17825527512879101979ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__counter0[__Vi0] = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4257478643580188781ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__valid1[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17737603011713051204ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__tag1[__Vi0] = VL_SCOPED_RAND_RESET_I(26, __VscopeHash, 13285449234352142793ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__target1[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3065917369741555209ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__counter1[__Vi0] = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17052842966954142487ull);
    }
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__lru[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11312594236262039830ull);
    }
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__wr_way = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8137704624338997254ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_bp__DOT__cnt_next = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 8132510679562019562ull);
    for (int __Vi0 = 0; __Vi0 < 8; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__stack[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1841442208438227024ull);
    }
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__ptr = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 9115965980314336529ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ras__DOT__top_idx = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10473989431514854368ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_ifu__DOT__pc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13339782952557279177ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5 = 0;
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_rfu__DOT__regs[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8591956389700374157ull);
    }
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14590726551760430361ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__done_pending = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9427757854383806581ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__opa_r = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 4870302014792916433ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__opb_r = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 13398368985656038809ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__high_out = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12268453300130739224ull);
    VL_SCOPED_RAND_RESET_W(66, vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_mul__DOT__product_w, __VscopeHash, 18111073303680999408ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2450851765945868789ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__iter = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 4533885708054598858ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__dividend = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 747492458435242928ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__divisor = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11213087100133461907ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__quotient = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9119837625288441373ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__remainder = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11455463452183294561ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__orig_a = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2725276354907399484ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__ret_rem = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3726021100277269157ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__sign_quot = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17486122027086433183ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__sign_rem = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14971668924034845879ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__div_by_zero = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14524101284069144926ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__overflow = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11874323718358411625ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__shifted_rem = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 13782077570883148615ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_div__DOT__sub_w = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 13409573889961246916ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mie_meie = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6661843939277501450ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mstatus_mie = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8452376188672720871ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mstatus_mpie = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10130729527075790522ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mtvec_base = VL_SCOPED_RAND_RESET_I(30, __VscopeHash, 673596469713762433ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mscratch = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3418073763589668920ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mepc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3767340154233567230ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mcause_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1961537895778200447ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__mtval_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 577705565339310268ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__ext_pending = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9143877074168778018ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__cycle_cnt = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 10420976079197177248ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__instret_cnt = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 6449817317062034735ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_cpu__DOT__u_core__DOT__u_csr__DOT__new_val = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9192203952320217117ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__i_state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 9226762966483802259ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__i_araddr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14148086545310850352ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17205780468014182207ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12119337924180761583ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14532843849185943465ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 5394396799340953374ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_aw_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1708686402979566071ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__d_w_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15155077115104275549ull);
    vlSelf->tb_axil_archtest__DOT__dut__DOT__u_axil__DOT__axi_err_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6750542958995032533ull);
    for (int __Vi0 = 0; __Vi0 < 524288; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__i_mem__DOT__memory[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8912985210195550307ull);
    }
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__rd_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9155495869964882466ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__rd_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6312340423853918210ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__rd_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6214116576555452311ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__aw_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6785556038093340968ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__w_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2513781371012844678ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__wr_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 403439832290180572ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__wr_data_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 740394975591602204ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__wr_strb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1712385543105431575ull);
    vlSelf->tb_axil_archtest__DOT__i_mem__DOT__wr_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6013487698251215734ull);
    for (int __Vi0 = 0; __Vi0 < 524288; ++__Vi0) {
        vlSelf->tb_axil_archtest__DOT__d_mem__DOT__memory[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16106654813993855756ull);
    }
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__rd_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13520753584527255804ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__rd_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9944768913742696081ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__rd_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12077060277728727932ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__aw_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14010704954990519204ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__w_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2724702030161236984ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__wr_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4500139773250496111ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__wr_data_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6027603221040705788ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__wr_strb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 1293763300590702523ull);
    vlSelf->tb_axil_archtest__DOT__d_mem__DOT__wr_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6185735885318700516ull);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__tb_axil_archtest__DOT__clk__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
