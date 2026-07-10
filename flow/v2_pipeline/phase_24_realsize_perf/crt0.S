/* Magpie_M1 bench crt0: stack top = 256KB, clear .bss, call main, ebreak to stop the TB. */
.section .init
.global _start
_start:
    li   sp, 0x40000            /* 256 KB memory top (bench TB MEM_WORDS=65536) */
    la   t0, trap_catch
    csrw mtvec, t0
    la   t0, __bss_start
    la   t1, __bss_end
1:  bgeu t0, t1, 2f
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    1b
2:  call main
    ebreak

    .balign 4
trap_catch:                     /* any unexpected trap: report cause and stop */
    li   t0, 0x10000004
    csrr t1, mcause
    sw   t1, 0(t0)
    ebreak
