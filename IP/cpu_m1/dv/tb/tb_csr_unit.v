`timescale 1ns/1ps
`include "def.vh"

module tb_csr_unit;
    reg         clk;
    reg         resetn;
    reg [11:0] csr_raddr;
    wire [31:0] csr_rdata;
    reg         csr_we;
    reg [11:0] csr_waddr;
    reg [1:0]  csr_op;
    reg [31:0] csr_wdata;
    reg [31:0] csr_old_val;
    reg         instr_retired;
    reg         trap_enter;
    reg [31:0] trap_pc;
    reg [31:0] trap_cause;
    reg [31:0] trap_mtval;
    reg         trap_exit;
    reg         irq_external_pulse;
    wire [31:0] mtvec_o;
    wire [31:0] mepc_o;
    wire        irq_pending;
    wire [32*8-1:0] pmp_addr_o;
    wire [ 8*8-1:0] pmp_cfg_o;

    integer vectors;
    integer errors;
    integer i;
    integer addr_i;
    integer op_i;
    integer pat_i;
    integer state_hits [0:3];
    integer arc_hits [0:5];
    reg [1:0] tb_state;
    reg [1:0] prev_tb_state;

    reg        g_mie_meie;
    reg        g_mstatus_mie;
    reg        g_mstatus_mpie;
    localparam [1:0] g_mstatus_mpp = 2'b11;  // M-only hart: MPP read-only WARL=M (ADR-0015)
    reg [31:2] g_mtvec_base;
    reg [31:0] g_mscratch;
    reg [31:0] g_mepc;
    reg [31:0] g_mcause;
    reg [31:0] g_mtval;
    reg        g_ext_pending;
    reg [63:0] g_cycle;
    reg [63:0] g_instret;

    reg [11:0] csr_rw_table [0:6];
    reg [31:0] pattern_table [0:9];

    localparam TB_IDLE       = 2'd0;
    localparam TB_TRAP_ENTER = 2'd1;
    localparam TB_IN_HANDLER = 2'd2;
    localparam TB_MRET       = 2'd3;

    csr dut (
        .clk(clk),
        .resetn(resetn),
        .csr_raddr(csr_raddr),
        .csr_rdata(csr_rdata),
        .csr_we(csr_we),
        .csr_waddr(csr_waddr),
        .csr_op(csr_op),
        .csr_wdata(csr_wdata),
        .csr_old_val(csr_old_val),
        .instr_retired(instr_retired),
        .trap_enter(trap_enter),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),
        .trap_mtval(trap_mtval),
        .trap_exit(trap_exit),
        .irq_external_pulse(irq_external_pulse),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .mtvec_o(mtvec_o),
        .mepc_o(mepc_o),
        .irq_pending(irq_pending),
        .irq_cause(),
        .pmp_addr_o(pmp_addr_o),
        .pmp_cfg_o(pmp_cfg_o)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            prev_tb_state <= TB_IDLE;
        end else begin
            state_hits[tb_state] = state_hits[tb_state] + 1;
            case ({prev_tb_state, tb_state})
                {TB_IDLE,       TB_IDLE}:       arc_hits[0] = arc_hits[0] + 1;
                {TB_IDLE,       TB_TRAP_ENTER}: arc_hits[1] = arc_hits[1] + 1;
                {TB_TRAP_ENTER, TB_IN_HANDLER}: arc_hits[2] = arc_hits[2] + 1;
                {TB_IN_HANDLER, TB_IN_HANDLER}: arc_hits[3] = arc_hits[3] + 1;
                {TB_IN_HANDLER, TB_MRET}:       arc_hits[4] = arc_hits[4] + 1;
                {TB_MRET,       TB_IDLE}:       arc_hits[5] = arc_hits[5] + 1;
                default: ;
            endcase
            prev_tb_state <= tb_state;
        end
    end

    function [31:0] mstatus_value;
        begin
            mstatus_value = {19'b0, g_mstatus_mpp, 3'b0, g_mstatus_mpie,
                             3'b0, g_mstatus_mie, 3'b0};
        end
    endfunction

    function [31:0] csr_model_read;
        input [11:0] addr;
        begin
            case (addr)
                `CSR_MSTATUS : csr_model_read = mstatus_value();
                `CSR_MIE     : csr_model_read = {20'b0, g_mie_meie, 11'b0};
                `CSR_MTVEC   : csr_model_read = {g_mtvec_base, 2'b00};
                `CSR_MSCRATCH: csr_model_read = g_mscratch;
                `CSR_MEPC    : csr_model_read = g_mepc;
                `CSR_MCAUSE  : csr_model_read = g_mcause;
                `CSR_MTVAL   : csr_model_read = g_mtval;
                `CSR_MIP     : csr_model_read = {20'b0, g_ext_pending, 11'b0};
                `CSR_CYCLE   : csr_model_read = g_cycle[31:0];
                `CSR_CYCLEH  : csr_model_read = g_cycle[63:32];
                `CSR_INSTRET : csr_model_read = g_instret[31:0];
                `CSR_INSTRETH: csr_model_read = g_instret[63:32];
                default      : csr_model_read = 32'h0000_0000;
            endcase
        end
    endfunction

    function [31:0] csr_new_value;
        input [1:0]  op;
        input [31:0] old_v;
        input [31:0] data_v;
        begin
            case (op)
                `CSR_OP_W: csr_new_value = data_v;
                `CSR_OP_S: csr_new_value = old_v | data_v;
                `CSR_OP_C: csr_new_value = old_v & ~data_v;
                default:   csr_new_value = old_v;
            endcase
        end
    endfunction

    task model_write;
        input [11:0] addr;
        input [31:0] value;
        begin
            case (addr)
                `CSR_MSTATUS: begin
                    g_mstatus_mie  = value[`MSTATUS_MIE_BIT];
                    g_mstatus_mpie = value[`MSTATUS_MPIE_BIT];
                    // mstatus.MPP read-only WARL=M (ADR-0015): CSR write to MPP ignored
                end
                `CSR_MIE:      g_mie_meie    = value[`MIE_MEIE_BIT];
                `CSR_MTVEC:    g_mtvec_base  = value[31:2];
                `CSR_MSCRATCH: g_mscratch    = value;
                `CSR_MEPC:     g_mepc        = {value[31:1], 1'b0};
                `CSR_MCAUSE:   g_mcause      = value;
                `CSR_MTVAL:    g_mtval       = value;
                default: ;
            endcase
        end
    endtask

    task model_tick;
        input retired;
        begin
            g_cycle = g_cycle + 64'd1;
            if (retired) begin
                g_instret = g_instret + 64'd1;
            end
        end
    endtask

    task check;
        input cond;
        input [8*80-1:0] msg;
        begin
            if (!cond) begin
                errors = errors + 1;
                $error("%0s", msg);
            end
        end
    endtask

    task check_read;
        input [11:0] addr;
        input [8*64-1:0] tag;
        reg [31:0] exp;
        begin
            csr_raddr = addr;
            #1;
            if ((addr == `CSR_CYCLE) || (addr == `CSR_CYCLEH) ||
                (addr == `CSR_INSTRET) || (addr == `CSR_INSTRETH)) begin
                g_cycle = dut.cycle_cnt;
                g_instret = dut.instret_cnt;
            end
            exp = csr_model_read(addr);
            vectors = vectors + 1;
            if (csr_rdata !== exp) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s read addr=%h got=%h exp=%h",
                       vectors, tag, addr, csr_rdata, exp);
            end
        end
    endtask

    task cycle_idle;
        input retired;
        begin
            @(negedge clk);
            csr_we             = 1'b0;
            instr_retired      = retired;
            trap_enter         = 1'b0;
            trap_exit          = 1'b0;
            irq_external_pulse = 1'b0;
            tb_state           = TB_IDLE;
            model_tick(retired);
            @(posedge clk);
            #1;
            instr_retired = 1'b0;
        end
    endtask

    task csr_write_and_check;
        input [11:0] addr;
        input [1:0]  op;
        input [31:0] data;
        input [8*64-1:0] tag;
        reg [31:0] old_v;
        reg [31:0] new_v;
        begin
            old_v = csr_model_read(addr);
            new_v = csr_new_value(op, old_v, data);
            @(negedge clk);
            csr_raddr           = addr;
            csr_we              = 1'b1;
            csr_waddr           = addr;
            csr_op              = op;
            csr_wdata           = data;
            csr_old_val         = old_v;
            instr_retired       = 1'b1;
            trap_enter          = 1'b0;
            trap_exit           = 1'b0;
            irq_external_pulse  = 1'b0;
            tb_state            = TB_IDLE;
            model_tick(1'b1);
            model_write(addr, new_v);
            @(posedge clk);
            #1;
            csr_we        = 1'b0;
            instr_retired = 1'b0;
            check_read(addr, tag);
            check(mtvec_o === csr_model_read(`CSR_MTVEC), "mtvec_o mismatch after csr write");
            check(mepc_o === csr_model_read(`CSR_MEPC), "mepc_o mismatch after csr write");
            check(irq_pending === (g_ext_pending & g_mie_meie & g_mstatus_mie),
                  "irq_pending mismatch after csr write");
        end
    endtask

    task csr_write_mismatch_read;
        input [11:0] waddr;
        input [11:0] raddr;
        input [1:0]  op;
        input [31:0] data;
        input [8*64-1:0] tag;
        reg [31:0] old_v;
        reg [31:0] new_v;
        reg [31:0] exp_r;
        begin
            old_v = csr_model_read(waddr);
            new_v = csr_new_value(op, old_v, data);
            exp_r = csr_model_read(raddr);
            @(negedge clk);
            csr_raddr          = raddr;
            csr_we             = 1'b1;
            csr_waddr          = waddr;
            csr_op             = op;
            csr_wdata          = data;
            csr_old_val        = old_v;
            instr_retired      = 1'b1;
            trap_enter         = 1'b0;
            trap_exit          = 1'b0;
            irq_external_pulse = 1'b0;
            tb_state           = TB_IDLE;
            model_tick(1'b1);
            model_write(waddr, new_v);
            @(posedge clk);
            #1;
            vectors = vectors + 1;
            if (csr_rdata !== exp_r) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s mismatch read got=%h exp=%h",
                       vectors, tag, csr_rdata, exp_r);
            end
            csr_we        = 1'b0;
            instr_retired = 1'b0;
            check_read(waddr, tag);
        end
    endtask

    task trap_enter_and_check;
        input [31:0] pc;
        input [31:0] cause;
        input [31:0] val;
        input [8*64-1:0] tag;
        begin
            @(negedge clk);
            csr_we             = 1'b0;
            instr_retired      = 1'b1;
            trap_enter         = 1'b1;
            trap_exit          = 1'b0;
            trap_pc            = pc;
            trap_cause         = cause;
            trap_mtval         = val;
            irq_external_pulse = 1'b0;
            tb_state           = TB_TRAP_ENTER;
            model_tick(1'b1);
            g_mepc        = pc;
            g_mcause      = cause;
            g_mtval       = val;
            g_mstatus_mpie = g_mstatus_mie;
            g_mstatus_mie  = 1'b0;
            g_ext_pending  = 1'b0;
            @(posedge clk);
            #1;
            trap_enter = 1'b0;
            tb_state   = TB_IN_HANDLER;
            @(negedge clk);
            model_tick(1'b0);
            @(posedge clk);
            #1;
            check_read(`CSR_MEPC, tag);
            check_read(`CSR_MCAUSE, tag);
            check_read(`CSR_MTVAL, tag);
            check_read(`CSR_MSTATUS, tag);
            check_read(`CSR_MIP, tag);
            check(mtvec_o === csr_model_read(`CSR_MTVEC), "mtvec_o mismatch after trap_enter");
            check(mepc_o === csr_model_read(`CSR_MEPC), "mepc_o mismatch after trap_enter");
            check(irq_pending === 1'b0, "irq_pending not cleared by trap_enter");
        end
    endtask

    task trap_exit_and_check;
        input [8*64-1:0] tag;
        begin
            @(negedge clk);
            csr_we             = 1'b0;
            instr_retired      = 1'b1;
            trap_enter         = 1'b0;
            trap_exit          = 1'b1;
            irq_external_pulse = 1'b0;
            tb_state           = TB_MRET;
            model_tick(1'b1);
            g_mstatus_mie  = g_mstatus_mpie;
            g_mstatus_mpie = 1'b1;
            @(posedge clk);
            #1;
            trap_exit = 1'b0;
            tb_state  = TB_IDLE;
            check_read(`CSR_MSTATUS, tag);
            check(irq_pending === (g_ext_pending & g_mie_meie & g_mstatus_mie),
                  "irq_pending mismatch after trap_exit");
        end
    endtask

    task irq_pulse_and_check;
        input [8*64-1:0] tag;
        begin
            @(negedge clk);
            csr_we             = 1'b0;
            instr_retired      = 1'b0;
            trap_enter         = 1'b0;
            trap_exit          = 1'b0;
            irq_external_pulse = 1'b1;
            tb_state           = TB_IDLE;
            model_tick(1'b0);
            g_ext_pending = 1'b1;
            @(posedge clk);
            #1;
            irq_external_pulse = 1'b0;
            check_read(`CSR_MIP, tag);
            check(irq_pending === (g_ext_pending & g_mie_meie & g_mstatus_mie),
                  "irq_pending mismatch after external pulse");
        end
    endtask

    task reset_dut;
        integer k;
        begin
            resetn             = 1'b0;
            csr_raddr          = `CSR_MSTATUS;
            csr_we             = 1'b0;
            csr_waddr          = `CSR_MSTATUS;
            csr_op             = `CSR_OP_W;
            csr_wdata          = 32'h0;
            csr_old_val        = 32'h0;
            instr_retired      = 1'b0;
            trap_enter         = 1'b0;
            trap_pc            = 32'h0;
            trap_cause         = 32'h0;
            trap_mtval         = 32'h0;
            trap_exit          = 1'b0;
            irq_external_pulse = 1'b0;
            tb_state           = TB_IDLE;
            prev_tb_state      = TB_IDLE;

            g_mie_meie     = 1'b0;
            g_mstatus_mie  = 1'b0;
            g_mstatus_mpie = 1'b0;
            g_mtvec_base   = 30'b0;
            g_mscratch     = 32'h0;
            g_mepc         = 32'h0;
            g_mcause       = 32'h0;
            g_mtval        = 32'h0;
            g_ext_pending  = 1'b0;
            g_cycle        = 64'h0;
            g_instret      = 64'h0;

            for (k = 0; k < 4; k = k + 1) begin
                state_hits[k] = 0;
            end
            for (k = 0; k < 6; k = k + 1) begin
                arc_hits[k] = 0;
            end

            repeat (4) @(posedge clk);
            @(negedge clk);
            resetn = 1'b1;
            model_tick(1'b0);
            @(posedge clk);
            #1;
            g_cycle = dut.cycle_cnt;
            g_instret = dut.instret_cnt;
        end
    endtask

    task accelerate_counter_toggle;
        begin
            @(negedge clk);
            dut.cycle_cnt   = 64'h0000_0000_0000_0000;
            dut.instret_cnt = 64'h0000_0000_0000_0000;
            #1;
            dut.cycle_cnt   = 64'hffff_ffff_ffff_ffff;
            dut.instret_cnt = 64'hffff_ffff_ffff_ffff;
            #1;
            dut.cycle_cnt   = 64'h0000_0000_0000_0000;
            dut.instret_cnt = 64'h0000_0000_0000_0000;
            #1;
            dut.cycle_cnt   = 64'haaaa_aaaa_aaaa_aa00;
            dut.instret_cnt = 64'h5555_5555_5555_5500;
            g_cycle         = 64'haaaa_aaaa_aaaa_aa00;
            g_instret       = 64'h5555_5555_5555_5500;
            cycle_idle(1'b1);
            @(negedge clk);
            dut.cycle_cnt   = 64'h5555_5555_5555_5500;
            dut.instret_cnt = 64'haaaa_aaaa_aaaa_aa00;
            g_cycle         = 64'h5555_5555_5555_5500;
            g_instret       = 64'haaaa_aaaa_aaaa_aa00;
            cycle_idle(1'b1);
            check_read(`CSR_CYCLE, "COUNTER_LOW");
            check_read(`CSR_CYCLEH, "COUNTER_HIGH");
            check_read(`CSR_INSTRET, "INSTRET_LOW");
            check_read(`CSR_INSTRETH, "INSTRET_HIGH");
        end
    endtask

    task pulse_reset_for_coverage;
        begin
            @(negedge clk);
            resetn = 1'b0;
            @(negedge clk);
            resetn = 1'b1;
        end
    endtask

    task print_fsm_report;
        begin
            $display("FSM_STATE CSR_IDLE       covered=%0d", state_hits[TB_IDLE]);
            $display("FSM_STATE CSR_TRAP_ENTER covered=%0d", state_hits[TB_TRAP_ENTER]);
            $display("FSM_STATE CSR_IN_HANDLER covered=%0d", state_hits[TB_IN_HANDLER]);
            $display("FSM_STATE CSR_MRET       covered=%0d", state_hits[TB_MRET]);
            $display("FSM_ARC CSR_IDLE->CSR_IDLE             covered=%0d", arc_hits[0]);
            $display("FSM_ARC CSR_IDLE->CSR_TRAP_ENTER       covered=%0d", arc_hits[1]);
            $display("FSM_ARC CSR_TRAP_ENTER->CSR_IN_HANDLER covered=%0d", arc_hits[2]);
            $display("FSM_ARC CSR_IN_HANDLER->CSR_IN_HANDLER covered=%0d", arc_hits[3]);
            $display("FSM_ARC CSR_IN_HANDLER->CSR_MRET       covered=%0d", arc_hits[4]);
            $display("FSM_ARC CSR_MRET->CSR_IDLE             covered=%0d", arc_hits[5]);
        end
    endtask

    initial begin
        vectors = 0;
        errors  = 0;

        csr_rw_table[0] = `CSR_MSTATUS;
        csr_rw_table[1] = `CSR_MIE;
        csr_rw_table[2] = `CSR_MTVEC;
        csr_rw_table[3] = `CSR_MSCRATCH;
        csr_rw_table[4] = `CSR_MEPC;
        csr_rw_table[5] = `CSR_MCAUSE;
        csr_rw_table[6] = `CSR_MTVAL;

        pattern_table[0] = 32'haaaa_aaaa;
        pattern_table[1] = 32'h5555_5555;
        pattern_table[2] = 32'hffff_ffff;
        pattern_table[3] = 32'h0000_0000;
        pattern_table[4] = 32'h0000_0808;
        pattern_table[5] = 32'h0000_0880;
        pattern_table[6] = 32'hffff_fffc;
        pattern_table[7] = 32'h0000_1001;
        pattern_table[8] = 32'h8000_000b;
        pattern_table[9] = 32'h7fff_ffff;

        reset_dut();

        check_read(`CSR_MSTATUS, "RESET");
        check_read(`CSR_MIE, "RESET");
        check_read(`CSR_MTVEC, "RESET");
        check_read(`CSR_MSCRATCH, "RESET");
        check_read(`CSR_MEPC, "RESET");
        check_read(`CSR_MCAUSE, "RESET");
        check_read(`CSR_MTVAL, "RESET");
        check_read(`CSR_MIP, "RESET");
        check_read(12'hf14, "UNKNOWN_MHARTID_ZERO");
        check_read(12'h301, "UNKNOWN_MISA_ZERO");

        for (addr_i = 0; addr_i < 7; addr_i = addr_i + 1) begin
            for (pat_i = 0; pat_i < 10; pat_i = pat_i + 1) begin
                csr_write_and_check(csr_rw_table[addr_i], `CSR_OP_W, pattern_table[pat_i], "CSRRW_PATTERN");
                csr_write_and_check(csr_rw_table[addr_i], `CSR_OP_S, ~pattern_table[pat_i], "CSRRS_PATTERN");
                csr_write_and_check(csr_rw_table[addr_i], `CSR_OP_C, pattern_table[pat_i], "CSRRC_PATTERN");
            end
        end

        csr_write_and_check(`CSR_MTVEC, `CSR_OP_W, 32'haaaa_aaa3, "MTVEC_MODE_MASK_A");
        csr_write_and_check(`CSR_MTVEC, `CSR_OP_W, 32'h5555_5557, "MTVEC_MODE_MASK_B");
        csr_write_and_check(`CSR_MEPC,  `CSR_OP_W, 32'haaaa_aaab, "MEPC_ALIGN_MASK_A");
        csr_write_and_check(`CSR_MEPC,  `CSR_OP_W, 32'h5555_5555, "MEPC_ALIGN_MASK_B");
        csr_write_and_check(`CSR_MIP,   `CSR_OP_W, 32'hffff_ffff, "MIP_WRITE_IGNORED");
        csr_write_and_check(`CSR_CYCLE, `CSR_OP_W, 32'hffff_ffff, "CYCLE_WRITE_IGNORED");
        csr_write_and_check(`CSR_INSTRET, `CSR_OP_W, 32'hffff_ffff, "INSTRET_WRITE_IGNORED");
        csr_write_and_check(12'h7c0, `CSR_OP_W, 32'hffff_ffff, "UNKNOWN_WRITE_IGNORED");
        csr_write_and_check(12'h338, `CSR_OP_W, 32'h0000_0000, "UNKNOWN_WADDR_BITS_3_5_A");
        csr_write_and_check(12'h360, `CSR_OP_W, 32'h0000_0000, "UNKNOWN_WADDR_BITS_3_5_B");
        csr_write_mismatch_read(`CSR_MSCRATCH, `CSR_MTVEC, `CSR_OP_W, 32'h1357_9bdf, "WRITE_READ_MISMATCH");
        csr_write_and_check(`CSR_MSCRATCH, 2'b00, 32'h2468_ace0, "CSR_OP_DEFAULT_HOLD");
        check_read(12'h328, "UNKNOWN_RADDR_BITS_3_5_A");
        check_read(12'h360, "UNKNOWN_RADDR_BITS_3_5_B");

        csr_write_and_check(`CSR_MSTATUS, `CSR_OP_W, 32'h0000_0008, "ENABLE_MIE");
        csr_write_and_check(`CSR_MIE,     `CSR_OP_W, 32'h0000_0800, "ENABLE_MEIE");
        irq_pulse_and_check("IRQ_MASKED_UNMASKED_SET");
        check(irq_pending === 1'b1, "irq_pending should assert when ext_pending/MIE/MEIE are set");
        csr_write_and_check(`CSR_MIE,     `CSR_OP_C, 32'h0000_0800, "MASK_MEIE_CLEAR_PENDING_HELD");
        check(irq_pending === 1'b0, "irq_pending should clear when MEIE is masked");
        csr_write_and_check(`CSR_MIE,     `CSR_OP_S, 32'h0000_0800, "UNMASK_MEIE_PENDING_HELD");
        check(irq_pending === 1'b1, "irq_pending should reassert when MEIE is unmasked");

        trap_enter_and_check(32'haaaa_aaa0, `MCAUSE_EXT_IRQ, 32'h5555_5555, "TRAP_IRQ");
        trap_exit_and_check("MRET_RESTORE_FROM_IRQ");
        irq_pulse_and_check("IRQ_SECOND_PULSE");

        trap_enter_and_check(32'h5555_5554, `MCAUSE_ILLEGAL_INSTRUCTION, 32'haaaa_aaaa, "TRAP_ILLEGAL");
        irq_pulse_and_check("IRQ_WHILE_MIE_DISABLED_IN_HANDLER");
        trap_exit_and_check("MRET_RESTORE_FROM_ILLEGAL");
        trap_enter_and_check(32'h0000_1001, `MCAUSE_BREAKPOINT, 32'h0000_0001, "TRAP_ODD_PC_REACHABILITY");
        trap_exit_and_check("MRET_RESTORE_FROM_ODD_PC");

        for (i = 0; i < 32; i = i + 1) begin
            trap_enter_and_check((32'h0000_0001 << i) & 32'hffff_fffe,
                                 32'h0000_0001 << i,
                                 32'hffff_ffff ^ (32'h0000_0001 << i),
                                 "TRAP_WALKING_ONE_ZERO");
            trap_exit_and_check("MRET_WALKING");
        end

        for (op_i = 0; op_i < 3; op_i = op_i + 1) begin
            for (i = 0; i < 32; i = i + 1) begin
                csr_write_and_check(`CSR_MSCRATCH, op_i[1:0] + 2'b01, 32'h0000_0001 << i, "MSCRATCH_WALK");
                csr_write_and_check(`CSR_MTVAL,    op_i[1:0] + 2'b01, ~(32'h0000_0001 << i), "MTVAL_WALK");
                csr_write_and_check(`CSR_MCAUSE,   op_i[1:0] + 2'b01, 32'h8000_0000 >> i, "MCAUSE_WALK");
                csr_write_and_check(`CSR_MEPC,     op_i[1:0] + 2'b01, 32'hffff_fffe ^ (32'h0000_0001 << i), "MEPC_WALK");
                csr_write_and_check(`CSR_MTVEC,    op_i[1:0] + 2'b01, 32'hffff_fffc ^ (32'h0000_0004 << (i % 30)), "MTVEC_WALK");
            end
        end

        accelerate_counter_toggle();

        repeat (16) cycle_idle(1'b0);

        print_fsm_report();
        pulse_reset_for_coverage();
        @(posedge clk);
        if (errors == 0) begin
            $display("PASS: csr unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: csr unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
