/* ADR-0056 Phase-C C4d directed: widening integer sum reduction.
   vwredsum.vs (sext), vwredsumu.vs (zext) -> vd[0] (2*SEW) = ext(vs1[0]) + sum of
   ext(vs2[0..vl-1]). OPIVV (not OPMVV). vs1[0] is already 2*SEW (seeded via vmv.s.x
   at the wide vtype). SEW 8 (dest 16) / 16 (dest 32). Data has sign variety so
   vwredsum != vwredsumu. Golden-probed seed=3 vs2={5,-1,127,-128}: vwredsum 6 /
   vwredsumu 518. Terminator: vwredsum @ vstart!=0 = illegal (both trap). Spike
   --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, d8
    lla  x22, dst
    li   a1, 3                       /* reduction seed (2*SEW) */

    /* ===== SEW8 (dest 16): seed at e16 m1, reduce at e8 mf2, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vmv.s.x v3, a1                    /* v3[0] = 3 (16-bit) */
    vsetvli t1, a0, e8, mf2, ta, ma
    vle8.v v2, (x20)
    vwredsum.vs  v5, v2, v3
    vsetvli x0, x0, e16, m1, ta, ma; vse16.v v5,(x22); lw t3,0(x22); vsetvli x0,x0,e8,mf2,ta,ma
    vwredsumu.vs v5, v2, v3
    vsetvli x0, x0, e16, m1, ta, ma; vse16.v v5,(x22); lw t4,0(x22)

    /* ===== SEW16 (dest 32): seed at e32 m1, reduce at e16 mf2, vl=4 ===== */
    lla  x20, d16
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.s.x v3, a1                    /* v3[0] = 3 (32-bit) */
    vsetvli t1, a0, e16, mf2, ta, ma
    vle16.v v2, (x20)
    vwredsum.vs  v5, v2, v3
    vsetvli x0, x0, e32, m1, ta, ma; vse32.v v5,(x22); lw t5,0(x22); vsetvli x0,x0,e16,mf2,ta,ma
    vwredsumu.vs v5, v2, v3
    vsetvli x0, x0, e32, m1, ta, ma; vse32.v v5,(x22); lw t6,0(x22)

    /* ===== terminator: vwredsum @ vstart!=0 = illegal (both trap) ===== */
    vsetvli x0, x0, e16, mf2, ta, ma
    csrw vstart, 2
    vwredsum.vs v5, v2, v3
    ebreak

.section .data
.align 6
d8:  .byte 0x05, 0xFF, 0x7F, 0x80, 0x01, 0xFE, 0x40, 0xC0
.align 6
d16: .short 0x0005, 0xFFFF, 0x7FFF, 0x8000
.align 6
dst: .space 32
