// =============================================================================
// tb_soc_m3v.v — minimal SoC smoke for ADR-0068
// -----------------------------------------------------------------------------
// The only preload is the real host instruction memory. The host cpu_m1 firmware
// loads NPU firmware, writes TCM/shared descriptors, rings the doorbell, polls
// status, and writes a DONE marker in shared SRAM.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_soc_m3v;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    wire host_trap, host_axi_err, npu_irq;
    wire [31:0] host_dbg_pc, host_dbg_instr;
    wire [2:0] host_dbg_state;

    soc_m3v_top #(
        .HOST_IMEM_WORDS(32768),
        .HOST_IMEM_AW(15),
        .SHARED_WORDS(16384),
        .SHARED_AW(14),
        .HOST_INIT_HEX("design/npu/sw/host_producer/host_producer.hex")
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .host_trap(host_trap),
        .host_axi_err(host_axi_err),
        .host_dbg_pc(host_dbg_pc),
        .host_dbg_instr(host_dbg_instr),
        .host_dbg_state(host_dbg_state),
        .npu_irq(npu_irq)
    );

    localparam integer DONE_WORD = 32'h0000FF00 >> 2;
    localparam integer RESULT_WORD = 32'h00001800 >> 2;
    localparam [31:0] DONE_PASS = 32'h534F4350;
    localparam [31:0] DONE_FAIL = 32'h534F4346;

    integer i;
    integer fdump;
    integer errors = 0;
    reg [31:0] marker;

    initial begin
        repeat (8) @(posedge clk);
        resetn = 1'b1;

        for (i = 0; i < 1200000; i = i + 1) begin
            @(posedge clk);
            marker = dut.u_shared_sram.mem[DONE_WORD];
            if (marker == DONE_PASS || marker == DONE_FAIL) begin
                i = 1200000;
            end
        end

        marker = dut.u_shared_sram.mem[DONE_WORD];
        if (marker !== DONE_PASS) begin
            errors = errors + 1;
            $display("SOC_M3V_FAIL: marker=%08x stage=%08x evidence=%08x",
                     marker,
                     dut.u_shared_sram.mem[DONE_WORD + 1],
                     dut.u_shared_sram.mem[DONE_WORD + 2]);
            $display("SOC_M3V_DIAG host_pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b npu_irq=%0b",
                     host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err, npu_irq);
        end
        if (host_trap || host_axi_err) begin
            errors = errors + 1;
            $display("SOC_M3V_FAIL: host_trap=%0b host_axi_err=%0b pc=%08x instr=%08x",
                     host_trap, host_axi_err, host_dbg_pc, host_dbg_instr);
        end

        fdump = $fopen("soc_m3v_result.dump", "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fdump, "%08x", dut.u_shared_sram.mem[RESULT_WORD + i]);
        $fclose(fdump);

        $display("SOC_M3V: %0d errors", errors);
        if (errors == 0) $display("SOC_M3V_PASS");
        else             $display("SOC_M3V_FAIL");
        $finish;
    end

    initial begin
        #30000000;
        $display("SOC_M3V_FAIL: timeout pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b marker=%08x",
                 host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err,
                 dut.u_shared_sram.mem[DONE_WORD]);
        $finish;
    end
endmodule
`default_nettype wire
