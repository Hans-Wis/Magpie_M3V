// tb_equiv.v - Phase 2.1 mem_wrapper equivalence test (ADR-0005)
//
// Single cold start; bare `core` (golden, 0-wait) and cpu_m1_top (DUT, wait
// states via +imode/+dmode plusargs) run CONCURRENTLY. Commit streams are
// recorded independently (different cycle timing) and compared by commit index.
// Bare core vs Spike is already proven (phase_03_06) => DUT==bare => DUT==Spike.
//
// Bus protocol = combinational-read, ready-gated (ADR-0005 §2).
// Run once per wait config:  ./Vtb_equiv +imode=N +dmode=M   (N,M in {0,1,3,9})
`timescale 1ns/1ns

module tb_equiv;
    localparam integer MEMW = 4096, AB = 12, MAXC = 400000, MAXN = 4096;
    integer imode, dmode;

    reg clk = 0; always #5 clk = ~clk;
    reg resetn;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;

    // ---------- reference (bare core, native registered 1-cycle memory) ----------
    reg  [31:0] rmem [0:MEMW-1];
    wire [31:0] r_iaddr; wire r_ien; reg [31:0] r_irdata;
    wire        r_dval; wire [31:0] r_daddr, r_dwdata; wire [3:0] r_dwstrb; reg [31:0] r_drdata;
    wire [31:0] r_dbgpc, r_dbginstr; wire [2:0] r_dbgst; wire r_trap;
    wire [11:0] r_iidx = r_iaddr[AB+1:2];
    wire [11:0] r_didx = r_daddr[AB+1:2];
    always @(posedge clk) begin
        if (r_ien) r_irdata <= rmem[r_iidx];
        if (r_dval) begin
            r_drdata <= rmem[r_didx];
            if (r_dwstrb[0]) rmem[r_didx][ 7:0]  <= r_dwdata[ 7:0];
            if (r_dwstrb[1]) rmem[r_didx][15:8]  <= r_dwdata[15:8];
            if (r_dwstrb[2]) rmem[r_didx][23:16] <= r_dwdata[23:16];
            if (r_dwstrb[3]) rmem[r_didx][31:24] <= r_dwdata[31:24];
        end
    end
    core refc(.clk(clk), .resetn(resetn), .trap(r_trap), .mem_stall(1'b0),
        .i_mem_addr(r_iaddr), .i_mem_en(r_ien), .i_mem_rdata(r_irdata),
        .d_mem_valid(r_dval), .d_mem_addr(r_daddr), .d_mem_wdata(r_dwdata),
        .d_mem_wstrb(r_dwstrb), .d_mem_rdata(r_drdata), .irq_external_pulse(1'b0),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy_halted),
        .debug_mode_o       (dbg_dummy_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dbg_dummy_acc_rdata),
        .dm_acc_err         (dbg_dummy_acc_err),
        .dbg_pc(r_dbgpc), .dbg_instr(r_dbginstr), .dbg_state(r_dbgst));

    // ---------- DUT (cpu_m1_top, valid/ready, combinational-read mem + waits) ----------
    reg  [31:0] dmem [0:MEMW-1];
    wire        ireq; wire [31:0] iaddr; reg iready; wire [31:0] irdata;
    wire        dreq; wire [31:0] daddr, dwdata; wire dwe; wire [3:0] dwstrb; reg dready; wire [31:0] drdata;
    wire [31:0] d_dbgpc, d_dbginstr; wire [2:0] d_dbgst; wire d_trap;
    wire [11:0] d_iidx = iaddr[AB+1:2];
    wire [11:0] d_didx = daddr[AB+1:2];
    assign irdata = dmem[d_iidx];
    assign drdata = dmem[d_didx];
    always @(posedge clk)
        if (dreq && dready && dwe) begin
            if (dwstrb[0]) dmem[d_didx][ 7:0]  <= dwdata[ 7:0];
            if (dwstrb[1]) dmem[d_didx][15:8]  <= dwdata[15:8];
            if (dwstrb[2]) dmem[d_didx][23:16] <= dwdata[23:16];
            if (dwstrb[3]) dmem[d_didx][31:24] <= dwdata[31:24];
        end
    cpu_m1_top dut(.clk(clk), .resetn(resetn), .trap(d_trap),
        .ibus_req(ireq), .ibus_addr(iaddr), .ibus_ready(iready), .ibus_rdata(irdata),
        .dbus_req(dreq), .dbus_addr(daddr), .dbus_we(dwe), .dbus_wstrb(dwstrb),
        .dbus_wdata(dwdata), .dbus_ready(dready), .dbus_rdata(drdata),
        .irq_external_pulse(1'b0),
        .mtip               (1'b0),
        .msip               (1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy_halted),
        .debug_mode         (dbg_dummy_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dbg_dummy_acc_rdata),
        .dm_acc_err         (dbg_dummy_acc_err),
        .dbg_pc(d_dbgpc), .dbg_instr(d_dbginstr), .dbg_state(d_dbgst));

    // ---------- wait-state generators ----------
    integer icnt = 0, dcnt = 0; reg [15:0] ilfsr = 16'hACE1, dlfsr = 16'h1234;
    always @(posedge clk) begin icnt<=icnt+1; dcnt<=dcnt+1;
        ilfsr<={ilfsr[14:0], ilfsr[15]^ilfsr[13]^ilfsr[12]^ilfsr[10]};
        dlfsr<={dlfsr[14:0], dlfsr[15]^dlfsr[13]^dlfsr[12]^dlfsr[10]}; end
    always @* begin
        case (imode) 0: iready=1'b1; 1: iready=icnt[0]; 3: iready=(icnt[1:0]==2'b11); default: iready=ilfsr[0]; endcase
        case (dmode) 0: dready=1'b1; 1: dready=dcnt[0]; 3: dready=(dcnt[1:0]==2'b11); default: dready=dlfsr[0]; endcase
    end

    // ---------- concurrent commit recorders ----------
    integer rn = 0, dn = 0, i, k, errors = 0;
    reg [31:0] rpc[0:MAXN-1]; reg [4:0] rrd[0:MAXN-1]; reg [31:0] rwd[0:MAXN-1];
    reg [31:0] dpc[0:MAXN-1]; reg [4:0] drd[0:MAXN-1]; reg [31:0] dwd[0:MAXN-1];

    // F1 check: count ACCEPTED D-write bus transactions (dreq&dready&dwe).
    // A duplicate store under freeze would inflate this vs the store count.
    integer dwrites = 0;
    always @(posedge clk) if (resetn && !ddone && dreq && dready && dwe) dwrites = dwrites + 1;

    reg rdone = 0, ddone = 0;
    always @(posedge clk) if (resetn) begin
        if (refc.ex_wb_valid_r && refc.ex_wb_illegal_r)         rdone <= 1'b1;
        if (dut.u_core.ex_wb_valid_r && dut.u_core.ex_wb_illegal_r) ddone <= 1'b1;
        if (!rdone && refc.wb_instr_retired && !(refc.ex_wb_valid_r && refc.ex_wb_illegal_r) && rn < MAXN) begin
            rpc[rn]=refc.ex_wb_pc_r;
            rrd[rn]=(refc.rfu_we && refc.rfu_wr_idx!=0)?refc.rfu_wr_idx:5'h0;
            rwd[rn]=(refc.rfu_we && refc.rfu_wr_idx!=0)?refc.rfu_wr_data:32'h0; rn=rn+1; end
        if (!ddone && dut.u_core.wb_instr_retired && !(dut.u_core.ex_wb_valid_r && dut.u_core.ex_wb_illegal_r) && dn < MAXN) begin
            dpc[dn]=dut.u_core.ex_wb_pc_r;
            drd[dn]=(dut.u_core.rfu_we && dut.u_core.rfu_wr_idx!=0)?dut.u_core.rfu_wr_idx:5'h0;
            dwd[dn]=(dut.u_core.rfu_we && dut.u_core.rfu_wr_idx!=0)?dut.u_core.rfu_wr_data:32'h0; dn=dn+1; end
    end

    initial begin
        imode=0; dmode=0;
        void'($value$plusargs("imode=%d", imode));
        void'($value$plusargs("dmode=%d", dmode));
        for (i=0;i<MEMW;i=i+1) begin rmem[i]=32'h0; dmem[i]=32'h0; end
        $readmemh("firmware.hex", rmem);
        $readmemh("firmware.hex", dmem);
        resetn=0; repeat(3) @(posedge clk); resetn=1;
        // run until both cores trap (terminal) or timeout
        for (i=0;i<MAXC;i=i+1) begin @(posedge clk);
            if (rdone && ddone) i=MAXC; end
        // compare
        if (rn != dn) begin $display("FAIL imode=%0d dmode=%0d: commit count ref=%0d dut=%0d", imode,dmode,rn,dn); errors=errors+1; end
        for (k=0;k<rn && k<dn;k=k+1)
            if (dpc[k]!==rpc[k] || drd[k]!==rrd[k] || dwd[k]!==rwd[k]) begin
                $display("FAIL imode=%0d dmode=%0d idx=%0d dut(pc=%08x rd=%0d wd=%08x) ref(pc=%08x rd=%0d wd=%08x)",
                         imode,dmode,k,dpc[k],drd[k],dwd[k],rpc[k],rrd[k],rwd[k]);
                errors=errors+1; k=rn; end
        $display("DWRITES imode=%0d dmode=%0d: %0d accepted D-write bus xfers", imode,dmode,dwrites);
        if (errors==0) $display("OK imode=%0d dmode=%0d: %0d commits match (ref=%0d dut=%0d)", imode,dmode,rn,rn,dn);
        else           $display("RESULT FAIL imode=%0d dmode=%0d", imode,dmode);
        $finish;
    end
endmodule
