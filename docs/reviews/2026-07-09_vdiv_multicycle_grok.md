## Architecture judgement — multi-cycle vdiv in vexu

**Verdict:** Option A is sound if nested carefully. Magnitude+fixup is bit-exact with `sov`/`bz` overrides. Main kill risks are FSM nesting (last-part / drained-start) and flush mid-divide, not signed arithmetic.

---

### 1. FSM integration — Option A

**Sound in principle.** One shared `div_it` that gates *both* LMUL=1 commit and VM_GRP part-advance is the right structure: one ownership model for “when is this beat’s result ready?”

**Nesting hazards (concrete):**

| Hazard | What breaks | Fix |
|---|---|---|
| **Double-advance** | `VM_GRP` currently does `grp_stage[grp_p] <= part_res; grp_p++` every non-stall cycle. If `div_busy` is only OR’d into a *pipe* stall but `!m_stall` still true in vexu’s own FSM, you advance every cycle with garbage/partial `part_res`. | Gate **both** `grp_stage` capture and `grp_p++` on `div_done` (or equivalently: treat `div_busy` as local hold so the VM_GRP body does not fire until done). Same for LMUL=1: hold `q_wdata`/commit until `div_done`. |
| **Double-count / restart** | Entering a new part (or LMUL=1 start) without resetting `div_it` → short divide or wrap. Restarting every cycle while “busy” → never finishes. | On beat start: `div_it=0`, load mag operands from that part’s `vs2/vs1` slice. Increment only while busy. Clear busy when `div_it==SEW` *and* capture happens. |
| **Off-by-one last part** | `div_done` asserted one cycle late → extra hold forever, or one cycle early → capture pre-final restore → wrong last register of LMUL group (silent lockstep fail, not hang). | Define: after SEW restore steps, result is stable; *that same cycle* may capture+advance, or capture on `div_done` and advance next — pick one and keep LMUL=1 identical. Prefer: `div_done = (div_it == SEW-1)` after the last subtract, or count 0..SEW-1 and done after SEW increments — match scalar `div.v`. |
| **Drained-start** | Contract: nothing else vector in flight until WB group commit. Multi-cycle hold *extends* drain; it must not re-open issue or allow a second `m_start` into vexu. | Keep `vm_active` true for entire `k·SEW` window; `div_busy` ⊆ `vm_active` (or LMUL=1 synthetic hold). Do **not** drop `vm_active` between parts. |
| **Operand freeze** | If `vs2_data`/`vs1`/`scalar_b`/`vsew` retime while iterating, mid-part corruption. | Latch per-beat operands (or rely on drained-start freeze — document which). Mask/`vd_old` for inactive lanes can stay combinational *after* registered mag result. |
| **`part_res` source** | Today combinational. After change, `part_res` for vdiv must be the **registered** post-fixup result, not a combo path that still has `/`. | Mux `part_res` from divider regs only when `op_vdivr`. |

**LMUL=1 path:** Today not in VM_GRP. You need either a tiny local hold state or force vdiv into a “single-part group” so only one advance path exists. Prefer **one path** (vdiv always uses the same div FSM; LMUL=1 = `grp_parts==1` or a dedicated `div_busy` with no `grp_p`) to avoid two slightly different done conditions.

**Option A is OK** if: `div_done` is the *only* enable for beat commit/advance, `div_it` resets per beat, flush clears both `div_*` and `vm_*`.

---

### 2. Signed magnitude + fixup vs Verilog `as/bs`, `as%bs`

**Provably identical for all cases that are not `bz`/`sov`, if magnitude is defined correctly.**

RISC-V (and Verilog signed `/` `%` toward zero):

- `q = trunc(a/b)` toward 0  
- `r = a - q·b` → `sign(r) == sign(a)` (or r=0)

Fixup:

- `sdiv = (sa^sb) ? -qmag : qmag`  
- `srem = sa ? -rmag : rmag`  

with `qmag = |a|/|b|`, `rmag = |a|%|b|` **unsigned**.

