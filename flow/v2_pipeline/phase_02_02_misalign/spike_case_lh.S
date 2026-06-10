.section .init
.global _start
_start:
    .option push
    .option norvc
    la   x10, data_area
    lh   x16, 1(x10)
    ebreak
    .option pop
    .balign 4
data_area:
    .word 0x44332211
    .word 0x88776655
