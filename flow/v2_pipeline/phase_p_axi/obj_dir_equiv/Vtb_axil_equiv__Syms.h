// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_AXIL_EQUIV__SYMS_H_
#define VERILATED_VTB_AXIL_EQUIV__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_axil_equiv.h"

// INCLUDE MODULE CLASSES
#include "Vtb_axil_equiv___024root.h"
#include "Vtb_axil_equiv_cpu_m1_top.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vtb_axil_equiv__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_axil_equiv* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_axil_equiv___024root       TOP;
    Vtb_axil_equiv_cpu_m1_top      TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu;
    Vtb_axil_equiv_cpu_m1_top      TOP__tb_axil_equiv__DOT__u_native;

    // CONSTRUCTORS
    Vtb_axil_equiv__Syms(VerilatedContext* contextp, const char* namep, Vtb_axil_equiv* modelp);
    ~Vtb_axil_equiv__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
