#!/usr/bin/env bash
# =============================================================================
# gen_tcm_sram.sh — regenerate TSMC28 dual-port SRAM macros for the NPU TCM.
# CONFIRMED WORKING 2026-07-08: the TSMC MC2 memory compiler (mc2-eu, Interra
# Systems, in ~/project/PDK/TSMC28/Memory/) is installed + licensed
# (LM_LICENSE_FILE=27050@127.0.0.1) and generates real dual-port SRAM
# (.v behavioral + .lib NLDM + datasheet, all PVT corners).
#
# The dual-port SRAM (Port A / Port B, each R/W: CLKA/CLKB, WEBA/WEBB, CEBA/CEBB,
# BWEBA/BWEBB, A/D/Q) is the per-bank building block. npu_tcm's 256-bit engine
# reads (eng_a + eng_b = 8 words each) require an 8-bank word-interleaved wrapper
# (see the banked-wrapper follow-up before re-synthesis).
#
# Valid instance format: <words>x<bits>m<mux><seg>, seg in {s,m,f}; NOT every
# (mux,seg) is legal — 2048x32m8f generates clean (mux8/seg-f); 2048x32m4s/m8s
# error (SEG has no matching case). Check the datasheet DB PDF for the legal grid.
#
# Usage: bash flow/dc_tsmc28/gen_tcm_sram.sh   (outputs to flow/dc_tsmc28/sram_macros/)
# =============================================================================
set -u
PDK="${PDK_ROOT:-$HOME/project/PDK}/TSMC28"
MCROOT="$PDK/Memory/1/tsmc_n28hpcpmc_20120200_110a/AN61001_20180125/TSMCHOME/sram/Compiler/tsmc_n28hpcpmc_20120200_110a"
DPGEN="$PDK/Memory/tsn28hpcpdpsram_20120200_130a/AN61001_20180125/TSMCHOME/sram/Compiler/tsn28hpcpdpsram_20120200_130a"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/sram_macros"; mkdir -p "$OUT"; cd "$OUT"

export PATH="$MCROOT/MC2_2012.02.00.d/bin:$PATH"
export MC2_INSTALL_DIR="$MCROOT/MC2_2012.02.00.d"
export MC_HOME="$DPGEN"                       # dir holding the dpsram .mco
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27050@127.0.0.1}"

# TCM candidate instances (dual-port). Tune once the banked wrapper is designed:
#   ITCM 8KB  = 2048 x 32  -> 2048x32m8f (single macro), OR bank by depth.
#   DTCM 32KB = 8192 x 32  -> bank word-interleaved x8 (each 1024x32) for the
#              256-bit engine read, e.g. 8 x 1024x32m4f  (verify legal mux/seg).
cat > tcm_config.txt <<'EOF'
2048x32m8f
EOF

echo "[gen-tcm-sram] configs:"; cat tcm_config.txt
perl "$DPGEN/tsn28hpcpdpsram_130a.pl" -file "$OUT/tcm_config.txt" -VERILOG -NLDM -DATASHEET 2>&1 \
  | grep -iE 'Creating instance|errors : [0-9]|ERROR' | tail -20
echo "[gen-tcm-sram] kits under $OUT/<instance>_130a/{VERILOG,NLDM,DATASHEET}/"
find "$OUT" -maxdepth 3 -name '*.lib' -o -maxdepth 3 -name '*.v' 2>/dev/null | head
