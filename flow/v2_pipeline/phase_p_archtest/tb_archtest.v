`timescale 1ns / 1ns

module tb_archtest #(
    parameter RV32A = 1,
    parameter PMP_ENTRIES = 0
);
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

    localparam MEM_WORDS = 524288;
    localparam ELF_BASE  = 32'h00001000;
    reg [31:0] memory [0:MEM_WORDS-1];

    reg [1023:0] firmware_hex;
    reg [1023:0] signature_path;
    integer max_cycles;
    integer sig_fd;
    integer i;
    integer watchdog;
    reg [31:0] stop_addr;
    reg [31:0] sig_begin;
    reg [31:0] sig_end;

    wire [31:0] i_mem_offset = (i_mem_addr >= ELF_BASE) ? (i_mem_addr - ELF_BASE) : i_mem_addr;
    wire [18:0] i_word_idx = i_mem_offset[20:2];
    wire [31:0] d_mem_offset = (d_mem_addr >= ELF_BASE) ? (d_mem_addr - ELF_BASE) : d_mem_addr;
    wire [18:0] d_word_idx = d_mem_offset[20:2];

    core #(
        .RESET_PC(ELF_BASE),
        .RV32A(RV32A),
        .PMP_ENTRIES(PMP_ENTRIES)
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

    task dump_signature;
        integer addr;
        integer word_idx;
        begin
            sig_fd = $fopen(signature_path, "w");
            if (sig_fd == 0) begin
                $display("FAIL: could not open signature %0s", signature_path);
                $fatal(1);
            end
            for (addr = sig_begin; addr < sig_end; addr = addr + 4) begin
                word_idx = (((addr >= ELF_BASE) ? (addr - ELF_BASE) : addr) >> 2);
                $fdisplay(sig_fd, "%08x", memory[word_idx]);
            end
            $fclose(sig_fd);
        end
    endtask

    initial begin
        if (!$value$plusargs("HEX=%s", firmware_hex)) firmware_hex = "firmware.hex";
        if (!$value$plusargs("SIGNATURE=%s", signature_path)) signature_path = "dut.signature";
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 5000000;
        if (!$value$plusargs("STOP_ADDR=%h", stop_addr)) stop_addr = 32'hffff_ffff;
        if (!$value$plusargs("SIG_BEGIN=%h", sig_begin)) sig_begin = 32'h0;
        if (!$value$plusargs("SIG_END=%h", sig_end)) sig_end = 32'h0;

        for (i = 0; i < MEM_WORDS; i = i + 1) memory[i] = 32'h0;
        $readmemh(firmware_hex, memory);
        watchdog = 0;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > max_cycles) begin
            $display("FAIL: watchdog timeout pc=%08x", dbg_pc);
            $fatal(1);
        end

        if (d_mem_valid && |d_mem_wstrb && d_mem_addr == stop_addr && d_mem_wdata != 32'h0) begin
            dump_signature();
            $display("PASS: arch-test signature dumped");
            $finish;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end
endmodule
