.equ RAM_BASE,          0x20000000
.equ STACK_TOP,         0x20004000
.equ RESULT_BASE,       0x20001000
.equ UART_THR,          0x10000000
.equ PLIC_PRIORITY1,    0x0c000004
.equ PLIC_ENABLE,       0x0c002000
.equ PLIC_THRESHOLD,    0x0c200000
.equ PLIC_CLAIM,        0x0c200004
.equ MCAUSE_EXT_IRQ,    0x8000000b

.section .init
.global _start

_start:
    li   sp, STACK_TOP

    la   t0, irq_scratch
    csrw mscratch, t0

    la   t0, mtvec_handler
    csrw mtvec, t0

    /* Enable PLIC source ID 1 at priority 1, threshold 0. */
    li   t0, PLIC_PRIORITY1
    li   t1, 1
    sw   t1, 0(t0)
    li   t0, PLIC_ENABLE
    sw   t1, 0(t0)
    li   t0, PLIC_THRESHOLD
    sw   zero, 0(t0)

    li   t0, (1 << 11)
    csrs mie, t0
    li   t0, (1 << 3)
    csrs mstatus, t0

    /* a) PLIC directed interrupt. */
    la   t0, phase
    li   t1, 1
    sw   t1, 0(t0)
    li   t0, RESULT_BASE
    li   t1, 0x11110001
    sw   t1, 0(t0)
plic_wait:
    la   t0, phase
    lw   t1, 0(t0)
    bnez t1, plic_wait
    li   t0, RESULT_BASE
    li   t1, 0x0000a001
    sw   t1, 0x10(t0)

    /* b) UART byte stream. */
    la   t0, uart_msg
uart_loop:
    lbu  t1, 0(t0)
    beqz t1, uart_done
    li   t2, UART_THR
    sb   t1, 0(t2)
    addi t0, t0, 1
    j    uart_loop
uart_done:
    li   t0, RESULT_BASE
    li   t1, 0x0000a002
    sw   t1, 0x20(t0)

    /* c) Full subsystem smoke: after UART, take another PLIC interrupt. */
    la   t0, phase
    li   t1, 3
    sw   t1, 0(t0)
    li   t0, RESULT_BASE
    li   t1, 0x11110003
    sw   t1, 0(t0)
smoke_wait:
    la   t0, phase
    lw   t1, 0(t0)
    bnez t1, smoke_wait
    li   t0, RESULT_BASE
    li   t1, 0x0000a003
    sw   t1, 0x30(t0)
done:
    j done

    .balign 4
mtvec_handler:
    csrrw t6, mscratch, t6
    sw   t0, 0(t6)
    sw   t1, 4(t6)
    sw   t2, 8(t6)
    sw   t3, 12(t6)
    sw   t4, 16(t6)
    sw   t5, 20(t6)
    csrr t0, mscratch
    sw   t0, 24(t6)

    csrr t0, mcause
    csrr t1, mepc
    la   t2, phase
    lw   t3, 0(t2)

    li   t4, 1
    beq  t3, t4, handle_plic_first
    li   t4, 3
    beq  t3, t4, handle_plic_smoke

handler_unknown:
    li   t5, RESULT_BASE
    sw   t0, 0x34(t5)
    j    handler_finish

handle_plic_first:
    li   t5, PLIC_CLAIM
    lw   t4, 0(t5)
    li   t5, RESULT_BASE
    sw   t0, 0x04(t5)
    sw   t1, 0x08(t5)
    sw   t4, 0x0c(t5)
    li   t5, PLIC_CLAIM
    sw   t4, 0(t5)
    j    handler_finish

handle_plic_smoke:
    li   t5, PLIC_CLAIM
    lw   t4, 0(t5)
    li   t5, RESULT_BASE
    sw   t0, 0x24(t5)
    sw   t1, 0x28(t5)
    sw   t4, 0x2c(t5)
    li   t5, PLIC_CLAIM
    sw   t4, 0(t5)

handler_finish:
    sw   zero, 0(t2)
    lw   t0, 0(t6)
    lw   t1, 4(t6)
    lw   t2, 8(t6)
    lw   t3, 12(t6)
    lw   t4, 16(t6)
    lw   t5, 20(t6)
    csrw mscratch, t6
    lw   t6, 24(t6)
    mret

    .balign 4
phase:
    .word 0
uart_msg:
    .ascii "MAGPIE PLIC UART"
    .byte 10, 0
    .balign 4
irq_scratch:
    .space 28
