# Magpie_M1 DV Architecture Notes — Interrupt Lockstep (P1.1) & Parallel riscv-dv Farm

---

## ITEM A — M-Mode Interrupt Lockstep Test Plan (P1.1)

### Goal

Make **MTI / MSI / MEI** injection **deterministic and identical** on DUT (Verilator TB) and Spike so **per-commit lockstep** holds. Non-determinism must be eliminated at the **architectural retire boundary**, not wall-clock or arbitrary cycle counts.

### Core Principle: Retire-Aligned Injection

Interrupts are architectural events. The only stable synchronization point shared by Spike ISS and a pipelined DUT is **retired instruction boundaries** (commit/retire count or retire PC), not simulation time.

| Injection trigger | Definition | When to use |
|---|---|---|
| **Retire-count** | Assert pending when `retire_count == N` (N-th committed instruction) | Best default; pipeline-depth agnostic |
| **Retire-PC** | Assert pending when instruction at PC `P` **retires** (not fetch/decode) | Directed corner cases, cross-boundary + IRQ |
| **Never** | Cycle count, `#posedge clk` after reset, wall time | Breaks lockstep across implementations |

**Rule:** Both sides observe the **same retire stream** first; only then may `mip` bits rise.

---

### Architecture: Deterministic IRQ Controller (Shared Contract)

Introduce a thin **deterministic IRQ injector** model used by both environments:

```
Retire monitor (DUT) / Spike retire hook
        │
        ▼
  IRQ schedule table: [(retire_n, irq_mask), (retire_pc, irq_mask), ...]
        │
        ├─► DUT TB: drive mip.MTI/MSI/MEI (or pulse → mip path)
        └─► Spike:   same table via retire callback / event replay
```

**Contract fields (per injection event):**
- `trigger_type`: `retire_count` | `retire_pc`
- `trigger_value`: N or PC
- `irq_lines`: `{mti, msi, mei}` (boolean or level)
- `persist`: level-held until taken vs single-retire pulse
- `clear_on_take`: whether pending clears when trap is taken (MEI often via PLIC claim; MTI/MSI via CLINT ack model)

Document this in an **IRQ schedule JSON** consumed by TB and Spike replay harness.

---

### DUT TB: Driving `mip`

**Assumption:** Magpie_M1 exposes or wrappers map external IRQ inputs into `mip` per privileged spec.

1. **Retire tap:** Export `retire_valid`, `retire_pc`, `retire_insn` (or commit interface). Maintain `retire_count` in TB.
2. **Schedule evaluator:** On each retire, check schedule; if match, assert pending:
   - **MTI:** `mip[7]` ← CLINT `mtime >= mtimecmp` model, or direct `mip.MTI` force if TB owns CLINT
   - **MSI:** `mip[3]` ← CLINT MSIP write or direct wire
   - **MEI:** `mip[11]` ← PLIC gateway / `irq_external` level
3. **Level vs pulse:** Prefer **level** pending until `mip` is cleared by architectural side effect (mret, CSR write, PLIC claim). Pulses must be **≥1 full retire period** wide unless RTL documents a synchronizer + minimum pulse width.
4. **Do not inject during RTL reset / before first retire** unless explicitly testing that corner.

**Open lead — `irq_external_pulse`:** If MEI enters through a pulse port with **no visible synchronizer**, TB-to-RTL cycle alignment can differ from Spike’s instantaneous `mip` update. For lockstep:

- **Short term:** Treat MEI as **level** in TB (hold until taken); avoid sub-cycle pulses in directed tests.
- **Verification:** Add a directed test that asserts a 1-cycle pulse and **waits 2+ retire boundaries** before expecting `mip.MEI`; compare against Spike only after defining an **ADR latency contract** (sync stages + interrupt recognition point).
- **Pitfall flag:** This is the #1 source of “Spike took IRQ at retire N, DUT at N+1”.

---

### Spike: Mirroring Injection

Three viable patterns (pick one; do not mix per suite):

#### Pattern 1 — Retire callback injection (preferred)

- Run Spike with a **custom extension / hook** on instruction retire (or use existing cosim retire callback).
- Load the same IRQ schedule JSON.
- On retire N or retire PC P, call Spike’s interrupt injection:
  - Set `mip` bits via CSR/backdoor API, **or**
  - Model CLINT/PLIC writes identically to DUT memory map.

#### Pattern 2 — Event log + replay

