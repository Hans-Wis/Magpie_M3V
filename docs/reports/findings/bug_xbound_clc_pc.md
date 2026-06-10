# FINDING — cross-boundary next-PC bug after a compressed branch/jump (riscv-arch-test cbnez-01 / cj-01)

- Severity: **real RV32C correctness bug** (PC/flow). Found by official `riscv-arch-test` (§06), NOT
  caught by Spike-lockstep over directed + riscv-dv stimulus or per-island coverage. Flagged for human
  review (delicate cross-boundary RTL — clean-room + ADR; do NOT hand to Spark per project guidance).
- Date: 2026-06-09. Authority: Spike per-commit lockstep (rv32imc) as golden.
- Status: **RESOLVED 2026-06-09 (ADR-0017)** — was UNFIXED — repro below; awaiting go-ahead. (Sibling bug clui-01 = C.LUI-rd0-HINT, already
  fixed under ADR-0016 addendum; this finding is the *separate* 2nd RV32C bug.)

## Symptom

Two arch-test RV32C tests diverge from Spike at the same root cause: a **32-bit instruction located at a
high-half address (PC[1]=1, i.e. it straddles a 4-byte boundary)**, reached after a compressed branch/jump
path, computes the **wrong next-PC (+2 instead of +4)** and retires a **ghost instruction** (`instr=0x00000020`).

### cbnez-01 — first divergence at commit 68
```
prev instr: 32-bit  sw sp,20(ra)   at high-half PC = 0x1416   (straddles 0x1416..0x1419)
Spike:  next retire  pc=0x141a  instr=ffb00413 (addi x8,x0,-5)   wdata=fffffffb
DUT:    next retire  pc=0x1418  instr=0x00000020 (GHOST)  rd=x8  wdata=ff76df6c
        -> DUT advanced PC by +2 (0x1416->0x1418) instead of +4 (->0x141a)
```

### cj-01 — first divergence at commit 42
```
prev instr: 32-bit  sw sp,4(ra)    at high-half PC = 0x1552
Spike:  next retire  pc=0x1556  instr=0100006f (jal ...)
DUT:    next retire  pc=0x1554  instr=0x00000020 (GHOST)
        -> DUT advanced 0x1552 -> 0x1554 (+2) instead of -> 0x1556 (+4)
```

## Suspected root cause (for the reviewer)

The fetch/PC path mis-handles a **32-bit instruction whose low half sits at a high-half address (PC[1]=1)
*after a compressed-instruction-driven redirect* landed the PC on an odd halfword**. The 4-byte instr is
assembled across the 2-byte boundary (cross-boundary prefetch / residue path), but:
1. the **next-PC increment** treats the instr as 16-bit (+2) instead of 32-bit (+4), and
2. the fetch returns a **ghost word `0x00000020`** (a residue/assembly artifact) at the wrong PC.

This is the same subsystem as BUG-XBOUND-0001 (cross-boundary 32-bit assemble + residue buffer in
`ifu`/`core`) but a distinct manifestation: the trigger is a compressed branch/jump (`c.bnez`/`c.j`)
redirecting to an odd halfword, after which the *following* 32-bit instruction's size/next-PC is wrong.
Likely sites: the `is_16bit_w` / `pc_inc` (+2/+4) selection and the `cross_assemble` / residue handoff in
`core.v` around the IF/EX boundary, when `pc_redirect` from a compressed branch lands on PC[1]=1.

## Repro

```
cd flow/v2_pipeline/phase_p_archtest
# build + run cbnez-01 / cj-01 on M1 (Verilator) with commit trace, compare to Spike rv32imc:
#   DUT commit trace vs spike --log-commits ; first mismatch at commit 68 (cbnez) / 42 (cj)
```
Triage detail + traces: `.run/archtest_triage/`. RV32I 39/39 + RV32M 8/8 PASS (harness correct); RV32C
24/27 before the clui fix, 25/27 after — these 2 remain.

## Proposed disposition (reviewer to decide)

Delicate cross-boundary fix in `ifu`/`core.v` (next-PC +4 for a 32-bit instr at PC[1]=1 after a compressed
redirect; correct the residue/assemble so no ghost word). Needs: clean-room RTL + ADR + re-verify (P14
ifu / P16 IF integration coverage + Spike lockstep on cbnez-01/cj-01 + full suite + no regression on the
176+ gates). NOT a Spark task. Recommend: fix after the user reviews this repro.


## RESOLUTION (ADR-0017)
Root cause (VCD): `at_cross_boundary` fired during `redirect_warmup` on STALE i_mem_rdata, arming the residue with garbage. Fix: `at_cross_boundary &&= !redirect_warmup` (one line, completing the guard its siblings upcoming_cross/consecutive_cross already had). Verified independently: RV32C 27/27, arch-test 74/74 (100%), full gate suite 273 pass/1 xfail, no regression.
