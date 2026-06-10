// Behavioral simulation model for the T28 1RW1R SRAM wrapper port list.
// Synchronous read: dout reflects the selected word after a clock edge.
`default_nettype none

module sky130_sram_2kbyte_1rw1r_32x512_8 (
    input         clk0,
    input         csb0,
    input         web0,
    input  [3:0]  wmask0,
    input  [8:0]  addr0,
    input  [31:0] din0,
    output reg [31:0] dout0,
    input         clk1,
    input         csb1,
    input  [8:0]  addr1,
    output reg [31:0] dout1
);
    reg [31:0] mem [0:511];
    integer i;

    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            mem[i] = 32'h0;
        end
        dout0 = 32'h0;
        dout1 = 32'h0;
    end

    always @(posedge clk0) begin
        if (!csb0) begin
            dout0 <= mem[addr0];
            if (!web0) begin
                if (wmask0[0]) mem[addr0][ 7: 0] <= din0[ 7: 0];
                if (wmask0[1]) mem[addr0][15: 8] <= din0[15: 8];
                if (wmask0[2]) mem[addr0][23:16] <= din0[23:16];
                if (wmask0[3]) mem[addr0][31:24] <= din0[31:24];
            end
        end
    end

    always @(posedge clk1) begin
        if (!csb1) begin
            dout1 <= mem[addr1];
        end
    end
endmodule

`default_nettype wire
