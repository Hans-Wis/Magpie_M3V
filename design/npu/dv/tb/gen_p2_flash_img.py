#!/usr/bin/env python3
"""gate_92/93 flash image (ADR-0071): 16KB byte-hex for spi_nor_model.

Layout (byte offsets):
  0x0000-0x07FF  pattern words  w(o) = 0x5EED0000 + (o>>2)   (LE bytes)
  0x0800-0x080B  XIP-resident routine: li a0,0x51AD600D; ret  (gate_93 calls it)
  0x080C-0x3FFF  pattern words (same formula)
Erase/program playground sectors: 0x1000-0x1FFF and 0x3000-0x3FFF (pattern,
destroyed by gate_92 — goldens outside those sectors stay valid).
"""
from pathlib import Path

IMG = 16384
ROUTINE_OFF = 0x800
# lui a0,0x51AD6 ; addi a0,a0,13 ; jalr x0,x1,0   -> returns 0x51AD600D
ROUTINE = [0x51AD6537, 0x00D50513, 0x00008067]

buf = bytearray()
for o in range(0, IMG, 4):
    w = (0x5EED0000 + (o >> 2)) & 0xFFFFFFFF
    buf += w.to_bytes(4, "little")
for i, w in enumerate(ROUTINE):
    buf[ROUTINE_OFF + 4 * i:ROUTINE_OFF + 4 * i + 4] = w.to_bytes(4, "little")

out = Path(__file__).parent / "xip_img_p2.hex"
out.write_text("".join(f"{b:02x}\n" for b in buf))
print(f"wrote {out} ({len(buf)} bytes)")
