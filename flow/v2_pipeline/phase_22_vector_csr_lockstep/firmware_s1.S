/* ADR-0049 S1 directed: mask pipeline corners (Grok DV list), Spike-arbitrated.
   vl in {0,1,VLMAX}; masks all-0/all-1/alternating; signed compare edges;
   mask-dest tail policy probed via vmv.x.s of v0 after short-vl compares. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0

    /* ---- e8/m1, vl=VLMAX=16 ---- */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    li   t2, 0x80              /* -128 as byte */
    vmv.v.x v1, t2
    li   t2, 127
    vmv.v.x v2, t2
    vmv.v.i v3, -1
    vmv.v.i v4, 0

    /* signed edges: -128 < 127, -1 vs 0 */
    vmslt.vv  v0, v1, v2       /* all 1s */
    vmv.x.s  t3, v0
    csrr     t4, vl
    vmsltu.vv v5, v1, v2       /* 0x80 >u 0x7f -> all 0s */
    vmv.x.s  t3, v5
    vmsle.vv  v6, v3, v4       /* -1 <= 0 -> all 1s */
    vmv.x.s  t3, v6
    li   t2, -1
    vmsgt.vx  v7, v4, t2       /* 0 > -1 -> all 1s */
    vmv.x.s  t3, v7
    vmseq.vi  v8, v4, 0        /* all 1s */
    vmv.x.s  t3, v8

    /* alternating mask: v9 = (v1 == v1) & pattern via compares of a ramp */
    vid_setup:
    li   t2, 0
    vmv.v.x v10, t2
    vadd.vi v10, v10, 1        /* all 1s * ... make a ramp via repeated adds */
    vadd.vv v11, v10, v10      /* 2s */
    vmseq.vv v0, v10, v10      /* all-1 mask */
    /* masked ops under all-1 (== unmasked) */
    vadd.vv v12, v1, v2, v0.t
    vmv.x.s  t3, v12
    /* build alternating: compare ramp parity is hard without vand; use vmxor trick */
    vmxor.mm v0, v0, v0        /* all-0 mask */
    vmv.x.s  t3, v0
    vadd.vv v13, v1, v2, v0.t  /* fully masked-off: v13 must stay old */
    vmv.v.i v13, 5             /* now overwrite (also proves prior kept) */
    vmv.x.s  t3, v13

    /* mask logicals ladder over known masks */
    vmseq.vv v14, v1, v1       /* all 1 */
    vmslt.vv v15, v2, v1       /* all 0 */
    vmand.mm  v16, v14, v15
    vmv.x.s  t3, v16
    vmor.mm   v16, v14, v15
    vmv.x.s  t3, v16
    vmnand.mm v16, v14, v15
    vmv.x.s  t3, v16
    vmxnor.mm v16, v14, v15
    vmv.x.s  t3, v16
    vmandn.mm v16, v14, v15
    vmv.x.s  t3, v16
    vmorn.mm  v16, v15, v14
    vmv.x.s  t3, v16

    /* min/max signed vs unsigned on edge values */
    vmax.vv  v17, v1, v2
    vmv.x.s  t3, v17
    vmaxu.vv v18, v1, v2
    vmv.x.s  t3, v18
    vmin.vv  v19, v1, v2
    vmv.x.s  t3, v19
    vminu.vv v20, v1, v2
    vmv.x.s  t3, v20

    /* ---- vl=1 ---- */
    li   a0, 1
    vsetvli t1, a0, e8, m1, tu, ma
    vmsne.vv v21, v1, v2       /* only bit0 written; tail bits = policy */
    vmv.x.s  t3, v21
    vmax.vv  v22, v1, v2
    vmv.x.s  t3, v22

    /* ---- vl=0: no update at all ---- */
    li   a0, 0
    vsetvli t1, a0, e8, m1, ta, ma
    vmv.v.i v23, 9             /* vl=0 -> no-op */
    vmseq.vv v23, v1, v2       /* vl=0 -> no-op */
    li   a0, 4
    vsetvli t1, a0, e8, m1, ta, ma
    vmv.x.s  t3, v23

    /* ---- e16 / e32 spot checks ---- */
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    li   t2, -30000
    vmv.v.x v24, t2
    li   t2, 30000
    vmv.v.x v25, t2
    vmslt.vv v0, v24, v25
    vmv.x.s  t3, v0
    vmax.vv  v26, v24, v25, v0.t
    vmv.x.s  t3, v26
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vminu.vv v27, v24, v25
    vmv.x.s  t3, v27
    csrr t4, vstart
    csrr t5, vtype

    /* terminator: masked body op writing v0 = ILLEGAL (dest overlaps mask;
       Spike-confirmed by Codex S1 review) — both sides trap here, ending the
       trace at the same commit. ebreak below is unreachable. */
    vadd.vv v0, v1, v2, v0.t

    ebreak
