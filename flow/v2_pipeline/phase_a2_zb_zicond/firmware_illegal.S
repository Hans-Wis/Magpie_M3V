/* A2 illegal negative test (DUT-side): 4 RESERVED encodings in the tightened OP/OP-IMM
 * space must trap (mcause=2); handler counts them in s11 and advances mepc. M1 baseline
 * silently wrong-decoded these as base ops — A2 decode tightening makes them trap. */
.section .init
.global _start
_start:
    la   t0, handler
    csrw mtvec, t0
    li   s11, 0
    .word 0x20b512b3      /* f7=0010000(zba) f3=001 -> reserved */
    .word 0x0ab50533      /* f7=0000101 f3=000 -> reserved (no clmul) */
    .word 0x60b51513      /* OP-IMM f3=001 f7=0110000 rs2sel=01011 -> reserved unary */
    .word 0x68b55513      /* OP-IMM f3=101 f7=0110100 rs2!=11000 -> reserved (not rev8) */
    addi a0, s11, 0       /* a0 = trap count, lands in commit trace */
done:
    ebreak
    .balign 4
handler:
    csrr t1, mcause
    li   t2, 2
    bne  t1, t2, bad
    addi s11, s11, 1
    csrr t1, mepc
    addi t1, t1, 4
    csrw mepc, t1
    mret
bad:
    ebreak
