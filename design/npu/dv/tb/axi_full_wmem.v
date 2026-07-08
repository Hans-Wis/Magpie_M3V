// AXI4-full write+read memory model (shared-mem target for the writeback DMA test).
// Accepts INCR write bursts (AW/W/B) and stores into mem[]; the tb back-door reads mem[]
// to compare against the TCM golden. ERR_MODE=1 makes every B return SLVERR (error-inject).
// Single-outstanding write. A minimal read side (AR/R) is provided but unused by the WB test.
`default_nettype none
module axi_full_wmem #(
    parameter integer WORDS = 8192,
    parameter integer AW = 13,
    parameter integer DMA_DATA_W = 32,
    parameter ERR_MODE = 0
) (
    input  wire clk, input wire resetn,
    // write address / data / response
    input  wire        awvalid, output reg  awready, input wire [31:0] awaddr,
    input  wire [7:0]  awlen,   input wire [2:0] awsize, input wire [1:0] awburst,
    input  wire        wvalid,  output reg  wready,  input wire [DMA_DATA_W-1:0] wdata, input wire [DMA_DATA_W/8-1:0] wstrb, input wire wlast,
    output reg         bvalid,  input  wire bready,  output wire [1:0] bresp
);
    assign bresp = ERR_MODE ? 2'b10 : 2'b00;
    localparam integer WPB = DMA_DATA_W / 32;
    reg [31:0] mem [0:WORDS-1];
    integer k;
    initial for (k = 0; k < WORDS; k = k + 1) mem[k] = 32'h0;

    // byte-strobe merge
    function [31:0] merge; input [31:0] old; input [31:0] wd; input [3:0] strb; begin
        merge = { strb[3]?wd[31:24]:old[31:24], strb[2]?wd[23:16]:old[23:16],
                  strb[1]?wd[15:8]:old[15:8],   strb[0]?wd[7:0]:old[7:0] };
    end endfunction

    localparam S_IDLE=2'd0, S_W=2'd1, S_B=2'd2;
    reg [1:0]  state;
    reg [31:0] wptr;      // current word index
    reg [31:0] wstride;
    integer wj;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; awready <= 1'b1; wready <= 1'b0; bvalid <= 1'b0;
        end else case (state)
            S_IDLE: begin
                bvalid <= 1'b0; awready <= 1'b1; wready <= 1'b0;
                if (awvalid && awready) begin
                    wptr    <= (awsize == 3'd2) ? ({19'b0, awaddr[AW+1:2]} - ({19'b0, awaddr[AW+1:2]} % WPB))
                                                 : {19'b0, awaddr[AW+1:2]};   // window-index (ignore region base)
                    wstride <= (awsize == 3'd2) ? 32'd1 : WPB;
                    awready <= 1'b0; wready <= 1'b1;
                    state   <= S_W;
                end
            end
            S_W: if (wvalid && wready) begin
                for (wj = 0; wj < WPB; wj = wj + 1) begin
                    if (|wstrb[wj*4 +: 4])
                        mem[wptr + wj] <= merge(mem[wptr + wj],
                                                wdata[wj*32 +: 32],
                                                wstrb[wj*4 +: 4]);
                end
                wptr <= wptr + wstride;
                if (wlast) begin wready <= 1'b0; bvalid <= 1'b1; state <= S_B; end
            end
            S_B: if (bvalid && bready) begin bvalid <= 1'b0; awready <= 1'b1; state <= S_IDLE; end
        endcase
    end
endmodule
`default_nettype wire
