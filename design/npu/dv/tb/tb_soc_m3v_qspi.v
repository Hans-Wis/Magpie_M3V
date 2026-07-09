// =============================================================================
// tb_soc_m3v_qspi.v — gate_92/93: ADR-0071 P2 (prog/erase CSR + quad e2e)
// -----------------------------------------------------------------------------
// imem-boot; firmware (+HOST_INIT_HEX) is self-checking against the flash image
// (+FLASH_HEX = xip_img_p2.hex) and writes DONE_PASS/FAIL+stage to shared mem.
// TB adds what firmware cannot see: QSPI cold/warm counter snapshots around the
// FLAG_COLDMARK handshake (post-PROG first XIP read must open COLD — ADR §5)
// and the final stats line for the gates.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_soc_m3v_qspi;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    wire host_trap, host_axi_err, npu_irq;
    wire [31:0] host_dbg_pc, host_dbg_instr;
    wire [2:0] host_dbg_state;
    wire uart_tx_strobe;
    wire [7:0] uart_tx_byte;
    wire qspi_sclk, qspi_cs_n;
    wire [3:0] qspi_io_o, qspi_io_oe, qspi_io_i;
    wire [15:0] gpio_out, gpio_oe;
    wire dm_ndmreset, jtag_tdo;

    reg [1023:0] host_hex;

    soc_m3v_top #(
        .HOST_IMEM_WORDS(8192),
        .HOST_IMEM_AW(13),
        .SHARED_WORDS(16384),
        .SHARED_AW(14),
        .HOST_INIT_HEX("")   // overridden below via $value$plusargs into imem
    ) dut (
        .clk(clk), .resetn(resetn),
        .host_trap(host_trap), .host_axi_err(host_axi_err),
        .host_dbg_pc(host_dbg_pc), .host_dbg_instr(host_dbg_instr),
        .host_dbg_state(host_dbg_state),
        .npu_irq(npu_irq),
        .uart_tx_strobe(uart_tx_strobe), .uart_tx_byte(uart_tx_byte),
        .qspi_sclk(qspi_sclk), .qspi_cs_n(qspi_cs_n),
        .qspi_io_o(qspi_io_o), .qspi_io_oe(qspi_io_oe), .qspi_io_i(qspi_io_i),
        .gpio_out(gpio_out), .gpio_oe(gpio_oe), .gpio_in(16'h0),
        .jtag_tck(1'b0), .jtag_tms(1'b0), .jtag_tdi(1'b0), .jtag_tdo(jtag_tdo),
        .dm_ndmreset(dm_ndmreset)
    );

    spi_nor_model u_flash (
        .clk(clk),
        .sclk(qspi_sclk), .cs_n(qspi_cs_n),
        .io_i(qspi_io_o), .io_o(qspi_io_i), .io_oe_i(qspi_io_oe));

    initial begin
        if ($value$plusargs("HOST_INIT_HEX=%s", host_hex))
            $readmemh(host_hex, dut.u_host_imem.mem);
    end

    localparam integer DONE_WORD = 32'h0000FF00 >> 2;
    localparam integer COLDMARK_WORD = 32'h0000FE30 >> 2;
    localparam [31:0] DONE_PASS = 32'h534F4350;
    localparam [31:0] DONE_FAIL = 32'h534F4346;

    // post-PROG cold reopen check: cold counters must advance between
    // FLAG_COLDMARK 1 (before PP) and 2 (after first post-PP XIP read)
    reg [31:0] cold_at_mark1 = 0;
    reg        mark1_seen = 0, mark2_seen = 0;
    reg [31:0] cold_delta = 0;
    always @(posedge clk) begin
        if (!mark1_seen && dut.u_shared_sram.mem[COLDMARK_WORD] == 32'h1) begin
            mark1_seen <= 1'b1;
            cold_at_mark1 <= dut.qspi_cold_reads + dut.qspi_quad_cold_reads;
        end
        if (mark1_seen && !mark2_seen && dut.u_shared_sram.mem[COLDMARK_WORD] == 32'h2) begin
            mark2_seen <= 1'b1;
            cold_delta <= (dut.qspi_cold_reads + dut.qspi_quad_cold_reads) - cold_at_mark1;
        end
    end

    integer i;
    reg [31:0] marker;
    initial begin
        repeat (8) @(posedge clk);
        resetn = 1'b1;

        for (i = 0; i < 4000000; i = i + 1) begin
            @(posedge clk);
            marker = dut.u_shared_sram.mem[DONE_WORD];
            if (marker == DONE_PASS || marker == DONE_FAIL) i = 4000000;
        end

        marker = dut.u_shared_sram.mem[DONE_WORD];
        if (marker == DONE_FAIL)
            $display("SOC_QSPI_FAIL stage=%0d evidence=%08x",
                     dut.u_shared_sram.mem[DONE_WORD + 1],
                     dut.u_shared_sram.mem[DONE_WORD + 2]);
        else if (marker != DONE_PASS)
            $display("SOC_QSPI_TIMEOUT pc=%08x instr=%08x trap=%0b",
                     host_dbg_pc, host_dbg_instr, host_trap);

        if (mark1_seen && mark2_seen)
            $display("SOC_QSPI_COLDMARK delta=%0d", cold_delta);

        $display("SOC_QSPI_STATS cold=%0d warm=%0d qcold=%0d qwarm=%0d",
                 dut.qspi_cold_reads, dut.qspi_warm_reads,
                 dut.qspi_quad_cold_reads, dut.qspi_quad_warm_reads);
        if (marker == DONE_PASS && !host_trap && !host_axi_err)
            $display("SOC_QSPI_PASS");
        else begin
            $display("SOC_QSPI_FAIL");
            $fatal(1, "SOC_QSPI_FAIL");
        end
        $finish;
    end

    initial begin
        #80000000;
        $fatal(1, "SOC_QSPI_TIMEOUT watchdog pc=%08x", host_dbg_pc);
    end
endmodule
`default_nettype wire
