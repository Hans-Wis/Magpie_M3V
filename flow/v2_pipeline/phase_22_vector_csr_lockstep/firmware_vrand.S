.section .init
.global _start
_start:
    /* vector-random seed=20260704 blocks=56 (3B subset) */
    li   t0, 0x200
    csrs mstatus, t0
    li   a0, 2
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, -14
    vmv.v.i v13, -6
    vadd.vv v15, v5, v5
    li   x13, 158
    vadd.vx v1, v5, x13
    vsub.vv v6, v5, v13
    vadd.vi v23, v5, 7
    vadd.vv v16, v5, v5
    li   x7, 1879
    vadd.vx v2, v13, x7
    vmv.x.s x9, v5
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v4, 8
    li   x15, -972
    vmv.v.x v19, x15
    vmv.v.v v22, v6
    vadd.vi v13, v16, -7
    vadd.vv v3, v4, v15
    vmv.x.s x11, v6
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v13, -7
    vmv.v.i v12, 11
    vadd.vv v3, v2, v22
    vmv.v.i v0, 10
    vmerge.vvm v16, v23, v6, v0
    vadd.vv v6, v13, v15
    vadd.vv v2, v6, v12
    vmv.x.s x10, v13
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, -597
    vmv.v.x v6, x7
    vmv.v.i v16, -5
    vadd.vi v1, v4, 1
    li   x15, -1985
    vsub.vx v8, v4, x15
    li   x14, -1278
    vadd.vx v8, v1, x14
    vmv.x.s x6, v19
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v16, -1
    vmv.v.i v20, 6
    vadd.vv v8, v3, v22
    vsub.vv v10, v6, v19
    li   x11, 1513
    vadd.vx v4, v3, x11
    vmv.x.s x5, v12
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 357
    vmv.v.x v3, x7
    vmv.v.i v14, 0
    li   x13, -1477
    vsub.vx v22, v23, x13
    vmv.v.i v0, 2
    vmerge.vvm v2, v6, v10, v0
    vadd.vv v14, v12, v13
    vadd.vi v8, v16, 5
    vadd.vi v3, v10, -4
    vmv.x.s x10, v22
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v17, 0
    vmv.v.i v2, 13
    vadd.vv v22, v23, v15
    vmv.v.v v5, v6
    li   x11, -355
    vsub.vx v15, v20, x11
    vadd.vv v1, v15, v22
    li   x6, 952
    vadd.vx v11, v5, x6
    vmv.x.s x8, v5
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, -1165
    vmv.v.x v19, x13
    vmv.v.i v10, -1
    vmv.v.v v23, v23
    li   x5, 1497
    vadd.vx v4, v13, x5
    li   x12, 8
    vadd.vx v19, v22, x12
    vadd.vv v18, v16, v19
    li   x11, -1867
    vadd.vx v18, v8, x11
    vsub.vv v14, v13, v13
    vmv.x.s x5, v14
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v20, 9
    li   x7, 881
    vmv.v.x v6, x7
    vmv.v.i v0, -6
    vmerge.vvm v19, v15, v23, v0
    vmv.v.i v0, 12
    vmerge.vvm v17, v3, v19, v0
    vadd.vv v9, v14, v6
    vadd.vv v12, v10, v13
    vmv.v.v v3, v22
    vmv.x.s x13, v23
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, 1741
    vmv.v.x v21, x14
    li   x14, 1723
    vmv.v.x v10, x14
    vadd.vv v16, v10, v14
    vsub.vv v23, v19, v9
    vadd.vv v19, v11, v21
    vsub.vv v17, v21, v1
    vmv.x.s x8, v6
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -522
    vmv.v.x v19, x6
    vmv.v.i v5, 14
    vmv.v.v v7, v20
    vadd.vv v8, v5, v10
    vadd.vi v2, v11, 3
    vsub.vv v11, v8, v12
    li   x8, -1564
    vsub.vx v21, v15, x8
    vmv.x.s x5, v22
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v22, -12
    vmv.v.i v7, 0
    vadd.vv v9, v18, v13
    li   x10, 814
    vsub.vx v6, v3, x10
    li   x6, 508
    vadd.vx v17, v22, x6
    vadd.vv v20, v11, v12
    vmv.x.s x10, v4
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -393
    vmv.v.x v8, x10
    vmv.v.i v9, 0
    vsub.vv v23, v16, v21
    vmv.v.i v0, -9
    vmerge.vvm v18, v22, v18, v0
    vmv.v.v v1, v4
    vadd.vv v14, v2, v11
    vadd.vi v23, v14, 11
    vadd.vv v18, v14, v5
    vmv.x.s x11, v18
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, -26
    vmv.v.x v3, x14
    vmv.v.i v8, -16
    vadd.vv v12, v9, v20
    vmv.v.i v0, -2
    vmerge.vvm v3, v5, v20, v0
    vsub.vv v8, v14, v15
    vadd.vi v13, v22, -9
    vmv.x.s x14, v4
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, -15
    li   x8, -1052
    vmv.v.x v19, x8
    li   x9, 739
    vadd.vx v7, v11, x9
    vmv.v.v v10, v5
    li   x9, 329
    vsub.vx v2, v4, x9
    vmv.x.s x5, v8
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v11, 13
    li   x6, 1264
    vmv.v.x v21, x6
    vadd.vv v16, v12, v16
    vsub.vv v8, v1, v8
    vadd.vi v20, v9, -13
    vadd.vv v22, v5, v10
    vmv.v.i v0, -7
    vmerge.vvm v3, v13, v2, v0
    vmv.v.v v12, v14
    vmv.x.s x10, v16
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v16, 3
    vmv.v.i v22, 10
    vsub.vv v20, v21, v14
    vsub.vv v13, v2, v23
    li   x12, 618
    vsub.vx v1, v2, x12
    vadd.vi v4, v9, 9
    vmv.x.s x11, v20
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, 127
    vmv.v.x v20, x6
    li   x6, -466
    vmv.v.x v23, x6
    li   x14, -72
    vadd.vx v22, v5, x14
    vadd.vi v9, v21, -4
    vadd.vv v4, v3, v22
    vadd.vi v14, v6, -9
    vadd.vi v14, v11, -2
    vadd.vi v5, v8, 6
    vmv.x.s x8, v4
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, 1811
    vmv.v.x v20, x10
    vmv.v.i v15, 9
    vsub.vv v21, v8, v17
    vadd.vi v6, v18, 2
    li   x6, 467
    vadd.vx v3, v20, x6
    vmv.x.s x10, v7
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x9, -26
    vmv.v.x v16, x9
    vmv.v.i v5, -14
    li   x10, 181
    vadd.vx v16, v6, x10
    vadd.vv v19, v6, v16
    vadd.vv v21, v12, v7
    vadd.vi v20, v11, -8
    vmv.x.s x10, v2
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 1155
    vmv.v.x v23, x12
    vmv.v.i v2, -15
    vadd.vv v7, v21, v18
    li   x14, -1139
    vadd.vx v10, v16, x14
    vadd.vi v18, v20, 4
    vadd.vv v20, v2, v19
    vmv.v.v v10, v21
    vmv.x.s x7, v11
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 145
    vmv.v.x v13, x12
    li   x13, 671
    vmv.v.x v10, x13
    li   x6, -1174
    vadd.vx v9, v4, x6
    vmv.v.i v0, -12
    vmerge.vvm v5, v23, v2, v0
    vsub.vv v15, v3, v13
    vmv.x.s x7, v12
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, 581
    vmv.v.x v21, x8
    li   x12, 149
    vmv.v.x v8, x12
    li   x5, 1332
    vadd.vx v23, v8, x5
    li   x14, -1312
    vsub.vx v18, v20, x14
    vadd.vv v16, v10, v12
    vadd.vi v1, v10, -4
    vadd.vv v8, v20, v17
    vmv.x.s x5, v1
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v21, 13
    li   x15, -1238
    vmv.v.x v19, x15
    vmv.v.i v0, -11
    vmerge.vvm v15, v7, v21, v0
    vadd.vi v3, v11, -14
    vsub.vv v21, v12, v14
    vadd.vv v10, v7, v19
    vadd.vv v15, v13, v18
    vadd.vv v17, v1, v11
    vmv.x.s x12, v11
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 1955
    vmv.v.x v20, x7
    vmv.v.i v7, -6
    vmv.v.v v13, v2
    li   x12, -252
    vadd.vx v20, v4, x12
    li   x11, -1007
    vsub.vx v9, v3, x11
    vmv.x.s x14, v20
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v10, -1
    vmv.v.i v3, -9
    li   x14, 810
    vadd.vx v12, v22, x14
    vmv.v.i v0, -11
    vmerge.vvm v18, v7, v4, v0
    vmv.v.i v0, 4
    vmerge.vvm v17, v6, v14, v0
    vadd.vv v12, v18, v4
    vsub.vv v2, v20, v15
    vmv.x.s x14, v8
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v23, -12
    li   x11, 1990
    vmv.v.x v21, x11
    vadd.vv v7, v15, v4
    vadd.vv v10, v9, v16
    vadd.vv v4, v16, v7
    vmv.v.i v0, 13
    vmerge.vvm v17, v6, v16, v0
    vmv.x.s x11, v14
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, 9
    vmv.v.i v20, 0
    vadd.vv v13, v5, v7
    vsub.vv v17, v8, v4
    vmv.v.v v21, v14
    vadd.vv v17, v7, v3
    vmv.x.s x13, v10
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v13, 13
    li   x8, -1894
    vmv.v.x v4, x8
    vmv.v.v v5, v21
    vadd.vv v17, v18, v9
    vadd.vv v9, v23, v8
    vadd.vv v20, v1, v12
    vmv.v.v v18, v19
    vmv.v.v v8, v14
    vmv.x.s x10, v23
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, -13
    li   x9, -1253
    vmv.v.x v23, x9
    li   x7, -1504
    vadd.vx v14, v4, x7
    vadd.vv v18, v13, v14
    vsub.vv v16, v19, v4
    vadd.vi v3, v8, -1
    vmv.v.v v12, v15
    vmv.x.s x7, v7
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, -569
    vmv.v.x v17, x5
    li   x10, 870
    vmv.v.x v2, x10
    vsub.vv v7, v16, v19
    vadd.vv v21, v19, v18
    li   x6, -1538
    vadd.vx v22, v23, x6
    vadd.vv v16, v5, v7
    vmv.x.s x13, v13
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 512
    vmv.v.x v10, x12
    li   x9, 701
    vmv.v.x v3, x9
    vadd.vv v4, v19, v11
    vsub.vv v11, v22, v7
    vadd.vi v11, v3, 5
    vadd.vv v22, v8, v5
    li   x6, 514
    vadd.vx v1, v1, x6
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
    vmv.x.s x13, v9
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, -8
    li   x6, -383
    vmv.v.x v21, x6
    vadd.vv v9, v1, v2
    li   x9, -317
    vadd.vx v11, v4, x9
    vadd.vi v4, v20, 8
    vadd.vv v3, v10, v10
    vmv.x.s x11, v19
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, 272
    vmv.v.x v19, x14
    li   x11, 699
    vmv.v.x v12, x11
    vadd.vi v14, v12, -15
    vmv.v.v v22, v5
    vadd.vv v17, v13, v22
    vmv.x.s x13, v7
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 499
    vmv.v.x v5, x11
    vmv.v.i v13, -8
    vadd.vi v14, v18, -10
    vadd.vv v2, v5, v7
    vadd.vv v18, v5, v13
    li   x6, 1098
    vadd.vx v1, v15, x6
    vmv.x.s x9, v16
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, 982
    vmv.v.x v10, x15
    li   x13, -1056
    vmv.v.x v23, x13
    vadd.vv v6, v7, v2
    vadd.vv v21, v13, v15
    li   x15, -1076
    vsub.vx v10, v16, x15
    vadd.vi v21, v22, 2
    vadd.vi v6, v19, 3
    vmv.x.s x13, v20
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, 1009
    vmv.v.x v13, x6
    vmv.v.i v10, 2
    vadd.vi v13, v23, 11
    vadd.vv v23, v20, v5
    vadd.vv v10, v19, v23
    vadd.vv v23, v5, v21
    vmv.x.s x15, v20
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -187
    vmv.v.x v3, x11
    vmv.v.i v3, 5
    vmv.v.i v0, -1
    vmerge.vvm v11, v5, v15, v0
    li   x9, -178
    vsub.vx v2, v13, x9
    li   x8, 1053
    vadd.vx v10, v9, x8
    vmv.x.s x12, v20
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v11, -11
    vmv.v.i v3, -11
    vadd.vv v10, v8, v9
    vadd.vv v3, v19, v13
    vadd.vi v12, v16, 13
    vadd.vv v23, v2, v8
    vmv.x.s x11, v9
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v3, 14
    vmv.v.i v7, 15
    vadd.vi v8, v17, -13
    vmv.v.v v3, v14
    vadd.vi v7, v5, 7
    vadd.vi v4, v4, 3
    vmv.x.s x13, v4
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -1613
    vmv.v.x v6, x6
    vmv.v.i v2, 12
    vadd.vv v21, v9, v16
    vadd.vv v5, v16, v22
    vmv.v.i v0, 3
    vmerge.vvm v16, v12, v20, v0
    vadd.vi v6, v8, -11
    vmv.x.s x15, v15
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, 1537
    vmv.v.x v23, x10
    vmv.v.i v3, 13
    vmv.v.v v18, v12
    vadd.vi v1, v13, 10
    vadd.vv v15, v8, v1
    li   x5, 672
    vsub.vx v8, v10, x5
    vadd.vi v8, v19, -5
    vadd.vi v10, v9, -1
    vmv.x.s x14, v8
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, -973
    vmv.v.x v6, x5
    li   x12, 1172
    vmv.v.x v16, x12
    vsub.vv v6, v12, v21
    vmv.v.i v0, -14
    vmerge.vvm v8, v10, v16, v0
    vsub.vv v9, v7, v6
    vmv.v.i v0, 11
    vmerge.vvm v7, v16, v2, v0
    vsub.vv v8, v10, v10
    vmv.x.s x6, v3
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, -291
    vmv.v.x v21, x15
    vmv.v.i v14, 12
    vadd.vi v9, v11, -1
    li   x6, 244
    vadd.vx v21, v5, x6
    li   x6, 639
    vadd.vx v9, v12, x6
    vmv.x.s x9, v20
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v3, -15
    li   x8, 1363
    vmv.v.x v22, x8
    vadd.vv v18, v13, v15
    vadd.vi v15, v2, -16
    vadd.vv v6, v12, v21
    vmv.x.s x9, v3
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, 3
    vmv.v.i v3, 14
    vadd.vi v15, v6, 12
    li   x6, 1483
    vadd.vx v8, v9, x6
    vsub.vv v6, v11, v10
    vmv.v.v v16, v17
    vsub.vv v6, v2, v10
    vadd.vi v16, v18, -1
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
    vmv.x.s x7, v11
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v11, -10
    vmv.v.i v2, -12
    vadd.vv v7, v2, v18
    vadd.vi v17, v1, -5
    vadd.vv v5, v10, v19
    li   x5, 459
    vadd.vx v9, v1, x5
    vmv.x.s x11, v2
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v6, 3
    vmv.v.i v15, -6
    vadd.vi v4, v21, -9
    li   x8, 749
    vsub.vx v19, v3, x8
    vsub.vv v23, v16, v4
    vmv.v.v v15, v10
    vadd.vv v15, v16, v14
    vmv.x.s x8, v22
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v9, -13
    vmv.v.i v6, 4
    vsub.vv v12, v14, v21
    li   x7, 1351
    vadd.vx v21, v3, x7
    vadd.vv v6, v5, v17
    vadd.vv v14, v16, v5
    vmv.x.s x12, v18
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, -884
    vmv.v.x v6, x15
    li   x9, 1386
    vmv.v.x v23, x9
    vadd.vv v16, v17, v10
    vsub.vv v15, v21, v8
    vadd.vv v13, v1, v2
    vadd.vi v22, v21, -1
    vmv.v.v v18, v20
    vsub.vv v22, v12, v5
    vmv.x.s x11, v8
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, 731
    vmv.v.x v1, x13
    vmv.v.i v12, -4
    vadd.vv v7, v15, v15
    vadd.vv v5, v23, v8
    vmv.v.v v7, v20
    vadd.vi v10, v4, -4
    vmv.v.v v21, v3
    li   x14, -1113
    vadd.vx v10, v14, x14
    vmv.x.s x6, v10
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v23, 0
    li   x15, -505
    vmv.v.x v15, x15
    li   x12, -1564
    vsub.vx v3, v19, x12
    li   x6, -606
    vsub.vx v15, v17, x6
    vadd.vv v17, v19, v20
    li   x9, -136
    vadd.vx v11, v22, x9
    vadd.vi v23, v5, -7
    li   x6, -1581
    vadd.vx v7, v23, x6
    vmv.x.s x12, v10
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, 169
    vmv.v.x v19, x14
    vmv.v.i v4, -10
    li   x12, -1146
    vadd.vx v21, v13, x12
    li   x15, 1380
    vsub.vx v1, v19, x15
    vsub.vv v23, v20, v21
    vmv.x.s x11, v17
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, 15
    li   x14, -878
    vmv.v.x v12, x14
    vmv.v.i v0, 14
    vmerge.vvm v18, v13, v11, v0
    li   x11, 679
    vsub.vx v12, v13, x11
    vmv.v.i v0, -5
    vmerge.vvm v6, v1, v5, v0
    vmv.x.s x15, v10
    csrr t4, vstart
    ebreak

