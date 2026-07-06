// =============================================================================
// axil_bootrom.v — tiny AXI4-Lite read-only boot ROM (LUT-based)
// -----------------------------------------------------------------------------
// Holds a minimal reset stub that jumps to RAM_BASE (or loops, for debug). The
// CPU's reset vector (RESET_PC=0) lands here; the stub redirects execution to
// the program loaded in RAM. ~8 word slots; synthesizes to a handful of LUTs
// (FPGA) or a small std-cell ROM (ASIC).
//
// Default stub (MODE_JUMP): lui x5, RAM_BASE[31:12]; jalr x0, x5, RAM_BASE[11:0]
// Debug stub  (MODE_DEBUG): j . (spin) — for first bring-up without a program.
// =============================================================================
`default_nettype none

module axil_bootrom #(
    parameter [31:0] RAM_BASE = 32'h2000_0000,
    parameter        MODE_DEBUG = 1'b0          // 1 = spin-forever stub
)(
    input  wire        clk,
    input  wire        resetn,
    // AXI4-Lite slave (read-only)
    input  wire        s_arvalid,
    output wire        s_arready,
    input  wire [31:0] s_araddr,
    input  wire        s_rready,
    output reg         s_rvalid,
    output reg  [31:0] s_rdata,
    output wire [ 1:0] s_rresp
);
    // 8-word ROM, addressed by araddr[4:2]
    function [31:0] rom_word(input [2:0] idx);
        if (MODE_DEBUG) begin
            rom_word = 32'h0000_006f;                 // 0: jal x0, 0  (j . spin)
        end else begin
            case (idx)
                3'd0: rom_word = {RAM_BASE[31:12], 5'd5, 7'b0110111};            // lui  x5, RAM_BASE[31:12]
                3'd1: rom_word = {RAM_BASE[11:0], 5'd5, 3'b000, 5'd0, 7'b1100111};// jalr x0, RAM_BASE[11:0](x5)
                default: rom_word = 32'h0000_0013;                               // nop (addi x0,x0,0)
            endcase
        end
    endfunction

    assign s_arready = !s_rvalid;                  // accept AR when no pending R
    assign s_rresp   = 2'b00;                       // OKAY

    reg [2:0] idx_q;
    always @(posedge clk) begin
        if (!resetn) begin
            s_rvalid <= 1'b0;
        end else begin
            if (s_arvalid && s_arready) begin
                idx_q    <= s_araddr[4:2];
                s_rvalid <= 1'b1;
                s_rdata  <= rom_word(s_araddr[4:2]);
            end else if (s_rvalid && s_rready) begin
                s_rvalid <= 1'b0;
            end
        end
    end
endmodule
`default_nettype wire
