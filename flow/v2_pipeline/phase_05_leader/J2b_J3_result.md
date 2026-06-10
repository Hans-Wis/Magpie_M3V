## funccov
Overall functional coverage: 55.56% (40/72 bins); gate threshold: 55%.
Per-covergroup hit rates: opcode/class 69.23%, ALU/M 80.95%, load/store 91.67%, branch/BP/RAS 0.00%, hazard/flush 50.00%, CSR/trap 0.00%.
VCS-COV was available; no coverage-license denial. `simv` ran 81 commits to PASS and URG generated `urgReport/dashboard.html`.

## lint
SpyGlass `lint/lint_rtl` on top `cpu_m1_top`: 0 fatals, 0 errors, 24 warnings, 3 infos.
STARC/starc2005 policy inside `lint/lint_rtl`: 0 errors, 9 warnings.
Verdict: PASS per ADR-0006; warnings/morelint are advisory. `lint/lint_turbo` is not present in this rtl_handoff methodology, so STARC evidence is extracted from the completed `lint/lint_rtl` report.

## files_added
`flow/v2_pipeline/phase_04_08_functional_coverage/provenance.log`
`flow/v2_pipeline/phase_05_00_lint/files.f`
`flow/v2_pipeline/phase_05_00_lint/run_spyglass.tcl`
`flow/v2_pipeline/phase_05_00_lint/lint_summary.txt`
`flow/v2_pipeline/phase_05_00_lint/provenance.log`
`flow/v2_pipeline/phase_05_00_lint/reports/lint_rtl.moresimple.rpt`
`flow/v2_pipeline/phase_05_00_lint/reports/starc.moresimple.rpt`
`tests/gates/gate_05_00_lint.py`
`flow/v2_pipeline/phase_05_leader/J2b_J3_result.md`

## provenance
VCS: X-2025.06-SP1_Full64; URG: X-2025.06-SP1; SpyGlass: X-2025.06-SP1; host `eda`; timestamp 2026-06-08 CST.
Key commands: `make clean all` in phase_04_08; `sg_shell -licqueue -tcl run_spyglass.tcl -shell_log_file spyglass_shell.log` in phase_05_00.
License outcomes: VCS/URG/SpyGlass lint available. SpyGlass dashboard HTML notes a separate dashboard feature requirement, but raw lint reports were generated.

## gate_status
`python3 -m pytest tests/gates/gate_*.py -q`: 172 passed in 11.88s.

## issues_or_waivers
No license waivers. Functional coverage remains low in branch/BP/RAS and CSR/trap groups for this bounded random seed; uncovered bins are triaged in `uncovered_bins.csv`.
RTL edits were declaration-order/comment-only for VCS compatibility; no semantic RTL logic change.

## tokens
Not measured by local tooling; result written within requested 45-line cap.
