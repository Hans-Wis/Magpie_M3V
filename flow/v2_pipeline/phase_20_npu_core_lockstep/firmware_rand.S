.section .init
.global _start
_start:
    /* deterministic pseudo-random seed=20260703 count=96 iters=110 */
    lui  sp, 1              /* sp = 0x1000 = TCM top (unused by body) */
    la   x31, data_area
    addi x30, zero, 7       /* non-zero divisor */
    addi x29, zero, 110 /* loop counter (reserved) */
    addi x5, zero, 1071
    addi x6, zero, 1711
    addi x7, zero, 1909
    addi x8, zero, 253
    addi x9, zero, 1751
    addi x10, zero, 942
    addi x11, zero, 877
    addi x12, zero, 1430
    addi x13, zero, 2018
    addi x14, zero, 21
    addi x15, zero, 933
    addi x16, zero, 695
    addi x17, zero, 645
    addi x18, zero, 123
    addi x19, zero, 1825
    addi x20, zero, 497
    addi x21, zero, 443
    addi x22, zero, 511
    addi x23, zero, 1220
    addi x24, zero, 1134
    addi x25, zero, 487
    addi x26, zero, 371
    addi x27, zero, 469
    addi x28, zero, 1752
loop_top:
    addi x7, x21, -132
    rem x5, x12, x30
    and x18, x19, x21
    srli x19, x23, 27
    sb x18, 10(x31)
    srai x25, x14, 18
    srl x8, x17, x22
    slt x19, x18, x13
    lbu x14, 6(x31)
    sh x18, 0(x31)
    lb x7, 6(x31)
    srai x20, x23, 1
    and x9, x23, x23
    srai x15, x5, 20
    sll x5, x25, x17
    addi x20, x5, 145
    lbu x25, 3(x31)
    andi x8, x20, 1335
    lw x10, 48(x31)
    andi x12, x26, 1899
    lbu x11, 5(x31)
    add x23, x27, x17
    xori x22, x26, 275
    or x26, x22, x6
    andi x12, x14, -531
    or x7, x8, x25
    srli x7, x26, 25
    slti x9, x7, 1755
    remu x8, x27, x30
    mulh x23, x19, x17
    sb x6, 1(x31)
    sw x17, 4(x31)
    mul x5, x6, x11
    srli x24, x27, 28
    srl x17, x21, x7
    sb x9, 1(x31)
    mulhu x6, x23, x11
    mul x25, x15, x20
    lw x27, 12(x31)
    srai x15, x26, 22
    sltu x24, x16, x22
    mulh x27, x16, x8
    or x12, x20, x26
    sb x9, 8(x31)
    sltiu x26, x26, 143
    srai x16, x23, 18
    divu x25, x23, x30
    sra x18, x8, x18
    xor x11, x25, x12
    lw x8, 52(x31)
    addi x20, x5, -1882
    slli x15, x10, 25
    sw x23, 12(x31)
    lb x17, 7(x31)
    lb x7, 15(x31)
    lh x14, 30(x31)
    sw x24, 52(x31)
    slli x7, x5, 12
    sll x18, x19, x5
    xori x7, x16, 1070
    sw x18, 52(x31)
    slt x22, x10, x10
    srli x24, x6, 25
    sh x18, 2(x31)
    add x17, x9, x8
    sw x17, 28(x31)
    lb x6, 15(x31)
    xor x18, x17, x23
    addi x17, x24, 69
    slli x5, x20, 12
    sltiu x22, x12, -1480
    addi x6, x21, 1346
    or x20, x19, x7
    slt x23, x18, x28
    or x28, x23, x28
    slt x18, x25, x10
    mulhu x17, x16, x16
    sltu x8, x19, x15
    remu x11, x13, x30
    mulh x16, x26, x9
    slli x5, x26, 10
    slli x25, x20, 27
    srai x25, x12, 14
    rem x25, x18, x30
    andi x22, x25, 1802
    rem x9, x13, x30
    lbu x13, 11(x31)
    div x6, x15, x30
    lb x25, 6(x31)
    andi x23, x20, 1793
    sw x27, 56(x31)
    sb x12, 6(x31)
    sll x24, x8, x21
    mul x21, x16, x23
    addi x11, x14, 169
    slli x8, x8, 28
    addi x29, x29, -1
    bne  x29, zero, loop_top   /* EX-resolve redirect every iteration (BP off) */
done:
    ebreak

    .balign 4
data_area:
    .word 0x30254d52
    .word 0x9405d6b9
    .word 0xf4a20f28
    .word 0xeb1bf285
    .word 0x2135c812
    .word 0xe7609a80
    .word 0xdb40bb60
    .word 0xbd23b738
    .word 0x02e83fb8
    .word 0x52cba52c
    .word 0x25ffa862
    .word 0xe7765124
    .word 0x02b75f1c
    .word 0x4a7d7a10
    .word 0xdad53873
    .word 0xe1d32a18
    .word 0xcfb7e13c
    .word 0xf84cda97
    .word 0xe023a48e
    .word 0x84f1f382
