#!/usr/bin/env python3
"""Pure RVV fixed-point bit model used by Gemma-private RVV goldens.

This module intentionally imports no RTL or simulator code.  Spike-facing gates validate these
helpers against the architectural RVV semantics before firmware is compared to the golden.
"""
from __future__ import annotations

INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1


def _s32(x: int) -> int:
    x &= 0xFFFF_FFFF
    return x - 0x1_0000_0000 if x & 0x8000_0000 else x


def sat32(x: int) -> int:
    return max(INT32_MIN, min(INT32_MAX, int(x)))


def vxrm_round(prod: int, shift: int, vxrm: int = 0) -> int:
    """RVV rounding increment plus arithmetic right shift.

    vxrm: 0=rnu, 1=rne, 2=rdn, 3=rod.  `prod` is interpreted as a signed two's-complement
    integer of sufficient width; Python's arithmetic right shift and low-bit extraction match
    the architectural formulas for the discarded bits.
    """
    prod = int(prod)
    shift = int(shift)
    vxrm = int(vxrm)
    assert 0 <= shift
    assert 0 <= vxrm <= 3
    if shift == 0:
        return prod

    half = (prod >> (shift - 1)) & 1
    lower = prod & ((1 << (shift - 1)) - 1)
    lsb = (prod >> shift) & 1
    discarded = prod & ((1 << shift) - 1)

    if vxrm == 0:          # rnu: round-to-nearest-up
        inc = half
    elif vxrm == 1:        # rne: round-to-nearest-even
        inc = half & (1 if (lower != 0 or lsb != 0) else 0)
    elif vxrm == 2:        # rdn: round-down/truncate
        inc = 0
    else:                  # rod: round-to-odd
        inc = (0 if lsb else 1) if discarded else 0
    return (prod >> shift) + inc


def vsmul(a32: int, b32: int, vxrm: int = 0) -> int:
    """SEW32 signed saturating rounding fractional multiply."""
    prod = _s32(a32) * _s32(b32)
    return sat32(vxrm_round(prod, 31, vxrm))


def vssra(x32: int, sh: int, vxrm: int = 0) -> int:
    """SEW32 signed scaling shift-right."""
    assert 0 <= int(sh) <= 31
    return _s32(vxrm_round(_s32(x32), int(sh), vxrm))


def sat8(x: int) -> int:
    """Signed int8 saturation before a Zve32x-legal narrow."""
    return max(-128, min(127, int(x)))
