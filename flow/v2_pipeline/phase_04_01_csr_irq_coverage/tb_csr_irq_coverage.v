`timescale 1ns / 1ns

module tb_csr_irq_coverage;
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
    localparam MCAUSE_EXT_IRQ = 32'h8000_000b;
    // mstatus snapshot inside the M-mode trap handler: MPP=2'b11 (M, bits 12:11 = 0x1800)
    // + MPIE=1 (bit 7 = 0x80, <- prior MIE). Per RISC-V Priv §3.1.6 (trap from M sets MPP=M).
    // Updated from stale 0x0080 (pre-MPP) to spec-correct 0x1880; matches Spike-verified core
    // (passed 104k riscv-dv lockstep). P2 TB modernization 2026-06-09.
    localparam MSTATUS_TRAP_SNAPSHOT = 32'h0000_1880;

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

    reg injected_irq;
    reg saw_mscratch_w;
    reg saw_mscratch_s;
    reg saw_mscratch_c;
    reg saw_mscratch_final;
    reg saw_unknown_zero;
    reg saw_cycle;
    reg saw_instret;
    reg saw_pending_mip;
    reg saw_handler_mepc;
    reg saw_handler_mcause;
    reg saw_handler_mstatus;
    reg saw_resume;

    reg [31:0] handler_mepc;

    initial begin
        injected_irq = 1'b0;
        saw_mscratch_w = 1'b0;
        saw_mscratch_s = 1'b0;
        saw_mscratch_c = 1'b0;
        saw_mscratch_final = 1'b0;
        saw_unknown_zero = 1'b0;
        saw_cycle = 1'b0;
        saw_instret = 1'b0;
        saw_pending_mip = 1'b0;
        saw_handler_mepc = 1'b0;
        saw_handler_mcause = 1'b0;
        saw_handler_mstatus = 1'b0;
        saw_resume = 1'b0;
        handler_mepc = 32'h0;
    end

    always @(negedge clk) begin
        if (resetn && saw_instret && !injected_irq && dbg_instr == 32'h0000_0013) begin
            irq_external_pulse <= 1'b1;
            injected_irq <= 1'b1;
            $display("[%0t ns] inject pending IRQ at pc=%08x instr=%08x", $time, dbg_pc, dbg_instr);
        end else begin
            irq_external_pulse <= 1'b0;
        end
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
            $display("FAIL: illegal trap pin asserted");
            $fatal(1);
        end

        if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
            $display("[%0t ns] mmio[%08x] <= %08x", $time, mmio_off, d_mem_wdata);
            case (mmio_off)
                32'h00: begin
                    check_store(d_mem_wdata, 32'h0000_0000, "csrrw old mscratch");
                    saw_mscratch_w <= 1'b1;
                end
                32'h04: begin
                    check_store(d_mem_wdata, 32'h1234_5678, "csrrs old mscratch");
                    saw_mscratch_s <= 1'b1;
                end
                32'h08: begin
                    check_store(d_mem_wdata, 32'h1234_567f, "csrrc old mscratch");
                    saw_mscratch_c <= 1'b1;
                end
                32'h0c: begin
                    check_store(d_mem_wdata, 32'h1234_5677, "final mscratch");
                    saw_mscratch_final <= 1'b1;
                end
                32'h10: begin
                    check_store(d_mem_wdata, 32'h0000_0000, "unknown CSR read");
                    saw_unknown_zero <= 1'b1;
                end
                32'h14: begin
                    if (d_mem_wdata == 32'h0) begin
                        $display("FAIL: cycle CSR did not increment");
                        $fatal(1);
                    end
                    saw_cycle <= 1'b1;
                end
                32'h18: begin
                    if (d_mem_wdata == 32'h0) begin
                        $display("FAIL: instret CSR did not increment");
                        $fatal(1);
                    end
                    saw_instret <= 1'b1;
                end
                32'h1c: begin
                    check_store(d_mem_wdata, 32'h0000_0800, "pending mip.MEIP");
                    saw_pending_mip <= 1'b1;
                end
                32'h20: begin
                    if (d_mem_wdata == 32'h0) begin
                        $display("FAIL: handler mepc was zero");
                        $fatal(1);
                    end
                    handler_mepc <= d_mem_wdata;
                    saw_handler_mepc <= 1'b1;
                end
                32'h24: begin
                    check_store(d_mem_wdata, MCAUSE_EXT_IRQ, "handler mcause");
                    saw_handler_mcause <= 1'b1;
                end
                32'h28: begin
                    check_store(d_mem_wdata, MSTATUS_TRAP_SNAPSHOT, "handler mstatus");
                    saw_handler_mstatus <= 1'b1;
                end
                32'h2c: begin
                    $display("[%0t ns] mret resume marker observed data=%08x", $time, d_mem_wdata);
                    saw_resume <= 1'b1;
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
            $dumpvars(0, tb_csr_irq_coverage);
        end else begin
            $dumpvars(0, clk, resetn, irq_external_pulse, trap, injected_irq);
            $dumpvars(0, i_mem_addr, i_mem_en, i_mem_rdata);
            $dumpvars(0, d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb);
            $dumpvars(0, dbg_pc, dbg_instr, dbg_state);
            $dumpvars(0, saw_mscratch_w, saw_mscratch_s, saw_mscratch_c,
                         saw_mscratch_final, saw_unknown_zero, saw_cycle,
                         saw_instret, saw_pending_mip, saw_handler_mepc,
                         saw_handler_mcause, saw_handler_mstatus, saw_resume,
                         handler_mepc);
            $dumpvars(0, dut.u_csr.mstatus_mie, dut.u_csr.mstatus_mpie,
                         dut.u_csr.mie_meie, dut.u_csr.ext_pending,
                         dut.u_csr.mtvec_base, dut.u_csr.mscratch,
                         dut.u_csr.mepc_reg, dut.u_csr.mcause_reg,
                         dut.wb_take_irq, dut.wb_is_mret, dut.wb_trap_pc_for_mepc);
        end
        $dumpoff;

        repeat (6) @(posedge clk);
        resetn = 1'b1;

        $dumpon;
        repeat (340) @(posedge clk);
        $dumpoff;

        if (!injected_irq || !saw_pending_mip || !saw_handler_mepc ||
            !saw_handler_mcause || !saw_handler_mstatus || !saw_resume ||
            !saw_mscratch_w || !saw_mscratch_s || !saw_mscratch_c ||
            !saw_mscratch_final || !saw_unknown_zero || !saw_cycle ||
            !saw_instret) begin
            $display("FAIL: missing CSR/IRQ evidence injected=%0b pending=%0b mepc=%0b mcause=%0b mstatus=%0b resume=%0b",
                     injected_irq, saw_pending_mip, saw_handler_mepc,
                     saw_handler_mcause, saw_handler_mstatus, saw_resume);
            $fatal(1);
        end

        $display("PASS: directed CSR/IRQ coverage completed mepc=%08x", handler_mepc);
        $finish;
    end

    initial begin
        #30_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
