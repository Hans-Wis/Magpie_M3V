# External dependencies & portability (GitHub-readiness)

Magpie_M3V is designed to be **self-contained for the open-source core flow**: the RTL,
the functional gates, the `/sim` benchmark harness, and the `/dv` coverage tooling all run
against open-source tools (Verilator + Spike + the RISC-V GCC toolchain) with **no link to a
sibling project**. This file is the honest manifest of what remains machine- or vendor-specific,
so a fresh clone knows exactly what to provide.

> Status of the de-vendoring (Stage 4): the **public-runnable surface is portable** — the active
> gates resolve their toolchain from the environment (below). The **signoff/EDA flow** and a set
> of **offline coverage-generation scripts** still carry local absolute paths; those are *marked
> and isolated* here rather than rewritten, because they either need external licensed tools that
> a public checkout cannot run anyway, or their committed output is what the gates actually check.

## 1. What a public checkout needs (open-source core flow)

| Tool | How it's resolved | Provide by |
|---|---|---|
| **Verilator** (`--binary --timing`) | `shutil.which("verilator")` (PATH) | having `verilator` on `PATH` |
| **Spike** ISS (golden) | PATH | having `spike` on `PATH` |
| **RISC-V GCC** (`riscv64-unknown-elf-*`) | PATH; `RISCV_TOOLCHAIN_BIN` override | `PATH`, or export `RISCV_TOOLCHAIN_BIN=/your/riscv/bin` |
| Runtime shared libs (Spike/GCC deps) | `LD_LIBRARY_PATH` derived from `$CONDA_PREFIX/lib` | activating the conda/venv that owns the toolchain |

The active gates (`tests/gates/gate_0*`, `gate_49/50/51/59/82/94/95`) and the coverage runner
(`dv/coverage/verilator/run_cov.sh`) honor the above — no absolute path is hardcoded on the
public-runnable path. Set `RISCV_TOOLCHAIN_BIN` if your `riscv64-unknown-elf-size` is not on `PATH`
(it defaults to this dev machine's conda-pkg location as a last-resort fallback).

## 2. Signoff / EDA flow — external licensed tools + PDK (NOT part of the open-source core)

These flows cannot run in a public checkout regardless of path fixes — they require licensed
vendor tools and a foundry PDK under NDA. They are kept in-tree as **evidence of the signoff work**
(scripts + committed logs), clearly fenced off:

| Path | Needs | External resource |
|---|---|---|
| `flow/dc_tsmc28/`, `flow/v2_pipeline/phase_05_01_synth_ppa/`, `phase_p_asic/`, `phase_p_multicorner_dc/` | **Synopsys Design Compiler** | TSMC 28 nm PDK `.db` (std-cell + SRAM), currently referenced from a sibling `Magpie_X3/APR/ref/db/` |
| `phase_p_asic/files.f` | SRAM macro Verilog | foundry SRAM `.v` (referenced from `Magpie_X3/core_ip/.../sram/`) |
| `flow/v2_pipeline/phase_p_cdc_rdc_xprop/` | **Synopsys Spyglass** | (no PDK; needs the tool) |
| `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/` | **riscv-dv** generator | vendored under a sibling `Magpie_X6/vendored/riscv-dv` |
| `tests/gates/gate_05_01_synth_ppa.py` | reads the DC evidence | asserts the PDK `.db` path appears in the run log — **skips** when the DC flow hasn't run |

**To reproduce signoff:** point these at your own PDK / tool install (edit the `set … _db`/`files.f`
paths, or supply the sibling directories). They are explicitly out of scope for the open-source
functional+coverage flow, which stands alone.

## 3. Offline coverage-generation scripts — local toolchain paths (documented debt)

A set of scripts under `flow/v2_pipeline/phase_04_*`, `phase_p1[5-8]_*`, `phase_02_02_misalign`,
`phase_03_06_multi_seed_coverage`, `phase_p_archtest`, `phase_p_axi` hardcode a conda-pkg toolchain
path (`TOOLCHAIN_DIR = …/miniforge3/pkgs/riscv-tools-…`). These are the **offline generators** that
produced the committed coverage/lockstep reports; a public consumer does **not** re-run them — the
gates read the committed output (`*_report.md`, `logs/*.log`, `codecov_report.json`). They are left
as-is (marked here) rather than rewritten, to avoid churn on evidence-producing scripts. If you do
re-run them, export `RISCV_TOOLCHAIN_BIN` and edit the `TOOLCHAIN_DIR` constant at the top of the
script.

## 4. Sibling-project references (fork lineage — read-only)

`Magpie_M1` / `Magpie_X3` / `Magpie_X6` are **sibling repos in the author's tree**, referenced only
by the §2/§3 flows above. The M3V core, gates, `/sim`, and `/dv` do **not** depend on them. See
`CLAUDE.md` for the fork lineage (M3V ⟵ `m1a-rtl-freeze-v1.0`).

## 5. Known pre-existing gate staleness (not a de-vendoring item)

`tests/gates/gate_01_02_decode_execute_rv32imc.py` (and siblings from the `Magpie_M1` baseline
snapshot) assert on M1-era RTL signal names (e.g. `md_active_is_div`) that the M3V parameterized
core (ADR-0032) has evolved past. These are **M1-legacy unit gates** slated for reclassification
(directory-reorg Stage 3), independent of portability.
