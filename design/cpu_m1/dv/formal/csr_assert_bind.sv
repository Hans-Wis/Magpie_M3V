`include "def.vh"
`default_nettype none

module csr_assert_bind (
    input wire        clk,
    input wire        resetn,
    input wire [31:0] mstatus_val
);
    always @* begin
        assert (mstatus_val[`MSTATUS_MPP_HI_BIT:`MSTATUS_MPP_LO_BIT] == 2'b11);
        assert (mstatus_val[31:13] == 19'b0);
        assert (mstatus_val[10:8]  == 3'b0);
        assert (mstatus_val[6:4]   == 3'b0);
        assert (mstatus_val[2:0]   == 3'b0);

    end

    always @(posedge clk) begin
        if (resetn)
            assert (mstatus_val[`MSTATUS_MPP_HI_BIT:`MSTATUS_MPP_LO_BIT] == 2'b11);
    end
endmodule

bind csr csr_assert_bind csr_assert_i (
    .clk(clk),
    .resetn(resetn),
    .mstatus_val(mstatus_val)
);

`default_nettype wire
