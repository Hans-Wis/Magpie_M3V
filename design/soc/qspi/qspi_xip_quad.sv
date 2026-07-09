// SPDX-License-Identifier: Apache-2.0
// Provenance (ADR-0071, reuse per ADR-0003 / SOC rule 5): copied verbatim from
// Magpie_M6 rtl/soc/peripheral/qspi/qspi_xip_quad.sv @ commit 14db08b (first-party
// Magpie_QSPI, Apache-2.0). Fix upstream first, then re-copy — no silent forks.
// qspi_xip_quad.sv - Magpie_QSPI quad (1-4-4) execute-in-place read controller
// with CONTINUOUS-READ, matching the JEDEC/Macronix 0xEB "Quad I/O Read" frame:
//   CS low -> opcode 0xEB (8 clk, 1-lane on IO0)
//          -> address    (6 clk, quad, MSB nibble first)
//          -> mode byte  (2 clk, quad) driven as 0xA5 (performance-enhance pattern)
//          -> dummy       (4 clk, Hi-Z)
//          -> read data   (quad, MSB nibble first), streaming.
// Continuous-read: the 0xEB frame is left OPEN (CS held low) and sequential 32-bit
// words stream out as data-only quad clocks - the flash auto-increments the address
// while CS stays low, so no opcode/address/mode/dummy is re-sent (a "warm" read). A
// non-sequential (branch) read closes CS and re-issues the full frame (a "cold" read).
// AXI4-read-slave interface + cold/warm counters mirror the single-lane qspi_xip so
// the two are directly comparable. Bidirectional quad bus via io_o/io_oe/io_i.
// SPI mode 0: drive on SCLK low, sample on SCLK rising; flash launches on SCLK low.
// Prerequisite: the flash's Quad-Enable (QE) bit must be set before use.
// ============================================================================
module qspi_xip_quad #(
  parameter int READ_BYTES = 4                    // bytes returned per AXI word
) (
  input  logic        clk,
  input  logic        rst_n,

  input  logic [31:0] araddr,
  input  logic        arvalid,
  output logic        arready,
  output logic [31:0] rdata,
  output logic        rvalid,
  input  logic        rready,
  output logic [1:0]  rresp,

  output logic        sclk,
  output logic        cs_n,
  output logic [3:0]  io_o,
  output logic        io_oe,                       // 1 = controller drives IO[3:0]
  input  logic [3:0]  io_i,

  output logic [31:0] cold_reads,
  output logic [31:0] warm_reads
);
  localparam int DATA_CYC = READ_BYTES * 2;        // quad cycles per word (2 nibbles/byte)

  typedef enum logic [3:0] {
    Q_IDLE, Q_CMD, Q_ADDR, Q_MODE, Q_DUM, Q_DATA, Q_RESP, Q_HOLD, Q_CSHI
  } qst_e;
  qst_e st;

  logic [31:0] next_addr, cur_addr;
  logic [7:0]  csh;                                // opcode shift (1-lane)
  logic [23:0] ash;                                // address shift (quad, MSB nibble first)
  logic [31:0] rx;
  logic [5:0]  bcnt;                               // SCLK cycles left in the phase
  logic        ph;                                 // 0 = SCLK low (drive), 1 = SCLK high (sample)
  logic [3:0]  cshi;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st<=Q_IDLE; arready<=1'b1; rvalid<=1'b0; rdata<='0; rresp<=2'b00;
      sclk<=1'b0; cs_n<=1'b1; io_o<='0; io_oe<=1'b0; ph<=1'b0; bcnt<='0;
      csh<='0; ash<='0; rx<='0; cshi<='0; next_addr<='0; cur_addr<='0;
      cold_reads<='0; warm_reads<='0;
    end else begin
      case (st)
        Q_IDLE: begin
          arready<=1'b1; cs_n<=1'b1; sclk<=1'b0; io_oe<=1'b0;
          if (arvalid && arready) begin
            cur_addr<=araddr; arready<=1'b0;
            cs_n<=1'b0; csh<=8'hEB; ash<=araddr[23:0];
            bcnt<=6'd8; ph<=1'b0; cold_reads<=cold_reads+1; st<=Q_CMD;
          end
        end
        // ---- opcode 0xEB, 1-lane on IO0 ----
        Q_CMD: begin
          if (!ph) begin sclk<=1'b0; io_oe<=1'b1; io_o<={3'b000, csh[7]}; ph<=1'b1; end
          else begin sclk<=1'b1; csh<={csh[6:0],1'b0};
            if (bcnt==6'd1) begin bcnt<=6'd6; ph<=1'b0; st<=Q_ADDR; end
            else begin bcnt<=bcnt-6'd1; ph<=1'b0; end end
        end
        // ---- 24-bit address, quad, MSB nibble first ----
        Q_ADDR: begin
          if (!ph) begin sclk<=1'b0; io_oe<=1'b1; io_o<=ash[23:20]; ph<=1'b1; end
          else begin sclk<=1'b1; ash<={ash[19:0],4'b0000};
            if (bcnt==6'd1) begin bcnt<=6'd2; ph<=1'b0; st<=Q_MODE; end
            else begin bcnt<=bcnt-6'd1; ph<=1'b0; end end
        end
        // ---- mode/performance-enhance byte 0xA5 (0xA then 0x5), quad ----
        Q_MODE: begin
          if (!ph) begin sclk<=1'b0; io_oe<=1'b1; io_o<=(bcnt==6'd2)?4'hA:4'h5; ph<=1'b1; end
          else begin sclk<=1'b1;
            if (bcnt==6'd1) begin bcnt<=6'd4; ph<=1'b0; st<=Q_DUM; end
            else begin bcnt<=bcnt-6'd1; ph<=1'b0; end end
        end
        // ---- 4 dummy cycles, bus released (flash turns around to drive) ----
        Q_DUM: begin
          if (!ph) begin sclk<=1'b0; io_oe<=1'b0; ph<=1'b1; end
          else begin sclk<=1'b1;
            if (bcnt==6'd1) begin bcnt<=DATA_CYC[5:0]; rx<='0; ph<=1'b0; st<=Q_DATA; end
            else begin bcnt<=bcnt-6'd1; ph<=1'b0; end end
        end
        // ---- read data, quad, MSB nibble first ----
        Q_DATA: begin
          if (!ph) begin sclk<=1'b0; io_oe<=1'b0; ph<=1'b1; end
          else begin sclk<=1'b1; rx<={rx[27:0], io_i};
            if (bcnt==6'd1) begin
              rdata<={rx[27:0], io_i}; rresp<=2'b00; rvalid<=1'b1;
              next_addr<=cur_addr+32'd4; ph<=1'b0; st<=Q_RESP;
            end else begin bcnt<=bcnt-6'd1; ph<=1'b0; end end
        end
        Q_RESP: if (rvalid && rready) begin rvalid<=1'b0; arready<=1'b1; st<=Q_HOLD; end
        // ---- stream open (CS low): sequential word continues without re-frame ----
        Q_HOLD: begin
          arready<=1'b1;
          if (arvalid && arready) begin
            cur_addr<=araddr; arready<=1'b0;
            if (araddr == next_addr) begin
              bcnt<=DATA_CYC[5:0]; rx<='0; ph<=1'b0; warm_reads<=warm_reads+1; st<=Q_DATA;
            end else begin
              cs_n<=1'b1; cshi<=4'd3; st<=Q_CSHI;
            end
          end
        end
        Q_CSHI: begin
          cs_n<=1'b1; sclk<=1'b0; io_oe<=1'b0;
          if (cshi==4'd0) begin
            cs_n<=1'b0; csh<=8'hEB; ash<=cur_addr[23:0];
            bcnt<=6'd8; ph<=1'b0; cold_reads<=cold_reads+1; st<=Q_CMD;
          end else cshi<=cshi-4'd1;
        end
        default: st<=Q_IDLE;
      endcase
    end
  end
endmodule
