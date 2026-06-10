## root_cause
cdec bug: no. fetch bug: no. Comparator/parser bug.
Repro seed `2026060801` initially reported idx 59 mismatch at `pc=0x000000d2`, `instr=0x6db5`.
Temporary probe at cdec boundary showed fetched/decode input was correct: `i_mem_rdata=6db58e95`, `cur_at_high=1`, `cinstr=6db5`, `cdec_expanded=0000ddb7`, `illegal=0`, `cross_assemble=0`, `any_stall=0`.
Correct RV32C result for `0x6db5 c.lui s11,0xd` is LUI x27 immediate `0x0000d000`; raw Spike log also wrote `x27=0x0000d000`.
False golden `0x0000c000` came from `parse_spike_commits()` subtracting `pc_base=0x1000` from any writeback in its old broad normalization window.

## fix
No RTL changed; no ADR needed.
Changed `flow/v2_pipeline/lib/spike_commit.py` to compute normalized RV32IMC integer Spike writebacks from normalized PC/register state instead of broad value-window subtraction.
Added parser regression coverage in `tests/gates/gate_03_03_spike_comparator_lib.py` for `C.LUI 0xd000` and large `AUIPC` PC normalization.
Updated `tests/gates/gate_03_09_riscvdv_lockstep.py` and `flow/v2_pipeline/phase_05_leader/J8_result.md` to report the bounded one-seed rerun as honest `INCOMPLETE`, not 100k PASS.
Evidence note: `docs/reports/bug_xbound_0001/j10_rvc_lui_evidence.md`.

## revalidate
`pytest -q` and `pytest -q tests` collect no tests because project gates are named `gate_*.py`.
Full explicit gate suite: `pytest -q tests/gates/*.py` PASS, `180 passed in 8.17s`.
`gate_03_08_lockstep_revalidate.py` PASS, `1 passed in 3.37s`.
`gate_02_01_mem_wrapper.py` PASS, `6 passed in 0.32s`.
`gate_04_08_functional_coverage.py` PASS, `5 passed in 0.01s`; covergroups remain `100.00%`.
Re-run seed `2026060801` only: `981` matched DUT commits; no next divergence before sentinel/stop in this bounded run.

## regressions
None observed in requested validation. This fix changes lockstep golden normalization only; active RTL `cdec.v` was not modified.

## tokens
Unavailable from local runtime/API telemetry.
