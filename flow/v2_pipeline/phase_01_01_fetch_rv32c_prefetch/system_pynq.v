// =============================================================================
// system_pynq.v -- Magpie_M1 Phase 1.1 smoke wrapper
// -----------------------------------------------------------------------------
// Based on Ch2 lab08e system wrapper:
//   * 兩個 BRAM port (Vivado 從 always block pattern infer 真正的 dual-port
//     RAMB36E1)：i-port 給 instr fetch 用 (read only), d-port 給 load/store 用
//   * Core 多 4 條 wire (split i/d 介面)；mem handshake 取消 (1-cycle BRAM 永遠 ready)
//
// 同 lab05：BTN1 debounce + edge → IRQ；LED MMIO 在 0x1xxx_xxxx；trap → 1111
// =============================================================================

`timescale 1ns / 1ns

module system_pynq #(
    parameter DEBOUNCE_CYC = 100_000   // 1 ms @ 100 MHz; sim 可 override
) (
    input        clk,
    input        btn0,
    input        btn1,
    output [3:0] led
);
    parameter MEM_SIZE = 4096;          // 16 KB BRAM

    // -------------------------------------------------------------------------
    // POR + reset
    // -------------------------------------------------------------------------
    reg [3:0] por_cnt = 0;
    reg       resetn  = 0;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    always @(posedge clk) begin
        if (por_cnt != 4'hF) por_cnt <= por_cnt + 1;
        resetn <= (por_cnt == 4'hF) && !btn0;
    end

    // -------------------------------------------------------------------------
    // BTN1 debouncer (同 lab05)
    // -------------------------------------------------------------------------
    reg btn1_sync0, btn1_sync1;
    always @(posedge clk) begin
        btn1_sync0 <= btn1;
        btn1_sync1 <= btn1_sync0;
    end

    reg [16:0] db_cnt;
    reg        btn1_stable;
    reg        btn1_stable_d;
    always @(posedge clk) begin
        if (!resetn) begin
            db_cnt <= 0; btn1_stable <= 0; btn1_stable_d <= 0;
        end else begin
            if (btn1_sync1 != btn1_stable) begin
                if (db_cnt == DEBOUNCE_CYC - 1) begin
                    btn1_stable <= btn1_sync1;
                    db_cnt      <= 0;
                end else
                    db_cnt <= db_cnt + 1'b1;
            end else
                db_cnt <= 0;
            btn1_stable_d <= btn1_stable;
        end
    end
    wire btn1_pulse = btn1_stable && !btn1_stable_d;

    // -------------------------------------------------------------------------
    // Core ↔ split mem interface
    // -------------------------------------------------------------------------
    wire        trap;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] i_mem_addr;        // 只用 [13:2]
    wire [31:0] d_mem_addr;
    /* verilator lint_on UNUSEDSIGNAL */
    wire        i_mem_en;
    reg  [31:0] i_mem_rdata;
    wire        d_mem_valid;
    wire [31:0] d_mem_wdata;
    wire [ 3:0] d_mem_wstrb;
    reg  [31:0] d_mem_rdata;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;

    /* verilator lint_off PINCONNECTEMPTY */
`ifdef REVIEW_TRACE
    /* verilator tracing_off */
`endif
    core u_core (
        .clk                (clk),
        .resetn             (resetn),
        .trap               (trap),
        .mem_stall          (1'b0),
        .i_mem_addr         (i_mem_addr),
        .i_mem_en           (i_mem_en),
        .i_mem_rdata        (i_mem_rdata),
        .d_mem_valid        (d_mem_valid),
        .d_mem_addr         (d_mem_addr),
        .d_mem_wdata        (d_mem_wdata),
        .d_mem_wstrb        (d_mem_wstrb),
        .d_mem_rdata        (d_mem_rdata),
        .irq_external_pulse (btn1_pulse),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy_halted),
        .debug_mode_o       (dbg_dummy_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dbg_dummy_acc_rdata),
        .dm_acc_err         (dbg_dummy_acc_err),
        .dbg_pc             (dbg_pc),
        .dbg_instr          (dbg_instr),
        .dbg_state          (dbg_state)
    );
`ifdef REVIEW_TRACE
    /* verilator tracing_on */
`endif
    /* verilator lint_on PINCONNECTEMPTY */

    // -------------------------------------------------------------------------
    // Dual-port BRAM
    //   Port A: i-port，read only。每 cycle 從 i_mem_addr 讀
    //   Port B: d-port，read + byte-strobe write。MMIO (0x1xxx_xxxx) 不寫進 BRAM
    // Vivado 從這個 pattern infer 真正的 RAMB36E1 dual-port
    // -------------------------------------------------------------------------
    reg [31:0] memory [0:MEM_SIZE-1];
    initial $readmemh("firmware.hex", memory);

    wire [11:0] i_word_idx = i_mem_addr[13:2];
    wire [11:0] d_word_idx = d_mem_addr[13:2];
    wire        d_is_mmio  = d_mem_addr[28];

    reg       out_byte_en;
    reg [3:0] out_byte;

    // Port A: instr fetch (read only, gated by i_mem_en)
    //   When i_mem_en=0 (= stall), mem_rdata holds — 防止 stall 期間漏掉指令
    always @(posedge clk) begin
        if (i_mem_en) i_mem_rdata <= memory[i_word_idx];
    end

    // Port B: data (read + write)
    always @(posedge clk) begin
        out_byte_en <= 1'b0;

        if (d_mem_valid) begin
            d_mem_rdata <= memory[d_word_idx];

            if (|d_mem_wstrb) begin
                if (d_is_mmio) begin
                    out_byte_en <= 1'b1;
                    out_byte    <= d_mem_wdata[3:0];
                end else begin
                    if (d_mem_wstrb[0]) memory[d_word_idx][ 7: 0] <= d_mem_wdata[ 7: 0];
                    if (d_mem_wstrb[1]) memory[d_word_idx][15: 8] <= d_mem_wdata[15: 8];
                    if (d_mem_wstrb[2]) memory[d_word_idx][23:16] <= d_mem_wdata[23:16];
                    if (d_mem_wstrb[3]) memory[d_word_idx][31:24] <= d_mem_wdata[31:24];
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // LED register
    // -------------------------------------------------------------------------
    reg [3:0] led_reg = 4'b1010;
    always @(posedge clk) begin
        if (!resetn)       led_reg <= 4'b1010;
        else if (trap)     led_reg <= 4'b1111;
        else if (out_byte_en) led_reg <= out_byte;
    end
    assign led = led_reg;

endmodule
