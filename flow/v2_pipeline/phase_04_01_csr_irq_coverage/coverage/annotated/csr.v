//      // verilator_coverage annotation
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
 001315     input             clk,
%000005     input             resetn,
        
            // CSR read port (combinational, ID/EX stage 用)
~000106     input  [11:0]     csr_raddr,
%000006     output reg [31:0] csr_rdata,
        
            // CSR write port (sync, EX/WB stage 用；可與 raddr 不同)
%000006     input             csr_we,
~000104     input  [11:0]     csr_waddr,
~000062     input  [ 1:0]     csr_op,        // CSR_OP_W/S/C
~000066     input  [31:0]     csr_wdata,     // 直接寫入用 / set 用 mask / clear 用 mask
%000006     input  [31:0]     csr_old_val,   // = ex_wb 階段已 latch 的 OLD 值 (pipeline 用)
        
            // Counter input
~000195     input             instr_retired,
        
            // Trap entry (from core, single-cycle pulse in WB)
%000001     input             trap_enter,
~000200     input  [31:0]     trap_pc,       // pc to save in mepc (next_pc that would have executed)
        
            // Trap exit (mret)
%000001     input             trap_exit,
        
            // External IRQ source (single-cycle pulse from debouncer)
%000001     input             irq_external_pulse,
        
            // To IFU / core
%000001     output [31:0]     mtvec_o,
%000001     output [31:0]     mepc_o,
%000001     output            irq_pending
        );
        
            // -------------------------------------------------------------------------
            // 1. CSR register storage
            // -------------------------------------------------------------------------
%000001     reg        mie_meie;        // mie[11]
%000002     reg        mstatus_mie;     // mstatus[3]
%000001     reg        mstatus_mpie;    // mstatus[7]
%000001     reg [31:2] mtvec_base;      // mtvec[31:2] (MODE 永遠 0)
%000001     reg [31:0] mscratch;
%000001     reg [31:0] mepc_reg;
%000001     reg [31:0] mcause_reg;
%000001     reg        ext_pending;     // mip[11], hardware managed
        
            // Counters
~000647     reg [63:0] cycle_cnt;
~000205     reg [63:0] instret_cnt;
        
            // -------------------------------------------------------------------------
            // 2. Read mux (組合)
            //   未列出的位址回 0 (mhartid / misa / mvendorid 等)
            // -------------------------------------------------------------------------
            // mstatus layout: [31:8]=0, [7]=MPIE, [6:4]=0, [3]=MIE, [2:0]=0
