/* Phase 2 Step 4 directed NPU-sequencer lockstep program (ADR-0034 gate_31).
 * rv32im only (EN_RVC=0). Exercises the ADR-0032 strip risks at system level:
 *  - mul/div busy back-to-back (M-unit stall with forwarding)
 *  - branch taken / not-taken: EX-resolve is the ONLY redirect (BP/RAS off)
 *  - jal/jalr call-return (no RAS prediction)
 *  - load-use hazard into ALU
 * Loop x64 => ~1300 commits (gate bar: >=500). ebreak = sole terminator (ADR-0034);
 * the DONE mailbox is deliberately not touched here (that is gate_30's directed test).
 */
.section .init
.global _start
_start:
    lui  sp, 1              /* sp = 0x1000 (TCM top, unused) */
    la   x31, data_area
    addi x30, zero, 7       /* divisor */
    addi x29, zero, 64      /* loop count */
    addi x5,  zero, 3
    addi x6,  zero, -9
    addi x12, zero, 0
    addi x13, zero, 0
    addi x15, zero, 0
    addi x16, zero, 0
    addi x17, zero, 0
loop:
    mul  x7,  x5, x6
    mulh x8,  x7, x6
    div  x9,  x7, x30
    rem  x10, x7, x30
    divu x11, x8, x30
    beq  x5, x6, skip1      /* not taken */
    addi x12, x12, 1
skip1:
    bne  x5, x6, take1      /* taken -> EX redirect */
    addi x13, x13, 99       /* must be skipped */
take1:
    jal  x1, sub1           /* call (no RAS) */
    lw   x14, 0(x31)        /* load-use pair */
    add  x15, x14, x5
    sw   x15, 4(x31)
    lw   x16, 4(x31)
    addi x16, x16, 1
    addi x29, x29, -1
    bne  x29, zero, loop
    ebreak

sub1:
    addi x17, x17, 5
    jalr x0, x1, 0          /* return (no RAS) */

    .balign 4
data_area:
    .word 0x12345678
    .word 0x00000000
