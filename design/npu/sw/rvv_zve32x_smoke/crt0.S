// Bare-metal HTIF crt0 for the Spike ISS golden.
// Enables the vector unit (mstatus.VS), runs npu_main, returns its result as the
// HTIF exit code so the gate can assert it deterministically.
.section .text._start,"ax",@progbits
.globl _start
_start:
    lui  sp, 0x80020            // stack top
    li   t0, (0x1<<9)          // mstatus.VS = 01 (Initial): enable RVV, else vsetvli traps illegal
    csrs mstatus, t0
    call npu_main
    slli a0, a0, 1             // HTIF exit protocol: tohost = (exit_code<<1)|1
    ori  a0, a0, 1
    la   t0, tohost
    sw   a0, 0(t0)
    sw   zero, 4(t0)
1:  j 1b

.section .tohost,"aw",@progbits
.globl tohost
tohost:   .dword 0
.globl fromhost
fromhost: .dword 0
