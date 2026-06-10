.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   s0, 0x10000000
    la   t0, mtvec_handler
    csrrw t1, mtvec, t0

    li   t0, 0x12345678
    csrrw t1, mscratch, t0
    sw   t1, 0(s0)
    li   t0, 0x0000000f
    csrrs t1, mscratch, t0
    sw   t1, 4(s0)
    li   t0, 0x00000008
    csrrc t1, mscratch, t0
    sw   t1, 8(s0)

    li   t0, 0x44
    csrrw zero, mepc, t0
    li   t0, 0x55
    csrrw zero, mcause, t0

    li   t0, (1 << 11)
    csrrs zero, mie, t0
    li   t0, (1 << 3)
    csrrs zero, mstatus, t0

    j    irq_target

    .org 0x80
.option push
.option rvc
.global irq_target
irq_target:
    c.addi s1, 1
after_irq:
    c.li   s2, 2
.option pop

    li   t1, 0x600d
    sw   t1, 28(s0)
done:
    ebreak

    .balign 4
    .org 0x100
.option push
.option norvc
.global mtvec_handler
mtvec_handler:
    csrr t1, mepc
    sw   t1, 16(s0)
    csrr t1, mcause
    sw   t1, 20(s0)
    csrr t1, mstatus
    sw   t1, 24(s0)
    mret
.option pop
