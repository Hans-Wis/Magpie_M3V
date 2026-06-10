`timescale 1ns / 1ns

module tb_irq_collision;
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
    localparam FIRST_MEPC = 32'h0000_0082;
    localparam EXPECTED_MCAUSE = 32'h8000_000b;

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

    integer trace_fd;
    integer watchdog;
    integer irq_entry_count;
    integer handler_store_count;
    reg injected_initial_irq;
    reg injected_samecycle_pulse;
    reg injected_delayed_pulse;
    reg request_delayed_pulse;
    reg saw_resume_marker;
    reg [31:0] first_mepc;
    reg [31:0] second_mepc;
    reg [31:0] last_mcause;

    initial begin
        trace_fd = $fopen("irq_collision.trace", "w");
        if (trace_fd == 0) begin
            $display("FAIL: could not open irq_collision.trace");
            $fatal(1);
        end
        $fdisplay(trace_fd, "event,idx,pc,value");
        watchdog = 0;
        irq_entry_count = 0;
        handler_store_count = 0;
        injected_initial_irq = 1'b0;
        injected_samecycle_pulse = 1'b0;
        injected_delayed_pulse = 1'b0;
        request_delayed_pulse = 1'b0;
        saw_resume_marker = 1'b0;
        first_mepc = 32'h0;
        second_mepc = 32'h0;
        last_mcause = 32'h0;
    end

    always @(negedge clk) begin
        if (!resetn) begin
            irq_external_pulse <= 1'b0;
        end else if (!injected_initial_irq &&
                     dbg_pc == IRQ_TARGET_PC && dbg_instr == IRQ_TARGET_EXPANDED) begin
            irq_external_pulse <= 1'b1;
            injected_initial_irq <= 1'b1;
            $fdisplay(trace_fd, "inject_initial,0,%08x,%08x", dbg_pc, dbg_instr);
        end else if (!injected_samecycle_pulse && dut.wb_take_irq) begin
            irq_external_pulse <= 1'b1;
            injected_samecycle_pulse <= 1'b1;
            $fdisplay(trace_fd, "inject_samecycle,%0d,%08x,%08x",
                      irq_entry_count + 1, dut.ex_wb_pc_r, dut.wb_trap_pc_for_mepc);
        end else if (request_delayed_pulse && !injected_delayed_pulse) begin
            irq_external_pulse <= 1'b1;
            injected_delayed_pulse <= 1'b1;
            $fdisplay(trace_fd, "inject_delayed,1,%08x,%08x", dbg_pc, dbg_instr);
        end else begin
            irq_external_pulse <= 1'b0;
        end
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > 900) begin
            $display("FAIL: watchdog timeout irq_count=%0d stores=%0d resume=%0d",
                     irq_entry_count, handler_store_count, saw_resume_marker);
            $fatal(1);
        end

        if (dut.wb_take_irq) begin
            irq_entry_count <= irq_entry_count + 1;
            $fdisplay(trace_fd, "irq_entry,%0d,%08x,%08x",
                      irq_entry_count + 1, dut.ex_wb_pc_r, dut.wb_trap_pc_for_mepc);
            if (irq_entry_count == 0) begin
                first_mepc <= dut.wb_trap_pc_for_mepc;
                request_delayed_pulse <= 1'b1;
                if (dut.wb_trap_pc_for_mepc !== FIRST_MEPC) begin
                    $display("FAIL: first mepc=%08x expected=%08x",
                             dut.wb_trap_pc_for_mepc, FIRST_MEPC);
                    $fatal(1);
                end
            end else if (irq_entry_count == 1) begin
                second_mepc <= dut.wb_trap_pc_for_mepc;
                if (dut.wb_trap_pc_for_mepc <= FIRST_MEPC) begin
                    $display("FAIL: second mepc did not advance: %08x",
                             dut.wb_trap_pc_for_mepc);
                    $fatal(1);
                end
            end else begin
                $display("FAIL: unexpected extra IRQ entry count=%0d", irq_entry_count + 1);
                $fatal(1);
            end
        end

        if (dut.wb_trap_exit) begin
            $fdisplay(trace_fd, "mret,%0d,%08x,%08x",
                      irq_entry_count, dut.ex_wb_pc_r, dut.mepc_o);
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            if (d_mem_addr == 32'h1000_0000) begin
                handler_store_count <= handler_store_count + 1;
                $fdisplay(trace_fd, "mepc_store,%0d,%08x,%08x",
                          handler_store_count + 1, dbg_pc, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_0004) begin
                last_mcause <= d_mem_wdata;
                $fdisplay(trace_fd, "mcause_store,%0d,%08x,%08x",
                          handler_store_count, dbg_pc, d_mem_wdata);
                if (d_mem_wdata !== EXPECTED_MCAUSE) begin
                    $display("FAIL: mcause=%08x expected=%08x", d_mem_wdata, EXPECTED_MCAUSE);
                    $fatal(1);
                end
            end else if (d_mem_addr == 32'h1000_0008) begin
                $fdisplay(trace_fd, "mstatus_store,%0d,%08x,%08x",
                          handler_store_count, dbg_pc, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_0010) begin
                saw_resume_marker <= 1'b1;
                $fdisplay(trace_fd, "resume,%0d,%08x,%08x",
                          irq_entry_count, dbg_pc, d_mem_wdata);
                if (!injected_initial_irq || !injected_samecycle_pulse ||
                    !injected_delayed_pulse) begin
                    $display("FAIL: resume before all planned IRQ pulses fired");
                    $fatal(1);
                end
                if (irq_entry_count !== 2 || handler_store_count !== 2 ||
                    first_mepc !== FIRST_MEPC || second_mepc <= FIRST_MEPC ||
                    last_mcause !== EXPECTED_MCAUSE ||
                    d_mem_wdata !== 32'h0000_600d) begin
                    $display("FAIL: bad collision result irq_count=%0d stores=%0d first=%08x second=%08x mcause=%08x resume=%08x",
                             irq_entry_count, handler_store_count, first_mepc,
                             second_mepc, last_mcause, d_mem_wdata);
                    $fatal(1);
                end
                $fclose(trace_fd);
                $display("PASS: IRQ collision contract validated");
                $finish;
            end
        end

        if (trap && !saw_resume_marker) begin
            $display("FAIL: illegal trap pin asserted");
            $fatal(1);
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, clk, resetn, irq_external_pulse, trap, irq_entry_count,
                     handler_store_count, injected_initial_irq,
                     injected_samecycle_pulse, injected_delayed_pulse,
                     request_delayed_pulse, first_mepc, second_mepc,
                     last_mcause, saw_resume_marker, i_mem_addr, i_mem_en,
                     i_mem_rdata, d_mem_valid, d_mem_addr, d_mem_wdata,
                     d_mem_wstrb, dbg_pc, dbg_instr, dbg_state);
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        repeat (600) @(posedge clk);
        $display("FAIL: timeout before IRQ collision contract completed");
        $fatal(1);
    end
endmodule
