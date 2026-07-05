/* ADR-0056 Phase-C C4a directed: full widening add/sub.
   vwaddu/vwadd/vwsubu/vwsub, .vv/.vx (narrow+narrow) and .wv/.wx (wide vs2 + narrow).
   dest 2*SEW; narrows sign/zero-extend per signedness. SEW 8 (dest 16) and 16 (dest 32),
   fractional LMUL (dest EMUL=2*LMUL<=1). Issue at source vtype, store at the wide vtype
   (keep-vl vsetvli). Observe vse+lw. vd==vs2 legal for .wv (vs2 wide); narrow overlap
   (vwaddu.vv vd==vs2) illegal terminator both DUT+Spike trap. Golden-probed vs2=0xFF
   vs1=1: vwaddu 256 / vwadd 0 / vwsubu 254 / vwsub -2 / vwaddu.wv 257 / vwsub.wv 255.
   Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start

.macro STORE16 reg
    vsetvli x0, x0, e16, m1, ta, ma
    vse16.v \reg, (x22)
    lw t3, 0(x22); lw t4, 4(x22); lw t5, 8(x22); lw t6, 12(x22)
    vsetvli x0, x0, e8, mf2, ta, ma
.endm

_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, pa8
    lla  x21, pb8
    lla  x24, pw16
    lla  x22, dst
    li   a1, -3

    /* ===== SEW8 (dest 16), mf2, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v v2, (x20)                 /* narrow vs2 */
    vle8.v v1, (x21)                 /* narrow vs1 */
    vsetvli x0, x0, e16, m1, ta, ma
    vle16.v v6, (x24)                /* wide vs2 (.wv) */
    vsetvli x0, x0, e8, mf2, ta, ma
    /* --- .vv (narrow+narrow) --- */
    vwaddu.vv v4, v2, v1;  STORE16 v4
    vwadd.vv  v4, v2, v1;  STORE16 v4
    vwsubu.vv v4, v2, v1;  STORE16 v4
    vwsub.vv  v4, v2, v1;  STORE16 v4
    /* --- .wv (wide vs2 + narrow vs1) --- */
    vwaddu.wv v4, v6, v1;  STORE16 v4
    vwadd.wv  v4, v6, v1;  STORE16 v4
    vwsubu.wv v4, v6, v1;  STORE16 v4
    vwsub.wv  v4, v6, v1;  STORE16 v4
    /* --- .vx / .wx (scalar narrow operand) --- */
    vwaddu.vx v4, v2, a1;  STORE16 v4
    vwsub.vx  v4, v2, a1;  STORE16 v4
    vwadd.wx  v4, v6, a1;  STORE16 v4
    vwsubu.wx v4, v6, a1;  STORE16 v4
    /* --- vd==vs2 legal for .wv (wide source) --- */
    vwadd.wv  v6, v6, v1;  STORE16 v6

    /* ===== SEW16 (dest 32), mf2, vl=4 ===== */
    lla  x20, pa16
    lla  x21, pb16
    lla  x24, pw32
    li   a0, 4
    vsetvli t1, a0, e16, mf2, ta, ma
    vle16.v v2, (x20)
    vle16.v v1, (x21)
    vsetvli x0, x0, e32, m1, ta, ma
    vle32.v v6, (x24)
    vsetvli x0, x0, e16, mf2, ta, ma
    vwaddu.vv v4, v2, v1
    vsetvli x0,x0,e32,m1,ta,ma; vse32.v v4,(x22); lw t3,0(x22); lw t4,4(x22); vsetvli x0,x0,e16,mf2,ta,ma
    vwsub.vv  v4, v2, v1
    vsetvli x0,x0,e32,m1,ta,ma; vse32.v v4,(x22); lw t3,0(x22); lw t4,4(x22); vsetvli x0,x0,e16,mf2,ta,ma
    vwaddu.wv v4, v6, v1
    vsetvli x0,x0,e32,m1,ta,ma; vse32.v v4,(x22); lw t3,0(x22); lw t4,4(x22); vsetvli x0,x0,e16,mf2,ta,ma
    vwsub.wv  v4, v6, v1
    vsetvli x0,x0,e32,m1,ta,ma; vse32.v v4,(x22); lw t3,0(x22); lw t4,4(x22); vsetvli x0,x0,e16,mf2,ta,ma

    /* ===== terminator: vwaddu.vv vd==vs2 (narrow overlap) = illegal, both trap ===== */
    vwaddu.vv v2, v2, v1
    ebreak

.section .data
.align 6
pa8:  .byte 0xFF, 0x80, 0x7F, 0x01, 0x00, 0xFE, 0x40, 0xC0
pb8:  .byte 0x01, 0x02, 0x7F, 0x80, 0xFF, 0x03, 0x40, 0x40
.align 6
pw16: .short 0x0100, 0x8000, 0x7FFF, 0xFFFF, 0x1234, 0x0001, 0x8001, 0x00FF
.align 6
pa16: .short 0xFFFF, 0x8000, 0x7FFF, 0x0001
pb16: .short 0x0001, 0x0002, 0x7FFF, 0x8000
.align 6
pw32: .word 0x00010000, 0x80000000, 0x7FFFFFFF, 0x12345678
.align 6
dst:  .space 64
