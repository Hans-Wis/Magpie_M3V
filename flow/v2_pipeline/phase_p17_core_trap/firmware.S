.section .init
.global _start

_start:
.option push
.option norvc
    la   t0, p17_suite
    jalr zero, 0(t0)

    .org 0x00300000
.global p17_suite
p17_suite:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    la   t0, trap_handler
    csrw mtvec, t0
    la   s0, data_area

    addi s1, zero, 1

.global p17_ecall
p17_ecall:
    ecall
    addi s1, s1, 1

.global p17_ebreak32
p17_ebreak32:
    ebreak
    addi s1, s1, 1

.global p17_illegal32
p17_illegal32:
    .word 0xffffffff
    addi s1, s1, 1

.option pop
.option push
.option rvc
    c.nop
.global p17_c_ebreak_odd
p17_c_ebreak_odd:
    c.ebreak
.option pop
.option push
.option norvc
    addi s1, s1, 1

.global p17_lw_misalign
p17_lw_misalign:
    lw   t1, 1(s0)
    addi s1, s1, 1

.global p17_sw_misalign
p17_sw_misalign:
    sw   t1, 2(s0)
    addi s1, s1, 1

    li   t0, (1 << 11)
    csrs mie, t0
    li   t0, (1 << 3)
    csrs mstatus, t0

.global p17_irq_alu
p17_irq_alu:
    addi s2, s1, 7
    addi s3, s2, 9

.global p17_irq_loaduse
p17_irq_loaduse:
    lw   s4, 0(s0)
    add  s5, s4, s3
    addi s6, s5, 3

    csrc mstatus, t0
    csrc mie, t0

    li   t2, 0x600d
.global p17_done_store
p17_done_store:
    sw   t2, 28(s0)

p17_done_loop:
    jal  zero, p17_done_loop

    .balign 4
.global trap_handler
trap_handler:
    csrr t3, mcause
    csrr t4, mepc
    csrr t5, mtval

    bltz t3, p17_irq_return

    la   t6, p17_c_ebreak_odd
    beq  t4, t6, p17_advance_2
    addi t4, t4, 4
    jal  zero, p17_write_mepc

p17_advance_2:
    addi t4, t4, 2

p17_write_mepc:
    csrw mepc, t4

p17_irq_return:
    mret
.option pop

    .balign 4
data_area:
    .word 0x11223344
    .word 0x55667788
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
