`timescale 1ns/1ns

module tb_debug_trigger;
    reg clk = 1'b0;
    reg resetn = 1'b0;

    wire trap;
    wire [31:0] i_mem_addr;
    wire        i_mem_en;
    reg  [31:0] i_mem_rdata;
    wire        d_mem_valid;
    wire [31:0] d_mem_addr;
    wire [31:0] d_mem_wdata;
    wire [3:0]  d_mem_wstrb;
    reg  [31:0] d_mem_rdata;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [2:0]  dbg_state;

    reg         dmi_req_en;
    reg  [6:0]  dmi_req_addr;
    reg         dmi_req_write;
    reg  [31:0] dmi_req_data;
    wire [31:0] dmi_resp_data;
    wire [1:0]  dmi_resp_op;
    wire        dm_halt_req;
    wire        dm_resume_req;
    wire        dm_ndmreset;
    wire        dm_acc_en;
    wire        dm_acc_write;
    wire [15:0] dm_acc_regno;
    wire [31:0] dm_acc_wdata;
    wire [31:0] dm_acc_rdata;
    wire        dm_acc_err;
    wire [63:0] dmi_reads;
    wire [63:0] dmi_writes;
    wire        hart_halted;
    wire        debug_mode;

    reg [31:0] imem [0:63];
    reg [31:0] dmem [0:63];
    integer cycle;
    integer i;
    integer trigger_entries;
    integer cross_ex_hits;
    integer false_fire_hits;
    reg     cross_phase;

    localparam [6:0] DMI_DATA0      = 7'h04;
    localparam [6:0] DMI_DMCONTROL  = 7'h10;
    localparam [6:0] DMI_DMSTATUS   = 7'h11;
    localparam [6:0] DMI_ABSTRACTCS = 7'h16;
    localparam [6:0] DMI_COMMAND    = 7'h17;
    localparam [31:0] DM_ACTIVE     = 32'h0000_0001;
    localparam [31:0] DM_HALTREQ    = 32'h8000_0001;
    localparam [31:0] DM_RESUMEREQ  = 32'h4000_0001;

    localparam [15:0] REG_DPC     = 16'h07b1;
    localparam [15:0] REG_TSELECT = 16'h07a0;
    localparam [15:0] REG_TDATA1  = 16'h07a1;
    localparam [15:0] REG_TDATA2  = 16'h07a2;

    localparam [31:0] MCONTROL6_EXEC  = 32'h6000_1044;
    localparam [31:0] MCONTROL6_STORE = 32'h6000_1042;

    core dut (
        .clk(clk),
        .resetn(resetn),
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
        .dm_halt_req(dm_halt_req),
        .dm_resume_req(dm_resume_req),
        .dm_hart_halted(hart_halted),
        .debug_mode_o(debug_mode),
        .dm_acc_en(dm_acc_en),
        .dm_acc_write(dm_acc_write),
        .dm_acc_regno(dm_acc_regno),
        .dm_acc_wdata(dm_acc_wdata),
        .dm_acc_rdata(dm_acc_rdata),
        .dm_acc_err(dm_acc_err),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    dm u_dm (
        .clk(clk),
        .rst(!resetn),
        .dmi_req_en(dmi_req_en),
        .dmi_req_addr(dmi_req_addr),
        .dmi_req_write(dmi_req_write),
        .dmi_req_data(dmi_req_data),
        .dmi_resp_data(dmi_resp_data),
        .dmi_resp_op(dmi_resp_op),
        .halt_req(dm_halt_req),
        .resume_req(dm_resume_req),
        .ndmreset(dm_ndmreset),
        .hart_halted(hart_halted),
        .hart_havereset(!resetn),
        .acc_en(dm_acc_en),
        .acc_write(dm_acc_write),
        .acc_regno(dm_acc_regno),
        .acc_wdata(dm_acc_wdata),
        .acc_rdata(dm_acc_rdata),
        .acc_err(dm_acc_err),
        .dmi_reads(dmi_reads),
        .dmi_writes(dmi_writes)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (i_mem_en)
            i_mem_rdata <= imem[i_mem_addr[7:2]];
        d_mem_rdata <= dmem[d_mem_addr[7:2]];
        if (d_mem_valid && (d_mem_wstrb != 4'h0))
            dmem[d_mem_addr[7:2]] <= d_mem_wdata;

        if (cross_phase && dut.ex_trigger_hit) begin
            if (dut.if_ex_pc == 32'h0000_0002 &&
                dut.if_ex_instr == 32'h0550_0293) begin
                cross_ex_hits <= cross_ex_hits + 1;
            end else begin
                false_fire_hits <= false_fire_hits + 1;
                $error("false execute trigger pc=%h instr=%h", dut.if_ex_pc, dut.if_ex_instr);
                $finish;
            end
        end
        if (dut.debug_halt_enter && dut.wb_take_trigger)
            trigger_entries <= trigger_entries + 1;
    end

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task dmi_write;
        input [6:0] addr;
        input [31:0] data;
        begin
            dmi_req_addr = addr;
            dmi_req_data = data;
            dmi_req_write = 1'b1;
            dmi_req_en = 1'b1;
            tick();
            dmi_req_en = 1'b0;
            dmi_req_write = 1'b0;
            dmi_req_data = 32'h0;
            tick();
        end
    endtask

    task dmi_read;
        input [6:0] addr;
        output [31:0] data;
        begin
            dmi_req_addr = addr;
            dmi_req_write = 1'b0;
            dmi_req_en = 1'b1;
            #1 data = dmi_resp_data;
            tick();
            dmi_req_en = 1'b0;
            tick();
        end
    endtask

    task wait_halted;
        integer n;
        reg [31:0] status;
        begin
            for (n = 0; n < 100; n = n + 1) begin
                dmi_read(DMI_DMSTATUS, status);
                if (status[8]) n = 100;
            end
            if (!hart_halted) begin
                $error("hart did not halt by cycle %0d", cycle);
                $finish;
            end
        end
    endtask

    task wait_running;
        integer n;
        reg [31:0] status;
        begin
            for (n = 0; n < 20; n = n + 1) begin
                dmi_read(DMI_DMSTATUS, status);
                if (status[10]) n = 20;
            end
            if (hart_halted) begin
                $error("hart did not resume by cycle %0d", cycle);
                $finish;
            end
        end
    endtask

    task abstract_read;
        input [15:0] regno;
        output [31:0] data;
        reg [31:0] abstractcs;
        begin
            dmi_write(DMI_ABSTRACTCS, 32'h0000_0700);
            dmi_write(DMI_COMMAND, 32'h0022_0000 | {16'h0, regno});
            dmi_read(DMI_ABSTRACTCS, abstractcs);
            if (abstractcs[10:8] != 3'd0) begin
                $error("abstract read cmderr regno=%h abstractcs=%h", regno, abstractcs);
                $finish;
            end
            dmi_read(DMI_DATA0, data);
        end
    endtask

    task abstract_write;
        input [15:0] regno;
        input [31:0] data;
        reg [31:0] abstractcs;
        begin
            dmi_write(DMI_ABSTRACTCS, 32'h0000_0700);
            dmi_write(DMI_DATA0, data);
            dmi_write(DMI_COMMAND, 32'h0023_0000 | {16'h0, regno});
            dmi_read(DMI_ABSTRACTCS, abstractcs);
            if (abstractcs[10:8] != 3'd0) begin
                $error("abstract write cmderr regno=%h abstractcs=%h", regno, abstractcs);
                $finish;
            end
        end
    endtask

    task clear_memories;
        begin
            for (i = 0; i < 64; i = i + 1) begin
                imem[i] = 32'h0000_0013;
                dmem[i] = 32'h0000_0000;
            end
            i_mem_rdata = 32'h0000_0013;
            d_mem_rdata = 32'h0;
        end
    endtask

    task reset_hart;
        begin
            resetn = 1'b0;
            repeat (3) tick();
            resetn = 1'b1;
            repeat (1) tick();
            dmi_write(DMI_DMCONTROL, DM_ACTIVE);
            dmi_write(DMI_DMCONTROL, DM_HALTREQ);
            wait_halted();
        end
    endtask

    reg [31:0] dpc_val;
    reg [31:0] x5_val;
    reg [31:0] x3_val;
    reg [31:0] tdata1_val;

    initial begin
        cycle = 0;
        trigger_entries = 0;
        cross_ex_hits = 0;
        false_fire_hits = 0;
        cross_phase = 1'b0;
        dmi_req_en = 1'b0;
        dmi_req_addr = 7'h0;
        dmi_req_write = 1'b0;
        dmi_req_data = 32'h0;

        clear_memories();
        imem[0] = 32'h0293_0001; // c.nop at 0x0, low half of addi x5,x0,0x55 at 0x2
        imem[1] = 32'h0001_0550; // high half of addi at 0x4, c.nop at 0x6
        reset_hart();
        abstract_write(16'h1005, 32'h0000_0000);
        abstract_write(REG_DPC, 32'h0000_0002);
        abstract_write(REG_TSELECT, 32'd0);
        abstract_write(REG_TDATA2, 32'h0000_0002);
        abstract_write(REG_TDATA1, MCONTROL6_EXEC);
        cross_phase = 1'b1;
        abstract_read(REG_TDATA1, tdata1_val);
        if (tdata1_val !== MCONTROL6_EXEC) begin
            $error("exec tdata1 readback mismatch got=%h", tdata1_val);
            $finish;
        end
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_halted();
        abstract_read(REG_DPC, dpc_val);
        abstract_read(16'h1005, x5_val);
        if (dpc_val !== 32'h0000_0002 || x5_val !== 32'h0 ||
            cross_ex_hits != 1 || false_fire_hits != 0 || trap) begin
            $error("cross trigger mismatch dpc=%h x5=%h cross_hits=%0d false=%0d trap=%0b",
                   dpc_val, x5_val, cross_ex_hits, false_fire_hits, trap);
            $finish;
        end
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_running();
        repeat (10) tick();
        if (hart_halted) begin
            $error("execute trigger re-fired immediately after resume");
            $finish;
        end
        dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        wait_halted();
        abstract_read(16'h1005, x5_val);
        if (x5_val !== 32'h0000_0055) begin
            $error("resume did not execute suppressed cross-boundary addi x5=%h", x5_val);
            $finish;
        end
        cross_phase = 1'b0;

        clear_memories();
        imem[0] = 32'h0030_0093; // addi x1,x0,3
        imem[1] = 32'h0070_0193; // addi x3,x0,7 at 0x4
        reset_hart();
        abstract_write(16'h1003, 32'h0000_0000);
        abstract_write(REG_DPC, 32'h0000_0004);
        abstract_write(REG_TSELECT, 32'd0);
        abstract_write(REG_TDATA2, 32'h0000_0004);
        abstract_write(REG_TDATA1, MCONTROL6_EXEC);
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_halted();
        abstract_read(REG_DPC, dpc_val);
        abstract_read(16'h1003, x3_val);
        if (dpc_val !== 32'h0000_0004 || x3_val !== 32'h0) begin
            $error("aligned pc trigger mismatch dpc=%h x3=%h", dpc_val, x3_val);
            $finish;
        end
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_running();
        repeat (8) tick();
        if (hart_halted) begin
            $error("aligned pc trigger re-fired on resume");
            $finish;
        end
        dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        wait_halted();
        abstract_read(16'h1003, x3_val);
        if (x3_val !== 32'h0000_0007) begin
            $error("aligned resume did not step off x3=%h", x3_val);
            $finish;
        end

        clear_memories();
        imem[0] = 32'h0200_0093; // addi x1,x0,0x20
        imem[1] = 32'h0aa0_0113; // addi x2,x0,0xaa
        imem[2] = 32'h0020_a023; // sw x2,0(x1) at 0x8
        reset_hart();
        dmem[8] = 32'h0000_0000;
        abstract_write(16'h1001, 32'h0000_0000);
        abstract_write(16'h1002, 32'h0000_0000);
        abstract_write(REG_DPC, 32'h0000_0000);
        abstract_write(REG_TSELECT, 32'd2);
        abstract_write(REG_TDATA2, 32'h0000_0020);
        abstract_write(REG_TDATA1, MCONTROL6_STORE);
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_halted();
        abstract_read(REG_DPC, dpc_val);
        if (dpc_val !== 32'h0000_0008 || dmem[8] !== 32'h0000_0000) begin
            $error("store watchpoint mismatch dpc=%h dmem20=%h", dpc_val, dmem[8]);
            $finish;
        end
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_running();
        repeat (8) tick();
        dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        wait_halted();
        if (dmem[8] !== 32'h0000_00aa) begin
            $error("watchpoint suppress did not allow resumed store dmem20=%h", dmem[8]);
            $finish;
        end

        $display("PASS: trigger cross_dpc=00000002 aligned_dpc=00000004 store_dpc=00000008 entries=%0d x5=%h x3=%h dmem20=%h",
                 trigger_entries, x5_val, x3_val, dmem[8]);
        $finish;
    end
endmodule
