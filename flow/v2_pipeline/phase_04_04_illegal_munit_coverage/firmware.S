.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)
    li   s0, 0x10000000

    addi s1, zero, 37
    addi s2, zero, 5
    addi s3, zero, -3
    addi s4, zero, -1
    lui  s5, 0x80000

    mul    t0, s1, s2
    mulh   t1, s3, s2
    mulhsu t2, s3, s2
    mulhu  t3, s1, s2
    div    t4, t0, s2
    rem    t5, t0, s2
    add    t6, t4, t5
    bne    t6, s1, fail

    div    a0, s1, zero
    addi   a1, zero, -1
    bne    a0, a1, fail
    rem    a2, s1, zero
    bne    a2, s1, fail
    div    a3, s5, s4
    bne    a3, s5, fail
    rem    a4, s5, s4
    bne    a4, zero, fail
    divu   a5, t0, s2
    remu   a6, t0, s2
    add    a7, a5, a6
    bne    a7, s1, fail

    la     t0, after_c_jalr
    .option push
    .option rvc
    c.jalr t0
    .option pop
after_c_jalr:
    li   t2, 0xa0a
    sw   t2, 36(s0)

done:
    j done

fail:
    li   t2, 0xbad
    sw   t2, 40(s0)
    j fail
