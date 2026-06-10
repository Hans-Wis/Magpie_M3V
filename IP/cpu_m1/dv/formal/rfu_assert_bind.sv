`default_nettype none

module rfu_assert_bind (
    input wire        clk,
    input wire [ 4:0] rs1_idx,
    input wire [31:0] rs1_data,
    input wire [ 4:0] rs2_idx,
    input wire [31:0] rs2_data,
    input wire        we,
    input wire [ 4:0] rd_idx,
    input wire [31:0] rd_data,
    input wire [31:0] x0_raw
);
    always @* begin
        if (rs1_idx == 5'd0)
            assert (rs1_data == 32'h0000_0000);
        if (rs2_idx == 5'd0)
            assert (rs2_data == 32'h0000_0000);
        assert (x0_raw == 32'h0000_0000);
    end

    always @(posedge clk) begin
        if (we && (rd_idx == 5'd0))
            assert (x0_raw == 32'h0000_0000);
    end

    wire _unused = ^rd_data;
endmodule

bind rfu rfu_assert_bind rfu_assert_i (
    .clk(clk),
    .rs1_idx(rs1_idx),
    .rs1_data(rs1_data),
    .rs2_idx(rs2_idx),
    .rs2_data(rs2_data),
    .we(we),
    .rd_idx(rd_idx),
    .rd_data(rd_data),
    .x0_raw(regs[0])
);

`default_nettype wire
