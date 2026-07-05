/* ADR-0058 Phase-E E1 directed: integer divide/remainder vdivu/vdiv/vremu/vrem.
   OPMVV(.vv)/OPMVX(.vx), SEW 8/16/32. Data hits every RISC-V special case: /0 (u ->
   all-1s, s -> -1), %0 (-> dividend), signed overflow MIN/-1 (div -> MIN, rem -> 0),
   signed truncation toward zero. Observe vse+lw. m2 group via vmv.v.x splat.
   Terminator: masked vdiv writing v0 = illegal. Spike golden probed (a=20,b=3 -> 6 r2;
   a/0 -> FF/-1, a%0 -> a; MIN/-1 -> MIN,0). Spike --isa=rv32imf_zve32x_zvl128b. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, pa8
    lla  x21, pb8
    lla  x22, dst

    /* ===== SEW8, m1, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)
    vle8.v v1, (x21)
    vdivu.vv v5, v2, v1; vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vdiv.vv  v5, v2, v1; vse8.v v5,(x22); lw t5,0(x22); lw t6,4(x22)
    vremu.vv v5, v2, v1; vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vrem.vv  v5, v2, v1; vse8.v v5,(x22); lw t5,0(x22); lw t6,4(x22)
    /* .vx (divisor rs1 = 3, incl 0/-1 via separate) */
    li   a1, 3
    vdivu.vx v5, v2, a1; vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vrem.vx  v5, v2, a1; vse8.v v5,(x22); lw t5,0(x22); lw t6,4(x22)
    li   a1, 0
    vdivu.vx v5, v2, a1; vse8.v v5,(x22); lw t3,0(x22)   /* div by zero scalar */
    li   a1, -1
    vdiv.vx  v5, v2, a1; vse8.v v5,(x22); lw t4,0(x22)   /* signed /-1 incl MIN ovf */

    /* ===== SEW16, m1, vl=8 ===== */
    lla  x20, pa16
    lla  x21, pb16
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x20)
    vle16.v v1, (x21)
    vdivu.vv v5, v2, v1; vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vdiv.vv  v5, v2, v1; vse16.v v5,(x22); lw t5,0(x22); lw t6,4(x22)
    vremu.vv v5, v2, v1; vse16.v v5,(x22); lw t3,0(x22)
    vrem.vv  v5, v2, v1; vse16.v v5,(x22); lw t4,0(x22)

    /* ===== SEW32, m1, vl=4 ===== */
    lla  x20, pa32
    lla  x21, pb32
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)
    vle32.v v1, (x21)
    vdivu.vv v5, v2, v1; vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vdiv.vv  v5, v2, v1; vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vrem.vv  v5, v2, v1; vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22)

    /* ===== e32, m2, vl=8 group smoke ===== */
    li   a0, 8
    vsetvli t1, a0, e32, m2, ta, ma
    li   a1, 100
    vmv.v.x v2, a1
    li   a1, 7
    vmv.v.x v4, a1
    vdiv.vv v8, v2, v4; vse32.v v8,(x22); lw t3,0(x22); lw t4,16(x22)
    vrem.vv v8, v2, v4; vse32.v v8,(x22); lw t3,0(x22); lw t4,16(x22)

    /* ===== terminator: masked vdiv writing v0 = illegal ===== */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vdiv.vv v0, v2, v4, v0.t
    ebreak

.section .data
.align 6
pa8:  .byte 20, 20, 0xEC, 0x80, 0x80, 100, 7, 0xCE
pb8:  .byte  3,  0,    3, 0xFF,    0,   7, 0, 4
.align 6
pa16: .short 300, 300, 0xFF00, 0x8000, 0x8000, 1000, 77, 0xFFCE
pb16: .short   7,   0,      3, 0xFFFF,      0,    9,  0, 4
.align 6
pa32: .word 1000000, 0x80000000, 0xFFFFFFFF, 12345
pb32: .word     123,          0, 0xFFFFFFFF,     0
.align 6
dst:  .space 64
