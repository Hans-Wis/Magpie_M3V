/* ADR-0036 gate_43 — Stage 3C unit-stride vector load/store directed lockstep.
 * Memory authority = the commit stream itself: every vector-store target is
 * read back with scalar lw (values compared vs Spike bit-exact), and every
 * vector load reads a region initialized by scalar sw. The DONE mailbox /
 * CSR windows are untouched (buffers live in low TCM).
 * Covers: vle8/vle16/vle32, vse16/vse32, EEW!=SEW (vle8 under e32),
 * partial-vl stores proving tail-undisturbed in memory, vl=0 no-ops,
 * vstart!=0 resumable load, and scalar/vector memory interleave.
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

    /* init 8 words via scalar stores (vector loads read these) */
    li   t0, 0x11223344
    sw   t0, 0(x31)
    li   t0, 0x55667788
    sw   t0, 4(x31)
    li   t0, 0x99AABBCC
    sw   t0, 8(x31)
    li   t0, 0xDDEEFF01
    sw   t0, 12(x31)
    li   t0, 0x0F1E2D3C
    sw   t0, 16(x31)
    li   t0, 0x4B5A6978
    sw   t0, 20(x31)
    li   t0, 0x87A6C5E4
    sw   t0, 24(x31)
    li   t0, 0x13579BDF
    sw   t0, 28(x31)

    /* ---- vle8 @ e8 mf4 (vl=4): bytes 44,33,22,11 ---- */
    li   a0, 100
    vsetvli t1, a0, e8, mf4, ta, ma
    CKPT
    vle8.v v1, (x31)
    vmv.x.s s0, v1                /* sext8(0x44) = 0x44 */
    vadd.vi v2, v1, 1
    vmv.x.s s1, v2                /* 0x45 */

    /* ---- vle32 @ e32 m1 (vl=4) ---- */
    vsetvli t1, a0, e32, m1, ta, ma
    CKPT
    vle32.v v3, (x31)
    vmv.x.s s2, v3                /* 0x11223344 */
    vadd.vi v4, v3, 3
    vmv.x.s s3, v4                /* 0x11223347 */

    /* ---- vse32 partial vl: only vl elements stored ---- */
    addi a1, x31, 32              /* out region */
    li   t0, 0x0BAD0000
    sw   t0, 40(x31)              /* sentinel at out+8 (element 2 slot) */
    li   a0, 2
    vsetvli t1, a0, e32, m1, ta, ma
    vse32.v v3, (a1)              /* stores elements 0,1 only */
    lw   s4, 0(a1)                /* 0x11223344 */
    lw   s5, 4(a1)                /* 0x55667788 */
    lw   s6, 8(a1)                /* sentinel intact = 0x0BAD0000 */

    /* ---- store a full register after partial writes: memory view of the
     * undisturbed policy (elements 2,3 of v5 come from the vl=4 vmv below) ---- */
    li   a0, 4
    vsetvli t1, a0, e32, m1, tu, ma
    li   t0, 0x0C0FFEE0
    vmv.v.x v5, t0                /* all 4 elems known */
    li   a0, 2
    vsetvli t1, a0, e32, m1, tu, ma
    li   t0, 0x0DEADBE0
    vmv.v.x v5, t0                /* elems 0,1 overwritten; 2,3 undisturbed */
    li   a0, 4
    vsetvli t1, a0, e32, m1, tu, ma
    addi a2, x31, 48
    vse32.v v5, (a2)
    lw   a4, 0(a2)                /* 0x0DEADBE0 */
    lw   a5, 4(a2)                /* 0x0DEADBE0 */
    lw   a6, 8(a2)                /* 0x0C0FFEE0 */
    lw   a7, 12(a2)               /* 0x0C0FFEE0 */

    /* ---- vle16/vse16 @ e16 m1 (vl=3) ---- */
    li   a0, 3
    vsetvli t1, a0, e16, m1, tu, ma
    CKPT
    vle16.v v6, (x31)
    vmv.x.s s7, v6                /* sext16(0x3344) */
    addi a3, x31, 64
    li   t0, 0x7A7B0000
    sw   t0, 68(x31)              /* sentinel word covering halves 2,3 */
    vse16.v v6, (a3)              /* 3 halves stored */
    lw   s8, 0(a3)
    lw   s9, 4(a3)                /* low half = 0x9AB..? compared vs Spike */

    /* ---- EEW != SEW: vle8 under e32 m1 (EMUL=mf4, vl=4 bytes) ---- */
    li   a0, 100
    vsetvli t1, a0, e32, m1, ta, ma
    vle8.v v7, (x31)              /* 4 bytes packed into elem0 */
    vmv.x.s s10, v7               /* 0x11223344 (LE byte pack) */

    /* ---- vl=0: load and store are no-ops ---- */
    vsetivli t1, 0, e32, m1, ta, ma
    CKPT
    vle32.v v3, (a1)              /* must NOT change v3 */
    vse32.v v3, (a2)              /* must NOT touch memory */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.x.s s11, v3               /* still 0x11223344 */
    lw   t5, 0(a2)                /* still 0x0DEADBE0 */

    /* ---- vstart!=0 load (resumable): elements 0,1 undisturbed ---- */
    li   a0, 4
    vsetvli t1, a0, e32, m1, tu, ma
    li   t0, 0x21212121
    vmv.v.x v8, t0                /* known base content */
    li   t0, 2
    csrw vstart, t0
    vle32.v v8, (x31)             /* resumes at element 2 */
    csrr t4, vstart               /* cleared -> 0 */
    vmv.x.s t6, v8                /* elem0 = 0x21212121 (below vstart) */
    addi a2, x31, 80
    vse32.v v8, (a2)
    lw   t5, 0(a2)                /* 0x21212121 */
    lw   t5, 8(a2)                /* 0x99AABBCC (loaded from element-2 addr) */
    lw   t5, 12(a2)               /* 0xDDEEFF01 */
    ebreak

    .balign 4
data_area:
    .zero 96
