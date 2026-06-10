//      // verilator_coverage annotation
        `timescale 1ns / 1ns
        
        module tb_random_lockstep;
~001315     reg         clk = 1'b0;
%000005     reg         resetn = 1'b0;
%000005     wire        trap;
~000213     wire [31:0] i_mem_addr;
 000036     wire        i_mem_en;
 000134     reg  [31:0] i_mem_rdata;
 000050     wire        d_mem_valid;
 000102     wire [31:0] d_mem_addr;
 000080     wire [31:0] d_mem_wdata;
 000020     wire [ 3:0] d_mem_wstrb;
 000021     reg  [31:0] d_mem_rdata;
~000200     wire [31:0] dbg_pc;
~000136     wire [31:0] dbg_instr;
~000195     wire [ 2:0] dbg_state;
        
            localparam MEM_SIZE = 4096;
            reg [31:0] memory [0:MEM_SIZE-1];
%000005     initial $readmemh("firmware.hex", memory);
        
~000213     wire [11:0] i_word_idx = i_mem_addr[13:2];
 000102     wire [11:0] d_word_idx = d_mem_addr[13:2];
        
            core dut (
                .clk                (clk),
                .resetn             (resetn),
                .trap               (trap),
                .i_mem_addr         (i_mem_addr),
                .i_mem_en           (i_mem_en),
                .i_mem_rdata        (i_mem_rdata),
                .d_mem_valid        (d_mem_valid),
                .d_mem_addr         (d_mem_addr),
                .d_mem_wdata        (d_mem_wdata),
                .d_mem_wstrb        (d_mem_wstrb),
                .d_mem_rdata        (d_mem_rdata),
                .irq_external_pulse (1'b0),
                .dbg_pc             (dbg_pc),
                .dbg_instr          (dbg_instr),
                .dbg_state          (dbg_state)
            );
        
 002625     always #5 clk = ~clk;
        
 001315     always @(posedge clk) begin
 000693         if (i_mem_en) i_mem_rdata <= memory[i_word_idx];
        
 001246         if (d_mem_valid) begin
 000069             d_mem_rdata <= memory[d_word_idx];
 000036             if (|d_mem_wstrb) begin
 000020                 if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
 000021                 if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
 000021                 if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
 000019                 if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
                    end
                end
            end
        
            integer trace_fd;
            integer commit_count;
            integer watchdog;
~000133     reg [31:0] commit_instr;
        
 000405     function [31:0] instr_at_pc;
                input [31:0] pc;
 000405         reg [31:0] word0;
 000405         reg [31:0] word1;
 000405         reg [15:0] half0;
 000405         begin
 000405             word0 = memory[pc[13:2]];
 000221             if (pc[1]) begin
 000184                 half0 = word0[31:16];
 000174                 if (half0[1:0] == 2'b11) begin
 000174                     word1 = memory[pc[13:2] + 12'd1];
 000174                     instr_at_pc = {word1[15:0], half0};
 000010                 end else begin
 000010                     instr_at_pc = {16'h0, half0};
                        end
 000221             end else begin
 000221                 half0 = word0[15:0];
 000209                 if (half0[1:0] == 2'b11)
 000209                     instr_at_pc = word0;
                        else
 000012                     instr_at_pc = {16'h0, half0};
                    end
                end
            endfunction
        
%000005     initial begin
%000005         trace_fd = $fopen("dut_commit.trace", "w");
%000005         if (trace_fd == 0) begin
                    $display("FAIL: could not open dut_commit.trace");
                    $fatal(1);
                end
%000005         $fdisplay(trace_fd, "idx,pc,instr,rd,wdata");
%000005         commit_count = 0;
%000005         watchdog = 0;
            end
        
 001315     always @(posedge clk) begin
 001315         watchdog <= watchdog + 1;
 001315         if (watchdog > 400) begin
                    $display("FAIL: watchdog timeout");
                    $fatal(1);
                end
        
~001310         if (dut.ex_wb_valid_r && dut.ex_wb_illegal_r) begin
%000005             $display("[%0t ns] stop on illegal/ebreak pc=%08x commits=%0d",
%000005                      $time, dut.ex_wb_pc_r, commit_count);
%000005             if (commit_count < 8) begin
                        $display("FAIL: too few commits before ebreak");
                        $fatal(1);
                    end
%000005             $fclose(trace_fd);
%000005             $display("PASS: random DUT trace wrote %0d commits before ebreak", commit_count);
%000005             $finish;
~000905         end else if (dut.wb_instr_retired && !dut.ex_wb_illegal_r) begin
                    /* verilator lint_off BLKSEQ */
 000405             commit_instr = instr_at_pc(dut.ex_wb_pc_r);
                    /* verilator lint_on BLKSEQ */
 000405             $fdisplay(trace_fd, "%0d,%08x,%08x,%0d,%08x",
 000405                       commit_count,
 000405                       dut.ex_wb_pc_r,
 000405                       (commit_instr[1:0] != 2'b11) ? {16'h0, commit_instr[15:0]} : commit_instr,
~000405                       (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_idx : 5'd0,
~000405                       (dut.rfu_we && dut.rfu_wr_idx != 5'd0) ? dut.rfu_wr_data : 32'h0);
 000405             commit_count <= commit_count + 1;
                end
            end
        
%000005     initial begin
%000005         $dumpfile("wave.vcd");
%000005         $dumpvars(0, clk, resetn, trap, commit_count,
                             i_mem_addr, i_mem_en, i_mem_rdata,
                             d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb,
                             dbg_pc, dbg_instr, dbg_state);
        
~000030         repeat (6) @(posedge clk);
%000005         resetn = 1'b1;
            end
        endmodule
        
