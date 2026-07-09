// SPDX-License-Identifier: Apache-2.0
// Provenance (ADR-0071, reuse per ADR-0003 / SOC rule 5): copied verbatim from
// Magpie_M6 rtl/soc/peripheral/qspi/qspi_prog.sv @ commit 14db08b (first-party
// Magpie_QSPI, Apache-2.0). Fix upstream first, then re-copy — no silent forks.
// qspi_prog.sv - Magpie_QSPI program/erase controller (single-lane, SPI mode 0).
// -----------------------------------------------------------------------------
// Drives the full SPI-NOR write sequence for one operation and self-times it by
// polling WIP - a single bus owner (no mux):
//     WREN (0x06)  ->  <op frame>  ->  poll RDSR until WIP clears  ->  done
//   op = PP (0x02, opcode+addr+N data bytes), SE (0x20), BE (0xD8), CE (0xC7).
// NOR rules the caller must honour: program only clears bits (1->0); erase first
// (sets 0xFF). PP data is pulled byte-by-byte: the controller drives wr_addr (index
// of the byte it is shifting) and reads wr_data = buf[wr_addr] combinationally.
// CS is dropped one SCLK-low cycle before it deasserts so the model's posedge-CS
// program/erase trigger sees a clean edge (not a CS/SCLK race).
// ============================================================================
module qspi_prog #(
  parameter int ADDR_BYTES = 3
) (
  input  logic        clk,
  input  logic        rst_n,

  // command
  input  logic        start,
  input  logic [1:0]  op,          // 0=PP 1=SE 2=BE 3=CE
  input  logic [31:0] addr,
  input  logic [8:0]  n_data,      // PP byte count (1..256); ignored for erase
  output logic        busy,
  output logic        done,        // 1-cycle pulse when WIP has cleared
  output logic [7:0]  status,      // last RDSR value (bit0=WIP, bit1=WEL)

  // PP data source (combinational: wr_data must equal buf[wr_addr])
  output logic [8:0]  wr_addr,
  input  logic [7:0]  wr_data,

  // SPI pins (single-lane)
  output logic        sclk,
  output logic        cs_n,
  output logic        si,
  input  logic        so
);
  localparam int ABITS = (ADDR_BYTES == 4) ? 32 : 24;
  localparam logic [7:0] WREN_BYTE = 8'h06;

  typedef enum logic [3:0] {
    G_IDLE, G_WREN, G_WREN_TR, G_WREN_HI,
    G_CMD, G_CMD_TR, G_CMD_HI,
    G_RD_CMD, G_RD_DAT, G_RD_TR, G_RD_HI, G_DONE
  } gst_e;
  gst_e st;

  logic [1:0]  op_q;   logic [31:0] addr_q;  logic [8:0] ndat_q;
  logic [7:0]  op_byte;  logic has_addr, has_data;
  logic [11:0] bcnt;              // bit index within the current frame
  logic [11:0] frame_bits;       // total bits in the op frame
  logic [3:0]  cshi;
  logic        ph;
  logic [7:0]  op_sh;            // opcode shifter for WREN / RDSR (MSB-first)

  // op decode (combinational, from latched op)
  always_comb begin
    unique case (op_q)
      2'd0: begin op_byte = 8'h02; has_addr = 1'b1; has_data = 1'b1; end   // PP
      2'd1: begin op_byte = 8'h20; has_addr = 1'b1; has_data = 1'b0; end   // SE
      2'd2: begin op_byte = 8'hD8; has_addr = 1'b1; has_data = 1'b0; end   // BE
      default: begin op_byte = 8'hC7; has_addr = 1'b0; has_data = 1'b0; end// CE
    endcase
    frame_bits = 12'd8
               + (has_addr ? ABITS[11:0] : 12'd0)
               + (has_data ? {ndat_q, 3'b000} : 12'd0);   // n_data * 8
  end

  // TX bit for the CMD frame, MSB-first. bcnt counts DOWN (frame_bits..1), so the
  // absolute bit index from the start is bi = frame_bits - bcnt: opcode -> addr -> data.
  logic [11:0] bi;               // absolute bit index within the frame
  logic [11:0] dbi;              // data-phase bit index
  logic        cmd_bit;
  always_comb begin
    bi      = frame_bits - bcnt;
    dbi     = bi - 12'd8 - (has_addr ? ABITS[11:0] : 12'd0);
    wr_addr = dbi[11:3];         // which PP byte we are shifting
    if (bi < 12'd8)                              cmd_bit = op_byte[3'(7) - bi[2:0]];
    else if (has_addr && bi < 12'd8 + ABITS[11:0])
      cmd_bit = addr_q[5'((ADDR_BYTES==4 ? 6'd39 : 6'd31) - bi[5:0])];
    else                                         cmd_bit = wr_data[3'(7) - dbi[2:0]];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st<=G_IDLE; sclk<=1'b0; cs_n<=1'b1; si<=1'b0; busy<=1'b0; done<=1'b0;
      bcnt<='0; cshi<='0; ph<=1'b0; status<='0; op_sh<='0;
      op_q<='0; addr_q<='0; ndat_q<='0;
    end else begin
      done <= 1'b0;
      case (st)
        G_IDLE: if (start) begin
          op_q<=op; addr_q<=addr; ndat_q<=n_data;
          busy<=1'b1; cs_n<=1'b0; sclk<=1'b0; bcnt<=12'd8; ph<=1'b0; op_sh<=WREN_BYTE; st<=G_WREN;
        end
        // ---- WREN (0x06), 8 bits (MSB-first shifter) ----
        G_WREN: begin
          if (!ph) begin sclk<=1'b0; si<=op_sh[7]; ph<=1'b1; end
          else begin sclk<=1'b1; ph<=1'b0; op_sh<={op_sh[6:0],1'b0};
            if (bcnt==12'd1) st<=G_WREN_TR; else bcnt<=bcnt-12'd1; end
        end
        G_WREN_TR: begin sclk<=1'b0; cshi<=4'd2; st<=G_WREN_HI; end
        G_WREN_HI: begin cs_n<=1'b1;                     // WEL now set
          if (cshi==4'd0) begin cs_n<=1'b0; bcnt<=frame_bits; ph<=1'b0; st<=G_CMD; end
          else cshi<=cshi-4'd1; end
        // ---- op frame: opcode [+ addr] [+ data] ----
        G_CMD: begin
          if (!ph) begin sclk<=1'b0; si<=cmd_bit; ph<=1'b1; end
          else begin sclk<=1'b1; ph<=1'b0;
            if (bcnt==12'd1) st<=G_CMD_TR; else bcnt<=bcnt-12'd1; end
        end
        G_CMD_TR: begin sclk<=1'b0; cshi<=4'd2; st<=G_CMD_HI; end
        G_CMD_HI: begin cs_n<=1'b1;                      // posedge CS triggers program/erase
          if (cshi==4'd0) begin cs_n<=1'b0; bcnt<=12'd8; ph<=1'b0; op_sh<=8'h05; st<=G_RD_CMD; end
          else cshi<=cshi-4'd1; end
        // ---- WIP poll: RDSR opcode then read 1 status byte ----
        G_RD_CMD: begin
          if (!ph) begin sclk<=1'b0; si<=op_sh[7]; ph<=1'b1; end
          else begin sclk<=1'b1; ph<=1'b0; op_sh<={op_sh[6:0],1'b0};
            if (bcnt==12'd1) begin bcnt<=12'd8; st<=G_RD_DAT; end else bcnt<=bcnt-12'd1; end
        end
        G_RD_DAT: begin
          if (!ph) begin sclk<=1'b0; ph<=1'b1; end
          else begin sclk<=1'b1; ph<=1'b0; status<={status[6:0], so};
            if (bcnt==12'd1) st<=G_RD_TR; else bcnt<=bcnt-12'd1; end
        end
        G_RD_TR: begin sclk<=1'b0; cshi<=4'd2; st<=G_RD_HI; end
        G_RD_HI: begin cs_n<=1'b1;
          if (cshi==4'd0) begin
            if (status[0]) begin cs_n<=1'b0; bcnt<=12'd8; ph<=1'b0; op_sh<=8'h05; st<=G_RD_CMD; end // WIP -> poll again
            else st<=G_DONE;                                                                          // WIP clear -> finished
          end else cshi<=cshi-4'd1;
        end
        G_DONE: begin busy<=1'b0; done<=1'b1; st<=G_IDLE; end
        default: st<=G_IDLE;
      endcase
    end
  end
endmodule
