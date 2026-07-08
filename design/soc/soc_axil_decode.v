// =============================================================================
// soc_axil_decode.v — M3V minimal host data AXI4-Lite decoder
// -----------------------------------------------------------------------------
// 0x300?_???? -> npu_top AXI4-Lite slave (CSR/DTCM/ITCM window)
// 0x0c??_???? -> PLIC AXI4-Lite shim
// 0x8000_???? -> shared SRAM host leg
// otherwise    -> DECERR/SLVERR response with no hang
// =============================================================================
`default_nettype none

module soc_axil_decode (
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
    output wire        s_bvalid,
    input  wire        s_bready,
    output wire [ 1:0] s_bresp,
    input  wire        s_arvalid,
    output wire        s_arready,
    input  wire [31:0] s_araddr,
    input  wire [ 2:0] s_arprot,
    output wire        s_rvalid,
    input  wire        s_rready,
    output wire [31:0] s_rdata,
    output wire [ 1:0] s_rresp,

    output wire        n_awvalid,
    input  wire        n_awready,
    output wire [31:0] n_awaddr,
    output wire [ 2:0] n_awprot,
    output wire        n_wvalid,
    input  wire        n_wready,
    output wire [31:0] n_wdata,
    output wire [ 3:0] n_wstrb,
    input  wire        n_bvalid,
    output wire        n_bready,
    input  wire [ 1:0] n_bresp,
    output wire        n_arvalid,
    input  wire        n_arready,
    output wire [31:0] n_araddr,
    output wire [ 2:0] n_arprot,
    input  wire        n_rvalid,
    output wire        n_rready,
    input  wire [31:0] n_rdata,
    input  wire [ 1:0] n_rresp,

    output wire        p_awvalid,
    input  wire        p_awready,
    output wire [31:0] p_awaddr,
    output wire [ 2:0] p_awprot,
    output wire        p_wvalid,
    input  wire        p_wready,
    output wire [31:0] p_wdata,
    output wire [ 3:0] p_wstrb,
    input  wire        p_bvalid,
    output wire        p_bready,
    input  wire [ 1:0] p_bresp,
    output wire        p_arvalid,
    input  wire        p_arready,
    output wire [31:0] p_araddr,
    output wire [ 2:0] p_arprot,
    input  wire        p_rvalid,
    output wire        p_rready,
    input  wire [31:0] p_rdata,
    input  wire [ 1:0] p_rresp,

    output wire        m_awvalid,
    input  wire        m_awready,
    output wire [31:0] m_awaddr,
    output wire [ 2:0] m_awprot,
    output wire        m_wvalid,
    input  wire        m_wready,
    output wire [31:0] m_wdata,
    output wire [ 3:0] m_wstrb,
    input  wire        m_bvalid,
    output wire        m_bready,
    input  wire [ 1:0] m_bresp,
    output wire        m_arvalid,
    input  wire        m_arready,
    output wire [31:0] m_araddr,
    output wire [ 2:0] m_arprot,
    input  wire        m_rvalid,
    output wire        m_rready,
    input  wire [31:0] m_rdata,
    input  wire [ 1:0] m_rresp
);
    localparam [1:0] ROUTE_NPU = 2'd0, ROUTE_MEM = 2'd1, ROUTE_PLIC = 2'd2, ROUTE_ERR = 2'd3;

    function [1:0] dec;
        input [31:0] a;
        begin
            if (a[31:20] == 12'h300)       dec = ROUTE_NPU;
            else if (a[31:24] == 8'h0c)    dec = ROUTE_PLIC;
            else if (a[31:16] == 16'h8000) dec = ROUTE_MEM;
            else                           dec = ROUTE_ERR;
        end
    endfunction

    reg        w_busy, r_busy;
    reg [1:0]  w_route_q, r_route_q;
    reg        err_bvalid, err_rvalid;
    wire [1:0] w_route = w_busy ? w_route_q : dec(s_awaddr);
    wire [1:0] r_route = r_busy ? r_route_q : dec(s_araddr);
    wire       w_known = w_busy | s_awvalid;

    assign n_awvalid = s_awvalid && (w_route == ROUTE_NPU);
    assign p_awvalid = s_awvalid && (w_route == ROUTE_PLIC);
    assign m_awvalid = s_awvalid && (w_route == ROUTE_MEM);
    assign n_awaddr = s_awaddr;
    assign p_awaddr = s_awaddr;
    assign m_awaddr = s_awaddr;
    assign n_awprot = s_awprot;
    assign p_awprot = s_awprot;
    assign m_awprot = s_awprot;

    assign n_wvalid = s_wvalid && w_known && (w_route == ROUTE_NPU);
    assign p_wvalid = s_wvalid && w_known && (w_route == ROUTE_PLIC);
    assign m_wvalid = s_wvalid && w_known && (w_route == ROUTE_MEM);
    assign n_wdata = s_wdata;
    assign p_wdata = s_wdata;
    assign m_wdata = s_wdata;
    assign n_wstrb = s_wstrb;
    assign p_wstrb = s_wstrb;
    assign m_wstrb = s_wstrb;

    assign n_bready = s_bready && (w_route == ROUTE_NPU);
    assign p_bready = s_bready && (w_route == ROUTE_PLIC);
    assign m_bready = s_bready && (w_route == ROUTE_MEM);

    assign s_awready = (w_route == ROUTE_NPU) ? n_awready :
                       (w_route == ROUTE_PLIC) ? p_awready :
                       (w_route == ROUTE_MEM) ? m_awready :
                       (!w_busy && !err_bvalid);
    assign s_wready  = !w_known ? 1'b0 :
                       (w_route == ROUTE_NPU) ? n_wready :
                       (w_route == ROUTE_PLIC) ? p_wready :
                       (w_route == ROUTE_MEM) ? m_wready :
                       (!err_bvalid);
    assign s_bvalid  = (w_route == ROUTE_NPU) ? n_bvalid :
                       (w_route == ROUTE_PLIC) ? p_bvalid :
                       (w_route == ROUTE_MEM) ? m_bvalid :
                       err_bvalid;
    assign s_bresp   = (w_route == ROUTE_NPU) ? n_bresp :
                       (w_route == ROUTE_PLIC) ? p_bresp :
                       (w_route == ROUTE_MEM) ? m_bresp :
                       2'b10;

    assign n_arvalid = s_arvalid && (r_route == ROUTE_NPU);
    assign p_arvalid = s_arvalid && (r_route == ROUTE_PLIC);
    assign m_arvalid = s_arvalid && (r_route == ROUTE_MEM);
    assign n_araddr = s_araddr;
    assign p_araddr = s_araddr;
    assign m_araddr = s_araddr;
    assign n_arprot = s_arprot;
    assign p_arprot = s_arprot;
    assign m_arprot = s_arprot;
    assign n_rready = s_rready && (r_route == ROUTE_NPU);
    assign p_rready = s_rready && (r_route == ROUTE_PLIC);
    assign m_rready = s_rready && (r_route == ROUTE_MEM);

    assign s_arready = (r_route == ROUTE_NPU) ? n_arready :
                       (r_route == ROUTE_PLIC) ? p_arready :
                       (r_route == ROUTE_MEM) ? m_arready :
                       (!r_busy && !err_rvalid);
    assign s_rvalid  = (r_route == ROUTE_NPU) ? n_rvalid :
                       (r_route == ROUTE_PLIC) ? p_rvalid :
                       (r_route == ROUTE_MEM) ? m_rvalid :
                       err_rvalid;
    assign s_rdata   = (r_route == ROUTE_NPU) ? n_rdata :
                       (r_route == ROUTE_PLIC) ? p_rdata :
                       (r_route == ROUTE_MEM) ? m_rdata :
                       32'hDECE_0001;
    assign s_rresp   = (r_route == ROUTE_NPU) ? n_rresp :
                       (r_route == ROUTE_PLIC) ? p_rresp :
                       (r_route == ROUTE_MEM) ? m_rresp :
                       2'b10;

    always @(posedge clk) begin
        if (!resetn) begin
            w_busy <= 1'b0;
            r_busy <= 1'b0;
            w_route_q <= ROUTE_ERR;
            r_route_q <= ROUTE_ERR;
            err_bvalid <= 1'b0;
            err_rvalid <= 1'b0;
        end else begin
            if (!w_busy && s_awvalid && s_awready) begin
                w_busy <= 1'b1;
                w_route_q <= dec(s_awaddr);
            end
            if (!r_busy && s_arvalid && s_arready) begin
                r_busy <= 1'b1;
                r_route_q <= dec(s_araddr);
                if (dec(s_araddr) == ROUTE_ERR) err_rvalid <= 1'b1;
            end
            if (s_awvalid && s_awready && dec(s_awaddr) == ROUTE_ERR &&
                s_wvalid && s_wready)
                err_bvalid <= 1'b1;
            else if (w_busy && w_route_q == ROUTE_ERR && s_wvalid && s_wready)
                err_bvalid <= 1'b1;

            if (s_bvalid && s_bready) begin
                w_busy <= 1'b0;
                err_bvalid <= 1'b0;
            end
            if (s_rvalid && s_rready) begin
                r_busy <= 1'b0;
                err_rvalid <= 1'b0;
            end
        end
    end
endmodule
`default_nettype wire
