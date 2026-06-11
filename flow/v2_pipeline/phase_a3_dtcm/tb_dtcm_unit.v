`timescale 1ns / 1ns

// A3 dtcm UNIT test (ADR-0026 A3 amended): proves the wide-port KPI and the core-port
// contract WITHOUT a CPU in the loop.
//   1. byte-lane writes via the core port, word readback (both banks)
//   2. WIDE PORT KPI: 64 consecutive granted reads -> 8 B/cycle sustained (512B/64cyc)
//   3. arbitration: core_en steals the banks -> wide_ready drops exactly those cycles
//   4. write->wide coherence: wide read sees fresh core-port stores
module tb_dtcm_unit;
    reg         clk = 1'b0;
    reg         core_en = 1'b0;
    reg  [31:0] core_addr = 32'h0;
    wire [31:0] core_rdata;
    reg  [ 3:0] core_wstrb = 4'h0;
    reg  [31:0] core_wdata = 32'h0;
    reg         wide_en = 1'b0;
    reg  [31:0] wide_addr = 32'h0;
    wire [63:0] wide_rdata;
    wire        wide_ready;

    dtcm #(.WORDS(1024)) u_dtcm (
        .clk(clk),
        .core_en(core_en), .core_addr(core_addr), .core_rdata(core_rdata),
        .core_wstrb(core_wstrb), .core_wdata(core_wdata),
        .wide_en(wide_en), .wide_addr(wide_addr), .wide_rdata(wide_rdata),
        .wide_ready(wide_ready)
    );

    always #5 clk = ~clk;

    integer i, grants, denials, cycles;
    reg [63:0] expect64;

    task tick; begin @(posedge clk); #1; end endtask

    initial begin
        // ---- 1. fill 128 words via core port (byte lanes exercised) ----
        repeat (2) tick();
        for (i = 0; i < 128; i = i + 1) begin
            core_addr  = i * 4;
            core_wdata = 32'hA5000000 | i;
            core_wstrb = 4'hF;
            tick();
        end
        core_wstrb = 4'h0;
        // byte-lane: patch one byte in word 5
        core_addr = 5 * 4; core_wdata = 32'h0000_7700; core_wstrb = 4'b0010; tick();
        core_wstrb = 4'h0;
        core_en = 1'b1; core_addr = 5 * 4; tick(); core_en = 1'b0; tick();
        if (core_rdata !== 32'hA500_7705) begin
            $display("FAIL: byte-lane readback %08x", core_rdata); $fatal(1);
        end

        // ---- 2. WIDE KPI: 64 back-to-back granted reads = 8 B/cycle ----
        grants = 0; cycles = 0;
        wide_en = 1'b1;
        for (i = 0; i < 64; i = i + 1) begin
            wide_addr = i * 8;
            tick();
            cycles = cycles + 1;
            if (wide_ready) grants = grants + 1;
            // wide_rdata is valid the SAME tick (addr presented before the edge, data
            // registered at it). Pair idx 2 holds the byte-patched word 5.
            expect64 = (i == 2) ? {32'hA500_7705, 32'hA500_0004}
                                : {32'hA5000000 | (i*2 + 1), 32'hA5000000 | (i*2)};
            if (wide_rdata !== expect64) begin
                $display("FAIL: wide data idx=%0d got=%016x exp=%016x", i, wide_rdata, expect64);
                $fatal(1);
            end
        end
        wide_en = 1'b0;
        if (grants != 64) begin
            $display("FAIL: wide grants %0d/64 (KPI 8 B/c not sustained)", grants); $fatal(1);
        end
        $display("KPI: wide port %0d bytes in %0d cycles = %0d B/c", grants*8, cycles, (grants*8)/cycles);

        // ---- 3. arbitration: core_en active -> wide_ready must drop ----
        denials = 0;
        wide_en = 1'b1; wide_addr = 0;
        core_en = 1'b1; core_addr = 16;
        for (i = 0; i < 4; i = i + 1) begin
            tick();
            if (!wide_ready) denials = denials + 1;
        end
        core_en = 1'b0;
        tick();
        if (denials != 4 || !wide_ready) begin
            $display("FAIL: arbitration denials=%0d wide_ready=%0b", denials, wide_ready); $fatal(1);
        end
        wide_en = 1'b0;

        // ---- 4. store -> wide coherence ----
        core_addr = 8; core_wdata = 32'hDEAD_BEEF; core_wstrb = 4'hF; tick();
        core_addr = 12; core_wdata = 32'hCAFE_F00D; core_wstrb = 4'hF; tick();
        core_wstrb = 4'h0; tick();
        wide_en = 1'b1; wide_addr = 8; tick(); wide_en = 1'b0; tick();
        if (wide_rdata !== 64'hCAFE_F00D_DEAD_BEEF) begin
            $display("FAIL: wide coherence got=%016x", wide_rdata); $fatal(1);
        end

        $display("PASS: dtcm unit — byte-lanes, wide 8 B/c sustained (64/64 grants), arbitration, coherence");
        $finish;
    end
endmodule