**MIN overflow:** For SEW-bit two’s complement, `|MIN|` is **not** representable as a signed SEW value (`-MIN` overflows). In *unsigned SEW* width:

- `|0x80| = 0x80`, `|0x8000| = 0x8000`, `|0x8000_0000| = 0x8000_0000`  
  as **unsigned** magnitudes — valid. Divider must take **unsigned SEW** inputs, not “negated signed into signed”.

**Cases where `|as|` “overflows” in signed sense:**

| Case | Without override | With current RTL |
|---|---|---|
| `MIN / -1` | qmag = MIN (unsigned), `-qmag` is MIN again in SEW wrap; true math q = +2^{W-1} not representable → must be **sov** → MIN, rem 0 | **sov catches** |
| `MIN / +1` | qmag = MIN, signs same → sdiv = MIN. Correct (MIN/-1 is the only overflow quot). rem 0. | OK without sov |
| `MIN / k` (k∉{0,-1}) | unsigned mag divide correct; rem sign = sign(a) = 1 → `-rmag` if needed | OK |
| `a / 0`, `a % 0` | mag path must not run free | **bz** overrides |

**No residual hole:** Every case where signed SEW quotient is non-representable is **only** `MIN/-1` → `sov`. Div-by-zero is `bz`. Other negatives are fine in unsigned SEW magnitude.

**Implement carefully:**

- `dvd_mag = sa ? (0 - a) : a` in **unsigned** SEW (two’s complement negate); for `a==MIN`, yields `MIN` bit pattern — correct for unsigned div.  
- Do **not** use `$signed(-as)` into a signed SEW type for mag.  
- Fixup negate: same modular negate; for non-sov results `|q| < 2^{W-1}` or q=0, so `-qmag` is fine; sov never uses this path.  
- **Order:** compute mag path always *or* mux final `r` as today: `bz` / `sov` / fixup. Prefer **still override after** so a buggy mag path cannot poison specials.  
- Inactive lanes: still `vd_old` (mask/vstart) — don’t “divide” them into WB.

**Bit-exact risk if:** SEW+1 partial remainder width wrong, non-restoring vs restoring mismatch, or signed negate of MIN fed as *signed* dividend without `sov`. With unsigned mag + sov/bz: **safe**.

---

### 3. Cycle budget / deadlock / flush

**Budget:** LMUL=1 → SEW; LMUL=k → k·SEW. No architectural hang if `div_it` is a free-running counter to SEW gated only by `div_busy`.

**Hang risks (must fix in design):**

1. **`div_done` never true** — wrong SEW decode, `div_it` not clocked when “stalled”, or compare `div_it==SEW` with counter that only goes to SEW-1.  
2. **`div_busy` raises stall that freezes `div_it`** — classic deadlock: stall stops the counter that would clear stall. **Counter must advance on `div_busy && !m_flush` even if outer `m_stall` is asserted *because of* div**, or use a separate “div progress” enable.  
3. **Flush mid-divide** — `m_flush` must clear `div_it`, `div_busy`, VM_GRP state (already resets `vm_state`/`grp_p`). Leaving `div_busy` stuck high after flush → permanent stall.  
4. **vstart/mask** — not multi-cycle hazards if evaluated once per part from frozen views; inactive elements write `vd_old`. No extra FSM.  
5. **vl==0 / vstart≥vl** — existing `vm_none` early done; must **not** enter div (0 cycles).  
6. **Wrong-path + re-issue** — after flush, next `m_start` must see clean div state.

**Not a problem:** mask/vstart “in flight” mid-divide if drained-start holds operands; there is no mid-op mask change architecturally.

**Deadlock guard:** assert/timeout `div_busy && div_it` progress each cycle; sim `gate_force`-style max latency `k*32`.

---

### 4. Per-lane parallel vs one shared sequential divider

