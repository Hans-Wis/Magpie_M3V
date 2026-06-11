/* phase_03_15 bp_way1 — directed 2-way BTB associativity coverage (blocker #1, u_bp way1).
 *
 * In the random farm the branch predictor's SECOND way is never exercised: rd_hit1 and
 * predict_from_way1 stay cold (random branches rarely alias to the same BTB set with a
 * different tag and then re-execute taken). This directed program forces it.
 *
 * bp.v: 32 sets indexed by PC[5:1], tag = PC[31:7], 2 ways + LRU replacement.
 *   brA @ 0x100 -> set index 0, tag 0x2     (fills way0; LRU then points to way1)
 *   brB @ 0x180 -> set index 0, tag 0x3     (miss, same index -> fills way1 via LRU)
 * Looping 16x: after warm-up, fetching brB READS way1 (rd_hit1) and, once counter1
 * saturates taken, predicts from it (predict_from_way1). Both branches are always-taken
 * (beq x0,x0), so the program is fully deterministic -> per-commit Spike lockstep.
 *
 * Ends in ebreak. Done-sentinel 0x600d -> 0x10000000.
 */
.section .init
.global _start

_start:
    li   t0, 0                /* iteration counter */
    li   t2, 16               /* iterations (>= a few to saturate counter1) */
    j    loop_start

    .org 0x44                 /* idx2 (NOT a 0x40 multiple) so this jal does not alias BTB set 0;
                                 only brA/brB may write set 0 -> two stable tags fill both ways */
loop_start:
    j    brA                  /* jump over the gap to the pinned branch sites */

    .org 0x100
brA:                          /* set index 0, tag 0x2 */
    beq  x0, x0, brA_t        /* always taken */
    nop
brA_t:
    j    brB

    .org 0x180
brB:                          /* set index 0, tag 0x3 -> way1 */
    beq  x0, x0, brB_t        /* always taken */
    nop
brB_t:
    addi t0, t0, 1
    blt  t0, t2, loop_start

    li   t5, 0x10000000
    li   t6, 0x0000600d
    sw   t6, 0(t5)
    ebreak
