//      // verilator_coverage annotation
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
%000000     input      [32*8-1:0] pmp_addr_i,
%000000     input      [ 8*8-1:0] pmp_cfg_i,
 000493     input      [31:0]     req_addr_i,
~000010     input                 req_exec_i,
 000028     input                 req_write_i,
 000029     input                 req_read_i,
%000000     output reg            fault_o
        );
            localparam [1:0] PMP_A_OFF   = 2'b00;
            localparam [1:0] PMP_A_TOR   = 2'b01;
            localparam [1:0] PMP_A_NA4   = 2'b10;
            localparam [1:0] PMP_A_NAPOT = 2'b11;
        
            // M1A lint fix (Spyglass W122): pass the bus explicitly — a hierarchical read inside
            // a function is not inferred into @* sensitivity by all tools.
%000000     function [31:0] addr_at;
                input [32*8-1:0] bus;
                input integer idx;
%000000         begin
%000000             addr_at = bus[idx*32 +: 32];
                end
            endfunction
        
%000000     function napot_match;
                input [31:0] req_addr;
                input [31:0] pmp_addr;
%000000         integer ones;
%000000         integer i;
%000000         reg [31:0] byte_mask;
%000000         reg [31:0] base_addr;
%000000         begin
%000000             ones = 0;
%000000             for (i = 0; i < 32; i = i + 1) begin
%000000                 if ((pmp_addr[i] == 1'b1) && (ones == i))
%000000                     ones = i + 1;
                    end
%000000             if (ones >= 29)
%000000                 byte_mask = 32'hffff_ffff;
                    else
%000000                 byte_mask = (32'h1 << (ones + 3)) - 32'h1;
%000000             base_addr = (pmp_addr << 2) & ~byte_mask;
%000000             napot_match = ((req_addr & ~byte_mask) == base_addr);
                end
            endfunction
        
            integer r;
%000000     reg matched;
%000000     reg [7:0] cfg;
%000000     reg [31:0] this_addr;
%000000     reg [31:0] prev_addr;
%000000     reg [31:0] tor_start;
%000000     reg [31:0] tor_end;
%000000     reg region_match;
%000000     reg perm_ok;
        
 000015     always @* begin
 000015         fault_o = 1'b0;
 000015         matched = 1'b0;
 000015         perm_ok = 1'b0;
 000120         for (r = 0; r < 8; r = r + 1) begin
~000120             if (!matched && (r < PMP_ENTRIES)) begin
%000000                 cfg = pmp_cfg_i[r*8 +: 8];
%000000                 this_addr = addr_at(pmp_addr_i, r);
%000000                 prev_addr = (r == 0) ? 32'h0 : addr_at(pmp_addr_i, r - 1);
%000000                 tor_start = prev_addr << 2;
%000000                 tor_end = this_addr << 2;
%000000                 region_match = 1'b0;
%000000                 case (cfg[4:3])
%000000                     PMP_A_OFF:   region_match = 1'b0;
%000000                     PMP_A_TOR:   region_match = (req_addr_i >= tor_start) && (req_addr_i < tor_end);
%000000                     PMP_A_NA4:   region_match = (req_addr_i[31:2] == this_addr[29:0]);
%000000                     PMP_A_NAPOT: region_match = napot_match(req_addr_i, this_addr);
%000000                     default:     region_match = 1'b0;
                        endcase
        
%000000                 if (region_match) begin
%000000                     matched = 1'b1;
%000000                     perm_ok = (req_exec_i  && cfg[2]) ||
%000000                               (req_write_i && cfg[1]) ||
%000000                               (req_read_i  && cfg[0]);
%000000                     fault_o = cfg[7] && !perm_ok;
                        end
                    end
                end
            end
        endmodule
        
        `endif
        
