// SPDX-License-Identifier: Apache-2.0
// Provenance (ADR-0069, reuse per ADR-0003 / SOC rule 5): copied verbatim from
// Magpie_M6 rtl/soc/peripheral/qspi/qspi_xip.sv @ commit 14db08b (first-party
// Magpie_QSPI, Apache-2.0). Fix upstream first, then re-copy — no silent forks.
// qspi_xip.sv - Magpie_QSPI XIP read controller with CONTINUOUS-READ.
// -----------------------------------------------------------------------------
// AXI4 read slave that maps flash reads (execute-in-place). Optimization: a 0x03
// read is left OPEN (CS low) and sequential words stream out WITHOUT re-sending
// opcode+address (SPI-NOR 0x03 auto-increments while CS stays low). A sequential
// AXI read (araddr == next_addr) is served from the open stream = data-only SCLK;
// a non-sequential (branch) read closes CS and issues a fresh opcode+address.
// Single-lane 0x03; 24/32-bit address (ADDR_BYTES). SPI mode 0.
//   Stats: cold_reads / warm_reads (continuous-read hits) exposed for the TB.
// ============================================================================
module qspi_xip #(
  parameter int ADDR_BYTES = 3
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
  output logic        si,
  input  logic        so,

  output logic [31:0] cold_reads,   // full opcode+addr issued
  output logic [31:0] warm_reads    // continuous-read (no re-command)
);
  localparam int ABITS = (ADDR_BYTES == 4) ? 32 : 24;
  localparam int SBITS = 8 + ABITS;              // opcode + address bits

  typedef enum logic [2:0] { S_IDLE, S_CSHI, S_SEND, S_RECV, S_RESP, S_HOLD } st_e;
  st_e st;

  logic [31:0] next_addr, cur_addr;
  logic [39:0] txsr;                             // {opcode, addr} left in low SBITS
  logic [31:0] rxsr;
  logic [6:0]  bcnt;                             // bits remaining in phase
  logic        ph;                               // 0 = SCLK low (drive), 1 = SCLK high (sample)
  logic [3:0]  cshi;                             // CS-high dwell counter

  function automatic logic [39:0] mk_cmd(input logic [31:0] a);
    mk_cmd = (ABITS == 32) ? {8'h03, a} : {8'h00, 8'h03, a[23:0]};
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st<=S_IDLE; arready<=1'b1; rvalid<=1'b0; rdata<='0; rresp<=2'b00;
      sclk<=1'b0; cs_n<=1'b1; si<=1'b0; next_addr<='0; cur_addr<='0;
      txsr<='0; rxsr<='0; bcnt<='0; ph<=1'b0; cshi<='0; cold_reads<='0; warm_reads<='0;
    end else begin
      case (st)
        S_IDLE: begin
          arready<=1'b1; cs_n<=1'b1; sclk<=1'b0;
          if (arvalid && arready) begin
            cur_addr<=araddr; arready<=1'b0;
            cs_n<=1'b0; txsr<=mk_cmd(araddr); bcnt<=SBITS[6:0]; ph<=1'b0;
            cold_reads<=cold_reads+1; st<=S_SEND;
          end
        end
        // ---- shift out opcode+address (MSB first) ----
        S_SEND: begin
          if (ph==1'b0) begin si<=txsr[bcnt-1]; sclk<=1'b0; ph<=1'b1; end
          else begin
            sclk<=1'b1; ph<=1'b0;
            if (bcnt==7'd1) begin bcnt<=7'd32; rxsr<='0; st<=S_RECV; end
            else bcnt<=bcnt-7'd1;
          end
        end
        // ---- shift in 32 data bits (4 bytes) ----
        S_RECV: begin
          if (ph==1'b0) begin sclk<=1'b0; ph<=1'b1; end
          else begin
            sclk<=1'b1; ph<=1'b0; rxsr<={rxsr[30:0], so};
            if (bcnt==7'd1) begin
              rdata<={rxsr[30:0], so}; rresp<=2'b00; rvalid<=1'b1;
              next_addr<=cur_addr+32'd4; st<=S_RESP;
            end else bcnt<=bcnt-7'd1;
          end
        end
        S_RESP: if (rvalid && rready) begin rvalid<=1'b0; arready<=1'b1; st<=S_HOLD; end
        // ---- stream open (CS low): sequential read continues without re-command ----
        S_HOLD: begin
          arready<=1'b1;
          if (arvalid && arready) begin
            cur_addr<=araddr; arready<=1'b0;
            if (araddr == next_addr) begin            // sequential -> continue stream
              bcnt<=7'd32; rxsr<='0; ph<=1'b0; warm_reads<=warm_reads+1; st<=S_RECV;
            end else begin                            // branch -> close + reopen
              cs_n<=1'b1; cshi<=4'd3; st<=S_CSHI;
            end
          end
        end
        S_CSHI: begin                                 // CS-high dwell then cold read
          cs_n<=1'b1; sclk<=1'b0;
          if (cshi==4'd0) begin
            cs_n<=1'b0; txsr<=mk_cmd(cur_addr); bcnt<=SBITS[6:0]; ph<=1'b0;
            cold_reads<=cold_reads+1; st<=S_SEND;
          end else cshi<=cshi-4'd1;
        end
        default: st<=S_IDLE;
      endcase
    end
  end
endmodule
