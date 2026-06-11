# Magpie_M1 Tier-2 CDC/RDC/X-prop Summary

## Result

Top: `cpu_m1_top`

Methodology: `$SPYGLASS_HOME/GuideWare/latest/block/rtl_handoff`

Goals run:
- CDC: `cdc/cdc_verify_struct`
- RDC: `rdc/rdc_verify_struct` (GuideWare clock-reset goal with advanced CDC/RDC features enabled by the goal)
- X-prop/unsync subset: `Ac_initstate01`, `Ac_unsync01`, `Ac_unsync02` from `cdc/cdc_verify_struct`

Final status: 0 unwaived fatals/errors/warnings in CDC and RDC. Two setup messages are generated and waived in both goals; see `magpie_m1_cdc_rdc_xprop_waivers.awl`.

## Counts

| Goal | Generated | Waived | Reported | Unwaived E/W/F |
|---|---:|---:|---:|---:|
| `cdc/cdc_verify_struct` | 46 | 2 | 44 infos | 0 |
| `rdc/rdc_verify_struct` | 41 | 2 | 39 infos | 0 |

Key structural counts:
- CDC unsynchronized crossings: 0
- CDC convergences: 0
- `Ac_unsync01`: 0 scalar unsynchronized crossings
- `Ac_unsync02`: 0 vector unsynchronized crossings
- `Ac_initstate01`: 0 messages
- RDC `Ar_resetcross01`: 0 reset domain crossings for 1 reset
- Missing clock definitions (`Clock_info03a`): 0
- Missing async reset definitions (`Reset_info09a`): 0

## Waivers

1. `SYNTH_5143` on `rfu.v`: same reviewed lint waiver; simulation-only register-file initialization is ignored by synthesis by construction.
2. `ErrorAnalyzeBBox` on `core.v:u_trigger`: mandated reuse of `phase_p_lint_current/files.f` omits `IP/cpu_m1/rtl/trigger.v`; the canonical `IP/cpu_m1/rtl/filelist.f` includes it. Structural audit of `trigger.v` shows only `clk`, `resetn`, one `always @(posedge clk)`, no generated clock/reset, and no new CDC/RDC domain. For a non-waived setup-clean run, update the shared lint filelist to include `trigger.v`.

## One-Domain Evidence

`cpu_m1_top` exposes one clock input, `clk`, and one active-low reset input, `resetn`. SGDC used:

```tcl
current_design cpu_m1_top
clock -name clk
reset -name resetn -value 0
```

SpyGlass propagated `cpu_m1_top.clk` and `cpu_m1_top.resetn`, reported 0 missing clock definitions, 0 missing async reset definitions, and RDC reported 0 crossings for 1 reset.

## Provenance

Host: `eda`

Tool: `SpyGlass_vX-2025.06-SP1` (`Version X-2025.06-SP1 for linux64 - Sep 02, 2025`)

License: `SNPSLMD_LICENSE_FILE=27050@127.0.0.1`, `LM_LICENSE_FILE=27050@127.0.0.1`; run used `sg_shell -licqueue`.

Command:

```sh
cd /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_cdc_rdc_xprop
sg_shell -licqueue -tcl /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_cdc_rdc_xprop/run_spyglass.tcl
```

Reports:
- `reports/cdc_verify_struct.moresimple.rpt`
- `reports/rdc_verify_struct.moresimple.rpt`
- `cpu_m1_phase_p_cdc_rdc_xprop/consolidated_reports/cpu_m1_top_cdc_cdc_verify_struct/`
- `cpu_m1_phase_p_cdc_rdc_xprop/consolidated_reports/cpu_m1_top_rdc_rdc_verify_struct/`

Note: `IP/cpu_m1/rtl/core.v` was changed only to move trigger-related wire declarations before first use so SpyGlass CDC/RDC design-read accepts the RTL; logic is unchanged.
