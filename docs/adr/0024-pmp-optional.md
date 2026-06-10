# ADR-0024 — Physical Memory Protection (PMP, optional)

- Status: accepted (design); implementation gated by no-regression + PMP directed + per-config matrix
- Date: 2026-06-10
- Deciders: Claude (PL), Grok (M1 design + timing), Gemini (spec + ibex). PMP RTL **adapted from ibex
  `ibex_pmp.sv`** (Apache-2.0, license-compliant ADR-0001; origin=adapted) + RISC-V Priv spec. **Optional**.

## Context (M-only value)

M1 is M-mode-only, so PMP is not S/U access control today. Its value: the **`L` (lock) bit** locks regions
**from M-mode itself** (write-protect code/ROM, restrict MMIO, brick-proofing) and prepares for a future
S/U bring-up. `PMP_ENTRIES=0` = today's flat M-mode (no PMP).

## Decision

- **CSRs**: `pmpcfg0..N` (RV32: 4 entries/reg, 8-bit field `L|00|A[1:0]|X|W|R`), `pmpaddr0..M`. **MVP =
  `PMP_ENTRIES=8`** (4 too tight for ROM+RAM+MMIO+stack). Lowest-index matching entry wins.
- **Address modes** A: OFF(0) / TOR(1, `addr[i-1] ≤ x < addr[i]`) / NA4(2, 4 B) / NAPOT(3, ≥8 B encoded
  in pmpaddr low bits).
- **Checks**: **IF** — X-permission on the fetch PC → instruction access fault **mcause=1**. **MEM** —
  R on load → **mcause=5**, W on store → **mcause=7**. **M-mode bypasses unless `L=1`**.
- **Timing (protect Fmax, Grok)**: recompute region bounds **on pmpcfg/pmpaddr write** (registered); at
  runtime do a **registered-address 1-cycle-early compare → kill/redirect** (like a branch mispredict),
  NOT a combinational check on `pc+4`. `mtval` = the faulting address.
- **AMO**: check **each beat** (load beat = R, store beat = W); an SC-fail skips the store check.
- **Debug**: the `dm_acc` abstract path is GPR/CSR only (no PMP). A future system-bus debug access bypasses
  PMP per the Debug spec.
- **Optional**: parameter **`PMP_ENTRIES` (0/4/8)**. `0` → no pmp CSRs (read 0, writes ignored), no check
  logic generated — bit-identical to today.

## Verification
- **Highest-risk corner first** (Grok): a **fetch PMP fault on an RVC / cross-boundary instruction** —
  precise `mepc` = the faulting instruction's PC (same hot-spot as the cross-boundary bugs). Also the
  **`L`-lock-misconfig brick** case (document the recovery = reset, since locked M can't rewrite pmpcfg).
- Directed: each mode (TOR/NA4/NAPOT) R/W/X allow+deny → access fault mcause 1/5/7, mtval=addr; the L-lock
  applies to M; lowest-index priority.
- **Per-config matrix**: full gates + arch-test pass at `PMP_ENTRIES=0` (no regression) AND `=8`
  (+ PMP directed). riscv-arch-test PMP if available.

## Consequences
- **+** Memory protection (code/MMIO lock) + S/U-ready foundation — a Priv-spec feature customers expect.
- **+** Reuses ibex's proven per-channel PMP match (Apache, adapted with attribution).
- **−** A permission check on **every fetch + load/store** — must use the registered 1-cycle-early compare
  to avoid an Fmax hit; touches IF + MEM + csr + trap. PL-led; full re-verify + Fmax re-check (DC).
