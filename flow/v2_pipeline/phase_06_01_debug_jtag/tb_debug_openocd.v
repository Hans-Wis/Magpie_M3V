`timescale 1ns/1ns

module tb_debug_openocd (
    input  wire        clk,
    input  wire        resetn,
    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,
    output wire        hart_halted,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [2:0]  dbg_state,
    output wire [63:0] dmi_reads,
    output wire [63:0] dmi_writes
);
    wire trap;
    wire [31:0] i_mem_addr;
    wire        i_mem_en;
    reg  [31:0] i_mem_rdata;
    wire        d_mem_valid;
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wstrb;
    reg  [31:0] d_mem_rdata;

    wire halt_req;
    wire resume_req;
    wire ndmreset;
    wire debug_mode;
    wire acc_en;
    wire acc_write;
    wire [15:0] acc_regno;
    wire [31:0] acc_wdata;
    wire [31:0] acc_rdata;
    wire        acc_err;

    reg [31:0] imem [0:63];
    integer init_i;

    wire core_resetn = resetn & ~ndmreset;

    core dut (
        .clk(clk),
        .resetn(core_resetn),
        .trap(trap),
        .mem_stall(1'b0),
        .i_mem_addr(i_mem_addr),
        .i_mem_en(i_mem_en),
        .i_mem_rdata(i_mem_rdata),
        .d_mem_valid(d_mem_valid),
        .d_mem_addr(d_mem_addr),
        .d_mem_wdata(d_mem_wdata),
        .d_mem_wstrb(d_mem_wstrb),
        .d_mem_rdata(d_mem_rdata),
        .irq_external_pulse(1'b0),
        .mtip(1'b0),
        .msip(1'b0),
        .meip(1'b0),
        .dm_halt_req(halt_req),
        .dm_resume_req(resume_req),
        .dm_hart_halted(hart_halted),
        .debug_mode_o(debug_mode),
        .dm_acc_en(acc_en),
        .dm_acc_write(acc_write),
        .dm_acc_regno(acc_regno),
        .dm_acc_wdata(acc_wdata),
        .dm_acc_rdata(acc_rdata),
        .dm_acc_err(acc_err),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    dtm u_dtm (
        .clk(clk),
        .rst(!resetn),
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .halt_req(halt_req),
        .resume_req(resume_req),
        .ndmreset(ndmreset),
        .hart_halted(hart_halted),
        .hart_havereset(!core_resetn),
        .acc_en(acc_en),
        .acc_write(acc_write),
        .acc_regno(acc_regno),
        .acc_wdata(acc_wdata),
        .acc_rdata(acc_rdata),
        .acc_err(acc_err),
        .dmi_reads(dmi_reads),
        .dmi_writes(dmi_writes)
    );

    initial begin
        for (init_i = 0; init_i < 64; init_i = init_i + 1)
            imem[init_i] = 32'h0000_0013; // nop

        imem[0] = 32'h1230_0093; // addi x1,x0,0x123
        imem[1] = 32'h0000_0463; // beq x0,x0,+8 -> 0x0c
        imem[2] = 32'h07a0_0493; // wrong path addi x9,x0,0x7a
        imem[3] = 32'h0040_0213; // addi x4,x0,4
        imem[4] = 32'h0011_8193; // addi x3,x3,1
    end

    always @(posedge clk) begin
        if (!core_resetn) begin
            i_mem_rdata <= 32'h0000_0013;
            d_mem_rdata <= 32'h0;
        end else begin
            if (i_mem_en)
                i_mem_rdata <= imem[i_mem_addr[7:2]];
            d_mem_rdata <= 32'h0;
        end
    end
endmodule
