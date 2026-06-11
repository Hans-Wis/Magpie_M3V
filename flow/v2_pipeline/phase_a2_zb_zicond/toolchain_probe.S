.section .init
.global _start
_start:
    li   a0, 0x1234
    li   a1, 0x00f0
    sh1add t0, a0, a1
    sh2add t1, a0, a1
    sh3add t2, a0, a1
    andn  t3, a0, a1
    orn   t4, a0, a1
    xnor  t5, a0, a1
    clz   t6, a0
    ctz   s2, a0
    cpop  s3, a0
    min   s4, a0, a1
    maxu  s5, a0, a1
    sext.b s6, a0
    sext.h s7, a0
    zext.h s8, a0
    rol   s9, a0, a1
    ror   s10, a0, a1
    rori  s11, a0, 5
    orc.b a2, a0
    rev8  a3, a0
    bclr  a4, a0, a1
    bext  a5, a0, a1
    binv  a6, a0, a1
    bset  a7, a0, a1
    bclri t0, a0, 3
    czero.eqz t1, a0, a1
    czero.nez t2, a0, a1
    ebreak
