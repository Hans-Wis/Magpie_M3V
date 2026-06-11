/* phase_a2_zb — directed lockstep for Zba/Zbb/Zbs/Zicond (ADR-0026 A2).
 * Deterministic, trap-free -> FULL per-commit Spike lockstep. Every implemented op with
 * sign/edge operands; results all land in compared GPRs. Also reads misa (parity check:
 * DUT 0x40001106 == Spike --priv=m with zba_zbb_zbs — the B-bit policy probe).
 * Forwarding interplay: BMU results produced/consumed back-to-back (EX/MEM forward path,
 * unlike MUL the BMU is single-cycle at EX so it forwards like an ALU op).
 */
.section .init
.global _start

_start:
    li   s0, 0x1234
    li   s1, -13
    li   s2, 0x7fffffff
    li   s3, 0x80000000
    li   s4, 0x00f0
    li   s5, 0

    /* misa.B parity */
    csrr a0, misa

    /* Zba */
    sh1add t0, s0, s4
    sh2add t1, s0, s4
    sh3add t2, s0, s4
    sh1add t3, s1, s2          /* negative + max */
    sh3add t4, s3, s3          /* min + min */

    /* Zbb logic (incl b2b forwarding: consumer uses producer at distance 1) */
    andn  a1, s0, s4
    orn   a2, a1, s0           /* dist-1 BMU->BMU forward */
    xnor  a3, a2, a1

    /* Zbb count: edges 0 / -1 / 0x80000000 / mixed */
    clz   a4, s5
    clz   a5, s3
    ctz   a6, s5
    ctz   a7, s0
    cpop  t5, s5
    cpop  t6, s2

    /* Zbb min/max sign matrix */
    min   t0, s1, s4
    minu  t1, s1, s4
    max   t2, s1, s4
    maxu  t3, s3, s2

    /* Zbb sext/zext/rot/byte */
    sext.b t4, s0
    sext.h t5, s3
    zext.h t6, s1
    rol    a1, s0, s4
    ror    a2, s0, s4
    rori   a3, s0, 5
    rori   a4, s0, 0           /* shamt edge 0 */
    orc.b  a5, s0
    rev8   a6, s0

    /* Zbs reg + imm forms, bit-31 edge */
    bclr  t0, s2, s4
    bext  t1, s3, s4
    binv  t2, s0, s4
    bset  t3, s5, s4
    bclri t4, s2, 31
    bexti t5, s3, 31
    binvi t6, s0, 0
    bseti a1, s5, 31

    /* Zicond: rs2 zero / nonzero both ways */
    czero.eqz a2, s0, s5       /* cond=0  -> 0 */
    czero.eqz a3, s0, s4       /* cond!=0 -> s0 */
    czero.nez a4, s0, s5       /* cond=0  -> s0 */
    czero.nez a5, s0, s4       /* cond!=0 -> 0 */

    /* BMU result feeding base ALU + load/store + mul (cross-unit forwarding) */
    sh2add a6, s0, s4
    add    a7, a6, s1          /* BMU -> ALU dist 1 */
    la     t0, scratch
    sh1add t1, s5, t0          /* address arithmetic via Zba */
    sw     a6, 0(t1)
    lw     t2, 0(t1)
    mul    t3, a6, s0          /* BMU -> MUL operand */
    cpop   t4, t3              /* MUL -> BMU dist 1 (mul-use stall + forward) */

done:
    ebreak

    .balign 4
scratch:
    .word 0
