## ppa
TRIAL DC `compile_ultra` on `cpu_m1_top` at 1.43 ns target (~699.30 MHz): area 26298.467795 um^2; setup WNS/TNS 0.00/0.00 ns; estimated total power 15.8503 mW.
Power is vectorless low-effort DC estimate: dynamic 15.8315 mW, leakage 18.2730 uW.

## library_used
`/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db`
Library/corner: `tcbn28hpcplusbwp40p140tt0p9v25c`, TSMC 28HPC+ BWP40P140 stdcell, tt0p9v25c.
Search evidence: `~/project/PDK/TSMC28` has 28HPC+ PDK/model/memory artifacts but no extracted stdcell `.lib/.db` found by the recorded PDK search; selected the Magpie_X3 APR ref `.db`.

## files_added
`flow/v2_pipeline/phase_05_01_synth_ppa/files.f`
`flow/v2_pipeline/phase_05_01_synth_ppa/run_dc.tcl`
`flow/v2_pipeline/phase_05_01_synth_ppa/library_search_evidence.txt`
`flow/v2_pipeline/phase_05_01_synth_ppa/dc_shell.log`
`flow/v2_pipeline/phase_05_01_synth_ppa/dc_stdout.log`
`flow/v2_pipeline/phase_05_01_synth_ppa/reports/{area,timing,power,qor,constraints,check_design}.rpt`
`flow/v2_pipeline/phase_05_01_synth_ppa/db/cpu_m1_top.{ddc,mapped.v}`
`flow/v2_pipeline/phase_05_01_synth_ppa/{ppa_summary.txt,provenance.log}`
`tests/gates/gate_05_01_synth_ppa.py`
`flow/v2_pipeline/phase_05_leader/J4_result.md`

## provenance
DC version: Synopsys Design Compiler `X-2025.06-SP2`; host `eda`; run timestamp 2026-06-08 14:20-14:23 +08:00.
Key command: `cd /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_05_01_synth_ppa; dc_shell -f ./run_dc.tcl -output_log_file dc_shell.log | tee dc_stdout.log`.
License outcome: available; DC loaded target `.db` and `dw_foundation.sldb`, completed compile and wrote reports/DDC/mapped Verilog.

## gate_status
`python3 -m pytest tests/gates/gate_05_01_synth_ppa.py -q`: 4 passed.
`python3 -m pytest tests/gates/gate_03_08_lockstep_revalidate.py -q`: 1 passed, lockstep still PASS.
`python3 -m pytest tests/gates/gate_*.py -q`: 176 passed in 8.36s.

## issues_or_waivers
No library/license waiver: usable 28HPC+ stdcell `.db` was found outside the PDK tree.
Trial caveats: no scan/DFT, no SAIF/VCD activity, zero-wireload/segmented estimate, two min-delay/hold violators in `reports/constraints.rpt`, and `check_design` has advisory lint warnings.

## tokens
Not measured by local tooling.
