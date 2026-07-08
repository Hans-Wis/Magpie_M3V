// =============================================================================
// npu_tcm_sram_dp.v -- synth-only TSMC28 SRAM macro wrappers for NPU TCMs.
// -----------------------------------------------------------------------------
// Option B: DC sees real registered dual-port SRAM macros for PPA. The default
// simulation path remains the flat memories in npu_tcm.v.
// =============================================================================
`default_nettype none

module npu_tcm_sram_dp #(
    parameter integer WORDS = 8192,
    parameter integer AW    = 13,
    parameter integer DMA_DATA_W = 256,
    parameter integer LANES = 4
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        s_axi_awvalid, output wire s_axi_awready, input wire [31:0] s_axi_awaddr, input wire [2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,  output wire s_axi_wready,  input wire [31:0] s_axi_wdata,  input wire [3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,  input  wire s_axi_bready,  output reg  [1:0] s_axi_bresp,
    input  wire        s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg         s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,

    input  wire        dma_narrow,
    input  wire        dma_we,
    input  wire [AW-1:0] dma_waddr,
    input  wire [DMA_DATA_W-1:0] dma_wdata,

    input  wire        dma_re,
    input  wire [AW-1:0] dma_raddr,
    output wire [DMA_DATA_W-1:0] dma_rdata,

    input  wire            eng_a_re,
    input  wire            eng_b_re,
    input  wire [AW-1:0]   eng_a_addr,
    output wire [255:0]    eng_a_rdata,
    input  wire [AW-1:0]   eng_b_addr,
    output wire [255:0]    eng_b_rdata,
    input  wire            eng_we,
    input  wire [AW-1:0]   eng_waddr,
    input  wire [31:0]     eng_wdata,

    input  wire            core_d_re,
    input  wire [AW-1:0]   core_d_addr,
    output wire [31:0]     core_d_rdata,
    input  wire            core_d_we,
    input  wire [31:0]     core_d_wdata,
    input  wire [ 3:0]     core_d_wstrb,
    output wire            core_d_wgrant
);
    localparam integer WPB = DMA_DATA_W / 32;
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;

    initial begin
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 && DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "npu_tcm_sram_dp: DMA_DATA_W must be one of 32/64/128/256");
        if (LANES != 4)
            $fatal(1, "npu_tcm_sram_dp requires MAT_LANES=4 (256b eng reads must be 32B/8-word aligned)");
    end

    wire unused_ports = &{1'b0, s_axi_awprot, s_axi_arprot, 1'b0};

    function [9:0] dtcm_row;
        input [AW-1:0] word_addr;
        integer ri;
        begin
            dtcm_row = 10'b0;
            for (ri = 3; ri < AW && ri < 13; ri = ri + 1)
                dtcm_row[ri-3] = word_addr[ri];
        end
    endfunction

    function [31:0] strb_to_bweb;
        input [3:0] strb;
        begin
            strb_to_bweb = {{8{~strb[3]}}, {8{~strb[2]}}, {8{~strb[1]}}, {8{~strb[0]}}};
        end
    endfunction

    function [31:0] bank_word;
        input [255:0] bus;
        input [2:0] bank;
        begin
            case (bank)
                3'd0: bank_word = bus[  0 +: 32];
                3'd1: bank_word = bus[ 32 +: 32];
                3'd2: bank_word = bus[ 64 +: 32];
                3'd3: bank_word = bus[ 96 +: 32];
                3'd4: bank_word = bus[128 +: 32];
                3'd5: bank_word = bus[160 +: 32];
                3'd6: bank_word = bus[192 +: 32];
                default: bank_word = bus[224 +: 32];
            endcase
        end
    endfunction

    function bank_bit;
        input [7:0] bus;
        input [2:0] bank;
        begin
            case (bank)
                3'd0: bank_bit = bus[0];
                3'd1: bank_bit = bus[1];
                3'd2: bank_bit = bus[2];
                3'd3: bank_bit = bus[3];
                3'd4: bank_bit = bus[4];
                3'd5: bank_bit = bus[5];
                3'd6: bank_bit = bus[6];
                default: bank_bit = bus[7];
            endcase
        end
    endfunction

    wire [255:0] dtcm_qa_bus;
    wire [255:0] dtcm_qb_bus;
    wire [7:0]   dtcm_a_ceb, dtcm_a_web, dtcm_b_ceb, dtcm_b_web;
    wire [80-1:0] dtcm_a_addr_bus, dtcm_b_addr_bus;
    wire [255:0] dtcm_a_data_bus, dtcm_b_data_bus;
    wire [255:0] dtcm_a_bweb_bus, dtcm_b_bweb_bus;
    wire [7:0] dtcm_dma_read_on_b, dtcm_core_read_on_b, dtcm_host_read_on_b;

    // Host write channel mirrors the flat TCM single-outstanding behavior.
    wire [13:0] aw_off = s_axi_awaddr[15:2];
    wire [13:0] ar_off = s_axi_araddr[15:2];
    reg aw_seen, w_seen, wa_ok;
    reg [AW-1:0] wa_q; reg [31:0] wd_q; reg [3:0] wstrb_q;
    wire host_we        = aw_seen && w_seen && !s_axi_bvalid;
    wire host_mem_grant = host_we && wa_ok && !dma_we && !eng_we && !core_d_we;
    wire host_resp_fire = host_we && (!wa_ok || host_mem_grant);
    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;
    assign core_d_wgrant = core_d_we & ~dma_we & ~eng_we;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen <= 1'b0; w_seen <= 1'b0; s_axi_bvalid <= 1'b0; s_axi_bresp <= OKAY;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen <= 1'b1;
                wa_q <= s_axi_awaddr[AW+1:2];
                wa_ok <= ({18'd0, aw_off} < WORDS);
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_seen <= 1'b1; wd_q <= s_axi_wdata; wstrb_q <= s_axi_wstrb;
            end
            if (host_resp_fire) begin
                s_axi_bvalid <= 1'b1; s_axi_bresp <= wa_ok ? OKAY : SLVERR;
                aw_seen <= 1'b0; w_seen <= 1'b0;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 1'b0;
        end
    end

    // Host read issues a macro read on the address handshake and returns the
    // registered macro output on the following cycle.
    reg host_re_q, host_re_ok_q, host_re_from_b_q;
    reg [2:0] host_re_bank_q;
    wire host_re_ok = ({18'd0, ar_off} < WORDS);
    wire host_re = s_axi_arvalid && s_axi_arready;
    assign s_axi_arready = !host_re_q && !s_axi_rvalid;

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_rvalid <= 1'b0; s_axi_rresp <= OKAY; s_axi_rdata <= 32'b0;
            host_re_q <= 1'b0; host_re_ok_q <= 1'b0; host_re_from_b_q <= 1'b0; host_re_bank_q <= 3'b0;
        end else begin
            if (host_re) begin
                host_re_q <= 1'b1;
                host_re_ok_q <= host_re_ok;
                host_re_bank_q <= s_axi_araddr[4:2];
                host_re_from_b_q <= bank_bit(dtcm_host_read_on_b, s_axi_araddr[4:2]);
            end else begin
                host_re_q <= 1'b0;
            end
            if (host_re_q) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= host_re_ok_q ? OKAY : SLVERR;
                s_axi_rdata <= host_re_ok_q
                    ? (host_re_from_b_q ? bank_word(dtcm_qb_bus, host_re_bank_q) : bank_word(dtcm_qa_bus, host_re_bank_q))
                    : 32'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    genvar gdw;
    generate
        for (gdw = 0; gdw < WPB; gdw = gdw + 1) begin : g_dma_rdata
            reg [2:0] dma_r_bank_q;
            reg       dma_r_from_b_q;
            wire [AW-1:0] lane_addr = dma_raddr + gdw[AW-1:0];
            always @(posedge clk) begin
                if (dma_re) begin
                    dma_r_bank_q <= lane_addr[2:0];
                    dma_r_from_b_q <= bank_bit(dtcm_dma_read_on_b, lane_addr[2:0]);
                end
            end
            assign dma_rdata[gdw*32 +: 32] = dma_r_from_b_q
                ? bank_word(dtcm_qb_bus, dma_r_bank_q)
                : bank_word(dtcm_qa_bus, dma_r_bank_q);
        end
    endgenerate

    reg [2:0] core_d_bank_q;
    reg       core_d_from_b_q;
    always @(posedge clk) begin
        if (core_d_re) begin
            core_d_bank_q <= core_d_addr[2:0];
            core_d_from_b_q <= bank_bit(dtcm_core_read_on_b, core_d_addr[2:0]);
        end
    end
    assign core_d_rdata = core_d_from_b_q ? bank_word(dtcm_qb_bus, core_d_bank_q) : bank_word(dtcm_qa_bus, core_d_bank_q);

    assign eng_a_rdata = dtcm_qa_bus;
    assign eng_b_rdata = dtcm_qb_bus;

    genvar gb;
    generate
        for (gb = 0; gb < 8; gb = gb + 1) begin : g_dtcm_bank
            localparam [2:0] BANK = gb[2:0];
            wire [31:0] qa;
            wire [31:0] qb;

            reg a_ceb_r, a_web_r, b_ceb_r, b_web_r;
            reg [9:0]  a_addr_r, b_addr_r;
            reg [31:0] a_data_r, b_data_r, a_bweb_r, b_bweb_r;
            reg dma_w_hit, dma_r_hit;
            reg [9:0] dma_w_row, dma_r_row;
            reg [31:0] dma_w_word;
            reg [6:0] cand_valid;
            reg [2:0] first_idx, second_idx;
            reg first_valid, second_valid;
            reg dma_read_b_r, core_read_b_r, host_read_b_r;
            reg [3:0] rd_cnt, wr_cnt;
            integer di;
            reg [AW-1:0] lane_addr;

            task set_port_a;
                input [2:0] idx;
                begin
                    a_ceb_r = 1'b0;
                    case (idx)
                        3'd0: begin a_web_r = 1'b0; a_addr_r = dma_w_row; a_data_r = dma_w_word; a_bweb_r = 32'h0000_0000; end
                        3'd1: begin a_web_r = 1'b1; a_addr_r = dma_r_row; a_data_r = 32'b0; a_bweb_r = 32'hffff_ffff; end
                        3'd2: begin a_web_r = 1'b0; a_addr_r = dtcm_row(eng_waddr); a_data_r = eng_wdata; a_bweb_r = 32'h0000_0000; end
                        3'd3: begin a_web_r = 1'b0; a_addr_r = dtcm_row(core_d_addr); a_data_r = core_d_wdata; a_bweb_r = strb_to_bweb(core_d_wstrb); end
                        3'd4: begin a_web_r = 1'b1; a_addr_r = dtcm_row(core_d_addr); a_data_r = 32'b0; a_bweb_r = 32'hffff_ffff; end
                        3'd5: begin a_web_r = 1'b0; a_addr_r = dtcm_row(wa_q); a_data_r = wd_q; a_bweb_r = strb_to_bweb(wstrb_q); end
                        default: begin a_web_r = 1'b1; a_addr_r = dtcm_row(s_axi_araddr[AW+1:2]); a_data_r = 32'b0; a_bweb_r = 32'hffff_ffff; end
                    endcase
                end
            endtask

            task set_port_b;
                input [2:0] idx;
                begin
                    b_ceb_r = 1'b0;
                    case (idx)
                        3'd0: begin b_web_r = 1'b0; b_addr_r = dma_w_row; b_data_r = dma_w_word; b_bweb_r = 32'h0000_0000; end
                        3'd1: begin b_web_r = 1'b1; b_addr_r = dma_r_row; b_data_r = 32'b0; b_bweb_r = 32'hffff_ffff; dma_read_b_r = 1'b1; end
                        3'd2: begin b_web_r = 1'b0; b_addr_r = dtcm_row(eng_waddr); b_data_r = eng_wdata; b_bweb_r = 32'h0000_0000; end
                        3'd3: begin b_web_r = 1'b0; b_addr_r = dtcm_row(core_d_addr); b_data_r = core_d_wdata; b_bweb_r = strb_to_bweb(core_d_wstrb); end
                        3'd4: begin b_web_r = 1'b1; b_addr_r = dtcm_row(core_d_addr); b_data_r = 32'b0; b_bweb_r = 32'hffff_ffff; core_read_b_r = 1'b1; end
                        3'd5: begin b_web_r = 1'b0; b_addr_r = dtcm_row(wa_q); b_data_r = wd_q; b_bweb_r = strb_to_bweb(wstrb_q); end
                        default: begin b_web_r = 1'b1; b_addr_r = dtcm_row(s_axi_araddr[AW+1:2]); b_data_r = 32'b0; b_bweb_r = 32'hffff_ffff; host_read_b_r = 1'b1; end
                    endcase
                end
            endtask

            always @* begin
                dma_w_hit = 1'b0; dma_r_hit = 1'b0;
                dma_w_row = dtcm_row(dma_waddr); dma_r_row = dtcm_row(dma_raddr);
                dma_w_word = dma_wdata[31:0];
                rd_cnt = 4'd0; wr_cnt = 4'd0;
                for (di = 0; di < WPB; di = di + 1) begin
                    lane_addr = dma_waddr + di[AW-1:0];
                    if (dma_we && (dma_narrow ? (di == 0 && dma_waddr[2:0] == BANK) : (lane_addr[2:0] == BANK))) begin
                        dma_w_hit = 1'b1;
                        dma_w_row = dtcm_row(lane_addr);
                        dma_w_word = dma_wdata[di*32 +: 32];
                        wr_cnt = wr_cnt + 4'd1;
                    end
                    lane_addr = dma_raddr + di[AW-1:0];
                    if (dma_re && (dma_narrow ? (di == 0 && dma_raddr[2:0] == BANK) : (lane_addr[2:0] == BANK))) begin
                        dma_r_hit = 1'b1;
                        dma_r_row = dtcm_row(lane_addr);
                        rd_cnt = rd_cnt + 4'd1;
                    end
                end
                if (eng_a_re) rd_cnt = rd_cnt + 4'd1;
                if (eng_b_re) rd_cnt = rd_cnt + 4'd1;
                if (eng_we && eng_waddr[2:0] == BANK) wr_cnt = wr_cnt + 4'd1;
                if (core_d_we && core_d_addr[2:0] == BANK) wr_cnt = wr_cnt + 4'd1;
                if (core_d_re && core_d_addr[2:0] == BANK) rd_cnt = rd_cnt + 4'd1;
                if (host_mem_grant && wa_q[2:0] == BANK) wr_cnt = wr_cnt + 4'd1;
                if (host_re && host_re_ok && s_axi_araddr[4:2] == BANK) rd_cnt = rd_cnt + 4'd1;

                cand_valid[0] = dma_w_hit;
                cand_valid[1] = dma_r_hit;
                cand_valid[2] = eng_we && eng_waddr[2:0] == BANK;
                cand_valid[3] = core_d_we && core_d_addr[2:0] == BANK;
                cand_valid[4] = core_d_re && core_d_addr[2:0] == BANK;
                cand_valid[5] = host_mem_grant && wa_q[2:0] == BANK;
                cand_valid[6] = host_re && host_re_ok && s_axi_araddr[4:2] == BANK;

                first_valid = 1'b1;
                if (cand_valid[0]) first_idx = 3'd0;
                else if (cand_valid[1]) first_idx = 3'd1;
                else if (cand_valid[2]) first_idx = 3'd2;
                else if (cand_valid[3]) first_idx = 3'd3;
                else if (cand_valid[4]) first_idx = 3'd4;
                else if (cand_valid[5]) first_idx = 3'd5;
                else if (cand_valid[6]) first_idx = 3'd6;
                else begin first_valid = 1'b0; first_idx = 3'd0; end

                cand_valid[first_idx] = 1'b0;
                second_valid = 1'b1;
                if (cand_valid[0]) second_idx = 3'd0;
                else if (cand_valid[1]) second_idx = 3'd1;
                else if (cand_valid[2]) second_idx = 3'd2;
                else if (cand_valid[3]) second_idx = 3'd3;
                else if (cand_valid[4]) second_idx = 3'd4;
                else if (cand_valid[5]) second_idx = 3'd5;
                else if (cand_valid[6]) second_idx = 3'd6;
                else begin second_valid = 1'b0; second_idx = 3'd0; end

                a_ceb_r = 1'b1; a_web_r = 1'b1; a_addr_r = 10'b0; a_data_r = 32'b0; a_bweb_r = 32'hffff_ffff;
                b_ceb_r = 1'b1; b_web_r = 1'b1; b_addr_r = 10'b0; b_data_r = 32'b0; b_bweb_r = 32'hffff_ffff;
                dma_read_b_r = 1'b0; core_read_b_r = 1'b0; host_read_b_r = 1'b0;

                if (eng_a_re) begin
                    a_ceb_r = 1'b0; a_web_r = 1'b1; a_addr_r = dtcm_row(eng_a_addr);
                end
                if (eng_b_re) begin
                    b_ceb_r = 1'b0; b_web_r = 1'b1; b_addr_r = dtcm_row(eng_b_addr);
                end

                if (first_valid) begin
                    if (!eng_a_re) set_port_a(first_idx);
                    else if (!eng_b_re) set_port_b(first_idx);
                end
                if (second_valid && !eng_a_re && !eng_b_re) set_port_b(second_idx);
            end

`ifndef SYNTHESIS
            always @(posedge clk) begin
                if (resetn && (wr_cnt > 4'd1 || (rd_cnt + wr_cnt) > 4'd2)) begin
                    $error("NPU_DTCM_SRAM: bank %0d dual-port conflict rd=%0d wr=%0d at %0t",
                           BANK, rd_cnt, wr_cnt, $time);
                end
            end
