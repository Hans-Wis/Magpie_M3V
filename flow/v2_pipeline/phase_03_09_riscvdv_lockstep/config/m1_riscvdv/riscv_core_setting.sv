// cpu_m1 riscv-dv target setting for Phase 3.9/J8.
// Used as provenance for the pyflow-generated RV32IMC machine-mode stream.

parameter int XLEN = 32;

parameter satp_mode_t SATP_MODE = BARE;

privileged_mode_t supported_privileged_mode[] = {MACHINE_MODE};

riscv_instr_group_t supported_isa[$] = {RV32I, RV32M, RV32C};

riscv_instr_name_t unsupported_instr[] = {
    WFI,
    FENCE,
    FENCE_I,
    ECALL,
    EBREAK
};

mtvec_mode_t supported_interrupt_mode[$] = {DIRECT};

int max_interrupt_vector_num = 1;

bit support_pmp = 0;
bit support_epmp = 0;
bit support_debug_mode = 0;
bit support_umode_trap = 0;
bit support_sfence = 0;
bit support_unaligned_load_store = 0;

parameter int NUM_FLOAT_GPR = 32;
parameter int NUM_GPR = 32;
parameter int NUM_VEC_GPR = 32;

parameter int VECTOR_EXTENSION_ENABLE = 0;
parameter int VLEN = 512;
parameter int ELEN = 32;
parameter int SELEN = 8;
parameter int VELEN = 2;
parameter int MAX_LMUL = 8;

parameter int NUM_HARTS = 1;

const privileged_reg_t implemented_csr[] = {
    MSTATUS,
    MIE,
    MTVEC,
    MSCRATCH,
    MEPC,
    MCAUSE,
    MIP,
    CYCLE,
    CYCLEH,
    INSTRET,
    INSTRETH
};

bit [11:0] custom_csr[] = {};

const interrupt_cause_t implemented_interrupt[] = {
    M_EXTERNAL_INTR
};

const exception_cause_t implemented_exception[] = {
    ILLEGAL_INSTRUCTION,
    BREAKPOINT,
    ECALL_MMODE,
    LOAD_ADDRESS_MISALIGNED,
    STORE_AMO_ADDRESS_MISALIGNED
};
