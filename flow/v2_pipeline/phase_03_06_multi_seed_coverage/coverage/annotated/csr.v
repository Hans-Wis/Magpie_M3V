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
        
        module csr #(
            parameter RV32A = 0,
            parameter PMP_ENTRIES = 0
        ) (
 001139     input             clk,
%000005     input             resetn,
        
            // CSR read port (combinational, ID/EX stage 用)
 000104     input  [11:0]     csr_raddr,
%000000     output reg [31:0] csr_rdata,
        
            // CSR write port (sync, EX/WB stage 用；可與 raddr 不同)
%000000     input             csr_we,
 000104     input  [11:0]     csr_waddr,
 000062     input  [ 1:0]     csr_op,        // CSR_OP_W/S/C
~000066     input  [31:0]     csr_wdata,     // 直接寫入用 / set 用 mask / clear 用 mask
%000000     input  [31:0]     csr_old_val,   // = ex_wb 階段已 latch 的 OLD 值 (pipeline 用)
        
            // Counter input
 000024     input             instr_retired,
        
            // Trap entry (from core, single-cycle pulse in WB)
%000005     input             trap_enter,
~000200     input  [31:0]     trap_pc,       // pc to save in mepc (next_pc that would have executed)
~000010     input  [31:0]     trap_cause,
 000101     input  [31:0]     trap_mtval,
        
            // Trap exit (mret)
%000000     input             trap_exit,
        
            // Debug-mode CSRs / abstract CSR access (ADR-0021; adapted from
            // Magpie_X1 rtl/cpu/csru.v dcsr/dpc/dscratch0, narrowed to RV32).
%000000     input             debug_csr_we,
%000000     input  [11:0]     debug_csr_waddr,
%000000     input  [31:0]     debug_csr_wdata,
%000000     output [31:0]     debug_csr_rdata,
%000000     input             debug_halt_enter,
~000200     input  [31:0]     debug_halt_pc,
%000005     input  [ 2:0]     debug_halt_cause,
%000000     output [31:0]     dpc_o,
%000000     output            dcsr_step_o,
%000000     output            dcsr_ebreakm_o,
        
            // Trigger CSRs (ADR-0022; storage/matching lives in trigger.v)
%000000     input  [31:0]     trigger_csr_rdata,
%000000     input  [31:0]     trigger_debug_csr_rdata,
%000000     output            trigger_csr_we,
 000104     output [11:0]     trigger_csr_waddr,
~000045     output [31:0]     trigger_csr_wdata,
%000000     output            trigger_debug_csr_we,
%000000     output [11:0]     trigger_debug_csr_waddr,
%000000     output [31:0]     trigger_debug_csr_wdata,
        
            // External IRQ source (single-cycle pulse from debouncer)
%000000     input             irq_external_pulse,
        
            // CLINT interrupt sources (level, CLINT-sourced; ADR-0019). 0 if no CLINT wired.
%000000     input             mtip,             // mip[7]: mtime >= mtimecmp
%000000     input             msip,             // mip[3]: software interrupt
        
            // PLIC external interrupt (level, ADR-0020). 0 if no PLIC; legacy irq_external_pulse still ORs in.
%000000     input             meip,             // mip[11] level source (PLIC.meip_o)
        
            // To IFU / core
%000000     output [31:0]     mtvec_o,
%000005     output [31:0]     mepc_o,
%000000     output            irq_pending,
%000005     output [31:0]     irq_cause,        // priority-encoded interrupt mcause (MEI>MSI>MTI)
        
            // PMP CSRs (ADR-0024). Flattened as 8 entries so PMP_ENTRIES=0/4/8 can share ports.
%000000     output [32*8-1:0] pmp_addr_o,
%000000     output [ 8*8-1:0] pmp_cfg_o
        );
        
            // -------------------------------------------------------------------------
            // 1. CSR register storage
            // -------------------------------------------------------------------------
