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
    vsetvli t1, a0, e8, m1, tu, ma
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
    addi a1, x31, 6
    vse8.v v14, (a1)
    lw   x11, 4(x31)
    vmv.x.s x12, v16
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -1754
    vmv.v.x v17, x6
    li   x10, 1626
    vmv.v.x v12, x10
    vmv.v.i v0, 4
    vmerge.vvm v6, v2, v8, v0
    vadd.vi v6, v23, -5
    vmv.v.i v0, -15
    vmerge.vvm v18, v22, v11, v0
    vadd.vv v9, v23, v2
    vadd.vv v7, v9, v18
    vmseq.vv v0, v2, v6
    vadd.vi v15, v8, -1, v0.t
    vmaxu.vv v1, v8, v7
    vmv.x.s x7, v0
    li   t0, 2
    csrw vxrm, t0
    vaaddu.vv v13, v17, v2
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x11, v13
    addi a1, x31, 0
    vle8.v v19, (a1)
    vmv.x.s x5, v19
    vmv.x.s x9, v6
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, m4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v16, 0
    li   x14, -1477
    vmv.v.x v12, x14
    vmv.v.i v0, 2
    vmerge.vvm v4, v16, v16, v0
    vadd.vv v20, v8, v16
    vadd.vv v4, v20, v20
    vadd.vv v12, v16, v20
    vmslt.vv v0, v4, v20
    li   x12, 127
    vmsgtu.vx v12, v20, x12
    vmnor.mm v0, v0, v12
    vadd.vv v20, v16, v8, v0.t
    vmin.vv v20, v8, v8
    vmv.x.s x12, v0
    li   t0, 2
    csrw vxrm, t0
    vssubu.vv v16, v16, v4
    vssra.vi v12, v20, 5
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x7, v16
    vmv.x.s x8, v8
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e16, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v10, -1
    li   x11, -1248
    vmv.v.x v14, x11
    vsub.vv v14, v16, v4
    vadd.vi v15, v14, 0
    li   x5, 1517
    vsub.vx v18, v20, x5
    vmsle.vv v0, v16, v20
    li   x11, 127
    vmsgtu.vx v14, v15, x11
    vmand.mm v0, v0, v14
    vmin.vv v12, v15, v20, v0.t
    vminu.vv v9, v10, v16
    vmv.x.s x14, v0
    li   t0, 3
    csrw vxrm, t0
    vasubu.vv v1, v18, v8
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x10, v1
    addi a1, x31, 22
    vle8.v v9, (a1)
    vmv.x.s x10, v9
    vmv.x.s x6, v18
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e32, m2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x15, 1741
    vmv.v.x v10, x15
    li   x14, 1723
    vmv.v.x v10, x14
    vadd.vv v16, v14, v18
    vadd.vv v14, v12, v10
    vmv.v.v v14, v20
    li   x8, -638
    vadd.vx v2, v14, x8
    vmsne.vv v0, v8, v20
    li   x12, 127
    vmsgtu.vx v6, v10, x12
    vmnand.mm v0, v0, v6
    vadd.vi v6, v18, 4, v0.t
    li   x8, -128
    vminu.vx v22, v2, x8
    vmv.x.s x12, v0
    li   t0, 0
    csrw vxrm, t0
    vssub.vv v22, v10, v20
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x15, v22
    addi a1, x31, 12
    vle16.v v14, (a1)
    vmv.x.s x9, v14
    vmv.x.s x14, v10
    csrr t4, vstart
    li   a0, 4
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -683
    vmv.v.x v15, x11
    vmv.v.i v11, -11
    li   x13, 616
    vadd.vx v22, v11, x13
    vadd.vv v12, v12, v14
    li   x10, -393
    vadd.vx v8, v20, x10
    vsub.vv v9, v10, v14
    vsub.vv v23, v18, v12
    vmsleu.vv v0, v2, v22
    vadd.vv v4, v14, v16, v0.t
    li   x14, -128
    vminu.vx v11, v23, x14
    vmv.x.s x11, v0
    li   t0, 3
    csrw vxrm, t0
    vsadd.vv v18, v12, v11
    vssra.vi v13, v8, 6
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v18
    addi a1, x31, 37
    vle8.v v8, (a1)
    vmv.x.s x5, v8
    vmv.x.s x8, v2
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, 4
    vmv.v.i v4, -7
    vmv.v.v v11, v20
    vadd.vi v13, v6, -10
    vadd.vv v9, v12, v2
    vadd.vv v10, v2, v23
    vmsne.vv v0, v6, v6
    vadd.vv v22, v15, v12, v0.t
    vmaxu.vv v1, v11, v23
    vmv.x.s x13, v0
    li   t0, 3
    csrw vxrm, t0
    vssubu.vv v11, v20, v22
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x15, v11
    addi a1, x31, 4
    vse8.v v20, (a1)
    lw   x12, 4(x31)
    vmv.x.s x5, v9
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e32, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, 1700
    vmv.v.x v13, x8
    li   x5, 252
    vmv.v.x v23, x5
    vsub.vv v10, v15, v6
    vmv.v.i v0, -13
    vmerge.vvm v12, v16, v13, v0
    vadd.vv v16, v16, v20
    vadd.vv v5, v12, v14
    vmseq.vv v0, v16, v6
    vmin.vv v20, v1, v20, v0.t
    vmax.vv v11, v5, v22
    vmv.x.s x9, v0
    li   t0, 3
    csrw vxrm, t0
    vssra.vv v13, v22, v14
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v13
    addi a1, x31, 54
    vse8.v v22, (a1)
    lw   x15, 52(x31)
    vmv.x.s x9, v23
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e8, m1, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -72
    vmv.v.x v13, x8
    vmv.v.i v5, -13
    vadd.vv v4, v4, v16
    vadd.vv v15, v5, v16
    vadd.vi v18, v13, -2
    vadd.vi v5, v10, 6
    vmsne.vv v0, v5, v9
    li   x10, -128
    vmsgtu.vx v20, v13, x10
    vmandn.mm v0, v0, v20
    vmin.vv v20, v12, v4, v0.t
    vmax.vv v5, v12, v14
    vmv.x.s x8, v0
    li   t0, 0
    csrw vxrm, t0
    vasubu.vv v16, v14, v11
    vssrl.vi v5, v2, 6
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x14, v16
    addi a1, x31, 31
    vse8.v v14, (a1)
    lw   x9, 28(x31)
    vmv.x.s x7, v11
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e8, m2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v22, 6
    li   x14, -1857
    vmv.v.x v8, x14
    vsub.vv v6, v2, v16
    vadd.vi v14, v16, 9
    vadd.vv v2, v18, v2
    vadd.vv v10, v14, v22
    li   x15, 1157
    vadd.vx v18, v20, x15
    vmsle.vv v0, v4, v16
    vadd.vv v20, v20, v18, v0.t
    vmaxu.vv v22, v12, v6
    vmv.x.s x10, v0
    li   t0, 3
    csrw vxrm, t0
    vssub.vv v22, v16, v18
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x9, v22
    vmv.x.s x9, v16
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e32, m2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x6, -1174
    vmv.v.x v10, x6
    li   x11, -1459
    vmv.v.x v4, x11
    vadd.vi v2, v16, -12
    vmv.v.i v0, 6
    vmerge.vvm v4, v6, v6, v0
    vadd.vi v22, v8, 4
    vmv.v.v v8, v16
    vmslt.vv v0, v12, v2
    li   x13, -1312
    vmsgt.vx v20, v16, x13
    vmand.mm v0, v0, v20
    vadd.vv v10, v12, v2, v0.t
    vmin.vv v2, v4, v12
    vmv.x.s x15, v0
    li   t0, 0
    csrw vxrm, t0
    vasubu.vv v12, v20, v22
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x14, v12
    addi a1, x31, 48
    vle16.v v18, (a1)
    vmv.x.s x13, v18
    vmv.x.s x13, v18
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v21, 5
    vmv.v.i v18, 6
    vmv.v.i v0, 2
    vmerge.vvm v4, v20, v8, v0
    vsub.vv v19, v14, v18
    vadd.vv v17, v2, v12
    vsub.vv v16, v22, v6
    li   x15, -674
    vadd.vx v11, v17, x15
    vmsltu.vv v0, v8, v14
    li   x11, -1
    vmsgtu.vx v3, v17, x11
    vmxnor.mm v0, v0, v3
    vmin.vv v16, v4, v22, v0.t
    vmax.vv v20, v10, v8
    vmv.x.s x9, v0
    li   t0, 0
    csrw vxrm, t0
    vssubu.vv v7, v4, v20
    vssrl.vi v9, v18, 7
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x13, v7
    addi a1, x31, 33
    vse8.v v4, (a1)
    lw   x13, 32(x31)
    vmv.x.s x8, v6
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 1487
    vmv.v.x v17, x7
    vmv.v.i v12, -10
    vmv.v.v v11, v19
    vadd.vv v20, v19, v6
    li   x15, -1430
    vadd.vx v4, v17, x15
    vmsltu.vv v0, v20, v10
    vmsne.vi v4, v12, -16
    vmxor.mm v0, v0, v4
    vmax.vv v9, v19, v21, v0.t
    vmaxu.vv v14, v7, v7
    vmv.x.s x5, v0
    li   t0, 1
    csrw vxrm, t0
    vasub.vv v10, v12, v11
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x7, v10
    addi a1, x31, 54
    vle8.v v11, (a1)
    vmv.x.s x8, v11
    vmv.x.s x8, v6
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e16, m4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v12, 2
    vmv.v.i v4, -15
    li   x8, -1894
    vadd.vx v4, v16, x8
    vmv.v.v v8, v20
    vadd.vi v4, v12, 1
    vmv.v.v v8, v8
    vadd.vv v20, v4, v12
    vmv.v.v v20, v20
    vmsne.vv v0, v16, v12
    vmax.vv v8, v12, v4, v0.t
    vmax.vv v8, v4, v20
    vmv.x.s x9, v0
    li   t0, 1
    csrw vxrm, t0
    vasub.vv v16, v16, v12
    vsadd.vi v20, v20, -12
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x8, v16
    vmv.x.s x10, v4
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e16, m2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, -1732
    vmv.v.x v12, x11
    vmv.v.i v2, -1
    vadd.vv v12, v8, v20
    vadd.vi v16, v2, -12
    li   x6, 1192
    vadd.vx v2, v4, x6
    vmv.v.v v8, v16
    vadd.vv v14, v2, v8
    vmsltu.vv v0, v12, v16
    li   x9, 127
    vmsgt.vx v22, v2, x9
    vmand.mm v0, v0, v22
    vadd.vi v16, v12, -1, v0.t
    li   x10, 0
    vmax.vx v4, v20, x10
    vmv.x.s x8, v0
    li   t0, 1
    csrw vxrm, t0
    vssrl.vv v2, v4, v16
    vssrl.vi v12, v12, 0
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x12, v2
    addi a1, x31, 46
    vse8.v v14, (a1)
    lw   x7, 44(x31)
    vmv.x.s x13, v8
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, mf4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v5, 1
    li   x7, 2040
    vmv.v.x v8, x7
    vsub.vv v5, v22, v12
    vsub.vv v8, v2, v12
    li   x7, -1233
    vadd.vx v10, v4, x7
    li   x8, 13
    vadd.vx v7, v5, x8
    vmv.v.v v1, v10
    vadd.vi v22, v20, -3
    vmseq.vv v0, v2, v14
    vmax.vv v18, v7, v10, v0.t
    li   x12, -128
    vmax.vx v7, v20, x12
    vmv.x.s x9, v0
    li   t0, 2
    csrw vxrm, t0
    vasub.vv v2, v16, v18
    vssrl.vi v1, v16, 5
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x15, v2
    addi a1, x31, 33
    vle8.v v13, (a1)
    vmv.x.s x15, v13
    vmv.x.s x13, v18
    csrr t4, vstart
    li   a0, 2
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v10, 11
    vmv.v.i v20, -3
    vadd.vi v5, v10, 13
    vadd.vi v18, v13, -10
    vadd.vv v2, v4, v5
    vadd.vv v18, v4, v20
    vmsltu.vv v0, v1, v18
    vmsne.vi v15, v7, 14
    vmor.mm v0, v0, v15
    vsub.vv v10, v16, v8, v0.t
    vminu.vv v10, v5, v1
    vmv.x.s x15, v0
    li   t0, 2
    csrw vxrm, t0
    vasubu.vv v13, v18, v7
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x12, v13
    addi a1, x31, 36
    vle32.v v10, (a1)
    vmv.x.s x7, v10
    vmv.x.s x12, v8
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, m4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, 156
    vmv.v.x v20, x13
    li   x6, 1009
    vmv.v.x v16, x6
    vmv.v.i v0, 2
    vmerge.vvm v20, v20, v8, v0
    vadd.vi v16, v16, -1
    vadd.vv v20, v12, v12
    vmv.v.v v16, v20
    vmv.v.i v0, -8
    vmerge.vvm v20, v20, v16, v0
    vmseq.vv v0, v16, v8
    vmseq.vi v12, v4, 7
    vmand.mm v0, v0, v12
    vsub.vv v8, v16, v4, v0.t
    vmin.vv v16, v16, v20
    vmv.x.s x14, v0
    li   t0, 0
    csrw vxrm, t0
    vaaddu.vv v8, v8, v20
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v8
    vmv.x.s x6, v20
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e32, m2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v10, -1
    vmv.v.i v10, 8
    vadd.vv v18, v12, v20
    vadd.vv v8, v4, v18
    vmv.v.i v0, 0
    vmerge.vvm v18, v12, v16, v0
    vmv.v.i v0, -14
    vmerge.vvm v8, v20, v20, v0
    vadd.vi v20, v8, 0
    vmsleu.vv v0, v20, v12
    vmin.vv v6, v12, v8, v0.t
    vmaxu.vv v6, v16, v16
    vmv.x.s x10, v0
    li   t0, 0
    csrw vxrm, t0
    vsaddu.vv v20, v6, v12
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x5, v20
    addi a1, x31, 10
    vse16.v v6, (a1)
    lw   x15, 8(x31)
    vmv.x.s x5, v4
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x9, 1937
    vmv.v.x v8, x9
    vmv.v.i v5, 14
    vsub.vv v19, v18, v12
    vadd.vv v20, v8, v5
    vadd.vi v22, v4, 14
    vmv.v.v v23, v12
    vadd.vv v15, v18, v18
    vmsltu.vv v0, v18, v23
    vsub.vv v1, v15, v15, v0.t
    vmin.vv v1, v10, v8
    vmv.x.s x12, v0
    li   t0, 3
    csrw vxrm, t0
    vssub.vv v19, v22, v8
    vsadd.vi v9, v4, -1
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v19
    addi a1, x31, 10
    vse8.v v1, (a1)
    lw   x15, 8(x31)
    vmv.x.s x7, v12
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v12, 7
    li   x8, -1708
    vmv.v.x v21, x8
    vadd.vi v10, v19, -7
    vadd.vv v7, v4, v21
    vmv.v.v v7, v22
    vadd.vv v2, v15, v15
    vmseq.vv v0, v4, v18
    vsub.vv v16, v8, v19, v0.t
    li   x15, -1
    vmax.vx v21, v10, x15
    vmv.x.s x7, v0
    li   t0, 2
    csrw vxrm, t0
    vsaddu.vv v21, v15, v16
    vsadd.vi v15, v4, 6
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x14, v21
    addi a1, x31, 43
    vse8.v v9, (a1)
    lw   x11, 40(x31)
    vmv.x.s x6, v23
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, -1662
    vmv.v.x v15, x12
    vmv.v.i v1, -7
    vmv.v.v v21, v4
    vmv.v.v v19, v19
    vadd.vv v4, v10, v12
    vadd.vv v3, v21, v23
    vsub.vv v15, v6, v19
    vmsne.vv v0, v22, v4
    li   x5, 127
    vmsgtu.vx v13, v20, x5
    vmxor.mm v0, v0, v13
    vmax.vv v14, v7, v16, v0.t
    li   x10, 127
    vmax.vx v5, v22, x10
    vmv.x.s x15, v0
    li   t0, 3
    csrw vxrm, t0
    vssub.vv v16, v10, v18
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x8, v16
    addi a1, x31, 24
    vse16.v v10, (a1)
    lw   x10, 24(x31)
    vmv.x.s x10, v20
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e8, m2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v14, -15
    vmv.v.i v14, 8
    vadd.vi v12, v8, 4
    vsub.vv v14, v2, v12
    vmv.v.i v0, -4
    vmerge.vvm v8, v2, v22, v0
    vadd.vi v2, v16, -16
    vmsle.vv v0, v20, v6
    vmsne.vi v10, v20, 0
    vmand.mm v0, v0, v10
    vmin.vv v10, v18, v18, v0.t
    vminu.vv v10, v16, v4
    vmv.x.s x7, v0
    li   t0, 2
    csrw vxrm, t0
    vssra.vv v4, v20, v22
    vssra.vi v2, v20, 3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v4
    vmv.x.s x12, v16
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e8, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v10, 14
    vmv.v.i v14, -9
    vadd.vi v18, v8, -13
    vsub.vv v6, v20, v18
    li   x13, -175
    vadd.vx v11, v12, x13
    vadd.vv v11, v20, v20
    vmsleu.vv v0, v11, v6
    li   x14, -984
    vmsgtu.vx v7, v12, x14
    vmand.mm v0, v0, v7
    vmin.vv v19, v18, v20, v0.t
    li   x15, 0
    vmax.vx v21, v22, x15
    vmv.x.s x9, v0
    li   t0, 3
    csrw vxrm, t0
    vasubu.vv v15, v7, v10
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v15
    addi a1, x31, 41
    vle8.v v3, (a1)
    vmv.x.s x15, v3
    vmv.x.s x5, v3
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e16, m4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, 1302
    vmv.v.x v8, x8
    li   x11, -212
    vmv.v.x v12, x11
    li   x13, 731
    vadd.vx v4, v12, x13
    li   x11, -271
    vadd.vx v12, v4, x11
    vadd.vi v4, v8, 2
    vadd.vv v8, v16, v20
    vmslt.vv v0, v16, v4
    li   x6, 406
    vmsgtu.vx v16, v20, x6
    vmor.mm v0, v0, v16
    vadd.vv v16, v4, v12, v0.t
    vminu.vv v20, v20, v4
    vmv.x.s x14, v0
    li   t0, 3
    csrw vxrm, t0
    vsaddu.vv v16, v8, v20
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x14, v16
    vmv.x.s x14, v12
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, m4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v20, 1
    li   x13, -868
    vmv.v.x v8, x13
    vmv.v.v v16, v4
    vadd.vv v16, v8, v4
    vadd.vi v4, v16, 1
    vsub.vv v4, v20, v4
    vmseq.vv v0, v4, v16
    vmax.vv v4, v8, v20, v0.t
    vmaxu.vv v4, v4, v16
    vmv.x.s x7, v0
    li   t0, 3
    csrw vxrm, t0
    vssra.vv v12, v16, v20
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x12, v12
    vmv.x.s x12, v20
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, m2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 679
    vmv.v.x v10, x11
    vmv.v.i v14, -5
    vmv.v.v v2, v16
    vadd.vv v10, v4, v20
    vadd.vv v18, v12, v2
    vadd.vv v14, v2, v16
    vmsltu.vv v0, v16, v8
    vmin.vv v2, v10, v16, v0.t
    li   x5, -1
    vminu.vx v8, v20, x5
    vmv.x.s x5, v0
    li   t0, 2
    csrw vxrm, t0
    vasubu.vv v6, v12, v20
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v6
    vmv.x.s x9, v18
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v15, 12
    vmv.v.i v2, -16
    vadd.vv v11, v15, v20
    li   x9, 12
    vadd.vx v16, v15, x9
    vsub.vv v1, v18, v20
    vadd.vv v15, v4, v11
    vmsleu.vv v0, v15, v2
    vadd.vv v20, v10, v8, v0.t
    li   x12, -1
    vminu.vx v18, v4, x12
    vmv.x.s x13, v0
    li   t0, 2
    csrw vxrm, t0
    vssub.vv v19, v12, v16
    vssra.vi v2, v18, 6
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v19
    addi a1, x31, 12
    vse16.v v20, (a1)
    lw   x15, 12(x31)
    vmv.x.s x10, v6
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e32, m2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, -1721
    vmv.v.x v18, x13
    vmv.v.i v16, 13
    vadd.vv v12, v20, v12
    li   x7, -1481
    vadd.vx v8, v4, x7
    vmv.v.v v14, v14
    vadd.vv v10, v4, v20
    vadd.vi v8, v12, -3
    vmsleu.vv v0, v2, v14
    vmseq.vi v14, v16, -5
    vmxor.mm v0, v0, v14
    vadd.vv v18, v8, v16, v0.t
    vmaxu.vv v22, v18, v4
    vmv.x.s x12, v0
    li   t0, 3
    csrw vxrm, t0
    vasubu.vv v20, v10, v2
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x6, v20
    addi a1, x31, 38
    vse8.v v8, (a1)
    lw   x13, 36(x31)
    vmv.x.s x5, v10
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, m2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x10, 1560
    vmv.v.x v14, x10
    li   x5, -1904
    vmv.v.x v12, x5
    vmv.v.v v16, v18
    vmv.v.i v0, 10
    vmerge.vvm v22, v14, v4, v0
    vadd.vv v18, v22, v14
    vadd.vv v22, v6, v2
    vmv.v.i v0, -13
    vmerge.vvm v6, v8, v10, v0
    vadd.vv v18, v18, v16
    vmsltu.vv v0, v14, v2
    vmax.vv v18, v14, v10, v0.t
    vmaxu.vv v20, v14, v4
    vmv.x.s x11, v0
    li   t0, 2
    csrw vxrm, t0
    vasub.vv v10, v10, v8
    vsadd.vi v10, v20, 13
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v10
    vmv.x.s x13, v12
    csrr t4, vstart
    li   a0, 0
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x14, 1712
    vmv.v.x v19, x14
    li   x14, -1585
    vmv.v.x v10, x14
    vsub.vv v22, v10, v22
    vsub.vv v18, v8, v14
    vadd.vv v19, v2, v22
    vmslt.vv v0, v10, v2
    vadd.vi v1, v18, 2, v0.t
    vmaxu.vv v22, v16, v16
    vmv.x.s x6, v0
    li   t0, 2
    csrw vxrm, t0
    vssub.vv v6, v18, v8
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v6
    addi a1, x31, 23
    vle8.v v13, (a1)
    vmv.x.s x8, v13
    vmv.x.s x9, v22
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x7, 321
    vmv.v.x v12, x7
    vmv.v.i v17, -14
    vmv.v.v v8, v10
    vadd.vi v10, v10, -7
    vadd.vi v5, v1, -4
    vadd.vv v21, v18, v6
    vmsleu.vv v0, v10, v8
    li   x7, 1702
    vmsgt.vx v5, v5, x7
    vmand.mm v0, v0, v5
    vmin.vv v3, v10, v22, v0.t
    vminu.vv v8, v1, v22
    vmv.x.s x6, v0
    li   t0, 0
    csrw vxrm, t0
    vssrl.vv v13, v14, v4
    vssrl.vi v21, v17, 0
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x9, v13
    addi a1, x31, 31
    vse8.v v13, (a1)
    lw   x12, 28(x31)
    vmv.x.s x14, v6
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e32, m2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v16, -3
    vmv.v.i v2, -14
    vmv.v.i v0, 15
    vmerge.vvm v12, v10, v22, v0
    vadd.vv v22, v18, v8
    vsub.vv v22, v22, v4
    vadd.vv v18, v4, v6
    vadd.vi v18, v20, 3
    vsub.vv v16, v16, v6
    vmsleu.vv v0, v18, v10
    vsub.vv v14, v10, v12, v0.t
    li   x7, 127
    vmax.vx v22, v8, x7
    vmv.x.s x5, v0
    li   t0, 1
    csrw vxrm, t0
    vssrl.vv v14, v8, v16
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x10, v14
    addi a1, x31, 48
    vse16.v v8, (a1)
    lw   x14, 48(x31)
    vmv.x.s x7, v20
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e32, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x11, 1744
    vmv.v.x v2, x11
    li   x10, -1703
    vmv.v.x v5, x10
    vadd.vv v6, v18, v12
    vadd.vv v22, v16, v10
    vadd.vv v4, v18, v12
    vadd.vv v6, v2, v5
    vadd.vv v20, v8, v16
    vmseq.vv v0, v8, v5
    li   x5, 0
    vmsgt.vx v14, v5, x5
    vmxnor.mm v0, v0, v14
    vadd.vi v23, v2, 9, v0.t
    vmaxu.vv v12, v10, v12
    vmv.x.s x11, v0
    li   t0, 0
    csrw vxrm, t0
    vasubu.vv v20, v16, v8
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v20
    addi a1, x31, 49
    vse8.v v2, (a1)
    lw   x6, 48(x31)
    vmv.x.s x6, v4
    csrr t4, vstart
    li   a0, 16
    vsetvli t1, a0, e8, mf2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v11, 12
    li   x12, -510
    vmv.v.x v7, x12
    li   x13, -4
    vadd.vx v4, v20, x13
    vadd.vv v5, v2, v4
    vadd.vv v15, v7, v7
    vmslt.vv v0, v15, v15
    li   x9, 127
    vmsgt.vx v20, v16, x9
    vmorn.mm v0, v0, v20
    vsub.vv v22, v5, v8, v0.t
    vminu.vv v17, v18, v20
    vmv.x.s x9, v0
    li   t0, 3
    csrw vxrm, t0
    vssubu.vv v13, v16, v5
    vsadd.vi v14, v5, -10
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x10, v13
    addi a1, x31, 2
    vse8.v v16, (a1)
    lw   x7, 0(x31)
    vmv.x.s x6, v18
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e8, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -1980
    vmv.v.x v17, x8
    li   x9, 2002
    vmv.v.x v11, x9
    vadd.vi v10, v17, 12
    vmv.v.v v20, v23
    vadd.vv v1, v22, v8
    vmv.v.v v12, v8
    vadd.vv v14, v2, v18
    vadd.vv v16, v14, v6
    vmsne.vv v0, v5, v14
    li   x8, 0
    vmsgt.vx v22, v13, x8
    vmxnor.mm v0, v0, v22
    vadd.vv v4, v22, v1, v0.t
    vminu.vv v5, v20, v10
    vmv.x.s x9, v0
    li   t0, 1
    csrw vxrm, t0
    vasub.vv v23, v14, v7
    vssrl.vi v16, v15, 3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x13, v23
    addi a1, x31, 5
    vse8.v v2, (a1)
    lw   x12, 4(x31)
    vmv.x.s x8, v5
    csrr t4, vstart
    li   a0, 3
    vsetvli t1, a0, e16, m1, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v1, 7
    li   x13, 1669
    vmv.v.x v22, x13
    vsub.vv v17, v22, v20
    vmv.v.i v0, 3
    vmerge.vvm v15, v23, v12, v0
    vmv.v.i v0, -3
    vmerge.vvm v11, v16, v15, v0
    vmv.v.v v14, v5
    vadd.vv v1, v6, v23
    vmsne.vv v0, v20, v2
    vadd.vi v8, v14, 7, v0.t
    vminu.vv v4, v20, v7
    vmv.x.s x9, v0
    li   t0, 2
    csrw vxrm, t0
    vssub.vv v18, v4, v8
    vssrl.vi v22, v4, 6
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v18
    addi a1, x31, 40
    vle16.v v10, (a1)
    vmv.x.s x9, v10
    vmv.x.s x5, v6
    csrr t4, vstart
    li   a0, 1
    vsetvli t1, a0, e16, m2, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x5, -1633
    vmv.v.x v18, x5
    vmv.v.i v8, 2
    vadd.vv v4, v4, v10
    vsub.vv v2, v18, v8
    vadd.vv v14, v6, v22
    vadd.vi v14, v18, -12
    vmseq.vv v0, v2, v6
    vadd.vi v16, v18, 5, v0.t
    vmaxu.vv v16, v12, v14
    vmv.x.s x12, v0
    li   t0, 3
    csrw vxrm, t0
    vaaddu.vv v14, v2, v4
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v14
    addi a1, x31, 13
    vle8.v v10, (a1)
    vmv.x.s x12, v10
    vmv.x.s x14, v20
    csrr t4, vstart
    li   a0, 15
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x8, -278
    vmv.v.x v14, x8
    vmv.v.i v22, -6
    vsub.vv v2, v22, v12
    vmv.v.i v0, -9
    vmerge.vvm v15, v22, v20, v0
    vmv.v.v v7, v15
    vsub.vv v13, v10, v2
    vadd.vv v17, v20, v20
    vmsle.vv v0, v16, v20
    vmin.vv v22, v17, v2, v0.t
    vmax.vv v1, v14, v13
    vmv.x.s x8, v0
    li   t0, 2
    csrw vxrm, t0
    vaaddu.vv v14, v10, v2
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x13, v14
    addi a1, x31, 1
    vle8.v v18, (a1)
    vmv.x.s x13, v18
    vmv.x.s x9, v12
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e8, mf4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v7, 1
    vmv.v.i v2, 2
    vmv.v.i v0, -5
    vmerge.vvm v19, v10, v10, v0
    vadd.vv v1, v19, v10
    li   x13, 1450
    vadd.vx v13, v12, x13
    vmsne.vv v0, v20, v14
    vmin.vv v6, v15, v22, v0.t
    li   x5, 0
    vminu.vx v2, v19, x5
    vmv.x.s x10, v0
    li   t0, 2
    csrw vxrm, t0
    vsadd.vv v4, v1, v4
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x9, v4
    addi a1, x31, 34
    vle16.v v1, (a1)
    vmv.x.s x6, v1
    vmv.x.s x5, v18
    csrr t4, vstart
    li   a0, 7
    vsetvli t1, a0, e16, m4, tu, ma
    csrr t2, vl
    csrr t3, vtype
    li   x13, 1686
    vmv.v.x v20, x13
    vmv.v.i v12, 9
    vsub.vv v12, v20, v16
    vmv.v.i v0, 3
    vmerge.vvm v4, v8, v12, v0
    vadd.vv v8, v12, v8
    vsub.vv v12, v12, v20
    li   x14, -61
    vadd.vx v4, v4, x14
    vmsleu.vv v0, v8, v16
    vmax.vv v20, v4, v12, v0.t
    li   x10, -1
    vmax.vx v8, v20, x10
    vmv.x.s x9, v0
    li   t0, 3
    csrw vxrm, t0
    vsaddu.vv v12, v20, v8
    vssrl.vi v4, v8, 1
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x5, v12
    vmv.x.s x13, v8
    csrr t4, vstart
    li   a0, 8
    vsetvli t1, a0, e8, m2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v20, 0
    vmv.v.i v18, 3
    vadd.vi v12, v18, -12
    vmv.v.i v0, -10
    vmerge.vvm v6, v16, v4, v0
    vsub.vv v12, v8, v18
    vsub.vv v6, v20, v20
    vmseq.vv v0, v16, v18
    vmin.vv v20, v12, v16, v0.t
    vminu.vv v12, v16, v12
    vmv.x.s x7, v0
    li   t0, 0
    csrw vxrm, t0
    vsaddu.vv v2, v12, v6
    vsadd.vi v14, v6, -3
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x10, v2
    vmv.x.s x7, v20
    csrr t4, vstart
    li   a0, 100
    vsetvli t1, a0, e16, mf2, tu, ma
    csrr t2, vl
    csrr t3, vtype
    vmv.v.i v19, 13
    li   x10, 1966
    vmv.v.x v12, x10
    vsub.vv v3, v12, v20
    vsub.vv v17, v2, v3
    vadd.vv v11, v8, v16
    li   x8, 1407
    vsub.vx v8, v17, x8
    vmv.v.v v1, v12
    vadd.vv v11, v19, v3
    vmsne.vv v0, v18, v8
    vmin.vv v15, v16, v6, v0.t
    li   x7, 127
    vmax.vx v1, v2, x7
    vmv.x.s x8, v0
    li   t0, 3
    csrw vxrm, t0
    vssubu.vv v5, v12, v20
    csrr t4, vxsat
    csrr t5, vcsr
    vmv.x.s x7, v5
    addi a1, x31, 28
    vle16.v v7, (a1)
    vmv.x.s x14, v7
    vmv.x.s x14, v17
    csrr t4, vstart
    li   a0, 31
    vsetvli t1, a0, e8, m4, ta, ma
    csrr t2, vl
    csrr t3, vtype
    li   x12, 925
    vmv.v.x v4, x12
    li   x12, -670
    vmv.v.x v20, x12
    li   x6, -1978
    vsub.vx v4, v8, x6
    vsub.vv v4, v8, v20
    vmv.v.v v8, v16
    vmsne.vv v0, v16, v4
    vmsne.vi v20, v20, 13
    vmand.mm v0, v0, v20
    vadd.vi v16, v8, 6, v0.t
    vminu.vv v12, v20, v8
    vmv.x.s x14, v0
    li   t0, 3
    csrw vxrm, t0
    vsadd.vv v16, v20, v20
    vsadd.vi v16, v4, -12
    csrr t4, vxsat
    csrr t5, vcsr
    csrw vxsat, x0
    vmv.x.s x15, v16
    vmv.x.s x8, v4
    csrr t4, vstart
    ebreak

    .balign 4
data_area:
    .zero 64

