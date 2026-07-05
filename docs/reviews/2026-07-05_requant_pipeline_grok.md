# ADR Draft: 2-Stage Requant Pipeline (`mat_engine` rescale)

**Context:** Synopsys DC + TSMC28, 1.2ns aggressive. All 30 worst paths terminate at `pack_q` (requant), ~64 logic levels, Fmax ~730MHz. `S_RUN` (256-MAC accumulate) absent from worst-30. Target: register cut inside requant only; follow-up DC measures new Fmax.

---

## 1. Register boundary — cut after `ab`, not after `s_sum` / `q_tz`

**Verdict: cut immediately after the 32×32 multiply. Register `rq_ab`, `rq_sat`, `rq_exp_r`, `rq_v`. Do not cut after SRDHM.**

| Cut point | Stage 1 (longest chain) | Stage 2 (longest chain) | Balance |
|---|---|---|---|
| **After `ab` (recommended)** | `acc_el` read + `cur_mult` mux + **32×32→64b mult** (~DC-critical) | `nudge`→`s_sum`→SRDHM→`t32` + `rmask`/`q_pot` (variable POT divide) + ZP + clamp → `out8` | Stage 1 ≈ measured critical sub-path; stage 2 ≈ 25–35 levels — acceptable secondary budget |
| After `s_sum` | mult + 64b add + nudge mux | SRDHM + POT + clamp | Stage 1 **strictly longer** than mult-only; no DC evidence the add is on the critical spine |
| After `q_tz` / `t32` | mult + SRDHM (sign, `>>>31`, sat mux) | `rmask` + `q_pot` + clamp | Stage 1 becomes mult **serial with** SRDHM — likely new Fmax limiter; worse than isolating the known-deep mult |

DC ground truth: deepest sub-path is `acc_el * cur_mult` → `ab`. Everything after `ab` is shallower than the multiplier tree. Putting SRDHM or POT divide into stage 1 lengthens the cycle-limiting chain without proof stage 2 is then over-budgeted.

### Exact stage-1 register set (posedge, keyed to `el_iss`)

```verilog
// Stage 1 combinational (same cycle as el_iss)
wire [63:0] ab_s1 = $signed(acc_el) * $signed(cur_mult);
wire        sat_s1 = (acc_el == 32'h8000_0000) && (cur_mult == 32'h8000_0000);
wire [5:0]  exp_r_s1 = cur_shift[5:0] - 6'd31;

// Registers (1-cycle delay element k → available stage 2 when el_pack==k)
logic [63:0] rq_ab;
logic        rq_sat;
logic [5:0]  rq_exp_r;
logic        rq_v;      // flush / first-cycle bubble
```

### Stage 2 (combinational from `rq_*` → `out8`)

```verilog
wire [63:0] nudge_s2 = rq_ab[63] ? 64'hFFFF_FFFF_4000_0000  // 1 - 2^30
                                : 64'h0000_0000_4000_0000;  // 2^30
wire [63:0] s_sum_s2  = rq_ab + nudge_s2;
wire [31:0] q_tz_s2   = s_sum_s2[63] ? -((-$signed(s_sum_s2)) >>> 31)
                                     :  ($signed(s_sum_s2)  >>> 31);
wire [31:0] t32_s2    = rq_sat ? 32'h7FFF_FFFF : q_tz_s2[31:0];
wire [5:0]  exp_r_s2  = rq_exp_r;
// rmask, remv, thr, q_pot, withzp, clampd → out8  (unchanged semantics)
```

**Not registered (safe):** `rs_zp`, `rs_min`, `rs_max` — per-tensor CSR, constant for entire rescale sweep; stage 2 reads CSR flops directly. No `el_i` dependence.

**Not registered (already absorbed):** `cur_mult`, `cur_shift`, `acc_el` — consumed only in stage 1 to produce `rq_ab` / `rq_sat` / `rq_exp_r`.

---

## 2. FSM restructuring — dual counters, lowest risk

**Pick (a): `el_iss` + delayed `el_pack`.** Avoid FIFO (sync/flush risk) and bare valid-SR without explicit index (write-address debug harder). Preserves 16-word addresses and `pack_q` byte order bit-identically.

