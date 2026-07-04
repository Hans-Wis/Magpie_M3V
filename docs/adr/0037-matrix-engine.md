# ADR-0037 — P0③ matrix engine v0.1: 64-MAC outer product + TFLite-exact requant

- Status: **ACCEPTED** (per-phase architecture confirmation, CLAUDE.md §2; User directive
  2026-07-04 "下一步:P0③ 矩陣"). Mode: PL design (Fable) with **Grok as critic** (contract
  critique adopted below) + **Gemini** (TFLite requant reference dossier + Coral matrix
  shape; run via the background+polling pattern). Codex = post-implementation reviewer.
- Date: 2026-07-04
- Relates: ADR-0035 (CQ transport — the descriptors this engine serves), v4 **§06 Command
  編碼 Spec v0.1 = SSOT**, ADR-0031 (64→256 MAC roadmap). Verification authority =
  **bit-accurate NumPy golden** (`IP/npu/golden/mat_golden.py`) — matrix is not ISA; Spike
  is not involved (CLAUDE.md §3 row 3).

## Decision — engine contract (v0.1 freeze)

**Datapath**: `mat_engine.v` — 8×8 = 64 int8 MACs, one outer product per MAC cycle
(`acc[r][c] += sext8(a[r])*sext8(b[c])`, int32 wrapping). **ACC = 4 banks × 8×8×32b**
(v4 left "16 tentative"; 4 frozen here — recorded deviation; `W0.ACC >= 4` → MAT_PARAM).
Commands via the sequencer CSR mirror (GO pulse; engine locks busy for a whole command;
done/err sticky until next accepted GO; **done ⇒ outputs visible in TCM** — the final
rescale write commits one cycle before done, a rule caught by gate_45):
- `CLR`: bank mask zeroing (single cycle).
- `OP`: RPT serialized outer products; per rep a/b pointers advance **+8 bytes** (frozen
  contiguous stripmine); 4 TCM word reads + 1 MAC cycle per rep. a/b are **TCM-local,
  4-byte-aligned** byte addresses. `rpt==0`, `bank>=4`, misalignment → MAT_PARAM.
- `RESCALE`: **exact TFLite/gemmlowp two-step** on one bank →
  `SaturatingRoundingDoublingHighMul(acc, mult_q31)` then `RoundingDivideByPOT(shift-31)`
  then `+zp`, clamp [min,max]; 64 int8 outputs packed to 16 TCM words at `out_base`.
  `shift ∈ [31,62]` (right-shift-only v0.1; the v4 worked example shift=38 → exp=7).

**Requant semantics (the核心 freeze, per Grok+Gemini both rejecting the collapsed
single-step)**: the v4 §06 comment formula (single rounding on the 64-bit product) is NOT
TFLite-equivalent — it differs on double-rounding boundaries, negative halves, and the
INT32_MIN×INT32_MIN saturation edge. Since the mission is TFLM parity (§0), the golden and
RTL implement gemmlowp **bit-exactly**, including its measured quirks (SRDHM negative
halves land TOWARD zero via the `1-2^30` nudge + truncating division; an exact +0.25 can
double-round to 1). `mat_golden.py --selftest` pins these truths; the v4 §06 text is
superseded on this point (SSOT delta recorded).

**Grok critique adopted**: K = 8×RPT binding (CFG latches M/N/K; OP with `RPT != K/8` →
MAT_PARAM — enforced in firmware in 4B); **W3 must be 0** (tile coords reserved for the
16-bank v0.2 — silently-ignored coords were called out as the worst v0.1 bug);
ACC persists across OPs until CLR; FENCE-after-LOAD_W is the documented SW contract; the
`ENGINE_NOT_READY` ERR for OP/RESCALE retires in 4B and `gate_38`'s case flips to a
MAT_PARAM probe (recorded gate transition); DMA∥engine overlap = deferred scoreboard
(time-division documented: no OP while DMA streams into the a/b region).

**TCM**: two new engine ports (combinational read, granted write) — priority
`dma > engine > core > host`. ASIC banking note stays P1.

## Staging + gates

| stage | scope | gate |
|---|---|---|
| 4A | engine unit-level vs golden | `gate_45`: 90 rescale corners (incl. INT32_MIN saturation, clamp/zp extremes, v4 worked example) + 24 random CLR→OP(rpt)→RESCALE sequences, all 64 bytes each + param-error probes — **DONE: 1629 checks, 0 errors** |
| 4B | npu_top integration: mirror MAT_* CSRs, firmware CQ dispatch (CFG/ACC_CLR/OP/RESCALE execute; MAT_PARAM=0x07 into the SSOT), MAT.STORE W2 = src_tcm_byte (0 = legacy weight base, backward compatible) | `gate_46`: CQ ring → CFG/ACC_CLR/OP/RESCALE/STORE(LAST) → shared memory == golden bytes; MAT_PARAM ERR path; gates 35–44 regression |

## 4A result (2026-07-04)

`mat_engine.v` + `mat_golden.py` + `phase_23_mat_engine` unit TB green: **1629 checks, 0
errors** (90 corners × 5 param sets incl. negative-multiplier and saturation edges; 24
sequences bit-exact across all 64 outputs; bank/shift/rpt/alignment param errors flagged).
Two bugs caught by the loop: done-before-final-write (S_FIN state added — "done means
visible"), and a golden emit formatting bug (negative multiplier as `-80000000` silently
truncated part 1 to 5 cases — the case-count print is now part of the gate's assertions).

## 4B result (2026-07-04) — P0③ COMPLETE

**gate_46 green**: the full Coral-shaped matrix offload — host loads int8 a/b into the TCM,
writes a 5-descriptor ring (CFG → ACC_CLR → OP(K=8×RPT binding) → RESCALE(v4 worked-example
params) → STORE(W2=MAT_OUT, IRQ|LAST)); the sequencer firmware drives the engine; the
requantized 8×8 tile lands in shared memory **byte-exact vs mat_golden.py**. MAT_PARAM ERR
paths verified (W3≠0, DTYPE≠i8). Gates 35–39 re-green with the engine integrated
(gate_36/38's ENGINE_NOT_READY probe flipped to MAT_PARAM as planned); full suite = 0 new
failures.

**Integration deviations found during 4B:** the sequencer text outgrew the 0x400 weight
region (LOAD_W DMA overwrote firmware — caught by the smoke gates) → weight region moved to
**0x600** (SSOT + TBs updated).

**Codex 4B review — 3 findings, all real, all fixed:** (1) the SSOT codec still encoded
MAT_STORE.W2 as `stride` (a Python-built descriptor would silently take the legacy path) —
schema fields renamed + regenerated; (2) TCM addresses could silently alias/wrap (a_addr
beyond 4KB read word 0) — firmware bound-checks a/b/W2 against the TCM (→ MAT_PARAM);
(3) DTYPE was accepted unchecked (i16/bf16 would run as int8 with wrong numbers) —
DTYPE≠i8 → MAT_PARAM for OP/RESCALE.

**Recorded deferrals:** 256-MAC scale-up (64 today), 16 ACC banks (4), MAT.CFG tile_flags
semantics, DMA∥engine overlap scoreboard (time-division SW contract documented),
weight-stationary LOAD_W-into-array (weights stream from TCM per rep).
