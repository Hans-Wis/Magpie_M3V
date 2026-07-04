/* ADR-0036 gate_44 — TCM harness for the UNMODIFIED Phase 0 kernel (vdot_i8.c,
 * compiled by clang with the exact Phase 0 -march=rv32im_zve32x_zvl128b).
 * dot([1..8],[2..9]) = 240. The result enters the compared commit stream via
 * mv + sw/lw readback; ebreak terminates lockstep (same dual-image discipline).
 */
.section .init
.global _start
_start:
    li   t0, 0x200            /* mstatus.VS = Initial (Phase 0 crt0 did the same) */
    csrs mstatus, t0
    li   sp, 0x0F00
    la   a0, vec_a
    la   a1, vec_b
    li   a2, 8
    call vdot_i8
    mv   s0, a0               /* 240 lands in the compared stream */
    la   t1, result_slot
    sw   a0, 0(t1)
    lw   s1, 0(t1)            /* memory readback: result region == Spike */
    ebreak

    .balign 4
vec_a:
    .byte 1, 2, 3, 4, 5, 6, 7, 8
vec_b:
    .byte 2, 3, 4, 5, 6, 7, 8, 9
    .balign 4
result_slot:
    .word 0
