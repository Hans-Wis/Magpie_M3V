// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 core_ip contributors
// Provenance: adapted from first-party Magpie_X3
//   /home/edauser/project/SOC/Magpie_X3/core_ip/rtl/peripherals/addr_decoder.v
// for Magpie_M1 ADR-0020 native-bus subsystem integration.

// =============================================================================
// addr_decoder.v -- Magpie_M1 native-bus subsystem address decoder
// -----------------------------------------------------------------------------
// Active ADR-0020 D-side map:
//   RAM   0x2000_0000..0x2fff_ffff  external native bus
//   CLINT 0x0200_0000..0x0200_ffff  internal clint.v
//   PLIC  0x0c00_0000..0x0fff_ffff  internal plic.v
//   UART  0x1000_0000..0x1000_ffff  internal uart.v
// =============================================================================

`default_nettype none

module addr_decoder #(
    parameter integer ADDR_W = 32
) (
    input  wire [ADDR_W-1:0] addr_i,

    output wire              sel_ram_o,
    output wire              sel_clint_o,
    output wire              sel_plic_o,
    output wire              sel_uart_o,
    output wire              d_in_range_o
);

    assign sel_ram_o      = (addr_i[ADDR_W-1:28] == 4'h2);
    assign sel_clint_o    = (addr_i[ADDR_W-1:16] == 16'h0200);
    assign sel_plic_o     = (addr_i[ADDR_W-1:26] == 6'b000011);
    assign sel_uart_o     = (addr_i[ADDR_W-1:16] == 16'h1000);
    assign d_in_range_o   = sel_ram_o | sel_clint_o | sel_plic_o | sel_uart_o;

endmodule

`default_nettype wire
