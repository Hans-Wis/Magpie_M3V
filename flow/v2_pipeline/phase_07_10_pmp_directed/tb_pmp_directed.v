`timescale 1ns / 1ns

module tb_pmp_directed;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
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
    wire        dm_halted;
    wire        debug_mode;
    wire [31:0] dm_rdata;
    wire        dm_err;

    localparam MEM_SIZE = 4096;
    localparam TOHOST   = 32'h0000_03f0;
    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_word_idx = i_mem_addr[13:2];
    wire [11:0] d_word_idx = d_mem_addr[13:2];

    core #(
        .RV32A(1),
        .PMP_ENTRIES(8)
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
        .dm_hart_halted     (dm_halted),
        .debug_mode_o       (debug_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dm_rdata),
        .dm_acc_err         (dm_err),
        .dbg_pc             (dbg_pc),
        .dbg_instr          (dbg_instr),
        .dbg_state          (dbg_state)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (i_mem_en)
            i_mem_rdata <= memory[i_word_idx];

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

    integer watchdog;
    initial begin
        watchdog = 0;
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_pmp_directed);
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > 5000) begin
            $display("FAIL: watchdog pc=%08x instr=%08x state=%03b if_addr=%08x if_en=%b trap=%b redirect=%b stall=%b any_stall=%b core_mem_stall=%b",
                     dbg_pc, dbg_instr, dbg_state, i_mem_addr, i_mem_en, trap,
                     dut.pc_redirect, dut.stall, dut.any_stall, dut.core_mem_stall);
            $fatal(1);
        end
        if (d_mem_valid && |d_mem_wstrb && d_mem_addr == TOHOST) begin
            if (d_mem_wdata == 32'h1) begin
                $display("PASS: PMP directed X/R/W/TOR/NA4/NAPOT priority AMO");
                $finish;
            end else begin
                $display("FAIL: PMP directed code=%08x", d_mem_wdata);
                $fatal(1);
            end
        end
    end
endmodule
