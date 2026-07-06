#!/usr/bin/env bash
# Phase 0 "toolchain applies" proof: open RVV Zve32x toolchain -> Spike ISS.
# clang (integrated-as, handles RVV) compiles; GNU ld links bare-metal HTIF; spike runs.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MARCH="rv32im_zve32x_zvl128b"   # Zvl128b pins VLEN=128; integer-only (no scalar F yet)
OUT="${1:-$(mktemp -d)}"
cd "$OUT"

clang --target=riscv32 -march=$MARCH -mabi=ilp32 -O2 -c "$HERE/vdot_i8.c"  -o vdot_i8.o
clang --target=riscv32 -march=$MARCH -mabi=ilp32 -O2 -c "$HERE/npu_main.c" -o npu_main.o
clang --target=riscv32 -march=$MARCH -mabi=ilp32       -c "$HERE/crt0.S"    -o crt0.o
riscv64-linux-gnu-gcc -nostdlib -nostartfiles -march=$MARCH -mabi=ilp32 \
    -Wl,-T,"$HERE/link.ld" crt0.o npu_main.o vdot_i8.o -o p0.elf

set +e
spike --isa=$MARCH p0.elf
rc=$?
set -e
echo "spike exit code = $rc (expected 240)"
[ "$rc" -eq 240 ]