### Counters

| Signal | Role |
|---|---|
| `el_iss` | Stage-1 ingress index; `0→63` over 64 cycles, then hold (no issue cycle 64) |
| `el_pack` | `el_iss` delayed 1 cycle: `el_pack <= el_iss` (registered each cycle) |
| `rq_v` | `1` when stage-1 slot holds valid element data; `0` cycle 0 and after `soft_reset` |

### Cycle timing (64 elements)

| Cycle | `el_iss` | `el_pack` | `rq_v` | Action |
|---:|---:|---:|---|---|
| 0 | 0 | × | 0→1 | S1 ingest elem 0; **no pack** (bubble) |
| 1 | 1 | 0 | 1 | S1 elem 1; S2 `out8`₀; `pack_q <= {out8, pack_q[31:8]}` |
| 2 | 2 | 1 | 1 | S1 elem 2; pack elem 1 |
| … | … | … | 1 | … |
| 63 | 63 | 62 | 1 | S1 elem 63; pack elem 62 |
| 64 | 63 (hold) | 63 | 1 | **drain**; S2 `out8`₆₃; pack elem 63; last word-write if `[1:0]==3` |

**Latency:** 65 active rescale cycles vs 64 baseline = **+1 cycle per rescale op.**

### FSM (minimal rename of existing `S_RSC` / `S_RSW` / `S_FIN`)

Predicates switch from `el_i` → `el_pack`. Issue logic uses `el_iss`.

```verilog
// S_RSC (pack + issue)
if (el_iss != 6'd63)
    el_iss <= el_iss + 1'b1;           // cycles 0..62 increment; hold at 63 cycle 64

if (rq_v) begin
    pack_q <= {out8, pack_q[31:8]};
    if (el_pack[1:0] == 2'd3)
        state <= S_RSW;
end

// S_RSW (word write — timing shifted +1 vs original, address math unchanged)
t_we    <= 1'b1;
t_waddr <= out_base_word + (el_pack[5:2] - 4'd1);  // el_pack is post-pack index
                                                      // same as original (el_i+1)[5:2]-1
if (el_pack == 6'd63)                                 // was el_i==0 after wrap from 63
    state <= S_FIN;
else
    state <= S_RSC;
```

**Address / byte-order proof:** Original packs `out8` for `el_i=k` same cycle, writes when `el_i` has advanced to `k+1` with `(k+1)[1:0]==0` and addr `(k+1)[5:2]-1 = k[5:2]` for `k[1:0]==3`. Pipelined version packs `out8` for `el_pack=k` one cycle later; write uses same `(el_pack+1)` semantics → identical `t_waddr` sequence `out_base+0..15` and identical big-endian byte order in `pack_q` (`{out8, pack_q[31:8]}` unchanged).

