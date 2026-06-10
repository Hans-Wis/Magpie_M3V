.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    # rd sweep: x0..x31
    addi x0,  x0, 0
    addi x1,  x0, 0
    addi x2,  x0, 0
    addi x3,  x0, 0
    addi x4,  x0, 0
    addi x5,  x0, 0
    addi x6,  x0, 0
    addi x7,  x0, 0
    addi x8,  x0, 0
    addi x9,  x0, 0
    addi x10, x0, 0
    addi x11, x0, 0
    addi x12, x0, 0
    addi x13, x0, 0
    addi x14, x0, 0
    addi x15, x0, 0
    addi x16, x0, 0
    addi x17, x0, 0
    addi x18, x0, 0
    addi x19, x0, 0
    addi x20, x0, 0
    addi x21, x0, 0
    addi x22, x0, 0
    addi x23, x0, 0
    addi x24, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x27, x0, 0
    addi x28, x0, 0
    addi x29, x0, 0
    addi x30, x0, 0
    addi x31, x0, 0

    # rs1 sweep: x0..x31
    addi x0, x0,  0
    addi x0, x1,  0
    addi x0, x2,  0
    addi x0, x3,  0
    addi x0, x4,  0
    addi x0, x5,  0
    addi x0, x6,  0
    addi x0, x7,  0
    addi x0, x8,  0
    addi x0, x9,  0
    addi x0, x10, 0
    addi x0, x11, 0
    addi x0, x12, 0
    addi x0, x13, 0
    addi x0, x14, 0
    addi x0, x15, 0
    addi x0, x16, 0
    addi x0, x17, 0
    addi x0, x18, 0
    addi x0, x19, 0
    addi x0, x20, 0
    addi x0, x21, 0
    addi x0, x22, 0
    addi x0, x23, 0
    addi x0, x24, 0
    addi x0, x25, 0
    addi x0, x26, 0
    addi x0, x27, 0
    addi x0, x28, 0
    addi x0, x29, 0
    addi x0, x30, 0
    addi x0, x31, 0

    # rs2 sweep: x0..x31
    add x0, x0, x0
    add x0, x0, x1
    add x0, x0, x2
    add x0, x0, x3
    add x0, x0, x4
    add x0, x0, x5
    add x0, x0, x6
    add x0, x0, x7
    add x0, x0, x8
    add x0, x0, x9
    add x0, x0, x10
    add x0, x0, x11
    add x0, x0, x12
    add x0, x0, x13
    add x0, x0, x14
    add x0, x0, x15
    add x0, x0, x16
    add x0, x0, x17
    add x0, x0, x18
    add x0, x0, x19
    add x0, x0, x20
    add x0, x0, x21
    add x0, x0, x22
    add x0, x0, x23
    add x0, x0, x24
    add x0, x0, x25
    add x0, x0, x26
    add x0, x0, x27
    add x0, x0, x28
    add x0, x0, x29
    add x0, x0, x30
    add x0, x0, x31

    # operand value corners on both source ports
    li x5,  0
    li x6,  1
    li x7, -1
    li x8,  0x7fffffff
    li x9,  0x80000000
    li x10, 0xffffffff
    add x0, x5,  x0
    add x0, x6,  x0
    add x0, x7,  x0
    add x0, x8,  x0
    add x0, x9,  x0
    add x0, x10, x0
    add x0, x0, x5
    add x0, x0, x6
    add x0, x0, x7
    add x0, x0, x8
    add x0, x0, x9
    add x0, x0, x10

    # I immediate zero/min/max
    addi x0, x0, 0
    addi x11, x0, -2048
    addi x12, x0, 2047

    # S immediate zero/min/max
    sb x0, 0(sp)
    sb x0, -2048(sp)
    sb x0, 2047(sp)

    # B immediate zero and positive max; both are taken/skipped safely.
    bne x0, x0, .
    beq x0, x0, b_pos_max_target
    .space 4090, 0
b_pos_max_target:

    # B immediate negative min; jump over padding, then sample branch false.
b_neg_min_target:
    jal x0, b_neg_min_branch
    .space 4092, 0
b_neg_min_branch:
    bne x0, x0, b_neg_min_target

    # U immediate zero/min/max/all-ones.
    lui x13, 0
    lui x14, 0x80000
    lui x15, 0x7ffff
    lui x16, 0xfffff

    # J format positive/negative ordinary samples; extreme J offsets are tracked
    # as uncovered until the large-address alias harness is extended.
    jal x1, j_pos
j_neg:
    ebreak
j_pos:
    jal x0, j_neg
.option pop
