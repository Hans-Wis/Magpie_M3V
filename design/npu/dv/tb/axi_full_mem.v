// AXI4-full read-only memory model (weight source) for the DMA testbench.
// Supports INCR read bursts (single-outstanding). Word i initialised to a known
// pattern 0xC0DE0000 | i so the DMA copy can be checked exactly.
`default_nettype none
module axi_full_mem #(
    parameter integer WORDS = 4096,
    parameter integer DMA_DATA_W = 32,
    parameter ERR_MODE = 0
) (
    input  wire clk, input wire resetn,
    input  wire        arvalid, output reg  arready, input wire [31:0] araddr,
    input  wire [7:0]  arlen,   input wire [2:0] arsize, input wire [1:0] arburst,
    output reg         rvalid,  input  wire rready, output reg [DMA_DATA_W-1:0] rdata,
    output reg         rlast,   output wire [1:0] rresp
);
    assign rresp = ERR_MODE ? 2'b10 : 2'b00;   // SLVERR when ERR_MODE (for DMA error test)
    localparam integer WPB = DMA_DATA_W / 32;
    reg [31:0] mem [0:WORDS-1];
    integer i;
    initial for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'hC0DE0000 | {16'b0, i[15:0]};

    localparam S_IDLE=1'b0, S_R=1'b1;
    reg        state;
    reg [31:0] word_ptr;
    reg [31:0] word_stride;
    reg [8:0]  beats_left;   // 1..256

    function [DMA_DATA_W-1:0] wide_read;
        input [31:0] base;
        integer j;
        begin
                wide_read = {DMA_DATA_W{1'b0}};
            for (j = 0; j < WPB; j = j + 1)
                wide_read[j*32 +: 32] = mem[base + j];
        end
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; arready <= 1'b1; rvalid <= 1'b0; rlast <= 1'b0;
        end else case (state)
            S_IDLE: begin
                rvalid <= 1'b0; rlast <= 1'b0; arready <= 1'b1;
                if (arvalid && arready) begin
                    word_ptr   <= (arsize == 3'd2) ? ({2'b0, araddr[31:2]} - ({2'b0, araddr[31:2]} % WPB)) : {2'b0, araddr[31:2]};
                    word_stride <= (arsize == 3'd2) ? 32'd1 : WPB;
                    beats_left <= {1'b0, arlen} + 9'd1;
                    arready    <= 1'b0;
                    rvalid     <= 1'b1;
                    rdata      <= wide_read((arsize == 3'd2) ? ({2'b0, araddr[31:2]} - ({2'b0, araddr[31:2]} % WPB)) : {2'b0, araddr[31:2]});
                    rlast      <= (arlen == 8'd0);
                    state      <= S_R;
                end
            end
            S_R: if (rvalid && rready) begin
                if (rlast) begin
                    rvalid <= 1'b0; rlast <= 1'b0; arready <= 1'b1; state <= S_IDLE;
                end else begin
                    word_ptr   <= word_ptr + word_stride;
                    rdata      <= wide_read(word_ptr + word_stride);
                    beats_left <= beats_left - 9'd1;
                    rlast      <= (beats_left == 9'd2);   // next beat is the last
                end
            end
        endcase
    end
endmodule
`default_nettype wire
