#!/usr/bin/env python3
"""Generate ADR-0035 command-queue artifacts from the descriptor SSOT.

The .yaml file is intentionally JSON-shaped YAML, so the generator can stay
stdlib-only and deterministic by parsing it with json.load().
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = Path(__file__).with_name("command_descriptor_v0_1.yaml")
HEADER = "GENERATED from command_descriptor_v0_1.yaml - DO NOT EDIT"


def mask(width, lsb):
    return ((1 << width) - 1) << lsb


def load_schema():
    with SCHEMA.open("r", encoding="utf-8") as f:
        return json.load(f)


def emit_rtl(s):
    lines = [
        "// " + HEADER,
        "`ifndef MAGPIE_NPU_CQ_DEFS_VH",
        "`define MAGPIE_NPU_CQ_DEFS_VH",
        "",
    ]
    for op in s["opcodes"]:
        lines.append("localparam CQ_OP_%s = 6'h%02X;" % (op["name"], op["value"]))
    lines.append("")
    for field in s["w0"]["fields"]:
        name = field["name"]
        lines.append("localparam [31:0] CQ_W0_%s_MASK = 32'h%08X;" % (name, mask(field["width"], field["lsb"])))
        lines.append("localparam integer CQ_W0_%s_LSB = %d;" % (name, field["lsb"]))
    lines.append("localparam [31:0] CQ_W0_RSVD_MASK = 32'h%08X;" % s["w0"]["reserved_mask"])
    lines.append("")
    for err in s["err_causes"]:
        lines.append("localparam [31:0] CQ_ERR_%s = 32'h%08X;" % (err["name"], err["value"]))
    lines.append("")
    lines.append("localparam [31:0] CQ_CORE_WINDOW_BASE = 32'h%08X;" % s["csr"]["core_window_base"])
    lines.append("localparam [31:0] CQ_MAILBOX_BASE = 32'h%08X;" % s["csr"]["mailbox_base"])
    for reg in s["csr"]["registers"]:
        lines.append("localparam [7:0] CSR_%s = 8'h%02X;" % (reg["name"], reg["offset"]))
    lines += ["", "`endif", ""]
    return "\n".join(lines)


def emit_c_header(s):
    lines = [
        "/* " + HEADER + " */",
        "#ifndef MAGPIE_NPU_COMMAND_DESCRIPTOR_H",
        "#define MAGPIE_NPU_COMMAND_DESCRIPTOR_H",
        "",
        "#include <stdint.h>",
        "",
        "typedef struct { uint32_t w0, w1, w2, w3; } cq_desc_t;",
        "",
        "typedef enum {",
    ]
    for op in s["opcodes"]:
        lines.append("    CQ_OP_%s = 0x%02X," % (op["name"], op["value"]))
    lines += ["} cq_opcode_t;", "", "typedef enum {"]
    for err in s["err_causes"]:
        lines.append("    CQ_ERR_%s = 0x%02X," % (err["name"], err["value"]))
    lines += ["} cq_err_cause_t;", ""]
    for field in s["w0"]["fields"]:
        name = field["name"]
        lines.append("#define CQ_W0_%s_MASK 0x%08Xu" % (name, mask(field["width"], field["lsb"])))
        lines.append("#define CQ_W0_%s_LSB %du" % (name, field["lsb"]))
    lines.append("#define CQ_W0_RSVD_MASK 0x%08Xu" % s["w0"]["reserved_mask"])
    lines.append("")
    lines += [
        "static inline uint32_t cq_w0_get(uint32_t w0, uint32_t mask, uint32_t lsb)",
        "{",
        "    return (w0 & mask) >> lsb;",
        "}",
        "",
        "static inline uint32_t cq_w0_set(uint32_t w0, uint32_t mask, uint32_t lsb, uint32_t value)",
        "{",
        "    return (w0 & ~mask) | ((value << lsb) & mask);",
        "}",
        "",
        "static inline uint32_t cq_w0_opcode(uint32_t w0) { return cq_w0_get(w0, CQ_W0_OPCODE_MASK, CQ_W0_OPCODE_LSB); }",
        "static inline uint32_t cq_w0_dtype(uint32_t w0) { return cq_w0_get(w0, CQ_W0_DTYPE_MASK, CQ_W0_DTYPE_LSB); }",
        "static inline uint32_t cq_w0_acc(uint32_t w0) { return cq_w0_get(w0, CQ_W0_ACC_MASK, CQ_W0_ACC_LSB); }",
        "static inline uint32_t cq_w0_irq(uint32_t w0) { return cq_w0_get(w0, CQ_W0_IRQ_MASK, CQ_W0_IRQ_LSB); }",
        "static inline uint32_t cq_w0_fence(uint32_t w0) { return cq_w0_get(w0, CQ_W0_FENCE_MASK, CQ_W0_FENCE_LSB); }",
        "static inline uint32_t cq_w0_last(uint32_t w0) { return cq_w0_get(w0, CQ_W0_LAST_MASK, CQ_W0_LAST_LSB); }",
        "static inline uint32_t cq_w0_rpt(uint32_t w0) { return cq_w0_get(w0, CQ_W0_RPT_MASK, CQ_W0_RPT_LSB); }",
        "",
    ]
    lines.append("#define CQ_CORE_WINDOW_BASE 0x%08Xu" % s["csr"]["core_window_base"])
    lines.append("#define CQ_MAILBOX_BASE 0x%08Xu" % s["csr"]["mailbox_base"])
    for reg in s["csr"]["registers"]:
        lines.append("#define CSR_%s 0x%02Xu" % (reg["name"], reg["offset"]))
    lines += ["", "#endif", ""]
    return "\n".join(lines)


def emit_codec(s):
    op_by_name = {op["name"]: op["value"] for op in s["opcodes"]}
    err_by_name = {err["name"]: err["value"] for err in s["err_causes"]}
    regs = {reg["name"]: reg["offset"] for reg in s["csr"]["registers"]}
    lines = [
        "# " + HEADER,
        "",
        "W0_RSVD_MASK = 0x%08X" % s["w0"]["reserved_mask"],
        "OPCODES = %r" % op_by_name,
        "OPCODE_NAMES = {v: k for k, v in OPCODES.items()}",
        "ERR_CAUSES = %r" % err_by_name,
        "CSR_OFFSETS = %r" % regs,
        "",
    ]
    for err in s["err_causes"]:
        lines.append("ERR_%s = %d" % (err["name"], err["value"]))
    lines += [
        "",
        "def _op_value(op):",
        "    if isinstance(op, str):",
        "        key = op.upper()",
        "        if key.startswith('CQ_OP_'):",
        "            key = key[6:]",
        "        if key not in OPCODES:",
        "            raise ValueError('bad opcode %r' % (op,))",
        "        return OPCODES[key]",
        "    if op not in OPCODE_NAMES:",
        "        raise ValueError('bad opcode %r' % (op,))",
        "    return op",
        "",
        "def _w0(op, fields):",
        "    w0 = _op_value(op)",
        "    w0 |= (fields.get('dtype', 0) & 0x3) << 6",
        "    w0 |= (fields.get('acc', 0) & 0xF) << 8",
        "    w0 |= (1 if fields.get('irq', 0) else 0) << 12",
        "    w0 |= (1 if fields.get('fence', 0) else 0) << 13",
        "    w0 |= (1 if fields.get('last', 0) else 0) << 14",
        "    w0 |= (fields.get('rpt', 0) & 0xFF) << 16",
        "    return w0 & 0xFFFFFFFF",
        "",
        "def encode(op, **fields):",
        "    opv = _op_value(op)",
        "    w0 = _w0(opv, fields)",
        "    if opv == OPCODES['MAT_CFG']:",
        "        return [w0, ((fields.get('m', 0) & 0xFFFF) << 16) | (fields.get('n', 0) & 0xFFFF), fields.get('k', 0) & 0xFFFFFFFF, fields.get('tile_flags', 0) & 0xFFFFFFFF]",
        "    if opv == OPCODES['MAT_LOAD_W']:",
        "        lw_stride = fields.get('src_row_stride_bytes', fields.get('stride', 0))",
        "        return [w0, fields.get('src_addr', 0) & 0xFFFFFFFF, lw_stride & 0xFFFFFFFF, ((fields.get('rows', 0) & 0xFF) << 8) | (fields.get('cols', 0) & 0xFF)]",
        "    if opv == OPCODES['MAT_OP']:",
        "        return [w0, fields.get('a_addr', 0) & 0xFFFFFFFF, fields.get('b_addr', 0) & 0xFFFFFFFF, ((fields.get('acc_r', 0) & 0xF) << 4) | (fields.get('acc_c', 0) & 0xF)]",
        "    if opv == OPCODES['MAT_RESCALE']:",
        "        if fields.get('param_ptr') is not None:",
        "            w0 = (w0 & 0xFF00FFFF) | (1 << 16)",
        "            return [w0, fields.get('param_ptr', 0) & 0xFFFFFFFF, ((fields.get('out_zp', 0) & 0xFF) << 8), ((fields.get('clamp_max', 0) & 0xFF) << 8) | (fields.get('clamp_min', 0) & 0xFF)]",
        "        return [w0, fields.get('multiplier_q31', 0) & 0xFFFFFFFF, ((fields.get('out_zp', 0) & 0xFF) << 8) | (fields.get('shift', 0) & 0xFF), ((fields.get('clamp_max', 0) & 0xFF) << 8) | (fields.get('clamp_min', 0) & 0xFF)]",
        "    if opv == OPCODES['MAT_STORE']:",
        "        src = fields.get('src_tcm_byte', fields.get('stride', 0))",
        "        return [w0, fields.get('dst_addr', 0) & 0xFFFFFFFF, src & 0xFFFFFFFF, ((fields.get('dst_stride_words', 0) & 0xFFFF) << 16) | ((fields.get('rows', 0) & 0xFF) << 8) | (fields.get('cols', 0) & 0xFF)]",
        "    if opv == OPCODES['MAT_ACC_CLR']:",
        "        return [w0, fields.get('acc_mask', 0) & 0xFFFFFFFF, fields.get('bias_tcm_byte', 0) & 0xFFFFFFFF, 0]",
        "    if opv == OPCODES['MAT_FENCE']:",
        "        return [w0, 0, 0, 0]",
        "    if opv == OPCODES['MAT_ACT_LUT']:",
        "        return [w0, fields.get('src', 0) & 0xFFFFFFFF, fields.get('dst', 0) & 0xFFFFFFFF, fields.get('lut', 0) & 0xFFFFFFFF]",
        "    if opv == OPCODES['MAT_EWISE_MUL']:",
        "        return [w0, fields.get('multiplier_q31', 0) & 0xFFFFFFFF, ((fields.get('src_a', 0) & 0xFFFF) << 16) | (fields.get('src_b', 0) & 0xFFFF), ((fields.get('dst', 0) & 0xFFFF) << 16) | (fields.get('shift', 0) & 0xFF)]",
        "    raise ValueError('bad opcode %r' % (op,))",
        "",
        "def decode(words):",
        "    if len(words) != 4:",
        "        raise ValueError('descriptor must have 4 words')",
        "    w0, w1, w2, w3 = [x & 0xFFFFFFFF for x in words]",
        "    if w0 & W0_RSVD_MASK:",
        "        raise ValueError('reserved W0 bits set')",
        "    opv = w0 & 0x3F",
        "    if opv not in OPCODE_NAMES:",
        "        raise ValueError('bad opcode 0x%02x' % opv)",
        "    d = {'op': OPCODE_NAMES[opv], 'opcode': opv, 'dtype': (w0 >> 6) & 0x3, 'acc': (w0 >> 8) & 0xF, 'irq': (w0 >> 12) & 1, 'fence': (w0 >> 13) & 1, 'last': (w0 >> 14) & 1, 'rpt': (w0 >> 16) & 0xFF}",
        "    if opv == OPCODES['MAT_CFG']:",
        "        d.update({'m': (w1 >> 16) & 0xFFFF, 'n': w1 & 0xFFFF, 'k': w2, 'tile_flags': w3})",
        "    elif opv == OPCODES['MAT_LOAD_W']:",
        "        d.update({'src_addr': w1, 'stride': w2, 'rows': (w3 >> 8) & 0xFF, 'cols': w3 & 0xFF})",
        "    elif opv == OPCODES['MAT_OP']:",
        "        d.update({'a_addr': w1, 'b_addr': w2, 'acc_r': (w3 >> 4) & 0xF, 'acc_c': w3 & 0xF})",
        "    elif opv == OPCODES['MAT_RESCALE']:",
        "        if d['rpt'] == 1:",
        "            d.update({'param_ptr': w1, 'out_zp': (w2 >> 8) & 0xFF, 'clamp_max': (w3 >> 8) & 0xFF, 'clamp_min': w3 & 0xFF})",
        "        else:",
        "            d.update({'multiplier_q31': w1, 'out_zp': (w2 >> 8) & 0xFF, 'shift': w2 & 0xFF, 'clamp_max': (w3 >> 8) & 0xFF, 'clamp_min': w3 & 0xFF})",
        "    elif opv == OPCODES['MAT_STORE']:",
        "        d.update({'dst_addr': w1, 'src_tcm_byte': w2, 'stride': w2, 'dst_stride_words': (w3 >> 16) & 0xFFFF, 'rows': (w3 >> 8) & 0xFF, 'cols': w3 & 0xFF})",
        "    elif opv == OPCODES['MAT_ACC_CLR']:",
        "        d.update({'acc_mask': w1, 'bias_tcm_byte': w2})",
        "    elif opv == OPCODES['MAT_ACT_LUT']:",
        "        d.update({'src': w1, 'dst': w2, 'lut': w3, 'len': d['rpt']})",
        "    elif opv == OPCODES['MAT_EWISE_MUL']:",
        "        d.update({'multiplier_q31': w1, 'src_a': (w2 >> 16) & 0xFFFF, 'src_b': w2 & 0xFFFF, 'dst': (w3 >> 16) & 0xFFFF, 'shift': w3 & 0xFF, 'len': d['rpt']})",
        "    return d",
        "",
        "def _self_test():",
        "    samples = {",
        "        'MAT_CFG': dict(m=8, n=8, k=16, tile_flags=3, last=1),",
        "        'MAT_LOAD_W': dict(src_addr=0x800, stride=0, rows=4, cols=4),",
        "        'MAT_OP': dict(a_addr=0x10, b_addr=0x20, acc_r=1, acc_c=2),",
        "        'MAT_RESCALE': dict(multiplier_q31=0x40000000, out_zp=1, shift=7, clamp_max=127, clamp_min=128),",
        "        'MAT_STORE': dict(dst_addr=0x1000, stride=0, rows=4, cols=4, irq=1),",
        "        'MAT_ACC_CLR': dict(acc_mask=0x5, bias_tcm_byte=0x600),",
        "        'MAT_FENCE': dict(fence=1),",
        "        'MAT_ACT_LUT': dict(src=0x100, dst=0x200, lut=0x300, rpt=128),",
        "        'MAT_EWISE_MUL': dict(multiplier_q31=0x40000000, src_a=0x100, src_b=0x200, dst=0x300, shift=38, rpt=128),",
        "    }",
        "    for name, fields in samples.items():",
        "        words = encode(name, **fields)",
        "        assert decode(words)['op'] == name",
        "    try:",
        "        decode([0x00008001, 0, 0, 0])",
        "    except ValueError:",
        "        pass",
        "    else:",
        "        raise AssertionError('reserved violation was accepted')",
        "    print('cq_codec self-test PASS')",
        "",
        "if __name__ == '__main__':",
        "    _self_test()",
        "",
    ]
    return "\n".join(lines)


def write_if_changed(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    old = path.read_text(encoding="utf-8") if path.exists() else None
    if old != data:
        path.write_text(data, encoding="utf-8")


def main():
    s = load_schema()
    write_if_changed(ROOT / "rtl" / "cq_defs.vh", emit_rtl(s))
    write_if_changed(ROOT / "sw" / "include" / "command_descriptor.h", emit_c_header(s))
    write_if_changed(ROOT / "sw" / "cq_codec.py", emit_codec(s))


if __name__ == "__main__":
    main()
