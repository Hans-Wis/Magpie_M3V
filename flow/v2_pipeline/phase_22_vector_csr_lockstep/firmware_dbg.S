.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    la   x31, data_area
    li   t0, 0xf4f4f4f4
    sw   t0, 8(x31)
    li   a0, 2
    vsetvli t1, a0, e8, m4, tu, ma
    vmv.v.i v12, 0
    addi a1, x31, 8
    vse8.v v12, (a1)
    lw   t2, 8(x31)
    ebreak
    .balign 4
data_area:
    .zero 64
