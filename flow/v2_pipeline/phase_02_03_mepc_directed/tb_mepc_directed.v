`timescale 1ns / 1ns

module tb_mepc_directed;
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

    localparam MEM_SIZE = 4096;
    localparam MMIO_BASE = 32'h1000_0000;
    localparam CSR_MASK_ADDR = 32'h1000_0200;
    localparam DONE_ADDR = 32'h1000_0100;
    localparam EVENT_COUNT = 5;

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
        /* verilator lint_off PINCONNECTEMPTY */
        .rvfi_valid(), .rvfi_pc(), .rvfi_trap(), .rvfi_trap_cause(), .rvfi_intr(),
        .rvfi_rd_addr(), .rvfi_rd_wdata(),
        .rvvi_v_valid(), .rvvi_v_vd(), .rvvi_v_wdata(), .rvvi_vl(), .rvvi_vtype(),
        /* verilator lint_on PINCONNECTEMPTY */
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

    reg observe_only;
    integer trap_idx;
    integer store_events;
    reg saw_done;
    reg saw_csr_mask;
    reg [31:0] csr_mask_value;
    reg [31:0] trap_pc_observed [0:EVENT_COUNT-1];
    reg [31:0] trap_pc_expected [0:EVENT_COUNT-1];
    reg [31:0] mepc_readback [0:EVENT_COUNT-1];
    reg [31:0] mcause_readback [0:EVENT_COUNT-1];
    reg [31:0] mtval_readback [0:EVENT_COUNT-1];
    wire [2:0] mmio_event_idx = d_mem_addr[6:4];

    initial begin
        observe_only = $test$plusargs("observe_only");
        trap_idx = 0;
        store_events = 0;
        saw_done = 1'b0;
        saw_csr_mask = 1'b0;
        csr_mask_value = 32'h0;
        trap_pc_expected[0] = 32'h0000_0080;
        trap_pc_expected[1] = 32'h0000_008e;
        trap_pc_expected[2] = 32'h0000_0098;
        trap_pc_expected[3] = 32'h0000_00a0;
        trap_pc_expected[4] = 32'h0000_00a8;
    end

    always @(posedge clk) begin
        if ((dut.wb_take_sync_trap || dut.wb_take_data_trap) && !dut.mem_stall) begin
            if (trap_idx >= EVENT_COUNT) begin
                $display("FAIL: too many traps");
                $fatal(1);
            end
            trap_pc_observed[trap_idx] <= dut.wb_trap_pc_for_mepc;
            $display("[%0t ns] TRAP idx=%0d ex_wb_pc=%08x trap_pc_for_mepc=%08x expected=%08x cause=%08x mtval=%08x",
                     $time, trap_idx, dut.ex_wb_pc_r, dut.wb_trap_pc_for_mepc,
                     trap_pc_expected[trap_idx], dut.wb_trap_cause, dut.wb_trap_mtval);
            if (!observe_only && dut.wb_trap_pc_for_mepc !== trap_pc_expected[trap_idx]) begin
                $display("FAIL: trap_pc_for_mepc idx=%0d observed=%08x expected=%08x",
                         trap_idx, dut.wb_trap_pc_for_mepc, trap_pc_expected[trap_idx]);
                $fatal(1);
            end
            trap_idx <= trap_idx + 1;
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            if (d_mem_addr == CSR_MASK_ADDR) begin
                saw_csr_mask <= 1'b1;
                csr_mask_value <= d_mem_wdata;
                $display("[%0t ns] CSR mepc write/read observed=%08x expected=00000082",
                         $time, d_mem_wdata);
                if (!observe_only && d_mem_wdata !== 32'h0000_0082) begin
                    $display("FAIL: mepc CSR mask observed=%08x expected=00000082", d_mem_wdata);
                    $fatal(1);
                end
            end else if (d_mem_addr == DONE_ADDR) begin
                saw_done <= 1'b1;
                $display("[%0t ns] DONE marker=%08x", $time, d_mem_wdata);
            end else if (d_mem_addr >= MMIO_BASE && d_mem_addr < (MMIO_BASE + EVENT_COUNT * 16)) begin
                store_events <= store_events + 1;
                case (d_mem_addr[5:0] & 6'h0f)
                    6'h0: mepc_readback[mmio_event_idx] <= d_mem_wdata;
                    6'h4: mcause_readback[mmio_event_idx] <= d_mem_wdata;
                    6'h8: mtval_readback[mmio_event_idx] <= d_mem_wdata;
                    default: ;
                endcase
                $display("[%0t ns] STORE event=%0d field=%0d value=%08x",
                         $time, mmio_event_idx, d_mem_addr[3:2], d_mem_wdata);
            end
        end
    end

    integer i;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, clk, resetn, trap, trap_idx, saw_csr_mask, csr_mask_value, saw_done,
                     i_mem_addr, i_mem_en, i_mem_rdata,
                     d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb,
                     dbg_pc, dbg_instr, dbg_state);

        repeat (6) @(posedge clk);
        resetn = 1'b1;
        wait (saw_done);
        repeat (4) @(posedge clk);

        if (!saw_csr_mask) begin
            $display("FAIL: CSR mepc mask readback not observed");
            $fatal(1);
        end
        if (trap_idx != EVENT_COUNT) begin
            $display("FAIL: trap_idx=%0d expected=%0d", trap_idx, EVENT_COUNT);
            $fatal(1);
        end

        for (i = 0; i < EVENT_COUNT; i = i + 1) begin
            $display("RESULT idx=%0d observed_mepc=%08x expected_mepc=%08x handler_mepc=%08x mcause=%08x mtval=%08x",
                     i, trap_pc_observed[i], trap_pc_expected[i], mepc_readback[i],
                     mcause_readback[i], mtval_readback[i]);
            if (!observe_only && mepc_readback[i] !== trap_pc_expected[i]) begin
                $display("FAIL: handler mepc idx=%0d observed=%08x expected=%08x",
                         i, mepc_readback[i], trap_pc_expected[i]);
                $fatal(1);
            end
        end

        $display("PASS: directed mepc CSR mask and synchronous trap precision completed");
        $finish;
    end

    initial begin
        #50_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
