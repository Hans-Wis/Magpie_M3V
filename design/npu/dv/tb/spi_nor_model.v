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
// =============================================================================
`default_nettype none

module spi_nor_model #(
    parameter integer IMG_BYTES = 65536
) (
    input  wire       sclk,
    input  wire       cs_n,
    input  wire [3:0] io_i,
    output reg  [3:0] io_o,
    input  wire [3:0] io_oe_i
);
    localparam [2:0] ST_OPCODE = 3'd0;
    localparam [2:0] ST_ADDR   = 3'd1;
    localparam [2:0] ST_READ   = 3'd2;
    localparam [2:0] ST_QADDR  = 3'd3;
    localparam [2:0] ST_QMODE  = 3'd4;
    localparam [2:0] ST_QDUMMY = 3'd5;
    localparam [2:0] ST_QREAD  = 3'd6;
    localparam [2:0] ST_IGNORE = 3'd7;

    reg [7:0] mem [0:IMG_BYTES-1];
    reg [2:0] state;
    reg [7:0] opcode_q;
    reg [4:0] bit_count;
    reg [23:0] addr_q;
    reg [2:0] data_bit;
    reg       q_low_nibble;
    reg [7:0] mode_q;
    reg       warned_bad_opcode;
    reg       warned_bad_mode;
    reg [1023:0] flash_hex;

    // Testbenches use this hierarchical signal to assert bus-turnaround safety
    // without changing the public flash-model port contract.
    reg [3:0] driving_lanes;

    integer init_i;

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

    initial begin
        for (init_i = 0; init_i < IMG_BYTES; init_i = init_i + 1)
            mem[init_i] = 8'hff;
        flash_hex = "";
        if ($value$plusargs("FLASH_HEX=%s", flash_hex)) begin
            $display("SPI_NOR_FLASH_HEX %0s", flash_hex);
            $readmemh(flash_hex, mem);
        end
        state = ST_OPCODE;
        opcode_q = 8'h00;
        bit_count = 5'd0;
        addr_q = 24'h0;
        data_bit = 3'd7;
        q_low_nibble = 1'b0;
        mode_q = 8'h00;
        warned_bad_opcode = 1'b0;
        warned_bad_mode = 1'b0;
        io_o = 4'hf;
        driving_lanes = 4'b0000;
    end

    always @(posedge sclk or negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            state <= ST_OPCODE;
            opcode_q <= 8'h00;
            bit_count <= 5'd0;
            addr_q <= 24'h0;
            data_bit <= 3'd7;
            q_low_nibble <= 1'b0;
            mode_q <= 8'h00;
            io_o <= 4'hf;
            driving_lanes <= 4'b0000;
        end else if (sclk) begin
            case (state)
                ST_OPCODE: begin
                    opcode_q <= {opcode_q[6:0], io_i[0]};
                    if (bit_count == 5'd7) begin
                        if ({opcode_q[6:0], io_i[0]} == 8'h03) begin
                            state <= ST_ADDR;
                            bit_count <= 5'd0;
                            addr_q <= 24'h0;
                        end else if ({opcode_q[6:0], io_i[0]} == 8'heb) begin
                            state <= ST_QADDR;
                            bit_count <= 5'd0;
                            addr_q <= 24'h0;
                        end else begin
                            state <= ST_IGNORE;
                            bit_count <= 5'd0;
                            if (!warned_bad_opcode) begin
                                $display("SPI_NOR_WARN unsupported opcode 0x%02x ignored until CS high",
                                         {opcode_q[6:0], io_i[0]});
                                warned_bad_opcode <= 1'b1;
                            end
                        end
                    end else begin
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_ADDR: begin
                    addr_q <= {addr_q[22:0], io_i[0]};
                    if (bit_count == 5'd23) begin
                        state <= ST_READ;
                        bit_count <= 5'd0;
                        data_bit <= 3'd7;
                    end else begin
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_QADDR: begin
                    addr_q <= {addr_q[19:0], io_i};
                    if (bit_count == 5'd5) begin
                        state <= ST_QMODE;
                        bit_count <= 5'd0;
                        mode_q <= 8'h00;
                    end else begin
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_QMODE: begin
                    mode_q <= {mode_q[3:0], io_i};
                    if (bit_count == 5'd1) begin
                        bit_count <= 5'd0;
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
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_QDUMMY: begin
                    if (bit_count == 5'd3) begin
                        state <= ST_QREAD;
                        bit_count <= 5'd0;
                        q_low_nibble <= 1'b0;
                    end else begin
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_READ,
                ST_QREAD: begin
                    bit_count <= 5'd0;
                end
                default: begin
                    bit_count <= 5'd0;
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
        end else begin
            io_o <= 4'hf;
            driving_lanes <= 4'b0000;
        end
    end

    wire unused_turnaround_hint = |io_oe_i | |mode_q;
endmodule
`default_nettype wire
