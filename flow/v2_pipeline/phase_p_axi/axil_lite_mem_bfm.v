`timescale 1ns / 1ns
`default_nettype none

module axil_lite_mem_bfm #(
    parameter integer MEM_WORDS = 524288,
    parameter [31:0]  ELF_BASE  = 32'h0000_0000
)(
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] wait_states,

    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    input  wire [31:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg  [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,

    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output wire [ 1:0] s_axi_bresp
);
    reg [31:0] memory [0:MEM_WORDS-1];

    reg        rd_busy;
    reg [31:0] rd_addr_q;
    reg [31:0] rd_wait_q;

    reg        aw_seen;
    reg        w_seen;
    reg [31:0] wr_addr_q;
    reg [31:0] wr_data_q;
    reg [ 3:0] wr_strb_q;
    reg [31:0] wr_wait_q;

    integer i;

    wire [31:0] ar_offset = (s_axi_araddr >= ELF_BASE) ? (s_axi_araddr - ELF_BASE) : s_axi_araddr;
    wire [31:0] aw_offset = (s_axi_awaddr >= ELF_BASE) ? (s_axi_awaddr - ELF_BASE) : s_axi_awaddr;
    wire [31:0] rd_offset = (rd_addr_q     >= ELF_BASE) ? (rd_addr_q     - ELF_BASE) : rd_addr_q;
    wire [31:0] wr_offset = (wr_addr_q     >= ELF_BASE) ? (wr_addr_q     - ELF_BASE) : wr_addr_q;

    wire [18:0] rd_word_idx = rd_offset[20:2];
    wire [18:0] wr_word_idx = wr_offset[20:2];

    assign s_axi_arready = resetn && !rd_busy && !s_axi_rvalid;
    assign s_axi_awready = resetn && !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = resetn && !w_seen  && !s_axi_bvalid;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_bresp   = 2'b00;

    task load_hex;
        input [1023:0] path;
        begin
            for (i = 0; i < MEM_WORDS; i = i + 1) memory[i] = 32'h0;
            $readmemh(path, memory);
        end
    endtask

    task dump_signature;
        input [1023:0] path;
        input [31:0]   sig_begin;
        input [31:0]   sig_end;
        integer fd;
        integer addr;
        integer word_idx;
        reg [31:0] offset;
        begin
            fd = $fopen(path, "w");
            if (fd == 0) begin
                $display("FAIL: could not open signature %0s", path);
                $fatal(1);
            end
            for (addr = sig_begin; addr < sig_end; addr = addr + 4) begin
                offset = (addr >= ELF_BASE) ? (addr - ELF_BASE) : addr;
                word_idx = offset >> 2;
                $fdisplay(fd, "%08x", memory[word_idx]);
            end
            $fclose(fd);
        end
    endtask

    function [31:0] instr_at_pc;
        input [31:0] pc;
        reg [31:0] offset;
        reg [18:0] idx;
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            offset = (pc >= ELF_BASE) ? (pc - ELF_BASE) : pc;
            idx = offset[20:2];
            word0 = memory[idx];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = memory[idx + 19'd1];
                    instr_at_pc = {word1[15:0], half0};
                end else begin
                    instr_at_pc = {16'h0, half0};
                end
            end else begin
                half0 = word0[15:0];
                if (half0[1:0] == 2'b11)
                    instr_at_pc = word0;
                else
                    instr_at_pc = {16'h0, half0};
            end
        end
    endfunction

    task write_word;
        input [18:0] idx;
        input [31:0] data;
        input [3:0]  strb;
        begin
            if (strb[0]) memory[idx][ 7: 0] = data[ 7: 0];
            if (strb[1]) memory[idx][15: 8] = data[15: 8];
            if (strb[2]) memory[idx][23:16] = data[23:16];
            if (strb[3]) memory[idx][31:24] = data[31:24];
        end
    endtask

    always @(posedge clk) begin
        if (!resetn) begin
            rd_busy      <= 1'b0;
            rd_addr_q    <= 32'h0;
            rd_wait_q    <= 32'h0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'h0;
        end else begin
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (s_axi_arvalid && s_axi_arready) begin
                rd_busy   <= 1'b1;
                rd_addr_q <= s_axi_araddr;
                rd_wait_q <= wait_states;
            end else if (rd_busy && !s_axi_rvalid) begin
                if (rd_wait_q != 32'h0) begin
                    rd_wait_q <= rd_wait_q - 1'b1;
                end else begin
                    s_axi_rdata  <= memory[rd_word_idx];
                    s_axi_rvalid <= 1'b1;
                    rd_busy      <= 1'b0;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen      <= 1'b0;
            w_seen       <= 1'b0;
            wr_addr_q    <= 32'h0;
            wr_data_q    <= 32'h0;
            wr_strb_q    <= 4'h0;
            wr_wait_q    <= 32'h0;
            s_axi_bvalid <= 1'b0;
        end else begin
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen   <= 1'b1;
                wr_addr_q <= s_axi_awaddr;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_seen   <= 1'b1;
                wr_data_q <= s_axi_wdata;
                wr_strb_q <= s_axi_wstrb;
            end

            if (!s_axi_bvalid && aw_seen && w_seen) begin
                if (wr_wait_q == 32'h0) begin
                    write_word(wr_word_idx, wr_data_q, wr_strb_q);
                    s_axi_bvalid <= 1'b1;
                    aw_seen      <= 1'b0;
                    w_seen       <= 1'b0;
                    wr_wait_q    <= wait_states;
                end else begin
                    wr_wait_q <= wr_wait_q - 1'b1;
                end
            end else if (!aw_seen && !w_seen && !s_axi_bvalid) begin
                wr_wait_q <= wait_states;
            end
        end
    end

    wire _unused = ^{s_axi_arprot, s_axi_awprot, ar_offset[1:0], aw_offset[1:0]};
endmodule

`default_nettype wire
