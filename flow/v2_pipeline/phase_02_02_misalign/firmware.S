.section .init
.global _start
_start:
    .option push
    .option norvc
    la   x5, trap_vector
    csrw mtvec, x5
    la   x10, data_area
    lui  x11, %hi(0x10001000)

    /* Aligned byte accesses must not trap. */
    lb   x12, 0(x10)
    addi x13, zero, 0x5a
    sb   x13, 0(x10)
    addi x14, zero, 0x11
    sw   x14, 0(x11)

    /* Deliberate misaligned load word: mcause=4, mtval=data_area+1. */
    lw   x15, 1(x10)
    addi x14, zero, 0x22
    sw   x14, 0(x11)

    /* Deliberate misaligned load half: mcause=4, mtval=data_area+1. */
    lh   x16, 1(x10)
    addi x14, zero, 0x33
    sw   x14, 0(x11)

    /* Deliberate misaligned store half: mcause=6, mtval=data_area+1. */
    addi x17, zero, 0x123
    sh   x17, 1(x10)
    addi x14, zero, 0x44
    sw   x14, 0(x11)

done:
    ebreak

trap_vector:
    nop
trap_handler:
    csrr x6, mepc
    addi x6, x6, 4
    csrw mepc, x6
    mret
    .option pop

    .balign 4
data_area:
    .word 0x44332211
    .word 0x88776655
