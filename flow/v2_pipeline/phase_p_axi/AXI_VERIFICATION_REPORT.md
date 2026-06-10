# Magpie_M1 AXI4-Lite Bridge Verification Report

No gate is marked green here. This report records verification evidence only.

## Scope

- DUT wrapper: `IP/cpu_m1/rtl/cpu_m1_axil_top.v`
- Bridge: `IP/cpu_m1/rtl/axil_bridge.v`
- New verification phase: `flow/v2_pipeline/phase_p_axi/`
- Core RTL changes: none
- Bridge RTL changes: none

## Behavioral Transparency

Command:

```sh
make run-equiv
```

Directed firmware:

- `flow/v2_pipeline/phase_03_04_directed_lockstep/firmware.hex`

Commit trace fields compared by retire index:

- `pc`
- `instr`
- `rd`
- `wdata`
- `mstatus`
- `mepc`
- `mcause`
- `mtval`

Results:

| AXI wait states | Result | Matched commits | Artifacts |
| ---: | --- | ---: | --- |
| 0 | PASS | 40 | `runs/equiv_wait0/native_commit.trace`, `runs/equiv_wait0/axi_commit.trace`, `runs/equiv_wait0/sim.log` |
| 3 | PASS | 40 | `runs/equiv_wait3/native_commit.trace`, `runs/equiv_wait3/axi_commit.trace`, `runs/equiv_wait3/sim.log` |

No native-vs-AXI commit divergence was observed.

## AXI riscv-arch-test Smoke

Command:

```sh
make run-arch
```

Reference:

- Spike signature replay, same method as `phase_p_archtest`.

Results:

| Extension | Test | AXI wait states | Result |
| --- | --- | --- | --- |
| RV32I | `add-01` | 0, 3 | PASS |
| RV32M | `mul-01` | 0, 3 | PASS |

Artifacts:

- `archtest_axi_results.csv`
- `archtest_axi_summary.json`
- `runs/RV32I/add-01/`
- `runs/RV32M/mul-01/`

## VC Formal FPV

Command:

```sh
make formal
```

Properties:

- `ARVALID/AWVALID/WVALID` hold until corresponding READY.
- `ARADDR/AWADDR/WDATA/WSTRB` stable while valid is held under backpressure.
- `RREADY/BREADY` hold while waiting for response valid.
- Single-outstanding read issue: no second AR while the corresponding R is pending.
- D-side read and write channel exclusion checks.

Result:

| Metric | Count |
| --- | ---: |
| Assertions found | 18 |
| Assertions proven | 18 |
| Vacuity checks found | 18 |
| Non-vacuous | 18 |
| CEX | 0 |

Artifacts:

- `formal_results.txt`
- `formal_summary.txt`
- `vcformal_axil.log`
- `vcformal_axil.out/`

Note: this VC Static install aborts during process shutdown after `report_fv` completes. The Makefile treats `make formal` as passing only if `formal_results.txt` contains `18` proven assertions and `18` non-vacuous vacuity results.

## Verdict

Observed evidence supports AXI wrapper behavioral transparency for the directed firmware at 0 and 3 wait states, plus AXI-top signature correctness for selected RV32I/RV32M arch tests at 0 and 3 wait states. Basic AXI4-Lite master protocol FPV properties on `axil_bridge` are proven with no CEX.
