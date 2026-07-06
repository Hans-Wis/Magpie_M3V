// AXI4-full read/write memory model for CQ smoke tests.
// One shared mem[] backs the read DMA source and writeback target.
`default_nettype none
module axi_full_rwmem #(parameter integer WORDS = 16384, parameter integer AW = 14, parameter ERR_MODE = 0) (
    input  wire clk, input wire resetn,
    input  wire        arvalid, output reg  arready, input wire [31:0] araddr,
    input  wire [7:0]  arlen,   input wire [2:0] arsize, input wire [1:0] arburst,
    output reg         rvalid,  input  wire rready, output reg [31:0] rdata,
    output reg         rlast,   output wire [1:0] rresp,
    input  wire        awvalid, output reg  awready, input wire [31:0] awaddr,
    input  wire [7:0]  awlen,   input wire [2:0] awsize, input wire [1:0] awburst,
    input  wire        wvalid,  output reg  wready, input wire [31:0] wdata, input wire [3:0] wstrb, input wire wlast,
    output reg         bvalid,  input  wire bready, output wire [1:0] bresp
);
    assign rresp = ERR_MODE ? 2'b10 : 2'b00;
    assign bresp = ERR_MODE ? 2'b10 : 2'b00;

    reg [31:0] mem [0:WORDS-1];

    function [31:0] merge; input [31:0] old; input [31:0] wd; input [3:0] strb; begin
        merge = { strb[3]?wd[31:24]:old[31:24], strb[2]?wd[23:16]:old[23:16],
                  strb[1]?wd[15:8]:old[15:8],   strb[0]?wd[7:0]:old[7:0] };
    end endfunction

    localparam R_IDLE=1'b0, R_DATA=1'b1;
    reg        rstate;
    reg [31:0] rptr;
    reg [8:0]  rbeats_left;

    always @(posedge clk) begin
        if (!resetn) begin
            rstate <= R_IDLE; arready <= 1'b1; rvalid <= 1'b0; rlast <= 1'b0;
        end else case (rstate)
            R_IDLE: begin
                rvalid <= 1'b0; rlast <= 1'b0; arready <= 1'b1;
                if (arvalid && arready) begin
                    rptr <= {18'b0, araddr[AW+1:2]};
                    rbeats_left <= {1'b0, arlen} + 9'd1;
                    arready <= 1'b0;
                    rvalid <= 1'b1;
                    rdata <= mem[araddr[AW+1:2]];
                    rlast <= (arlen == 8'd0);
                    rstate <= R_DATA;
                end
            end
            R_DATA: if (rvalid && rready) begin
                if (rlast) begin
                    rvalid <= 1'b0; rlast <= 1'b0; arready <= 1'b1; rstate <= R_IDLE;
                end else begin
                    rptr <= rptr + 1'b1;
                    rdata <= mem[rptr[AW-1:0] + 1'b1];
                    rbeats_left <= rbeats_left - 9'd1;
                    rlast <= (rbeats_left == 9'd2);
                end
            end
        endcase
    end

    localparam W_IDLE=2'd0, W_DATA=2'd1, W_RESP=2'd2;
    reg [1:0]  wstate;
    reg [31:0] wptr;

    always @(posedge clk) begin
        if (!resetn) begin
            wstate <= W_IDLE; awready <= 1'b1; wready <= 1'b0; bvalid <= 1'b0;
        end else case (wstate)
            W_IDLE: begin
                bvalid <= 1'b0; awready <= 1'b1; wready <= 1'b0;
                if (awvalid && awready) begin
                    wptr <= {18'b0, awaddr[AW+1:2]};
                    awready <= 1'b0;
                    wready <= 1'b1;
                    wstate <= W_DATA;
                end
            end
            W_DATA: if (wvalid && wready) begin
                mem[wptr[AW-1:0]] <= merge(mem[wptr[AW-1:0]], wdata, wstrb);
                wptr <= wptr + 1'b1;
                if (wlast) begin
                    wready <= 1'b0;
                    bvalid <= 1'b1;
                    wstate <= W_RESP;
                end
            end
            W_RESP: if (bvalid && bready) begin
                bvalid <= 1'b0;
                awready <= 1'b1;
                wstate <= W_IDLE;
            end
            default: wstate <= W_IDLE;
        endcase
    end
endmodule
`default_nettype wire
