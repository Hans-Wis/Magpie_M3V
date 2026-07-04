/* ADR-0038 gate_47 — deterministic core-trap reporter. Executes an illegal
 * instruction at a KNOWN pc (0x14); the terminal handler reports
 * ERR_PC=0x14 / ERR_CAUSE=0x80000002 through the mirror, raising the ERR IRQ. */
.section .init
.global _start
_start:
    la   t0, th            /* 0x00: auipc+addi */
    csrw mtvec, t0         /* 0x08 */
    li   t1, 0x200         /* 0x0c */
    csrs mstatus, t1       /* 0x10 */
bad:
    .word 0xFFFFFFFF       /* 0x14: illegal -> trap */
1:  j 1b
    .balign 4
th:
    lui  t1, 0x20
    csrr t2, mepc
    sw   t2, 0x80(t1)      /* ERR_PC */
    csrr t0, mcause
    lui  t3, 0x80000
    or   t0, t0, t3
    sw   t0, 0x58(t1)      /* ERR_CAUSE = CORE_TRAP|mcause */
2:  j 2b
