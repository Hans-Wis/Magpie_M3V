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

module csr #(
    parameter RV32A = 1,
    parameter PMP_ENTRIES = 0
) (
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
    input  [31:0]     trap_cause,
    input  [31:0]     trap_mtval,

    // Trap exit (mret)
    input             trap_exit,

    // Debug-mode CSRs / abstract CSR access (ADR-0021; adapted from
    // Magpie_X1 rtl/cpu/csru.v dcsr/dpc/dscratch0, narrowed to RV32).
    input             debug_csr_we,
    input  [11:0]     debug_csr_waddr,
    input  [31:0]     debug_csr_wdata,
    output [31:0]     debug_csr_rdata,
    input             debug_halt_enter,
    input  [31:0]     debug_halt_pc,
    input  [ 2:0]     debug_halt_cause,
    output [31:0]     dpc_o,
    output            dcsr_step_o,
    output            dcsr_ebreakm_o,

    // Trigger CSRs (ADR-0022; storage/matching lives in trigger.v)
    input  [31:0]     trigger_csr_rdata,
    input  [31:0]     trigger_debug_csr_rdata,
    output            trigger_csr_we,
    output [11:0]     trigger_csr_waddr,
    output [31:0]     trigger_csr_wdata,
    output            trigger_debug_csr_we,
    output [11:0]     trigger_debug_csr_waddr,
    output [31:0]     trigger_debug_csr_wdata,

    // External IRQ source (single-cycle pulse from debouncer)
    input             irq_external_pulse,

    // CLINT interrupt sources (level, CLINT-sourced; ADR-0019). 0 if no CLINT wired.
    input             mtip,             // mip[7]: mtime >= mtimecmp
    input             msip,             // mip[3]: software interrupt

    // PLIC external interrupt (level, ADR-0020). 0 if no PLIC; legacy irq_external_pulse still ORs in.
    input             meip,             // mip[11] level source (PLIC.meip_o)

    // To IFU / core
    output [31:0]     mtvec_o,
    output [31:0]     mepc_o,
    output            irq_pending,
    output [31:0]     irq_cause         // priority-encoded interrupt mcause (MEI>MSI>MTI)
);

    // -------------------------------------------------------------------------
    // 1. CSR register storage
    // -------------------------------------------------------------------------
    reg        mie_meie;        // mie[11]
    reg        mie_mtie;        // mie[7]  (ADR-0019)
    reg        mie_msie;        // mie[3]  (ADR-0019)
    reg        mstatus_mie;     // mstatus[3]
    reg        mstatus_mpie;    // mstatus[7]
    localparam [1:0] mstatus_mpp = 2'b11;  // mstatus[12:11] read-only WARL=M (M-only hart; ADR-0015)
    reg [31:2] mtvec_base;      // mtvec[31:2] (MODE 永遠 0)
    reg [31:0] mscratch;
    reg [31:0] mepc_reg;
    reg [31:0] mcause_reg;
    reg [31:0] mtval_reg;
    reg        ext_pending;     // mip[11], hardware managed
    reg [31:0] dpc_reg;
    reg [31:0] dscratch0_reg;
    reg        dcsr_step_reg;
    reg        dcsr_ebreakm_reg;
    reg [ 2:0] dcsr_cause_reg;

    // Counters
    reg [63:0] cycle_cnt;
    reg [63:0] instret_cnt;

    reg [31:0] new_val;

    function is_trigger_csr;
        input [11:0] addr;
        begin
            is_trigger_csr = (addr == `CSR_TSELECT) ||
                             (addr == `CSR_TDATA1)  ||
                             (addr == `CSR_TDATA2)  ||
                             (addr == `CSR_TINFO);
        end
    endfunction

    // -------------------------------------------------------------------------
    // 2. Read mux (組合)
    //   未列出的位址回 0 (mhartid / misa / mvendorid 等)
    // -------------------------------------------------------------------------
    // mstatus layout: [31:8]=0, [7]=MPIE, [6:4]=0, [3]=MIE, [2:0]=0
    wire [31:0] mstatus_val = {19'b0, mstatus_mpp, 3'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};
    // mie/mip layout: [11]=MEIE/MEIP, [7]=MTIE/MTIP, [3]=MSIE/MSIP (ADR-0019)
    wire [31:0] mie_val     = {20'b0, mie_meie, 3'b0, mie_mtie, 3'b0, mie_msie, 3'b0};
    wire [31:0] mip_val     = {20'b0, (ext_pending | meip), 3'b0, mtip, 3'b0, msip, 3'b0};
    wire [31:0] mtvec_val   = {mtvec_base, 2'b00};
    wire [31:0] mtval_val   = mtval_reg;
    localparam [25:0] MISA_EXT_BASE = (26'h1 << 8) | (26'h1 << 12) | (26'h1 << 2);
    wire [31:0] misa_val    = {2'b01, 4'b0, (MISA_EXT_BASE | ((RV32A != 0) ? 26'h1 : 26'h0))};
    wire [31:0] dcsr_val    = {4'h4, 12'h0, dcsr_ebreakm_reg, 3'h0, 1'b0, 2'b0,
                               dcsr_cause_reg, 3'h0, dcsr_step_reg, 2'b11};

    function [31:0] csr_debug_read;
        input [11:0] addr;
        begin
            case (addr)
                `CSR_MSTATUS : csr_debug_read = mstatus_val;
                `CSR_MISA    : csr_debug_read = misa_val;
                `CSR_MIE     : csr_debug_read = mie_val;
                `CSR_MTVEC   : csr_debug_read = mtvec_val;
                `CSR_MSCRATCH: csr_debug_read = mscratch;
                `CSR_MEPC    : csr_debug_read = mepc_reg;
                `CSR_MCAUSE  : csr_debug_read = mcause_reg;
                `CSR_MTVAL   : csr_debug_read = mtval_val;
                `CSR_MIP     : csr_debug_read = mip_val;
                `CSR_CYCLE   : csr_debug_read = cycle_cnt[31:0];
                `CSR_CYCLEH  : csr_debug_read = cycle_cnt[63:32];
                `CSR_INSTRET : csr_debug_read = instret_cnt[31:0];
                `CSR_INSTRETH: csr_debug_read = instret_cnt[63:32];
                `CSR_DCSR    : csr_debug_read = dcsr_val;
                `CSR_DPC     : csr_debug_read = dpc_reg;
                `CSR_DSCRATCH0: csr_debug_read = dscratch0_reg;
                `CSR_TSELECT,
                `CSR_TDATA1,
                `CSR_TDATA2,
                `CSR_TINFO   : csr_debug_read = trigger_debug_csr_rdata;
                default      : csr_debug_read = 32'h0;
            endcase
        end
    endfunction

    always @* begin
        case (csr_raddr)
            `CSR_MSTATUS : csr_rdata = mstatus_val;
            `CSR_MISA    : csr_rdata = misa_val;
            `CSR_MIE     : csr_rdata = mie_val;
            `CSR_MTVEC   : csr_rdata = mtvec_val;
            `CSR_MSCRATCH: csr_rdata = mscratch;
            `CSR_MEPC    : csr_rdata = mepc_reg;
            `CSR_MCAUSE  : csr_rdata = mcause_reg;
            `CSR_MTVAL   : csr_rdata = mtval_val;
            `CSR_MIP     : csr_rdata = mip_val;
            `CSR_CYCLE   : csr_rdata = cycle_cnt[31:0];
            `CSR_CYCLEH  : csr_rdata = cycle_cnt[63:32];
            `CSR_INSTRET : csr_rdata = instret_cnt[31:0];
            `CSR_INSTRETH: csr_rdata = instret_cnt[63:32];
            `CSR_DCSR    : csr_rdata = dcsr_val;
            `CSR_DPC     : csr_rdata = dpc_reg;
            `CSR_DSCRATCH0: csr_rdata = dscratch0_reg;
            `CSR_TSELECT,
            `CSR_TDATA1,
            `CSR_TDATA2,
            `CSR_TINFO   : csr_rdata = trigger_csr_rdata;
            default      : csr_rdata = 32'h0;
        endcase
        if (csr_we && (csr_waddr == csr_raddr)) begin
            case (csr_waddr)
                `CSR_MSTATUS,
                `CSR_MIE,
                `CSR_MTVEC,
                `CSR_MSCRATCH,
                `CSR_MEPC,
                `CSR_MCAUSE,
                `CSR_MTVAL,
                `CSR_DPC,
                `CSR_DSCRATCH0,
                `CSR_TSELECT,
                `CSR_TDATA1,
                `CSR_TDATA2,
                `CSR_TINFO: csr_rdata = is_trigger_csr(csr_waddr) ? trigger_csr_rdata : new_val;
                `CSR_DCSR: csr_rdata = {4'h4, 12'h0, new_val[15], 3'h0, 1'b0, 2'b0,
                                        new_val[8:6], 3'h0, new_val[2], 2'b11};
                default: ;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // 3. Compute "next value" for whichever CSR is being written this cycle
    //    (CSRRW/RS/RC 對任何 CSR 行為一致，只是 set/clear/swap 差異)
    // -------------------------------------------------------------------------
    always @* begin
        case (csr_op)
            `CSR_OP_W : new_val = csr_wdata;
            `CSR_OP_S : new_val = csr_old_val | csr_wdata;
            `CSR_OP_C : new_val = csr_old_val & ~csr_wdata;
            default   : new_val = csr_old_val;
        endcase
    end

    assign trigger_csr_we      = csr_we && is_trigger_csr(csr_waddr);
    assign trigger_csr_waddr   = csr_waddr;
    assign trigger_csr_wdata   = new_val;
    assign trigger_debug_csr_we    = debug_csr_we && is_trigger_csr(debug_csr_waddr);
    assign trigger_debug_csr_waddr = debug_csr_waddr;
    assign trigger_debug_csr_wdata = debug_csr_wdata;

    // -------------------------------------------------------------------------
    // 4. Sync write logic (CSR* 指令、trap 進入/退出、counter increment)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            mie_meie     <= 1'b0;
            mie_mtie     <= 1'b0;          // ADR-0019
            mie_msie     <= 1'b0;          // ADR-0019
            mstatus_mie  <= 1'b0;          // 重置時 IRQ 關閉，要靠軟體開
            mstatus_mpie <= 1'b0;
            mtvec_base   <= 30'b0;
            mscratch     <= 32'b0;
            mepc_reg     <= 32'b0;
            mcause_reg   <= 32'b0;
            mtval_reg    <= 32'b0;
            ext_pending  <= 1'b0;
            dpc_reg      <= 32'b0;
            dscratch0_reg <= 32'b0;
            dcsr_step_reg <= 1'b0;
            dcsr_ebreakm_reg <= 1'b0;
            dcsr_cause_reg <= 3'b0;
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
                        // mstatus.MPP is read-only WARL=M (M-only hart, ADR-0015): write ignored
                    end
                    `CSR_MIE     : begin
                        mie_meie <= new_val[`MIE_MEIE_BIT];
                        mie_mtie <= new_val[`MIE_MTIE_BIT];   // ADR-0019
                        mie_msie <= new_val[`MIE_MSIE_BIT];   // ADR-0019
                    end
                    `CSR_MTVEC   : mtvec_base  <= new_val[31:2];
                    `CSR_MSCRATCH: mscratch    <= new_val;
                    `CSR_MEPC    : mepc_reg    <= {new_val[31:1], 1'b0};
                    `CSR_MCAUSE  : mcause_reg  <= new_val;
                    `CSR_MTVAL   : mtval_reg   <= new_val;
                    `CSR_DPC     : dpc_reg     <= {new_val[31:1], 1'b0};
                    `CSR_DSCRATCH0: dscratch0_reg <= new_val;
                    `CSR_DCSR    : begin
                        dcsr_ebreakm_reg <= new_val[15];
                        dcsr_cause_reg   <= new_val[8:6];
                        dcsr_step_reg    <= new_val[2];
                    end
                    // 其他 (MIP / counters / unknown) 忽略
                    default      : ;
                endcase
            end

            if (debug_csr_we) begin
                case (debug_csr_waddr)
                    `CSR_MSTATUS : begin
                        mstatus_mie  <= debug_csr_wdata[`MSTATUS_MIE_BIT];
                        mstatus_mpie <= debug_csr_wdata[`MSTATUS_MPIE_BIT];
                    end
                    `CSR_MIE     : begin
                        mie_meie <= debug_csr_wdata[`MIE_MEIE_BIT];
                        mie_mtie <= debug_csr_wdata[`MIE_MTIE_BIT];
                        mie_msie <= debug_csr_wdata[`MIE_MSIE_BIT];
                    end
                    `CSR_MTVEC   : mtvec_base  <= debug_csr_wdata[31:2];
                    `CSR_MSCRATCH: mscratch    <= debug_csr_wdata;
                    `CSR_MEPC    : mepc_reg    <= {debug_csr_wdata[31:1], 1'b0};
                    `CSR_MCAUSE  : mcause_reg  <= debug_csr_wdata;
                    `CSR_MTVAL   : mtval_reg   <= debug_csr_wdata;
                    `CSR_DPC     : dpc_reg     <= {debug_csr_wdata[31:1], 1'b0};
                    `CSR_DSCRATCH0: dscratch0_reg <= debug_csr_wdata;
                    `CSR_DCSR    : begin
                        dcsr_ebreakm_reg <= debug_csr_wdata[15];
                        dcsr_cause_reg   <= debug_csr_wdata[8:6];
                        dcsr_step_reg    <= debug_csr_wdata[2];
                    end
                    default: ;
                endcase
            end

            // 4.4 硬體 trap entry / exit
            //     core.v 保證 trap_enter / trap_exit / csr_we 三者互斥；
            //     不過 trap_enter 在源碼順序上放在 csr_we 後面，
            //     就算同 cycle 都 fire 也是 trap_enter 路徑的 NBA 寫贏。
            if (trap_enter) begin
                mepc_reg     <= trap_pc;
                mcause_reg   <= trap_cause;
                mtval_reg    <= trap_mtval;
                mstatus_mpie <= mstatus_mie;
                mstatus_mie  <= 1'b0;
            end else if (trap_exit) begin
                mstatus_mie  <= mstatus_mpie;
                mstatus_mpie <= 1'b1;            // spec: MPIE <- 1 after mret
            end

            if (debug_halt_enter) begin
                dpc_reg         <= {debug_halt_pc[31:1], 1'b0};
                dcsr_cause_reg  <= debug_halt_cause;
            end

            // 4.5 ext_pending 三優先級邏輯 (trap_enter > pulse > hold)
            //     - trap_enter → clear (hardware ack)
            //     - 新 pulse 進來且沒有同拍 trap_enter → set
            //     - 其他保持
            //     寫成一條 mux 而不是兩個 if，邏輯 + timing 都比較乾淨
            ext_pending <=
                trap_enter         ? 1'b0 :
                irq_external_pulse ? 1'b1 :
                                     ext_pending;
        end
    end

    // -------------------------------------------------------------------------
    // 5. 輸出
    // -------------------------------------------------------------------------
    assign mtvec_o     = mtvec_val;
    assign mepc_o      = mepc_reg;
    assign dpc_o       = dpc_reg;
    assign dcsr_step_o = dcsr_step_reg;
    assign dcsr_ebreakm_o = dcsr_ebreakm_reg;
    assign debug_csr_rdata = csr_debug_read(debug_csr_waddr);

    // Interrupt arbitration (ADR-0019). mip[3,7,11] are CLINT/ext-sourced (RO to CSR
    // writes); only mie + mstatus.MIE gate delivery. Priority MEI > MSI > MTI (priv spec).
    wire irq_mei = (ext_pending | meip) & mie_meie;  // M external: legacy pulse-sticky OR PLIC level (ADR-0020)
    wire irq_msi = msip        & mie_msie;   // M software
    wire irq_mti = mtip        & mie_mtie;   // M timer (lowest)
    assign irq_pending = (irq_mei | irq_msi | irq_mti) & mstatus_mie;
    assign irq_cause   = irq_mei ? `MCAUSE_EXT_IRQ   :
                         irq_msi ? `MCAUSE_MSW_IRQ   :
                                   `MCAUSE_TIMER_IRQ;

endmodule
