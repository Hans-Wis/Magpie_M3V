// =============================================================================
// qspi_axil_front.v - AXI4-Lite I/D front-end for the M3V QSPI XIP controllers
// -----------------------------------------------------------------------------
// The instruction-side port is read-only and intentionally has no AW/W/B
// channels. The data-side port is full AXI4-Lite; writes are accepted locally and
// return SLVERR because the XIP window is read-only.
//
// Reads are word-aligned/full-word AXI4-Lite accesses in this adapter. AXI4-Lite
// has no read strobes, so sub-word lane extraction is left to the requester.
// Both read ports strip the 0x4000_0000 base by passing addr[23:0] to the XIP
// engine. A single transaction may be outstanding across both ports; arbitration
// is fixed I-priority only when idle, with no preemption after a grant.
// =============================================================================
`default_nettype none

module qspi_axil_front (
    input  wire        clk,
    input  wire        resetn,
    input  wire        mode_quad_i,

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
    output wire [3:0]  io_o,
    output wire [3:0]  io_oe,
    input  wire [3:0]  io_i,

    output wire [31:0] cold_reads,
    output wire [31:0] warm_reads,
    output wire [31:0] quad_cold_reads,
    output wire [31:0] quad_warm_reads
);
    localparam [1:0] GRANT_NONE = 2'd0;
    localparam [1:0] GRANT_I    = 2'd1;
    localparam [1:0] GRANT_D    = 2'd2;

    reg        read_busy;
    reg [ 1:0] read_grant_q;
    reg        d_aw_seen;
    reg        d_w_seen;
    reg        mode_quad_q;
    reg        reset_xip_q;
    reg [31:0] single_cold_base;
    reg [31:0] single_warm_base;
    reg [31:0] quad_cold_base;
    reg [31:0] quad_warm_base;

    wire       write_active;
    wire       mode_switch_idle;
    wire       read_select_i;
    wire       read_select_d;
    wire       xip_arvalid;
    wire       selected_arready;
    wire [31:0] xip_araddr;
    wire       xip_rvalid;
    wire       xip_rready;
    wire [31:0] xip_rdata;
    wire [ 1:0] xip_rresp;
    wire       xip_fire;
    wire       d_aw_take;
    wire       d_w_take;
    wire       d_write_fire;

    wire       single_arready;
    wire [31:0] single_rdata;
    wire       single_rvalid;
    wire [ 1:0] single_rresp;
    wire       single_sclk;
    wire       single_cs_n;
    wire       single_si;
    wire [31:0] single_cold_raw;
    wire [31:0] single_warm_raw;

    wire       quad_arready;
    wire [31:0] quad_rdata;
    wire       quad_rvalid;
    wire [ 1:0] quad_rresp;
    wire       quad_sclk;
    wire       quad_cs_n;
    wire [3:0] quad_io_o;
    wire       quad_io_oe;
    wire [31:0] quad_cold_raw;
    wire [31:0] quad_warm_raw;

    assign write_active = d_aw_seen | d_w_seen | d_bvalid;
    assign mode_switch_idle = resetn && !read_busy && !write_active &&
                              (mode_quad_i != mode_quad_q);

    assign selected_arready = mode_quad_q ? quad_arready : single_arready;
    assign read_select_i = !read_busy && !write_active && !mode_switch_idle &&
                           !reset_xip_q && i_arvalid;
    assign read_select_d = !read_busy && !write_active && !mode_switch_idle &&
                           !reset_xip_q && !i_arvalid && d_arvalid;
    assign xip_arvalid = read_select_i | read_select_d;
    assign xip_araddr = read_select_i ? {8'h00, i_araddr[23:0]} :
                                      {8'h00, d_araddr[23:0]};
    assign xip_fire = xip_arvalid & selected_arready;

    assign i_arready = read_select_i & selected_arready;
    assign d_arready = read_select_d & selected_arready;

    assign xip_rvalid = mode_quad_q ? quad_rvalid : single_rvalid;
    assign xip_rdata  = mode_quad_q ? quad_rdata  : single_rdata;
    assign xip_rresp  = mode_quad_q ? quad_rresp  : single_rresp;

    assign i_rvalid = xip_rvalid & (read_grant_q == GRANT_I);
    assign d_rvalid = xip_rvalid & (read_grant_q == GRANT_D);
    // Both qspi_xip and qspi_xip_quad shift flash bytes MSB-first, so byte@offset
    // lands in rdata[31:24] on both paths; this common swap returns true LE words.
    wire [31:0] xip_rdata_le = {xip_rdata[7:0], xip_rdata[15:8],
                                xip_rdata[23:16], xip_rdata[31:24]};
    assign i_rdata = xip_rdata_le;
    assign d_rdata = xip_rdata_le;
    assign i_rresp = xip_rresp;
    assign d_rresp = xip_rresp;
    assign xip_rready = ((read_grant_q == GRANT_I) & i_rready) |
                        ((read_grant_q == GRANT_D) & d_rready);

    assign d_awready = !read_busy && !d_bvalid && !d_aw_seen &&
                       !mode_switch_idle && !reset_xip_q &&
                       (d_w_seen || !(i_arvalid || d_arvalid));
    assign d_wready = !read_busy && !d_bvalid && !d_w_seen &&
                      !mode_switch_idle && !reset_xip_q &&
                      (d_aw_seen || !(i_arvalid || d_arvalid));
    assign d_aw_take = d_awvalid & d_awready;
    assign d_w_take = d_wvalid & d_wready;
    assign d_write_fire = (d_aw_seen | d_aw_take) & (d_w_seen | d_w_take);
    assign d_bresp = 2'b10;

    assign cold_reads = single_cold_base + single_cold_raw;
    assign warm_reads = single_warm_base + single_warm_raw;
    assign quad_cold_reads = quad_cold_base + quad_cold_raw;
    assign quad_warm_reads = quad_warm_base + quad_warm_raw;

    wire engines_resetn = resetn & !reset_xip_q;
    wire force_cshi = mode_switch_idle | reset_xip_q;
    assign o_sclk = force_cshi ? 1'b0 : (mode_quad_q ? quad_sclk : single_sclk);
    assign o_cs_n = force_cshi ? 1'b1 : (mode_quad_q ? quad_cs_n : single_cs_n);
    assign io_o = mode_quad_q ? quad_io_o : {2'b00, 1'b0, single_si};
    assign io_oe = force_cshi ? 4'b0000 :
                   (mode_quad_q ? (quad_io_oe ? 4'b1111 : 4'b0000) : 4'b0001);

    qspi_xip #(
        .ADDR_BYTES(3)
    ) u_xip_single (
        .clk(clk),
        .rst_n(engines_resetn),
        .araddr(xip_araddr),
        .arvalid(xip_arvalid & !mode_quad_q),
        .arready(single_arready),
        .rdata(single_rdata),
        .rvalid(single_rvalid),
        .rready(xip_rready & !mode_quad_q),
        .rresp(single_rresp),
        .sclk(single_sclk),
        .cs_n(single_cs_n),
        .si(single_si),
        .so(io_i[1]),
        .cold_reads(single_cold_raw),
        .warm_reads(single_warm_raw)
    );

    qspi_xip_quad #(
        .READ_BYTES(4)
    ) u_xip_quad (
        .clk(clk),
        .rst_n(engines_resetn),
        .araddr(xip_araddr),
        .arvalid(xip_arvalid & mode_quad_q),
        .arready(quad_arready),
        .rdata(quad_rdata),
        .rvalid(quad_rvalid),
        .rready(xip_rready & mode_quad_q),
        .rresp(quad_rresp),
        .sclk(quad_sclk),
        .cs_n(quad_cs_n),
        .io_o(quad_io_o),
        .io_oe(quad_io_oe),
        .io_i(io_i),
        .cold_reads(quad_cold_raw),
        .warm_reads(quad_warm_raw)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            read_busy <= 1'b0;
            read_grant_q <= GRANT_NONE;
            d_aw_seen <= 1'b0;
            d_w_seen <= 1'b0;
            d_bvalid <= 1'b0;
            mode_quad_q <= 1'b0;
            reset_xip_q <= 1'b0;
            single_cold_base <= 32'h0;
            single_warm_base <= 32'h0;
            quad_cold_base <= 32'h0;
            quad_warm_base <= 32'h0;
        end else begin
            reset_xip_q <= 1'b0;

            if (mode_switch_idle) begin
                single_cold_base <= single_cold_base + single_cold_raw;
                single_warm_base <= single_warm_base + single_warm_raw;
                quad_cold_base <= quad_cold_base + quad_cold_raw;
                quad_warm_base <= quad_warm_base + quad_warm_raw;
                mode_quad_q <= mode_quad_i;
                reset_xip_q <= 1'b1;
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
    end

    wire unused_axil_sideband = |{i_arprot, d_awaddr, d_awprot, d_wdata, d_wstrb, d_arprot};
endmodule
`default_nettype wire
