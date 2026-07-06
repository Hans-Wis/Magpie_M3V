# ADR-0032 — Phase 2: parameterize cpu_m1 into host + NPU-scalar roles (fully verified)

- Status: **ACCEPTED** (User directive 2026-07-03: cpu_m1 is modifiable in M3V but must be fully
  verified). Producer = Claude (integrating Grok's DV plan); approver = User.
- Date: 2026-07-03
- Relates: ADR-0031 (M3V scope); supersedes the byte-identical freeze guard of `gate_10` for the
  cpu_m1 host (M3V line only — M1A's frozen deliverable is unaffected).

## Context / governance change

M3V's `design/cpu_m1/` was inherited under a byte-identical freeze (`gate_10_host_noregress`). The User
has **relaxed this for M3V**: cpu_m1 may be modified, but **every modification must be fully verified**
(Spike per-commit lockstep + gates, no regression). This unlocks the cleaner Phase-2 solution: one
parameterized cpu_m1 source serving BOTH the host CPU and the NPU scalar sequencer, instead of a
divergent forked copy (which ADR-0031's review flagged as "two scalar bloodlines to maintain").

The verification loop is proven operational in M3V: `flow/v2_pipeline/phase_03_00_spike_lockstep`
re-runs from scratch with **Verilator (DUT) + Spike (golden) + riscv64-unknown-elf-gcc (firmware)**
and passes (14/14 commits, 2026-07-03). Sim policy: Verilator in-sandbox, VCS signoff OUTSIDE-SANDBOX.

## Decision — parameterize in place

Add elaboration parameters to `cpu_m1`; **host defaults reproduce today's behavior exactly**:

| param | host | NPU | effect |
|---|---|---|---|
| `EN_RVC`   | 1 | 0 | `cdec` compressed decode + `ifu` cross-boundary residue behind `generate`; NPU = 32-bit fetch only |
| `EN_BP`    | 1 | 0 | `bp` BTB/BHT predict+update; NPU = `pred_taken=0`, redirect only on EX branch resolve |
| `EN_RAS`   | 1 | 0 | `ras` push/pop return predict; NPU = `ras_pred=0` |
| `FETCH_SRC`| IMEM/AXI | TCM | NPU scalar fetches its program from the NPU TCM |

**Keep unconditionally**: `hazard`, `forward` (load-use, mul/div busy still needed), `csr` (mepc,
mtvec, traps), `alu`/`bmu`/`mul`/`div`/`lsu`/`rfu`.

**Strip risks (from Grok):** (1) RVC-off ⇒ reset-PC 4-byte aligned, NPU boot image is 32-bit-only,
mepc uses the faulting 32-bit PC — boot/linker scripts change. (2) BP/RAS-off ≠ no branches: EX
mispredict redirect becomes the ONLY redirect; hazard flush must not assume BP-provided early-taken.
(3) IFU residue must not persist after trap/redirect in NPU mode (directed odd-PC = illegal, not
assemble). (4) **Forbidden**: changing any host elaboration default — that breaks equivalence.

## Verification plan ("fully verified")

**Host equivalence (the acceptance bar):** tag the pre-Phase-2 RTL (`m3v-pre-phase2-cpu`). After
parameterization, the host config (`EN_*=1`) must produce **byte-identical commit traces** (PC,
instr, rd, wdata, CSR, mem) vs the tag across the existing lockstep corpus — a null diff. Plus
gates 01_*/03_00..09/04 coverage: zero regression.

**NPU sequencer:** config `EN_*=0, FETCH_SRC=TCM`, Spike `--isa rv32im_zicsr_zifencei` (NO C),
TCM-backed fetch; directed (TCM boot, IRQ→handler, mul/div busy, branch/jalr) + random `riscv_rand`
with C disabled, **≥10k commits** before signoff. Line coverage on the `!EN_*` generate branches ≥95%.

**Gate order:** `gate_00_identity` → **`gate_02_host_equivalence` (NEW, trace-diff vs tag)** →
existing host gates 01_*/03_* → **`gate_02_npu_sequencer_directed` (NEW)** →
**`gate_03_npu_lockstep` (NEW, rv32im TCM)** → **`gate_04_npu_coverage` (NEW)** → npu_top system 15/15.

`gate_10_host_noregress` is **superseded** by `gate_02_host_equivalence`: the guarantee moves from
"source byte-identical to the freeze" to "host behavior byte-identical by commit-trace".

## Labor-division model (User asked for the best model)

| agent | role | sequence | hand-off | acceptance |
|---|---|---|---|---|
| **Grok** | architect / DV plan / strip-point spec | first (done) | this ADR's strip matrix + test plan | Claude reviews completeness |
| **Codex** | surgical RTL — params + `generate` guards; self-verify Verilator | after ADR accepted | diff, both configs lint + host smoke green | compiles both; host smoke identical |
| **Claude** | PL / sole committer / **authoritative lockstep + host-equivalence** | reviews Grok → commits Codex → runs lockstep/gates | state json, trace-diff report | **host trace-diff EMPTY + NPU lockstep ≥10k rv32im** |

**Green-wash guards (Claude enforces, do NOT accept if any):** (1) host `riscv_rand` scope shrunk;
(2) BP disabled in TB not RTL; (3) NPU lockstep run with C in `--isa` while `EN_RVC=0`; (4) trace-diff
equivalence skipped; (5) NPU "done" without the TCM fetch path (still IMEM).

## First 3 steps (each independently verifiable)

1. **ADR + param contract** (this doc) + tag `m3v-pre-phase2-cpu`. Verify: `gate_00_identity`, no RTL change.
2. **Scaffold params, host default unchanged** (Codex): add `EN_RVC/EN_BP/EN_RAS/FETCH_SRC` +
   `generate` wrappers; disabled bodies empty. Verify: Verilator lint both configs; host directed
   smoke identical.
3. **Host equivalence gate** (Claude): `gate_02_host_equivalence` — lockstep on host config,
   commit-trace diff vs tag = 0 divergences. Only then authorize NPU-strip work.
