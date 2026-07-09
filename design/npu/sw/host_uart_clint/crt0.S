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
    csrr t0, mcause
    li t1, 0x8000000B
    beq t0, t1, trap_ext
    li t1, 0x80000007
    beq t0, t1, trap_timer
    li t1, 0x80000003
    beq t0, t1, trap_soft

    li t2, 0x8000FE10
    li t3, 0x0000DEAD
    sw t3, 0(t2)
    mret

trap_ext:
    li t1, 0x0C200004
    lw t0, 0(t1)
    li t2, 2                    # UART = PLIC ID 2 (NPU keeps ID 1)
    beq t0, t2, 1f
    li t3, 0x8000FE10
    sw t0, 0(t3)
    sw t0, 0(t1)
    mret
1:
    li t3, 0x10000008
    lw t4, 0(t3)
    sw t0, 0(t1)
    li t3, 0x8000FE04
    sw t0, 0(t3)
    li t3, 0x8000FE14
    sw t4, 0(t3)
    mret

trap_timer:
    li t5, 128
    csrc mie, t5
    li t1, 0x02004004
    li t2, -1
    sw t2, 0(t1)
    li t1, 0x02004000
    sw t2, 0(t1)
    li t3, 0x8000FE08
    li t4, 1
    sw t4, 0(t3)
    mret

trap_soft:
    li t5, 8
    csrc mie, t5
    li t1, 0x02000000
    sw zero, 0(t1)
    li t3, 0x8000FE0C
    li t4, 1
    sw t4, 0(t3)
    la t6, soft_resume
    csrw mepc, t6
    mret

    .balign 4
    .globl arm_soft_and_wait
arm_soft_and_wait:
    fence iorw, iorw
    li t0, 8
    csrs mie, t0
    li t0, 0x02000000
    li t1, 1
    sw t1, 0(t0)
1:
    li t0, 0x8000FE0C
    lw t1, 0(t0)
    beqz t1, 1b
soft_resume:
    ret
