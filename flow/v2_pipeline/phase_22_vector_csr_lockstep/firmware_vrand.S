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
    li   t0, 3
    csrw vxrm, t0
    vaaddu.vv v11, v16, v23
    vsadd.vi v6, v6, 11
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v11
    addi a1, x31, 55
    vle8.v v8, (a1)
    vmv.x.s x9, v8
    vmv.x.s x11, v23
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v19, -13
    vmv.v.i v4, 8
    vadd.vv v15, v14, v6
    vadd.vv v22, v6, v16
    vmv.v.i v0, -5
    vmerge.vvm v1, v2, v19, v0
    vmv.v.i v0, 1
    vmerge.vvm v8, v22, v1, v0
    vadd.vv v7, v6, v19
    vmseq.vv v0, v1, v2
    vadd.vi v15, v6, -1, v0.t
    vmaxu.vv v1, v6, v4
    vmv.x.s x7, v0
    li   t0, 2
    csrw vxrm, t0
    vaaddu.vv v13, v22, v2
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x11, v13
    addi a1, x31, 0
    vle8.v v19, (a1)
    vmv.x.s x5, v19
    vmv.x.s x9, v2
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v14, 0
    li   x14, -1477
    vmv.v.x v9, x14
    vmv.v.i v0, 2
    vmerge.vvm v2, v16, v19, v0
    vadd.vv v18, v6, v9
    vadd.vv v4, v14, v11
    vmv.v.v v19, v18
    vmsle.vv v0, v15, v4
    vadd.vv v8, v9, v15, v0.t
    li   x13, 127
    vminu.vx v16, v15, x13
    vmv.x.s x15, v0
    li   t0, 1
    csrw vxrm, t0
    vssrl.vv v2, v16, v7
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x12, v2
    addi a1, x31, 24
    vse16.v v23, (a1)
    lw   x5, 24(x31)
    vmv.x.s x7, v9
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -915
    vmv.v.x v22, x10
    vmv.v.i v7, 3
    li   x13, -1165
    vadd.vx v19, v14, x13
    vsub.vv v1, v19, v18
    vadd.vv v19, v2, v19
    vadd.vi v11, v2, 13
    vmsle.vv v0, v13, v1
    vadd.vi v16, v18, 9, v0.t
    vmaxu.vv v9, v9, v18
    vmv.x.s x7, v0
    li   t0, 3
    csrw vxrm, t0
    vaaddu.vv v6, v13, v23
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x11, v6
    addi a1, x31, 0
    vle8.v v3, (a1)
    vmv.x.s x13, v3
    vmv.x.s x9, v3
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v12, 0
    vmv.v.i v12, -14
    vadd.vv v21, v18, v12
    vadd.vv v18, v18, v22
    vmv.v.v v8, v9
    vadd.vv v16, v15, v15
    vadd.vi v8, v23, -5
    vmsltu.vv v0, v12, v21
    li   x7, 0
    vmsgt.vx v8, v6, x7
    vmnor.mm v0, v0, v8
    vadd.vv v4, v22, v7, v0.t
    vmin.vv v5, v2, v19
    vmv.x.s x15, v0
    li   t0, 2
    csrw vxrm, t0
    vaaddu.vv v10, v11, v8
    vssra.vi v21, v23, 3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v10
    addi a1, x31, 56
    vle16.v v22, (a1)
    vmv.x.s x7, v22
    vmv.x.s x9, v22
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v22, -12
    vmv.v.i v7, 0
    vadd.vv v9, v19, v13
    vmv.v.v v6, v11
    vadd.vv v12, v3, v10
    li   x13, 616
    vadd.vx v22, v12, x13
    vmslt.vv v0, v4, v23
    li   x10, 127
    vmsgtu.vx v23, v13, x10
    vmxor.mm v0, v0, v23
    vadd.vv v9, v15, v10, v0.t
    vmax.vv v2, v14, v5
    vmv.x.s x5, v0
    li   t0, 2
    csrw vxrm, t0
    vssra.vv v23, v18, v14
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x11, v23
    addi a1, x31, 0
    vle32.v v5, (a1)
    vmv.x.s x11, v5
    vmv.x.s x13, v14
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, -26
    vmv.v.x v3, x14
    vmv.v.i v8, -16
    vadd.vv v12, v9, v22
    vmv.v.i v0, -2
    vmerge.vvm v3, v5, v22, v0
    vsub.vv v8, v14, v15
    vadd.vi v13, v4, -10
    vmslt.vv v0, v1, v9
    vadd.vi v1, v18, -2, v0.t
    vmin.vv v11, v10, v6
    vmv.x.s x7, v0
    li   t0, 0
    csrw vxrm, t0
    vaadd.vv v10, v4, v1
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x13, v10
    addi a1, x31, 20
    vle16.v v17, (a1)
    vmv.x.s x15, v17
    vmv.x.s x12, v22
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, -284
    vmv.v.x v16, x5
    li   x8, 1168
    vmv.v.x v12, x8
    li   x9, -1556
    vadd.vx v8, v23, x9
    li   x9, 819
    vsub.vx v9, v13, x9
    vadd.vv v5, v13, v2
    vmslt.vv v0, v14, v11
    li   x12, 0
    vmsgt.vx v14, v21, x12
    vmnor.mm v0, v0, v14
    vmax.vv v22, v4, v22, v0.t
    vmax.vv v1, v1, v1
    vmv.x.s x12, v0
    li   t0, 2
    csrw vxrm, t0
    vsaddu.vv v2, v17, v9
    vssra.vi v20, v21, 5
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v2
    addi a1, x31, 44
    vse32.v v23, (a1)
    lw   x15, 44(x31)
    vmv.x.s x9, v23
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v7, -2
    li   x7, 104
    vmv.v.x v20, x7
    li   x6, -1880
    vadd.vx v2, v12, x6
    li   x11, 1694
    vadd.vx v3, v6, x11
    vadd.vv v6, v14, v18
    vmv.v.v v18, v11
    li   x8, -920
    vadd.vx v23, v16, x8
    vmv.v.i v0, 6
    vmerge.vvm v8, v4, v7, v0
    vmsltu.vv v0, v17, v6
    vmin.vv v20, v21, v8, v0.t
    vminu.vv v6, v4, v18
    vmv.x.s x9, v0
    li   t0, 0
    csrw vxrm, t0
    vssub.vv v20, v3, v10
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x8, v20
    addi a1, x31, 46
    vle8.v v12, (a1)
    vmv.x.s x9, v12
    vmv.x.s x8, v5
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 1955
    vmv.v.x v20, x7
    vmv.v.i v22, 7
    vadd.vi v6, v14, -6
    li   x8, 872
    vadd.vx v16, v7, x8
    vadd.vi v20, v11, -8
    vmv.v.i v0, 14
    vmerge.vvm v13, v18, v4, v0
    vmv.v.v v23, v16
    vmsltu.vv v0, v2, v7
    vadd.vv v17, v1, v9, v0.t
    li   x13, -128
    vmax.vx v16, v20, x13
    vmv.x.s x13, v0
    li   t0, 2
    csrw vxrm, t0
    vsadd.vv v20, v12, v2
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x5, v20
    addi a1, x31, 48
    vle32.v v5, (a1)
    vmv.x.s x10, v5
    vmv.x.s x11, v21
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, 671
    vmv.v.x v10, x13
    vmv.v.i v21, -10
    vmv.v.i v0, 8
    vmerge.vvm v3, v5, v23, v0
    vadd.vi v2, v15, -12
    vmv.v.i v0, 6
    vmerge.vvm v3, v6, v6, v0
    vmsleu.vv v0, v20, v1
    li   x12, 127
    vmsgtu.vx v2, v23, x12
    vmand.mm v0, v0, v2
    vadd.vi v14, v17, -11, v0.t
    li   x9, 0
    vmax.vx v1, v8, x9
    vmv.x.s x6, v0
    li   t0, 2
    csrw vxrm, t0
    vssrl.vv v20, v2, v1
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x15, v20
    addi a1, x31, 22
    vse8.v v19, (a1)
    lw   x15, 20(x31)
    vmv.x.s x6, v19
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, -12
    li   x13, -1772
    vmv.v.x v17, x13
    vsub.vv v12, v10, v4
    vadd.vv v20, v15, v10
    vmv.v.i v0, -3
    vmerge.vvm v1, v11, v16, v0
    vadd.vv v11, v5, v11
    vmv.v.i v0, -6
    vmerge.vvm v17, v16, v7, v0
    vmsltu.vv v0, v9, v6
    vsub.vv v13, v20, v21, v0.t
    li   x14, -1
    vmax.vx v3, v9, x14
    vmv.x.s x8, v0
    li   t0, 2
    csrw vxrm, t0
    vssubu.vv v3, v8, v3
    vssrl.vi v4, v20, 5
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x15, v3
    addi a1, x31, 42
    vse16.v v3, (a1)
    lw   x13, 40(x31)
    vmv.x.s x15, v22
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v4, 10
    li   x7, 1487
    vmv.v.x v11, x7
    vmv.v.i v0, -10
    vmerge.vvm v2, v11, v20, v0
    li   x12, -1185
    vadd.vx v15, v4, x12
    vadd.vv v23, v3, v21
    vsub.vv v13, v23, v22
    vadd.vi v16, v7, -11
    vmsleu.vv v0, v15, v4
    vmin.vv v1, v19, v15, v0.t
    vminu.vv v6, v14, v14
    vmv.x.s x8, v0
    li   t0, 1
    csrw vxrm, t0
    vsadd.vv v5, v8, v10
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x9, v5
    addi a1, x31, 25
    vle8.v v5, (a1)
    vmv.x.s x8, v5
    vmv.x.s x13, v11
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -460
    vmv.v.x v21, x11
    vmv.v.i v12, 2
    vsub.vv v10, v15, v4
    vadd.vv v21, v17, v1
    vmv.v.v v15, v15
    vmsleu.vv v0, v17, v3
    vadd.vi v9, v20, -6, v0.t
    vmaxu.vv v19, v14, v11
    vmv.x.s x8, v0
    li   t0, 1
    csrw vxrm, t0
    vssub.vv v4, v10, v13
    vssrl.vi v23, v9, 1
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x11, v4
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
    li   t0, 1
    csrw vxrm, t0
    vssra.vv v11, v11, v3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v11
    addi a1, x31, 12
    vse32.v v5, (a1)
    lw   x5, 12(x31)
    vmv.x.s x15, v18
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, 1487
    vmv.v.x v1, x10
    li   x8, 1709
    vmv.v.x v1, x8
    vadd.vv v6, v5, v18
    vmv.v.i v0, -16
    vmerge.vvm v20, v11, v5, v0
    vsub.vv v13, v8, v22
    vmsltu.vv v0, v6, v16
    vadd.vi v17, v20, 1, v0.t
    li   x13, 0
    vminu.vx v10, v21, x13
    vmv.x.s x14, v0
    li   t0, 0
    csrw vxrm, t0
    vssubu.vv v3, v21, v21
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x5, v3
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
    li   t0, 1
    csrw vxrm, t0
    vssub.vv v10, v13, v1
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x12, v10
    addi a1, x31, 30
    vse16.v v23, (a1)
    lw   x13, 28(x31)
    vmv.x.s x13, v4
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, -1056
    vmv.v.x v23, x13
    li   x7, 365
    vmv.v.x v10, x7
    vadd.vv v7, v9, v13
    vmv.v.v v15, v22
    vadd.vi v4, v19, -12
    vmv.v.i v0, -6
    vmerge.vvm v16, v12, v19, v0
    vsub.vv v18, v18, v20
    vmv.v.v v15, v18
    vmsleu.vv v0, v9, v13
    vmax.vv v3, v13, v17, v0.t
    vmaxu.vv v23, v20, v5
    vmv.x.s x9, v0
    li   t0, 2
    csrw vxrm, t0
    vssra.vv v14, v23, v23
    vssra.vi v5, v3, 6
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x11, v14
    addi a1, x31, 5
    vle8.v v11, (a1)
    vmv.x.s x6, v11
    vmv.x.s x10, v2
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, 4
    vmv.v.i v23, -2
    li   x8, 1053
    vadd.vx v10, v9, x8
    vmv.v.i v0, -12
    vmerge.vvm v6, v11, v7, v0
    vmv.v.i v0, -11
    vmerge.vvm v3, v3, v17, v0
    vadd.vv v18, v8, v10
    vadd.vv v3, v8, v9
    vadd.vv v3, v19, v13
    vmslt.vv v0, v17, v2
    li   x5, -128
    vmsgtu.vx v8, v9, x5
    vmorn.mm v0, v0, v8
    vsub.vv v18, v2, v8, v0.t
    li   x6, -128
    vmax.vx v8, v2, x6
    vmv.x.s x6, v0
    li   t0, 1
    csrw vxrm, t0
    vssubu.vv v14, v18, v6
    vssra.vi v20, v4, 5
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v14
    addi a1, x31, 34
    vle16.v v2, (a1)
    vmv.x.s x13, v2
    vmv.x.s x12, v6
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, 12
    li   x9, 1937
    vmv.v.x v8, x9
    li   x15, 681
    vadd.vx v9, v19, x15
    vmv.v.v v10, v16
    li   x12, -1
    vadd.vx v12, v3, x12
    vadd.vi v22, v1, 14
    vmsleu.vv v0, v23, v7
    li   x12, -128
    vmsgt.vx v4, v18, x12
    vmxnor.mm v0, v0, v4
    vadd.vv v1, v19, v3, v0.t
    vmin.vv v11, v8, v15
    vmv.x.s x11, v0
    li   t0, 1
    csrw vxrm, t0
    vasubu.vv v10, v17, v9
    vsadd.vi v20, v23, -12
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v10
    addi a1, x31, 16
    vse32.v v14, (a1)
    lw   x5, 16(x31)
    vmv.x.s x15, v5
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v13, 9
    li   x15, -43
    vmv.v.x v17, x15
    vadd.vv v8, v9, v12
    vmv.v.i v0, -4
    vmerge.vvm v6, v6, v2, v0
    vmv.v.v v23, v14
    vmsne.vv v0, v16, v2
    vmseq.vi v10, v4, -12
    vmandn.mm v0, v0, v10
    vadd.vv v16, v11, v21, v0.t
    li   x15, 1
    vmax.vx v9, v8, x15
    vmv.x.s x15, v0
    li   t0, 0
    csrw vxrm, t0
    vssub.vv v9, v9, v21
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v9
    addi a1, x31, 38
    vle16.v v12, (a1)
    vmv.x.s x6, v12
    vmv.x.s x5, v2
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -1478
    vmv.v.x v14, x6
    li   x11, 1627
    vmv.v.x v15, x11
    vmv.v.i v0, -16
    vmerge.vvm v6, v9, v5, v0
    vmv.v.v v12, v10
    vadd.vi v3, v14, -10
    vadd.vv v2, v10, v3
    vadd.vv v1, v16, v18
    vsub.vv v15, v6, v15
    vmsne.vv v0, v22, v18
    vadd.vv v14, v9, v6, v0.t
    vminu.vv v10, v16, v17
    vmv.x.s x13, v0
    li   t0, 1
    csrw vxrm, t0
    vssubu.vv v23, v22, v13
    vssrl.vi v13, v17, 2
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x12, v23
    addi a1, x31, 30
    vle16.v v23, (a1)
    vmv.x.s x9, v23
    vmv.x.s x12, v16
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, 2
    vmv.v.i v11, 9
    vsub.vv v14, v22, v1
    vsub.vv v13, v13, v5
    vadd.vi v11, v8, 4
    vsub.vv v13, v2, v11
    vmv.v.i v0, -4
    vmerge.vvm v7, v1, v21, v0
    vadd.vi v2, v15, -16
    vmsle.vv v0, v19, v23
    vmax.vv v6, v20, v2, v0.t
    li   x14, -128
    vmax.vx v2, v14, x14
    vmv.x.s x7, v0
    li   t0, 3
    csrw vxrm, t0
    vssrl.vv v18, v22, v22
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x9, v18
    addi a1, x31, 28
    vle16.v v18, (a1)
    vmv.x.s x9, v18
    vmv.x.s x6, v19
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, 749
    vmv.v.x v19, x8
    li   x12, -1247
    vmv.v.x v3, x12
    vmv.v.v v10, v15
    li   x11, -87
    vadd.vx v5, v22, x11
    vmv.v.v v4, v18
    vadd.vv v15, v18, v2
    vsub.vv v6, v19, v17
    li   x13, -175
    vadd.vx v11, v12, x13
    vmslt.vv v0, v7, v14
    vmax.vv v21, v7, v19, v0.t
    li   x12, 0
    vmax.vx v1, v15, x12
    vmv.x.s x13, v0
    li   t0, 0
    csrw vxrm, t0
    vasub.vv v6, v6, v20
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x14, v6
    addi a1, x31, 44
    vse8.v v23, (a1)
    lw   x9, 44(x31)
    vmv.x.s x11, v15
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v17, 4
    li   x11, -1517
    vmv.v.x v4, x11
    li   x9, -100
    vadd.vx v2, v18, x9
    vmv.v.v v8, v22
    vmv.v.v v14, v12
    vmsne.vv v0, v14, v8
    vmax.vv v21, v12, v9, v0.t
    vmax.vv v7, v2, v15
    vmv.x.s x12, v0
    li   t0, 1
    csrw vxrm, t0
    vssubu.vv v10, v7, v13
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v10
    addi a1, x31, 44
    vse8.v v21, (a1)
    lw   x11, 44(x31)
    vmv.x.s x6, v10
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v14, 15
    li   x9, 1586
    vmv.v.x v13, x9
    li   x11, -1419
    vadd.vx v22, v18, x11
    li   x14, 1672
    vadd.vx v15, v15, x14
    vmv.v.i v0, -5
    vmerge.vvm v17, v17, v4, v0
    vmsleu.vv v0, v19, v20
    li   x14, -136
    vmsgtu.vx v9, v9, x14
    vmxor.mm v0, v0, v9
    vsub.vv v17, v7, v21, v0.t
    vmax.vv v2, v19, v20
    vmv.x.s x11, v0
    li   t0, 2
    csrw vxrm, t0
    vaaddu.vv v4, v21, v18
    vssra.vi v21, v15, 0
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v4
    addi a1, x31, 54
    vle16.v v13, (a1)
    vmv.x.s x15, v13
    vmv.x.s x15, v14
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 1971
    vmv.v.x v20, x11
    vmv.v.i v1, -16
    vadd.vi v5, v19, 9
    vmv.v.v v19, v2
    vmv.v.i v0, 14
    vmerge.vvm v18, v13, v11, v0
    vmv.v.v v12, v14
    vadd.vi v21, v13, 15
    vadd.vv v23, v1, v5
    vmsleu.vv v0, v10, v8
    vmsne.vi v17, v8, 2
    vmand.mm v0, v0, v17
    vadd.vi v13, v14, 11, v0.t
    vmax.vv v16, v16, v2
    vmv.x.s x15, v0
    li   t0, 0
    csrw vxrm, t0
    vsaddu.vv v16, v8, v23
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x15, v16
    addi a1, x31, 3
    vse8.v v23, (a1)
    lw   x5, 0(x31)
    vmv.x.s x10, v5
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -1607
    vmv.v.x v17, x6
    li   x13, -151
    vmv.v.x v10, x13
    vadd.vi v23, v11, 13
    vadd.vv v11, v2, v6
    vadd.vv v22, v7, v11
    vsub.vv v8, v21, v16
    vadd.vv v23, v9, v9
    vadd.vv v18, v21, v15
    vmseq.vv v0, v20, v5
    vadd.vv v21, v19, v3, v0.t
    li   x5, -128
    vminu.vx v21, v23, x5
    vmv.x.s x12, v0
    li   t0, 0
    csrw vxrm, t0
    vssrl.vv v6, v12, v19
    vssrl.vi v22, v2, 3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x14, v6
    addi a1, x31, 52
    vse16.v v12, (a1)
    lw   x5, 52(x31)
    vmv.x.s x11, v7
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, 226
    vmv.v.x v8, x15
    li   x13, -1721
    vmv.v.x v17, x13
    li   x10, 854
    vadd.vx v3, v4, x10
    vadd.vi v20, v7, -6
    vadd.vv v3, v14, v15
    vmv.v.v v13, v10
    vsub.vv v3, v20, v8
    vsub.vv v17, v12, v7
    vmsleu.vv v0, v23, v2
    vmseq.vi v14, v15, -5
    vmxor.mm v0, v0, v14
    vmin.vv v23, v20, v9, v0.t
    li   x12, 127
    vminu.vx v16, v3, x12
    vmv.x.s x15, v0
    li   t0, 1
    csrw vxrm, t0
    vsaddu.vv v18, v15, v14
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x12, v18
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
    li   t0, 1
    csrw vxrm, t0
    vsaddu.vv v14, v13, v12
    vssrl.vi v14, v13, 3
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x7, v14
    addi a1, x31, 38
    vse16.v v11, (a1)
    lw   x13, 36(x31)
    vmv.x.s x10, v6
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, -1585
    vmv.v.x v10, x14
    vmv.v.i v21, 9
    vmv.v.v v9, v18
    vadd.vv v13, v14, v19
    vsub.vv v2, v1, v9
    vmslt.vv v0, v1, v20
    vadd.vi v19, v10, 10, v0.t
    vmaxu.vv v22, v16, v16
    vmv.x.s x6, v0
    li   t0, 2
    csrw vxrm, t0
    vssub.vv v6, v20, v10
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v6
    addi a1, x31, 40
    vle32.v v4, (a1)
    vmv.x.s x11, v4
    vmv.x.s x11, v7
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, 26
    vmv.v.x v3, x10
    li   x9, -38
    vmv.v.x v5, x9
    vadd.vv v5, v12, v10
    vsub.vv v19, v5, v5
    vmv.v.v v19, v20
    vmsne.vv v0, v21, v5
    vmsne.vi v17, v22, -7
    vmnand.mm v0, v0, v17
    vsub.vv v6, v5, v6, v0.t
    vmin.vv v21, v8, v14
    vmv.x.s x7, v0
    li   t0, 0
    csrw vxrm, t0
    vssub.vv v8, v7, v19
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x12, v8
    addi a1, x31, 32
    vse8.v v3, (a1)
    lw   x6, 32(x31)
    vmv.x.s x11, v17
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, 9
    vmv.v.i v19, 1
    vmv.v.i v0, 3
    vmerge.vvm v16, v19, v6, v0
    vmv.v.i v0, 15
    vmerge.vvm v16, v7, v5, v0
    vadd.vv v18, v7, v13
    li   x11, 2035
    vadd.vx v2, v11, x11
    vmslt.vv v0, v22, v21
    li   x11, -1
    vmsgtu.vx v22, v18, x11
    vmand.mm v0, v0, v22
    vadd.vv v17, v4, v23, v0.t
    vmaxu.vv v16, v22, v18
    vmv.x.s x9, v0
    li   t0, 3
    csrw vxrm, t0
    vssubu.vv v2, v9, v11
    vssra.vi v20, v11, 1
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x13, v2
    addi a1, x31, 28
    vse8.v v2, (a1)
    lw   x8, 28(x31)
    vmv.x.s x11, v18
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -693
    vmv.v.x v5, x10
    li   x14, -642
    vmv.v.x v7, x14
    vsub.vv v12, v17, v14
    vadd.vi v17, v5, 7
    vadd.vi v2, v6, -10
    vsub.vv v20, v8, v20
    vsub.vv v18, v8, v3
    vmsle.vv v0, v14, v6
    li   x14, -128
    vmsgt.vx v6, v9, x14
    vmand.mm v0, v0, v6
    vmin.vv v10, v5, v5, v0.t
    li   x12, -128
    vminu.vx v12, v9, x12
    vmv.x.s x12, v0
    li   t0, 0
    csrw vxrm, t0
    vssubu.vv v13, v10, v3
    vssrl.vi v6, v13, 6
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x12, v13
    addi a1, x31, 26
    vse16.v v11, (a1)
    lw   x7, 24(x31)
    vmv.x.s x14, v1
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, -1384
    vmv.v.x v4, x15
    vmv.v.i v11, 12
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
    li   t0, 3
    csrw vxrm, t0
    vsaddu.vv v6, v2, v5
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x9, v6
    addi a1, x31, 24
    vle32.v v12, (a1)
    vmv.x.s x6, v12
    vmv.x.s x8, v14
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -542
    vmv.v.x v7, x10
    li   x14, 1174
    vmv.v.x v2, x14
    vmv.v.v v3, v6
    vadd.vv v7, v17, v17
    vmv.v.i v0, -4
    vmerge.vvm v18, v1, v11, v0
    vmv.v.v v22, v21
    vmsltu.vv v0, v19, v14
    vmsne.vi v15, v20, -3
    vmand.mm v0, v0, v15
    vmin.vv v3, v17, v2, v0.t
    vminu.vv v16, v4, v14
    vmv.x.s x10, v0
    li   t0, 1
    csrw vxrm, t0
    vsaddu.vv v6, v12, v7
    vssra.vi v3, v12, 3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v6
    addi a1, x31, 56
    vse16.v v4, (a1)
    lw   x15, 56(x31)
    vmv.x.s x13, v1
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v2, 8
    li   x6, -789
    vmv.v.x v6, x6
    vmv.v.i v0, 3
    vmerge.vvm v8, v23, v13, v0
    li   x8, 379
    vadd.vx v12, v16, x8
    vadd.vv v14, v23, v18
    vadd.vv v1, v9, v2
    vadd.vv v15, v9, v7
    vadd.vv v9, v8, v12
    vmsleu.vv v0, v13, v18
    vmseq.vi v17, v14, 0
    vmnor.mm v0, v0, v17
    vmin.vv v15, v13, v14, v0.t
    vmax.vv v20, v1, v9
    vmv.x.s x10, v0
    li   t0, 1
    csrw vxrm, t0
    vssub.vv v19, v17, v2
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x9, v19
    addi a1, x31, 22
    vse8.v v20, (a1)
    lw   x15, 20(x31)
    vmv.x.s x10, v12
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v19, -9
    li   x7, 308
    vmv.v.x v15, x7
    vmv.v.v v18, v6
    vadd.vv v3, v22, v12
    vadd.vv v13, v3, v1
    vadd.vv v20, v21, v15
    vmv.v.v v17, v9
    vmseq.vv v0, v23, v5
    li   x11, -1
    vmsgt.vx v18, v8, x11
    vmandn.mm v0, v0, v18
    vadd.vi v4, v4, -16, v0.t
    li   x8, 127
    vmax.vx v14, v7, x8
    vmv.x.s x11, v0
    li   t0, 1
    csrw vxrm, t0
    vasub.vv v22, v18, v4
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x6, v22
    addi a1, x31, 9
    vse8.v v16, (a1)
    lw   x13, 8(x31)
    vmv.x.s x9, v17
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 1228
    vmv.v.x v10, x11
    vmv.v.i v11, -8
    vmv.v.i v0, 9
    vmerge.vvm v13, v12, v1, v0
    vadd.vi v3, v12, -13
    vadd.vv v19, v7, v1
    vmv.v.v v23, v16
    vadd.vi v20, v7, 14
    vmsltu.vv v0, v14, v8
    vadd.vi v7, v6, 6, v0.t
    li   x15, -1
    vminu.vx v14, v15, x15
    vmv.x.s x15, v0
    li   t0, 1
    csrw vxrm, t0
    vasub.vv v16, v13, v2
    vsadd.vi v17, v23, -5
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x7, v16
    addi a1, x31, 52
    vle8.v v1, (a1)
    vmv.x.s x13, v1
    vmv.x.s x5, v4
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 819
    vmv.v.x v10, x11
    vmv.v.i v7, -15
    vmv.v.v v21, v18
    vadd.vv v1, v22, v18
    vmv.v.i v0, -2
    vmerge.vvm v1, v12, v4, v0
    vadd.vv v7, v9, v2
    vmseq.vv v0, v14, v18
    li   x7, -514
    vmsgt.vx v16, v7, x7
    vmnand.mm v0, v0, v16
    vmax.vv v1, v13, v23, v0.t
    vmaxu.vv v18, v5, v16
    vmv.x.s x9, v0
    li   t0, 1
    csrw vxrm, t0
    vaadd.vv v10, v3, v10
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x13, v10
    addi a1, x31, 26
    vle8.v v11, (a1)
    vmv.x.s x13, v11
    vmv.x.s x14, v2
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, -1150
    vmv.v.x v15, x10
    vmv.v.i v2, -11
    vsub.vv v3, v9, v18
    vmv.v.v v1, v3
    li   x15, 928
    vsub.vx v1, v23, x15
    vmsltu.vv v0, v21, v19
    vadd.vi v23, v11, -2, v0.t
    vminu.vv v10, v9, v17
    vmv.x.s x12, v0
    li   t0, 3
    csrw vxrm, t0
    vaadd.vv v23, v3, v5
    vsadd.vi v8, v5, 0
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x15, v23
    addi a1, x31, 16
    vse32.v v21, (a1)
    lw   x13, 16(x31)
    vmv.x.s x5, v23
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, 1260
    vmv.v.x v2, x8
    li   x13, -1520
    vmv.v.x v21, x13
    li   x8, -720
    vsub.vx v13, v21, x8
    vadd.vv v1, v21, v20
    vmv.v.i v0, 6
    vmerge.vvm v4, v17, v10, v0
    vmv.v.v v23, v12
    vadd.vi v3, v7, -15
    vmsltu.vv v0, v3, v11
    vmseq.vi v2, v18, -8
    vmandn.mm v0, v0, v2
    vmin.vv v13, v12, v16, v0.t
    li   x7, -1
    vminu.vx v3, v4, x7
    vmv.x.s x7, v0
    li   t0, 3
    csrw vxrm, t0
    vaaddu.vv v3, v11, v23
    vssrl.vi v6, v3, 0
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x15, v3
    addi a1, x31, 40
    vle16.v v10, (a1)
    vmv.x.s x11, v10
    vmv.x.s x6, v2
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, -1440
    vmv.v.x v13, x7
    li   x12, -995
    vmv.v.x v2, x12
    vsub.vv v14, v7, v8
    vsub.vv v21, v21, v18
    vmv.v.i v0, 15
    vmerge.vvm v19, v10, v15, v0
    vmv.v.v v12, v12
    vsub.vv v16, v14, v13
    vmsleu.vv v0, v9, v20
    vmax.vv v9, v16, v8, v0.t
    vmax.vv v19, v15, v13
    vmv.x.s x10, v0
    li   t0, 1
    csrw vxrm, t0
    vssub.vv v2, v7, v12
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v2
    addi a1, x31, 42
    vse16.v v3, (a1)
    lw   x7, 40(x31)
    vmv.x.s x7, v19
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -1388
    vmv.v.x v18, x11
    li   x12, -871
    vmv.v.x v7, x12
    vmv.v.i v0, 7
    vmerge.vvm v1, v5, v9, v0
    vadd.vv v15, v7, v19
    vadd.vi v23, v20, -15
    vmv.v.v v4, v15
    vmslt.vv v0, v19, v18
    vmax.vv v15, v1, v8, v0.t
    li   x15, 0
    vmax.vx v6, v22, x15
    vmv.x.s x11, v0
    li   t0, 1
    csrw vxrm, t0
    vsadd.vv v15, v12, v22
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x14, v15
    addi a1, x31, 3
    vle8.v v12, (a1)
    vmv.x.s x7, v12
    vmv.x.s x9, v23
    csrr t4, vstart
    ebreak

    .balign 4
data_area:
    .zero 64

