//      // verilator_coverage annotation
        // =============================================================================
        // trigger.v -- ADR-0022 RISC-V debug trigger module
        // -----------------------------------------------------------------------------
        // Four mcontrol6 triggers:
        //   trigger 0..1 : execute address match
        //   trigger 2..3 : load/store address match
        //
        // Supported fields are intentionally small and WARL-filtered:
        //   type=6, match=0 exact, action=1 debug, m=1, chain=0, select=0 address.
        //   mcontrol6.hit0 is set when the trigger fires and is writable for clear.
        // =============================================================================
        
        `include "def.vh"
        
        module trigger (
 001139     input             clk,
%000005     input             resetn,
        
 000104     input      [11:0] csr_raddr,
%000000     output reg [31:0] csr_rdata,
%000000     input             csr_we,
 000104     input      [11:0] csr_waddr,
~000045     input      [31:0] csr_wdata,
        
%000000     input      [11:0] debug_csr_raddr,
%000000     output reg [31:0] debug_csr_rdata,
%000000     input             debug_csr_we,
%000000     input      [11:0] debug_csr_waddr,
%000000     input      [31:0] debug_csr_wdata,
        
 000024     input             ex_valid,
~000200     input      [31:0] ex_pc,
 000018     input             ex_is_16bit,
%000000     output            ex_trigger_hit,
%000005     output     [ 1:0] ex_trigger_idx,
        
 000024     input             mem_valid,
 000029     input             mem_is_load,
 000028     input             mem_is_store,
 000101     input      [31:0] mem_addr,
~000051     input      [ 2:0] mem_size,
%000000     output            mem_trigger_hit,
%000005     output     [ 1:0] mem_trigger_idx,
%000000     output            mem_trigger_is_load,
%000000     output            mem_trigger_is_store,
        
%000000     input             fire_valid,
 000024     input      [ 1:0] fire_idx
        );
            localparam [31:0] TINFO_MCONTROL6 = 32'h0000_0040;
            localparam [31:0] TYPE_MCONTROL6  = 32'h6000_0000;
        
%000000     reg [1:0]  tselect_r;
%000000     reg [31:0] tdata1_r [0:3];
%000000     reg [31:0] tdata2_r [0:3];
%000000     reg [3:0]  suppress_r;
        
            integer i;
        
%000000     function is_trigger_csr;
                input [11:0] addr;
%000000         begin
%000000             is_trigger_csr = (addr == `CSR_TSELECT) ||
%000000                              (addr == `CSR_TDATA1)  ||
%000000                              (addr == `CSR_TDATA2)  ||
%000000                              (addr == `CSR_TINFO);
                end
            endfunction
        
%000000     function [31:0] legal_tdata1;
                input [31:0] wdata;
                input [1:0]  idx;
                input        cur_hit0;
%000000         reg          want_type6;
%000000         reg          exec_slot;
%000000         reg          data_slot;
%000000         reg          en_action_debug;
%000000         reg          en_m;
%000000         reg          want_exec;
%000000         reg          want_load;
%000000         reg          want_store;
%000000         begin
%000000             want_type6      = (wdata[31:28] == 4'h6);
%000000             exec_slot       = (idx < 2'd2);
%000000             data_slot       = !exec_slot;
%000000             en_action_debug = (wdata[15:12] == 4'h1);
%000000             en_m            = wdata[6];
%000000             want_exec       = exec_slot && wdata[2];
%000000             want_load       = data_slot && wdata[0];
%000000             want_store      = data_slot && wdata[1];
        
%000000             if (!want_type6) begin
%000000                 legal_tdata1 = 32'h0;
%000000             end else begin
%000000                 legal_tdata1 = TYPE_MCONTROL6;
%000000                 legal_tdata1[27]    = wdata[27];      // dmode
%000000                 legal_tdata1[22]    = wdata[22] | cur_hit0;
%000000                 legal_tdata1[18:16] = wdata[18:16];   // size
%000000                 legal_tdata1[15:12] = en_action_debug ? 4'h1 : 4'h0;
%000000                 legal_tdata1[10:7]  = 4'h0;           // exact only
%000000                 legal_tdata1[6]     = en_m;
%000000                 legal_tdata1[2]     = want_exec;
%000000                 legal_tdata1[1]     = want_store;
%000000                 legal_tdata1[0]     = want_load;
                    end
                end
            endfunction
        
 005424     function slot_enabled;
                input [1:0] idx;
 005424         begin
 005424             slot_enabled = (tdata1_r[idx][31:28] == 4'h6) &&
 005424                            (tdata1_r[idx][15:12] == 4'h1) &&
~005424                            (tdata1_r[idx][10:7] == 4'h0) &&
 005424                            tdata1_r[idx][6];
                end
            endfunction
        
%000000     function size_match;
                input [2:0] cfg_size;
                input [2:0] actual_size;
%000000         begin
%000000             size_match = (cfg_size == 3'd0) || (cfg_size == actual_size);
                end
            endfunction
        
            // M1A lint fix (Spyglass W122, same class as pmp.v): module state is passed as
            // explicit function inputs so every read is visible to @* sensitivity inference.
%000000     wire [31:0] trig_tdata1_sel = tdata1_r[tselect_r];
%000000     wire [31:0] trig_tdata2_sel = tdata2_r[tselect_r];
        
 002288     function [31:0] read_csr;
                input [11:0] addr;
                input [ 1:0] tsel;
                input [31:0] td1_sel;
                input [31:0] td2_sel;
 002288         begin
 002288             case (addr)
%000000                 `CSR_TSELECT: read_csr = {30'h0, tsel};
%000000                 `CSR_TDATA1 : read_csr = td1_sel;
%000000                 `CSR_TDATA2 : read_csr = td2_sel;
%000000                 `CSR_TINFO  : read_csr = TINFO_MCONTROL6;
 002288                 default     : read_csr = 32'h0;
                    endcase
                end
            endfunction
        
~001108     wire [2:0] ex_size = ex_is_16bit ? 3'd2 : 3'd3;
        
%000000     wire ex_hit0 = ex_valid && slot_enabled(2'd0) && tdata1_r[0][2] &&
                           !suppress_r[0] && size_match(tdata1_r[0][18:16], ex_size) &&
                           (ex_pc == tdata2_r[0]);
%000000     wire ex_hit1 = ex_valid && slot_enabled(2'd1) && tdata1_r[1][2] &&
                           !suppress_r[1] && size_match(tdata1_r[1][18:16], ex_size) &&
                           (ex_pc == tdata2_r[1]);
            assign ex_trigger_hit = ex_hit0 | ex_hit1;
~001144     assign ex_trigger_idx = ex_hit0 ? 2'd0 : 2'd1;
        
%000000     wire mem_hit2_ld = mem_valid && mem_is_load && slot_enabled(2'd2) && tdata1_r[2][0] &&
                               !suppress_r[2] && size_match(tdata1_r[2][18:16], mem_size) &&
                               (mem_addr == tdata2_r[2]);
%000000     wire mem_hit2_st = mem_valid && mem_is_store && slot_enabled(2'd2) && tdata1_r[2][1] &&
                               !suppress_r[2] && size_match(tdata1_r[2][18:16], mem_size) &&
                               (mem_addr == tdata2_r[2]);
%000000     wire mem_hit3_ld = mem_valid && mem_is_load && slot_enabled(2'd3) && tdata1_r[3][0] &&
                               !suppress_r[3] && size_match(tdata1_r[3][18:16], mem_size) &&
                               (mem_addr == tdata2_r[3]);
%000000     wire mem_hit3_st = mem_valid && mem_is_store && slot_enabled(2'd3) && tdata1_r[3][1] &&
                               !suppress_r[3] && size_match(tdata1_r[3][18:16], mem_size) &&
                               (mem_addr == tdata2_r[3]);
        
            assign mem_trigger_hit      = mem_hit2_ld | mem_hit2_st | mem_hit3_ld | mem_hit3_st;
~001144     assign mem_trigger_idx      = (mem_hit2_ld | mem_hit2_st) ? 2'd2 : 2'd3;
            assign mem_trigger_is_load  = mem_hit2_ld | mem_hit3_ld;
            assign mem_trigger_is_store = mem_hit2_st | mem_hit3_st;
        
 001144     always @* begin
 001144         csr_rdata = read_csr(csr_raddr, tselect_r, trig_tdata1_sel, trig_tdata2_sel);
~001144         if (csr_we && (csr_waddr == csr_raddr) && is_trigger_csr(csr_waddr)) begin
%000000             if (csr_waddr == `CSR_TSELECT)
%000000                 csr_rdata = (csr_wdata[31:2] == 30'h0) ? {30'h0, csr_wdata[1:0]} : {30'h0, tselect_r};
%000000             else if (csr_waddr == `CSR_TDATA1)
%000000                 csr_rdata = legal_tdata1(csr_wdata, tselect_r, 1'b0);
%000000             else if (csr_waddr == `CSR_TDATA2)
%000000                 csr_rdata = csr_wdata;
                end
            end
        
 001144     always @* begin
 001144         debug_csr_rdata = read_csr(debug_csr_raddr, tselect_r, trig_tdata1_sel, trig_tdata2_sel);
~001144         if (debug_csr_we && (debug_csr_waddr == debug_csr_raddr) && is_trigger_csr(debug_csr_waddr)) begin
%000000             if (debug_csr_waddr == `CSR_TSELECT)
%000000                 debug_csr_rdata = (debug_csr_wdata[31:2] == 30'h0) ? {30'h0, debug_csr_wdata[1:0]} : {30'h0, tselect_r};
%000000             else if (debug_csr_waddr == `CSR_TDATA1)
%000000                 debug_csr_rdata = legal_tdata1(debug_csr_wdata, tselect_r, 1'b0);
%000000             else if (debug_csr_waddr == `CSR_TDATA2)
%000000                 debug_csr_rdata = debug_csr_wdata;
                end
            end
        
 001139     always @(posedge clk) begin
 001114         if (!resetn) begin
 000025             tselect_r  <= 2'd0;
 000025             suppress_r <= 4'h0;
 000100             for (i = 0; i < 4; i = i + 1) begin
 000100                 tdata1_r[i] <= 32'h0;
 000100                 tdata2_r[i] <= 32'h0;
                    end
 001114         end else begin
 004456             for (i = 0; i < 4; i = i + 1) begin
~004456                 if (!slot_enabled(i[1:0]))
 004456                     suppress_r[i] <= 1'b0;
                    end
        
 000699             if (ex_valid) begin
~000410                 if (ex_pc != tdata2_r[0]) suppress_r[0] <= 1'b0;
~000410                 if (ex_pc != tdata2_r[1]) suppress_r[1] <= 1'b0;
                    end
 000704             if (mem_valid) begin
 000341                 if (mem_addr != tdata2_r[2]) suppress_r[2] <= 1'b0;
 000341                 if (mem_addr != tdata2_r[3]) suppress_r[3] <= 1'b0;
                    end
        
~001114             if (csr_we && is_trigger_csr(csr_waddr)) begin
%000000                 case (csr_waddr)
%000000                     `CSR_TSELECT: if (csr_wdata[31:2] == 30'h0) tselect_r <= csr_wdata[1:0];
%000000                     `CSR_TDATA1: begin
%000000                         tdata1_r[tselect_r] <= legal_tdata1(csr_wdata, tselect_r, 1'b0);
%000000                         if (csr_wdata[31:28] != 4'h6)
%000000                             suppress_r[tselect_r] <= 1'b0;
                            end
%000000                     `CSR_TDATA2: begin
%000000                         tdata2_r[tselect_r] <= csr_wdata;
%000000                         suppress_r[tselect_r] <= 1'b0;
                            end
%000000                     default: ;
                        endcase
                    end
        
~001114             if (debug_csr_we && is_trigger_csr(debug_csr_waddr)) begin
%000000                 case (debug_csr_waddr)
%000000                     `CSR_TSELECT: if (debug_csr_wdata[31:2] == 30'h0) tselect_r <= debug_csr_wdata[1:0];
%000000                     `CSR_TDATA1: begin
%000000                         tdata1_r[tselect_r] <= legal_tdata1(debug_csr_wdata, tselect_r, 1'b0);
%000000                         if (debug_csr_wdata[31:28] != 4'h6)
%000000                             suppress_r[tselect_r] <= 1'b0;
                            end
%000000                     `CSR_TDATA2: begin
%000000                         tdata2_r[tselect_r] <= debug_csr_wdata;
%000000                         suppress_r[tselect_r] <= 1'b0;
                            end
%000000                     default: ;
                        endcase
                    end
        
~001114             if (fire_valid) begin
%000000                 suppress_r[fire_idx] <= 1'b1;
%000000                 tdata1_r[fire_idx][22] <= 1'b1;
                    end
                end
            end
        endmodule
        
