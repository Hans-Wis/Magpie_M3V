#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

export VC_STATIC_HOME=/soft/synopsys/vcs/X-2025.06-SP1/vcfca
export PATH="$VC_STATIC_HOME/bin:$PATH"
export LD_LIBRARY_PATH="/soft/synopsys/verdi/X-2025.06-SP1-1/platform/linux64/lib/Qt5/lib:${LD_LIBRARY_PATH:-}"

OUT=flow/v2_pipeline/phase_p_formal_coverage
mkdir -p "$OUT/logs"

mods=(alu rfu forward lsu csr)
for mod in "${mods[@]}"; do
    echo "== VC Formal coverage ${mod} =="
    rm -rf "$OUT/vcf_runs/${mod}_coverage_session"
    vcf -batch -no_ui -fmode FPV -no_init -no_restore \
        -session "$OUT/vcf_runs/${mod}_coverage_session" \
        -f "$OUT/vcf_runs/${mod}_coverage.tcl" \
        -output_log_file "$OUT/logs/${mod}_coverage_vcf.log"
    rc=$?
    echo "${mod} vcf_exit=${rc}" | tee "$OUT/logs/${mod}_coverage_vcf.exit"
done
