//      // verilator_coverage annotation
        `timescale 1ns / 1ns
        
        module tb_csr_irq_coverage;
~000346     reg         clk = 1'b0;
%000001     reg         resetn = 1'b0;
%000001     reg         irq_external_pulse = 1'b0;
%000000     wire        trap;
~000022     wire [31:0] i_mem_addr;
%000001     wire        i_mem_en;
~000015     reg  [31:0] i_mem_rdata;
 000012     wire        d_mem_valid;
~000014     wire [31:0] d_mem_addr;
%000006     wire [31:0] d_mem_wdata;
 000012     wire [ 3:0] d_mem_wstrb;
%000004     reg  [31:0] d_mem_rdata;
~000021     wire [31:0] dbg_pc;
~000018     wire [31:0] dbg_instr;
%000007     wire [ 2:0] dbg_state;
        
            localparam MEM_SIZE = 4096;
            localparam MCAUSE_EXT_IRQ = 32'h8000_000b;
            localparam MSTATUS_TRAP_SNAPSHOT = 32'h0000_0080;
        
            reg [31:0] memory [0:MEM_SIZE-1];
%000001     initial $readmemh("firmware.hex", memory);
        
~000022     wire [11:0] i_word_idx = i_mem_addr[13:2];
%000009     wire [11:0] d_word_idx = d_mem_addr[13:2];
 000014     wire        d_is_mmio = d_mem_addr[28];
~000015     wire [31:0] mmio_off = d_mem_addr - 32'h1000_0000;
        
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
                .irq_external_pulse (irq_external_pulse),
                .dbg_pc             (dbg_pc),
                .dbg_instr          (dbg_instr),
                .dbg_state          (dbg_state)
            );
        
 000691     always #5 clk = ~clk;
        
 000346     always @(posedge clk) begin
~000346         if (i_mem_en) i_mem_rdata <= memory[i_word_idx];
        
 000334         if (d_mem_valid) begin
 000012             d_mem_rdata <= memory[d_word_idx];
~000012             if (!d_is_mmio && |d_mem_wstrb) begin
%000000                 if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
%000000                 if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
%000000                 if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
%000000                 if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
                    end
                end
            end
        
%000001     reg injected_irq;
%000001     reg saw_mscratch_w;
%000001     reg saw_mscratch_s;
%000001     reg saw_mscratch_c;
%000001     reg saw_mscratch_final;
%000001     reg saw_unknown_zero;
%000001     reg saw_cycle;
%000001     reg saw_instret;
%000001     reg saw_pending_mip;
%000001     reg saw_handler_mepc;
%000001     reg saw_handler_mcause;
%000001     reg saw_handler_mstatus;
%000001     reg saw_resume;
        
%000001     reg [31:0] handler_mepc;
        
%000001     initial begin
%000001         injected_irq = 1'b0;
%000001         saw_mscratch_w = 1'b0;
%000001         saw_mscratch_s = 1'b0;
%000001         saw_mscratch_c = 1'b0;
%000001         saw_mscratch_final = 1'b0;
%000001         saw_unknown_zero = 1'b0;
%000001         saw_cycle = 1'b0;
%000001         saw_instret = 1'b0;
%000001         saw_pending_mip = 1'b0;
%000001         saw_handler_mepc = 1'b0;
%000001         saw_handler_mcause = 1'b0;
%000001         saw_handler_mstatus = 1'b0;
%000001         saw_resume = 1'b0;
%000001         handler_mepc = 32'h0;
            end
        
 000345     always @(negedge clk) begin
~000344         if (resetn && saw_instret && !injected_irq && dbg_instr == 32'h0000_0013) begin
%000001             irq_external_pulse <= 1'b1;
%000001             injected_irq <= 1'b1;
%000001             $display("[%0t ns] inject pending IRQ at pc=%08x instr=%08x", $time, dbg_pc, dbg_instr);
 000344         end else begin
 000344             irq_external_pulse <= 1'b0;
                end
            end
        
%000008     task check_store;
                input [31:0] got;
                input [31:0] exp;
                input [255:0] label;
%000008         begin
%000008             if (got !== exp) begin
                        $display("FAIL: %0s got=%08x expected=%08x", label, got, exp);
                        $fatal(1);
                    end
                end
            endtask
        
 000346     always @(posedge clk) begin
 000346         if (trap) begin
                    $display("FAIL: illegal trap pin asserted");
                    $fatal(1);
                end
        
 000334         if (d_mem_valid && d_is_mmio && |d_mem_wstrb) begin
 000012             $display("[%0t ns] mmio[%08x] <= %08x", $time, mmio_off, d_mem_wdata);
 000012             case (mmio_off)
%000001                 32'h00: begin
%000001                     check_store(d_mem_wdata, 32'h0000_0000, "csrrw old mscratch");
%000001                     saw_mscratch_w <= 1'b1;
                        end
%000001                 32'h04: begin
%000001                     check_store(d_mem_wdata, 32'h1234_5678, "csrrs old mscratch");
%000001                     saw_mscratch_s <= 1'b1;
                        end
%000001                 32'h08: begin
%000001                     check_store(d_mem_wdata, 32'h1234_567f, "csrrc old mscratch");
%000001                     saw_mscratch_c <= 1'b1;
                        end
%000001                 32'h0c: begin
%000001                     check_store(d_mem_wdata, 32'h1234_5677, "final mscratch");
%000001                     saw_mscratch_final <= 1'b1;
                        end
%000001                 32'h10: begin
%000001                     check_store(d_mem_wdata, 32'h0000_0000, "unknown CSR read");
%000001                     saw_unknown_zero <= 1'b1;
                        end
%000001                 32'h14: begin
%000001                     if (d_mem_wdata == 32'h0) begin
                                $display("FAIL: cycle CSR did not increment");
                                $fatal(1);
                            end
%000001                     saw_cycle <= 1'b1;
                        end
%000001                 32'h18: begin
%000001                     if (d_mem_wdata == 32'h0) begin
                                $display("FAIL: instret CSR did not increment");
                                $fatal(1);
                            end
%000001                     saw_instret <= 1'b1;
                        end
%000001                 32'h1c: begin
%000001                     check_store(d_mem_wdata, 32'h0000_0800, "pending mip.MEIP");
%000001                     saw_pending_mip <= 1'b1;
                        end
%000001                 32'h20: begin
%000001                     if (d_mem_wdata == 32'h0) begin
                                $display("FAIL: handler mepc was zero");
                                $fatal(1);
                            end
%000001                     handler_mepc <= d_mem_wdata;
%000001                     saw_handler_mepc <= 1'b1;
                        end
%000001                 32'h24: begin
%000001                     check_store(d_mem_wdata, MCAUSE_EXT_IRQ, "handler mcause");
%000001                     saw_handler_mcause <= 1'b1;
                        end
%000001                 32'h28: begin
%000001                     check_store(d_mem_wdata, MSTATUS_TRAP_SNAPSHOT, "handler mstatus");
%000001                     saw_handler_mstatus <= 1'b1;
                        end
%000001                 32'h2c: begin
%000001                     $display("[%0t ns] mret resume marker observed data=%08x", $time, d_mem_wdata);
%000001                     saw_resume <= 1'b1;
                        end
                        default: begin
                            $display("FAIL: unexpected MMIO store offset=%08x data=%08x", mmio_off, d_mem_wdata);
                            $fatal(1);
                        end
                    endcase
                end
            end
        
%000001     initial begin
%000001         $dumpfile("wave.vcd");
%000001         if ($test$plusargs("full_vcd")) begin
%000000             $dumpvars(0, tb_csr_irq_coverage);
%000001         end else begin
%000001             $dumpvars(0, clk, resetn, irq_external_pulse, trap, injected_irq);
%000001             $dumpvars(0, i_mem_addr, i_mem_en, i_mem_rdata);
%000001             $dumpvars(0, d_mem_valid, d_mem_addr, d_mem_wdata, d_mem_wstrb);
%000001             $dumpvars(0, dbg_pc, dbg_instr, dbg_state);
%000001             $dumpvars(0, saw_mscratch_w, saw_mscratch_s, saw_mscratch_c,
                                 saw_mscratch_final, saw_unknown_zero, saw_cycle,
                                 saw_instret, saw_pending_mip, saw_handler_mepc,
                                 saw_handler_mcause, saw_handler_mstatus, saw_resume,
                                 handler_mepc);
%000001             $dumpvars(0, dut.u_csr.mstatus_mie, dut.u_csr.mstatus_mpie,
                                 dut.u_csr.mie_meie, dut.u_csr.ext_pending,
                                 dut.u_csr.mtvec_base, dut.u_csr.mscratch,
                                 dut.u_csr.mepc_reg, dut.u_csr.mcause_reg,
                                 dut.wb_take_irq, dut.wb_is_mret, dut.wb_trap_pc_for_mepc);
                end
%000001         $dumpoff;
        
%000006         repeat (6) @(posedge clk);
%000001         resetn = 1'b1;
        
%000001         $dumpon;
~000340         repeat (340) @(posedge clk);
%000001         $dumpoff;
        
%000001         if (!injected_irq || !saw_pending_mip || !saw_handler_mepc ||
                    !saw_handler_mcause || !saw_handler_mstatus || !saw_resume ||
                    !saw_mscratch_w || !saw_mscratch_s || !saw_mscratch_c ||
%000001             !saw_mscratch_final || !saw_unknown_zero || !saw_cycle ||
                    !saw_instret) begin
                    $display("FAIL: missing CSR/IRQ evidence injected=%0b pending=%0b mepc=%0b mcause=%0b mstatus=%0b resume=%0b",
                             injected_irq, saw_pending_mip, saw_handler_mepc,
                             saw_handler_mcause, saw_handler_mstatus, saw_resume);
                    $fatal(1);
                end
        
%000001         $display("PASS: directed CSR/IRQ coverage completed mepc=%08x", handler_mepc);
%000001         $finish;
            end
        
            initial begin
                #30_000;
                $display("FAIL: watchdog timeout");
                $fatal(1);
            end
        endmodule
        
