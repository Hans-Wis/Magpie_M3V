# ADR Draft: Matrix-Engine Micro-Architecture Optimization (Route A)

**Status:** Architecture confirmation for post-bring-up optimization  
**Scope:** `mat_engine.v` S_RUN / S_RSC pipelining; feeding path; no functional contract change  
**Authority:** `mat_golden.py` final acc/output bit-exact; throughput gate cycle-count baseline (allowed to move); Spike lockstep unchanged (scalar/vector only)

---

## 1. Critical path — cut S_RUN first

| Candidate | Structure | Throughput demand | Likely limiter |
|---|---|---|---|
| **S_RUN** | 2×256b TCM mux → 256×(int8×int8→int17) → 64×(4:1, 17→32b tree) → 64×(acc+psum) **same cycle** | 1 rep/cycle sustained | **Width × depth × routing.** 64 parallel trees + 64 acc adds + 512B read mux fanout. Loop-carried acc forbids retiming the final add without explicit bypass. |
| **S_RSC** | One 32×32→64b signed mult + sat-round-shift + clamp | **1 element/cycle** | Single deep multiplier (~6–8 useful logic levels). Narrow, no loop carry. |

**Judgment (ranked):**

1. **S_RUN mult+tree+accumulate is the npu_top Fmax suspect and the first cut.** Combinational 256-MAC + 64 trees + same-cycle acc update is the classic “wide + feedback” path that DC on `cpu_m1_top` cannot predict.
2. **S_RSC is second and conditional.** A lone 32×32 mult is deep but narrow; it only bounds layer time when REscale dominates (small K, many requant passes). It does **not** explain suspected `npu_top` Fmax during MAC-heavy TFLM layers.
3. **Do not cut S_RSC first** — requant is already 1/cycle; shaving it wins nothing while software still burns ~10 cycles/op on A/B/CTRL stores.

**First synthesis target:** `mat_engine` in isolation, then `npu_top` with registered TCM read boundaries explicitly modeled. Compare S_RUN vs S_RSC slacks per FSM state.

---

## 2. S_RUN pipelining — concrete, hazard-safe scheme

### 2.1 Pipeline placement (recommended: **3 stages + acc stage with bypass**)

```
Cycle →
  S0 RD   : reg {bank, rep, lane_en, tcm_addr_a/b}  → comb TCM read (existing 2×256b)
  S1 MUL  : reg t_a_rdata[255:0], t_b_rdata[255:0]  → 256× int8×int8 → int17 (masked)
  S2 TREE : reg prod[255:0] (packed 17b lanes)      → 64× 4:1 signed tree → psum[63:0] (32b)
  S3 ACC  : comb acc_in + psum → acc_next; reg acc[bank][*] at phase end
```

- **Registers:** between read→mult, mult→tree, tree→accumulate. **Do not** register inside the 4:1 trees (preserve today’s per-cell tree topology for bit-exact intermediate widening).
- **Accumulate:** keep **one** combinational 32b add at S3; register **only** the acc array write.

### 2.2 Loop-carried accumulate — forwarding, not bubbles

Consecutive reps of one `CMD_OP` hit the **same bank**; rep \(k\) needs rep \(k{-}1\)’s `acc_next`, not stale `acc_reg`.

Per `(bank, cell)` maintain:

- `acc_reg[bank][ci]` — architectural acc (unchanged semantics).
- `acc_fwd[bank][ci]` — **bypass register**: value produced by the **last completed S3** for that bank (valid bit `acc_fwd_v[bank]`).

**S3 acc_in mux (same bank, consecutive rep):**

```
acc_in[ci] = acc_fwd_v[bank] ? acc_fwd[bank][ci] : acc_reg[bank][ci]
acc_next[ci] = acc_in[ci] + psum[ci]   // lane_en mask at S1 only; disabled lanes contribute 0 psum
```

**End of S3:** `acc_reg[bank][ci] <= acc_next[ci]`; `acc_fwd[bank][ci] <= acc_next[ci]`; `acc_fwd_v[bank] <= 1`.

**Bank switch / ACC_CLR / new CMD_OP first rep:** clear `acc_fwd_v[new_bank]`; use `acc_reg` (post-clear or prior state). No RAW bubble if forwarding covers back-to-back same-bank reps.

**Drain:** on `CMD_OP` last rep or `FENCE`, stall new issues until `inflight[bank]==0` (3-entry shift counter per bank suffices for this depth).

### 2.3 Latency and bit-exact proof sketch

| Metric | Value |
|---|---|
| Pipeline fill (first rep → first acc write) | **4 cycles** (S0..S3) |
| Steady-state issue rate | **1 rep/cycle** (after fill) |
| Loop-carried penalty | **0** (bypass, not stall) |

**Bit-identical:** Forwarding is algebraically `acc[k] = acc[k-1] + psum[k]` with the same 32b two’s-complement add as today. `psum` computation and tree topology unchanged. `lane_en` still applied at S1. Rep order preserved by single-issue into S0. **Final acc values match `mat_golden.py`.**

**Throughput gate:** Expect fewer cycles **per rep** in steady state only after software batching (§4); pipeline fill adds +3 cycles **per CMD_OP chain start** — document new baseline; gate compares ratios, not absolute legacy counts.

### 2.4 Alternatives rejected

| Option | Why not |
|---|---|
| Full 4-stage incl. registered acc | Requires 1 bubble/rep on same-bank chains unless complex multi-entry bypass; worse IPC for zero Fmax gain if S3 add is shallow. |
| Partial-sum reassociation across reps | Violates per-rep accumulation order; no overflow headroom argument across the full dot-product chain. |
| Pipelined acc with interleaved banks only | Software already targets one bank per op; doesn’t solve the stated hazard. |

