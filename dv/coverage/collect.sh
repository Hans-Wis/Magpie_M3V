#!/usr/bin/env bash
# ADR-0063 V1: collect Spike commit logs across the regression -> ISA coverage report.
# Authority = Spike --log-commits (the lockstep golden). Re-run to refresh the baseline.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOGS="$ROOT/dv/coverage/logs"; mkdir -p "$LOGS"; rm -f "$LOGS"/*.log
P22="$ROOT/flow/v2_pipeline/phase_22_vector_csr_lockstep"
P20="$ROOT/flow/v2_pipeline/phase_20_npu_core_lockstep"
VEC="grid vill valu s1 s2 b1 b2 b3 b4 c1 c2 c3 c4a c4b c4c c4d c5 d1a d1b d2 e1 e2 e3 f f1 f2 ecmp cov s3 s3i pool vmem vwide kernel"
for t in $VEC; do make -C "$P22" $t >/dev/null 2>&1 && cp "$P22/spike.log" "$LOGS/vec_$t.log" || true; done
for t in directed "random SEED=1" "random SEED=2"; do
  make -C "$P20" $t >/dev/null 2>&1 && cp "$P20/spike.log" "$LOGS/npu_$(echo $t|tr ' =' '__').log" || true; done
P0320="$ROOT/flow/v2_pipeline/phase_03_20_isacov_host"
make -C "$P0320" lockstep.log >/dev/null 2>&1 && cp "$P0320/spike.log" "$LOGS/host_isacov_rvc.log" || true
# host scalar (RVC/Zbb/Zba/Zbs/Zicond/F) from existing tree logs
find "$ROOT" -path "$ROOT/.git" -prune -o -path "$ROOT/dv/coverage" -prune -o -name 'spike*.log' -print 2>/dev/null \
  | grep -vE 'obj_dir|/phase_22_|/phase_20_' | while read f; do
    cp "$f" "$LOGS/host_$(echo "$f"|sed -E 's#.*/(phase_[^/]+)/.*#\1#;s#[^a-zA-Z0-9_]#_#g')_$(basename $f)" 2>/dev/null || true; done
python3 "$ROOT/dv/coverage/isa_cov.py" "$LOGS"/*.log --json "$ROOT/dv/coverage/isa_cov_report.json"
