#include "coremark.h"
#include "core_portme.h"

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

ee_u32 default_num_contexts = 1;

#define M1_MMIO_RESULT_BASE ((volatile ee_u32 *)0x10000000u)

static CORETIMETYPE start_time_val;
static CORETIMETYPE stop_time_val;
static ee_u32 start_instret_val;
static ee_u32 stop_instret_val;

static inline ee_u32 read_mcycle_lo(void)
{
    register ee_u32 v asm("a0");
    __asm__ volatile (".word 0xc0002573" : "=r"(v));
    return v;
}

static inline ee_u32 read_minstret_lo(void)
{
    register ee_u32 v asm("a0");
    __asm__ volatile (".word 0xc0202573" : "=r"(v));
    return v;
}

CORETIMETYPE barebones_clock(void)
{
    return read_mcycle_lo();
}

void start_time(void)
{
    M1_MMIO_RESULT_BASE[6] = 0x53544152u;
    start_instret_val = read_minstret_lo();
    start_time_val = barebones_clock();
}

void stop_time(void)
{
    stop_time_val = barebones_clock();
    stop_instret_val = read_minstret_lo();
    M1_MMIO_RESULT_BASE[0] = (ee_u32)seed4_volatile;
    M1_MMIO_RESULT_BASE[1] = (ee_u32)(stop_time_val - start_time_val);
    M1_MMIO_RESULT_BASE[2] = (ee_u32)(stop_instret_val - start_instret_val);
    M1_MMIO_RESULT_BASE[3] = start_time_val;
    M1_MMIO_RESULT_BASE[4] = stop_time_val;
    M1_MMIO_RESULT_BASE[7] = 0x53544f50u;
}

CORE_TICKS get_time(void)
{
    return (CORE_TICKS)(stop_time_val - start_time_val);
}

secs_ret time_in_secs(CORE_TICKS ticks)
{
    return ticks / 1000000u;
}

void portable_init(core_portable *p, int *argc, char *argv[])
{
    (void)argc;
    (void)argv;
    p->portable_id = 1;
}

void portable_fini(core_portable *p)
{
    p->portable_id = 0;
    M1_MMIO_RESULT_BASE[5] = 0x434d444eu;
}

void uart_send_char(char c)
{
    volatile ee_u32 *uart = (volatile ee_u32 *)0x10000020u;
    *uart = (ee_u8)c;
}
