# Magpie_M1 RETRY-3 Multi-Corner DC QoR

Date: 2026-06-09 23:24 +0800
Host: `eda`
DC version: `X-2025.06-SP2`
LC version: `X-2025.06-SP2`

Flow source: `flow/v2_pipeline/phase_05_01_synth_ppa/run_dc.tcl`.
Execution area: `flow/v2_pipeline/phase_p_multicorner_dc/`.

The RETRY-3 Tcl/filelist mirrors phase_05_01: same `cpu_m1_top`, same `files.f`, same `dw_foundation.sldb`, same `search_path` structure, same `hdlin_*` settings, same 1.43 ns clock and I/O constraints. Only `target_library_path`, and therefore `target_library` / `link_library`, differs by corner.

Target clock: 1.43 ns = 699.30 MHz.
Target with -10% margin: 629.37 MHz.

| corner | Fmax(MHz) | WNS | area(um2) | power(mW) |
|---|---:|---:|---:|---:|
| TT | 699.30 | 0.00 | 26790.749787 | 16.1030 |
| SLOW | 699.30 | 0.00 | 27069.839827 | 13.0798 |
| FAST | 699.30 | 0.00 | 26800.829889 | 17.4699 |

Signoff line: SLOW/setup trial meets the 699.30 MHz target and the 629.37 MHz target-with-10%-margin threshold with WNS 0.00 ns. **No gate is marked green**: this is a DC `compile_ultra` trial only, with no scan/DFT, no physical extraction, no propagated CTS clock tree, no SAIF/VCD switching activity, and no STA signoff deck.

## Corner Status

| corner | status | note |
|---|---|---|
| TT | complete mapped trial | QoR from `reports/TT/qor.rpt`, `reports/TT/area.rpt`, and `reports/TT/power.rpt`. |
| SLOW | complete mapped trial | QoR from `reports/SLOW/qor.rpt`, `reports/SLOW/area.rpt`, and `reports/SLOW/power.rpt`; `.db` compiled from the complete 84 MB Liberty source. |
| FAST | complete mapped trial | QoR from `reports/FAST/qor.rpt`, `reports/FAST/area.rpt`, and `reports/FAST/power.rpt`; `.db` compiled from the complete 84 MB Liberty source. |

## Library Compile Provenance

| corner | source `.lib` | compiled `.db` | evidence |
|---|---|---|---|
| SLOW | `/home/edauser/project/PDK/TSMC28/logic/tcbn28hpcplusbwp40p140_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/tcbn28hpcplusbwp40p140ssg0p81v0c.lib` | `flow/v2_pipeline/phase_p_multicorner_dc/compiled_db/tcbn28hpcplusbwp40p140ssg0p81v0c.db` | `logs/retry3_lc_shell_stdout.log`: library read successfully and `.db` written successfully. |
| FAST | `/home/edauser/project/PDK/TSMC28/logic/tcbn28hpcplusbwp40p140_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/tcbn28hpcplusbwp40p140ffg0p88v125c.lib` | `flow/v2_pipeline/phase_p_multicorner_dc/compiled_db/tcbn28hpcplusbwp40p140ffg0p88v125c.db` | `logs/retry3_lc_shell_stdout.log`: library read successfully and `.db` written successfully. |

The complete Liberty files contain `BUFFD1BWP40P140` and inverter cells. The compiled RETRY-3 `.db` files are about 20 MB each, not the prior subset-sized SS/FF `.db` files that failed with missing inverter mapping.

## DC Provenance

| corner | role | target library | evidence |
|---|---|---|---|
| TT | nominal | `/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db` | `runs/TT/provenance.log`, `runs/TT/status.txt`, `reports/TT/`, `db/TT/` |
| SLOW | setup/Fmax signoff trial | `/home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/compiled_db/tcbn28hpcplusbwp40p140ssg0p81v0c.db` | `runs/SLOW/provenance.log`, `runs/SLOW/status.txt`, `reports/SLOW/`, `db/SLOW/` |
| FAST | hold/leak trial | `/home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/compiled_db/tcbn28hpcplusbwp40p140ffg0p88v125c.db` | `runs/FAST/provenance.log`, `runs/FAST/status.txt`, `reports/FAST/`, `db/FAST/` |

Command:

```sh
cd /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc
lc_shell -f /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/compile_retry3_libs.tcl > logs/retry3_lc_shell_stdout.log 2>&1
dc_shell -f /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/run_dc.tcl > logs/retry3_dc_stdout.log 2>&1
```

Summary source: `flow/v2_pipeline/phase_p_multicorner_dc/qor_summary.tsv`.

Token record: local goal/token accounting was not available for this run; `get_goal` returned no active goal and no token budget report.
