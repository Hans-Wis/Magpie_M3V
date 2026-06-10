`default_nettype none

module forward_assert_bind (
    input wire [4:0] id_rs1_idx,
    input wire [4:0] id_rs2_idx,
    input wire       em_valid,
    input wire       em_rd_we,
    input wire [4:0] em_rd_idx,
    input wire       em_is_load,
    input wire       wb_valid,
    input wire       wb_rd_we,
    input wire [4:0] wb_rd_idx,
    input wire       wb_is_load,
    input wire       em_fwd_ok,
    input wire       em_fwd_rs1,
    input wire       em_fwd_rs2,
    input wire       wb_fwd_ok,
    input wire       wb_fwd_rs1,
    input wire       wb_fwd_rs2
);
    wire em_allowed = em_valid && em_rd_we && !em_is_load && (em_rd_idx != 5'd0);
    wire wb_allowed = wb_valid && wb_rd_we && (wb_rd_idx != 5'd0);

    always @* begin
        assert (em_fwd_ok == em_allowed);
        assert (wb_fwd_ok == wb_allowed);

        assert (!em_fwd_rs1 || (em_allowed && (id_rs1_idx == em_rd_idx)));
        assert (!em_fwd_rs2 || (em_allowed && (id_rs2_idx == em_rd_idx)));
        assert (!wb_fwd_rs1 || (wb_allowed && !em_fwd_rs1 && (id_rs1_idx == wb_rd_idx)));
        assert (!wb_fwd_rs2 || (wb_allowed && !em_fwd_rs2 && (id_rs2_idx == wb_rd_idx)));

        assert (!(em_fwd_rs1 || em_fwd_rs2) || !em_is_load);
        assert (!(em_fwd_rs1 || em_fwd_rs2 || wb_fwd_rs1 || wb_fwd_rs2) ||
                ((em_rd_idx != 5'd0) || (wb_rd_idx != 5'd0)));
    end

    wire _wb_load_documented_allowed = wb_is_load;
endmodule

bind forward forward_assert_bind forward_assert_i (
    .id_rs1_idx(id_rs1_idx),
    .id_rs2_idx(id_rs2_idx),
    .em_valid(em_valid),
    .em_rd_we(em_rd_we),
    .em_rd_idx(em_rd_idx),
    .em_is_load(em_is_load),
    .wb_valid(wb_valid),
    .wb_rd_we(wb_rd_we),
    .wb_rd_idx(wb_rd_idx),
    .wb_is_load(wb_is_load),
    .em_fwd_ok(em_fwd_ok),
    .em_fwd_rs1(em_fwd_rs1),
    .em_fwd_rs2(em_fwd_rs2),
    .wb_fwd_ok(wb_fwd_ok),
    .wb_fwd_rs1(wb_fwd_rs1),
    .wb_fwd_rs2(wb_fwd_rs2)
);

`default_nettype wire
