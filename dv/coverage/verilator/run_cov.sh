#!/usr/bin/env bash
# ADR-0063 V5: Verilator line+toggle code coverage across THREE DUTs so every module is
# exercised by a harness that owns it, then combine (line=union effective, toggle=per-owner).
#   vector  tb_npu_lockstep     -> vexu / fexu / core            (phase_22 regression)
#   tflm    tb_npu_tflm_model   -> mat_engine / dma / axil / CQ  (dwsep + cnn layers)
#   host    tb_spike_lockstep   -> bmu / csr / idu / div / bp/ras (host rv32imc tests)
# Report: combine_cov.py dats -> codecov_report.json. Coverage is COMPLETENESS (G1) —
# every run is Spike-lockstep verified in its phase.
set -e
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HERE="$ROOT/dv/coverage/verilator"; DATS="$HERE/dats"; mkdir -p "$DATS"; rm -f "$DATS"/*.dat
VL=/home/edauser/miniforge3/envs/magpie_claude/bin/verilator
CPU="$ROOT/IP/cpu_m1/rtl"; NPU="$ROOT/IP/npu/rtl"
COVFLAGS="--coverage-line --coverage-toggle"
WAIVERS="-Wno-fatal -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-PINMISSING -Wno-WIDTHEXPAND"
srcs(){ for m in $1; do echo -n " $2/$m.v"; done; }

# ---- 1. vector DUT ----
VSRC="$(srcs 'npu_top npu_axil_regs npu_dma npu_tcm axil_decerr mat_engine' $NPU)$(srcs 'rfu alu bmu idu ifu lsu csr trigger pmp mul div forward hazard bp ras cdec vexu fexu core cpu_m1_top' $CPU)"
[ -x "$HERE/obj_dir/Vcov" ] || $VL --binary --timing -j 4 --top-module tb_npu_lockstep --timescale 1ns/1ns $COVFLAGS -I$CPU $WAIVERS -Mdir "$HERE/obj_dir" -o Vcov $VSRC "$ROOT/flow/v2_pipeline/phase_20_npu_core_lockstep/tb_npu_lockstep.v"
P22="$ROOT/flow/v2_pipeline/phase_22_vector_csr_lockstep"
for t in grid vill valu s1 s2 b1 b2 b3 b4 c1 c2 c3 c4a c4b c4c c4d c5 d1a d1b d2 e1 e2 e3 f f1 f2 ecmp cov s3 s3i pool vmem vwide kernel; do
  make -C "$P22" $t >/dev/null 2>&1 || continue
  (cd "$P22" && rm -f coverage.dat && "$HERE/obj_dir/Vcov" +max_cycles=200000 +min_commits=1 >/dev/null 2>&1)
  [ -f "$P22/coverage.dat" ] && cp "$P22/coverage.dat" "$DATS/vec_$t.dat"
done

# ---- 2. tflm/offload DUT ----
TSRC="$(srcs 'npu_top npu_axil_regs npu_dma npu_tcm axil_decerr mat_engine' $NPU)$(srcs 'rfu alu bmu idu ifu lsu csr trigger pmp mul div forward hazard bp ras cdec vexu core cpu_m1_top' $CPU)"
[ -x "$HERE/obj_tflm/Vcov_tflm" ] || $VL --binary --timing -j 4 --top-module tb_npu_tflm_model --timescale 1ns/1ns $COVFLAGS -I$CPU $WAIVERS -Mdir "$HERE/obj_tflm" -o Vcov_tflm $TSRC "$ROOT/IP/npu/dv/tb/axi_full_rwmem.v" "$ROOT/IP/npu/dv/tb/tb_npu_tflm_model.v"
python3 "$HERE/run_tflm_cov.py"

# ---- 3. host DUT ----
HSRC="$(srcs 'rfu alu idu ifu lsu csr mul div forward hazard bp ras cdec core' $CPU)"
[ -x "$HERE/obj_host/Vcov_host" ] || $VL --binary --timing -j 4 --top-module tb_spike_lockstep --timescale 1ns/1ns $COVFLAGS -I$CPU -Wall $WAIVERS -Mdir "$HERE/obj_host" -o Vcov_host $HSRC "$ROOT/flow/v2_pipeline/phase_03_00_spike_lockstep/tb_spike_lockstep.v"
for ph in phase_03_20_isacov_host:rvc_csr phase_03_21_isacov_bmu:bmu phase_03_22_isacov_csr:csr phase_03_05_random_lockstep:random phase_03_00_spike_lockstep:directed phase_03_01_trap_irq_lockstep:trap; do
  d="${ph%%:*}"; tag="${ph##*:}"
  make -C "$ROOT/flow/v2_pipeline/$d" lockstep.log >/dev/null 2>&1 || make -C "$ROOT/flow/v2_pipeline/$d" >/dev/null 2>&1 || true
  [ -f "$ROOT/flow/v2_pipeline/$d/firmware.hex" ] || continue
  (cd "$ROOT/flow/v2_pipeline/$d" && rm -f coverage.dat && "$HERE/obj_host/Vcov_host" +max_cycles=200000 >/dev/null 2>&1)
  [ -f "$ROOT/flow/v2_pipeline/$d/coverage.dat" ] && cp "$ROOT/flow/v2_pipeline/$d/coverage.dat" "$DATS/host_$tag.dat"
done

# ---- 4. debug DUTs (DM abstract CSR + trigger) -> csr debug interface / trigger / dm.v ----
SOC="$ROOT/IP/cpu_m1/soc"
DBGSRC="$(srcs 'rfu alu idu ifu lsu csr trigger mul div forward hazard bp ras cdec vexu fexu core' $CPU) $SOC/dm.v"
for pair in tb_debug_mvd:phase_06_00_debug_mvd:mvd tb_debug_trigger:phase_06_02_debug_trigger:trig; do
  top="${pair%%:*}"; rest="${pair#*:}"; ph="${rest%%:*}"; tag="${rest##*:}"
  od="$HERE/obj_dbg_$tag"
  [ -x "$od/Vcov_$tag" ] || $VL --binary --timing -j 4 --top-module $top --timescale 1ns/1ns $COVFLAGS -I$CPU -I$SOC -Wall $WAIVERS -Wno-PROCASSINIT -Mdir "$od" -o Vcov_$tag $DBGSRC "$ROOT/flow/v2_pipeline/$ph/$top.v"
  (cd "$ROOT/flow/v2_pipeline/$ph" && rm -f coverage.dat && "$od/Vcov_$tag" >/dev/null 2>&1)
  [ -f "$ROOT/flow/v2_pipeline/$ph/coverage.dat" ] && cp "$ROOT/flow/v2_pipeline/$ph/coverage.dat" "$DATS/host_debug_$tag.dat"
done

# ---- combine ----
python3 "$HERE/combine_cov.py" "$DATS" --json "$HERE/codecov_report.json"
