.section .init
.global _start

_start:
    la   t0, high_pc_probe
    jalr ra, 0(t0)

low_done:
    ebreak

    .org 0x00300000
high_bpras_suite:
.option push
.option norvc
    la   sp, stack_top

    /*
     * Taken/not-taken backward branch pair.  The repeated taken updates train
     * the BHT counter; the final fall-through forces a direction recovery.
     */
    addi t0, zero, 0
    addi t1, zero, 8
.global p18_train_taken_a
p18_train_taken_a:
    addi t0, t0, 1
    blt  t0, t1, p18_train_taken_a

    addi t0, zero, 0
    addi t1, zero, 6
.global p18_train_taken_b
p18_train_taken_b:
    addi t0, t0, 1
    bne  t0, t1, p18_train_taken_b

    /*
     * Four-plus taken updates at one high-PC offset, then enough not-taken
     * outcomes at the same offset to exercise down-saturation and recovery.
     */
    addi t2, zero, 5
.global p18_saturate_taken
p18_saturate_taken:
    addi t2, t2, -1
    bne  t2, zero, p18_saturate_taken

    addi t2, zero, 0
.global p18_saturate_not_taken
p18_saturate_not_taken:
    bne  t2, zero, p18_saturate_not_taken
    bne  t2, zero, p18_saturate_not_taken
    bne  t2, zero, p18_saturate_not_taken
    bne  t2, zero, p18_saturate_not_taken

    /*
     * Target alias: two branch PCs separated by 64 bytes share bp.v index
     * bits [6:1] while using different targets/tags.
     */
    addi t3, zero, 1
.global p18_alias_a
p18_alias_a:
    beq  t3, t3, p18_alias_a_target
    addi s0, zero, -1
p18_alias_a_target:
    addi s0, zero, 0x44
    .rept 13
    nop
    .endr
.global p18_alias_b
p18_alias_b:
    beq  t3, t3, p18_alias_b_target
    addi s0, zero, -2
p18_alias_b_target:
    addi s0, zero, 0x55

    /*
     * Call/return path.  The first call pushes a high return address and the
     * return predicts through RAS.  The second call poisons ra before ret, so a
     * valid but stale RAS top must recover to the actual JALR target.
     */
    jal  ra, p18_call_leaf
p18_returned_from_leaf:
    addi s1, zero, 0x11

    jal  ra, p18_poison_ret
p18_predicted_return:
    addi s2, zero, -1
    jal  zero, p18_fail

p18_actual_return:
    addi s2, zero, 0x22

    /*
     * JAL target prediction/update path: second trip should have a trained
     * BTB entry; fall-through code after the JAL must stay wrong-path only.
     */
    jal  ra, p18_jal_target
p18_after_jal:
    addi s3, zero, 0x33
    jal  zero, p18_done_high

p18_jal_target:
    addi s4, zero, 0x44
    ret

p18_call_leaf:
    addi s5, zero, 0x66
    ret

p18_poison_ret:
    la   t4, p18_actual_return
    mv   ra, t4
    ret

p18_fail:
    addi s6, zero, -1
    ebreak

p18_done_high:
    la   t0, low_done
    jalr zero, 0(t0)
.option pop

    .balign 16
    .space 256
stack_top:

    .org 0x003fff00
high_pc_probe:
.option push
.option norvc
    la   t0, high_bpras_suite
    jalr ra, 0(t0)
.option pop
