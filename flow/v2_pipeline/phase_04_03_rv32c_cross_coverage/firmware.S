.section .init
.global _start

_start:
    .option push
    .option norvc
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)
    li   s0, 0x10000000
    addi a0, x0, 0
    addi a1, x0, 0
    addi a2, x0, 0
    addi a3, x0, 0
    addi a4, x0, 0
    addi a5, x0, 0
    .option pop

    .option push
    .option rvc
    c.addi4spn s1, sp, 16
    c.li   a0, 7
    c.sw   a0, 0(s1)
    c.lw   a1, 0(s1)
    c.addi a1, 1
    c.mv   a2, a1
    c.add  a2, a0
    c.swsp a2, 0(sp)
    c.lwsp a3, 0(sp)
    c.slli a3, 1
    c.srli a3, 1
    c.srai a3, 1
    c.andi a3, 31
    c.sub  a3, a0
    c.xor  a3, a1
    c.or   a3, a2
    c.and  a3, a2
    c.lui  a4, 1
    c.addi16sp sp, 16
    c.addi16sp sp, -16
    c.beqz a5, 1f
    c.li   a4, 1
1:
    c.li   a5, 3
    c.bnez a5, 2f
    c.li   a4, 2
2:
    c.jal  c_call_target
c_call_return:
    c.j    after_c_j
    c.li   a4, 4
after_c_j:
    .option pop
    .option push
    .option norvc
    li   t2, 0x707
    sw   t2, 24(s0)
    .option pop

    .balign 4
    .option push
    .option rvc
    c.nop
    .option pop
cross_fast32:
    .option push
    .option norvc
    addi a3, a3, 1
    li   t2, 0x808
    sw   t2, 28(s0)
    .option pop

    .balign 4
    .option push
    .option rvc
    c.j cross_fallback32
    .option pop
cross_fallback32:
    .option push
    .option norvc
    addi a3, a3, 2
    li   t2, 0x909
    sw   t2, 32(s0)
    .option pop

done:
    .option push
    .option norvc
    j done
    .option pop

    .option push
    .option rvc
c_call_target:
    c.li   a5, 6
    .option pop
    .option push
    .option norvc
    li   t2, 0x606
    sw   t2, 20(s0)
    .option pop
    .option push
    .option rvc
    c.jr   ra
    .option pop
