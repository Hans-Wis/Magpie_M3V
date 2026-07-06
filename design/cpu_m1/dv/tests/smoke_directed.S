.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

.option push
.option rvc
    c.li   s0, 1
    c.addi s0, 2
.option pop

    addi s1, zero, 5
    add  s2, s0, s1
    sw   s2, data_word, t0
    lw   s3, data_word
    beq  s2, s3, branch_taken
    addi s4, zero, 1

branch_taken:
    addi s4, zero, 2
    mul  s5, s4, s1
    addi s6, s5, -3

done:
    ebreak

    .balign 4
data_word:
    .word 0
