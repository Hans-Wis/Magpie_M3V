/* ADR-0060 Phase-E tail directed: vcompress.vm vd,vs2,vs1.
   Pack active vs2 elements (mask = BIT i of vs1, NOT v0) into contiguous low vd
   lanes; positions [count,vl) undisturbed. OPMVV f6=010111 vm=0. m1-only, vstart=0.
   Spike-probed golden: mask 0x4D over [10..17] -> [10,12,13,16]; empty mask keeps
   pre-color. Observe via vse+lw. Out-of-scope LMUL>1 = illegal (grp_only_illegal).
   Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x22, dst

    /* ===== e8, vl=8, mask 0x4D (elems 0,2,3,6) -> [10,12,13,16] + tail 0xDE ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    li   t2, 0xDE
    vmv.v.x v4, t2                       /* pre-color vd to see tail undisturbed */
    lla  x20, src8
    vle8.v v2, (x20)                      /* v2 = [10..17] */
    lla  x21, m4d
    vle8.v v1, (x21)                      /* v1[7:0] = 0x4D mask bits */
    vcompress.vm v4, v2, v1
    vse8.v v4, (x22); lw t3,0(x22); lw t4,4(x22)   /* 0x100d0c0a ; tail bytes4..7=0xDE */

    /* ===== all-active mask 0xFF -> identity ===== */
    li   t2, 0xFF
    sb   t2, 0(x21)
    vle8.v v1, (x21)
    vcompress.vm v6, v2, v1
    vse8.v v6, (x22); lw t5,0(x22); lw t6,4(x22)   /* 0x0d0c0b0a ; 0x11100f0e */

    /* ===== empty mask 0x00 -> count 0, whole vd undisturbed (pre-color 0x99) ===== */
    li   t2, 0x00
    sb   t2, 0(x21)
    vle8.v v1, (x21)
    li   t2, 0x99
    vmv.v.x v8, t2
    vcompress.vm v8, v2, v1
    vse8.v v8, (x22); lw t3,0(x22); lw t4,4(x22)   /* both 0x99999999 */

    /* ===== e16, vl=8, mask 0x35 (elems 0,2,4,5) ===== */
    lla  x20, src16
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x20)                     /* [0x100..0x800 step] */
    li   t2, 0x35
    sb   t2, 0(x21)
    vle8.v v1, (x21)                      /* mask bits only need low byte */
    li   t2, 0xBEEF
    vmv.v.x v10, t2
    vsetvli t1, a0, e16, m1, ta, ma
    vcompress.vm v10, v2, v1
    vse16.v v10,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ===== e32, vl=4, mask 0x0A (elems 1,3) ===== */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    lla  x20, src32
    vle32.v v2, (x20)
    li   t2, 0x0A
    sb   t2, 0(x21)
    vle8.v v1, (x21)
    li   t2, 0x7777
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.v.x v12, t2
    vcompress.vm v12, v2, v1
    vse32.v v12,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ===== partial vl: e8 vl=5, mask 0xFF but only 5 active (i<vl) ===== */
    li   a0, 5
    vsetvli t1, a0, e8, m1, ta, ma
    li   t2, 0xFF
    sb   t2, 0(x21)
    vle8.v v1, (x21)
    li   t2, 0x22
    li   a1, 8
    vsetvli t1, a1, e8, m1, ta, ma       /* pre-color 8 lanes */
    vmv.v.x v14, t2
    li   a0, 5
    vsetvli t1, a0, e8, m1, ta, ma       /* vl=5 */
    vcompress.vm v14, v2, v1             /* v2 still src32 bytes; pack first 5 -> lanes0..4 */
    li   a1, 8
    vsetvli t1, a1, e8, m1, ta, ma
    vse8.v v14,(x22); lw t3,0(x22); lw t4,4(x22)   /* lanes5..7 stay 0x22 */

    /* ===== terminator: vd==vs2 overlap = illegal (both DUT & Spike trap) ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vcompress.vm v2, v2, v1
    ebreak

.section .data
.align 6
src8:  .byte 10,11,12,13,14,15,16,17
.align 6
m4d:   .byte 0x4D
.align 6
src16: .short 0x0100,0x0200,0x0300,0x0400,0x0500,0x0600,0x0700,0x0800
.align 6
src32: .word 0x11110000,0x22220000,0x33330000,0x44440000
.align 6
dst:   .space 32
