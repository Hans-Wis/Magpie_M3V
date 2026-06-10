.section .init
.global _start

_start:
.option push
.option norvc
    la   t0, trap_handler
    csrw mtvec, t0
    la   a0, data_area

    lb   a1, 0(a0)
    sb   a1, 3(a0)
    lw   a2, 1(a0)
    lh   a3, 1(a0)
    li   a4, 0x123
    sh   a4, 1(a0)
done:
    ebreak

trap_handler:
    csrr t1, mepc
    addi t1, t1, 4
    csrw mepc, t1
    mret
.option pop

    .balign 4
data_area:
    .word 0x44332211
    .word 0x88776655
