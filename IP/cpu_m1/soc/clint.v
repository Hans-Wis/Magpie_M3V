// =============================================================================
// clint.v -- Magpie_M1 single-hart Core-Local Interruptor (ADR-0019)
// -----------------------------------------------------------------------------
// Native bus, selected by the surrounding subsystem:
//   en=1 with |wstrb|=0 : combinational read on rdata
//   en=1 with |wstrb|!=0: byte-strobed write on the next clk edge
//
// Memory map, base 0x0200_0000:
//   +0x0000  msip[0]
//   +0x4000  mtimecmp[31:0]
//   +0x4004  mtimecmp[63:32]
//   +0xBFF8  mtime[31:0]
//   +0xBFFC  mtime[63:32]
// =============================================================================
`default_nettype none

module clint (
    input  wire        clk,
    input  wire        resetn,

    input  wire        en,
    input  wire [31:0] addr,
    input  wire [ 3:0] wstrb,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    output wire        mtip,
    output wire        msip
);
    reg [63:0] mtime_r;
    reg [63:0] mtimecmp_r;
    reg        msip_r;

    wire sel_msip       = (addr[15:2] == 14'h0000);
    wire sel_mtimecmp_l = (addr[15:2] == 14'h1000);
    wire sel_mtimecmp_h = (addr[15:2] == 14'h1001);
    wire sel_mtime_l    = (addr[15:2] == 14'h2ffe);
    wire sel_mtime_h    = (addr[15:2] == 14'h2fff);
    wire is_read        = en && (wstrb == 4'b0000);
    wire is_write       = en && (wstrb != 4'b0000);

    assign mtip = (mtime_r >= mtimecmp_r);
    assign msip = msip_r;

    always @* begin
        rdata = 32'h0000_0000;
        if (is_read) begin
            if (sel_msip)            rdata = {31'h0, msip_r};
            else if (sel_mtimecmp_l) rdata = mtimecmp_r[31:0];
            else if (sel_mtimecmp_h) rdata = mtimecmp_r[63:32];
            else if (sel_mtime_l)    rdata = mtime_r[31:0];
            else if (sel_mtime_h)    rdata = mtime_r[63:32];
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            mtime_r    <= 64'h0000_0000_0000_0000;
            mtimecmp_r <= 64'hffff_ffff_ffff_ffff;
            msip_r     <= 1'b0;
        end else begin
            mtime_r <= mtime_r + 64'd1;

            if (is_write) begin
                if (sel_msip) begin
                    if (wstrb[0]) msip_r <= wdata[0];
                end

                if (sel_mtimecmp_l) begin
                    if (wstrb[0]) mtimecmp_r[ 7: 0] <= wdata[ 7: 0];
                    if (wstrb[1]) mtimecmp_r[15: 8] <= wdata[15: 8];
                    if (wstrb[2]) mtimecmp_r[23:16] <= wdata[23:16];
                    if (wstrb[3]) mtimecmp_r[31:24] <= wdata[31:24];
                end

                if (sel_mtimecmp_h) begin
                    if (wstrb[0]) mtimecmp_r[39:32] <= wdata[ 7: 0];
                    if (wstrb[1]) mtimecmp_r[47:40] <= wdata[15: 8];
                    if (wstrb[2]) mtimecmp_r[55:48] <= wdata[23:16];
                    if (wstrb[3]) mtimecmp_r[63:56] <= wdata[31:24];
                end
            end
        end
    end
endmodule

`default_nettype wire
