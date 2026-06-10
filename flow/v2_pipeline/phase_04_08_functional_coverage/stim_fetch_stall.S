.section .init
.global _start

.option push
.option rvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    c.li   s0, 1
    c.j    target_unaligned
    c.nop

    .org 0x82
target_unaligned:
    lui  a0, 0x12345
    addi a1, a0, 7
    ebreak
.option pop
