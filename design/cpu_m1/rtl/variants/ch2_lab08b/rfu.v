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
    input         clk,
    // Read port 1
    input  [ 4:0] rs1_idx,
    output [31:0] rs1_data,
    // Read port 2
    input  [ 4:0] rs2_idx,
    output [31:0] rs2_data,
    // Write port (同步)
    input         we,
    input  [ 4:0] rd_idx,
    input  [31:0] rd_data
);

    reg [31:0] regs [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0;
    end

    // x0 read返回 0；其餘讀對應 entry
    assign rs1_data = (rs1_idx == 5'd0) ? 32'h0 : regs[rs1_idx];
    assign rs2_data = (rs2_idx == 5'd0) ? 32'h0 : regs[rs2_idx];

    // x0 寫入忽略
    always @(posedge clk) begin
        if (we && rd_idx != 5'd0)
            regs[rd_idx] <= rd_data;
    end

endmodule
