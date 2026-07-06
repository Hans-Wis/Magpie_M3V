# S1 RMSNorm + Residual — Architecture Judgment

## 1. Fixed-point `rsqrt` (ADR-0062)

**Pick (b): normalized mantissa + Horner polynomial.** Not Newton–Raphson.

| Criterion | Polynomial | Newton–Raphson |
|---|---|---|
| Step count | Fixed (normalize + 3–4 MACs) | Depends on K + per-iter rounding |
| rv32im cost | 32×32→64 muls only | Same, but 2–3× more, order-sensitive |
| Bit-exact | One rounding table in ADR | Easy to diverge on `>>` vs `/2` |

**SSOT contract (NumPy `int` ≡ C):**

```
Input:  arg_q   UQ48.16  (unsigned int64), arg_q > 0
Output: y_q    UQ0.31   (uint32),  y ≈ rsqrt(arg_real)  where arg_real = arg_q / 2^16

1. e = 47 - clz(arg_q)                    # exponent, 0..47
2. m = (arg_q << (e + 1)) >> 16           # UQ1.15 mantissa in [65536, 131071] ⊂ [1,2)
3. f = m - 65536                          # UQ0.16 fraction in [0,1)
4. y_m = horner(f, c3,c2,c1,c0)           # all coeffs int32 Q0.31; each MAC:
                                           #   acc = (acc * f + ci + 2^15) >> 16  (round-half-up)
5. y_q = y_m >> (e >> 1)                  # if e even
        = (y_m * 46341 + 2^15) >> 16       # if e odd; 46341 = round(1/sqrt(2) * 2^16)
        >> ((e+1) >> 1)                    # then arithmetic shift
6. if arg_q == 0: illegal / saturate (gate must hit this)
```

- **No NR refinement** — int8 requant absorbs ≤1 ULP of Q0.31 error if coeffs are Remez-fit on `[1,2)` with max error `< 2^-28`.
- **Initial estimate = polynomial itself** (no separate LUT seed); optional 256-entry `y0` LUT only saves cycles, not needed for correctness.
- **Coefficients**: 4-term Remez, stored in `.rodata` at `0x1000`; golden imports same `rsqrt_coeffs.h` / YAML SSOT.

Polynomial is the simplest path to byte-identical reproduction.

---

## 2. Scale + `eps` folding

**Per row (hidden = H):**

```
sum_sq   = Σ a_i²                     # int32
mean_sq  = sum_sq // H                # floor div — SSOT, not round
```

**Fold `s_a` and `eps` into one `rsqrt` argument (real domain):**

```
arg_real = mean_sq · s_a² + eps
arg_q    = mean_sq * SA2_Q + EPS_Q     # int64
SA2_Q    = round(s_a² · 2^16)          # uint32, SSOT per layer
EPS_Q    = round(eps · 2^16)           # = 66 for eps=1e-6 (not 0)
```

**Chain after `rsqrt`:**

```
t_i = (a_i * y_q) >> 15               # int32; y_q is UQ0.31
```

Do **not** multiply by `s_a` again — it is already inside `arg_q`. That is the whole point of folding.

**Does `eps` matter?** Yes, honestly:

| Case | `mean_sq` | Without `EPS_Q` |
|---|---|---|
| All-zero row | 0 | `rsqrt(0)` → ∞ / wrong |
| Tiny activations | 0–2 | bias in norm gain |

At `s_a ≈ 1/128`, `eps` dominates only when `mean_sq = 0`. For `mean_sq ≥ 1`, `EPS_Q / (mean_sq · SA2_Q)` is negligible in int8 output — but the gate **must** include `mean_sq = 0` corners; dropping `eps` is green-wash.

**`s_x` (output scale of normed activations):** derive offline from max row dynamic range after `(1+w)` multiply; store as SSOT constant, not computed at runtime.

---

## 3. `(1+w)` weight quantization

**Use int16, not int8.**

```
(1+w)_real = ONE_PLUS_W_Q[i] / W_DEN
ONE_PLUS_W_Q[i] = round((1 + w_fp32[i]) * W_DEN)
W_DEN = 2^14   # Q2.14, range ~[0, 4)
```

- Per-channel, length = hidden = 64; `.rodata` ~128 B.
- int8 loses too much on `(1+w) ≈ 1.0` — int8 requant error swamps the norm.
- **Scale**: dimensionless; no separate `s_w`. Fold into final requant:

