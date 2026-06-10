# P11 CSR Unit Coverage Summary

Gate: `gate_01_11_csr_stateful`

Status: **not green**. Directed unit stimulus passes, line/branch/cond are closed, but raw toggle is below the Tier-2 bar until structural waivers are reviewed and approved. VCS did not extract an RTL FSM shape for `csr` because the RTL has no encoded FSM state register.

## Commands

```sh
cd flow/v2_pipeline/phase_p11_csr
make clean verilator urg
```

## Results

- Verilator vector result: `PASS: csr unit 936/936 vectors`
- VCS vector result: `PASS: csr unit 936/936 vectors`
- Verilator `csr.v` line: `108/108 = 100.00%`
- Verilator `csr.v` toggle: `1360/1548 = 87.86%`
- VCS `csr` line: `63/63 = 100.00%`
- VCS `csr` cond: `13/13 = 100.00%`
- VCS `csr` branch: `38/38 = 100.00%`
- VCS `csr` toggle bits: `1360/1548 = 87.86%`
- VCS FSM: not reported; URG emitted `Warning-[UCAPI-SNF] Shape Not Found`.
- TB lifecycle coverage: 4/4 states and 6/6 intended arcs covered in the printed trap lifecycle counters.

## Uncovered Toggles

STRUCTURAL:

- `mstatus_val[31:13]`, `[10:8]`, `[6:4]`, `[2:0]`: WPRI/reserved readback bits hardwired to zero.
- `mie_val[31:12]`, `[10:0]`: WPRI/readback bits hardwired to zero; only MEIE bit 11 is implemented.
- `mip_val[31:12]`, `[10:0]`: WPRI/readback bits hardwired to zero; only MEIP bit 11 is implemented.
- `mtvec_val[1:0]`, `mtvec_o[1:0]`: MODE hardwired to direct mode `2'b00`.

REACHABLE-still-uncovered:

- None observed in final Verilator toggle enumeration.

Note: the earlier charter listed counter upper bits and `mepc[0]`; the final TB accelerated counter toggles with hierarchical counter assignment and drove an odd `trap_pc`, so those are no longer uncovered in this unit run.

## Proposed Waiver JSONL

These are proposals only. They are not applied and remain unapproved for Claude review.

```jsonl
{"design_id":"cpu_m1","gate_id":"gate_01_11_csr_stateful","leaf":"P11_csr","metric":"toggle","module":"csr.v","signal_re":"mstatus_val","bit_ranges":["31:13","10:8","6:4","2:0"],"structural_basis":"WPRI/reserved mstatus readback fields are hardwired zero in csr.v mstatus_val concatenation; implemented fields are MPP/MPIE/MIE only.","quant_bound":"constant-zero combinational readback; no legal CSR write/trap input can toggle these bits","waiver":"proposed","approved":false,"approver":null}
{"design_id":"cpu_m1","gate_id":"gate_01_11_csr_stateful","leaf":"P11_csr","metric":"toggle","module":"csr.v","signal_re":"mie_val","bit_ranges":["31:12","10:0"],"structural_basis":"MIE readback implements only MEIE bit 11; all other bits are WPRI and hardwired zero in csr.v mie_val concatenation.","quant_bound":"constant-zero combinational readback; no legal CSR write/trap input can toggle these bits","waiver":"proposed","approved":false,"approver":null}
{"design_id":"cpu_m1","gate_id":"gate_01_11_csr_stateful","leaf":"P11_csr","metric":"toggle","module":"csr.v","signal_re":"mip_val","bit_ranges":["31:12","10:0"],"structural_basis":"MIP readback implements only MEIP bit 11; all other bits are WPRI and hardwired zero in csr.v mip_val concatenation.","quant_bound":"constant-zero combinational readback; no legal CSR write/trap input can toggle these bits","waiver":"proposed","approved":false,"approver":null}
{"design_id":"cpu_m1","gate_id":"gate_01_11_csr_stateful","leaf":"P11_csr","metric":"toggle","module":"csr.v","signal_re":"mtvec_val|mtvec_o","bit_ranges":["1:0"],"structural_basis":"MTVEC direct mode only; MODE bits are hardwired to 2'b00 in csr.v mtvec_val concatenation and mtvec_o is assigned from mtvec_val.","quant_bound":"constant-zero combinational readback/output; no legal CSR write can toggle MODE bits","waiver":"proposed","approved":false,"approver":null}
```

Token record: not available from local simulator artifacts.
