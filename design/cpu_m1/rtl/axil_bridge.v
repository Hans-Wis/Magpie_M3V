// =============================================================================
// axil_bridge.v — Magpie_M1 native valid/ready bus  <->  AXI4-Lite master
// -----------------------------------------------------------------------------
// Converts the CPU's single-outstanding, ready-gated native I/D busses
// (ibus_*/dbus_*) into two AXI4-Lite masters: a read-only I master and a
// read+write D master. Single-outstanding -> no ID/outstanding tracking; each
// channel is a small 2/3-state FSM bridging the native 1-phase (req->ready)
// to AXI's 2-phase (address then data/response). Holds native *_ready=0 until
// the AXI transaction completes (the core sees mem_stall and waits).
//
// Native contract (cpu_m1_top): req held until ready; xfer = req && ready;
// rdata sampled the cycle ready=1; dbus_we = |dbus_wstrb (read when wstrb=0).
// AXI4-Lite: 32-bit data, no bursts, single transfer. RRESP/BRESP ignored
// (SLVERR is surfaced on dbg_axi_err for the integrator; data still returned).
// =============================================================================
`default_nettype none

module axil_bridge (
    input  wire        clk,
    input  wire        resetn,

    // ---- native I-side (read-only) from cpu_m1_top ----
    input  wire        ibus_req,
    input  wire [31:0] ibus_addr,
    output wire        ibus_ready,
    output wire [31:0] ibus_rdata,

    // ---- native D-side (read+write) from cpu_m1_top ----
    input  wire        dbus_req,
    input  wire [31:0] dbus_addr,
    input  wire        dbus_we,
    input  wire [ 3:0] dbus_wstrb,
    input  wire [31:0] dbus_wdata,
    output wire        dbus_ready,
    output wire [31:0] dbus_rdata,

    // ---- AXI4-Lite master: instruction (read-only) ----
    output wire        m_axi_i_arvalid,
    input  wire        m_axi_i_arready,
    output wire [31:0] m_axi_i_araddr,
    output wire [ 2:0] m_axi_i_arprot,
    input  wire        m_axi_i_rvalid,
    output wire        m_axi_i_rready,
    input  wire [31:0] m_axi_i_rdata,
    input  wire [ 1:0] m_axi_i_rresp,

    // ---- AXI4-Lite master: data (read+write) ----
    output wire        m_axi_d_arvalid,
    input  wire        m_axi_d_arready,
    output wire [31:0] m_axi_d_araddr,
    output wire [ 2:0] m_axi_d_arprot,
    input  wire        m_axi_d_rvalid,
    output wire        m_axi_d_rready,
    input  wire [31:0] m_axi_d_rdata,
    input  wire [ 1:0] m_axi_d_rresp,
    output wire        m_axi_d_awvalid,
    input  wire        m_axi_d_awready,
    output wire [31:0] m_axi_d_awaddr,
    output wire [ 2:0] m_axi_d_awprot,
    output wire        m_axi_d_wvalid,
    input  wire        m_axi_d_wready,
    output wire [31:0] m_axi_d_wdata,
    output wire [ 3:0] m_axi_d_wstrb,
    input  wire        m_axi_d_bvalid,
    output wire        m_axi_d_bready,
    input  wire [ 1:0] m_axi_d_bresp,

    output wire        dbg_axi_err          // sticky: any RRESP/BRESP != OKAY/EXOKAY
);
    localparam [1:0] I_IDLE = 2'd0, I_AR = 2'd1, I_R = 2'd2;
    localparam [1:0] D_IDLE = 2'd0, D_AR = 2'd1, D_R = 2'd2, D_AW = 2'd3;

    // ====================== I-side (read-only) ======================
    reg [1:0]  i_state;
    reg [31:0] i_araddr;
    always @(posedge clk) begin
        if (!resetn) begin
            i_state <= I_IDLE;
        end else case (i_state)
            I_IDLE: if (ibus_req) begin i_araddr <= ibus_addr; i_state <= I_AR; end
            I_AR:   if (m_axi_i_arready) i_state <= I_R;
            I_R:    if (m_axi_i_rvalid)  i_state <= I_IDLE;
            default: i_state <= I_IDLE;
        endcase
    end
    assign m_axi_i_arvalid = (i_state == I_AR);
    assign m_axi_i_araddr  = i_araddr;
    assign m_axi_i_arprot  = 3'b100;                 // [2]=instruction, unpriv, secure
    assign m_axi_i_rready  = (i_state == I_R);
    assign ibus_ready      = (i_state == I_R) && m_axi_i_rvalid;
    assign ibus_rdata      = m_axi_i_rdata;

    // ====================== D-side (read+write) ======================
    reg [1:0]  d_state;
    reg [31:0] d_addr, d_wdata;
    reg [ 3:0] d_wstrb;
    reg        d_aw_done, d_w_done;
    always @(posedge clk) begin
        if (!resetn) begin
            d_state <= D_IDLE; d_aw_done <= 1'b0; d_w_done <= 1'b0;
        end else case (d_state)
            D_IDLE: if (dbus_req) begin
                        d_addr  <= dbus_addr;  d_wdata <= dbus_wdata;  d_wstrb <= dbus_wstrb;
                        d_aw_done <= 1'b0; d_w_done <= 1'b0;
                        d_state <= dbus_we ? D_AW : D_AR;
                    end
            D_AR:   if (m_axi_d_arready) d_state <= D_R;
            D_R:    if (m_axi_d_rvalid)  d_state <= D_IDLE;
            D_AW:   begin                                   // issue AW + W, wait both then B
                        if (m_axi_d_awvalid && m_axi_d_awready) d_aw_done <= 1'b1;
                        if (m_axi_d_wvalid  && m_axi_d_wready)  d_w_done  <= 1'b1;
                        if ((d_aw_done || (m_axi_d_awvalid && m_axi_d_awready)) &&
                            (d_w_done  || (m_axi_d_wvalid  && m_axi_d_wready)) &&
                            m_axi_d_bvalid)
                            d_state <= D_IDLE;
                    end
            default: d_state <= D_IDLE;
        endcase
    end
    // read channel
    assign m_axi_d_arvalid = (d_state == D_AR);
    assign m_axi_d_araddr  = d_addr;
    assign m_axi_d_arprot  = 3'b000;
    assign m_axi_d_rready  = (d_state == D_R);
    // write channels
    assign m_axi_d_awvalid = (d_state == D_AW) && !d_aw_done;
    assign m_axi_d_awaddr  = d_addr;
    assign m_axi_d_awprot  = 3'b000;
    assign m_axi_d_wvalid  = (d_state == D_AW) && !d_w_done;
    assign m_axi_d_wdata   = d_wdata;
    assign m_axi_d_wstrb   = d_wstrb;
    assign m_axi_d_bready  = (d_state == D_AW);
    // native ready: read completes on RVALID; write completes on BVALID
    assign dbus_ready = ((d_state == D_R)  && m_axi_d_rvalid) ||
                        ((d_state == D_AW) && m_axi_d_bvalid &&
                         (d_aw_done || (m_axi_d_awvalid && m_axi_d_awready)) &&
                         (d_w_done  || (m_axi_d_wvalid  && m_axi_d_wready)));
    assign dbus_rdata = m_axi_d_rdata;

    // sticky AXI error flag (non-OKAY response) for the integrator
    reg axi_err_q;
    always @(posedge clk)
        if (!resetn) axi_err_q <= 1'b0;
        else if ((m_axi_i_rvalid && m_axi_i_rready && m_axi_i_rresp[1]) ||
                 (m_axi_d_rvalid && m_axi_d_rready && m_axi_d_rresp[1]) ||
                 (m_axi_d_bvalid && m_axi_d_bready && m_axi_d_bresp[1]))
            axi_err_q <= 1'b1;
    assign dbg_axi_err = axi_err_q;

endmodule
`default_nettype wire
