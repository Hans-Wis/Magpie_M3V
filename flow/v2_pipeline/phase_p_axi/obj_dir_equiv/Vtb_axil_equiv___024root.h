// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_axil_equiv.h for the primary calling header

#ifndef VERILATED_VTB_AXIL_EQUIV___024ROOT_H_
#define VERILATED_VTB_AXIL_EQUIV___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"
class Vtb_axil_equiv_cpu_m1_top;


class Vtb_axil_equiv__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_axil_equiv___024root final {
  public:
    // CELLS
    Vtb_axil_equiv_cpu_m1_top* __PVT__tb_axil_equiv__DOT__u_native;
    Vtb_axil_equiv_cpu_m1_top* __PVT__tb_axil_equiv__DOT__u_axi__DOT__u_cpu;

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ tb_axil_equiv__DOT__clk;
        CData/*0:0*/ tb_axil_equiv__DOT__resetn;
        CData/*3:0*/ tb_axil_equiv__DOT__n_dbus_wstrb;
        CData/*0:0*/ tb_axil_equiv__DOT__a_i_arready;
        CData/*0:0*/ tb_axil_equiv__DOT__a_i_rvalid;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_arready;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_rvalid;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_awvalid;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_awready;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_wvalid;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_wready;
        CData/*0:0*/ tb_axil_equiv__DOT__a_d_bvalid;
        CData/*0:0*/ tb_axil_equiv__DOT__unused_i_bvalid;
        CData/*0:0*/ tb_axil_equiv__DOT__n_done;
        CData/*0:0*/ tb_axil_equiv__DOT__a_done;
        CData/*0:0*/ tb_axil_equiv__DOT__u_axi__DOT__ibus_req;
        CData/*0:0*/ tb_axil_equiv__DOT__u_axi__DOT__dbus_req;
        CData/*3:0*/ tb_axil_equiv__DOT__u_axi__DOT__dbus_wstrb;
        CData/*1:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_state;
        CData/*1:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_state;
        CData/*3:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wstrb;
        CData/*0:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_aw_done;
        CData/*0:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_w_done;
        CData/*0:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__axi_err_q;
        CData/*0:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__rd_busy;
        CData/*0:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__aw_seen;
        CData/*0:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__w_seen;
        CData/*3:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__wr_strb_q;
        CData/*0:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__rd_busy;
        CData/*0:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__aw_seen;
        CData/*0:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__w_seen;
        CData/*3:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__wr_strb_q;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __VstlPhaseResult;
        CData/*0:0*/ __Vtrigprevexpr___TOP__tb_axil_equiv__DOT__clk__0;
        CData/*0:0*/ __VactPhaseResult;
        CData/*0:0*/ __VinactPhaseResult;
        CData/*0:0*/ __VnbaPhaseResult;
        SData/*15:0*/ tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__half0;
        SData/*15:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__half0;
        VlWide<32>/*1023:0*/ tb_axil_equiv__DOT__firmware_hex;
        VlWide<32>/*1023:0*/ tb_axil_equiv__DOT__native_trace_path;
        VlWide<32>/*1023:0*/ tb_axil_equiv__DOT__axi_trace_path;
        IData/*31:0*/ tb_axil_equiv__DOT__wait_states;
        IData/*31:0*/ tb_axil_equiv__DOT__max_cycles;
        IData/*31:0*/ tb_axil_equiv__DOT__n_fd;
        IData/*31:0*/ tb_axil_equiv__DOT__a_fd;
        IData/*31:0*/ tb_axil_equiv__DOT__watchdog;
        IData/*31:0*/ tb_axil_equiv__DOT__errors;
        IData/*31:0*/ tb_axil_equiv__DOT__idx;
        IData/*31:0*/ tb_axil_equiv__DOT__n_dbus_wdata;
        IData/*18:0*/ tb_axil_equiv__DOT__n_didx;
        IData/*31:0*/ tb_axil_equiv__DOT__a_i_rdata;
        IData/*31:0*/ tb_axil_equiv__DOT__a_d_rdata;
        IData/*31:0*/ tb_axil_equiv__DOT__n_count;
        IData/*31:0*/ tb_axil_equiv__DOT__a_count;
        IData/*18:0*/ tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word_idx;
        IData/*31:0*/ tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word0;
        IData/*31:0*/ tb_axil_equiv__DOT__native_instr_at_pc__Vstatic__word1;
        IData/*31:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__i_araddr;
        IData/*31:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_addr;
        IData/*31:0*/ tb_axil_equiv__DOT__u_axi__DOT__u_axil__DOT__d_wdata;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__rd_addr_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__rd_wait_q;
    };
    struct {
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__wr_addr_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__wr_data_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__wr_wait_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__offset;
        IData/*18:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__idx;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word0;
        IData/*31:0*/ tb_axil_equiv__DOT__u_i_mem__DOT__instr_at_pc__Vstatic__word1;
        IData/*31:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__rd_addr_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__rd_wait_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__wr_addr_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__wr_data_q;
        IData/*31:0*/ tb_axil_equiv__DOT__u_d_mem__DOT__wr_wait_q;
        IData/*31:0*/ __VactIterCount;
        IData/*31:0*/ __VinactIterCount;
        IData/*31:0*/ __Vi;
        VlUnpacked<IData/*31:0*/, 524288> tb_axil_equiv__DOT__native_mem;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_pc;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_instr;
        VlUnpacked<CData/*4:0*/, 8192> tb_axil_equiv__DOT__n_rd;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_wdata;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_mstatus;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_mepc;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_mcause;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__n_mtval;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_pc;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_instr;
        VlUnpacked<CData/*4:0*/, 8192> tb_axil_equiv__DOT__a_rd;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_wdata;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_mstatus;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_mepc;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_mcause;
        VlUnpacked<IData/*31:0*/, 8192> tb_axil_equiv__DOT__a_mtval;
        VlUnpacked<IData/*31:0*/, 524288> tb_axil_equiv__DOT__u_i_mem__DOT__memory;
        VlUnpacked<IData/*31:0*/, 524288> tb_axil_equiv__DOT__u_d_mem__DOT__memory;
        VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
        VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
        VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
        VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    };
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h411bf940__0;

    // INTERNAL VARIABLES
    Vtb_axil_equiv__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_axil_equiv___024root(Vtb_axil_equiv__Syms* symsp, const char* namep);
    ~Vtb_axil_equiv___024root();
    VL_UNCOPYABLE(Vtb_axil_equiv___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
