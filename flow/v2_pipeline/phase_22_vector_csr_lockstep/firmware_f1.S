/* ADR-0050 F1 directed: FS/fcsr contract + moves/sign/compare/classify/
   min-max/cvt/flw-fsw. Spike --isa=rv32imf... is the authority; F-reg writes
   compared via the rd=64+f trace rows. */
.section .init
.global _start
_start:
    li   t0, 0x2200            /* mstatus: FS=01 + VS=01 */
    csrs mstatus, t0
    la   x31, data_area

    /* seed memory floats: 1.5f, -2.25f, qNaN, -0.0f */
    li   t0, 0x3FC00000
    sw   t0, 0(x31)
    li   t0, 0xC0100000
    sw   t0, 4(x31)
    li   t0, 0x7FC00001
    sw   t0, 8(x31)
    li   t0, 0x80000000
    sw   t0, 12(x31)
    li   t0, 0x7F800000        /* +inf */
    sw   t0, 16(x31)
    li   t0, 0x00000001        /* min subnormal */
    sw   t0, 20(x31)
    li   t0, 0x7FA00000        /* sNaN */
    sw   t0, 24(x31)

    /* flw / fmv.x.w roundtrips */
    flw  f1, 0(x31)
    fmv.x.w t1, f1
    flw  f2, 4(x31)
    fmv.x.w t1, f2
    flw  f3, 8(x31)
    flw  f4, 12(x31)
    flw  f5, 16(x31)
    flw  f6, 20(x31)
    flw  f7, 24(x31)

    /* fmv.w.x + fsw roundtrip */
    li   t0, 0x40490FDB        /* pi */
    fmv.w.x f8, t0
    fsw  f8, 28(x31)
    lw   t1, 28(x31)

    /* sign injection incl. NaN payload */
    fsgnj.s  f9, f1, f2
    fmv.x.w t1, f9
    fsgnjn.s f9, f2, f2
    fmv.x.w t1, f9
    fsgnjx.s f9, f2, f2
    fmv.x.w t1, f9
    fsgnj.s  f9, f3, f2        /* NaN payload preserved, no NV */
    fmv.x.w t1, f9
    csrr t2, fflags

    /* compares: feq sNaN-only NV; flt/fle any-NaN NV */
    feq.s t1, f1, f1
    csrr t2, fflags
    feq.s t1, f3, f1           /* qNaN: 0, no NV */
    csrr t2, fflags
    flt.s t1, f3, f1           /* qNaN: 0, NV */
    csrr t2, fflags
    csrw fflags, x0
    feq.s t1, f7, f1           /* sNaN: 0, NV */
    csrr t2, fflags
    csrw fflags, x0
    fle.s t1, f2, f1           /* -2.25 <= 1.5 */
    flt.s t1, f4, f1           /* -0 < 1.5 */
    feq.s t1, f4, f4
    fmv.w.x f10, x0            /* +0 */
    feq.s t1, f4, f10          /* -0 == +0 */

    /* min/max: +-0 ordering, NaN rules */
    fmin.s f11, f4, f10        /* -> -0 */
    fmv.x.w t1, f11
    fmax.s f11, f4, f10        /* -> +0 */
    fmv.x.w t1, f11
    fmin.s f11, f3, f1         /* qNaN,x -> x, no NV */
    fmv.x.w t1, f11
    csrr t2, fflags
    fmin.s f11, f7, f1         /* sNaN,x -> x, NV */
    fmv.x.w t1, f11
    csrr t2, fflags
    csrw fflags, x0
    fmin.s f11, f3, f3         /* both NaN -> canonical */
    fmv.x.w t1, f11
    fclass.s t1, f1
    fclass.s t1, f2
    fclass.s t1, f3
    fclass.s t1, f4
    fclass.s t1, f5
    fclass.s t1, f6
    fclass.s t1, f7

    /* fcvt.w.s: rounding grid + specials */
    fcvt.w.s t1, f1, rne       /* 1.5 -> 2 */
    csrr t2, fflags
    csrw fflags, x0
    fcvt.w.s t1, f1, rtz       /* 1 */
    fcvt.w.s t1, f1, rdn       /* 1 */
    fcvt.w.s t1, f1, rup       /* 2 */
    fcvt.w.s t1, f1, rmm       /* 2 */
    csrw fflags, x0
    fcvt.w.s t1, f2, rne       /* -2.25 -> -2 */
    fcvt.w.s t1, f2, rdn       /* -3 */
    fcvt.wu.s t1, f2, rtz      /* negative -> NV, 0 */
    csrr t2, fflags
    csrw fflags, x0
    fcvt.w.s t1, f3, rtz       /* NaN -> 0x7FFFFFFF NV */
    csrr t2, fflags
    csrw fflags, x0
    fcvt.w.s t1, f5, rtz       /* +inf -> 0x7FFFFFFF NV */
    csrr t2, fflags
    csrw fflags, x0
    fcvt.wu.s t1, f5, rtz      /* +inf -> 0xFFFFFFFF NV */
    csrr t2, fflags
    csrw fflags, x0
    fcvt.w.s t1, f6, rtz       /* subnormal -> 0, NX */
    csrr t2, fflags
    csrw fflags, x0

    /* fcvt.s.w / s.wu: exact + inexact + dynamic rm */
    li   t0, 7
    fcvt.s.w f12, t0           /* exact, no NX */
    fmv.x.w t1, f12
    csrr t2, fflags
    li   t0, 0x7FFFFFC1        /* needs rounding at 24 bits */
    fcvt.s.w f12, t0
    fmv.x.w t1, f12
    csrr t2, fflags
    csrw fflags, x0
    li   t0, -5
    fcvt.s.w f12, t0
    fmv.x.w t1, f12
    li   t0, 0xFFFFFFFF
    fcvt.s.wu f12, t0          /* 2^32-1 rounds */
    fmv.x.w t1, f12
    csrr t2, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0               /* RTZ dynamic */
    li   t0, 0x7FFFFFC1
    fcvt.s.w f12, t0           /* dyn rm consumes frm (fwd corner) */
    fmv.x.w t1, f12
    csrw frm, x0

    /* fcsr alias + FS dirty visibility */
    li   t0, 0x63
    csrw fcsr, t0
    csrr t2, fflags
    csrr t3, frm
    csrr t4, fcsr
    csrw fcsr, x0
    csrr t5, mstatus           /* FS dirty + SD */

    ebreak
    .balign 4
data_area:
    .zero 64
