`timescale 1ns / 1ns

module tb_trap_irq;
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
    localparam IRQ_TARGET_EXPANDED = 32'h0014_0413;  // c.addi s0,1 -> addi x8,x8,1
    localparam EXPECTED_MEPC = 32'h0000_0082;
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

    reg injected_irq;
    reg saw_irq_entry;
    reg saw_handler_mepc_store;
    reg saw_handler_mcause_store;
    reg saw_mret_resume_marker;
    reg [31:0] stored_mepc;
    reg [31:0] stored_mcause;

    initial begin
        injected_irq = 1'b0;
        saw_irq_entry = 1'b0;
        saw_handler_mepc_store = 1'b0;
        saw_handler_mcause_store = 1'b0;
        saw_mret_resume_marker = 1'b0;
        stored_mepc = 32'h0;
        stored_mcause = 32'h0;
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
        if (dut.wb_take_irq) begin
            saw_irq_entry <= 1'b1;
            $display("[%0t ns] irq entry trap_pc=%08x mtvec=%08x",
                     $time, dut.wb_trap_pc_for_mepc, dut.mtvec_o);
            if (dut.wb_trap_pc_for_mepc !== EXPECTED_MEPC) begin
                $display("FAIL: IRQ trap_pc/mepc candidate=%08x expected=%08x",
                         dut.wb_trap_pc_for_mepc, EXPECTED_MEPC);
                $fatal(1);
            end
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            if (d_mem_addr == 32'h1000_0000) begin
                saw_handler_mepc_store <= 1'b1;
                stored_mepc <= d_mem_wdata;
                $display("[%0t ns] handler stored mepc=%08x", $time, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_0004) begin
                saw_handler_mcause_store <= 1'b1;
                stored_mcause <= d_mem_wdata;
                $display("[%0t ns] handler stored mcause=%08x", $time, d_mem_wdata);
            end else if (d_mem_addr == 32'h1000_0008) begin
                saw_mret_resume_marker <= 1'b1;
                $display("[%0t ns] mret resume marker=%08x", $time, d_mem_wdata);
                if (d_mem_wdata !== 32'h0000_600d) begin
                    $display("FAIL: bad mret resume marker=%08x", d_mem_wdata);
                    $fatal(1);
                end
            end
        end

        if (trap) begin
            $display("FAIL: illegal trap pin asserted");
            $fatal(1);
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        if ($test$plusargs("full_vcd")) begin
            $dumpvars(0, tb_trap_irq);
        end else begin
            $dumpvars(0, clk, resetn, irq_external_pulse, trap,
                         injected_irq, saw_irq_entry,
                         saw_handler_mepc_store, saw_handler_mcause_store,
                         saw_mret_resume_marker, stored_mepc, stored_mcause);
            $dumpvars(0, i_mem_addr, i_mem_en, i_mem_rdata,
                         d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb,
                         dbg_pc, dbg_instr, dbg_state);
        end
        $dumpoff;

        repeat (6) @(posedge clk);
        resetn = 1'b1;

        $dumpon;
        repeat (220) @(posedge clk);
        $dumpoff;

        if (!injected_irq) begin
            $display("FAIL: never reached 16-bit IRQ target");
            $fatal(1);
        end
        if (!saw_irq_entry) begin
            $display("FAIL: IRQ entry not observed");
            $fatal(1);
        end
        if (!saw_handler_mepc_store || stored_mepc !== EXPECTED_MEPC) begin
            $display("FAIL: stored mepc=%08x expected=%08x", stored_mepc, EXPECTED_MEPC);
            $fatal(1);
        end
        if (!saw_handler_mcause_store || stored_mcause !== EXPECTED_MCAUSE) begin
            $display("FAIL: stored mcause=%08x expected=%08x", stored_mcause, EXPECTED_MCAUSE);
            $fatal(1);
        end
        if (!saw_mret_resume_marker) begin
            $display("FAIL: mret resume marker not observed");
            $fatal(1);
        end

        $display("PASS: directed IRQ on 16-bit instruction saved mepc=%08x mcause=%08x and mret resumed",
                 stored_mepc, stored_mcause);
        $finish;
    end

    initial begin
        #20_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
