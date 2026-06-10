# FINDING — reserved compressed instructions do not trap (`cdec_illegal` unwired)

- Severity: **real spec gap** (functional), not just a lint warning. Flagged for user decision (touches behavior + spec).
- Found via: Spyglass W528 `cdec_illegal` set-but-not-read (core.v:146), investigated 2026-06-09.
- Advisor: Grok (spec); not auto-fixed per the "escalate on spec/behavior" rule.

## What

`cdec.v` outputs an `illegal` signal, but `core.v` instantiates `cdec u_cdec(.illegal(cdec_illegal))`
and **never uses `cdec_illegal`**. Illegal-instruction trapping relies only on `id_illegal` from `idu`
(`assign illegal = !known_opcode`).

`cdec` sets `illegal=1` for three different classes, and for some it ALSO produces a valid `expanded`
32-bit instruction:
- **Reserved compressed** (e.g. `C.ADDI4SPN imm=0`, reserved `C.*` combos): `expanded` is a valid-looking
  insn → `idu` does NOT flag it → **executes instead of trapping**. ← the bug.
- **HINT** (e.g. `c.*` with `rd=0`, comment "hint (skip)"): per spec, HINTs execute as **NOP**, no trap.
- **RV64/FP-only** (C.FLD/FSD, SUBW/ADDW — out of RV32IMC scope): `expanded` stays `32'h0` → `idu`
  catches opcode 0 as illegal → already traps. OK.

## Why it matters (spec)

Per the RISC-V Unprivileged C-extension, **reserved compressed encodings must raise an illegal-instruction
exception (mcause=2)** — they must not execute as a 32-bit expansion. HINTs, conversely, must be NOP and
must **not** trap. The current RTL conflates these in `cdec_illegal`, and wires neither.

**Spike risk:** Spike traps reserved compressed and NOPs hints. So a reserved encoding that today
expands+runs is a **latent Spike-lockstep divergence** (random DV may rarely hit it; a directed test
will). HINTs are likely already OK (NOP via expansion).

## Recommended fix (Grok-advised) — pending user decision

1. `cdec.v`: stop marking HINTs as `illegal`; introduce a **reserved-only** `cdec_reserved_illegal`.
2. `core.v` trap path: `illegal = id_illegal | cdec_reserved_illegal` (at the compressed-decode boundary,
   before execute treats the expansion as real).
3. RV64/FP reserved (expanded=0) — leave as-is (`id_illegal` already catches).
4. Add a **directed Spike-lockstep test** (reserved compressed patterns) + a short **ADR**
   ("compressed reserved → trap at cdec; hints → NOP, no trap").

Not P0 vs BUG-XBOUND-0001, but a **real spec gap to fix before claiming full C-extension compliance or
scaling lockstep**. Do NOT blindly `OR cdec_illegal` (would wrongly trap HINTs).

## Status

UNWAIVED in Spyglass (kept visible). The other 23 lint warnings were reviewed + waived/cleaned. Awaiting
user go-ahead to implement the reserved-vs-hint split (RTL + golden + directed test + ADR + lockstep re-verify).
