// =============================================================================
// axil_1to2.v — Magpie_M3V AXI4-Lite fabric: 1 master -> 2 slaves by address
// -----------------------------------------------------------------------------
// Routes the host cpu_m1 AXI4-Lite D master (from the frozen axil_bridge) to:
//   slave 0 = NPU control window   addr[31:28] == NPU_HI (default 0x3)
//   slave 1 = passthrough          everything else (host's existing subsystem)
// Single-outstanding for read and write independently (matches the host bridge,
// which is single-outstanding). 32-bit AXI4-Lite, no bursts.
// =============================================================================
`default_nettype none

module axil_1to2 #(
    parameter [3:0] NPU_HI = 4'h3          // NPU window = addr[31:28] == 0x3
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- upstream: AXI4-Lite slave (faces the host master) ----
    input  wire        s_awvalid, output wire s_awready, input wire [31:0] s_awaddr, input wire [2:0] s_awprot,
    input  wire        s_wvalid,  output wire s_wready,  input wire [31:0] s_wdata,  input wire [3:0] s_wstrb,
    output wire        s_bvalid,  input  wire s_bready,  output wire [1:0] s_bresp,
    input  wire        s_arvalid, output wire s_arready, input wire [31:0] s_araddr, input wire [2:0] s_arprot,
    output wire        s_rvalid,  input  wire s_rready,  output wire [31:0] s_rdata, output wire [1:0] s_rresp,

    // ---- downstream slave 0 (NPU) ----
    output wire        m0_awvalid, input wire m0_awready, output wire [31:0] m0_awaddr, output wire [2:0] m0_awprot,
    output wire        m0_wvalid,  input wire m0_wready,  output wire [31:0] m0_wdata,  output wire [3:0] m0_wstrb,
    input  wire        m0_bvalid,  output wire m0_bready, input wire [1:0] m0_bresp,
    output wire        m0_arvalid, input wire m0_arready, output wire [31:0] m0_araddr, output wire [2:0] m0_arprot,
    input  wire        m0_rvalid,  output wire m0_rready, input wire [31:0] m0_rdata, input wire [1:0] m0_rresp,

    // ---- downstream slave 1 (passthrough) ----
    output wire        m1_awvalid, input wire m1_awready, output wire [31:0] m1_awaddr, output wire [2:0] m1_awprot,
    output wire        m1_wvalid,  input wire m1_wready,  output wire [31:0] m1_wdata,  output wire [3:0] m1_wstrb,
    input  wire        m1_bvalid,  output wire m1_bready, input wire [1:0] m1_bresp,
    output wire        m1_arvalid, input wire m1_arready, output wire [31:0] m1_araddr, output wire [2:0] m1_arprot,
    input  wire        m1_rvalid,  output wire m1_rready, input wire [31:0] m1_rdata, input wire [1:0] m1_rresp
);
    // ---------------- write route ----------------
    // The write route is determined by AWADDR. W may legally arrive before AW, so W must NOT be
    // forwarded until the route is known (either AW is present this cycle, or already latched).
    reg  w_busy, w_sel;                       // sel: 0=NPU, 1=pass ; latched at AW accept
    wire w_dec   = (s_awaddr[31:28] == NPU_HI) ? 1'b0 : 1'b1;   // valid only when s_awvalid
    wire w_known = w_busy | s_awvalid;        // is the write route known yet?
    wire w_route = w_busy ? w_sel : w_dec;

    always @(posedge clk) begin
        if (!resetn) begin
            w_busy <= 1'b0; w_sel <= 1'b0;
        end else begin
            if (!w_busy && s_awvalid && s_awready) begin w_busy <= 1'b1; w_sel <= w_dec; end
            if (s_bvalid && s_bready) w_busy <= 1'b0;
        end
    end

    // AW/W to the routed slave; B back from it. Broadcast valids only to the target.
    assign m0_awvalid = s_awvalid & (w_route == 1'b0);
    assign m1_awvalid = s_awvalid & (w_route == 1'b1);
    assign s_awready  = (w_route == 1'b0) ? m0_awready : m1_awready;
    assign m0_awaddr = s_awaddr; assign m1_awaddr = s_awaddr;
    assign m0_awprot = s_awprot; assign m1_awprot = s_awprot;

    // W is held (wready=0, no downstream wvalid) until the route is known — fixes W-before-AW.
    assign m0_wvalid = s_wvalid & w_known & (w_route == 1'b0);
    assign m1_wvalid = s_wvalid & w_known & (w_route == 1'b1);
    assign s_wready  = w_known ? ((w_route == 1'b0) ? m0_wready : m1_wready) : 1'b0;
    assign m0_wdata = s_wdata; assign m1_wdata = s_wdata;
    assign m0_wstrb = s_wstrb; assign m1_wstrb = s_wstrb;

    assign s_bvalid = (w_route == 1'b0) ? m0_bvalid : m1_bvalid;
    assign s_bresp  = (w_route == 1'b0) ? m0_bresp  : m1_bresp;
    assign m0_bready = s_bready & (w_route == 1'b0);
    assign m1_bready = s_bready & (w_route == 1'b1);

    // ---------------- read route ----------------
    reg  r_busy, r_sel;
    wire r_dec   = (s_araddr[31:28] == NPU_HI) ? 1'b0 : 1'b1;
    wire r_route = r_busy ? r_sel : r_dec;

    always @(posedge clk) begin
        if (!resetn) begin
            r_busy <= 1'b0; r_sel <= 1'b0;
        end else begin
            if (!r_busy && s_arvalid && s_arready) begin r_busy <= 1'b1; r_sel <= r_dec; end
            if (s_rvalid && s_rready) r_busy <= 1'b0;
        end
    end

    assign m0_arvalid = s_arvalid & (r_route == 1'b0);
    assign m1_arvalid = s_arvalid & (r_route == 1'b1);
    assign s_arready  = (r_route == 1'b0) ? m0_arready : m1_arready;
    assign m0_araddr = s_araddr; assign m1_araddr = s_araddr;
    assign m0_arprot = s_arprot; assign m1_arprot = s_arprot;

    assign s_rvalid = (r_route == 1'b0) ? m0_rvalid : m1_rvalid;
    assign s_rdata  = (r_route == 1'b0) ? m0_rdata  : m1_rdata;
    assign s_rresp  = (r_route == 1'b0) ? m0_rresp  : m1_rresp;
    assign m0_rready = s_rready & (r_route == 1'b0);
    assign m1_rready = s_rready & (r_route == 1'b1);

endmodule
`default_nettype wire
