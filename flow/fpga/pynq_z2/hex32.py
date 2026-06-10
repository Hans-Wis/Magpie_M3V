#!/usr/bin/env python3
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: hex32.py input.bin output.hex", file=sys.stderr)
        return 2

    data = Path(sys.argv[1]).read_bytes()
    if len(data) % 4:
        data += bytes(4 - (len(data) % 4))

    lines = []
    for i in range(0, len(data), 4):
        word = int.from_bytes(data[i:i + 4], byteorder="little")
        lines.append(f"{word:08x}\n")

    Path(sys.argv[2]).write_text("".join(lines), encoding="ascii")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
