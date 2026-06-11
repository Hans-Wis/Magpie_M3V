`timescale 1ns/1ns

module tb_debug_mvd;
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
    reg [31:0] rdata_q;
    integer cycle;
    integer commits;
    integer corner_hits;

    localparam [6:0] DMI_DATA0      = 7'h04;
    localparam [6:0] DMI_DMCONTROL  = 7'h10;
    localparam [6:0] DMI_DMSTATUS   = 7'h11;
    localparam [6:0] DMI_ABSTRACTCS = 7'h16;
    localparam [6:0] DMI_COMMAND    = 7'h17;
    localparam [31:0] DM_ACTIVE     = 32'h0000_0001;
    localparam [31:0] DM_HALTREQ    = 32'h8000_0001;
    localparam [31:0] DM_RESUMEREQ  = 32'h4000_0001;
    localparam [31:0] DM_HALT_RESUME = 32'hc000_0001;

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
        d_mem_rdata <= rdata_q;
        if (dut.wb_instr_retired)
            commits <= commits + 1;
        if (dut.debug_halt_enter) begin
            $display("halt_enter cycle=%0d dpc_next=%h exmem_valid=%0b br=%0b jal=%0b jalr=%0b mis=%0b",
                     cycle, dut.wb_trap_pc_for_mepc, dut.ex_mem_valid_r,
                     dut.ex_mem_is_branch_taken_r, dut.ex_mem_is_jal_r,
                     dut.ex_mem_is_jalr_r, dut.ex_mem_mispredict_r);
            if (dut.ex_mem_valid_r &&
                (dut.ex_mem_mispredict_r || dut.ex_mem_is_branch_taken_r ||
                 dut.ex_mem_is_jal_r || dut.ex_mem_is_jalr_r)) begin
                corner_hits <= corner_hits + 1;
                if (dut.wb_trap_pc_for_mepc !== 32'h0000_0004) begin
                    $error("corner dpc mismatch cycle=%0d got=%h", cycle, dut.wb_trap_pc_for_mepc);
                    $finish;
                end
            end
        end
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
        integer i;
        reg [31:0] status;
        begin
            for (i = 0; i < 80; i = i + 1) begin
                dmi_read(DMI_DMSTATUS, status);
                if (status[8]) i = 80;
            end
            if (!hart_halted) begin
                $error("hart did not halt by cycle %0d", cycle);
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

    reg [31:0] x1_val;
    reg [31:0] x2_val;
    reg [31:0] x3_val;
    reg [31:0] x4_val;
    reg [31:0] dpc_val;
    reg [31:0] commits_before;
    reg [31:0] dscr_val;
    reg [31:0] dcsr_rb;

    initial begin
        cycle = 0;
        commits = 0;
        corner_hits = 0;
        dmi_req_en = 1'b0;
        dmi_req_addr = 7'h0;
        dmi_req_write = 1'b0;
        dmi_req_data = 32'h0;
        i_mem_rdata = 32'h0;
        d_mem_rdata = 32'h0;
        rdata_q = 32'h0;
        imem[0] = 32'h1230_0093; // addi x1,x0,0x123
        imem[1] = 32'h0000_0463; // beq x0,x0,+8 -> 0x0c
        imem[2] = 32'h07a0_0493; // wrong path addi x9,x0,0x7a
        imem[3] = 32'h0040_0213; // addi x4,x0,4
        imem[4] = 32'h0011_8193; // addi x3,x3,1

        repeat (3) tick();
        resetn = 1'b1;
        repeat (1) tick();

        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        wait_halted();

        abstract_read(16'h1001, x1_val);
        abstract_read(16'h07b1, dpc_val);
        if (x1_val !== 32'h0000_0123 || dpc_val !== 32'h0000_000c) begin
            $error("halt/read mismatch x1=%h dpc=%h", x1_val, dpc_val);
            $finish;
        end

        abstract_write(16'h1002, 32'h0000_0055);
        abstract_read(16'h1002, x2_val);
        if (x2_val !== 32'h0000_0055) begin
            $error("abstract write/readback x2 mismatch x2=%h", x2_val);
            $finish;
        end
        abstract_write(16'h07b1, 32'h0000_0000);
        abstract_write(16'h07b0, 32'h0000_0000);
        dmi_write(DMI_DMCONTROL, DM_HALT_RESUME);
        dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        wait_halted();
        abstract_read(16'h07b1, dpc_val);
        if (dpc_val !== 32'h0000_0004 || corner_hits != 1) begin
            $error("corner halt mismatch dpc=%h hits=%0d", dpc_val, corner_hits);
            $finish;
        end

        abstract_write(16'h07b0, 32'h0000_0004); // dcsr.step=1
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_halted();
        abstract_read(16'h07b1, dpc_val);
        if (dpc_val !== 32'h0000_000c) begin
            $error("single-step branch dpc mismatch got=%h", dpc_val);
            $finish;
        end

        commits_before = commits;
        dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        wait_halted();
        if (commits != commits_before + 1) begin
            $error("single-step retired %0d instructions", commits - commits_before);
            $finish;
        end
        abstract_read(16'h1004, x4_val);
        abstract_read(16'h07b1, dpc_val);
        if (x4_val !== 32'h0000_0004 || dpc_val !== 32'h0000_0010) begin
            $error("step addi mismatch x4=%h dpc=%h", x4_val, dpc_val);
            $finish;
        end

        // ---- Coverage closure for previously-cold debug CSR bits (hart still halted) ----
        // dscratch0 (0x7b2): plain 32-bit debug scratch, never accessed before -> walking patterns.
        abstract_write(16'h07b2, 32'hAAAA_AAAA);
        abstract_read(16'h07b2, dscr_val);
        if (dscr_val !== 32'hAAAA_AAAA) begin
            $error("dscratch0 AAAA readback=%h", dscr_val); $finish;
        end
        abstract_write(16'h07b2, 32'h5555_5555);
        abstract_read(16'h07b2, dscr_val);
        if (dscr_val !== 32'h5555_5555) begin
            $error("dscratch0 5555 readback=%h", dscr_val); $finish;
        end
        // dcsr.ebreakm (bit 15): make EBREAK enter Debug Mode from M-mode — previously cold.
        abstract_write(16'h07b0, 32'h0000_8000);
        abstract_read(16'h07b0, dcsr_rb);
        if (dcsr_rb[15] !== 1'b1) begin
            $error("dcsr.ebreakm not set dcsr=%h", dcsr_rb); $finish;
        end

        $display("PASS: DMI halt x1=%h dpc0=%h write_x2=%h step_dpc=%h x4=%h commits=%0d corner_hits=%0d dscratch0=%h ebreakm=%0b",
                 x1_val, 32'h0000_000c, x2_val, dpc_val, x4_val, commits, corner_hits, dscr_val, dcsr_rb[15]);
        $finish;
    end
endmodule
