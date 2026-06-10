// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 core_ip contributors
// Provenance: copied from first-party Magpie_X3
//   /home/edauser/project/SOC/Magpie_X3/core_ip/rtl/peripherals/plic.v
// for Magpie_M1 ADR-0020 PLIC/UART subsystem integration.

// =============================================================================
// plic.v — Platform-Level Interrupt Controller (lab24a)
// -----------------------------------------------------------------------------
// Single-hart, single-context (M-mode only) PLIC per riscv-plic-spec v1.0.0
// (ratified subset). Clean-room: spec + textbook priority encoder.
//
// Topology:
//   8 sources (IDs 1..7; ID 0 reserved per spec)
//   8 priority levels (0..7; 0 = "never claim")
//   1 hart × 1 context (M-mode)
//
// Frozen source-ID assignment (will extend in lab24b + later peripheral labs):
//   1 = UART0 RX     (lab24b)
//   2 = UART0 TX     (lab24b)
//   3 = BTN1         (currently still on the direct `ext_pending` path in
//                     core/csr.v — lab24a wires the PLIC pin but doesn't yet
//                     replace the legacy path; firmware claim/complete coming
//                     in a follow-up)
//   4..7 reserved
//
// MMIO map (within PLIC_BASE..+PLIC_SIZE = 0x0C00_0000..0x0FFF_FFFF):
//   +0x0000_0000           reserved (priority[0] read-only 0)
//   +0x0000_0004..+0x1C    priority[1..7]   (3 bits each — bits[2:0])
//   +0x0000_1000           pending[7:0]     (R/O — sticky; cleared on claim)
//   +0x0000_2000           enable[7:0]      (context 0)
//   +0x0020_0000           threshold[2:0]   (context 0)
//   +0x0020_0004           claim/complete   R = top pending source ID
//                                           W = release source for SW
//
// `meip_o` (combinational) is 1 iff at least one source is
//      pending  &&  enabled  &&  priority > threshold.
// SoC top OR's meip_o with the legacy `ext_pending` into core's mip[11].
//
// Bus interface (lighter-weight, SoC top handles gnt/rvalid/err — same as
// clint.v):
//   en + |wstrb| = write at addr.   en + !|wstrb| = read at addr → rdata.
// =============================================================================

`default_nettype none

module plic (
    input  wire        clk,
    input  wire        rst,

    // ---- Source IRQ pulses (level → edge sticky) -------------------
    // sources[i] corresponds to source ID (i+1), so sources[0]=ID 1 etc.
    input  wire [ 6:0] sources,

    // ---- SoC-top-facing bus interface ------------------------------
    input  wire        en,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [ 3:0] wstrb,
    output reg  [31:0] rdata,

    // ---- M-mode external-interrupt pin to core ---------------------
    output wire        meip_o
);

    // ---- State -----------------------------------------------------
    // priority_q[i] is the 3-bit priority for source i+1.
    // pending_q[i] is the sticky pending bit for source i+1.
    reg  [2:0] priority_q [1:7];
    reg  [6:0] pending_q;
    reg  [6:0] enable_q;
    reg  [2:0] threshold_q;

    // ---- Edge-detect on source pulses ------------------------------
    reg  [6:0] sources_d;
    always @(posedge clk) begin
        if (rst) sources_d <= 7'd0;
        else     sources_d <= sources;
    end
    // Rising edge per source — set pending sticky (cleared on claim only).
    wire [6:0] sources_rising = sources & ~sources_d;

    // ---- Priority encoder ------------------------------------------
    // Find the highest-priority enabled+pending source above threshold.
    // Tiebreaker: lower source ID wins (per PLIC spec §6).
    reg  [2:0] best_id;           // source ID (1..7), 0 if none
    reg  [2:0] best_prio;
    integer    i;
    always @* begin
        best_id   = 3'd0;
        best_prio = 3'd0;
        for (i = 1; i <= 7; i = i + 1) begin
            if (pending_q[i-1] && enable_q[i-1] &&
                (priority_q[i] > threshold_q) &&
                (priority_q[i] > best_prio)) begin
                best_id   = i[2:0];
                best_prio = priority_q[i];
            end
        end
    end
    assign meip_o = (best_id != 3'd0);

    // ---- Sub-decode ------------------------------------------------
    // The full PLIC carve-out is 4 MB; we only decode the live slots.
    wire is_priority    = (addr[23:0] >= 24'h00_0004) && (addr[23:0] <= 24'h00_001C);
    wire is_pending     = (addr[23:0] == 24'h00_1000);
    wire is_enable      = (addr[23:0] == 24'h00_2000);
    wire is_threshold   = (addr[23:0] == 24'h20_0000);
    wire is_claim       = (addr[23:0] == 24'h20_0004);

    wire [2:0] prio_idx = addr[4:2];  // 1..7 for priority slot

    wire is_write = en && (|wstrb);
    wire is_read  = en && (~|wstrb);

    // ---- Read mux (combinational) ----------------------------------
    always @* begin
        rdata = 32'h0;
        if (is_read) begin
            if      (is_priority)  rdata = {29'h0, priority_q[prio_idx]};
            else if (is_pending)   rdata = {25'h0, pending_q};
            else if (is_enable)    rdata = {25'h0, enable_q};
            else if (is_threshold) rdata = {29'h0, threshold_q};
            else if (is_claim)     rdata = {29'h0, best_id};
            // else: 0 (incl priority[0])
        end
    end

    // ---- State updates ---------------------------------------------
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 1; k <= 7; k = k + 1) priority_q[k] <= 3'd0;
            pending_q   <= 7'd0;
            enable_q    <= 7'd0;
            threshold_q <= 3'd0;
        end else begin
            // Source edge → set sticky pending bit
            pending_q <= pending_q | sources_rising;

            if (is_write) begin
                if (is_priority && wstrb[0])
                    priority_q[prio_idx] <= wdata[2:0];
                if (is_enable && wstrb[0])
                    enable_q <= wdata[6:0];
                if (is_threshold && wstrb[0])
                    threshold_q <= wdata[2:0];
                // Claim register: write = complete; clears the pending bit
                // for the source whose ID equals wdata[2:0]. Per spec §7,
                // writing an out-of-range ID is silently ignored.
                if (is_claim && wstrb[0]) begin
                    // ID 1..7 (ID 0 reserved). wdata[2:0]<=7 is implicit in
                    // the 3-bit width, so just check ID != 0.
                    if (wdata[2:0] != 3'd0)
                        pending_q[wdata[2:0] - 3'd1] <= 1'b0;
                end
            end

            // Reading the claim register also "claims" — top pending source
            // pending bit is cleared.
            if (is_read && is_claim && best_id != 3'd0) begin
                pending_q[best_id - 3'd1] <= 1'b0;
            end

            // pending writes (W1C on direct write to pending reg) — non-standard,
            // not implemented. Only claim/complete clears.
        end
    end

    // addr[31:24] is the PLIC-region prefix consumed by the SoC top's
    // decoder; not used inside this module.

endmodule

`default_nettype wire
