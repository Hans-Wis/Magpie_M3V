.section .init
.global _start
_start:
.option push
.option norvc
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)
    addi t0, zero, 1
    .word 0x00000000
.option pop
