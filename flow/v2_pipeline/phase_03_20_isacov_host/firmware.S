/* ADR-0063 V1 closure (host): exercise the RV32IMC + Zicsr residuals that the
   regression had not emitted — c.jalr (indirect call), c.jr (computed jump +
   compressed ret), csrrsi/csrrci (CSR immediate set/clear). Host cpu_m1 core,
   rv32imc lockstep vs Spike. Deterministic, self-terminating (ebreak). */
.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    /* csrrsi / csrrci — CSR immediate (rd != x0 keeps the base mnemonic) */
    csrrsi t0, mscratch, 5        /* mscratch |= 0b00101 */
    csrrci t1, mscratch, 1        /* mscratch &= ~0b00001 */
    csrrsi t2, mscratch, 4        /* mscratch |= 0b00100, read old into t2 */

    /* c.jalr — indirect call to sub_fn (jalr a0 => 16-bit c.jalr) */
    la   a0, sub_fn
    jalr a0

    /* c.jr — computed jump to done (jr a1 => 16-bit c.jr) */
    la   a1, done
    jr   a1

    addi s0, zero, 99            /* skipped: proves the c.jr took */

sub_fn:
    addi a2, zero, 7
    ret                          /* compressed return => c.jr ra */

done:
    ebreak
