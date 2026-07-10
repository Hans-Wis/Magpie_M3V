#include "../include/command_descriptor.h"

#ifndef N_TILES
#define N_TILES 8u
#endif
/* ML_JOB_CFG value: bit0=legacy_bypass, bit1=B1 activation-stationary (ADR-0067 Phase B) */
#ifndef ML_CFG
#define ML_CFG 0u
#endif

#define CSR_ML_NTILES 0x84u
#define CSR_ML_GO     0x88u
#define CSR_ML_CFG    0x8Cu
#define CSR_ML_STATUS 0x90u
#define CSR_ML_MODE   0x94u
#define CSR_ML_W_BASE 0x98u
#define CSR_ML_SBYTES 0x9Cu
#define CSR_ML_NSTRIP 0xA0u
#define CSR_ML_KCHUNK 0xA4u
#define CSR_ML_NTAIL  0xA8u

#define ML_STATUS_DONE 0x2u

#ifdef STRIP_EN
#ifndef W_BASE
#error "STRIP_EN requires -DW_BASE=<byte address>"
#endif
#ifndef STRIP_BYTES
#error "STRIP_EN requires -DSTRIP_BYTES=<bytes>"
#endif
#ifndef N_STRIPS
#error "STRIP_EN requires -DN_STRIPS=<count>"
#endif
#ifndef K_CHUNKS
#error "STRIP_EN requires -DK_CHUNKS=<count>"
#endif
#ifndef K_TAIL
#error "STRIP_EN requires -DK_TAIL=<1..64>"
#endif
#ifndef N_TAIL
#error "STRIP_EN requires -DN_TAIL=<1..64>"
#endif
#endif

static volatile uint32_t *const csr = (volatile uint32_t *)CQ_CORE_WINDOW_BASE;
static volatile uint32_t *const mailbox = (volatile uint32_t *)CQ_MAILBOX_BASE;

__attribute__((naked, section(".init"))) void _start(void)
{
    __asm__ volatile (
        "li   sp, 0x8000\n"
        "call main\n"
        "1: j 1b\n"
    );
}

static __attribute__((noinline)) uint32_t csr_read(uint32_t off)
{
    return csr[off >> 2];
}

static __attribute__((noinline)) void csr_write(uint32_t off, uint32_t value)
{
    csr[off >> 2] = value;
}

int main(void)
{
    csr_write(CSR_ML_CFG, (uint32_t)ML_CFG);
#ifdef STRIP_EN
    csr_write(CSR_ML_NTILES, 0u);
    csr_write(CSR_ML_MODE, 1u);
    csr_write(CSR_ML_W_BASE, (uint32_t)W_BASE);
    csr_write(CSR_ML_SBYTES, (uint32_t)STRIP_BYTES);
    csr_write(CSR_ML_NSTRIP, (uint32_t)N_STRIPS);
    csr_write(CSR_ML_KCHUNK, ((uint32_t)K_TAIL << 8) | (uint32_t)K_CHUNKS);
    csr_write(CSR_ML_NTAIL, (uint32_t)N_TAIL);
#else
    csr_write(CSR_ML_NTILES, (uint32_t)N_TILES);
#endif
    csr_write(CSR_ML_GO, 1u);

    while ((csr_read(CSR_ML_STATUS) & ML_STATUS_DONE) == 0u)
        ;

    mailbox[0] = 1u;
    for (;;)
        ;
}
