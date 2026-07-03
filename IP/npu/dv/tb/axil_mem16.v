// Minimal 16x32 AXI4-Lite memory slave — stands in for the host's existing
// subsystem (passthrough port) in the Phase 1 fabric testbench. Single-outstanding.
`default_nettype none
module axil_mem16 (
    input  wire clk, input wire resetn,
    input  wire s_axi_awvalid, output wire s_axi_awready, input wire [31:0] s_axi_awaddr, input wire [2:0] s_axi_awprot,
    input  wire s_axi_wvalid,  output wire s_axi_wready,  input wire [31:0] s_axi_wdata,  input wire [3:0] s_axi_wstrb,
    output reg  s_axi_bvalid,  input  wire s_axi_bready,  output wire [1:0] s_axi_bresp,
    input  wire s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg  s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output wire [1:0] s_axi_rresp
);
    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;
    reg [31:0] mem [0:15];

    reg aw_seen, w_seen;
    reg [31:0] wa_q, wd_q;
    wire wr_fire = aw_seen && w_seen && !s_axi_bvalid;
    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;
    always @(posedge clk) begin
        if (!resetn) begin aw_seen<=0; w_seen<=0; s_axi_bvalid<=0; end
        else begin
            if (s_axi_awvalid && s_axi_awready) begin aw_seen<=1; wa_q<=s_axi_awaddr; end
            if (s_axi_wvalid  && s_axi_wready ) begin w_seen<=1;  wd_q<=s_axi_wdata;  end
            if (wr_fire) begin mem[wa_q[5:2]] <= wd_q; s_axi_bvalid<=1; aw_seen<=0; w_seen<=0; end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
        end
    end
    always @(posedge clk) begin
        if (!resetn) s_axi_rvalid<=0;
        else begin
            if (s_axi_arvalid && s_axi_arready) begin s_axi_rvalid<=1; s_axi_rdata<=mem[s_axi_araddr[5:2]]; end
            else if (s_axi_rvalid && s_axi_rready) s_axi_rvalid<=0;
        end
    end
    assign s_axi_arready = !s_axi_rvalid;
endmodule
`default_nettype wire
