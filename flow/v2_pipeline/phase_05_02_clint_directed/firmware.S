.equ CLINT_BASE,       0x02000000
.equ CLINT_MSIP,       0x02000000
.equ CLINT_MTIMECMP,   0x02004000
.equ CLINT_MTIME,      0x0200bff8
.equ RESULT_BASE,      0x10000000
.equ MCAUSE_MSW_IRQ,   0x80000003
.equ MCAUSE_TIMER_IRQ, 0x80000007

.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    la   t0, mtvec_handler
    csrw mtvec, t0

    li   t0, 0x10000000
    la   t1, corner_resume
    sw   t1, 0x38(t0)
    la   t1, corner_branch
    sw   t1, 0x3c(t0)

    /* a) Basic timer IRQ through CLINT mtimecmp. */
    la   t0, phase
    li   t1, 1
    sw   t1, 0(t0)
    li   t0, CLINT_MTIME
    lw   t1, 0(t0)
    addi t1, t1, 48
    li   t0, CLINT_MTIMECMP
    sw   zero, 4(t0)
    sw   t1, 0(t0)
    li   t0, (1 << 7)
    csrs mie, t0
    li   t0, (1 << 3)
    csrs mstatus, t0
timer_wait:
    la   t0, phase
    lw   t1, 0(t0)
    bnez t1, timer_wait
    li   t0, RESULT_BASE
    li   t1, 0x0000a001
    sw   t1, 0x08(t0)

    /* b) Software IRQ through CLINT msip. */
    la   t0, phase
    li   t1, 2
    sw   t1, 0(t0)
    li   t0, (1 << 3)
    csrs mie, t0
    li   t0, CLINT_MSIP
    li   t1, 1
    sw   t1, 0(t0)
sw_wait:
    la   t0, phase
    lw   t1, 0(t0)
    bnez t1, sw_wait
    li   t0, RESULT_BASE
    li   t1, 0x0000a002
    sw   t1, 0x18(t0)

    /* c) Timer IRQ aligned by TB to a cold branch mispredict and compressed resume PC. */
    la   t0, phase
    li   t1, 3
    sw   t1, 0(t0)
    li   t0, CLINT_MTIMECMP
    li   t1, -1
    sw   t1, 0(t0)
    sw   t1, 4(t0)
    li   t0, (1 << 7)
    csrs mie, t0

corner_branch:
    beq  zero, zero, corner_target
    li   t0, RESULT_BASE
    li   t1, 0xdead0001
    sw   t1, 0x20(t0)

.option push
.option rvc
corner_target:
    c.addi s0, 1
corner_resume:
    c.addi s1, 1
.option pop

corner_wait:
    la   t0, phase
    lw   t1, 0(t0)
    bnez t1, corner_wait
    li   t0, RESULT_BASE
    li   t1, 0x0000a003
    sw   t1, 0x40(t0)
done:
    j done

    .balign 4
mtvec_handler:
    csrr t0, mcause
    csrr t1, mepc
    la   t2, phase
    lw   t3, 0(t2)

    li   t4, 1
    beq  t3, t4, handle_timer_basic
    li   t4, 2
    beq  t3, t4, handle_sw
    li   t4, 3
    beq  t3, t4, handle_timer_corner

handler_unknown:
    li   t5, RESULT_BASE
    sw   t0, 0x44(t5)
    j    handler_finish

handle_timer_basic:
    li   t5, RESULT_BASE
    sw   t0, 0x00(t5)
    sw   t1, 0x04(t5)
    j    clear_timer

handle_sw:
    li   t5, RESULT_BASE
    sw   t0, 0x10(t5)
    sw   t1, 0x14(t5)
    li   t5, CLINT_MSIP
    sw   zero, 0(t5)
    j    handler_finish

handle_timer_corner:
    li   t5, RESULT_BASE
    sw   t0, 0x30(t5)
    sw   t1, 0x34(t5)
    j    clear_timer

clear_timer:
    li   t5, CLINT_MTIMECMP
    li   t6, -1
    sw   t6, 0(t5)
    sw   t6, 4(t5)

handler_finish:
    sw   zero, 0(t2)
    mret

    .balign 4
phase:
    .word 0
