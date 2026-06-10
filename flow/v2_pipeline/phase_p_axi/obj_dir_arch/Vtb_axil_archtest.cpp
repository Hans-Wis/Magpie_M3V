// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtb_axil_archtest__pch.h"

//============================================================
// Constructors

Vtb_axil_archtest::Vtb_axil_archtest(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtb_axil_archtest__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtb_axil_archtest::Vtb_axil_archtest(const char* _vcname__)
    : Vtb_axil_archtest(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtb_axil_archtest::~Vtb_axil_archtest() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtb_axil_archtest___024root___eval_debug_assertions(Vtb_axil_archtest___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_axil_archtest___024root___eval_static(Vtb_axil_archtest___024root* vlSelf);
void Vtb_axil_archtest___024root___eval_initial(Vtb_axil_archtest___024root* vlSelf);
void Vtb_axil_archtest___024root___eval_settle(Vtb_axil_archtest___024root* vlSelf);
void Vtb_axil_archtest___024root___eval(Vtb_axil_archtest___024root* vlSelf);

void Vtb_axil_archtest::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtb_axil_archtest::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtb_axil_archtest___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtb_axil_archtest___024root___eval_static(&(vlSymsp->TOP));
        Vtb_axil_archtest___024root___eval_initial(&(vlSymsp->TOP));
        Vtb_axil_archtest___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtb_axil_archtest___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtb_axil_archtest::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t Vtb_axil_archtest::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtb_axil_archtest::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtb_axil_archtest___024root___eval_final(Vtb_axil_archtest___024root* vlSelf);

VL_ATTR_COLD void Vtb_axil_archtest::final() {
    Vtb_axil_archtest___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtb_axil_archtest::hierName() const { return vlSymsp->name(); }
const char* Vtb_axil_archtest::modelName() const { return "Vtb_axil_archtest"; }
unsigned Vtb_axil_archtest::threads() const { return 1; }
void Vtb_axil_archtest::prepareClone() const { contextp()->prepareClone(); }
void Vtb_axil_archtest::atClone() const {
    contextp()->threadPoolpOnClone();
}
