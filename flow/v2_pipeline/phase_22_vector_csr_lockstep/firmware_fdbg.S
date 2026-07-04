.section .init
.global _start
_start:
    li   t0, 0x2200
    csrs mstatus, t0
    li   t0, 0xC0100000        /* -2.25 */
    fmv.w.x f2, t0
    li   t0, 0x7FC00001
    fmv.w.x f3, t0
    fcvt.w.s t1, f2, rdn
    fcvt.wu.s t1, f2, rtz
    csrr t2, fflags
    csrw fflags, x0
    fcvt.w.s t1, f3, rtz
    csrr t2, fflags
    ebreak
