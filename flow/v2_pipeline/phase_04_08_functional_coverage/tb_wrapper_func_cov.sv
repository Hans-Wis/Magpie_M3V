`timescale 1ns / 1ns

module tb_wrapper_func_cov;
    localparam integer MEMW = 4096;
    localparam integer AB  = 12;
    localparam integer MAXC_DEFAULT = 220000;
    localparam integer WAIT_MODE_0      = 0;
    localparam integer WAIT_MODE_1      = 1;
    localparam integer WAIT_MODE_3      = 3;
    localparam integer WAIT_MODE_RANDOM = 4;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    integer imode = WAIT_MODE_3;
    integer dmode = WAIT_MODE_1;
    integer max_cycles = MAXC_DEFAULT;

    wire        ibus_req;
    wire [31:0] ibus_addr;
    reg         ibus_ready;
    reg  [31:0] ibus_rdata;

    wire        dbus_req;
    wire [31:0] dbus_addr;
    wire        dbus_we;
    wire [3:0]  dbus_wstrb;
    wire [31:0] dbus_wdata;
    reg         dbus_ready;
    reg  [31:0] dbus_rdata;

    wire trap;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;

    reg [31:0] memory [0:MEMW-1];

    wire [11:0] ibus_word = ibus_addr[AB+1:2];
    wire [11:0] dbus_word = dbus_addr[AB+1:2];

    integer i_cycle_cnt = 0;
    integer d_cycle_cnt = 0;
    reg [15:0] ilfsr = 16'hACE1;
    reg [15:0] dlfsr = 16'h1ACE;

    assign ibus_rdata = memory[ibus_word];
    assign dbus_rdata = memory[dbus_word];

    integer  cp_hazard_sample_cycle;
    reg [3:0] cp_hazard_sample;
    integer  mem_stall_events;
    integer  pure_mem_stall_events;
    integer  watchdog;
    integer  commit_count;

    always #5 clk = ~clk;

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

    always @(posedge clk) begin
        if (!resetn) begin
            i_cycle_cnt <= 0;
            d_cycle_cnt <= 0;
            ilfsr       <= 16'hACE1;
            dlfsr       <= 16'h1ACE;
        end else begin
            i_cycle_cnt <= i_cycle_cnt + 1;
            d_cycle_cnt <= d_cycle_cnt + 1;
            ilfsr      <= {ilfsr[14:0], ilfsr[15]^ilfsr[13]^ilfsr[12]^ilfsr[10]};
            dlfsr      <= {dlfsr[14:0], dlfsr[15]^dlfsr[13]^dlfsr[12]^dlfsr[10]};
        end
    end

    always @* begin
        case (imode)
            WAIT_MODE_0:      ibus_ready = 1'b1;
            WAIT_MODE_1:      ibus_ready = i_cycle_cnt[0];
            WAIT_MODE_3:      ibus_ready = (i_cycle_cnt[1:0] == 2'b11);
            default:          ibus_ready = ilfsr[0];
        endcase
        case (dmode)
            WAIT_MODE_0:      dbus_ready = 1'b1;
            WAIT_MODE_1:      dbus_ready = d_cycle_cnt[0];
            WAIT_MODE_3:      dbus_ready = (d_cycle_cnt[1:0] == 2'b11);
            default:          dbus_ready = dlfsr[0];
        endcase
    end

    always @(posedge clk) begin
        if (dbus_req && dbus_ready && dbus_we) begin
            if (dbus_wstrb[0]) memory[dbus_word][ 7:0]  <= dbus_wdata[ 7:0];
            if (dbus_wstrb[1]) memory[dbus_word][15:8]  <= dbus_wdata[15:8];
            if (dbus_wstrb[2]) memory[dbus_word][23:16] <= dbus_wdata[23:16];
            if (dbus_wstrb[3]) memory[dbus_word][31:24] <= dbus_wdata[31:24];
        end
    end

    // mirror the covergroup hazard decode to confirm pure mem-stall vector sampling
    wire dut_stall          = dut.u_core.stall;
    wire dut_fetch_stall    = dut.u_core.fetch_stall;
    wire dut_mem_stall      = dut.u_core.mem_stall;
    wire dut_md_busy        = dut.u_core.md_busy;
    wire dut_id_is_muldiv   = dut.u_core.id_is_muldiv;
    wire dut_load_use_stall = dut_stall && !dut_id_is_muldiv && !dut_md_busy;
    wire dut_muldiv_busy    = dut_stall && dut_id_is_muldiv && dut_md_busy;
    wire [3:0] dut_cp_hazard = {dut_load_use_stall, dut_muldiv_busy, dut_fetch_stall, dut_mem_stall};

    initial begin
        integer idx;
        if (!$value$plusargs("imode=%d", imode))       imode = WAIT_MODE_3;
        if (!$value$plusargs("dmode=%d", dmode))       dmode = WAIT_MODE_1;
        if (!$value$plusargs("max_cycles=%0d", max_cycles)) max_cycles = MAXC_DEFAULT;
        for (idx = 0; idx < MEMW; idx = idx + 1) memory[idx] = 32'h0;
        $readmemh("wrapper_memstall.hex", memory);
        if (memory[0] === 32'hx) begin
            $display("FAIL: wrapper_memstall.hex not initialized");
            $fatal(1);
        end
        resetn = 1'b0;
        cp_hazard_sample_cycle = -1;
        cp_hazard_sample = 4'b0000;
        mem_stall_events = 0;
        pure_mem_stall_events = 0;
        watchdog = 0;
        commit_count = 0;
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        $display("[%0t] tb_wrapper_func_cov start imode=%0d dmode=%0d max_cycles=%0d", $time, imode, dmode, max_cycles);
    end

    always @(posedge clk) begin
        if (!resetn) begin
            watchdog <= 0;
            commit_count <= 0;
        end else if (!trap) begin
            watchdog <= watchdog + 1;
            if (dut.u_core.wb_instr_retired && !dut.u_core.ex_wb_illegal_r) commit_count <= commit_count + 1;
            if (dut.u_core.mem_stall) begin
                mem_stall_events <= mem_stall_events + 1;
                if (dut_cp_hazard == 4'b0001 && pure_mem_stall_events == 0) begin
                    pure_mem_stall_events <= pure_mem_stall_events + 1;
                    cp_hazard_sample_cycle <= watchdog;
                    cp_hazard_sample <= dut_cp_hazard;
                    $display("WRAPPER_MEMSTALL_HIT cycle=%0d cp_hazard=%b imode=%0d dmode=%0d", watchdog, dut_cp_hazard, imode, dmode);
                end
            end
            if (watchdog >= max_cycles) begin
                $display("FAIL: wrapper TB watchdog timeout at %0d cycles", watchdog);
                $display("mem_stall_events=%0d pure_mem_stall_events=%0d cp_hazard_sample=%b", mem_stall_events, pure_mem_stall_events, cp_hazard_sample);
                $fatal(1);
            end
        end else begin
            $display("PASS: wrapper functional coverage observed trap after %0d commits", commit_count);
            $display("mem_stall_events=%0d pure_mem_stall_events=%0d cp_hazard_sample=%b (cycle=%0d)", mem_stall_events, pure_mem_stall_events, cp_hazard_sample, cp_hazard_sample_cycle);
            $finish;
        end
    end
endmodule
