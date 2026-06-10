// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_axil_equiv.h for the primary calling header

#ifndef VERILATED_VTB_AXIL_EQUIV_CPU_M1_TOP_H_
#define VERILATED_VTB_AXIL_EQUIV_CPU_M1_TOP_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb_axil_equiv__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_axil_equiv_cpu_m1_top final {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ clk;
        CData/*0:0*/ resetn;
        CData/*0:0*/ trap;
        CData/*0:0*/ ibus_req;
        CData/*0:0*/ ibus_ready;
        CData/*0:0*/ dbus_req;
        CData/*0:0*/ dbus_we;
        CData/*3:0*/ dbus_wstrb;
        CData/*0:0*/ dbus_ready;
        CData/*0:0*/ irq_external_pulse;
        CData/*2:0*/ dbg_state;
        CData/*3:0*/ __PVT__core_d_mem_wstrb;
        CData/*0:0*/ __PVT__i_busy;
        CData/*0:0*/ __PVT__d_busy;
        CData/*3:0*/ __PVT__d_wstrb_q;
        CData/*0:0*/ __PVT__primed;
        CData/*0:0*/ __PVT__mem_stall;
        CData/*0:0*/ __PVT__i_boot;
        CData/*0:0*/ __PVT__i_fire;
        CData/*0:0*/ __PVT__d_fire;
        CData/*0:0*/ __PVT__d_xfer;
        CData/*0:0*/ __PVT__u_core__DOT__warmup;
        CData/*0:0*/ __PVT__u_core__DOT__pc_redirect;
        CData/*0:0*/ __PVT__u_core__DOT__stall;
        CData/*0:0*/ __PVT__u_core__DOT__redirect_warmup;
        CData/*0:0*/ __PVT__u_core__DOT__bp_predict_taken;
        CData/*0:0*/ __PVT__u_core__DOT__bp_upd_valid;
        CData/*0:0*/ __PVT__u_core__DOT__ras_push;
        CData/*0:0*/ __PVT__u_core__DOT__ras_pop;
        CData/*0:0*/ __PVT__u_core__DOT__cross_assemble;
        CData/*0:0*/ __PVT__u_core__DOT__at_cross_boundary;
        CData/*0:0*/ __PVT__u_core__DOT__upcoming_cross;
        CData/*0:0*/ __PVT__u_core__DOT__consecutive_cross;
        CData/*0:0*/ __PVT__u_core__DOT__is_16bit_w;
        CData/*0:0*/ __PVT__u_core__DOT__any_stall;
        CData/*0:0*/ __PVT__u_core__DOT__cdec_illegal;
        CData/*0:0*/ __PVT__u_core__DOT__if_ex_valid;
        CData/*0:0*/ __PVT__u_core__DOT__if_ex_pred_taken;
        CData/*0:0*/ __PVT__u_core__DOT__if_ex_pred_ras;
        CData/*0:0*/ __PVT__u_core__DOT__if_ex_is_16bit;
        CData/*2:0*/ __PVT__u_core__DOT__id_wb_sel;
        CData/*0:0*/ __PVT__u_core__DOT__id_is_jalr;
        CData/*0:0*/ __PVT__u_core__DOT__id_is_csr;
        CData/*0:0*/ u_core__DOT__rfu_we;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_valid_r;
        CData/*4:0*/ __PVT__u_core__DOT__ex_mem_rd_idx_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_rd_we_r;
        CData/*2:0*/ __PVT__u_core__DOT__ex_mem_wb_sel_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_load_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_store_r;
        CData/*2:0*/ __PVT__u_core__DOT__ex_mem_ls_funct3_r;
        CData/*1:0*/ __PVT__u_core__DOT__ex_mem_addr_lo_r;
        CData/*3:0*/ __PVT__u_core__DOT__ex_mem_store_wstrb_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_mret_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_misaligned_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_misaligned_store_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_csr_we_r;
        CData/*1:0*/ __PVT__u_core__DOT__ex_mem_csr_op_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_branch_taken_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_jal_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_jalr_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_illegal_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_ecall_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_is_ebreak_r;
    };
    struct {
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_mispredict_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_bp_upd_valid_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_bp_upd_taken_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_pred_ras_r;
        CData/*0:0*/ __PVT__u_core__DOT__id_advance_to_ex_mem;
        CData/*0:0*/ __PVT__u_core__DOT__branch_taken;
        CData/*0:0*/ __PVT__u_core__DOT__ex_bp_upd_taken;
        CData/*0:0*/ __PVT__u_core__DOT__mul_done;
        CData/*0:0*/ __PVT__u_core__DOT__div_done;
        CData/*0:0*/ __PVT__u_core__DOT__md_started;
        CData/*0:0*/ __PVT__u_core__DOT__md_active_is_div;
        CData/*0:0*/ __PVT__u_core__DOT__md_result_valid;
        CData/*0:0*/ __PVT__u_core__DOT__md_done;
        CData/*0:0*/ __PVT__u_core__DOT__md_start;
        CData/*1:0*/ __PVT__u_core__DOT__store_addr_lo;
        CData/*0:0*/ __PVT__u_core__DOT__wb_csr_we;
        CData/*0:0*/ __PVT__u_core__DOT__wb_trap_enter;
        CData/*0:0*/ __PVT__u_core__DOT__wb_trap_exit;
        CData/*0:0*/ u_core__DOT__wb_instr_retired;
        CData/*0:0*/ u_core__DOT__ex_wb_valid_r;
        CData/*4:0*/ __PVT__u_core__DOT__ex_wb_rd_idx_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_rd_we_r;
        CData/*2:0*/ __PVT__u_core__DOT__ex_wb_wb_sel_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_misaligned_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_misaligned_store_r;
        CData/*2:0*/ __PVT__u_core__DOT__ex_wb_ls_funct3_r;
        CData/*1:0*/ __PVT__u_core__DOT__ex_wb_addr_lo_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_mret_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_csr_we_r;
        CData/*1:0*/ __PVT__u_core__DOT__ex_wb_csr_op_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_branch_taken_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_jal_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_jalr_r;
        CData/*0:0*/ u_core__DOT__ex_wb_illegal_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_ecall_r;
        CData/*0:0*/ __PVT__u_core__DOT__ex_wb_is_ebreak_r;
        CData/*0:0*/ __PVT__u_core__DOT__mem_ras_mispredict;
        CData/*0:0*/ __PVT__u_core__DOT__wb_take_data_trap;
        CData/*0:0*/ __PVT__u_core__DOT__wb_take_sync_trap;
        CData/*0:0*/ __PVT__u_core__DOT__ex_mem_advance_to_wb;
        CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_9;
        CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_14;
        CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_15;
        CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_16;
        CData/*0:0*/ u_core__DOT____VdfgRegularize_hbfa0e40b_0_17;
        CData/*0:0*/ __PVT__u_core__DOT__u_bp__DOT__wr_way;
        CData/*1:0*/ __PVT__u_core__DOT__u_bp__DOT__cnt_next;
        CData/*2:0*/ __PVT__u_core__DOT__u_ras__DOT__ptr;
        CData/*2:0*/ __PVT__u_core__DOT__u_ras__DOT__top_idx;
        CData/*0:0*/ u_core__DOT__u_idu__DOT____VdfgRegularize_h48023c04_0_5;
        CData/*0:0*/ __PVT__u_core__DOT__u_mul__DOT__busy;
        CData/*0:0*/ __PVT__u_core__DOT__u_mul__DOT__done_pending;
        CData/*0:0*/ __PVT__u_core__DOT__u_mul__DOT__high_out;
        CData/*1:0*/ __PVT__u_core__DOT__u_div__DOT__state;
        CData/*5:0*/ __PVT__u_core__DOT__u_div__DOT__iter;
        CData/*0:0*/ __PVT__u_core__DOT__u_div__DOT__ret_rem;
        CData/*0:0*/ __PVT__u_core__DOT__u_div__DOT__sign_quot;
        CData/*0:0*/ __PVT__u_core__DOT__u_div__DOT__sign_rem;
        CData/*0:0*/ __PVT__u_core__DOT__u_div__DOT__div_by_zero;
        CData/*0:0*/ __PVT__u_core__DOT__u_div__DOT__overflow;
        CData/*0:0*/ __PVT__u_core__DOT__u_csr__DOT__mie_meie;
        CData/*0:0*/ __PVT__u_core__DOT__u_csr__DOT__mstatus_mie;
        CData/*0:0*/ __PVT__u_core__DOT__u_csr__DOT__mstatus_mpie;
        CData/*0:0*/ __PVT__u_core__DOT__u_csr__DOT__ext_pending;
    };
    struct {
        CData/*7:0*/ __PVT__u_core__DOT__u_lsu_wb__DOT__byte_sel;
        CData/*0:0*/ __Vdly__i_busy;
        CData/*0:0*/ __Vdly__d_busy;
        SData/*15:0*/ __PVT__u_core__DOT__residue;
        SData/*15:0*/ __PVT__u_core__DOT__cinstr;
        SData/*11:0*/ __PVT__u_core__DOT__ex_mem_csr_addr_r;
        SData/*11:0*/ __PVT__u_core__DOT__ex_wb_csr_addr_r;
        SData/*15:0*/ __PVT__u_core__DOT__u_lsu_wb__DOT__half_sel;
        IData/*31:0*/ ibus_addr;
        IData/*31:0*/ ibus_rdata;
        IData/*31:0*/ dbus_addr;
        IData/*31:0*/ dbus_wdata;
        IData/*31:0*/ dbus_rdata;
        IData/*31:0*/ dbg_pc;
        IData/*31:0*/ dbg_instr;
        IData/*31:0*/ __PVT__core_i_mem_addr;
        IData/*31:0*/ __PVT__i_addr_q;
        IData/*31:0*/ __PVT__i_rdata_q;
        IData/*31:0*/ __PVT__d_addr_q;
        IData/*31:0*/ __PVT__d_wdata_q;
        IData/*31:0*/ __PVT__d_rdata_q;
        IData/*31:0*/ __PVT__u_core__DOT__next_pc_w;
        IData/*31:0*/ __PVT__u_core__DOT__bp_predict_target;
        IData/*31:0*/ __PVT__u_core__DOT__ras_top;
        IData/*31:0*/ __PVT__u_core__DOT__ras_push_val;
        IData/*31:0*/ __PVT__u_core__DOT__cdec_expanded;
        IData/*31:0*/ __PVT__u_core__DOT__instr_assembled;
        IData/*31:0*/ __PVT__u_core__DOT__if_ex_instr;
        IData/*31:0*/ __PVT__u_core__DOT__if_ex_pc;
        IData/*31:0*/ __PVT__u_core__DOT__if_ex_pred_target;
        IData/*31:0*/ __PVT__u_core__DOT__if_ex_pred_ras_target;
        IData/*31:0*/ u_core__DOT__rfu_wr_data;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_pc_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_alu_result_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_md_result_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_pc_plus_4_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_pc_plus_imm_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_csr_rdata_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_store_wdata_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_csr_wdata_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_instr_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_bp_upd_pc_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_bp_upd_target_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_mem_pred_ras_target_r;
        IData/*31:0*/ __PVT__u_core__DOT__rs1_val;
        IData/*31:0*/ __PVT__u_core__DOT__rs2_val;
        IData/*31:0*/ __PVT__u_core__DOT__alu_result;
        IData/*31:0*/ __PVT__u_core__DOT__if_ex_pc_plus_imm;
        IData/*31:0*/ __PVT__u_core__DOT__mul_result;
        IData/*31:0*/ __PVT__u_core__DOT__div_result;
        IData/*31:0*/ __PVT__u_core__DOT__md_result_q;
        IData/*31:0*/ __PVT__u_core__DOT__id_csr_wdata;
        IData/*31:0*/ __PVT__u_core__DOT__id_csr_rdata;
        IData/*31:0*/ u_core__DOT__ex_wb_pc_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_alu_result_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_md_result_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_pc_plus_4_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_pc_plus_imm_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_csr_rdata_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_csr_wdata_r;
        IData/*31:0*/ __PVT__u_core__DOT__ex_wb_instr_r;
        IData/*31:0*/ __PVT__u_core__DOT__u_ifu__DOT__pc_reg;
        VlWide<3>/*65:0*/ __PVT__u_core__DOT__u_mul__DOT__product_w;
        IData/*31:0*/ __PVT__u_core__DOT__u_div__DOT__dividend;
    };
    struct {
        IData/*31:0*/ __PVT__u_core__DOT__u_div__DOT__divisor;
        IData/*31:0*/ __PVT__u_core__DOT__u_div__DOT__quotient;
        IData/*31:0*/ __PVT__u_core__DOT__u_div__DOT__remainder;
        IData/*31:0*/ __PVT__u_core__DOT__u_div__DOT__orig_a;
        IData/*29:0*/ __PVT__u_core__DOT__u_csr__DOT__mtvec_base;
        IData/*31:0*/ __PVT__u_core__DOT__u_csr__DOT__mscratch;
        IData/*31:0*/ u_core__DOT__u_csr__DOT__mepc_reg;
        IData/*31:0*/ u_core__DOT__u_csr__DOT__mcause_reg;
        IData/*31:0*/ u_core__DOT__u_csr__DOT__mtval_reg;
        IData/*31:0*/ __PVT__u_core__DOT__u_csr__DOT__new_val;
        IData/*31:0*/ u_core__DOT__u_csr__DOT__mstatus_val;
        QData/*32:0*/ __PVT__u_core__DOT__u_mul__DOT__opa_r;
        QData/*32:0*/ __PVT__u_core__DOT__u_mul__DOT__opb_r;
        QData/*32:0*/ __PVT__u_core__DOT__u_div__DOT__shifted_rem;
        QData/*32:0*/ __PVT__u_core__DOT__u_div__DOT__sub_w;
        QData/*63:0*/ __PVT__u_core__DOT__u_csr__DOT__cycle_cnt;
        QData/*63:0*/ __PVT__u_core__DOT__u_csr__DOT__instret_cnt;
        VlUnpacked<CData/*0:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__valid0;
        VlUnpacked<IData/*25:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__tag0;
        VlUnpacked<IData/*31:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__target0;
        VlUnpacked<CData/*1:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__counter0;
        VlUnpacked<CData/*0:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__valid1;
        VlUnpacked<IData/*25:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__tag1;
        VlUnpacked<IData/*31:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__target1;
        VlUnpacked<CData/*1:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__counter1;
        VlUnpacked<CData/*0:0*/, 32> __PVT__u_core__DOT__u_bp__DOT__lru;
        VlUnpacked<IData/*31:0*/, 8> __PVT__u_core__DOT__u_ras__DOT__stack;
        VlUnpacked<IData/*31:0*/, 32> __PVT__u_core__DOT__u_rfu__DOT__regs;
    };

    // INTERNAL VARIABLES
    Vtb_axil_equiv__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_axil_equiv_cpu_m1_top();
    ~Vtb_axil_equiv_cpu_m1_top();
    void ctor(Vtb_axil_equiv__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(Vtb_axil_equiv_cpu_m1_top);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
