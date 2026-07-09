    .section .init, "ax"
    .globl _start
_start:
    li sp, 0x80010000       # JTAG abstract-read golden: gate_89 reads x2 == this
    call main
1:
    j 1b
