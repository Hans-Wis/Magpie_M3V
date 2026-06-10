# ADR-0016 — Compressed HINTs execute as NOP; reserved compressed trap

- Status: accepted
- Date: 2026-06-09
- Deciders: Claude (PL), Grok (advisor, two rounds incl. a correction)
- Found via: Spyglass W528 `cdec_illegal` set-but-not-read → investigation revealed a behavior bug.

## Context

`cdec.v` (RV32C → 32-bit expander) outputs an `illegal` flag and an `expanded` instruction. In `core.v`,
every cdec `illegal=1` case left `expanded` at its init `32'h0`; `idu` (`illegal = !known_opcode`) treats
opcode 0 as illegal → so **all** of cdec's `illegal=1` encodings actually trap via the idu path
(`cdec_illegal` itself was unused — the W528).

Reading cdec.v line-by-line showed the real problem was **not** "reserved don't trap" (an earlier,
imprecise framing): reserved/out-of-scope encodings already trap correctly via `expanded=0 → idu`. The
bug was that **compressed HINTs were lumped into the same `illegal=1` path and therefore trapped**, but
per the RISC-V Unprivileged C-extension, **HINTs must execute as NOP (no exception)**.

The HINT encodings wrongly trapped: `C.LI rd=0`, `C.SLLI rd=0`, `C.MV rd=0`, `C.ADD rd=0`. (`C.ADDI/C.NOP
rd=0` was already expanded correctly.) Reserved (must trap) and out-of-scope (RV64/FP, illegal in RV32IMC)
were already correct.

## Decision

1. The 4 HINT encodings **expand to their natural `rd=x0` form (a NOP)**, `illegal=0` — they no longer
   trap. (cdec.v.)
2. **Reserved** compressed (C.ADDI4SPN/ADDI16SP/LUI reserved imm/rd, SRLI/SRAI/SLLI shamt≥32, C.LWSP rd=0,
   C.JR rs1=0) and **out-of-scope** (C.FLD/FSD, C.SUBW/ADDW) **stay illegal → trap** (via `expanded=0 →
   idu`, unchanged).
3. `cdec.illegal` is **not** wired into a second architectural trap path (Grok: redundant with idu, adds
   pipeline timing for no functional gain). It is retained as a **checked unit-TB output** + a **sim-only
   invariant assertion** in core.v (`cdec_illegal → cdec_expanded==0`). This resolves the W528 and keeps
   defense-in-depth without a redundant trap.

## Consequences

- **+** Spec-correct C-extension HINT behavior (NOP, not trap). Improves Spike `rv32imc` lockstep
  agreement (Spike NOPs hints, traps reserved — DUT now matches on both).
- **+** No redundant trap path / timing cost.
- **−** Behavior change on the 4 HINT encodings (trap → NOP). Verified by updating the P10 golden to the
  spec behavior + directed vectors (hints → NOP, reserved → illegal) + full-suite / lockstep re-verify.
- HINTs are rare in compiled code / random DV, so no existing lockstep test exercised the divergence
  (which is why it passed before) — but it is a real spec gap closed before claiming full C-ext compliance.

## Addendum (2026-06-09): C.LUI rd=x0 is also a HINT (riscv-arch-test clui-01)

The official `riscv-arch-test` RV32C suite (run for §06 commercialization) caught a 5th HINT that the
original ADR-0016 fix missed: **C.LUI with rd=x0 (and imm≠0) is a HINT** (executes as `lui x0,imm` = NOP),
not illegal. M1 was trapping it (cdec.v C.LUI arm `if (rd_rs1_5==0) illegal=1`), diverging from Spike,
which retires it. Fix: C.LUI is illegal only for imm=0 (reserved, any rd); rd=0 with imm≠0 expands to
`lui x0,imm` (NOP). Golden (tb_cdec_unit) mirrored; P10 cdec 68/68, full suite green. RV32I/M arch-test
were already 100%; this closes one of the 3 RV32C failures (the other 2 are a separate cross-boundary PC
bug, see docs/reports/findings/). Lesson: official compliance catches hint/reserved corners that Spike-
lockstep over directed+riscv-dv stimulus did not exercise.
