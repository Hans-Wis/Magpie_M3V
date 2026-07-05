/* ADR-0055 Phase-C C1 directed: same-width integer multiply.
   vmul (low SEW), vmulh (signed*signed high), vmulhu (unsigned*unsigned high),
   vmulhsu (signed vs2 * unsigned vs1/rs1, high). OPMVV(.vv)/OPMVX(.vx). SEW 8/16/32.
   Sign matrix via boundary data (-2^(SEW-1), -1, max+, mixed). Observe vse+lw.
   m2 group smoke via vmv.v.x splat (group-EMUL loads out of scope). Terminator:
   masked vmul writing v0 = illegal (dest overlaps mask). Spike --isa=rv32imf_zve32x
   _zvl128b is authority (golden probed: -2^31*2 -> mul 0 / mulh,mulhsu -1 / mulhu 1). */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, pa32
    lla  x21, pb32
    lla  x22, dst

    /* ================= e32, m1, vl=4 ================= */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)
    vle32.v v3, (x21)
    vmul.vv    v5, v2, v3
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulh.vv   v5, v2, v3
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulhu.vv  v5, v2, v3
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulhsu.vv v5, v2, v3
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    /* --- .vx forms (rs1 = -3) --- */
    li   a1, -3
    vmul.vx    v5, v2, a1
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22)
    vmulh.vx   v5, v2, a1
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22)
    vmulhu.vx  v5, v2, a1
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22)
    vmulhsu.vx v5, v2, a1
    vse32.v v5, (x22); lw t3,0(x22); lw t4,4(x22)

    /* ================= e16, m1, vl=8 ================= */
    lla  x18, pa16
    lla  x19, pb16
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x18)
    vle16.v v3, (x19)
    vmul.vv    v5, v2, v3
    vse16.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulh.vv   v5, v2, v3
    vse16.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulhu.vv  v5, v2, v3
    vse16.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulhsu.vv v5, v2, v3
    vse16.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ================= e8, m1, vl=16 ================= */
    lla  x18, pa8
    lla  x19, pb8
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x18)
    vle8.v v3, (x19)
    vmul.vv    v5, v2, v3
    vse8.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulh.vv   v5, v2, v3
    vse8.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulhu.vv  v5, v2, v3
    vse8.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmulhsu.vv v5, v2, v3
    vse8.v v5, (x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ============ e32, m2, vl=8 group smoke (beats_op) ============ */
    li   a0, 8
    vsetvli t1, a0, e32, m2, ta, ma
    li   a1, 0xFFFFF001          /* splat a (negative) */
    vmv.v.x v2, a1
    li   a1, 0x00000007
    vmv.v.x v4, a1
    vmul.vv   v8, v2, v4         /* group v8v9 = a*b low */
    vse32.v v8, (x22); lw t3,0(x22); lw t4,16(x22)
    vmulh.vv  v8, v2, v4         /* signed high */
    vse32.v v8, (x22); lw t3,0(x22); lw t4,16(x22)
    vmulhu.vv v8, v2, v4         /* unsigned high */
    vse32.v v8, (x22); lw t3,0(x22); lw t4,16(x22)

    /* ============ terminator: masked vmul writing v0 = illegal ============ */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vmul.vv v0, v2, v4, v0.t
    ebreak

.section .data
.align 6
pa32: .word 0x80000000, 0xFFFFFFFF, 0x12345678, 0x7FFFFFFF
pb32: .word 0x00000002, 0xFFFFFFFF, 0x00010000, 0x00000003
.align 6
pa16: .short 0x8000, 0xFFFF, 0x1234, 0x7FFF, 0x0002, 0x8001, 0xABCD, 0x00FF
pb16: .short 0x0002, 0xFFFF, 0x0100, 0x0003, 0x7FFF, 0x8000, 0x0010, 0xFF00
.align 6
pa8:  .byte 0x80,0xFF,0x7F,0x01,0x00,0xFE,0xAB,0x10, 0x55,0xC3,0x0F,0xF0,0x01,0x7F,0x80,0xFF
pb8:  .byte 0x02,0xFF,0x03,0xFF,0x7F,0x80,0x10,0xF0, 0xAB,0x3D,0xF1,0x0F,0xFE,0x81,0x80,0x02
.align 6
dst:  .space 64
