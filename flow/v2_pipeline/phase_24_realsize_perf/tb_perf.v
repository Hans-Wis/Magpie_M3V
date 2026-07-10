`timescale 1ns / 1ns

// Magpie_M1 benchmark TB (Phase 0, M1A evaluation): 256KB unified 1-cycle memory (same timing
// model as the riscv-dv lockstep farm TB, i.e. ideal TCM-like memory — report this with any
// score), MMIO putchar @0x10000000 (prints to stdout), trap-cause report @0x10000004 (treated
// as FAIL), stop on ebreak. No tracing/coverage — built for wall-clock speed.
module tb_perf;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    wire        trap;
    wire [31:0] i_mem_addr;
    wire        i_mem_en;
    reg  [31:0] i_mem_rdata;
    wire        d_mem_valid;
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [ 3:0] d_mem_wstrb;
    reg  [31:0] d_mem_rdata;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;

    localparam MEM_WORDS = 65536;            // 256 KB
    reg [31:0] memory [0:MEM_WORDS-1];
    initial $readmemh("firmware.hex", memory);

    wire [15:0] i_word_idx = i_mem_addr[17:2];
    wire [15:0] d_word_idx = d_mem_addr[17:2];
    wire        d_is_mmio  = d_mem_addr[28];

    // NPU sequencer config (ADR-0032): stripped spine + Zve32x + F
    core #(
        .EN_RVC(0), .EN_BP(0), .EN_RAS(0), .EN_RVV(1), .EN_F(1)
    ) dut (
        .clk                (clk),
        .resetn             (resetn),
        .trap               (trap),
        .mem_stall          (1'b0),
        .i_mem_addr         (i_mem_addr),
        .i_mem_en           (i_mem_en),
        .i_mem_rdata        (i_mem_rdata),
        .d_mem_valid        (d_mem_valid),
        .d_mem_addr         (d_mem_addr),
        .d_mem_wdata        (d_mem_wdata),
        .d_mem_wstrb        (d_mem_wstrb),
        .d_mem_rdata        (d_mem_rdata),
        .irq_external_pulse (1'b0),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy_halted),
        .debug_mode_o       (dbg_dummy_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dbg_dummy_acc_rdata),
        .dm_acc_err         (dbg_dummy_acc_err),
        .dbg_pc             (dbg_pc),
        .dbg_instr          (dbg_instr),
        .dbg_state          (dbg_state)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (i_mem_en) i_mem_rdata <= memory[i_word_idx];
        if (d_mem_valid) begin
            d_mem_rdata <= memory[d_word_idx];
            if (!d_is_mmio && |d_mem_wstrb) begin
                if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
                if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
                if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
                if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
            end
        end
    end

    longint cycles;
    longint max_cycles;

    initial begin
        cycles = 0;
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 200_000_000;
    end

    always @(posedge clk) begin
        cycles <= cycles + 1;
        if (cycles > max_cycles) begin
            $display("FAIL: watchdog timeout at %0d cycles", cycles);
            $fatal(1);
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            if (d_mem_addr == 32'h1000_0000) begin
                $write("%c", d_mem_wdata[7:0]);
                $fflush;
            end else if (d_mem_addr == 32'h1000_0004) begin
                $display("\nFAIL: unexpected trap mcause=%08x pc=%08x", d_mem_wdata, dbg_pc);
                $fatal(1);
            end
        end

        if (dut.ex_wb_valid_r && dut.ex_wb_is_ebreak_r) begin
            $display("\nBENCH DONE: tb cycles=%0d", cycles);
            $finish;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
