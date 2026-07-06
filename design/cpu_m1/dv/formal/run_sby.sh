#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
FORMAL_DIR="$ROOT/design/cpu_m1/dv/formal"
OUT_DIR="$ROOT/flow/v2_pipeline/phase_p_formal/logs"
mkdir -p "$OUT_DIR"

if ! command -v sby >/dev/null 2>&1; then
    {
        echo "SymbiYosys not available on PATH."
        echo "No SBY proof was run in this environment."
    } | tee "$OUT_DIR/sby_missing.log"
    exit 127
fi

status=0
for mod in rfu alu forward lsu csr; do
    log="$OUT_DIR/${mod}_sby.log"
    (
        cd "$FORMAL_DIR" &&
        rm -rf "${mod}" &&
        sby -f "${mod}.sby"
    ) >"$log" 2>&1 || status=$?
done

exit "$status"
