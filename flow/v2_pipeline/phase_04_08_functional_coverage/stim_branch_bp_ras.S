.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    fence

    li   t0, 1
    li   t1, 1
    beq  t0, t1, beq_taken
    addi s0, zero, -1
beq_taken:
    bne  t0, t1, bne_not_taken_bad
    addi s0, zero, 1
bne_not_taken_bad:

    li   t2, -1
    li   t3, 2
    blt  t2, t3, blt_taken
    addi s1, zero, -1
blt_taken:
    bge  t2, t3, bge_not_taken_bad
    addi s1, zero, 2
bge_not_taken_bad:

    li   t4, 3
    li   t5, 4
    bltu t4, t5, bltu_taken
    addi s2, zero, -1
bltu_taken:
    bgeu t4, t5, bgeu_not_taken_bad
    addi s2, zero, 3
bgeu_not_taken_bad:

    li   a0, 0
    li   a1, 20
bp_train_loop:
    addi a0, a0, 1
    blt  a0, a1, bp_train_loop

    jal  ra, func_a
    la   t0, jalr_target
    jalr ra, 0(t0)
after_jalr:
    ebreak

jalr_target:
    addi s3, zero, 4
    jalr zero, 0(ra)

func_a:
    addi sp, sp, -16
    sw   ra, 12(sp)
    jal  ra, func_b
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

func_b:
    addi sp, sp, -16
    sw   ra, 12(sp)
    jal  ra, func_c
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

func_c:
    addi s4, zero, 5
    ret
.option pop
