// =============================================================================
// tb_soc_m3v_p1.v — gate_89/90: ADR-0070 P1 (debug dm/dtm mount + GPIO)
// -----------------------------------------------------------------------------
// One imem-boot run, two directed phases with granular markers:
//   GPIO : reset values -> DIR/OUT pad+oe assert -> TB-driven IN via 2FF
//   JTAG : idle halt_req quiet -> IDCODE -> dmactive -> haltreq (heartbeat
//          freezes) -> abstract read sp==0x80010000 -> resume (heartbeat moves)
// JTAG task library copied from flow/v2_pipeline/phase_06_01_debug_jtag/
// tb_debug_jtag.v (first-party) — TCK is bit-banged, 3 sysclk per TCK phase.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_soc_m3v_p1;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    wire host_trap, host_axi_err, npu_irq;
    wire [31:0] host_dbg_pc, host_dbg_instr;
    wire [2:0] host_dbg_state;
    wire uart_tx_strobe;
    wire [7:0] uart_tx_byte;
    wire qspi_sclk, qspi_cs_n;
    wire [3:0] qspi_io_o, qspi_io_oe, qspi_io_i;
    wire [15:0] gpio_out, gpio_oe;
    reg  [15:0] gpio_in = 16'h0;
    reg  tck = 1'b0, tms = 1'b0, tdi = 1'b0;
    wire tdo;
    wire dm_ndmreset;

    soc_m3v_top #(
        .HOST_IMEM_WORDS(8192),
        .HOST_IMEM_AW(13),
        .SHARED_WORDS(16384),
        .SHARED_AW(14),
        .HOST_INIT_HEX("design/npu/sw/host_p1/host_p1.hex")
    ) dut (
        .clk(clk), .resetn(resetn),
        .host_trap(host_trap), .host_axi_err(host_axi_err),
        .host_dbg_pc(host_dbg_pc), .host_dbg_instr(host_dbg_instr),
        .host_dbg_state(host_dbg_state),
        .npu_irq(npu_irq),
        .uart_tx_strobe(uart_tx_strobe), .uart_tx_byte(uart_tx_byte),
        .qspi_sclk(qspi_sclk), .qspi_cs_n(qspi_cs_n),
        .qspi_io_o(qspi_io_o), .qspi_io_oe(qspi_io_oe), .qspi_io_i(qspi_io_i),
        .gpio_out(gpio_out), .gpio_oe(gpio_oe), .gpio_in(gpio_in),
        .jtag_tck(tck), .jtag_tms(tms), .jtag_tdi(tdi), .jtag_tdo(tdo),
        .dm_ndmreset(dm_ndmreset)
    );

    spi_nor_model u_flash (
        .sclk(qspi_sclk), .cs_n(qspi_cs_n), .io_i(qspi_io_o), .io_o(qspi_io_i), .io_oe_i(qspi_io_oe));

    localparam integer F_GPIO_RDY  = 32'h0000FE20 >> 2;
    localparam integer F_TB_DRIVEN = 32'h0000FE24 >> 2;
    localparam integer F_IN_VALUE  = 32'h0000FE28 >> 2;
    localparam integer F_HEARTBEAT = 32'h0000FE2C >> 2;

    // ---- JTAG task library (from tb_debug_jtag.v, first-party) ----
    localparam [4:0] IR_IDCODE = 5'h01;
    localparam [4:0] IR_DMI    = 5'h11;
    localparam [1:0] DMI_OP_NOP   = 2'd0;
    localparam [1:0] DMI_OP_READ  = 2'd1;
    localparam [1:0] DMI_OP_WRITE = 2'd2;
    localparam [6:0] DMI_DATA0      = 7'h04;
    localparam [6:0] DMI_DMCONTROL  = 7'h10;
    localparam [6:0] DMI_DMSTATUS   = 7'h11;
    localparam [6:0] DMI_ABSTRACTCS = 7'h16;
    localparam [6:0] DMI_COMMAND    = 7'h17;
    localparam [31:0] DTM_IDCODE_EXPECTED = 32'h10A9_8AD3;
    localparam [31:0] DM_ACTIVE           = 32'h0000_0001;
    localparam [31:0] DM_HALTREQ          = 32'h8000_0001;
    localparam [31:0] DM_RESUMEREQ        = 32'h4000_0001;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task tap_step;
        input tms_i;
        input tdi_i;
        output tdo_o;
        begin
            // timing kept IDENTICAL to tb_debug_jtag.v — the dtm tck
            // synchronizer phase is part of the proven contract; stretching
            // the phases shifts the first captured TDO bit.
            tms = tms_i;
            tdi = tdi_i;
            tck = 1'b0;
            tick();
            tck = 1'b1;
            tick();
            tdo_o = tdo;
            tck = 1'b0;
            tick();
        end
    endtask

    task tap_step_ignore;
        input tms_i;
        input tdi_i;
        reg tdo_unused;
        begin
            tap_step(tms_i, tdi_i, tdo_unused);
        end
    endtask

    task jtag_reset_to_rti;
        integer i;
        begin
            for (i = 0; i < 6; i = i + 1)
                tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
        end
    endtask

    task jtag_shift_ir;
        input [4:0] ir;
        integer i;
        begin
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            for (i = 0; i < 5; i = i + 1)
                tap_step_ignore((i == 4), ir[i]);
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
        end
    endtask

    task jtag_shift_dr;
        input [40:0] data_in;
        input integer length;
        output [40:0] data_out;
        integer i;
        reg tdo_bit;
        begin
            data_out = 41'd0;
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
            for (i = 0; i < length; i = i + 1) begin
                tap_step((i == length - 1), data_in[i], tdo_bit);
                data_out[i] = tdo_bit;
            end
            tap_step_ignore(1'b1, 1'b0);
            tap_step_ignore(1'b0, 1'b0);
        end
    endtask

    task jtag_read_idcode;
        output [31:0] idcode;
        reg [40:0] scan_out;
        begin
            jtag_shift_ir(IR_IDCODE);
            jtag_shift_dr(41'd0, 32, scan_out);
            idcode = scan_out[31:0];
        end
    endtask

    task jtag_dmi_op;
        input [6:0] addr;
        input [31:0] data;
        input [1:0] op;
        output [31:0] out_data;
        output [1:0] out_stat;
        reg [40:0] scan_in;
        reg [40:0] scan_out;
        begin
            jtag_shift_ir(IR_DMI);
            scan_in = {addr, data, op};
            jtag_shift_dr(scan_in, 41, scan_out);
            out_data = scan_out[33:2];
            out_stat = scan_out[1:0];
        end
    endtask

    task jtag_dmi_write;
        input [6:0] addr;
        input [31:0] data;
        reg [31:0] unused_data;
        reg [1:0] unused_stat;
        begin
            jtag_dmi_op(addr, data, DMI_OP_WRITE, unused_data, unused_stat);
        end
    endtask

    task jtag_dmi_read;
        input [6:0] addr;
        output [31:0] data;
        reg [31:0] unused_data;
        reg [1:0] stat;
        begin
            jtag_dmi_op(addr, 32'd0, DMI_OP_READ, unused_data, stat);
            jtag_dmi_op(7'd0, 32'd0, DMI_OP_NOP, data, stat);
            if (stat != 2'd0)
                $fatal(1, "P1_FAIL dmi read dmistat=%0d addr=%h", stat, addr);
        end
    endtask

    task jtag_abstract_read;
        input [15:0] regno;
        output [31:0] data;
        reg [31:0] abstractcs;
        begin
            jtag_dmi_write(DMI_ABSTRACTCS, 32'h0000_0700);
            jtag_dmi_write(DMI_COMMAND, 32'h0022_0000 | {16'h0, regno});
            jtag_dmi_read(DMI_ABSTRACTCS, abstractcs);
            if (abstractcs[10:8] != 3'd0)
                $fatal(1, "P1_FAIL abstract cmderr regno=%h cs=%h", regno, abstractcs);
            jtag_dmi_read(DMI_DATA0, data);
        end
    endtask

    // halt_req must stay quiet whenever the TAP is idle (ADR-0070 / Grok #9)
    reg jtag_active = 1'b0;
    always @(posedge clk) begin
        if (resetn && !jtag_active && dut.dbg_halt_req)
            $fatal(1, "P1_FAIL halt_req asserted while JTAG idle");
    end

    integer i;
    reg [31:0] v, beat_a, beat_b;
    initial begin
        repeat (8) @(posedge clk);
        resetn = 1'b1;

        // reset values before firmware touches GPIO (it boots in ~10s of clk;
        // sample immediately after deassert)
        @(posedge clk);
        if (gpio_oe !== 16'h0 || gpio_out !== 16'h0)
            $fatal(1, "P1_FAIL gpio reset oe=%h out=%h", gpio_oe, gpio_out);
        $display("GPIO_RESET_OK");

        // firmware programs DIR=0x00FF OUT=0x5A then raises FE20
        i = 0;
        while (dut.u_shared_sram.mem[F_GPIO_RDY] !== 32'h1 && i < 200000) begin
            @(posedge clk); i = i + 1;
        end
        if (i >= 200000) $fatal(1, "P1_FAIL gpio-ready timeout");
        repeat (4) @(posedge clk);
        if (gpio_oe !== 16'h00FF || gpio_out[7:0] !== 8'h5A)
            $fatal(1, "P1_FAIL gpio drive oe=%h out=%h", gpio_oe, gpio_out);
        $display("GPIO_OE_OUT_OK");

        gpio_in = 16'hA5C3;
        repeat (6) @(posedge clk);   // >= 2FF sync + margin (Grok #11)
        dut.u_shared_sram.mem[F_TB_DRIVEN] = 32'h1;
        i = 0;
        while (dut.u_shared_sram.mem[F_IN_VALUE] === 32'h0 && i < 200000) begin
            @(posedge clk); i = i + 1;
        end
        v = dut.u_shared_sram.mem[F_IN_VALUE];
        if (v[15:0] !== 16'hA5C3 || v[31:16] !== 16'h0)
            $fatal(1, "P1_FAIL gpio IN readback=%h", v);
        $display("GPIO_IN_OK");

        // heartbeat alive + JTAG idle quiet window
        beat_a = dut.u_shared_sram.mem[F_HEARTBEAT];
        repeat (200) @(posedge clk);
        beat_b = dut.u_shared_sram.mem[F_HEARTBEAT];
        if (beat_b == beat_a) $fatal(1, "P1_FAIL heartbeat not running");
        $display("JTAG_IDLE_QUIET_OK");

        jtag_active = 1'b1;
        jtag_reset_to_rti();
        jtag_read_idcode(v);
        if (v !== DTM_IDCODE_EXPECTED)
            $fatal(1, "P1_FAIL idcode=%h", v);
        $display("JTAG_IDCODE_OK");

        jtag_dmi_write(DMI_DMCONTROL, DM_ACTIVE);
        jtag_dmi_write(DMI_DMCONTROL, DM_HALTREQ);
        for (i = 0; i < 80; i = i + 1) begin
            jtag_dmi_read(DMI_DMSTATUS, v);
            if (v[8]) i = 80;
        end
        if (!v[8]) $fatal(1, "P1_FAIL hart did not halt dmstatus=%h", v);
        beat_a = dut.u_shared_sram.mem[F_HEARTBEAT];
        repeat (500) @(posedge clk);
        beat_b = dut.u_shared_sram.mem[F_HEARTBEAT];
        if (beat_b != beat_a) $fatal(1, "P1_FAIL heartbeat moved while halted");
        $display("JTAG_HALT_OK");

        jtag_abstract_read(16'h1002, v);   // x2 = sp
        if (v !== 32'h80010000)
            $fatal(1, "P1_FAIL sp=%h expected 80010000", v);
        $display("JTAG_SP_OK");

        jtag_dmi_write(DMI_DMCONTROL, DM_RESUMEREQ);
        for (i = 0; i < 80; i = i + 1) begin
            jtag_dmi_read(DMI_DMSTATUS, v);
            if (!v[8]) i = 80;
        end
        jtag_active = 1'b0;
        beat_a = dut.u_shared_sram.mem[F_HEARTBEAT];
        i = 0;
        while (dut.u_shared_sram.mem[F_HEARTBEAT] == beat_a && i < 200000) begin
            @(posedge clk); i = i + 1;
        end
        if (i >= 200000) $fatal(1, "P1_FAIL heartbeat did not resume");
        $display("JTAG_RESUME_OK");

        $display("SOC_P1_PASS");
        $finish;
    end

    initial begin
        #60000000;
        $fatal(1, "P1_FAIL watchdog timeout pc=%08x", host_dbg_pc);
    end
endmodule
`default_nettype wire
