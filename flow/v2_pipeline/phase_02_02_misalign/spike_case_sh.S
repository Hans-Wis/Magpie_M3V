.section .init
.global _start
_start:
    .option push
    .option norvc
    la   x10, data_area
    addi x17, zero, 0x123
    sh   x17, 1(x10)
    ebreak
    .option pop
    .balign 4
data_area:
    .word 0x44332211
    .word 0x88776655
