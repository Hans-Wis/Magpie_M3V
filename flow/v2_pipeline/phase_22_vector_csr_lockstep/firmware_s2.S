/* ADR-0049 S2 directed: saturating/averaging/scaling corners, Spike-arbitrated.
   Forwarding corners: csrr vxsat RIGHT AFTER a sat op (WB/MEM windows);
   csrw vxrm IMMEDIATELY before vaadd (eff_vxrm windows). */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0

    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    li   t2, 127
    vmv.v.x v1, t2
    vmv.v.i v2, 1
    li   t2, 0x80
    vmv.v.x v3, t2              /* -128 */
    vmv.v.i v4, 0

    /* signed sat add: 127+1 -> 127, vxsat=1; read IMMEDIATELY (fwd corner) */
    vsadd.vv v5, v1, v2
    csrr t3, vxsat
    csrr t4, vcsr
    vmv.x.s  t5, v5
    /* clear via vcsr write, then verify */
    csrw vcsr, x0
    csrr t3, vxsat
    /* no-sat op must NOT set (green-wash guard) */
    vsadd.vv v6, v4, v2
    csrr t3, vxsat
    vmv.x.s  t5, v6
    /* unsigned sat add: 255+1 */
    vmv.v.i v7, -1              /* 0xFF */
    vsaddu.vv v8, v7, v2
    csrr t3, vxsat
    vmv.x.s  t5, v8
    csrw vxsat, x0
    /* signed sat sub: -128-1; unsigned: 0-1 */
    vssub.vv v9, v3, v2
    csrr t3, vxsat
    csrw vcsr, x0
    vssubu.vv v10, v4, v2
    csrr t3, vxsat
    vmv.x.s  t5, v9
    vmv.x.s  t5, v10

    /* averaging: all four vxrm modes on odd sums (rounding visible) */
    vmv.v.i v11, 3
    vmv.v.i v12, 2              /* 3+2=5 -> 5>>1 rounding cases */
    li   t2, 0
    csrw vxrm, t2
    vaadd.vv v13, v11, v12
    vmv.x.s  t5, v13
    li   t2, 1
    csrw vxrm, t2
    vaadd.vv v13, v11, v12      /* csrw->vaadd back-to-back: eff_vxrm fwd */
    vmv.x.s  t5, v13
    li   t2, 2
    csrw vxrm, t2
    vasub.vv v13, v12, v11      /* 2-3=-1 -> -1>>1 signed */
    vmv.x.s  t5, v13
    li   t2, 3
    csrw vxrm, t2
    vaaddu.vv v13, v7, v2       /* 255+1=256>>1=128 */
    vmv.x.s  t5, v13
    csrr t3, vxsat              /* averaging never sets vxsat */

    /* scaling shifts: d=0 (no round) and d=3 with each mode */
    li   t2, 0
    csrw vxrm, t2
    vmv.v.i v14, 13             /* 13>>3 = 1.625 */
    vssrl.vi v15, v14, 3
    vmv.x.s  t5, v15
    vssrl.vi v15, v14, 0
    vmv.x.s  t5, v15
    li   t2, 1
    csrw vxrm, t2
    vssra.vi v16, v3, 3         /* -128>>>3 with rne */
    vmv.x.s  t5, v16
    li   t2, 3
    csrw vxrm, t2
    vssra.vi v16, v3, 2
    vmv.x.s  t5, v16

    /* masked sat: fully masked-off must not set vxsat */
    csrw vxsat, x0
    vmxor.mm v0, v0, v0         /* all-0 mask */
    vsadd.vv v17, v1, v2, v0.t
    csrr t3, vxsat
    vmv.x.s  t5, v17

    /* vnclip: fractional LMUL config (source EMUL=2*LMUL<=1) */
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    li   t2, 0x7FFF
    vmv.v.x v20, t2             /* SEW=8: bytes... build wide via e16 view */
    li   a0, 4
    vsetvli t1, a0, e16, mf2, ta, ma
    li   t2, 300
    vmv.v.x v21, t2             /* wide 16-bit values 300 */
    li   t2, -300
    vmv.v.x v22, t2
    li   a0, 4
    vsetvli t1, a0, e8, mf2, ta, ma
    csrw vxsat, x0
    vnclip.wi v23, v21, 0       /* 300 -> clip 127, sat */
    csrr t3, vxsat
    vmv.x.s  t5, v23
    csrw vxsat, x0
    vnclip.wi v24, v22, 1       /* -150 -> clip -128, sat */
    csrr t3, vxsat
    vmv.x.s  t5, v24
    csrw vxsat, x0
    vnclipu.wi v25, v21, 4      /* 300>>4=18(round) no sat */
    csrr t3, vxsat
    vmv.x.s  t5, v25

    /* Codex S2 corner: sat-op ; csrw vxsat,x0 ; csrr — the YOUNGER clear must
       win over the WB-window saturation overlay (back-to-back-to-back) */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vsadd.vv v27, v1, v2
    csrw vxsat, x0
    csrr t3, vxsat
    vsadd.vv v28, v1, v2
    csrw vcsr, x0
    csrr t4, vcsr

    /* vl=0: no effect on vxsat */
    csrw vxsat, x0
    li   a0, 0
    vsetvli t1, a0, e8, m1, ta, ma
    vsadd.vv v26, v1, v2
    csrr t3, vxsat
    csrr t4, vtype
    csrr t5, vstart

    ebreak