%000000     reg        mie_meie;        // mie[11]
%000000     reg        mie_mtie;        // mie[7]  (ADR-0019)
%000000     reg        mie_msie;        // mie[3]  (ADR-0019)
%000000     reg        mstatus_mie;     // mstatus[3]
%000000     reg        mstatus_mpie;    // mstatus[7]
            localparam [1:0] mstatus_mpp = 2'b11;  // mstatus[12:11] read-only WARL=M (M-only hart; ADR-0015)
%000000     reg [31:2] mtvec_base;      // mtvec[31:2] (MODE 永遠 0)
%000000     reg [31:0] mscratch;
%000005     reg [31:0] mepc_reg;
%000005     reg [31:0] mcause_reg;
%000005     reg [31:0] mtval_reg;
%000000     reg        ext_pending;     // mip[11], hardware managed
%000000     reg [31:0] dpc_reg;
%000000     reg [31:0] dscratch0_reg;
%000000     reg        dcsr_step_reg;
%000000     reg        dcsr_ebreakm_reg;
%000000     reg [ 2:0] dcsr_cause_reg;
%000000     reg [ 7:0] pmpcfg_r [0:7];
%000000     reg [31:0] pmpaddr_r [0:7];
        
            // Counters
~000557     reg [63:0] cycle_cnt;
~000205     reg [63:0] instret_cnt;
        
~000045     reg [31:0] new_val;
            integer pmp_i;
        
%000000     function is_trigger_csr;
                input [11:0] addr;
%000000         begin
%000000             is_trigger_csr = (addr == `CSR_TSELECT) ||
%000000                              (addr == `CSR_TDATA1)  ||
%000000                              (addr == `CSR_TDATA2)  ||
%000000                              (addr == `CSR_TINFO);
                end
            endfunction
        
%000000     function is_pmpcfg_csr;
                input [11:0] addr;
%000000         begin
%000000             is_pmpcfg_csr = (PMP_ENTRIES != 0) &&
%000000                             ((addr == `CSR_PMPCFG0) ||
%000000                              ((PMP_ENTRIES > 4) && (addr == `CSR_PMPCFG1)));
                end
            endfunction
        
%000000     function is_pmpaddr_csr;
                input [11:0] addr;
%000000         begin
%000000             is_pmpaddr_csr = (PMP_ENTRIES != 0) &&
%000000                              (addr >= `CSR_PMPADDR0) &&
%000000                              (addr < (`CSR_PMPADDR0 + PMP_ENTRIES));
                end
            endfunction
        
%000000     function [2:0] pmp_index;
                input [11:0] addr;
%000000         begin
%000000             pmp_index = addr[2:0];
                end
            endfunction
        
%000000     function [31:0] pmpcfg_read;
                input [11:0] addr;
