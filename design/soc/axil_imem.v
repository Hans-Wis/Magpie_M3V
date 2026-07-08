// =============================================================================
// axil_imem.v — simple read-only AXI4-Lite instruction memory
// =============================================================================
`default_nettype none

module axil_imem #(
    parameter integer WORDS = 8192,
    parameter integer AW    = 13,
    parameter [1023:0] INIT_HEX = ""
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        arvalid,
    output wire        arready,
    input  wire [31:0] araddr,
    input  wire [ 2:0] arprot,
    output reg         rvalid,
    input  wire        rready,
    output reg  [31:0] rdata,
    output wire [ 1:0] rresp
);
    reg [31:0] mem [0:WORDS-1];

    initial begin
        if (INIT_HEX != "") $readmemh(INIT_HEX, mem);
    end

    assign arready = !rvalid;
    assign rresp = 2'b00;

    always @(posedge clk) begin
        if (!resetn) begin
            rvalid <= 1'b0;
            rdata <= 32'b0;
        end else begin
            if (arvalid && arready) begin
                rvalid <= 1'b1;
                rdata <= mem[araddr[AW+1:2]];
            end else if (rvalid && rready) begin
                rvalid <= 1'b0;
            end
        end
    end

    wire unused = |arprot;
endmodule
`default_nettype wire
