# Phase-B B3 (carry/borrow) — three-way review + verification record (2026-07-05)

Instrs: `vadc` `vsbc` `vmadc` `vmsbc` (Zve32x). ADR-0055 §6 B3.

## Legs
- **Grok (architecture / spec)**: full §1-§7 encoding + datapath + active-policy +
  legality + beats_op + hookup + golden — archived at
  `docs/reviews/2026-07-05_phase_b3_carry_spec_grok.md`. Implemented verbatim.
- **Spike lockstep (correctness authority)**: `make b3` vs `--isa=rv32imf_zve32x_zvl128b`,
  **178 commits bit-exact**; DUT+Spike trap together at the `vadc.vvm v0,..` (vd==0)
  terminator. Regression: b1/b2/s1/s2/s3/grid/vill + vrand **1324 commits** all green,
  NPU subsystem no regression. Gate: `tests/gates/gate_64_rvv_b3_carry.py`.
- **Gemini (full-context consistency)**: verdict below.

## Gemini review verdict (gemini-3.1-flash, full spec + RTL diff)
Based on a rigorous spec-to-RTL verification of the Phase-B B3 (ADR-0055) carry/borrow implementation in `design/cpu_m1/rtl/vexu.v`, the design is **completely clean**. 

There are no encoding aliasing, legality-matrix holes, LMUL-group edge cases, or tail/mask policy gaps. Here is the architectural sign-off validation for the checklist:

### 1. `vadc`/`vsbc` Spec Conformance
* **Force Active:** `op_adcsbc` is correctly integrated into the elements' `active` wire (`(op_merge || op_adcsbc || vm || m)`). This bypasses the masking predicate and forces execution/updates on all elements $i \in [\text{vstart}, \text{vl})$, while maintaining standard undisturbed behavior for tail elements.
* **Illegalities:** `(op_adcsbc && (vm || (vd_i == 5'd0)))` perfectly intercepts `vm=1` as illegal, and flags `vd == 0` as illegal due to destination/carry-operand overlap on `v0`.
* **No `OPIVI` for `vsbc`:** `op_sbc` is correctly restricted to `is_opivv || is_opivx`, excluding immediate encodings.

### 2. `vmadc`/`vmsbc` Spec Conformance
* **Carry-In / Borrow-In Selection:** `cin` is correctly defined as `vm ? 1'b0 : v0_view[gi]`.
* **Legality Overlaps:** `(op_madcb && !vm && (vd_i == 5'd0))` cleanly restricts the `vd == 0` illegality to only when `vm=0` (which reads `v0` as carry-in). Under `vm=1` (no carry-in), `vd == 0` is allowed and legal.
* **Unsigned Carry-Out (`vmadc`):** Summation `sum = {1'b0, a} + {1'b0, b} + {8'b0, cin}` is zero-extended to `SEW+1` bits, so `sum[SEW]` is mathematically guaranteed to be the exact carry-out.
* **Unsigned Borrow-Out (`vmsbc`):** Subtraction `dif = {1'b0, a} - {1'b0, b} - {8'b0, cin}` in 2's complement on `SEW+1` bits correctly yields $dif < 0 \iff a < b + cin$. The sign bit `dif[SEW]` is exactly `1` when a borrow is generated, avoiding any signed overflow/underflow errors.

### 3. Opcode Mapping and Aliasing
* **Disjoint Encodings:** `op_sbc` (`f6 == 010010`) and `op_msbc` (`f6 == 010011`) are explicitly gated by `(is_opivv || is_opivx)`. This cleanly isolates them from `OPMVV` vzext/vsext (`f3 == 010`) and ensures zero aliasing with other extension groups.

### 4. LMUL-Group & Mask Accumulation
* **Mask Destination Multi-Beat Write-Back:** `mask_dest` (which aggregates `op_cmp || op_madcb`) correctly prevents multi-register group write-back (`q_grp_w`) for multi-beat `LMUL > 1` operations. Instead, individual beat results are accumulated into `grp_mask_acc` via `cmp_seg` (with precise element offset indexing), triggering a single-register destination write-back of `grp_cmp_res` at the final beat boundary.
* **Alignment Checks:** `mask_dest` correctly bypasses destination alignment restrictions since the mask target is always a single register (`v0`-`v31`), while maintaining standard group-alignment validation on multi-register sources `vs2` and `vs1`.

## Notes vs B1/B2
Unlike B1 and B2 (each had review catch a masked-vd0 / vext-overlap legality gap),
B3 landed clean on first pass: the Grok spec already carried the complete §4 legality
matrix and the B1/B2 masked-vd0 lesson was applied proactively (vadc/vsbc vd==0
illegal; vmadc/vmsbc vd==0 illegal only when vm=0). No RTL change resulted from review.

## Scope / latent (roadmap continuity)
- vadc/vsbc/vmadc/vmsbc support LMUL m1 + m2/m4 groups (beats_op / mask accumulation).
  m8 stays deferred-illegal (cfg_illegal), same as the rest of the vexu.
- `vle32.v @ e32/mf2` latent (Section D) is unrelated to B3 (vsetvli/vmem fractional-LMUL).