**Entry:** On rescale start, `el_iss<=0`, `el_pack<=6'd63` (don't-care), `rq_v<=0`, `pack_q<=0`. First issue cycle clears bubble.

**Exit:** `S_FIN` unchanged. 16th word write occurs cycle 64 (was 63) — the documented +1 shift.

---

## 3. Hazards — every `el_i`-dependent term

Stage 2 must see **zero** live `el_i` / `el_iss`. All per-element selection captured in stage 1.

| Term | Depends on `el_i`? | Action |
|---|---|---|
| `cur_mult = pc_mode ? mult_c[el_i[2:0]] : rs_mult` | **yes** (`[2:0]`) | Compute in S1; result in `rq_ab` / `rq_sat` only |
| `cur_shift = pc_mode ? shift_c[el_i[2:0]] : rs_shift` | **yes** | Compute `exp_r_s1` in S1 → `rq_exp_r` |
| `acc_el = acc[bank_q][el_i]` | **yes** (index) | Read in S1 only; **do not** re-index `acc` in S2 |
| `ab` | via above | → `rq_ab` |
| `sat` | via `acc_el`, `cur_mult` | → `rq_sat` |
| `exp_r` | via `cur_shift` | → `rq_exp_r` |
| `nudge`, `s_sum`, `q_tz`, `t32` | no (from `rq_*`) | S2 combo |
| `rmask`, `q_pot` | no (`rq_exp_r` only) | S2 combo |
| `withzp`, `clampd`, `out8` | no (`rs_zp/min/max` tensor CSR) | S2 combo |
| `pack_q` shift position | **yes** (`[1:0]`) | Use **`el_pack[1:0]`**, not `el_i` |
| `t_waddr` | **yes** (`[5:2]`) | Use **`el_pack[5:2]`** (with same +1 wrap semantics) |
| `pc_mode` | no (mode CSR, constant per op) | S1 mux only |
| `bank_q` | no (constant per rescale) | S1 `acc` read port only |

**Mandatory rule:** no `mult_c[el_i[2:0]]` / `shift_c[el_i[2:0]]` / `acc[bank_q][el_i]` in stage 2. Re-selecting with advanced `el_i` in S2 is a silent bit-corruption bug.

---

## 4. Bit-exact preservation + verification

**Argument:**

1. During `S_RSC`/`S_RSW`, `acc` is not written → `acc[k]` stable when element `k` is processed.
2. Requant is a pure feed-forward map per element:  
   `out8[k] = g(acc[k], mult[k], shift[k], zp, min, max)` — no loop-carried dependency.
3. Stage 1 computes `g₁(inputs) → (rq_ab, rq_sat, rq_exp_r)`; stage 2 computes `g₂(rq_*) = g(inputs)` — algebraically identical to monolithic `g`, only delayed 1 cycle.
4. `el_pack = el_iss - 1` preserves pack position and write-address mapping vs original `el_i`.

**Gates (must re-run, expect green without golden change):**

| Gate | What it proves |
|---|---|
| `gate_45` | `mat_golden.py` packed-byte diff — **primary** requant bit-exact |
| `gate_46` | CQ end-to-end rescale path |
| `gate_48` | TFLM int8 FC corner e2e |
| `gate_49` | TFLM AOT 2-layer MLP |
| `gate_50` | TFLM Conv2D per-channel |

No NumPy golden / opcode encoding change. Only RTL pipeline + FSM +1 cycle.

**Throughput:** +1 cycle per `RESCALE` descriptor (64 elements). MAC/`S_RUN` duty cycle unchanged. Rescale is tail of tensor op — negligible vs compute-bound workloads; rescale initiation latency +1 cycle.

---

## 5. Pipeline `S_RUN` now?

**No. Requant-only is correct.**

- DC: all 30 worst paths at `pack_q`; `S_RUN` absent from worst-30 → accumulate already meets 1.2ns budget.
- `S_RUN` has structural MAC tree + acc feedback (loop-carried across cycles / bank semantics). Pipelining it risks acc hazard, multi-bank write-enable skew, and CQ timing — high risk, no DC justification.
- Strategy: close requant Fmax gap first; follow-up DC locates new critical path (likely stage-2 `q_pot` variable shift or stage-1 mult remainder). Only then consider secondary cuts (e.g. register `t32` + `rq_exp_r` if stage 2 emerges as limiter).

---

## Summary decision

| Item | Decision |
|---|---|
| Cut point | After `ab`; registers `rq_ab[63:0]`, `rq_sat`, `rq_exp_r[5:0]`, `rq_v` |
| FSM | `el_iss` (S1) + `el_pack = el_iss@N-1` (S2 pack/write); +1 drain cycle; 16 writes bit-identical |
| el_i hazards | Capture `cur_mult`/`cur_shift`/`acc_el` in S1 only; S2 uses `el_pack` for pack/write indexing |
| Correctness | Pure feed-forward → bit-exact by construction; `gate_45` authoritative |
| `S_RUN` | Do not pipeline; DC evidence supports requant-only |

**Next step:** RTL implement per above → `gate_45` green → DC rerun → record new Fmax and whether stage-2 `RoundingDivideByPOT` becomes successor critical path (candidate second cut: `rq_t32` + `rq_exp_r` if needed).
