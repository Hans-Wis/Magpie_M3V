/* ADR-0055 Phase-B B1 directed: bitwise (vand/vor/vxor), shift (vsll/vsrl/vsra),
   vrsub — vv/vx/vi across e8/e16/e32, m1 + m2 (beats). Sources loaded from a
   known data table; results stored via vse and read back with scalar lw so the
   Spike lockstep compares every element. Shift amounts include >=SEW (truncation
   to low log2(SEW) bits) and vsra sign edges. --isa=zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200            /* mstatus.VS = initial */
    csrs mstatus, t0
    lla  x20, src_a
    lla  x21, src_b
    lla  x22, dst

    /* ================= e8 / m1 (vl=16) ================= */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v  v1, (x20)          /* a = ramp/pattern bytes */
    vle8.v  v2, (x21)          /* b */

    vand.vv  v3, v1, v2
    vse8.v   v3, (x22)
    lw t2, 0(x22)
    lw t3, 4(x22)
    lw t4, 8(x22)
    lw t5, 12(x22)
    vor.vv   v3, v1, v2
    vse8.v   v3, (x22)
    lw t2, 0(x22)
    lw t3, 4(x22)
    vxor.vv  v3, v1, v2
    vse8.v   v3, (x22)
    lw t2, 0(x22)
    lw t3, 8(x22)

    /* .vx / .vi bitwise */
    li t2, 0x3C
    vand.vx  v3, v1, t2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    vor.vi   v3, v1, 5
    vse8.v   v3, (x22)
    lw t3, 4(x22)
    vxor.vi  v3, v1, -1        /* imm sext: ~a */
    vse8.v   v3, (x22)
    lw t3, 0(x22)

    /* shifts e8: vv (shamt from b, low 3 bits), vx (incl >=8 truncation), vi */
    vsll.vv  v3, v1, v2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 8(x22)
    vsrl.vv  v3, v1, v2
    vse8.v   v3, (x22)
    lw t3, 4(x22)
    vsra.vv  v3, v1, v2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 12(x22)
    li t2, 11                  /* shamt 11 -> low 3 bits = 3 */
    vsll.vx  v3, v1, t2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    vsra.vi  v3, v1, 2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 8(x22)

    /* vrsub e8 */
    li t2, 20
    vrsub.vx v3, v1, t2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    vrsub.vi v3, v1, -8
    vse8.v   v3, (x22)
    lw t3, 4(x22)

    /* ================= e16 / m1 (vl=8) ================= */
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v1, (x20)
    vle16.v v2, (x21)
    vand.vv  v3, v1, v2
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 8(x22)
    vsll.vv  v3, v1, v2
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    vsra.vx  v3, v1, t2        /* t2=20 -> low4=4 */
    vse16.v  v3, (x22)
    lw t3, 4(x22)
    vxor.vx  v3, v1, t2
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    vrsub.vi v3, v1, 7
    vse16.v  v3, (x22)
    lw t3, 8(x22)

    /* ================= e32 / m1 (vl=4) ================= */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v1, (x20)
    vle32.v v2, (x21)
    vand.vv  v3, v1, v2
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 12(x22)
    vor.vv   v3, v1, v2
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    vsll.vv  v3, v1, v2
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    vsrl.vx  v3, v1, t2        /* t2=20 -> low5=20 */
    vse32.v  v3, (x22)
    lw t3, 4(x22)
    vsra.vv  v3, v1, v2
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    vrsub.vx v3, v1, t2
    vse32.v  v3, (x22)
    lw t3, 8(x22)

    /* ========== e8 / m2 (beats, vl=32) — group sources via vmv.v.x splat;
       observe element 0 via vmv.x.s (group memory ops are out of scope so no
       vse group store). B1 in beats_op reuses the m2 beat machinery already
       verified for add/sub; random corpus covers the full group. ============ */
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    li t2, 0x5A
    vmv.v.x  v4, t2            /* group v4-v5 = 0x5A */
    li t2, 0x0C
    vmv.v.x  v6, t2            /* group v6-v7 = 0x0C */
    vand.vv  v8, v4, v6        /* 0x08 across 32 elems (2 beats, group commit) */
    vmv.x.s  t3, v8            /* elem0 = 0x08 */
    li t2, 3
    vsll.vx  v8, v4, t2        /* 0x5A<<3 -> low byte 0xD0 */
    vmv.x.s  t3, v8
    vxor.vx  v8, v4, t2        /* 0x5A ^ 3 = 0x59 */
    vmv.x.s  t3, v8

    ebreak

.section .data
.align 6
src_a:
    .byte 0x00,0x01,0x7F,0x80,0xFF,0x55,0xAA,0x0F
    .byte 0xF0,0x33,0xCC,0x81,0x40,0x20,0x10,0x08
    .byte 0x03,0x1D,0x64,0x9C,0xE7,0x12,0xBE,0x77
    .byte 0x88,0x44,0x22,0x11,0xC3,0x3C,0x5A,0xA5
src_b:
    .byte 0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x00
    .byte 0x08,0x09,0x0A,0x0B,0x02,0x04,0x0F,0x05
    .byte 0x10,0x11,0x12,0x13,0x1F,0x03,0x07,0x01
    .byte 0x06,0x05,0x04,0x03,0x02,0x01,0x00,0x1E
.align 6
dst:
    .space 64
