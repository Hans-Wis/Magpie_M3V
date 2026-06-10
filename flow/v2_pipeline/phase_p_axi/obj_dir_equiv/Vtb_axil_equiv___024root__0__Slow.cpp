// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_equiv.h for the primary calling header

#include "Vtb_axil_equiv__pch.h"

void Vtb_axil_equiv___024root___timing_ready(Vtb_axil_equiv___024root* vlSelf);

VL_ATTR_COLD void Vtb_axil_equiv___024root___eval_static(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_static\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_equiv__DOT__clk = 0U;
    vlSelfRef.tb_axil_equiv__DOT__resetn = 0U;
    vlSelfRef.tb_axil_equiv__DOT__n_count = 0U;
    vlSelfRef.tb_axil_equiv__DOT__a_count = 0U;
    vlSelfRef.tb_axil_equiv__DOT__n_done = 0U;
    vlSelfRef.tb_axil_equiv__DOT__a_done = 0U;
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word_idx = VL_SCOPED_RAND_RESET_I(19, __VscopeHash, 13497740345523011986ull);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9780377888787394010ull);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14712855827731428190ull);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0 = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 299574524500679562ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__offset = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2556064254312808075ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__idx = VL_SCOPED_RAND_RESET_I(19, __VscopeHash, 15579489402918320625ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15908101646011345983ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14802007338299876564ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0 = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 3817348699484579706ull);
    vlSelfRef.__Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0 = 0U;
    Vtb_axil_equiv___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vtb_axil_equiv___024root___eval_static__TOP(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_static__TOP\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_equiv__DOT__clk = 0U;
    vlSelfRef.tb_axil_equiv__DOT__resetn = 0U;
    vlSelfRef.tb_axil_equiv__DOT__n_count = 0U;
    vlSelfRef.tb_axil_equiv__DOT__a_count = 0U;
    vlSelfRef.tb_axil_equiv__DOT__n_done = 0U;
    vlSelfRef.tb_axil_equiv__DOT__a_done = 0U;
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word_idx = VL_SCOPED_RAND_RESET_I(19, __VscopeHash, 13497740345523011986ull);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9780377888787394010ull);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14712855827731428190ull);
    vlSelf->tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0 = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 299574524500679562ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__offset = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2556064254312808075ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__idx = VL_SCOPED_RAND_RESET_I(19, __VscopeHash, 15579489402918320625ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15908101646011345983ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14802007338299876564ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0 = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 3817348699484579706ull);
}

VL_ATTR_COLD void Vtb_axil_equiv___024root___eval_final(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_final\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_equiv___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_axil_equiv___024root___eval_phase__stl(Vtb_axil_equiv___024root* vlSelf);

VL_ATTR_COLD void Vtb_axil_equiv___024root___eval_settle(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_settle\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vtb_axil_equiv___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("tb_axil_equiv.v", 3, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vtb_axil_equiv___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void Vtb_axil_equiv___024root___eval_triggers_vec__stl(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_triggers_vec__stl\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool Vtb_axil_equiv___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_equiv___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_axil_equiv___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vtb_axil_equiv___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___trigger_anySet__stl\n"); );
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

VL_ATTR_COLD void Vtb_axil_equiv___024root___stl_sequent__TOP__0(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___stl_sequent__TOP__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_equiv__DOT__a_i_arready = ((~ 
                                                  ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid) 
                                                   | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy))) 
                                                 & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
    vlSelfRef.tb_axil_equiv__DOT__a_d_arready = ((~ 
                                                  ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid) 
                                                   | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy))) 
                                                 & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
    if (vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy) {
        vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
            = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wdata_q;
        vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb 
            = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wstrb_q;
    } else {
        vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
            = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_store_wdata_r;
        vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb 
            = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__core_d_mem_wstrb;
    }
    vlSelfRef.tb_axil_equiv__DOT__n_didx = (0x0007ffffU 
                                            & (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                 ? vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_addr_q
                                                 : vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                                               >> 2U));
    vlSelfRef.tb_axil_equiv__DOT__a_d_awvalid = ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done)) 
                                                 & (3U 
                                                    == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)));
    vlSelfRef.tb_axil_equiv__DOT__a_d_wvalid = ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done)) 
                                                & (3U 
                                                   == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)));
    vlSelfRef.tb_axil_equiv__DOT__a_d_awready = ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
                                                 & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen)) 
                                                    & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
    vlSelfRef.tb_axil_equiv__DOT__a_d_wready = ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
                                                & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen)) 
                                                   & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb 
        = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy)
            ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_wstrb_q)
            : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__core_d_mem_wstrb));
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__ibus_req 
        = (1U & ((~ (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__primed)) 
                 | ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_fire) 
                    | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_busy))));
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_req 
        = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_fire) 
           | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy));
}

VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_native__0(Vtb_axil_equiv_cpu_m1_top* vlSelf);
VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0(Vtb_axil_equiv_cpu_m1_top* vlSelf);
VL_ATTR_COLD void Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1(Vtb_axil_equiv_cpu_m1_top* vlSelf);

VL_ATTR_COLD void Vtb_axil_equiv___024root___eval_stl(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_stl\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_native__0((&vlSymsp->TOP__tb_axil_equiv__DOT__u_native));
        Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0((&vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu));
        vlSelfRef.tb_axil_equiv__DOT__a_i_arready = 
            ((~ ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid) 
                 | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy))) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
        vlSelfRef.tb_axil_equiv__DOT__a_d_arready = 
            ((~ ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid) 
                 | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy))) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
        if (vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy) {
            vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wdata_q;
            vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wstrb_q;
        } else {
            vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_store_wdata_r;
            vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__core_d_mem_wstrb;
        }
        vlSelfRef.tb_axil_equiv__DOT__n_didx = (0x0007ffffU 
                                                & (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                     ? vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_addr_q
                                                     : vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                                                   >> 2U));
        vlSelfRef.tb_axil_equiv__DOT__a_d_awvalid = 
            ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done)) 
             & (3U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)));
        vlSelfRef.tb_axil_equiv__DOT__a_d_wvalid = 
            ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done)) 
             & (3U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)));
        vlSelfRef.tb_axil_equiv__DOT__a_d_awready = 
            ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
             & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen)) 
                & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
        vlSelfRef.tb_axil_equiv__DOT__a_d_wready = 
            ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
             & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen)) 
                & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb 
            = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy)
                ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_wstrb_q)
                : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__core_d_mem_wstrb));
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__ibus_req 
            = (1U & ((~ (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__primed)) 
                     | ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_fire) 
                        | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_busy))));
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_req 
            = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_fire) 
               | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy));
        Vtb_axil_equiv_cpu_m1_top___stl_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1((&vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu));
    }
}

