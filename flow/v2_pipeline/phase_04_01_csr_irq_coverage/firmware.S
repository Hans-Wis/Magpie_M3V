.section .init
.global _start

/* MMIO evidence map:
 * 0x10000000: old mscratch from csrrw, expected 0
 * 0x10000004: old mscratch from csrrs, expected 0x12345678
 * 0x10000008: old mscratch from csrrc, expected 0x1234567f
 * 0x1000000c: final mscratch, expected 0x12345677
 * 0x10000010: unknown CSR read, expected 0
 * 0x10000014: cycle low, expected non-zero
 * 0x10000018: instret low, expected non-zero
 * 0x1000001c: mip after pending IRQ while MIE=0, expected MEIP bit
 * 0x10000020: handler mepc
 * 0x10000024: handler mcause, expected external IRQ
 * 0x10000028: handler mstatus snapshot
 * 0x1000002c: mret resume marker store; value is not checked because the
 *             IRQ may resume between marker setup and store.
 */

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   s0, 0x10000000

    la   t0, mtvec_handler
    csrw mtvec, t0

    li   t0, 0x12345678
    csrrw t1, mscratch, t0
    sw   t1, 0(s0)

    li   t0, 0x0000000f
    csrrs t1, mscratch, t0
    sw   t1, 4(s0)

    li   t0, 0x00000008
    csrrc t1, mscratch, t0
    sw   t1, 8(s0)

    nop
    nop
    csrr t1, mscratch
    sw   t1, 12(s0)

    csrr t1, 0x7c0              /* unknown/custom CSR returns zero in lab08e */
    sw   t1, 16(s0)

    csrr t1, cycle
    sw   t1, 20(s0)

    csrr t1, instret
    sw   t1, 24(s0)

    li   t0, (1 << 11)
    csrs mie, t0                /* Enable MEIE but keep mstatus.MIE cleared. */

.global pending_irq_target
pending_irq_target:
.option push
.option rvc
    c.nop                       /* TB injects external IRQ pulse here. */
.option pop

    csrr t1, mip
    sw   t1, 28(s0)             /* Pending should be visible before global MIE. */

    li   t0, (1 << 3)
    csrs mstatus, t0            /* Pending IRQ may now be taken at commit boundary. */

after_irq:
    addi s1, zero, 0x60d
    sw   s1, 44(s0)

done:
    j    done

.option push
.option rvc
    c.nop                       /* pad so mtvec handler starts on a 4-byte boundary */
.option pop

.option push
.option norvc
.global mtvec_handler
mtvec_handler:
    csrr t1, mepc
    sw   t1, 32(s0)
    csrr t1, mcause
    sw   t1, 36(s0)
    csrr t1, mstatus
    sw   t1, 40(s0)
    mret
.option pop
