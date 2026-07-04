/* ADR-0036 gate_44 (directed half) — Stage 3D widening/reduction ops, exactly
 * the Phase 0 kernel instruction set: vwmul.vv, vwadd.wv (vd==vs2 accumulate),
 * vmv.s.x, vredsum.vs (vd==vs2). Probes via vmv.x.s + vse32/lw readback so the
 * 16- and 32-bit wide lanes are memory-verified, not just element 0.
 */
.section .init
.global _start

.macro CKPT
    csrr t2, vl
    csrr t3, vtype
    csrr t4, vstart
.endm

_start:
    li   t0, 0x200
    csrs mstatus, t0
    la   x31, data_area

    /* a[] = {1,2,3,4}, b[] = {2,3,4,5} packed as bytes */
    li   t0, 0x04030201
    sw   t0, 0(x31)
    li   t0, 0x05040302
    sw   t0, 4(x31)

    /* ---- vwmul.vv @ e8 mf4 (vl=4): products 2,6,12,20 in 16-bit lanes ---- */
    li   a0, 4
    vsetvli t1, a0, e8, mf4, ta, ma
    CKPT
    vle8.v v1, (x31)
    addi a1, x31, 4
    vle8.v v2, (a1)
    vwmul.vv v3, v1, v2
    /* switch to e16 mf2 (same ratio: keep-vl) and store the wide lanes */
    vsetvli x0, x0, e16, mf2, ta, ma
    CKPT
    addi a2, x31, 16
    vse16.v v3, (a2)
    lw   s0, 0(a2)               /* 0x00060002 (products 2,6) */
    lw   s1, 4(a2)               /* 0x0014000C (12,20) */

    /* ---- vwadd.wv accumulate with vd==vs2 (the kernel pattern) ---- */
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.v.i v8, 0                /* acc = 0 */
    vsetvli x0, x0, e16, mf2, ta, ma
    vwadd.wv v8, v8, v3          /* acc += products (widened to 32) */
    vwadd.wv v8, v8, v3          /* twice: 4,12,24,40 */
    vsetvli t1, a0, e32, m1, ta, ma
    CKPT
    addi a3, x31, 32
    vse32.v v8, (a3)
    lw   s2, 0(a3)               /* 4 */
    lw   s3, 4(a3)               /* 12 */
    lw   s4, 8(a3)               /* 24 */
    lw   s5, 12(a3)              /* 40 */

    /* ---- vmv.s.x + vredsum.vs (vd==vs2) @ e32 m1 ---- */
    li   t0, 100
    vmv.s.x v9, t0               /* v9[0] = 100, elements 1..3 untouched */
    vredsum.vs v8, v8, v9        /* v8[0] = 100 + (4+12+24+40) = 180 */
    vmv.x.s s6, v8               /* 180 */

    /* ---- negative operands: sign correctness through widening ---- */
    li   a0, 4
    vsetvli t1, a0, e8, mf4, ta, ma
    li   t0, 0xFF80817F          /* bytes 0x7F,0x81,0x80,0xFF = 127,-127,-128,-1 */
    sw   t0, 8(x31)
    addi a4, x31, 8
    vle8.v v4, (a4)
    vwmul.vv v5, v4, v4          /* squares: 16129, 16129, 16384, 1 */
    vsetvli x0, x0, e16, mf2, ta, ma
    addi a5, x31, 48
    vse16.v v5, (a5)
    lw   s7, 0(a5)               /* 0x3F013F01 */
    lw   s8, 4(a5)               /* 0x00014000 */
    /* widen-accumulate negatives: acc32 = -1 + -1 -> check sign extension */
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.v.i v10, -1
    vsetvli x0, x0, e16, mf2, ta, ma
    vwadd.wv v10, v10, v5
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.x.s s9, v10              /* -1 + 16129 = 16128 */

    /* ---- vredsum @ e16 (vl=6) ---- */
    li   a0, 6
    vsetvli t1, a0, e16, m1, ta, ma
    CKPT
    li   t0, 7
    vmv.v.x v11, t0              /* six 7s */
    li   t0, 2
    vmv.s.x v12, t0
    vredsum.vs v13, v11, v12     /* 2 + 6*7 = 44 */
    vmv.x.s s10, v13             /* sext16(44) */

    /* ---- vl=0 reduction / vmv.s.x are no-ops ---- */
    vsetivli t1, 0, e32, m1, ta, ma
    CKPT
    li   t0, 55
    vmv.s.x v8, t0               /* must NOT write */
    vredsum.vs v8, v8, v9        /* must NOT write */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.x.s s11, v8              /* still 180 */
    ebreak

    .balign 4
data_area:
    .zero 64
