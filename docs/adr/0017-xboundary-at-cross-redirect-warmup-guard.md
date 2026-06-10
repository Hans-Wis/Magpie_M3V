# ADR-0017 — `at_cross_boundary` must be gated off during `redirect_warmup`

- Status: accepted
- Date: 2026-06-09
- Deciders: Claude (PL, root-cause review + independent verify), Codex (VCD debug + minimal fix)
- Found by: official `riscv-arch-test` RV32C (cbnez-01, cj-01) during §06 commercialization — NOT caught
  by Spike-lockstep over directed + riscv-dv stimulus or per-island coverage.

## Context

`core.v`'s RV32C cross-boundary prefetch has three sibling signals that detect a 32-bit instruction
straddling a 4-byte boundary at a high-half PC (`PC[1]=1`):
- `upcoming_cross` (predictive, low-half 16-bit followed by high-half 32-bit) — guarded `!redirect_warmup`.
- `consecutive_cross` (back-to-back cross-boundary) — guarded `!redirect_warmup`.
- `at_cross_boundary` (fallback: arrived at a cross-boundary without pre-setup) — **was NOT guarded**.

`redirect_warmup` is the 1-cycle refetch bubble after a branch/jump redirect (`redirect_warmup <=
pc_redirect`), during which `i_mem_rdata` still holds the **stale pre-redirect word** until the BRAM
catches up to the redirected PC.

## Problem (VCD-confirmed, cbnez-01 @ 1145 ns)

After a compressed branch redirect to `if_pc=0x1416` (a 32-bit instr at a high-half PC), `redirect_warmup=1`
but `i_mem_rdata=0x006f0011` was still stale. `is_comp_hi` was computed on that stale data, so the unguarded
`at_cross_boundary` fired and armed `residue=0x006f` from garbage. The next cycle `cross_assemble` assembled
`instr_assembled=0x0020006f` (a bogus JAL) instead of the real `0x0020aa23`; that ghost JAL redirected to
`0x1418` and `is_16bit_w=1` on the low half `0x0020` retired a ghost word `0x00000020` — i.e. next-PC went
`0x1416 -> 0x1418 (+2)` instead of `-> 0x141a (+4)`. Same mechanism in cj-01.

## Decision

Add `!redirect_warmup` to `at_cross_boundary`, making it consistent with its two siblings:
```verilog
wire at_cross_boundary = cur_at_high && !is_comp_hi && !cross_assemble && !redirect_warmup;
```
During `redirect_warmup` the fetched word is stale, so the fallback cross-boundary FSM must not arm the
residue. After the warmup cycle (when `i_mem_rdata` is the correct redirected word), a genuine
cross-boundary re-arms `at_cross_boundary` correctly.

## Consequences

- **+** RV32C now passes official `riscv-arch-test` **27/27** (cbnez-01 + cj-01 fixed; clui-01 fixed
  separately under ADR-0016 addendum). With RV32I 39/39 + RV32M 8/8, M1 is **RV32IMC arch-test 74/74**.
- **+** Minimal, clean-room: completes the existing `redirect_warmup` discipline (the other two
  cross-boundary signals already had this guard); no new state, no timing cost.
- **−** Behavior change only in the previously-buggy stale-data window. Verified: full gate suite
  273 pass/1 xfail (no regression), cbnez-01/cj-01/clui-01 Spike-lockstep pass, the existing
  cross-boundary directed/lockstep gates (P14 ifu, P16 IF, 03_*) unchanged.
- **Lesson** (3rd time this campaign): official compliance + formal catch corners that lockstep-over-
  random-stimulus does not. cross-boundary residue + redirect interaction is a recurring hot-spot
  (BUG-XBOUND-0001, this) — any new fetch/redirect signal must respect `redirect_warmup`/`warmup`.
