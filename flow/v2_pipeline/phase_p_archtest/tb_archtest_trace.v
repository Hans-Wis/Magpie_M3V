`timescale 1ns / 1ns

module tb_archtest_trace;
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

    localparam MEM_WORDS = 524288;
    localparam ELF_BASE  = 32'h00001000;
    reg [31:0] memory [0:MEM_WORDS-1];

    reg [1023:0] firmware_hex;
    reg [1023:0] trace_path;
    integer max_cycles;
    integer trace_fd;
    integer i;
    integer watchdog;
    integer commit_count;
    reg [31:0] stop_addr;
    reg [31:0] commit_instr;

    wire [31:0] i_mem_offset = (i_mem_addr >= ELF_BASE) ? (i_mem_addr - ELF_BASE) : i_mem_addr;
    wire [18:0] i_word_idx = i_mem_offset[20:2];
    wire [31:0] d_mem_offset = (d_mem_addr >= ELF_BASE) ? (d_mem_addr - ELF_BASE) : d_mem_addr;
    wire [18:0] d_word_idx = d_mem_offset[20:2];

    core #(
        .RESET_PC(ELF_BASE)
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
            if (|d_mem_wstrb) begin
                if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
                if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
                if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
                if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
            end
        end
    end

    function [31:0] instr_at_pc;
        input [31:0] pc;
        reg [31:0] offset;
        reg [18:0] idx;
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            offset = (pc >= ELF_BASE) ? (pc - ELF_BASE) : pc;
            idx = offset[20:2];
            word0 = memory[idx];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = memory[idx + 19'd1];
                    instr_at_pc = {word1[15:0], half0};
                end else begin
                    instr_at_pc = {16'h0, half0};
                end
            end else begin
                half0 = word0[15:0];
                if (half0[1:0] == 2'b11)
                    instr_at_pc = word0;
                else
                    instr_at_pc = {16'h0, half0};
            end
        end
    endfunction

    initial begin
        if (!$value$plusargs("HEX=%s", firmware_hex)) firmware_hex = "firmware.hex";
        if (!$value$plusargs("TRACE=%s", trace_path)) trace_path = "dut_commit.trace";
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 5000000;
        if (!$value$plusargs("STOP_ADDR=%h", stop_addr)) stop_addr = 32'hffff_ffff;

        for (i = 0; i < MEM_WORDS; i = i + 1) memory[i] = 32'h0;
        $readmemh(firmware_hex, memory);

        trace_fd = $fopen(trace_path, "w");
        if (trace_fd == 0) begin
            $display("FAIL: could not open trace %0s", trace_path);
            $fatal(1);
        end
        $fdisplay(trace_fd, "idx,pc,instr,rd,wdata");
        watchdog = 0;
        commit_count = 0;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > max_cycles) begin
            $display("FAIL: watchdog timeout pc=%08x commits=%0d", dbg_pc, commit_count);
            $fclose(trace_fd);
            $fatal(1);
        end

        if (dut.wb_instr_retired && !dut.ex_wb_illegal_r) begin
            /* verilator lint_off BLKSEQ */
            commit_instr = instr_at_pc(dut.ex_wb_pc_r);
            /* verilator lint_on BLKSEQ */
            $fdisplay(trace_fd, "%0d,%08x,%08x,%0d,%08x",
                      commit_count,
                      dut.ex_wb_pc_r,
                      (commit_instr[1:0] != 2'b11) ? {16'h0, commit_instr[15:0]} : commit_instr,
                      dut.rfu_we ? dut.rfu_wr_idx : 5'd0,
                      dut.rfu_we ? dut.rfu_wr_data : 32'h0);
            commit_count <= commit_count + 1;
        end

        if (dut.ex_wb_valid_r && dut.ex_wb_illegal_r) begin
            $display("STOP: illegal/ebreak pc=%08x commits=%0d", dut.ex_wb_pc_r, commit_count);
            $fclose(trace_fd);
            $finish;
        end

        if (d_mem_valid && |d_mem_wstrb && d_mem_addr == stop_addr && d_mem_wdata != 32'h0) begin
            $display("STOP: tohost pc=%08x commits=%0d", dut.ex_wb_pc_r, commit_count);
            $fclose(trace_fd);
            $finish;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
