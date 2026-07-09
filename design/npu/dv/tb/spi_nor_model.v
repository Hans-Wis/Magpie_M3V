// =============================================================================
// spi_nor_model.v - small behavioral SPI-NOR model for QSPI XIP tests
// -----------------------------------------------------------------------------
// Mode 0 single-lane SPI. The model samples SI on SCLK rising edges and drives
// SO on falling edges. Opcode 0x03 consumes a 24-bit MSB-first address, then
// streams bytes MSB-first and auto-increments while CS_n remains low.
// =============================================================================
`default_nettype none

module spi_nor_model #(
    parameter integer IMG_BYTES = 65536
) (
    input  wire sclk,
    input  wire cs_n,
    input  wire si,
    output reg  so
);
    localparam [2:0] ST_OPCODE = 3'd0;
    localparam [2:0] ST_ADDR   = 3'd1;
    localparam [2:0] ST_READ   = 3'd2;
    localparam [2:0] ST_IGNORE = 3'd3;

    reg [7:0] mem [0:IMG_BYTES-1];
    reg [2:0] state;
    reg [7:0] opcode_q;
    reg [4:0] bit_count;
    reg [23:0] addr_q;
    reg [2:0] data_bit;
    reg warned_bad_opcode;
    reg [1023:0] flash_hex;

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
        warned_bad_opcode = 1'b0;
        so = 1'b1;
    end

    always @(posedge sclk or negedge sclk or posedge cs_n) begin
        if (cs_n) begin
            state <= ST_OPCODE;
            opcode_q <= 8'h00;
            bit_count <= 5'd0;
            addr_q <= 24'h0;
            data_bit <= 3'd7;
            so <= 1'b1;
        end else if (sclk) begin
            case (state)
                ST_OPCODE: begin
                    opcode_q <= {opcode_q[6:0], si};
                    if (bit_count == 5'd7) begin
                        if ({opcode_q[6:0], si} == 8'h03) begin
                            state <= ST_ADDR;
                            bit_count <= 5'd0;
                            addr_q <= 24'h0;
                        end else begin
                            state <= ST_IGNORE;
                            bit_count <= 5'd0;
                            if (!warned_bad_opcode) begin
                                $display("SPI_NOR_WARN unsupported opcode 0x%02x ignored until CS high",
                                         {opcode_q[6:0], si});
                                warned_bad_opcode <= 1'b1;
                            end
                        end
                    end else begin
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_ADDR: begin
                    addr_q <= {addr_q[22:0], si};
                    if (bit_count == 5'd23) begin
                        state <= ST_READ;
                        bit_count <= 5'd0;
                        data_bit <= 3'd7;
                    end else begin
                        bit_count <= bit_count + 5'd1;
                    end
                end
                ST_READ: begin
                    bit_count <= 5'd0;
                end
                default: begin
                    bit_count <= 5'd0;
                end
            endcase
        end else if (state == ST_READ) begin
            so <= read_byte(addr_q)[data_bit];
            if (data_bit == 3'd0) begin
                data_bit <= 3'd7;
                addr_q <= addr_q + 24'd1;
            end else begin
                data_bit <= data_bit - 3'd1;
            end
        end else begin
            so <= 1'b1;
        end
    end
endmodule
`default_nettype wire
