# Phase P Formal Results: VC Formal

Date: 2026-06-09

Scope: existing non-invasive SVA bind files for `rfu`, `alu`, `forward`, `lsu`, and `csr`.

Tool command: `flow/v2_pipeline/phase_p_formal/run_vcf_formal.sh`

Environment:

```sh
export VC_STATIC_HOME=/soft/synopsys/vcs/X-2025.06-SP1/vcfca
export PATH=$VC_STATIC_HOME/bin:$PATH
export LD_LIBRARY_PATH=/soft/synopsys/verdi/X-2025.06-SP1-1/platform/linux64/lib/Qt5/lib:$LD_LIBRARY_PATH
```

VC Formal launched and produced proof reports for every module. Each run ended with process exit code 3 after report generation because `vc_static_shell` aborted during shutdown with `terminate called without an active exception` / `SIGABRT`; the proof summaries below are taken from the generated `report_fv` files and `PROP_I_RESULT` log lines before that shutdown abort.

## Summary

| module | assertions found | PROVEN | FALSIFIED+CEX | INCONCLUSIVE | notes |
|---|---:|---:|---:|---:|---|
| `alu` | 3 | 3 | 0 | 0 | all comparator equivalence assertions proven |
| `rfu` | 4 | 4 | 0 | 0 | rerun with reset-state constraint; read mux x0 and raw x0 storage assertions proven |
| `forward` | 8 | 8 | 0 | 0 | all forwarding source gating assertions proven |
| `lsu` | 1 | 1 | 0 | 0 | non-store write strobe suppression proven |
| `csr` | 6 | 6 | 0 | 0 | mstatus MPP/WPRI assertions proven |

## Per-Property Results

| module | property | result | tool |
|---|---|---|---|
| `alu` | `cmp_eq == (op_a == op_b)` | PROVEN | VC Formal |
| `alu` | `cmp_lt_s == ($signed(op_a) < $signed(op_b))` | PROVEN | VC Formal |
| `alu` | `cmp_lt_u == (op_a < op_b)` | PROVEN | VC Formal |
| `rfu` | `rs1_idx == 0 -> rs1_data == 0` | PROVEN | VC Formal |
| `rfu` | `rs2_idx == 0 -> rs2_data == 0` | PROVEN | VC Formal |
| `rfu` | raw `regs[0] == 0` invariant | PROVEN | VC Formal |
| `rfu` | attempted x0 write leaves raw `regs[0] == 0` | PROVEN | VC Formal |
| `forward` | `em_fwd_ok == em_allowed` | PROVEN | VC Formal |
| `forward` | `wb_fwd_ok == wb_allowed` | PROVEN | VC Formal |
| `forward` | `em_fwd_rs1` requires allowed EX/MEM source and matching `rs1` | PROVEN | VC Formal |
| `forward` | `em_fwd_rs2` requires allowed EX/MEM source and matching `rs2` | PROVEN | VC Formal |
| `forward` | `wb_fwd_rs1` requires allowed WB source, no EX/MEM priority hit, and matching `rs1` | PROVEN | VC Formal |
| `forward` | `wb_fwd_rs2` requires allowed WB source, no EX/MEM priority hit, and matching `rs2` | PROVEN | VC Formal |
| `forward` | EX/MEM load forwarding is suppressed | PROVEN | VC Formal |
| `forward` | any forwarding select implies a nonzero destination in EX/MEM or WB | PROVEN | VC Formal |
| `lsu` | `!is_store -> mem_wstrb == 4'b0000` | PROVEN | VC Formal |
| `csr` | `mstatus_val.MPP == 2'b11` combinational invariant | PROVEN | VC Formal |
| `csr` | `mstatus_val[31:13] == 0` WPRI invariant | PROVEN | VC Formal |
| `csr` | `mstatus_val[10:8] == 0` WPRI invariant | PROVEN | VC Formal |
| `csr` | `mstatus_val[6:4] == 0` WPRI invariant | PROVEN | VC Formal |
| `csr` | `mstatus_val[2:0] == 0` WPRI invariant | PROVEN | VC Formal |
| `csr` | after reset release, `mstatus_val.MPP == 2'b11` | PROVEN | VC Formal |

## Evidence Files

| file | purpose |
|---|---|
| `flow/v2_pipeline/phase_p_formal/vcf_runs/*_vcf.tcl` | per-module VC Formal scripts |
| `flow/v2_pipeline/phase_p_formal/run_vcf_formal.sh` | batch runner with required VC Formal environment |
| `flow/v2_pipeline/phase_p_formal/logs/*_vcf.log` | full VC Formal console logs |
| `flow/v2_pipeline/phase_p_formal/logs/*_vcf_report_fv.txt` | `report_fv` summary |
| `flow/v2_pipeline/phase_p_formal/logs/*_vcf_report_fv_verbose.txt` | per-property status, source location, and depths |
| `flow/v2_pipeline/phase_p_formal/logs/*_vcf_props.tsv` | machine-readable property/status extraction |
| `flow/v2_pipeline/phase_p_formal/logs/*_vcf.exit` | observed process exit code; all were `vcf_exit=3` due post-report shutdown `SIGABRT` |

RFU rerun note: `rfu` was rerun alone after adding `create_reset resetn -value low` to `flow/v2_pipeline/phase_p_formal/vcf_runs/rfu_vcf.tcl`. VC Formal reported 4/4 assertions proven with one reset constraint (`resetn==1`) in the generated report. The raw `regs[0] == 0` invariant proved with safe depth 45, and the attempted x0 write storage assertion proved with safe depth 233.

Token record: this RFU rerun was tracked in the Codex goal tracker; the final assistant response records the tool-reported token count.
