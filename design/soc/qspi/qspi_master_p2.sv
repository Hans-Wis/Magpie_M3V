// SPDX-License-Identifier: Apache-2.0
// Provenance (ADR-0071, reuse per ADR-0003 / SOC rule 5): copied verbatim from
// Magpie_M6 rtl/soc/peripheral/qspi/qspi_master_p2.sv @ commit 14db08b (first-party
// Magpie_QSPI, Apache-2.0). Fix upstream first, then re-copy — no silent forks.
// qspi_master_p2.sv - Magpie_QSPI P2: SPI master with single + QUAD (1-4-4) read.
// -----------------------------------------------------------------------------
// Superset of the P0 engine. A command frame is: opcode(8, 1-lane) + address
// (24/32-bit, 1- or 4-lane) + N dummy cycles + read data (1- or 4-lane). Quad
// (0xEB) puts address AND data on IO[3:0] (4 bits/SCLK) - ~4x the data bandwidth
// of the single-lane 0x03. Bidirectional quad bus via io_o/io_oe/io_i (the top
// tri-states the pads). SPI mode 0 (drive on SCLK low, sample on SCLK rising).
//   addr_quad/data_quad select lane width per phase; n_dummy after address.
// ============================================================================
module qspi_master_p2 (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        start,
  input  logic [7:0]  opcode,
  input  logic        use_addr,
  input  logic        addr32,       // 4-byte address
  input  logic        addr_quad,    // address on IO[3:0]
  input  logic [31:0] addr,
  input  logic [4:0]  n_dummy,      // dummy SCLK cycles after address
  input  logic        data_quad,    // read data on IO[3:0]
  input  logic [3:0]  n_read,       // bytes to read
  output logic        busy,
  output logic        done,
  output logic [63:0] rdata,
  output logic [15:0] read_cycles,  // SCLK cycles used (bandwidth metric)

  // quad IO
  output logic        sclk,
  output logic        cs_n,
  output logic [3:0]  io_o,
  output logic        io_oe,        // 1 = controller drives IO[3:0]
  input  logic [3:0]  io_i
);
  typedef enum logic [2:0] { S_IDLE, S_LO, S_HI, S_TRAIL, S_DONE } st_e;
  st_e state;

  // latched command
  logic [7:0]  op_q;   logic [31:0] addr_q;
  logic        use_addr_q, addr32_q, aquad_q, dquad_q;
  logic [4:0]  ndum_q;  logic [3:0] nrd_q;
  logic [63:0] rx;

  // phase boundaries in SCLK cycles
  logic [15:0] ccnt, cmd_e, addr_e, dum_e, rd_e;
  logic [15:0] addr_cyc, data_cyc;
  always_comb begin
    addr_cyc = use_addr_q ? (aquad_q ? (addr32_q ? 16'd8 : 16'd6)
                                     : (addr32_q ? 16'd32: 16'd24)) : 16'd0;
    data_cyc = dquad_q ? ({12'd0, nrd_q} << 1) : ({12'd0, nrd_q} << 3);
    cmd_e  = 16'd8;
    addr_e = cmd_e  + addr_cyc;
    dum_e  = addr_e + {11'd0, ndum_q};
    rd_e   = dum_e  + data_cyc;
  end

  // drive value for the current cycle (combinational)
  logic [3:0]  drv;  logic oe;
  logic [4:0]  ai;                 // index within the address phase (0..31)
  logic [4:0]  np, bp;             // top bit of quad nibble / single addr bit (5-bit select)
  always_comb begin
    drv = 4'b0000; oe = 1'b0;
    ai = 5'(ccnt - cmd_e);
    np = (addr32_q ? 5'd31 : 5'd23) - {ai[2:0], 2'b00};       // quad: msb - ai*4
    bp = (addr32_q ? 5'd31 : 5'd23) - ai;                     // single: msb - ai
    if (ccnt < cmd_e) begin
      oe = 1'b1; drv = {3'b000, op_q[3'(7) - ccnt[2:0]]};      // opcode, 1-lane on IO0
    end else if (use_addr_q && ccnt < addr_e) begin
      oe = 1'b1;
      if (aquad_q) drv = {addr_q[np], addr_q[np-5'd1], addr_q[np-5'd2], addr_q[np-5'd3]};
      else         drv = {3'b000, addr_q[bp]};
    end                                                        // dummy + data: Hi-Z
  end
  wire capturing = (ccnt >= dum_e) && (ccnt < rd_e);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state<=S_IDLE; cs_n<=1'b1; sclk<=1'b0; io_o<='0; io_oe<=1'b0;
      busy<=1'b0; done<=1'b0; ccnt<='0; rx<='0; rdata<='0; read_cycles<='0;
    end else begin
      done <= 1'b0;
      case (state)
        S_IDLE: if (start) begin
          op_q<=opcode; use_addr_q<=use_addr; addr32_q<=addr32; aquad_q<=addr_quad;
          dquad_q<=data_quad; addr_q<=addr; ndum_q<=n_dummy; nrd_q<=n_read;
          ccnt<='0; rx<='0; busy<=1'b1; cs_n<=1'b0; sclk<=1'b0; state<=S_LO;
        end
        S_LO: begin io_o<=drv; io_oe<=oe; sclk<=1'b0; state<=S_HI; end
        S_HI: begin
          sclk<=1'b1;
          if (capturing) rx <= dquad_q ? {rx[59:0], io_i}          // 4 bits
                                       : {rx[62:0], io_i[1]};      // SO=IO1, 1 bit
          if (ccnt + 16'd1 == rd_e) state<=S_TRAIL;
          else begin ccnt<=ccnt+16'd1; state<=S_LO; end
        end
        S_TRAIL: begin
          sclk<=1'b0; cs_n<=1'b1; io_oe<=1'b0;
          rdata<=rx << ((8 - {4'd0,nrd_q}) << 3);
          read_cycles<=rd_e;
          state<=S_DONE;
        end
        S_DONE: begin busy<=1'b0; done<=1'b1; state<=S_IDLE; end
        default: state<=S_IDLE;
      endcase
    end
  end
endmodule
