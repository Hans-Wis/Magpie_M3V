`timescale 1ns / 1ns

module tb_clint_directed;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
    wire        trap;
    wire        ibus_req;
    wire [31:0] ibus_addr;
    wire [31:0] ibus_rdata;
    wire        dbus_req;
    wire [31:0] dbus_addr;
    wire        dbus_we;
    wire [ 3:0] dbus_wstrb;
    wire [31:0] dbus_wdata;
    wire [31:0] dbus_rdata;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;

    localparam MEM_WORDS = 4096;
    localparam RESULT_BASE = 32'h1000_0000;
    localparam MCAUSE_MSW_IRQ = 32'h8000_0003;
    localparam MCAUSE_TIMER_IRQ = 32'h8000_0007;

    reg [31:0] memory [0:MEM_WORDS-1];
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_idx = ibus_addr[13:2];
    wire [11:0] d_idx = dbus_addr[13:2];
    assign ibus_rdata = memory[i_idx];
    assign dbus_rdata = memory[d_idx];

    cpu_m1_clint_top dut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .ibus_req(ibus_req),
        .ibus_addr(ibus_addr),
        .ibus_ready(1'b1),
        .ibus_rdata(ibus_rdata),
        .dbus_req(dbus_req),
        .dbus_addr(dbus_addr),
        .dbus_we(dbus_we),
        .dbus_wstrb(dbus_wstrb),
        .dbus_wdata(dbus_wdata),
        .dbus_ready(1'b1),
        .dbus_rdata(dbus_rdata),
        .irq_external_pulse(1'b0),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (resetn && dbus_req && dbus_we && dbus_addr[31:28] == 4'h0) begin
            if (dbus_wstrb[0]) memory[d_idx][ 7: 0] <= dbus_wdata[ 7: 0];
            if (dbus_wstrb[1]) memory[d_idx][15: 8] <= dbus_wdata[15: 8];
            if (dbus_wstrb[2]) memory[d_idx][23:16] <= dbus_wdata[23:16];
            if (dbus_wstrb[3]) memory[d_idx][31:24] <= dbus_wdata[31:24];
        end
    end

    reg saw_timer_basic;
    reg saw_timer_basic_resume;
    reg saw_sw;
    reg saw_sw_resume;
    reg saw_corner;
    reg saw_corner_resume;
    reg saw_wrong_path;
    reg armed_corner_timer;
    reg saw_corner_mispredict;
    reg [31:0] timer_mcause;
    reg [31:0] timer_mepc;
    reg [31:0] sw_mcause;
    reg [31:0] sw_mepc;
    reg [31:0] corner_mcause;
    reg [31:0] corner_mepc;
    reg [31:0] expected_corner_mepc;
    reg [31:0] expected_corner_branch;
    integer retired_after_wrong_path;

    initial begin
        saw_timer_basic = 1'b0;
        saw_timer_basic_resume = 1'b0;
        saw_sw = 1'b0;
        saw_sw_resume = 1'b0;
        saw_corner = 1'b0;
        saw_corner_resume = 1'b0;
        saw_wrong_path = 1'b0;
        armed_corner_timer = 1'b0;
        saw_corner_mispredict = 1'b0;
        timer_mcause = 32'h0;
        timer_mepc = 32'h0;
        sw_mcause = 32'h0;
        sw_mepc = 32'h0;
        corner_mcause = 32'h0;
        corner_mepc = 32'h0;
        expected_corner_mepc = 32'h0;
        expected_corner_branch = 32'h0;
        retired_after_wrong_path = 0;
    end

    always @(negedge clk) begin
        if (resetn && saw_sw_resume && !armed_corner_timer &&
            expected_corner_branch != 32'h0 &&
            dut.u_cpu.u_core.ex_mem_mispredict_r &&
            dut.u_cpu.u_core.ex_mem_pc_r == expected_corner_branch) begin
            saw_corner_mispredict <= 1'b1;
            armed_corner_timer <= 1'b1;
            dut.u_clint.mtimecmp_r = dut.u_clint.mtime_r + 64'd4;
            $display("[%0t ns] armed corner MTIP at branch mispredict mtime=%0d",
                     $time, dut.u_clint.mtime_r);
        end
    end

    always @(posedge clk) begin
        if (dut.u_cpu.u_core.wb_instr_retired &&
            dut.u_cpu.u_core.ex_wb_pc_r == 32'h0000_0000) begin
            retired_after_wrong_path <= retired_after_wrong_path + 1;
        end

        if (trap && !saw_corner_resume) begin
            $display("FAIL: trap output asserted");
            $fatal(1);
        end

        if (resetn && dbus_req && dbus_we && dbus_addr[31:28] == 4'h1) begin
            case (dbus_addr - RESULT_BASE)
                32'h00: begin timer_mcause <= dbus_wdata; saw_timer_basic <= 1'b1; $display("timer mcause=%08x", dbus_wdata); end
                32'h04: begin timer_mepc <= dbus_wdata; $display("timer mepc=%08x", dbus_wdata); end
                32'h08: begin
                    if (dbus_wdata !== 32'h0000a001) begin
                        $display("FAIL: timer resume marker=%08x", dbus_wdata);
                        $fatal(1);
                    end
                    saw_timer_basic_resume <= 1'b1;
                end
                32'h10: begin sw_mcause <= dbus_wdata; saw_sw <= 1'b1; $display("sw mcause=%08x", dbus_wdata); end
                32'h14: begin sw_mepc <= dbus_wdata; $display("sw mepc=%08x", dbus_wdata); end
                32'h18: begin
                    if (dbus_wdata !== 32'h0000a002) begin
                        $display("FAIL: sw resume marker=%08x", dbus_wdata);
                        $fatal(1);
                    end
                    saw_sw_resume <= 1'b1;
                end
                32'h20: begin
                    saw_wrong_path <= 1'b1;
                    $display("FAIL: wrong-path store retired data=%08x", dbus_wdata);
                    $fatal(1);
                end
                32'h30: begin corner_mcause <= dbus_wdata; saw_corner <= 1'b1; $display("corner mcause=%08x", dbus_wdata); end
                32'h34: begin corner_mepc <= dbus_wdata; $display("corner mepc=%08x", dbus_wdata); end
                32'h38: begin expected_corner_mepc <= dbus_wdata; $display("expected corner mepc=%08x", dbus_wdata); end
                32'h3c: begin expected_corner_branch <= dbus_wdata; $display("expected corner branch=%08x", dbus_wdata); end
                32'h40: begin
                    if (dbus_wdata !== 32'h0000a003) begin
                        $display("FAIL: corner resume marker=%08x", dbus_wdata);
                        $fatal(1);
                    end
                    saw_corner_resume <= 1'b1;
                end
                32'h44: begin
                    $display("FAIL: unknown handler mcause=%08x", dbus_wdata);
                    $fatal(1);
                end
                default: begin end
            endcase
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_clint_directed);
        repeat (6) @(posedge clk);
        resetn = 1'b1;

        repeat (1200) @(posedge clk);

        if (!saw_timer_basic || timer_mcause !== MCAUSE_TIMER_IRQ) begin
            $display("FAIL: basic timer mcause=%08x", timer_mcause);
            $fatal(1);
        end
        if (!saw_timer_basic_resume) begin
            $display("FAIL: basic timer did not resume");
            $fatal(1);
        end
        if (!saw_sw || sw_mcause !== MCAUSE_MSW_IRQ) begin
            $display("FAIL: software mcause=%08x", sw_mcause);
            $fatal(1);
        end
        if (!saw_sw_resume) begin
            $display("FAIL: software IRQ did not resume");
            $fatal(1);
        end
        if (!saw_corner_mispredict || !armed_corner_timer) begin
            $display("FAIL: corner branch mispredict/MTIP arm not observed");
            $fatal(1);
        end
        if (!saw_corner || corner_mcause !== MCAUSE_TIMER_IRQ) begin
            $display("FAIL: corner timer mcause=%08x", corner_mcause);
            $fatal(1);
        end
        if (expected_corner_mepc == 32'h0 || corner_mepc !== expected_corner_mepc) begin
            $display("FAIL: corner mepc=%08x expected=%08x", corner_mepc, expected_corner_mepc);
            $fatal(1);
        end
        if (!saw_corner_resume || saw_wrong_path) begin
            $display("FAIL: corner resume=%0d wrong_path=%0d", saw_corner_resume, saw_wrong_path);
            $fatal(1);
        end

        $display("PASS: CLINT directed basic_timer mcause=%08x mepc=%08x; software mcause=%08x mepc=%08x; corner mcause=%08x mepc=%08x",
                 timer_mcause, timer_mepc, sw_mcause, sw_mepc, corner_mcause, corner_mepc);
        $finish;
    end

    initial begin
        #40_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
