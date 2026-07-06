## Phase-E Long Tail — Architecture Spec (ADR + Litmus Draft)

House rules assumed throughout: Spike `rv32imf_zve32x_zvl128b` is golden; DUT `vstart≠0` illegal for all non-memory ops; group-EMUL plain `vle/vse` illegal; fractional-LMUL bounds via `vlmax_el`; reductions today m1/vm=1 only.

---

# (a) `vcompress.vm` — First Slice (FULL)

### ROI — **Do now (P0 within Phase-E tail)**

| Factor | Verdict |
|--------|---------|
| TFLM | Autovectorized **argmax / top-k / sparse-ish** paths often lower to **compress active lanes** after compare/mask (`vmseq` → `vcompress`). Not on every kernel, but appears in **classification heads** and mask compaction. |
| Coral parity | Coral Zve32x exposes compress; drop-in parity needs it for **compiler-emitted** RVV, not hand-written only. |
| RTL cost | **Low–medium**: permute-class, no memory FSM; single-pass scan + running write index. No new port. |
| Defer risk | Compiler may emit it whenever masks exist; silent illegal → **mysterious TFLM failures**. |

**Decision: do-now, first E-tail slice.**

---

### Encoding

| Field | Value |
|-------|-------|
| Opcode | `OP-V` → **OPIVV** (`opcode[6:0] = 1010111`) |
| `funct6` | **`010111`** (`0x17`) |
| `funct3` | **`010`** (`.vv`) |
| `vm` | **Must be 0** — mask is **explicit `vs1`**, not `v0` |
| `vd`, `vs1`, `vs2` | Standard 5-bit regnums; **same SEW** for all three |

Illegal if: `vm=1`; `vstart≠0`; `vill`; `vd` overlaps `vs1` or `vs2`; masked-body write to `v0` (N/A here); any group-reduction/masked-reduction coupling (N/A).

---

### Per-element semantics (exact)

Let `SEW` ∈ {8,16,32}, `vl` current, `EEW = SEW` for `vd/vs1/vs2`.

