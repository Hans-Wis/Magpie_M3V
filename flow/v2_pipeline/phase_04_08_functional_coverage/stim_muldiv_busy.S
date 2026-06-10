.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   a0, 33
    li   a1, 7
    mul  a2, a0, a1
    mul  a3, a2, a1
    div  a4, a0, a1
    divu a5, a4, a1
    add  a6, a3, a5
    ebreak
.option pop