%000002     wire [31:0] mstatus_val = {24'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};
%000001     wire [31:0] mie_val     = {20'b0, mie_meie, 11'b0};
%000001     wire [31:0] mip_val     = {20'b0, ext_pending, 11'b0};
%000001     wire [31:0] mtvec_val   = {mtvec_base, 2'b00};
        
 001320     always @* begin
 001320         case (csr_raddr)
%000003             `CSR_MSTATUS : csr_rdata = mstatus_val;
%000001             `CSR_MIE     : csr_rdata = mie_val;
%000001             `CSR_MTVEC   : csr_rdata = mtvec_val;
%000005             `CSR_MSCRATCH: csr_rdata = mscratch;
%000001             `CSR_MEPC    : csr_rdata = mepc_reg;
%000002             `CSR_MCAUSE  : csr_rdata = mcause_reg;
%000001             `CSR_MIP     : csr_rdata = mip_val;
%000001             `CSR_CYCLE   : csr_rdata = cycle_cnt[31:0];
%000000             `CSR_CYCLEH  : csr_rdata = cycle_cnt[63:32];
%000001             `CSR_INSTRET : csr_rdata = instret_cnt[31:0];
%000000             `CSR_INSTRETH: csr_rdata = instret_cnt[63:32];
 001318             default      : csr_rdata = 32'h0;
                endcase
            end
        
            // -------------------------------------------------------------------------
            // 3. Compute "next value" for whichever CSR is being written this cycle
            //    (CSRRW/RS/RC 對任何 CSR 行為一致，只是 set/clear/swap 差異)
            // -------------------------------------------------------------------------
~000045     reg [31:0] new_val;
 001320     always @* begin
 001320         case (csr_op)
~000355             `CSR_OP_W : new_val = csr_wdata;
 000135             `CSR_OP_S : new_val = csr_old_val | csr_wdata;
~000269             `CSR_OP_C : new_val = csr_old_val & ~csr_wdata;
 000561             default   : new_val = csr_old_val;
                endcase
            end
        
            // -------------------------------------------------------------------------
            // 4. Sync write logic (CSR* 指令、trap 進入/退出、counter increment)
            // -------------------------------------------------------------------------
 001315     always @(posedge clk) begin
~001290         if (!resetn) begin
~000025             mie_meie     <= 1'b0;
~000025             mstatus_mie  <= 1'b0;          // 重置時 IRQ 關閉，要靠軟體開
~000025             mstatus_mpie <= 1'b0;
~000025             mtvec_base   <= 30'b0;
~000025             mscratch     <= 32'b0;
~000025             mepc_reg     <= 32'b0;
~000025             mcause_reg   <= 32'b0;
~000025             ext_pending  <= 1'b0;
~000025             cycle_cnt    <= 64'b0;
~000025             instret_cnt  <= 64'b0;
 001290         end else begin
                    // 4.1 cycle 永遠 +1 (CSR write 不影響)
 001290             cycle_cnt <= cycle_cnt + 1'b1;
        
                    // 4.2 instret 在每條完成 +1
 000880             if (instr_retired)
 000410                 instret_cnt <= instret_cnt + 1'b1;
        
                    // 4.3 軟體 CSR 寫入 (CSR* 指令)
                    //     只 patch 對應位址的 register；RO 位址寫入忽略
~001290             if (csr_we) begin
%000006                 case (csr_waddr)
%000001                     `CSR_MSTATUS : begin
%000001                         mstatus_mie  <= new_val[`MSTATUS_MIE_BIT];
%000001                         mstatus_mpie <= new_val[`MSTATUS_MPIE_BIT];
                            end
%000001                     `CSR_MIE     : mie_meie    <= new_val[`MIE_MEIE_BIT];
%000001                     `CSR_MTVEC   : mtvec_base  <= new_val[31:2];
%000003                     `CSR_MSCRATCH: mscratch    <= new_val;
%000000                     `CSR_MEPC    : mepc_reg    <= new_val;
%000000                     `CSR_MCAUSE  : mcause_reg  <= new_val;
                            // 其他 (MIP / counters / unknown) 忽略
%000000                     default      : ;
                        endcase
                    end
        
                    // 4.4 硬體 trap entry / exit
                    //     core.v 保證 trap_enter / trap_exit / csr_we 三者互斥；
                    //     不過 trap_enter 在源碼順序上放在 csr_we 後面，
                    //     就算同 cycle 都 fire 也是 trap_enter 路徑的 NBA 寫贏。
%000001             if (trap_enter) begin
%000001                 mepc_reg     <= trap_pc;
%000001                 mcause_reg   <= `MCAUSE_EXT_IRQ;
%000001                 mstatus_mpie <= mstatus_mie;
%000001                 mstatus_mie  <= 1'b0;
~001290             end else if (trap_exit) begin
%000001                 mstatus_mie  <= mstatus_mpie;
%000001                 mstatus_mpie <= 1'b1;            // spec: MPIE <- 1 after mret
                    end
        
                    // 4.5 ext_pending 三優先級邏輯 (trap_enter > pulse > hold)
                    //     - trap_enter → clear (hardware ack)
                    //     - 新 pulse 進來且沒有同拍 trap_enter → set
                    //     - 其他保持
                    //     寫成一條 mux 而不是兩個 if，邏輯 + timing 都比較乾淨
 001290             ext_pending <=
~001290                 trap_enter         ? 1'b0 :
~001290                 irq_external_pulse ? 1'b1 :
 001290                                      ext_pending;
                end
            end
        
            // -------------------------------------------------------------------------
            // 5. 輸出
            // -------------------------------------------------------------------------
            assign mtvec_o     = mtvec_val;
            assign mepc_o      = mepc_reg;
            assign irq_pending = ext_pending & mie_meie & mstatus_mie;
        
        endmodule
        
