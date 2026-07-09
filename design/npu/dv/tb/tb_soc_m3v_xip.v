// =============================================================================
// tb_soc_m3v_xip.v — gate_86: XIP-boot SoC e2e (ADR-0069 Step B)
// -----------------------------------------------------------------------------
// Same q_proj offload as tb_soc_m3v, but the host boots at 0x4000_0000 and
// fetches EVERY instruction (and rodata load) over QSPI from the SPI-NOR model.
// Green-wash guard: HOST_INIT_HEX is left EMPTY — instruction memory at 0x0
// holds nothing, so any fetch outside the flash window cannot silently succeed.
// The only preload is the flash image (+FLASH_HEX, byte hex at flash offset 0).
// NOT a performance test: watchdog is ~20x the imem-boot budget (XIP ifetch is
// tens of clk/word cold; a timeout here means hang, not slowness — raise only
// with evidence).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_soc_m3v_xip;
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

    soc_m3v_top #(
        .HOST_RESET_PC(32'h4000_0000),
        .HOST_IMEM_WORDS(32768),
        .HOST_IMEM_AW(15),
        .SHARED_WORDS(16384),
        .SHARED_AW(14),
        .HOST_INIT_HEX("")
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .host_trap(host_trap),
        .host_axi_err(host_axi_err),
        .host_dbg_pc(host_dbg_pc),
        .host_dbg_instr(host_dbg_instr),
        .host_dbg_state(host_dbg_state),
        .npu_irq(npu_irq),
        .uart_tx_strobe(uart_tx_strobe),
        .uart_tx_byte(uart_tx_byte),
        .qspi_sclk(qspi_sclk),
        .qspi_cs_n(qspi_cs_n),
        .qspi_io_o(qspi_io_o), .qspi_io_oe(qspi_io_oe), .qspi_io_i(qspi_io_i)
    );

    // 1MB image window: host_producer text+rodata (~30KB) fits with margin.
    spi_nor_model #(.IMG_BYTES(1048576)) u_flash (
        .clk(clk),
        .sclk(qspi_sclk),
        .cs_n(qspi_cs_n),
        .io_i(qspi_io_o), .io_o(qspi_io_i), .io_oe_i(qspi_io_oe)
    );

    localparam integer DONE_WORD = 32'h0000FF00 >> 2;
    localparam integer RESULT_WORD = 32'h00001800 >> 2;
    localparam [31:0] DONE_PASS = 32'h534F4350;
    localparam [31:0] DONE_FAIL = 32'h534F4346;

    integer i;
    integer fdump;
    integer errors = 0;
    reg [31:0] marker;

    initial begin
        repeat (8) @(posedge clk);
        resetn = 1'b1;

        // 20x the imem-boot poll budget: XIP instruction fetch dominates.
        for (i = 0; i < 24000000; i = i + 1) begin
            @(posedge clk);
            marker = dut.u_shared_sram.mem[DONE_WORD];
            if (marker == DONE_PASS || marker == DONE_FAIL) begin
                i = 24000000;
            end
        end

        marker = dut.u_shared_sram.mem[DONE_WORD];
        if (marker !== DONE_PASS) begin
            errors = errors + 1;
            $display("SOC_M3V_XIP_FAIL: marker=%08x stage=%08x evidence=%08x",
                     marker,
                     dut.u_shared_sram.mem[DONE_WORD + 1],
                     dut.u_shared_sram.mem[DONE_WORD + 2]);
            $display("SOC_M3V_XIP_DIAG host_pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b npu_irq=%0b",
                     host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err, npu_irq);
        end
        if (host_trap || host_axi_err) begin
            errors = errors + 1;
            $display("SOC_M3V_XIP_FAIL: host_trap=%0b host_axi_err=%0b pc=%08x instr=%08x",
                     host_trap, host_axi_err, host_dbg_pc, host_dbg_instr);
        end

        fdump = $fopen("soc_m3v_xip_result.dump", "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fdump, "%08x", dut.u_shared_sram.mem[RESULT_WORD + i]);
        $fclose(fdump);

        $display("SOC_M3V_XIP_QSPI cold=%0d warm=%0d",
                 dut.qspi_cold_reads, dut.qspi_warm_reads);
        $display("SOC_M3V_XIP: %0d errors", errors);
        if (errors == 0) $display("SOC_M3V_XIP_PASS");
        else             $display("SOC_M3V_XIP_FAIL");
        $finish;
    end

    always @(posedge clk) begin
        if (uart_tx_strobe)
            $display("UART_TX %02x (%c)", uart_tx_byte, uart_tx_byte);
    end

    initial begin
        // 20x the imem-boot 30ms wall: XIP-boot is NOT a perf gate (ADR-0069).
        #600000000;
        $display("SOC_M3V_XIP_FAIL: timeout pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b marker=%08x",
                 host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err,
                 dut.u_shared_sram.mem[DONE_WORD]);
        $finish;
    end
endmodule
`default_nettype wire
