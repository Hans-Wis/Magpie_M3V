# ADR-0005 — D/I memory: fixed-latency → valid/ready wrapper + backpressure

- Status: Accepted (2026-06-08)
- Deciders: Claude (architect), User
- Flow stage: 2.1 `mem_wrapper` (gate_02_01_mem_wrapper)
- Supersedes: none. Builds on ADR-0002 (lab08e active baseline).

## Context

The active baseline `core` (ch2_lab08e) exposes **fixed-latency, non-stallable**
memory ports:

- I-port: `i_mem_addr[31:0]`, `i_mem_en` (out), `i_mem_rdata[31:0]` (in) — sync
  read, data assumed valid the next cycle whenever `i_mem_en`.
- D-port: `d_mem_valid`, `d_mem_addr[31:0]`, `d_mem_wdata[31:0]`,
  `d_mem_wstrb[3:0]` (out), `d_mem_rdata[31:0]` (in) — 1-cycle access,
  byte-strobed write.

There is **no `mem_ready`/`mem_stall` input**: the core cannot wait for memory.
To be a real reusable CPU IP (talk to variable-latency SRAM / a bus), the IP must
present a standard **valid/ready** memory interface and freeze the pipeline while
a response is outstanding. All prior gates (incl. Spike lockstep) ran against the
1-cycle TB memory only — `copy + lint ≠ qualified`.

## Decision

1. **New top `cpu_m1_top`** wraps `core` and presents outward, per Harvard
   (I and D independent), a **single-outstanding, ready-gated valid/ready**
   protocol:
   - I-bus (read-only): `ibus_req` (out), `ibus_addr[31:0]` (out);
     `ibus_ready` (in), `ibus_rdata[31:0]` (in). `req` held until the cycle
     `req & ready`; `rdata` sampled on that cycle. Wait state = `ready` low N cycles.
   - D-bus: `dbus_req` (out), `dbus_addr[31:0]`, `dbus_we` (out, = `|wstrb`),
     `dbus_wstrb[3:0]`, `dbus_wdata[31:0]` (out); `dbus_ready` (in),
     `dbus_rdata[31:0]` (in). Same ready-gated single-outstanding semantics.

2. **Core change — add a global `mem_stall` input that FREEZES the pipeline.**
   *(Revised 2026-06-08: the original "just OR mem_stall into any_stall" was
   under-scoped.)* This core stalls the dependent instr in ID and lets bubbles
   propagate (ex_mem/ex_wb *bubble* on stall); `ex_mem_advance_to_wb` is not
   gated by `any_stall`. A memory wait instead needs a **freeze**: every pipeline
   register holds in place and every commit side-effect is suppressed for the
   wait duration. Concretely `mem_stall` must (a) hold EX/MEM and EX/WB in place
   (not bubble), and (b) gate off `rfu_we`, `wb_csr_we`, `wb_instr_retired`,
   `wb_trap_enter`, `wb_trap_exit`, `trap_latched`, `wb_take_irq`, `pc_redirect`,
   `bp_upd_valid`, `ras_push`, and the cross-boundary residue capture
   (`upcoming_cross` / `at_cross_boundary`). Single-outstanding, no I/D request
   pipelining. (Without this a waited load retires with stale `d_mem_rdata`.)

   **Bus read timing = combinational-read, ready-gated.** On the cycle
   `req & ready`, `*_rdata` already reflects `mem[addr]` (combinational), and the
   wrapper registers it once → the core sees native 1-cycle latency at 0 wait
   states. A registered-read slave (data one cycle *after* ready) is NOT this
   protocol and would double-register. Memory models / adapters must present
   combinational read data on the ready cycle.

3. **Misalign policy = precise trap.** Naturally-misaligned data accesses raise
   `load address misaligned` (mcause 4) / `store/AMO address misaligned`
   (mcause 6) with `mtval` = faulting address. The core (lsu) detects; the
   wrapper never issues a misaligned bus request. **Spike must be configured to
   trap-on-misaligned** so lockstep stays equivalent (key equivalence risk).
   RVC keeps instruction fetch 16-bit-aligned (handled upstream in ifu); this ADR
   covers data accesses only.

4. **Byte lanes / sign-zero ext unchanged.** Write byte-enables already come from
   `d_mem_wstrb`; load sign/zero-extension stays in `lsu`. The wrapper passes
   `wstrb`/byte-enables outward and does no new shaping.

5. **Regression-safety contract:** with `ready` tied high (0 wait states) the
   wrapped core MUST be behaviourally identical to the bare baseline — the entire
   existing Spike lockstep suite must still pass through `cpu_m1_top`.

## Gate (gate_02_01_mem_wrapper)

Verilator TB drives the valid/ready side and asserts:
- (a) **Equivalence**: 0-wait wrapper commit trace == bare-core baseline trace.
- (b) **Backpressure correctness**: under injected I/D wait states {0,1,3, random}
  no commit is lost/duplicated; PC/commit stream matches the 0-wait run.
- (c) **Misalign**: a misaligned lw/sw/lh/sh traps with correct mcause + mtval.
- (d) **Lockstep regression**: an existing random Spike program replayed through
  `cpu_m1_top` with random wait states matches Spike per-commit (Spike misaligned-trap).

## Freeze exception — free-running counters (mcycle)

`mem_stall` suppresses every *instruction-commit* side-effect (regfile, CSR
writes, `minstret`, traps, redirects, BP/RAS, residue). It does **not** freeze
`mcycle` (`cycle_cnt`): per the RISC-V spec `mcycle` counts elapsed clock cycles,
and wait-state cycles are real elapsed cycles, so it correctly keeps counting.
Consequence: timing CSRs (`mcycle`/`time`) are *not* bit-equivalent between runs
of differing memory latency — by definition they cannot be. Per-commit
equivalence / Spike lockstep therefore compares `{pc, rd, wdata}` and excludes
timing CSRs (Spike does not model wait states). `minstret` *is* gated (counts
retired instructions, latency-independent) and remains equivalent.

(Independent Codex review F2 flagged `mcycle` as a freeze violation; this is the
intentional, spec-correct exception. F1 "duplicate store under freeze" was
empirically disproven — accepted D-write bus transactions are constant across all
wait modes incl. concurrent I+D waits, because `ex_mem_advance_to_wb` fires the
same cycle a store issues, so a store is never held in EX/MEM after issuing; the
runner asserts this invariant continuously.)

## Consequences

- First core RTL edit on the M1 line; re-validates the whole lockstep suite.
- Single-outstanding only — no overlapped I/D latency hiding (deferred).
- Misalign-trap is a clean-room choice (spec permits trap or handle); revisit via
  new ADR if a use case needs hardware misalign support.
- Enables stage 5 (lint/synth) to see a bus-like boundary instead of raw SRAM ports.
