# Phase P AXI Verification

This phase verifies the Magpie_M1 AXI4-Lite wrapper without marking any gate green.

Artifacts:

- `axil_lite_mem_bfm.v`: AXI4-Lite slave memory BFM with configurable wait states.
- `tb_axil_equiv.v`: native `cpu_m1_top` vs `cpu_m1_axil_top` commit-trace equivalence.
- `tb_axil_archtest.v` and `run_axil_archtest.py`: selected riscv-arch-test signature runs through AXI.
- `axil_bridge_formal.sv` and `vcformal_axil.tcl`: VC Formal FPV protocol properties.

Commands:

```sh
make run-equiv
make run-arch
make formal
```
