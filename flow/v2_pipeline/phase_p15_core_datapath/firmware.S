.section .init
.global _start

_start:
    la   t0, high_pc_probe
    jalr ra, 0(t0)

low_done:
    ebreak

    .org 0x00300000
high_datapath_suite:
    la   sp, stack_top
    la   a0, data_area

    /* Back-to-back ALU and load-use stall: lw feeds the very next add. */
    addi t0, zero, 9
    addi t0, t0, 4
    lw   t1, 0(a0)
    add  t2, t1, t0

    /* EX/MEM forwarding: consumer immediately follows producer. */
    addi s0, zero, 5
    add  s1, s0, s0
    xor  s2, s1, s0

    /* WB forwarding: one independent op places the producer in WB. */
    addi s3, zero, 7
    addi a1, zero, 1
    add  s4, s3, s1

    /*
     * Full-width forwarded VALUE coverage.  Each producer is consumed by the
     * next instruction for EX/MEM forwarding, then again after one independent
     * instruction for EX/WB forwarding.  Keep this block uncompressed so PC4
     * link values are predictable while the wider RV32IMC suite still includes
     * compressed coverage below.
     */
.option push
.option norvc
    /* ALU wb_sel: dense 32-bit masks and sign bit. */
    lui  t0, 0xaaaab
    addi t0, t0, -1366
    add  t1, t0, zero
    addi t2, zero, 0
    xor  t3, t0, t2

    lui  t0, 0x55555
    addi t0, t0, 1365
    add  t1, t0, zero
    addi t2, zero, 0
    xor  t3, t0, t2

    addi t0, zero, -1
    add  t1, t0, zero
    addi t2, zero, 0
    xor  t3, t0, t2

    lui  t0, 0x80000
    add  t1, t0, zero
    addi t2, zero, 0
    xor  t3, t0, t2

    addi t0, zero, 0
    add  t1, t0, zero

    /* ALU wb_sel: walking one covers every bit position on ex_mem_fwd_val. */
    addi t0, zero, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    slli t0, t0, 1
    add  t1, t0, zero
    addi t0, zero, 0
    add  t1, t0, zero

    /* PC+imm wb_sel via AUIPC. */
    auipc t0, 0x55555
    add   t1, t0, zero
    addi  t2, zero, 0
    xor   t3, t0, t2
    auipc t0, 0xaaaab
    add   t1, t0, zero
    addi  t2, zero, 0
    xor   t3, t0, t2

    /* PC+4 wb_sel via JAL and JALR links to the immediately following PC. */
    jal   t0, 1f
1:  add   t1, t0, zero
    addi  t2, zero, 0
    xor   t3, t0, t2

    auipc t2, 0
    addi  t2, t2, 12
    jalr  t0, 0(t2)
2:  add   t1, t0, zero
    addi  t2, zero, 0
    xor   t3, t0, t2

    /* M-unit wb_sel: wide multiply/divide results, immediately consumed. */
    addi t4, zero, 1
    lui  t0, 0x80000
    mul  s0, t0, t4
    add  s1, s0, zero
    addi s2, zero, 0
    xor  s3, s0, s2

    lui  t0, 0xaaaab
    addi t0, t0, -1366
    mul  s0, t0, t4
    add  s1, s0, zero
    addi s2, zero, 0
    xor  s3, s0, s2

    addi t0, zero, -1
    div  s0, t0, t4
    add  s1, s0, zero
    addi s2, zero, 0
    xor  s3, s0, s2
.option pop

    /* WB result mux and MEM sign/zero-extension glue. */
    lb   a2, 1(a0)
    lbu  a3, 1(a0)
    lh   a4, 2(a0)
    lhu  a5, 2(a0)
    lw   a6, 4(a0)

    /* C.LWSP with rd=x16 exercises compressed expansion into datapath regs. */
.option push
.option rvc
    c.lwsp a6, 16(sp)
.option pop

    /* M-unit busy stalls hold younger independent ALU work for multiple cycles. */
    addi t3, zero, 13
    addi t4, zero, 3
    mul  t5, t3, t4
    addi t6, zero, 1
    add  s5, t6, t5
    div  s6, t5, t4
    addi s7, zero, 2
    add  s8, s6, s7

    /* Redirect near a recent load-use pair exercises flush priority around held IF/EX. */
    lw   s9, 8(a0)
    add  s10, s9, s8
    beq  zero, zero, flush_target
    add  s11, s9, s10
    addi s11, s11, 1

fail:
    addi s7, zero, -1
    ebreak

flush_target:
    add  a7, s10, s5
    bne  t2, zero, done
    jal  zero, fail

done:
    la   t0, low_done
    jalr zero, 0(t0)

    .balign 4
data_area:
    .word 0x00080880
    .word 0xfff77880
    .word 0x00080800
    .word 0
    .word 0x00080880
stack_top:

    .org 0x003fff00
high_pc_probe:
    la   t0, high_datapath_suite
    jalr ra, 0(t0)
