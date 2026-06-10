`timescale 1ns / 1ns

module tb_coremark;
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

    localparam MEM_SIZE = 65536;
    localparam MMIO_RESULT_BASE = 32'h1000_0000;
    localparam MMIO_UART        = 32'h1000_0020;
    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [15:0] i_word_idx = i_mem_addr[17:2];
    wire [15:0] d_word_idx = d_mem_addr[17:2];

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

    integer timed_active;
    integer timed_cycles;
    integer timed_commits;
    integer stall_load_use_cycles;
    integer stall_muldiv_cycles;
    integer stall_fetch_cycles;
    integer redirect_cycles;
    integer other_stall_cycles;

    always @(posedge clk) begin
        if (i_mem_en) i_mem_rdata <= memory[i_word_idx];

        if (d_mem_valid) begin
            d_mem_rdata <= (d_mem_addr[31:18] == 14'h0) ? memory[d_word_idx] : 32'h0;
            if (|d_mem_wstrb) begin
                if (d_mem_addr == MMIO_UART) begin
                    $write("%c", d_mem_wdata[7:0]);
                end else if (d_mem_addr >= MMIO_RESULT_BASE && d_mem_addr < MMIO_RESULT_BASE + 32'h20) begin
                    $display("MMIO_RESULT[%0d]=%08x", (d_mem_addr - MMIO_RESULT_BASE) >> 2, d_mem_wdata);
                    if (d_mem_addr == MMIO_RESULT_BASE + 32'h18 && d_mem_wdata == 32'h53544152) begin
                        timed_active <= 1;
                        timed_cycles <= 0;
                        timed_commits <= 0;
                        stall_load_use_cycles <= 0;
                        stall_muldiv_cycles <= 0;
                        stall_fetch_cycles <= 0;
                        redirect_cycles <= 0;
                        other_stall_cycles <= 0;
                    end else if (d_mem_addr == MMIO_RESULT_BASE + 32'h1c && d_mem_wdata == 32'h53544f50) begin
                        timed_active <= 0;
                        $display("TB_TIMED cycles=%0d commits=%0d load_use_stall=%0d muldiv_stall=%0d fetch_stall=%0d redirect=%0d other_stall=%0d",
                                 timed_cycles, timed_commits, stall_load_use_cycles,
                                 stall_muldiv_cycles, stall_fetch_cycles, redirect_cycles,
                                 other_stall_cycles);
                    end
                end else if (d_mem_addr[31:18] == 14'h0) begin
                    if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
                    if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
                    if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
                    if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
                end else begin
                    $display("FAIL: unmapped store addr=%08x data=%08x", d_mem_addr, d_mem_wdata);
                    $fatal(1);
                end
            end
        end
    end

    integer commit_count;
    integer watchdog;

    initial begin
        commit_count = 0;
        watchdog = 0;
        timed_active = 0;
        timed_cycles = 0;
        timed_commits = 0;
        stall_load_use_cycles = 0;
        stall_muldiv_cycles = 0;
        stall_fetch_cycles = 0;
        redirect_cycles = 0;
        other_stall_cycles = 0;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (timed_active) begin
            timed_cycles <= timed_cycles + 1;
            if (dut.wb_instr_retired && !dut.ex_wb_illegal_r)
                timed_commits <= timed_commits + 1;
            if (dut.u_hazard.load_use_stall)
                stall_load_use_cycles <= stall_load_use_cycles + 1;
            else if (dut.md_busy)
                stall_muldiv_cycles <= stall_muldiv_cycles + 1;
            else if (dut.fetch_stall)
                stall_fetch_cycles <= stall_fetch_cycles + 1;
            else if (dut.pc_redirect || dut.redirect_warmup)
                redirect_cycles <= redirect_cycles + 1;
            else if (dut.any_stall)
                other_stall_cycles <= other_stall_cycles + 1;
        end
        if (watchdog > 2000000000) begin
            $display("FAIL: watchdog timeout");
            $fatal(1);
        end
        if (watchdog != 0 && (watchdog % 10000000) == 0) begin
            $display("PROGRESS: cycles=%0d commits=%0d pc=%08x", watchdog, commit_count, dbg_pc);
        end

        if (dut.ex_wb_valid_r && dut.ex_wb_illegal_r) begin
            $display("[%0t ns] stop on illegal/ebreak pc=%08x commits=%0d cycles=%0d",
                     $time, dut.ex_wb_pc_r, commit_count, watchdog);
            if (commit_count < 8) begin
                $display("FAIL: too few commits before ebreak");
                $fatal(1);
            end
            $display("PASS: CoreMark firmware reached ebreak after %0d commits", commit_count);
            $finish;
        end else if (dut.wb_instr_retired && !dut.ex_wb_illegal_r) begin
            commit_count <= commit_count + 1;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
