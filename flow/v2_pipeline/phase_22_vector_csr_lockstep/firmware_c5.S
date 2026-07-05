/* ADR-0056 Phase-C C5 directed: vsmul (signed saturating rounding fractional mul).
   vd = sat(round((vs2*vs1) >> (SEW-1))) with vxrm rounding. OPIVV/OPIVX. SEW 8/16/32.
   Exercises all four vxrm modes (rnu/rne/rdn/rod) on fractional products, the
   (-2^(SEW-1))^2 overflow -> +max saturation (vxsat), and .vx/m2 forms. vxsat observed
   via csrr. Terminator: masked vsmul writing v0 = illegal. Spike golden probed:
   64*64>>7=32, -128*-128->127(vxsat), 64*3>>7 rounds 1->2 (rnu).
   Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, pa8
    lla  x21, pb8
    lla  x22, dst

    /* ===== SEW8, m1, vl=8, all four vxrm modes ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)
    vle8.v v1, (x21)
    csrw vxrm, 0                     /* rnu */
    vsmul.vv v5, v2, v1
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    csrr t5, vxsat                   /* sat from -128*-128 */
    csrw vxrm, 1                     /* rne */
    vsmul.vv v5, v2, v1
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    csrw vxrm, 2                     /* rdn */
    vsmul.vv v5, v2, v1
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    csrw vxrm, 3                     /* rod */
    vsmul.vv v5, v2, v1
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    /* .vx (rs1 = 3) */
    li   a1, 3
    csrw vxrm, 0
    vsmul.vx v5, v2, a1
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)

    /* ===== SEW16, m1, vl=8 ===== */
    lla  x20, pa16
    lla  x21, pb16
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x20)
    vle16.v v1, (x21)
    csrw vxrm, 0
    vsmul.vv v5, v2, v1
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    csrw vxrm, 1
    vsmul.vv v5, v2, v1
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    li   a1, -5
    vsmul.vx v5, v2, a1
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22)

    /* ===== SEW32, m1, vl=4 (incl -2^31*-2^31 saturation) ===== */
    lla  x20, pa32
    lla  x21, pb32
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)
    vle32.v v1, (x21)
    csrw vxrm, 0
    vsmul.vv v5, v2, v1
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    csrr t3, vxsat

    /* ===== e32, m2, vl=8 group smoke (observe via m1 stores — group-EMUL
       memory ops are out of scope, so store v8 and v9 separately at m1) ===== */
    li   a0, 8
    vsetvli t1, a0, e32, m2, ta, ma
    li   a1, 0x40000000
    vmv.v.x v2, a1
    li   a1, 0x00000004
    vmv.v.x v4, a1
    csrw vxrm, 0
    vsmul.vv v8, v2, v4              /* group v8v9 = (2^30 * 4) >> 31 = 2 */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vse32.v v8,(x22); lw t3,0(x22)
    vse32.v v9,(x22); lw t4,0(x22)

    /* ===== terminator: masked vsmul writing v0 = illegal ===== */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vsmul.vv v0, v2, v4, v0.t
    ebreak

.section .data
.align 6
pa8:  .byte 0x40, 0x80, 0x7F, 0x40, 0x60, 0x30, 0x20, 0xC0
pb8:  .byte 0x40, 0x80, 0x7F, 0x03, 0x03, 0x05, 0x20, 0x41
.align 6
pa16: .short 0x4000, 0x8000, 0x7FFF, 0x4000, 0x0300, 0x1234, 0xF000, 0x00FF
pb16: .short 0x4000, 0x8000, 0x7FFF, 0x0003, 0x0005, 0x0007, 0x0010, 0x7FFF
.align 6
pa32: .word 0x80000000, 0x40000000, 0x7FFFFFFF, 0x12345678
pb32: .word 0x80000000, 0x00000004, 0x7FFFFFFF, 0x00000003
.align 6
dst:  .space 64
