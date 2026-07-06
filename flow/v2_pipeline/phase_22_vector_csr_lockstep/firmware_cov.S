/* ADR-0063 V1 closure: exercise the 45 uncovered Zve32x op-forms (.vi/.vx/.vv/.w*)
   so the instruction-coverage report ratchets up. Each op is OBSERVED via vse+lw
   (Spike-lockstep verified, green-wash guard G2 — not toggle-only). Segment nf*eew
   matrix stays a representative-coverage waiver (ADR-0063). Spike rv32imf_zve32x_zvl128b. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x22, dst

    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    li t2, 5;    vmv.v.x v2, t2          /* 5  */
    li t2, 3;    vmv.v.x v3, t2          /* 3  */
    li t2, 0xFE; vmv.v.x v5, t2          /* -2 signed / 254u */
    lla x21, mbits; li t2, 0x55; sb t2, 0(x21); vle8.v v0, (x21)   /* v0 mask 0x55 */

    /* ===== integer .vx / .vi ===== */
    li t2, 3
    vand.vi  v6, v2, 3;   vse8.v v6,(x22); lw t3,0(x22)
    vor.vx   v6, v2, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vsll.vi  v6, v2, 2;   vse8.v v6,(x22); lw t3,0(x22)
    vsrl.vi  v6, v5, 1;   vse8.v v6,(x22); lw t3,0(x22)
    vmax.vx  v6, v5, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vmaxu.vx v6, v5, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vmin.vx  v6, v5, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vminu.vx v6, v5, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vremu.vx v6, v2, t2;  vse8.v v6,(x22); lw t3,0(x22)   /* 5%3=2 */

    /* ===== compares -> mask v1 ===== */
    vmseq.vx  v1, v2, t2; vse8.v v1,(x22); lw t3,0(x22)
    vmsne.vx  v1, v2, t2; vse8.v v1,(x22); lw t3,0(x22)
    vmsgtu.vx v1, v2, t2; vse8.v v1,(x22); lw t3,0(x22)
    vmsgt.vi  v1, v2, 3;  vse8.v v1,(x22); lw t3,0(x22)
    vmsgtu.vi v1, v2, 3;  vse8.v v1,(x22); lw t3,0(x22)
    vmsle.vx  v1, v2, t2; vse8.v v1,(x22); lw t3,0(x22)
    vmsle.vi  v1, v2, 5;  vse8.v v1,(x22); lw t3,0(x22)
    vmsleu.vv v1, v2, v3; vse8.v v1,(x22); lw t3,0(x22)
    vmsleu.vx v1, v2, t2; vse8.v v1,(x22); lw t3,0(x22)
    vmsleu.vi v1, v2, 5;  vse8.v v1,(x22); lw t3,0(x22)

    /* ===== mask logic vmnor.mm (two mask sources) ===== */
    vmseq.vx v1, v2, t2
    vmsne.vx v7, v2, t2
    vmnor.mm v6, v1, v7;  vse8.v v6,(x22); lw t3,0(x22)

    /* ===== merge (v0 mask) ===== */
    li t2, 9
    vmerge.vxm v6, v2, t2, v0; vse8.v v6,(x22); lw t3,0(x22)
    vmerge.vim v6, v2, 7, v0;  vse8.v v6,(x22); lw t3,0(x22)

    /* ===== averaging (csrw vxrm before) ===== */
    csrw vxrm, x0
    li t2, 3
    vaadd.vx  v6, v2, t2; vse8.v v6,(x22); lw t3,0(x22)
    vaaddu.vx v6, v2, t2; vse8.v v6,(x22); lw t3,0(x22)
    vasub.vx  v6, v2, t2; vse8.v v6,(x22); lw t3,0(x22)
    vasubu.vv v6, v2, v3; vse8.v v6,(x22); lw t3,0(x22)
    vasubu.vx v6, v2, t2; vse8.v v6,(x22); lw t3,0(x22)

    /* ===== saturating ===== */
    li t2, 0x7F
    vsadd.vx  v6, v5, t2; vse8.v v6,(x22); lw t3,0(x22)
    vsadd.vi  v6, v5, 5;  vse8.v v6,(x22); lw t3,0(x22)
    vsaddu.vx v6, v2, t2; vse8.v v6,(x22); lw t3,0(x22)
    vsaddu.vi v6, v2, 5;  vse8.v v6,(x22); lw t3,0(x22)
    vssub.vx  v6, v5, t2; vse8.v v6,(x22); lw t3,0(x22)
    vssubu.vx v6, v2, t2; vse8.v v6,(x22); lw t3,0(x22)

    /* ===== scaling shift (vxrm) ===== */
    li t2, 1
    vssrl.vv v6, v5, v3;  vse8.v v6,(x22); lw t3,0(x22)
    vssrl.vx v6, v5, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vssra.vv v6, v5, v3;  vse8.v v6,(x22); lw t3,0(x22)
    vssra.vx v6, v5, t2;  vse8.v v6,(x22); lw t3,0(x22)

    /* ===== widening .vx / .wx (e8 mf2 -> e16) ===== */
    li a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    li t2, 7
    vwadd.vx  v8,  v2, t2
    vwsubu.vx v10, v2, t2
    vsetvli x0, x0, e16, m1, ta, ma
    li t3, 0x40; vmv.v.x v12, t3          /* e16 wide source */
    vsetvli x0, x0, e8, mf2, ta, ma
    vwaddu.wx v14, v12, t2
    vwsub.wx  v16, v12, t2
    vsetvli t1, a0, e16, m1, ta, ma
    vse16.v v8, (x22); lw t3,0(x22)
    vse16.v v10,(x22); lw t3,0(x22)
    vse16.v v14,(x22); lw t3,0(x22)
    vse16.v v16,(x22); lw t3,0(x22)

    /* ===== narrowing clip .wv / .wx (e16 src -> e8 dst) ===== */
    li a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    li t2, 0x140; vmv.v.x v12, t2         /* wide e16 source (>127 to show clip) */
    csrw vxrm, x0
    vsetvli t1, a0, e8, mf2, ta, ma
    li t2, 2; vmv.v.x v13, t2             /* shift amounts (SEW=8) */
    vnclip.wv  v6, v12, v13; vse8.v v6,(x22); lw t3,0(x22)
    vnclip.wx  v6, v12, t2;  vse8.v v6,(x22); lw t3,0(x22)
    vnclipu.wv v6, v12, v13; vse8.v v6,(x22); lw t3,0(x22)
    vnclipu.wx v6, v12, t2;  vse8.v v6,(x22); lw t3,0(x22)

    ebreak

.section .data
.align 6
mbits: .byte 0x55
.align 6
dst:   .space 32
