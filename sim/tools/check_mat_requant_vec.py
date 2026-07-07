#!/usr/bin/env python3
"""ADR-0066 E1a: LOADVEC -> RESCALE bit-exact proof for mat_engine.

This is intentionally standalone: it builds a tiny Verilator TB in /tmp, drives
CMD_LOADVEC with 64 distinct int32 values, then drives the existing CMD_RESCALE
datapath and compares all 64 bytes against design/npu/golden/mat_golden.py.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "design/npu/golden"))
import mat_golden  # noqa: E402


SRC_BASE = 0x100
DST_BASE = 0x300

VALUES = [
    mat_golden.I32_MIN, mat_golden.I32_MIN + 1, -1000003, mat_golden.I32_MAX,
] + list(range(-37, 23))

CASES = [
    {
        "name": "order_corners",
        "mult": 0x7FFFFFFF,
        "shift": 31,
        "zp": 0,
        "cmin": -128,
        "cmax": 127,
    },
    {
        "name": "shift62_boundary",
        "mult": 0x40000000,
        "shift": 62,
        "zp": -3,
        "cmin": -100,
        "cmax": 100,
    },
]


def u32(v: int) -> int:
    return v & 0xFFFF_FFFF


def u8(v: int) -> int:
    return v & 0xFF


def verilator_bin() -> str:
    return (
        os.environ.get("VERILATOR")
        or shutil.which("verilator")
        or "/home/edauser/miniforge3/envs/magpie_claude/bin/verilator"
    )


def build_tb() -> str:
    assert len(VALUES) == 64
    assert len(set(VALUES)) == 64, "LOADVEC stimulus must use 64 distinct int32 values"
    for case in CASES:
        exp = [
            mat_golden.rescale(v, case["mult"], case["shift"], case["zp"],
                               case["cmin"], case["cmax"]) & 0xFF
            for v in VALUES
        ]
        case["expected"] = exp
    assert len(set(CASES[0]["expected"])) > 48, "order case needs varied outputs"

    lines = [
        "`default_nettype none",
        "`timescale 1ns/1ps",
        "module tb_mat_requant_vec;",
        "    reg clk = 1'b0;",
        "    reg resetn = 1'b0;",
        "    always #5 clk = ~clk;",
        "    reg go = 1'b0;",
        "    reg [2:0] cmd = 3'd0;",
        "    reg [3:0] arg_bank = 4'd0;",
        "    reg [7:0] arg_rpt = 8'd0;",
        "    reg [31:0] a_addr = 32'd0, b_addr = 32'd0, rs_mult = 32'd0, out_base = 32'd0;",
        "    reg [7:0] rs_shift = 8'd0, rs_zp = 8'd0, rs_min = 8'd0, rs_max = 8'd0;",
        "    wire busy, done, err_param, t_a_re, t_b_re, t_we;",
        "    wire [9:0] t_a_addr, t_b_addr, t_waddr;",
        "    wire [31:0] t_wdata;",
        "    reg [31:0] mem [0:1023];",
        "    reg [7:0] exp [0:63];",
        "    wire [255:0] t_a_rdata, t_b_rdata;",
        "    genvar gw;",
        "    generate",
        "        for (gw = 0; gw < 8; gw = gw + 1) begin : g_wide",
        "            assign t_a_rdata[gw*32 +: 32] = mem[t_a_addr + gw[9:0]];",
        "            assign t_b_rdata[gw*32 +: 32] = mem[t_b_addr + gw[9:0]];",
        "        end",
        "    endgenerate",
        "    always @(posedge clk) if (t_we) mem[t_waddr] <= t_wdata;",
        "    mat_engine #(.TCM_AW(10)) dut (",
        "        .clk(clk), .resetn(resetn), .go(go), .abort_i(1'b0),",
        "        .cmd(cmd), .arg_bank(arg_bank), .arg_rpt(arg_rpt),",
        "        .a_addr(a_addr), .b_addr(b_addr), .rs_mult(rs_mult),",
        "        .rs_shift(rs_shift), .rs_zp(rs_zp), .rs_min(rs_min),",
        "        .rs_max(rs_max), .out_base(out_base), .busy(busy),",
        "        .done(done), .err_param(err_param), .t_a_re(t_a_re),",
        "        .t_a_addr(t_a_addr), .t_a_rdata(t_a_rdata), .t_b_re(t_b_re),",
        "        .t_b_addr(t_b_addr), .t_b_rdata(t_b_rdata), .t_we(t_we),",
        "        .t_waddr(t_waddr), .t_wdata(t_wdata)",
        "    );",
        "    integer errors = 0;",
        "    integer checks = 0;",
        "    integer i;",
        "    task pulse_go;",
        "        integer guard;",
        "        begin",
        "            @(negedge clk); go = 1'b1;",
        "            @(negedge clk); go = 1'b0;",
        "            guard = 0;",
        "            while (!done && guard < 1000) begin @(posedge clk); guard = guard + 1; end",
        "            if (!done) begin errors = errors + 1; $display(\"FAIL: engine timeout cmd=%0d\", cmd); end",
        "        end",
        "    endtask",
        "    task dump_actual;",
        "        begin",
        "            $write(\"actual bytes:\");",
        "            for (i = 0; i < 64; i = i + 1)",
        f"                $write(\" %02x\", mem[(32'h{DST_BASE:08x} >> 2) + i[7:2]][(i%4)*8 +: 8]);",
        "            $write(\"\\n\");",
        "        end",
        "    endtask",
        "    task check_outputs;",
        "        input [8*32-1:0] name;",
        "        reg failed;",
        "        reg [7:0] got;",
        "        begin",
        "            failed = 1'b0;",
        "            for (i = 0; i < 64; i = i + 1) begin",
        "                checks = checks + 1;",
        f"                got = mem[(32'h{DST_BASE:08x} >> 2) + i[7:2]][(i%4)*8 +: 8];",
        "                if (got !== exp[i]) begin",
        "                    failed = 1'b1;",
        "                    errors = errors + 1;",
        "                    $display(\"FAIL %0s[%0d]: got %02x exp %02x\", name, i, got, exp[i]);",
        "                end",
        "            end",
        "            if (failed) dump_actual();",
        "            else $display(\"PASS %0s\", name);",
        "        end",
        "    endtask",
        "    task load_values;",
        "        begin",
    ]
    for i, v in enumerate(VALUES):
        lines.append(f"            mem[(32'h{SRC_BASE:08x} >> 2) + {i}] = 32'h{u32(v):08x};")
    lines += [
        "        end",
        "    endtask",
    ]
    for ci, case in enumerate(CASES):
        lines += [
            f"    task load_expected_{ci};",
            "        begin",
        ]
        for i, b in enumerate(case["expected"]):
            lines.append(f"            exp[{i}] = 8'h{b:02x};")
        lines += [
            "        end",
            "    endtask",
        ]
    lines += [
        "    initial begin",
        "        for (i = 0; i < 1024; i = i + 1) mem[i] = 32'h0;",
        "        repeat (4) @(posedge clk);",
        "        resetn = 1'b1;",
        "        @(posedge clk);",
    ]
    for ci, case in enumerate(CASES):
        lines += [
            "        load_values();",
            f"        load_expected_{ci}();",
            "        cmd = 3'd5; arg_bank = 4'd1; arg_rpt = 8'd1;",
            f"        a_addr = 32'h{SRC_BASE:08x};",
            "        pulse_go();",
            "        checks = checks + 1;",
            "        if (err_param) begin errors = errors + 1; $display(\"FAIL: LOADVEC unexpectedly errored\"); end",
            "        cmd = 3'd2; arg_bank = 4'd1; arg_rpt = 8'd1;",
            f"        rs_mult = 32'h{case['mult']:08x};",
            f"        rs_shift = 8'd{case['shift']};",
            f"        rs_zp = 8'h{u8(case['zp']):02x};",
            f"        rs_min = 8'h{u8(case['cmin']):02x};",
            f"        rs_max = 8'h{u8(case['cmax']):02x};",
            f"        out_base = 32'h{DST_BASE:08x};",
            "        pulse_go();",
            "        checks = checks + 1;",
            "        if (err_param) begin errors = errors + 1; $display(\"FAIL: RESCALE unexpectedly errored\"); end",
            f"        check_outputs(\"{case['name']}\");",
        ]
    lines += [
        "        cmd = 3'd5; arg_bank = 4'd4; a_addr = 32'h00000100;",
        "        pulse_go();",
        "        checks = checks + 1;",
        "        if (!err_param) begin errors = errors + 1; $display(\"FAIL: LOADVEC bank>=4 not flagged\"); end",
        "        cmd = 3'd5; arg_bank = 4'd0; a_addr = 32'h00000104;",
        "        pulse_go();",
        "        checks = checks + 1;",
        "        if (!err_param) begin errors = errors + 1; $display(\"FAIL: LOADVEC misaligned src not flagged\"); end",
        "        if (errors == 0) $display(\"MAT_REQUANT_VEC_PASS checks=%0d\", checks);",
        "        else $display(\"MAT_REQUANT_VEC_FAIL errors=%0d checks=%0d\", errors, checks);",
        "        $finish;",
        "    end",
        "endmodule",
        "`default_nettype wire",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    verilator = verilator_bin()
    if not Path(verilator).exists() and shutil.which(verilator) is None:
        print(f"FAIL: verilator not found: {verilator}", file=sys.stderr)
        return 1

    with tempfile.TemporaryDirectory(prefix="mat_requant_vec_", dir="/tmp") as td:
        tdir = Path(td)
        tb = tdir / "tb_mat_requant_vec.v"
        tb.write_text(build_tb(), encoding="utf-8")
        cmd = [
            verilator,
            "--binary",
            "--timing",
            "-j",
            "4",
            "-Wno-fatal",
            "--top-module",
            "tb_mat_requant_vec",
            "--timescale",
            "1ns/1ps",
            "-Wno-DECLFILENAME",
            "-Wno-UNUSEDSIGNAL",
            str(ROOT / "design/npu/rtl/mat_engine.v"),
            str(tb),
        ]
        build = subprocess.run(cmd, cwd=tdir, text=True, capture_output=True)
        if build.returncode != 0:
            print(build.stdout, end="")
            print(build.stderr, end="", file=sys.stderr)
            return build.returncode
        sim = subprocess.run([str(tdir / "obj_dir/Vtb_mat_requant_vec")],
                             cwd=tdir, text=True, capture_output=True)
        print(sim.stdout, end="")
        if sim.stderr:
            print(sim.stderr, end="", file=sys.stderr)
        if sim.returncode != 0:
            return sim.returncode
        return 0 if "MAT_REQUANT_VEC_PASS" in sim.stdout else 1


if __name__ == "__main__":
    raise SystemExit(main())
