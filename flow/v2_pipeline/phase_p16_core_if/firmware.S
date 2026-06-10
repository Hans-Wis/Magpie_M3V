.section .init
.global _start

_start:
    la   sp, stack_top
    la   s0, data_area
    la   t0, high_if_suite
    jalr ra, 0(t0)

low_done:
    ebreak

    .org 0x00100100
data_area:
    .word 0x11223344
    .word 0x55667788
    .word 0x99aabbcc
    .word 0xddeeff00
    .space 128
stack_top:

    .org 0x00300800
high_if_suite:
    addi s1, zero, 1

    /*
     * p16_xbound_00: 16-bit low halfword tail, then a 32-bit ADDI starting
     * at PC[1]=1.  This is the BUG-XBOUND-0001 primary repro shape.
     */
    .balign 4
.option push
.option rvc
    c.addi s1, 1
.option pop
.option push
.option norvc
p16_odd_aligned_addi:
    addi s2, s1, 0x11
.option pop

    /*
     * p16_xbound_01: compressed tail followed by the head of a 32-bit op,
     * then another 32-bit op at the next odd halfword.  This exercises
     * consecutive cross-boundary residue handoff without a fallback bubble.
     */
    .balign 4
.option push
.option rvc
    c.addi s1, 1
.option pop
.option push
.option norvc
p16_consecutive_32b_0:
    addi s3, s2, 0x22
p16_consecutive_32b_1:
    addi s4, s3, 0x33
.option pop

    /*
     * p16_xbound_02: c.lw at the low halfword immediately followed by a
     * 32-bit high-halfword instruction, repeated to keep the IF residue path
     * active across compressed memory operations.
     */
    .balign 4
.option push
.option rvc
    c.lw  a0, 0(s0)
.option pop
.option push
.option norvc
p16_clw_then_32b_0:
    addi a1, a0, 7
.option pop

    .balign 4
.option push
.option rvc
    c.lw  a2, 4(s0)
.option pop
.option push
.option norvc
p16_clw_then_32b_1:
    addi a3, a2, 9
.option pop

    /*
     * p16_xbound_03: C.JAL and C.J redirect to a high-halfword 32-bit target.
     * Redirect realignment must discard stale residue and fetch the target word.
     */
    .balign 4
.option push
.option rvc
    c.jal p16_cjal_cross_target
.option pop
    addi t6, zero, -1
    ebreak

    .balign 4
.option push
.option rvc
    c.nop
.option pop
.option push
.option norvc
p16_cjal_cross_target:
    addi s5, ra, 0
.option pop

    .balign 4
.option push
.option rvc
    c.j p16_cj_cross_target
.option pop
    addi t6, zero, -2
    ebreak

    .balign 4
.option push
.option rvc
    c.nop
.option pop
.option push
.option norvc
p16_cj_cross_target:
    addi s6, s5, 0x44
.option pop

    /*
     * p16_xbound_04: a taken 32-bit branch starts at a high halfword after
     * residue setup.  The redirect occurs after a cross-boundary instruction
     * and must clear/reload the IF assembly state.
     */
    .balign 4
.option push
.option rvc
    c.addi s1, 1
.option pop
.option push
.option norvc
p16_redirect_after_cross:
    beq  s1, s1, p16_redirect_target
    addi t6, zero, -3
    ebreak
.option pop

    .balign 4
.option push
.option rvc
    c.nop
.option pop
.option push
.option norvc
p16_redirect_target:
    addi s7, s6, 0x55
.option pop

    /*
     * p16_xbound_05: high PC-range toggling for IF path and pipeline PC
     * propagation bits that were deferred from P15.
     */
    la   t0, high_if_probe
    jalr t1, 0(t0)
after_high_probe:
    la   t0, low_done
    jalr zero, 0(t0)

    .org 0x003ff100
high_if_probe:
    addi t2, zero, 0x5a

    .balign 4
.option push
.option rvc
    c.addi t2, 1
.option pop
.option push
.option norvc
high_probe_cross:
    addi t3, t2, 0x66
    addi t4, t3, 0x77
.option pop

    jalr zero, 0(t1)
