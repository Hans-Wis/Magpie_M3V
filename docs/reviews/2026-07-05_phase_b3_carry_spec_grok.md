# Zve32x Phase-B B3: `vadc` / `vmadc` / `vsbc` / `vmsbc` — Implementation Spec

Authority: Spike `--isa=zve32x_zvl128b`, RVV 1.0 unsigned carry/borrow rules.  
Fits existing `vexu` split: **arithmetic path** → vector `vd`; **compare path** → 1-bit-per-element MASK `vd`; inactive = undisturbed; `vstart≠0` illegal on arithmetic.

---

## 1. Decode / encodings

All four use **OPI\*** (`f3` = `000` OPIVV, `100` OPIVX, `011` OPIVI).  
`f6=010010` collides with OPMVV `vzext/vsext` only on **`f3=010` (OPMVV)** — disjoint.

| Instr | f6 | Legal forms (`f3`) | `vm=0` | `vm=1` |
|-------|-----|-------------------|--------|--------|
| **vadc** | `010000` | vvm, vxm, **vim** | **Only legal form.** Carry-in from `v0[i]`. | **RESERVED → illegal** |
| **vmadc** | `010001` | vvm, vxm, vim **and** vv, vx, vi | **Masked carry-in:** `vadc.v*m` family. `cin=v0[i]`. | **No carry-in:** `vmadc.vv/vx/vi`. `cin=0`. |
| **vsbc** | `010010` | **vvm, vxm only** | **Only legal form.** Borrow-in from `v0[i]`. | **RESERVED → illegal** |
| **vmsbc** | `010011` | **vvm, vxm only** (no vi/vim) | **Borrow-in:** `vmsbc.v*m`. `bin=v0[i]`. | **No borrow-in:** `vmsbc.vv/vx`. `bin=0`. |

### `vm` bit meaning (confirmed)

- **vadc / vsbc:** `vm` is not a predicate toggle. **`vm=0` is required**; `v0` is **carry/borrow operand**, not mask. **`vm=1` → illegal.**
- **vmadc / vmsbc:** `vm` selects carry/borrow **operand presence**:
  - `vm=0`: read `v0[i]` as `cin`/`bin`; mnemonic suffix `.vvm`/`.vxm`/`.vim`.
  - `vm=1`: no `cin`/`bin`; mnemonic `.vv`/`.vx`/`.vi` (vi only for **vmadc**).
- **vsbc / vmsbc have no immediate form** — subtract-with-borrow has no `OPIVI` encoding in RVV. Decode `f6=010010/010011` + `f3=011` as **illegal**.

Immediate (`vim`/`vi`): sign-extend 5-bit imm to SEW (same as `vadd.vi`).

---

## 2. Per-element datapath (SEW ∈ {8,16,32})

Operands per element `i`:
- `a = vs2[i]` (unsigned SEW-bit)
- `b = vs1[i]` | `zero_ext(rs1,SEW)` | `sext(imm,SEW)`
- `c = v0[i]` (1-bit, 0/1) when used as carry/borrow **in**

Widen to **SEW+1** for carry/borrow detection; result reg uses mod `2^SEW`.

### Vector-result (arithmetic path)

```
vadc:  vd[i] = (a + b + c) mod 2^SEW     // unsigned; c = v0[i], vm must be 0
vsbc:  vd[i] = (a - b - c) mod 2^SEW     // unsigned; c = v0[i], vm must be 0
```

### Mask-result (compare path)

```
cin  = (vm==1) ? 0 : v0[i]
bin  = (vm==1) ? 0 : v0[i]

vmadc:  vd[i] = bit SEW of ( zero_ext(a,SEW+1) + zero_ext(b,SEW+1) + cin )
        // equivalently: 1 iff (a + b + cin) >= 2^SEW

vmsbc:  vd[i] = 1 iff  zero_ext(a,SEW+1) < zero_ext(b,SEW+1) + bin
        // equivalently: unsigned borrow on (a - b - bin)
        // DO NOT use signed underflow; DO NOT use (a-b-bin) mod 2^SEW alone
```

**Unsigned only** — no signed carry/borrow variants. Confirmed.

RTL one-liners (per SEW slice):

```verilog
wire [SEW:0] sum  = a + b + cin;           // vmadc carry-out = sum[SEW]
wire [SEW:0] diff = a - b - bin;           // vmsbc borrow-out  = diff[SEW]  (MSB of SEW+1 result)
// vsbc mod result: diff[SEW-1:0]
```

---

## 3. Active / mask policy

### vadc / vsbc (vector `vd`)

- **`v0` is NOT the execution mask.** Do **not** apply `v0` as predicate.
- **Force active** for every element `i ∈ [vstart, vl)` — same spirit as `vmerge` (all body elements computed and written).
- `i < vstart` or `i ≥ vl` → **undisturbed**.
- Standard tail policy (`ta`/`tu`) applies to tail elements per `vtype`; body always written.

