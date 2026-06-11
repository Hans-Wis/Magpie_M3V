`timescale 1ns / 1ns

// A3 dtcm-IN-THE-LOOP directed lockstep (ADR-0026 A3 amended): the core runs the full A2
// directed program with its D-side served by the dtcm dual-bank macro instead of the flat
// 1-cycle array. Lockstep vs Spike proves the core port is bit/cycle-identical to the flat
// model (ZERO scalar regression by construction). A background WIDE-port reader runs the
// whole time, checking 64-bit reads against the flat shadow (write->wide coherence + live
// arbitration with the running core).
module tb_a3_dtcm;
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
    wire [31:0] d_mem_rdata;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;

    localparam MEM_SIZE = 4096;                  // words; same image as the flat TB
    reg [31:0] memory [0:MEM_SIZE-1];            // I-side + SHADOW for d-checks
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_word_idx = i_mem_addr[13:2];
    wire [11:0] d_word_idx = d_mem_addr[13:2];

    // ---- dtcm on the D-side ----
    reg         wide_en;
    reg  [31:0] wide_addr;
    wire [63:0] wide_rdata;
    wire        wide_ready;

    dtcm #(.WORDS(MEM_SIZE)) u_dtcm (
        .clk        (clk),
        .core_en    (d_mem_valid),
        .core_addr  ({18'b0, d_word_idx, 2'b00}),
        .core_rdata (d_mem_rdata),
        .core_wstrb (d_mem_wstrb),
        .core_wdata (d_mem_wdata),
        .wide_en    (wide_en),
        .wide_addr  (wide_addr),
        .wide_rdata (wide_rdata),
        .wide_ready (wide_ready)
    );

    integer init_i;
    initial begin
        #1;                                       // after $readmemh
        for (init_i = 0; init_i < MEM_SIZE/2; init_i = init_i + 1) begin
            u_dtcm.bank0[init_i] = memory[2*init_i];
            u_dtcm.bank1[init_i] = memory[2*init_i + 1];
        end
    end

    core dut (
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

    // I-side from the flat image; SHADOW mirrors d-side writes (for wide checking)
    always @(posedge clk) begin
        if (i_mem_en) i_mem_rdata <= memory[i_word_idx];
        if (d_mem_valid && |d_mem_wstrb) begin
            if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
            if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
            if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
            if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
        end
    end

    // ---- background WIDE reader: sweeps the image, checks vs shadow on each grant ----
    integer wide_grants;
    reg [63:0] wide_expect_q;
    reg        wide_pending;
    always @(posedge clk) begin
        if (!resetn) begin
            wide_en      <= 1'b0;
            wide_addr    <= 32'h0;
            wide_grants  <= 0;
            wide_pending <= 1'b0;
        end else begin
            wide_en <= 1'b1;
            if (wide_pending) begin
                if (wide_rdata !== wide_expect_q) begin
                    $display("FAIL: wide mismatch addr=%08x got=%016x exp=%016x",
                             wide_addr - 8, wide_rdata, wide_expect_q);
                    $fatal(1);
                end
                wide_pending <= 1'b0;
            end
            if (wide_en && wide_ready) begin
                wide_expect_q <= {memory[{wide_addr[13:3], 1'b1}], memory[{wide_addr[13:3], 1'b0}]};
                wide_pending  <= 1'b1;
                wide_grants   <= wide_grants + 1;
                wide_addr     <= (wide_addr + 8) & 32'h0000_1FF8;   // wrap inside the image
            end
        end
    end

    integer trace_fd;
    integer commit_count;
    integer watchdog;
    reg [31:0] commit_instr;

    function [31:0] instr_at_pc;
        input [31:0] pc;
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            word0 = memory[pc[13:2]];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = memory[pc[13:2] + 12'd1];
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
        trace_fd = $fopen("dut_commit.trace", "w");
        if (trace_fd == 0) begin
            $display("FAIL: could not open dut_commit.trace");
            $fatal(1);
        end
        $fdisplay(trace_fd, "idx,pc,instr,rd,wdata");
        commit_count = 0;
        watchdog = 0;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > 6000) begin
            $display("FAIL: watchdog timeout");
            $fatal(1);
        end

        if (dut.ex_wb_valid_r && dut.ex_wb_is_ebreak_r) begin
            $display("[%0t ns] stop on ebreak pc=%08x commits=%0d wide_grants=%0d",
                     $time, dut.ex_wb_pc_r, commit_count, wide_grants);
            if (commit_count < 8) begin
                $display("FAIL: too few commits before ebreak");
                $fatal(1);
            end
            if (wide_grants < 50) begin
                $display("FAIL: wide port barely exercised (%0d grants)", wide_grants);
                $fatal(1);
            end
            $fclose(trace_fd);
            $display("PASS: dtcm-in-the-loop trace wrote %0d commits, wide reader %0d coherent grants",
                     commit_count, wide_grants);
            $finish;
        end else if (dut.wb_instr_retired && !dut.ex_wb_illegal_r) begin
            /* verilator lint_off BLKSEQ */
            commit_instr = instr_at_pc(dut.ex_wb_pc_r);
            /* verilator lint_on BLKSEQ */
            $fdisplay(trace_fd, "%0d,%08x,%08x,%0d,%08x",
                      commit_count,
                      dut.ex_wb_pc_r,
                      (commit_instr[1:0] != 2'b11) ? {16'h0, commit_instr[15:0]} : commit_instr,
                      (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_idx : 5'd0,
                      (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_data : 32'h0);
            commit_count <= commit_count + 1;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
