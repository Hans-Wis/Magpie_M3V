/* phase_03_14 msip (M software interrupt, CLINT-sourced) directed lockstep slice.
 *
 * Closes Tier-2 blocker #4b's lockstep-able path: msip is the deterministic interrupt
 * (CLINT software-int) — unlike truly-async meip/mtip, the program decides exactly when it
 * becomes pending, so DUT and Spike agree on the pre-IRQ commit prefix. We compare that
 * prefix per-commit against Spike (which has no msip driven, so it runs straight through),
 * then validate the DUT's interrupt handler CSRs against the RISC-V Priv spec — the same
 * "prefix-lockstep + spec-validated handler" rigor accepted for the through-trap slice
 * (gate_03_12).  mcause must be 0x8000_0003 (interrupt, code 3 = M software, ADR-0019).
 *
 * MMIO evidence map (d_mem_addr[28]=1 => MMIO in the TB):
 *   0x10000000 : handler stores mepc
 *   0x10000004 : handler stores mcause   (expect 0x8000_0003)
 *   0x10000008 : handler stores mstatus  (expect 0x0000_1880: MPP=11 + MPIE=1)
 *   0x10000010 : handler stores 0 -> TB drops msip (models software clearing CLINT msip)
 *   0x1000000c : main stores 0x600d done-sentinel
 */
.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    la   t0, mtvec_handler
    csrw mtvec, t0

    li   t0, (1 << 3)          /* MIE.MSIE — enable M software interrupt */
    csrs mie, t0
    li   t0, (1 << 3)          /* mstatus.MIE — global M-mode interrupt enable */
    csrs mstatus, t0

    addi s2, zero, 3
    addi s3, s2, 4

    j    irq_target

    .org 0x80
.option push
.option rvc
.global irq_target
irq_target:
    c.addi s0, 1               /* TB asserts msip when PC reaches this 16-bit target */
after_irq:
    c.li   s1, 2
.option pop

    li   t0, 0x10000000
    li   t1, 0x0000600d
    sw   t1, 12(t0)
done:
    ebreak

    .balign 4
    .org 0x100
.global mtvec_handler
mtvec_handler:
    li   t0, 0x10000000
    csrr t1, mepc
    sw   t1, 0(t0)
    csrr t1, mcause
    sw   t1, 4(t0)
    csrr t1, mstatus
    sw   t1, 8(t0)
    sw   zero, 16(t0)          /* clear msip (CLINT software-int ack) -> TB drops msip */
    mret
