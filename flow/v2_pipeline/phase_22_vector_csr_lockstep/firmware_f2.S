/* ADR-0050 F2-F4 directed corners (Grok list): all-rm rounding, NaN
   propagation, inf/zero algebra, overflow/underflow ladders per rm,
   fused-vs-split FMA cases, massive exponent deltas, DZ/NV, subnormal
   quotients, exact/inexact sqrt. Spike --isa=rv32imf... is the authority;
   every f-write is compared bit-exact, fflags probed per group. */
.section .init
.global _start
_start:
    li   t0, 0x2200            /* mstatus: FS=01 + VS=01 */
    csrs mstatus, t0

    /* ---- constants in f-regs ---- */
    li t0, 0x3F800000
    fmv.w.x f1, t0             /* 1.0 */
    li t0, 0x40000000
    fmv.w.x f2, t0             /* 2.0 */
    li t0, 0x33800000
    fmv.w.x f3, t0             /* 2^-24 (half-ulp of 1.0) */
    li t0, 0x7F800000
    fmv.w.x f4, t0             /* +inf */
    li t0, 0xFF800000
    fmv.w.x f5, t0             /* -inf */
    li t0, 0x7FC00001
    fmv.w.x f6, t0             /* qNaN w/ payload */
    li t0, 0x7FA00000
    fmv.w.x f7, t0             /* sNaN */
    li t0, 0x7F7FFFFF
    fmv.w.x f8, t0             /* max normal */
    li t0, 0x00800000
    fmv.w.x f9, t0             /* min normal */
    li t0, 0x00000001
    fmv.w.x f10, t0            /* min subnormal */
    li t0, 0x00000000
    fmv.w.x f11, t0            /* +0 */
    li t0, 0x80000000
    fmv.w.x f12, t0            /* -0 */
    li t0, 0x7149F2CA
    fmv.w.x f13, t0            /* ~1e30 */
    li t0, 0x0F94EE94
    fmv.w.x f14, t0            /* ~1e-30 */
    li t0, 0x3F000000
    fmv.w.x f15, t0            /* 0.5 */
    li t0, 0x40400000
    fmv.w.x f16, t0            /* 3.0 */
    li t0, 0x00800001
    fmv.w.x f17, t0            /* min normal + 1ulp */
    li t0, 0xBF800000
    fmv.w.x f18, t0            /* -1.0 */
    li t0, 0x3FC00000
    fmv.w.x f19, t0            /* 1.5 */
    csrw fflags, x0

    /* ==== F2: fadd half-ulp tie across every static rm ==== */
    fadd.s f20, f1, f3, rne    /* tie -> even: 1.0 */
    fmv.x.w t1, f20
    fadd.s f20, f1, f3, rtz
    fadd.s f20, f1, f3, rdn
    fadd.s f20, f1, f3, rup    /* 1.0+ulp */
    fmv.x.w t1, f20
    fadd.s f20, f1, f3, rmm    /* tie away: 1.0+ulp */
    fmv.x.w t1, f20
    frflags t2                 /* NX */
    csrw fflags, x0
    /* dynamic rm: frm=RUP then RDN, back-to-back forwarding corner */
    li t0, 3
    csrw frm, t0
    fadd.s f20, f1, f3         /* dyn=RUP */
    fmv.x.w t1, f20
    li t0, 2
    csrw frm, t0
    fadd.s f20, f1, f3         /* dyn=RDN, frm forwarded same-window */
    fmv.x.w t1, f20
    csrw frm, x0
    csrw fflags, x0

    /* ==== F2: inf/NaN algebra ==== */
    fadd.s f20, f4, f5         /* inf + -inf -> qNaN, NV */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fadd.s f20, f4, f4         /* inf + inf -> inf, clean */
    frflags t2
    fadd.s f20, f6, f1         /* qNaN + 1.0 -> canonical, clean */
    fmv.x.w t1, f20
    frflags t2
    fadd.s f20, f7, f1         /* sNaN -> canonical + NV */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fsub.s f20, f19, f19, rne  /* 1.5-1.5 -> +0 */
    fmv.x.w t1, f20
    fsub.s f20, f19, f19, rdn  /* -> -0 under RDN */
    fmv.x.w t1, f20
    fsub.s f20, f4, f4         /* inf - inf -> qNaN, NV */
    frflags t2
    csrw fflags, x0
    /* equal-exponent cancelling subtracts (Sterbenz-exact, renormalizing) —
       the path random floats almost never hit; regression for the
       subMags pack-carry fix */
    li t0, 0x3FC00000
    fmv.w.x f25, t0            /* 1.5 */
    li t0, 0x3FA00000
    fmv.w.x f26, t0            /* 1.25 */
    fsub.s f20, f25, f26       /* -> 0.25 = 0x3E800000 (was 0x3F000000 bug) */
    fmv.x.w t1, f20
    fsub.s f20, f26, f25       /* -> -0.25 */
    fmv.x.w t1, f20
    frflags t2                 /* must stay clean: exact */
    li t0, 0x40490FDB
    fmv.w.x f27, t0            /* pi */
    li t0, 0x40470000
    fmv.w.x f28, t0            /* 3.109375, same exp as pi */
    fsub.s f20, f27, f28       /* small normal result, renormalized */
    fmv.x.w t1, f20
    fsub.s f20, f17, f9        /* (min_normal+1ulp)-min_normal -> min subnormal 0x1 */
    fmv.x.w t1, f20
    frflags t2
    li t0, 0x00800002
    fmv.w.x f29, t0
    fsub.s f20, f29, f17       /* subnormal-underflow from equal-exp normals */
    fmv.x.w t1, f20
    li t0, 0x00600000
    fmv.w.x f29, t0            /* subnormal */
    li t0, 0x00200000
    fmv.w.x f30, t0            /* subnormal, same (zero) exp */
    fsub.s f20, f29, f30       /* subnormal-subnormal exact */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0

    /* ==== F2: overflow ladder per rm (max+max) ==== */
    fadd.s f20, f8, f8, rne    /* -> +inf, OF+NX */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fadd.s f20, f8, f8, rtz    /* -> max normal, OF+NX */
    fmv.x.w t1, f20
    fadd.s f20, f8, f8, rdn    /* -> max normal */
    fmv.x.w t1, f20
    fadd.s f20, f8, f8, rup    /* -> +inf */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0

    /* ==== F2: subnormal arithmetic ==== */
    fsub.s f20, f9, f10        /* min_normal - min_sub -> max subnormal, exact */
    fmv.x.w t1, f20
    frflags t2
    fadd.s f20, f10, f10       /* 2*min_sub, exact subnormal */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0

    /* ==== F2: fmul ==== */
    fmul.s f20, f2, f16        /* 6.0 exact */
    fmv.x.w t1, f20
    frflags t2
    fmul.s f20, f11, f4        /* 0 * inf -> qNaN, NV */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fmul.s f20, f12, f2        /* -0 * 2 -> -0 */
    fmv.x.w t1, f20
    fmul.s f20, f8, f2, rne    /* overflow -> inf OF+NX */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fmul.s f20, f8, f2, rtz    /* -> max normal */
    fmv.x.w t1, f20
    fmul.s f20, f17, f15       /* (min_normal+ulp)*0.5 -> inexact subnormal: UF+NX */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fmul.s f20, f9, f15        /* min_normal*0.5 -> exact subnormal: clean */
    fmv.x.w t1, f20
    frflags t2
    fmul.s f20, f13, f13       /* 1e60 -> inf, OF+NX */
    fmv.x.w t1, f20
    fmul.s f20, f14, f14       /* 1e-60 -> subnormal/zero, UF+NX */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0
    fmul.s f20, f14, f14, rup  /* underflow rounds up to min_sub */
    fmv.x.w t1, f20
    frflags t2
    csrw fflags, x0

    /* ==== F3: FMA fused-vs-split ==== */
    fmadd.s f21, f13, f14, f1  /* 1e30*1e-30 + 1.0: single rounding */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fmadd.s f21, f14, f14, f1  /* tiny product folded into sticky of 1.0 */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fmsub.s f21, f2, f16, f1   /* 2*3-1 = 5 */
    fmv.x.w t1, f21
    fnmadd.s f21, f1, f2, f16  /* -(1*2)-3 = -5 */
    fmv.x.w t1, f21
    fnmsub.s f21, f1, f2, f16  /* -(1*2)+3 = 1 */
    fmv.x.w t1, f21
    frflags t2
    fmadd.s f21, f11, f4, f6   /* 0*inf + qNaN -> NV */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fmadd.s f21, f4, f1, f5    /* inf*1 + -inf -> qNaN NV */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fmsub.s f21, f13, f13, f4  /* of-product - inf -> -inf (no NV: product not NaN) */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fmadd.s f21, f8, f2, f5    /* huge product + -inf -> -inf clean */
    fmv.x.w t1, f21
    frflags t2
    fmadd.s f21, f19, f19, f3  /* 2.25 + 2^-24: alignment + sticky */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fnmadd.s f21, f12, f2, f11 /* -(-0*2)-(+0) = +0-+0 = +0 (rne) */
    fmv.x.w t1, f21
    fmadd.s f21, f9, f15, f10  /* subnormal-range fused result */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0
    fmadd.s f21, f8, f8, f5    /* max*max + -inf -> -inf, clean (fused, no OF) */
    fmv.x.w t1, f21
    frflags t2
    csrw fflags, x0

    /* ==== F4: fdiv ==== */
    fdiv.s f22, f1, f16        /* 1/3 NX */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f1, f16, rtz
    fmv.x.w t1, f22
    fdiv.s f22, f1, f16, rup
    fmv.x.w t1, f22
    fdiv.s f22, f2, f2         /* exact 1.0, clean */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f1, f11        /* 1/0 -> +inf DZ */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f18, f11       /* -1/0 -> -inf DZ */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f11, f11       /* 0/0 -> qNaN NV */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f4, f4         /* inf/inf -> qNaN NV */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f4, f2         /* inf/2 -> inf clean */
    fmv.x.w t1, f22
    fdiv.s f22, f2, f4         /* 2/inf -> +0 clean */
    fmv.x.w t1, f22
    frflags t2
    fdiv.s f22, f1, f8         /* 1/max -> subnormal quotient UF+NX */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f8, f15        /* max/0.5 -> inf OF+NX */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f10, f2        /* min_sub/2 -> rounds to 0 or stays: UF path */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0
    fdiv.s f22, f7, f1         /* sNaN/1 -> canonical + NV */
    fmv.x.w t1, f22
    frflags t2
    csrw fflags, x0

    /* ==== F4: fsqrt ==== */
    fsqrt.s f23, f2            /* sqrt(2) NX */
    fmv.x.w t1, f23
    frflags t2
    csrw fflags, x0
    li t0, 0x40800000
    fmv.w.x f24, t0
    fsqrt.s f23, f24           /* sqrt(4)=2 exact clean */
    fmv.x.w t1, f23
    frflags t2
    fsqrt.s f23, f18           /* sqrt(-1) -> qNaN NV */
    fmv.x.w t1, f23
    frflags t2
    csrw fflags, x0
    fsqrt.s f23, f12           /* sqrt(-0) -> -0 clean */
    fmv.x.w t1, f23
    frflags t2
    fsqrt.s f23, f4            /* sqrt(+inf) -> +inf clean */
    fmv.x.w t1, f23
    fsqrt.s f23, f10           /* sqrt(min subnormal) NX */
    fmv.x.w t1, f23
    frflags t2
    csrw fflags, x0
    fsqrt.s f23, f9            /* sqrt(min normal) NX */
    fmv.x.w t1, f23
    frflags t2
    csrw fflags, x0
    fsqrt.s f23, f7            /* sqrt(sNaN) -> canonical NV */
    fmv.x.w t1, f23
    frflags t2
    csrw fflags, x0
    fsqrt.s f23, f2, rup       /* sqrt(2) rounded up */
    fmv.x.w t1, f23
    fsqrt.s f23, f2, rtz
    fmv.x.w t1, f23
    frflags t2
    csrw fflags, x0

    /* final fcsr snapshot */
    csrr t3, fcsr
    csrr t4, mstatus
    ebreak

.section .data
data_area:
    .space 64
