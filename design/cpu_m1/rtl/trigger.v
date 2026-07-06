// =============================================================================
// trigger.v -- ADR-0022 RISC-V debug trigger module
// -----------------------------------------------------------------------------
// Four mcontrol6 triggers:
//   trigger 0..1 : execute address match
//   trigger 2..3 : load/store address match
//
// Supported fields are intentionally small and WARL-filtered:
//   type=6, match=0 exact, action=1 debug, m=1, chain=0, select=0 address.
//   mcontrol6.hit0 is set when the trigger fires and is writable for clear.
// =============================================================================

`include "def.vh"

module trigger (
    input             clk,
    input             resetn,

    input      [11:0] csr_raddr,
    output reg [31:0] csr_rdata,
    input             csr_we,
    input      [11:0] csr_waddr,
    input      [31:0] csr_wdata,

    input      [11:0] debug_csr_raddr,
    output reg [31:0] debug_csr_rdata,
    input             debug_csr_we,
    input      [11:0] debug_csr_waddr,
    input      [31:0] debug_csr_wdata,

    input             ex_valid,
    input      [31:0] ex_pc,
    input             ex_is_16bit,
    output            ex_trigger_hit,
    output     [ 1:0] ex_trigger_idx,

    input             mem_valid,
    input             mem_is_load,
    input             mem_is_store,
    input      [31:0] mem_addr,
    input      [ 2:0] mem_size,
    output            mem_trigger_hit,
    output     [ 1:0] mem_trigger_idx,
    output            mem_trigger_is_load,
    output            mem_trigger_is_store,

    input             fire_valid,
    input      [ 1:0] fire_idx
);
    localparam [31:0] TINFO_MCONTROL6 = 32'h0000_0040;
    localparam [31:0] TYPE_MCONTROL6  = 32'h6000_0000;

    reg [1:0]  tselect_r;
    reg [31:0] tdata1_r [0:3];
    reg [31:0] tdata2_r [0:3];
    reg [3:0]  suppress_r;

    integer i;

    function is_trigger_csr;
        input [11:0] addr;
        begin
            is_trigger_csr = (addr == `CSR_TSELECT) ||
                             (addr == `CSR_TDATA1)  ||
                             (addr == `CSR_TDATA2)  ||
                             (addr == `CSR_TINFO);
        end
    endfunction

    function [31:0] legal_tdata1;
        input [31:0] wdata;
        input [1:0]  idx;
        input        cur_hit0;
        reg          want_type6;
        reg          exec_slot;
        reg          data_slot;
        reg          en_action_debug;
        reg          en_m;
        reg          want_exec;
        reg          want_load;
        reg          want_store;
        begin
            want_type6      = (wdata[31:28] == 4'h6);
            exec_slot       = (idx < 2'd2);
            data_slot       = !exec_slot;
            en_action_debug = (wdata[15:12] == 4'h1);
            en_m            = wdata[6];
            want_exec       = exec_slot && wdata[2];
            want_load       = data_slot && wdata[0];
            want_store      = data_slot && wdata[1];

            if (!want_type6) begin
                legal_tdata1 = 32'h0;
            end else begin
                legal_tdata1 = TYPE_MCONTROL6;
                legal_tdata1[27]    = wdata[27];      // dmode
                legal_tdata1[22]    = wdata[22] | cur_hit0;
                legal_tdata1[18:16] = wdata[18:16];   // size
                legal_tdata1[15:12] = en_action_debug ? 4'h1 : 4'h0;
                legal_tdata1[10:7]  = 4'h0;           // exact only
                legal_tdata1[6]     = en_m;
                legal_tdata1[2]     = want_exec;
                legal_tdata1[1]     = want_store;
                legal_tdata1[0]     = want_load;
            end
        end
    endfunction

    function slot_enabled;
        input [1:0] idx;
        begin
            slot_enabled = (tdata1_r[idx][31:28] == 4'h6) &&
                           (tdata1_r[idx][15:12] == 4'h1) &&
                           (tdata1_r[idx][10:7] == 4'h0) &&
                           tdata1_r[idx][6];
        end
    endfunction

    function size_match;
        input [2:0] cfg_size;
        input [2:0] actual_size;
        begin
            size_match = (cfg_size == 3'd0) || (cfg_size == actual_size);
        end
    endfunction

    // M1A lint fix (Spyglass W122, same class as pmp.v): module state is passed as
    // explicit function inputs so every read is visible to @* sensitivity inference.
    wire [31:0] trig_tdata1_sel = tdata1_r[tselect_r];
    wire [31:0] trig_tdata2_sel = tdata2_r[tselect_r];

    function [31:0] read_csr;
        input [11:0] addr;
        input [ 1:0] tsel;
        input [31:0] td1_sel;
        input [31:0] td2_sel;
        begin
            case (addr)
                `CSR_TSELECT: read_csr = {30'h0, tsel};
                `CSR_TDATA1 : read_csr = td1_sel;
                `CSR_TDATA2 : read_csr = td2_sel;
                `CSR_TINFO  : read_csr = TINFO_MCONTROL6;
                default     : read_csr = 32'h0;
            endcase
        end
    endfunction

    wire [2:0] ex_size = ex_is_16bit ? 3'd2 : 3'd3;

    wire ex_hit0 = ex_valid && slot_enabled(2'd0) && tdata1_r[0][2] &&
                   !suppress_r[0] && size_match(tdata1_r[0][18:16], ex_size) &&
                   (ex_pc == tdata2_r[0]);
    wire ex_hit1 = ex_valid && slot_enabled(2'd1) && tdata1_r[1][2] &&
                   !suppress_r[1] && size_match(tdata1_r[1][18:16], ex_size) &&
                   (ex_pc == tdata2_r[1]);
    assign ex_trigger_hit = ex_hit0 | ex_hit1;
    assign ex_trigger_idx = ex_hit0 ? 2'd0 : 2'd1;

    wire mem_hit2_ld = mem_valid && mem_is_load && slot_enabled(2'd2) && tdata1_r[2][0] &&
                       !suppress_r[2] && size_match(tdata1_r[2][18:16], mem_size) &&
                       (mem_addr == tdata2_r[2]);
    wire mem_hit2_st = mem_valid && mem_is_store && slot_enabled(2'd2) && tdata1_r[2][1] &&
                       !suppress_r[2] && size_match(tdata1_r[2][18:16], mem_size) &&
                       (mem_addr == tdata2_r[2]);
    wire mem_hit3_ld = mem_valid && mem_is_load && slot_enabled(2'd3) && tdata1_r[3][0] &&
                       !suppress_r[3] && size_match(tdata1_r[3][18:16], mem_size) &&
                       (mem_addr == tdata2_r[3]);
    wire mem_hit3_st = mem_valid && mem_is_store && slot_enabled(2'd3) && tdata1_r[3][1] &&
                       !suppress_r[3] && size_match(tdata1_r[3][18:16], mem_size) &&
                       (mem_addr == tdata2_r[3]);

    assign mem_trigger_hit      = mem_hit2_ld | mem_hit2_st | mem_hit3_ld | mem_hit3_st;
    assign mem_trigger_idx      = (mem_hit2_ld | mem_hit2_st) ? 2'd2 : 2'd3;
    assign mem_trigger_is_load  = mem_hit2_ld | mem_hit3_ld;
    assign mem_trigger_is_store = mem_hit2_st | mem_hit3_st;

    always @* begin
        csr_rdata = read_csr(csr_raddr, tselect_r, trig_tdata1_sel, trig_tdata2_sel);
        if (csr_we && (csr_waddr == csr_raddr) && is_trigger_csr(csr_waddr)) begin
            if (csr_waddr == `CSR_TSELECT)
                csr_rdata = (csr_wdata[31:2] == 30'h0) ? {30'h0, csr_wdata[1:0]} : {30'h0, tselect_r};
            else if (csr_waddr == `CSR_TDATA1)
                csr_rdata = legal_tdata1(csr_wdata, tselect_r, 1'b0);
            else if (csr_waddr == `CSR_TDATA2)
                csr_rdata = csr_wdata;
        end
    end

    always @* begin
        debug_csr_rdata = read_csr(debug_csr_raddr, tselect_r, trig_tdata1_sel, trig_tdata2_sel);
        if (debug_csr_we && (debug_csr_waddr == debug_csr_raddr) && is_trigger_csr(debug_csr_waddr)) begin
            if (debug_csr_waddr == `CSR_TSELECT)
                debug_csr_rdata = (debug_csr_wdata[31:2] == 30'h0) ? {30'h0, debug_csr_wdata[1:0]} : {30'h0, tselect_r};
            else if (debug_csr_waddr == `CSR_TDATA1)
                debug_csr_rdata = legal_tdata1(debug_csr_wdata, tselect_r, 1'b0);
            else if (debug_csr_waddr == `CSR_TDATA2)
                debug_csr_rdata = debug_csr_wdata;
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            tselect_r  <= 2'd0;
            suppress_r <= 4'h0;
            for (i = 0; i < 4; i = i + 1) begin
                tdata1_r[i] <= 32'h0;
                tdata2_r[i] <= 32'h0;
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                if (!slot_enabled(i[1:0]))
                    suppress_r[i] <= 1'b0;
            end

            if (ex_valid) begin
                if (ex_pc != tdata2_r[0]) suppress_r[0] <= 1'b0;
                if (ex_pc != tdata2_r[1]) suppress_r[1] <= 1'b0;
            end
            if (mem_valid) begin
                if (mem_addr != tdata2_r[2]) suppress_r[2] <= 1'b0;
                if (mem_addr != tdata2_r[3]) suppress_r[3] <= 1'b0;
            end

            if (csr_we && is_trigger_csr(csr_waddr)) begin
                case (csr_waddr)
                    `CSR_TSELECT: if (csr_wdata[31:2] == 30'h0) tselect_r <= csr_wdata[1:0];
                    `CSR_TDATA1: begin
                        tdata1_r[tselect_r] <= legal_tdata1(csr_wdata, tselect_r, 1'b0);
                        if (csr_wdata[31:28] != 4'h6)
                            suppress_r[tselect_r] <= 1'b0;
                    end
                    `CSR_TDATA2: begin
                        tdata2_r[tselect_r] <= csr_wdata;
                        suppress_r[tselect_r] <= 1'b0;
                    end
                    default: ;
                endcase
            end

            if (debug_csr_we && is_trigger_csr(debug_csr_waddr)) begin
                case (debug_csr_waddr)
                    `CSR_TSELECT: if (debug_csr_wdata[31:2] == 30'h0) tselect_r <= debug_csr_wdata[1:0];
                    `CSR_TDATA1: begin
                        tdata1_r[tselect_r] <= legal_tdata1(debug_csr_wdata, tselect_r, 1'b0);
                        if (debug_csr_wdata[31:28] != 4'h6)
                            suppress_r[tselect_r] <= 1'b0;
                    end
                    `CSR_TDATA2: begin
                        tdata2_r[tselect_r] <= debug_csr_wdata;
                        suppress_r[tselect_r] <= 1'b0;
                    end
                    default: ;
                endcase
            end

            if (fire_valid) begin
                suppress_r[fire_idx] <= 1'b1;
                tdata1_r[fire_idx][22] <= 1'b1;
            end
        end
    end
endmodule
