// =============================================================================
// csr.v — Lab05 RISC-V M-mode Control & Status Register file
// -----------------------------------------------------------------------------
// 內含：
//   * 7 個 RW CSR (mstatus / mie / mtvec / mscratch / mepc / mcause / mip*)
//     [* mip 對外是 read-only；只受硬體 irq + trap entry 控制]
//   * 4 個 RO counter CSR (cycle / cycleh / instret / instreth)
//   * 中斷 pending 邏輯 (irq_pending = ext_pending & MIE & MEIE)
//
// 與 core.v 的介面 (CSR 讀寫一律在 WB state 同一拍完成)：
//   csr_addr/op/wdata/we  → 寫 CSR (op = W/S/C，wdata = rs1 或 zimm)
//   csr_rdata             ← 組合讀 (回 OLD 值，給 rd 寫回)
//   instr_retired         → 每條完成 1 cycle pulse，instret++
//   trap_enter + trap_pc  → 進中斷：mepc <- trap_pc, mcause<-EXT, MPIE<-MIE, MIE<-0
//   trap_exit (mret)      → 退中斷：MIE <- MPIE, MPIE <- 1
//   irq_external_pulse    → BTN1 debounced 上緣，set ext_pending
//   mtvec_o / mepc_o      ← 給 IFU 做 next_pc 用
//   irq_pending           ← 給 core 在 WB 判斷是否要 trap entry
//
// 教學說明：
//   * cycle / instret 是 RO；寫入 (e.g. csrrw 試圖寫) 被忽略，不 trap
//   * 「未實作」CSR 讀回 0、寫忽略，避免 boot code 隨便讀 mhartid 就 trap
//   * MEIE/MIE/MPIE/MEIP 用 named bit-position (def.vh) 而不是 magic number
//   * mtvec direct mode only (MODE bits 寫入被遮蔽成 0)
//   * mip[11] 是「外部中斷已發生但尚未進 ISR」的硬體 sticky bit；
//     軟體不需要清 (進 trap 時硬體自動清)
// =============================================================================