- **Record** during a golden Spike run: `(retire_index, pc, insn, mip_before, mip_after, inject_event)`.
- **Replay** in lockstep: DUT retire stream must match; on recorded inject event, TB asserts same `mip`.
- Spike replay run validates the log is self-consistent.

#### Pattern 3 — Memory-mapped CLINT/PLIC lockstep

- Both DUT and Spike use **identical** CLINT/PLIC simulation models in TB.
- IRQ “injection” is a **scheduled write** to `mtimecmp`, `msip`, or PLIC `threshold/enable/priority` at retire boundary — not raw `mip` force.
- Best for riscv-dv-generated programs that manipulate interrupt controllers via loads/stores.

**Spike API surface (conceptual):**
- Direct: write `mip` CSR shadow (debug/backdoor)
- Structural: `processor_t::set_interrupt(uint irq)` / clear equivalents
- Time: `mtime` advance tied to **retired instruction count** or explicit bus clock ratio — **not** free-running sim time unless DUT uses the same ratio

**Critical:** Spike must evaluate interrupt eligibility **after** the same retire that raised `mip`, matching RISC-V “interrupt recognized between instructions” rule.

---

### Lockstep Compare Points at Interrupt Entry

On the **first retire where trap is taken** (DUT `trap_taken` / Spike `trap`):

| Field | Check | Notes |
|---|---|---|
| `mepc` | Must match | Points to **interrupted instruction** or **next** per configured `mtvec` mode; agree on spec interpretation (RV32: mepc LSB=0) |
| `mcause` | Must match | **Interrupt bit = 1**; code = 3 (MSI), 7 (MTI), 11 (MEI) |
| `mstatus.MPIE` | Must match | Saved prior MIE |
| `mstatus.MIE` | Must match | Cleared on entry |
| `mstatus.MPP` | Must match | Prior mode (M for these tests) |
| `mtval` | Match if applicable | Usually 0 for interrupts |
| `pc` (post-entry) | Must match | `mtvec` (+4 if vectored and code indexing) |

**Also compare** the **last retired instruction before trap** (PC, encoding, rd data) — catches off-by-one retire alignment.

---

### riscv-dv Interrupt Test Config (Magpie_M1)

Target: **RV32IMC_Zicsr**, **M-mode only**, interrupts enabled.

| Parameter | Recommended | Rationale |
|---|---|---|
| `enable_interrupt` | `1` | Generate CSR/trap code |
| `support_m_mode` | `1` | M-mode only |
| `support_s/u_mode` | `0` | Reduce delegation noise |
| `mtvec_mode` | `DIRECT` first; then `VECTORED` | Staged bring-up |
| `gen_irq_vector` | `1` for vectored phase | Exercises `mtvec`+offset |
| `enable_timer_irq` / `enable_external_irq` / `enable_software_irq` | Staged: MSI → MTI → MEI | Isolate failure |
| `mstatus_mie` | Random + directed override | Tests disabled-window behavior |
| `mie_*` | Constrained initially (all enabled) | Then randomize |
| `tvec_alignment` | Match RTL (`mtvec` minimum alignment) | Avoid illegal CSR writes |
| `no_iss` | `1` in gen only | ISS compare is your lockstep harness, not riscv-dv internal |
| `instr_cnt` / `num_of_tests` | Small for P1.1 directed; scale in P1.2 | |

**riscv-dv caveat:** Random interrupt “spontaneity” in stock gen is **not** retire-deterministic. For lockstep:

1. Generate **bare interrupt handler code** + CSR setup with riscv-dv.
2. Replace or post-process IRQ timing with your **retire-scheduled injection** (directed overlay or custom riscv-dv interrupt stream class).
3. Do **not** rely on riscv-dv’s default random IRQ firing time for Spike lockstep until the schedule is shared.

---

### Latency-Window Handling

Define an explicit **Interrupt Recognition Contract (IRC)** in test metadata:

| Window | Definition |
|---|---|
| **Pending visibility** | `mip` bit visible at retire boundary T |
| **Take eligibility** | Next instruction boundary T+1 if `mie` & `mstatus.MIE` & priority allow |
| **External sync** | MEI: +K retire boundaries if pulse synchronizer exists (K = sync depth ADR) |

**Directed latency tests:**

1. Raise `mip.MTI` at retire N; `mie.MTIE=1`, `MIE=1` → expect trap at **N+1** retire (not same retire).
2. Raise pending at N; clear `MIE` before N+1 → expect **no trap**; retire continues.
3. Instruction touching `mstatus`/`mie` immediately before pending → verify spec ordering (cannot take in middle of instruction).

