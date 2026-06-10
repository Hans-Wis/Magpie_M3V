// =============================================================================
// cpu_m1_top  (Magpie_M1 CPU IP wrapper, Phase 2.1 mem-wrapper, ADR-0005)
//
// Presents Harvard, single-outstanding, ready-gated valid/ready I/D busses and
// adapts the fixed-latency (registered-read look-ahead) `core` to variable bus
// latency by freezing the pipeline through `core.mem_stall`.
//
// Per-port controller (I and D identical):
//   fire  = core_req && !busy && !mem_stall   // start a bus xfer (not mid-freeze)
//   req   = fire || busy                       // req held until ready
//   addr  = busy ? latched : core              // stable address while waiting
//   xfer  = req && ready                        // transaction completes this cycle
//   on xfer: capture rdata into a register -> presented to core next cycle
//   busy (registered): set on an unready fire, cleared on ready
//   mem_stall = i_busy || d_busy
//
// Why this is correct:
//  - 0 wait states (ready always 1, combinational-read memory): busy never sets,
//    mem_stall stays 0, and `rdata_q <= bus_rdata when fire` is bit-identical to
//    the native TB `if (en) i_mem_rdata <= mem[addr]`. => baseline equivalence.
//  - With wait states: mem_stall is registered so it lags one cycle; the issuing
//    instruction advances out of its stage on the (mem_stall==0) issue cycle, and
//    the freeze protects the *next* cycle's data consumption. `!mem_stall` in
//    `fire` forbids launching a second mem-op while frozen, so the single shared
//    captured-data register is never clobbered before it is consumed.
//  - Misalignment is handled inside `core` (no misaligned bus request is issued).
// =============================================================================