```
acc_i = (t_i * ONE_PLUS_W_Q[i] + 2^13) >> 14    # int32
out_i = sat8( (acc_i * OUT_NUM + 2^15) >> 16 )   # OUT_NUM/2^16 = s_x
```

`OUT_NUM` chosen once offline so max row fits int8 without clip (or clip = honest ERR).

---

## 4. Residual add — reuse generic requant add

**Yes — `MAT_EWISE_ADD_REQUANT`**, mirror of S0 `MAT_EWISE_MUL` contract:

```
# Params (CQ descriptor or CSR): ZP=0, all scales rational Q16
in0: int8 @ s_r     (residual)
in1: int8 @ s_x     (a_normed)
out: int8 @ s_out   (block output)

acc_i = in0_i * R_NUM + in1_i * X_NUM        # int32
out_i = sat8( (acc_i + ROUND_BIAS) >> SHIFT )  # SHIFT,BIAS SSOT offline
```

- **Rounding**: round-half-away (match Gemma/TFLM requant); same as S0.
- **Independent scales** — do not force `s_r == s_x`.
- Firmware: two CQ launches, no scalar loop over hidden.

---

## 5. CQ op split

| Op | Responsibility | Why separate |
|---|---|---|
| **`MAT_RMSNORM`** | row `sum_sq` → `mean_sq` → `arg_q` → `rsqrt_q31` → `×(1+w)` → int8 @ `s_x` | One descriptor per row (seq=4 → 4 launches); hides reduction + poly |
| **`MAT_EWISE_ADD_REQUANT`** | `r + a_normed` → int8 @ `s_out` | Reusable every residual in decoder |

**Do not fuse** residual into `MAT_RMSNORM` — costs TCM if duplicated, kills reuse on other residual sites.

**`rsqrt_q31`**: shared `.text` subroutine (not its own CQ opcode). Called only from `MAT_RMSNORM` microcode / firmware thunk. Coeffs + `SA2_Q`/`EPS_Q` in `.rodata`.

**TCM budget**: seq=4 × 2 ops = 8 CQ descriptors; heavy math in mat_engine / op ROM, firmware = pointer setup + doorbell only (S0 pattern).

---

## 6. S1 gate green-wash guards

1. **Tier-C golden is `int` end-to-end** — `grep` gate fails on `np.sqrt`, `**-0.5`, `float`, `astype(float)`.
2. **Firmware object dump** — no `fsqrt`/`fdiv`/softfloat symbols.
3. **Coefficient hash** — `.rodata` poly coeffs == golden YAML (same as B3 SSOT pattern).
4. **Corner grid must include:**
   - `a = 0` (eps-only `rsqrt`)
   - single `a_i = ±127`, rest 0
   - alternating ±127
   - `w = 0` and `w = max` per-channel
   - `s_r ≠ s_x` residual path
5. **Intermediate dumps** — per row: `sum_sq`, `mean_sq`, `arg_q`, `y_q`, first/mid/last `acc_i` pre-sat8.
6. **Eps sensitivity** — golden with `EPS_Q-1` must fail at least one output byte.
7. **Non-degenerate dims** — `hidden=64`, `seq=4`; gate rejects `H=1` / `seq=1`.
8. **No float RMS in mat_engine** — reduction is integer `sum(a²)` only.

---

## 7. One riskiest pitfall

**The post-`rsqrt` multiply–requant chain** (`a_i × y_q × (1+w)_q → int8`), not the polynomial.

Three signed widths + two rounding points + C's `>>` on negative intermediates (must not occur if all unsigned until final `sat8`, but `a_i` is signed):

```
# WRONG:  (a_i * y_q) >> 15          # a_i signed, y_q unsigned → ternary promotion bugs
# RIGHT:  (int32(a_i) * int32(y_q)) >> 15   # explicit int32 cast both sides
```

**Guard:** ADR-0062 appendix with one worked row (all intermediates as hex literals). Gate compares **every** `int32`/`int64` lane before `sat8`, not just final bytes. One mismatch localizes to rounding point immediately.

---

**Summary:** Q48.16 `arg_q` → UQ0.31 poly `rsqrt` → Q2.14 `(1+w)` int16 → int8 `@ s_x` → `MAT_EWISE_ADD_REQUANT` with `r @ s_r`. Polynomial (b) is the bit-exact choice; `eps` stays as `EPS_Q=66`; biggest pitfall is signed×unsigned shift in the requant chain.
GROK_S1_DONE
