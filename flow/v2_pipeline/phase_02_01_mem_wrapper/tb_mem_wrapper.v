`timescale 1ns / 1ns

module tb_mem_wrapper;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    wire        dbg_dummy2_halted;
    wire        dbg_dummy2_mode;
    wire [31:0] dbg_dummy2_acc_rdata;
    wire        dbg_dummy2_acc_err;

    localparam int MEM_WORDS        = 4096;
    localparam int ADDR_BITS        = 12;
    localparam int MAX_COMMITS      = 4096;
    localparam int WAIT_MODE_0      = 0;
    localparam int WAIT_MODE_1      = 1;
    localparam int WAIT_MODE_3      = 3;
    localparam int WAIT_MODE_RANDOM = 4;
    localparam int MAX_WAIT_CYCLES  = 22000;

    wire        ibus_req;
    wire [31:0] ibus_addr;
    wire        ibus_ready;
    wire [31:0] ibus_rdata;

    wire        dbus_req;
    wire [31:0] dbus_addr;
    wire        dbus_we;
    wire [3:0]  dbus_wstrb;
    wire [31:0] dbus_wdata;
    wire        dbus_ready;
    wire [31:0] dbus_rdata;
    // REPAIR-0001 combinational bus reads (contract-correct for all wait modes:
    // addr is held stable while req, single outstanding)
    // assigns placed after idx wires below via the second anchor

    wire        trap;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [2:0]  dbg_state;
    wire [31:0] ref_dbg_pc;
    wire [31:0] ref_dbg_instr;
    wire [2:0]  ref_dbg_state;

    // reference core
    wire        ref_trap;
    wire [31:0] ref_i_mem_addr;
    wire        ref_i_mem_en;
    reg  [31:0] ref_i_mem_rdata;
    wire [31:0] ref_d_mem_addr;
    wire        ref_d_mem_valid;
    wire [31:0] ref_d_mem_wdata;
    wire [3:0]  ref_d_mem_wstrb;
    reg  [31:0] ref_d_mem_rdata;

    integer i_wait_mode;
    integer d_wait_mode;
    reg [31:0] i_cycle_cnt;
    reg [31:0] d_cycle_cnt;
    reg [15:0] i_lfsr;
    reg [15:0] d_lfsr;
    reg        run_ref;
    reg        run_top;

    integer    ref_commit_count;
    reg [31:0] ref_pc   [0:MAX_COMMITS-1];
    reg [31:0] ref_instr[0:MAX_COMMITS-1];
    reg [4:0]  ref_rd   [0:MAX_COMMITS-1];
    reg [31:0] ref_wdata[0:MAX_COMMITS-1];

    reg [31:0] misaligned_cause [0:3];
    reg [31:0] misaligned_mtval [0:3];
    reg        saw_misaligned_bus;

    reg [31:0] mem_ref [0:MEM_WORDS-1];
    reg [31:0] mem_top [0:MEM_WORDS-1];

    wire ref_commit_valid = run_ref && ref_core.wb_instr_retired;
    wire top_commit_valid = run_top && uut.u_core.wb_instr_retired;
    wire ref_terminal = run_ref && ref_core.ex_wb_valid_r && ref_core.ex_wb_illegal_r;
    wire top_terminal = run_top && uut.u_core.ex_wb_valid_r && uut.u_core.ex_wb_illegal_r;

    wire i_ready_next = (i_wait_mode == WAIT_MODE_RANDOM) ? i_lfsr[0] :
                        (i_wait_mode == WAIT_MODE_0)     ? 1'b1 :
                        (i_wait_mode == WAIT_MODE_1)     ? i_cycle_cnt[0] :
                                                           (i_cycle_cnt[1:0] == 2'b11);
    wire d_ready_next = (d_wait_mode == WAIT_MODE_RANDOM) ? d_lfsr[0] :
                        (d_wait_mode == WAIT_MODE_0)     ? 1'b1 :
                        (d_wait_mode == WAIT_MODE_1)     ? d_cycle_cnt[0] :
                                                           (d_cycle_cnt[1:0] == 2'b11);

    assign ibus_ready = run_top ? i_ready_next : 1'b1;
    assign dbus_ready = run_top ? d_ready_next : 1'b1;

    always @(posedge clk) begin
        if (!resetn || !run_top) begin
            i_cycle_cnt <= 32'h0;
            d_cycle_cnt <= 32'h0;
            i_lfsr      <= 16'hACE1;
            d_lfsr      <= 16'h1ACE;
        end else begin
            i_cycle_cnt <= i_cycle_cnt + 1'b1;
            d_cycle_cnt <= d_cycle_cnt + 1'b1;
            i_lfsr <= {i_lfsr[14:0], i_lfsr[15] ^ i_lfsr[13] ^ i_lfsr[12] ^ i_lfsr[10]};
            d_lfsr <= {d_lfsr[14:0], d_lfsr[15] ^ d_lfsr[13] ^ d_lfsr[12] ^ d_lfsr[10]};
        end
    end

    cpu_m1_top uut (
        .clk               (clk),
        .resetn            (resetn),
        .trap              (trap),
        .ibus_req          (ibus_req),
        .ibus_addr         (ibus_addr),
        .ibus_ready        (ibus_ready),
        .ibus_rdata        (ibus_rdata),
        .dbus_req          (dbus_req),
        .dbus_addr         (dbus_addr),
        .dbus_we           (dbus_we),
        .dbus_wstrb        (dbus_wstrb),
        .dbus_wdata        (dbus_wdata),
        .dbus_ready        (dbus_ready),
        .dbus_rdata        (dbus_rdata),
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
        .dbg_pc            (dbg_pc),
        .dbg_instr         (dbg_instr),
        /* verilator lint_off PINCONNECTEMPTY */
        .rvfi_valid(), .rvfi_pc(), .rvfi_trap(), .rvfi_trap_cause(), .rvfi_intr(),
        .rvfi_rd_addr(), .rvfi_rd_wdata(),
        .rvvi_v_valid(), .rvvi_v_vd(), .rvvi_v_wdata(), .rvvi_vl(), .rvvi_vtype(), .rvfi_insn(), .rvfi_trap_mtval(), .rvfi_mstatus(), .rvfi_mem_re(), .rvfi_mem_we(), .rvfi_mem_addr(), .rvfi_mem_wdata(), .rvfi_mem_wstrb(),
        /* verilator lint_on PINCONNECTEMPTY */
        .dbg_state         (dbg_state)
    );

    core ref_core (
        .clk               (clk),
        .resetn            (resetn),
        .trap              (ref_trap),
        .mem_stall         (1'b0),
        .i_mem_addr        (ref_i_mem_addr),
        .i_mem_en          (ref_i_mem_en),
        .i_mem_rdata       (ref_i_mem_rdata),
        .d_mem_valid       (ref_d_mem_valid),
        .d_mem_addr        (ref_d_mem_addr),
        .d_mem_wdata       (ref_d_mem_wdata),
        .d_mem_wstrb       (ref_d_mem_wstrb),
        .d_mem_rdata       (ref_d_mem_rdata),
        .irq_external_pulse(1'b0),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy2_halted),
        .debug_mode_o       (dbg_dummy2_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dbg_dummy2_acc_rdata),
        .dm_acc_err         (dbg_dummy2_acc_err),
        .dbg_pc            (ref_dbg_pc),
        .dbg_instr         (ref_dbg_instr),
        /* verilator lint_off PINCONNECTEMPTY */
        .rvfi_valid(), .rvfi_pc(), .rvfi_trap(), .rvfi_trap_cause(), .rvfi_intr(),
        .rvfi_rd_addr(), .rvfi_rd_wdata(),
        .rvvi_v_valid(), .rvvi_v_vd(), .rvvi_v_wdata(), .rvvi_vl(), .rvvi_vtype(), .rvfi_insn(), .rvfi_trap_mtval(), .rvfi_mstatus(), .rvfi_mem_re(), .rvfi_mem_we(), .rvfi_mem_addr(), .rvfi_mem_wdata(), .rvfi_mem_wstrb(),
        /* verilator lint_on PINCONNECTEMPTY */
        .dbg_state         (ref_dbg_state)
    );

    wire [31:0] ref_i_word_idx = {{(32-ADDR_BITS){1'b0}}, ref_i_mem_addr[ADDR_BITS+1:2]};
    wire [31:0] ref_d_word_idx = {{(32-ADDR_BITS){1'b0}}, ref_d_mem_addr[ADDR_BITS+1:2]};
    wire [31:0] top_i_word_idx = {{(32-ADDR_BITS){1'b0}}, ibus_addr[ADDR_BITS+1:2]};
    wire [31:0] top_d_word_idx = {{(32-ADDR_BITS){1'b0}}, dbus_addr[ADDR_BITS+1:2]};

    assign ibus_rdata = (top_i_word_idx < MEM_WORDS) ? mem_top[top_i_word_idx] : 32'h0;
    assign dbus_rdata = (top_d_word_idx < MEM_WORDS) ? mem_top[top_d_word_idx] : 32'h0;

    always @(posedge clk) begin
        // REPAIR-0001: memory must respond whenever the core is out of reset — gating the
        // RESPONSE on run_ref froze i_mem_rdata during the resetn->run_ref window, feeding
        // the already-running core a stale/zero instruction (illegal at the first WB,
        // 0-commit baseline). run_ref/run_top now gate only counting/asserting.
        if (resetn) begin
            if (ref_i_mem_en && (ref_i_word_idx < MEM_WORDS))
                ref_i_mem_rdata <= mem_ref[ref_i_word_idx];

            if (ref_d_mem_valid && (ref_d_word_idx < MEM_WORDS)) begin
                ref_d_mem_rdata <= mem_ref[ref_d_word_idx];
                if (|ref_d_mem_wstrb) begin
                    if (ref_d_mem_wstrb[0]) mem_ref[ref_d_word_idx][ 7:0]  <= ref_d_mem_wdata[ 7:0];
                    if (ref_d_mem_wstrb[1]) mem_ref[ref_d_word_idx][15:8]  <= ref_d_mem_wdata[15:8];
                    if (ref_d_mem_wstrb[2]) mem_ref[ref_d_word_idx][23:16] <= ref_d_mem_wdata[23:16];
                    if (ref_d_mem_wstrb[3]) mem_ref[ref_d_word_idx][31:24] <= ref_d_mem_wdata[31:24];
                end
            end
        end

        if (resetn) begin
            // REPAIR-0001: reads are COMBINATIONAL (assigns below) — the wrapper consumes
            // bus_rdata AT the fire/xfer cycle ("rdata_q <= bus_rdata when fire",
            // cpu_m1_top.v header); a registered TB response is one cycle late and feeds
            // the wrapper garbage on its first fetch. Writes stay registered on xfer.
            if (dbus_req && dbus_ready && (top_d_word_idx < MEM_WORDS)) begin

                if (dbus_addr[31:28] == 4'h1) begin
                    if (dbus_we) begin
                        if (dbus_addr[2] == 1'b0)
                            misaligned_cause[dbus_addr[4:3]] <= dbus_wdata;
                        else
                            misaligned_mtval[dbus_addr[4:3]] <= dbus_wdata;
                    end
                end else if (dbus_we) begin
                    if (dbus_wstrb[0]) mem_top[top_d_word_idx][ 7:0]  <= dbus_wdata[ 7:0];
                    if (dbus_wstrb[1]) mem_top[top_d_word_idx][15:8]  <= dbus_wdata[15:8];
                    if (dbus_wstrb[2]) mem_top[top_d_word_idx][23:16] <= dbus_wdata[23:16];
                    if (dbus_wstrb[3]) mem_top[top_d_word_idx][31:24] <= dbus_wdata[31:24];
                end
            end
        end
    end

    function automatic [31:0] instr_at_pc_ref(input [31:0] pc);
        // REPAIR-0001: same inverted-marker decay as instr_at_pc_top; same proven fix.
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            word0 = mem_ref[{20'b0, pc[ADDR_BITS+1:2]}];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = mem_ref[{20'b0, pc[ADDR_BITS+1:2]} + 1];
                    instr_at_pc_ref = {word1[15:0], half0};
                end else begin
                    instr_at_pc_ref = {16'h0, half0};
                end
            end else begin
                half0 = word0[15:0];
                if (half0[1:0] == 2'b11)
                    instr_at_pc_ref = word0;
                else
                    instr_at_pc_ref = {16'h0, half0};
            end
        end
    endfunction

    function automatic [31:0] instr_at_pc_top(input [31:0] pc);
        // REPAIR-0001: the decayed version had the 32/16-bit marker conditions INVERTED
        // (a 32-bit instr returned truncated low-half). Replaced with the proven
        // reconstruction used by every passing directed TB (tb_spike_lockstep lineage).
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            word0 = mem_top[{20'b0, pc[ADDR_BITS+1:2]}];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = mem_top[{20'b0, pc[ADDR_BITS+1:2]} + 1];
                    instr_at_pc_top = {word1[15:0], half0};
                end else begin
                    instr_at_pc_top = {16'h0, half0};
                end
            end else begin
                half0 = word0[15:0];
                if (half0[1:0] == 2'b11)
                    instr_at_pc_top = word0;
                else
                    instr_at_pc_top = {16'h0, half0};
            end
        end
    endfunction

    task automatic clear_mem(input bit for_top);
        integer i;
        begin
            for (i = 0; i < MEM_WORDS; i = i + 1) begin
                if (for_top)
                    mem_top[i] = 32'h0;
                else
                    mem_ref[i] = 32'h0;
            end
        end
    endtask

    task automatic load_firmware_ref(input bit misalign_program);
        begin
            clear_mem(1'b0);
            if (misalign_program)
                $readmemh("firmware_misalign.hex", mem_ref);
            else
                $readmemh("firmware.hex", mem_ref);
        end
    endtask

    task automatic load_firmware_top(input bit misalign_program);
        begin
            clear_mem(1'b1);
            if (misalign_program)
                $readmemh("firmware_misalign.hex", mem_top);
            else
                $readmemh("firmware.hex", mem_top);
        end
    endtask

    task automatic reset_and_prepare;
        integer i;
        begin
            resetn = 1'b0;
            run_ref = 1'b0;
            run_top = 1'b0;
            i_wait_mode = WAIT_MODE_0;
            d_wait_mode = WAIT_MODE_0;
            saw_misaligned_bus = 1'b0;
            misaligned_cause[0] = 32'h0;
            misaligned_cause[1] = 32'h0;
            misaligned_cause[2] = 32'h0;
            misaligned_cause[3] = 32'h0;
            misaligned_mtval[0] = 32'h0;
            misaligned_mtval[1] = 32'h0;
            misaligned_mtval[2] = 32'h0;
            misaligned_mtval[3] = 32'h0;
            repeat (6) @(posedge clk);
            // REPAIR-0001: resetn is RELEASED BY THE CALLER together with run_* (same
            // time slot, no clock in between) so both cores start fetching on the same
            // cycle with LIVE memory — no garbage-fetch window, cycle-aligned compare.
        end
    endtask

    task automatic run_baseline_ref_top;
        integer cycles;
        integer top_count;
        integer ref_count;
        begin
            load_firmware_ref(1'b0);
            load_firmware_top(1'b0);
            reset_and_prepare();

            resetn  = 1'b1;
            run_ref = 1'b1;
            run_top = 1'b1;
            i_wait_mode = WAIT_MODE_0;
            d_wait_mode = WAIT_MODE_0;
            top_count = 0;
            ref_count = 0;

            for (cycles = 0; cycles < MAX_WAIT_CYCLES; cycles = cycles + 1) begin
                @(posedge clk);
                if (cycles < 30) begin
                    $display("TRACE_A cyc=%0d ref_term=%b top_term=%b ref_v=%b top_v=%b ref_count=%0d top_count=%0d",
                             cycles, ref_terminal, top_terminal,
                             ref_commit_valid, top_commit_valid, ref_count, top_count);
                    $display("         if_pc=%08x if_ex_valid=%b any_stall=%b at_cross=%b upcoming=%b warmup=%b",
                             uut.u_core.if_pc, uut.u_core.if_ex_valid, uut.u_core.any_stall,
                             uut.u_core.at_cross_boundary, uut.u_core.upcoming_cross, uut.u_core.warmup);
                end

                if (ref_commit_valid) begin
                    if (ref_count >= MAX_COMMITS)
                        $fatal(1);
                    ref_pc[ref_count]    = ref_core.ex_wb_pc_r;
                    ref_instr[ref_count] = instr_at_pc_ref(ref_core.ex_wb_pc_r);
                    ref_rd[ref_count]    = (ref_core.rfu_wr_idx != 5'h0 && ref_core.rfu_we) ? ref_core.rfu_wr_idx : 5'h0;
                    ref_wdata[ref_count] = (ref_core.rfu_wr_idx != 5'h0 && ref_core.rfu_we) ? ref_core.rfu_wr_data : 32'h0;
                    ref_count = ref_count + 1;
                end

                if (top_commit_valid) begin
                    if (top_count >= ref_count) begin
                        $display("ASSERT_A fail: top commit appeared before baseline idx=%0d", top_count);
                        $fatal(1);
                    end
                    $display("TRACE_A top commit[%0d] pc=%08x instr=%08x", top_count,
                             uut.u_core.ex_wb_pc_r, instr_at_pc_top(uut.u_core.ex_wb_pc_r));
                    if (uut.u_core.ex_wb_pc_r != ref_pc[top_count] ||
                        instr_at_pc_top(uut.u_core.ex_wb_pc_r) != ref_instr[top_count] ||
                        ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_idx : 5'h0) != ref_rd[top_count] ||
                        ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_data : 32'h0) != ref_wdata[top_count]) begin
                        $display("ASSERT_A fail: mismatch idx=%0d", top_count);
                        $display("  top pc=%08x instr=%08x rd=%0d wdata=%08x",
                                 uut.u_core.ex_wb_pc_r, instr_at_pc_top(uut.u_core.ex_wb_pc_r),
                                 ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_idx : 5'h0),
                                 ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_data : 32'h0));
                        $display("  ref pc=%08x instr=%08x rd=%0d wdata=%08x",
                                 ref_pc[top_count], ref_instr[top_count], ref_rd[top_count], ref_wdata[top_count]);
                        $fatal(1);
                    end
                    top_count = top_count + 1;
                end

                if (top_terminal || ref_terminal) begin
                    if (top_terminal !== ref_terminal) begin
                        $display("ASSERT_A fail: terminal trap mismatch");
                        $fatal(1);
                    end
                    if (top_count != ref_count) begin
                        $display("ASSERT_A fail: commit count mismatch ref=%0d top=%0d", ref_count, top_count);
                        $fatal(1);
                    end
                    ref_commit_count = ref_count;
                    $display("ASSERT_A pass: zero-wait baseline equivalence with %0d commits", ref_count);
                    return;
                end
            end
            $display("ASSERT_A fail: timeout");
            $fatal(1);
        end
    endtask

	    task automatic run_backpressure(input int wait_i, input int wait_d, input [127:0] label);
        integer cycles;
        integer top_count;
        integer fd;
        begin
            load_firmware_top(1'b0);
            reset_and_prepare();
            resetn  = 1'b1;
            run_top = 1'b1;
            i_wait_mode = wait_i;
            d_wait_mode = wait_d;
            top_count = 0;
            fd = $fopen("dut_commit.trace", "w");
            $fdisplay(fd, "idx,pc,instr,rd,wdata");

            for (cycles = 0; cycles < MAX_WAIT_CYCLES; cycles = cycles + 1) begin
                @(posedge clk);
                if (top_commit_valid) begin
                    if (top_count >= ref_commit_count) begin
                        $display("ASSERT_B(%s) fail: commit beyond baseline idx=%0d", label, top_count);
                        $fatal(1);
                    end
                    $display("TRACE_B(%s) commit[%0d] pc=%08x instr=%08x dbg_pc=%08x dbg_state=%03b wait_i=%0d wait_d=%0d terminal=%b",
                             label, top_count, uut.u_core.ex_wb_pc_r, instr_at_pc_top(uut.u_core.ex_wb_pc_r),
                             dbg_pc, dbg_state, i_wait_mode, d_wait_mode, top_terminal);
                    if (uut.u_core.ex_wb_pc_r != ref_pc[top_count] ||
                        instr_at_pc_top(uut.u_core.ex_wb_pc_r) != ref_instr[top_count]) begin
                        $display("ASSERT_B(%s) fail: mismatch idx=%0d", label, top_count);
                        $display("  expected pc=%08x instr=%08x rd=%0d wdata=%08x",
                                 ref_pc[top_count], ref_instr[top_count], ref_rd[top_count], ref_wdata[top_count]);
                        $display("  got      pc=%08x instr=%08x rd=%0d wdata=%08x",
                                 uut.u_core.ex_wb_pc_r,
                                 instr_at_pc_top(uut.u_core.ex_wb_pc_r),
                                 ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_idx : 5'h0),
                                 ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_data : 32'h0));
                        $fatal(1);
                    end
                    $fdisplay(fd, "%0d,%08x,%08x,%0d,%08x",
                             top_count,
                             uut.u_core.ex_wb_pc_r,
                             instr_at_pc_top(uut.u_core.ex_wb_pc_r),
                             ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_idx : 5'h0),
                             ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_data : 32'h0));
                    top_count = top_count + 1;
                end

                if (top_terminal) begin
                    $display("TRACE_B(%s) terminal at pc=%08x is_illegal=%b commit=%0d", label, uut.u_core.ex_wb_pc_r, uut.u_core.ex_wb_illegal_r, top_count);
                    if (top_count != ref_commit_count) begin
                        $display("ASSERT_B(%s) fail: commit count mismatch ref=%0d top=%0d", label, ref_commit_count, top_count);
                        $fatal(1);
                    end
                    $fclose(fd);
                    $display("ASSERT_B(%s) pass: %0d commits", label, top_count);
                    return;
                end
            end
            $fclose(fd);
            $display("ASSERT_B(%s) fail: timeout", label);
            $fatal(1);
        end
    endtask

    task automatic run_misaligned_trap;
        integer cycles;
        begin
            load_firmware_top(1'b1);
            load_firmware_ref(1'b1);
            reset_and_prepare();
            resetn  = 1'b1;
            run_top = 1'b1;
            i_wait_mode = WAIT_MODE_0;
            d_wait_mode = WAIT_MODE_0;

            for (cycles = 0; cycles < MAX_WAIT_CYCLES; cycles = cycles + 1) begin
                @(posedge clk);

                if (dbus_req && dbus_ready) begin
                    if ((dbus_addr[1:0] != 2'b00) &&
                        (dbus_wstrb == 4'hF || (dbus_wstrb == 4'h3 && dbus_addr[1]) || (dbus_wstrb == 4'hC && dbus_addr[1])))
                        saw_misaligned_bus = 1'b1;
                    if ((dbus_wstrb == 4'h0) && (dbus_addr[1:0] != 2'b00))
                        saw_misaligned_bus = 1'b1;
                end

                if (top_terminal) begin
                    if (saw_misaligned_bus) begin
                        $display("ASSERT_C fail: misaligned data bus request escaped wrapper/core");
                        $fatal(1);
                    end
                    if ((misaligned_cause[0] !== 32'h00000004) ||
                        (misaligned_cause[1] !== 32'h00000006) ||
                        (misaligned_cause[2] !== 32'h00000004) ||
                        (misaligned_cause[3] !== 32'h00000006) ||
                        (misaligned_mtval[0] !== 32'h00000101) ||
                        (misaligned_mtval[1] !== 32'h00000101) ||
                        (misaligned_mtval[2] !== 32'h00000101) ||
                        (misaligned_mtval[3] !== 32'h00000103)) begin
                        $display("ASSERT_C fail: cause/mtval mismatch");
                        $display("  causes=%08x %08x %08x %08x", misaligned_cause[0], misaligned_cause[1], misaligned_cause[2], misaligned_cause[3]);
                        $display("  mtvals=%08x %08x %08x %08x", misaligned_mtval[0], misaligned_mtval[1], misaligned_mtval[2], misaligned_mtval[3]);
                        $fatal(1);
                    end
                    $display("ASSERT_C pass: misaligned traps + no misaligned bus request");
                    return;
                end
            end
            $display("ASSERT_C fail: timeout");
            $fatal(1);
        end
    endtask

    task automatic run_lockstep_trace;
        integer cycles;
        integer top_count;
        integer fd;
        begin
            load_firmware_top(1'b0);
            reset_and_prepare();
            resetn  = 1'b1;
            run_top = 1'b1;
            i_wait_mode = WAIT_MODE_RANDOM;
            d_wait_mode = WAIT_MODE_RANDOM;
            top_count = 0;
            fd = $fopen("dut_commit.trace", "w");
            $fdisplay(fd, "idx,pc,instr,rd,wdata");

            for (cycles = 0; cycles < MAX_WAIT_CYCLES; cycles = cycles + 1) begin
                @(posedge clk);
                if (top_commit_valid) begin
                    $fdisplay(fd, "%0d,%08x,%08x,%0d,%08x",
                             top_count,
                             uut.u_core.ex_wb_pc_r,
                             instr_at_pc_top(uut.u_core.ex_wb_pc_r),
                             ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_idx : 5'h0),
                             ((uut.u_core.rfu_wr_idx != 5'h0 && uut.u_core.rfu_we) ? uut.u_core.rfu_wr_data : 32'h0));
                    top_count = top_count + 1;
                end
                if (top_terminal) begin
                    $fclose(fd);
                    $display("ASSERT_D pass: random-wait trace generated (%0d commits)", top_count);
                    return;
                end
            end
            $fclose(fd);
            $display("ASSERT_D fail: timeout");
            $fatal(1);
        end
    endtask

    initial begin
        run_baseline_ref_top();
        run_backpressure(WAIT_MODE_1,      WAIT_MODE_0, "I_WAIT_1");
        run_backpressure(WAIT_MODE_3,      WAIT_MODE_0, "I_WAIT_3");
        run_backpressure(WAIT_MODE_RANDOM, WAIT_MODE_0, "I_WAIT_RAND");
        run_backpressure(WAIT_MODE_0,      WAIT_MODE_1, "D_WAIT_1");
        run_backpressure(WAIT_MODE_0,      WAIT_MODE_3, "D_WAIT_3");
        run_backpressure(WAIT_MODE_0,      WAIT_MODE_RANDOM, "D_WAIT_RAND");
        run_misaligned_trap();
        run_lockstep_trace();
        $display("PASS: mem_wrapper TB gate A/B/C/D complete");
        $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_mem_wrapper);
    end
endmodule
