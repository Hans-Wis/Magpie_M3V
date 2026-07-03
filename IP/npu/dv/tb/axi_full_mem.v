// AXI4-full read-only memory model (weight source) for the DMA testbench.
// Supports INCR read bursts (single-outstanding). Word i initialised to a known
// pattern 0xC0DE0000 | i so the DMA copy can be checked exactly.
`default_nettype none
module axi_full_mem #(parameter integer WORDS = 4096) (
    input  wire clk, input wire resetn,
    input  wire        arvalid, output reg  arready, input wire [31:0] araddr,
    input  wire [7:0]  arlen,   input wire [2:0] arsize, input wire [1:0] arburst,
    output reg         rvalid,  input  wire rready, output reg [31:0] rdata,
    output reg         rlast,   output wire [1:0] rresp
);
    assign rresp = 2'b00;
    reg [31:0] mem [0:WORDS-1];
    integer i;
    initial for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'hC0DE0000 | i[15:0];

    localparam S_IDLE=1'b0, S_R=1'b1;
    reg        state;
    reg [31:0] word_ptr;
    reg [8:0]  beats_left;   // 1..256

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; arready <= 1'b1; rvalid <= 1'b0; rlast <= 1'b0;
        end else case (state)
            S_IDLE: begin
                rvalid <= 1'b0; rlast <= 1'b0; arready <= 1'b1;
                if (arvalid && arready) begin
                    word_ptr   <= araddr[31:2];
                    beats_left <= {1'b0, arlen} + 9'd1;
                    arready    <= 1'b0;
                    rvalid     <= 1'b1;
                    rdata      <= mem[araddr[31:2]];
                    rlast      <= (arlen == 8'd0);
                    state      <= S_R;
                end
            end
            S_R: if (rvalid && rready) begin
                if (rlast) begin
                    rvalid <= 1'b0; rlast <= 1'b0; arready <= 1'b1; state <= S_IDLE;
                end else begin
                    word_ptr   <= word_ptr + 1'b1;
                    rdata      <= mem[word_ptr + 1'b1];
                    beats_left <= beats_left - 9'd1;
                    rlast      <= (beats_left == 9'd2);   // next beat is the last
                end
            end
        endcase
    end
endmodule
`default_nettype wire
