# ADR-0019 — CLINT interrupt extension (MTIP + MSIP) for RTOS readiness

- Status: accepted (design); implementation gated by full re-verification
- Date: 2026-06-10
- Deciders: Claude (PL), Grok (design advice), to be implemented under PL review
- Pairs with ADR-0018 (subsystem). Touches the verified core (csr.v interrupt model) — clean-room + ADR
  + 273-gate/lockstep/arch-test no-regression required before acceptance.

## Context

M1 today has **only MEIP** (external interrupt, `mip[11]`/`ext_pending`). RTOS workloads need a **timer
tick** (MTIP) and **inter-core/software** (MSIP) interrupt, supplied by a **CLINT**. Reuse the first-party
Magpie_X3 CLINT (64-bit mtime/mtimecmp + msip, native `en/addr/wstrb/wdata/rdata` bus).

## Decision (design — per Grok advice, RISC-V priv spec)

1. **CSR bits**: add **MSIP=mip[3]**, **MTIP=mip[7]** (keep **MEIP=mip[11]**); **MSIE=mie[3]**,
   **MTIE=mie[7]** (keep **MEIE=mie[11]**). `mcause`: `0x8000_0003` (MSI), `0x8000_0007` (MTI),
   `0x8000_000B` (MEI). **M-only**: ignore all S/U bits. **`mip[3,7,11]` are CLINT-sourced, read-only to
   CSR writes**; only `mie` is SW-writable. No `mideleg` (all delivery M-mode via existing mtvec direct).
2. **Trap priority**: **MEI > MSI > MTI** (spec). One arbitration point at execute/commit (same as current
   MEIP). If `mstatus.MIE && !in_trap`: take highest-priority `(mip & mie)`; synchronous traps keep current
   precedence. **Gate on valid commit** — never take an IRQ on a flushed/mispredicted op; pending bits stay
   latched; flush must NOT clear `mip` (only CLINT compare/SW clears).
3. **mtime/mtimecmp (Spike-equivalent)**: 64-bit monotonic compare. SW read `mtime` hi→lo→hi (retry on hi
   change); write `mtimecmp` lo-then-hi (arm on hi) to avoid a transient `mtime≥mtimecmp`. **MTIP set iff
   `mtime ≥ mtimecmp`**, cleared when `<`; re-evaluate every tick and every `mtimecmp` write. **Tick rate
   fixed + documented** (1 CLINT tick = 1 core cycle unless explicitly scaled).
4. **Memory map** (= Spike CLINT): base `0x0200_0000`, `msip +0x0`, `mtimecmp +0x4000`, `mtime +0xBFF8`.
   Align Spike `--rtcfreq`/CLINT increment with M1's tick via one shared `timebase` in test metadata.

## Verification (mandatory before acceptance)

- **Highest-risk corner first** (Grok): `mtime` crosses `mtimecmp` on the **exact commit cycle of a
  branch-mispredict flush** (wrong-path insn in WB + pending MTIP + MIE=1) — proves priority, precise
  `mepc`, flush gating, and **16-bit `mepc`** if the IRQ lands on a compressed instruction (hits M1's
  cross-boundary/redirect history hardest).
- Directed CLINT tests (mtimecmp set → MTIP → handler → clear; msip; split-store ordering; WSTRB partial).
- **Spike CLINT per-commit lockstep** (shared timebase) — the authority.
- Full re-run: 273 gates + integration lockstep + arch-test 74/74 + coverage — **no regression**.

## Consequences

- **+** RTOS-capable subsystem (timer tick + SW interrupt) — a major customer capability.
- **−** Interrupt-model change to the verified core; the IRQ-at-flush corner is genuinely delicate (same
  subsystem as the cross-boundary bugs). Not a Spark task; PL-led, fully re-verified.
- Risks (Grok): IRQ one cycle early/late vs Spike commit; mtimecmp split-store ordering; MEIP+MTIP same
  cycle priority; CLINT-reg WSTRB partial writes.
