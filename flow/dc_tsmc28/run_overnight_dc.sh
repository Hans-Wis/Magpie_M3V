#!/usr/bin/env bash
# =============================================================================
# run_overnight_dc.sh — unattended full-design DC PPA (M3 sign-off).
# The RTL is DC/Presto-clean as of commit 8b783a0 (declaration-order refactor).
# This runs the long compile_ultra jobs that are impractical interactively:
#   1. npu_top  (whole NPU: RV32IMF core + Zve32x vexu + 256-MAC mat + dma + ml_ctrl;
#      TCM black-boxed via npu_tcm_bb.v). Flagship MAT_LANES=4/DMA_DATA_W=256/ML_V2_EN=1.
# The vexu RVV combinational vdiv + fexu float dividers make this a ~40-60 min compile.
#
# Usage (from anywhere):
#   nohup bash flow/dc_tsmc28/run_overnight_dc.sh > /tmp/dc_overnight.out 2>&1 &
# or cron. Writes per-run logs + a machine-readable PPA summary + a DONE marker.
# Re-run safe (cleans its own work dirs).
# =============================================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$HERE"

export T28_ROOT="${T28_ROOT:-/home/edauser/project/PDK}"
DC="${DC_SHELL:-/soft/synopsys/syn/X-2025.06-SP2/bin/dc_shell}"
STAMP="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo run)"
LOG="$HERE/dc_overnight_${STAMP}.log"
SUMMARY="$ROOT/reports/dc_npu_top/ppa_summary.txt"

echo "[overnight-dc] start $(date 2>/dev/null); DC=$DC" | tee "$LOG"
rm -rf "$HERE/work_npu_top"

# --- npu_top flagship full compile ---
# real TCM SRAM macro (Option B): build .db then synth with USE_SRAM_MACRO=1 (default in tcl)
"$DC" -f "$HERE/lib2db.tcl" >> "$LOG" 2>&1
CLK_PERIOD="${CLK_PERIOD:-2.0}" MAT_LANES="${MAT_LANES:-4}" DMA_DATA_W="${DMA_DATA_W:-256}" ML_V2_EN="${ML_V2_EN:-1}" USE_SRAM_MACRO="${USE_SRAM_MACRO:-1}" \
  "$DC" -f "$HERE/synth_npu_top.tcl" >> "$LOG" 2>&1
RC=$?
echo "[overnight-dc] npu_top dc_shell rc=$RC" | tee -a "$LOG"

# --- extract a machine-readable PPA summary ---
mkdir -p "$ROOT/reports/dc_npu_top"
AREA=$(grep -iE 'Total cell area' "$ROOT/reports/dc_npu_top/dc.area.rpt" 2>/dev/null | head -1 | grep -oE '[0-9.]+' | head -1)
DYN=$(grep -iE 'Total Dynamic Power' "$ROOT/reports/dc_npu_top/dc.power.rpt" 2>/dev/null | head -1)
LEAK=$(grep -iE 'Cell Leakage Power' "$ROOT/reports/dc_npu_top/dc.power.rpt" 2>/dev/null | head -1)
SLACK=$(grep -i slack "$ROOT/reports/dc_npu_top/dc.qor.rpt" 2>/dev/null | head -1)
{
  echo "top=npu_top"
  echo "config=MAT_LANES=${MAT_LANES:-4} DMA_DATA_W=${DMA_DATA_W:-256} ML_V2_EN=${ML_V2_EN:-1}"
  echo "clk_period_ns=${CLK_PERIOD:-2.0}"
  echo "tcm=black-boxed (npu_tcm_bb.v; SRAM macro, not synthesized)"
  echo "dc_shell_rc=$RC"
  echo "total_cell_area_um2=${AREA:-NA}"
  echo "power_dynamic=${DYN:-NA}"
  echo "power_leakage=${LEAK:-NA}"
  echo "timing=${SLACK:-NA}"
  echo "log=$LOG"
  echo "note=std-cell logic only; TCM macro area from memory compiler is separate."
} > "$SUMMARY"
echo "[overnight-dc] PPA summary -> $SUMMARY" | tee -a "$LOG"
cat "$SUMMARY" | tee -a "$LOG"

touch "$HERE/DONE_NPU_TOP_PPA"
echo "[overnight-dc] done $(date 2>/dev/null)" | tee -a "$LOG"
