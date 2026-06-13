//      // verilator_coverage annotation
        // =============================================================================
        // forward.v — Lab06b 4-stage forwarding mux (2 sources: EX/MEM + EX/WB)
        // -----------------------------------------------------------------------------
        // lab06b 把 lab06 的 3-stage 拆成 4-stage (加 ex_mem register)。Forward 也對應變成
        // 2 source:
        //   1. EX/MEM stage 的 alu_result (1 cycle ahead, registered)
        //   2. EX/WB stage 的 wb_data    (2 cycles ahead, includes load via wb_data mux)
        //   3. RFU 直接讀                (fallback)
        //
        // 優先級：EX/MEM > EX/WB > RFU
        //
        // 不 forward load 的原因 (同 lab06)：load 的 wb_data 由 mem_rdata → LSU → wb mux 組成，
        // 組合鏈長。EX/MEM stage 的 load 也不能 forward (此時 alu_result 是 addr 不是 load value)
        // → 走 stall (2-cycle now: load 在 EX/MEM stay 1 cycle, 然後 WB stage 才有 lsu 結果)
        // =============================================================================
        
        `include "def.vh"
        
        module forward (
            // ID/EX stage 想要的 rs index
 000074     input  [ 4:0] id_rs1_idx,
 000104     input  [ 4:0] id_rs2_idx,
        
            // 從 RFU 組合讀出的「舊」值
~000063     input  [31:0] rfu_rs1_data,
~000076     input  [31:0] rfu_rs2_data,
        
            // EX/MEM stage 的寫回資訊 (1 cycle ahead)
 000024     input         em_valid,
 000051     input         em_rd_we,
 000133     input  [ 4:0] em_rd_idx,
 000097     input  [31:0] em_fwd_val,      // = alu_result 或 pc_plus_4 / pc_plus_imm / csr / md
 000036     input         em_is_load,      // value-not-ready-in-MEM class: load (alu_result=addr)
                                             // OR M1A pipelined MUL (product lands at WB) — caller ORs both
        
            // EX/WB stage 的寫回資訊 (2 cycles ahead, 但 load 可以 forward 因為 wb_data 已 mux)
 000024     input         wb_valid,
 000048     input         wb_rd_we,
 000133     input  [ 4:0] wb_rd_idx,
 000094     input  [31:0] wb_data,
 000029     input         wb_is_load,
        
            // Forwarded operand 給 ALU 用
~000058     output [31:0] rs1_val,
~000080     output [31:0] rs2_val
        );
        
            // EX/MEM forward (priority 1, closer)
 000065     wire em_fwd_ok  = em_valid && em_rd_we && !em_is_load && (em_rd_idx != 5'd0);
 000016     wire em_fwd_rs1 = em_fwd_ok && (id_rs1_idx == em_rd_idx);
 000013     wire em_fwd_rs2 = em_fwd_ok && (id_rs2_idx == em_rd_idx);
        
            // EX/WB forward (priority 2, further)
            // load 在 WB 可以 forward 因為 wb_data mux 已含 lsu sign-ext 結果
            // (代價：critical path 11.7 ns @ 85 MHz)
 000048     wire wb_fwd_ok  = wb_valid && wb_rd_we && (wb_rd_idx != 5'd0);
%000006     wire wb_fwd_rs1 = wb_fwd_ok && !em_fwd_rs1 && (id_rs1_idx == wb_rd_idx);
%000009     wire wb_fwd_rs2 = wb_fwd_ok && !em_fwd_rs2 && (id_rs2_idx == wb_rd_idx);
        
            /* verilator lint_off UNUSEDSIGNAL */
            wire _unused_wb_is_load = wb_is_load;
            /* verilator lint_on UNUSEDSIGNAL */
        
 001128     assign rs1_val = em_fwd_rs1 ? em_fwd_val :
~001122                      wb_fwd_rs1 ? wb_data    :
 001122                                   rfu_rs1_data;
        
 001131     assign rs2_val = em_fwd_rs2 ? em_fwd_val :
~001122                      wb_fwd_rs2 ? wb_data    :
 001122                                   rfu_rs2_data;
        
        endmodule
        
