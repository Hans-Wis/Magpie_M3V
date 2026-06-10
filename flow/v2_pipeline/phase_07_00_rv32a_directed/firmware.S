    .section .init
    .globl _start
_start:
    la   sp, stack_top
    la   t0, trap_handler
    csrw mtvec, t0

    la   s0, data_word
    li   t0, 0x11
    sw   t0, 0(s0)

    lr.w t1, (s0)
    li   t2, 0x22
    sc.w t3, t2, (s0)
    bnez t3, fail_10
    lw   t4, 0(s0)
    li   t5, 0x22
    bne  t4, t5, fail_11

    li   t0, 0x33
    sc.w t1, t0, (s0)
    beqz t1, fail_12
    lw   t2, 0(s0)
    bne  t2, t5, fail_13

    li   t0, 0x10
    sw   t0, 0(s0)
    li   t2, 0x05
    amoadd.w t1, t2, (s0)
    li   t3, 0x10
    bne  t1, t3, fail_20
    lw   t4, 0(s0)
    li   t5, 0x15
    bne  t4, t5, fail_21

    li   t2, 0xaa
    amoswap.w t1, t2, (s0)
    bne  t1, t5, fail_22
    lw   t4, 0(s0)
    bne  t4, t2, fail_23

    li   t2, 0x0f
    amoxor.w t1, t2, (s0)
    li   t3, 0xaa
    bne  t1, t3, fail_24
    lw   t4, 0(s0)
    li   t5, 0xa5
    bne  t4, t5, fail_25

    li   t2, 0x50
    amoand.w t1, t2, (s0)
    bne  t1, t5, fail_26
    lw   t4, 0(s0)
    li   t5, 0x00
    bne  t4, t5, fail_27

    li   t2, 0x81
    amoor.w t1, t2, (s0)
    bne  t1, t5, fail_28
    lw   t4, 0(s0)
    li   t5, 0x81
    bne  t4, t5, fail_29

    li   t0, -5
    sw   t0, 0(s0)
    li   t2, 3
    amomin.w t1, t2, (s0)
    bne  t1, t0, fail_30
    lw   t4, 0(s0)
    bne  t4, t0, fail_31

    amomax.w t1, t2, (s0)
    bne  t1, t0, fail_32
    lw   t4, 0(s0)
    bne  t4, t2, fail_33

    li   t0, -1
    sw   t0, 0(s0)
    li   t2, 1
    amominu.w t1, t2, (s0)
    bne  t1, t0, fail_34
    lw   t4, 0(s0)
    bne  t4, t2, fail_35

    li   t0, 2
    sw   t0, 0(s0)
    li   t2, -1
    amomaxu.w t1, t2, (s0)
    bne  t1, t0, fail_36
    lw   t4, 0(s0)
    bne  t4, t2, fail_37

    li   s1, 0
    addi t0, s0, 2
    amoswap.w t1, t2, (t0)
    j    fail_40
after_misalign:
    li   t0, 1
    bne  s1, t0, fail_41

    li   t0, 0x44
    sw   t0, 0(s0)
    lr.w t1, (s0)
    li   t2, 0x55
    amoadd.w t3, t2, (s0)
    csrr t4, mstatus
    ori  t4, t4, 0x8
    csrw mstatus, t4
    li   t4, 0x800
    csrw mie, t4
irq_resume:
    li   t2, 0x66
    sc.w t3, t2, (s0)
    beqz t3, fail_50
    lw   t4, 0(s0)
    li   t5, 0x99
    bne  t4, t5, fail_51

pass:
    li   t0, 1
    li   t1, 0x3f0
    sw   t0, 0(t1)
1:  j 1b

fail_10: li t0, 0x10; j fail
fail_11: li t0, 0x11; j fail
fail_12: li t0, 0x12; j fail
fail_13: li t0, 0x13; j fail
fail_20: li t0, 0x20; j fail
fail_21: li t0, 0x21; j fail
fail_22: li t0, 0x22; j fail
fail_23: li t0, 0x23; j fail
fail_24: li t0, 0x24; j fail
fail_25: li t0, 0x25; j fail
fail_26: li t0, 0x26; j fail
fail_27: li t0, 0x27; j fail
fail_28: li t0, 0x28; j fail
fail_29: li t0, 0x29; j fail
fail_30: li t0, 0x30; j fail
fail_31: li t0, 0x31; j fail
fail_32: li t0, 0x32; j fail
fail_33: li t0, 0x33; j fail
fail_34: li t0, 0x34; j fail
fail_35: li t0, 0x35; j fail
fail_36: li t0, 0x36; j fail
fail_37: li t0, 0x37; j fail
fail_40: li t0, 0x40; j fail
fail_41: li t0, 0x41; j fail
fail_50: li t0, 0x50; j fail
fail_51: li t0, 0x51; j fail

fail:
    li   t1, 0x3f0
    sw   t0, 0(t1)
1:  j 1b

trap_handler:
    csrr t0, mcause
    li   t1, 6
    beq  t0, t1, trap_misalign
    li   t1, 0x8000000b
    beq  t0, t1, trap_irq
    li   t0, 0xee
    j    fail
trap_misalign:
    csrr t0, mtval
    addi t1, s0, 2
    bne  t0, t1, fail_40
    csrr t0, mepc
    la   t1, after_misalign
    csrw mepc, t1
    li   s1, 1
    mret
trap_irq:
    csrr t0, mepc
    la   t1, irq_resume
    csrw mepc, t1
    csrr t0, mstatus
    li   t1, -9
    and  t0, t0, t1
    csrw mstatus, t0
    mret

    .align 2
data_word:
    .word 0
    .space 256
stack_top:
