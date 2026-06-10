`timescale 1ns / 1ns

module tb_trap_irq_lockstep;
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

    localparam MEM_SIZE = 4096;
    localparam IRQ_TARGET_PC = 32'h0000_0080;
    localparam IRQ_TARGET_EXPANDED = 32'h0014_0413;
    localparam EXPECTED_MEPC = 32'h0000_0082;
    localparam EXPECTED_MCAUSE = 32'h8000_000b;
    // M-mode handler mstatus: MPP=2'b11 (0x1800) + MPIE=1 (0x80) per Priv §3.1.6.
    // Updated from stale 0x0080 (pre-MPP) to spec-correct 0x1880; Spike-verified core. P2 2026-06-09.
    localparam EXPECTED_MSTATUS_IN_HANDLER = 32'h0000_1880;

    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_word_idx = i_mem_addr[13:2];
    wire [11:0] d_word_idx = d_mem_addr[13:2];
    wire        d_is_mmio = d_mem_addr[28];

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

    integer commit_fd;
    integer trap_fd;
    integer commit_count;
    integer watchdog;
    reg [31:0] commit_instr;
    reg injected_irq;
    reg saw_irq_entry;
    reg saw_mepc;
    reg saw_mcause;
    reg saw_mstatus;
    reg saw_resume;
    reg [31:0] stored_mepc;
    reg [31:0] stored_mcause;
    reg [31:0] stored_mstatus;

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
        commit_fd = $fopen("dut_commit.trace", "w");
        trap_fd = $fopen("dut_trap.trace", "w");
        if (commit_fd == 0 || trap_fd == 0) begin
            $display("FAIL: could not open trace output");
            $fatal(1);
        end
        $fdisplay(commit_fd, "idx,pc,instr,rd,wdata");
        $fdisplay(trap_fd, "event,pc,value");
        commit_count = 0;
        watchdog = 0;
        injected_irq = 1'b0;
        saw_irq_entry = 1'b0;
        saw_mepc = 1'b0;
        saw_mcause = 1'b0;
        saw_mstatus = 1'b0;
        saw_resume = 1'b0;
        stored_mepc = 32'h0;
        stored_mcause = 32'h0;
        stored_mstatus = 32'h0;
    end

    always @(negedge clk) begin
        if (resetn && !injected_irq &&
            dbg_pc == IRQ_TARGET_PC && dbg_instr == IRQ_TARGET_EXPANDED) begin
            irq_external_pulse <= 1'b1;
            injected_irq <= 1'b1;
            $display("[%0t ns] inject IRQ on 16-bit target pc=%08x instr=%08x",
                     $time, dbg_pc, dbg_instr);
        end else begin
            irq_external_pulse <= 1'b0;
        end
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > 500) begin
            $display("FAIL: watchdog timeout");
            $fatal(1);
        end

        if (dut.wb_take_irq) begin
            saw_irq_entry <= 1'b1;
            $fdisplay(trap_fd, "irq_entry,%08x,%08x", dut.ex_wb_pc_r, dut.wb_trap_pc_for_mepc);
            if (dut.wb_trap_pc_for_mepc !== EXPECTED_MEPC) begin
                $display("FAIL: trap pc=%08x expected=%08x", dut.wb_trap_pc_for_mepc, EXPECTED_MEPC);
                $fatal(1);
            end
        end

        if (dut.wb_trap_exit) begin
            $fdisplay(trap_fd, "mret,%08x,%08x", dut.ex_wb_pc_r, dut.mepc_o);
        end

        if (dut.wb_instr_retired && !dut.ex_wb_illegal_r && !saw_irq_entry) begin
            /* verilator lint_off BLKSEQ */
            commit_instr = instr_at_pc(dut.ex_wb_pc_r);
            /* verilator lint_on BLKSEQ */
            $fdisplay(commit_fd, "%0d,%08x,%08x,%0d,%08x",
                      commit_count,
                      dut.ex_wb_pc_r,
                      (commit_instr[1:0] != 2'b11) ? {16'h0, commit_instr[15:0]} : commit_instr,
                      (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_idx : 5'd0,
                      (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_data : 32'h0);
            commit_count <= commit_count + 1;
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            if (d_mem_addr == 32'h1000_0000) begin
                saw_mepc <= 1'b1;
                stored_mepc <= d_mem_wdata;
                $fdisplay(trap_fd, "mepc,%08x,%08x", dbg_pc, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_0004) begin
                saw_mcause <= 1'b1;
                stored_mcause <= d_mem_wdata;
                $fdisplay(trap_fd, "mcause,%08x,%08x", dbg_pc, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_0008) begin
                saw_mstatus <= 1'b1;
                stored_mstatus <= d_mem_wdata;
                $fdisplay(trap_fd, "mstatus,%08x,%08x", dbg_pc, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_000c) begin
                saw_resume <= 1'b1;
                $fdisplay(trap_fd, "resume,%08x,%08x", dbg_pc, d_mem_wdata);
                if (!injected_irq || !saw_irq_entry || !saw_mepc || !saw_mcause ||
                    !saw_mstatus) begin
                    $display("FAIL: resume before complete trap/IRQ event");
                    $fatal(1);
                end
                if (stored_mepc !== EXPECTED_MEPC ||
                    stored_mcause !== EXPECTED_MCAUSE ||
                    stored_mstatus !== EXPECTED_MSTATUS_IN_HANDLER ||
                    d_mem_wdata !== 32'h0000_600d) begin
                    $display("FAIL: bad CSR/resume values mepc=%08x mcause=%08x mstatus=%08x resume=%08x",
                             stored_mepc, stored_mcause, stored_mstatus, d_mem_wdata);
                    $fatal(1);
                end
                $fclose(commit_fd);
                $fclose(trap_fd);
                $display("PASS: trap/IRQ lockstep trace captured prefix commits and CSR events");
                $finish;
            end
        end

        if (trap && !saw_resume) begin
            $display("FAIL: illegal trap pin asserted");
            $fatal(1);
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, clk, resetn, irq_external_pulse, trap, commit_count,
                     injected_irq, saw_irq_entry, saw_mepc, saw_mcause,
                     saw_mstatus, saw_resume, stored_mepc, stored_mcause,
                     stored_mstatus, i_mem_addr, i_mem_en, i_mem_rdata,
                     d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb,
                     dbg_pc, dbg_instr, dbg_state);
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        repeat (260) @(posedge clk);
        $display("FAIL: timeout before trap/IRQ lockstep completed");
        $fatal(1);
    end
endmodule
