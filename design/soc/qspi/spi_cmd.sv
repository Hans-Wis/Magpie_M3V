// SPDX-License-Identifier: Apache-2.0
// Provenance (ADR-0071, reuse per ADR-0003 / SOC rule 5): copied verbatim from
// Magpie_M6 rtl/soc/peripheral/qspi/spi_cmd.sv @ commit 14db08b (first-party
// Magpie_QSPI, Apache-2.0). Fix upstream first, then re-copy — no silent forks.
// spi_cmd.sv - Magpie_QSPI generic single-lane command engine (config/status path).
// -----------------------------------------------------------------------------
// Issues a simple SPI-NOR command frame: CS low -> opcode (8b) -> optional tx bytes
// (n_tx) -> optional rx bytes (n_rx) -> CS high. Used for the non-read config path:
// WREN (0x06, no data), WRSR (0x01 + 1 status byte to set Quad-Enable), RDSR (0x05,
// read 1 status byte for WIP polling / QE verify). MSB-first, SPI mode 0 (drive on
// SCLK low, flash samples on SCLK rising; flash launches read data on SCLK falling).
// ============================================================================
module spi_cmd (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        start,
  input  logic [7:0]  opcode,
  input  logic [1:0]  n_tx,        // tx bytes after opcode (0..2)
  input  logic [15:0] tx_data,     // sent MSB byte first: tx_data[15:8] then [7:0]
  input  logic [1:0]  n_rx,        // rx bytes to read (0..2)
  output logic        busy,
  output logic        done,
  output logic [15:0] rx_data,     // last rx byte in [7:0]

  output logic        sclk,
  output logic        cs_n,
  output logic        si,
  input  logic        so
);
  typedef enum logic [2:0] { C_IDLE, C_BIT, C_TRAIL, C_END, C_DONE } cst_e;
  cst_e st;

  logic [23:0] txsr;               // {opcode, tx_data} left-justified (MSB first)
  logic [15:0] rxsr;
  logic [5:0]  cnt;                // bit index
  logic [5:0]  tx_bits, tot_bits;
  logic        ph;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st<=C_IDLE; sclk<=1'b0; cs_n<=1'b1; si<=1'b0; busy<=1'b0; done<=1'b0;
      txsr<='0; rxsr<='0; cnt<='0; ph<=1'b0; tx_bits<='0; tot_bits<='0; rx_data<='0;
    end else begin
      done <= 1'b0;
      case (st)
        C_IDLE: if (start) begin
          txsr    <= {opcode, tx_data};
          tx_bits <= 6'(6'd8 + {1'b0, n_tx, 3'b000});                       // 8 + n_tx*8
          tot_bits<= 6'(6'd8 + {1'b0, n_tx, 3'b000} + {1'b0, n_rx, 3'b000}); // + n_rx*8
          cnt<='0; ph<=1'b0; busy<=1'b1; cs_n<=1'b0; sclk<=1'b0; rxsr<='0; st<=C_BIT;
        end
        C_BIT: begin
          if (!ph) begin sclk<=1'b0; si<=txsr[23]; ph<=1'b1; end
          else begin
            sclk<=1'b1;
            if (cnt >= tx_bits) rxsr <= {rxsr[14:0], so};      // sample during rx window
            txsr <= {txsr[22:0], 1'b0};
            if (cnt == tot_bits-6'd1) st<=C_TRAIL;
            else begin cnt<=cnt+6'd1; ph<=1'b0; end
          end
        end
        // drop SCLK and hold CS low one cycle, so CS deasserts cleanly AFTER the last
        // SCLK falling edge (the model triggers WREN/WRSR on posedge CS at Bit==7/15;
        // raising CS simultaneously with the SCLK edge races that evaluation).
        C_TRAIL: begin sclk<=1'b0; rx_data<=rxsr; st<=C_END; end
        C_END: begin cs_n<=1'b1; st<=C_DONE; end
        C_DONE: begin busy<=1'b0; done<=1'b1; st<=C_IDLE; end
        default: st<=C_IDLE;
      endcase
    end
  end
endmodule
