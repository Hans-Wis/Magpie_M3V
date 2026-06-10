.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    la   t0, load_data
    lw   s1, 0(t0)
    addi s2, s1, 1
    add  s3, s2, s1
    sw   s3, 4(t0)
    ebreak
.option pop

    .balign 4
load_data:
    .word 0x00000021
