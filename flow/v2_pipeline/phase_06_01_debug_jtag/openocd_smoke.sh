#!/usr/bin/env bash
set -euo pipefail

if ! command -v openocd >/dev/null 2>&1; then
  echo "OPENOCD_UNAVAILABLE: openocd is not installed or not in PATH."
  exit 1
fi

echo "OPENOCD_AVAILABLE: $(openocd --version 2>&1 | head -n 1)"

make obj_dir/Vtb_debug_openocd >/dev/null

rm -f sim_remote_bitbang.log openocd_stdout.log
./obj_dir/Vtb_debug_openocd --port 9824 >sim_remote_bitbang.log 2>&1 &
sim_pid=$!
cleanup() {
  if kill -0 "${sim_pid}" >/dev/null 2>&1; then
    kill "${sim_pid}" >/dev/null 2>&1 || true
    wait "${sim_pid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

for _ in $(seq 1 100); do
  if grep -q "REMOTE_BITBANG_READY" sim_remote_bitbang.log; then
    break
  fi
  sleep 0.05
done

if ! grep -q "REMOTE_BITBANG_READY" sim_remote_bitbang.log; then
  echo "SIM_BRIDGE_NOT_READY"
  cat sim_remote_bitbang.log
  exit 1
fi

set +e
openocd -f openocd_magpie_m1_remote_bitbang.cfg \
  -c "init; halt; reg pc; reg x1; resume; halt; step; reg pc; shutdown" \
  >openocd_stdout.log 2>&1
openocd_rc=$?
set -e

cat openocd_stdout.log
echo "OPENOCD_EXIT_CODE: ${openocd_rc}"

exit "${openocd_rc}"
