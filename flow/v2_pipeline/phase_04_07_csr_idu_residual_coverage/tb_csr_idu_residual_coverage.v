`timescale 1ns / 1ns

`include "def.vh"

module tb_csr_idu_residual_coverage;
    reg clk = 1'b0;
    reg resetn = 1'b0;

    reg  [11:0] csr_raddr;
    wire [31:0] csr_rdata;
    reg         csr_we;
    reg  [11:0] csr_waddr;
    reg  [ 1:0] csr_op;
    reg  [31:0] csr_wdata;
    reg  [31:0] csr_old_val;
    reg         instr_retired;
    reg         trap_enter;
    reg  [31:0] trap_pc;
    reg  [31:0] trap_cause;   // csr.v gained trap_cause/trap_mtval inputs (P2 modernization)
    reg  [31:0] trap_mtval;
    reg         trap_exit;
    reg         irq_external_pulse;
    wire [31:0] mtvec_o;
    wire [31:0] mepc_o;
    wire        irq_pending;

    reg  [31:0] instr;
    wire [ 4:0] rd_idx;
    wire [ 4:0] rs1_idx;
    wire [ 4:0] rs2_idx;
    wire [31:0] imm;
    wire [ 3:0] alu_op;
    wire        alu_b_use_imm;
    wire        rd_we;
    wire [ 2:0] wb_sel;
    wire        is_branch;
    wire        branch_invert;
    wire [ 1:0] br_type;
    wire        is_jal;
    wire        is_jalr;
    wire        is_load;
    wire        is_store;
    wire [ 2:0] ls_funct3;
    wire        is_csr;
    wire [ 1:0] idu_csr_op;
    wire        csr_uses_imm;
    wire [11:0] csr_addr;
    wire [31:0] csr_zimm;
    wire        is_mret;
    wire        is_muldiv;
    wire [ 2:0] md_op;
    wire        md_is_div;
    wire        illegal;

    csr u_csr (
        .clk                (clk),
        .resetn             (resetn),
        .csr_raddr          (csr_raddr),
        .csr_rdata          (csr_rdata),
        .csr_we             (csr_we),
        .csr_waddr          (csr_waddr),
        .csr_op             (csr_op),
        .csr_wdata          (csr_wdata),
        .csr_old_val        (csr_old_val),
        .instr_retired      (instr_retired),
        .trap_enter         (trap_enter),
        .trap_pc            (trap_pc),
        .trap_cause         (trap_cause),
        .trap_mtval         (trap_mtval),
        .trap_exit          (trap_exit),
        .irq_external_pulse (irq_external_pulse),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .mtvec_o            (mtvec_o),
        .mepc_o             (mepc_o),
        .irq_pending        (irq_pending),
        .irq_cause          ()
    );

    idu u_idu (
        .instr        (instr),
        .rd_idx       (rd_idx),
        .rs1_idx      (rs1_idx),
        .rs2_idx      (rs2_idx),
        .imm          (imm),
        .alu_op       (alu_op),
        .alu_b_use_imm(alu_b_use_imm),
        .rd_we        (rd_we),
        .wb_sel       (wb_sel),
        .is_branch    (is_branch),
        .branch_invert(branch_invert),
        .br_type      (br_type),
        .is_jal       (is_jal),
        .is_jalr      (is_jalr),
        .is_load      (is_load),
        .is_store     (is_store),
        .ls_funct3    (ls_funct3),
        .is_csr       (is_csr),
        .csr_op       (idu_csr_op),
        .csr_uses_imm (csr_uses_imm),
        .csr_addr     (csr_addr),
        .csr_zimm     (csr_zimm),
        .is_mret      (is_mret),
        .is_muldiv    (is_muldiv),
        .md_op        (md_op),
        .md_is_div    (md_is_div),
        .illegal      (illegal)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task csr_write;
        input [11:0] addr;
        input [31:0] value;
        begin
            csr_waddr = addr;
            csr_wdata = value;
            csr_old_val = 32'h0;
            csr_op = `CSR_OP_W;
            csr_we = 1'b1;
            tick();
            csr_we = 1'b0;
            tick();
        end
    endtask

    task csr_read_check;
        input [11:0] addr;
        input [31:0] exp;
        input [255:0] label;
        begin
            csr_raddr = addr;
            #1;
            $display("csr read %0s addr=%03x data=%08x", label, addr, csr_rdata);
            if (csr_rdata !== exp) begin
                $display("FAIL: csr read %0s got=%08x expected=%08x", label, csr_rdata, exp);
                $fatal(1);
            end
        end
    endtask

    task decode_check;
        input [31:0] insn;
        input [3:0]  exp_alu;
        input        exp_branch;
        input        exp_invert;
        input [1:0]  exp_br_type;
        input        exp_illegal;
        input [255:0] label;
        begin
            instr = insn;
            #1;
            $display("decode %0s instr=%08x alu=%0d branch=%0b invert=%0b br_type=%0d illegal=%0b",
                     label, insn, alu_op, is_branch, branch_invert, br_type, illegal);
            if (alu_op !== exp_alu || is_branch !== exp_branch ||
                branch_invert !== exp_invert || br_type !== exp_br_type ||
                illegal !== exp_illegal) begin
                $display("FAIL: decode %0s mismatch", label);
                $fatal(1);
            end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        if ($test$plusargs("full_vcd")) begin
            $dumpvars(0, tb_csr_idu_residual_coverage);
        end else begin
            $dumpvars(0, clk, resetn);
            $dumpvars(0, csr_raddr, csr_rdata, csr_we, csr_waddr, csr_op, csr_wdata);
            $dumpvars(0, u_csr.mepc_reg, u_csr.mcause_reg, u_csr.cycle_cnt, u_csr.instret_cnt);
            $dumpvars(0, instr, alu_op, is_branch, branch_invert, br_type, illegal);
        end
        $dumpoff;

        csr_raddr = `CSR_MSTATUS;
        csr_we = 1'b0;
        csr_waddr = `CSR_MSTATUS;
        csr_op = `CSR_OP_W;
        csr_wdata = 32'h0;
        csr_old_val = 32'h0;
        instr_retired = 1'b0;
        trap_enter = 1'b0;
        trap_pc = 32'h0;
        trap_cause = 32'h0;
        trap_mtval = 32'h0;
        trap_exit = 1'b0;
        irq_external_pulse = 1'b0;
        instr = 32'h0000_0013;

        repeat (4) tick();
        resetn = 1'b1;
        $dumpon;

        repeat (4) begin
            instr_retired = 1'b1;
            tick();
            instr_retired = 1'b0;
            tick();
        end

        csr_read_check(`CSR_CYCLEH, 32'h0000_0000, "cycleh");
        csr_read_check(`CSR_INSTRETH, 32'h0000_0000, "instreth");

        csr_write(`CSR_MEPC, 32'h0000_1234);
        csr_read_check(`CSR_MEPC, 32'h0000_1234, "mepc explicit write");

        csr_write(`CSR_MCAUSE, 32'h0000_0002);
        csr_read_check(`CSR_MCAUSE, 32'h0000_0002, "mcause explicit write");

        csr_write(12'h7c1, 32'hfeed_cafe);
        csr_read_check(12'h7c1, 32'h0000_0000, "unsupported csr default write");

        decode_check(32'h0000_000f, `ALU_ADD, 1'b0, 1'b0, 2'b00, 1'b0, "fence");
        decode_check(32'h0000_100f, `ALU_ADD, 1'b0, 1'b0, 2'b00, 1'b0, "fence.i");
        decode_check(32'h0020_6463, `ALU_SLTU, 1'b1, 1'b0, 2'b11, 1'b0, "bltu");
        decode_check(32'h0020_7563, `ALU_SLTU, 1'b1, 1'b1, 2'b11, 1'b0, "bgeu");
        decode_check(32'h0020_3263, `ALU_SEQ,  1'b1, 1'b0, 2'b01, 1'b1, "reserved branch funct3 default");

        repeat (4) tick();
        $dumpoff;
        $display("PASS: CSR/IDU residual coverage completed");
        $finish;
    end

    initial begin
        #20_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