module cpu_m1_top #(
    // Reset vector. Default 0 = native boot behavior (backward compatible).
    // Integrators with a nonzero boot ROM override this AND place the reset
    // handler at RESET_PC (see integration guide). ADR-0012.
    parameter [31:0] RESET_PC = 32'h0000_0000,
    parameter RV32A = 0,
    parameter PMP_ENTRIES = 0
)(
    input             clk,
    input             resetn,

    output            trap,

    // I-side valid/ready (read-only, 1 outstanding)
    output            ibus_req,
    output     [31:0] ibus_addr,
    input             ibus_ready,
    input      [31:0] ibus_rdata,

    // D-side valid/ready (1 outstanding)
    output            dbus_req,
    output     [31:0] dbus_addr,
    output            dbus_we,
    output     [ 3:0] dbus_wstrb,
    output     [31:0] dbus_wdata,
    input             dbus_ready,
    input      [31:0] dbus_rdata,

    input             irq_external_pulse,
    input             mtip,
    input             msip,
    input             meip,

    input             dm_halt_req,
    input             dm_resume_req,
    output            dm_hart_halted,
    output            debug_mode,
    input             dm_acc_en,
    input             dm_acc_write,
    input      [15:0] dm_acc_regno,
    input      [31:0] dm_acc_wdata,
    output     [31:0] dm_acc_rdata,
    output            dm_acc_err,

    output     [31:0] dbg_pc,
    output     [31:0] dbg_instr,
    output     [ 2:0] dbg_state
);

    // ---- core-facing native signals ----
    wire        core_i_mem_en;
    wire [31:0] core_i_mem_addr;
    wire        core_d_mem_valid;
    wire [31:0] core_d_mem_addr;
    wire [31:0] core_d_mem_wdata;
    wire [ 3:0] core_d_mem_wstrb;

    // ---- per-port state ----
    reg        i_busy;
    reg [31:0] i_addr_q;
    reg [31:0] i_rdata_q;

    reg        d_busy;
    reg [31:0] d_addr_q;
    reg [31:0] d_wdata_q;
    reg [ 3:0] d_wstrb_q;
    reg [31:0] d_rdata_q;

    reg primed;   // reset-vector instruction word captured into i_rdata_q

    // single global freeze: any port waiting for its bus, OR the boot prime not
    // yet done. Forced 0 under reset so the core's mem_stall input is never X
    // while the busy/primed regs are still resetting.
    wire mem_stall = ((i_busy | d_busy) | ~primed) & resetn;

    // ---- I-port controller ----
    // The look-ahead core assumes the reset-vector instruction is already in
    // i_mem_rdata when it leaves warmup; a variable-latency bus cannot guarantee
    // that, so the wrapper boot-fetches RESET_PC and freezes (mem_stall) until
    // mem[RESET_PC] is captured. This replaces the native always-on-BRAM priming.
    wire i_boot = ~primed;
    wire i_fire = core_i_mem_en & ~i_busy & ~mem_stall;
    assign ibus_req  = i_boot | i_fire | i_busy;
    assign ibus_addr = i_boot ? RESET_PC : (i_busy ? i_addr_q : core_i_mem_addr);
    wire   i_xfer    = ibus_req & ibus_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            i_busy   <= 1'b0;
            i_addr_q <= 32'h0;
            primed   <= 1'b0;
            // i_rdata_q intentionally NOT reset (captured memory data persists)
        end else begin
            if (i_fire & ~ibus_ready) begin
                i_busy   <= 1'b1;
                i_addr_q <= core_i_mem_addr;
            end else if (i_busy & ibus_ready) begin
                i_busy   <= 1'b0;
            end
        end
        if (i_xfer) i_rdata_q <= ibus_rdata;       // boot word + normal fetches
        if (i_boot & ibus_ready) primed <= 1'b1;   // boot prime complete
    end

    // ---- D-port controller ----
    wire d_fire = core_d_mem_valid & ~d_busy & ~mem_stall;
    assign dbus_req   = d_fire | d_busy;
    assign dbus_addr  = d_busy ? d_addr_q  : core_d_mem_addr;
    assign dbus_wdata = d_busy ? d_wdata_q : core_d_mem_wdata;
    assign dbus_wstrb = d_busy ? d_wstrb_q : core_d_mem_wstrb;
    assign dbus_we    = |dbus_wstrb;
    wire   d_xfer     = dbus_req & dbus_ready;

    always @(posedge clk) begin
        if (!resetn) begin
            d_busy    <= 1'b0;
            d_addr_q  <= 32'h0;
            d_wdata_q <= 32'h0;
            d_wstrb_q <= 4'h0;
            // d_rdata_q intentionally NOT reset (captured memory data persists)
        end else begin
            if (d_fire & ~dbus_ready) begin
                d_busy    <= 1'b1;
                d_addr_q  <= core_d_mem_addr;
                d_wdata_q <= core_d_mem_wdata;
                d_wstrb_q <= core_d_mem_wstrb;
            end else if (d_busy & dbus_ready) begin
                d_busy    <= 1'b0;
            end
        end
        if (d_xfer) d_rdata_q <= dbus_rdata;
    end

    // ---- core ----
    core #(
        .RESET_PC(RESET_PC),
        .RV32A(RV32A),
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_core(
        .clk                (clk),
        .resetn             (resetn),
        .trap               (trap),
        .mem_stall          (mem_stall),

        .i_mem_addr         (core_i_mem_addr),
        .i_mem_en           (core_i_mem_en),
        .i_mem_rdata        (i_rdata_q),

        .d_mem_valid        (core_d_mem_valid),
        .d_mem_addr         (core_d_mem_addr),
        .d_mem_wdata        (core_d_mem_wdata),
        .d_mem_wstrb        (core_d_mem_wstrb),
        .d_mem_rdata        (d_rdata_q),

        .irq_external_pulse (irq_external_pulse),
        .mtip               (mtip),
        .msip               (msip),
        .meip               (meip),

        .dm_halt_req        (dm_halt_req),
        .dm_resume_req      (dm_resume_req),
        .dm_hart_halted     (dm_hart_halted),
        .debug_mode_o       (debug_mode),
        .dm_acc_en          (dm_acc_en),
        .dm_acc_write       (dm_acc_write),
        .dm_acc_regno       (dm_acc_regno),
        .dm_acc_wdata       (dm_acc_wdata),
        .dm_acc_rdata       (dm_acc_rdata),
        .dm_acc_err         (dm_acc_err),

        .dbg_pc             (dbg_pc),
        .dbg_instr          (dbg_instr),
        .dbg_state          (dbg_state)
    );

endmodule
