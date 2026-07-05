/* ADR-0055 Phase-B B2a directed: narrowing shift vnsrl/vnsra (.wv/.wx/.wi).
   wide 2*SEW source >> shamt -> SEW dest (low bits); reuses the vnclip wide bus
   minus round/clip. Only SEW8 (src e16) and SEW16 (src e32) — SEW32 narrowing
   needs a 64-bit source, absent in Zve32x. Fractional LMUL (source EMUL=2*LMUL
   <=1). vnsra sign edges shown with shamt >= 9 (the sign-fill reaches the low
   SEW bits). Terminator = masked vd==v0 illegal. Spike --isa=zve32x is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, wsrc16
    lla  x21, sh8
    lla  x19, wsrc32
    lla  x18, sh16
    lla  x22, dst

    /* ===== e8 dest from e16 source (narrow 16->8), mf2 vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e16, mf2, ta, ma
    vle16.v v2, (x20)          /* wide 16-bit source (incl negatives) */
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v  v1, (x21)          /* per-element shamts (8-bit) */

    vnsrl.wv v3, v2, v1
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)
    vnsra.wv v3, v2, v1        /* arithmetic — differs where shamt>=9 */
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)
    vnsrl.wi v3, v2, 12        /* large shamt: logical zero-fill */
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    vnsra.wi v3, v2, 12        /* large shamt: sign-fill into low byte */
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)
    li t2, 3
    vnsrl.wx v3, v2, t2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    li t2, 11                  /* wx shamt masked to low 4 bits -> 11 */
    vnsra.wx v3, v2, t2
    vse8.v   v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)

    /* ===== e16 dest from e32 source (narrow 32->16), mf2 vl=4 =====
       load the wide 32-bit source with an EEW=32 unit-stride load AT the
       e16/mf2 vtype (EMUL=EEW/SEW*LMUL = 32/16*mf2 = m1); avoids e32/mf2. */
    li   a0, 4
    vsetvli t1, a0, e16, mf2, ta, ma
    vle32.v v2, (x19)          /* wide 32-bit source (EEW32 @ SEW16) */
    vle16.v v1, (x18)          /* shamts (16-bit) */
    vnsrl.wv v3, v2, v1
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)
    vnsra.wv v3, v2, v1
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)
    vnsra.wi v3, v2, 20        /* large shamt (>=17): sign-fill */
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    vnsrl.wi v3, v2, 20
    vse16.v  v3, (x22)
    lw t3, 0(x22)

    /* ===== B2b vzext/vsext ===== */
    lla  x17, esrc8
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v  v2, (x17)          /* signed 8-bit source (0x80/0xFF... negatives) */
    /* vf2 -> e16 */
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vzext.vf2 v3, v2
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)
    vsext.vf2 v3, v2           /* sign-extend: 0x80 -> 0xFF80 */
    vse16.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 12(x22)
    /* vf4 -> e32 (8-bit source) */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vsext.vf4 v3, v2
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 12(x22)
    vzext.vf4 v3, v2
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    /* vf2 -> e32 (16-bit source) */
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v4, (x20)          /* 16-bit source (wsrc16, negatives) */
    vsetvli t1, a0, e32, m1, ta, ma
    vsext.vf2 v3, v4
    vse32.v  v3, (x22)
    lw t3, 0(x22)
    lw t4, 4(x22)

    /* terminator: vext with vd==vs2 = ILLEGAL (wider dest overlaps the narrower
       source; Grok review — require_noover). Both DUT and Spike trap here. */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vsext.vf2 v3, v3
    ebreak

.section .data
.align 6
wsrc16:
    .short 0x0001, 0x8000, 0xFF00, 0x1234, 0x8010, 0x7FFF, 0xABCD, 0x0080
sh8:
    .byte 0, 1, 4, 8, 12, 15, 3, 9
    .byte 0, 0, 0, 0, 0, 0, 0, 0
.align 6
wsrc32:
    .word 0x00000001, 0x80000000, 0xFFFF0000, 0x12345678
sh16:
    .short 0, 4, 20, 31
    .short 0, 0, 0, 0
esrc8:
    .byte 0x80, 0xFF, 0x7F, 0x01, 0xC0, 0x3F, 0x88, 0x08
    .byte 0xF0, 0x0F, 0xA5, 0x5A, 0x00, 0xFE, 0x40, 0x81
.align 6
dst:
    .space 64
