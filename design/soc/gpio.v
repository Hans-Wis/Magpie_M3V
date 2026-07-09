// =============================================================================
// gpio.v - minimal 16-bit GPIO block for soc_m3v_top P1
// -----------------------------------------------------------------------------
// Native peripheral bus target behind periph_axil_shim.
//   +0x00 OUT  RW, low N bits drive gpio_out
//   +0x04 IN   RO, low N bits read synchronized gpio_in
//   +0x08 DIR  RW, low N bits drive gpio_oe (1 = output)
//
// For N <= 16, reads return zero in [31:16] and writes ignore [31:16].
// Byte strobes only affect the low halfword.
// =============================================================================
`default_nettype none

module gpio #(
    parameter integer N = 16
) (
    input  wire         clk,
    input  wire         rst,

    input  wire         en,
    input  wire [31:0]  addr,
    input  wire [31:0]  wdata,
    input  wire [ 3:0]  wstrb,
    output reg  [31:0]  rdata,

    output wire [N-1:0] gpio_out,
    output wire [N-1:0] gpio_oe,
    input  wire [N-1:0] gpio_in
);
    localparam [5:0] REG_OUT = 6'h00;
    localparam [5:0] REG_IN  = 6'h01;
    localparam [5:0] REG_DIR = 6'h02;

    reg [N-1:0] out_q;
    reg [N-1:0] dir_q;
    reg [N-1:0] in_sync_0_q;
    reg [N-1:0] in_sync_1_q;

    wire        is_write = en && (|wstrb);
    wire [5:0]  reg_sel = addr[7:2];
    wire [15:0] out_pad = {{(16-N){1'b0}}, out_q};
    wire [15:0] in_pad  = {{(16-N){1'b0}}, in_sync_1_q};
    wire [15:0] dir_pad = {{(16-N){1'b0}}, dir_q};

    assign gpio_out = out_q;
    assign gpio_oe  = dir_q;

    always @* begin
        rdata = 32'h0;
        if (en && (~|wstrb)) begin
            if (reg_sel == REG_OUT)
                rdata = {16'h0, out_pad};
            else if (reg_sel == REG_IN)
                rdata = {16'h0, in_pad};
            else if (reg_sel == REG_DIR)
                rdata = {16'h0, dir_pad};
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            out_q       <= {N{1'b0}};
            dir_q       <= {N{1'b0}};
            in_sync_0_q <= {N{1'b0}};
            in_sync_1_q <= {N{1'b0}};
        end else begin
            in_sync_0_q <= gpio_in;
            in_sync_1_q <= in_sync_0_q;

            if (is_write && reg_sel == REG_OUT) begin
                if (wstrb[0])
                    out_q[(N < 8 ? N : 8)-1:0] <= wdata[(N < 8 ? N : 8)-1:0];
                if (N > 8 && wstrb[1])
                    out_q[N-1:8] <= wdata[N-1:8];
            end

            if (is_write && reg_sel == REG_DIR) begin
                if (wstrb[0])
                    dir_q[(N < 8 ? N : 8)-1:0] <= wdata[(N < 8 ? N : 8)-1:0];
                if (N > 8 && wstrb[1])
                    dir_q[N-1:8] <= wdata[N-1:8];
            end
        end
    end

    initial begin
        if (N < 1 || N > 16)
            $fatal(1, "gpio: N must be in the range 1..16");
    end

    wire unused = |{addr[31:8], addr[1:0], wdata[31:16], wstrb[3:2]};
endmodule
`default_nettype wire
