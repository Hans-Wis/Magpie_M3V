// =============================================================================
// tb_soc_m3v_irq.v — IRQ-driven SoC smoke for ADR-0068 M2
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_soc_m3v_irq #(
    parameter [31:0] TRAP_PC = 32'h0000_0000
);
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
        .HOST_INIT_HEX("design/npu/sw/host_producer_irq/host_producer_irq.hex")
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
    reg npu_irq_seen = 1'b0;
    reg trap_pc_seen = 1'b0;

    task sample_irq_path;
        begin
            if (npu_irq)
                npu_irq_seen = 1'b1;
            if (npu_irq_seen && host_dbg_pc >= TRAP_PC && host_dbg_pc < (TRAP_PC + 32'h100))
                trap_pc_seen = 1'b1;
        end
    endtask

    initial begin
        repeat (8) @(posedge clk);
        resetn = 1'b1;

        for (i = 0; i < 2000000; i = i + 1) begin
            @(posedge clk);
            sample_irq_path();
            marker = dut.u_shared_sram.mem[DONE_WORD];
            if (marker == DONE_PASS || marker == DONE_FAIL) begin
                i = 2000000;
            end
        end

        marker = dut.u_shared_sram.mem[DONE_WORD];
        if (marker !== DONE_PASS) begin
            errors = errors + 1;
            $display("SOC_M3V_IRQ_FAIL: marker=%08x stage=%08x evidence=%08x",
                     marker,
                     dut.u_shared_sram.mem[DONE_WORD + 1],
                     dut.u_shared_sram.mem[DONE_WORD + 2]);
            $display("SOC_M3V_IRQ_DIAG host_pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b npu_irq=%0b plic_meip=%0b",
                     host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err,
                     npu_irq, dut.plic_meip);
        end
        if (host_axi_err) begin
            errors = errors + 1;
            $display("SOC_M3V_IRQ_FAIL: host_axi_err=1 pc=%08x instr=%08x", host_dbg_pc, host_dbg_instr);
        end
        if (!npu_irq_seen || !trap_pc_seen) begin
            errors = errors + 1;
            $display("SOC_M3V_IRQ_FAIL: irq_seen=%0b trap_pc_seen=%0b trap_pc=%08x last_pc=%08x",
                     npu_irq_seen, trap_pc_seen, TRAP_PC, host_dbg_pc);
        end else begin
            $display("SOC_M3V_IRQ_SEEN irq=1 trap_pc=%08x", TRAP_PC);
        end

        fdump = $fopen("soc_m3v_irq_result.dump", "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fdump, "%08x", dut.u_shared_sram.mem[RESULT_WORD + i]);
        $fclose(fdump);

        $display("SOC_M3V_IRQ: %0d errors", errors);
        if (errors == 0) $display("SOC_M3V_IRQ_PASS");
        else             $display("SOC_M3V_IRQ_FAIL");
        $finish;
    end

    initial begin
        #50000000;
        $display("SOC_M3V_IRQ_FAIL: timeout pc=%08x instr=%08x state=%0d trap=%0b axi_err=%0b marker=%08x irq_seen=%0b trap_pc_seen=%0b plic_meip=%0b",
                 host_dbg_pc, host_dbg_instr, host_dbg_state, host_trap, host_axi_err,
                 dut.u_shared_sram.mem[DONE_WORD], npu_irq_seen, trap_pc_seen, dut.plic_meip);
        $finish;
    end
endmodule
`default_nettype wire
