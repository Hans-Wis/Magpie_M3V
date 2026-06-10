`timescale 1ns / 1ns

module tb_directed_lockstep;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    reg         irq_external_pulse = 1'b0;
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

    localparam MEM_SIZE = 1048576;
    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [19:0] i_word_idx = i_mem_addr[21:2];
    wire [19:0] d_word_idx = d_mem_addr[21:2];

    reg mem_stall_q = 1'b0;
    reg loaduse_wait_armed = 1'b1;

    core dut (
        .clk                (clk),
        .resetn             (resetn),
        .trap               (trap),
        .mem_stall          (mem_stall_q),
        .i_mem_addr         (i_mem_addr),
        .i_mem_en           (i_mem_en),
        .i_mem_rdata        (i_mem_rdata),
        .d_mem_valid        (d_mem_valid),
        .d_mem_addr         (d_mem_addr),
        .d_mem_wdata        (d_mem_wdata),
        .d_mem_wstrb        (d_mem_wstrb),
        .d_mem_rdata        (d_mem_rdata),
        .irq_external_pulse (irq_external_pulse),
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
        if (!resetn) begin
            mem_stall_q <= 1'b0;
            loaduse_wait_armed <= 1'b1;
        end else if (loaduse_wait_armed && d_mem_valid && d_mem_addr[7:0] == 8'h00) begin
            mem_stall_q <= 1'b1;
            loaduse_wait_armed <= 1'b0;
        end else begin
            mem_stall_q <= 1'b0;
        end

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

    integer trace_fd;
    integer event_fd;
    integer commit_count;
    integer event_count;
    integer watchdog;
    reg [31:0] commit_instr;
    reg in_irq_handler_filter;
    reg injected_irq_alu;
    reg injected_irq_loaduse;

    function [31:0] instr_at_pc;
        input [31:0] pc;
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            word0 = memory[pc[21:2]];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = memory[pc[21:2] + 20'd1];
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
        event_fd = $fopen("dut_trap_events.csv", "w");
        if (trace_fd == 0 || event_fd == 0) begin
            $display("FAIL: could not open trace outputs");
            $fatal(1);
        end
        $fdisplay(trace_fd, "idx,pc,instr,rd,wdata");
        $fdisplay(event_fd, "idx,kind,pc,cause,mtval,mepc");
        commit_count = 0;
        event_count = 0;
        watchdog = 0;
        in_irq_handler_filter = 1'b0;
        injected_irq_alu = 1'b0;
        injected_irq_loaduse = 1'b0;
    end

    always @(negedge clk) begin
        if (resetn && !injected_irq_alu && dbg_pc == `P17_IRQ_ALU_PC) begin
            irq_external_pulse <= 1'b1;
            injected_irq_alu <= 1'b1;
        end else if (resetn && injected_irq_alu && !injected_irq_loaduse && dut.stall && !in_irq_handler_filter) begin
            irq_external_pulse <= 1'b1;
            injected_irq_loaduse <= 1'b1;
        end else begin
            irq_external_pulse <= 1'b0;
        end
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > 5000) begin
            $display("FAIL: watchdog timeout commits=%0d events=%0d pc=%08x instr=%08x",
                     commit_count, event_count, dbg_pc, dbg_instr);
            $fatal(1);
        end

        if (dut.wb_trap_enter && !dut.mem_stall) begin
            $fdisplay(event_fd, "%0d,%0s,%08x,%08x,%08x,%08x",
                      event_count,
                      dut.wb_take_irq ? "irq" : (dut.wb_take_data_trap ? "data" : "sync"),
                      dut.ex_wb_pc_r,
                      dut.wb_trap_cause,
                      dut.wb_trap_mtval,
                      dut.wb_trap_pc_for_mepc);
            event_count <= event_count + 1;
            if (dut.wb_take_irq) in_irq_handler_filter <= 1'b1;
        end

        if (dut.wb_trap_exit && in_irq_handler_filter) begin
            in_irq_handler_filter <= 1'b0;
        end

        if (dut.wb_instr_retired && !in_irq_handler_filter) begin
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

        if (d_mem_valid && |d_mem_wstrb && d_mem_addr == `P17_DONE_ADDR) begin
            if (!injected_irq_alu || !injected_irq_loaduse) begin
                $display("FAIL: missing IRQ injections alu=%0b loaduse=%0b", injected_irq_alu, injected_irq_loaduse);
                $fatal(1);
            end
            if (d_mem_wdata != 32'h0000_600d) begin
                $display("FAIL: done store data=%08x", d_mem_wdata);
                $fatal(1);
            end
            $fclose(trace_fd);
            $fclose(event_fd);
            $display("PASS: P17 trap DUT trace wrote %0d commits and %0d trap events", commit_count, event_count);
            $finish;
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, clk, resetn, irq_external_pulse, trap, commit_count, event_count,
                     mem_stall_q, i_mem_addr, i_mem_en, i_mem_rdata,
                     d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb,
                     dbg_pc, dbg_instr, dbg_state);
        $dumpvars(0, dut.wb_take_irq, dut.wb_take_data_trap, dut.wb_take_sync_trap,
                     dut.wb_trap_enter, dut.wb_trap_exit, dut.wb_trap_pc_for_mepc,
                     dut.wb_trap_cause, dut.wb_trap_mtval, dut.ex_wb_is_mret_r,
                     dut.ex_wb_is_misaligned_r, dut.ex_wb_is_misaligned_store_r,
                     dut.id_mem_misaligned, dut.id_mem_align_error);

        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
