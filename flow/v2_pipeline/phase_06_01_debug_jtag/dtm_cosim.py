"""Magpie_M1 ADR-0021 Slice B JTAG bit-bang helper.

Adapted from first-party source:
  ~/project/RISC-V/magpie/Magpie_X1/rtl_cosim/dtm_cosim.py

This phase uses the Verilog testbench tasks in ``tb_debug_jtag.v`` for the
checked simulation. This Python helper preserves the same LSB-first TAP/DMI
transaction sequencing for future C-ABI or socket-backed cosim drivers.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


IR_IDCODE = 0x01
IR_DTMCS = 0x10
IR_DMI = 0x11

DMI_OP_NOP = 0
DMI_OP_READ = 1
DMI_OP_WRITE = 2

DTM_IDCODE_EXPECTED = 0x10A9_8AD3

DMI_DATA0 = 0x04
DMI_DMCONTROL = 0x10
DMI_DMSTATUS = 0x11
DMI_ABSTRACTCS = 0x16
DMI_COMMAND = 0x17

DMCTRL_DMACTIVE = 0
DMCTRL_RESUMEREQ = 30
DMCTRL_HALTREQ = 31


class JtagPins(Protocol):
    """Minimal pin-level backend for a JTAG TAP."""

    def step(self, tms: int, tdi: int) -> int:
        """Pulse TCK once with TMS/TDI staged; return sampled TDO."""


@dataclass
class DtmBitBang:
    """LSB-first JTAG DTM accessors for the Magpie_M1 DTM."""

    pins: JtagPins

    def reset_to_rti(self, cycles: int = 6) -> None:
        for _ in range(cycles):
            self.pins.step(1, 0)
        self.pins.step(0, 0)

    def shift_ir(self, ir: int, ir_len: int = 5) -> None:
        self.pins.step(1, 0)  # RTI -> Select-DR
        self.pins.step(1, 0)  # Select-DR -> Select-IR
        self.pins.step(0, 0)  # Select-IR -> Capture-IR
        self.pins.step(0, 0)  # Capture-IR -> Shift-IR
        for bit in range(ir_len):
            self.pins.step(1 if bit == ir_len - 1 else 0, (ir >> bit) & 1)
        self.pins.step(1, 0)  # Exit1-IR -> Update-IR
        self.pins.step(0, 0)  # Update-IR -> RTI

    def shift_dr(self, data_in: int, length: int) -> int:
        self.pins.step(1, 0)  # RTI -> Select-DR
        self.pins.step(0, 0)  # Select-DR -> Capture-DR
        self.pins.step(0, 0)  # Capture-DR -> Shift-DR
        data_out = 0
        for bit in range(length):
            tdo = self.pins.step(1 if bit == length - 1 else 0, (data_in >> bit) & 1)
            data_out |= (tdo & 1) << bit
        self.pins.step(1, 0)  # Exit1-DR -> Update-DR
        self.pins.step(0, 0)  # Update-DR -> RTI
        return data_out

    def read_idcode(self) -> int:
        self.shift_ir(IR_IDCODE)
        return self.shift_dr(0, 32)

    def read_dtmcs(self) -> int:
        self.shift_ir(IR_DTMCS)
        return self.shift_dr(0, 32)

    def dmi_op(self, addr: int, data: int, op: int) -> tuple[int, int]:
        self.shift_ir(IR_DMI)
        scan_in = ((addr & 0x7F) << 34) | ((data & 0xFFFFFFFF) << 2) | (op & 0x3)
        scan_out = self.shift_dr(scan_in, 41)
        return (scan_out >> 2) & 0xFFFFFFFF, scan_out & 0x3

    def dmi_write(self, addr: int, data: int) -> None:
        self.dmi_op(addr, data, DMI_OP_WRITE)

    def dmi_read(self, addr: int) -> int:
        self.dmi_op(addr, 0, DMI_OP_READ)
        data, stat = self.dmi_op(0, 0, DMI_OP_NOP)
        if stat != 0:
            raise RuntimeError(f"DMI read failed: addr=0x{addr:02x} dmistat={stat}")
        return data

    def activate(self) -> None:
        self.dmi_write(DMI_DMCONTROL, 1 << DMCTRL_DMACTIVE)

    def halt_request(self) -> None:
        self.dmi_write(DMI_DMCONTROL, (1 << DMCTRL_HALTREQ) | (1 << DMCTRL_DMACTIVE))

    def resume_request(self) -> None:
        self.dmi_write(DMI_DMCONTROL, (1 << DMCTRL_RESUMEREQ) | (1 << DMCTRL_DMACTIVE))
