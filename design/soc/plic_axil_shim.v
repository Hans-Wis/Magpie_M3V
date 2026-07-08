// =============================================================================
// plic_axil_shim.v — AXI4-Lite slave to native PLIC bus
// -----------------------------------------------------------------------------
// Single-outstanding bridge for the local plic.v native port. Reads pulse native
// en during the AR handshake and capture combinational rdata on that same edge,
// which preserves claim-read side effects in plic.v.
// =============================================================================
`default_nettype none

module plic_axil_shim (
    input  wire        clk,
    input  wire        resetn,

    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_awaddr,
    input  wire [ 2:0] s_awprot,
    input  wire        s_wvalid,
    output wire        s_wready,
    input  wire [31:0] s_wdata,
    input  wire [ 3:0] s_wstrb,
    output reg         s_bvalid,
    input  wire        s_bready,
    output wire [ 1:0] s_bresp,
    input  wire        s_arvalid,
    output wire        s_arready,
    input  wire [31:0] s_araddr,
    input  wire [ 2:0] s_arprot,
    output reg         s_rvalid,
    input  wire        s_rready,
    output reg  [31:0] s_rdata,
    output wire [ 1:0] s_rresp,

    output wire        plic_en,
    output wire [31:0] plic_addr,
    output wire [31:0] plic_wdata,
    output wire [ 3:0] plic_wstrb,
    input  wire [31:0] plic_rdata
);
    reg        aw_seen;
    reg        w_seen;
    reg [31:0] awaddr_q;
    reg [31:0] wdata_q;
    reg [ 3:0] wstrb_q;

    wire resp_pending = s_bvalid | s_rvalid;
    wire aw_take = s_awvalid & s_awready;
    wire w_take  = s_wvalid  & s_wready;
    wire have_aw = aw_seen | aw_take;
    wire have_w  = w_seen  | w_take;
    wire write_fire = !resp_pending & have_aw & have_w;
    wire write_seen_or_valid = aw_seen | w_seen | s_awvalid | s_wvalid;
    wire read_fire = s_arvalid & s_arready;

    assign s_awready = !resp_pending & !aw_seen;
    assign s_wready  = !resp_pending & !w_seen;
    assign s_arready = !resp_pending & !write_seen_or_valid;

    assign plic_en    = write_fire | read_fire;
    assign plic_addr  = write_fire ? (aw_seen ? awaddr_q : s_awaddr) : s_araddr;
    assign plic_wdata = write_fire ? (w_seen ? wdata_q : s_wdata) : 32'h0;
    assign plic_wstrb = write_fire ? (w_seen ? wstrb_q : s_wstrb) : 4'h0;

    assign s_bresp = 2'b00;
    assign s_rresp = 2'b00;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen  <= 1'b0;
            w_seen   <= 1'b0;
            awaddr_q <= 32'h0;
            wdata_q  <= 32'h0;
            wstrb_q  <= 4'h0;
            s_bvalid <= 1'b0;
            s_rvalid <= 1'b0;
            s_rdata  <= 32'h0;
        end else begin
            if (s_bvalid && s_bready)
                s_bvalid <= 1'b0;
            if (s_rvalid && s_rready)
                s_rvalid <= 1'b0;

            if (aw_take) begin
                aw_seen  <= 1'b1;
                awaddr_q <= s_awaddr;
            end
            if (w_take) begin
                w_seen  <= 1'b1;
                wdata_q <= s_wdata;
                wstrb_q <= s_wstrb;
            end

            if (write_fire) begin
                aw_seen  <= 1'b0;
                w_seen   <= 1'b0;
                s_bvalid <= 1'b1;
            end
            if (read_fire) begin
                s_rdata  <= plic_rdata;
                s_rvalid <= 1'b1;
            end
        end
    end

    wire unused_axil_sideband = |{s_awprot, s_arprot};
endmodule
`default_nettype wire
