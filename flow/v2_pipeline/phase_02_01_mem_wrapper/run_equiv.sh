#!/usr/bin/env bash
# Phase 2.1 mem_wrapper equivalence runner (ADR-0005).
# Builds tb_equiv (cpu_m1_top vs bare core) and runs every I/D wait config.
# Writes equiv_run.log; prints one OK/FAIL line per config + a summary.
set -u
cd "$(dirname "$0")"
R=../../../design/cpu_m1/rtl
VL=$(command -v verilator || echo /home/edauser/miniforge3/envs/magpie_claude/bin/verilator)

"$VL" --binary -j 4 --top-module tb_equiv \
  -Wno-WIDTH -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-TIMESCALEMOD \
  -I"$R" "$R"/*.v tb_equiv.v -o Vtb_equiv > equiv_build.log 2>&1
if [ $? -ne 0 ]; then echo "BUILD FAIL"; tail -5 equiv_build.log; exit 2; fi

: > equiv_run.log
pass=0; tot=0; dw_ref=""; dw_ok=1
for cfg in "0 0" "1 0" "0 1" "1 1" "3 3" "9 9" "9 3" "3 9" "9 0" "0 9"; do
  set -- $cfg; tot=$((tot+1))
  out=$(./obj_dir/Vtb_equiv +imode=$1 +dmode=$2 2>&1)
  line=$(echo "$out" | grep -E "OK |RESULT FAIL" | head -1)
  echo "$line" | tee -a equiv_run.log
  echo "$line" | grep -q "^OK" && pass=$((pass+1))
  # F1 closure: accepted D-write bus xfers must be identical across all wait modes
  dw=$(echo "$out" | grep -oE "DWRITES[^:]*: [0-9]+" | grep -oE "[0-9]+$")
  [ -z "$dw_ref" ] && dw_ref="$dw"
  [ "$dw" != "$dw_ref" ] && dw_ok=0 && echo "DUP-STORE? dwrites=$dw != ref=$dw_ref (imode=$1 dmode=$2)" | tee -a equiv_run.log
done
echo "SUMMARY ${pass}/${tot} wait configs pass; D-writes=${dw_ref} constant across modes (dw_ok=${dw_ok})" | tee -a equiv_run.log
[ "$pass" -eq "$tot" ] && [ "$dw_ok" -eq 1 ]
