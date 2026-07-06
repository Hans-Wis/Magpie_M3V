# ADR-0039 — Phase 6: TFLM int8 FullyConnected end-to-end on the NPU

- Status: **ACCEPTED** (per-phase architecture confirmation, CLAUDE.md §2; User directive
  2026-07-04 "(a) Phase 6 TFLM e2e"). Mode: PL design, **Grok pre-critique** (adoptions
  below) + **Codex post-review** (1 High finding, fixed + DV'd).
- Date: 2026-07-04
- Relates: ADR-0035 (CQ SSOT), ADR-0037 (matrix engine + frozen gemmlowp requant).

## Coral mapping

Coral/Kelvin's software row is TF→MLIR→IREE (closed). Our replaceability route
(§0/ADR-0031) is the open-source TFLM path: the same op semantics
(`reference_integer_ops::FullyConnected`, per-tensor int8) must produce **bit-exact**
results through OUR offload contract. This phase proves the first real TFLM op runs the
full Coral-shaped loop — ring descriptors in shared memory → doorbell → sequencer →
weight/activation DMA → compute → requant → result writeback → IRQ — with nothing
host-side except the SSOT encoder.

## Decision — lowering contract

1. **Batch-8 GEMV on the outer-product engine.** Rep k computes
   `acc[r][c] += a_k[r]·b_k[c]` with `a_k[r] = input[r][k]`, `b_k[c] = filter[c][k]`;
   RPT = FC depth `k_dim` (one outer product per rep; **CFG.K counts a-bytes = 8·k_dim** —
   descriptor-semantics clarification of ADR-0037). Full 64-MAC utilization.
2. **Affine fold → accumulator preload.** TFLM adds `input_offset` (= −zero_point,
   TFLM sign convention) per element and `bias` at the end. We precompute
   `fold32[c] = wrap32(bias[c] + input_offset·Σ_k filter[c][k])` and preload it into
   **every accumulator row**: new engine command **CMD_LOADACC** (8 int32 words read from
   TCM, broadcast down rows), exposed as **MAT.ACC_CLR W2 = bias_tcm_byte** (0 = plain
   clear). Exactness: int32 accumulation is a mod-2³² two's-complement **ring** — wrapping
   add is associative/commutative and multiply distributes — so the fold grouping is
   bit-identical to TFLM's per-k order (and for K ≤ 64 the pre-bias sum can't wrap at
   all: |Σ| ≤ 64·255·128 ≈ 2.1M). Grok's "fold diverges under wrap" concern is refuted by
   ring algebra, but his DV demand (deliberate-wrap corner) is adopted and green.
3. **Requant = already-frozen path.** Engine RESCALE (gemmlowp SRDHM +
   RoundingDivideByPOT) **is** TFLM `MultiplyByQuantizedMultiplier`; out_zp added
   post-scale, clamp = fused activation range. Nothing new to freeze.
4. **SSOT discipline (Grok adoption).** `bias_tcm_byte` added to the schema + generated
   codec (encode/decode round-trip); the compiler emits descriptors **only** through
   `cq_codec`; gate_48 asserts the round-trip and the W2≠0 ⇒ LOADACC binding.
5. **Scope (explicit gate assumptions):** per-tensor quant (per-channel deferred),
   `filter_offset == 0` (TFLite int8 filters mandate zp 0 — the compiler **raises**, no
   silent wrong answer), batch = 8, outputs = 8 (pad upstream), K ∈ {8..64} multiple
   of 8, single tile. TFLM *runtime* port is future work — this phase locks the op
   semantics + lowering contract the runtime will target.

## Verification (gate_48 — authority: independent per-k TFLM reference, NumPy-free)

`design/npu/golden/tflm_fc.py` holds two independent halves: `fc_reference()` (faithful
per-k int32-wrap TFLM kernel) and `compile_fc()` (fold + packing + SSOT descriptors).
Six corner cases run the FULL loop on real RTL (LOAD_W DMA of a single blob:
fold + a + b; LOADACC; k_dim reps; RESCALE; STORE writeback; IRQ|LAST), each compared
**bit-exact** in shared memory: input_zp {−128, 1, 13, 55, 100, −77}, out_zp {127, −10,
0, 5, −1, 3}, **deliberate int32 wrap** through huge bias, **doubling-high multiplier
boundary** (mult 0x7FFFFFFF, shift 31), **fused-ReLU clamp** [0,127], **bias-only /
zero-weights** (pure LOADACC), K ∈ {8,16,32,64}. Guards: corner-count assert,
filter_offset rejection test, codec round-trip test.

**Found during bring-up:** RPT semantics (compiler first emitted RPT = k_dim/8 —
partial sums; clamp rails masked the magnitude until a rail-free debug case exposed it).
**Codex High finding (fixed + DV):** the firmware descriptor sanitizers formed
`base + len` in uint32 — an aligned `w2 = 0xFFFF_FFE4` wrapped past the bounds check and
aliased the TCM. All three sites (ACC_CLR bias, OP a/b, STORE src) rewritten wrap-safe
(`base > limit − len`); tb_npu_cq_ring_err gained a wrap-bypass scenario that fails on
the old firmware.

## Result

**§3 row 7 (軟體) upgrades to PARTIAL-strong:** open-source encoder path + first TFLM op
bit-exact e2e. Remaining for green: TFLM runtime integration (op resolver → CQ encoder
online) and multi-op/multi-tile models (Phase 6 continuation), 64→256 MAC scale-up for
row 3.
