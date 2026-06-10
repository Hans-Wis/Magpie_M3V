// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_archtest.h for the primary calling header

#include "Vtb_axil_archtest__pch.h"

void Vtb_axil_archtest___024root___ctor_var_reset(Vtb_axil_archtest___024root* vlSelf);

Vtb_axil_archtest___024root::Vtb_axil_archtest___024root(Vtb_axil_archtest__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vtb_axil_archtest___024root___ctor_var_reset(this);
}

void Vtb_axil_archtest___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vtb_axil_archtest___024root::~Vtb_axil_archtest___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
