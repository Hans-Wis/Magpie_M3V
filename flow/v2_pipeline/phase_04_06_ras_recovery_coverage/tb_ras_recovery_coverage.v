`timescale 1ns / 1ns

module tb_ras_recovery_coverage;
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

    reg         ras_edge_push = 1'b0;
    reg  [31:0] ras_edge_push_val = 32'h0;
    reg         ras_edge_pop = 1'b0;
    wire [31:0] ras_edge_top;

    ras u_ras_edge (
        .clk      (clk),
        .resetn   (resetn),
        .ras_top  (ras_edge_top),
        .push     (ras_edge_push),
        .push_val (ras_edge_push_val),
        .pop      (ras_edge_pop)
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

    reg saw_actual_return;
    reg saw_ras_mispredict;
    reg saw_redirect;
    reg ras_edge_done;

    initial begin
        saw_actual_return = 1'b0;
        saw_ras_mispredict = 1'b0;
        saw_redirect = 1'b0;
        ras_edge_done = 1'b0;
    end

    task check_store;
        input [31:0] got;
        input [31:0] exp;
        input [255:0] label;
        begin
            if (got !== exp) begin
                $display("FAIL: %0s got=%08x expected=%08x", label, got, exp);
                $fatal(1);
            end
        end
    endtask

    always @(posedge clk) begin
        if (trap) begin
            $display("FAIL: illegal trap pin asserted pc=%08x instr=%08x state=%0d",
                     dbg_pc, dbg_instr, dbg_state);
            $fatal(1);
        end

        if (dut.mem_ras_mispredict) begin
            saw_ras_mispredict <= 1'b1;
            $display("[%0t ns] saw mem_ras_mispredict pred=%08x actual=%08x",
                     $time, dut.ex_mem_pred_ras_target_r, dut.mem_ras_actual_target);
        end

        if (dut.pc_redirect && dut.mem_ras_mispredict) begin
            saw_redirect <= 1'b1;
            $display("[%0t ns] saw RAS recovery redirect target=%08x",
                     $time, dut.redirect_target);
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            $display("[%0t ns] mmio[%08x] <= %08x", $time, mmio_off, d_mem_wdata);
            case (mmio_off)
                32'h00: begin
                    check_store(d_mem_wdata, 32'h00000406, "actual return marker");
                    saw_actual_return <= 1'b1;
                end
                32'h04: begin
                    $display("FAIL: wrong-path predicted return committed data=%08x", d_mem_wdata);
                    $fatal(1);
                end
                default: begin
                    $display("FAIL: unexpected MMIO store offset=%08x data=%08x", mmio_off, d_mem_wdata);
                    $fatal(1);
                end
            endcase
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        if ($test$plusargs("full_vcd")) begin
            $dumpvars(0, tb_ras_recovery_coverage);
        end else begin
            $dumpvars(0, clk, resetn, trap);
            $dumpvars(0, i_mem_addr, i_mem_en, i_mem_rdata);
            $dumpvars(0, d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb);
            $dumpvars(0, dbg_pc, dbg_instr, dbg_state);
            $dumpvars(0, saw_actual_return, saw_ras_mispredict, saw_redirect, ras_edge_done);
            $dumpvars(0, dut.ex_mem_valid_r, dut.ex_mem_pred_ras_r,
                         dut.ex_mem_pred_ras_target_r, dut.mem_ras_actual_target,
                         dut.mem_ras_mispredict, dut.pc_redirect, dut.redirect_target,
                         dut.ras_push, dut.ras_push_val, dut.ras_pop, dut.ras_top,
                         dut.u_ras.ptr);
            $dumpvars(0, ras_edge_push, ras_edge_push_val, ras_edge_pop,
                         ras_edge_top, u_ras_edge.ptr);
        end
        $dumpoff;

        repeat (6) @(posedge clk);
        resetn = 1'b1;

        $dumpon;
        fork
            begin : core_run
                repeat (260) @(posedge clk);
            end
            begin : ras_edge_run
                @(posedge clk);
                ras_edge_push_val = 32'h1111_1111;
                ras_edge_push = 1'b1;
                ras_edge_pop = 1'b1;
                @(posedge clk);
                ras_edge_push = 1'b0;
                ras_edge_pop = 1'b0;
                @(posedge clk);
                if (u_ras_edge.ptr !== 3'd0 || u_ras_edge.stack[0] !== 32'h1111_1111) begin
                    $display("FAIL: empty push+pop edge ptr=%0d stack0=%08x",
                             u_ras_edge.ptr, u_ras_edge.stack[0]);
                    $fatal(1);
                end

                ras_edge_push_val = 32'h2222_2222;
                ras_edge_push = 1'b1;
                @(posedge clk);
                ras_edge_push = 1'b0;
                @(posedge clk);
                if (u_ras_edge.ptr !== 3'd1 || ras_edge_top !== 32'h2222_2222) begin
                    $display("FAIL: push setup edge ptr=%0d top=%08x",
                             u_ras_edge.ptr, ras_edge_top);
                    $fatal(1);
                end

                ras_edge_push_val = 32'h3333_3333;
                ras_edge_push = 1'b1;
                ras_edge_pop = 1'b1;
                @(posedge clk);
                ras_edge_push = 1'b0;
                ras_edge_pop = 1'b0;
                @(posedge clk);
                if (u_ras_edge.ptr !== 3'd1 || ras_edge_top !== 32'h3333_3333) begin
                    $display("FAIL: non-empty push+pop replace edge ptr=%0d top=%08x",
                             u_ras_edge.ptr, ras_edge_top);
                    $fatal(1);
                end
                ras_edge_done = 1'b1;
                $display("[%0t ns] RAS unit pointer-edge checks passed", $time);
            end
        join
        $dumpoff;

        if (!saw_ras_mispredict || !saw_redirect || !saw_actual_return || !ras_edge_done) begin
            $display("FAIL: missing RAS evidence mispredict=%0b redirect=%0b actual=%0b edge=%0b",
                     saw_ras_mispredict, saw_redirect, saw_actual_return, ras_edge_done);
            $fatal(1);
        end

        $display("PASS: directed RAS recovery and pointer-edge coverage completed");
        $finish;
    end

    initial begin
        #30_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
