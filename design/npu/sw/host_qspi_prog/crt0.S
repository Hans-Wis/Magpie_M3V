    .section .init, "ax"
    .globl _start
_start:
    li sp, 0x80010000
    call main
1:
    j 1b
