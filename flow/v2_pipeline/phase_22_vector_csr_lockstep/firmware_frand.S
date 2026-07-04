.section .init
.global _start
_start:
    li   t0, 0x2200
    csrs mstatus, t0
    /* float-random seed=12345 blocks=40 */
    li   t0, 3
    csrw frm, t0
    li   t1, 2155872255
    fmv.w.x f24, t1
    li   t1, 13136628
    fmv.w.x f28, t1
    li   t1, 3212836864
    fmv.w.x f14, t1
    fmul.s f9, f14, f28
    fmv.x.w t2, f9
    csrr t3, fflags
    fsub.s f6, f9, f28
    fmv.x.w t2, f6
    csrr t3, fflags
    fadd.s f5, f6, f9
    fmv.x.w t2, f5
    csrr t3, fflags
    fadd.s f11, f9, f5
    fmv.x.w t2, f11
    csrr t3, fflags
    fdiv.s f23, f5, f5
    fmv.x.w t2, f23
    csrr t3, fflags
    fadd.s f28, f9, f14
    fmv.x.w t2, f28
    csrr t3, fflags
    fmul.s f21, f9, f24
    fmv.x.w t2, f21
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 3542634833
    fmv.w.x f20, t1
    li   t1, 997755750
    fmv.w.x f11, t1
    li   t1, 929346862
    fmv.w.x f4, t1
    fmsub.s f9, f23, f6, f4
    fmv.x.w t2, f9
    csrr t3, fflags
    fsqrt.s f10, f4
    fmv.x.w t2, f10
    csrr t3, fflags
    fmul.s f12, f6, f14
    fmv.x.w t2, f12
    csrr t3, fflags
    fadd.s f1, f24, f14
    fmv.x.w t2, f1
    csrr t3, fflags
    fsqrt.s f13, f5
    fmv.x.w t2, f13
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 2
    csrw frm, t0
    li   t1, 3269581508
    fmv.w.x f7, t1
    li   t1, 5252140
    fmv.w.x f4, t1
    li   t1, 1056964608
    fmv.w.x f16, t1
    fdiv.s f12, f6, f7
    fmv.x.w t2, f12
    csrr t3, fflags
    fadd.s f16, f14, f11
    fmv.x.w t2, f16
    csrr t3, fflags
    fadd.s f6, f7, f5
    fmv.x.w t2, f6
    csrr t3, fflags
    fadd.s f23, f1, f24
    fmv.x.w t2, f23
    csrr t3, fflags
    fnmsub.s f27, f6, f12, f28
    fmv.x.w t2, f27
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 1979401237
    fmv.w.x f26, t1
    li   t1, 4286578688
    fmv.w.x f14, t1
    li   t1, 9880541
    fmv.w.x f1, t1
    fnmsub.s f19, f26, f11, f21
    fmv.x.w t2, f19
    csrr t3, fflags
    fadd.s f11, f21, f10
    fmv.x.w t2, f11
    csrr t3, fflags
    fadd.s f19, f7, f24
    fmv.x.w t2, f19
    csrr t3, fflags
    fmul.s f11, f7, f26
    fmv.x.w t2, f11
    csrr t3, fflags
    fdiv.s f23, f4, f12
    fmv.x.w t2, f23
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2301680987
    fmv.w.x f12, t1
    li   t1, 1065353216
    fmv.w.x f19, t1
    li   t1, 3213133210
    fmv.w.x f5, t1
    fmul.s f24, f16, f19
    fmv.x.w t2, f24
    csrr t3, fflags
    fmadd.s f15, f13, f23, f23
    fmv.x.w t2, f15
    csrr t3, fflags
    fmul.s f9, f11, f15
    fmv.x.w t2, f9
    csrr t3, fflags
    fmadd.s f1, f28, f5, f1
    fmv.x.w t2, f1
    csrr t3, fflags
    fsqrt.s f20, f16
    fmv.x.w t2, f20
    csrr t3, fflags
    fsub.s f9, f13, f14
    fmv.x.w t2, f9
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2147483648
    fmv.w.x f20, t1
    li   t1, 1065353216
    fmv.w.x f14, t1
    li   t1, 997489600
    fmv.w.x f5, t1
    fadd.s f14, f7, f6
    fmv.x.w t2, f14
    csrr t3, fflags
    fdiv.s f2, f14, f16
    fmv.x.w t2, f2
    csrr t3, fflags
    fadd.s f28, f5, f20
    fmv.x.w t2, f28
    csrr t3, fflags
    fadd.s f19, f24, f23
    fmv.x.w t2, f19
    csrr t3, fflags
    fsqrt.s f6, f12
    fmv.x.w t2, f6
    csrr t3, fflags
    fmul.s f4, f23, f21
    fmv.x.w t2, f4
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 3
    csrw frm, t0
    li   t1, 2147483649
    fmv.w.x f17, t1
    li   t1, 1397402968
    fmv.w.x f5, t1
    li   t1, 3865468554
    fmv.w.x f19, t1
    fmul.s f15, f1, f14
    fmv.x.w t2, f15
    csrr t3, fflags
    fdiv.s f1, f14, f27
    fmv.x.w t2, f1
    csrr t3, fflags
    fmadd.s f22, f13, f19, f17
    fmv.x.w t2, f22
    csrr t3, fflags
    fsub.s f11, f12, f6
    fmv.x.w t2, f11
    csrr t3, fflags
    fmadd.s f19, f22, f5, f19
    fmv.x.w t2, f19
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2147483648
    fmv.w.x f20, t1
    li   t1, 2255177236
    fmv.w.x f10, t1
    li   t1, 2125869191
    fmv.w.x f4, t1
    fsub.s f29, f28, f7
    fmv.x.w t2, f29
    csrr t3, fflags
    fmul.s f19, f26, f19
    fmv.x.w t2, f19
    csrr t3, fflags
    fadd.s f29, f22, f21
    fmv.x.w t2, f29
    csrr t3, fflags
    fadd.s f7, f28, f17
    fmv.x.w t2, f7
    csrr t3, fflags
    fmadd.s f1, f4, f29, f4
    fmv.x.w t2, f1
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 917364322
    fmv.w.x f9, t1
    li   t1, 2139095039
    fmv.w.x f9, t1
    li   t1, 2848277575
    fmv.w.x f24, t1
    fsub.s f18, f17, f20
    fmv.x.w t2, f18
    csrr t3, fflags
    fadd.s f17, f20, f24
    fmv.x.w t2, f17
    csrr t3, fflags
    fsub.s f8, f24, f4
    fmv.x.w t2, f8
    csrr t3, fflags
    fadd.s f15, f9, f16
    fmv.x.w t2, f15
    csrr t3, fflags
    fmul.s f14, f7, f8
    fmv.x.w t2, f14
    csrr t3, fflags
    fsqrt.s f20, f14
    fmv.x.w t2, f20
    csrr t3, fflags
    fmadd.s f29, f28, f7, f22
    fmv.x.w t2, f29
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 102027018
    fmv.w.x f24, t1
    li   t1, 3859597985
    fmv.w.x f26, t1
    li   t1, 865947338
    fmv.w.x f11, t1
    fnmadd.s f1, f13, f8, f19
    fmv.x.w t2, f1
    csrr t3, fflags
    fadd.s f8, f28, f8
    fmv.x.w t2, f8
    csrr t3, fflags
    fadd.s f18, f6, f20
    fmv.x.w t2, f18
    csrr t3, fflags
    fsqrt.s f26, f6
    fmv.x.w t2, f26
    csrr t3, fflags
    fdiv.s f5, f21, f11
    fmv.x.w t2, f5
    csrr t3, fflags
    fadd.s f10, f15, f14
    fmv.x.w t2, f10
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 2750574613
    fmv.w.x f13, t1
    li   t1, 1890466964
    fmv.w.x f24, t1
    li   t1, 1202505984
    fmv.w.x f19, t1
    fadd.s f18, f17, f24
    fmv.x.w t2, f18
    csrr t3, fflags
    fadd.s f21, f15, f2
    fmv.x.w t2, f21
    csrr t3, fflags
    fnmadd.s f4, f29, f5, f10
    fmv.x.w t2, f4
    csrr t3, fflags
    fmul.s f29, f14, f17
    fmv.x.w t2, f29
    csrr t3, fflags
    fmsub.s f13, f5, f26, f15
    fmv.x.w t2, f13
    csrr t3, fflags
    fadd.s f20, f16, f6
    fmv.x.w t2, f20
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 1
    fmv.w.x f12, t1
    li   t1, 22039082
    fmv.w.x f5, t1
    li   t1, 2147483648
    fmv.w.x f20, t1
    fnmsub.s f8, f16, f1, f13
    fmv.x.w t2, f8
    csrr t3, fflags
    fadd.s f16, f27, f27
    fmv.x.w t2, f16
    csrr t3, fflags
    fmsub.s f28, f20, f29, f11
    fmv.x.w t2, f28
    csrr t3, fflags
    fmul.s f16, f1, f16
    fmv.x.w t2, f16
    csrr t3, fflags
    fsub.s f12, f17, f9
    fmv.x.w t2, f12
    csrr t3, fflags
    fsub.s f17, f11, f29
    fmv.x.w t2, f17
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 1557879
    fmv.w.x f29, t1
    li   t1, 3212836864
    fmv.w.x f18, t1
    li   t1, 18458360
    fmv.w.x f25, t1
    fadd.s f1, f10, f20
    fmv.x.w t2, f1
    csrr t3, fflags
    fmul.s f21, f10, f21
    fmv.x.w t2, f21
    csrr t3, fflags
    fsub.s f10, f14, f1
    fmv.x.w t2, f10
    csrr t3, fflags
    fmsub.s f4, f16, f22, f12
    fmv.x.w t2, f4
    csrr t3, fflags
    fadd.s f9, f23, f11
    fmv.x.w t2, f9
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2147483649
    fmv.w.x f17, t1
    li   t1, 906199588
    fmv.w.x f7, t1
    li   t1, 2139095039
    fmv.w.x f28, t1
    fsqrt.s f3, f6
    fmv.x.w t2, f3
    csrr t3, fflags
    fmsub.s f8, f2, f26, f27
    fmv.x.w t2, f8
    csrr t3, fflags
    fadd.s f1, f13, f14
    fmv.x.w t2, f1
    csrr t3, fflags
    fadd.s f14, f5, f22
    fmv.x.w t2, f14
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 6272824
    fmv.w.x f5, t1
    li   t1, 96326954
    fmv.w.x f3, t1
    li   t1, 1521827340
    fmv.w.x f3, t1
    fsub.s f12, f7, f10
    fmv.x.w t2, f12
    csrr t3, fflags
    fsub.s f18, f3, f11
    fmv.x.w t2, f18
    csrr t3, fflags
    fmul.s f9, f18, f6
    fmv.x.w t2, f9
    csrr t3, fflags
    fadd.s f23, f1, f15
    fmv.x.w t2, f23
    csrr t3, fflags
    fsqrt.s f29, f5
    fmv.x.w t2, f29
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 1086019243
    fmv.w.x f18, t1
    li   t1, 0
    fmv.w.x f23, t1
    li   t1, 3055693802
    fmv.w.x f17, t1
    fadd.s f18, f4, f29
    fmv.x.w t2, f18
    csrr t3, fflags
    fmul.s f21, f15, f26
    fmv.x.w t2, f21
    csrr t3, fflags
    fadd.s f6, f27, f19
    fmv.x.w t2, f6
    csrr t3, fflags
    fadd.s f26, f5, f25
    fmv.x.w t2, f26
    csrr t3, fflags
    fmul.s f2, f4, f13
    fmv.x.w t2, f2
    csrr t3, fflags
    fadd.s f10, f17, f8
    fmv.x.w t2, f10
    csrr t3, fflags
    fadd.s f24, f4, f14
    fmv.x.w t2, f24
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 2
    csrw frm, t0
    li   t1, 2882833139
    fmv.w.x f8, t1
    li   t1, 2397518535
    fmv.w.x f11, t1
    li   t1, 3375806094
    fmv.w.x f26, t1
    fsub.s f7, f10, f1
    fmv.x.w t2, f7
    csrr t3, fflags
    fsqrt.s f29, f23
    fmv.x.w t2, f29
    csrr t3, fflags
    fmul.s f15, f4, f16
    fmv.x.w t2, f15
    csrr t3, fflags
    fmsub.s f8, f12, f6, f17
    fmv.x.w t2, f8
    csrr t3, fflags
    fsqrt.s f8, f3
    fmv.x.w t2, f8
    csrr t3, fflags
    fdiv.s f19, f26, f18
    fmv.x.w t2, f19
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 0
    fmv.w.x f5, t1
    li   t1, 554010699
    fmv.w.x f27, t1
    li   t1, 3252181464
    fmv.w.x f1, t1
    fadd.s f9, f18, f10
    fmv.x.w t2, f9
    csrr t3, fflags
    fadd.s f27, f20, f19
    fmv.x.w t2, f27
    csrr t3, fflags
    fnmsub.s f11, f1, f1, f21
    fmv.x.w t2, f11
    csrr t3, fflags
    fsub.s f4, f3, f3
    fmv.x.w t2, f4
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 4194304
    fmv.w.x f15, t1
    li   t1, 2721351340
    fmv.w.x f24, t1
    li   t1, 1077188021
    fmv.w.x f27, t1
    fnmsub.s f14, f12, f23, f8
    fmv.x.w t2, f14
    csrr t3, fflags
    fmul.s f1, f4, f23
    fmv.x.w t2, f1
    csrr t3, fflags
    fdiv.s f29, f12, f4
    fmv.x.w t2, f29
    csrr t3, fflags
    fadd.s f9, f7, f1
    fmv.x.w t2, f9
    csrr t3, fflags
    fmsub.s f13, f18, f16, f21
    fmv.x.w t2, f13
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 0
    fmv.w.x f24, t1
    li   t1, 4286578687
    fmv.w.x f5, t1
    li   t1, 808626444
    fmv.w.x f8, t1
    fadd.s f22, f19, f15
    fmv.x.w t2, f22
    csrr t3, fflags
    fsub.s f17, f13, f14
    fmv.x.w t2, f17
    csrr t3, fflags
    fadd.s f14, f21, f23
    fmv.x.w t2, f14
    csrr t3, fflags
    fsub.s f4, f1, f10
    fmv.x.w t2, f4
    csrr t3, fflags
    fmul.s f2, f18, f27
    fmv.x.w t2, f2
    csrr t3, fflags
    fdiv.s f4, f17, f15
    fmv.x.w t2, f4
    csrr t3, fflags
    fadd.s f26, f2, f3
    fmv.x.w t2, f26
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 2434610622
    fmv.w.x f15, t1
    li   t1, 8388608
    fmv.w.x f15, t1
    li   t1, 1077208626
    fmv.w.x f28, t1
    fmsub.s f9, f14, f3, f6
    fmv.x.w t2, f9
    csrr t3, fflags
    fmul.s f16, f25, f19
    fmv.x.w t2, f16
    csrr t3, fflags
    fsub.s f3, f18, f11
    fmv.x.w t2, f3
    csrr t3, fflags
    fmul.s f26, f18, f26
    fmv.x.w t2, f26
    csrr t3, fflags
    fdiv.s f23, f12, f23
    fmv.x.w t2, f23
    csrr t3, fflags
    fadd.s f11, f15, f28
    fmv.x.w t2, f11
    csrr t3, fflags
    fdiv.s f15, f15, f24
    fmv.x.w t2, f15
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 3214870074
    fmv.w.x f7, t1
    li   t1, 23643802
    fmv.w.x f27, t1
    li   t1, 417382190
    fmv.w.x f14, t1
    fsub.s f23, f22, f15
    fmv.x.w t2, f23
    csrr t3, fflags
    fadd.s f25, f26, f22
    fmv.x.w t2, f25
    csrr t3, fflags
    fadd.s f22, f12, f19
    fmv.x.w t2, f22
    csrr t3, fflags
    fadd.s f21, f26, f1
    fmv.x.w t2, f21
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 3
    csrw frm, t0
    li   t1, 862327568
    fmv.w.x f17, t1
    li   t1, 1364066983
    fmv.w.x f23, t1
    li   t1, 2141192193
    fmv.w.x f27, t1
    fsqrt.s f15, f1
    fmv.x.w t2, f15
    csrr t3, fflags
    fnmsub.s f29, f8, f26, f28
    fmv.x.w t2, f29
    csrr t3, fflags
    fadd.s f24, f2, f23
    fmv.x.w t2, f24
    csrr t3, fflags
    fadd.s f15, f15, f17
    fmv.x.w t2, f15
    csrr t3, fflags
    fmsub.s f12, f11, f1, f4
    fmv.x.w t2, f12
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 3212836864
    fmv.w.x f28, t1
    li   t1, 2485125698
    fmv.w.x f11, t1
    li   t1, 2147483649
    fmv.w.x f29, t1
    fsub.s f7, f14, f7
    fmv.x.w t2, f7
    csrr t3, fflags
    fadd.s f7, f21, f6
    fmv.x.w t2, f7
    csrr t3, fflags
    fadd.s f12, f4, f21
    fmv.x.w t2, f12
    csrr t3, fflags
    fsub.s f5, f25, f8
    fmv.x.w t2, f5
    csrr t3, fflags
    fmul.s f28, f25, f16
    fmv.x.w t2, f28
    csrr t3, fflags
    fsub.s f1, f16, f11
    fmv.x.w t2, f1
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2147483649
    fmv.w.x f29, t1
    li   t1, 3217277732
    fmv.w.x f22, t1
    li   t1, 3299583838
    fmv.w.x f12, t1
    fadd.s f1, f20, f6
    fmv.x.w t2, f1
    csrr t3, fflags
    fsqrt.s f8, f24
    fmv.x.w t2, f8
    csrr t3, fflags
    fadd.s f15, f22, f26
    fmv.x.w t2, f15
    csrr t3, fflags
    fmul.s f29, f19, f19
    fmv.x.w t2, f29
    csrr t3, fflags
    fsub.s f26, f19, f14
    fmv.x.w t2, f26
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 2
    csrw frm, t0
    li   t1, 2526299691
    fmv.w.x f17, t1
    li   t1, 863032852
    fmv.w.x f4, t1
    li   t1, 588325191
    fmv.w.x f20, t1
    fnmsub.s f14, f28, f23, f7
    fmv.x.w t2, f14
    csrr t3, fflags
    fadd.s f11, f29, f12
    fmv.x.w t2, f11
    csrr t3, fflags
    fsub.s f5, f8, f15
    fmv.x.w t2, f5
    csrr t3, fflags
    fsqrt.s f23, f14
    fmv.x.w t2, f23
    csrr t3, fflags
    fnmsub.s f16, f27, f10, f8
    fmv.x.w t2, f16
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2160757411
    fmv.w.x f8, t1
    li   t1, 2136804818
    fmv.w.x f21, t1
    li   t1, 1068943286
    fmv.w.x f9, t1
    fadd.s f16, f9, f11
    fmv.x.w t2, f16
    csrr t3, fflags
    fadd.s f25, f23, f1
    fmv.x.w t2, f25
    csrr t3, fflags
    fmsub.s f1, f12, f5, f6
    fmv.x.w t2, f1
    csrr t3, fflags
    fsub.s f22, f17, f29
    fmv.x.w t2, f22
    csrr t3, fflags
    fmul.s f3, f19, f3
    fmv.x.w t2, f3
    csrr t3, fflags
    fsqrt.s f13, f29
    fmv.x.w t2, f13
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 324683280
    fmv.w.x f19, t1
    li   t1, 2130706432
    fmv.w.x f22, t1
    li   t1, 3849990222
    fmv.w.x f6, t1
    fadd.s f11, f7, f8
    fmv.x.w t2, f11
    csrr t3, fflags
    fmsub.s f27, f28, f20, f24
    fmv.x.w t2, f27
    csrr t3, fflags
    fnmsub.s f21, f4, f21, f23
    fmv.x.w t2, f21
    csrr t3, fflags
    fnmsub.s f5, f27, f23, f28
    fmv.x.w t2, f5
    csrr t3, fflags
    fsub.s f23, f26, f3
    fmv.x.w t2, f23
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 2
    csrw frm, t0
    li   t1, 18440329
    fmv.w.x f11, t1
    li   t1, 1075983379
    fmv.w.x f9, t1
    li   t1, 27178745
    fmv.w.x f12, t1
    fsqrt.s f14, f17
    fmv.x.w t2, f14
    csrr t3, fflags
    fmul.s f1, f3, f17
    fmv.x.w t2, f1
    csrr t3, fflags
    fadd.s f25, f13, f25
    fmv.x.w t2, f25
    csrr t3, fflags
    fadd.s f27, f12, f24
    fmv.x.w t2, f27
    csrr t3, fflags
    fmul.s f3, f12, f14
    fmv.x.w t2, f3
    csrr t3, fflags
    fmul.s f11, f25, f1
    fmv.x.w t2, f11
    csrr t3, fflags
    fsub.s f17, f28, f27
    fmv.x.w t2, f17
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 3
    csrw frm, t0
    li   t1, 1355774992
    fmv.w.x f18, t1
    li   t1, 8388608
    fmv.w.x f18, t1
    li   t1, 1287757616
    fmv.w.x f26, t1
    fdiv.s f16, f2, f13
    fmv.x.w t2, f16
    csrr t3, fflags
    fsqrt.s f10, f23
    fmv.x.w t2, f10
    csrr t3, fflags
    fmadd.s f28, f3, f26, f28
    fmv.x.w t2, f28
    csrr t3, fflags
    fsub.s f24, f9, f28
    fmv.x.w t2, f24
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 3
    csrw frm, t0
    li   t1, 4284509243
    fmv.w.x f1, t1
    li   t1, 3629704435
    fmv.w.x f28, t1
    li   t1, 2147483648
    fmv.w.x f29, t1
    fmsub.s f4, f28, f3, f8
    fmv.x.w t2, f4
    csrr t3, fflags
    fsqrt.s f1, f25
    fmv.x.w t2, f1
    csrr t3, fflags
    fadd.s f21, f12, f21
    fmv.x.w t2, f21
    csrr t3, fflags
    fsub.s f3, f25, f13
    fmv.x.w t2, f3
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 2130706432
    fmv.w.x f15, t1
    li   t1, 3235024812
    fmv.w.x f16, t1
    li   t1, 2162754351
    fmv.w.x f7, t1
    fmul.s f26, f10, f15
    fmv.x.w t2, f26
    csrr t3, fflags
    fdiv.s f13, f26, f17
    fmv.x.w t2, f13
    csrr t3, fflags
    fmadd.s f25, f13, f14, f18
    fmv.x.w t2, f25
    csrr t3, fflags
    fdiv.s f1, f28, f4
    fmv.x.w t2, f1
    csrr t3, fflags
    fsub.s f26, f9, f21
    fmv.x.w t2, f26
    csrr t3, fflags
    fdiv.s f17, f23, f14
    fmv.x.w t2, f17
    csrr t3, fflags
    fnmadd.s f15, f9, f3, f13
    fmv.x.w t2, f15
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 2
    csrw frm, t0
    li   t1, 4282637676
    fmv.w.x f26, t1
    li   t1, 16458843
    fmv.w.x f11, t1
    li   t1, 1029378818
    fmv.w.x f19, t1
    fdiv.s f28, f25, f4
    fmv.x.w t2, f28
    csrr t3, fflags
    fsub.s f7, f19, f5
    fmv.x.w t2, f7
    csrr t3, fflags
    fadd.s f26, f21, f20
    fmv.x.w t2, f26
    csrr t3, fflags
    fnmsub.s f28, f17, f22, f1
    fmv.x.w t2, f28
    csrr t3, fflags
    fnmadd.s f22, f16, f3, f6
    fmv.x.w t2, f22
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 3135608848
    fmv.w.x f7, t1
    li   t1, 15159641
    fmv.w.x f24, t1
    li   t1, 3222532239
    fmv.w.x f5, t1
    fadd.s f12, f1, f6
    fmv.x.w t2, f12
    csrr t3, fflags
    fadd.s f19, f28, f2
    fmv.x.w t2, f19
    csrr t3, fflags
    fdiv.s f24, f6, f11
    fmv.x.w t2, f24
    csrr t3, fflags
    fmadd.s f29, f11, f27, f3
    fmv.x.w t2, f29
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 1642081208
    fmv.w.x f23, t1
    li   t1, 1077321263
    fmv.w.x f5, t1
    li   t1, 4286578688
    fmv.w.x f28, t1
    fadd.s f27, f13, f18
    fmv.x.w t2, f27
    csrr t3, fflags
    fsub.s f29, f23, f13
    fmv.x.w t2, f29
    csrr t3, fflags
    fadd.s f2, f9, f20
    fmv.x.w t2, f2
    csrr t3, fflags
    fadd.s f9, f14, f25
    fmv.x.w t2, f9
    csrr t3, fflags
    fmul.s f26, f2, f27
    fmv.x.w t2, f26
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 2
    csrw frm, t0
    li   t1, 1075454653
    fmv.w.x f18, t1
    li   t1, 2169378659
    fmv.w.x f8, t1
    li   t1, 1066154034
    fmv.w.x f13, t1
    fsqrt.s f22, f11
    fmv.x.w t2, f22
    csrr t3, fflags
    fmul.s f26, f4, f17
    fmv.x.w t2, f26
    csrr t3, fflags
    fadd.s f25, f24, f13
    fmv.x.w t2, f25
    csrr t3, fflags
    fsub.s f3, f5, f12
    fmv.x.w t2, f3
    csrr t3, fflags
    fmul.s f2, f29, f10
    fmv.x.w t2, f2
    csrr t3, fflags
    fmul.s f7, f22, f26
    fmv.x.w t2, f7
    csrr t3, fflags
    fsqrt.s f21, f27
    fmv.x.w t2, f21
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 4
    csrw frm, t0
    li   t1, 4201127923
    fmv.w.x f6, t1
    li   t1, 621819386
    fmv.w.x f10, t1
    li   t1, 4284499114
    fmv.w.x f11, t1
    fmadd.s f7, f17, f2, f14
    fmv.x.w t2, f7
    csrr t3, fflags
    fsqrt.s f1, f2
    fmv.x.w t2, f1
    csrr t3, fflags
    fdiv.s f9, f24, f9
    fmv.x.w t2, f9
    csrr t3, fflags
    fsub.s f29, f16, f13
    fmv.x.w t2, f29
    csrr t3, fflags
    fadd.s f8, f2, f17
    fmv.x.w t2, f8
    csrr t3, fflags
    fdiv.s f23, f5, f11
    fmv.x.w t2, f23
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 3
    csrw frm, t0
    li   t1, 2147483648
    fmv.w.x f18, t1
    li   t1, 2147483649
    fmv.w.x f7, t1
    li   t1, 2147483649
    fmv.w.x f19, t1
    fadd.s f24, f16, f2
    fmv.x.w t2, f24
    csrr t3, fflags
    fmadd.s f19, f7, f26, f22
    fmv.x.w t2, f19
    csrr t3, fflags
    fadd.s f13, f24, f9
    fmv.x.w t2, f13
    csrr t3, fflags
    fsub.s f4, f2, f27
    fmv.x.w t2, f4
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 1
    csrw frm, t0
    li   t1, 2147483649
    fmv.w.x f26, t1
    li   t1, 1657943330
    fmv.w.x f25, t1
    li   t1, 4070235835
    fmv.w.x f26, t1
    fsqrt.s f1, f19
    fmv.x.w t2, f1
    csrr t3, fflags
    fmul.s f18, f1, f15
    fmv.x.w t2, f18
    csrr t3, fflags
    fdiv.s f29, f20, f11
    fmv.x.w t2, f29
    csrr t3, fflags
    fmul.s f25, f26, f23
    fmv.x.w t2, f25
    csrr t3, fflags
    fmul.s f2, f24, f10
    fmv.x.w t2, f2
    csrr t3, fflags
    csrw fflags, x0
    li   t0, 0
    csrw frm, t0
    li   t1, 435308176
    fmv.w.x f15, t1
    li   t1, 3510636237
    fmv.w.x f27, t1
    li   t1, 2132551346
    fmv.w.x f28, t1
    fadd.s f3, f13, f28
    fmv.x.w t2, f3
    csrr t3, fflags
    fnmadd.s f3, f16, f12, f27
    fmv.x.w t2, f3
    csrr t3, fflags
    fsqrt.s f15, f16
    fmv.x.w t2, f15
    csrr t3, fflags
    fadd.s f5, f6, f24
    fmv.x.w t2, f5
    csrr t3, fflags
    fsub.s f9, f5, f25
    fmv.x.w t2, f9
    csrr t3, fflags
    fsub.s f8, f23, f14
    fmv.x.w t2, f8
    csrr t3, fflags
    csrw fflags, x0
    ebreak
