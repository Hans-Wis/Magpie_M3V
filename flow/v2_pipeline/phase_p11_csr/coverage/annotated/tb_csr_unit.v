//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_csr_unit;
 000878     reg         clk;
%000002     reg         resetn;
~000270     reg [11:0] csr_raddr;
 000259     wire [31:0] csr_rdata;
 000706     reg         csr_we;
~000195     reg [11:0] csr_waddr;
 000074     reg [1:0]  csr_op;
 000289     reg [31:0] csr_wdata;
 000190     reg [31:0] csr_old_val;
 000710     reg         instr_retired;
 000035     reg         trap_enter;
%000002     reg [31:0] trap_pc;
%000002     reg [31:0] trap_cause;
%000003     reg [31:0] trap_mtval;
 000035     reg         trap_exit;
%000003     reg         irq_external_pulse;
~000010     wire [31:0] mtvec_o;
~000012     wire [31:0] mepc_o;
%000004     wire        irq_pending;
        
            integer vectors;
            integer errors;
            integer i;
            integer addr_i;
            integer op_i;
            integer pat_i;
            integer state_hits [0:3];
            integer arc_hits [0:5];
 000070     reg [1:0] tb_state;
 000037     reg [1:0] prev_tb_state;
        
%000009     reg        g_mie_meie;
 000042     reg        g_mstatus_mie;
%000008     reg        g_mstatus_mpie;
            localparam [1:0] g_mstatus_mpp = 2'b11;  // M-only hart: MPP read-only WARL=M (ADR-0015)
~000010     reg [31:2] g_mtvec_base;
~000011     reg [31:0] g_mscratch;
~000012     reg [31:0] g_mepc;
~000012     reg [31:0] g_mcause;
 000012     reg [31:0] g_mtval;
%000003     reg        g_ext_pending;
~000418     reg [63:0] g_cycle;
~000390     reg [63:0] g_instret;
        
%000001     reg [11:0] csr_rw_table [0:6];
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
                .mtvec_o(mtvec_o),
                .mepc_o(mepc_o),
                .irq_pending(irq_pending)
            );
        
%000000     initial begin
%000000         clk = 1'b0;
~001755         forever #5 clk = ~clk;
            end
        
 000878     always @(posedge clk) begin
~000873         if (!resetn) begin
%000005             prev_tb_state <= TB_IDLE;
 000873         end else begin
 000873             state_hits[tb_state] = state_hits[tb_state] + 1;
 000873             case ({prev_tb_state, tb_state})
 000730                 {TB_IDLE,       TB_IDLE}:       arc_hits[0] = arc_hits[0] + 1;
%000002                 {TB_IDLE,       TB_TRAP_ENTER}: arc_hits[1] = arc_hits[1] + 1;
 000035                 {TB_TRAP_ENTER, TB_IN_HANDLER}: arc_hits[2] = arc_hits[2] + 1;
 000035                 {TB_IN_HANDLER, TB_IN_HANDLER}: arc_hits[3] = arc_hits[3] + 1;
 000034                 {TB_IN_HANDLER, TB_MRET}:       arc_hits[4] = arc_hits[4] + 1;
%000002                 {TB_MRET,       TB_IDLE}:       arc_hits[5] = arc_hits[5] + 1;
 000035                 default: ;
                    endcase
 000873             prev_tb_state <= tb_state;
                end
            end
        
 000133     function [31:0] mstatus_value;
 000133         begin
 000133             mstatus_value = {19'b0, g_mstatus_mpp, 3'b0, g_mstatus_mpie,
 000133                              3'b0, g_mstatus_mie, 3'b0};
                end
            endfunction
        
 003122     function [31:0] csr_model_read;
                input [11:0] addr;
 003122         begin
 003122             case (addr)
 000133                 `CSR_MSTATUS : csr_model_read = mstatus_value();
 000067                 `CSR_MIE     : csr_model_read = {20'b0, g_mie_meie, 11'b0};
 000998                 `CSR_MTVEC   : csr_model_read = {g_mtvec_base, 2'b00};
 000257                 `CSR_MSCRATCH: csr_model_read = g_mscratch;
 001032                 `CSR_MEPC    : csr_model_read = g_mepc;
 000288                 `CSR_MCAUSE  : csr_model_read = g_mcause;
 000288                 `CSR_MTVAL   : csr_model_read = g_mtval;
 000041                 `CSR_MIP     : csr_model_read = {20'b0, g_ext_pending, 11'b0};