**Mask source:** element `i` of **`vs1`** (not `v0`). Active iff `vs1[i]` is truthy per mask semantics (for integer SEW: LSB of element, or full element ≠ 0 per `vms*` convention — **pin with Spike litmus #1**).

**Running index recurrence (authoritative algorithm):**

```
j ← 0
for i = 0 .. vl-1:
    if active(vs1[i]):
        vd[j] ← vs2[i]
        j ← j + 1
// positions [j .. vl-1] in vd: TAIL — undisturbed (prior vd values)
// positions [vl .. vlmax-1]: inactive — undisturbed
```

- **No writes** to `vd[k]` for `k ≥ j` among the `vl` active body (only the first `j` lanes are overwritten).
- **`vs2`/`vs1` read-only**; inactive `vs2[i]` never copied.
- **Order preserved**: increasing `i` → increasing `j`.

**Tail policy:** **`undisturbed`** on `vd[j:vl]` and inactive `vd[vl:vlmax]`. (Spike is the tie-break if any agnostic nuance; litmus must assert prior `vd` survives.)

**LMUL scope:** Same as other OPIVV permutes — support **`m1/m2/m4/m8`** via existing **VM_GRP** multi-beat FSM; each beat uses local `vl` slice and **local `j` reset per beat** only if group semantics are per-subregister; **pin with litmus #6** (m2). If whole-instruction atomic: one global `j` across group — Spike decides.

**Overlap:** **`require_nooverlap(vd, vs1)`** and **`require_nooverlap(vd, vs2)`** (standard RVV compress rule). DUT may remain stricter if already global for permutes.

---

### Legality (DUT contract)

| Rule | |
|------|--|
| `vstart` | **Must be 0** (global non-memory rule) |
| `vm` | **Must be 0**; `vm=1` → illegal |
| Overlap | `vd` must not overlap `vs1` or `vs2` |
| `vstart` + memory | N/A |
| EEW | `vd` EEW = `vs1` EEW = `vs2` EEW = `SEW` |
| LMUL | `vd`, `vs1`, `vs2` same EMUL; group beats via VM_GRP |
| Fractional LMUL | Use **`vlmax_el`** bound checks (DUT stricter OK) |

---

### Minimal RTL shape

| Block | Role |
|-------|------|
| **Decode** | OPIVV + `funct6=010111` + `funct3=010` + `vm==0`; else illegal |
| **Legality** | `vstart≠0`, overlap `vd`↔`vs1`/`vs2`, `vm≠0` |
| **Execution** | **vexu permute path** (like `vrgather`), **not vmem** |
| **FSM** | Extend **VM_GRP** only if m2+ needs multi-beat; **no new top-level FSM** |
| **Datapath** | Single forward scan over `i∈[0,vl)`: read `vs1[i]`, `vs2[i]`; if active, write `vd[j++]`; else no `vd` write |
| **WB** | Group **atomic commit** as existing permute ops |

Combinational core per beat; `j` register held in beat FSM across cycles if `vl` > lane plumbing width.

---

### Spike-probe litmus (pin before RTL)

| # | Setup | Op | Expected (assert all `vd` lanes) |
|---|-------|-----|----------------------------------|
| **C1** | `vsetivli vl=8, e8, m1`; `vs2={a..h}`; `vs1` mask **explicit pattern** `0,1,0,1,1,0,0,1` (define encoding in asm); `vd` prefill `0xDE` | `vcompress.vm v4, v6, v5` (`vd,vs2,vs1`) | Packed low: `vs2[1],vs2[3],vs2[4],vs2[7]` → `vd[0..3]`; **`vd[4..7]=0xDE`** |
| **C2** | `vl=4`, all `vs1` inactive | compress | **`j=0`** → **`vd[0..3]` undisturbed** (all prefill) |
| **C3** | `vl=4`, all `vs1` active | compress | `vd[i]=vs2[i]` for `i=0..3` |
| **C4** | `vl=0` | compress | **No `vd` body writes**; all undisturbed |
| **C5** | `vm=1` encoding | — | **Spike illegal** → DUT illegal |
| **C6** | `vstart=4` (if Spike allows — expect illegal on DUT regardless) | — | DUT **illegal**; record Spike for doc honesty |
| **C7** | `vd==vs2` or `vd==vs1` | — | **Illegal** (overlap) |
| **C8** | `e32, m1, vl=3`, sparse mask on middle lane | compress | 32-bit element pack order + tail `vd[2]` undisturbed if only 1 active |
| **C9** | `m2, vl=8` (two registers) | compress | Cross-beat `j` continuity vs per-register — **Spike golden file** |

---

### Top green-wash risk

**Testing only `vl=8, m1, all-distinct regs, vm=0` with a hand-written mask** while **missing tail undisturbed** (`vd[j:vl]` must keep old values). Naive directed test that pre-zeroes `vd` or checks only `vd[0..j-1]` **hides** wrong tail policy and **wrong mask register** (accidentally using `v0` via `vm=1` path).

---

# Ranked tail: (b)–(f)

| Rank | Item | ROI | Action |
|------|------|-----|--------|
| **1** | **(b) Strided `vlse`/`vsse`** | **High** — TFLM **depthwise/stride conv**, NHWC padding, non-contiguous rows; compiler emits strided vector loads. | **Do-now** (after compress or parallel track) |
| **2** | **(c) Indexed `vluxei`/`vloxei`/`vsuxei`/`vsoxei`** | **High** — **gather/scatter** for embedding, sparse, some conv im2col alternatives; Coral has them. | **Do-now** (vmem FSM) |
| **3** | **(d) `vle*ff.v` fault-only-first** | **Medium** — prologue/epilogue of unknown length; less common in fixed-shape TFLM than strided/indexed. | **Do-now lite** or **defer** if no emitted FF in Coral object dumps |
| **4** | **(f) Masked reductions `vred*` vm=0** | **Medium** — useful for **masked sum/mean**; many TFLM paths use `vredsum` unmasked + scalar cleanup. | **Defer** until object-dump proof; keep illegal + documented |
| **5** | **(e) `vrgatherei16.vv`** | **Low** — niche index width; `vrgather` + widen index often suffices; deferred from E3 for cause. | **Defer** |

---

## (b) Strided load/store — sketch

**ROI:** Do-now (#1).  
**Encoding:** `OP-V` **stride-indexed mem**: `vlse<eew>.v` / `vsse<eew>.v` — `funct3` width, `mop`/`lumop`/`sumop` per spec table (Spike decode dump). Address: `addr = rs1 + i * rs2` per element `i`.  
**Semantics:** Per-element strided access; **mem resumes `vstart`**; tail inactive untouched on stores; loads zero/agnostic per policy.  
**Legality:** `vstart` OK (memory); no group-EMUL plain load scope-cut stays; indexed overlap rules per mem chapter.  
**RTL:** **vmem FSM extension** — reuse segment-style `i` loop; add `stride*elem_idx` to base (rs2 scalar stride in **bytes** per Spike).  
**Litmus:** `vl=4, stride=8, base` → 4 words at 0,8,16,24; `vstart=2` resume; fault on bad addr.  
**Green-wash:** Unit-stride regression only — misses **stride≠EEW** and **`vstart` resume**.

---

## (c) Indexed load/store — sketch

**ROI:** Do-now (#2).  
**Encoding:** `vluxei32.v`, `vloxei32.v`, `vsuxei32.v`, `vsoxei32.v` (+ e8/e16 variants).  
**Semantics:** `addr_i = rs1 + vs2[i]` (index EEW typically 32 for Zve32x); ordered vs unordered variants per spec.  
**Legality:** mem `vstart` resume; `vs2` index reg no overlap `vd` on load; store analogous.  
**RTL:** **vmem FSM** — same skeleton as segment + gather index read per beat.  
**Litmus:** fixed index vector `{0,4,8,12}`; duplicate indices; `vstart=1`; OOB trap.  
**Green-wash:** only **ordered** paths tested; **unordered** store ordering differs.

---

## (d) `vle<eew>ff.v` — sketch

**ROI:** Medium — defer until FF seen in TFLM/Coral dumps.  
**Encoding:** `vle*ff.v` load FF variant (`nf`/`mew`/`vm` per spec row).  
**Semantics:** Load until first fault; **`vl` may shrink**; fault only on first active element fault.  
**Legality:** `vstart` resume; **`vstart≥vl` illegal** after VL trim.  
**RTL:** **vmem FSM** + **`vl` side-effect** (CSR write) — new for vexu.  
**Litmus:** guard page after 3 valid words → `vl` becomes 3; element 3 fault doesn't touch rest.  
**Green-wash:** fake FF in TB without **`vl` CSR update** vs Spike.

---

## (e) `vrgatherei16.vv` — sketch

**ROI:** Low — **defer**.  
**Encoding:** OPIVV `vrgatherei16` funct6 row (16-bit indices in vs1).  
**Semantics:** Like `vrgather` but index EEW=16, scaled to SEW.  
**RTL:** vexu permute; index narrow read path.  
**Green-wash:** only SEW=32 indices via `vrgather` — never tests **16-bit wrap/scale**.

---

## (f) Masked reductions — sketch

**ROI:** Medium — **defer** (documented scope-cut).  
**Encoding:** existing `vredsum.vs` etc with **`vm=0`** (mask from `v0`).  
**Semantics:** Only active masked lanes contribute; inactive lanes don't affect acc; `vstart=0`.  
**Legality:** Today m1/vm=1 only — extending needs **group + mask** legality.  
**RTL:** **vexu reduction unit** + mask latch; possibly multi-cycle.  
**Litmus:** partial mask sum known scalar; `vstart` illegal on DUT.  
**Green-wash:** **vm=1-only tests** while claiming masked reduction done.

---

## Recommended implementation order

1. **`vcompress.vm`** (this slice) — vexu permute, low risk, compiler-facing.  
2. **`vlse`/`vsse`** — highest TFLM memory ROI.  
3. **Indexed load/store** — vmem FSM reuse from (2)+segment.  
4. **`vle*ff.v`** — if object-dump or gate requires.  
5. **Defer:** `vrgatherei16`, masked reductions — ADR scope-cut unless evidence flips.

I can turn this into a formal `docs/adr/00xx-phase-e-tail.md` with encodings copied from your decode tables and a `tests/litmus/vcompress_spike_probe.S` skeleton when you're ready to implement.
