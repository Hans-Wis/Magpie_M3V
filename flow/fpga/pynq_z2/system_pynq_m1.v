`timescale 1 ns / 1 ps
`default_nettype none

module system_pynq_m1 #(
    parameter [31:0] RAM_BASE   = 32'h2000_0000,
    parameter [31:0] LED_ADDR   = 32'h4000_0000,
    parameter        RAM_ADDR_W = 14,
    parameter        INIT_HEX   = "firmware.hex"
)(
    input  wire       clk,
    input  wire       btn0,
    output wire [3:0] led
);
    reg [3:0] por_cnt;
    reg       resetn;
    wire [2:0] dbg_state;

    initial begin
        por_cnt = 4'h0;
        resetn  = 1'b0;
    end

    always @(posedge clk) begin
        if (btn0) begin
            por_cnt <= 4'h0;
            resetn  <= 1'b0;
        end else begin
            if (por_cnt != 4'hf) por_cnt <= por_cnt + 4'h1;
            resetn <= (por_cnt == 4'hf);
        end
    end

    wire        trap;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire        dbg_axi_err;

    wire        i_arvalid, i_arready, i_rvalid, i_rready;
    wire [31:0] i_araddr, i_rdata;
    wire [ 2:0] i_arprot;
    wire [ 1:0] i_rresp;

    wire        d_arvalid, d_arready, d_rvalid, d_rready;
    wire [31:0] d_araddr, d_rdata;
    wire [ 2:0] d_arprot;
    wire [ 1:0] d_rresp;
    wire        d_awvalid, d_awready, d_wvalid, d_wready, d_bvalid, d_bready;
    wire [31:0] d_awaddr, d_wdata;
    wire [ 2:0] d_awprot;
    wire [ 3:0] d_wstrb;
    wire [ 1:0] d_bresp;

    cpu_m1_axil_top #(.RESET_PC(32'h0000_0000)) u_cpu (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .irq_external_pulse(1'b0),
        .m_axi_i_arvalid(i_arvalid),
        .m_axi_i_arready(i_arready),
        .m_axi_i_araddr(i_araddr),
        .m_axi_i_arprot(i_arprot),
        .m_axi_i_rvalid(i_rvalid),
        .m_axi_i_rready(i_rready),
        .m_axi_i_rdata(i_rdata),
        .m_axi_i_rresp(i_rresp),
        .m_axi_d_arvalid(d_arvalid),
        .m_axi_d_arready(d_arready),
        .m_axi_d_araddr(d_araddr),
        .m_axi_d_arprot(d_arprot),
        .m_axi_d_rvalid(d_rvalid),
        .m_axi_d_rready(d_rready),
        .m_axi_d_rdata(d_rdata),
        .m_axi_d_rresp(d_rresp),
        .m_axi_d_awvalid(d_awvalid),
        .m_axi_d_awready(d_awready),
        .m_axi_d_awaddr(d_awaddr),
        .m_axi_d_awprot(d_awprot),
        .m_axi_d_wvalid(d_wvalid),
        .m_axi_d_wready(d_wready),
        .m_axi_d_wdata(d_wdata),
        .m_axi_d_wstrb(d_wstrb),
        .m_axi_d_bvalid(d_bvalid),
        .m_axi_d_bready(d_bready),
        .m_axi_d_bresp(d_bresp),
        .dbg_axi_err(dbg_axi_err),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    wire i_sel_ram = (i_araddr >= RAM_BASE);
    reg  i_sel_ram_q;
    always @(posedge clk) begin
        if (!resetn) i_sel_ram_q <= 1'b0;
        else if (i_arvalid && i_arready) i_sel_ram_q <= i_sel_ram;
    end

    wire        rom_arvalid, rom_arready, rom_rvalid, rom_rready;
    wire [31:0] rom_rdata;
    wire [ 1:0] rom_rresp;
    wire        bram_a_arvalid, bram_a_arready, bram_a_rvalid, bram_a_rready;
    wire [31:0] bram_a_rdata;
    wire [ 1:0] bram_a_rresp;

    assign rom_arvalid    = i_arvalid && !i_sel_ram;
    assign bram_a_arvalid = i_arvalid &&  i_sel_ram;
    assign i_arready      = i_sel_ram ? bram_a_arready : rom_arready;
    assign i_rvalid       = i_sel_ram_q ? bram_a_rvalid : rom_rvalid;
    assign i_rdata        = i_sel_ram_q ? bram_a_rdata  : rom_rdata;
    assign i_rresp        = i_sel_ram_q ? bram_a_rresp  : rom_rresp;
    assign rom_rready     = i_rready && !i_sel_ram_q;
    assign bram_a_rready  = i_rready &&  i_sel_ram_q;

    axil_bootrom #(.RAM_BASE(RAM_BASE), .MODE_DEBUG(1'b0)) u_rom (
        .clk(clk),
        .resetn(resetn),
        .s_arvalid(rom_arvalid),
        .s_arready(rom_arready),
        .s_araddr(i_araddr),
        .s_rready(rom_rready),
        .s_rvalid(rom_rvalid),
        .s_rdata(rom_rdata),
        .s_rresp(rom_rresp)
    );

    wire d_rd_sel_led = (d_araddr == LED_ADDR);
    reg  d_rd_sel_led_q;
    always @(posedge clk) begin
        if (!resetn) d_rd_sel_led_q <= 1'b0;
        else if (d_arvalid && d_arready) d_rd_sel_led_q <= d_rd_sel_led;
    end

    wire        bram_b_arvalid, bram_b_arready, bram_b_rvalid, bram_b_rready;
    wire [31:0] bram_b_rdata;
    wire [ 1:0] bram_b_rresp;
    wire        bram_b_awvalid, bram_b_awready, bram_b_wvalid, bram_b_wready;
    wire        bram_b_bvalid, bram_b_bready;
    wire [ 1:0] bram_b_bresp;

    reg [3:0] led_reg;

    initial led_reg = 4'h0;

    assign bram_b_arvalid = d_arvalid && !d_rd_sel_led;
    assign d_arready      = d_rd_sel_led ? !led_rvalid : bram_b_arready;
    assign d_rvalid       = d_rd_sel_led_q ? led_rvalid : bram_b_rvalid;
    assign d_rdata        = d_rd_sel_led_q ? {28'h0, led_reg} : bram_b_rdata;
    assign d_rresp        = d_rd_sel_led_q ? 2'b00 : bram_b_rresp;
    assign bram_b_rready  = d_rready && !d_rd_sel_led_q;

    reg led_rvalid;
    always @(posedge clk) begin
        if (!resetn) led_rvalid <= 1'b0;
        else if (d_arvalid && d_arready && d_rd_sel_led) led_rvalid <= 1'b1;
        else if (led_rvalid && d_rready) led_rvalid <= 1'b0;
    end

    wire wr_sel_led = (d_awaddr == LED_ADDR);
    reg  wr_target_valid;
    reg  wr_target_led;
    wire wr_target_fire = d_awvalid && d_awready;
    wire wr_have_target = wr_target_valid || wr_target_fire;
    wire wr_to_led      = wr_target_valid ? wr_target_led : wr_sel_led;

    assign d_awready       = !wr_target_valid && (wr_sel_led ? !led_bvalid : bram_b_awready);
    assign bram_b_awvalid  = d_awvalid && !wr_sel_led && !wr_target_valid;
    assign bram_b_wvalid   = d_wvalid && wr_have_target && !wr_to_led;
    assign d_wready        = wr_have_target ? (wr_to_led ? !led_bvalid : bram_b_wready) : 1'b0;
    assign bram_b_bready   = d_bready && !wr_to_led;
    assign d_bvalid        = wr_to_led ? led_bvalid : bram_b_bvalid;
    assign d_bresp         = wr_to_led ? 2'b00 : bram_b_bresp;

    reg led_bvalid;
    always @(posedge clk) begin
        if (!resetn) begin
            wr_target_valid <= 1'b0;
            wr_target_led   <= 1'b0;
            led_bvalid      <= 1'b0;
            led_reg         <= 4'h0;
        end else begin
            if (wr_target_fire) begin
                wr_target_valid <= 1'b1;
                wr_target_led   <= wr_sel_led;
            end

            if (d_wvalid && d_wready && wr_to_led) begin
                if (d_wstrb[0]) led_reg <= d_wdata[3:0];
                led_bvalid      <= 1'b1;
                wr_target_valid <= 1'b0;
            end else if (d_wvalid && d_wready && !wr_to_led) begin
                wr_target_valid <= 1'b0;
            end

            if (led_bvalid && d_bready) led_bvalid <= 1'b0;
        end
    end

    axil_dp_bram #(.ADDR_W(RAM_ADDR_W), .INIT_HEX(INIT_HEX)) u_bram (
        .clk(clk),
        .resetn(resetn),
        .a_arvalid(bram_a_arvalid),
        .a_arready(bram_a_arready),
        .a_araddr(i_araddr),
        .a_rvalid(bram_a_rvalid),
        .a_rready(bram_a_rready),
        .a_rdata(bram_a_rdata),
        .a_rresp(bram_a_rresp),
        .b_arvalid(bram_b_arvalid),
        .b_arready(bram_b_arready),
        .b_araddr(d_araddr),
        .b_rvalid(bram_b_rvalid),
        .b_rready(bram_b_rready),
        .b_rdata(bram_b_rdata),
        .b_rresp(bram_b_rresp),
        .b_awvalid(bram_b_awvalid),
        .b_awready(bram_b_awready),
        .b_awaddr(d_awaddr),
        .b_wvalid(bram_b_wvalid),
        .b_wready(bram_b_wready),
        .b_wdata(d_wdata),
        .b_wstrb(d_wstrb),
        .b_bvalid(bram_b_bvalid),
        .b_bready(bram_b_bready),
        .b_bresp(bram_b_bresp)
    );

    assign led = trap ? 4'hf : led_reg;

    wire unused = ^{i_arprot, d_arprot, d_awprot, dbg_pc, dbg_instr, dbg_state, dbg_axi_err};
endmodule

`default_nettype wire
