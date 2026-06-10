// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_equiv.h for the primary calling header

#include "Vtb_axil_equiv__pch.h"

VlCoroutine Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__0(Vtb_axil_equiv___024root* vlSelf);
VlCoroutine Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__1(Vtb_axil_equiv___024root* vlSelf);
void Vtb_axil_equiv_cpu_m1_top___eval_initial__TOP__tb_axil_equiv__DOT__u_native(Vtb_axil_equiv_cpu_m1_top* vlSelf);

void Vtb_axil_equiv___024root___eval_initial(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_initial\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    Vtb_axil_equiv_cpu_m1_top___eval_initial__TOP__tb_axil_equiv__DOT__u_native((&vlSymsp->TOP__tb_axil_equiv__DOT__u_native));
    Vtb_axil_equiv_cpu_m1_top___eval_initial__TOP__tb_axil_equiv__DOT__u_native((&vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu));
}

extern const VlWide<32>/*1023:0*/ Vtb_axil_equiv__ConstPool__CONST_h0eac72c9_0;
extern const VlWide<32>/*1023:0*/ Vtb_axil_equiv__ConstPool__CONST_h75dcfd94_0;
extern const VlWide<32>/*1023:0*/ Vtb_axil_equiv__ConstPool__CONST_h2437df8b_0;
void Vtb_axil_equiv___024root____VbeforeTrig_h411bf940__0(Vtb_axil_equiv___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__0(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ tb_axil_equiv__DOT__i;
    tb_axil_equiv__DOT__i = 0;
    IData/*31:0*/ tb_axil_equiv__DOT__unnamedblk1_1__DOT____Vrepeat0;
    tb_axil_equiv__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__i;
    tb_axil_equiv__DOT__u_i_mem__DOT__i = 0;
    IData/*31:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__i;
    tb_axil_equiv__DOT__u_d_mem__DOT__i = 0;
    VlWide<32>/*1023:0*/ __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path;
    VL_ZERO_W(1024, __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path);
    VlWide<32>/*1023:0*/ __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path;
    VL_ZERO_W(1024, __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path);
    // Body
    if ((! VL_VALUEPLUSARGS_INW(1024, "HEX=%s"s, vlSelfRef.tb_axil_equiv__DOT__firmware_hex))) {
        VL_ASSIGN_W(1024, vlSelfRef.tb_axil_equiv__DOT__firmware_hex, Vtb_axil_equiv__ConstPool__CONST_h0eac72c9_0);
    }
    if ((! VL_VALUEPLUSARGS_INW(1024, "NATIVE_TRACE=%s"s, 
                                vlSelfRef.tb_axil_equiv__DOT__native_trace_path))) {
        VL_ASSIGN_W(1024, vlSelfRef.tb_axil_equiv__DOT__native_trace_path, Vtb_axil_equiv__ConstPool__CONST_h75dcfd94_0);
    }
    if ((! VL_VALUEPLUSARGS_INW(1024, "AXI_TRACE=%s"s, 
                                vlSelfRef.tb_axil_equiv__DOT__axi_trace_path))) {
        VL_ASSIGN_W(1024, vlSelfRef.tb_axil_equiv__DOT__axi_trace_path, Vtb_axil_equiv__ConstPool__CONST_h2437df8b_0);
    }
    if ((! VL_VALUEPLUSARGS_INI(32, "WAIT=%d"s, vlSelfRef.tb_axil_equiv__DOT__wait_states))) {
        vlSelfRef.tb_axil_equiv__DOT__wait_states = 0U;
    }
    if ((! VL_VALUEPLUSARGS_INI(32, "MAX_CYCLES=%d"s, 
                                vlSelfRef.tb_axil_equiv__DOT__max_cycles))) {
        vlSelfRef.tb_axil_equiv__DOT__max_cycles = 0x000f4240U;
    }
    tb_axil_equiv__DOT__i = 0U;
    while (VL_GTS_III(32, 0x00080000U, tb_axil_equiv__DOT__i)) {
        vlSelfRef.tb_axil_equiv__DOT__native_mem[(0x0007ffffU 
                                                  & tb_axil_equiv__DOT__i)] = 0U;
        tb_axil_equiv__DOT__i = ((IData)(1U) + tb_axil_equiv__DOT__i);
    }
    VL_READMEM_N(true, 32, 524288, 0, VL_CVT_PACK_STR_NW(32, vlSelfRef.tb_axil_equiv__DOT__firmware_hex)
                 ,  &(vlSelfRef.tb_axil_equiv__DOT__native_mem)
                 , 0, ~0ULL);
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[0U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[0U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[1U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[1U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[2U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[2U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[3U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[3U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[4U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[4U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[5U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[5U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[6U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[6U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[7U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[7U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[8U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[8U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[9U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[9U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[10U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[10U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[11U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[11U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[12U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[12U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[13U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[13U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[14U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[14U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[15U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[15U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[16U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[16U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[17U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[17U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[18U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[18U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[19U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[19U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[20U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[20U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[21U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[21U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[22U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[22U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[23U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[23U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[24U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[24U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[25U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[25U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[26U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[26U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[27U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[27U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[28U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[28U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[29U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[29U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[30U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[30U];
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path[31U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[31U];
    tb_axil_equiv__DOT__u_i_mem__DOT__i = 0U;
    while (VL_GTS_III(32, 0x00080000U, tb_axil_equiv__DOT__u_i_mem__DOT__i)) {
        vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory[(0x0007ffffU 
                                                            & tb_axil_equiv__DOT__u_i_mem__DOT__i)] = 0U;
        tb_axil_equiv__DOT__u_i_mem__DOT__i = ((IData)(1U) 
                                               + tb_axil_equiv__DOT__u_i_mem__DOT__i);
    }
    VL_READMEM_N(true, 32, 524288, 0, VL_CVT_PACK_STR_NW(32, __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__load_hex__0__path)
                 ,  &(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory)
                 , 0, ~0ULL);
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[0U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[0U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[1U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[1U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[2U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[2U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[3U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[3U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[4U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[4U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[5U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[5U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[6U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[6U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[7U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[7U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[8U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[8U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[9U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[9U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[10U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[10U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[11U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[11U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[12U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[12U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[13U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[13U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[14U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[14U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[15U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[15U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[16U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[16U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[17U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[17U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[18U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[18U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[19U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[19U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[20U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[20U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[21U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[21U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[22U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[22U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[23U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[23U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[24U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[24U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[25U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[25U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[26U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[26U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[27U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[27U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[28U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[28U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[29U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[29U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[30U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[30U];
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path[31U] 
        = vlSelfRef.tb_axil_equiv__DOT__firmware_hex[31U];
    tb_axil_equiv__DOT__u_d_mem__DOT__i = 0U;
    while (VL_GTS_III(32, 0x00080000U, tb_axil_equiv__DOT__u_d_mem__DOT__i)) {
        vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory[(0x0007ffffU 
                                                            & tb_axil_equiv__DOT__u_d_mem__DOT__i)] = 0U;
        tb_axil_equiv__DOT__u_d_mem__DOT__i = ((IData)(1U) 
                                               + tb_axil_equiv__DOT__u_d_mem__DOT__i);
    }
    VL_READMEM_N(true, 32, 524288, 0, VL_CVT_PACK_STR_NW(32, __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__load_hex__1__path)
                 ,  &(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory)
                 , 0, ~0ULL);
    vlSelfRef.tb_axil_equiv__DOT__n_fd = VL_FOPEN_NN(
                                                     VL_CVT_PACK_STR_NW(32, vlSelfRef.tb_axil_equiv__DOT__native_trace_path)
                                                     , "w"s);
    ;
    vlSelfRef.tb_axil_equiv__DOT__a_fd = VL_FOPEN_NN(
                                                     VL_CVT_PACK_STR_NW(32, vlSelfRef.tb_axil_equiv__DOT__axi_trace_path)
                                                     , "w"s);
    ;
    if (VL_UNLIKELY((((0U == vlSelfRef.tb_axil_equiv__DOT__n_fd) 
                      | (0U == vlSelfRef.tb_axil_equiv__DOT__a_fd))))) {
        VL_WRITEF_NX("FAIL: could not open trace files\n[%0t] %%Fatal: tb_axil_equiv.v:300: Assertion failed in %Ntb_axil_equiv\n",0,
                     64,VL_TIME_UNITED_Q(1),-9,vlSymsp->name());
        VL_STOP_MT("tb_axil_equiv.v", 300, "", false);
    }
    VL_FWRITEF_NX(vlSelfRef.tb_axil_equiv__DOT__n_fd,"idx,pc,instr,rd,wdata,mstatus,mepc,mcause,mtval\n",0);
    VL_FWRITEF_NX(vlSelfRef.tb_axil_equiv__DOT__a_fd,"idx,pc,instr,rd,wdata,mstatus,mepc,mcause,mtval\n",0);
    tb_axil_equiv__DOT__unnamedblk1_1__DOT____Vrepeat0 = 6U;
    while (VL_LTS_III(32, 0U, tb_axil_equiv__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vtb_axil_equiv___024root____VbeforeTrig_h411bf940__0(vlSelf, 
                                                             "@(posedge tb_axil_equiv.clk)");
        co_await vlSelfRef.__VtrigSched_h411bf940__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_axil_equiv.clk)", 
                                                             "tb_axil_equiv.v", 
                                                             305);
        tb_axil_equiv__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (tb_axil_equiv__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    vlSelfRef.tb_axil_equiv__DOT__resetn = 1U;
    co_return;
}

VlCoroutine Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__1(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(5ULL, 
                                             nullptr, 
                                             "tb_axil_equiv.v", 
                                             10);
        vlSelfRef.tb_axil_equiv__DOT__clk = (1U & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__clk)));
    }
    co_return;
}

void Vtb_axil_equiv___024root___eval_triggers_vec__act(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_triggers_vec__act\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                      << 1U) 
                                                     | ((IData)(vlSelfRef.tb_axil_equiv__DOT__clk) 
                                                        & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0))))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0 
        = vlSelfRef.tb_axil_equiv__DOT__clk;
}

bool Vtb_axil_equiv___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___trigger_anySet__act\n"); );
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

void Vtb_axil_equiv___024root___act_sequent__TOP__0(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___act_sequent__TOP__0\n"); );
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
    vlSelfRef.tb_axil_equiv__DOT__a_d_awready = ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
                                                 & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen)) 
                                                    & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
    vlSelfRef.tb_axil_equiv__DOT__a_d_wready = ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
                                                & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen)) 
                                                   & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
}

void Vtb_axil_equiv___024root___act_sequent__TOP__1(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___act_sequent__TOP__1\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                   ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wstrb_q)
                                                   : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__core_d_mem_wstrb));
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

void Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_native__0(Vtb_axil_equiv_cpu_m1_top* vlSelf);
void Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0(Vtb_axil_equiv_cpu_m1_top* vlSelf);

void Vtb_axil_equiv___024root___eval_act(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_act\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.tb_axil_equiv__DOT__a_i_arready = 
            ((~ ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid) 
                 | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy))) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
        vlSelfRef.tb_axil_equiv__DOT__a_d_arready = 
            ((~ ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid) 
                 | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy))) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
        vlSelfRef.tb_axil_equiv__DOT__a_d_awready = 
            ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
             & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen)) 
                & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
        vlSelfRef.tb_axil_equiv__DOT__a_d_wready = 
            ((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
             & ((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen)) 
                & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))));
        Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_native__0((&vlSymsp->TOP__tb_axil_equiv__DOT__u_native));
        Vtb_axil_equiv_cpu_m1_top___act_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0((&vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu));
        vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb 
            = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wstrb_q)
                : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__core_d_mem_wstrb));
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
}

void Vtb_axil_equiv___024root___nba_sequent__TOP__0(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___nba_sequent__TOP__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__Vfuncout;
    __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__pc;
    __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__pc = 0;
    IData/*31:0*/ __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__Vfuncout;
    __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__pc;
    __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__pc = 0;
    IData/*18:0*/ __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx;
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx = 0;
    IData/*31:0*/ __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data;
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data = 0;
    CData/*3:0*/ __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb;
    __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb = 0;
    IData/*18:0*/ __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx;
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx = 0;
    IData/*31:0*/ __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data;
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data = 0;
    CData/*3:0*/ __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb;
    __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb = 0;
    IData/*31:0*/ __Vdly__tb_axil_equiv__DOT__watchdog;
    __Vdly__tb_axil_equiv__DOT__watchdog = 0;
    CData/*1:0*/ __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state;
    __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = 0;
    CData/*1:0*/ __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state;
    __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__a_i_rvalid;
    __Vdly__tb_axil_equiv__DOT__a_i_rvalid = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy = 0;
    IData/*31:0*/ __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__unused_i_bvalid;
    __Vdly__tb_axil_equiv__DOT__unused_i_bvalid = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__w_seen;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__w_seen = 0;
    IData/*31:0*/ __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__a_d_rvalid;
    __Vdly__tb_axil_equiv__DOT__a_d_rvalid = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy = 0;
    IData/*31:0*/ __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__a_d_bvalid;
    __Vdly__tb_axil_equiv__DOT__a_d_bvalid = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen = 0;
    CData/*0:0*/ __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen = 0;
    IData/*31:0*/ __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q = 0;
    CData/*7:0*/ __VdlyVal__tb_axil_equiv__DOT__native_mem__v0;
    __VdlyVal__tb_axil_equiv__DOT__native_mem__v0 = 0;
    IData/*18:0*/ __VdlyDim0__tb_axil_equiv__DOT__native_mem__v0;
    __VdlyDim0__tb_axil_equiv__DOT__native_mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_axil_equiv__DOT__native_mem__v0;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_axil_equiv__DOT__native_mem__v1;
    __VdlyVal__tb_axil_equiv__DOT__native_mem__v1 = 0;
    IData/*18:0*/ __VdlyDim0__tb_axil_equiv__DOT__native_mem__v1;
    __VdlyDim0__tb_axil_equiv__DOT__native_mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_axil_equiv__DOT__native_mem__v1;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_axil_equiv__DOT__native_mem__v2;
    __VdlyVal__tb_axil_equiv__DOT__native_mem__v2 = 0;
    IData/*18:0*/ __VdlyDim0__tb_axil_equiv__DOT__native_mem__v2;
    __VdlyDim0__tb_axil_equiv__DOT__native_mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_axil_equiv__DOT__native_mem__v2;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_axil_equiv__DOT__native_mem__v3;
    __VdlyVal__tb_axil_equiv__DOT__native_mem__v3 = 0;
    IData/*18:0*/ __VdlyDim0__tb_axil_equiv__DOT__native_mem__v3;
    __VdlyDim0__tb_axil_equiv__DOT__native_mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_axil_equiv__DOT__native_mem__v3;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v3 = 0;
    // Body
    __VdlySet__tb_axil_equiv__DOT__native_mem__v0 = 0U;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v1 = 0U;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v2 = 0U;
    __VdlySet__tb_axil_equiv__DOT__native_mem__v3 = 0U;
    __Vdly__tb_axil_equiv__DOT__unused_i_bvalid = vlSelfRef.tb_axil_equiv__DOT__unused_i_bvalid;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen 
        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__w_seen 
        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__w_seen;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q 
        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state 
        = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q 
        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy 
        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy;
    __Vdly__tb_axil_equiv__DOT__a_i_rvalid = vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid;
    __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state 
        = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q 
        = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy 
        = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy;
    __Vdly__tb_axil_equiv__DOT__a_d_rvalid = vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q 
        = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen 
        = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen;
    __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen 
        = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen;
    __Vdly__tb_axil_equiv__DOT__a_d_bvalid = vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid;
    __Vdly__tb_axil_equiv__DOT__watchdog = vlSelfRef.tb_axil_equiv__DOT__watchdog;
    if ((((IData)(vlSelfRef.tb_axil_equiv__DOT__resetn) 
          & (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_xfer)) 
         & (0U != (IData)(vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb)))) {
        if ((1U & (IData)(vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb))) {
            __VdlyVal__tb_axil_equiv__DOT__native_mem__v0 
                = (0x000000ffU & vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata);
            __VdlyDim0__tb_axil_equiv__DOT__native_mem__v0 
                = vlSelfRef.tb_axil_equiv__DOT__n_didx;
            __VdlySet__tb_axil_equiv__DOT__native_mem__v0 = 1U;
        }
        if ((2U & (IData)(vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb))) {
            __VdlyVal__tb_axil_equiv__DOT__native_mem__v1 
                = (0x000000ffU & (vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
                                  >> 8U));
            __VdlyDim0__tb_axil_equiv__DOT__native_mem__v1 
                = vlSelfRef.tb_axil_equiv__DOT__n_didx;
            __VdlySet__tb_axil_equiv__DOT__native_mem__v1 = 1U;
        }
        if ((4U & (IData)(vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb))) {
            __VdlyVal__tb_axil_equiv__DOT__native_mem__v2 
                = (0x000000ffU & (vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
                                  >> 0x10U));
            __VdlyDim0__tb_axil_equiv__DOT__native_mem__v2 
                = vlSelfRef.tb_axil_equiv__DOT__n_didx;
            __VdlySet__tb_axil_equiv__DOT__native_mem__v2 = 1U;
        }
        if ((8U & (IData)(vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb))) {
            __VdlyVal__tb_axil_equiv__DOT__native_mem__v3 
                = (vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata 
                   >> 0x18U);
            __VdlyDim0__tb_axil_equiv__DOT__native_mem__v3 
                = vlSelfRef.tb_axil_equiv__DOT__n_didx;
            __VdlySet__tb_axil_equiv__DOT__native_mem__v3 = 1U;
        }
    }
    if (vlSelfRef.tb_axil_equiv__DOT__resetn) {
        if ((((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__unused_i_bvalid)) 
              & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen)) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__w_seen))) {
            if ((0U == vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q)) {
                __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb 
                    = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_strb_q;
                __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data 
                    = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_data_q;
                __Vdly__tb_axil_equiv__DOT__unused_i_bvalid = 1U;
                __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen = 0U;
                __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__w_seen = 0U;
                __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q 
                    = vlSelfRef.tb_axil_equiv__DOT__wait_states;
                __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx 
                    = (0x0007ffffU & (vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_addr_q 
                                      >> 2U));
                if ((1U & (IData)(__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx] 
                        = ((0xffffff00U & vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx]) 
                           | (0x000000ffU & __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data));
                }
                if ((2U & (IData)(__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx] 
                        = ((0xffff00ffU & vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx]) 
                           | (0x0000ff00U & __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data));
                }
                if ((4U & (IData)(__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx] 
                        = ((0xff00ffffU & vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx]) 
                           | (0x00ff0000U & __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data));
                }
                if ((8U & (IData)(__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx] 
                        = ((0x00ffffffU & vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__idx]) 
                           | (0xff000000U & __Vtask_tb_axil_equiv__DOT__u_i_mem__DOT__write_word__6__data));
                }
            } else {
                __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q 
                    = (vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q 
                       - (IData)(1U));
            }
        } else if ((1U & (((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen)) 
                           & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__w_seen))) 
                          & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__unused_i_bvalid))))) {
            __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q 
                = vlSelfRef.tb_axil_equiv__DOT__wait_states;
        }
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid) 
             & (3U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)))) {
            __Vdly__tb_axil_equiv__DOT__a_d_bvalid = 0U;
        }
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awvalid) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awready))) {
            __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen = 1U;
        }
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wvalid) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wready))) {
            __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen = 1U;
        }
        if ((((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid)) 
              & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen)) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen))) {
            if ((0U == vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q)) {
                __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb 
                    = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_strb_q;
                __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data 
                    = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_data_q;
                __Vdly__tb_axil_equiv__DOT__a_d_bvalid = 1U;
                __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen = 0U;
                __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen = 0U;
                __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q 
                    = vlSelfRef.tb_axil_equiv__DOT__wait_states;
                __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx 
                    = (0x0007ffffU & (vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_addr_q 
                                      >> 2U));
                if ((1U & (IData)(__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx] 
                        = ((0xffffff00U & vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx]) 
                           | (0x000000ffU & __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data));
                }
                if ((2U & (IData)(__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx] 
                        = ((0xffff00ffU & vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx]) 
                           | (0x0000ff00U & __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data));
                }
                if ((4U & (IData)(__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx] 
                        = ((0xff00ffffU & vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx]) 
                           | (0x00ff0000U & __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data));
                }
                if ((8U & (IData)(__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__strb))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory[__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx] 
                        = ((0x00ffffffU & vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory
                            [__Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__idx]) 
                           | (0xff000000U & __Vtask_tb_axil_equiv__DOT__u_d_mem__DOT__write_word__7__data));
                }
            } else {
                __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q 
                    = (vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q 
                       - (IData)(1U));
            }
        } else if ((1U & (((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen)) 
                           & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen))) 
                          & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))))) {
            __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q 
                = vlSelfRef.tb_axil_equiv__DOT__wait_states;
        }
    } else {
        __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen = 0U;
        __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__w_seen = 0U;
        __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q = 0U;
        __Vdly__tb_axil_equiv__DOT__unused_i_bvalid = 0U;
        __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen = 0U;
        __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen = 0U;
        __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q = 0U;
        __Vdly__tb_axil_equiv__DOT__a_d_bvalid = 0U;
    }
    if (vlSelfRef.tb_axil_equiv__DOT__resetn) {
        __Vdly__tb_axil_equiv__DOT__watchdog = ((IData)(1U) 
                                                + vlSelfRef.tb_axil_equiv__DOT__watchdog);
        if (VL_UNLIKELY((VL_GTS_III(32, vlSelfRef.tb_axil_equiv__DOT__watchdog, vlSelfRef.tb_axil_equiv__DOT__max_cycles)))) {
            VL_WRITEF_NX("FAIL wait=%0d: watchdog timeout native_pc=%08x axi_pc=%08x native_commits=%0d axi_commits=%0d\n[%0t] %%Fatal: tb_axil_equiv.v:315: Assertion failed in %Ntb_axil_equiv\n",0,
                         32,vlSelfRef.tb_axil_equiv__DOT__wait_states,
                         32,vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__if_ex_pc,
                         32,vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__u_core__DOT__if_ex_pc,
                         32,vlSelfRef.tb_axil_equiv__DOT__n_count,
                         32,vlSelfRef.tb_axil_equiv__DOT__a_count,
                         64,VL_TIME_UNITED_Q(1),-9,
                         vlSymsp->name());
            VL_STOP_MT("tb_axil_equiv.v", 315, "", false);
        }
        if (VL_UNLIKELY(((((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__n_done)) 
                           & (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__wb_instr_retired)) 
                          & (~ (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__ex_wb_illegal_r)))))) {
            if (VL_UNLIKELY((VL_LTES_III(32, 0x00002000U, vlSelfRef.tb_axil_equiv__DOT__n_count)))) {
                VL_WRITEF_NX("[%0t] %%Fatal: tb_axil_equiv.v:319: Assertion failed in %Ntb_axil_equiv: native commit array overflow\n",0,
                             64,VL_TIME_UNITED_Q(1),
                             -9,vlSymsp->name());
                VL_STOP_MT("tb_axil_equiv.v", 319, "", false);
            }
            vlSelfRef.tb_axil_equiv__DOT__n_pc[(0x00001fffU 
                                                & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__ex_wb_pc_r;
            __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__pc 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__ex_wb_pc_r;
            vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word_idx 
                = (0x0007ffffU & (__Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__pc 
                                  >> 2U));
            vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0 
                = vlSelfRef.tb_axil_equiv__DOT__native_mem
                [vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word_idx];
            if ((2U & __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__pc)) {
                vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0 
                    = (vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0 
                       >> 0x10U);
                if ((3U == (3U & (IData)(vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0)))) {
                    vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word1 
                        = vlSelfRef.tb_axil_equiv__DOT__native_mem
                        [(0x0007ffffU & ((IData)(1U) 
                                         + vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word_idx))];
                    __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__Vfuncout 
                        = ((vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word1 
                            << 0x00000010U) | (IData)(vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0));
                } else {
                    __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__Vfuncout 
                        = vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0;
                }
            } else {
                vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0 
                    = (0x0000ffffU & vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0);
                __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__Vfuncout 
                    = ((3U == (3U & (IData)(vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0)))
                        ? vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0
                        : (IData)(vlSelfRef.tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0));
            }
            vlSelfRef.tb_axil_equiv__DOT__n_instr[(0x00001fffU 
                                                   & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                = __Vfunc_tb_axil_equiv__DOT__native_instr_at_pc__3__Vfuncout;
            if (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__rfu_we) 
                 & (0U != (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_wb_rd_idx_r)))) {
                vlSelfRef.tb_axil_equiv__DOT__n_rd[(0x00001fffU 
                                                    & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_wb_rd_idx_r;
                vlSelfRef.tb_axil_equiv__DOT__n_wdata[(0x00001fffU 
                                                       & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__rfu_wr_data;
            } else {
                vlSelfRef.tb_axil_equiv__DOT__n_rd[(0x00001fffU 
                                                    & vlSelfRef.tb_axil_equiv__DOT__n_count)] = 0U;
                vlSelfRef.tb_axil_equiv__DOT__n_wdata[(0x00001fffU 
                                                       & vlSelfRef.tb_axil_equiv__DOT__n_count)] = 0U;
            }
            vlSelfRef.tb_axil_equiv__DOT__n_mstatus[(0x00001fffU 
                                                     & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__u_csr__DOT__mstatus_val;
            vlSelfRef.tb_axil_equiv__DOT__n_mepc[(0x00001fffU 
                                                  & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.tb_axil_equiv__DOT__n_mcause[(0x00001fffU 
                                                    & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__u_csr__DOT__mcause_reg;
            vlSelfRef.tb_axil_equiv__DOT__n_mtval[(0x00001fffU 
                                                   & vlSelfRef.tb_axil_equiv__DOT__n_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__u_csr__DOT__mtval_reg;
            VL_FWRITEF_NX(vlSelfRef.tb_axil_equiv__DOT__n_fd,"%0d,%08x,%08x,%0#,%08x,%08x,%08x,%08x,%08x\n",0,
                          32,vlSelfRef.tb_axil_equiv__DOT__n_count,
                          32,vlSelfRef.tb_axil_equiv__DOT__n_pc
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__n_instr
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          5,vlSelfRef.tb_axil_equiv__DOT__n_rd
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__n_wdata
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__n_mstatus
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__n_mepc
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__n_mcause
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__n_mtval
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__n_count)]);
            vlSelfRef.tb_axil_equiv__DOT__n_count = 
                ((IData)(1U) + vlSelfRef.tb_axil_equiv__DOT__n_count);
        }
        if (VL_UNLIKELY(((((~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_done)) 
                           & (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__wb_instr_retired)) 
                          & (~ (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__ex_wb_illegal_r)))))) {
            if (VL_UNLIKELY((VL_LTES_III(32, 0x00002000U, vlSelfRef.tb_axil_equiv__DOT__a_count)))) {
                VL_WRITEF_NX("[%0t] %%Fatal: tb_axil_equiv.v:323: Assertion failed in %Ntb_axil_equiv: axi commit array overflow\n",0,
                             64,VL_TIME_UNITED_Q(1),
                             -9,vlSymsp->name());
                VL_STOP_MT("tb_axil_equiv.v", 323, "", false);
            }
            vlSelfRef.tb_axil_equiv__DOT__a_pc[(0x00001fffU 
                                                & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__ex_wb_pc_r;
            __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__pc 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__ex_wb_pc_r;
            vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__offset 
                = __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__pc;
            vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__idx 
                = (0x0007ffffU & (vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__offset 
                                  >> 2U));
            vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0 
                = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                [vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__idx];
            if ((2U & __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__pc)) {
                vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0 
                    = (vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0 
                       >> 0x10U);
                if ((3U == (3U & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0)))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word1 
                        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                        [(0x0007ffffU & ((IData)(1U) 
                                         + vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__idx))];
                    __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__Vfuncout 
                        = ((vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word1 
                            << 0x00000010U) | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0));
                } else {
                    __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__Vfuncout 
                        = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0;
                }
            } else {
                vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0 
                    = (0x0000ffffU & vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0);
                __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__Vfuncout 
                    = ((3U == (3U & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0)))
                        ? vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0
                        : (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0));
            }
            vlSelfRef.tb_axil_equiv__DOT__a_instr[(0x00001fffU 
                                                   & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                = __Vfunc_tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__5__Vfuncout;
            if (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__rfu_we) 
                 & (0U != (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__u_core__DOT__ex_wb_rd_idx_r)))) {
                vlSelfRef.tb_axil_equiv__DOT__a_rd[(0x00001fffU 
                                                    & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__u_core__DOT__ex_wb_rd_idx_r;
                vlSelfRef.tb_axil_equiv__DOT__a_wdata[(0x00001fffU 
                                                       & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__rfu_wr_data;
            } else {
                vlSelfRef.tb_axil_equiv__DOT__a_rd[(0x00001fffU 
                                                    & vlSelfRef.tb_axil_equiv__DOT__a_count)] = 0U;
                vlSelfRef.tb_axil_equiv__DOT__a_wdata[(0x00001fffU 
                                                       & vlSelfRef.tb_axil_equiv__DOT__a_count)] = 0U;
            }
            vlSelfRef.tb_axil_equiv__DOT__a_mstatus[(0x00001fffU 
                                                     & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__u_csr__DOT__mstatus_val;
            vlSelfRef.tb_axil_equiv__DOT__a_mepc[(0x00001fffU 
                                                  & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__u_csr__DOT__mepc_reg;
            vlSelfRef.tb_axil_equiv__DOT__a_mcause[(0x00001fffU 
                                                    & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__u_csr__DOT__mcause_reg;
            vlSelfRef.tb_axil_equiv__DOT__a_mtval[(0x00001fffU 
                                                   & vlSelfRef.tb_axil_equiv__DOT__a_count)] 
                = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__u_csr__DOT__mtval_reg;
            VL_FWRITEF_NX(vlSelfRef.tb_axil_equiv__DOT__a_fd,"%0d,%08x,%08x,%0#,%08x,%08x,%08x,%08x,%08x\n",0,
                          32,vlSelfRef.tb_axil_equiv__DOT__a_count,
                          32,vlSelfRef.tb_axil_equiv__DOT__a_pc
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__a_instr
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          5,vlSelfRef.tb_axil_equiv__DOT__a_rd
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__a_wdata
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__a_mstatus
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__a_mepc
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__a_mcause
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)],
                          32,vlSelfRef.tb_axil_equiv__DOT__a_mtval
                          [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__a_count)]);
            vlSelfRef.tb_axil_equiv__DOT__a_count = 
                ((IData)(1U) + vlSelfRef.tb_axil_equiv__DOT__a_count);
        }
        if (VL_UNLIKELY((((IData)(vlSelfRef.tb_axil_equiv__DOT__n_done) 
                          & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_done))))) {
            vlSelfRef.tb_axil_equiv__DOT__errors = 0U;
            if (VL_UNLIKELY(((vlSelfRef.tb_axil_equiv__DOT__n_count 
                              != vlSelfRef.tb_axil_equiv__DOT__a_count)))) {
                vlSelfRef.tb_axil_equiv__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.tb_axil_equiv__DOT__errors);
                VL_WRITEF_NX("FAIL wait=%0d: commit count native=%0d axi=%0d\n",0,
                             32,vlSelfRef.tb_axil_equiv__DOT__wait_states,
                             32,vlSelfRef.tb_axil_equiv__DOT__n_count,
                             32,vlSelfRef.tb_axil_equiv__DOT__a_count);
            }
            vlSelfRef.tb_axil_equiv__DOT__idx = 0U;
            while ((VL_LTS_III(32, vlSelfRef.tb_axil_equiv__DOT__idx, vlSelfRef.tb_axil_equiv__DOT__n_count) 
                    & VL_LTS_III(32, vlSelfRef.tb_axil_equiv__DOT__idx, vlSelfRef.tb_axil_equiv__DOT__a_count))) {
                if (VL_UNLIKELY((((((((((vlSelfRef.tb_axil_equiv__DOT__n_pc
                                         [(0x00001fffU 
                                           & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                         != vlSelfRef.tb_axil_equiv__DOT__a_pc
                                         [(0x00001fffU 
                                           & vlSelfRef.tb_axil_equiv__DOT__idx)]) 
                                        | (vlSelfRef.tb_axil_equiv__DOT__n_instr
                                           [(0x00001fffU 
                                             & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                           != vlSelfRef.tb_axil_equiv__DOT__a_instr
                                           [(0x00001fffU 
                                             & vlSelfRef.tb_axil_equiv__DOT__idx)])) 
                                       | (vlSelfRef.tb_axil_equiv__DOT__n_rd
                                          [(0x00001fffU 
                                            & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                          != vlSelfRef.tb_axil_equiv__DOT__a_rd
                                          [(0x00001fffU 
                                            & vlSelfRef.tb_axil_equiv__DOT__idx)])) 
                                      | (vlSelfRef.tb_axil_equiv__DOT__n_wdata
                                         [(0x00001fffU 
                                           & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                         != vlSelfRef.tb_axil_equiv__DOT__a_wdata
                                         [(0x00001fffU 
                                           & vlSelfRef.tb_axil_equiv__DOT__idx)])) 
                                     | (vlSelfRef.tb_axil_equiv__DOT__n_mstatus
                                        [(0x00001fffU 
                                          & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                        != vlSelfRef.tb_axil_equiv__DOT__a_mstatus
                                        [(0x00001fffU 
                                          & vlSelfRef.tb_axil_equiv__DOT__idx)])) 
                                    | (vlSelfRef.tb_axil_equiv__DOT__n_mepc
                                       [(0x00001fffU 
                                         & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                       != vlSelfRef.tb_axil_equiv__DOT__a_mepc
                                       [(0x00001fffU 
                                         & vlSelfRef.tb_axil_equiv__DOT__idx)])) 
                                   | (vlSelfRef.tb_axil_equiv__DOT__n_mcause
                                      [(0x00001fffU 
                                        & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                      != vlSelfRef.tb_axil_equiv__DOT__a_mcause
                                      [(0x00001fffU 
                                        & vlSelfRef.tb_axil_equiv__DOT__idx)])) 
                                  | (vlSelfRef.tb_axil_equiv__DOT__n_mtval
                                     [(0x00001fffU 
                                       & vlSelfRef.tb_axil_equiv__DOT__idx)] 
                                     != vlSelfRef.tb_axil_equiv__DOT__a_mtval
                                     [(0x00001fffU 
                                       & vlSelfRef.tb_axil_equiv__DOT__idx)]))))) {
                    vlSelfRef.tb_axil_equiv__DOT__errors 
                        = ((IData)(1U) + vlSelfRef.tb_axil_equiv__DOT__errors);
                    VL_WRITEF_NX("FAIL wait=%0d idx=%0d\n  native pc=%08x instr=%08x rd=%0# wdata=%08x mstatus=%08x mepc=%08x mcause=%08x mtval=%08x\n  axi    pc=%08x instr=%08x rd=%0# wdata=%08x mstatus=%08x mepc=%08x mcause=%08x mtval=%08x\n",0,
                                 32,vlSelfRef.tb_axil_equiv__DOT__wait_states,
                                 32,vlSelfRef.tb_axil_equiv__DOT__idx,
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_pc
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_instr
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 5,vlSelfRef.tb_axil_equiv__DOT__n_rd
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_wdata
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_mstatus
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_mepc
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_mcause
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__n_mtval
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_pc
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_instr
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 5,vlSelfRef.tb_axil_equiv__DOT__a_rd
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_wdata
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_mstatus
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_mepc
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_mcause
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)],
                                 32,vlSelfRef.tb_axil_equiv__DOT__a_mtval
                                 [(0x00001fffU & vlSelfRef.tb_axil_equiv__DOT__idx)]);
                    vlSelfRef.tb_axil_equiv__DOT__idx 
                        = vlSelfRef.tb_axil_equiv__DOT__n_count;
                }
                vlSelfRef.tb_axil_equiv__DOT__idx = 
                    ((IData)(1U) + vlSelfRef.tb_axil_equiv__DOT__idx);
            }
            if (VL_UNLIKELY((vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__axi_err_q))) {
                vlSelfRef.tb_axil_equiv__DOT__errors 
                    = ((IData)(1U) + vlSelfRef.tb_axil_equiv__DOT__errors);
                VL_WRITEF_NX("FAIL wait=%0d: dbg_axi_err asserted\n",0,
                             32,vlSelfRef.tb_axil_equiv__DOT__wait_states);
            }
            VL_FCLOSE_I(vlSelfRef.tb_axil_equiv__DOT__n_fd); VL_FCLOSE_I(vlSelfRef.tb_axil_equiv__DOT__a_fd); if (
                                                                                (0U 
                                                                                == vlSelfRef.tb_axil_equiv__DOT__errors)) {
                VL_WRITEF_NX("PASS wait=%0d: native vs AXI commit trace matched %0d commits\n",0,
                             32,vlSelfRef.tb_axil_equiv__DOT__wait_states,
                             32,vlSelfRef.tb_axil_equiv__DOT__n_count);
                VL_FINISH_MT("tb_axil_equiv.v", 358, "");
            } else {
                VL_WRITEF_NX("[%0t] %%Fatal: tb_axil_equiv.v:360: Assertion failed in %Ntb_axil_equiv\n",0,
                             64,VL_TIME_UNITED_Q(1),
                             -9,vlSymsp->name());
                VL_STOP_MT("tb_axil_equiv.v", 360, "", false);
            }
        }
        if (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__ex_wb_valid_r) 
             & (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.u_core__DOT__ex_wb_illegal_r))) {
            vlSelfRef.tb_axil_equiv__DOT__n_done = 1U;
        }
        if (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__ex_wb_valid_r) 
             & (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.u_core__DOT__ex_wb_illegal_r))) {
            vlSelfRef.tb_axil_equiv__DOT__a_done = 1U;
        }
    } else {
        __Vdly__tb_axil_equiv__DOT__watchdog = 0U;
    }
    if (vlSelfRef.tb_axil_equiv__DOT__resetn) {
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid) 
             & (2U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)))) {
            __Vdly__tb_axil_equiv__DOT__a_d_rvalid = 0U;
        }
        if (((1U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state)) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_arready))) {
            __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy = 1U;
            __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q 
                = vlSelfRef.tb_axil_equiv__DOT__wait_states;
            vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_addr_q 
                = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_addr;
        } else if (((IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy) 
                    & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid)))) {
            if ((0U != vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q)) {
                __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q 
                    = (vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q 
                       - (IData)(1U));
            } else {
                vlSelfRef.tb_axil_equiv__DOT__a_d_rdata 
                    = vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__memory
                    [(0x0007ffffU & (vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_addr_q 
                                     >> 2U))];
                __Vdly__tb_axil_equiv__DOT__a_d_rvalid = 1U;
                __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy = 0U;
            }
        }
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid) 
             & (2U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state)))) {
            __Vdly__tb_axil_equiv__DOT__a_i_rvalid = 0U;
        }
        if (((1U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state)) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_arready))) {
            __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy = 1U;
            __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q 
                = vlSelfRef.tb_axil_equiv__DOT__wait_states;
            vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_addr_q 
                = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_araddr;
        } else if (((IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy) 
                    & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid)))) {
            if ((0U != vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q)) {
                __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q 
                    = (vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q 
                       - (IData)(1U));
            } else {
                vlSelfRef.tb_axil_equiv__DOT__a_i_rdata 
                    = vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__memory
                    [(0x0007ffffU & (vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_addr_q 
                                     >> 2U))];
                __Vdly__tb_axil_equiv__DOT__a_i_rvalid = 1U;
                __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy = 0U;
            }
        }
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awvalid) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awready))) {
            vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_addr_q 
                = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_addr;
        }
        if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wvalid) 
             & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wready))) {
            vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_strb_q 
                = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wstrb;
            vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_data_q 
                = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wdata;
        }
        if ((2U & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state))) {
            if ((1U & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state))) {
                if (((((IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done) 
                       | ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awvalid) 
                          & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awready))) 
                      & ((IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done) 
                         | ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wvalid) 
                            & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wready)))) 
                     & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid))) {
                    __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state = 0U;
                }
                if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awvalid) 
                     & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_awready))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done = 1U;
                }
                if (((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wvalid) 
                     & (IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_wready))) {
                    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done = 1U;
                }
            } else if (vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid) {
                __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state = 0U;
            }
        } else if ((1U & (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state))) {
            if (vlSelfRef.tb_axil_equiv__DOT__a_d_arready) {
                __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state = 2U;
            }
        } else if (vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_req) {
            if (vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy) {
                vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_addr 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_addr_q;
                vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wdata 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_wdata_q;
            } else {
                vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_addr 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__u_core__DOT__ex_mem_alu_result_r;
                vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wdata 
                    = vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__u_core__DOT__ex_mem_store_wdata_r;
            }
            vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wstrb 
                = vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb;
            vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done = 0U;
            vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done = 0U;
            __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state 
                = ((0U != (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb))
                    ? 3U : 1U);
        }
        if ((0U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state))) {
            if (vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__ibus_req) {
                vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_araddr 
                    = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__primed)
                        ? ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_busy)
                            ? vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_addr_q
                            : vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__core_i_mem_addr)
                        : 0U);
                __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = 1U;
            }
        } else if ((1U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state))) {
            if (vlSelfRef.tb_axil_equiv__DOT__a_i_arready) {
                __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = 2U;
            }
        } else if ((2U == (IData)(vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state))) {
            if (vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid) {
                __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = 0U;
            }
        } else {
            __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = 0U;
        }
    } else {
        __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy = 0U;
        __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q = 0U;
        __Vdly__tb_axil_equiv__DOT__a_d_rvalid = 0U;
        vlSelfRef.tb_axil_equiv__DOT__a_d_rdata = 0U;
        __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy = 0U;
        __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q = 0U;
        __Vdly__tb_axil_equiv__DOT__a_i_rvalid = 0U;
        vlSelfRef.tb_axil_equiv__DOT__a_i_rdata = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_addr_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_strb_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_data_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_addr_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_addr_q = 0U;
        __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done = 0U;
        __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state = 0U;
    }
    vlSelfRef.tb_axil_equiv__DOT__n_dbus_wdata = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                   ? vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wdata_q
                                                   : vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_store_wdata_r);
    vlSelfRef.tb_axil_equiv__DOT__unused_i_bvalid = __Vdly__tb_axil_equiv__DOT__unused_i_bvalid;
    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen 
        = __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen;
    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__w_seen 
        = __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__w_seen;
    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q 
        = __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q;
    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q 
        = __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q;
    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen 
        = __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen;
    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__w_seen 
        = __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__w_seen;
    vlSelfRef.tb_axil_equiv__DOT__watchdog = __Vdly__tb_axil_equiv__DOT__watchdog;
    if (__VdlySet__tb_axil_equiv__DOT__native_mem__v0) {
        vlSelfRef.tb_axil_equiv__DOT__native_mem[__VdlyDim0__tb_axil_equiv__DOT__native_mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_axil_equiv__DOT__native_mem
                [__VdlyDim0__tb_axil_equiv__DOT__native_mem__v0]) 
               | (IData)(__VdlyVal__tb_axil_equiv__DOT__native_mem__v0));
    }
    if (__VdlySet__tb_axil_equiv__DOT__native_mem__v1) {
        vlSelfRef.tb_axil_equiv__DOT__native_mem[__VdlyDim0__tb_axil_equiv__DOT__native_mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_axil_equiv__DOT__native_mem
                [__VdlyDim0__tb_axil_equiv__DOT__native_mem__v1]) 
               | ((IData)(__VdlyVal__tb_axil_equiv__DOT__native_mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_axil_equiv__DOT__native_mem__v2) {
        vlSelfRef.tb_axil_equiv__DOT__native_mem[__VdlyDim0__tb_axil_equiv__DOT__native_mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_axil_equiv__DOT__native_mem
                [__VdlyDim0__tb_axil_equiv__DOT__native_mem__v2]) 
               | ((IData)(__VdlyVal__tb_axil_equiv__DOT__native_mem__v2) 
                  << 0x00000010U));
    }
    if (__VdlySet__tb_axil_equiv__DOT__native_mem__v3) {
        vlSelfRef.tb_axil_equiv__DOT__native_mem[__VdlyDim0__tb_axil_equiv__DOT__native_mem__v3] 
            = ((0x00ffffffU & vlSelfRef.tb_axil_equiv__DOT__native_mem
                [__VdlyDim0__tb_axil_equiv__DOT__native_mem__v3]) 
               | ((IData)(__VdlyVal__tb_axil_equiv__DOT__native_mem__v3) 
                  << 0x00000018U));
    }
    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q 
        = __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q;
    vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy 
        = __Vdly__tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy;
    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q 
        = __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q;
    vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy 
        = __Vdly__tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy;
    if ((1U & (~ (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn)))) {
        vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_strb_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_data_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__wr_addr_q = 0U;
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__axi_err_q = 0U;
    }
    vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid = __Vdly__tb_axil_equiv__DOT__a_d_rvalid;
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state 
        = __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state;
    vlSelfRef.tb_axil_equiv__DOT__a_d_bvalid = __Vdly__tb_axil_equiv__DOT__a_d_bvalid;
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state 
        = __Vdly__tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state;
    vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid = __Vdly__tb_axil_equiv__DOT__a_i_rvalid;
    vlSelfRef.tb_axil_equiv__DOT__a_d_arready = ((~ 
                                                  ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_d_rvalid) 
                                                   | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy))) 
                                                 & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
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
    vlSelfRef.tb_axil_equiv__DOT__a_i_arready = ((~ 
                                                  ((IData)(vlSelfRef.tb_axil_equiv__DOT__a_i_rvalid) 
                                                   | (IData)(vlSelfRef.tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy))) 
                                                 & (IData)(vlSelfRef.tb_axil_equiv__DOT__resetn));
}

void Vtb_axil_equiv___024root___nba_sequent__TOP__1(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___nba_sequent__TOP__1\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_axil_equiv__DOT__n_didx = (0x0007ffffU 
                                            & (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                 ? vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_addr_q
                                                 : vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                                               >> 2U));
    vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                   ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wstrb_q)
                                                   : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__core_d_mem_wstrb));
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb 
        = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy)
            ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_wstrb_q)
            : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__core_d_mem_wstrb));
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_req 
        = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_fire) 
           | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy));
    vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__ibus_req 
        = (1U & ((~ (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__primed)) 
                 | ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_fire) 
                    | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_busy))));
}

void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__0(Vtb_axil_equiv_cpu_m1_top* vlSelf);
void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0(Vtb_axil_equiv_cpu_m1_top* vlSelf);
void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__1(Vtb_axil_equiv_cpu_m1_top* vlSelf);
void Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1(Vtb_axil_equiv_cpu_m1_top* vlSelf);

void Vtb_axil_equiv___024root___eval_nba(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_nba\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__0((&vlSymsp->TOP__tb_axil_equiv__DOT__u_native));
        Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__0((&vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu));
        Vtb_axil_equiv___024root___nba_sequent__TOP__0(vlSelf);
        Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_native__1((&vlSymsp->TOP__tb_axil_equiv__DOT__u_native));
        Vtb_axil_equiv_cpu_m1_top___nba_sequent__TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu__1((&vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu));
        vlSelfRef.tb_axil_equiv__DOT__n_didx = (0x0007ffffU 
                                                & (((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                                                     ? vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_addr_q
                                                     : vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__u_core__DOT__ex_mem_alu_result_r) 
                                                   >> 2U));
        vlSelfRef.tb_axil_equiv__DOT__n_dbus_wstrb 
            = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_busy)
                ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__d_wstrb_q)
                : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_native.__PVT__core_d_mem_wstrb));
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb 
            = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy)
                ? (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_wstrb_q)
                : (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__core_d_mem_wstrb));
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__dbus_req 
            = ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_fire) 
               | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__d_busy));
        vlSelfRef.tb_axil_equiv__DOT__u_axi__DOT__ibus_req 
            = (1U & ((~ (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__primed)) 
                     | ((IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_fire) 
                        | (IData)(vlSymsp->TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__PVT__i_busy))));
    }
}

void Vtb_axil_equiv___024root___timing_ready(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___timing_ready\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h411bf940__0.ready("@(posedge tb_axil_equiv.clk)");
    }
}

void Vtb_axil_equiv___024root___timing_resume(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___timing_resume\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h411bf940__0.moveToResumeQueue(
                                                          "@(posedge tb_axil_equiv.clk)");
    vlSelfRef.__VtrigSched_h411bf940__0.resume("@(posedge tb_axil_equiv.clk)");
    if ((2ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vtb_axil_equiv___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_axil_equiv___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vtb_axil_equiv___024root___eval_phase__act(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_phase__act\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    Vtb_axil_equiv___024root___eval_triggers_vec__act(vlSelf);
    Vtb_axil_equiv___024root___timing_ready(vlSelf);
    Vtb_axil_equiv___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_axil_equiv___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vtb_axil_equiv___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vtb_axil_equiv___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vtb_axil_equiv___024root___timing_resume(vlSelf);
        Vtb_axil_equiv___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtb_axil_equiv___024root___eval_phase__inact(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_phase__inact\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("tb_axil_equiv.v", 3, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vtb_axil_equiv___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtb_axil_equiv___024root___eval_phase__nba(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_phase__nba\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vtb_axil_equiv___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vtb_axil_equiv___024root___eval_nba(vlSelf);
        Vtb_axil_equiv___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vtb_axil_equiv___024root___eval(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtb_axil_equiv___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("tb_axil_equiv.v", 3, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("tb_axil_equiv.v", 3, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vtb_axil_equiv___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("tb_axil_equiv.v", 3, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vtb_axil_equiv___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vtb_axil_equiv___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vtb_axil_equiv___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vtb_axil_equiv___024root____VbeforeTrig_h411bf940__0(Vtb_axil_equiv___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root____VbeforeTrig_h411bf940__0\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.tb_axil_equiv__DOT__clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0 
        = vlSelfRef.tb_axil_equiv__DOT__clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h411bf940__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vtb_axil_equiv___024root___eval_debug_assertions(Vtb_axil_equiv___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_axil_equiv___024root___eval_debug_assertions\n"); );
    Vtb_axil_equiv__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