%000003                 `CSR_CYCLE   : csr_model_read = g_cycle[31:0];
%000001                 `CSR_CYCLEH  : csr_model_read = g_cycle[63:32];
%000003                 `CSR_INSTRET : csr_model_read = g_instret[31:0];
%000001                 `CSR_INSTRETH: csr_model_read = g_instret[63:32];
 000010                 default      : csr_model_read = 32'h0000_0000;
                    endcase
                end
            endfunction
        
 000706     function [31:0] csr_new_value;
                input [1:0]  op;
                input [31:0] old_v;
                input [31:0] data_v;
 000706         begin
 000706             case (op)
 000243                 `CSR_OP_W: csr_new_value = data_v;
 000231                 `CSR_OP_S: csr_new_value = old_v | data_v;
 000231                 `CSR_OP_C: csr_new_value = old_v & ~data_v;
%000001                 default:   csr_new_value = old_v;
                    endcase
                end
            endfunction
        
 000706     task model_write;
                input [11:0] addr;
                input [31:0] value;
 000706         begin
 000706             case (addr)
 000031                 `CSR_MSTATUS: begin
 000031                     g_mstatus_mie  = value[`MSTATUS_MIE_BIT];
 000031                     g_mstatus_mpie = value[`MSTATUS_MPIE_BIT];
                            // mstatus.MPP read-only WARL=M (ADR-0015): CSR write to MPP ignored
                        end
 000033                 `CSR_MIE:      g_mie_meie    = value[`MIE_MEIE_BIT];
 000128                 `CSR_MTVEC:    g_mtvec_base  = value[31:2];
 000128                 `CSR_MSCRATCH: g_mscratch    = value;
 000128                 `CSR_MEPC:     g_mepc        = {value[31:1], 1'b0};
 000126                 `CSR_MCAUSE:   g_mcause      = value;
 000126                 `CSR_MTVAL:    g_mtval       = value;
%000006                 default: ;
                    endcase
                end
            endtask
        
 000833     task model_tick;
                input retired;
 000833         begin
 000833             g_cycle = g_cycle + 64'd1;
 000778             if (retired) begin
 000778                 g_instret = g_instret + 64'd1;
                    end
                end
            endtask
        
 002261     task check;
                input cond;
                input [8*80-1:0] msg;
 002261         begin
~002261             if (!cond) begin
                        errors = errors + 1;
                        $error("%0s", msg);
                    end
                end
            endtask
        
 000935     task check_read;
                input [11:0] addr;
                input [8*64-1:0] tag;
 000935         reg [31:0] exp;
 000935         begin
 000935             csr_raddr = addr;
 000935             #1;
~000929             if ((addr == `CSR_CYCLE) || (addr == `CSR_CYCLEH) ||
~000929                 (addr == `CSR_INSTRET) || (addr == `CSR_INSTRETH)) begin
%000006                 g_cycle = dut.cycle_cnt;
%000006                 g_instret = dut.instret_cnt;
                    end
 000935             exp = csr_model_read(addr);
 000935             vectors = vectors + 1;
 000935             if (csr_rdata !== exp) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s read addr=%h got=%h exp=%h",
                               vectors, tag, addr, csr_rdata, exp);
                    end
                end
            endtask
        
 000018     task cycle_idle;
                input retired;
 000018         begin
 000018             @(negedge clk);
 000018             csr_we             = 1'b0;
 000018             instr_retired      = retired;
 000018             trap_enter         = 1'b0;
 000018             trap_exit          = 1'b0;
 000018             irq_external_pulse = 1'b0;
 000018             tb_state           = TB_IDLE;
 000018             model_tick(retired);
 000018             @(posedge clk);
 000018             #1;
 000018             instr_retired = 1'b0;
                end
            endtask
        
 000705     task csr_write_and_check;
                input [11:0] addr;
                input [1:0]  op;
                input [31:0] data;
                input [8*64-1:0] tag;
 000705         reg [31:0] old_v;
 000705         reg [31:0] new_v;
 000705         begin
 000705             old_v = csr_model_read(addr);
 000705             new_v = csr_new_value(op, old_v, data);
 000705             @(negedge clk);
 000705             csr_raddr           = addr;
 000705             csr_we              = 1'b1;
 000705             csr_waddr           = addr;
 000705             csr_op              = op;
 000705             csr_wdata           = data;
 000705             csr_old_val         = old_v;
 000705             instr_retired       = 1'b1;
 000705             trap_enter          = 1'b0;
 000705             trap_exit           = 1'b0;
 000705             irq_external_pulse  = 1'b0;
 000705             tb_state            = TB_IDLE;
 000705             model_tick(1'b1);
 000705             model_write(addr, new_v);
 000705             @(posedge clk);
 000705             #1;
 000705             csr_we        = 1'b0;
 000705             instr_retired = 1'b0;
 000705             check_read(addr, tag);
 000705             check(mtvec_o === csr_model_read(`CSR_MTVEC), "mtvec_o mismatch after csr write");
 000705             check(mepc_o === csr_model_read(`CSR_MEPC), "mepc_o mismatch after csr write");
~000705             check(irq_pending === (g_ext_pending & g_mie_meie & g_mstatus_mie),
 000705                   "irq_pending mismatch after csr write");
                end
            endtask
        
%000001     task csr_write_mismatch_read;
                input [11:0] waddr;
                input [11:0] raddr;
                input [1:0]  op;
                input [31:0] data;
                input [8*64-1:0] tag;
%000001         reg [31:0] old_v;
%000001         reg [31:0] new_v;
%000001         reg [31:0] exp_r;
%000001         begin
%000001             old_v = csr_model_read(waddr);
%000001             new_v = csr_new_value(op, old_v, data);
%000001             exp_r = csr_model_read(raddr);
%000001             @(negedge clk);
%000001             csr_raddr          = raddr;
%000001             csr_we             = 1'b1;
%000001             csr_waddr          = waddr;
%000001             csr_op             = op;
%000001             csr_wdata          = data;
%000001             csr_old_val        = old_v;
%000001             instr_retired      = 1'b1;
%000001             trap_enter         = 1'b0;
%000001             trap_exit          = 1'b0;
%000001             irq_external_pulse = 1'b0;
%000001             tb_state           = TB_IDLE;
%000001             model_tick(1'b1);
%000001             model_write(waddr, new_v);
%000001             @(posedge clk);
%000001             #1;
%000001             vectors = vectors + 1;
%000001             if (csr_rdata !== exp_r) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s mismatch read got=%h exp=%h",
                               vectors, tag, csr_rdata, exp_r);
                    end
%000001             csr_we        = 1'b0;
%000001             instr_retired = 1'b0;
%000001             check_read(waddr, tag);
                end
            endtask
        
 000035     task trap_enter_and_check;
                input [31:0] pc;
                input [31:0] cause;
                input [31:0] val;
                input [8*64-1:0] tag;
 000035         begin
 000035             @(negedge clk);
 000035             csr_we             = 1'b0;
 000035             instr_retired      = 1'b1;
 000035             trap_enter         = 1'b1;
 000035             trap_exit          = 1'b0;
 000035             trap_pc            = pc;
 000035             trap_cause         = cause;
 000035             trap_mtval         = val;
 000035             irq_external_pulse = 1'b0;
 000035             tb_state           = TB_TRAP_ENTER;
 000035             model_tick(1'b1);
 000035             g_mepc        = pc;
 000035             g_mcause      = cause;
 000035             g_mtval       = val;
 000035             g_mstatus_mpie = g_mstatus_mie;
 000035             g_mstatus_mie  = 1'b0;
 000035             g_ext_pending  = 1'b0;
 000035             @(posedge clk);
 000035             #1;
 000035             trap_enter = 1'b0;
 000035             tb_state   = TB_IN_HANDLER;
 000035             @(negedge clk);
 000035             model_tick(1'b0);
 000035             @(posedge clk);
 000035             #1;
 000035             check_read(`CSR_MEPC, tag);
 000035             check_read(`CSR_MCAUSE, tag);
 000035             check_read(`CSR_MTVAL, tag);
 000035             check_read(`CSR_MSTATUS, tag);
 000035             check_read(`CSR_MIP, tag);
 000035             check(mtvec_o === csr_model_read(`CSR_MTVEC), "mtvec_o mismatch after trap_enter");
 000035             check(mepc_o === csr_model_read(`CSR_MEPC), "mepc_o mismatch after trap_enter");
 000035             check(irq_pending === 1'b0, "irq_pending not cleared by trap_enter");
                end
            endtask
        
 000035     task trap_exit_and_check;
                input [8*64-1:0] tag;
 000035         begin
 000035             @(negedge clk);
 000035             csr_we             = 1'b0;
 000035             instr_retired      = 1'b1;
 000035             trap_enter         = 1'b0;
 000035             trap_exit          = 1'b1;
 000035             irq_external_pulse = 1'b0;
 000035             tb_state           = TB_MRET;
 000035             model_tick(1'b1);
 000035             g_mstatus_mie  = g_mstatus_mpie;
 000035             g_mstatus_mpie = 1'b1;
 000035             @(posedge clk);
 000035             #1;
 000035             trap_exit = 1'b0;
 000035             tb_state  = TB_IDLE;
 000035             check_read(`CSR_MSTATUS, tag);
~000035             check(irq_pending === (g_ext_pending & g_mie_meie & g_mstatus_mie),
 000035                   "irq_pending mismatch after trap_exit");
                end
            endtask
        
%000003     task irq_pulse_and_check;
                input [8*64-1:0] tag;
%000003         begin
%000003             @(negedge clk);
%000003             csr_we             = 1'b0;
%000003             instr_retired      = 1'b0;
%000003             trap_enter         = 1'b0;
%000003             trap_exit          = 1'b0;
%000003             irq_external_pulse = 1'b1;
%000003             tb_state           = TB_IDLE;
%000003             model_tick(1'b0);
%000003             g_ext_pending = 1'b1;
%000003             @(posedge clk);
%000003             #1;
%000003             irq_external_pulse = 1'b0;
%000003             check_read(`CSR_MIP, tag);
%000003             check(irq_pending === (g_ext_pending & g_mie_meie & g_mstatus_mie),
%000003                   "irq_pending mismatch after external pulse");
                end
            endtask
        
%000001     task reset_dut;
%000001         integer k;
%000001         begin
%000001             resetn             = 1'b0;
%000001             csr_raddr          = `CSR_MSTATUS;
%000001             csr_we             = 1'b0;
%000001             csr_waddr          = `CSR_MSTATUS;
%000001             csr_op             = `CSR_OP_W;
%000001             csr_wdata          = 32'h0;
%000001             csr_old_val        = 32'h0;
%000001             instr_retired      = 1'b0;
%000001             trap_enter         = 1'b0;
%000001             trap_pc            = 32'h0;
%000001             trap_cause         = 32'h0;
%000001             trap_mtval         = 32'h0;
%000001             trap_exit          = 1'b0;
%000001             irq_external_pulse = 1'b0;
%000001             tb_state           = TB_IDLE;
%000001             prev_tb_state      = TB_IDLE;
        
%000001             g_mie_meie     = 1'b0;
%000001             g_mstatus_mie  = 1'b0;
%000001             g_mstatus_mpie = 1'b0;
%000001             g_mtvec_base   = 30'b0;
%000001             g_mscratch     = 32'h0;
%000001             g_mepc         = 32'h0;
%000001             g_mcause       = 32'h0;
%000001             g_mtval        = 32'h0;
%000001             g_ext_pending  = 1'b0;
%000001             g_cycle        = 64'h0;
%000001             g_instret      = 64'h0;
        
%000004             for (k = 0; k < 4; k = k + 1) begin
%000004                 state_hits[k] = 0;
                    end
%000006             for (k = 0; k < 6; k = k + 1) begin
%000006                 arc_hits[k] = 0;
                    end
        
%000004             repeat (4) @(posedge clk);
%000001             @(negedge clk);
%000001             resetn = 1'b1;
%000001             model_tick(1'b0);
%000001             @(posedge clk);
%000001             #1;
%000001             g_cycle = dut.cycle_cnt;
%000001             g_instret = dut.instret_cnt;
                end
            endtask
        
%000001     task accelerate_counter_toggle;
%000001         begin
%000001             @(negedge clk);
%000001             dut.cycle_cnt   = 64'h0000_0000_0000_0000;
%000001             dut.instret_cnt = 64'h0000_0000_0000_0000;
%000001             #1;
%000001             dut.cycle_cnt   = 64'hffff_ffff_ffff_ffff;
%000001             dut.instret_cnt = 64'hffff_ffff_ffff_ffff;
%000001             #1;
%000001             dut.cycle_cnt   = 64'h0000_0000_0000_0000;
%000001             dut.instret_cnt = 64'h0000_0000_0000_0000;
%000001             #1;
%000001             dut.cycle_cnt   = 64'haaaa_aaaa_aaaa_aa00;
%000001             dut.instret_cnt = 64'h5555_5555_5555_5500;
%000001             g_cycle         = 64'haaaa_aaaa_aaaa_aa00;
%000001             g_instret       = 64'h5555_5555_5555_5500;
%000001             cycle_idle(1'b1);
%000001             @(negedge clk);
%000001             dut.cycle_cnt   = 64'h5555_5555_5555_5500;
%000001             dut.instret_cnt = 64'haaaa_aaaa_aaaa_aa00;
%000001             g_cycle         = 64'h5555_5555_5555_5500;
%000001             g_instret       = 64'haaaa_aaaa_aaaa_aa00;
%000001             cycle_idle(1'b1);
%000001             check_read(`CSR_CYCLE, "COUNTER_LOW");
%000001             check_read(`CSR_CYCLEH, "COUNTER_HIGH");
%000001             check_read(`CSR_INSTRET, "INSTRET_LOW");
%000001             check_read(`CSR_INSTRETH, "INSTRET_HIGH");
                end
            endtask
        
%000001     task pulse_reset_for_coverage;
%000001         begin
%000001             @(negedge clk);
%000001             resetn = 1'b0;
%000001             @(negedge clk);
%000001             resetn = 1'b1;
                end
            endtask
        
%000001     task print_fsm_report;
%000001         begin
%000001             $display("FSM_STATE CSR_IDLE       covered=%0d", state_hits[TB_IDLE]);
%000001             $display("FSM_STATE CSR_TRAP_ENTER covered=%0d", state_hits[TB_TRAP_ENTER]);
%000001             $display("FSM_STATE CSR_IN_HANDLER covered=%0d", state_hits[TB_IN_HANDLER]);
%000001             $display("FSM_STATE CSR_MRET       covered=%0d", state_hits[TB_MRET]);
%000001             $display("FSM_ARC CSR_IDLE->CSR_IDLE             covered=%0d", arc_hits[0]);
%000001             $display("FSM_ARC CSR_IDLE->CSR_TRAP_ENTER       covered=%0d", arc_hits[1]);
%000001             $display("FSM_ARC CSR_TRAP_ENTER->CSR_IN_HANDLER covered=%0d", arc_hits[2]);
%000001             $display("FSM_ARC CSR_IN_HANDLER->CSR_IN_HANDLER covered=%0d", arc_hits[3]);
%000001             $display("FSM_ARC CSR_IN_HANDLER->CSR_MRET       covered=%0d", arc_hits[4]);
%000001             $display("FSM_ARC CSR_MRET->CSR_IDLE             covered=%0d", arc_hits[5]);
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors  = 0;
        
%000001         csr_rw_table[0] = `CSR_MSTATUS;
%000001         csr_rw_table[1] = `CSR_MIE;
%000001         csr_rw_table[2] = `CSR_MTVEC;
%000001         csr_rw_table[3] = `CSR_MSCRATCH;
%000001         csr_rw_table[4] = `CSR_MEPC;
%000001         csr_rw_table[5] = `CSR_MCAUSE;
%000001         csr_rw_table[6] = `CSR_MTVAL;
        
%000001         pattern_table[0] = 32'haaaa_aaaa;
%000001         pattern_table[1] = 32'h5555_5555;
%000001         pattern_table[2] = 32'hffff_ffff;
%000001         pattern_table[3] = 32'h0000_0000;
%000001         pattern_table[4] = 32'h0000_0808;
%000001         pattern_table[5] = 32'h0000_0880;
%000001         pattern_table[6] = 32'hffff_fffc;
%000001         pattern_table[7] = 32'h0000_1001;
%000001         pattern_table[8] = 32'h8000_000b;
%000001         pattern_table[9] = 32'h7fff_ffff;
        
%000001         reset_dut();
        
%000001         check_read(`CSR_MSTATUS, "RESET");
%000001         check_read(`CSR_MIE, "RESET");
%000001         check_read(`CSR_MTVEC, "RESET");
%000001         check_read(`CSR_MSCRATCH, "RESET");
%000001         check_read(`CSR_MEPC, "RESET");
%000001         check_read(`CSR_MCAUSE, "RESET");
%000001         check_read(`CSR_MTVAL, "RESET");
%000001         check_read(`CSR_MIP, "RESET");
%000001         check_read(12'hf14, "UNKNOWN_MHARTID_ZERO");
%000001         check_read(12'h301, "UNKNOWN_MISA_ZERO");
        
%000007         for (addr_i = 0; addr_i < 7; addr_i = addr_i + 1) begin
~000070             for (pat_i = 0; pat_i < 10; pat_i = pat_i + 1) begin
 000070                 csr_write_and_check(csr_rw_table[addr_i], `CSR_OP_W, pattern_table[pat_i], "CSRRW_PATTERN");
 000070                 csr_write_and_check(csr_rw_table[addr_i], `CSR_OP_S, ~pattern_table[pat_i], "CSRRS_PATTERN");
 000070                 csr_write_and_check(csr_rw_table[addr_i], `CSR_OP_C, pattern_table[pat_i], "CSRRC_PATTERN");
                    end
                end
        
%000001         csr_write_and_check(`CSR_MTVEC, `CSR_OP_W, 32'haaaa_aaa3, "MTVEC_MODE_MASK_A");
%000001         csr_write_and_check(`CSR_MTVEC, `CSR_OP_W, 32'h5555_5557, "MTVEC_MODE_MASK_B");
%000001         csr_write_and_check(`CSR_MEPC,  `CSR_OP_W, 32'haaaa_aaab, "MEPC_ALIGN_MASK_A");
%000001         csr_write_and_check(`CSR_MEPC,  `CSR_OP_W, 32'h5555_5555, "MEPC_ALIGN_MASK_B");
%000001         csr_write_and_check(`CSR_MIP,   `CSR_OP_W, 32'hffff_ffff, "MIP_WRITE_IGNORED");
%000001         csr_write_and_check(`CSR_CYCLE, `CSR_OP_W, 32'hffff_ffff, "CYCLE_WRITE_IGNORED");
%000001         csr_write_and_check(`CSR_INSTRET, `CSR_OP_W, 32'hffff_ffff, "INSTRET_WRITE_IGNORED");
%000001         csr_write_and_check(12'h7c0, `CSR_OP_W, 32'hffff_ffff, "UNKNOWN_WRITE_IGNORED");
%000001         csr_write_and_check(12'h338, `CSR_OP_W, 32'h0000_0000, "UNKNOWN_WADDR_BITS_3_5_A");
%000001         csr_write_and_check(12'h360, `CSR_OP_W, 32'h0000_0000, "UNKNOWN_WADDR_BITS_3_5_B");
%000001         csr_write_mismatch_read(`CSR_MSCRATCH, `CSR_MTVEC, `CSR_OP_W, 32'h1357_9bdf, "WRITE_READ_MISMATCH");
%000001         csr_write_and_check(`CSR_MSCRATCH, 2'b00, 32'h2468_ace0, "CSR_OP_DEFAULT_HOLD");
%000001         check_read(12'h328, "UNKNOWN_RADDR_BITS_3_5_A");
%000001         check_read(12'h360, "UNKNOWN_RADDR_BITS_3_5_B");
        
%000001         csr_write_and_check(`CSR_MSTATUS, `CSR_OP_W, 32'h0000_0008, "ENABLE_MIE");
%000001         csr_write_and_check(`CSR_MIE,     `CSR_OP_W, 32'h0000_0800, "ENABLE_MEIE");
%000001         irq_pulse_and_check("IRQ_MASKED_UNMASKED_SET");
%000001         check(irq_pending === 1'b1, "irq_pending should assert when ext_pending/MIE/MEIE are set");
%000001         csr_write_and_check(`CSR_MIE,     `CSR_OP_C, 32'h0000_0800, "MASK_MEIE_CLEAR_PENDING_HELD");
%000001         check(irq_pending === 1'b0, "irq_pending should clear when MEIE is masked");
%000001         csr_write_and_check(`CSR_MIE,     `CSR_OP_S, 32'h0000_0800, "UNMASK_MEIE_PENDING_HELD");
%000001         check(irq_pending === 1'b1, "irq_pending should reassert when MEIE is unmasked");
        
%000001         trap_enter_and_check(32'haaaa_aaa0, `MCAUSE_EXT_IRQ, 32'h5555_5555, "TRAP_IRQ");
%000001         trap_exit_and_check("MRET_RESTORE_FROM_IRQ");
%000001         irq_pulse_and_check("IRQ_SECOND_PULSE");
        
%000001         trap_enter_and_check(32'h5555_5554, `MCAUSE_ILLEGAL_INSTRUCTION, 32'haaaa_aaaa, "TRAP_ILLEGAL");
%000001         irq_pulse_and_check("IRQ_WHILE_MIE_DISABLED_IN_HANDLER");
%000001         trap_exit_and_check("MRET_RESTORE_FROM_ILLEGAL");
%000001         trap_enter_and_check(32'h0000_1001, `MCAUSE_BREAKPOINT, 32'h0000_0001, "TRAP_ODD_PC_REACHABILITY");
%000001         trap_exit_and_check("MRET_RESTORE_FROM_ODD_PC");
        
~000032         for (i = 0; i < 32; i = i + 1) begin
 000032             trap_enter_and_check((32'h0000_0001 << i) & 32'hffff_fffe,
 000032                                  32'h0000_0001 << i,
 000032                                  32'hffff_ffff ^ (32'h0000_0001 << i),
 000032                                  "TRAP_WALKING_ONE_ZERO");
 000032             trap_exit_and_check("MRET_WALKING");
                end
        
%000003         for (op_i = 0; op_i < 3; op_i = op_i + 1) begin
~000096             for (i = 0; i < 32; i = i + 1) begin
 000096                 csr_write_and_check(`CSR_MSCRATCH, op_i[1:0] + 2'b01, 32'h0000_0001 << i, "MSCRATCH_WALK");
 000096                 csr_write_and_check(`CSR_MTVAL,    op_i[1:0] + 2'b01, ~(32'h0000_0001 << i), "MTVAL_WALK");
 000096                 csr_write_and_check(`CSR_MCAUSE,   op_i[1:0] + 2'b01, 32'h8000_0000 >> i, "MCAUSE_WALK");
 000096                 csr_write_and_check(`CSR_MEPC,     op_i[1:0] + 2'b01, 32'hffff_fffe ^ (32'h0000_0001 << i), "MEPC_WALK");
 000096                 csr_write_and_check(`CSR_MTVEC,    op_i[1:0] + 2'b01, 32'hffff_fffc ^ (32'h0000_0004 << (i % 30)), "MTVEC_WALK");
                    end
                end
        
%000001         accelerate_counter_toggle();
        
~000016         repeat (16) cycle_idle(1'b0);
        
%000001         print_fsm_report();
%000001         pulse_reset_for_coverage();
%000001         @(posedge clk);
%000001         if (errors == 0) begin
%000001             $display("PASS: csr unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: csr unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
