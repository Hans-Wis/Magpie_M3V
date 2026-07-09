// =============================================================================
// qspi_csr.v - QSPI mode and program/erase CSRs for ADR-0071 D2
// -----------------------------------------------------------------------------
// Native peripheral bus target behind periph_axil_shim.
//   +0x00 MODE      RW bit0 QUAD_EN
//   +0x04 PROG_CTRL WO bit[1:0] op, bit8 start pulse
//   +0x08 PROG_ADDR RW flash byte address
//   +0x0c PROG_LEN  RW PP byte count, clamped to 1..256
//   +0x10 STATUS    RO bit0 busy, bit1 done sticky read-clear, [15:8] RDSR
//   +0x100..0x1fc WBUF 256B write buffer, byte-strobed writes
// =============================================================================
`default_nettype none

module qspi_csr (
    input  wire        clk,
    input  wire        rst,

    input  wire        en,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [ 3:0] wstrb,
    output reg  [31:0] rdata,

    output wire        mode_quad_o,
    output reg         start_o,
    output reg  [ 1:0] op_o,
    output wire [31:0] prog_addr_o,
    output wire [ 8:0] prog_len_o,
    input  wire        busy_i,
    input  wire        done_i,
    input  wire [ 7:0] rdsr_i,

    input  wire [ 8:0] wr_addr_i,
    output wire [ 7:0] wr_data_o
);
    localparam [9:0] REG_MODE      = 10'h000;
    localparam [9:0] REG_PROG_CTRL = 10'h001;
    localparam [9:0] REG_PROG_ADDR = 10'h002;
    localparam [9:0] REG_PROG_LEN  = 10'h003;
    localparam [9:0] REG_STATUS    = 10'h004;

    reg        mode_quad_q;
    reg [31:0] prog_addr_q;
    reg [ 8:0] prog_len_q;
    reg        done_q;
    reg [31:0] wbuf [0:63];

    wire        is_write = en && (|wstrb);
    wire        is_read = en && (~|wstrb);
    wire [ 9:0] reg_sel = addr[11:2];
    wire        is_wbuf = (addr[11:8] == 4'h1);
    wire        status_read = is_read && (reg_sel == REG_STATUS);
    wire        start_write = is_write && (reg_sel == REG_PROG_CTRL) &&
                              wstrb[1] && wdata[8] && !busy_i;
    wire [31:0] prog_len_word = {23'h0, prog_len_q};
    wire [31:0] prog_len_merged = {
        wstrb[3] ? wdata[31:24] : prog_len_word[31:24],
        wstrb[2] ? wdata[23:16] : prog_len_word[23:16],
        wstrb[1] ? wdata[15: 8] : prog_len_word[15: 8],
        wstrb[0] ? wdata[ 7: 0] : prog_len_word[ 7: 0]
    };
    wire [31:0] status_word = {16'h0, rdsr_i, 6'h0, (done_q | done_i), busy_i};
    wire [31:0] wbuf_word = wbuf[addr[7:2]];

    integer i;

    function [8:0] clamp_len;
        input [31:0] v;
        begin
            if (v == 32'h0)
                clamp_len = 9'd1;
            else if (v >= 32'd256)
                clamp_len = 9'd256;
            else
                clamp_len = v[8:0];
        end
    endfunction

    assign mode_quad_o = mode_quad_q;
    assign prog_addr_o = prog_addr_q;
    assign prog_len_o = prog_len_q;
    assign wr_data_o = wr_addr_i[8] ? 8'hff :
                       (wr_addr_i[1:0] == 2'd0) ? wbuf[wr_addr_i[7:2]][ 7: 0] :
                       (wr_addr_i[1:0] == 2'd1) ? wbuf[wr_addr_i[7:2]][15: 8] :
                       (wr_addr_i[1:0] == 2'd2) ? wbuf[wr_addr_i[7:2]][23:16] :
                                                  wbuf[wr_addr_i[7:2]][31:24];

    always @* begin
        rdata = 32'h0;
        if (is_read) begin
            if (reg_sel == REG_MODE)
                rdata = {31'h0, mode_quad_q};
            else if (reg_sel == REG_PROG_ADDR)
                rdata = prog_addr_q;
            else if (reg_sel == REG_PROG_LEN)
                rdata = {23'h0, prog_len_q};
            else if (reg_sel == REG_STATUS)
                rdata = status_word;
            else if (is_wbuf)
                rdata = 32'h0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            mode_quad_q <= 1'b0;
            start_o <= 1'b0;
            op_o <= 2'b00;
            prog_addr_q <= 32'h0;
            prog_len_q <= 9'd1;
            done_q <= 1'b0;
            for (i = 0; i < 64; i = i + 1)
                wbuf[i] <= 32'h0;
        end else begin
            start_o <= 1'b0;

            if (status_read && !done_i)
                done_q <= 1'b0;
            if (done_i)
                done_q <= 1'b1;

            if (is_write && (reg_sel == REG_MODE) && wstrb[0])
                mode_quad_q <= wdata[0];

            if (start_write) begin
                start_o <= 1'b1;
                op_o <= wdata[1:0];
            end

            if (is_write && (reg_sel == REG_PROG_ADDR)) begin
                if (wstrb[0])
                    prog_addr_q[ 7: 0] <= wdata[ 7: 0];
                if (wstrb[1])
                    prog_addr_q[15: 8] <= wdata[15: 8];
                if (wstrb[2])
                    prog_addr_q[23:16] <= wdata[23:16];
                if (wstrb[3])
                    prog_addr_q[31:24] <= wdata[31:24];
            end

            if (is_write && (reg_sel == REG_PROG_LEN))
                prog_len_q <= clamp_len(prog_len_merged);

            if (is_write && is_wbuf) begin
                if (wstrb[0])
                    wbuf[addr[7:2]][ 7: 0] <= wdata[ 7: 0];
                if (wstrb[1])
                    wbuf[addr[7:2]][15: 8] <= wdata[15: 8];
                if (wstrb[2])
                    wbuf[addr[7:2]][23:16] <= wdata[23:16];
                if (wstrb[3])
                    wbuf[addr[7:2]][31:24] <= wdata[31:24];
            end
        end
    end

    wire unused_addr = |{addr[31:12], addr[1:0], wbuf_word};
endmodule
`default_nettype wire
