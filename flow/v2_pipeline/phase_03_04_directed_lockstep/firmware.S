.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

.option push
.option rvc
    c.li   s0, 3
    c.addi s0, 4
    c.li   s1, 2
    c.add  s1, s0
.option pop

    addi t0, zero, 0
    addi t1, zero, 11
    addi t2, zero, -5
    add  s2, t1, t2
    sub  s3, t1, t2
    xor  s4, s2, s3
    or   s5, s2, s3
    and  s6, s4, s5
    slli a0, s2, 2
    srli a1, a0, 1
    srai a2, t2, 1

    la   a3, data_area
    sw   s3, 0(a3)
    lw   a4, 0(a3)
    sh   s2, 4(a3)
    lh   a5, 4(a3)
    sb   s2, 6(a3)
    lb   a6, 6(a3)

.option push
.option rvc
    c.sw  s0, 8(a3)
    c.lw  s1, 8(a3)
.option pop

    bne  a4, s3, fail
    beq  a5, s2, branch_taken
    addi t0, zero, 1

branch_taken:
    addi t0, t0, 2
    blt  t2, zero, signed_branch
    addi t0, t0, 4

signed_branch:
    mul  t3, s0, s1
    div  t4, t3, s0
    rem  t5, t3, s0
    add  t6, t4, t5

    jal  ra, subroutine
after_subroutine:
    addi s7, s7, 1
    bne  s7, t6, fail
    ebreak

subroutine:
    addi s7, t6, -1
    jalr zero, 0(ra)

fail:
    addi s7, zero, -1
    ebreak

    .balign 4
data_area:
    .word 0
    .word 0
    .word 0
