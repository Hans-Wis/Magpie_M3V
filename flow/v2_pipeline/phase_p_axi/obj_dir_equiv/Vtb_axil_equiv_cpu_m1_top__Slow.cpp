// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_axil_equiv.h for the primary calling header

#include "Vtb_axil_equiv__pch.h"

void Vtb_axil_equiv_cpu_m1_top___ctor_var_reset(Vtb_axil_equiv_cpu_m1_top* vlSelf);

Vtb_axil_equiv_cpu_m1_top::Vtb_axil_equiv_cpu_m1_top() = default;
Vtb_axil_equiv_cpu_m1_top::~Vtb_axil_equiv_cpu_m1_top() = default;

void Vtb_axil_equiv_cpu_m1_top::ctor(Vtb_axil_equiv__Syms* symsp, const char* namep) {
    vlSymsp = symsp;
    vlNamep = strdup(Verilated::catName(vlSymsp->name(), namep));
    // Reset structure values
    Vtb_axil_equiv_cpu_m1_top___ctor_var_reset(this);
}

void Vtb_axil_equiv_cpu_m1_top::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

void Vtb_axil_equiv_cpu_m1_top::dtor() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
