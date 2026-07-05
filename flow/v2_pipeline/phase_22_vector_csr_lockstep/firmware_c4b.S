/* ADR-0056 Phase-C C4b directed: widening multiply.
   vwmul (signed*signed), vwmulu (unsigned*unsigned), vwmulsu (signed vs2 * unsigned
   vs1/rs1) -> full 2*SEW product. .vv/.vx. SEW 8 (dest 16) / 16 (dest 32), fractional
   LMUL. Issue at source vtype, store wide. Golden-probed vs2=-128 vs1=255: vwmul 128 /
   vwmulu 32640 / vwmulsu -32640. Terminator: vwmulu.vv vd==vs2 (narrow overlap) illegal
   both trap. Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start

.macro STORE16 reg
    vsetvli x0, x0, e16, m1, ta, ma
    vse16.v \reg, (x22)
    lw t3, 0(x22); lw t4, 4(x22); lw t5, 8(x22); lw t6, 12(x22)
    vsetvli x0, x0, e8, mf2, ta, ma
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

    /* ===== SEW8 (dest 16), mf2, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v v2, (x20)
    vle8.v v1, (x21)
    vwmul.vv   v4, v2, v1;  STORE16 v4
    vwmulu.vv  v4, v2, v1;  STORE16 v4
    vwmulsu.vv v4, v2, v1;  STORE16 v4
    vwmul.vx   v4, v2, a1;  STORE16 v4
    vwmulu.vx  v4, v2, a1;  STORE16 v4
    vwmulsu.vx v4, v2, a1;  STORE16 v4

    /* ===== SEW16 (dest 32), mf2, vl=4 ===== */
    lla  x20, pa16
    lla  x21, pb16
    li   a0, 4
    vsetvli t1, a0, e16, mf2, ta, ma
    vle16.v v2, (x20)
    vle16.v v1, (x21)
    vwmul.vv   v4, v2, v1;  STORE32 v4
    vwmulu.vv  v4, v2, v1;  STORE32 v4
    vwmulsu.vv v4, v2, v1;  STORE32 v4
    vwmulsu.vx v4, v2, a1;  STORE32 v4

    /* ===== terminator: vwmulu.vv vd==vs2 (narrow overlap) = illegal ===== */
    lla  x20, pa8
    lla  x21, pb8
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v v2, (x20)
    vle8.v v1, (x21)
    vwmulu.vv v2, v2, v1
    ebreak

.section .data
.align 6
pa8:  .byte 0x80, 0xFF, 0x7F, 0x01, 0x00, 0xC0, 0x40, 0x02
pb8:  .byte 0xFF, 0x80, 0x02, 0xFF, 0x7F, 0x03, 0x40, 0x81
.align 6
pa16: .short 0x8000, 0xFFFF, 0x7FFF, 0x0001
pb16: .short 0xFFFF, 0x8000, 0x0002, 0xFFFF
.align 6
dst:  .space 64
