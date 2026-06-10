`timescale 1ns/1ps
`include "def.vh"

module tb_lsu_unit;
    reg  [ 1:0] addr_lo;
    reg  [31:0] wdata_raw;
    reg  [ 2:0] funct3;
    reg         is_store;
    reg  [31:0] mem_rdata;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    wire [31:0] ld_result;

    integer vectors;
    integer errors;
    integer fidx;
    integer aidx;
    integer pidx;
    integer i;

    reg [2:0] load_funct3 [0:4];
    reg [2:0] store_funct3 [0:2];
    reg [31:0] load_patterns [0:9];
    reg [31:0] store_patterns [0:7];

    lsu dut (
        .addr_lo(addr_lo),
        .wdata_raw(wdata_raw),
        .funct3(funct3),
        .is_store(is_store),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .ld_result(ld_result)
    );

    function [7:0] golden_byte_sel;
        input [31:0] f_mem_rdata;
        input [ 1:0] f_addr_lo;
        begin
            case (f_addr_lo)
                2'b00: golden_byte_sel = f_mem_rdata[ 7: 0];
                2'b01: golden_byte_sel = f_mem_rdata[15: 8];
                2'b10: golden_byte_sel = f_mem_rdata[23:16];
                default: golden_byte_sel = f_mem_rdata[31:24];
            endcase
        end
    endfunction

    function [15:0] golden_half_sel;
        input [31:0] f_mem_rdata;
        input [ 1:0] f_addr_lo;
        begin
            case (f_addr_lo)
                2'b00: golden_half_sel = f_mem_rdata[15:0];
                2'b01: golden_half_sel = f_mem_rdata[15:0];
                2'b10: golden_half_sel = f_mem_rdata[31:16];
                default: golden_half_sel = f_mem_rdata[31:16];
            endcase
        end
    endfunction

    function [31:0] golden_ld_result;
        input [2:0]  f_funct3;
        input [1:0]  f_addr_lo;
        input [31:0] f_mem_rdata;
        reg   [7:0]  f_byte;
        reg   [15:0] f_half;
        begin
            f_byte = golden_byte_sel(f_mem_rdata, f_addr_lo);
            f_half = golden_half_sel(f_mem_rdata, f_addr_lo);
            case (f_funct3)
                `F3_LB : golden_ld_result = {{24{f_byte[7]}}, f_byte};
                `F3_LH : golden_ld_result = {{16{f_half[15]}}, f_half};
                `F3_LW : golden_ld_result = f_mem_rdata;
                `F3_LBU: golden_ld_result = {24'h000000, f_byte};
                `F3_LHU: golden_ld_result = {16'h0000, f_half};
                default: golden_ld_result = f_mem_rdata;
            endcase
        end
    endfunction

    function [31:0] golden_mem_wdata;
        input [2:0]  f_funct3;
        input [31:0] f_wdata_raw;
        begin
            case (f_funct3)
                `F3_SB : golden_mem_wdata = {4{f_wdata_raw[7:0]}};
                `F3_SH : golden_mem_wdata = {2{f_wdata_raw[15:0]}};
                `F3_SW : golden_mem_wdata = f_wdata_raw;
                default: golden_mem_wdata = f_wdata_raw;
            endcase
        end
    endfunction

    function [3:0] golden_raw_wstrb;
        input [2:0] f_funct3;
        input [1:0] f_addr_lo;
        begin
            case (f_funct3)
                `F3_SB : golden_raw_wstrb = 4'b0001 << f_addr_lo;
                `F3_SH : golden_raw_wstrb = 4'b0011 << {f_addr_lo[1], 1'b0};
                `F3_SW : golden_raw_wstrb = 4'b1111;
                default: golden_raw_wstrb = 4'b0000;
            endcase
        end
    endfunction

    function [8*24-1:0] load_name;
        input [2:0] f_funct3;
        begin
            case (f_funct3)
                `F3_LB : load_name = "LB";
                `F3_LH : load_name = "LH";
                `F3_LW : load_name = "LW";
                `F3_LBU: load_name = "LBU";
                `F3_LHU: load_name = "LHU";
                default: load_name = "ILL";
            endcase
        end
    endfunction

    function [8*24-1:0] store_name;
        input [2:0] f_funct3;
        begin
            case (f_funct3)
                `F3_SB : store_name = "SB";
                `F3_SH : store_name = "SH";
                `F3_SW : store_name = "SW";
                default: store_name = "ILL";
            endcase
        end
    endfunction

    task check_vector;
        input [2:0]  t_funct3;
        input [1:0]  t_addr_lo;
        input        t_is_store;
        input [31:0] t_wdata_raw;
        input [31:0] t_mem_rdata;
        input [8*24-1:0] tag;
        reg [31:0] exp_ld_result;
        reg [31:0] exp_mem_wdata;
        reg [ 3:0] exp_mem_wstrb;
        begin
            funct3    = t_funct3;
            addr_lo   = t_addr_lo;
            is_store  = t_is_store;
            wdata_raw = t_wdata_raw;
            mem_rdata = t_mem_rdata;
            #1;

            exp_ld_result = golden_ld_result(t_funct3, t_addr_lo, t_mem_rdata);
            exp_mem_wdata = golden_mem_wdata(t_funct3, t_wdata_raw);
            exp_mem_wstrb = t_is_store ? golden_raw_wstrb(t_funct3, t_addr_lo) : 4'b0000;

            vectors = vectors + 1;
            if (ld_result !== exp_ld_result ||
                mem_wdata !== exp_mem_wdata ||
                mem_wstrb !== exp_mem_wstrb) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s f3=%b addr_lo=%b store=%b wdata=%h rdata=%h ld=%h exp_ld=%h mwdata=%h exp_mwdata=%h wstrb=%b exp_wstrb=%b",
                       vectors, tag, t_funct3, t_addr_lo, t_is_store,
                       t_wdata_raw, t_mem_rdata,
                       ld_result, exp_ld_result,
                       mem_wdata, exp_mem_wdata,
                       mem_wstrb, exp_mem_wstrb);
            end
        end
    endtask

    initial begin
        load_funct3[0] = `F3_LB;
        load_funct3[1] = `F3_LH;
        load_funct3[2] = `F3_LW;
        load_funct3[3] = `F3_LBU;
        load_funct3[4] = `F3_LHU;

        store_funct3[0] = `F3_SB;
        store_funct3[1] = `F3_SH;
        store_funct3[2] = `F3_SW;

        load_patterns[0] = 32'h0000_0000;
        load_patterns[1] = 32'hffff_ffff;
        load_patterns[2] = 32'h0102_7f80;
        load_patterns[3] = 32'h8000_7fff;
        load_patterns[4] = 32'h7fff_8000;
        load_patterns[5] = 32'h807f_0080;
        load_patterns[6] = 32'h0080_8000;
        load_patterns[7] = 32'ha5a5_5a5a;
        load_patterns[8] = 32'h3cc3_c33c;
        load_patterns[9] = 32'h9696_6969;

        store_patterns[0] = 32'h0000_0000;
        store_patterns[1] = 32'hffff_ffff;
        store_patterns[2] = 32'h0000_0080;
        store_patterns[3] = 32'h0000_8000;
        store_patterns[4] = 32'h1234_5678;
        store_patterns[5] = 32'h8765_4321;
        store_patterns[6] = 32'ha5a5_5a5a;
        store_patterns[7] = 32'h3cc3_c33c;

        vectors   = 0;
        errors    = 0;
        addr_lo   = 2'b00;
        wdata_raw = 32'h0000_0000;
        funct3    = `F3_LB;
        is_store  = 1'b0;
        mem_rdata = 32'h0000_0000;
        #1;

        for (fidx = 0; fidx < 5; fidx = fidx + 1) begin
            for (aidx = 0; aidx < 4; aidx = aidx + 1) begin
                for (pidx = 0; pidx < 10; pidx = pidx + 1) begin
                    check_vector(load_funct3[fidx], aidx[1:0], 1'b0,
                                 32'hcafe_babe ^ load_patterns[pidx],
                                 load_patterns[pidx],
                                 load_name(load_funct3[fidx]));
                end
            end
        end

        for (fidx = 0; fidx < 3; fidx = fidx + 1) begin
            for (aidx = 0; aidx < 4; aidx = aidx + 1) begin
                for (pidx = 0; pidx < 8; pidx = pidx + 1) begin
                    check_vector(store_funct3[fidx], aidx[1:0], 1'b1,
                                 store_patterns[pidx],
                                 32'h1357_9bdf ^ store_patterns[pidx],
                                 store_name(store_funct3[fidx]));
                end
            end
        end

        check_vector(3'b011, 2'b00, 1'b0, 32'h0123_4567, 32'h89ab_cdef, "ILL_LOAD_011");
        check_vector(3'b110, 2'b01, 1'b0, 32'h89ab_cdef, 32'h0123_4567, "ILL_LOAD_110");
        check_vector(3'b111, 2'b10, 1'b0, 32'hffff_0000, 32'h0000_ffff, "ILL_LOAD_111");
        check_vector(3'b011, 2'b11, 1'b1, 32'h55aa_00ff, 32'hf0f0_0f0f, "ILL_STORE_011");
        check_vector(3'b110, 2'b10, 1'b1, 32'haa55_ff00, 32'h0f0f_f0f0, "ILL_STORE_110");
        check_vector(3'b111, 2'b01, 1'b1, 32'h1357_2468, 32'hdead_beef, "ILL_STORE_111");
        check_vector(`F3_LW, 2'bxx, 1'b0, 32'h2468_1357, 32'h5a5a_a5a5, "X_ADDR_LW");

        for (i = 0; i < 32; i = i + 1) begin
            check_vector(`F3_LB, i[1:0], 1'b0, ~(32'h0000_0001 << i),
                         (32'h0000_0001 << i), "WALK_LB");
            check_vector(`F3_LHU, i[1:0], 1'b0, (32'h8000_0000 >> i),
                         ~(32'h8000_0000 >> i), "WALK_LHU");
            check_vector(`F3_SB, i[1:0], 1'b1, (32'h0000_0001 << i),
                         ~(32'h0000_0001 << i), "WALK_SB");
            check_vector(`F3_SH, i[1:0], 1'b1, ~(32'h0000_0001 << i),
                         (32'h8000_0000 >> i), "WALK_SH");
        end

        if (errors == 0) begin
            $display("PASS: lsu unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: lsu unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
