/* ADR-0063 V5 backlog #2 (host): exercise the bmu (Zba/Zbb/Zbs bit-manip) datapath —
   bmu.v line coverage was 6% because the earlier host coverage runs were rv32imc-only.
   Each op has a distinct rd (!=x0) so results are lockstep-compared vs Spike
   (rv32imc_zba_zbb_zbs). Deterministic, self-terminating. */
.section .init
.global _start
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   a0, 0x0F0F1234
    li   a1, 0x00FF00FF
    li   a2, 0x00000005

    /* ---- Zbb: logic-with-negate ---- */
    andn s0, a0, a1
    orn  s1, a0, a1
    xnor s2, a0, a1
    /* ---- Zbb: count ---- */
    clz  s3, a1
    ctz  s4, a1
    cpop s5, a0
    /* ---- Zbb: min/max ---- */
    min  s6, a0, a1
    max  s7, a0, a1
    minu s8, a0, a1
    maxu s9, a0, a1
    /* ---- Zbb: sign/zero extend ---- */
    sext.b s10, a0
    sext.h s11, a0
    zext.h t0, a0
    /* ---- Zbb: rotate ---- */
    rol  t1, a0, a2
    ror  t2, a0, a2
    rori t3, a0, 7
    /* ---- Zbb: byte ops ---- */
    orc.b t4, a1
    rev8  t5, a0
    /* ---- Zba: shift-add ---- */
    sh1add t6, a2, a0
    sh2add s0, a2, a0
    sh3add s1, a2, a0
    /* ---- Zbs: single-bit ---- */
    bclr  s2, a0, a2
    bclri s3, a0, 12
    bext  s4, a0, a2
    bexti s5, a0, 12
    binv  s6, a0, a2
    binvi s7, a0, 12
    bset  s8, a0, a2
    bseti s9, a0, 12

    ebreak
