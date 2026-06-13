//      // verilator_coverage annotation
        // =============================================================================
        // rfu.v — Register File Unit
        // -----------------------------------------------------------------------------
        // 32 個 32-bit 暫存器 (x0–x31)。
        //   - 2 read ports (組合讀)：rs1_idx → rs1_data，rs2_idx → rs2_data
        //   - 1 write port (同步寫，posedge clk)：we && rd_idx != 0 → rd_data
        //   - x0 永遠讀回 0，寫入被忽略
        //
        // 教學說明：
        //   * 這是最樸素的 register file 實作。FPGA 上 Vivado 會把它推到分散式 RAM
        //     (LUT-based)；如果想推 BRAM 可以加 (* ram_style = "block" *) 但 lab01
        //     baseline 是 LUT，這裡跟著走。
        //   * 真實處理器的 RF 常有 bypass / forwarding，本 lab 是 multi-cycle FSM
        //     (一條指令完整跑完才下一條)，不會有 read-after-write hazard，所以無 bypass。
        // =============================================================================
        
        `include "def.vh"
        
        module rfu (
 001139     input         clk,
%000005     input         resetn,         // active-low; holds x0 (regs[0]) at 0 architecturally
            // Read port 1
 000074     input  [ 4:0] rs1_idx,
~000063     output [31:0] rs1_data,
            // Read port 2
 000104     input  [ 4:0] rs2_idx,
~000076     output [31:0] rs2_data,
            // Write port (同步)
 000048     input         we,
 000133     input  [ 4:0] rd_idx,
 000094     input  [31:0] rd_data,
        
            // Debug abstract GPR access (ADR-0021; active only while core is halted)
%000000     input         dbg_acc_en,
%000000     input         dbg_acc_write,
%000000     input  [ 4:0] dbg_acc_idx,
%000000     input  [31:0] dbg_acc_wdata,
%000000     output [31:0] dbg_acc_rdata
        );
        
            reg [31:0] regs [0:31];
        
            integer i;
%000005     initial begin
~000160         for (i = 0; i < 32; i = i + 1)
 000160             regs[i] = 32'h0;
            end
        
            // x0 read返回 0；其餘讀對應 entry
 000940     assign rs1_data = (rs1_idx == 5'd0) ? 32'h0 : regs[rs1_idx];
 001072     assign rs2_data = (rs2_idx == 5'd0) ? 32'h0 : regs[rs2_idx];
%000005     assign dbg_acc_rdata = (dbg_acc_idx == 5'd0) ? 32'h0 : regs[dbg_acc_idx];
        
            // x0 storage held at 0 by reset (architectural x0=0); x0 writes ignored
 001139     always @(posedge clk) begin
 001114         if (!resetn)
 000025             regs[0] <= 32'h0;
~001114         else if (dbg_acc_en && dbg_acc_write && dbg_acc_idx != 5'd0)
%000000             regs[dbg_acc_idx] <= dbg_acc_wdata;
 000742         else if (we && rd_idx != 5'd0)
 000372             regs[rd_idx] <= rd_data;
            end
        
        endmodule
        