| | **16-lane parallel (proposed)** | **1 shared, lane-serial** |
|---|---|---|
| Latency | SEW (or k·SEW for LMUL) | up to 16·SEW (·k) |
| Area | 16× (SEW+1)-bit subtract/reg | 1× wider reuse |
| Bit-exact risk | Low if all lanes identical RTL | **Higher** — lane index vs mask/vstart/active, scalar broadcast, which lanes skip, ordering of `vd_old` merge |
| CP | Shallow; Fmax goal met either way | Same depth, worse throughput |
| Verification | Matches current per-lane structure | New sequencing bugs in golden corners |

**Recommendation:** keep **per-lane parallel bit-serial** (proposal). Lower risk for bit-exactness because it preserves the existing per-element generate structure and only replaces `/` `%` with iterative mag. Shared sequential is an area optimization for a rare op — not worth correctness surface.

(If area bites later: shared is OK only with a frozen active-lane bitmap and identical special-case mux per element result.)

---

### 5. Zve32x / Spike legality flags (before RTL)

Not divide-algorithm issues — decode/CSR traps that break lockstep if ignored:

- **EEW = SEW only** for vdiv/vrem; no widening. Illegal `vsew`/encodings → trap before EX (match Spike).  
- **vstart ≠ 0:** legal for arithmetic; elements `< vstart` undisturbed. Multi-cycle must not rewrite them.  
- **Mask + tail/body:** tail undisturbed (or agnostic — your core’s policy must match Spike/config); body inactive → `vd_old`.  
- **LMUL fractional / group overlap:** `vd` overlap with `vs1`/`vs2` legality is upstream; multi-cycle doesn’t change it but longer EX means more pressure on “drained” assumption — keep drain.  
- **`vdiv`/`vrem` vs `vdivu`/`vremu`:** same datapath, op mux after mag — Spike specials only on signed.  
- **÷0 / overflow:** already match RISC-V-V (all-1s quot, rem=dividend; MIN/−1 → MIN, rem 0). Don’t “fix” to IEEE or x86.  
- **No FP,** no `vxrm` effect on integer div.  
- **LMUL>1 part mapping:** element indices continuous across parts; `elem_base` / mask shift must stay aligned when part stays multi-cycle (mask_dest path in VM_GRP — vdiv is not mask-dest, but don’t regress the shared VM_GRP body).  
- **Illegal for non-unit-stride mem** is unrelated; don’t conflate.  
- **Spike probe:** MIN/−1, ÷0, `vl` mid-group, `vstart` mid-group, LMUL=8 SEW=32 (4 elems/part × 8 parts × 32 = 256 cycles worst) for timeout only.

Nothing Zve32x-specific forbids multi-cycle integer div; correctness is **value + exception identity**, latency free.

---

### Would make it NOT bit-exact or NOT terminate

| Flag | Severity |
|---|---|
| VM_GRP advances every cycle while divider still iterating | **Wrong results / not exact** |
| `div_busy` stalls the same clock enable as `div_it` | **Deadlock (no terminate)** |
| `m_flush` leaves `div_busy` set | **Hang** |
| Signed mag via signed SEW negate without unsigned cast; missing `sov` | **MIN cases wrong** |
| Capture `part_res` before final restore step (off-by-one) | **Silent mismatch** |
| LMUL=1 and VM_GRP different done/SEW counts | **Intermittent LMUL fails** |
| Active mask applied *inside* divider state across parts incorrectly | **vstart/mask fail** |

---

### Bottom line

- **Option A: yes**, with strict rule: **`div_done` alone enables part/LMUL commit; `div_it` free-runs under `div_busy`; flush clears all.** Unify LMUL=1 with the same hold.  
- **Mag+fixup: yes bit-exact** with unsigned SEW magnitude + existing **sov/bz** overrides; no uncaught MIN overflow class.  
- **Hang:** only from stall/counter coupling or flush sticky busy — design those two explicitly.  
- **Prefer lane-parallel** over shared sequential for exactness risk.  
- **Legality:** standard RVV arithmetic + Spike specials; no extra multi-cycle trap — verify vstart/mask/vl=0 and don’t re-open issue during drain.

**Approve to implement** with the FSM nesting and stall-enable notes as hard requirements in the ADR/RTL checklist; not a pure drop-in of `/` → iterative without re-gating `VM_GRP`.