%000000         integer base;
%000000         begin
%000000             base = (addr == `CSR_PMPCFG1) ? 4 : 0;
%000000             pmpcfg_read = {pmpcfg_r[base + 3], pmpcfg_r[base + 2],
%000000                            pmpcfg_r[base + 1], pmpcfg_r[base + 0]};
                end
            endfunction
        
            // -------------------------------------------------------------------------
            // 2. Read mux (組合)
            //   未列出的位址回 0 (mhartid / misa / mvendorid 等)
            // -------------------------------------------------------------------------
            // mstatus layout: [31:8]=0, [7]=MPIE, [6:4]=0, [3]=MIE, [2:0]=0
%000005     wire [31:0] mstatus_val = {19'b0, mstatus_mpp, 3'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};
            // mie/mip layout: [11]=MEIE/MEIP, [7]=MTIE/MTIP, [3]=MSIE/MSIP (ADR-0019)
%000000     wire [31:0] mie_val     = {20'b0, mie_meie, 3'b0, mie_mtie, 3'b0, mie_msie, 3'b0};
%000000     wire [31:0] mip_val     = {20'b0, (ext_pending | meip), 3'b0, mtip, 3'b0, msip, 3'b0};
%000000     wire [31:0] mtvec_val   = {mtvec_base, 2'b00};
%000005     wire [31:0] mtval_val   = mtval_reg;
            // M1A A2 (ADR-0026): + misa.B (bit1) — Zba+Zbb+Zbs ratified as B; Spike --priv=m parity = 0x40001106
            localparam [25:0] MISA_EXT_BASE = (26'h1 << 8) | (26'h1 << 12) | (26'h1 << 2) | (26'h1 << 1);
%000005     wire [31:0] misa_val    = {2'b01, 4'b0, (MISA_EXT_BASE | ((RV32A != 0) ? 26'h1 : 26'h0))};
%000005     wire [31:0] dcsr_val    = {4'h4, 12'h0, dcsr_ebreakm_reg, 3'h0, 1'b0, 2'b0,
                                       dcsr_cause_reg, 3'h0, dcsr_step_reg, 2'b11};
        
 001144     function [31:0] csr_debug_read;
                input [11:0] addr;
 001144         begin
 001144             case (addr)
%000000                 `CSR_MSTATUS : csr_debug_read = mstatus_val;
%000000                 `CSR_MISA    : csr_debug_read = misa_val;
%000000                 `CSR_MIE     : csr_debug_read = mie_val;
%000000                 `CSR_MTVEC   : csr_debug_read = mtvec_val;
%000000                 `CSR_MSCRATCH: csr_debug_read = mscratch;
%000000                 `CSR_MEPC    : csr_debug_read = mepc_reg;
%000000                 `CSR_MCAUSE  : csr_debug_read = mcause_reg;
%000000                 `CSR_MTVAL   : csr_debug_read = mtval_val;
%000000                 `CSR_MIP     : csr_debug_read = mip_val;
%000000                 `CSR_CYCLE   : csr_debug_read = cycle_cnt[31:0];
%000000                 `CSR_CYCLEH  : csr_debug_read = cycle_cnt[63:32];
%000000                 `CSR_INSTRET : csr_debug_read = instret_cnt[31:0];
%000000                 `CSR_INSTRETH: csr_debug_read = instret_cnt[63:32];
%000000                 `CSR_DCSR    : csr_debug_read = dcsr_val;
%000000                 `CSR_DPC     : csr_debug_read = dpc_reg;
%000000                 `CSR_DSCRATCH0: csr_debug_read = dscratch0_reg;
                        `CSR_PMPCFG0,
%000000                 `CSR_PMPCFG1 : csr_debug_read = is_pmpcfg_csr(addr) ? pmpcfg_read(addr) : 32'h0;
                        `CSR_PMPADDR0,
                        `CSR_PMPADDR1,
                        `CSR_PMPADDR2,
                        `CSR_PMPADDR3,
                        `CSR_PMPADDR4,
                        `CSR_PMPADDR5,
                        `CSR_PMPADDR6,
%000000                 `CSR_PMPADDR7: csr_debug_read = is_pmpaddr_csr(addr) ?
%000000                                                 pmpaddr_r[pmp_index(addr)] : 32'h0;
                        `CSR_TSELECT,
                        `CSR_TDATA1,
                        `CSR_TDATA2,
%000000                 `CSR_TINFO   : csr_debug_read = trigger_debug_csr_rdata;
 001144                 default      : csr_debug_read = 32'h0;
                    endcase
                end
            endfunction
        
 001144     always @* begin
 001144         case (csr_raddr)
%000000             `CSR_MSTATUS : csr_rdata = mstatus_val;
%000000             `CSR_MISA    : csr_rdata = misa_val;
%000000             `CSR_MIE     : csr_rdata = mie_val;
%000000             `CSR_MTVEC   : csr_rdata = mtvec_val;
%000000             `CSR_MSCRATCH: csr_rdata = mscratch;
%000000             `CSR_MEPC    : csr_rdata = mepc_reg;
%000001             `CSR_MCAUSE  : csr_rdata = mcause_reg;
%000000             `CSR_MTVAL   : csr_rdata = mtval_val;
%000000             `CSR_MIP     : csr_rdata = mip_val;
%000000             `CSR_CYCLE   : csr_rdata = cycle_cnt[31:0];
%000000             `CSR_CYCLEH  : csr_rdata = cycle_cnt[63:32];
%000000             `CSR_INSTRET : csr_rdata = instret_cnt[31:0];
%000000             `CSR_INSTRETH: csr_rdata = instret_cnt[63:32];
%000000             `CSR_DCSR    : csr_rdata = dcsr_val;
%000000             `CSR_DPC     : csr_rdata = dpc_reg;
%000000             `CSR_DSCRATCH0: csr_rdata = dscratch0_reg;
                    `CSR_PMPCFG0,
%000000             `CSR_PMPCFG1 : csr_rdata = is_pmpcfg_csr(csr_raddr) ? pmpcfg_read(csr_raddr) : 32'h0;
                    `CSR_PMPADDR0,
                    `CSR_PMPADDR1,
                    `CSR_PMPADDR2,
                    `CSR_PMPADDR3,
                    `CSR_PMPADDR4,
                    `CSR_PMPADDR5,
                    `CSR_PMPADDR6,
%000000             `CSR_PMPADDR7: csr_rdata = is_pmpaddr_csr(csr_raddr) ?
%000000                                        pmpaddr_r[pmp_index(csr_raddr)] : 32'h0;
                    `CSR_TSELECT,
                    `CSR_TDATA1,
                    `CSR_TDATA2,
%000000             `CSR_TINFO   : csr_rdata = trigger_csr_rdata;
 001143             default      : csr_rdata = 32'h0;
                endcase
~001144         if (csr_we && (csr_waddr == csr_raddr)) begin
%000000             case (csr_waddr)
                        `CSR_MSTATUS,
                        `CSR_MIE,
                        `CSR_MTVEC,
                        `CSR_MSCRATCH,
                        `CSR_MEPC,
                        `CSR_MCAUSE,
                        `CSR_MTVAL,
                        `CSR_DPC,
                        `CSR_DSCRATCH0,
                        `CSR_PMPCFG0,
                        `CSR_PMPCFG1,
                        `CSR_PMPADDR0,
                        `CSR_PMPADDR1,
                        `CSR_PMPADDR2,
                        `CSR_PMPADDR3,
                        `CSR_PMPADDR4,
                        `CSR_PMPADDR5,
                        `CSR_PMPADDR6,
                        `CSR_PMPADDR7,
                        `CSR_TSELECT,
                        `CSR_TDATA1,
                        `CSR_TDATA2,
%000000                 `CSR_TINFO: begin
%000000                     if (is_trigger_csr(csr_waddr))
%000000                         csr_rdata = trigger_csr_rdata;
%000000                     else if (is_pmpcfg_csr(csr_waddr))
%000000                         csr_rdata = new_val;
%000000                     else if (is_pmpaddr_csr(csr_waddr))
%000000                         csr_rdata = new_val;
                            else
%000000                         csr_rdata = new_val;
                        end
%000000                 `CSR_DCSR: csr_rdata = {4'h4, 12'h0, new_val[15], 3'h0, 1'b0, 2'b0,
%000000                                         new_val[8:6], 3'h0, new_val[2], 2'b11};
                        // verilator coverage_off
                        default: ;
                        // verilator coverage_on
                        // ^ CS-COV-1 exclusion: every writable CSR is in the bypass list; reachable only via RO-addr writes which trap — CS-COV-1
                    endcase
                end
            end
        
            // -------------------------------------------------------------------------
            // 3. Compute "next value" for whichever CSR is being written this cycle
            //    (CSRRW/RS/RC 對任何 CSR 行為一致，只是 set/clear/swap 差異)
            // -------------------------------------------------------------------------
 001144     always @* begin
 001144         case (csr_op)
 000340             `CSR_OP_W : new_val = csr_wdata;
 000123             `CSR_OP_S : new_val = csr_old_val | csr_wdata;
 000257             `CSR_OP_C : new_val = csr_old_val & ~csr_wdata;
 000424             default   : new_val = csr_old_val;
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
 001139     always @(posedge clk) begin
 001114         if (!resetn) begin
 000025             mie_meie     <= 1'b0;
 000025             mie_mtie     <= 1'b0;          // ADR-0019
 000025             mie_msie     <= 1'b0;          // ADR-0019
 000025             mstatus_mie  <= 1'b0;          // 重置時 IRQ 關閉，要靠軟體開
 000025             mstatus_mpie <= 1'b0;
 000025             mtvec_base   <= 30'b0;
 000025             mscratch     <= 32'b0;
 000025             mepc_reg     <= 32'b0;
 000025             mcause_reg   <= 32'b0;
 000025             mtval_reg    <= 32'b0;
 000025             ext_pending  <= 1'b0;
 000025             dpc_reg      <= 32'b0;
 000025             dscratch0_reg <= 32'b0;
 000025             dcsr_step_reg <= 1'b0;
 000025             dcsr_ebreakm_reg <= 1'b0;
 000025             dcsr_cause_reg <= 3'b0;
 000025             cycle_cnt    <= 64'b0;
 000025             instret_cnt  <= 64'b0;
 000200             for (pmp_i = 0; pmp_i < 8; pmp_i = pmp_i + 1) begin
 000200                 pmpcfg_r[pmp_i]  <= 8'h00;
 000200                 pmpaddr_r[pmp_i] <= 32'h0;
                    end
 001114         end else begin
                    // 4.1 cycle 永遠 +1 (CSR write 不影響)
 001114             cycle_cnt <= cycle_cnt + 1'b1;
        
                    // 4.2 instret 在每條完成 +1
 000709             if (instr_retired)
 000405                 instret_cnt <= instret_cnt + 1'b1;
        
                    // 4.3 軟體 CSR 寫入 (CSR* 指令)
                    //     只 patch 對應位址的 register；RO 位址寫入忽略
~001114             if (csr_we) begin
%000000                 case (csr_waddr)
%000000                     `CSR_MSTATUS : begin
%000000                         mstatus_mie  <= new_val[`MSTATUS_MIE_BIT];
%000000                         mstatus_mpie <= new_val[`MSTATUS_MPIE_BIT];
                                // mstatus.MPP is read-only WARL=M (M-only hart, ADR-0015): write ignored
                            end
%000000                     `CSR_MIE     : begin
%000000                         mie_meie <= new_val[`MIE_MEIE_BIT];
%000000                         mie_mtie <= new_val[`MIE_MTIE_BIT];   // ADR-0019
%000000                         mie_msie <= new_val[`MIE_MSIE_BIT];   // ADR-0019
                            end
%000000                     `CSR_MTVEC   : mtvec_base  <= new_val[31:2];
%000000                     `CSR_MSCRATCH: mscratch    <= new_val;
%000000                     `CSR_MEPC    : mepc_reg    <= {new_val[31:1], 1'b0};
%000000                     `CSR_MCAUSE  : mcause_reg  <= new_val;
%000000                     `CSR_MTVAL   : mtval_reg   <= new_val;
%000000                     `CSR_DPC     : dpc_reg     <= {new_val[31:1], 1'b0};
%000000                     `CSR_DSCRATCH0: dscratch0_reg <= new_val;
%000000                     `CSR_PMPCFG0: if (PMP_ENTRIES != 0) begin
%000000                         for (pmp_i = 0; pmp_i < 4; pmp_i = pmp_i + 1)
%000000                             if (!pmpcfg_r[pmp_i][7])
%000000                                 pmpcfg_r[pmp_i] <= new_val[pmp_i*8 +: 8];
                            end
%000000                     `CSR_PMPCFG1: if (PMP_ENTRIES > 4) begin
%000000                         for (pmp_i = 0; pmp_i < 4; pmp_i = pmp_i + 1)
%000000                             if (!pmpcfg_r[pmp_i + 4][7])
%000000                                 pmpcfg_r[pmp_i + 4] <= new_val[pmp_i*8 +: 8];
                            end
                            `CSR_PMPADDR0,
                            `CSR_PMPADDR1,
                            `CSR_PMPADDR2,
                            `CSR_PMPADDR3,
                            `CSR_PMPADDR4,
                            `CSR_PMPADDR5,
                            `CSR_PMPADDR6,
%000000                     `CSR_PMPADDR7: if (is_pmpaddr_csr(csr_waddr) &&
%000000                                        !pmpcfg_r[pmp_index(csr_waddr)][7]) begin
%000000                         pmpaddr_r[pmp_index(csr_waddr)] <= new_val;
                            end
%000000                     `CSR_DCSR    : begin
%000000                         dcsr_ebreakm_reg <= new_val[15];
%000000                         dcsr_cause_reg   <= new_val[8:6];
%000000                         dcsr_step_reg    <= new_val[2];
                            end
                            // 其他 (MIP / counters / unknown) 忽略
                            // verilator coverage_off
                            default      : ;
                            // verilator coverage_on
                            // ^ CS-COV-1 exclusion: writes to unlisted/RO CSR addrs are ignored by the DUT but trap on the reference model — unreachable for legal traffic
                        endcase
                    end
        
~001114             if (debug_csr_we) begin
%000000                 case (debug_csr_waddr)
%000000                     `CSR_MSTATUS : begin
%000000                         mstatus_mie  <= debug_csr_wdata[`MSTATUS_MIE_BIT];
%000000                         mstatus_mpie <= debug_csr_wdata[`MSTATUS_MPIE_BIT];
                            end
%000000                     `CSR_MIE     : begin
%000000                         mie_meie <= debug_csr_wdata[`MIE_MEIE_BIT];
%000000                         mie_mtie <= debug_csr_wdata[`MIE_MTIE_BIT];
%000000                         mie_msie <= debug_csr_wdata[`MIE_MSIE_BIT];
                            end
%000000                     `CSR_MTVEC   : mtvec_base  <= debug_csr_wdata[31:2];
%000000                     `CSR_MSCRATCH: mscratch    <= debug_csr_wdata;
%000000                     `CSR_MEPC    : mepc_reg    <= {debug_csr_wdata[31:1], 1'b0};
%000000                     `CSR_MCAUSE  : mcause_reg  <= debug_csr_wdata;
%000000                     `CSR_MTVAL   : mtval_reg   <= debug_csr_wdata;
%000000                     `CSR_DPC     : dpc_reg     <= {debug_csr_wdata[31:1], 1'b0};
%000000                     `CSR_DSCRATCH0: dscratch0_reg <= debug_csr_wdata;
%000000                     `CSR_PMPCFG0: if (PMP_ENTRIES != 0) begin
%000000                         for (pmp_i = 0; pmp_i < 4; pmp_i = pmp_i + 1)
%000000                             if (!pmpcfg_r[pmp_i][7])
%000000                                 pmpcfg_r[pmp_i] <= debug_csr_wdata[pmp_i*8 +: 8];
                            end
%000000                     `CSR_PMPCFG1: if (PMP_ENTRIES > 4) begin
%000000                         for (pmp_i = 0; pmp_i < 4; pmp_i = pmp_i + 1)
%000000                             if (!pmpcfg_r[pmp_i + 4][7])
%000000                                 pmpcfg_r[pmp_i + 4] <= debug_csr_wdata[pmp_i*8 +: 8];
                            end
                            `CSR_PMPADDR0,
                            `CSR_PMPADDR1,
                            `CSR_PMPADDR2,
                            `CSR_PMPADDR3,
                            `CSR_PMPADDR4,
                            `CSR_PMPADDR5,
                            `CSR_PMPADDR6,
%000000                     `CSR_PMPADDR7: if (is_pmpaddr_csr(debug_csr_waddr) &&
%000000                                        !pmpcfg_r[pmp_index(debug_csr_waddr)][7]) begin
%000000                         pmpaddr_r[pmp_index(debug_csr_waddr)] <= debug_csr_wdata;
                            end
%000000                     `CSR_DCSR    : begin
%000000                         dcsr_ebreakm_reg <= debug_csr_wdata[15];
%000000                         dcsr_cause_reg   <= debug_csr_wdata[8:6];
%000000                         dcsr_step_reg    <= debug_csr_wdata[2];
                            end
%000000                     default: ;
                        endcase
                    end
        
                    // 4.4 硬體 trap entry / exit
                    //     core.v 保證 trap_enter / trap_exit / csr_we 三者互斥；
                    //     不過 trap_enter 在源碼順序上放在 csr_we 後面，
                    //     就算同 cycle 都 fire 也是 trap_enter 路徑的 NBA 寫贏。
%000005             if (trap_enter) begin
%000005                 mepc_reg     <= trap_pc;
%000005                 mcause_reg   <= trap_cause;
%000005                 mtval_reg    <= trap_mtval;
%000005                 mstatus_mpie <= mstatus_mie;
%000005                 mstatus_mie  <= 1'b0;
~001109             end else if (trap_exit) begin
%000000                 mstatus_mie  <= mstatus_mpie;
%000000                 mstatus_mpie <= 1'b1;            // spec: MPIE <- 1 after mret
                    end
        
~001114             if (debug_halt_enter) begin
%000000                 dpc_reg         <= {debug_halt_pc[31:1], 1'b0};
%000000                 dcsr_cause_reg  <= debug_halt_cause;
                    end
        
                    // 4.5 ext_pending 三優先級邏輯 (trap_enter > pulse > hold)
                    //     - trap_enter → clear (hardware ack)
                    //     - 新 pulse 進來且沒有同拍 trap_enter → set
                    //     - 其他保持
                    //     寫成一條 mux 而不是兩個 if，邏輯 + timing 都比較乾淨
 001114             ext_pending <=
~001114                 trap_enter         ? 1'b0 :
~001109                 irq_external_pulse ? 1'b1 :
 001109                                      ext_pending;
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
            genvar pmp_g;
            generate
%000000         for (pmp_g = 0; pmp_g < 8; pmp_g = pmp_g + 1) begin : g_pmp_flatten
%000000             assign pmp_cfg_o[pmp_g*8 +: 8] = ((PMP_ENTRIES != 0) && (pmp_g < PMP_ENTRIES)) ?
~000040                                              pmpcfg_r[pmp_g] : 8'h00;
%000000             assign pmp_addr_o[pmp_g*32 +: 32] = ((PMP_ENTRIES != 0) && (pmp_g < PMP_ENTRIES)) ?
~000040                                                 pmpaddr_r[pmp_g] : 32'h0;
                end
            endgenerate
        
            // Interrupt arbitration (ADR-0019). mip[3,7,11] are CLINT/ext-sourced (RO to CSR
            // writes); only mie + mstatus.MIE gate delivery. Priority MEI > MSI > MTI (priv spec).
%000000     wire irq_mei = (ext_pending | meip) & mie_meie;  // M external: legacy pulse-sticky OR PLIC level (ADR-0020)
%000000     wire irq_msi = msip        & mie_msie;   // M software
%000000     wire irq_mti = mtip        & mie_mtie;   // M timer (lowest)
            assign irq_pending = (irq_mei | irq_msi | irq_mti) & mstatus_mie;
~001144     assign irq_cause   = irq_mei ? `MCAUSE_EXT_IRQ   :
~001144                          irq_msi ? `MCAUSE_MSW_IRQ   :
 001144                                    `MCAUSE_TIMER_IRQ;
        
        endmodule
        
