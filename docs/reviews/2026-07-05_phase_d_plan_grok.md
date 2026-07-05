# Phase-D (mask-scan + slides) — Grok architecture confirmation (2026-07-05)

Order D1a(vid)->D1b(vcpop/vfirst)->D2a(slide1)->D1c(vms*)->D1d(viota)->D2b(slide). ADR-0057.

NOTE: Grok's vcpop/vfirst 'vstart-exempt' claim was empirically WRONG — Spike traps vcpop@vstart!=0 (see D1a).

# Phase-D Architecture Review: Mask-Scan (D1) + Slides (D2)

Authority anchor: RVV 1.0 / Zve32x, `vlmax` per `SEW`, tail undisturbed, Spike `zve32x_zvl128b` lockstep.

---

## 1. Order by cost/risk (cheapest first)

| Rank | Sub-slice | Rationale |
|------|-----------|-----------|
| **1** | **D1a: `vid.v`** | Pure index counter per active lane; no vs1 scan, no scalar path. Lowest semantic surface. |
| **2** | **D1b: `vcpop.m` + `vfirst.m`** | Single mask-lane reduction → scalar `rd`; shares popcount/leading-zero finder; **no `vd`**, no tail-policy debate. |
| **3** | **D2a: `vslide1up.vx` / `vslide1down.vx`** | Offset fixed at 1; small neighbor mux + one scalar inject; reuses existing `vd_old` in-place contract. |
| **4** | **D1c: `vmsbf.m` / `vmsof.m` / `vmsif.m`** | One shared “first active set bit in `vs1`” engine, three output recipes; mask-dest tail/masking is the risk cluster. |
| **5** | **D1d: `viota.m`** | Prefix-sum over masked-active `vs1` bits; highest D1 bug rate (off-by-one on inactive elements, `vstart` boundary). |
| **6** | **D2b: `vslideup.*` / `vslidedown.*`** | General `off` mux up to `vlmax−1`; `.vx`/`.vi` unsigned offset; EMUL group beats; in-place `vd==vs2` ordering. |

**Why D1 before D2 (mostly):** D1a–b and D1c–d build a reusable mask scan tree that `viota` needs anyway. **Exception:** slip **D2a** between D1b and D1c—it is mechanically simpler than `vms*`, validates `vd_old`/group FSM without wide offset mux, and de-risks D2b.

**Recommended delivery slices:** `vid` → `vcpop/vfirst` → `slide1` → `vmsbf/vmsof/vmsif` → `viota` → `slideup/down`.

---

## 2. D1 exact semantics, masking, destinations

**Active element definition (all D1):** index `i ∈ [0, vl)`; if `vm=0`, only `v0[i]=1` lanes participate. Inactive lanes: **`vd` undisturbed** (mask-dest or vector-dest); scalar ops ignore inactive lanes in count/search.

### Scalar-dest (`vcpop.m`, `vfirst.m`)

| Op | Semantics | Mask `v0`? |
|----|-----------|------------|
| **`vcpop.m`** | `rd = Σ_{i active} vs1[i]` (each `vs1[i]∈{0,1}`) | Yes—count only active |
| **`vfirst.m`** | `rd = min { i \| active ∧ vs1[i]=1 }`, else `−1` (all bits set in `XLEN`) | Yes—search only active |

### Mask-dest (`vmsbf.m`, `vmsof.m`, `vmsif.m`, `viota.m`)

Let `F = min { i \| active ∧ vs1[i]=1 }`, undefined if none.

| Op | `vd[i]` for **active** `i` | Inactive `i` (`vm=0`) |
|----|---------------------------|------------------------|
| **`vmsbf.m`** | `1` iff ∃ active `j<i` with `vs1[j]=1`; else `0` | undisturbed |
| **`vmsof.m`** | `1` iff `i=F`; else `0` | undisturbed |
| **`vmsif.m`** | `1` iff `i≥F` (inclusive from first set); else `0` (if no `F`, all `0`) | undisturbed |
| **`viota.m`** | `# { active j<i : vs1[j]=1 }` (prefix popcount over **active** lanes only) | undisturbed |

**`vid.v`:** `vd[i]=i` (zero-ext to `SEW`) for active `i`; **`vs2` ignored** (tie off / don’t read). Inactive → undisturbed. Vector-dest.

### Destination class summary

| Class | Ops |
|-------|-----|
| **Scalar `rd`** | `vcpop.m`, `vfirst.m` |
| **Mask `vd`** (effective `LMUL=1`) | `vmsbf.m`, `vmsof.m`, `vmsif.m`, `viota.m` |
| **Vector `vd`** | `vid.v` |

**Tail policy:** all vector/mask destinations follow your global **tail undisturbed** (`i ≥ vl` untouched).

---

## 3. D1 illegality

