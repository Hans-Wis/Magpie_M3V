.section .init
.global _start
_start:
    li    x1, 0x00000100
    la    x2, trap_handler
    csrw  mtvec, x2

    li    x3, 0xa5a5a5a5

    # ---- four misaligned accesses, each must trap ----
    lw    x4, 1(x1)
    sw    x3, 1(x1)
    lh    x5, 1(x1)
    sh    x3, 3(x1)

    ebreak

.section .text
.align 4
trap_handler:
    csrr x6, mcause
    csrr x7, mtval

    li    x8, 0x10000000
    la    x9, trap_count
    lw    x10, 0(x9)
    li    x11, 4
    blt   x10, x11, 1f
    mret
1:
    slli  x12, x10, 3      # offset = event * 8
    add   x12, x12, x8

    sw    x6, 0(x12)       # cause
    sw    x7, 4(x12)       # mtval

    addi  x10, x10, 1
    sw    x10, 0(x9)

    mret

.section .bss
.align 4
trap_count:
    .word 0
