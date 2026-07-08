    .section .init, "ax"
    .globl _start
_start:
    li sp, 0x80010000
    call main
1:
    j 1b

    .balign 4
    .globl trap_entry
trap_entry:
    li t1, 0x0C200004
    lw t0, 0(t1)
    li t3, 1
    beq t0, t3, 2f
    beqz t0, 1f
    sw t0, 0(t1)
    li t4, 3
    j 5f
1:
    li t4, 4
    j 5f
2:
    li t2, 0x30000008
    lw t3, 0(t2)
    andi t5, t3, 2
    beqz t5, 4f
    li t2, 0x30000054
    lw t5, 0(t2)
    li t2, 0x30000004
    li t4, 10
    sw t4, 0(t2)
    sw t0, 0(t1)
    li t2, 0x8000FE04
    sw t0, 0(t2)
    li t2, 0x8000FE08
    sw t3, 0(t2)
    li t2, 0x8000FE0C
    sw t5, 0(t2)
    li t4, 1
    j 5f
4:
    li t2, 0x30000004
    li t4, 10
    sw t4, 0(t2)
    sw t0, 0(t1)
    li t2, 0x8000FE04
    sw t0, 0(t2)
    li t2, 0x8000FE08
    sw t3, 0(t2)
    li t4, 2
5:
    li t2, 0x8000FE04
    sw t0, 0(t2)
    li t2, 0x8000FE00
    sw t4, 0(t2)
    la t6, irq_resume
    csrw mepc, t6
    mret

    .balign 4
    .globl arm_tail_and_wait
arm_tail_and_wait:
    fence iorw, iorw
    li t0, 8
    csrs mstatus, t0
    li t0, 0x3000004C
    li t1, 5
    sw t1, 0(t0)
1:
    li t0, 0x8000FE00
    lw t1, 0(t0)
    beqz t1, 1b
irq_resume:
    ret
