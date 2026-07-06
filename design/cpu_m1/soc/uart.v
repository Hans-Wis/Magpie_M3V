// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 core_ip contributors
// Provenance: copied from first-party Magpie_X3
//   /home/edauser/project/SOC/Magpie_X3/core_ip/rtl/peripherals/uart.v
// for Magpie_M1 ADR-0020 PLIC/UART subsystem integration.

// =============================================================================
// uart.v — NS16550-compatible UART subset (lab24b)
// -----------------------------------------------------------------------------
// Clean-room minimal TX-side implementation for lab24b. Goal: let firmware
// `printf` to memory-mapped THR and have a testbench capture the byte stream.
// Real bit-rate divider + RX FIFO + modem control are NOT implemented today;
// they land in later peripheral labs.
//
// Implemented registers (within UART0_BASE 0x1001_0000 + 4 KB):
//   +0x00  THR  (W) — Transmit Holding Register; writes pulse tx_strobe_o + tx_byte_o
//                (R) — RBR; reads always return 0 (no RX yet)
//   +0x04  IER  (R/W) — only bit 1 (THRE — Transmitter Holding Empty IRQ) is honoured
//   +0x08  IIR  (R)   — Interrupt Identification:
//                       0xC1 = no pending,
//                       0xC2 = THRE IRQ (cleared on IIR read or THR write per spec)
//                (W) — FCR ignored
//   +0x0C  LCR  (R/W) — Line Control. DLAB / word-length bits stored but unused
//                       (no bit-rate divider implemented)
//   +0x10  MCR  (R/W) — Modem Control. Bits stored but not driven anywhere
//   +0x14  LSR  (R)   — Line Status:
//                       bit 5 (THRE)  = 1 always (transmit is instantaneous)
//                       bit 6 (TEMT)  = 1 always
//                       bit 0 (DR)    = 0 (no RX)
//   +0x1C  SCR  (R/W) — Scratch register, software-defined
//
// `tx_strobe_o` pulses for 1 cycle each time THR is written; `tx_byte_o` holds
// the data byte that cycle. A testbench / future PYNQ wrapper / future bit-rate
// divider consumes this pair.
//
// `tx_irq_o` is asserted whenever (IER.bit1=1) — the THRE IRQ is enabled and
// the transmitter is empty. Today the transmitter is ALWAYS empty so tx_irq_o
// = IER.bit1. Wire this into PLIC source 2 in a follow-up commit once the
// firmware ISR can claim/complete (today it's just exposed at the SoC top
// boundary but not yet routed into PLIC sources).
// =============================================================================

`default_nettype none

module uart (
    input  wire        clk,
    input  wire        rst,

    // ---- SoC-top-facing bus interface ---------------------------------------
    input  wire        en,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [ 3:0] wstrb,
    output reg  [31:0] rdata,

    // ---- TX byte stream -----------------------------------------------------
    output reg         tx_strobe_o,    // 1-cycle pulse per THR write
    output reg  [ 7:0] tx_byte_o,

    // ---- TX-empty IRQ to PLIC (routed via SoC top) --------------------------
    output wire        tx_irq_o
);

    // ---- Registers ----------------------------------------------------------
    reg [7:0] ier_q;       // bit 1 = THRE IRQ enable
    reg [7:0] iir_pending; // 1 = THRE IRQ pending
    reg [7:0] lcr_q;
    reg [7:0] mcr_q;
    reg [7:0] scr_q;

    // Bit constants
    localparam IER_THRE_BIT = 1;
    localparam IIR_NO_INT   = 8'hC1;
    localparam IIR_THRE     = 8'hC2;
    localparam LSR_THRE_BIT = 5;
    localparam LSR_TEMT_BIT = 6;

    // ---- Sub-decode (addr[7:2] selects register slot) -----------------------
    wire sel_thr = (addr[7:2] == 6'h00);
    wire sel_ier = (addr[7:2] == 6'h01);
    wire sel_iir = (addr[7:2] == 6'h02);
    wire sel_lcr = (addr[7:2] == 6'h03);
    wire sel_mcr = (addr[7:2] == 6'h04);
    wire sel_lsr = (addr[7:2] == 6'h05);
    wire sel_scr = (addr[7:2] == 6'h07);

    wire is_write = en && (|wstrb);
    wire is_read  = en && (~|wstrb);

    // LSR.THRE + LSR.TEMT both = 1 always (we never block)
    wire [7:0] lsr_val = (1 << LSR_THRE_BIT) | (1 << LSR_TEMT_BIT);

    // ---- Read mux (combinational) -------------------------------------------
    always @* begin
        rdata = 32'h0;
        if (is_read) begin
            if      (sel_thr) rdata = 32'h0;             // RBR (no RX)
            else if (sel_ier) rdata = {24'h0, ier_q};
            else if (sel_iir) rdata = {24'h0, (ier_q[IER_THRE_BIT] && iir_pending[1])
                                              ? IIR_THRE : IIR_NO_INT};
            else if (sel_lcr) rdata = {24'h0, lcr_q};
            else if (sel_mcr) rdata = {24'h0, mcr_q};
            else if (sel_lsr) rdata = {24'h0, lsr_val};
            else if (sel_scr) rdata = {24'h0, scr_q};
        end
    end

    // ---- State updates ------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            ier_q       <= 8'h0;
            iir_pending <= 8'h0;
            lcr_q       <= 8'h0;
            mcr_q       <= 8'h0;
            scr_q       <= 8'h0;
            tx_strobe_o <= 1'b0;
            tx_byte_o   <= 8'h0;
        end else begin
            tx_strobe_o <= 1'b0;  // default: 1-cycle pulse

            // THRE IRQ is "pending" while the transmitter is empty AND IRQ is
            // enabled. Today the transmitter is always empty so iir_pending[1]
            // tracks ier_q[THRE]. Cleared on (a) IIR read, (b) THR write.
            if (ier_q[IER_THRE_BIT])
                iir_pending[1] <= 1'b1;

            if (is_write) begin
                if (sel_thr && wstrb[0]) begin
                    tx_strobe_o    <= 1'b1;
                    tx_byte_o      <= wdata[7:0];
                    iir_pending[1] <= 1'b0;
                end
                if (sel_ier && wstrb[0]) ier_q <= wdata[7:0];
                if (sel_lcr && wstrb[0]) lcr_q <= wdata[7:0];
                if (sel_mcr && wstrb[0]) mcr_q <= wdata[7:0];
                if (sel_scr && wstrb[0]) scr_q <= wdata[7:0];
                // FCR (sel_iir on write) ignored — no FIFO yet
            end

            // Reads of IIR also clear THRE pending (NS16550 §B.4)
            if (is_read && sel_iir) iir_pending[1] <= 1'b0;
        end
    end

    // tx_irq_o is the line into PLIC. Today the transmitter is always empty,
    // so this just tracks IER.THRE — wire to PLIC source 2 once firmware is
    // ready to claim/complete (until then SoC top leaves it unconnected and
    // PLIC sources stay tied to 0).
    assign tx_irq_o = ier_q[IER_THRE_BIT];

    // addr[31:8], addr[1:0], wdata[31:8], wstrb[3:1] are deliberately
    // unused (this is an 8-bit NS16550 view through a 32-bit native bus;
    // SoC top decodes the upper addr bits, only byte 0 of each register
    // is used). iir_pending[7:2,0] are reserved for future IRQ sources
    // (THRE only today).

endmodule

`default_nettype wire
