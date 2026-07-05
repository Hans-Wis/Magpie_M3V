/* ADR-0056 Phase-C C3 directed: non-sum reductions.
   vred{sum,and,or,xor,minu,min,maxu,max}.vs — vd[0] = vs1[0] OP reduce(vs2[0..vl-1]).
   OPMVV, unmasked (vm=1), m1. Seed vs1[0] set via vmv.s.x. Data picks signed/unsigned
   boundary values so vredminu!=vredmin and vredmaxu!=vredmax. Observe vd[0] via
   vse+lw(0). SEW 8/16/32. Terminator: vredsum at vstart!=0 = illegal (both DUT and
   Spike trap — reduction vstart must be 0). Spike --isa=rv32imf_zve32x_zvl128b golden. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    li   a1, 3                    /* reduction seed = vs1[0] */

    /* ================= e32, m1, vl=4 ================= */
    lla  x20, d32
    lla  x22, dst
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)
    vmv.s.x v3, a1
    vredsum.vs  v5, v2, v3; vse32.v v5,(x22); lw t3,0(x22)
    vredand.vs  v5, v2, v3; vse32.v v5,(x22); lw t4,0(x22)
    vredor.vs   v5, v2, v3; vse32.v v5,(x22); lw t5,0(x22)
    vredxor.vs  v5, v2, v3; vse32.v v5,(x22); lw t6,0(x22)
    vredminu.vs v5, v2, v3; vse32.v v5,(x22); lw t3,0(x22)
    vredmin.vs  v5, v2, v3; vse32.v v5,(x22); lw t4,0(x22)
    vredmaxu.vs v5, v2, v3; vse32.v v5,(x22); lw t5,0(x22)
    vredmax.vs  v5, v2, v3; vse32.v v5,(x22); lw t6,0(x22)

    /* ================= e16, m1, vl=8 ================= */
    lla  x20, d16
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x20)
    vmv.s.x v3, a1
    vredsum.vs  v5, v2, v3; vse16.v v5,(x22); lw t3,0(x22)
    vredand.vs  v5, v2, v3; vse16.v v5,(x22); lw t4,0(x22)
    vredor.vs   v5, v2, v3; vse16.v v5,(x22); lw t5,0(x22)
    vredxor.vs  v5, v2, v3; vse16.v v5,(x22); lw t6,0(x22)
    vredminu.vs v5, v2, v3; vse16.v v5,(x22); lw t3,0(x22)
    vredmin.vs  v5, v2, v3; vse16.v v5,(x22); lw t4,0(x22)
    vredmaxu.vs v5, v2, v3; vse16.v v5,(x22); lw t5,0(x22)
    vredmax.vs  v5, v2, v3; vse16.v v5,(x22); lw t6,0(x22)

    /* ================= e8, m1, vl=16 ================= */
    lla  x20, d8
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)
    vmv.s.x v3, a1
    vredsum.vs  v5, v2, v3; vse8.v v5,(x22); lw t3,0(x22)
    vredand.vs  v5, v2, v3; vse8.v v5,(x22); lw t4,0(x22)
    vredor.vs   v5, v2, v3; vse8.v v5,(x22); lw t5,0(x22)
    vredxor.vs  v5, v2, v3; vse8.v v5,(x22); lw t6,0(x22)
    vredminu.vs v5, v2, v3; vse8.v v5,(x22); lw t3,0(x22)
    vredmin.vs  v5, v2, v3; vse8.v v5,(x22); lw t4,0(x22)
    vredmaxu.vs v5, v2, v3; vse8.v v5,(x22); lw t5,0(x22)
    vredmax.vs  v5, v2, v3; vse8.v v5,(x22); lw t6,0(x22)

    /* ============ terminator: vredsum @ vstart!=0 = illegal (both trap) ============ */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    csrw vstart, 2
    vredsum.vs v5, v2, v3
    ebreak

.section .data
.align 6
d32: .word 0x00000005, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000
.align 6
d16: .short 0x0005, 0xFFFF, 0x7FFF, 0x8000, 0x0100, 0x00FF, 0x8001, 0x1234
.align 6
d8:  .byte 0x05,0xFF,0x7F,0x80,0x10,0x01,0x81,0x40, 0xC0,0x3F,0x00,0xFE,0x7E,0x02,0x88,0x55
.align 6
dst: .space 64
