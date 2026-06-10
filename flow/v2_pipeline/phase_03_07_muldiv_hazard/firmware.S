.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    la   s0, data_area
    addi s1, zero, 37
    addi s2, zero, 5
    addi s3, zero, -3
    addi s4, zero, -1
    lui  s5, 0x80000

    /* Back-to-back M ops with immediate ALU consumers. */
    mul  t0, s1, s2          /* 185 */
    div  t1, t0, s2          /* 37 */
    rem  t2, t0, s2          /* 0 */
    add  t3, t1, t2          /* consume div/rem immediately */
    bne  t3, s1, fail

    /* Signed multiply/divide chain. */
    mul  t4, s3, s2          /* -15 */
    div  t5, t4, s3          /* 5 */
    rem  t6, t4, s3          /* 0 */
    add  a0, t5, t6
    bne  a0, s2, fail

    /* M result as store data, then load-use into ALU. */
    sw   t1, 0(s0)
    lw   a1, 0(s0)
    addi a2, a1, 1
    addi a3, zero, 38
    bne  a2, a3, fail

    /* M result as address component. */
    addi a4, zero, 4
    mul  a5, a4, s2          /* 20 */
    add  a6, s0, a5
    sw   a2, 0(a6)
    lw   a7, 0(a6)
    bne  a7, a2, fail

    /* Divide-by-zero and overflow architectural corners. */
    div  s6, s1, zero        /* quotient all ones */
    addi s7, zero, -1
    bne  s6, s7, fail
    rem  s8, s1, zero        /* remainder dividend */
    bne  s8, s1, fail
    div  s9, s5, s4          /* overflow quotient INT_MIN */
    bne  s9, s5, fail
    rem  s10, s5, s4         /* overflow remainder 0 */
    bne  s10, zero, fail

    /* Back-to-back divide results with dependent branch. */
    divu s11, t0, s2         /* 37 */
    remu t0, t0, s2          /* 0 */
    add  t1, s11, t0
    bne  t1, s1, fail

.option push
.option rvc
    c.addi t1, 1
    c.addi t1, -1
.option pop

    ebreak

fail:
    addi t1, zero, -1
    ebreak

    .balign 4
data_area:
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
