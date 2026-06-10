// =============================================================================
// axil_sram_t28.v -- AXI4-Lite wrapper for one TSMC28 1RW1R 2 KiB SRAM macro
// -----------------------------------------------------------------------------
// Same AXI4-Lite port list as axil_dp_bram:
//   Port A: read-only  (instruction fetch, M_AXI_I) -> SRAM port1 (R)
//   Port B: read+write (data load/store,    M_AXI_D) -> SRAM port0 (RW)
//
// The SRAM is synchronous-read: CS/address are presented for one clock edge and
// AXI RVALID is asserted on the following edge with the macro dout value.
// =============================================================================
`default_nettype none

module axil_sram_t28 #(
    parameter        ADDR_W   = 11,               // 2 KiB = 2^11 bytes
    parameter        INIT_HEX = ""                // optional preload (sim only)
)(
    input  wire        clk,
    input  wire        resetn,

    // ---- Port A : AXI4-Lite read-only ----
    input  wire        a_arvalid, output wire a_arready, input wire [31:0] a_araddr,
    output reg         a_rvalid,  input  wire a_rready,  output reg  [31:0] a_rdata,
    output wire [1:0]  a_rresp,

    // ---- Port B : AXI4-Lite read+write ----
    input  wire        b_arvalid, output wire b_arready, input wire [31:0] b_araddr,
    output reg         b_rvalid,  input  wire b_rready,  output reg  [31:0] b_rdata,
    output wire [1:0]  b_rresp,
    input  wire        b_awvalid, output wire b_awready, input wire [31:0] b_awaddr,
    input  wire        b_wvalid,  output wire b_wready,  input wire [31:0] b_wdata,
    input  wire [3:0]  b_wstrb,
    output reg         b_bvalid,  input  wire b_bready,  output wire [1:0] b_bresp
);
    localparam WORDS = 512;

    wire [8:0] a_word = a_araddr[10:2];
    wire [8:0] b_rword = b_araddr[10:2];
    wire [8:0] b_wword = b_awaddr[10:2];

    assign a_rresp = 2'b00;
    assign b_rresp = 2'b00;
    assign b_bresp = 2'b00;

    wire [31:0] sram_dout0;
    wire [31:0] sram_dout1;

    // ---- Port A read: request this cycle, response next cycle ----
    reg a_rd_pending;
    wire a_rd_fire = a_arvalid && a_arready;
    assign a_arready = !a_rvalid && !a_rd_pending;

    always @(posedge clk) begin
        if (!resetn) begin
            a_rvalid     <= 1'b0;
            a_rd_pending <= 1'b0;
        end else begin
            if (a_rd_pending) begin
                a_rvalid     <= 1'b1;
                a_rdata      <= sram_dout1;
                a_rd_pending <= 1'b0;
            end else if (a_rvalid && a_rready) begin
                a_rvalid <= 1'b0;
            end

            if (a_rd_fire) begin
                a_rd_pending <= 1'b1;
            end
        end
    end

    // ---- Port B write capture/commit (single outstanding) ----
    reg        aw_seen, w_seen;
    reg [8:0]  waddr_q;
    reg [31:0] wdata_q;
    reg [3:0]  wstrb_q;

    assign b_awready = !b_bvalid && !aw_seen;
    assign b_wready  = !b_bvalid && !w_seen;

    wire aw_fire = b_awvalid && b_awready;
    wire w_fire  = b_wvalid  && b_wready;
    wire have_aw = aw_seen || aw_fire;
    wire have_w  = w_seen  || w_fire;
    wire do_wr   = have_aw && have_w && !b_bvalid;
    wire [8:0]  wr_addr = aw_seen ? waddr_q : b_wword;
    wire [31:0] wr_data = w_seen  ? wdata_q : b_wdata;
    wire [3:0]  wr_strb = w_seen  ? wstrb_q : b_wstrb;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen  <= 1'b0;
            w_seen   <= 1'b0;
            b_bvalid <= 1'b0;
        end else begin
            if (aw_fire) begin
                aw_seen <= 1'b1;
                waddr_q <= b_wword;
            end
            if (w_fire) begin
                w_seen  <= 1'b1;
                wdata_q <= b_wdata;
                wstrb_q <= b_wstrb;
            end
            if (do_wr) begin
                b_bvalid <= 1'b1;
                aw_seen  <= 1'b0;
                w_seen   <= 1'b0;
            end
            if (b_bvalid && b_bready) begin
                b_bvalid <= 1'b0;
            end
        end
    end

    // ---- Port B read: use RW port only when no write commits this cycle ----
    reg b_rd_pending;
    wire b_rd_fire = b_arvalid && b_arready;
    assign b_arready = !b_rvalid && !b_rd_pending && !do_wr;

    always @(posedge clk) begin
        if (!resetn) begin
            b_rvalid     <= 1'b0;
            b_rd_pending <= 1'b0;
        end else begin
            if (b_rd_pending) begin
                b_rvalid     <= 1'b1;
                b_rdata      <= sram_dout0;
                b_rd_pending <= 1'b0;
            end else if (b_rvalid && b_rready) begin
                b_rvalid <= 1'b0;
            end

            if (b_rd_fire) begin
                b_rd_pending <= 1'b1;
            end
        end
    end

`ifndef SYNTHESIS
    reg [31:0] init_mem [0:WORDS-1];
    reg        init_active;
    reg [8:0]  init_addr;
    integer init_i;
    initial begin
        init_active = (INIT_HEX != "");
        init_addr   = 9'd0;
        for (init_i = 0; init_i < WORDS; init_i = init_i + 1) begin
            init_mem[init_i] = 32'h0;
        end
        if (INIT_HEX != "") begin
            $readmemh(INIT_HEX, init_mem);
        end
    end

    always @(posedge clk) begin
        if (init_active) begin
            if (init_addr == 9'd511) begin
                init_active <= 1'b0;
            end else begin
                init_addr <= init_addr + 9'd1;
            end
        end
    end
`endif

`ifndef SYNTHESIS
    wire        init_port_active = init_active;
    wire [8:0]  init_port_addr   = init_addr;
    wire [31:0] init_port_data   = init_mem[init_addr];
`else
    wire        init_port_active = 1'b0;
    wire [8:0]  init_port_addr   = 9'd0;
    wire [31:0] init_port_data   = 32'd0;
`endif

    wire        sram_csb0  = init_port_active ? 1'b0    : !(do_wr || b_rd_fire);
    wire        sram_web0  = init_port_active ? 1'b0    : !do_wr;
    wire [3:0]  sram_wmask = init_port_active ? 4'b1111 : (do_wr ? wr_strb : 4'b0000);
    wire [8:0]  sram_addr0 = init_port_active ? init_port_addr : (do_wr ? wr_addr : b_rword);
    wire [31:0] sram_din0  = init_port_active ? init_port_data : wr_data;

    wire        sram_csb1  = !a_rd_fire;
    wire [8:0]  sram_addr1 = a_word;

    sky130_sram_2kbyte_1rw1r_32x512_8 u_sram (
        .clk0(clk),
        .csb0(sram_csb0),
        .web0(sram_web0),
        .wmask0(sram_wmask),
        .addr0(sram_addr0),
        .din0(sram_din0),
        .dout0(sram_dout0),
        .clk1(clk),
        .csb1(sram_csb1),
        .addr1(sram_addr1),
        .dout1(sram_dout1)
    );

endmodule
`default_nettype wire
