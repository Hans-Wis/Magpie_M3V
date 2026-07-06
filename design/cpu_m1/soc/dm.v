// rtl/debug/dm.v — Magpie_X1 RISC-V Debug Module (Phase 7b-1, ADR-0025).
// Adapted for Magpie_M1 ADR-0021 Slice A:
//   - RV32 abstract register access (aarsize=2) with data0..1.
//   - DMI-direct 7-bit address / 32-bit data.
//   - Single hart, no program buffer, no SBA in this MVD slice.
//
// Original first-party source:
//   ~/project/RISC-V/magpie/Magpie_X1/rtl/debug/dm.v
//
// Clean-room basis in original: riscv-debug-spec v0.13.2 ratified.

`default_nettype none

module dm (
    input  wire        clk,
    input  wire        rst,

    input  wire        dmi_req_en,
    input  wire [6:0]  dmi_req_addr,
    input  wire        dmi_req_write,
    input  wire [31:0] dmi_req_data,
    output wire [31:0] dmi_resp_data,
    output wire [1:0]  dmi_resp_op,

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
    localparam [6:0] ADDR_DATA0      = 7'h04;
    localparam [6:0] ADDR_DATA1      = 7'h05;
    localparam [6:0] ADDR_DMCONTROL  = 7'h10;
    localparam [6:0] ADDR_DMSTATUS   = 7'h11;
    localparam [6:0] ADDR_HARTINFO   = 7'h12;
    localparam [6:0] ADDR_ABSTRACTCS = 7'h16;
    localparam [6:0] ADDR_COMMAND    = 7'h17;
    localparam [6:0] ADDR_NEXTDM     = 7'h1d;

    localparam [1:0] OP_SUCCESS = 2'd0;

    reg dmcontrol_haltreq_r;
    reg dmcontrol_resumereq_r;
    reg dmcontrol_ndmreset_r;
    reg dmcontrol_dmactive_r;
    reg havereset_latch_r;
    reg resumeack_latch_r;
    reg resume_pending_r;

    reg [31:0] data0_r;
    reg [31:0] data1_r;

    reg [2:0] abstractcs_cmderr_r;
    reg       abstractcs_busy_r;
    reg [31:0] command_r;

    localparam [1:0] AC_IDLE = 2'd0;
    localparam [1:0] AC_RUN  = 2'd1;
    reg [1:0]  ac_state_r;
    reg        ac_write_r;
    reg [15:0] ac_regno_r;
    reg [31:0] ac_wdata_r;

    reg [63:0] dmi_reads_r;
    reg [63:0] dmi_writes_r;

    assign dmi_reads  = dmi_reads_r;
    assign dmi_writes = dmi_writes_r;

    assign halt_req   = dmcontrol_haltreq_r   & dmcontrol_dmactive_r;
    assign resume_req = dmcontrol_resumereq_r & dmcontrol_dmactive_r;
    assign ndmreset   = dmcontrol_ndmreset_r  & dmcontrol_dmactive_r;

    assign acc_en     = (ac_state_r == AC_RUN);
    assign acc_write  = ac_write_r;
    assign acc_regno  = ac_regno_r;
    assign acc_wdata  = ac_wdata_r;

    wire [31:0] dmcontrol_read =
          {dmcontrol_haltreq_r, 1'b0, 1'b0, 1'b0,
           2'd0, 1'b0, 1'b0, 10'd0, 5'd0, 1'b0, 4'd0, 1'b0, 1'b0,
           dmcontrol_ndmreset_r, dmcontrol_dmactive_r};

    wire [31:0] dmstatus_read = {
        9'd0, 1'b0, 2'd0,
        havereset_latch_r, havereset_latch_r,
        resumeack_latch_r, resumeack_latch_r,
        1'b0, 1'b0, 1'b0, 1'b0,
        ~hart_halted, ~hart_halted, hart_halted, hart_halted,
        1'b1, 1'b0, 1'b0, 1'b0, 4'd2
    };

    wire [31:0] hartinfo_read = {
        8'd0, 4'd1, 3'd0, 1'b0, 4'd2, 12'h7B0
    };

    wire [31:0] abstractcs_read = {
        3'd0, 5'd0, 11'd0, abstractcs_busy_r, 1'b0,
        abstractcs_cmderr_r, 4'd0, 4'd2
    };

    reg [31:0] dmi_read_data;
    always @* begin
        case (dmi_req_addr)
            ADDR_DATA0:      dmi_read_data = data0_r;
            ADDR_DATA1:      dmi_read_data = data1_r;
            ADDR_DMCONTROL:  dmi_read_data = dmcontrol_read;
            ADDR_DMSTATUS:   dmi_read_data = dmstatus_read;
            ADDR_HARTINFO:   dmi_read_data = hartinfo_read;
            ADDR_ABSTRACTCS: dmi_read_data = abstractcs_read;
            ADDR_COMMAND:    dmi_read_data = command_r;
            ADDR_NEXTDM:     dmi_read_data = 32'd0;
            default:         dmi_read_data = 32'd0;
        endcase
    end

    assign dmi_resp_data = dmi_read_data;
    assign dmi_resp_op   = OP_SUCCESS;

    always @(posedge clk) begin
        if (rst) begin
            dmcontrol_haltreq_r   <= 1'b0;
            dmcontrol_resumereq_r <= 1'b0;
            dmcontrol_ndmreset_r  <= 1'b0;
            dmcontrol_dmactive_r  <= 1'b0;
            havereset_latch_r     <= 1'b0;
            resumeack_latch_r     <= 1'b0;
            resume_pending_r      <= 1'b0;
            data0_r               <= 32'd0;
            data1_r               <= 32'd0;
            abstractcs_cmderr_r   <= 3'd0;
            abstractcs_busy_r     <= 1'b0;
            command_r             <= 32'd0;
            ac_state_r            <= AC_IDLE;
            ac_write_r            <= 1'b0;
            ac_regno_r            <= 16'd0;
            ac_wdata_r            <= 32'd0;
            dmi_reads_r           <= 64'd0;
            dmi_writes_r          <= 64'd0;
        end else begin
            if (hart_havereset)
                havereset_latch_r <= 1'b1;
            dmcontrol_resumereq_r <= 1'b0;
            if (resume_pending_r && !hart_halted) begin
                resumeack_latch_r <= 1'b1;
                resume_pending_r  <= 1'b0;
            end

            if (ac_state_r == AC_RUN) begin
                if (acc_err) begin
                    abstractcs_cmderr_r <= 3'd2;
                end else if (!ac_write_r) begin
                    data0_r <= acc_rdata;
                    data1_r <= 32'd0;
                end
                abstractcs_busy_r <= 1'b0;
                ac_state_r        <= AC_IDLE;
            end

            if (dmi_req_en) begin
                if (dmi_req_write) begin
                    dmi_writes_r <= dmi_writes_r + 64'd1;
                    case (dmi_req_addr)
                        ADDR_DATA0: data0_r <= dmi_req_data;
                        ADDR_DATA1: data1_r <= dmi_req_data;
                        ADDR_DMCONTROL: begin
                            dmcontrol_haltreq_r   <= dmi_req_data[31];
                            dmcontrol_resumereq_r <= dmi_req_data[30];
                            if (dmi_req_data[30])
                                resume_pending_r <= 1'b1;
                            dmcontrol_ndmreset_r  <= dmi_req_data[1];
                            dmcontrol_dmactive_r  <= dmi_req_data[0];
                            if (dmi_req_data[28])
                                havereset_latch_r <= 1'b0;
                            if (!dmi_req_data[30]) begin
                                resumeack_latch_r <= 1'b0;
                                resume_pending_r  <= 1'b0;
                            end
                        end
                        ADDR_ABSTRACTCS: begin
                            if (dmi_req_data[10:8] != 3'd0)
                                abstractcs_cmderr_r <= abstractcs_cmderr_r & ~dmi_req_data[10:8];
                        end
                        ADDR_COMMAND: begin
                            command_r <= dmi_req_data;
                            if (abstractcs_cmderr_r != 3'd0) begin
                            end else if (dmi_req_data[31:24] != 8'd0) begin
                                abstractcs_cmderr_r <= 3'd2;
                            end else if (dmi_req_data[22:20] != 3'd2) begin
                                abstractcs_cmderr_r <= 3'd2;
                            end else if (dmi_req_data[17] == 1'b0) begin
                            end else if (!hart_halted) begin
                                abstractcs_cmderr_r <= 3'd4;
                            end else begin
                                ac_write_r <= dmi_req_data[16];
                                ac_regno_r <= dmi_req_data[15:0];
                                ac_wdata_r <= data0_r;
                                ac_state_r <= AC_RUN;
                                abstractcs_busy_r <= 1'b1;
                            end
                        end
                        default: ;
                    endcase
                end else begin
                    dmi_reads_r <= dmi_reads_r + 64'd1;
                end
            end
        end
    end
endmodule

`default_nettype wire
