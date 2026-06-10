.section .init
.global _start

_start:
    .option push
    .option norvc
    lui  x8, %hi(0x10000000)

    li   x5, 0x00000083
    csrw mepc, x5
    nop
    nop
    nop
    csrr x6, mepc
    sw   x6, 0x200(x8)

    la   x5, trap_vector
    csrw mtvec, x5
    la   x5, data_area

    j    illegal32_aligned
resume_illegal32_aligned:
    j    illegal32_half
resume_illegal32_half:
    j    illegal16
resume_illegal16:
    j    ebreak32
resume_ebreak32:
    j    misaligned_lw
resume_misaligned_lw:
    li   x6, 0x600d
    sw   x6, 0x100(x8)
done:
    j    done

    .org 0x80
.global illegal32_aligned
illegal32_aligned:
    .word 0xffffffff

    .org 0x8c
    .2byte 0x0001
.global illegal32_half
illegal32_half:
    .word 0xffffffff

    .org 0x98
.global illegal16
illegal16:
    .2byte 0x0000

    .org 0xa0
.global ebreak32
ebreak32:
    ebreak

    .org 0xa8
.global misaligned_lw
misaligned_lw:
    lw   x9, 1(x5)

    .balign 4
trap_vector:
    la   x10, event_count
    lw   x11, 0(x10)
    li   x12, 0x10000000
    slli x13, x11, 4
    add  x12, x12, x13

    csrr x14, mepc
    sw   x14, 0(x12)
    csrr x14, mcause
    sw   x14, 4(x12)
    csrr x14, mtval
    sw   x14, 8(x12)

    la   x15, resume_table
    slli x16, x11, 2
    add  x15, x15, x16
    lw   x14, 0(x15)
    addi x11, x11, 1
    sw   x11, 0(x10)
    csrw mepc, x14
    mret
    .option pop

    .balign 4
resume_table:
    .word resume_illegal32_aligned
    .word resume_illegal32_half
    .word resume_illegal16
    .word resume_ebreak32
    .word resume_misaligned_lw

    .balign 4
event_count:
    .word 0

    .balign 4
data_area:
    .word 0x44332211
    .word 0x88776655
