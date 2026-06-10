    .option norvc
    .section .text.init
    .globl _start

    .equ TOHOST, 0x000003f0
    .equ MCAUSE_INSTR_ACCESS, 1
    .equ MCAUSE_LOAD_ACCESS,  5
    .equ MCAUSE_STORE_ACCESS, 7

_start:
    la   sp, stack_top
    la   t0, trap_handler
    csrw mtvec, t0

    call setup_pmp

    /* OFF/no-match allow. */
    la   t0, open_word
    lw   t1, 0(t0)
    li   t2, 0x11223344
    bne  t1, t2, fail_10

    /* Lowest-index priority: entry5 allows R before entry6 denies same NAPOT. */
    la   t0, priority_word
    lw   t1, 0(t0)
    li   t2, 0x55667788
    bne  t1, t2, fail_11

    /* NA4 load deny. */
    la   t0, deny_load_word
    la   t1, after_load_fault
    li   t2, MCAUSE_LOAD_ACCESS
    la   t6, exp_mtval
    sw   t0, 0(t6)
    la   t6, exp_resume
    sw   t1, 0(t6)
    la   t6, exp_mcause
    sw   t2, 0(t6)
    la   t6, exp_mepc
    sw   zero, 0(t6)
faulting_load:
    lw   t4, 0(t0)
after_load_fault:

    /* TOR load deny. */
    la   t0, tor_word
    la   t1, after_tor_fault
    li   t2, MCAUSE_LOAD_ACCESS
    la   t6, exp_mtval
    sw   t0, 0(t6)
    la   t6, exp_resume
    sw   t1, 0(t6)
    la   t6, exp_mcause
    sw   t2, 0(t6)
    la   t6, exp_mepc
    sw   zero, 0(t6)
faulting_tor_load:
    lw   t4, 0(t0)
after_tor_fault:

    /* NAPOT store deny. */
    la   t0, napot_pair
    la   t1, after_store_fault
    li   t2, MCAUSE_STORE_ACCESS
    la   t6, exp_mtval
    sw   t0, 0(t6)
    la   t6, exp_resume
    sw   t1, 0(t6)
    la   t6, exp_mcause
    sw   t2, 0(t6)
    la   t6, exp_mepc
    sw   zero, 0(t6)
faulting_store:
    sw   t2, 0(t0)
after_store_fault:
    la   t0, napot_pair
    lw   t4, 0(t0)
    li   t5, 0x99aabbcc
    bne  t4, t5, fail_12

    /* AMO checks R then W; this region allows R but denies W, so memory must not update. */
    la   t0, napot_pair
    la   t1, after_amo_fault
    li   t2, MCAUSE_STORE_ACCESS
    la   t6, exp_mtval
    sw   t0, 0(t6)
    la   t6, exp_resume
    sw   t1, 0(t6)
    la   t6, exp_mcause
    sw   t2, 0(t6)
    la   t6, exp_mepc
    sw   zero, 0(t6)
    li   t6, 0x12345678
faulting_amo:
    amoadd.w t4, t6, (t0)
after_amo_fault:
    la   t0, napot_pair
    lw   t4, 0(t0)
    li   t5, 0x99aabbcc
    bne  t4, t5, fail_13

    /* Fetch deny on a 32-bit instruction starting at 0x202 and crossing into 0x204. */
    la   t0, cross_fault
    la   t1, after_fetch_fault
    li   t2, MCAUSE_INSTR_ACCESS
    addi t3, t0, 2
    la   t6, exp_mtval
    sw   t3, 0(t6)
    la   t6, exp_resume
    sw   t1, 0(t6)
    la   t6, exp_mcause
    sw   t2, 0(t6)
    la   t6, exp_mepc
    sw   t0, 0(t6)
    jr   t0
after_fetch_fault:

    li   t0, 1
    li   t1, TOHOST
    sw   t0, 0(t1)

fail_10: li t0, 0x10; j fail
fail_11: li t0, 0x11; j fail
fail_12: li t0, 0x12; j fail
fail_13: li t0, 0x13; j fail
fail_20: li t0, 0x20; j fail
fail_21: li t0, 0x21; j fail
fail_22: li t0, 0x22; j fail
fail:
    li   t1, TOHOST
    sw   t0, 0(t1)
1:  j    1b

setup_pmp:
    la   t0, cross_fault
    addi t0, t0, 2
    srli t0, t0, 2
    csrw pmpaddr0, t0
    la   t0, deny_load_word
    srli t0, t0, 2
    csrw pmpaddr1, t0
    la   t0, tor_word
    srli t0, t0, 2
    csrw pmpaddr2, t0
    la   t0, tor_word_end
    srli t0, t0, 2
    csrw pmpaddr3, t0
    la   t0, napot_pair
    srli t0, t0, 2
    csrw pmpaddr4, t0
    la   t0, priority_word
    srli t0, t0, 2
    csrw pmpaddr5, t0
    csrw pmpaddr6, t0

    /* cfg0: e0 NA4 no X, e1 NA4 no R, e2 OFF, e3 TOR no R; all locked. */
    li   t0, 0x88009090
    csrw pmpcfg0, t0
    /* cfg1: e4 NAPOT R-only, e5 NAPOT R allow, e6 NAPOT deny, e7 OFF. */
    li   t0, 0x00989999
    csrw pmpcfg1, t0
    ret

trap_handler:
    csrr t0, mcause
    lw   t1, exp_mcause
    bne  t0, t1, fail_20
    csrr t0, mtval
    lw   t1, exp_mtval
    bne  t0, t1, fail_21
    lw   t1, exp_mepc
    beqz t1, 1f
    csrr t0, mepc
    bne  t0, t1, fail_22
1:
    lw   t0, exp_resume
    csrw mepc, t0
    mret

    .org 0x400
    .2byte 0x0001
cross_fault:
    addi t0, zero, 7

    .section .data
    .balign 8
open_word:       .word 0x11223344
deny_load_word:  .word 0xdeadbeef
tor_word:        .word 0xcafef00d
tor_word_end:
    .balign 8
napot_pair:      .word 0x99aabbcc
                 .word 0x0badc0de
    .balign 8
priority_word:   .word 0x55667788
                 .word 0x01020304
exp_mcause:      .word 0
exp_mtval:       .word 0
exp_mepc:        .word 0
exp_resume:      .word 0
stack_space:     .space 256
stack_top:
