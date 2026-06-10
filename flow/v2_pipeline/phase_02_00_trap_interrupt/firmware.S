.section .init
.global _start

_start:
    /* Set stack to top of the 16 KB test memory. */
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    /* mtvec direct mode -> handler at 0x100. */
    la   t0, mtvec_handler
    csrw mtvec, t0

    /* Enable machine external interrupt and global MIE. */
    li   t0, (1 << 11)
    csrs mie, t0
    li   t0, (1 << 3)
    csrs mstatus, t0

    /* Jump to a fixed 16-bit instruction target. */
    j    irq_target

    .org 0x80
.option push
.option rvc
.global irq_target
irq_target:
    c.addi s0, 1              /* PC=0x80, length=2, expanded ADDI x8,x8,1 */
after_irq:
    c.li   s1, 2              /* Resume point must be PC=0x82 after mret. */
.option pop

    li   t0, 0x10000000
    li   t1, 0x0000600d
    sw   t1, 8(t0)            /* marker: mret resumed at after_irq */
done:
    j    done

    .balign 4
    .org 0x100
.global mtvec_handler
mtvec_handler:
    li   t0, 0x10000000
    csrr t1, mepc
    sw   t1, 0(t0)
    csrr t1, mcause
    sw   t1, 4(t0)
    mret
