// rtl/debug/dtm.v - Magpie_X1 RISC-V Debug Transport Module / JTAG TAP
// (Phase 7b-7, ADR-0025 slice B).
//
// Adapted for Magpie_M1 ADR-0021 Slice B:
//   - Kept the first-party IEEE 1149.1 TAP / riscv-debug-spec v0.13.2
//     IDCODE, DTMCS, and DMI scan behavior.
//   - Removed Magpie_X1 SBA/AXI side-band wiring.
//   - Wrapped the Magpie_M1 Slice-A dm.v DMI contract:
//       7-bit address, 32-bit data, dmi_req_en/addr/write/data,
//       dmi_resp_data/op.
//
// Original first-party source:
//   ~/project/RISC-V/magpie/Magpie_X1/rtl/debug/dtm.v
//
// Clean-room basis in original: IEEE 1149.1 + riscv-debug-spec v0.13.2.

`default_nettype none

module dtm (
    input  wire        clk,
    input  wire        rst,

    input  wire        tck,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,

    output wire        halt_req,
    output wire        resume_req,
    output wire        ndmreset,
    input  wire        hart_halted,
    input  wire        hart_havereset,

    output wire        acc_en,
    output wire        acc_write,
    output wire [15:0] acc_regno,
    output wire [31:0] acc_wdata,
    input  wire [31:0] acc_rdata,
    input  wire        acc_err,

    output wire [63:0] dmi_reads,
    output wire [63:0] dmi_writes
);
    localparam [31:0] DTM_IDCODE = 32'h10A9_8AD3;

    localparam [4:0] IR_IDCODE = 5'h01;
    localparam [4:0] IR_DTMCS  = 5'h10;
    localparam [4:0] IR_DMI    = 5'h11;

    localparam integer ABITS = 7;
    localparam integer DMI_W = ABITS + 32 + 2;
    localparam integer IR_W  = 5;

    localparam [3:0] S_TLR    = 4'd0;
    localparam [3:0] S_RTI    = 4'd1;
    localparam [3:0] S_SEL_DR = 4'd2;
    localparam [3:0] S_CAP_DR = 4'd3;
    localparam [3:0] S_SHF_DR = 4'd4;
    localparam [3:0] S_EX1_DR = 4'd5;
    localparam [3:0] S_PAU_DR = 4'd6;
    localparam [3:0] S_EX2_DR = 4'd7;
    localparam [3:0] S_UPD_DR = 4'd8;
    localparam [3:0] S_SEL_IR = 4'd9;
    localparam [3:0] S_CAP_IR = 4'd10;
    localparam [3:0] S_SHF_IR = 4'd11;
    localparam [3:0] S_EX1_IR = 4'd12;
    localparam [3:0] S_PAU_IR = 4'd13;
    localparam [3:0] S_EX2_IR = 4'd14;
    localparam [3:0] S_UPD_IR = 4'd15;

    reg [3:0]       tap_state_r;
    reg [IR_W-1:0]  ir_shift_r;
    reg [IR_W-1:0]  ir_r;
    reg [DMI_W-1:0] dr_shift_r;
    reg [1:0]       dmistat_r;
    reg             tck_prev_r;
    reg             tdo_r;

    reg             pending_dmi_op_r;
    reg             pending_dmi_write_r;
    reg [6:0]       pending_dmi_addr_r;
    reg [31:0]      pending_dmi_data_r;
    reg [31:0]      last_dmi_read_data_r;

    reg             dmi_req_en;
    reg [6:0]       dmi_req_addr;
    reg             dmi_req_write;
    reg [31:0]      dmi_req_data;
    wire [31:0]     dmi_resp_data;
    wire [1:0]      dmi_resp_op;

    wire tck_rising = tck & ~tck_prev_r;

    assign tdo = tdo_r;

    dm u_dm (
        .clk            (clk),
        .rst            (rst),
        .dmi_req_en     (dmi_req_en),
        .dmi_req_addr   (dmi_req_addr),
        .dmi_req_write  (dmi_req_write),
        .dmi_req_data   (dmi_req_data),
        .dmi_resp_data  (dmi_resp_data),
        .dmi_resp_op    (dmi_resp_op),
        .halt_req       (halt_req),
        .resume_req     (resume_req),
        .ndmreset       (ndmreset),
        .hart_halted    (hart_halted),
        .hart_havereset (hart_havereset),
        .acc_en         (acc_en),
        .acc_write      (acc_write),
        .acc_regno      (acc_regno),
        .acc_wdata      (acc_wdata),
        .acc_rdata      (acc_rdata),
        .acc_err        (acc_err),
        .dmi_reads      (dmi_reads),
        .dmi_writes     (dmi_writes)
    );

    always @* begin
        dmi_req_en    = pending_dmi_op_r;
        dmi_req_addr  = pending_dmi_addr_r;
        dmi_req_write = pending_dmi_write_r;
        dmi_req_data  = pending_dmi_data_r;
    end

    wire [31:0] dtmcs_view = {
        14'd0,
        1'b0,
        1'b0,
        1'b0,
        3'd0,
        dmistat_r,
        6'd7,
        4'd1
    };

    always @(posedge clk) begin
        if (rst) begin
            tap_state_r          <= S_TLR;
            ir_shift_r           <= {IR_W{1'b0}};
            ir_r                 <= IR_IDCODE;
            dr_shift_r           <= {DMI_W{1'b0}};
            dmistat_r            <= 2'd0;
            tck_prev_r           <= 1'b0;
            tdo_r                <= 1'b0;
            pending_dmi_op_r     <= 1'b0;
            pending_dmi_write_r  <= 1'b0;
            pending_dmi_addr_r   <= 7'd0;
            pending_dmi_data_r   <= 32'd0;
            last_dmi_read_data_r <= 32'd0;
        end else begin
            tck_prev_r <= tck;

            if (pending_dmi_op_r) begin
                last_dmi_read_data_r <= dmi_resp_data;
                pending_dmi_op_r     <= 1'b0;
                dmistat_r            <= dmi_resp_op;
            end

            if (tck_rising) begin
                case (tap_state_r)
                    S_TLR:    tap_state_r <= tms ? S_TLR    : S_RTI;
                    S_RTI:    tap_state_r <= tms ? S_SEL_DR : S_RTI;
                    S_SEL_DR: tap_state_r <= tms ? S_SEL_IR : S_CAP_DR;
                    S_CAP_DR: tap_state_r <= tms ? S_EX1_DR : S_SHF_DR;
                    S_SHF_DR: tap_state_r <= tms ? S_EX1_DR : S_SHF_DR;
                    S_EX1_DR: tap_state_r <= tms ? S_UPD_DR : S_PAU_DR;
                    S_PAU_DR: tap_state_r <= tms ? S_EX2_DR : S_PAU_DR;
                    S_EX2_DR: tap_state_r <= tms ? S_UPD_DR : S_SHF_DR;
                    S_UPD_DR: tap_state_r <= tms ? S_SEL_DR : S_RTI;
                    S_SEL_IR: tap_state_r <= tms ? S_TLR    : S_CAP_IR;
                    S_CAP_IR: tap_state_r <= tms ? S_EX1_IR : S_SHF_IR;
                    S_SHF_IR: tap_state_r <= tms ? S_EX1_IR : S_SHF_IR;
                    S_EX1_IR: tap_state_r <= tms ? S_UPD_IR : S_PAU_IR;
                    S_PAU_IR: tap_state_r <= tms ? S_EX2_IR : S_PAU_IR;
                    S_EX2_IR: tap_state_r <= tms ? S_UPD_IR : S_SHF_IR;
                    S_UPD_IR: tap_state_r <= tms ? S_SEL_DR : S_RTI;
                    default:  tap_state_r <= S_TLR;
                endcase

                if (tms && tap_state_r == S_SEL_IR)
                    ir_r <= IR_IDCODE;

                if (tap_state_r == S_CAP_DR) begin
                    case (ir_r)
                        IR_IDCODE: dr_shift_r <= {{(DMI_W-32){1'b0}}, DTM_IDCODE};
                        IR_DTMCS:  dr_shift_r <= {{(DMI_W-32){1'b0}}, dtmcs_view};
                        IR_DMI:    dr_shift_r <= {pending_dmi_addr_r, last_dmi_read_data_r, dmistat_r};
                        default:   dr_shift_r <= {DMI_W{1'b0}};
                    endcase
                end

                if (tap_state_r == S_SHF_DR) begin
                    case (ir_r)
                        IR_IDCODE,
                        IR_DTMCS: dr_shift_r <= {{(DMI_W-32){1'b0}}, tdi, dr_shift_r[31:1]};
                        IR_DMI:   dr_shift_r <= {tdi, dr_shift_r[DMI_W-1:1]};
                        default:  dr_shift_r <= {{(DMI_W-1){1'b0}}, tdi};
                    endcase
                end

                if (tap_state_r == S_CAP_IR)
                    ir_shift_r <= 5'b00001;
                if (tap_state_r == S_SHF_IR)
                    ir_shift_r <= {tdi, ir_shift_r[IR_W-1:1]};
                if (tap_state_r == S_UPD_IR)
                    ir_r <= ir_shift_r;

                if (tap_state_r == S_UPD_DR && ir_r == IR_DMI) begin
                    if (dr_shift_r[1:0] == 2'd1 || dr_shift_r[1:0] == 2'd2) begin
                        pending_dmi_addr_r  <= dr_shift_r[40:34];
                        pending_dmi_data_r  <= dr_shift_r[33:2];
                        pending_dmi_write_r <= (dr_shift_r[1:0] == 2'd2);
                        pending_dmi_op_r    <= 1'b1;
                    end
                end
            end

            if (tap_state_r == S_SHF_DR)
                tdo_r <= dr_shift_r[0];
            else if (tap_state_r == S_SHF_IR)
                tdo_r <= ir_shift_r[0];
            else
                tdo_r <= 1'b0;
        end
    end
endmodule

`default_nettype wire
