.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   t0, 0x12345678
    csrrw t1, mscratch, t0
    li   t0, 0x0000000f
    csrrs t1, mscratch, t0
    li   t0, 0x00000008
    csrrc t1, mscratch, t0

    la   t0, trap_vector
    csrrw zero, mtvec, t0
    li   t0, (1 << 11)
    csrrs zero, mie, t0
    csrrc zero, mie, t0
    li   t0, (1 << 3)
    csrrs zero, mstatus, t0
    csrrc zero, mstatus, t0
    li   t0, 0x40
    csrrw zero, mepc, t0
    li   t0, 0x55
    csrrw zero, mcause, t0

    ebreak

trap_vector:
    mret
