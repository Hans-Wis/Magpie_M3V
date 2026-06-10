`default_nettype none

module lsu_assert_bind (
    input wire       is_store,
    input wire [3:0] mem_wstrb
);
    always @* begin
        if (!is_store)
            assert (mem_wstrb == 4'b0000);
    end
endmodule

bind lsu lsu_assert_bind lsu_assert_i (
    .is_store(is_store),
    .mem_wstrb(mem_wstrb)
);

`default_nettype wire
