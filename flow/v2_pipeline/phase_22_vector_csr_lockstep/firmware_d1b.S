/* ADR-0057 Phase-D D1b directed: vmsbf/vmsof/vmsif.m (mask dest) + viota.m (vector).
   F = first active set bit in vs2. vmsbf: i<F. vmsof: i==F. vmsif: i<=F. viota:
   vd[i]=# active set bits in [0,i). Maskable (inactive undisturbed), m1-only,
   vstart!=0 illegal. Pre-zero v6 before each op for a deterministic tail. Golden
   mask {2,3,6}: vmsbf 0x03 / vmsif 0x07 / vmsof 0x04 / viota [0,0,0,1,2,2,2,3];
   masked v0={3,6,7} (active-set {3,6}): viota vd[3,6,7]=0,1,2. Terminator: viota @
   vstart!=0 illegal (both trap). Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start

.macro Z6
    vmv.v.i v6, 0
.endm

_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, src
    lla  x21, msk
    lla  x22, dst
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v4, (x20)
    vmsne.vi v2, v4, 0          /* v2 mask = {2,3,6} */
    vle8.v v5, (x21)
    vmsne.vi v0, v5, 0          /* v0 predicate = {3,6,7} */
    vmxor.mm v3, v2, v2         /* v3 = empty mask */

    /* --- unmasked vmsbf/vmsif/vmsof/viota @ e8 --- */
    Z6; vmsbf.m v6, v2; vse8.v v6,(x22); lw t3,0(x22)
    Z6; vmsif.m v6, v2; vse8.v v6,(x22); lw t4,0(x22)
    Z6; vmsof.m v6, v2; vse8.v v6,(x22); lw t5,0(x22)
    Z6; viota.m v6, v2; vse8.v v6,(x22); lw t6,0(x22); lw t3,4(x22)

    /* --- masked (v0 predicate) --- */
    Z6; viota.m v6, v2, v0.t; vse8.v v6,(x22); lw t4,0(x22); lw t5,4(x22)
    Z6; vmsbf.m v6, v2, v0.t; vse8.v v6,(x22); lw t6,0(x22)
    Z6; vmsif.m v6, v2, v0.t; vse8.v v6,(x22); lw t3,0(x22)

    /* --- empty mask (all zero) --- */
    Z6; vmsif.m v6, v3; vse8.v v6,(x22); lw t4,0(x22)
    Z6; viota.m v6, v3; vse8.v v6,(x22); lw t5,0(x22)

    /* --- viota @ e16 / e32 --- */
    vsetvli t1, a0, e16, m1, ta, ma
    vmv.v.i v6, 0
    viota.m v6, v2; vse16.v v6,(x22); lw t6,0(x22); lw t3,4(x22)
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vmv.v.i v6, 0
    viota.m v6, v2; vse32.v v6,(x22); lw t4,0(x22); lw t5,4(x22)

    /* --- terminator: viota @ vstart!=0 = illegal (both trap) --- */
    csrw vstart, 1
    viota.m v6, v2
    ebreak

.section .data
.align 6
src: .byte 0,0,1,1,0,0,1,0
.align 6
msk: .byte 0,0,0,1,0,0,1,1
.align 6
dst: .space 32
