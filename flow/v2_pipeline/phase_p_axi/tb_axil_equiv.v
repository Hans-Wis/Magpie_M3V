`timescale 1ns / 1ns

module tb_axil_equiv;
    localparam integer MEM_WORDS = 524288;
    localparam [31:0]  ELF_BASE  = 32'h0000_0000;
    localparam integer MAX_COMMITS = 8192;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    always #5 clk = ~clk;

    reg [1023:0] firmware_hex;
    reg [1023:0] native_trace_path;
    reg [1023:0] axi_trace_path;
    integer wait_states;
    integer max_cycles;
    integer n_fd;
    integer a_fd;
    integer watchdog;
    integer errors;
    integer idx;

    reg [31:0] native_mem [0:MEM_WORDS-1];
    integer i;

    wire n_trap;
    wire n_ibus_req;
    wire [31:0] n_ibus_addr;
    wire [31:0] n_ibus_rdata;
    wire n_dbus_req;
    wire [31:0] n_dbus_addr;
    wire n_dbus_we;
    wire [3:0] n_dbus_wstrb;
    wire [31:0] n_dbus_wdata;
    wire [31:0] n_dbus_rdata;
    wire [31:0] n_dbg_pc;
    wire [31:0] n_dbg_instr;
    wire [2:0] n_dbg_state;

    wire [18:0] n_iidx = n_ibus_addr[20:2];
    wire [18:0] n_didx = n_dbus_addr[20:2];
    assign n_ibus_rdata = native_mem[n_iidx];
    assign n_dbus_rdata = native_mem[n_didx];

    always @(posedge clk) begin
        if (resetn && n_dbus_req && n_dbus_we) begin
            if (n_dbus_wstrb[0]) native_mem[n_didx][ 7: 0] <= n_dbus_wdata[ 7: 0];
            if (n_dbus_wstrb[1]) native_mem[n_didx][15: 8] <= n_dbus_wdata[15: 8];
            if (n_dbus_wstrb[2]) native_mem[n_didx][23:16] <= n_dbus_wdata[23:16];
            if (n_dbus_wstrb[3]) native_mem[n_didx][31:24] <= n_dbus_wdata[31:24];
        end
    end

    cpu_m1_top #(.RESET_PC(ELF_BASE)) u_native (
        .clk(clk),
        .resetn(resetn),
        .trap(n_trap),
        .ibus_req(n_ibus_req),
        .ibus_addr(n_ibus_addr),
        .ibus_ready(1'b1),
        .ibus_rdata(n_ibus_rdata),
        .dbus_req(n_dbus_req),
        .dbus_addr(n_dbus_addr),
        .dbus_we(n_dbus_we),
        .dbus_wstrb(n_dbus_wstrb),
        .dbus_wdata(n_dbus_wdata),
        .dbus_ready(1'b1),
        .dbus_rdata(n_dbus_rdata),
        .irq_external_pulse(1'b0),
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
        .dbg_pc(n_dbg_pc),
        .dbg_instr(n_dbg_instr),
        .dbg_state(n_dbg_state)
    );

    wire a_trap;
    wire a_i_arvalid;
    wire a_i_arready;
    wire [31:0] a_i_araddr;
    wire [2:0] a_i_arprot;
    wire a_i_rvalid;
    wire a_i_rready;
    wire [31:0] a_i_rdata;
    wire [1:0] a_i_rresp;
    wire a_d_arvalid;
    wire a_d_arready;
    wire [31:0] a_d_araddr;
    wire [2:0] a_d_arprot;
    wire a_d_rvalid;
    wire a_d_rready;
    wire [31:0] a_d_rdata;
    wire [1:0] a_d_rresp;
    wire a_d_awvalid;
    wire a_d_awready;
    wire [31:0] a_d_awaddr;
    wire [2:0] a_d_awprot;
    wire a_d_wvalid;
    wire a_d_wready;
    wire [31:0] a_d_wdata;
    wire [3:0] a_d_wstrb;
    wire a_d_bvalid;
    wire a_d_bready;
    wire [1:0] a_d_bresp;
    wire a_dbg_axi_err;
    wire [31:0] a_dbg_pc;
    wire [31:0] a_dbg_instr;
    wire [2:0] a_dbg_state;
    wire unused_i_awready;
    wire unused_i_wready;
    wire unused_i_bvalid;
    wire [1:0] unused_i_bresp;

    cpu_m1_axil_top #(.RESET_PC(ELF_BASE)) u_axi (
        .clk(clk),
        .resetn(resetn),
        .trap(a_trap),
        .irq_external_pulse(1'b0),
        .m_axi_i_arvalid(a_i_arvalid),
        .m_axi_i_arready(a_i_arready),
        .m_axi_i_araddr(a_i_araddr),
        .m_axi_i_arprot(a_i_arprot),
        .m_axi_i_rvalid(a_i_rvalid),
        .m_axi_i_rready(a_i_rready),
        .m_axi_i_rdata(a_i_rdata),
        .m_axi_i_rresp(a_i_rresp),
        .m_axi_d_arvalid(a_d_arvalid),
        .m_axi_d_arready(a_d_arready),
        .m_axi_d_araddr(a_d_araddr),
        .m_axi_d_arprot(a_d_arprot),
        .m_axi_d_rvalid(a_d_rvalid),
        .m_axi_d_rready(a_d_rready),
        .m_axi_d_rdata(a_d_rdata),
        .m_axi_d_rresp(a_d_rresp),
        .m_axi_d_awvalid(a_d_awvalid),
        .m_axi_d_awready(a_d_awready),
        .m_axi_d_awaddr(a_d_awaddr),
        .m_axi_d_awprot(a_d_awprot),
        .m_axi_d_wvalid(a_d_wvalid),
        .m_axi_d_wready(a_d_wready),
        .m_axi_d_wdata(a_d_wdata),
        .m_axi_d_wstrb(a_d_wstrb),
        .m_axi_d_bvalid(a_d_bvalid),
        .m_axi_d_bready(a_d_bready),
        .m_axi_d_bresp(a_d_bresp),
        .dbg_axi_err(a_dbg_axi_err),
        .dbg_pc(a_dbg_pc),
        .dbg_instr(a_dbg_instr),
        .dbg_state(a_dbg_state)
    );

    axil_lite_mem_bfm #(.MEM_WORDS(MEM_WORDS), .ELF_BASE(ELF_BASE)) u_i_mem (
        .clk(clk),
        .resetn(resetn),
        .wait_states(wait_states),
        .s_axi_arvalid(a_i_arvalid),
        .s_axi_arready(a_i_arready),
        .s_axi_araddr(a_i_araddr),
        .s_axi_arprot(a_i_arprot),
        .s_axi_rvalid(a_i_rvalid),
        .s_axi_rready(a_i_rready),
        .s_axi_rdata(a_i_rdata),
        .s_axi_rresp(a_i_rresp),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(unused_i_awready),
        .s_axi_awaddr(32'h0),
        .s_axi_awprot(3'b0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(unused_i_wready),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_bvalid(unused_i_bvalid),
        .s_axi_bready(1'b0),
        .s_axi_bresp(unused_i_bresp)
    );

    axil_lite_mem_bfm #(.MEM_WORDS(MEM_WORDS), .ELF_BASE(ELF_BASE)) u_d_mem (
        .clk(clk),
        .resetn(resetn),
        .wait_states(wait_states),
        .s_axi_arvalid(a_d_arvalid),
        .s_axi_arready(a_d_arready),
        .s_axi_araddr(a_d_araddr),
        .s_axi_arprot(a_d_arprot),
        .s_axi_rvalid(a_d_rvalid),
        .s_axi_rready(a_d_rready),
        .s_axi_rdata(a_d_rdata),
        .s_axi_rresp(a_d_rresp),
        .s_axi_awvalid(a_d_awvalid),
        .s_axi_awready(a_d_awready),
        .s_axi_awaddr(a_d_awaddr),
        .s_axi_awprot(a_d_awprot),
        .s_axi_wvalid(a_d_wvalid),
        .s_axi_wready(a_d_wready),
        .s_axi_wdata(a_d_wdata),
        .s_axi_wstrb(a_d_wstrb),
        .s_axi_bvalid(a_d_bvalid),
        .s_axi_bready(a_d_bready),
        .s_axi_bresp(a_d_bresp)
    );

    integer n_count = 0;
    integer a_count = 0;
    reg n_done = 1'b0;
    reg a_done = 1'b0;

    reg [31:0] n_pc[0:MAX_COMMITS-1];
    reg [31:0] n_instr[0:MAX_COMMITS-1];
    reg [4:0]  n_rd[0:MAX_COMMITS-1];
    reg [31:0] n_wdata[0:MAX_COMMITS-1];
    reg [31:0] n_mstatus[0:MAX_COMMITS-1];
    reg [31:0] n_mepc[0:MAX_COMMITS-1];
    reg [31:0] n_mcause[0:MAX_COMMITS-1];
    reg [31:0] n_mtval[0:MAX_COMMITS-1];

    reg [31:0] a_pc[0:MAX_COMMITS-1];
    reg [31:0] a_instr[0:MAX_COMMITS-1];
    reg [4:0]  a_rd[0:MAX_COMMITS-1];
    reg [31:0] a_wdata[0:MAX_COMMITS-1];
    reg [31:0] a_mstatus[0:MAX_COMMITS-1];
    reg [31:0] a_mepc[0:MAX_COMMITS-1];
    reg [31:0] a_mcause[0:MAX_COMMITS-1];
    reg [31:0] a_mtval[0:MAX_COMMITS-1];

    function [31:0] native_instr_at_pc;
        input [31:0] pc;
        reg [18:0] word_idx;
        reg [31:0] word0;
        reg [31:0] word1;
        reg [15:0] half0;
        begin
            word_idx = pc[20:2];
            word0 = native_mem[word_idx];
            if (pc[1]) begin
                half0 = word0[31:16];
                if (half0[1:0] == 2'b11) begin
                    word1 = native_mem[word_idx + 19'd1];
                    native_instr_at_pc = {word1[15:0], half0};
                end else begin
                    native_instr_at_pc = {16'h0, half0};
                end
            end else begin
                half0 = word0[15:0];
                if (half0[1:0] == 2'b11)
                    native_instr_at_pc = word0;
                else
                    native_instr_at_pc = {16'h0, half0};
            end
        end
    endfunction

    task record_native;
        begin
            n_pc[n_count]      = u_native.u_core.ex_wb_pc_r;
            n_instr[n_count]   = native_instr_at_pc(u_native.u_core.ex_wb_pc_r);
            n_rd[n_count]      = (u_native.u_core.rfu_we && (u_native.u_core.rfu_wr_idx != 5'd0)) ? u_native.u_core.rfu_wr_idx : 5'd0;
            n_wdata[n_count]   = (u_native.u_core.rfu_we && (u_native.u_core.rfu_wr_idx != 5'd0)) ? u_native.u_core.rfu_wr_data : 32'h0;
            n_mstatus[n_count] = u_native.u_core.u_csr.mstatus_val;
            n_mepc[n_count]    = u_native.u_core.u_csr.mepc_reg;
            n_mcause[n_count]  = u_native.u_core.u_csr.mcause_reg;
            n_mtval[n_count]   = u_native.u_core.u_csr.mtval_reg;
            $fdisplay(n_fd, "%0d,%08x,%08x,%0d,%08x,%08x,%08x,%08x,%08x",
                      n_count, n_pc[n_count], n_instr[n_count], n_rd[n_count], n_wdata[n_count],
                      n_mstatus[n_count], n_mepc[n_count], n_mcause[n_count], n_mtval[n_count]);
            n_count = n_count + 1;
        end
    endtask

    task record_axi;
        begin
            a_pc[a_count]      = u_axi.u_cpu.u_core.ex_wb_pc_r;
            a_instr[a_count]   = u_i_mem.instr_at_pc(u_axi.u_cpu.u_core.ex_wb_pc_r);
            a_rd[a_count]      = (u_axi.u_cpu.u_core.rfu_we && (u_axi.u_cpu.u_core.rfu_wr_idx != 5'd0)) ? u_axi.u_cpu.u_core.rfu_wr_idx : 5'd0;
            a_wdata[a_count]   = (u_axi.u_cpu.u_core.rfu_we && (u_axi.u_cpu.u_core.rfu_wr_idx != 5'd0)) ? u_axi.u_cpu.u_core.rfu_wr_data : 32'h0;
            a_mstatus[a_count] = u_axi.u_cpu.u_core.u_csr.mstatus_val;
            a_mepc[a_count]    = u_axi.u_cpu.u_core.u_csr.mepc_reg;
            a_mcause[a_count]  = u_axi.u_cpu.u_core.u_csr.mcause_reg;
            a_mtval[a_count]   = u_axi.u_cpu.u_core.u_csr.mtval_reg;
            $fdisplay(a_fd, "%0d,%08x,%08x,%0d,%08x,%08x,%08x,%08x,%08x",
                      a_count, a_pc[a_count], a_instr[a_count], a_rd[a_count], a_wdata[a_count],
                      a_mstatus[a_count], a_mepc[a_count], a_mcause[a_count], a_mtval[a_count]);
            a_count = a_count + 1;
        end
    endtask

    initial begin
        if (!$value$plusargs("HEX=%s", firmware_hex)) firmware_hex = "../phase_03_04_directed_lockstep/firmware.hex";
        if (!$value$plusargs("NATIVE_TRACE=%s", native_trace_path)) native_trace_path = "native_commit.trace";
        if (!$value$plusargs("AXI_TRACE=%s", axi_trace_path)) axi_trace_path = "axi_commit.trace";
        if (!$value$plusargs("WAIT=%d", wait_states)) wait_states = 0;
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 1000000;

        for (i = 0; i < MEM_WORDS; i = i + 1) native_mem[i] = 32'h0;
        $readmemh(firmware_hex, native_mem);
        u_i_mem.load_hex(firmware_hex);
        u_d_mem.load_hex(firmware_hex);

        n_fd = $fopen(native_trace_path, "w");
        a_fd = $fopen(axi_trace_path, "w");
        if (n_fd == 0 || a_fd == 0) begin
            $display("FAIL: could not open trace files");
            $fatal(1);
        end
        $fdisplay(n_fd, "idx,pc,instr,rd,wdata,mstatus,mepc,mcause,mtval");
        $fdisplay(a_fd, "idx,pc,instr,rd,wdata,mstatus,mepc,mcause,mtval");

        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end

    always @(posedge clk) begin
        if (resetn) begin
            watchdog <= watchdog + 1;
            if (watchdog > max_cycles) begin
                $display("FAIL wait=%0d: watchdog timeout native_pc=%08x axi_pc=%08x native_commits=%0d axi_commits=%0d",
                         wait_states, n_dbg_pc, a_dbg_pc, n_count, a_count);
                $fatal(1);
            end

            if (!n_done && u_native.u_core.wb_instr_retired && !u_native.u_core.ex_wb_illegal_r) begin
                if (n_count >= MAX_COMMITS) $fatal(1, "native commit array overflow");
                record_native();
            end
            if (!a_done && u_axi.u_cpu.u_core.wb_instr_retired && !u_axi.u_cpu.u_core.ex_wb_illegal_r) begin
                if (a_count >= MAX_COMMITS) $fatal(1, "axi commit array overflow");
                record_axi();
            end

            if (u_native.u_core.ex_wb_valid_r && u_native.u_core.ex_wb_illegal_r) n_done <= 1'b1;
            if (u_axi.u_cpu.u_core.ex_wb_valid_r && u_axi.u_cpu.u_core.ex_wb_illegal_r) a_done <= 1'b1;

            if (n_done && a_done) begin
                errors = 0;
                if (n_count != a_count) begin
                    $display("FAIL wait=%0d: commit count native=%0d axi=%0d", wait_states, n_count, a_count);
                    errors = errors + 1;
                end
                for (idx = 0; idx < n_count && idx < a_count; idx = idx + 1) begin
                    if (n_pc[idx] !== a_pc[idx] || n_instr[idx] !== a_instr[idx] ||
                        n_rd[idx] !== a_rd[idx] || n_wdata[idx] !== a_wdata[idx] ||
                        n_mstatus[idx] !== a_mstatus[idx] || n_mepc[idx] !== a_mepc[idx] ||
                        n_mcause[idx] !== a_mcause[idx] || n_mtval[idx] !== a_mtval[idx]) begin
                        $display("FAIL wait=%0d idx=%0d", wait_states, idx);
                        $display("  native pc=%08x instr=%08x rd=%0d wdata=%08x mstatus=%08x mepc=%08x mcause=%08x mtval=%08x",
                                 n_pc[idx], n_instr[idx], n_rd[idx], n_wdata[idx], n_mstatus[idx], n_mepc[idx], n_mcause[idx], n_mtval[idx]);
                        $display("  axi    pc=%08x instr=%08x rd=%0d wdata=%08x mstatus=%08x mepc=%08x mcause=%08x mtval=%08x",
                                 a_pc[idx], a_instr[idx], a_rd[idx], a_wdata[idx], a_mstatus[idx], a_mepc[idx], a_mcause[idx], a_mtval[idx]);
                        errors = errors + 1;
                        idx = n_count;
                    end
                end
                if (a_dbg_axi_err) begin
                    $display("FAIL wait=%0d: dbg_axi_err asserted", wait_states);
                    errors = errors + 1;
                end
                $fclose(n_fd);
                $fclose(a_fd);
                if (errors == 0) begin
                    $display("PASS wait=%0d: native vs AXI commit trace matched %0d commits", wait_states, n_count);
                    $finish;
                end else begin
                    $fatal(1);
                end
            end
        end else begin
            watchdog <= 0;
        end
    end

    wire _unused = ^{n_trap, n_ibus_req, n_dbg_instr, n_dbg_state, a_trap, a_dbg_instr, a_dbg_state,
                     unused_i_awready, unused_i_wready, unused_i_bvalid, unused_i_bresp};
endmodule
