`timescale 1ns / 1ns

module tb_illegal_munit_coverage;
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
    localparam ILLEGAL_LUI_X0      = 32'h0001_6005;
    localparam ILLEGAL_SLLI_SH5    = 32'h0001_1406;
    localparam ILLEGAL_Q2_DEFAULT  = 32'h0001_2002;

    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_word_idx = i_mem_addr[13:2];
    wire [11:0] d_word_idx = d_mem_addr[13:2];
    wire        d_is_mmio = d_mem_addr[28];
    wire [31:0] mmio_off = d_mem_addr - 32'h1000_0000;

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

    integer watchdog;
    integer illegal_case;
    integer pending_trap_case;
    reg saw_munit_done;
    reg saw_illegal_lui;
    reg saw_illegal_slli;
    reg saw_illegal_q2;

    initial begin
        watchdog = 0;
        illegal_case = 0;
        pending_trap_case = 0;
        saw_munit_done = 1'b0;
        saw_illegal_lui = 1'b0;
        saw_illegal_slli = 1'b0;
        saw_illegal_q2 = 1'b0;
    end

    task start_illegal_case;
        input integer next_case;
        input [31:0] word0;
        begin
            illegal_case = next_case;
            resetn = 1'b0;
            memory[0] = word0;
            i_mem_rdata = 32'h0;
            d_mem_rdata = 32'h0;
            repeat (4) @(posedge clk);
            resetn = 1'b1;
            $display("[%0t ns] start illegal compressed case %0d word0=%08x",
                     $time, next_case, word0);
        end
    endtask

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > 2400) begin
            $display("FAIL: watchdog timeout");
            $fatal(1);
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            $display("[%0t ns] mmio[%08x] <= %08x pc=%08x instr=%08x",
                     $time, mmio_off, d_mem_wdata, dbg_pc, dbg_instr);
            if (mmio_off == 32'h24) begin
                if (d_mem_wdata !== 32'h00000a0a) begin
                    $display("FAIL: bad M-unit marker %08x", d_mem_wdata);
                    $fatal(1);
                end
                saw_munit_done <= 1'b1;
            end else if (mmio_off == 32'h28) begin
                $display("FAIL: M-unit firmware fail marker observed");
                $fatal(1);
            end
        end
    end

    always @(posedge clk) begin
        if (resetn && illegal_case != 0 && dut.ex_wb_valid_r && dut.ex_wb_illegal_r) begin
            if (!dut.cdec_illegal) begin
                $display("FAIL: ex_wb_illegal without cdec_illegal in case %0d", illegal_case);
                $fatal(1);
            end
            pending_trap_case <= illegal_case;
            $display("[%0t ns] illegal compressed case %0d reached WB illegal pc=%08x instr=%08x cinstr=%04x",
                     $time, illegal_case, dut.ex_wb_pc_r, dbg_instr, dut.cinstr);
            illegal_case <= 0;
        end

        if (resetn && pending_trap_case != 0 && trap) begin
            $display("[%0t ns] illegal compressed case %0d asserted terminal trap",
                     $time, pending_trap_case);
            if (pending_trap_case == 1) saw_illegal_lui <= 1'b1;
            if (pending_trap_case == 2) saw_illegal_slli <= 1'b1;
            if (pending_trap_case == 3) saw_illegal_q2 <= 1'b1;
            pending_trap_case <= 0;
            resetn <= 1'b0;
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        if ($test$plusargs("full_vcd")) begin
            $dumpvars(0, tb_illegal_munit_coverage);
        end else begin
            $dumpvars(0, clk, resetn, trap, illegal_case);
            $dumpvars(0, i_mem_addr, i_mem_en, i_mem_rdata);
            $dumpvars(0, d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb);
            $dumpvars(0, dbg_pc, dbg_instr, dbg_state);
            $dumpvars(0, saw_munit_done, saw_illegal_lui, saw_illegal_slli, saw_illegal_q2);
            $dumpvars(0, dut.md_started, dut.md_active_is_div, dut.md_result_valid,
                         dut.md_result_q, dut.md_done, dut.md_busy, dut.id_is_muldiv,
                         dut.id_md_is_div, dut.ex_mem_md_result_r, dut.ex_wb_md_result_r);
            $dumpvars(0, dut.cinstr, dut.cdec_expanded, dut.cdec_illegal,
                         dut.id_illegal, dut.ex_mem_illegal_r, dut.ex_wb_illegal_r,
                         dut.trap_latched);
        end
        $dumpoff;

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        $dumpon;

        wait (saw_munit_done);
        repeat (8) @(posedge clk);
        start_illegal_case(1, ILLEGAL_LUI_X0);
        wait (saw_illegal_lui);
        repeat (6) @(posedge clk);
        start_illegal_case(2, ILLEGAL_SLLI_SH5);
        wait (saw_illegal_slli);
        repeat (6) @(posedge clk);
        start_illegal_case(3, ILLEGAL_Q2_DEFAULT);
        wait (saw_illegal_q2);

        repeat (8) @(posedge clk);
        $dumpoff;
        $display("PASS: illegal compressed trap and M-unit coverage completed");
        $finish;
    end
endmodule
