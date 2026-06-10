# Formal Assertions

This report records the real VC Formal run for the existing Tier-2 assertion bind files under `IP/cpu_m1/dv/formal/`. No synthesizable RTL was edited.

Run command: `flow/v2_pipeline/phase_p_formal/run_vcf_formal.sh`

Tool environment:

```sh
export VC_STATIC_HOME=/soft/synopsys/vcs/X-2025.06-SP1/vcfca
export PATH=$VC_STATIC_HOME/bin:$PATH
export LD_LIBRARY_PATH=/soft/synopsys/verdi/X-2025.06-SP1-1/platform/linux64/lib/Qt5/lib:$LD_LIBRARY_PATH
```

VC Formal produced reports for all five modules. The tool then exited with code 3 after each report due to a shutdown `SIGABRT`; this is captured in `flow/v2_pipeline/phase_p_formal/logs/*_vcf.log` and `*.exit`. RFU was rerun independently after adding the `resetn` reset-state constraint in `flow/v2_pipeline/phase_p_formal/vcf_runs/rfu_vcf.tcl`.

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

Summary: `alu` 3/3 proven, `rfu` 4/4 proven, `forward` 8/8 proven, `lsu` 1/1 proven, `csr` 6/6 proven.

RFU rerun note: `rfu` was rerun alone with `create_reset resetn -value low` so VC Formal starts from the reset state and constrains post-reset operation with `resetn==1`. The rerun found 4 assertions and proved all 4. The raw `regs[0] == 0` invariant proved with safe depth 45, and the attempted x0 write storage assertion proved with safe depth 233. VC Formal still logged `Warning-[SM_IGN_INITIAL] Ignoring Initial block` for `IP/cpu_m1/rtl/rfu.v`, but the reset-state proof no longer depends on that `initial` block.

Detailed evidence is in `flow/v2_pipeline/phase_p_formal/results.md` and `flow/v2_pipeline/phase_p_formal/logs/`.

Token record: this RFU rerun was tracked in the Codex goal tracker; the final assistant response records the tool-reported token count.
