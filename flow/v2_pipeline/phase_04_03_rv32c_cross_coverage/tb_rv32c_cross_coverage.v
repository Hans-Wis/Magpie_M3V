`timescale 1ns / 1ns

module tb_rv32c_cross_coverage;
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

    reg saw_c_call;
    reg saw_cdec_done;
    reg saw_cross_fast;
    reg saw_cross_fallback;
    reg saw_cross_assemble;
    reg saw_upcoming_cross;
    reg saw_at_cross_boundary;

    initial begin
        saw_c_call = 1'b0;
        saw_cdec_done = 1'b0;
        saw_cross_fast = 1'b0;
        saw_cross_fallback = 1'b0;
        saw_cross_assemble = 1'b0;
        saw_upcoming_cross = 1'b0;
        saw_at_cross_boundary = 1'b0;
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

        if (dut.upcoming_cross) saw_upcoming_cross <= 1'b1;
        if (dut.at_cross_boundary) saw_at_cross_boundary <= 1'b1;
        if (dut.cross_assemble) saw_cross_assemble <= 1'b1;

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            $display("[%0t ns] mmio[%08x] <= %08x pc=%08x instr=%08x",
                     $time, mmio_off, d_mem_wdata, dbg_pc, dbg_instr);
            case (mmio_off)
                32'h14: begin check_store(d_mem_wdata, 32'h606, "compressed call"); saw_c_call <= 1'b1; end
                32'h18: begin check_store(d_mem_wdata, 32'h707, "compressed decode done"); saw_cdec_done <= 1'b1; end
                32'h1c: begin check_store(d_mem_wdata, 32'h808, "cross fast"); saw_cross_fast <= 1'b1; end
                32'h20: begin check_store(d_mem_wdata, 32'h909, "cross fallback"); saw_cross_fallback <= 1'b1; end
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
            $dumpvars(0, tb_rv32c_cross_coverage);
        end else begin
            $dumpvars(0, clk, resetn, trap);
            $dumpvars(0, i_mem_addr, i_mem_en, i_mem_rdata);
            $dumpvars(0, d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb);
            $dumpvars(0, dbg_pc, dbg_instr, dbg_state);
            $dumpvars(0, saw_c_call, saw_cdec_done, saw_cross_fast, saw_cross_fallback);
            $dumpvars(0, saw_cross_assemble, saw_upcoming_cross, saw_at_cross_boundary);
            $dumpvars(0, dut.cur_half_lo, dut.cur_half_hi, dut.is_comp_lo, dut.is_comp_hi,
                         dut.cur_at_high, dut.upcoming_cross, dut.at_cross_boundary,
                         dut.cross_assemble, dut.residue, dut.is_16bit_w,
                         dut.cinstr, dut.cdec_expanded, dut.cdec_illegal,
                         dut.instr_assembled, dut.if_pc, dut.next_pc_w);
        end
        $dumpoff;

        repeat (6) @(posedge clk);
        resetn = 1'b1;

        $dumpon;
        repeat (1200) @(posedge clk);
        $dumpoff;

        if (!saw_c_call || !saw_cdec_done || !saw_cross_fast || !saw_cross_fallback ||
            !saw_cross_assemble || !saw_upcoming_cross || !saw_at_cross_boundary) begin
            $display("FAIL: missing RV32C/cross evidence call=%0b cdec=%0b fast=%0b fallback=%0b assemble=%0b upcoming=%0b atcross=%0b",
                     saw_c_call, saw_cdec_done, saw_cross_fast, saw_cross_fallback,
                     saw_cross_assemble, saw_upcoming_cross, saw_at_cross_boundary);
            $fatal(1);
        end

        $display("PASS: directed RV32C/cross-boundary coverage completed");
        $finish;
    end

    initial begin
        #80_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
