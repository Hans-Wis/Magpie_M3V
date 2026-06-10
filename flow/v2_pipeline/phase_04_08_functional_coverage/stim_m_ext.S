.section .init
.global _start

_start:
.option push
.option norvc
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   a0, 123
    li   a1, 7
    mulhsu a2, a0, a1
    divu   a3, a0, a1
    rem    a4, a0, a1
    remu   a5, a0, a1
    ebreak
.option pop
