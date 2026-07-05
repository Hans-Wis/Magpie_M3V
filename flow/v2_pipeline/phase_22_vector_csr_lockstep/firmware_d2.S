/* ADR-0057 Phase-D D2 directed: slides.
   vslideup/vslidedown.vx/.vi (off=rs1/uimm), vslide1up/vslide1down.vx (off=1, inject
   rs1 at boundary). Barrel-shift model. vd preloaded with a sentinel to see undisturbed
   lanes. Covers SEW 8/16/32, masked, off>=vl (all undisturbed / zero-fill), the
   slidedown zero-fill tail, and slide1 scalar inject. vstart!=0 illegal; slideup-family
   vd==vs2 illegal (terminator). Spike --isa=rv32imf_zve32x_zvl128b golden probed
   (src[10..17]: slideup2=[.,.,10..15], slidedown2=[12..17,0,0], slide1 inject). */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, src8
    lla  x22, dst
    li   a3, 0x7F                 /* sentinel preload */
    li   a2, 0x55                 /* slide1 inject value */

    /* ===== SEW8, m1, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)
    li   a1, 2
    vmv.v.x v6, a3; vslideup.vx   v6, v2, a1; vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    vmv.v.x v6, a3; vslidedown.vx v6, v2, a1; vse8.v v6,(x22); lw t5,0(x22); lw t6,4(x22)
    vmv.v.x v6, a3; vslideup.vi   v6, v2, 3;  vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    vmv.v.x v6, a3; vslidedown.vi v6, v2, 3;  vse8.v v6,(x22); lw t5,0(x22); lw t6,4(x22)
    vmv.v.x v6, a3; vslide1up.vx  v6, v2, a2; vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    vmv.v.x v6, a3; vslide1down.vx v6, v2, a2; vse8.v v6,(x22); lw t5,0(x22); lw t6,4(x22)
    /* off >= vl: slideup all undisturbed; slidedown all zero */
    li   a1, 10
    vmv.v.x v6, a3; vslideup.vx   v6, v2, a1; vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    vmv.v.x v6, a3; vslidedown.vx v6, v2, a1; vse8.v v6,(x22); lw t5,0(x22); lw t6,4(x22)
    /* masked slide (v0 predicate) */
    lla  x21, msk
    vle8.v v4, (x21)
    vmsne.vi v0, v4, 0
    li   a1, 1
    vmv.v.x v6, a3; vslideup.vx   v6, v2, a1, v0.t; vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    li   a1, 2
    vmv.v.x v6, a3; vslidedown.vx v6, v2, a1, v0.t; vse8.v v6,(x22); lw t5,0(x22); lw t6,4(x22)
    vmv.v.x v6, a3; vslide1down.vx v6, v2, a2, v0.t; vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)

    /* ===== SEW16, m1, vl=8 ===== */
    lla  x20, src16
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x20)
    li   a1, 2
    vmv.v.x v6, a3; vslideup.vx    v6, v2, a1; vse16.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    vmv.v.x v6, a3; vslidedown.vx  v6, v2, a1; vse16.v v6,(x22); lw t5,0(x22); lw t6,4(x22)
    vmv.v.x v6, a3; vslide1down.vx v6, v2, a2; vse16.v v6,(x22); lw t3,0(x22); lw t4,4(x22)

    /* ===== SEW32, m1, vl=4 ===== */
    lla  x20, src32
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)
    li   a1, 1
    vmv.v.x v6, a3; vslideup.vx    v6, v2, a1; vse32.v v6,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vmv.v.x v6, a3; vslidedown.vx  v6, v2, a1; vse32.v v6,(x22); lw t3,0(x22); lw t4,4(x22)
    vmv.v.x v6, a3; vslide1up.vx   v6, v2, a2; vse32.v v6,(x22); lw t5,0(x22); lw t6,4(x22)

    /* ===== fractional-LMUL vslidedown zero-fill (Codex finding): e8 mf2 VLMAX=8 =====
       Load 16 bytes at m1 so physical lanes 8+ are nonzero, then slidedown at mf2.
       vd[6,7] must be 0 (i+2>=VLMAX=8), NOT vs2[8]/vs2[9]. */
    lla  x20, src8
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    li   a1, 2
    vmv.v.x v6, a3
    vslidedown.vx v6, v2, a1
    vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)

    /* ===== terminator: vslideup vd==vs2 (overlap) = illegal, both trap ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vslideup.vx v2, v2, a1
    ebreak

.section .data
.align 6
src8:  .byte 10,11,12,13,14,15,16,17, 18,19,20,21,22,23,24,25
.align 6
msk:   .byte 0,1,1,0,1,0,0,1
.align 6
src16: .short 0x0101,0x0202,0x0303,0x0404,0x0505,0x0606,0x0707,0x0808
.align 6
src32: .word 0x11111111,0x22222222,0x33333333,0x44444444
.align 6
dst:   .space 64