| Rule | Applies to |
|------|------------|
| **`vstart≠0` → illegal** | `vmsbf/vmsof/vmsif`, `viota`, **`vid.v`** (vector/mask body producers) |
| **`vstart` ignored (legal at `vstart≠0`)** | **`vcpop.m`, `vfirst.m`** — spec-exempt scalar mask ops; scan/count over `i∈[0,vl)` with normal `vm` masking, **not** `[vstart,vl)` skip |
| **Masked body write `vd[0]` illegal** | **`vid.v`, `viota.m`** (vector-dest / treated as body op writing `vd`) |
| **`vmsbf/vmsof/vmsif/viota` → `vd[0]`** | These **define** mask bits in `vd`; not the “masked-body-write-v0” case—that rule targets **arithmetic** ops with `vm=0` **using** `v0` as mask while **writing** `v0` as dest. Still illegal: **`vid.v` with `vd=v0` and `vm=0`**. |
| **`vd` overlap `v0`** | `viota`/`vid`: if `vd` aliases `v0` and instruction would write `vd[0]` under mask → **illegal** (same as other body ops). Mask-result ops (`vms*`) write full mask dest—**`vd=v0` always illegal** (you’re defining the mask register). |
| **`vs2` overlap** | `vid` ignores `vs2`—overlap don’t-care if `vs2` unread. `viota` reads `vs1` only. `vms*` read `vs1` only. |

**Clarification on your “arithmetic body” rule:** extend the illegal table explicitly:

- **Category A (scalar mask scan):** `vcpop`, `vfirst` — **exempt** from `vstart≠0`.
- **Category B (mask/vector body):** everything else in D1 — **`vstart≠0` illegal**.

---

## 4. D2 slides

### `vslideup.vx/.vi` (`f6=001110`)

For each active `i ∈ [max(vstart, off), vl)`:

- `vd[i] = vs2[i − off]`

For active `i ∈ [vstart, vl)` with `i < off`: **undisturbed**.  
`off` = `rs1` (unsigned, low `log2(vlmax)` bits) or `uimm` zero-extended.  
`off ≥ vl` → no active index satisfies `i≥off` → **all active lanes undisturbed**.

**Masking (`vm=0`):** inactive lanes undisturbed.

### `vslidedown.vx/.vi` (`f6=001111`)

For active `i ∈ [vstart, vl)`:

- if `i + off < vlmax` (use **`vlmax`**, not `vl`): `vd[i] = vs2[i + off]`
- else: **`vd[i] = 0`** (not undisturbed—spec zero-fill)

**Masking:** inactive undisturbed.

### `vslide1up.vx` / `vslide1down.vx` (`OPMVX`, same `f6`)

- **`vslide1up`:** active `i=0` → `vd[0]=rs1` (SEW-wide, **signed extend of `rs1[SEW-1:0]`** per spec); active `i>0` → `vd[i]=vs2[i−1]`.
- **`vslide1down`:** active `i=vl−1` → `vd[vl−1]=rs1` (same sext); active `i<vl−1` → `vd[i]=vs2[i+1]`.

**Masking:** inactive undisturbed; injected scalar only when that lane index is active.

### Overlap / group

- **`vslideup` `vd==vs2`:** **legal** (in-place); must read `vs2` from **`vd_old`** before write—your datapath already has this.
- **`vslidedown` `vd==vs2`:** **legal**, same `vd_old` discipline.
- **`vslide1*` `vd==vs2`:** legal with `vd_old`.
- **EMUL:** slides are per-element with EMUL>1; use existing **VM_GRP multi-beat** (m2/m4). Reductions/m1-only rule does **not** apply. Mask register not involved unless `vm=0`.

---

## 5. Phase-D trap corners (beyond generic rules)

| Corner | Behavior |
|--------|----------|
| **`vfirst` no set bit** | `rd = −1` (`XLEN` all ones); Spike bit-exact on scalar write |
| **`vcpop` empty active** | `rd = 0` |
| **`vms*` / `viota` no set bit in active `vs1`** | `vmsbf`→all `0`; `vmsof`→all `0`; `vmsif`→all `0`; `viota`→all `0` |
| **`vslidedown` zero-fill** | `i+off ≥ vlmax` → **0**, even if `vs2` would be undisturbed in a “tail” intuition—common Spike mismatch |
| **`vslideup` `off=0`** | degenerate copy on active range (still honor mask) |
| **Large `off` on slide1** | `vslide1up` at `vl=0` → no active elements, nothing written |
| **`vid` at `vl=0`** | no writes; scalar side effects none |
| **`viota` + `vm=0`** | inactive positions **undisturbed**, active get running count **skipping** inactive (not “count as 0 in prefix”) |
| **SEW 8/16/32** | `vcpop` result in `rd` is `XLEN` wide; `vfirst` index fits in `XLEN`; mask ops always **1-bit `vd`** regardless of `SEW` |
| **`vstart≠0` on `vcpop`** | **must not trap**—add explicit decode exemption or Spike will diverge immediately |

---

## Lockstep test ordering (minimal)

1. `vid` grid: `vl∈{1,2,3,4,8}`, `vm` on/off  
2. `vcpop/vfirst`: empty / singleton / all-ones masks; **`vstart≠0` must-pass** for scalar pair only  
3. `vmsbf/vmsof/vmsif`: golden first-set at 0, mid, last, none; masked gaps  
4. `viota`: compare against serial reference on random `vs1`+`v0`  
5. `slide1` then `slideup/down`: `off∈{0,1,vl−1,vl,vlmax−1}`; **`vd==vs2` in-place**; `vslidedown` zero-fill past `vlmax−off`  
6. Group beats: one m2/m4 case per slide opcode at `SEW=32`

**Highest-risk assertions:** `viota` inactive undisturbed + active prefix; `vslidedown` zero vs undisturbed; `vcpop/vfirst` at `vstart≠0` legal; `vms*` with masked holes before/after first set.