**Lockstep harness rule:** If DUT and Spike disagree only on **which retire** took the trap, widen compare to a **bounded window** (e.g. ±1 retire) **only during bring-up**; production pass criterion is **exact retire index match**.

---

### Pass Criteria (P1.1)

| Tier | Criterion |
|---|---|
| **P1.1a Directed** | ≥12 directed tests (MSI/MTI/MEI × direct/vectored × MIE on/off) — **100%** per-commit lockstep through handler `mret` return |
| **P1.1b Random CSR** | riscv-dv gen + **injected schedule** — **0 mismatches** for 1k+ retire commits per test |
| **Entry checkpoint** | Every trap: `mepc`, `mcause`, `mstatus` bit-exact vs Spike at same retire index |
| **Return checkpoint** | Post-`mret` PC and `mstatus.MIE/MPIE` match |
| **Regression** | Re-run with same seed + schedule → identical commit trace hash |

**Fail artifacts:** retire index, last 8 retired insns, `mip/mie/mstatus`, DUT vs Spike trap CSR snapshot.

---

### Top 3 Pitfalls

1. **Retire vs fetch/decode alignment** — Injecting at fetch PC or cycle count causes stable Spike mismatch on pipelined DUT. *Fix:* only retire-count / retire-PC triggers.

2. **`irq_external_pulse` without documented synchronizer** — 1-cycle pulse may be missed or delayed differently than Spike’s immediate `mip.MEI`. *Fix:* level-held MEI for lockstep; ADR for pulse/sync depth; directed sync test before random.

3. **`mtime` / MTI timebase drift** — Free-running TB clock vs Spike sim time makes MTI fire at different retire indices. *Fix:* advance `mtime` on a fixed ratio tied to **retire count** or explicit bus transactions, never independent clocks.

---

## ITEM B — Adversarial Review: Parallel riscv-dv Generation Farm

### Setup Under Review

- Install shared riscv-dv target config **once** (shared `core_setting`, YAML, overrides).
- Many parallel: `run.py --steps gen --seed S --output <perseed_dir>`
- Each worker: unique `--output`, per-seed testlist; all read same installed config.

### Verdict

**Conditionally safe** — parallel gen is **not automatically** deterministic. It is safe **only if** every worker has **isolated writable state** and the generator is **pure** w.r.t. `(seed, test_name, config_hash)` → artifacts. Shared **read-only** config is fine; shared **mutable** anything is not.

---

### Concrete Risks, Detection, and Hardening

#### Risk 1 — Shared temp / cache / build artifacts

| | |
|---|---|
| **Mechanism** | `TMPDIR`, `__pycache__`, `.pyc`, shared `build/`, default `/tmp/riscv_*`, compiled template caches, accidental writes relative to **cwd** not `--output`. |
| **Symptom** | Intermittent ELF diffs; corrupt or partial `.S`; duplicate section names; flaky gen failures under load. |
| **Detect** | Run same `(seed, test)` twice in parallel (N workers) + once serial; `sha256` all outputs. Any divergence = contamination. |
| **Harden** | Per worker: `TMPDIR=$output/.tmp`, unique `cwd` or `PYTHONDONTWRITEBYTECODE=1`, `python -B`. Generator wrapper **chdirs** to `--output` before `run.py`. Post-gen assert: all new files under `--output` only (see Risk 4). |

#### Risk 2 — RNG seeding and global process state

| | |
|---|---|
| **Mechanism** | `random` / `numpy` seeded once at import; fork without re-seed; `uuid` for names; hash randomization (`PYTHONHASHSEED`); worker pool reuse without per-job `random.seed(S)`. |
| **Symptom** | Same `--seed S` different binaries when N_parallel changes; order-dependent instruction streams. |
| **Detect** | **Byte-identical ELF test:** for seeds `{s1..s100}`, compare `parallel_gen(s)` vs `serial_gen(s)`; must match exactly. Vary worker count `{1,2,8,32}`. |
| **Harden** | Force `random.seed(S)` (and numpy if used) at **start of each gen invocation**, not module import. Set `PYTHONHASHSEED=0` in farm policy. Single-test-per-process (no reused long-lived workers without re-init). Log effective seed in manifest. |

#### Risk 3 — Same `--test` name across seeds with shared namespace

