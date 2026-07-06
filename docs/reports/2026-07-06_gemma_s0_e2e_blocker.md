# Gemma S0 GeGLU RTL e2e — implementation status + firmware TCM blocker

Date: 2026-07-06 · F1.5. Design + golden verified; e2e blocked on a firmware-size collision.

## What's done + verified
- **Completeness review** (Grok+Codex) + **Tier-C golden fix** (srdhm now bit-exact to
  mat_engine, 0-byte diff) — committed `57947e7`.
- **CQ contract** for the two nonlinear ops (MAT_ACT_LUT / MAT_EWISE_MUL), gate_35 byte-identical
  — committed `a856c04`.
- **Firmware handlers** (Codex, surgical): both `case`s + `seq_srdhm`/`seq_rdbpot` (bit-exact to
  mat_golden, verified int64 ops inline — no libgcc). Code is correct; preserved verbatim in the
  scratchpad + summarized below.
- **Runtime** (`sim/models/gemma_runtime.py`): S0 lowered as a host-chained 5-step pipeline —
  gate GEMM → gelu(MAT_ACT_LUT) → up GEMM → prod(MAT_EWISE_MUL) → down GEMM. GEMMs reuse the
  proven mat_engine FC path; nonlinear on the NPU sequencer. Standalone-validated (CQ generates,
  TCM in-bounds, requant params = the golden's).
- **Gate** (`sim/gates/gate_gemma3_s0_geglu.py`): geometry/contract test PASSES; the e2e test is
  RTL-chained (each step consumes the previous step's actual RTL output) with hex-exact
  checkpoints at gate/gelu/up/prod/out. Currently `@pytest.mark.skip` (blocker below).
- **TB**: `wait_bit` poll guard 6000→200000 (large multi-tile GEMMs; the 8ms watchdog still caps
  a hang) — kept, safe for all gates.

## The blocker (root-caused)
The sequencer firmware links `.text/.rodata/.data/.bss` into ONE 4K TCM region (sequencer.lds,
`LENGTH = 4K`), sequentially from 0. The CQ **data** regions are hardcoded byte offsets in the
SAME memory: `TCM_WEIGHT_B = 0x700` (weight-DMA target), `TCM_SCRATCH_B = 0xF00` (descriptor
prefetch). The comment history (`0x400→0x600→0x680→0x700, batched-prefetch code growth`) shows
the weight region has been walked up as code grew — it was at the edge.

Adding the two handlers + int64 `seq_srdhm`/`seq_rdbpot` grows `.text` to **0x840** and `.bss`
(the latched `cfg_m/cfg_n/cfg_k/…`, `acc_mask_latch`) to **0x840–0x854** — now INSIDE the weight
region. When the sequencer DMAs a GEMM weight blob to 0x700 (blobs are ~0x640 B, reaching
~0xD40), it **overwrites its own `.bss` state** → corrupt CFG → mat_engine gets garbage → hang
(no CQ error). This breaks **every** GEMM (confirmed: gate_50 hangs with the rebuilt firmware),
not just gemma. Original firmware was ~0x6D0 — just under 0x700.

## Fix options (next step, tractable)
`MAT_OUT` uses a CSR-set `out_base` (mat_engine.v) and the weight/scratch regions are firmware
constants, so the TCM layout is fully relocatable. The 4K linker region uses only ~1/8 of the
32KB DTCM.
1. **Relocate the CQ data regions past the code** (recommended): raise the linker `LENGTH` and
   move `TCM_WEIGHT_B`/`TCM_SCRATCH_B` above the code+bss (e.g. weight 0x1000, scratch 0x1E00),
   and update `tflm_runtime` `TCM_BLOB_B`/`MAT_OUT_B`/`A_OFF` + `gemma_runtime.TCM_IN`
   consistently. Blast radius: re-verify all tflm gates (48/49/50/82/94/95). No RTL change.
2. **Shrink the firmware** under 0x700: hand-code `seq_srdhm` with `mulh`/`mul` (avoid the int64
   codegen) to reclaim ~0x140 B. Smaller blast radius, fiddlier fixed-point.

## Preserved handler code (Codex, correct — re-apply after the layout fix)
```c
static int32_t seq_srdhm(int32_t a, int32_t b) {
    if (a == (int32_t)0x80000000 && b == (int32_t)0x80000000) return 0x7FFFFFFF;
    int64_t ab = (int64_t)a * (int64_t)b;
    int64_t nudge = (ab >= 0) ? (1 << 30) : (1 - (1 << 30));
    int64_t s = ab + nudge;
    return (int32_t)(s / (int64_t)((int64_t)1 << 31));   /* trunc toward zero == mat_engine */
}
static int32_t seq_rdbpot(int32_t x, int32_t exp) {
    if (exp <= 0) return x;
    int32_t mask = (int32_t)((1u << exp) - 1u);
    int32_t rem  = x & mask;
    int32_t thr  = (mask >> 1) + ((x < 0) ? 1 : 0);
    return (x >> exp) + ((rem > thr) ? 1 : 0);
}
/* case CQ_OP_MAT_ACT_LUT:  len=cq_w0_rpt(w0); dst[i]=lut[(uint8)((int32)src[i]+128)]  */
/* case CQ_OP_MAT_EWISE_MUL: q=seq_rdbpot(seq_srdhm(a[i]*b[i], w1), shift-31); clamp -128..127 */
```
Both with `< TCM_SCRATCH_B` bound checks → `cq_halt(CQ_ERR_MAT_PARAM)`.
