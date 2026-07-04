/* ADR-0049 S3 directed: LMUL m2/m4 register groups — atomic group commit.
   Corners (Grok list): vl at part boundaries {16,17,32}, masked groups with
   v0 bits spanning parts, saturation raised only in a LATER part, group
   compares to one mask register, group merge/mv, SEW sweep. Terminator =
   odd-vd@m2 (group alignment illegal, Spike-arbitrated). */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    la   x31, data_area

    /* ---- e8 m2: vl=32 full group ---- */
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    li   t2, 3
    vmv.v.x v2, t2              /* group v2..v3 */
    li   t2, 5
    vmv.v.x v4, t2
    vadd.vv v6, v2, v4          /* full-group add */
    vmv.x.s t3, v6
    vmax.vv v8, v2, v4
    vmv.x.s t3, v8

    /* vl=17: crosses the part boundary by one element */
    li   a0, 17
    vsetvli t1, a0, e8, m2, tu, ma
    vadd.vi v10, v2, 7
    vmv.x.s t3, v10
    /* vl=16: exactly one part; part 1 must stay undisturbed */
    li   a0, 16
    vsetvli t1, a0, e8, m2, tu, ma
    vsub.vv v10, v4, v2
    vmv.x.s t3, v10

    /* group compare -> ONE mask register (33 bits would exceed; vl=32) */
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    vmsne.vv v0, v2, v4         /* all-1s mask, 32 bits */
    vmv.x.s t3, v0
    /* masked group op under that mask; then alternating via compare */
    vadd.vv v12, v2, v4, v0.t
    vmv.x.s t3, v12
    vmseq.vv v1, v2, v2         /* NOTE: v1 legal mask dest (single reg) */
    vmv.x.s t3, v1

    /* group saturation: part 0 benign, part 1 saturates */
    li   a0, 32
    vsetvli t1, a0, e8, m2, tu, ma
    li   t2, 100
    vmv.v.x v14, t2             /* whole group = 100 */
    li   a0, 16
    vsetvli t1, a0, e8, m2, tu, ma
    li   t2, 1
    vmv.v.x v14, t2             /* part 0 elements = 1 (vl=16) */
    li   a0, 32
    vsetvli t1, a0, e8, m2, tu, ma
    csrw vxsat, x0
    vsadd.vv v16, v14, v14      /* part0: 2 (no sat), part1: 200 -> 127 sat */
    csrr t3, vxsat
    vmv.x.s t4, v16

    /* group merge + group vmv.v.v */
    vmerge.vvm v18, v2, v4, v0
    vmv.x.s t3, v18
    vmv.v.v v20, v16
    vmv.x.s t3, v20

    /* ---- e16 m4: vl=32 (4 parts x 8) ---- */
    li   a0, 32
    vsetvli t1, a0, e16, m4, ta, ma
    li   t2, -2000
    vmv.v.x v8, t2
    li   t2, 1999
    vmv.v.x v12, t2
    vadd.vv v16, v8, v12
    vmv.x.s t3, v16
    vmin.vv v20, v8, v12
    vmv.x.s t3, v20
    vmsle.vv v3, v8, v12        /* group cmp at m4 */
    vmv.x.s t3, v3

    /* ---- e32 m2: vl=8 ---- */
    li   a0, 8
    vsetvli t1, a0, e32, m2, ta, ma
    li   t2, 0x40000000
    vmv.v.x v22, t2
    csrw vxsat, x0
    vsadd.vv v24, v22, v22      /* every element saturates */
    csrr t3, vxsat
    vmv.x.s t4, v24
    csrr t5, vl
    csrr t6, vtype

    /* terminator: ODD vd with m2 = group misalignment illegal */
    li   a0, 16
    vsetvli t1, a0, e8, m2, ta, ma
    vadd.vv v7, v2, v4

    ebreak
    .balign 4
data_area:
    .zero 64
