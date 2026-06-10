// =============================================================================
// firmware.c — Lab05 LED counter with BTN1 IRQ
// -----------------------------------------------------------------------------
// Demo：
//   * main 持續 LED ← n、n++、delay loop
//   * 按 BTN1 觸發 M-mode external interrupt → ISR 把 n 設回 0
//   * mret 返回後 main 從 LED=0 重新計數
//
// 用到的 RISC-V CSR：
//   mtvec    : trap vector base address
//   mie      : interrupt-enable mask (bit 11 = MEIE)
//   mstatus  : global interrupt enable (bit 3 = MIE)
//
// `__attribute__((interrupt("machine")))` 告訴 gcc：
//   * 進 ISR 自動 push 所有用到的 caller-saved register
//   * 出 ISR 自動換成 mret (不是 ret)
//   * 不需要手寫 mscratch context switch
// =============================================================================

#define LED (*(volatile unsigned int *)0x10000000)

#ifndef DELAY_ITER
#define DELAY_ITER 2000000U
#endif

volatile unsigned int n = 0;

__attribute__((interrupt("machine")))
void mtvec_handler(void) {
    n = 0;
}

void main(void)
{
    /* 1. mtvec ← ISR address (direct mode, MODE=00) */
    asm volatile("csrw mtvec, %0" :: "r"((unsigned long)&mtvec_handler));

    /* 2. 開 machine external interrupt enable (mie.MEIE = bit 11) */
    asm volatile("csrs mie, %0" :: "r"((unsigned long)(1u << 11)));

    /* 3. 開 global interrupt enable (mstatus.MIE = bit 3) */
    asm volatile("csrs mstatus, %0" :: "r"((unsigned long)(1u << 3)));

    /* 4. LED counter loop — n 是 volatile，ISR 可以從 main 之外改它 */
    while (1) {
        LED = n;
        n++;
        for (volatile unsigned int i = 0; i < DELAY_ITER; i++)
            ;
    }
}