### vmadc / vmsbc (mask `vd`)

- **Mask-producing** — ignore `vm` as body predicate (only controls `cin`/`bin`).
- Write **all** elements `i ∈ [0, vl)` (with `vstart=0` enforced, so `[vstart,vl) = [0,vl)`).
- `i ≥ vl` → undisturbed.
- When `vm=0`, `v0[i]` is read as `cin`/`bin` **and** `vd[i]` is written — simultaneous read/write of `v0` bits is why `vd==0` is illegal in that form (§4).

**Confirmed:** compares and `vmadc`/`vmsbc` emit mask bits for the full `vl` span regardless of any “masking” interpretation of `v0`.

---

## 4. Legality / overlap

| Check | vadc | vsbc | vmadc | vmsbc |
|-------|------|------|-------|-------|
| `vstart ≠ 0` | **illegal** | **illegal** | **illegal** | **illegal** |
| `vm=1` | **illegal** | **illegal** | legal (no cin) | legal (no bin) |
| `vd == 0` | **illegal** (reads `v0` as cin) | **illegal** (reads `v0` as bin) | **illegal iff `vm=0`** (RW `v0`) | **illegal iff `vm=0`** |
| `vd == 0`, `vm=1` | N/A | N/A | **legal** (writes mask to `v0`, no cin read) | **legal** |
| OPIVI / vim | legal | **illegal** | vim + vi legal | **illegal** |
| `vill` / dtype | std | std | std | std |

No other special overlap rule beyond normal vector register-group constraints.

---

## 5. `beats_op` / LMUL

| Instr | Dest type | `beats_op` |
|-------|-----------|------------|
| **vadc.*** | vector reg group (same shape as `vadd`) | **IN** — m2/m4 multi-beat like add/sub |
| **vsbc.*** | vector reg group | **IN** |
| **vmadc.*** | mask reg (`LMUL=1`, one bit / elem) | **OUT** — single beat, like `vmseq`/`vmslt` |
| **vmsbc.*** | mask reg | **OUT** |

Source shapes: `vadc`/`vsbc`/`vmadc`/`vmsbc` `.vvm`/`.vxm` follow normal `vs2`+`vs1` grouping; `.vim`/`.vi` use scalar imm (no extra source beats).

---

## 6. `vexu` hook-up (minimal)

### Decode flags

```
is_vadc   = (f6==010000) && opivi/opivx/opivv
is_vmadc  = (f6==010001) && ...
is_vsbc   = (f6==010010) && (opivv || opivx)
is_vmsbc  = (f6==010011) && (opivv || opivx)
is_b3_arith = is_vadc || is_vsbc
is_b3_cmp   = is_vmadc || is_vmsbc
```

### Illegal precheck (before execute)

```text
if is_vadc  && (vm || vd==0 || vstart!=0) → illegal
if is_vsbc  && (vm || vd==0 || vstart!=0 || opivi) → illegal
if is_vmadc && (vstart!=0 || (vm==0 && vd==0)) → illegal
if is_vmsbc && (vstart!=0 || (vm==0 && vd==0) || opivi) → illegal
```

### Execute routing

| Path | Instr | `force_active` | `dest_is_mask` |
|------|-------|----------------|----------------|
| Arithmetic loop | vadc, vsbc | **1** for `i∈[vstart,vl)` | 0 |
| Compare loop | vmadc, vmsbc | N/A (mask path) | **1** |

Per-SEW generate loops: reuse add/sub unsigned mod for `vadc`/`vsbc`; reuse compare mask write for `vmadc`/`vmsbc` with formulas in §2.

---

## 7. Spike lockstep golden (per element)

```python
def vadc(a, b, c, sew): return (a + b + c) & ((1<<sew)-1)
def vsbc(a, b, c, sew): return (a - b - c) & ((1<<sew)-1)

def vmadc(a, b, cin, sew):
    s = a + b + cin
    return 1 if s >= (1<<sew) else 0

def vmsbc(a, b, bin_, sew):
    return 1 if a < b + bin_ else 0   # unbounded int; operands are SEW-bit unsigned
```

Test matrix minimum: SEW {8,16,32} × forms above × `vl` corner × `vmadc`/`vmsbc` both `vm=0` (`vd≠0`) and `vm=1` (`vd==0` legal) × carry/borrow boundary (`a+b+cin = 2^SEW-1`, `a < b+bin`, `a == b+bin`).

---

**Bottom-line confirmations:** your beliefs on §1–§5 are all **correct** as stated; only precision added is `vmsbc` borrow = `a < b+bin` (unsigned, wide compare), not signed underflow, and `vmadc`/`vmsbc` `vd==0` is legal **only** when `vm=1`.
