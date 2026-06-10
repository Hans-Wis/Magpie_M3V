# cpu_m1 / dv — verification deliverable

The curated DV deliverable for the cpu_m1 IP (RV32IMC_Zicsr_Zifencei). The *executable* development
flow lives under `../../../flow/v2_pipeline/phase_*`; this tree is the hand-off-shaped subset.

| Dir | Contents |
|---|---|
| `tb/` | Reusable testbenches: `tb_spike_lockstep.v`, `tb_riscvdv_lockstep.v` (+ fence directed) |
| `lib/` | `spike_commit.py` — Spike per-commit comparator (RVVI-intent: PC/GPR/CSR per retire) |
| `cov/` | `cpu_m1_func_cov_bind.sv` — functional coverage model (own coverpoints plus riscvISACOV operand/value/immediate covergroups; immediate J corners still partial) |
| `tests/` | Directed test programs (`fence_directed.S`, `smoke_directed.S`); fixtures |
| `sim/` | (see `../sim/`) build/run filelist |
| `vplan/` | `VPLAN.md` (feature→test→coverage trace) + `DV_SIGNOFF_CHECKLIST.md` (Tier-1, honest) |

Authority = Spike per-commit lockstep + pytest gates (`../../../tests/gates/`). Status (honest):
189 pytest gates pass + 1 xfail (toggle <90% Tier-1 bar). See `vplan/DV_SIGNOFF_CHECKLIST.md`.
