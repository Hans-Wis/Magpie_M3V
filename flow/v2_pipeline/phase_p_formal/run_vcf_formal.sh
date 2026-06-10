#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

export VC_STATIC_HOME=/soft/synopsys/vcs/X-2025.06-SP1/vcfca
export PATH="$VC_STATIC_HOME/bin:$PATH"
export LD_LIBRARY_PATH="/soft/synopsys/verdi/X-2025.06-SP1-1/platform/linux64/lib/Qt5/lib:${LD_LIBRARY_PATH:-}"

mkdir -p flow/v2_pipeline/phase_p_formal/logs

mods=(alu rfu forward lsu csr)
for mod in "${mods[@]}"; do
    echo "== VC Formal ${mod} =="
    rm -rf "flow/v2_pipeline/phase_p_formal/vcf_runs/${mod}_session"
    vcf -batch -no_ui -fmode FPV -no_init -no_restore \
        -session "flow/v2_pipeline/phase_p_formal/vcf_runs/${mod}_session" \
        -f "flow/v2_pipeline/phase_p_formal/vcf_runs/${mod}_vcf.tcl" \
        -output_log_file "flow/v2_pipeline/phase_p_formal/logs/${mod}_vcf.log"
    rc=$?
    echo "${mod} vcf_exit=${rc}" | tee "flow/v2_pipeline/phase_p_formal/logs/${mod}_vcf.exit"
done
