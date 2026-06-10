// =============================================================================
// axil_dp_bram.v — dual-port AXI4-Lite BRAM (FPGA block RAM)
// -----------------------------------------------------------------------------
// Port A: read-only  (instruction fetch, M_AXI_I)
// Port B: read+write (data load/store,    M_AXI_D)
// Single shared memory; inferred as true-dual-port BRAM on FPGA. For ASIC, swap
// the `mem` array for a T28 dual-port SRAM macro (see cpu_m1_asic_top, same
// AXI wrapper). 1-cycle read latency (BRAM-style). Optional $readmemh preload.
// =============================================================================
`default_nettype none

module axil_dp_bram #(
    parameter        ADDR_W   = 14,               // 16 KiB = 2^14 bytes
    parameter        INIT_HEX = ""                // optional preload (sim/FPGA)
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
    localparam WORDS = (1 << (ADDR_W - 2));
    reg [31:0] mem [0:WORDS-1];
    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'h0;
        if (INIT_HEX != "") $readmemh(INIT_HEX, mem);
    end

    wire [ADDR_W-3:0] a_word = a_araddr[ADDR_W-1:2];
    wire [ADDR_W-3:0] b_rword = b_araddr[ADDR_W-1:2];
    wire [ADDR_W-3:0] b_wword = b_awaddr[ADDR_W-1:2];

    assign a_rresp = 2'b00;
    assign b_rresp = 2'b00;
    assign b_bresp = 2'b00;

    // ---- Port A read ----
    assign a_arready = !a_rvalid;
    always @(posedge clk) begin
        if (!resetn) a_rvalid <= 1'b0;
        else if (a_arvalid && a_arready) begin a_rvalid <= 1'b1; a_rdata <= mem[a_word]; end
        else if (a_rvalid && a_rready)   a_rvalid <= 1'b0;
    end

    // ---- Port B read ----
    assign b_arready = !b_rvalid;
    always @(posedge clk) begin
        if (!resetn) b_rvalid <= 1'b0;
        else if (b_arvalid && b_arready) begin b_rvalid <= 1'b1; b_rdata <= mem[b_rword]; end
        else if (b_rvalid && b_rready)   b_rvalid <= 1'b0;
    end

    // ---- Port B write (single-outstanding; capture AW and W, then commit + B) ----
    reg               aw_seen, w_seen;
    reg [ADDR_W-3:0]  waddr_q;
    reg [31:0]        wdata_q;
    reg [3:0]         wstrb_q;
    // accept AW/W while no response pending and not already captured
    assign b_awready = !b_bvalid && !aw_seen;
    assign b_wready  = !b_bvalid && !w_seen;
    wire aw_fire = b_awvalid && b_awready;
    wire w_fire  = b_wvalid  && b_wready;
    wire have_aw = aw_seen || aw_fire;
    wire have_w  = w_seen  || w_fire;
    wire do_wr   = have_aw && have_w && !b_bvalid;     // commit this cycle
    wire [ADDR_W-3:0] wr_addr = aw_seen ? waddr_q : b_wword;
    wire [31:0]       wr_data = w_seen  ? wdata_q : b_wdata;
    wire [3:0]        wr_strb = w_seen  ? wstrb_q : b_wstrb;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen <= 1'b0; w_seen <= 1'b0; b_bvalid <= 1'b0;
        end else begin
            if (aw_fire) begin aw_seen <= 1'b1; waddr_q <= b_wword; end
            if (w_fire)  begin w_seen  <= 1'b1; wdata_q <= b_wdata; wstrb_q <= b_wstrb; end
            if (do_wr) begin
                b_bvalid <= 1'b1;
                aw_seen  <= 1'b0; w_seen <= 1'b0;
            end
            if (b_bvalid && b_bready) b_bvalid <= 1'b0;
        end
    end
    // byte-strobed write on the commit cycle
    always @(posedge clk) if (do_wr) begin
        if (wr_strb[0]) mem[wr_addr][ 7: 0] <= wr_data[ 7: 0];
        if (wr_strb[1]) mem[wr_addr][15: 8] <= wr_data[15: 8];
        if (wr_strb[2]) mem[wr_addr][23:16] <= wr_data[23:16];
        if (wr_strb[3]) mem[wr_addr][31:24] <= wr_data[31:24];
    end
endmodule
`default_nettype wire