---

## 3. 128-bit port — keep 2×256b; defer Coral parity

**Recommendation: keep 2×256b combinational read ports; pipeline S_RUN; do not narrow to 128b in this phase.**

| Factor | 2×256b + pipeline | Drop to 128b (Coral parity) |
|---|---|---|
| MAC reps/cycle | 1 (after pipe fill) | ≥2 read cycles to feed 256 MACs → **≤0.5 rep/cycle** unless weight-stationary SRAM added |
| Critical path | Cut by staging mult/tree | Removes read mux width but **adds cycle count**; needs new buffering + descriptor/addr semantics |
| Recorded deviation | ADR-0040/0044 Class B — acceptable | Closure cost high, functional risk in CQ/CSR path |
| Synergy with Route A | Direct | Requires mini weight-stationary arch → not “pipeline internals” |

128b only pays off with **explicit weight-stationary micro-buffer** (load W over N cycles, stream A). That is a **feeding-protocol change**, not an optimization of the existing outer-product datapath. Revisit **post-signoff** for area/power, not Fmax.

---

## 4. Double-buffer vs descriptor batching

**Root cause:** ~10+ cycles/op from **software serialization** (single-issue core, ≥3 stores for A/B/CTRL per `MAT_OP`), not GO→MAC hardware latency.

| Rank | Measure | Mechanism | Expected win | Verification hook |
|---|---|---|---|---|
| **#1** | **Descriptor-level batching / autonomous MAT_OP** | Embed `{ptr_a, ptr_b, ctrl, reps, bank}` in CQ 128b descriptor (or shadow regs loaded once per layer). Sequencer issues reps **without per-op scalar stores.** CPU only doorbell + ring advance. | Cuts **~10 cycles/op → ~0–1** amortized; dominates wall-clock for short K. | `gate_35..39` CQ equivalence + `gate_48/49/50` TFLM e2e bit-exact |
| **#2** | **Operand double-buffer (TCM side)** | Ping-pong addr/regs at S0 while MAC drains pipe | Hides **1-cycle registered TCM latency** if reads are retimed; useless while CPU still blocks on stores | Throughput gate on multi-rep chains only |
| **#3** | **Engine-side double-buffer (acc/ctrl)** | Second acc bank | **No win** — same-bank accumulate is sequential by definition; forwarding already solves RAW | N/A |

**Double-buffering does not fix the dominant gap.** Do batching first; add TCM read ping-pong only if post-pipeline synthesis shows read port registering limits sustained 1 rep/cycle.

---

## 5. Route judgment and execution order

### Route decision (this repo, this phase)

| Route | Verdict |
|---|---|
| **A** — scalar orchestrator + external `mat_engine`, single 8×8×4 fused MAC, **pipeline internals** | **SELECTED** |
| B — multi-engine / Coral 4-wide MAC | **REJECTED** (scope + replatform) |
| C — CPU vectorizes MAC | **REJECTED** (violates accelerator shape; RVV path already separate) |

### Ordered work list (mandatory → optional)

| Order | Work item | Mandatoriness | Verification hook |
|---|---|---|---|
| **1** | **S_RUN 3-stage pipe + acc_fwd bypass + per-bank inflight drain** | **Mandatory** | `mat_golden.py` all corners unchanged; directed mat op tests; throughput gate **re-baseline** |
| **2** | **`mat_engine` → `npu_top` DC/Genus trial** (28HPC+ or project std cell) | **Mandatory** | Report Fmax, area; confirm S_RUN vs S_RSC slack; drives whether step 4 runs |
| **3** | **CQ/descriptor autonomous MAT_OP** (eliminate per-op A/B/CTRL stores) | **Mandatory** (perf ROI) | CQ equivalence gates + TFLM/CNN e2e (`gate_48–50`) |
| **4** | **S_RSC 2-stage pipe** (reg mul product → reg round/sat) | **Conditional** on synth #2 showing S_RSC ≥ S_RUN slack OR requant-bound profile | `mat_golden.py` rescale vectors; bit-exact on requant corners |
| **5** | **TCM read register + optional S0 ping-pong** | **Optional** — only if #2 shows read mux on critical path after #1 | Throughput gate multi-rep |
| **6** | **128b single-port / weight-stationary** | **Defer** (post-signoff area/power audit) | Would need new ADR + feeding contract |
| **7** | **VCS / Spyglass / coverage signoff** | **Mandatory terminal** | Existing signoff gates; pipeline adds reachable-state coverage for bypass/drain |

### Explicit non-goals this phase

- Coral 4-wide MAC replication  
- Changing outer-product dimensions (still 8×8, 4 fused, 256 MACs/cycle **logical** throughput)  
- Cycle-accurate golden (not required; final-value authority stands)

---

## Summary table (one line each)

1. **Cut S_RUN first** — wide combinatorial tree + same-cycle acc feedback; S_RSC only if synth proves it.  
2. **3 pipe stages (RD/MUL/TREE) + comb acc with `acc_fwd` bypass** — 4-cycle fill, 1 rep/cycle steady, bit-exact.  
3. **Keep 2×256b** — 128b trades cycles for port parity; not worth it without weight-stationary redesign.  
4. **Descriptor batching ≫ double-buffer** — software serialization is the real ~10 cycle tax.  
5. **Route A, order: pipeline → synth evidence → CQ batching → (maybe) S_RSC pipe → signoff.**
