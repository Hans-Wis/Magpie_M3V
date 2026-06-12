/* Magpie_M1 bare-metal CoreMark port (Phase 0 benchmark baseline, M1A evaluation).
 * Based on the EEMBC barebones template (coremark @ 1f483d5, Apache-style EEMBC license;
 * benchmark harness only — NOT shipped RTL/IP). Timing = rdcycle CSR (M1 implements
 * cycle/cycleh, Zicntr). Output = ee_printf -> MMIO putchar 0x10000000 (bench TB).
 * HAS_FLOAT=0: scores are computed offline from printed ticks/iterations. */
#ifndef CORE_PORTME_H
#define CORE_PORTME_H

#define HAS_FLOAT 0
#define HAS_TIME_H 0
#define USE_CLOCK 0
#define HAS_STDIO 0
#define HAS_PRINTF 0

#define COMPILER_VERSION "riscv64-unknown-elf-gcc 13.2.0 (riscv-tools 1.0.6)"
#ifndef COMPILER_FLAGS
#define COMPILER_FLAGS "see Makefile OPT/GCC_MARCH (passed via -DCOMPILER_FLAGS at build)"
#endif
#define FLAGS_STR COMPILER_FLAGS " (1-cycle imem/dmem bench TB)"
#define MEM_LOCATION "STACK"

typedef signed short   ee_s16;
typedef unsigned short ee_u16;
typedef signed int     ee_s32;
typedef double         ee_f32;
typedef unsigned char  ee_u8;
typedef unsigned int   ee_u32;
typedef ee_u32         ee_ptr_int;
typedef unsigned int   ee_size_t;
#define NULL ((void *)0)

#define align_mem(x) (void *)(4 + (((ee_ptr_int)(x)-1) & ~3))

typedef ee_u32 CORE_TICKS;

#define SEED_METHOD SEED_VOLATILE
#define MEM_METHOD MEM_STACK

#define MULTITHREAD 1
#define USE_PTHREAD 0
#define USE_FORK 0
#define USE_SOCKET 0

#define MAIN_HAS_NOARGC 1
#define MAIN_HAS_NORETURN 0

extern ee_u32 default_num_contexts;

typedef struct CORE_PORTABLE_S {
    ee_u8 portable_id;
} core_portable;

void portable_init(core_portable *p, int *argc, char *argv[]);
void portable_fini(core_portable *p);

#if !defined(PROFILE_RUN) && !defined(PERFORMANCE_RUN) && !defined(VALIDATION_RUN)
#if (TOTAL_DATA_SIZE == 1200)
#define PROFILE_RUN 1
#elif (TOTAL_DATA_SIZE == 2000)
#define PERFORMANCE_RUN 1
#else
#define VALIDATION_RUN 1
#endif
#endif

int ee_printf(const char *fmt, ...);

#endif /* CORE_PORTME_H */