`endif

            assign dtcm_a_ceb[gb] = a_ceb_r;
            assign dtcm_a_web[gb] = a_web_r;
            assign dtcm_b_ceb[gb] = b_ceb_r;
            assign dtcm_b_web[gb] = b_web_r;
            assign dtcm_a_addr_bus[gb*10 +: 10] = a_addr_r;
            assign dtcm_b_addr_bus[gb*10 +: 10] = b_addr_r;
            assign dtcm_a_data_bus[gb*32 +: 32] = a_data_r;
            assign dtcm_b_data_bus[gb*32 +: 32] = b_data_r;
            assign dtcm_a_bweb_bus[gb*32 +: 32] = a_bweb_r;
            assign dtcm_b_bweb_bus[gb*32 +: 32] = b_bweb_r;
            assign dtcm_qa_bus[gb*32 +: 32] = qa;
            assign dtcm_qb_bus[gb*32 +: 32] = qb;
            assign dtcm_dma_read_on_b[gb] = dma_read_b_r;
            assign dtcm_core_read_on_b[gb] = core_read_b_r;
            assign dtcm_host_read_on_b[gb] = host_read_b_r;

            TSDN28HPCPA1024X32M4FWBASO u_sram (
                .SLP(1'b0), .SD(1'b0), .WTSEL(2'b01), .RTSEL(2'b01), .VG(1'b1), .VS(1'b1),
                .AA(dtcm_a_addr_bus[gb*10 +: 10]), .DA(dtcm_a_data_bus[gb*32 +: 32]), .BWEBA(dtcm_a_bweb_bus[gb*32 +: 32]),
                .WEBA(dtcm_a_web[gb]), .CEBA(dtcm_a_ceb[gb]), .CLKA(clk),
                .AB(dtcm_b_addr_bus[gb*10 +: 10]), .DB(dtcm_b_data_bus[gb*32 +: 32]), .BWEBB(dtcm_b_bweb_bus[gb*32 +: 32]),
                .WEBB(dtcm_b_web[gb]), .CEBB(dtcm_b_ceb[gb]), .CLKB(clk),
                .AWT(1'b0),
                .AMA(10'b0), .DMA(32'b0), .BWEBMA(32'hffff_ffff), .WEBMA(1'b1), .CEBMA(1'b1),
                .AMB(10'b0), .DMB(32'b0), .BWEBMB(32'hffff_ffff), .WEBMB(1'b1), .CEBMB(1'b1),
                .BIST(1'b0), .CLKM(clk),
                .QA(qa), .QB(qb)
            );
        end
    endgenerate
endmodule

module npu_itcm_sram_dp #(
    parameter integer WORDS = 2048,
    parameter integer AW    = 11
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        s_axi_awvalid, output wire s_axi_awready, input wire [31:0] s_axi_awaddr, input wire [2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,  output wire s_axi_wready,  input wire [31:0] s_axi_wdata,  input wire [3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,  input  wire s_axi_bready,  output reg  [1:0] s_axi_bresp,
    input  wire        s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg         s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,

    input  wire            core_i_en,
    input  wire [AW-1:0]   core_i_addr,
    output wire [31:0]     core_i_rdata
);
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
    wire unused_ports = &{1'b0, s_axi_awprot, s_axi_arprot, WORDS[15:0], 1'b0};

    function [10:0] itcm_row;
        input [AW-1:0] word_addr;
        integer ri;
        begin
            itcm_row = 11'b0;
            for (ri = 0; ri < AW && ri < 11; ri = ri + 1)
                itcm_row[ri] = word_addr[ri];
        end
    endfunction

    function [31:0] strb_to_bweb;
        input [3:0] strb;
        begin
            strb_to_bweb = {{8{~strb[3]}}, {8{~strb[2]}}, {8{~strb[1]}}, {8{~strb[0]}}};
        end
    endfunction

    wire [13:0] aw_off = s_axi_awaddr[15:2];
    wire [13:0] ar_off = s_axi_araddr[15:2];
    reg aw_seen, w_seen, wa_ok;
    reg [AW-1:0] wa_q; reg [31:0] wd_q; reg [3:0] wstrb_q;
    wire host_we = aw_seen && w_seen && !s_axi_bvalid;
    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen <= 1'b0; w_seen <= 1'b0; s_axi_bvalid <= 1'b0; s_axi_bresp <= OKAY;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen <= 1'b1; wa_q <= s_axi_awaddr[AW+1:2]; wa_ok <= ({18'd0, aw_off} < WORDS);
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_seen <= 1'b1; wd_q <= s_axi_wdata; wstrb_q <= s_axi_wstrb;
            end
            if (host_we) begin
                s_axi_bvalid <= 1'b1; s_axi_bresp <= wa_ok ? OKAY : SLVERR;
                aw_seen <= 1'b0; w_seen <= 1'b0;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 1'b0;
        end
    end

    reg host_re_q, host_re_ok_q;
    wire host_re_ok = ({18'd0, ar_off} < WORDS);
    wire host_re = s_axi_arvalid && s_axi_arready;
    assign s_axi_arready = !host_re_q && !s_axi_rvalid;

    wire [31:0] qa, qb;
    assign core_i_rdata = qa;

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_rvalid <= 1'b0; s_axi_rresp <= OKAY; s_axi_rdata <= 32'b0;
            host_re_q <= 1'b0; host_re_ok_q <= 1'b0;
        end else begin
            if (host_re) begin
                host_re_q <= 1'b1;
                host_re_ok_q <= host_re_ok;
            end else begin
                host_re_q <= 1'b0;
            end
            if (host_re_q) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= host_re_ok_q ? OKAY : SLVERR;
                s_axi_rdata <= host_re_ok_q ? qb : 32'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    wire host_write_fire = host_we && wa_ok;
    wire port_b_en = host_write_fire || (host_re && host_re_ok);
    wire port_b_we_n = host_write_fire ? 1'b0 : 1'b1;
    wire [10:0] port_b_addr = host_write_fire ? itcm_row(wa_q) : itcm_row(s_axi_araddr[AW+1:2]);
    wire [31:0] port_b_bweb = host_write_fire ? strb_to_bweb(wstrb_q) : 32'hffff_ffff;

    TSDN28HPCPA2048X32M8FWBASO u_sram (
        .SLP(1'b0), .SD(1'b0), .WTSEL(2'b01), .RTSEL(2'b01), .VG(1'b1), .VS(1'b1),
        .AA(itcm_row(core_i_addr)), .DA(32'b0), .BWEBA(32'hffff_ffff),
        .WEBA(1'b1), .CEBA(~core_i_en), .CLKA(clk),
        .AB(port_b_addr), .DB(wd_q), .BWEBB(port_b_bweb),
        .WEBB(port_b_we_n), .CEBB(~port_b_en), .CLKB(clk),
        .AWT(1'b0),
        .AMA(11'b0), .DMA(32'b0), .BWEBMA(32'hffff_ffff), .WEBMA(1'b1), .CEBMA(1'b1),
        .AMB(11'b0), .DMB(32'b0), .BWEBMB(32'hffff_ffff), .WEBMB(1'b1), .CEBMB(1'b1),
        .BIST(1'b0), .CLKM(clk),
        .QA(qa), .QB(qb)
    );
endmodule

`default_nettype wire
