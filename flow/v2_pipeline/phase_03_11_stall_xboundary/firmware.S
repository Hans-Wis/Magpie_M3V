/* phase_03_11_stall_xboundary — directed stress for the BUG-XBOUND-0001 "Open lead":
 *
 *   a load-use / muldiv STALL or a branch REDIRECT landing ON a consecutive
 *   cross-boundary 32-bit RVC run holds cross_assemble/residue while i_mem_addr
 *   reverts to the held PC, so the resumed {cur_half_lo, residue} could use a
 *   stale cur_half_lo and mis-assemble a 32-bit instruction.
 *
 * The narrow arith+RVC riscv-dv farm cannot reach this (no loads -> no load-use
 * stall during a run). This directed program forces the corner and proves it
 * against Spike per-commit.
 *
 * Construction: ONE c.nop (16-bit) at a 4-byte boundary pushes PC to the odd
 * half-word (%4==2); every following 32-bit instruction then starts at a high
 * half and crosses a word boundary -> a *consecutive* cross-boundary run.
 * Inside that run we place:
 *   - lw + dependent use            -> load-use stall ON the run
 *   - mul + dependent use           -> muldiv busy stall ON the run
 *   - div + dependent use           -> muldiv busy stall ON the run
 *   - taken forward bne -> runB     -> redirect lands ON a cross-boundary instr
 *                                      (the skipped addi is wrong-path: must NOT commit)
 *   - taken backward bne -> runA    -> 2nd pass re-enters the run via redirect
 *                                      (fallback cross path, not the prefetch path)
 *
 * Data is a write-then-read scratch word addressed PC-relative (la), so the
 * loaded value is identical on DUT (base 0x0) and Spike (base 0x8000_0000); the
 * lockstep normalizer re-derives auipc/la writebacks at the DUT base.
 */

.section .text
.global _start
_start:
.option norvc
    li    t0, 0x12345678        /* store/compare constant (lui+addi, 32-bit each) */
    li    t1, 13
    li    t2, 7
    li    t4, 0                 /* loop counter */
    la    t3, scratch           /* auipc+addi: PC-relative scratch pointer */
    sw    t0, 0(t3)             /* scratch = 0x12345678 (so the load is deterministic) */

.option rvc
    c.nop                       /* 16-bit: push PC to odd half-word -> arm cross-boundary */
.option norvc

runA:                           /* %4==2: start of the consecutive cross-boundary run */
    lw    a0, 0(t3)             /* cross-boundary 32-bit load */
    addi  a1, a0, 1             /* LOAD-USE stall ON the cross-boundary run */
    xor   a2, a1, t1
    mul   a3, a1, t2            /* cross-boundary multiply */
    add   a4, a3, a2            /* MULDIV-USE stall ON the cross-boundary run */
    sub   a5, a4, t0
    bne   t4, t2, runB          /* taken (counter != 7): REDIRECT onto a cross instr */
    addi  a6, a5, 99            /* WRONG-PATH: must be flushed, must NOT commit */

runB:                           /* %4==2: redirect target, still cross-boundary */
    or    a7, a5, t1
    and   s2, a7, t2
    div   s3, a7, t2            /* cross-boundary divide */
    add   s4, s3, s2            /* DIV-USE stall ON the cross-boundary run */
    xor   s5, s4, t0

    addi  t4, t4, 1             /* advance loop counter */
    li    t5, 2
    bne   t4, t5, runA          /* 1st pass: taken -> BACKWARD redirect onto runA (cross) */

.option rvc
    c.ebreak                    /* halt: stops DUT trace and Spike trace symmetrically */
.option norvc

.balign 4
scratch:
    .word 0
