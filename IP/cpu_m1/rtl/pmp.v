// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Adapted for Magpie_M1 ADR-0024 from Ibex rtl/ibex_pmp.sv.
// Origin: adapted. Scope: RV32 M-mode PMP, no Smepmp/MSECCFG/debug bypass.

`ifndef MAGPIE_M1_PMP_V
`define MAGPIE_M1_PMP_V

module pmp #(
    parameter PMP_ENTRIES = 0
) (
    input      [32*8-1:0] pmp_addr_i,
    input      [ 8*8-1:0] pmp_cfg_i,
    input      [31:0]     req_addr_i,
    input                 req_exec_i,
    input                 req_write_i,
    input                 req_read_i,
    output reg            fault_o
);
    localparam [1:0] PMP_A_OFF   = 2'b00;
    localparam [1:0] PMP_A_TOR   = 2'b01;
    localparam [1:0] PMP_A_NA4   = 2'b10;
    localparam [1:0] PMP_A_NAPOT = 2'b11;

    // M1A lint fix (Spyglass W122): pass the bus explicitly — a hierarchical read inside
    // a function is not inferred into @* sensitivity by all tools.
    function [31:0] addr_at;
        input [32*8-1:0] bus;
        input integer idx;
        begin
            addr_at = bus[idx*32 +: 32];
        end
    endfunction

    function napot_match;
        input [31:0] req_addr;
        input [31:0] pmp_addr;
        integer ones;
        integer i;
        reg [31:0] byte_mask;
        reg [31:0] base_addr;
        begin
            ones = 0;
            for (i = 0; i < 32; i = i + 1) begin
                if ((pmp_addr[i] == 1'b1) && (ones == i))
                    ones = i + 1;
            end
            if (ones >= 29)
                byte_mask = 32'hffff_ffff;
            else
                byte_mask = (32'h1 << (ones + 3)) - 32'h1;
            base_addr = (pmp_addr << 2) & ~byte_mask;
            napot_match = ((req_addr & ~byte_mask) == base_addr);
        end
    endfunction

    integer r;
    reg matched;
    reg [7:0] cfg;
    reg [31:0] this_addr;
    reg [31:0] prev_addr;
    reg [31:0] tor_start;
    reg [31:0] tor_end;
    reg region_match;
    reg perm_ok;

    always @* begin
        fault_o = 1'b0;
        matched = 1'b0;
        perm_ok = 1'b0;
        for (r = 0; r < 8; r = r + 1) begin
            if (!matched && (r < PMP_ENTRIES)) begin
                cfg = pmp_cfg_i[r*8 +: 8];
                this_addr = addr_at(pmp_addr_i, r);
                prev_addr = (r == 0) ? 32'h0 : addr_at(pmp_addr_i, r - 1);
                tor_start = prev_addr << 2;
                tor_end = this_addr << 2;
                region_match = 1'b0;
                case (cfg[4:3])
                    PMP_A_OFF:   region_match = 1'b0;
                    PMP_A_TOR:   region_match = (req_addr_i >= tor_start) && (req_addr_i < tor_end);
                    PMP_A_NA4:   region_match = (req_addr_i[31:2] == this_addr[29:0]);
                    PMP_A_NAPOT: region_match = napot_match(req_addr_i, this_addr);
                    default:     region_match = 1'b0;
                endcase

                if (region_match) begin
                    matched = 1'b1;
                    perm_ok = (req_exec_i  && cfg[2]) ||
                              (req_write_i && cfg[1]) ||
                              (req_read_i  && cfg[0]);
                    fault_o = cfg[7] && !perm_ok;
                end
            end
        end
    end
endmodule

`endif
