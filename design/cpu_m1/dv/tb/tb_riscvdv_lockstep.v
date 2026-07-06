`timescale 1ns / 1ns

module tb_riscvdv_lockstep;
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

    localparam MEM_WORDS = 65536;
    localparam ELF_BASE  = 32'h00001000;
    reg [31:0] memory [0:MEM_WORDS-1];

    reg [1023:0] firmware_hex;
    reg [1023:0] trace_path;
    reg [1023:0] trap_trace_path;
    integer max_cycles;
    integer debug_branch;
    integer debug_munit;
    reg [31:0] stop_addr;

    wire [31:0] i_mem_offset = (i_mem_addr >= ELF_BASE) ? (i_mem_addr - ELF_BASE) : i_mem_addr;
    wire [15:0] i_word_idx = i_mem_offset[17:2];
    wire [31:0] d_mem_offset = (d_mem_addr >= ELF_BASE) ? (d_mem_addr - ELF_BASE) : d_mem_addr;
    wire [15:0] d_word_idx = d_mem_offset[17:2];

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

    integer trace_fd;
    integer trap_trace_fd;
    integer commit_count;
    integer watchdog;
    integer i;
    reg [31:0] commit_instr;

    function [31:0] instr_at_pc;
        input [31:0] pc;
        reg [31:0] offset;
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            offset = (pc >= ELF_BASE) ? (pc - ELF_BASE) : pc;
            word0 = memory[offset[17:2]];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = memory[offset[17:2] + 16'd1];
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
        if (!$value$plusargs("TRAP_TRACE=%s", trap_trace_path)) trap_trace_path = "dut_trap.trace";
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 2000000;
        if (!$value$plusargs("DEBUG_BRANCH=%d", debug_branch)) debug_branch = 0;
        if (!$value$plusargs("DEBUG_MUNIT=%d", debug_munit)) debug_munit = 0;
        if (!$value$plusargs("STOP_ADDR=%h", stop_addr)) stop_addr = 32'hffff_ffff;

        for (i = 0; i < MEM_WORDS; i = i + 1) memory[i] = 32'h0;
        $readmemh(firmware_hex, memory);

        trace_fd = $fopen(trace_path, "w");
        if (trace_fd == 0) begin
            $display("FAIL: could not open trace %0s", trace_path);
            $fatal(1);
        end
        $fdisplay(trace_fd, "idx,pc,instr,rd,wdata,csr");
        trap_trace_fd = $fopen(trap_trace_path, "w");
        if (trap_trace_fd == 0) begin
            $display("FAIL: could not open trap trace %0s", trap_trace_path);
            $fatal(1);
        end
        $fdisplay(trap_trace_fd, "idx,event,pc,instr,mepc,mcause,mtval,mstatus");
        commit_count = 0;
        watchdog = 0;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > max_cycles) begin
            $display("FAIL: watchdog timeout commits=%0d pc=%08x", commit_count, dbg_pc);
            $fatal(1);
        end

        if (d_mem_valid && |d_mem_wstrb && d_mem_addr == stop_addr && d_mem_wdata != 32'h0) begin
            $display("[%0t ns] stop on tohost=%08x commits=%0d", $time, d_mem_wdata, commit_count);
            $fclose(trace_fd);
            $fclose(trap_trace_fd);
            $display("PASS: riscv-dv DUT trace wrote %0d commits before tohost", commit_count);
            $finish;
        end else if (dut.wb_instr_retired && !dut.ex_wb_illegal_r) begin
            /* verilator lint_off BLKSEQ */
            commit_instr = instr_at_pc(dut.ex_wb_pc_r);
            /* verilator lint_on BLKSEQ */
            $fdisplay(trace_fd, "%0d,%08x,%08x,%0d,%08x,%03x",
                      commit_count,
                      dut.ex_wb_pc_r,
                      (commit_instr[1:0] != 2'b11) ? {16'h0, commit_instr[15:0]} : commit_instr,
                      (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_idx : 5'd0,
                      (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_data : 32'h0,
                      ((commit_instr[6:0] == `OPC_SYSTEM) && (commit_instr[14:12] != 3'b000)) ? commit_instr[31:20] : 12'h000);
            commit_count <= commit_count + 1;
        end

        if (dut.wb_trap_enter) begin
            $fdisplay(trap_trace_fd, "%0d,enter,%08x,%08x,%08x,%08x,%08x,%08x",
                      commit_count, dut.ex_wb_pc_r, dut.ex_wb_instr_r,
                      dut.wb_trap_pc_for_mepc, dut.wb_trap_cause,
                      dut.wb_trap_mtval, dut.u_csr.mstatus_val);
        end
        if (dut.wb_trap_exit) begin
            $fdisplay(trap_trace_fd, "%0d,mret,%08x,%08x,%08x,%08x,%08x,%08x",
                      commit_count, dut.ex_wb_pc_r, dut.ex_wb_instr_r,
                      dut.u_csr.mepc_o, 32'h0, dut.u_csr.mtval_val,
                      dut.u_csr.mstatus_val);
        end

        if ((debug_branch != 0) && dut.if_ex_valid && dut.id_is_branch) begin
            $display("BRDBG cyc=%0d pc=%08x instr=%08x rs1=x%0d/%08x rs2=x%0d/%08x br_type=%0d inv=%0d cond=%0d taken=%0d pred=%0d pred_tgt=%08x ex_misp=%0d pc_redirect=%0d redir=%08x",
                     watchdog, dut.if_ex_pc, dut.if_ex_instr,
                     dut.id_rs1_idx, dut.rs1_val, dut.id_rs2_idx, dut.rs2_val,
                     dut.id_br_type, dut.id_branch_invert, dut.branch_cond,
                     dut.branch_taken, dut.if_ex_pred_taken, dut.if_ex_pred_target,
                     dut.ex_mispredict, dut.pc_redirect, dut.redirect_target);
        end
        if ((debug_branch != 0) && dut.if_ex_valid && (dut.if_ex_pc == 32'h000000f8)) begin
            $display("PCDBG cyc=%0d pc=%08x if_ex_instr=%08x id_branch=%0d next_pc=%08x i_addr=%08x i_rdata=%08x pc_redirect=%0d redir=%08x",
                     watchdog, dut.if_ex_pc, dut.if_ex_instr, dut.id_is_branch,
                     dut.next_pc_w, i_mem_addr, i_mem_rdata, dut.pc_redirect,
                     dut.redirect_target);
        end
        if ((debug_munit != 0) && (dut.md_start || dut.md_done || dut.id_advance_to_ex_mem ||
            (dut.ex_wb_valid_r && dut.ex_wb_wb_sel_r == `WB_SEL_MD))) begin
            $display("MDBUG cyc=%0d ifpc=%08x ifinstr=%08x id_md=%0d op=%0d is_div=%0d rs1=x%0d/%08x rs2=x%0d/%08x start=%0d done=%0d busy=%0d md_started=%0d active_div=%0d valid=%0d mul=%08x div=%08x mdq=%08x adv=%0d em_pc=%08x em_sel=%0d em_md=%08x wb_pc=%08x wb_sel=%0d wb_rd=x%0d wb_data=%08x stall=%0d",
                     watchdog, dut.if_ex_pc, dut.if_ex_instr, dut.id_is_muldiv,
                     dut.id_md_op, dut.id_md_is_div, dut.id_rs1_idx, dut.rs1_val,
                     dut.id_rs2_idx, dut.rs2_val, dut.md_start, dut.md_done,
                     dut.md_busy, dut.md_started, dut.md_active_is_div,
                     dut.md_result_valid, dut.mul_result, dut.div_result,
                     dut.md_result_q, dut.id_advance_to_ex_mem, dut.ex_mem_pc_r,
                     dut.ex_mem_wb_sel_r, dut.ex_mem_md_result_r, dut.ex_wb_pc_r,
                     dut.ex_wb_wb_sel_r, dut.ex_wb_rd_idx_r, dut.wb_data, dut.stall);
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
