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
    vmslt.vv v0, v6, v16
    li   x11, 1635
    vmsgt.vx v8, v6, x11
    vmand.mm v0, v0, v8
    vmax.vv v22, v2, v2, v0.t
    vmin.vv v14, v16, v23
    vmv.x.s x7, v0
    addi a1, x31, 20
    vle16.v v5, (a1)
    vmv.x.s x10, v5
    vmv.x.s x7, v2
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v3, -10
    li   x11, 1827
    vmv.v.x v8, x11
    vadd.vv v6, v22, v23
    vadd.vv v2, v14, v16
    vsub.vv v12, v14, v5
    vadd.vv v22, v5, v16
    vmv.v.i v0, -5
    vmerge.vvm v1, v2, v22, v0
    vmsle.vv v0, v5, v6
    li   x8, -356
    vmsgt.vx v7, v2, x8
    vmand.mm v0, v0, v7
    vadd.vi v3, v5, -1, v0.t
    vmaxu.vv v1, v5, v3
    vmv.x.s x7, v0
    addi a1, x31, 24
    vse16.v v23, (a1)
    lw   x6, 24(x31)
    vmv.x.s x15, v14
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, -15
    vmv.v.i v9, -7
    vadd.vv v14, v6, v6
    vmv.v.v v22, v12
    vadd.vi v3, v12, 2
    li   x13, -757
    vadd.vx v2, v22, x13
    vsub.vv v8, v5, v6
    vmsle.vv v0, v14, v16
    vadd.vi v8, v7, -12, v0.t
    vmax.vv v16, v7, v12
    vmv.x.s x9, v0
    addi a1, x31, 28
    vle32.v v9, (a1)
    vmv.x.s x5, v9
    vmv.x.s x6, v9
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, 945
    vmv.v.x v11, x5
    li   x7, 1629
    vmv.v.x v5, x7
    li   x12, -2025
    vadd.vx v13, v3, x12
    vsub.vv v7, v7, v13
    vadd.vv v17, v23, v3
    vadd.vv v7, v12, v7
    li   x13, -1165
    vadd.vx v19, v12, x13
    vmseq.vv v0, v14, v9
    vmsne.vi v19, v5, -13
    vmandn.mm v0, v0, v19
    vmax.vv v11, v16, v23, v0.t
    vminu.vv v13, v13, v13
    vmv.x.s x5, v0
    addi a1, x31, 16
    vle16.v v20, (a1)
    vmv.x.s x8, v20
    vmv.x.s x11, v7
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, 58
    vmv.v.x v12, x13
    li   x7, 1100
    vmv.v.x v16, x7
    vsub.vv v1, v3, v22
    vadd.vv v9, v14, v7
    vadd.vv v12, v11, v14
    vmv.v.v v3, v22
    li   x9, -856
    vadd.vx v23, v19, x9
    vadd.vi v10, v19, -2
    vmsltu.vv v0, v9, v19
    vmsne.vi v23, v14, -1
    vmnand.mm v0, v0, v23
    vsub.vv v19, v11, v20, v0.t
    li   x13, 1
    vmax.vx v5, v5, x13
    vmv.x.s x15, v0
    addi a1, x31, 8
    vse32.v v17, (a1)
    lw   x12, 8(x31)
    vmv.x.s x9, v8
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, 2
    vmv.v.i v2, 4
    vsub.vv v11, v9, v13
    vmv.v.v v21, v9
    vmv.v.v v20, v2
    vmv.v.i v0, -8
    vmerge.vvm v10, v23, v8, v0
    vsub.vv v22, v3, v8
    vmsltu.vv v0, v11, v22
    vadd.vv v5, v10, v7, v0.t
    li   x14, 0
    vminu.vx v10, v20, x14
    vmv.x.s x10, v0
    addi a1, x31, 22
    vle16.v v13, (a1)
    vmv.x.s x12, v13
    vmv.x.s x8, v13
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v6, 3
    li   x15, -1589
    vmv.v.x v8, x15
    li   x5, -1686
    vadd.vx v18, v5, x5
    vadd.vv v14, v2, v12
    vadd.vi v23, v16, 11
    vmsle.vv v0, v2, v18
    vmsne.vi v18, v16, -3
    vmand.mm v0, v0, v18
    vadd.vi v3, v9, -15, v0.t
    vmin.vv v5, v22, v12
    vmv.x.s x6, v0
    addi a1, x31, 5
    vle8.v v20, (a1)
    vmv.x.s x8, v20
    vmv.x.s x10, v16
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v20, -15
    vmv.v.i v23, -15
    vmv.v.v v3, v21
    vadd.vv v17, v5, v8
    vsub.vv v22, v12, v12
    vmv.v.v v10, v6
    li   x9, 329
    vsub.vx v2, v5, x9
    vmseq.vv v0, v9, v9
    vmax.vv v18, v23, v1, v0.t
    vminu.vv v16, v1, v8
    vmv.x.s x10, v0
    addi a1, x31, 14
    vle16.v v1, (a1)
    vmv.x.s x8, v1
    vmv.x.s x14, v17
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v22, -7
    vmv.v.i v10, 9
    vmv.v.i v0, -13
    vmerge.vvm v12, v16, v12, v0
    vadd.vv v16, v16, v18
    vadd.vv v5, v11, v13
    vmv.v.v v2, v6
    vmsleu.vv v0, v22, v13
    vmsne.vi v13, v14, -16
    vmand.mm v0, v0, v13
    vmax.vv v23, v5, v19, v0.t
    li   x14, 1
    vmax.vx v20, v22, x14
    vmv.x.s x6, v0
    addi a1, x31, 54
    vse8.v v19, (a1)
    lw   x15, 52(x31)
    vmv.x.s x9, v20
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -72
    vmv.v.x v13, x8
    vmv.v.i v5, -13
    vadd.vv v4, v3, v16
    vadd.vv v15, v4, v14
    vadd.vi v18, v11, -2
    vadd.vi v5, v8, 6
    vmsne.vv v0, v4, v7
    li   x10, -128
    vmsgtu.vx v20, v11, x10
    vmandn.mm v0, v0, v20
    vadd.vv v20, v1, v21, v0.t
    vmaxu.vv v20, v3, v10
    vmv.x.s x14, v0
    addi a1, x31, 12
    vse16.v v3, (a1)
    lw   x12, 12(x31)
    vmv.x.s x12, v12
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, -14
    li   x7, 1955
    vmv.v.x v20, x7
    vsub.vv v23, v6, v19
    vsub.vv v9, v16, v21
    vadd.vv v7, v7, v20
    vadd.vv v19, v5, v11
    vmv.v.v v2, v13
    vmsle.vv v0, v4, v23
    vmin.vv v16, v13, v21, v0.t
    li   x11, -128
    vminu.vx v10, v17, x11
    vmv.x.s x6, v0
    addi a1, x31, 35
    vse8.v v20, (a1)
    lw   x14, 32(x31)
    vmv.x.s x13, v22
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v12, 2
    li   x7, 617
    vmv.v.x v1, x7
    vsub.vv v12, v5, v16
    vmv.v.i v0, 1
    vmerge.vvm v10, v23, v16, v0
    vsub.vv v17, v4, v9
    vmv.v.v v21, v4
    vmseq.vv v0, v17, v13
    li   x5, 127
    vmsgtu.vx v23, v15, x5
    vmor.mm v0, v0, v23
    vmax.vv v13, v8, v11, v0.t
    vmin.vv v9, v23, v2
    vmv.x.s x11, v0
    addi a1, x31, 34
    vse8.v v20, (a1)
    lw   x13, 32(x31)
    vmv.x.s x6, v20
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v12, 3
    vmv.v.i v7, 1
    vmv.v.i v0, -11
    vmerge.vvm v12, v21, v4, v0
    vmv.v.i v0, -10
    vmerge.vvm v19, v15, v11, v0
    vadd.vi v17, v18, -11
    vmsltu.vv v0, v7, v21
    vmseq.vi v18, v2, 6
    vmxnor.mm v0, v0, v18
    vsub.vv v14, v20, v7, v0.t
    vmin.vv v1, v16, v11
    vmv.x.s x8, v0
    addi a1, x31, 21
    vse8.v v21, (a1)
    lw   x7, 20(x31)
    vmv.x.s x13, v16
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 2025
    vmv.v.x v6, x11
    li   x15, 655
    vmv.v.x v2, x15
    vadd.vv v8, v9, v14
    li   x14, -1669
    vsub.vx v5, v9, x14
    vadd.vv v7, v7, v8
    vsub.vv v3, v4, v9
    li   x14, 810
    vadd.vx v12, v22, x14
    vmv.v.i v0, -11
    vmerge.vvm v18, v7, v4, v0
    vmseq.vv v0, v14, v11
    vsub.vv v6, v2, v18, v0.t
    vmax.vv v15, v4, v23
    vmv.x.s x8, v0
    addi a1, x31, 40
    vse8.v v13, (a1)
    lw   x15, 40(x31)
    vmv.x.s x12, v19
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x9, -2031
    vmv.v.x v15, x9
    vmv.v.i v6, 15
    vmv.v.v v9, v7
    vmv.v.i v0, 13
    vmerge.vvm v17, v6, v16, v0
    vsub.vv v14, v5, v5
    vmseq.vv v0, v8, v10
    vsub.vv v20, v8, v13, v0.t
    vmax.vv v8, v21, v14
    vmv.x.s x13, v0
    addi a1, x31, 22
    vle8.v v18, (a1)
    vmv.x.s x9, v18
    vmv.x.s x15, v4
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, -6
    li   x5, 1610
    vmv.v.x v7, x5
    li   x6, 60
    vadd.vx v15, v9, x6
    vmv.v.v v7, v23
    vmv.v.v v8, v6
    vadd.vv v23, v12, v18
    vmslt.vv v0, v19, v8
    vadd.vi v14, v4, -7, v0.t
    vmin.vv v4, v14, v23
    vmv.x.s x11, v0
    addi a1, x31, 4
    vle8.v v9, (a1)
    vmv.x.s x8, v9
    vmv.x.s x11, v14
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -1325
    vmv.v.x v19, x6
    vmv.v.i v8, -15
    vmv.v.v v5, v12
    vmv.v.v v19, v17
    vadd.vv v23, v6, v2
    vmv.v.v v8, v12
    vadd.vv v12, v11, v23
    vadd.vi v16, v4, -12
    vmseq.vv v0, v23, v16
    li   x13, -1
    vmsgtu.vx v7, v6, x13
    vmand.mm v0, v0, v7
    vmax.vv v10, v11, v12, v0.t
    vmin.vv v19, v11, v13
    vmv.x.s x8, v0
    addi a1, x31, 12
    vle32.v v11, (a1)
    vmv.x.s x6, v11
    vmv.x.s x13, v23
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v8, -10
    vmv.v.i v17, 7
    li   x8, 1709
    vadd.vx v1, v2, x8
    vadd.vv v6, v5, v18
    vmv.v.i v0, -16
    vmerge.vvm v20, v11, v5, v0
    vsub.vv v13, v8, v22
    vadd.vv v16, v16, v19
    vmv.v.v v17, v14
    vmsne.vv v0, v13, v20
    vsub.vv v8, v2, v10, v0.t
    li   x8, 1
    vminu.vx v21, v6, x8
    vmv.x.s x5, v0
    addi a1, x31, 21
    vse8.v v10, (a1)
    lw   x15, 20(x31)
    vmv.x.s x13, v7
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v3, 2
    vmv.v.i v10, 11
    vmv.v.i v0, 2
    vmerge.vvm v12, v2, v14, v0
    li   x5, 1449
    vadd.vx v20, v19, x5
    vmv.v.i v0, -15
    vmerge.vvm v22, v21, v5, v0
    vadd.vv v17, v13, v22
    vmsle.vv v0, v7, v5
    vmseq.vi v5, v21, 11
    vmnor.mm v0, v0, v5
    vadd.vv v13, v7, v6, v0.t
    vmin.vv v2, v5, v7
    vmv.x.s x13, v0
    addi a1, x31, 19
    vle8.v v13, (a1)
    vmv.x.s x5, v13
    vmv.x.s x6, v4
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, -1038
    vmv.v.x v16, x13
    li   x15, 982
    vmv.v.x v10, x15
    vmv.v.i v0, -5
    vmerge.vvm v10, v14, v7, v0
    li   x11, 1633
    vadd.vx v2, v10, x11
    vadd.vv v22, v21, v19
    vmseq.vv v0, v22, v10
    vmseq.vi v19, v18, 3
    vmorn.mm v0, v0, v19
    vmin.vv v18, v21, v10, v0.t
    vmaxu.vv v17, v13, v17
    vmv.x.s x5, v0
    addi a1, x31, 44
    vle32.v v23, (a1)
    vmv.x.s x8, v23
    vmv.x.s x14, v5
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, -782
    vmv.v.x v14, x14
    li   x14, 1449
    vmv.v.x v5, x14
    vadd.vv v13, v1, v11
    vadd.vv v11, v2, v8
    vmv.v.v v11, v15
    vmseq.vv v0, v11, v23
    li   x9, -128
    vmsgtu.vx v13, v9, x9
    vmorn.mm v0, v0, v13
    vadd.vv v20, v20, v3, v0.t
    vmaxu.vv v20, v10, v3
    vmv.x.s x9, v0
    addi a1, x31, 17
    vle8.v v19, (a1)
    vmv.x.s x11, v19
    vmv.x.s x10, v17
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v23, -13
    li   x9, 1983
    vmv.v.x v8, x9
    vadd.vv v3, v19, v18
    vadd.vv v16, v16, v22
    vadd.vv v6, v3, v17
    vadd.vv v2, v6, v14
    vmsne.vv v0, v18, v6
    vmseq.vi v4, v19, -10
    vmor.mm v0, v0, v4
    vadd.vv v10, v18, v4, v0.t
    vmaxu.vv v5, v15, v8
    vmv.x.s x15, v0
    addi a1, x31, 58
    vse8.v v9, (a1)
    lw   x12, 56(x31)
    vmv.x.s x7, v9
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v19, 14
    li   x12, -1
    vmv.v.x v12, x12
    vadd.vi v22, v1, 14
    vmv.v.v v23, v12
    vadd.vv v15, v16, v15
    vmsltu.vv v0, v18, v12
    li   x11, 127
    vmsgt.vx v13, v15, x11
    vmnand.mm v0, v0, v13
    vmax.vv v1, v14, v19, v0.t
    vmin.vv v17, v8, v20
    vmv.x.s x8, v0
    addi a1, x31, 44
    vse8.v v2, (a1)
    lw   x15, 44(x31)
    vmv.x.s x9, v6
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 1172
    vmv.v.x v16, x12
    vmv.v.i v12, 7
    vadd.vv v2, v16, v9
    vadd.vv v12, v7, v6
    vmv.v.i v0, 11
    vmerge.vvm v7, v16, v2, v0
    vsub.vv v8, v10, v10
    vmseq.vv v0, v3, v13
    vadd.vv v16, v11, v21, v0.t
    li   x15, 1
    vmax.vx v9, v8, x15
    vmv.x.s x15, v0
    addi a1, x31, 40
    vle32.v v5, (a1)
    vmv.x.s x9, v5
    vmv.x.s x15, v3
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 791
    vmv.v.x v9, x7
    vmv.v.i v3, -15
    vmv.v.v v14, v4
    vadd.vv v18, v13, v15
    vadd.vi v15, v2, -16
    vadd.vv v6, v12, v21
    vmslt.vv v0, v3, v19
    vmax.vv v14, v1, v3, v0.t
    vminu.vv v15, v6, v15
    vmv.x.s x8, v0
    addi a1, x31, 27
    vle8.v v13, (a1)
    vmv.x.s x5, v13
    vmv.x.s x10, v10
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, 295
    vmv.v.x v14, x5
    vmv.v.i v16, -1
    vsub.vv v22, v13, v14
    vadd.vi v5, v22, 14
    vmv.v.v v22, v21
    vadd.vi v14, v23, 3
    vmsltu.vv v0, v16, v17
    vmsne.vi v13, v20, 2
    vmxnor.mm v0, v0, v13
    vadd.vv v11, v18, v13, v0.t
    vminu.vv v13, v11, v13
    vmv.x.s x7, v0
    addi a1, x31, 32
    vse16.v v8, (a1)
    lw   x10, 32(x31)
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
    vmv.v.v v10, v9
    vmv.v.v v20, v10
    vmseq.vv v0, v13, v2
    vmin.vv v18, v4, v6, v0.t
    vmax.vv v10, v19, v20
    vmv.x.s x15, v0
    addi a1, x31, 36
    vse8.v v7, (a1)
    lw   x14, 36(x31)
    vmv.x.s x14, v11
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x9, 465
    vmv.v.x v4, x9
    vmv.v.i v15, 14
    li   x7, 1776
    vadd.vx v8, v9, x7
    vmv.v.v v7, v18
    vmv.v.i v0, 12
    vmerge.vvm v16, v19, v17, v0
    li   x13, -175
    vadd.vx v11, v12, x13
    vadd.vv v11, v21, v21
    vsub.vv v21, v14, v3
    vmsne.vv v0, v7, v19
    vsub.vv v17, v19, v16, v0.t
    li   x13, -128
    vminu.vx v20, v22, x13
    vmv.x.s x7, v0
    addi a1, x31, 44
    vse32.v v10, (a1)
    lw   x11, 44(x31)
    vmv.x.s x12, v16
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, -1
    vmv.v.i v13, -15
    vadd.vi v22, v21, -1
    vmv.v.v v18, v20
    vsub.vv v22, v12, v5
    vmsltu.vv v0, v8, v19
    vmax.vv v21, v12, v9, v0.t
    vmax.vv v7, v2, v15
    vmv.x.s x12, v0
    addi a1, x31, 18
    vse8.v v23, (a1)
    lw   x8, 16(x31)
    vmv.x.s x8, v13
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v4, -4
    li   x6, 406
    vmv.v.x v21, x6
    vadd.vv v14, v22, v16
    li   x9, 1586
    vadd.vx v13, v3, x9
    li   x11, -1419
    vadd.vx v22, v18, x11
    vmsltu.vv v0, v20, v2
    vsub.vv v15, v23, v6, v0.t
    li   x14, 0
    vminu.vx v9, v22, x14
    vmv.x.s x13, v0
    addi a1, x31, 8
    vse16.v v17, (a1)
    lw   x15, 8(x31)
    vmv.x.s x7, v7
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x9, -884
    vmv.v.x v2, x9
    vmv.v.i v2, 8
    vsub.vv v4, v18, v4
    vmv.v.v v1, v23
    vadd.vi v1, v4, 9
    vmv.v.v v1, v22
    vmv.v.v v22, v19
    vmsleu.vv v0, v12, v7
    vadd.vi v20, v1, -8, v0.t
    vminu.vv v19, v19, v5
    vmv.x.s x5, v0
    addi a1, x31, 28
    vle16.v v18, (a1)
    vmv.x.s x11, v18
    vmv.x.s x10, v12
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v13, -5
    vmv.v.i v6, -7
    vsub.vv v8, v15, v17
    vmv.v.v v8, v10
    vmv.v.i v0, -7
    vmerge.vvm v1, v22, v14, v0
    li   x11, -1020
    vadd.vx v14, v17, x11
    vadd.vv v23, v16, v3
    vmsltu.vv v0, v2, v22
    li   x14, 1277
    vmsgt.vx v8, v7, x14
    vmand.mm v0, v0, v8
    vmin.vv v2, v23, v9, v0.t
    vmax.vv v3, v2, v10
    vmv.x.s x13, v0
    addi a1, x31, 31
    vse8.v v22, (a1)
    lw   x10, 28(x31)
    vmv.x.s x12, v11
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, 711
    vmv.v.x v6, x8
    vmv.v.i v8, 14
    vadd.vv v23, v18, v1
    vmv.v.i v0, 13
    vmerge.vvm v1, v20, v5, v0
    li   x6, 789
    vadd.vx v14, v10, x6
    vmv.v.v v5, v6
    vmv.v.i v0, -12
    vmerge.vvm v21, v2, v18, v0
    vmsleu.vv v0, v16, v21
    vmseq.vi v19, v6, 14
    vmandn.mm v0, v0, v19
    vadd.vi v8, v21, 7, v0.t
    li   x13, 1
    vmax.vx v8, v17, x13
    vmv.x.s x8, v0
    addi a1, x31, 31
    vle8.v v15, (a1)
    vmv.x.s x10, v15
    vmv.x.s x10, v4
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, -1481
    vmv.v.x v7, x7
    li   x12, 1279
    vmv.v.x v4, x12
    vsub.vv v3, v20, v8
    vsub.vv v17, v12, v7
    vmv.v.v v23, v2
    vsub.vv v14, v18, v9
    vadd.vi v14, v6, -1
    vmsleu.vv v0, v16, v7
    vmin.vv v20, v22, v5, v0.t
    vminu.vv v3, v14, v20
    vmv.x.s x12, v0
    addi a1, x31, 2
    vse16.v v4, (a1)
    lw   x7, 0(x31)
    vmv.x.s x14, v21
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v9, -1
    vmv.v.i v4, 6
    vmv.v.v v12, v2
    vadd.vi v1, v16, 12
    vadd.vi v17, v21, 10
    vsub.vv v21, v17, v3
    li   x15, -60
    vadd.vx v19, v6, x15
    vmv.v.i v0, -14
    vmerge.vvm v2, v6, v8, v0
    vmsleu.vv v0, v23, v10
    vmax.vv v23, v16, v20, v0.t
    li   x9, 127
    vminu.vx v14, v20, x9
    vmv.x.s x12, v0
    addi a1, x31, 8
    vle32.v v3, (a1)
    vmv.x.s x11, v3
    vmv.x.s x10, v9
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v8, 3
    vmv.v.i v6, 5
    vadd.vv v6, v19, v18
    vadd.vi v20, v10, 9
    vadd.vv v19, v2, v22
    vadd.vv v13, v18, v13
    vadd.vv v6, v19, v2
    vmslt.vv v0, v1, v9
    vsub.vv v1, v1, v19, v0.t
    vmin.vv v16, v23, v10
    vmv.x.s x15, v0
    addi a1, x31, 31
    vle8.v v23, (a1)
    vmv.x.s x6, v23
    vmv.x.s x15, v9
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, 1867
    vmv.v.x v3, x5
    vmv.v.i v12, 9
    vmv.v.i v0, -12
    vmerge.vvm v17, v15, v12, v0
    vadd.vv v20, v18, v10
    vadd.vv v17, v2, v5
    vmv.v.v v8, v12
    vmsleu.vv v0, v10, v19
    li   x14, -1905
    vmsgtu.vx v5, v7, x14
    vmxor.mm v0, v0, v5
    vsub.vv v5, v22, v5, v0.t
    vminu.vv v19, v20, v4
    vmv.x.s x5, v0
    addi a1, x31, 14
    vse8.v v12, (a1)
    lw   x8, 12(x31)
    vmv.x.s x11, v6
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -172
    vmv.v.x v8, x8
    li   x13, -1429
    vmv.v.x v15, x13
    vadd.vi v13, v19, -9
    vadd.vv v5, v21, v13
    vadd.vv v19, v17, v19
    vmslt.vv v0, v6, v16
    vsub.vv v22, v19, v6, v0.t
    vmaxu.vv v2, v13, v2
    vmv.x.s x14, v0
    addi a1, x31, 42
    vse16.v v16, (a1)
    lw   x10, 40(x31)
    vmv.x.s x9, v22
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v22, -12
    vmv.v.i v18, -9
    vadd.vi v17, v19, 3
    vsub.vv v16, v16, v5
    vadd.vi v22, v18, 11
    li   x9, 644
    vadd.vx v2, v1, x9
    vmslt.vv v0, v20, v22
    li   x13, -128
    vmsgtu.vx v22, v8, x13
    vmand.mm v0, v0, v22
    vmin.vv v7, v6, v7, v0.t
    li   x10, 1
    vmax.vx v6, v12, x10
    vmv.x.s x5, v0
    addi a1, x31, 48
    vse32.v v14, (a1)
    lw   x13, 48(x31)
    vmv.x.s x12, v5
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v19, -10
    vmv.v.i v20, -2
    vadd.vv v4, v19, v14
    vadd.vv v6, v1, v6
    vadd.vv v20, v9, v18
    vmv.v.v v2, v6
    vsub.vv v2, v4, v14
    vmseq.vv v0, v19, v3
    vmseq.vi v23, v16, 0
    vmorn.mm v0, v0, v23
    vmax.vv v2, v12, v6, v0.t
    li   x12, -128
    vmax.vx v3, v10, x12
    vmv.x.s x11, v0
    addi a1, x31, 20
    vse16.v v23, (a1)
    lw   x14, 20(x31)
    vmv.x.s x5, v4
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, 585
    vmv.v.x v18, x6
    vmv.v.i v10, 12
    vsub.vv v9, v7, v18
    vadd.vv v19, v20, v12
    li   x8, -948
    vsub.vx v18, v9, x8
    vadd.vv v11, v15, v1
    vmsltu.vv v0, v9, v9
    vmseq.vi v11, v14, 6
    vmor.mm v0, v0, v11
    vadd.vv v20, v10, v10, v0.t
    vmin.vv v6, v18, v15
    vmv.x.s x14, v0
    addi a1, x31, 28
    vle32.v v4, (a1)
    vmv.x.s x5, v4
    vmv.x.s x7, v17
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -161
    vmv.v.x v9, x11
    li   x6, -215
    vmv.v.x v12, x6
    vmv.v.v v3, v3
    vmv.v.v v7, v12
    vadd.vv v18, v20, v13
    vsub.vv v20, v3, v15
    vadd.vv v6, v17, v17
    vmv.v.i v0, -4
    vmerge.vvm v18, v1, v11, v0
    vmsleu.vv v0, v9, v21
    vmsne.vi v10, v15, 10
    vmorn.mm v0, v0, v10
    vadd.vi v20, v11, -6, v0.t
    vmax.vv v17, v20, v16
    vmv.x.s x12, v0
    addi a1, x31, 26
    vse8.v v5, (a1)
    lw   x7, 24(x31)
    vmv.x.s x6, v12
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -549
    vmv.v.x v22, x10
    li   x6, -1999
    vmv.v.x v11, x6
    vadd.vv v23, v2, v2
    vsub.vv v14, v6, v23
    vadd.vv v22, v14, v17
    vmsne.vv v0, v10, v8
    vmin.vv v13, v13, v23, v0.t
    vmax.vv v1, v9, v2
    vmv.x.s x12, v0
    addi a1, x31, 7
    vle8.v v9, (a1)
    vmv.x.s x5, v9
    vmv.x.s x11, v8
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v18, 0
    vmv.v.i v17, 3
    vadd.vv v19, v13, v22
    vsub.vv v7, v13, v14
    li   x5, 98
    vadd.vx v19, v11, x5
    vmv.v.i v0, -7
    vmerge.vvm v17, v2, v19, v0
    vmv.v.i v0, 0
    vmerge.vvm v5, v12, v22, v0
    li   x15, 991
    vadd.vx v15, v12, x15
    vmsle.vv v0, v2, v6
    vsub.vv v19, v15, v17, v0.t
    vmaxu.vv v3, v3, v22
    vmv.x.s x10, v0
    addi a1, x31, 5
    vle8.v v1, (a1)
    vmv.x.s x14, v1
    vmv.x.s x9, v21
    csrr t4, vstart
    ebreak

    .balign 4
data_area:
    .zero 64

