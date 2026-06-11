/* phase_a1_mul — directed coverage of the A1 issue-decoupled MUL (ADR-0026 A1).
 *
 * Deterministic program, FULL per-commit Spike lockstep. Exercises every hazard corner the
 * load-like MUL design introduces (Grok design-review holes 1-4):
 *   1. back-to-back MULs            (throughput-1 issue, b2b operand capture)
 *   2. mul -> use at distance 1     (mul-use stall + WB forward)
 *   3. mul -> use at distance 2     (WB forward, no stall)
 *   4. mul -> mul RAW at distance 1 (producer in MEM, consumer needs stall)
 *   5. all four ops sign matrix     (MUL/MULH/MULHSU/MULHU, +/- operands)
 *   6. mul right before/after load  (mul-use and load-use interplay)
 *   7. MUL on the WRONG PATH of a taken branch (squash: stateless mul must not corrupt)
 *   8. div -> mul and mul -> div    (blocking DIV FSM vs pipelined MUL arbitration)
 *   9. ERRATA-0001 regression       (load -> div/divu/rem dist-1 stale-operand, frozen-M1 bug)
 *   (trap-x-mul interplay is covered at scale by the riscv-dv farm streams, which mix
 *   sync traps with the new pipelined MUL; this directed test stays trap-free so the
 *   whole program is FULL per-commit lockstep — Spike halts commit logging at traps.)
 * Ends at ebreak (no MMIO store — unmapped in Spike); correctness = per-commit lockstep.
 */
.section .init
.global _start

_start:
    li   sp, 0x3000
    li   s0, 7
    li   s1, -13
    li   s2, 0x7fffffff
    li   s3, 0x80000000
    li   s4, 100

    /* 1. back-to-back MULs (independent dests) */
    mul  a0, s0, s1
    mul  a1, s1, s2
    mul  a2, s2, s3
    mul  a3, s3, s0
    mul  a4, s0, s4
    mul  a5, s4, s1

    /* 2. mul -> use distance 1 (stall + forward) */
    mul  t0, s0, s4
    add  t1, t0, s0
    /* 3. mul -> use distance 2 (forward, no stall) */
    mul  t2, s1, s4
    nop
    add  t3, t2, s1

    /* 4. mul -> mul RAW distance 1 */
    mul  t4, s0, s1
    mul  t5, t4, s0
    mul  t6, t5, t5

    /* 5. sign matrix: MULH/MULHSU/MULHU with +/-, extreme values */
    mulh   a6, s1, s1
    mulh   a7, s2, s2
    mulhsu t0, s1, s4
    mulhsu t1, s3, s3
    mulhu  t2, s3, s3
    mulhu  t3, s1, s1
    mul    t4, s3, s3

    /* 6. mul/load interplay (load-use + mul-use back to back) */
    la   t5, scratch       /* PC-relative: mapped in BOTH DUT(0x0-base) and Spike(0x80000000) */
    sw   s0, 0(t5)
    lw   t6, 0(t5)         /* load */
    mul  a0, t6, s0        /* load-use into mul operand */
    lw   t6, 0(t5)
    mul  a1, s0, s1
    add  a2, a1, t6        /* consumes both mul (dist 2) and load (dist 2) */

    /* 7. MUL on the wrong path of a taken branch (must be squashed cleanly) */
    li   t0, 1
    bnez t0, 1f            /* taken: the following mul is wrong-path fetch */
    mul  a3, s2, s3        /* WRONG PATH — must never retire */
    add  a4, a3, s0        /* wrong path too */
1:  mul  a5, s0, s0        /* right path resumes; back-to-back with redirect */

    /* 8. div -> mul and mul -> div (blocking FSM vs pipelined unit) */
    div  t1, s4, s0
    mul  t2, t1, s0        /* div result consumed by mul, dist 1 */
    mul  t3, s4, s4
    divu t4, t3, s0        /* mul result consumed by div, dist 1 */
    rem  t5, s4, s1
    mul  t6, t5, t5

    /* 9. ERRATA-0001 regression (frozen-M1 bug): load -> div/divu/rem at distance 1.
     *    The div must NOT latch the stale pre-load register value (md_start gated on
     *    operand_stall). On frozen M1 this miscomputes (DUT 0 vs Spike 14). */
    la   t5, scratch
    sw   s4, 0(t5)
    lw   t0, 0(t5)
    div  t1, t0, s0        /* 100/7 = 14 */
    lw   t2, 0(t5)
    divu t3, t2, s0
    lw   t4, 0(t5)
    rem  t6, t4, s0        /* 100%7 = 2 */
    add  a0, t1, t3
    add  a0, a0, t6

    /* 10: mul chained into the program tail right before ebreak */
    mul  a6, s1, s4
    mul  a7, a6, s0

    /* checksum + done sentinel */
    add  a0, a0, a1
    add  a0, a0, a2
    add  a0, a0, a5
    add  a0, a0, a7
done:
    ebreak                 /* TB and Spike both stop here; no MMIO store (unmapped in Spike) */

    .balign 4
scratch:
    .word 0
