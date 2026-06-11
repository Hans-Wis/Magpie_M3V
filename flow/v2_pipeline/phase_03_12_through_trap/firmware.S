/* phase_03_12_through_trap — THROUGH-TRAP per-commit Spike lockstep.
 *
 * Closes the §05/§P17 "through-trap not commit-by-commit" gap (Tier-2 blocker #3,
 * docs/reports/integration_closure.md P17, dv_methodology_equivalence.md). The prior
 * limitation was NOT a Spike --priv=m limitation (Spike does log commit-by-commit under
 * --priv=m) — the earlier directed trap firmware stored to UART MMIO that Spike does not
 * map, which faults and halts. This program keeps the entire traced window in plain
 * memory + CSRs, so DUT and Spike are compared commit-by-commit THROUGH the handler.
 *
 * The remaining obstacle was that a handler `csrr a0, mepc` returns an ABSOLUTE PC, which
 * differs between the DUT (base 0x0) and Spike (base 0x8000_0000). Fixed in the lockstep
 * harness: spike_commit.py now normalizes PC-holding CSR reads (mepc/mtvec/mtval) by
 * pc_base, so mepc is compared at the DUT base. mcause/mstatus are not PC-based and compare
 * as-is — a real architectural check of trap-entry CSR state.
 *
 * Flow: set mtvec(direct) -> ECALL (M-ecall, mcause 11) -> handler reads mepc/mcause/mstatus,
 * advances mepc past the 4-byte ecall, mret -> resume -> a second ECALL -> resume -> ebreak.
 * Every retired commit (incl. the handler body and the post-mret resume) is matched to Spike.
 */

.section .text
.global _start
_start:
.option norvc
    la    t0, handler
    csrw  mtvec, t0            /* direct-mode mtvec (base[1:0]=00) */
    li    s0, 0x11111111
    li    s1, 0x22222222

    ecall                      /* TRAP 1: M-mode ecall, mcause=11 */
    addi  s2, s0, 1            /* resume after trap 1 */
    xor   s3, s1, s0

    ecall                      /* TRAP 2 */
    add   s4, s2, s3           /* resume after trap 2 */
    sub   s5, s4, s0
    ebreak                     /* halt (32-bit, keeps everything 4-byte aligned) */

.balign 4
handler:
    csrr  a0, mepc             /* mepc (PC-holding) — normalized by harness, compared */
    csrr  a1, mcause           /* mcause == 11 (base-independent) — compared */
    csrr  a2, mstatus          /* mstatus trap-entry state — compared */
    addi  a0, a0, 4            /* advance past the 4-byte ecall */
    csrw  mepc, a0             /* return to the instruction after ecall */
    mret

.balign 4
scratch:
    .word 0
