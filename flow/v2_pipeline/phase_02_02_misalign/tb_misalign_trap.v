`timescale 1ns / 1ns

module tb_misalign_trap;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    wire        trap;
    wire        ibus_req;
    wire [31:0] ibus_addr;
    wire        ibus_ready = 1'b1;
    reg  [31:0] ibus_rdata;
    wire        dbus_req;
    wire [31:0] dbus_addr;
    wire        dbus_we;
    wire [ 3:0] dbus_wstrb;
    wire [31:0] dbus_wdata;
    wire        dbus_ready = 1'b1;
    reg  [31:0] dbus_rdata;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;

    localparam MEM_SIZE = 4096;
    localparam MMIO_BASE = 32'h1000_1000;
    localparam MCAUSE_LOAD = 32'h0000_0004;
    localparam MCAUSE_STORE = 32'h0000_0006;

    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_word_idx = ibus_addr[13:2];
    wire [11:0] d_word_idx = dbus_addr[13:2];
    wire        d_is_mmio = dbus_addr[28];
    wire        dbus_xfer = dbus_req & dbus_ready;

    cpu_m1_top dut (
        .clk                (clk),
        .resetn             (resetn),
        .trap               (trap),
        .ibus_req           (ibus_req),
        .ibus_addr          (ibus_addr),
        .ibus_ready         (ibus_ready),
        .ibus_rdata         (ibus_rdata),
        .dbus_req           (dbus_req),
        .dbus_addr          (dbus_addr),
        .dbus_we            (dbus_we),
        .dbus_wstrb         (dbus_wstrb),
        .dbus_wdata         (dbus_wdata),
        .dbus_ready         (dbus_ready),
        .dbus_rdata         (dbus_rdata),
        .irq_external_pulse (1'b0),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy_halted),
        .debug_mode         (dbg_dummy_mode),
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
        if (ibus_req) ibus_rdata <= memory[i_word_idx];

        if (dbus_req) begin
            dbus_rdata <= memory[d_word_idx];
            if (dbus_we && !d_is_mmio) begin
                if (dbus_wstrb[0]) memory[d_word_idx][ 7: 0] <= dbus_wdata[ 7: 0];
                if (dbus_wstrb[1]) memory[d_word_idx][15: 8] <= dbus_wdata[15: 8];
                if (dbus_wstrb[2]) memory[d_word_idx][23:16] <= dbus_wdata[23:16];
                if (dbus_wstrb[3]) memory[d_word_idx][31:24] <= dbus_wdata[31:24];
            end
        end
    end

    integer events_fd;
    integer trap_count;
    integer marker_count;
    integer bad_misaligned_bus_count;
    reg [31:0] first_misaligned_bus_addr;
    reg saw_aligned_marker;
    reg saw_done_marker;
    reg [31:0] expected_addr;
    reg [31:0] expected_cause;

    initial begin
        events_fd = $fopen("misalign_events.csv", "w");
        if (events_fd == 0) begin
            $display("FAIL: could not open misalign_events.csv");
            $fatal(1);
        end
        $fdisplay(events_fd, "idx,kind,pc,mcause,mtval");
        trap_count = 0;
        marker_count = 0;
        bad_misaligned_bus_count = 0;
        first_misaligned_bus_addr = 32'h0;
        saw_aligned_marker = 1'b0;
        saw_done_marker = 1'b0;
    end

    always @* begin
        expected_addr = dut.u_core.ex_wb_alu_result_r;
        expected_cause = dut.u_core.ex_wb_is_misaligned_store_r ? MCAUSE_STORE : MCAUSE_LOAD;
    end

    always @(posedge clk) begin
        if (dbus_xfer && !d_is_mmio && dbus_addr[1:0] != 2'b00) begin
            bad_misaligned_bus_count <= bad_misaligned_bus_count + 1;
            first_misaligned_bus_addr <= dbus_addr;
            $display("FAIL: misaligned DBUS request addr=%08x wstrb=%x", dbus_addr, dbus_wstrb);
            $fatal(1);
        end

        if (dut.u_core.wb_take_data_trap && !dut.u_core.mem_stall) begin
            if (expected_addr[1:0] == 2'b00) begin
                $display("FAIL: trap on aligned address mtval=%08x", expected_addr);
                $fatal(1);
            end
            if (dut.u_core.wb_trap_cause !== expected_cause) begin
                $display("FAIL: bad mcause=%08x expected=%08x",
                         dut.u_core.wb_trap_cause, expected_cause);
                $fatal(1);
            end
            if (dut.u_core.wb_trap_mtval !== expected_addr) begin
                $display("FAIL: bad mtval=%08x expected=%08x",
                         dut.u_core.wb_trap_mtval, expected_addr);
                $fatal(1);
            end
            $fdisplay(events_fd, "%0d,%s,%08x,%08x,%08x",
                      trap_count,
                      dut.u_core.ex_wb_is_misaligned_store_r ? "store" : "load",
                      dut.u_core.ex_wb_pc_r,
                      dut.u_core.wb_trap_cause,
                      dut.u_core.wb_trap_mtval);
            $display("[%0t ns] MISALIGN idx=%0d kind=%s pc=%08x mcause=%08x mtval=%08x",
                     $time,
                     trap_count,
                     dut.u_core.ex_wb_is_misaligned_store_r ? "store" : "load",
                     dut.u_core.ex_wb_pc_r,
                     dut.u_core.wb_trap_cause,
                     dut.u_core.wb_trap_mtval);
            trap_count <= trap_count + 1;
        end

        if (dbus_xfer && d_is_mmio && dbus_we) begin
            marker_count <= marker_count + 1;
            if (dbus_addr == MMIO_BASE && dbus_wdata == 32'h0000_0011 && !saw_aligned_marker) begin
                saw_aligned_marker <= 1'b1;
                if (trap_count != 0) begin
                    $display("FAIL: aligned byte marker occurred after trap_count=%0d", trap_count);
                    $fatal(1);
                end
                $display("[%0t ns] MARK aligned_byte_no_trap value=%08x", $time, dbus_wdata);
            end
            if (dbus_addr == MMIO_BASE && dbus_wdata == 32'h0000_0044) begin
                saw_done_marker <= 1'b1;
                $display("[%0t ns] MARK done value=%08x", $time, dbus_wdata);
            end
        end

        if (trap && !saw_done_marker && trap_count == 3) begin
            saw_done_marker <= 1'b1;
            $display("[%0t ns] MARK done terminal ebreak after expected traps", $time);
        end else if (trap && !saw_done_marker) begin
            $display("FAIL: illegal trap pin asserted");
            $fatal(1);
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, clk, resetn, trap, trap_count, marker_count,
                     ibus_req, ibus_addr, ibus_rdata,
                     dbus_req, dbus_addr, dbus_we, dbus_wstrb, dbus_wdata, dbus_rdata,
                     dbg_pc, dbg_instr, dbg_state);

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        wait (saw_done_marker);
        repeat (2) @(posedge clk);

        if (!saw_aligned_marker) begin
            $display("FAIL: aligned byte no-trap marker not observed");
            $fatal(1);
        end
        if (trap_count != 3) begin
            $display("FAIL: trap_count=%0d expected=3", trap_count);
            $fatal(1);
        end
        if (!saw_done_marker) begin
            $display("FAIL: done marker not observed");
            $fatal(1);
        end
        if (bad_misaligned_bus_count != 0) begin
            $display("FAIL: bad_misaligned_bus_count=%0d first_addr=%08x",
                     bad_misaligned_bus_count, first_misaligned_bus_addr);
            $fatal(1);
        end

        $fclose(events_fd);
        $display("PASS: misalign trap observed 3 precise traps, aligned lb/sb did not trap, no misaligned DBUS request");
        $finish;
    end

    initial begin
        #20_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
