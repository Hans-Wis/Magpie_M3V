`timescale 1ns/1ps
`default_nettype none

module tb_cpu_m1_asic_top;
    localparam [31:0] RAM_BASE    = 32'h2000_0000;
    localparam        RAM_ADDR_W  = 11;
    localparam [31:0] MAGIC       = 32'hcafe_f00d;
    localparam int    MAGIC_WORD  = 32'h07fc >> 2;
    localparam int    TIMEOUT_CYC = 8000;

    reg clk;
    reg resetn;
    wire trap;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire dbg_axi_err;

    always #5 clk = ~clk;

    cpu_m1_asic_top #(
        .RAM_BASE(RAM_BASE),
        .RAM_ADDR_W(RAM_ADDR_W),
        .INIT_HEX("build/asic_boot_magic.hex"),
        .BOOT_DEBUG(1'b0)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .irq_external_pulse(1'b0),
        .trap(trap),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_axi_err(dbg_axi_err)
    );

    integer cycle;
    reg [31:0] last_pc;
    reg saw_rom0;
    reg saw_rom4;
    reg saw_ram;
    reg saw_magic;
    reg [31:0] magic_mem;

    task automatic sample_magic;
        begin
            magic_mem = dut.u_sram.u_sram.mem[MAGIC_WORD];
        end
    endtask

    task automatic print_trace(input [31:0] pc, input [31:0] instr);
        begin
            sample_magic();
            $display("TRACE cycle=%0d pc=%08x instr=%08x magic=%08x axi_err=%0b",
                     cycle, pc, instr, magic_mem, dbg_axi_err);
        end
    endtask

    initial begin
        clk = 1'b0;
    end

    initial begin
        resetn = 1'b0;
        cycle = 0;
        last_pc = 32'hffff_ffff;
        saw_rom0 = 1'b0;
        saw_rom4 = 1'b0;
        saw_ram = 1'b0;
        saw_magic = 1'b0;
        magic_mem = 32'h0;

        repeat (540) @(posedge clk);
        resetn = 1'b1;

        while (cycle < TIMEOUT_CYC && !saw_magic) begin
            @(posedge clk);
            cycle = cycle + 1;
            sample_magic();

            if (dbg_pc !== last_pc) begin
                if ((dbg_pc == 32'h0000_0000) ||
                    (dbg_pc == 32'h0000_0004) ||
                    ((dbg_pc >= RAM_BASE) && !saw_ram) ||
                    ((dbg_pc >= RAM_BASE) && (cycle < 120))) begin
                    print_trace(dbg_pc, dbg_instr);
                end
                last_pc = dbg_pc;
            end

            if (dbg_pc == 32'h0000_0000) saw_rom0 = 1'b1;
            if (dbg_pc == 32'h0000_0004) saw_rom4 = 1'b1;
            if (dbg_pc >= RAM_BASE) saw_ram = 1'b1;
            if (magic_mem === MAGIC) saw_magic = 1'b1;
        end

        repeat (5) @(posedge clk);
        sample_magic();
        $display("RESULT magic_mem[%0d]=%08x dbg_axi_err=%0b trap=%0b saw_rom0=%0b saw_rom4=%0b saw_ram=%0b cycles=%0d",
                 MAGIC_WORD, magic_mem, dbg_axi_err, trap,
                 saw_rom0, saw_rom4, saw_ram, cycle);

        if (saw_rom0 && saw_rom4 && saw_ram && saw_magic && !dbg_axi_err) begin
            $display("PASS cpu_m1_asic_top boot ROM -> T28 SRAM execution wrote MAGIC");
            $finish;
        end else begin
            $display("FAIL cpu_m1_asic_top boot verification");
            if (!saw_rom0) $display("FAIL_DETAIL missing PC 0x00000000 ROM fetch in dbg_pc trace");
            if (!saw_rom4) $display("FAIL_DETAIL missing PC 0x00000004 ROM fetch in dbg_pc trace");
            if (!saw_ram)  $display("FAIL_DETAIL never observed dbg_pc in RAM at/above 0x20000000");
            if (!saw_magic)$display("FAIL_DETAIL MAGIC was not written before timeout");
            if (dbg_axi_err)$display("FAIL_DETAIL dbg_axi_err asserted");
            $fatal(1);
        end
    end
endmodule

`default_nettype wire
