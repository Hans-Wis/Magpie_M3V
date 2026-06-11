/* Magpie_M1 bare-metal CoreMark port — timing/portable layer.
 * rdcycle (CSR 0xC00) is the tick source; M1 implements cycle/instret (Zicntr).
 * Also reports instret so CPI falls out directly. */
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

static inline ee_u32 rdcycle(void)
{
    ee_u32 v;
    __asm__ volatile("csrr %0, cycle" : "=r"(v));
    return v;
}

static inline ee_u32 rdinstret(void)
{
    ee_u32 v;
    __asm__ volatile("csrr %0, instret" : "=r"(v));
    return v;
}

#define EE_TICKS_PER_SEC 1000000 /* nominal; real score computed offline from raw ticks */

static CORE_TICKS start_cycle, stop_cycle;
static ee_u32 start_instr, stop_instr;

void start_time(void)
{
    start_instr = rdinstret();
    start_cycle = rdcycle();
}

void stop_time(void)
{
    stop_cycle = rdcycle();
    stop_instr = rdinstret();
}

CORE_TICKS get_time(void)
{
    return stop_cycle - start_cycle;
}

secs_ret time_in_secs(CORE_TICKS ticks)
{
    return ticks / EE_TICKS_PER_SEC; /* integer; offline math uses raw ticks below */
}

void portable_init(core_portable *p, int *argc, char *argv[])
{
    (void)argc;
    (void)argv;
    if (sizeof(ee_ptr_int) != sizeof(ee_u8 *))
        ee_printf("ERROR! Please define ee_ptr_int to a type that holds a pointer!\n");
    if (sizeof(ee_u32) != 4)
        ee_printf("ERROR! Please define ee_u32 to a 32b unsigned type!\n");
    p->portable_id = 1;
}

void portable_fini(core_portable *p)
{
    /* Raw evidence for offline CoreMark/MHz + CPI computation. */
    ee_printf("M1_BENCH: cycles=%u instret=%u\n",
              (unsigned)(stop_cycle - start_cycle),
              (unsigned)(stop_instr - start_instr));
    p->portable_id = 0;
}

/* -nostdlib: gcc may emit calls to these for struct copies / array init. */
void *memcpy(void *dst, const void *src, ee_size_t n)
{
    ee_u8 *d = (ee_u8 *)dst;
    const ee_u8 *s = (const ee_u8 *)src;
    while (n--) *d++ = *s++;
    return dst;
}

void *memset(void *dst, int c, ee_size_t n)
{
    ee_u8 *d = (ee_u8 *)dst;
    while (n--) *d++ = (ee_u8)c;
    return dst;
}