`include "def.vh"

module csr (
    input             clk,
    input             resetn,

    // CSR read port (combinational, ID/EX stage 用)
    input  [11:0]     csr_raddr,
    output reg [31:0] csr_rdata,

    // CSR write port (sync, EX/WB stage 用；可與 raddr 不同)
    input             csr_we,
    input  [11:0]     csr_waddr,
    input  [ 1:0]     csr_op,        // CSR_OP_W/S/C
    input  [31:0]     csr_wdata,     // 直接寫入用 / set 用 mask / clear 用 mask
    input  [31:0]     csr_old_val,   // = ex_wb 階段已 latch 的 OLD 值 (pipeline 用)

    // Counter input
    input             instr_retired,

    // Trap entry (from core, single-cycle pulse in WB)
    input             trap_enter,
    input  [31:0]     trap_pc,       // pc to save in mepc (next_pc that would have executed)

    // Trap exit (mret)
    input             trap_exit,

    // External IRQ source (single-cycle pulse from debouncer)
    input             irq_external_pulse,

    // To IFU / core
    output [31:0]     mtvec_o,
    output [31:0]     mepc_o,
    output            irq_pending
);

    // -------------------------------------------------------------------------
    // 1. CSR register storage
    // -------------------------------------------------------------------------
    reg        mie_meie;        // mie[11]
    reg        mstatus_mie;     // mstatus[3]
    reg        mstatus_mpie;    // mstatus[7]
    reg [31:2] mtvec_base;      // mtvec[31:2] (MODE 永遠 0)
    reg [31:0] mscratch;
    reg [31:0] mepc_reg;
    reg [31:0] mcause_reg;
    reg        ext_pending;     // mip[11], hardware managed

    // Counters
    reg [63:0] cycle_cnt;
    reg [63:0] instret_cnt;

    // -------------------------------------------------------------------------
    // 2. Read mux (組合)
    //   未列出的位址回 0 (mhartid / misa / mvendorid 等)
    // -------------------------------------------------------------------------
    // mstatus layout: [31:8]=0, [7]=MPIE, [6:4]=0, [3]=MIE, [2:0]=0
    wire [31:0] mstatus_val = {24'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};
    wire [31:0] mie_val     = {20'b0, mie_meie, 11'b0};
    wire [31:0] mip_val     = {20'b0, ext_pending, 11'b0};
    wire [31:0] mtvec_val   = {mtvec_base, 2'b00};

    always @* begin
        case (csr_raddr)
            `CSR_MSTATUS : csr_rdata = mstatus_val;
            `CSR_MIE     : csr_rdata = mie_val;
            `CSR_MTVEC   : csr_rdata = mtvec_val;
            `CSR_MSCRATCH: csr_rdata = mscratch;
            `CSR_MEPC    : csr_rdata = mepc_reg;
            `CSR_MCAUSE  : csr_rdata = mcause_reg;
            `CSR_MIP     : csr_rdata = mip_val;
            `CSR_CYCLE   : csr_rdata = cycle_cnt[31:0];
            `CSR_CYCLEH  : csr_rdata = cycle_cnt[63:32];
            `CSR_INSTRET : csr_rdata = instret_cnt[31:0];
            `CSR_INSTRETH: csr_rdata = instret_cnt[63:32];
            default      : csr_rdata = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // 3. Compute "next value" for whichever CSR is being written this cycle
    //    (CSRRW/RS/RC 對任何 CSR 行為一致，只是 set/clear/swap 差異)
    // -------------------------------------------------------------------------
    reg [31:0] new_val;
    always @* begin
        case (csr_op)
            `CSR_OP_W : new_val = csr_wdata;
            `CSR_OP_S : new_val = csr_old_val | csr_wdata;
            `CSR_OP_C : new_val = csr_old_val & ~csr_wdata;
            default   : new_val = csr_old_val;
        endcase
    end

    // -------------------------------------------------------------------------
    // 4. Sync write logic (CSR* 指令、trap 進入/退出、counter increment)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            mie_meie     <= 1'b0;
            mstatus_mie  <= 1'b0;          // 重置時 IRQ 關閉，要靠軟體開
            mstatus_mpie <= 1'b0;
            mtvec_base   <= 30'b0;
            mscratch     <= 32'b0;
            mepc_reg     <= 32'b0;
            mcause_reg   <= 32'b0;
            ext_pending  <= 1'b0;
            cycle_cnt    <= 64'b0;
            instret_cnt  <= 64'b0;
        end else begin
            // 4.1 cycle 永遠 +1 (CSR write 不影響)
            cycle_cnt <= cycle_cnt + 1'b1;

            // 4.2 instret 在每條完成 +1
            if (instr_retired)
                instret_cnt <= instret_cnt + 1'b1;

            // 4.3 軟體 CSR 寫入 (CSR* 指令)
            //     只 patch 對應位址的 register；RO 位址寫入忽略
            if (csr_we) begin
                case (csr_waddr)
                    `CSR_MSTATUS : begin
                        mstatus_mie  <= new_val[`MSTATUS_MIE_BIT];
                        mstatus_mpie <= new_val[`MSTATUS_MPIE_BIT];
                    end
                    `CSR_MIE     : mie_meie    <= new_val[`MIE_MEIE_BIT];
                    `CSR_MTVEC   : mtvec_base  <= new_val[31:2];
                    `CSR_MSCRATCH: mscratch    <= new_val;
                    `CSR_MEPC    : mepc_reg    <= new_val;
                    `CSR_MCAUSE  : mcause_reg  <= new_val;
                    // 其他 (MIP / counters / unknown) 忽略
                    default      : ;
                endcase
            end

            // 4.4 硬體 trap entry / exit
            //     core.v 保證 trap_enter / trap_exit / csr_we 三者互斥；
            //     不過 trap_enter 在源碼順序上放在 csr_we 後面，
            //     就算同 cycle 都 fire 也是 trap_enter 路徑的 NBA 寫贏。
            if (trap_enter) begin
                mepc_reg     <= trap_pc;
                mcause_reg   <= `MCAUSE_EXT_IRQ;
                mstatus_mpie <= mstatus_mie;
                mstatus_mie  <= 1'b0;
            end else if (trap_exit) begin
                mstatus_mie  <= mstatus_mpie;
                mstatus_mpie <= 1'b1;            // spec: MPIE <- 1 after mret
            end

            // 4.5 ext_pending 三優先級邏輯 (pulse > trap_enter > hold)
            //     - 新 pulse 進來 → set (即使同 cycle 也 trap_enter 也要 set，
            //       因為這是「下一次中斷」，不該被當前 trap entry 清掉)
            //     - trap_enter 且無新 pulse → clear (hardware ack)
            //     - 其他保持
            //     寫成一條 mux 而不是兩個 if，邏輯 + timing 都比較乾淨
            ext_pending <=
                irq_external_pulse ? 1'b1 :
                trap_enter         ? 1'b0 :
                                     ext_pending;
        end
    end

    // -------------------------------------------------------------------------
    // 5. 輸出
    // -------------------------------------------------------------------------
    assign mtvec_o     = mtvec_val;
    assign mepc_o      = mepc_reg;
    assign irq_pending = ext_pending & mie_meie & mstatus_mie;

endmodule
