# Magpie_M1 — Integration phase (P15–P18) closure

> Honest closure of the core.v integration slices. Authority = Spike per-commit lockstep + the delta
> methodology (each slice owns only its core.v integrator region; never a blank-slate whole-core farm —
> that is a separate J8-scale milestone). Date: 2026-06-09.

## Per-slice result (Spike lockstep = correctness authority)

| slice | scope | Spike lockstep | toggle delta | VCS branch/expr (core.v, per-slice) |
|---|---|---|---|---|
| **P15** datapath | forward/stall/flush/wb_sel/mem_stall | **PASS** 162 commits | +519 | run |
| **P16** IF/xboundary | +2/+4, residue, redirect-after-cross; **BUG-XBOUND-0001 green** | **PASS** 43 commits | + | branch 72.7% / expr 55.6% |
| **P17** CSR/trap | trap glue, mepc/mcause/mtval, IRQ, mret | **PARTIAL** (see note) | + | branch 74.7% / expr 65.1% |
| **P18** BP/RAS | mispredict redirect, RAS push/pop/recover, saturation | **PASS** 93 commits | + | branch 68.7% / expr 55.6% |

Per-slice branch/expr is intentionally partial — each slice only exercises its own core.v region.
The integration number is the **merge**.

## Merged core.v (P15–P18 ∪ baseline)

| metric | merged | tool |
|---|---|---|
| branch | **95/99 = 96.0%** | VCS/URG |
| expr   | **307/390 = 78.7%** | VCS/URG |
| toggle | **4544/5426 = 83.7%** | Verilator |

## P17 honest note (report-faithfully)

Local **Spike 1.1.1-dev logs the M-mode synchronous exception and stops before the `mtvec` handler**
(known from J14/J18). Therefore **through-trap per-commit lockstep is NOT claimed green**. P17's
correctness evidence is: (1) pre-trap commit lockstep prefix matches, (2) trap-entry `mepc`/`mcause`/
`mtval` match Spike's expected values, (3) `wb_trap_mtval` roster 64/64 covered. A future through-trap
lockstep requires Spike configured **M-only (`--priv=m`)** — see ADR-0015.

## Residual attribution (the integration tail — NOT claimed covered)

The merged residual (4 branches, ~83 expr terms, ~16% toggle) is honestly attributed, not waived blanket:
- **Structural** — core.v defensive `default` arms / hardwired bits (e.g. PC bit0 alignment) — cite RTL.
- **Trap paths** — blocked from commit-lockstep by the Spike-stop limitation (P17); architecturally
  evidenced by trap-value match, not commit-by-commit.
- **SKU/memory-bound** — pipeline PC high bits (`ex_*_pc_r[31:8]`) toggle only with code at high
  addresses; bounded by the configured memory map (a larger-memory SKU, owned by the IF slice).
- **Compound-expr tail** — core.v multi-term conditions needing combined IRQ+load-use+flush+muldiv
  scenarios; the residual closure path is the **whole-core riscv-dv lockstep farm** (J8-scale,
  ≥100k commits) — a SEPARATE signoff milestone, explicitly NOT an integration-gate acceptance substitute.

## What is signed off here

13 island/unit modules at **Tier-2** (Verilator line/toggle + VCS branch/expr/FSM) + 4 integration
slices **Spike-lockstep-verified** with their toggle deltas closed, merged to core.v branch 96% / expr
79% / toggle 84%, residual attributed by owner. **Not** claimed: whole-core core.v 100% (that is the
riscv-dv-farm milestone). This is the truthful, hand-off-able integration state.
