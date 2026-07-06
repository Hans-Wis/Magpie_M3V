// =============================================================================
// axil_decerr.v — AXI4-Lite slave that answers every access with SLVERR.
// Used as the "hole" target for NPU-window addresses that decode to neither CSR
// nor TCM, so out-of-range accesses get a clean error response instead of
// aliasing onto a real register. Single-outstanding.
// =============================================================================
`default_nettype none

module axil_decerr (
    input  wire clk, input wire resetn,
    input  wire s_awvalid, output wire s_awready, input wire [31:0] s_awaddr, input wire [2:0] s_awprot,
    input  wire s_wvalid,  output wire s_wready,  input wire [31:0] s_wdata,  input wire [3:0] s_wstrb,
    output reg  s_bvalid,  input  wire s_bready,  output wire [1:0] s_bresp,
    input  wire s_arvalid, output wire s_arready, input wire [31:0] s_araddr, input wire [2:0] s_arprot,
    output reg  s_rvalid,  input  wire s_rready,  output wire [31:0] s_rdata, output wire [1:0] s_rresp
);
    assign s_bresp = 2'b10;   // SLVERR
    assign s_rresp = 2'b10;   // SLVERR
    assign s_rdata = 32'b0;

    // write: accept AW+W, emit B=SLVERR (single-outstanding)
    reg aw_seen, w_seen;
    assign s_awready = !aw_seen && !s_bvalid;
    assign s_wready  = !w_seen  && !s_bvalid;
    always @(posedge clk) begin
        if (!resetn) begin aw_seen<=0; w_seen<=0; s_bvalid<=0; end
        else begin
            if (s_awvalid && s_awready) aw_seen<=1;
            if (s_wvalid  && s_wready ) w_seen<=1;
            if (aw_seen && w_seen && !s_bvalid) begin s_bvalid<=1; aw_seen<=0; w_seen<=0; end
            if (s_bvalid && s_bready) s_bvalid<=0;
        end
    end

    // read: accept AR, emit R=SLVERR
    assign s_arready = !s_rvalid;
    always @(posedge clk) begin
        if (!resetn) s_rvalid<=0;
        else begin
            if (s_arvalid && s_arready) s_rvalid<=1;
            else if (s_rvalid && s_rready) s_rvalid<=0;
        end
    end
endmodule
`default_nettype wire
