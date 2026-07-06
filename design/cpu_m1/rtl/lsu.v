// =============================================================================
// lsu.v — Load / Store Unit (純組合輔助器)
// -----------------------------------------------------------------------------
// 處理 byte/half/word 對齊 + 符號擴展 + write strobe 計算。
//
// 不負責 mem handshake (mem_valid / mem_ready)；那是 core.v FSM 的工作。
// LSU 只是把 RISC-V 的 LB/LH/LW/LBU/LHU/SB/SH/SW 語意翻譯成 byte-strobe 介面。
//
// 對外介面：
//   addr      : 完整 byte address (但對齊到 word boundary 才送 mem_addr，
//                配合 system_pynq.v 用 addr[31:2] 索引)
//   wdata_raw : 直接從 rs2 來的 32-bit 寫資料 (sub-word store 要做 byte 對齊)
//   funct3    : 沿用 RISC-V funct3 → 大小 + signed/unsigned
//   is_load / is_store: 由 core.v 控制
//   mem_rdata : 整字讀回，由 LSU 抽出對應 byte/half 並擴展
//
// 輸出：
//   mem_wdata : byte-replicated 寫資料 (依 addr_lo 對齊)
//   mem_wstrb : 4-bit byte enable
//   ld_result : 已 sign/zero-extend 的 load 結果，給 core.v 寫回 rd
//
// 教學說明：
//   * mem_addr[31:2] 是 word index, addr_lo 決定 byte/half lane。
//   * Store 採 byte-replicate 是 picorv32 的習慣：BRAM 不在意 wdata 的 don't-care
//     bit，只看 wstrb 決定哪些 byte 真正被寫入。
//   * 不檢查 misalignment (lab01 firmware 全部對齊；CATCH_MISALIGN 已關)。
// =============================================================================

`include "def.vh"

module lsu (
    // 來自 core.v 的請求 (只看 addr 低 2 bit 做 byte/half lane 對齊；
    //   整個 addr 由 core.v 自己驅動 mem_addr，本模組不參與)
    input  [ 1:0] addr_lo,
    input  [31:0] wdata_raw,
    input  [ 2:0] funct3,
    input         is_store,

    // 來自 memory 的回應
    input  [31:0] mem_rdata,

    // 給 memory 介面的訊號 (core.v 套上 mem_valid 後送出去)
    output [31:0] mem_wdata,
    output [ 3:0] mem_wstrb,

    // 給 core.v 的 load 結果 (sign-ext 完)
    output reg [31:0] ld_result
);

    // -------------------------------------------------------------------------
    // Store path: byte-replicate wdata + 計算 wstrb
    // -------------------------------------------------------------------------
    reg [31:0] wdata_aligned;
    reg [ 3:0] wstrb;

    always @* begin
        case (funct3)
            `F3_SB: begin
                wdata_aligned = {4{wdata_raw[7:0]}};
                wstrb         = 4'b0001 << addr_lo;
            end
            `F3_SH: begin
                wdata_aligned = {2{wdata_raw[15:0]}};
                wstrb         = 4'b0011 << {addr_lo[1], 1'b0};
            end
            `F3_SW: begin
                wdata_aligned = wdata_raw;
                wstrb         = 4'b1111;
            end
            default: begin
                wdata_aligned = wdata_raw;
                wstrb         = 4'b0000;
            end
        endcase
    end

    assign mem_wdata = wdata_aligned;
    assign mem_wstrb = is_store ? wstrb : 4'b0000;

    // -------------------------------------------------------------------------
    // Load path: 從 mem_rdata 抽出 byte / half / word 並 sign-ext
    // -------------------------------------------------------------------------
    reg [ 7:0] byte_sel;
    reg [15:0] half_sel;

    always @* begin
        case (addr_lo)
            2'b00: byte_sel = mem_rdata[ 7: 0];
            2'b01: byte_sel = mem_rdata[15: 8];
            2'b10: byte_sel = mem_rdata[23:16];
            2'b11: byte_sel = mem_rdata[31:24];
        endcase
    end

    always @* begin
        half_sel = addr_lo[1] ? mem_rdata[31:16] : mem_rdata[15:0];
    end

    always @* begin
        case (funct3)
            `F3_LB : ld_result = {{24{byte_sel[7]}}, byte_sel};
            `F3_LBU: ld_result = {24'b0,             byte_sel};
            `F3_LH : ld_result = {{16{half_sel[15]}}, half_sel};
            `F3_LHU: ld_result = {16'b0,              half_sel};
            `F3_LW : ld_result = mem_rdata;
            default: ld_result = mem_rdata;
        endcase
    end

endmodule
