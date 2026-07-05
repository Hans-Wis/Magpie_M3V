/* ADR-0057 Phase-D D1a directed: mask-scan simple set (vid.v, vcpop.m, vfirst.m).
   vid.v: vd[i]=i (vector dest). vcpop.m: rd = popcount of active vs2 mask bits.
   vfirst.m: rd = first active set index, else -1. Maskable (active = vm||v0[i]).
   m1-only. vstart!=0 illegal (Spike-probed: vcpop TRAPS at vstart!=0). Golden: mask
   {2,3,6} -> vcpop 3 / vfirst 2 / vid [0..7]; masked v0={3,6,7} -> vcpop 2 / vfirst 3;
   empty mask -> vcpop 0 / vfirst -1. Terminator: vid @ vstart!=0 (both trap).
   Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
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
    vmxor.mm v3, v0, v0         /* v3 = empty mask (all 0) */

    /* --- vid.v @ e8 --- */
    vid.v v6
    vse8.v v6,(x22); lw t3,0(x22); lw t4,4(x22)

    /* --- vcpop / vfirst (unmasked, masked, empty) --- */
    vcpop.m  a1, v2             /* 3  */
    vfirst.m a2, v2             /* 2  */
    vcpop.m  a3, v2, v0.t       /* v2&v0={3,6} -> 2 */
    vfirst.m a4, v2, v0.t       /* 3  */
    vcpop.m  a5, v3             /* 0  */
    vfirst.m a6, v3             /* -1 */

    /* --- vid.v @ e16 / e32 --- */
    vsetvli t1, a0, e16, m1, ta, ma
    vid.v v6
    vse16.v v6,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vid.v v6
    vse32.v v6,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* --- terminator: vid.v @ vstart!=0 = illegal (both trap) --- */
    csrw vstart, 1
    vid.v v6
    ebreak

.section .data
.align 6
src: .byte 0,0,1,1,0,0,1,0
.align 6
msk: .byte 0,0,0,1,0,0,1,1
.align 6
dst: .space 32
