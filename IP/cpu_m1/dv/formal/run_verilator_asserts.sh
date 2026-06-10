#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
RTL_DIR="$ROOT/IP/cpu_m1/rtl"
TB_DIR="$ROOT/IP/cpu_m1/dv/tb"
FORMAL_DIR="$ROOT/IP/cpu_m1/dv/formal"
OUT_DIR="$ROOT/flow/v2_pipeline/phase_p_formal/logs"
mkdir -p "$OUT_DIR"

if ! command -v verilator >/dev/null 2>&1; then
    echo "Verilator not available on PATH." | tee "$OUT_DIR/verilator_missing.log"
    exit 127
fi

status=0
run_one() {
    local mod="$1"
    local top="$2"
    local log="$OUT_DIR/${mod}_verilator.log"
    local obj_dir="$OUT_DIR/obj_${mod}"

    rm -rf "$obj_dir"
    verilator --binary --assert --timing -Wno-fatal \
        -I"$RTL_DIR" \
        --top-module "$top" \
        --Mdir "$obj_dir" \
        "$RTL_DIR/${mod}.v" \
        "$FORMAL_DIR/${mod}_assert_bind.sv" \
        "$TB_DIR/${top}.v" >"$log" 2>&1
    local build_rc=$?
    if [ "$build_rc" -ne 0 ]; then
        echo "BUILD_FAIL rc=$build_rc" >>"$log"
        status="$build_rc"
        return
    fi

    "$obj_dir/V${top}" >>"$log" 2>&1
    local run_rc=$?
    if [ "$run_rc" -ne 0 ]; then
        echo "RUN_FAIL rc=$run_rc" >>"$log"
        status="$run_rc"
    else
        echo "PASS" >>"$log"
    fi
}

run_one rfu tb_rfu_unit
run_one alu tb_alu_unit
run_one forward tb_forward_unit
run_one lsu tb_lsu_unit
run_one csr tb_csr_unit

exit "$status"
