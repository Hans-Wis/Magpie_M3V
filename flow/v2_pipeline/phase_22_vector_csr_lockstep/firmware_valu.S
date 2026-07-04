/* ADR-0036 gate_42 — Stage 3B vector-ALU directed lockstep.
 * Every vector op is followed by scalar-visible probes: vmv.x.s (element 0)
 * and csrr checkpoints (P0④ discipline). Whole-register content authority
 * arrives with vector stores in 3C; this gate locks element-0 semantics,
 * sign extension, vmerge masking, fractional-LMUL execution, vl=0 no-op,
 * vstart splicing, and the RAW path through the WB-commit VRF.
 * Registers are always written before they are read (VRF reset state is not
 * part of the contract).
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

    /* ---- e32 m1 (vl=4): OPIVV/OPIVX/OPIVI + vmv family ---- */
    li   a0, 8
    vsetvli t1, a0, e32, m1, ta, ma
    CKPT
    vmv.v.i v1, 5
    csrr s0, vstart               /* cleared by the vector op */
    li   a1, 0x1234
    vmv.v.x v2, a1
    vadd.vv v3, v1, v2
    vmv.x.s t5, v3                /* 0x1239 */
    vsub.vv v4, v2, v1
    vmv.x.s t6, v4                /* 0x122F */
    vadd.vi v5, v3, -3
    vmv.x.s s1, v5                /* 0x1236 */
    li   a2, 100
    vadd.vx v6, v3, a2
    vmv.x.s s2, v6                /* 0x129D */
    vsub.vx v14, v2, a2
    vmv.x.s s3, v14               /* 0x11D0 */

    /* ---- vmerge with v0 mask (elem0 mask bit = v0[0]) ---- */
    vmv.v.i v0, 5                 /* v0[0]=1 -> take vs1 side */
    vmerge.vvm v7, v1, v2, v0
    vmv.x.s s4, v7                /* 0x1234 */
    vmv.v.i v0, 4                 /* v0[0]=0 -> take vs2 side */
    vmerge.vvm v7, v1, v2, v0
    vmv.x.s s5, v7                /* 5 */

    /* ---- e8 mf4 fractional (vl=4 of 16) + 8-bit sign extension ---- */
    li   a0, 100
    vsetvli t1, a0, e8, mf4, ta, ma
    CKPT
    vmv.v.i v8, -1
    vadd.vi v9, v8, 2
    vmv.x.s s6, v9                /* sext8(1) = 1 */
    vmv.v.i v9, -3
    vmv.x.s s7, v9                /* sext8(0xFD) = -3 */

    /* ---- e16 m1 (vl=3, tu) + 16-bit sign extension ---- */
    li   a0, 3
    vsetvli t1, a0, e16, m1, tu, ma
    CKPT
    vmv.v.x v10, a1
    vadd.vv v11, v10, v10
    vmv.x.s s8, v11               /* 0x2468 */
    li   a3, -2
    vmv.v.x v12, a3
    vmv.x.s s9, v12               /* sext16(0xFFFE) = -2 */

    /* ---- vl=0: arithmetic is a no-op; vmv.x.s still reads elem 0 ---- */
    vsetivli t1, 0, e32, m1, ta, ma
    CKPT
    vadd.vv v3, v1, v2            /* must NOT change v3 */
    vmv.x.s s10, v3               /* still 0x1239 */

    /* ---- vstart round-trip: arithmetic with vstart!=0 is ILLEGAL (Spike
     * choice, matched in vexu) — so no vector op here until vsetvli clears it */
    li   t0, 2
    csrw vstart, t0
    csrr s11, vstart              /* 2 */
    li   a0, 8
    vsetvli t1, a0, e32, m1, tu, ma
    csrr a4, vstart               /* cleared by vsetvli -> 0 */

    /* ---- back-to-back vector ops (RAW через WB-commit stall path) ---- */
    li   a0, 8
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.v.i v20, 7
    vadd.vv v21, v20, v20
    vadd.vv v22, v21, v21
    vadd.vv v23, v22, v21
    vmv.x.s a5, v23               /* 7*2*2 + 7*2 = 42 */
    ebreak
