# `sim/gates/` — system-functional gates

**System-functional** verification: the whole NPU acting as a system, authority = Spike lockstep
+ bit-accurate golden + AXI scoreboard. Grouped with `/sim` because these exercise system behaviour
(models, patterns, offload), not basic-circuit structure.

Coverage:
- **NPU domain** — AXI4-Lite/full fabric, DMA, TCM, IRQ, DECERR (`gate_20`–`gate_28`)
- **NPU core + CQ** — sequencer integration, command-queue ring/exec-equiv (`gate_29`–`gate_39`)
- **RVV Zve32x** — vector CSR + full integer/fixed-point/mask/reduction/permutation (`gate_40`–`gate_81`)
- **mat-engine + benchmarks** — GEMM golden, TFLM FC/MLP/CNN, MobileNet, MLPerf AD/KWS, Gemma
  foundation (`gate_44`–`gate_95`)

`gate_20_axi_fabric.py` is the shared Verilator-harness helper (`CPU_M1_ARGS`, `verilator_sim`, …);
the other system gates import it — they must stay co-located here. The `/sim` benchmark runner
(`sim/run_bench.py`) drives the `rtl_e2e` benchmark gates in this directory.

```bash
python3 -m pytest sim/gates/gate_51_offload_closure.py -q
python3 sim/run_bench.py            # functional-correctness matrix across rtl_e2e benches
```
