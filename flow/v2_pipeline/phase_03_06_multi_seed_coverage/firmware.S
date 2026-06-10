.section .init
.global _start
_start:
    /* deterministic pseudo-random seed=20260607 count=48 */
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)
    la   x31, data_area
    addi x30, zero, 7       /* non-zero divisor */
    addi x5, zero, 776
    addi x6, zero, 1765
    addi x7, zero, 313
    addi x8, zero, 364
    addi x9, zero, 480
    addi x10, zero, 487
    addi x11, zero, 72
    addi x12, zero, 862
    addi x13, zero, 823
    addi x14, zero, 602
    addi x15, zero, 1471
    addi x16, zero, 278
    addi x17, zero, 380
    addi x18, zero, 1240
    addi x19, zero, 1784
    addi x20, zero, 872
    addi x21, zero, 1898
    addi x22, zero, 575
    addi x23, zero, 931
    addi x24, zero, 1973
    addi x25, zero, 1811
    addi x26, zero, 972
    addi x27, zero, 1283
    addi x28, zero, 1728
    addi x29, zero, 1111
.option push
.option rvc
    c.li   s0, 1
    c.addi s0, 2
    c.mv   s1, s0
.option pop
    slli x26, x8, 4
    div x16, x12, x30
    srli x8, x14, 8
    slt x5, x13, x28
    add x17, x10, x25
    sh x13, 2(x31)
    srl x18, x23, x6
    slti x6, x16, 1058
    xori x18, x24, -475
    lb x13, 9(x31)
    sltu x14, x18, x23
    lb x6, 10(x31)
    lbu x8, 5(x31)
    sh x22, 30(x31)
    sw x7, 40(x31)
    lw x24, 8(x31)
    lh x19, 4(x31)
    sb x10, 2(x31)
    sra x21, x6, x25
    srl x18, x12, x15
    srai x24, x10, 22
    add x6, x20, x29
    add x15, x25, x9
    mulh x6, x28, x9
    andi x7, x11, -1861
    srai x8, x5, 15
    addi x17, x11, 1726
    div x27, x6, x30
    srl x8, x20, x21
    slli x25, x11, 12
    sra x26, x29, x14
    sltu x11, x21, x15
    sra x25, x9, x26
    andi x16, x23, 1572
    or x19, x22, x15
    srli x27, x24, 21
    mulhu x16, x15, x21
    sw x6, 60(x31)
    sh x13, 4(x31)
    mul x29, x6, x18
    sltiu x22, x13, -781
    srli x10, x23, 1
    sll x15, x6, x28
    srl x9, x12, x28
    sub x13, x24, x7
    sra x5, x24, x27
    srai x7, x23, 7
    ori x22, x13, 1330
done:
    ebreak

    .balign 4
data_area:
    .word 0x1de28ab8
    .word 0xe4151ddc
    .word 0xd2858015
    .word 0x687183ee
    .word 0xb75d52ce
    .word 0xf2f076c1
    .word 0x20086b3e
    .word 0x54112fe2
    .word 0x5b5bdd6d
    .word 0x0c8942db
    .word 0x628b4dee
    .word 0x31834b8f
    .word 0xf0b65ab4
    .word 0xc9695e28
    .word 0xa2941268
    .word 0xb834be8b
    .word 0xda07f747
    .word 0xd04fbf41
    .word 0xeb8d587c
    .word 0xc1fa1cc5
