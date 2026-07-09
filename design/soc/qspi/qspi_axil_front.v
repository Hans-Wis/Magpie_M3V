// =============================================================================
// qspi_axil_front.v - AXI4-Lite I/D front-end for the M3V QSPI XIP controller
// -----------------------------------------------------------------------------
// The instruction-side port is read-only and intentionally has no AW/W/B
// channels. The data-side port is full AXI4-Lite; writes are accepted locally and
// return SLVERR because the P0 XIP window is read-only.
//
// Reads are word-aligned/full-word AXI4-Lite accesses in this P0 adapter. AXI4-
// Lite has no read strobes, so sub-word lane extraction is left to the requester.
// Both read ports strip the 0x4000_0000 base by passing addr[23:0] to qspi_xip.
// A single qspi_xip transaction may be outstanding across both ports; arbitration
// is fixed I-priority only when idle, with no preemption after a grant.
// =============================================================================
`default_nettype none

module qspi_axil_front (
    input  wire        clk,
    input  wire        resetn,

    input  wire        i_arvalid,
    output wire        i_arready,
    input  wire [31:0] i_araddr,
    input  wire [ 2:0] i_arprot,
    output wire        i_rvalid,
    input  wire        i_rready,
    output wire [31:0] i_rdata,
    output wire [ 1:0] i_rresp,

    input  wire        d_awvalid,
    output wire        d_awready,
    input  wire [31:0] d_awaddr,
    input  wire [ 2:0] d_awprot,
    input  wire        d_wvalid,
    output wire        d_wready,
    input  wire [31:0] d_wdata,
    input  wire [ 3:0] d_wstrb,
    output reg         d_bvalid,
    input  wire        d_bready,
    output wire [ 1:0] d_bresp,
    input  wire        d_arvalid,
    output wire        d_arready,
    input  wire [31:0] d_araddr,
    input  wire [ 2:0] d_arprot,
    output wire        d_rvalid,
    input  wire        d_rready,
    output wire [31:0] d_rdata,
    output wire [ 1:0] d_rresp,

    output wire        o_sclk,
    output wire        o_cs_n,
    output wire        o_si,
    input  wire        i_so,

    output wire [31:0] cold_reads,
    output wire [31:0] warm_reads
);
    localparam [1:0] GRANT_NONE = 2'd0;
    localparam [1:0] GRANT_I    = 2'd1;
    localparam [1:0] GRANT_D    = 2'd2;

    reg        read_busy;
    reg [ 1:0] read_grant_q;
    reg        d_aw_seen;
    reg        d_w_seen;

    wire       write_active;
    wire       read_select_i;
    wire       read_select_d;
    wire       xip_arvalid;
    wire       xip_arready;
    wire [31:0] xip_araddr;
    wire       xip_rvalid;
    wire       xip_rready;
    wire [31:0] xip_rdata;
    wire [ 1:0] xip_rresp;
    wire       xip_fire;
    wire       d_aw_take;
    wire       d_w_take;
    wire       d_write_fire;

    assign write_active = d_aw_seen | d_w_seen | d_bvalid;

    assign read_select_i = !read_busy && !write_active && i_arvalid;
    assign read_select_d = !read_busy && !write_active && !i_arvalid && d_arvalid;
    assign xip_arvalid = read_select_i | read_select_d;
    assign xip_araddr = read_select_i ? {8'h00, i_araddr[23:0]} : {8'h00, d_araddr[23:0]};
    assign xip_fire = xip_arvalid & xip_arready;

    assign i_arready = read_select_i & xip_arready;
    assign d_arready = read_select_d & xip_arready;

    assign i_rvalid = xip_rvalid & (read_grant_q == GRANT_I);
    assign d_rvalid = xip_rvalid & (read_grant_q == GRANT_D);
    // qspi_xip shifts SO in MSB-first, so flash byte@offset+0 lands in
    // rdata[31:24]; swap to little-endian words (same fix M6's qspi_axi_rom
    // applies). Instruction fetch is LE — without this the first XIP fetch
    // decodes as an illegal instruction.
    wire [31:0] xip_rdata_le = {xip_rdata[7:0], xip_rdata[15:8],
                                xip_rdata[23:16], xip_rdata[31:24]};
    assign i_rdata = xip_rdata_le;
    assign d_rdata = xip_rdata_le;
    assign i_rresp = xip_rresp;
    assign d_rresp = xip_rresp;
    assign xip_rready = ((read_grant_q == GRANT_I) & i_rready) |
                        ((read_grant_q == GRANT_D) & d_rready);

    assign d_awready = !read_busy && !d_bvalid && !d_aw_seen &&
                       (d_w_seen || !(i_arvalid || d_arvalid));
    assign d_wready = !read_busy && !d_bvalid && !d_w_seen &&
                      (d_aw_seen || !(i_arvalid || d_arvalid));
    assign d_aw_take = d_awvalid & d_awready;
    assign d_w_take = d_wvalid & d_wready;
    assign d_write_fire = (d_aw_seen | d_aw_take) & (d_w_seen | d_w_take);
    assign d_bresp = 2'b10;

    qspi_xip #(
        .ADDR_BYTES(3)
    ) u_xip (
        .clk(clk),
        .rst_n(resetn),
        .araddr(xip_araddr),
        .arvalid(xip_arvalid),
        .arready(xip_arready),
        .rdata(xip_rdata),
        .rvalid(xip_rvalid),
        .rready(xip_rready),
        .rresp(xip_rresp),
        .sclk(o_sclk),
        .cs_n(o_cs_n),
        .si(o_si),
        .so(i_so),
        .cold_reads(cold_reads),
        .warm_reads(warm_reads)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            read_busy <= 1'b0;
            read_grant_q <= GRANT_NONE;
            d_aw_seen <= 1'b0;
            d_w_seen <= 1'b0;
            d_bvalid <= 1'b0;
        end else begin
            if (xip_fire) begin
                read_busy <= 1'b1;
                if (read_select_i)
                    read_grant_q <= GRANT_I;
                else
                    read_grant_q <= GRANT_D;
            end
            if (xip_rvalid && xip_rready) begin
                read_busy <= 1'b0;
                read_grant_q <= GRANT_NONE;
            end

            if (d_bvalid && d_bready)
                d_bvalid <= 1'b0;

            if (d_aw_take)
                d_aw_seen <= 1'b1;
            if (d_w_take)
                d_w_seen <= 1'b1;
            if (d_write_fire) begin
                d_aw_seen <= 1'b0;
                d_w_seen <= 1'b0;
                d_bvalid <= 1'b1;
            end
        end
    end

    wire unused_axil_sideband = |{i_arprot, d_awaddr, d_awprot, d_wdata, d_wstrb, d_arprot};
endmodule
`default_nettype wire