VL_ATTR_COLD bool Vtb_axil_equiv___024root___eval_phase__stl(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_phase__stl\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtb_axil_equiv___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_axil_equiv___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vtb_axil_equiv___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vtb_axil_equiv___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vtb_axil_equiv___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_equiv___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_axil_equiv___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge tb_axil_equiv.clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_axil_equiv___024root___ctor_var_reset(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___ctor_var_reset\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    VL_SCOPED_RAND_RESET_W(1024, vlSelf->tb_axil_equiv__DOT__firmware_hex, __VscopeHash, 12526880894389268992ull);
    VL_SCOPED_RAND_RESET_W(1024, vlSelf->tb_axil_equiv__DOT__native_trace_path, __VscopeHash, 10211022137705401557ull);
    VL_SCOPED_RAND_RESET_W(1024, vlSelf->tb_axil_equiv__DOT__axi_trace_path, __VscopeHash, 6753548474391686125ull);
    vlSelf->tb_axil_equiv__DOT__wait_states = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9346925095097097833ull);
    vlSelf->tb_axil_equiv__DOT__max_cycles = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7749076563360132162ull);
    vlSelf->tb_axil_equiv__DOT__n_fd = 0;
    vlSelf->tb_axil_equiv__DOT__a_fd = 0;
    vlSelf->tb_axil_equiv__DOT__watchdog = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10430200810229089914ull);
    vlSelf->tb_axil_equiv__DOT__errors = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6305908826868125884ull);
    vlSelf->tb_axil_equiv__DOT__idx = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12885197037841298383ull);
    for (int __Vi0 = 0; __Vi0 < 524288; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__native_mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4255072957553303239ull);
    }
    vlSelf->tb_axil_equiv__DOT__n_dbus_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9970402208391841927ull);
    vlSelf->tb_axil_equiv__DOT__n_dbus_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 133042525945013330ull);
    vlSelf->tb_axil_equiv__DOT__n_didx = VL_SCOPED_RAND_RESET_I(19, __VscopeHash, 10264444250450449129ull);
    vlSelf->tb_axil_equiv__DOT__a_i_arready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18018050660327135245ull);
    vlSelf->tb_axil_equiv__DOT__a_i_rvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13027343764798028368ull);
    vlSelf->tb_axil_equiv__DOT__a_i_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7160840807917033448ull);
    vlSelf->tb_axil_equiv__DOT__a_d_arready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12763904643125192077ull);
    vlSelf->tb_axil_equiv__DOT__a_d_rvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17779772578622704049ull);
    vlSelf->tb_axil_equiv__DOT__a_d_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3920604431836767270ull);
    vlSelf->tb_axil_equiv__DOT__a_d_awvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8970456183477948891ull);
    vlSelf->tb_axil_equiv__DOT__a_d_awready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16422698815090476608ull);
    vlSelf->tb_axil_equiv__DOT__a_d_wvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1120972501922614371ull);
    vlSelf->tb_axil_equiv__DOT__a_d_wready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7017243113528828820ull);
    vlSelf->tb_axil_equiv__DOT__a_d_bvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3387793473699315103ull);
    vlSelf->tb_axil_equiv__DOT__unused_i_bvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 550882045941282088ull);
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_pc[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1225188437190123102ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_instr[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8378481414200408802ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_rd[__Vi0] = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 8401714566129468602ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_wdata[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15520326713587824743ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_mstatus[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9904186842281347848ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_mepc[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6493184198092178253ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_mcause[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15672905471680930396ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__n_mtval[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17158248685647040027ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_pc[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16266968743774263438ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_instr[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2303381795694118119ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_rd[__Vi0] = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 15282311751799313835ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_wdata[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7191643444665238667ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_mstatus[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17404333780617113920ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_mepc[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2651129196943694067ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_mcause[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8689851025425500659ull);
    }
    for (int __Vi0 = 0; __Vi0 < 8192; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__a_mtval[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 18397703487414846026ull);
    }
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__ibus_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5287836230181701808ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__dbus_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5484952878195807165ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 533343267185025397ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2737619300664191134ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_araddr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3716476307756812426ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 5781932891285159573ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14337265552155505341ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13015000622851295388ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7075325421525990376ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9417758972868743948ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10563064386140866039ull);
    vlSelf->tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__axi_err_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6134204506015727045ull);
    for (int __Vi0 = 0; __Vi0 < 524288; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__memory[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4930208216991037741ull);
    }
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3350441751815827948ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__rd_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15522705665428603681ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5068851706261674404ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2069513107401292367ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__w_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14420882976833806627ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__wr_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 883756917909856942ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__wr_data_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2840259892771618918ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__wr_strb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 10518016838155336046ull);
    vlSelf->tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9539005144743243303ull);
    for (int __Vi0 = 0; __Vi0 < 524288; ++__Vi0) {
        vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__memory[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7644429070430638387ull);
    }
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6188449587868288221ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__rd_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6676990902374916147ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 766109926797490264ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2823460704648288346ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__w_seen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18396838932569472348ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__wr_addr_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9408586545098858093ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__wr_data_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9463748609843873010ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__wr_strb_q = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 11600995702143104113ull);
    vlSelf->tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10175772945180797220ull);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
