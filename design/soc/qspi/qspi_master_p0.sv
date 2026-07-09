// SPDX-License-Identifier: Apache-2.0
// Provenance (ADR-0069, reuse per ADR-0003 / SOC rule 5): copied verbatim from
// Magpie_M6 rtl/soc/peripheral/qspi/qspi_master_p0.sv @ commit 14db08b (first-party
// Magpie_QSPI, Apache-2.0). Fix upstream first, then re-copy — no silent forks.
// qspi_master_p0.sv - Magpie_QSPI P0: minimal single-lane SPI master (mode 0).
// -----------------------------------------------------------------------------
// The kernel of the QSPI boot controller: given a command (opcode [+ 24-bit addr]
// [+ dummy cycles] [+ N read bytes]), it sequences CS_n / SCLK / SI and captures
// SO. SPI mode 0 (CPOL=0/CPHA=0): SI is launched while SCLK=0, SO is sampled on
// SCLK rising. Two `clk` cycles per SPI bit (SCLK = clk/2). Single-lane only;
// quad (1-4-4, 0xEB) and the AXI front-end land in P1/P2.
//   - Pulse `start` with {opcode,use_addr,addr,n_dummy,n_read}; wait `done`.
//   - Read bytes land MSB-first in `rdata` (first byte in the high bits).
// ============================================================================
module qspi_master_p0 (
  input  logic        clk,
  input  logic        rst_n,

  // command interface
  input  logic        start,       // 1-cycle pulse to launch
  input  logic [7:0]  opcode,
  input  logic        use_addr,     // send address after opcode
  input  logic        addr32,       // 1 = 4-byte (32-bit) addr, 0 = 3-byte (24-bit)
  input  logic [31:0] addr,
  input  logic [3:0]  n_dummy,      // dummy SCLK cycles after addr
  input  logic [3:0]  n_read,       // bytes to read (1..8)
  output logic        busy,
  output logic        done,         // 1-cycle pulse when the command completes
  output logic [63:0] rdata,        // captured read bytes, first byte in [.. : ..]

  // SPI pins (single-lane)
  output logic        sclk,
  output logic        cs_n,
  output logic        si,
  input  logic        so
);
  typedef enum logic [2:0] { S_IDLE, S_LEAD, S_BIT_LO, S_BIT_HI, S_TRAIL, S_DONE } st_e;
  st_e state;

  logic [9:0] bcnt;          // bit index within the frame
  logic [9:0] cmd_end, addr_end, dummy_end, read_end;
  logic [7:0] op_q;   logic [31:0] addr_q;  logic use_addr_q, addr32_q;
  logic [3:0] ndum_q, nrd_q;
  logic [63:0] rx;

  // frame boundaries (in "SCLK cycles" = bits)
  always_comb begin
    cmd_end   = 10'd8;
    addr_end  = cmd_end  + (use_addr_q ? (addr32_q ? 10'd32 : 10'd24) : 10'd0);
    dummy_end = addr_end + {6'd0, ndum_q};
    read_end  = dummy_end + ({6'd0, nrd_q} << 3);   // n_read * 8
  end

  // TX bit for the current bcnt (MSB-first per field). The address index is
  // (msb - (bcnt-8)) = ((32/24-1+8) - bcnt); cast to 5 bits (0..31) for the select.
  logic tx_bit;
  always_comb begin
    if (bcnt < cmd_end)                     tx_bit = op_q[3'(7) - bcnt[2:0]];
    else if (use_addr_q && bcnt < addr_end) tx_bit = addr_q[5'((addr32_q ? 6'd39 : 6'd31) - bcnt[5:0])];
    else                                    tx_bit = 1'b0;
  end
  wire capturing = (bcnt >= dummy_end) && (bcnt < read_end);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_IDLE; cs_n <= 1'b1; sclk <= 1'b0; si <= 1'b0;
      busy <= 1'b0; done <= 1'b0; bcnt <= '0; rx <= '0; rdata <= '0;
    end else begin
      done <= 1'b0;
      case (state)
        S_IDLE: if (start) begin
          op_q<=opcode; use_addr_q<=use_addr; addr32_q<=addr32; addr_q<=addr; ndum_q<=n_dummy; nrd_q<=n_read;
          bcnt<='0; rx<='0; busy<=1'b1; cs_n<=1'b0; sclk<=1'b0; state<=S_LEAD;
        end
        S_LEAD: begin si <= op_q[7]; state <= S_BIT_LO; end   // CS setup, present bit0
        S_BIT_LO: begin                                       // SCLK low: SI valid
          si   <= tx_bit;
          sclk <= 1'b0;
          state<= S_BIT_HI;
        end
        S_BIT_HI: begin                                       // SCLK rising edge: sample SO
          sclk <= 1'b1;
          if (capturing) rx <= {rx[62:0], so};
          if (bcnt + 10'd1 == read_end) state <= S_TRAIL;
          else begin bcnt <= bcnt + 10'd1; state <= S_BIT_LO; end
        end
        S_TRAIL: begin                                        // finish last bit, drop CS
          sclk <= 1'b0; cs_n <= 1'b1;
          rdata <= rx << ((8 - nrd_q) << 3);                  // left-justify first byte
          state <= S_DONE;
        end
        S_DONE: begin busy <= 1'b0; done <= 1'b1; state <= S_IDLE; end
        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
