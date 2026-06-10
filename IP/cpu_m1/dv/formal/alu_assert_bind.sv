`default_nettype none

module alu_assert_bind (
    input wire [31:0] op_a,
    input wire [31:0] op_b,
    input wire        cmp_eq,
    input wire        cmp_lt_s,
    input wire        cmp_lt_u
);
    always @* begin
        assert (cmp_eq   == (op_a == op_b));
        assert (cmp_lt_s == ($signed(op_a) < $signed(op_b)));
        assert (cmp_lt_u == (op_a < op_b));
    end
endmodule

bind alu alu_assert_bind alu_assert_i (
    .op_a(op_a),
    .op_b(op_b),
    .cmp_eq(cmp_eq),
    .cmp_lt_s(cmp_lt_s),
    .cmp_lt_u(cmp_lt_u)
);

`default_nettype wire
