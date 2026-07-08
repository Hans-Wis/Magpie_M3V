#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SRC = ROOT / "design/npu/sw/cq_sequencer/firmware.hex"
DST = Path(__file__).resolve().parent / "npu_fw_load.inc"


def parse_verilog_hex(path: Path):
    addr = 0
    out = []
    for raw in path.read_text().split():
        tok = raw.strip()
        if not tok:
            continue
        if tok.startswith("@"):
            addr = int(tok[1:], 16)
            continue
        out.append((addr, int(tok, 16)))
        addr += 1
    return out


def main():
    words = parse_verilog_hex(SRC)
    lines = [
        "/* Generated from design/npu/sw/cq_sequencer/firmware.hex. */",
        "static inline void load_npu_firmware(void)",
        "{",
    ]
    for idx, word in words:
        byte_off = idx * 4
        lines.append(f"    store32(0x30010000u + 0x{byte_off:04X}u, 0x{word:08X}u);")
        lines.append(f"    store32(0x30020000u + 0x{byte_off:04X}u, 0x{word:08X}u);")
    lines.append("}")
    DST.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
