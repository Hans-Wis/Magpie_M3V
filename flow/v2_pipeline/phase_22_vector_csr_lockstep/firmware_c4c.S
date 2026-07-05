/* ADR-0056 Phase-C C4c directed: widening MAC.
   vwmaccu (u*u), vwmacc (s*s), vwmaccsu (signed vs1 * unsigned vs2), vwmaccus
   (unsigned rs1 * signed vs2, .vx only) -> vd (2*SEW) += product. vd is the wide
   accumulator, reseeded before each op so the sum is deterministic. SEW 8 (dest 16)
   / 16 (dest 32), fractional LMUL. su/us sign roles are SWAPPED vs vwmulsu
   (Spike-probed vs2=-128 vs1=255 vd=0 -> maccu 32640 / macc 128 / maccsu -128 /
   maccus -32640). Terminator: vwmaccu.vv vd==vs2 (narrow overlap) illegal both trap.
   Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start

.macro SEED16
    vsetvli x0, x0, e16, m1, ta, ma
    vmv.v.x v4, s0
    vsetvli x0, x0, e8, mf2, ta, ma
.endm
.macro STORE16 reg
    vsetvli x0, x0, e16, m1, ta, ma
    vse16.v \reg, (x22)
    lw t3, 0(x22); lw t4, 4(x22); lw t5, 8(x22); lw t6, 12(x22)
    vsetvli x0, x0, e8, mf2, ta, ma
.endm
.macro SEED32
    vsetvli x0, x0, e32, m1, ta, ma
    vmv.v.x v4, s0
    vsetvli x0, x0, e16, mf2, ta, ma
.endm
.macro STORE32 reg
    vsetvli x0, x0, e32, m1, ta, ma
    vse32.v \reg, (x22)
    lw t3, 0(x22); lw t4, 4(x22); lw t5, 8(x22); lw t6, 12(x22)
    vsetvli x0, x0, e16, mf2, ta, ma
.endm

_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, pa8
    lla  x21, pb8
    lla  x22, dst
    li   a1, -1
    li   s0, 0x0064                 /* accumulator seed = 100 */

    /* ===== SEW8 (dest 16), mf2, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v v2, (x20)                /* vs2 */
    vle8.v v1, (x21)                /* vs1 */
    SEED16; vwmaccu.vv  v4, v1, v2;  STORE16 v4
    SEED16; vwmacc.vv   v4, v1, v2;  STORE16 v4
    SEED16; vwmaccsu.vv v4, v1, v2;  STORE16 v4
    SEED16; vwmaccus.vx v4, a1, v2;  STORE16 v4
    SEED16; vwmaccu.vx  v4, a1, v2;  STORE16 v4
    SEED16; vwmacc.vx   v4, a1, v2;  STORE16 v4
    SEED16; vwmaccsu.vx v4, a1, v2;  STORE16 v4

    /* ===== SEW16 (dest 32), mf2, vl=4 ===== */
    lla  x20, pa16
    lla  x21, pb16
    li   a0, 4
    vsetvli t1, a0, e16, mf2, ta, ma
    vle16.v v2, (x20)
    vle16.v v1, (x21)
    SEED32; vwmaccu.vv  v4, v1, v2;  STORE32 v4
    SEED32; vwmacc.vv   v4, v1, v2;  STORE32 v4
    SEED32; vwmaccsu.vv v4, v1, v2;  STORE32 v4
    SEED32; vwmaccus.vx v4, a1, v2;  STORE32 v4

    /* ===== terminator: vwmaccu.vv vd==vs2 (narrow overlap) = illegal ===== */
    lla  x20, pa8
    lla  x21, pb8
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v v2, (x20)
    vle8.v v1, (x21)
    vwmaccu.vv v2, v1, v2
    ebreak

.section .data
.align 6
pa8:  .byte 0x80, 0xFF, 0x7F, 0x01, 0x00, 0xC0, 0x40, 0x02
pb8:  .byte 0xFF, 0x02, 0x80, 0x7F, 0x03, 0xFF, 0x40, 0x81
.align 6
pa16: .short 0x8000, 0xFFFF, 0x7FFF, 0x0001
pb16: .short 0xFFFF, 0x0002, 0x8000, 0x7FFF
.align 6
dst:  .space 64
