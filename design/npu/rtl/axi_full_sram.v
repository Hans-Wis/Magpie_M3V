// =============================================================================
// axi_full_sram.v — byte-lane SRAM behind a minimal AXI4-full slave
// -----------------------------------------------------------------------------
// Single-outstanding read and write channels. Supports 32-bit INCR bursts up to
// AXI len=255. Address decode uses the low address bits, so both zero-based DMA
// addresses and the host's 0x8000_xxxx shared-memory window alias the same SRAM.
// =============================================================================
`default_nettype none

module axi_full_sram #(
    parameter integer WORDS = 16384,
    parameter integer AW    = 14,
    parameter [1023:0] INIT_HEX = ""
) (
    input  wire clk,
    input  wire resetn,

    input  wire        arvalid,
    output reg         arready,
    input  wire [31:0] araddr,
    input  wire [ 7:0] arlen,
    input  wire [ 2:0] arsize,
    input  wire [ 1:0] arburst,
    output reg         rvalid,
    input  wire        rready,
    output reg  [31:0] rdata,
    output reg         rlast,
    output wire [ 1:0] rresp,

    input  wire        awvalid,
    output reg         awready,
    input  wire [31:0] awaddr,
    input  wire [ 7:0] awlen,
    input  wire [ 2:0] awsize,
    input  wire [ 1:0] awburst,
    input  wire        wvalid,
    output reg         wready,
    input  wire [31:0] wdata,
    input  wire [ 3:0] wstrb,
    input  wire        wlast,
    output reg         bvalid,
    input  wire        bready,
    output wire [ 1:0] bresp
);
    assign rresp = 2'b00;
    assign bresp = 2'b00;

    reg [31:0] mem [0:WORDS-1];

    initial begin
        if (INIT_HEX != "") $readmemh(INIT_HEX, mem);
    end

    function [31:0] merge;
        input [31:0] old;
        input [31:0] wd;
        input [3:0]  strb;
        begin
            merge = {strb[3] ? wd[31:24] : old[31:24],
                     strb[2] ? wd[23:16] : old[23:16],
                     strb[1] ? wd[15:8]  : old[15:8],
                     strb[0] ? wd[7:0]   : old[7:0]};
        end
    endfunction

    localparam R_IDLE = 1'b0, R_DATA = 1'b1;
    reg        rstate;
    reg [AW-1:0] rptr;
    reg [8:0]  rbeats_left;

    always @(posedge clk) begin
        if (!resetn) begin
            rstate <= R_IDLE;
            arready <= 1'b1;
            rvalid <= 1'b0;
            rlast <= 1'b0;
            rdata <= 32'b0;
            rptr <= {AW{1'b0}};
            rbeats_left <= 9'b0;
        end else begin
            case (rstate)
                R_IDLE: begin
                    arready <= 1'b1;
                    rvalid <= 1'b0;
                    rlast <= 1'b0;
                    if (arvalid && arready) begin
                        arready <= 1'b0;
                        rstate <= R_DATA;
                        rptr <= araddr[AW+1:2];
                        rbeats_left <= {1'b0, arlen} + 9'd1;
                        rdata <= mem[araddr[AW+1:2]];
                        rvalid <= 1'b1;
                        rlast <= (arlen == 8'd0);
                    end
                end
                R_DATA: begin
                    if (rvalid && rready) begin
                        if (rlast) begin
                            rvalid <= 1'b0;
                            rlast <= 1'b0;
                            arready <= 1'b1;
                            rstate <= R_IDLE;
                        end else begin
                            rptr <= rptr + {{(AW-1){1'b0}}, 1'b1};
                            rbeats_left <= rbeats_left - 9'd1;
                            rdata <= mem[rptr + {{(AW-1){1'b0}}, 1'b1}];
                            rlast <= (rbeats_left == 9'd2);
                        end
                    end
                end
            endcase
        end
    end

    localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
    reg [1:0] wstate;
    reg [AW-1:0] wptr;

    always @(posedge clk) begin
        if (!resetn) begin
            wstate <= W_IDLE;
            awready <= 1'b1;
            wready <= 1'b0;
            bvalid <= 1'b0;
            wptr <= {AW{1'b0}};
        end else begin
            case (wstate)
                W_IDLE: begin
                    awready <= 1'b1;
                    wready <= 1'b0;
                    bvalid <= 1'b0;
                    if (awvalid && awready) begin
                        wptr <= awaddr[AW+1:2];
                        awready <= 1'b0;
                        wready <= 1'b1;
                        wstate <= W_DATA;
                    end
                end
                W_DATA: begin
                    if (wvalid && wready) begin
                        mem[wptr] <= merge(mem[wptr], wdata, wstrb);
                        wptr <= wptr + {{(AW-1){1'b0}}, 1'b1};
                        if (wlast) begin
                            wready <= 1'b0;
                            bvalid <= 1'b1;
                            wstate <= W_RESP;
                        end
                    end
                end
                W_RESP: begin
                    if (bvalid && bready) begin
                        bvalid <= 1'b0;
                        awready <= 1'b1;
                        wstate <= W_IDLE;
                    end
                end
                default: wstate <= W_IDLE;
            endcase
        end
    end

    wire unused_axi = |{arsize, arburst, awlen, awsize, awburst};
endmodule
`default_nettype wire
