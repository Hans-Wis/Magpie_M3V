`timescale 1ns/1ns

module tb_debug_jtag;
    reg clk = 1'b0;
    reg resetn = 1'b0;

    wire jtag_trap;
    wire [31:0] jtag_i_mem_addr;
    wire        jtag_i_mem_en;
    reg  [31:0] jtag_i_mem_rdata;
    wire        jtag_d_mem_valid;
    wire [31:0] jtag_d_mem_addr;
    wire [31:0] jtag_d_mem_wdata;
    wire [3:0]  jtag_d_mem_wstrb;
    reg  [31:0] jtag_d_mem_rdata;
    wire        jtag_halt_req;
    wire        jtag_resume_req;
    wire        jtag_ndmreset;
    wire        jtag_hart_halted;
    wire        jtag_debug_mode;
    wire        jtag_acc_en;
    wire        jtag_acc_write;
    wire [15:0] jtag_acc_regno;
    wire [31:0] jtag_acc_wdata;
    wire [31:0] jtag_acc_rdata;
    wire        jtag_acc_err;
    wire [63:0] jtag_dmi_reads;
    wire [63:0] jtag_dmi_writes;
    wire [31:0] jtag_dbg_pc;
    wire [31:0] jtag_dbg_instr;
    wire [2:0]  jtag_dbg_state;

    reg         tck = 1'b0;
    reg         tms = 1'b1;
    reg         tdi = 1'b0;
    wire        tdo;

    wire ref_trap;
    wire [31:0] ref_i_mem_addr;
    wire        ref_i_mem_en;
    reg  [31:0] ref_i_mem_rdata;
    wire        ref_d_mem_valid;
    wire [31:0] ref_d_mem_addr;
    wire [31:0] ref_d_mem_wdata;
    wire [3:0]  ref_d_mem_wstrb;
    reg  [31:0] ref_d_mem_rdata;
    reg         ref_dmi_req_en;
    reg  [6:0]  ref_dmi_req_addr;
    reg         ref_dmi_req_write;
    reg  [31:0] ref_dmi_req_data;
    wire [31:0] ref_dmi_resp_data;
    wire [1:0]  ref_dmi_resp_op;
    wire        ref_halt_req;
    wire        ref_resume_req;
    wire        ref_ndmreset;
    wire        ref_hart_halted;
    wire        ref_debug_mode;
    wire        ref_acc_en;
    wire        ref_acc_write;
    wire [15:0] ref_acc_regno;
    wire [31:0] ref_acc_wdata;
    wire [31:0] ref_acc_rdata;
    wire        ref_acc_err;
    wire [63:0] ref_dmi_reads;
    wire [63:0] ref_dmi_writes;
    wire [31:0] ref_dbg_pc;
    wire [31:0] ref_dbg_instr;
    wire [2:0]  ref_dbg_state;

    reg [31:0] imem [0:63];
    integer cycle;

    localparam [4:0] IR_IDCODE = 5'h01;
    localparam [4:0] IR_DTMCS  = 5'h10;
    localparam [4:0] IR_DMI    = 5'h11;

    localparam [1:0] DMI_OP_NOP   = 2'd0;
    localparam [1:0] DMI_OP_READ  = 2'd1;
    localparam [1:0] DMI_OP_WRITE = 2'd2;

    localparam [6:0] DMI_DATA0      = 7'h04;
    localparam [6:0] DMI_DMCONTROL  = 7'h10;
    localparam [6:0] DMI_DMSTATUS   = 7'h11;
    localparam [6:0] DMI_ABSTRACTCS = 7'h16;
    localparam [6:0] DMI_COMMAND    = 7'h17;

    localparam [31:0] DTM_IDCODE_EXPECTED = 32'h10A9_8AD3;
    localparam [31:0] DM_ACTIVE           = 32'h0000_0001;
    localparam [31:0] DM_HALTREQ          = 32'h8000_0001;
    localparam [31:0] DM_RESUMEREQ        = 32'h4000_0001;

    core jtag_dut (
        .clk(clk),
        .resetn(resetn),
        .trap(jtag_trap),
        .mem_stall(1'b0),
        .i_mem_addr(jtag_i_mem_addr),
        .i_mem_en(jtag_i_mem_en),
        .i_mem_rdata(jtag_i_mem_rdata),
        .d_mem_valid(jtag_d_mem_valid),
        .d_mem_addr(jtag_d_mem_addr),
        .d_mem_wdata(jtag_d_mem_wdata),
        .d_mem_wstrb(jtag_d_mem_wstrb),
        .d_mem_rdata(jtag_d_mem_rdata),
        .irq_external_pulse(1'b0),
        .mtip(1'b0),
        .msip(1'b0),
        .meip(1'b0),
        .dm_halt_req(jtag_halt_req),
        .dm_resume_req(jtag_resume_req),
        .dm_hart_halted(jtag_hart_halted),
        .debug_mode_o(jtag_debug_mode),
        .dm_acc_en(jtag_acc_en),
        .dm_acc_write(jtag_acc_write),
        .dm_acc_regno(jtag_acc_regno),
        .dm_acc_wdata(jtag_acc_wdata),
        .dm_acc_rdata(jtag_acc_rdata),
        .dm_acc_err(jtag_acc_err),
        .dbg_pc(jtag_dbg_pc),
        .dbg_instr(jtag_dbg_instr),
        .dbg_state(jtag_dbg_state)
    );

    dtm u_dtm (
        .clk(clk),
        .rst(!resetn),
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .halt_req(jtag_halt_req),
        .resume_req(jtag_resume_req),
        .ndmreset(jtag_ndmreset),
        .hart_halted(jtag_hart_halted),
        .hart_havereset(!resetn),
        .acc_en(jtag_acc_en),
        .acc_write(jtag_acc_write),
        .acc_regno(jtag_acc_regno),
        .acc_wdata(jtag_acc_wdata),
        .acc_rdata(jtag_acc_rdata),
        .acc_err(jtag_acc_err),
        .dmi_reads(jtag_dmi_reads),
        .dmi_writes(jtag_dmi_writes)
    );

    core ref_dut (
        .clk(clk),
        .resetn(resetn),
        .trap(ref_trap),
        .mem_stall(1'b0),
        .i_mem_addr(ref_i_mem_addr),
        .i_mem_en(ref_i_mem_en),
        .i_mem_rdata(ref_i_mem_rdata),
        .d_mem_valid(ref_d_mem_valid),
        .d_mem_addr(ref_d_mem_addr),
        .d_mem_wdata(ref_d_mem_wdata),
        .d_mem_wstrb(ref_d_mem_wstrb),
        .d_mem_rdata(ref_d_mem_rdata),
        .irq_external_pulse(1'b0),
        .mtip(1'b0),
        .msip(1'b0),
        .meip(1'b0),
        .dm_halt_req(ref_halt_req),
        .dm_resume_req(ref_resume_req),
        .dm_hart_halted(ref_hart_halted),
        .debug_mode_o(ref_debug_mode),
        .dm_acc_en(ref_acc_en),
        .dm_acc_write(ref_acc_write),
        .dm_acc_regno(ref_acc_regno),
        .dm_acc_wdata(ref_acc_wdata),
        .dm_acc_rdata(ref_acc_rdata),
        .dm_acc_err(ref_acc_err),
        .dbg_pc(ref_dbg_pc),
        .dbg_instr(ref_dbg_instr),
        .dbg_state(ref_dbg_state)
    );

    dm u_dm_ref (
        .clk(clk),
        .rst(!resetn),
        .dmi_req_en(ref_dmi_req_en),
        .dmi_req_addr(ref_dmi_req_addr),
        .dmi_req_write(ref_dmi_req_write),
        .dmi_req_data(ref_dmi_req_data),
        .dmi_resp_data(ref_dmi_resp_data),
        .dmi_resp_op(ref_dmi_resp_op),
        .halt_req(ref_halt_req),
        .resume_req(ref_resume_req),
        .ndmreset(ref_ndmreset),
        .hart_halted(ref_hart_halted),
        .hart_havereset(!resetn),
        .acc_en(ref_acc_en),
        .acc_write(ref_acc_write),
        .acc_regno(ref_acc_regno),
        .acc_wdata(ref_acc_wdata),
        .acc_rdata(ref_acc_rdata),
        .acc_err(ref_acc_err),
        .dmi_reads(ref_dmi_reads),
        .dmi_writes(ref_dmi_writes)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (jtag_i_mem_en)
            jtag_i_mem_rdata <= imem[jtag_i_mem_addr[7:2]];
        if (ref_i_mem_en)
            ref_i_mem_rdata <= imem[ref_i_mem_addr[7:2]];
        jtag_d_mem_rdata <= 32'h0;
        ref_d_mem_rdata <= 32'h0;
    end

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task tap_step;
        input tms_i;
        input tdi_i;
        output tdo_o;
        begin
            tms = tms_i;
            tdi = tdi_i;
            tck = 1'b0;
            tick();
            tck = 1'b1;
            tick();
            tdo_o = tdo;
            tck = 1'b0;
            tick();
        end
    endtask

    task tap_step_ignore;
        input tms_i;
        input tdi_i;
        reg tdo_unused;
        begin
            tap_step(tms_i, tdi_i, tdo_unused);
        end
    endtask

    task jtag_reset_to_rti;
        integer i;
        begin
            for (i = 0; i < 6; i = i + 1)
                tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
        end
    endtask

    task jtag_shift_ir;
        input [4:0] ir;
        integer i;
        begin
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            for (i = 0; i < 5; i = i + 1)
                tap_step_ignore((i == 4), ir[i]);
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
        end
    endtask

    task jtag_shift_dr;
        input [40:0] data_in;
        input integer length;
        output [40:0] data_out;
        integer i;
        reg tdo_bit;
        begin
            data_out = 41'd0;
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            for (i = 0; i < length; i = i + 1) begin
                tap_step((i == length - 1), data_in[i], tdo_bit);
                data_out[i] = tdo_bit;
            end
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
        end
    endtask

    task jtag_read_idcode;
        output [31:0] idcode;
        reg [40:0] scan_out;
        begin
            jtag_shift_ir(IR_IDCODE);
            jtag_shift_dr(41'd0, 32, scan_out);
            idcode = scan_out[31:0];
        end
    endtask

    task jtag_read_dtmcs;
        output [31:0] dtmcs;
        reg [40:0] scan_out;
        begin
            jtag_shift_ir(IR_DTMCS);
            jtag_shift_dr(41'd0, 32, scan_out);
            dtmcs = scan_out[31:0];
        end
    endtask

    task jtag_dmi_op;
        input [6:0] addr;
        input [31:0] data;
        input [1:0] op;
        output [31:0] out_data;
        output [1:0] out_stat;
        reg [40:0] scan_in;
        reg [40:0] scan_out;
        begin
            jtag_shift_ir(IR_DMI);
            scan_in = {addr, data, op};
            jtag_shift_dr(scan_in, 41, scan_out);
            out_data = scan_out[33:2];
            out_stat = scan_out[1:0];
        end
    endtask

    task jtag_dmi_write;
        input [6:0] addr;
        input [31:0] data;
        reg [31:0] unused_data;
        reg [1:0] unused_stat;
        begin
            jtag_dmi_op(addr, data, DMI_OP_WRITE, unused_data, unused_stat);
        end
    endtask

    task jtag_dmi_read;
        input [6:0] addr;
        output [31:0] data;
        reg [31:0] unused_data;
        reg [1:0] stat;
        begin
            jtag_dmi_op(addr, 32'd0, DMI_OP_READ, unused_data, stat);
            jtag_dmi_op(7'd0, 32'd0, DMI_OP_NOP, data, stat);
            if (stat != 2'd0) begin
                $error("JTAG DMI read dmistat=%0d addr=%h", stat, addr);
                $finish;
            end
        end
    endtask

    task jtag_wait_halted;
        integer i;
        reg [31:0] status;
        begin
            for (i = 0; i < 80; i = i + 1) begin
                jtag_dmi_read(DMI_DMSTATUS, status);
                if (status[8])
                    i = 80;
            end
            if (!jtag_hart_halted) begin
                $error("JTAG hart did not halt by cycle %0d", cycle);
                $finish;
            end
        end
    endtask

    task jtag_wait_running;
        integer i;
        reg [31:0] status;
        begin
            for (i = 0; i < 40; i = i + 1) begin
                jtag_dmi_read(DMI_DMSTATUS, status);
                if (!status[8])
                    i = 40;
            end
            if (jtag_hart_halted) begin
                $error("JTAG hart did not resume by cycle %0d", cycle);
                $finish;
            end
        end
    endtask

    task jtag_abstract_read;
        input [15:0] regno;
        output [31:0] data;
        reg [31:0] abstractcs;
        begin
            jtag_dmi_write(DMI_ABSTRACTCS, 32'h0000_0700);
            jtag_dmi_write(DMI_COMMAND, 32'h0022_0000 | {16'h0, regno});
            jtag_dmi_read(DMI_ABSTRACTCS, abstractcs);
            if (abstractcs[10:8] != 3'd0) begin
                $error("JTAG abstract read cmderr regno=%h abstractcs=%h", regno, abstractcs);
                $finish;
            end
            jtag_dmi_read(DMI_DATA0, data);
        end
    endtask

    task ref_dmi_write;
        input [6:0] addr;
        input [31:0] data;
        begin
            ref_dmi_req_addr = addr;
            ref_dmi_req_data = data;
            ref_dmi_req_write = 1'b1;
            ref_dmi_req_en = 1'b1;
            tick();
            ref_dmi_req_en = 1'b0;
            ref_dmi_req_write = 1'b0;
            ref_dmi_req_data = 32'h0;
            tick();
        end
    endtask

    task ref_dmi_read;
        input [6:0] addr;
        output [31:0] data;
        begin
            ref_dmi_req_addr = addr;
            ref_dmi_req_write = 1'b0;
            ref_dmi_req_en = 1'b1;
            #1 data = ref_dmi_resp_data;
            tick();
            ref_dmi_req_en = 1'b0;
            tick();
        end
    endtask

    task ref_wait_halted;
        integer i;
        reg [31:0] status;
        begin
            for (i = 0; i < 80; i = i + 1) begin
                ref_dmi_read(DMI_DMSTATUS, status);
                if (status[8])
                    i = 80;
            end
            if (!ref_hart_halted) begin
                $error("Direct-DMI hart did not halt by cycle %0d", cycle);
                $finish;
            end
        end
    endtask

    task ref_wait_running;
        integer i;
        reg [31:0] status;
        begin
            for (i = 0; i < 40; i = i + 1) begin
                ref_dmi_read(DMI_DMSTATUS, status);
                if (!status[8])
                    i = 40;
            end
            if (ref_hart_halted) begin
                $error("Direct-DMI hart did not resume by cycle %0d", cycle);
                $finish;
            end
        end
    endtask

    task ref_abstract_read;
        input [15:0] regno;
        output [31:0] data;
        reg [31:0] abstractcs;
        begin
            ref_dmi_write(DMI_ABSTRACTCS, 32'h0000_0700);
            ref_dmi_write(DMI_COMMAND, 32'h0022_0000 | {16'h0, regno});
            ref_dmi_read(DMI_ABSTRACTCS, abstractcs);
            if (abstractcs[10:8] != 3'd0) begin
                $error("Direct-DMI abstract read cmderr regno=%h abstractcs=%h", regno, abstractcs);
                $finish;
            end
            ref_dmi_read(DMI_DATA0, data);
        end
    endtask

    reg [31:0] idcode;
    reg [31:0] dtmcs;
    reg [31:0] jtag_x1;
    reg [31:0] ref_x1;
    reg [31:0] jtag_dpc;
    reg [31:0] ref_dpc;
    integer init_i;

    initial begin
        cycle = 0;
        jtag_i_mem_rdata = 32'h0;
        jtag_d_mem_rdata = 32'h0;
        ref_i_mem_rdata = 32'h0;
        ref_d_mem_rdata = 32'h0;
        ref_dmi_req_en = 1'b0;
        ref_dmi_req_addr = 7'h0;
        ref_dmi_req_write = 1'b0;
        ref_dmi_req_data = 32'h0;

        for (init_i = 0; init_i < 64; init_i = init_i + 1)
            imem[init_i] = 32'h0000_0013; // nop
        imem[0] = 32'h1230_0093; // addi x1,x0,0x123
        imem[1] = 32'h0000_0463; // beq x0,x0,+8 -> 0x0c
        imem[2] = 32'h07a0_0493; // wrong path addi x9,x0,0x7a
        imem[3] = 32'h0040_0213; // addi x4,x0,4
        imem[4] = 32'h0011_8193; // addi x3,x3,1

        repeat (3) tick();
        resetn = 1'b1;
        repeat (2) tick();

        jtag_reset_to_rti();
        jtag_read_idcode(idcode);
        if (idcode !== DTM_IDCODE_EXPECTED) begin
            $error("IDCODE mismatch got=%h expected=%h", idcode, DTM_IDCODE_EXPECTED);
            $finish;
        end

        jtag_read_dtmcs(dtmcs);
        if (dtmcs[3:0] !== 4'd1 || dtmcs[9:4] !== 6'd7) begin
            $error("DTMCS mismatch got=%h", dtmcs);
            $finish;
        end

        jtag_dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        jtag_dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        jtag_wait_halted();
        jtag_abstract_read(16'h1001, jtag_x1);
        jtag_abstract_read(16'h07b1, jtag_dpc);

        ref_dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        ref_dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        ref_wait_halted();
        ref_abstract_read(16'h1001, ref_x1);
        ref_abstract_read(16'h07b1, ref_dpc);

        if (jtag_x1 !== ref_x1) begin
            $error("JTAG/direct GPR mismatch jtag_x1=%h ref_x1=%h jtag_dpc=%h ref_dpc=%h",
                   jtag_x1, ref_x1, jtag_dpc, ref_dpc);
            $finish;
        end
        if (jtag_x1 !== 32'h0000_0123) begin
            $error("Unexpected debug values x1=%h dpc=%h", jtag_x1, jtag_dpc);
            $finish;
        end

        jtag_dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        jtag_dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        jtag_wait_running();

        ref_dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        ref_dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        ref_wait_running();

        $display("PASS: JTAG IDCODE=%h DTMCS=%h halt_read_x1=%h direct_x1=%h jtag_dpc=%h direct_dpc=%h jtag_dmi_reads=%0d jtag_dmi_writes=%0d",
                 idcode, dtmcs, jtag_x1, ref_x1, jtag_dpc, ref_dpc, jtag_dmi_reads, jtag_dmi_writes);
        $finish;
    end
endmodule
