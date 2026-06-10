// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtb_axil_equiv__pch.h"

Vtb_axil_equiv__Syms::Vtb_axil_equiv__Syms(VerilatedContext* contextp, const char* namep, Vtb_axil_equiv* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup top module instance
    , TOP{this, namep}
{
    // Check resources
    Verilated::stackCheck(2041);
    // Setup sub module instances
    TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.ctor(this, "tb_axil_equiv.u_axi.u_cpu");
    TOP__tb_axil_equiv__DOT__u_native.ctor(this, "tb_axil_equiv.u_native");
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-9);
    // Setup each module's pointers to their submodules
    TOP.__PVT__tb_axil_equiv__DOT__u_axi__DOT__u_cpu = &TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu;
    TOP.__PVT__tb_axil_equiv__DOT__u_native = &TOP__tb_axil_equiv__DOT__u_native;
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.__Vconfigure(true);
    TOP__tb_axil_equiv__DOT__u_native.__Vconfigure(false);
    // Setup scopes
}

Vtb_axil_equiv__Syms::~Vtb_axil_equiv__Syms() {
    // Tear down scopes
    // Tear down sub module instances
    TOP__tb_axil_equiv__DOT__u_native.dtor();
    TOP__tb_axil_equiv__DOT__u_axi__DOT__u_cpu.dtor();
}