| | |
|---|---|
| **Mechanism** | If any path uses **test name without seed prefix** outside `--output` (global test registry, shared `instr_test.h`, linker script cache), workers stomp each other. |
| **Symptom** | Test A’s ELF contains test B’s symbols; wrong `begin_signature`; mixed `.text` fragments. |
| **Detect** | `strings elf \| grep -E 'test_|seed'` — unexpected cross-seed symbol names. Compare `.map` / symbol tables serial vs parallel. |
| **Harden** | Enforce `--output` hierarchy: `<farm_root>/<seed>/<test_name>/`. Unique testlist per seed. Generator manifest lists **every** output file + sha256. Never share a writable `testlists/` directory across workers. |

#### Risk 4 — Files written outside `--output`

| | |
|---|---|
| **Mechanism** | riscv-dv / vendor extensions write to install tree, source tree, `../../`, shared `riscv-target`, default log dir, or CWD. |
| **Symptom** | Serial vs parallel ELF diff; install tree mtimes change during farm run. |
| **Detect** | **Sandbox audit:** `inotifywait` / pre-post directory hash of install root + repo; only `--output` and `/tmp` (per-worker) may change. CI gate: fail if install tree hash changes. |
| **Harden** | Read-only mount or snapshot install config. Wrapper copies **read-only** config into per-job sandbox. `run.py` only invoked with abs `--output`. Post-run: `find $output -type f -exec sha256sum` → `manifest.json`. |

#### Risk 5 — Non-reproducibility vs serial (ordering and filesystem)

| | |
|---|---|
| **Mechanism** | `os.walk` order, `set` iteration, `glob` order, race on shared lock files, `mtime`-based logic, parallel FS listing affecting “first test”. |
| **Symptom** | ELF byte diff with identical seed when farm concurrency changes. |
| **Detect** | Golden reference: `serial_gen(seed) → elf_ref`. Farm job: `parallel_gen(seed) → elf_job`. `cmp -b elf_ref elf_job`. Automate for all seeds in regression matrix. |
| **Harden** | Sort all iterables (`sorted(glob())`). No mtime-based decisions. Deterministic linker command lines. Pin tool versions in manifest. Treat **byte-identical** as the farm correctness definition. |

#### Risk 6 — Shared “install once” config is secretly mutable

| | |
|---|---|
| **Mechanism** | `run.py` or `gen_config` appends to installed YAML, writes resolved config back, caches codegen in install dir. |
| **Symptom** | Seed 5 output changes depending on whether seed 3 finished first. |
| **Detect** | Hash install dir before/after each worker; run workers with staggered start; first and last worker same seed must match. |
| **Harden** | Install step produces **immutable** config package (checksum file). Workers `cp -a` immutable package to local read-only `$JOBROOT/config` before gen. |

---

### Provably Correct Farm Protocol (Recommended)

```text
For each seed S:
  1. JOBROOT = <farm>/<S>/          # unique
  2. TMPDIR  = JOBROOT/.tmp
  3. CONFIG  = ro-copy(global_install) → JOBROOT/config
  4. random.seed(S); PYTHONHASHSEED=0
  5. run.py --steps gen --seed S --output JOBROOT/dv --config JOBROOT/config ...
  6. manifest = sha256(every file under JOBROOT/dv)
  7. ASSERT: no file changes outside JOBROOT (inotify/hashes)
  8. OPTIONAL GOLDEN: cmp JOBROOT/dv/*.elf serial_reference/S/*.elf
```

**Farm CI gate:**

- **Determinism gate:** `parallel(N=32)` vs `serial` → **100% byte-identical ELF** for fixed seed list.
- **Isolation gate:** install-tree hash **unchanged** after 1000 parallel jobs.
- **Manifest gate:** every production ELF has `manifest.json` with seed, config hash, tool versions.

---

### Summary Table

| Question | Answer |
|---|---|
| Is parallel riscv-dv gen safe? | **Only with per-job isolation + determinism gates** |
| Is shared installed config OK? | **Yes if truly read-only** to all workers |
| Strongest correctness signal? | **Byte-identical ELF** vs serial for same seed, across worker counts |
| Most likely silent bug? | **RNG / global state** and **writes outside `--output`** |

---

*Context note for M1 bring-up:* P1.1 interrupt lockstep should land **before** scaling the parallel riscv-dv farm on interrupt-heavy tests; otherwise farm throughput will amplify non-deterministic IRQ timing into high-volume false divergences. Resolve `irq_external_pulse` synchronizer ambiguity via ADR before MEI enters random lockstep at scale.
