// =============================================================================
// spi_nor_model.v - small behavioral SPI-NOR model for QSPI XIP tests
// -----------------------------------------------------------------------------
// Mode 0 SPI/QSPI. The model samples controller-driven lanes on SCLK rising
// edges and launches flash-driven lanes on falling edges.
//
// 0x03 remains the original single-lane path: io0 is SI, io1 is SO, 24-bit
// address MSB-first, then byte stream MSB-first while CS_n remains low.
//
// 0xEB implements the ADR-0071 frozen 1-4-4 frame:
// opcode 8 SCLK on io0, address 6 SCLK on four lanes, mode 2 SCLK on four lanes,
// dummy 4 SCLK with flash Hi-Z, data 8 SCLK per 32-bit word on four lanes.
//
// Program/erase commands are single-lane: WREN, PP, SE, BE, CE, and RDSR.
// WIP duration is abstracted in sysclk cycles per ADR-0071.
// =============================================================================
`default_nettype none

module spi_nor_model #(
    parameter integer IMG_BYTES = 65536
) (
    input  wire       clk,
    input  wire       sclk,
    input  wire       cs_n,
    input  wire [3:0] io_i,
    output reg  [3:0] io_o,
    input  wire [3:0] io_oe_i
);
    localparam [3:0] ST_OPCODE = 4'd0;
    localparam [3:0] ST_ADDR   = 4'd1;
    localparam [3:0] ST_READ   = 4'd2;
    localparam [3:0] ST_QADDR  = 4'd3;
    localparam [3:0] ST_QMODE  = 4'd4;
    localparam [3:0] ST_QDUMMY = 4'd5;
    localparam [3:0] ST_QREAD  = 4'd6;
    localparam [3:0] ST_IGNORE = 4'd7;
    localparam [3:0] ST_PADDR  = 4'd8;
    localparam [3:0] ST_PDATA  = 4'd9;
    localparam [3:0] ST_EADDR  = 4'd10;
    localparam [3:0] ST_RDSR   = 4'd11;

    reg [7:0] mem [0:IMG_BYTES-1];
    reg [7:0] pp_buf [0:255];
    reg [3:0] state;
    reg [7:0] opcode_q;
    reg       opcode_valid_q;
    reg [5:0] bit_count;
    reg [23:0] addr_q;
    reg [2:0] data_bit;
    reg       q_low_nibble;
    reg [7:0] mode_q;
    reg [7:0] pp_shift;
    reg [8:0] pp_count;
    reg       warned_bad_opcode;
    reg       warned_bad_mode;
    reg [1023:0] flash_hex;

    reg       wel_q;
    reg       wip_q;
    reg [9:0] wip_count_q;
    reg [3:0] commit_seq_q;
    reg [3:0] commit_seq_seen_q;
    reg [7:0] commit_opcode_q;
    reg [23:0] commit_addr_q;
    reg [8:0] commit_pp_count_q;

    // Testbenches use this hierarchical signal to assert bus-turnaround safety
    // without changing the public flash-model port contract.
    reg [3:0] driving_lanes;

    wire [7:0] status_byte = {6'b0, wel_q, wip_q};
    wire       commit_new = (commit_seq_seen_q != commit_seq_q);

    integer init_i;
    integer pp_init_i;
    integer prog_i;
    integer erase_i;
    integer mem_idx;
    integer erase_start_i;
    integer erase_end_i;
    reg [23:0] wrap_addr;

    function [7:0] read_byte;
        input [23:0] addr;
        integer idx;
        begin
            idx = {8'h00, addr};
            if (idx < IMG_BYTES)
                read_byte = mem[idx];
            else
                read_byte = 8'hff;
        end
    endfunction

    function [9:0] op_wip_cycles;
        input [7:0] op;
        begin
            if (op == 8'h02)
                op_wip_cycles = 10'd64;
            else if (op == 8'h20)
                op_wip_cycles = 10'd128;
            else if (op == 8'hd8)
                op_wip_cycles = 10'd256;
            else
                op_wip_cycles = 10'd512;
        end
    endfunction

    initial begin
        for (init_i = 0; init_i < IMG_BYTES; init_i = init_i + 1)
            mem[init_i] = 8'hff;
        for (pp_init_i = 0; pp_init_i < 256; pp_init_i = pp_init_i + 1)
            pp_buf[pp_init_i] = 8'hff;
        flash_hex = "";
        if ($value$plusargs("FLASH_HEX=%s", flash_hex)) begin
            $display("SPI_NOR_FLASH_HEX %0s", flash_hex);
            $readmemh(flash_hex, mem);
        end
        state = ST_OPCODE;
        opcode_q = 8'h00;
        opcode_valid_q = 1'b0;
        bit_count = 6'd0;
        addr_q = 24'h0;
        data_bit = 3'd7;
        q_low_nibble = 1'b0;
        mode_q = 8'h00;
        pp_shift = 8'h00;
        pp_count = 9'd0;
        warned_bad_opcode = 1'b0;
        warned_bad_mode = 1'b0;
        wel_q = 1'b0;
        wip_q = 1'b0;
        wip_count_q = 10'd0;
        commit_seq_q = 4'h0;
        commit_seq_seen_q = 4'h0;
        commit_opcode_q = 8'h00;
        commit_addr_q = 24'h0;
        commit_pp_count_q = 9'd0;
        io_o = 4'hf;
        driving_lanes = 4'b0000;
        wrap_addr = 24'h0;
    end

    always @(posedge clk) begin
        if (commit_new)
            commit_seq_seen_q <= commit_seq_q;

        if (commit_new && !wip_q && (commit_opcode_q == 8'h06)) begin
            wel_q <= 1'b1;
        end else if (commit_new && !wip_q && wel_q && (commit_opcode_q == 8'h02)) begin
            for (prog_i = 0; prog_i < 256; prog_i = prog_i + 1) begin
                if (prog_i < commit_pp_count_q) begin
                    wrap_addr = {commit_addr_q[23:8],
                                 commit_addr_q[7:0] + prog_i[7:0]};
                    mem_idx = {8'h00, wrap_addr};
                    if (mem_idx < IMG_BYTES)
                        mem[mem_idx] <= mem[mem_idx] & pp_buf[prog_i];
                end
            end
            wip_q <= 1'b1;
            wip_count_q <= op_wip_cycles(commit_opcode_q);
        end else if (commit_new && !wip_q && wel_q &&
                    ((commit_opcode_q == 8'h20) ||
                     (commit_opcode_q == 8'hd8))) begin
            erase_start_i = {8'h00, commit_addr_q};
            if (commit_opcode_q == 8'h20) begin
                erase_start_i = (erase_start_i / 4096) * 4096;
                erase_end_i = erase_start_i + 4096;
            end else begin
                erase_start_i = (erase_start_i / 65536) * 65536;
                erase_end_i = erase_start_i + 65536;
            end
            for (erase_i = 0; erase_i < IMG_BYTES; erase_i = erase_i + 1) begin
                if ((erase_i >= erase_start_i) && (erase_i < erase_end_i))
                    mem[erase_i] <= 8'hff;
            end
            wip_q <= 1'b1;
            wip_count_q <= op_wip_cycles(commit_opcode_q);
        end else if (commit_new && !wip_q && wel_q && (commit_opcode_q == 8'hc7)) begin
            for (erase_i = 0; erase_i < IMG_BYTES; erase_i = erase_i + 1)
                mem[erase_i] <= 8'hff;
            wip_q <= 1'b1;
            wip_count_q <= op_wip_cycles(commit_opcode_q);
        end else if (wip_q) begin
            if (wip_count_q <= 10'd1) begin
                wip_q <= 1'b0;
                wip_count_q <= 10'd0;
                wel_q <= 1'b0;
            end else begin
                wip_count_q <= wip_count_q - 10'd1;
            end
        end
    end

    always @(posedge sclk or negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            if (opcode_valid_q) begin
                commit_opcode_q <= opcode_q;
                commit_addr_q <= addr_q;
                commit_pp_count_q <= pp_count;
                commit_seq_q <= commit_seq_q + 4'd1;
            end
            state <= ST_OPCODE;
            opcode_q <= 8'h00;
            opcode_valid_q <= 1'b0;
            bit_count <= 6'd0;
            addr_q <= 24'h0;
            data_bit <= 3'd7;
            q_low_nibble <= 1'b0;
            mode_q <= 8'h00;
            pp_shift <= 8'h00;
            pp_count <= 9'd0;
            io_o <= 4'hf;
            driving_lanes <= 4'b0000;
        end else if (sclk) begin
            case (state)
                ST_OPCODE: begin
                    opcode_q <= {opcode_q[6:0], io_i[0]};
                    if (bit_count == 6'd7) begin
                        opcode_valid_q <= 1'b1;
                        if ({opcode_q[6:0], io_i[0]} == 8'h03) begin
                            state <= ST_ADDR;
                            bit_count <= 6'd0;
                            addr_q <= 24'h0;
                        end else if ({opcode_q[6:0], io_i[0]} == 8'heb) begin
                            state <= ST_QADDR;
                            bit_count <= 6'd0;
                            addr_q <= 24'h0;
                        end else if ({opcode_q[6:0], io_i[0]} == 8'h05) begin
                            state <= ST_RDSR;
                            bit_count <= 6'd0;
                            data_bit <= 3'd7;
                        end else if ({opcode_q[6:0], io_i[0]} == 8'h02) begin
                            state <= ST_PADDR;
                            bit_count <= 6'd0;
                            addr_q <= 24'h0;
                        end else if (({opcode_q[6:0], io_i[0]} == 8'h20) ||
                                     ({opcode_q[6:0], io_i[0]} == 8'hd8)) begin
                            state <= ST_EADDR;
                            bit_count <= 6'd0;
                            addr_q <= 24'h0;
                        end else if (({opcode_q[6:0], io_i[0]} == 8'h06) ||
                                     ({opcode_q[6:0], io_i[0]} == 8'hc7)) begin
                            state <= ST_IGNORE;
                            bit_count <= 6'd0;
                        end else begin
                            state <= ST_IGNORE;
                            bit_count <= 6'd0;
                            opcode_valid_q <= 1'b0;
                            if (!warned_bad_opcode) begin
                                $display("SPI_NOR_WARN unsupported opcode 0x%02x ignored until CS high",
                                         {opcode_q[6:0], io_i[0]});
                                warned_bad_opcode <= 1'b1;
                            end
                        end
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_ADDR: begin
                    addr_q <= {addr_q[22:0], io_i[0]};
                    if (bit_count == 6'd23) begin
                        state <= ST_READ;
                        bit_count <= 6'd0;
                        data_bit <= 3'd7;
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_PADDR: begin
                    addr_q <= {addr_q[22:0], io_i[0]};
                    if (bit_count == 6'd23) begin
                        state <= ST_PDATA;
                        bit_count <= 6'd0;
                        pp_shift <= 8'h00;
                        pp_count <= 9'd0;
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_PDATA: begin
                    pp_shift <= {pp_shift[6:0], io_i[0]};
                    if (bit_count == 6'd7) begin
                        if (pp_count != 9'd256) begin
                            pp_buf[pp_count[7:0]] <= {pp_shift[6:0], io_i[0]};
                            pp_count <= pp_count + 9'd1;
                        end
                        bit_count <= 6'd0;
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_EADDR: begin
                    addr_q <= {addr_q[22:0], io_i[0]};
                    if (bit_count == 6'd23) begin
                        state <= ST_IGNORE;
                        bit_count <= 6'd0;
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_QADDR: begin
                    addr_q <= {addr_q[19:0], io_i};
                    if (bit_count == 6'd5) begin
                        state <= ST_QMODE;
                        bit_count <= 6'd0;
                        mode_q <= 8'h00;
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_QMODE: begin
                    mode_q <= {mode_q[3:0], io_i};
                    if (bit_count == 6'd1) begin
                        bit_count <= 6'd0;
                        if ({mode_q[3:0], io_i} == 8'ha5) begin
                            state <= ST_QDUMMY;
                        end else begin
                            state <= ST_IGNORE;
                            if (!warned_bad_mode) begin
                                $display("SPI_NOR_WARN unsupported quad mode 0x%02x ignored until CS high",
                                         {mode_q[3:0], io_i});
                                warned_bad_mode <= 1'b1;
                            end
                        end
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_QDUMMY: begin
                    if (bit_count == 6'd3) begin
                        state <= ST_QREAD;
                        bit_count <= 6'd0;
                        q_low_nibble <= 1'b0;
                    end else begin
                        bit_count <= bit_count + 6'd1;
                    end
                end
                ST_READ,
                ST_QREAD,
                ST_RDSR: begin
                    bit_count <= 6'd0;
                end
                default: begin
                    bit_count <= 6'd0;
                end
            endcase
        end else if (state == ST_READ) begin
            io_o <= {2'b11, read_byte(addr_q)[data_bit], 1'b1};
            driving_lanes <= 4'b0010;
            if (data_bit == 3'd0) begin
                data_bit <= 3'd7;
                addr_q <= addr_q + 24'd1;
            end else begin
                data_bit <= data_bit - 3'd1;
            end
        end else if (state == ST_QREAD) begin
            driving_lanes <= 4'b1111;
            if (!q_low_nibble) begin
                io_o <= read_byte(addr_q)[7:4];
                q_low_nibble <= 1'b1;
            end else begin
                io_o <= read_byte(addr_q)[3:0];
                q_low_nibble <= 1'b0;
                addr_q <= addr_q + 24'd1;
            end
        end else if (state == ST_RDSR) begin
            io_o <= {2'b11, status_byte[data_bit], 1'b1};
            driving_lanes <= 4'b0010;
            if (data_bit == 3'd0)
                data_bit <= 3'd7;
            else
                data_bit <= data_bit - 3'd1;
        end else begin
            io_o <= 4'hf;
            driving_lanes <= 4'b0000;
        end
    end

    wire unused_turnaround_hint = |io_oe_i | |mode_q;
endmodule
`default_nettype wire
