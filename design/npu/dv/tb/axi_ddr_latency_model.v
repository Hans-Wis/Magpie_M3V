// =============================================================================
// axi_ddr_latency_model.v -- AXI4-full DDR-latency model for NPU perf TBs
// -----------------------------------------------------------------------------
// Drop-in port/parameter shape for axi_full_sram. The backing array and byte-lane
// semantics match axi_full_sram; only transaction timing is DDR-like.
// =============================================================================
`default_nettype none

module axi_ddr_latency_model #(
    parameter integer WORDS = 16384,
    parameter integer AW    = 14,
    parameter integer DMA_DATA_W = 32,
    parameter [1023:0] INIT_HEX = "",
    parameter integer T_FIRST_HIT  = 24,
    parameter integer T_FIRST_MISS = 48,
    parameter integer COL_CYC      = 13,
    parameter integer PAGE_BYTES   = 2048
) (
    input  wire clk,
    input  wire resetn,

    input  wire        arvalid,
    output reg         arready,
    input  wire [31:0] araddr,
    input  wire [ 7:0] arlen,
    input  wire [ 2:0] arsize,
    input  wire [ 1:0] arburst,
    output reg         rvalid,
    input  wire        rready,
    output reg  [DMA_DATA_W-1:0] rdata,
    output reg         rlast,
    output wire [ 1:0] rresp,

    input  wire        awvalid,
    output reg         awready,
    input  wire [31:0] awaddr,
    input  wire [ 7:0] awlen,
    input  wire [ 2:0] awsize,
    input  wire [ 1:0] awburst,
    input  wire        wvalid,
    output reg         wready,
    input  wire [DMA_DATA_W-1:0] wdata,
    input  wire [DMA_DATA_W/8-1:0] wstrb,
    input  wire        wlast,
    output reg         bvalid,
    input  wire        bready,
    output wire [ 1:0] bresp
);
    assign rresp = 2'b00;
    assign bresp = 2'b00;

    localparam integer WPB = DMA_DATA_W / 32;
    localparam [3:0] WPB_4 = (DMA_DATA_W == 256) ? 4'd8 :
                             (DMA_DATA_W == 128) ? 4'd4 :
                             (DMA_DATA_W == 64)  ? 4'd2 : 4'd1;
    localparam [AW-1:0] WPB_AW = {{(AW-4){1'b0}}, WPB_4};
    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_R_WAIT = 3'd1;
    localparam [2:0] S_R_DATA = 3'd2;
    localparam [2:0] S_W_WAIT = 3'd3;
    localparam [2:0] S_W_DATA = 3'd4;
    localparam [2:0] S_W_RESP = 3'd5;

    reg [31:0] mem [0:WORDS-1];

    reg [2:0] state;
    reg [AW-1:0] rptr;
    reg [AW-1:0] rstride;
    reg [8:0] rbeats_left;
    reg [31:0] rwait;
    reg [2:0] rsize_l;
    reg [AW-1:0] wptr;
    reg [AW-1:0] wstride;
    reg [8:0] wbeats_left;
    reg [31:0] wwait;
    reg prev_page_valid;
    reg [31:0] prev_last_page;
    reg [63:0] bytes_rd;
    reg [63:0] bytes_wr;
    reg [63:0] busy_cycles;
    integer col_cyc_runtime;
    integer wj;

    initial begin
        col_cyc_runtime = COL_CYC;
        if ($value$plusargs("DDR_COL_CYC=%d", col_cyc_runtime)) begin
            if (col_cyc_runtime < 1)
                $fatal(1, "axi_ddr_latency_model: DDR_COL_CYC must be >= 1");
        end
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 && DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "axi_ddr_latency_model: DMA_DATA_W must be one of 32/64/128/256");
        if (PAGE_BYTES < 1)
            $fatal(1, "axi_ddr_latency_model: PAGE_BYTES must be >= 1");
        if (INIT_HEX != "") $readmemh(INIT_HEX, mem);
    end

    function [31:0] merge;
        input [31:0] old;
        input [31:0] wd;
        input [3:0]  strb;
        begin
            merge = {strb[3] ? wd[31:24] : old[31:24],
                     strb[2] ? wd[23:16] : old[23:16],
                     strb[1] ? wd[15:8]  : old[15:8],
                     strb[0] ? wd[7:0]   : old[7:0]};
        end
    endfunction

    function [AW-1:0] beat_base;
        input [31:0] byte_addr;
        input [2:0]  size;
        reg [31:0] word_addr;
        reg [31:0] base;
        begin
            word_addr = {{(32-AW){1'b0}}, byte_addr[AW+1:2]};
            base = (size == 3'd2) ? (word_addr - (word_addr % WPB)) : word_addr;
            beat_base = base[AW-1:0];
        end
    endfunction

    function [AW-1:0] beat_stride;
        input [2:0] size;
        begin
            beat_stride = (size == 3'd2) ? {{(AW-1){1'b0}}, 1'b1} : WPB_AW;
        end
    endfunction

    function [DMA_DATA_W-1:0] wide_read;
        input [AW-1:0] base;
        integer j;
        begin
            wide_read = {DMA_DATA_W{1'b0}};
            for (j = 0; j < WPB; j = j + 1)
                wide_read[j*32 +: 32] = mem[base + j[AW-1:0]];
        end
    endfunction

    function [31:0] beat_bytes;
        input [2:0] size;
        begin
            beat_bytes = 32'd1 << size;
        end
    endfunction

    function [31:0] burst_bytes;
        input [7:0] len;
        input [2:0] size;
        reg [31:0] beats;
        begin
            beats = {24'b0, len} + 32'd1;
            burst_bytes = beats * beat_bytes(size);
        end
    endfunction

    function [31:0] burst_last_addr;
        input [31:0] addr;
        input [7:0] len;
        input [2:0] size;
        begin
            burst_last_addr = addr + burst_bytes(len, size) - 32'd1;
        end
    endfunction

    function [31:0] page_base;
        input [31:0] addr;
        begin
            page_base = (addr / PAGE_BYTES) * PAGE_BYTES;
        end
    endfunction

    function [31:0] first_delay;
        input [31:0] addr;
        begin
            if (prev_page_valid && page_base(addr) == prev_last_page)
                first_delay = T_FIRST_HIT;
            else
                first_delay = T_FIRST_MISS;
        end
    endfunction

    function [31:0] delay_minus_one;
        input [31:0] delay;
        begin
            delay_minus_one = (delay > 32'd1) ? (delay - 32'd1) : 32'd0;
        end
    endfunction

    function [31:0] col_delay_minus_one;
        input unused;
        begin
            col_delay_minus_one = (col_cyc_runtime > 1) ? (col_cyc_runtime - 32'd1) : 32'd0;
        end
    endfunction

    function [63:0] strobe_count;
        input [DMA_DATA_W/8-1:0] strb;
        integer sj;
        begin
            strobe_count = 64'd0;
            for (sj = 0; sj < DMA_DATA_W/8; sj = sj + 1) begin
                if (strb[sj])
                    strobe_count = strobe_count + 64'd1;
            end
        end
    endfunction

    task check_burst;
        input [31:0] addr;
        input [7:0] len;
        input [2:0] size;
        input [1:0] burst;
        input [8*2-1:0] chan;
        reg [31:0] last;
        begin
            last = burst_last_addr(addr, len, size);
            if (burst != 2'b01)
                $fatal(1, "axi_ddr_latency_model: %0s burst must be INCR", chan);
            if (({1'b0, len} + 9'd1) > 9'd256)
                $fatal(1, "axi_ddr_latency_model: %0s burst len exceeds 256", chan);
            if (addr[31:12] != last[31:12])
                $fatal(1, "axi_ddr_latency_model: %0s burst crosses 4KB addr=%08x last=%08x", chan, addr, last);
        end
    endtask

    task print_stats;
        begin
            $display("DDR_MODEL_STATS bytes_rd=%0d bytes_wr=%0d busy_cycles=%0d",
                     bytes_rd, bytes_wr, busy_cycles);
        end
    endtask

    always @* begin
        arready = resetn && (state == S_IDLE);
        awready = resetn && (state == S_IDLE) && !arvalid;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE;
            rvalid <= 1'b0;
            rlast <= 1'b0;
            rdata <= {DMA_DATA_W{1'b0}};
            wready <= 1'b0;
            bvalid <= 1'b0;
            rptr <= {AW{1'b0}};
            rstride <= {{(AW-1){1'b0}}, 1'b1};
            rbeats_left <= 9'd0;
            rwait <= 32'd0;
            rsize_l <= 3'd2;
            wptr <= {AW{1'b0}};
            wstride <= {{(AW-1){1'b0}}, 1'b1};
            wbeats_left <= 9'd0;
            wwait <= 32'd0;
            prev_page_valid <= 1'b0;
            prev_last_page <= 32'd0;
            bytes_rd <= 64'd0;
            bytes_wr <= 64'd0;
            busy_cycles <= 64'd0;
        end else begin
            if (state != S_IDLE)
                busy_cycles <= busy_cycles + 64'd1;

            case (state)
                S_IDLE: begin
                    rvalid <= 1'b0;
                    rlast <= 1'b0;
                    wready <= 1'b0;
                    bvalid <= 1'b0;
                    if (arvalid && arready) begin
                        check_burst(araddr, arlen, arsize, arburst, "AR");
                        rptr <= beat_base(araddr, arsize);
                        rstride <= beat_stride(arsize);
                        rbeats_left <= {1'b0, arlen} + 9'd1;
                        rwait <= delay_minus_one(first_delay(araddr));
                        rsize_l <= arsize;
                        prev_page_valid <= 1'b1;
                        prev_last_page <= page_base(burst_last_addr(araddr, arlen, arsize));
                        if (delay_minus_one(first_delay(araddr)) == 32'd0) begin
                            rdata <= wide_read(beat_base(araddr, arsize));
                            rlast <= (arlen == 8'd0);
                            rvalid <= 1'b1;
                            state <= S_R_DATA;
                        end else begin
                            state <= S_R_WAIT;
                        end
                    end else if (awvalid && awready) begin
                        check_burst(awaddr, awlen, awsize, awburst, "AW");
                        wptr <= beat_base(awaddr, awsize);
                        wstride <= beat_stride(awsize);
                        wbeats_left <= {1'b0, awlen} + 9'd1;
                        wwait <= delay_minus_one(first_delay(awaddr));
                        prev_page_valid <= 1'b1;
                        prev_last_page <= page_base(burst_last_addr(awaddr, awlen, awsize));
                        if (delay_minus_one(first_delay(awaddr)) == 32'd0) begin
                            wready <= 1'b1;
                            state <= S_W_DATA;
                        end else begin
                            state <= S_W_WAIT;
                        end
                    end
                end

                S_R_WAIT: begin
                    if (rwait <= 32'd1) begin
                        rdata <= wide_read(rptr);
                        rlast <= (rbeats_left == 9'd1);
                        rvalid <= 1'b1;
                        rwait <= 32'd0;
                        state <= S_R_DATA;
                    end else begin
                        rwait <= rwait - 32'd1;
                    end
                end

                S_R_DATA: begin
                    if (rvalid && rready) begin
                        bytes_rd <= bytes_rd + {32'd0, beat_bytes(rsize_l)};
                        if (rlast) begin
                            rvalid <= 1'b0;
                            rlast <= 1'b0;
                            state <= S_IDLE;
                        end else begin
                            rptr <= rptr + rstride;
                            rbeats_left <= rbeats_left - 9'd1;
                            if (col_delay_minus_one(1'b0) == 32'd0) begin
                                rdata <= wide_read(rptr + rstride);
                                rlast <= (rbeats_left == 9'd2);
                                rvalid <= 1'b1;
                            end else begin
                                rvalid <= 1'b0;
                                rlast <= 1'b0;
                                rwait <= col_delay_minus_one(1'b0);
                                state <= S_R_WAIT;
                            end
                        end
                    end
                end

                S_W_WAIT: begin
                    if (wwait <= 32'd1) begin
                        wready <= 1'b1;
                        wwait <= 32'd0;
                        state <= S_W_DATA;
                    end else begin
                        wwait <= wwait - 32'd1;
                    end
                end

                S_W_DATA: begin
                    if (wvalid && wready) begin
                        if (wlast != (wbeats_left == 9'd1))
                            $fatal(1, "axi_ddr_latency_model: WLAST does not match AWLEN");
                        for (wj = 0; wj < WPB; wj = wj + 1) begin
                            if (|wstrb[wj*4 +: 4])
                                mem[wptr + wj[AW-1:0]] <= merge(mem[wptr + wj[AW-1:0]],
                                                        wdata[wj*32 +: 32],
                                                        wstrb[wj*4 +: 4]);
                        end
                        bytes_wr <= bytes_wr + strobe_count(wstrb);
                        wptr <= wptr + wstride;
                        if (wlast) begin
                            wready <= 1'b0;
                            bvalid <= 1'b1;
                            state <= S_W_RESP;
                        end else begin
                            wbeats_left <= wbeats_left - 9'd1;
                            if (col_delay_minus_one(1'b0) == 32'd0) begin
                                wready <= 1'b1;
                            end else begin
                                wready <= 1'b0;
                                wwait <= col_delay_minus_one(1'b0);
                                state <= S_W_WAIT;
                            end
                        end
                    end
                end

                S_W_RESP: begin
                    if (bvalid && bready) begin
                        bvalid <= 1'b0;
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    rvalid <= 1'b0;
                    rlast <= 1'b0;
                    wready <= 1'b0;
                    bvalid <= 1'b0;
                end
            endcase
        end
    end
endmodule
`default_nettype wire
