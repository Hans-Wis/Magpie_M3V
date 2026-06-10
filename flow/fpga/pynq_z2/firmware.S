    .section .init
    .global _start
    .global main

_start:
    lui  sp, %hi(_stack_top)
    addi sp, sp, %lo(_stack_top)
    jal  ra, main
1:
    j 1b
