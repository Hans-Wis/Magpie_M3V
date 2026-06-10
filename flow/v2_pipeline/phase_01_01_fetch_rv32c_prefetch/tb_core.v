// =============================================================================
// tb_core.v -- Magpie_M1 Phase 1.1 Verilator smoke test
// -----------------------------------------------------------------------------
// 驗證：
//   1. firmware 正常跑 LED counter (跟 lab04 同邏輯)
//   2. 拉 btn1 → debounce 偵測 → core 進 trap → ISR (n=0) → mret → LED 從 0 重計
//
// 流程：
//   - 100 MHz clock, btn0 拉低 (硬 reset 透過 POR cnt 自動釋放)
//   - 跑 ~250 μs 看 LED 走到 3 或 4
//   - 在 ~250 μs 拉 btn1 高，維持夠久讓 debouncer (sim 用 DEBOUNCE_CYC=16) 觸發
//   - 預期：之後 LED 回到 0 再開始遞增
//
// PASS 條件：
//   * 不卡在 4'b1111 (即 IRQ 沒被當作 illegal)
//   * 觀察到「LED 計到 N → 突然 0 → 繼續計」的序列
// =============================================================================

`timescale 1ns / 1ns

module tb_core;
    reg        clk  = 1'b0;
    reg        btn0 = 1'b0;
    reg        btn1 = 1'b0;
    wire [3:0] led;

    // sim 用很短的 debounce，否則要等 1ms 還太久
    system_pynq #(.DEBOUNCE_CYC(16)) dut (
        .clk  (clk),
        .btn0 (btn0),
        .btn1 (btn1),
        .led  (led)
    );

    always #5 clk = ~clk;

    // ---- LED transition tracker ----
    reg [3:0] led_prev;
    integer   transitions;

    initial begin
        led_prev    = 4'bx;
        transitions = 0;
    end

    // ---- 自動偵測「IRQ 後 LED 從某值 N>0 跳回 0」事件 ----
    reg [3:0] led_before_irq;
    reg       saw_irq_reset;
    initial begin
        led_before_irq = 4'b1010;
        saw_irq_reset  = 1'b0;
    end

    always @(led) begin
        if (led !== led_prev) begin
            // Lab08e: trap is checked directly through dut.u_core.trap.
            // BP 加速後 LED 會跑到 15 然後 BTN1 在那拍按下，舊條件會 false-negative。
            if (led_prev !== 4'b1010 &&
                led_prev !== 4'b0000 && led === 4'b0000) begin
                led_before_irq = led_prev;
                saw_irq_reset  = 1'b1;
                $display("[%7t ns]  >>> IRQ reset: LED was %b, now 0",
                         $time, led_prev);
            end
            $display("[%7t ns]  LED  %b -> %b  pc=%08x  state=%b",
                     $time, led_prev, led, dut.dbg_pc, dut.dbg_state);
            led_prev    = led;
            transitions = transitions + 1;
        end
    end

    // ---- 主流程 ----
    initial begin
        $dumpfile("wave.vcd");
        if ($test$plusargs("full_vcd")) begin
            $dumpvars(0, tb_core);
        end else begin
            // Focused review VCD: enough for fetch/RV32C/IRQ smoke triage without
            // dumping the full hierarchy and memory contents.
            $dumpvars(0, clk, btn0, btn1, led, led_prev, transitions,
                         led_before_irq, saw_irq_reset);
            $dumpvars(0, dut.resetn, dut.btn1_pulse, dut.trap,
                         dut.i_mem_addr, dut.i_mem_en, dut.i_mem_rdata,
                         dut.d_mem_valid, dut.d_mem_addr, dut.d_mem_wdata,
                         dut.d_mem_wstrb, dut.out_byte_en, dut.out_byte,
                         dut.dbg_pc, dut.dbg_instr, dut.dbg_state);
        end
        $dumpoff;

        $display("================================================");
        $display(" Magpie_M1 Phase 1.1 -- lab08e 4-stage pipeline + BP/RAS + RV32IMC");
        $display(" clock: 100 MHz, btn0 held low");
        $display(" DEBOUNCE_CYC = 16 (override 100_000 for sim speed)");
        $display(" firmware DELAY_ITER = 200");
        $display(" Phase 1: 讓 LED 跑到 ~3");
        $display(" Phase 2: 拉 btn1 觸發 IRQ → 預期 LED 回 0");
        $display("================================================");

        // Review window 1: reset release + first instruction activity.
        $dumpon;
        #2_000;
        $dumpoff;

        // 跑到 IRQ 前。中間 LED transitions 已由 sim.log 完整記錄，不需要全量波形。
        #238_000;

        // Review window 2: pre-IRQ, BTN1 edge, trap/IRQ return, post-IRQ LED reset.
        $dumpon;
        #10_000;
        $display("[%7t ns]  *** Pressing BTN1 ***", $time);
        btn1 = 1'b1;
        #500;
        btn1 = 1'b0;
        $display("[%7t ns]  *** Releasing BTN1 ***", $time);
        #39_500;
        $dumpoff;

        // Finish the behavioral smoke run with log-only observation.
        #250_000;

        // ---- 結果判斷 ----
        $display("");
        $display("=== sim end @ %0t ns, final LED=%b, transitions=%0d ===",
                 $time, led, transitions);

        if (dut.u_core.trap === 1'b1) begin
            $display("FAIL: core trap pin asserted (illegal/ebreak)");
            $fatal(1);
        end else if (!saw_irq_reset) begin
            $display("FAIL: BTN1 IRQ didn't reset LED");
            $fatal(1);
        end else if (transitions < 10) begin
            $display("FAIL: only %0d LED transitions", transitions);
            $fatal(1);
        end else begin
            $display("PASS: %0d LED transitions, BTN1 IRQ reset observed (LED %b -> 0)",
                     transitions, led_before_irq);
        end

        $finish;
    end

    initial begin
        #2_000_000;
        $display("FAIL: watchdog timeout");
        $fatal(1);
    end
endmodule
