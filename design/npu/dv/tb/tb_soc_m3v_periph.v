// =============================================================================
// tb_soc_m3v_periph.v - UART + CLINT directed SoC smoke for ADR-0069
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_soc_m3v_periph;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    wire host_trap;
    wire host_axi_err;
    wire npu_irq;
    wire uart_tx_strobe;
    wire [ 7:0] uart_tx_byte;
    wire [31:0] host_dbg_pc;
    wire [31:0] host_dbg_instr;
    wire [ 2:0] host_dbg_state;
    wire qspi_sclk;
    wire qspi_cs_n;
    wire qspi_si;
    wire qspi_so;

    soc_m3v_top #(
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
        .qspi_si(qspi_si),
        .qspi_so(qspi_so)
    );

    spi_nor_model #(
        .IMG_BYTES(65536)
    ) flash (
        .sclk(qspi_sclk),
        .cs_n(qspi_cs_n),
        .si(qspi_si),
        .so(qspi_so)
    );

    localparam integer DONE_WORD = 32'h0000FF00 >> 2;
    localparam integer FLAG_WORD = 32'h0000FE00 >> 2;
    localparam [31:0] DONE_PASS = 32'hC0DE0087;
    localparam [31:0] DONE_FAIL = 32'hBAD00087;
    localparam integer WATCHDOG_CYCLES = 2000000;

    integer i;
    reg [31:0] marker;
    reg [1023:0] host_init_hex;

    initial begin
        host_init_hex = "design/npu/sw/host_uart_clint/host_uart_clint.hex";
        if ($value$plusargs("HOST_INIT_HEX=%s", host_init_hex))
            $display("SOC_PERIPH_HOST_INIT_HEX %0s", host_init_hex);
        $readmemh(host_init_hex, dut.u_host_imem.mem);

        repeat (8) @(posedge clk);
        resetn = 1'b1;

        for (i = 0; i < WATCHDOG_CYCLES; i = i + 1) begin
            @(posedge clk);
            marker = dut.u_shared_sram.mem[DONE_WORD];
            if (marker == DONE_PASS) begin
                $display("SOC_PERIPH_PASS");
                i = WATCHDOG_CYCLES;
            end
            if (marker == DONE_FAIL) begin
                $display("SOC_PERIPH_FAIL stage=%08x evidence=%08x error=%08x",
                         dut.u_shared_sram.mem[DONE_WORD + 1],
                         dut.u_shared_sram.mem[DONE_WORD + 2],
                         dut.u_shared_sram.mem[FLAG_WORD + 4]);
                $fatal(1, "SOC_PERIPH_FAIL");
            end
        end

        if (marker == DONE_PASS) begin
            $finish;
        end else begin
            $display("SOC_PERIPH_TIMEOUT pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b done=%08x ext=%08x timer=%08x soft=%08x",
                     host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err,
                     dut.u_shared_sram.mem[DONE_WORD],
                     dut.u_shared_sram.mem[FLAG_WORD + 1],
                     dut.u_shared_sram.mem[FLAG_WORD + 2],
                     dut.u_shared_sram.mem[FLAG_WORD + 3]);
            $fatal(1, "SOC_PERIPH_TIMEOUT");
        end
    end

    always @(posedge clk) begin
        if (uart_tx_strobe)
            $display("UART_TX %02x (%c)", uart_tx_byte, uart_tx_byte);
    end
endmodule
`default_nettype wire
