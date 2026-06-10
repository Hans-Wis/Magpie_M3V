.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    la   t0, mtvec_handler
    csrw mtvec, t0

    li   t0, (1 << 11)
    csrs mie, t0
    li   t0, (1 << 3)
    csrs mstatus, t0

    addi s2, zero, 3
    addi s3, s2, 4

    j    irq_target

    .org 0x80
.option push
.option rvc
.global irq_target
irq_target:
    c.addi s0, 1
after_irq:
    c.li   s1, 2
.option pop

    li   t0, 0x10000000
    li   t1, 0x0000600d
    sw   t1, 12(t0)
done:
    ebreak

    .balign 4
    .org 0x100
.global mtvec_handler
mtvec_handler:
    li   t0, 0x10000000
    csrr t1, mepc
    sw   t1, 0(t0)
    csrr t1, mcause
    sw   t1, 4(t0)
    csrr t1, mstatus
    sw   t1, 8(t0)
    mret
