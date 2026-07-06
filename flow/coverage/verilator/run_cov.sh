#!/usr/bin/env bash
# ADR-0063 V5: Verilator line+toggle code coverage over the vector regression.
# Builds the tb_npu_lockstep DUT (npu_top + core + vexu + fexu + mat_engine) with
# --coverage, runs each phase_22 firmware against it, merges -> per-file report.
# NOTE: this DUT/stimulus covers the vector+FP datapath (vexu/fexu) thoroughly; the
# NPU-offload (mat_engine/dma/CQ) and host-scalar (bmu/csr/idu/div) paths need the
# tflm/CQ and host-rv32imc harnesses respectively (V5 backlog).
set -e
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HERE="$ROOT/flow/coverage/verilator"; DATS="$HERE/dats"; mkdir -p "$DATS"; rm -f "$DATS"/*.dat
P22="$ROOT/flow/v2_pipeline/phase_22_vector_csr_lockstep"
VL=/home/edauser/miniforge3/envs/magpie_claude/bin/verilator
CPU="$ROOT/IP/cpu_m1/rtl"; NPU="$ROOT/IP/npu/rtl"
CPU_SRCS="rfu alu bmu idu ifu lsu csr trigger pmp mul div forward hazard bp ras cdec vexu fexu core cpu_m1_top"
NPU_SRCS="npu_top npu_axil_regs npu_dma npu_tcm axil_decerr mat_engine"
SRCS=""; for m in $NPU_SRCS; do SRCS="$SRCS $NPU/$m.v"; done; for m in $CPU_SRCS; do SRCS="$SRCS $CPU/$m.v"; done
TB="$ROOT/flow/v2_pipeline/phase_20_npu_core_lockstep/tb_npu_lockstep.v"
COVBIN="$HERE/obj_dir/Vcov"
[ -x "$COVBIN" ] || $VL --binary --timing -j 4 --top-module tb_npu_lockstep --timescale 1ns/1ns \
  --coverage-line --coverage-toggle -I$CPU \
  -Wno-fatal -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-PINMISSING -Wno-WIDTHEXPAND \
  -Mdir "$HERE/obj_dir" -o Vcov $SRCS $TB
VEC="grid vill valu s1 s2 b1 b2 b3 b4 c1 c2 c3 c4a c4b c4c c4d c5 d1a d1b d2 e1 e2 e3 f f1 f2 ecmp cov s3 s3i pool vmem vwide kernel"
for t in $VEC; do
  make -C "$P22" $t >/dev/null 2>&1 || continue
  (cd "$P22" && rm -f coverage.dat && "$COVBIN" +max_cycles=200000 +min_commits=1 >/dev/null 2>&1)
  [ -f "$P22/coverage.dat" ] && cp "$P22/coverage.dat" "$DATS/vec_$t.dat"
done
verilator_coverage --write "$HERE/merged.dat" "$DATS"/*.dat >/dev/null 2>&1
python3 "$HERE/codecov_report.py" "$HERE/merged.dat" --json "$HERE/codecov_report.json"
