`timescale 1ns / 1ns

module tb_plic_uart_directed;
    reg         clk = 1'b0;
    reg         resetn = 1'b0;
    wire        trap;
    wire        ibus_req;
    wire [31:0] ibus_addr;
    wire [31:0] ibus_rdata;
    wire        dbus_req;
    wire [31:0] dbus_addr;
    wire        dbus_we;
    wire [ 3:0] dbus_wstrb;
    wire [31:0] dbus_wdata;
    wire [31:0] dbus_rdata;
    reg  [ 6:0] plic_sources = 7'h00;
    wire        uart_tx_strobe;
    wire [ 7:0] uart_tx_byte;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [ 2:0] dbg_state;
    wire [31:0] dmi_dummy_resp_data;
    wire [ 1:0] dmi_dummy_resp_op;
    wire        dm_dummy_ndmreset;

    localparam [31:0] RAM_BASE         = 32'h2000_0000;
    localparam [31:0] RESULT_BASE      = 32'h2000_1000;
    localparam [31:0] MCAUSE_EXT_IRQ   = 32'h8000_000b;
    localparam        MEM_WORDS        = 8192;
    localparam        UART_EXPECT_LEN  = 17;

    reg [31:0] memory [0:MEM_WORDS-1];
    initial $readmemh("firmware.hex", memory);

    wire [31:0] i_off = ibus_addr - RAM_BASE;
    wire [31:0] d_off = dbus_addr - RAM_BASE;
    wire [12:0] i_idx = i_off[14:2];
    wire [12:0] d_idx = d_off[14:2];
    assign ibus_rdata = memory[i_idx];
    assign dbus_rdata = memory[d_idx];

    cpu_m1_soc_top #(.RESET_PC(RAM_BASE)) dut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .ibus_req(ibus_req),
        .ibus_addr(ibus_addr),
        .ibus_ready(1'b1),
        .ibus_rdata(ibus_rdata),
        .dbus_req(dbus_req),
        .dbus_addr(dbus_addr),
        .dbus_we(dbus_we),
        .dbus_wstrb(dbus_wstrb),
        .dbus_wdata(dbus_wdata),
        .dbus_ready(1'b1),
        .dbus_rdata(dbus_rdata),
        .irq_external_pulse(1'b0),
        .plic_sources(plic_sources),
        .dmi_req_en(1'b0),
        .dmi_req_addr(7'h0),
        .dmi_req_write(1'b0),
        .dmi_req_data(32'h0),
        .dmi_resp_data(dmi_dummy_resp_data),
        .dmi_resp_op(dmi_dummy_resp_op),
        .dm_ndmreset(dm_dummy_ndmreset),
        .uart_tx_strobe(uart_tx_strobe),
        .uart_tx_byte(uart_tx_byte),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    always #5 clk = ~clk;

    reg        saw_plic_ready;
    reg        saw_plic_meip_high;
    reg        saw_plic_meip_low_after_claim;
    reg        saw_plic_resume;
    reg        saw_uart_done;
    reg        saw_smoke_ready;
    reg        saw_smoke_meip_high;
    reg        saw_smoke_resume;
    reg [31:0] plic_mcause;
    reg [31:0] plic_mepc;
    reg [31:0] plic_claim;
    reg [31:0] smoke_mcause;
    reg [31:0] smoke_mepc;
    reg [31:0] smoke_claim;
    reg [8*UART_EXPECT_LEN-1:0] uart_bytes;
    integer uart_count;

    always @(posedge clk) begin
        if (resetn && dbus_req && dbus_we) begin
            if (dbus_wstrb[0]) memory[d_idx][ 7: 0] <= dbus_wdata[ 7: 0];
            if (dbus_wstrb[1]) memory[d_idx][15: 8] <= dbus_wdata[15: 8];
            if (dbus_wstrb[2]) memory[d_idx][23:16] <= dbus_wdata[23:16];
            if (dbus_wstrb[3]) memory[d_idx][31:24] <= dbus_wdata[31:24];
        end

        if (resetn && dbus_req && dbus_we && dbus_addr[31:12] == RESULT_BASE[31:12]) begin
            case (dbus_addr - RESULT_BASE)
                32'h00: begin
                    if (dbus_wdata == 32'h11110001) saw_plic_ready <= 1'b1;
                    if (dbus_wdata == 32'h11110003) saw_smoke_ready <= 1'b1;
                end
                32'h04: begin plic_mcause <= dbus_wdata; $display("plic mcause=%08x", dbus_wdata); end
                32'h08: begin plic_mepc <= dbus_wdata; $display("plic mepc=%08x", dbus_wdata); end
                32'h0c: begin plic_claim <= dbus_wdata; $display("plic claim=%08x", dbus_wdata); end
                32'h10: saw_plic_resume <= (dbus_wdata == 32'h0000a001);
                32'h20: saw_uart_done <= (dbus_wdata == 32'h0000a002);
                32'h24: begin smoke_mcause <= dbus_wdata; $display("smoke mcause=%08x", dbus_wdata); end
                32'h28: begin smoke_mepc <= dbus_wdata; $display("smoke mepc=%08x", dbus_wdata); end
                32'h2c: begin smoke_claim <= dbus_wdata; $display("smoke claim=%08x", dbus_wdata); end
                32'h30: saw_smoke_resume <= (dbus_wdata == 32'h0000a003);
                32'h34: begin
                    $display("FAIL: unexpected handler mcause=%08x", dbus_wdata);
                    $fatal(1);
                end
                default: begin end
            endcase
        end

        if (saw_plic_ready && dut.u_plic.meip_o)
            saw_plic_meip_high <= 1'b1;
        if (saw_plic_meip_high && plic_claim == 32'h1 && !dut.u_plic.meip_o)
            saw_plic_meip_low_after_claim <= 1'b1;
        if (saw_smoke_ready && dut.u_plic.meip_o)
            saw_smoke_meip_high <= 1'b1;
    end

    always @(negedge clk) begin
        if (resetn && uart_tx_strobe) begin
            if (uart_count < UART_EXPECT_LEN)
                uart_bytes[8*(UART_EXPECT_LEN-1-uart_count) +: 8] <= uart_tx_byte;
            uart_count <= uart_count + 1;
            $write("%c", uart_tx_byte);
        end
    end

    initial begin
        saw_plic_ready = 1'b0;
        saw_plic_meip_high = 1'b0;
        saw_plic_meip_low_after_claim = 1'b0;
        saw_plic_resume = 1'b0;
        saw_uart_done = 1'b0;
        saw_smoke_ready = 1'b0;
        saw_smoke_meip_high = 1'b0;
        saw_smoke_resume = 1'b0;
        plic_mcause = 32'h0;
        plic_mepc = 32'h0;
        plic_claim = 32'h0;
        smoke_mcause = 32'h0;
        smoke_mepc = 32'h0;
        smoke_claim = 32'h0;
        uart_bytes = {UART_EXPECT_LEN{8'h00}};
        uart_count = 0;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_plic_uart_directed);
        repeat (6) @(posedge clk);
        resetn = 1'b1;

        wait (saw_plic_ready);
        repeat (2) @(posedge clk);
        plic_sources[0] = 1'b1;
        @(posedge clk);
        plic_sources[0] = 1'b0;

        wait (saw_uart_done);

        wait (saw_smoke_ready);
        repeat (2) @(posedge clk);
        plic_sources[0] = 1'b1;
        @(posedge clk);
        plic_sources[0] = 1'b0;

        wait (saw_smoke_resume);
        repeat (10) @(posedge clk);

        if (!saw_plic_meip_high || !saw_plic_meip_low_after_claim) begin
            $display("FAIL: PLIC meip high=%0d low_after_claim=%0d", saw_plic_meip_high, saw_plic_meip_low_after_claim);
            $fatal(1);
        end
        if (!saw_plic_resume || plic_mcause !== MCAUSE_EXT_IRQ || plic_claim !== 32'h1) begin
            $display("FAIL: PLIC mcause=%08x claim=%08x resume=%0d", plic_mcause, plic_claim, saw_plic_resume);
            $fatal(1);
        end
        if (!saw_uart_done || uart_count != UART_EXPECT_LEN ||
            uart_bytes !== "MAGPIE PLIC UART\n") begin
            $display("FAIL: UART count=%0d bytes='%0s'", uart_count, uart_bytes);
            $fatal(1);
        end
        if (!saw_smoke_meip_high || !saw_smoke_resume ||
            smoke_mcause !== MCAUSE_EXT_IRQ || smoke_claim !== 32'h1) begin
            $display("FAIL: smoke meip=%0d mcause=%08x claim=%08x resume=%0d",
                     saw_smoke_meip_high, smoke_mcause, smoke_claim, saw_smoke_resume);
            $fatal(1);
        end

        $display("PASS: PLIC mcause=%08x claim=%0d meip_deasserted=%0d; UART string='%0s'; smoke mcause=%08x claim=%0d",
                 plic_mcause, plic_claim, saw_plic_meip_low_after_claim,
                 uart_bytes, smoke_mcause, smoke_claim);
        $finish;
    end

    initial begin
        #80_000;
        $display("FAIL: watchdog timeout pc=%08x", dbg_pc);
        $fatal(1);
    end
endmodule
