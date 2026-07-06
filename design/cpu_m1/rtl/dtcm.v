// =============================================================================
// dtcm.v — Dual-bank Data TCM macro (M1A A3, ADR-0026 as amended 2026-06-12)
// -----------------------------------------------------------------------------
// IP-delivered tightly-coupled data memory. The CPU core RTL is UNTOUCHED by A3:
// this macro sits on the SoC side of the pinned valid/ready (or raw en/valid)
// memory contract and must be BIT-IDENTICAL, cycle-identical to the flat 1-cycle
// memory it replaces on the 32-bit core port (the dtcm-in-the-loop directed
// lockstep proves it).
//
// Organization: 2 banks x 32-bit, word-interleaved on addr[2]
//   bank0 holds words at addr[2]==0, bank1 at addr[2]==1.
//
// Ports:
//   CORE port (32-bit, 1-cycle, en/wstrb — same shape as the flat TB memory):
//     priority over the wide port; semantics identical to `if (en) rdata<=mem[i]`
//     plus byte-lane writes.
//   WIDE port (64-bit READ-ONLY): the documented Phase-B interface (vector LSU /
//     GEMV weight feed). Reads BOTH banks at the same index in one cycle ->
//     8 B/cycle sustained (KPI-demonstrated by tb_dtcm; a stub without directed
//     exercise is dead logic — Grok review condition). Arbitration: core port
//     wins; wide_ready=0 that cycle (single-cycle stall, retry).
//     Consumer: Phase B vector LSU (ip.json microarchitecture.m1a_planned_features
//     .phase_b_consumer).
// =============================================================================

module dtcm #(
    parameter WORDS = 65536              // total 32-bit words (256 KB default)
) (
    input             clk,

    // ---- CORE port (32-bit, 1-cycle; same contract as the flat TB memory) ----
    input             core_en,           // read enable (data returns next cycle)
    input  [31:0]     core_addr,         // byte address
    output reg [31:0] core_rdata,
    input  [ 3:0]     core_wstrb,        // byte-lane write strobes (with core_en path
    input  [31:0]     core_wdata,        //   semantics identical to the flat model)

    // ---- WIDE port (64-bit read-only; Phase-B vector/GEMV feed) ----
    input             wide_en,
    input  [31:0]     wide_addr,         // 8-byte aligned (addr[2:0] ignored)
    output reg [63:0] wide_rdata,
    output            wide_ready         // 0 when the core port owns the banks this cycle
);

    localparam BANK_WORDS = WORDS / 2;
    localparam IDX_W = $clog2(BANK_WORDS);

    reg [31:0] bank0 [0:BANK_WORDS-1];
    reg [31:0] bank1 [0:BANK_WORDS-1];

    wire              core_bank = core_addr[2];
    wire [IDX_W-1:0]  core_idx  = core_addr[3 +: IDX_W];
    wire [IDX_W-1:0]  wide_idx  = wide_addr[3 +: IDX_W];

    // Core port always wins both-bank access conflicts (it only touches ONE bank,
    // but the wide port needs BOTH; simple, contract-safe arbitration).
    assign wide_ready = !core_en && !(|core_wstrb);

    always @(posedge clk) begin
        // ---- core port: identical semantics to the flat 1-cycle memory ----
        if (core_en)
            core_rdata <= core_bank ? bank1[core_idx] : bank0[core_idx];
        if (|core_wstrb) begin
            if (core_bank) begin
                if (core_wstrb[0]) bank1[core_idx][ 7: 0] <= core_wdata[ 7: 0];
                if (core_wstrb[1]) bank1[core_idx][15: 8] <= core_wdata[15: 8];
                if (core_wstrb[2]) bank1[core_idx][23:16] <= core_wdata[23:16];
                if (core_wstrb[3]) bank1[core_idx][31:24] <= core_wdata[31:24];
            end else begin
                if (core_wstrb[0]) bank0[core_idx][ 7: 0] <= core_wdata[ 7: 0];
                if (core_wstrb[1]) bank0[core_idx][15: 8] <= core_wdata[15: 8];
                if (core_wstrb[2]) bank0[core_idx][23:16] <= core_wdata[23:16];
                if (core_wstrb[3]) bank0[core_idx][31:24] <= core_wdata[31:24];
            end
        end

        // ---- wide port: both banks in parallel, 8 B/cycle when granted ----
        if (wide_en && wide_ready)
            wide_rdata <= {bank1[wide_idx], bank0[wide_idx]};
    end

endmodule
