/* GENERATED from command_descriptor_v0_1.yaml - DO NOT EDIT */
#ifndef MAGPIE_NPU_COMMAND_DESCRIPTOR_H
#define MAGPIE_NPU_COMMAND_DESCRIPTOR_H

#include <stdint.h>

typedef struct { uint32_t w0, w1, w2, w3; } cq_desc_t;

typedef enum {
    CQ_OP_MAT_CFG = 0x01,
    CQ_OP_MAT_LOAD_W = 0x02,
    CQ_OP_MAT_OP = 0x03,
    CQ_OP_MAT_RESCALE = 0x04,
    CQ_OP_MAT_STORE = 0x05,
    CQ_OP_MAT_ACC_CLR = 0x06,
    CQ_OP_MAT_FENCE = 0x07,
} cq_opcode_t;

typedef enum {
    CQ_ERR_BAD_OPCODE = 0x01,
    CQ_ERR_RSVD_VIOLATION = 0x02,
    CQ_ERR_RING_OVERRUN = 0x03,
    CQ_ERR_ENGINE_NOT_READY = 0x04,
    CQ_ERR_DMA_FAULT = 0x05,
    CQ_ERR_DESC_ALIGN = 0x06,
    CQ_ERR_MAT_PARAM = 0x07,
    CQ_ERR_ABORTED = 0x08,
    CQ_ERR_CORE_TRAP_FLAG = 0x80000000,
} cq_err_cause_t;

#define CQ_W0_OPCODE_MASK 0x0000003Fu
#define CQ_W0_OPCODE_LSB 0u
#define CQ_W0_DTYPE_MASK 0x000000C0u
#define CQ_W0_DTYPE_LSB 6u
#define CQ_W0_ACC_MASK 0x00000F00u
#define CQ_W0_ACC_LSB 8u
#define CQ_W0_IRQ_MASK 0x00001000u
#define CQ_W0_IRQ_LSB 12u
#define CQ_W0_FENCE_MASK 0x00002000u
#define CQ_W0_FENCE_LSB 13u
#define CQ_W0_LAST_MASK 0x00004000u
#define CQ_W0_LAST_LSB 14u
#define CQ_W0_RPT_MASK 0x00FF0000u
#define CQ_W0_RPT_LSB 16u
#define CQ_W0_RSVD_MASK 0xFF008000u

static inline uint32_t cq_w0_get(uint32_t w0, uint32_t mask, uint32_t lsb)
{
    return (w0 & mask) >> lsb;
}

static inline uint32_t cq_w0_set(uint32_t w0, uint32_t mask, uint32_t lsb, uint32_t value)
{
    return (w0 & ~mask) | ((value << lsb) & mask);
}

static inline uint32_t cq_w0_opcode(uint32_t w0) { return cq_w0_get(w0, CQ_W0_OPCODE_MASK, CQ_W0_OPCODE_LSB); }
static inline uint32_t cq_w0_dtype(uint32_t w0) { return cq_w0_get(w0, CQ_W0_DTYPE_MASK, CQ_W0_DTYPE_LSB); }
static inline uint32_t cq_w0_acc(uint32_t w0) { return cq_w0_get(w0, CQ_W0_ACC_MASK, CQ_W0_ACC_LSB); }
static inline uint32_t cq_w0_irq(uint32_t w0) { return cq_w0_get(w0, CQ_W0_IRQ_MASK, CQ_W0_IRQ_LSB); }
static inline uint32_t cq_w0_fence(uint32_t w0) { return cq_w0_get(w0, CQ_W0_FENCE_MASK, CQ_W0_FENCE_LSB); }
static inline uint32_t cq_w0_last(uint32_t w0) { return cq_w0_get(w0, CQ_W0_LAST_MASK, CQ_W0_LAST_LSB); }
static inline uint32_t cq_w0_rpt(uint32_t w0) { return cq_w0_get(w0, CQ_W0_RPT_MASK, CQ_W0_RPT_LSB); }

#define CQ_CORE_WINDOW_BASE 0x00020000u
#define CQ_MAILBOX_BASE 0x00010000u
#define CSR_CQ_RING_BASE 0x40u
#define CSR_CQ_RING_SIZE 0x44u
#define CSR_CQ_HEAD 0x48u
#define CSR_CQ_TAIL 0x4Cu
#define CSR_CQ_CTRL 0x50u
#define CSR_CQ_STATUS 0x54u
#define CSR_ERR_CAUSE 0x58u
#define CSR_CQ_EVENT 0x5Cu
#define CSR_MAT_A_ADDR 0x60u
#define CSR_MAT_B_ADDR 0x64u
#define CSR_MAT_CTRL 0x68u
#define CSR_MAT_MULT 0x6Cu
#define CSR_MAT_RSP 0x70u
#define CSR_MAT_CLAMP 0x74u
#define CSR_MAT_OUT_BASE 0x78u
#define CSR_MAT_STATUS 0x7Cu
#define CSR_ERR_PC 0x80u

#endif
