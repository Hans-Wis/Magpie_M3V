.section .init
.global _start
_start:
    /* vector-random seed=20260704 blocks=44 (3B+3C subset) */
    li   t0, 0x200
    csrs mstatus, t0
    la   x31, data_area
    li   t0, 1840814040
    sw   t0, 0(x31)
    li   t0, 1245529229
    sw   t0, 4(x31)
    li   t0, 319846652
    sw   t0, 8(x31)
    li   t0, 1193510886
    sw   t0, 12(x31)
    li   t0, 1195144413
    sw   t0, 16(x31)
    li   t0, 1760849799
    sw   t0, 20(x31)
    li   t0, 1220629866
    sw   t0, 24(x31)
    li   t0, 920650661
    sw   t0, 28(x31)
    li   t0, 273897149
    sw   t0, 32(x31)
    li   t0, 198566807
    sw   t0, 36(x31)
    li   t0, 563921998
    sw   t0, 40(x31)
    li   t0, 1963306362
    sw   t0, 44(x31)
    li   t0, 81133027
    sw   t0, 48(x31)
    li   t0, 821396671
    sw   t0, 52(x31)
    li   t0, 778478445
    sw   t0, 56(x31)
    li   t0, 735757266
    sw   t0, 60(x31)
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, -6
    li   x5, 158
    vmv.v.x v23, x5
    vsub.vv v6, v2, v23
    vadd.vi v23, v2, 7
    vadd.vv v16, v2, v2
    li   x7, 1879
    vadd.vx v2, v23, x7
    addi a1, x31, 34
    vse16.v v6, (a1)
    lw   x13, 32(x31)
    vmv.x.s x9, v2
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, 1635
    vmv.v.x v13, x14
    li   x5, -1774
    vmv.v.x v22, x5
    vadd.vi v13, v16, -7
    vadd.vv v3, v6, v16
    vsub.vv v14, v13, v3
    vsub.vv v13, v6, v16
    vadd.vv v6, v22, v6
    addi a1, x31, 12
    vse8.v v13, (a1)
    lw   x9, 12(x31)
    vmv.x.s x11, v23
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v19, -13
    vmv.v.i v4, 8
    vadd.vv v15, v14, v4
    vadd.vv v22, v4, v16
    vmv.v.i v0, -5
    vmerge.vvm v1, v2, v19, v0
    vmv.v.i v0, 1
    vmerge.vvm v8, v22, v1, v0
    vadd.vv v7, v4, v16
    addi a1, x31, 2
    vle8.v v15, (a1)
    vmv.x.s x11, v15
    vmv.x.s x7, v13
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -2008
    vmv.v.x v1, x10
    vmv.v.i v8, -5
    vmv.v.v v13, v19
    li   x11, 1513
    vadd.vx v4, v19, x11
    vmv.v.i v0, 0
    vmerge.vvm v19, v22, v1, v0
    vadd.vv v9, v23, v3
    vmv.v.i v0, 10
    vmerge.vvm v1, v13, v6, v0
    addi a1, x31, 42
    vse16.v v13, (a1)
    lw   x6, 40(x31)
    vmv.x.s x13, v4
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, -757
    vmv.v.x v2, x13
    vmv.v.i v8, -2
    vadd.vi v20, v16, 3
    vadd.vi v8, v19, 5
    vadd.vi v3, v9, -4
    li   x5, 774
    vsub.vx v11, v13, x5
    vadd.vi v17, v11, -14
    addi a1, x31, 30
    vse8.v v22, (a1)
    lw   x12, 28(x31)
    vmv.x.s x10, v6
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 1629
    vmv.v.x v5, x7
    vmv.v.i v11, -3
    vadd.vv v1, v14, v20
    li   x6, 952
    vadd.vx v11, v5, x6
    vadd.vv v7, v11, v6
    li   x13, -1165
    vadd.vx v19, v11, x13
    vsub.vv v1, v16, v15
    vadd.vv v19, v2, v16
    addi a1, x31, 36
    vse16.v v17, (a1)
    lw   x14, 36(x31)
    vmv.x.s x13, v23
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v20, 8
    li   x13, -1867
    vmv.v.x v20, x13
    vsub.vv v14, v13, v13
    vsub.vv v2, v9, v8
    vadd.vv v20, v15, v6
    vadd.vv v15, v22, v9
    addi a1, x31, 52
    vse16.v v23, (a1)
    lw   x11, 52(x31)
    vmv.x.s x14, v17
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v17, 7
    li   x10, 69
    vmv.v.x v22, x10
    vsub.vv v9, v20, v2
    li   x15, 1741
    vadd.vx v10, v11, x15
    vadd.vv v18, v23, v16
    addi a1, x31, 32
    vle32.v v16, (a1)
    vmv.x.s x8, v16
    vmv.x.s x12, v9
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v18, -5
    li   x14, 1554
    vmv.v.x v14, x14
    vadd.vv v20, v6, v9
    vadd.vv v5, v20, v19
    vadd.vv v9, v19, v6
    addi a1, x31, 29
    vse8.v v17, (a1)
    lw   x9, 28(x31)
    vmv.x.s x8, v20
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, 14
    li   x9, 767
    vmv.v.x v22, x9
    vsub.vv v8, v23, v8
    vmv.v.v v20, v2
    vmv.v.i v0, -8
    vmerge.vvm v10, v22, v23, v0
    vadd.vv v22, v13, v7
    vadd.vv v3, v10, v20
    addi a1, x31, 8
    vle16.v v15, (a1)
    vmv.x.s x13, v15
    vmv.x.s x11, v6
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, 508
    vmv.v.x v17, x6
    li   x13, 616
    vmv.v.x v22, x13
    vadd.vv v12, v14, v16
    li   x10, -393
    vadd.vx v8, v9, x10
    vadd.vv v13, v15, v10
    vmv.v.v v8, v22
    vmv.v.i v0, -9
    vmerge.vvm v18, v23, v18, v0
    addi a1, x31, 2
    vse8.v v14, (a1)
    lw   x7, 0(x31)
    vmv.x.s x5, v11
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -1626
    vmv.v.x v21, x11
    vmv.v.i v16, 8
    li   x6, 1222
    vadd.vx v7, v19, x6
    vmv.v.i v0, -15
    vmerge.vvm v7, v23, v1, v0
    vsub.vv v8, v5, v9
    vmv.v.i v0, -9
    vmerge.vvm v8, v3, v5, v0
    vadd.vv v20, v14, v15
    vadd.vi v13, v22, -9
    addi a1, x31, 4
    vle32.v v23, (a1)
    vmv.x.s x9, v23
    vmv.x.s x5, v10
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v4, -3
    vmv.v.i v22, 5
    vmv.v.v v10, v5
    li   x9, 329
    vsub.vx v2, v4, x9
    vmv.v.i v0, -2
    vmerge.vvm v17, v18, v14, v0
    vadd.vv v11, v17, v21
    vadd.vi v23, v1, -12
    addi a1, x31, 24
    vle32.v v16, (a1)
    vmv.x.s x5, v16
    vmv.x.s x8, v12
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v22, 13
    li   x5, 252
    vmv.v.x v23, x5
    vsub.vv v10, v13, v5
    vmv.v.i v0, -13
    vmerge.vvm v12, v14, v11, v0
    vadd.vv v16, v14, v16
    vadd.vv v5, v10, v22
    addi a1, x31, 2
    vse16.v v23, (a1)
    lw   x7, 0(x31)
    vmv.x.s x14, v12
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v13, -13
    li   x5, -1928
    vmv.v.x v23, x5
    vmv.v.v v18, v11
    vadd.vv v2, v9, v13
    vmv.v.v v13, v17
    vsub.vv v20, v20, v3
    vmv.v.i v0, 0
    vmerge.vvm v23, v18, v6, v0
    vadd.vv v3, v22, v20
    addi a1, x31, 38
    vse8.v v5, (a1)
    lw   x9, 36(x31)
    vmv.x.s x12, v2
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, 10
    vmv.v.i v15, -9
    vadd.vi v18, v11, -2
    vadd.vi v5, v8, 6
    vmv.v.i v0, -4
    vmerge.vvm v13, v17, v6, v0
    vmv.v.v v20, v11
    vsub.vv v16, v13, v20
    li   x15, -198
    vadd.vx v1, v17, x15
    addi a1, x31, 30
    vle8.v v10, (a1)
    vmv.x.s x6, v10
    vmv.x.s x14, v5
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, 1986
    vmv.v.x v7, x6
    li   x9, -26
    vmv.v.x v16, x9
    vsub.vv v15, v2, v20
    vmv.v.v v20, v16
    vsub.vv v22, v12, v9
    vadd.vi v6, v14, -6
    addi a1, x31, 40
    vle16.v v12, (a1)
    vmv.x.s x8, v12
    vmv.x.s x14, v19
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 1255
    vmv.v.x v11, x12
    vmv.v.i v18, 14
    vadd.vv v2, v17, v1
    vadd.vv v9, v13, v21
    li   x15, 1157
    vadd.vx v18, v19, x15
    vadd.vv v17, v16, v18
    li   x14, 599
    vsub.vx v18, v20, x14
    vsub.vv v1, v19, v10
    addi a1, x31, 40
    vse8.v v11, (a1)
    lw   x7, 40(x31)
    vmv.x.s x10, v13
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, 145
    vmv.v.x v17, x14
    li   x13, 671
    vmv.v.x v10, x13
    li   x6, -1174
    vadd.vx v9, v4, x6
    vmv.v.i v0, -12
    vmerge.vvm v5, v23, v2, v0
    vsub.vv v15, v3, v13
    addi a1, x31, 22
    vse8.v v6, (a1)
    lw   x7, 20(x31)
    vmv.x.s x15, v20
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 149
    vmv.v.x v8, x12
    li   x5, 1332
    vmv.v.x v12, x5
    li   x14, -1312
    vsub.vx v18, v20, x14
    vadd.vv v16, v10, v12
    vadd.vi v1, v10, -4
    vadd.vv v8, v20, v17
    addi a1, x31, 0
    vse8.v v3, (a1)
    lw   x10, 0(x31)
    vmv.x.s x15, v4
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -1295
    vmv.v.x v19, x10
    vmv.v.i v15, -12
    vadd.vv v18, v21, v12
    vsub.vv v12, v10, v4
    vadd.vv v20, v15, v10
    vmv.v.i v0, -3
    vmerge.vvm v1, v11, v16, v0
    vadd.vv v11, v5, v11
    addi a1, x31, 33
    vse8.v v7, (a1)
    lw   x12, 32(x31)
    vmv.x.s x9, v6
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, 655
    vmv.v.x v2, x15
    li   x6, 114
    vmv.v.x v16, x6
    li   x14, -1669
    vsub.vx v5, v9, x14
    vadd.vv v7, v7, v8
    vsub.vv v3, v4, v9
    li   x14, 810
    vadd.vx v12, v22, x14
    vmv.v.i v0, -11
    vmerge.vvm v18, v7, v4, v0
    vmv.v.i v0, 4
    vmerge.vvm v17, v6, v14, v0
    addi a1, x31, 2
    vse16.v v4, (a1)
    lw   x5, 0(x31)
    vmv.x.s x10, v20
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -349
    vmv.v.x v15, x6
    vmv.v.i v21, 8
    vmv.v.v v23, v16
    vadd.vv v19, v3, v15
    vmv.v.v v4, v1
    vadd.vv v6, v16, v4
    vmv.v.v v9, v7
    vmv.v.i v0, 13
    vmerge.vvm v17, v6, v16, v0
    addi a1, x31, 26
    vle16.v v5, (a1)
    vmv.x.s x7, v5
    vmv.x.s x5, v8
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -1549
    vmv.v.x v9, x11
    vmv.v.i v5, -4
    vadd.vv v7, v21, v14
    vadd.vv v17, v7, v3
    vadd.vv v18, v21, v4
    vsub.vv v10, v15, v4
    vadd.vv v21, v17, v1
    addi a1, x31, 9
    vse8.v v21, (a1)
    lw   x13, 8(x31)
    vmv.x.s x6, v19
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -669
    vmv.v.x v7, x8
    vmv.v.i v23, 6
    vmv.v.v v19, v14
    vmv.v.v v11, v8
    li   x7, 334
    vsub.vx v6, v13, x7
    li   x9, -1253
    vadd.vx v2, v9, x9
    li   x7, -1504
    vadd.vx v14, v4, x7
    addi a1, x31, 12
    vse16.v v13, (a1)
    lw   x11, 12(x31)
    vmv.x.s x12, v12
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -4
    vmv.v.x v3, x8
    li   x12, -783
    vmv.v.x v12, x12
    vadd.vi v12, v13, -14
    vadd.vv v1, v8, v12
    vadd.vv v12, v11, v23
    vadd.vi v16, v4, -12
    addi a1, x31, 45
    vle8.v v13, (a1)
    vmv.x.s x7, v13
    vmv.x.s x8, v18
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, 13
    li   x6, 431
    vmv.v.x v16, x6
    vadd.vv v12, v15, v19
    vsub.vv v11, v8, v22
    vsub.vv v7, v11, v3
    vmv.v.v v18, v23
    li   x8, -865
    vadd.vx v11, v1, x8
    addi a1, x31, 32
    vle32.v v11, (a1)
    vmv.x.s x5, v11
    vmv.x.s x13, v12
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v18, -6
    li   x13, -587
    vmv.v.x v9, x13
    vsub.vv v20, v13, v13
    vadd.vv v9, v16, v6
    vmv.v.i v0, 11
    vmerge.vvm v5, v13, v20, v0
    addi a1, x31, 16
    vle32.v v8, (a1)
    vmv.x.s x5, v8
    vmv.x.s x9, v10
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -383
    vmv.v.x v21, x6
    li   x8, 13
    vmv.v.x v21, x8
    vmv.v.v v1, v11
    vadd.vi v22, v22, -3
    vadd.vv v4, v19, v20
    vmv.v.v v18, v3
    addi a1, x31, 2
    vse16.v v10, (a1)
    lw   x11, 0(x31)
    vmv.x.s x14, v22
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -1758
    vmv.v.x v19, x10
    li   x10, -1999
    vmv.v.x v14, x10
    vadd.vi v19, v12, -15
    vmv.v.v v22, v5
    vadd.vv v17, v13, v22
    vmv.v.v v18, v5
    vmv.v.v v15, v5
    li   x14, 499
    vsub.vx v21, v13, x14
    addi a1, x31, 10
    vse8.v v5, (a1)
    lw   x14, 8(x31)
    vmv.x.s x7, v14
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, -8
    li   x9, -862
    vmv.v.x v7, x9
    li   x6, 1098
    vadd.vx v1, v15, x6
    vadd.vi v9, v19, -9
    li   x15, 982
    vadd.vx v10, v23, x15
    vmv.v.v v20, v4
    vmv.v.i v0, -5
    vmerge.vvm v10, v14, v7, v0
    li   x11, 1633
    vadd.vx v2, v10, x11
    addi a1, x31, 4
    vle32.v v19, (a1)
    vmv.x.s x6, v19
    vmv.x.s x15, v10
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, 1539
    vmv.v.x v19, x13
    li   x9, 1027
    vmv.v.x v18, x9
    vadd.vv v12, v21, v10
    vadd.vi v19, v13, -13
    vmv.v.v v23, v23
    addi a1, x31, 38
    vle8.v v10, (a1)
    vmv.x.s x9, v10
    vmv.x.s x11, v19
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, 1449
    vmv.v.x v21, x15
    li   x11, -187
    vmv.v.x v3, x11
    vsub.vv v1, v11, v4
    vmv.v.i v0, -1
    vmerge.vvm v11, v5, v15, v0
    li   x9, -178
    vsub.vx v2, v13, x9
    addi a1, x31, 42
    vse16.v v7, (a1)
    lw   x11, 40(x31)
    vmv.x.s x9, v16
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v6, -11
    vmv.v.i v3, -11
    vadd.vv v10, v8, v9
    vadd.vv v3, v19, v13
    vadd.vi v12, v16, 13
    vadd.vv v23, v2, v8
    addi a1, x31, 16
    vse16.v v18, (a1)
    lw   x8, 16(x31)
    vmv.x.s x6, v2
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v7, 15
    li   x7, -127
    vmv.v.x v22, x7
    vadd.vv v17, v6, v14
    vadd.vi v7, v5, 7
    vadd.vi v4, v4, 3
    addi a1, x31, 14
    vle8.v v16, (a1)
    vmv.x.s x7, v16
    vmv.x.s x6, v21
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v7, -12
    vmv.v.i v9, 0
    li   x10, 481
    vsub.vx v22, v16, x10
    li   x12, -1
    vadd.vx v12, v3, x12
    vadd.vi v22, v1, 14
    li   x10, 1537
    vsub.vx v23, v3, x10
    vadd.vi v4, v15, 13
    vmv.v.v v18, v12
    addi a1, x31, 36
    vle8.v v14, (a1)
    vmv.x.s x12, v14
    vmv.x.s x9, v15
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, -1
    vmv.v.i v15, -5
    vadd.vi v16, v8, -1
    li   x5, 310
    vsub.vx v3, v6, x5
    vadd.vv v14, v22, v5
    vmv.v.v v16, v16
    vsub.vv v13, v13, v17
    addi a1, x31, 40
    vse16.v v8, (a1)
    lw   x5, 40(x31)
    vmv.x.s x8, v10
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -629
    vmv.v.x v5, x8
    li   x11, -420
    vmv.v.x v6, x11
    vadd.vv v2, v10, v10
    vadd.vv v4, v16, v11
    li   x15, -291
    vadd.vx v21, v14, x15
    vmv.v.i v0, 12
    vmerge.vvm v4, v9, v17, v0
    vsub.vv v22, v21, v20
    vadd.vv v21, v5, v9
    addi a1, x31, 4
    vse32.v v12, (a1)
    lw   x9, 4(x31)
    vmv.x.s x14, v15
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, -15
    li   x8, 1363
    vmv.v.x v22, x8
    vadd.vv v18, v13, v15
    vadd.vi v15, v2, -16
    vadd.vv v6, v12, v21
    addi a1, x31, 4
    vse16.v v14, (a1)
    lw   x6, 4(x31)
    vmv.x.s x5, v6
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, 14
    vmv.v.i v18, 15
    vadd.vv v15, v18, v4
    vadd.vv v14, v13, v2
    vmv.v.v v11, v16
    vadd.vv v17, v23, v2
    addi a1, x31, 31
    vle8.v v18, (a1)
    vmv.x.s x8, v18
    vmv.x.s x8, v22
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v14, 5
    vmv.v.i v22, 11
    vmv.v.i v0, 3
    vmerge.vvm v16, v16, v17, v0
    vadd.vv v16, v13, v20
    vadd.vv v22, v11, v11
    vsub.vv v18, v22, v23
    vsub.vv v13, v23, v22
    vsub.vv v1, v11, v13
    addi a1, x31, 20
    vse8.v v8, (a1)
    lw   x10, 20(x31)
    vmv.x.s x11, v13
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -501
    vmv.v.x v13, x8
    li   x13, 1750
    vmv.v.x v1, x13
    vmv.v.i v0, -5
    vmerge.vvm v5, v7, v15, v0
    li   x9, -1702
    vsub.vx v10, v10, x9
    vsub.vv v1, v17, v20
    addi a1, x31, 44
    vle32.v v6, (a1)
    vmv.x.s x12, v6
    vmv.x.s x13, v23
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, -6
    li   x6, -1148
    vmv.v.x v18, x6
    vadd.vi v7, v11, -11
    vsub.vv v23, v16, v4
    vmv.v.v v15, v10
    addi a1, x31, 8
    vse16.v v14, (a1)
    lw   x8, 8(x31)
    vmv.x.s x15, v4
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v9, -13
    vmv.v.i v6, 4
    vsub.vv v12, v14, v21
    li   x7, 1351
    vadd.vx v21, v3, x7
    vadd.vv v6, v5, v17
    vadd.vv v14, v16, v5
    addi a1, x31, 34
    vle16.v v6, (a1)
    vmv.x.s x11, v6
    vmv.x.s x7, v20
    csrr t4, vstart
    ebreak

    .balign 4
data_area:
    .zero 64

