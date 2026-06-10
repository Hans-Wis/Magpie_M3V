`timescale 1ns / 1ns
`default_nettype none

module axil_bridge_formal (
    input wire clk,
    input wire resetn,

    input wire        ibus_req,
    input wire [31:0] ibus_addr,
    input wire        dbus_req,
    input wire [31:0] dbus_addr,
    input wire        dbus_we,
    input wire [ 3:0] dbus_wstrb,
    input wire [31:0] dbus_wdata,

    input wire        m_axi_i_arready,
    input wire        m_axi_i_rvalid,
    input wire [31:0] m_axi_i_rdata,
    input wire [ 1:0] m_axi_i_rresp,
    input wire        m_axi_d_arready,
    input wire        m_axi_d_rvalid,
    input wire [31:0] m_axi_d_rdata,
    input wire [ 1:0] m_axi_d_rresp,
    input wire        m_axi_d_awready,
    input wire        m_axi_d_wready,
    input wire        m_axi_d_bvalid,
    input wire [ 1:0] m_axi_d_bresp
);
    wire        ibus_ready;
    wire [31:0] ibus_rdata;
    wire        dbus_ready;
    wire [31:0] dbus_rdata;
    wire        m_axi_i_arvalid;
    wire [31:0] m_axi_i_araddr;
    wire [ 2:0] m_axi_i_arprot;
    wire        m_axi_i_rready;
    wire        m_axi_d_arvalid;
    wire [31:0] m_axi_d_araddr;
    wire [ 2:0] m_axi_d_arprot;
    wire        m_axi_d_rready;
    wire        m_axi_d_awvalid;
    wire [31:0] m_axi_d_awaddr;
    wire [ 2:0] m_axi_d_awprot;
    wire        m_axi_d_wvalid;
    wire [31:0] m_axi_d_wdata;
    wire [ 3:0] m_axi_d_wstrb;
    wire        m_axi_d_bready;
    wire        dbg_axi_err;

    axil_bridge dut (
        .clk(clk),
        .resetn(resetn),
        .ibus_req(ibus_req),
        .ibus_addr(ibus_addr),
        .ibus_ready(ibus_ready),
        .ibus_rdata(ibus_rdata),
        .dbus_req(dbus_req),
        .dbus_addr(dbus_addr),
        .dbus_we(dbus_we),
        .dbus_wstrb(dbus_wstrb),
        .dbus_wdata(dbus_wdata),
        .dbus_ready(dbus_ready),
        .dbus_rdata(dbus_rdata),
        .m_axi_i_arvalid(m_axi_i_arvalid),
        .m_axi_i_arready(m_axi_i_arready),
        .m_axi_i_araddr(m_axi_i_araddr),
        .m_axi_i_arprot(m_axi_i_arprot),
        .m_axi_i_rvalid(m_axi_i_rvalid),
        .m_axi_i_rready(m_axi_i_rready),
        .m_axi_i_rdata(m_axi_i_rdata),
        .m_axi_i_rresp(m_axi_i_rresp),
        .m_axi_d_arvalid(m_axi_d_arvalid),
        .m_axi_d_arready(m_axi_d_arready),
        .m_axi_d_araddr(m_axi_d_araddr),
        .m_axi_d_arprot(m_axi_d_arprot),
        .m_axi_d_rvalid(m_axi_d_rvalid),
        .m_axi_d_rready(m_axi_d_rready),
        .m_axi_d_rdata(m_axi_d_rdata),
        .m_axi_d_rresp(m_axi_d_rresp),
        .m_axi_d_awvalid(m_axi_d_awvalid),
        .m_axi_d_awready(m_axi_d_awready),
        .m_axi_d_awaddr(m_axi_d_awaddr),
        .m_axi_d_awprot(m_axi_d_awprot),
        .m_axi_d_wvalid(m_axi_d_wvalid),
        .m_axi_d_wready(m_axi_d_wready),
        .m_axi_d_wdata(m_axi_d_wdata),
        .m_axi_d_wstrb(m_axi_d_wstrb),
        .m_axi_d_bvalid(m_axi_d_bvalid),
        .m_axi_d_bready(m_axi_d_bready),
        .m_axi_d_bresp(m_axi_d_bresp),
        .dbg_axi_err(dbg_axi_err)
    );

    reg f_past_valid = 1'b0;
    always @(posedge clk) begin
        f_past_valid <= 1'b1;
        if (!f_past_valid) assume (!resetn);
        if (f_past_valid && $past(resetn)) assume (resetn);
    end

    default clocking cb @(posedge clk); endclocking
    default disable iff (!resetn || !f_past_valid);

    property p_valid_holds_until_ready(valid, ready);
        valid && !ready |=> valid;
    endproperty

    property p_ready_holds_until_valid(ready, valid);
        ready && !valid |=> ready;
    endproperty

    assert property (p_valid_holds_until_ready(m_axi_i_arvalid, m_axi_i_arready));
    assert property (m_axi_i_arvalid && !m_axi_i_arready |=> $stable(m_axi_i_araddr) && $stable(m_axi_i_arprot));

    assert property (p_valid_holds_until_ready(m_axi_d_arvalid, m_axi_d_arready));
    assert property (m_axi_d_arvalid && !m_axi_d_arready |=> $stable(m_axi_d_araddr) && $stable(m_axi_d_arprot));

    assert property (p_valid_holds_until_ready(m_axi_d_awvalid, m_axi_d_awready));
    assert property (m_axi_d_awvalid && !m_axi_d_awready |=> $stable(m_axi_d_awaddr) && $stable(m_axi_d_awprot));

    assert property (p_valid_holds_until_ready(m_axi_d_wvalid, m_axi_d_wready));
    assert property (m_axi_d_wvalid && !m_axi_d_wready |=> $stable(m_axi_d_wdata) && $stable(m_axi_d_wstrb));

    assert property (p_ready_holds_until_valid(m_axi_i_rready, m_axi_i_rvalid));
    assert property (p_ready_holds_until_valid(m_axi_d_rready, m_axi_d_rvalid));
    assert property (p_ready_holds_until_valid(m_axi_d_bready, m_axi_d_bvalid));

    assert property (m_axi_i_arvalid |-> !m_axi_i_rready);
    assert property (m_axi_d_arvalid |-> !m_axi_d_rready);
    assert property (m_axi_i_rready |-> !m_axi_i_arvalid);
    assert property (m_axi_d_rready |-> !m_axi_d_arvalid);
    assert property (m_axi_d_awvalid |-> !m_axi_d_arvalid && !m_axi_d_rready);
    assert property (m_axi_d_wvalid  |-> !m_axi_d_arvalid && !m_axi_d_rready);
    assert property (m_axi_d_arvalid |-> !m_axi_d_awvalid && !m_axi_d_wvalid && !m_axi_d_bready);

    wire _unused = ^{ibus_ready, ibus_rdata, dbus_ready, dbus_rdata, dbg_axi_err};
endmodule

`default_nettype wire
