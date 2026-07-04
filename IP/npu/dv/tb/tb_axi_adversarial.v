// =============================================================================
// tb_axi_adversarial.v — Phase 1.5 hardening proof: adversarial AXI stimulus that
// the happy-path BFMs never generate. Each check targets a Codex-found bug and
// asserts the FIX. Drives npu_top's AXI4-Lite slave. Prints ADVERSARIAL_PASS.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_axi_adversarial;
    reg clk=0, resetn=0; always #5 clk=~clk;
    reg  s_awvalid=0,s_wvalid=0,s_bready=0,s_arvalid=0,s_rready=0;
    reg  [31:0] s_awaddr=0,s_wdata=0,s_araddr=0; reg [3:0] s_wstrb=4'hf;
    wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid; wire [31:0] s_rdata; wire [1:0] s_bresp,s_rresp;
    wire d_arvalid,d_arready,d_rvalid,d_rready,d_rlast; wire [31:0] d_araddr,d_rdata;
    wire [7:0] d_arlen; wire [2:0] d_arsize; wire [1:0] d_arburst,d_rresp;
    wire irq, npu_start; wire [31:0] npu_config;

    npu_top #(.TCM_WORDS(8192), .TCM_AW(13)) dut (
        .clk(clk),.resetn(resetn),
        .s_awvalid(s_awvalid),.s_awready(s_awready),.s_awaddr(s_awaddr),.s_awprot(3'b0),
        .s_wvalid(s_wvalid),.s_wready(s_wready),.s_wdata(s_wdata),.s_wstrb(s_wstrb),
        .s_bvalid(s_bvalid),.s_bready(s_bready),.s_bresp(s_bresp),
        .s_arvalid(s_arvalid),.s_arready(s_arready),.s_araddr(s_araddr),.s_arprot(3'b0),
        .s_rvalid(s_rvalid),.s_rready(s_rready),.s_rdata(s_rdata),.s_rresp(s_rresp),
        .m_arvalid(d_arvalid),.m_arready(d_arready),.m_araddr(d_araddr),.m_arlen(d_arlen),
        .m_arsize(d_arsize),.m_arburst(d_arburst),
        .m_rvalid(d_rvalid),.m_rready(d_rready),.m_rdata(d_rdata),.m_rlast(d_rlast),.m_rresp(d_rresp),
        .irq(irq),.npu_start(npu_start),.npu_config(npu_config)
    );
    axi_full_mem #(.WORDS(4096)) wmem (
        .clk(clk),.resetn(resetn),
        .arvalid(d_arvalid),.arready(d_arready),.araddr(d_araddr),.arlen(d_arlen),.arsize(d_arsize),.arburst(d_arburst),
        .rvalid(d_rvalid),.rready(d_rready),.rdata(d_rdata),.rlast(d_rlast),.rresp(d_rresp)
    );

    integer errors=0, checks=0, i; reg [31:0] rd; reg [1:0] resp;

    // full read returning BRESP/RRESP too
    task axil_read_resp(input [31:0] a, output [31:0] d, output [1:0] rp); begin
        @(negedge clk); s_arvalid=1; s_araddr=a; s_rready=1;
        @(posedge clk); while(!(s_arvalid&&s_arready)) @(posedge clk); @(negedge clk); s_arvalid=0;
        @(posedge clk); while(!(s_rvalid&&s_rready)) @(posedge clk); d=s_rdata; rp=s_rresp; @(negedge clk); s_rready=0;
    end endtask
    task axil_write(input [31:0] a, input [31:0] d, input [3:0] strb); reg awd,wdn; begin
        @(negedge clk); s_awvalid=1;s_awaddr=a;s_wvalid=1;s_wdata=d;s_wstrb=strb;s_bready=0;awd=0;wdn=0;
        while(!(awd&&wdn)) begin @(posedge clk); if(s_awvalid&&s_awready)awd=1; if(s_wvalid&&s_wready)wdn=1;
            @(negedge clk); if(awd)s_awvalid=0; if(wdn)s_wvalid=0; end
        s_bready=1; @(posedge clk); while(!s_bvalid)@(posedge clk); @(negedge clk); s_bready=0;
    end endtask
    task ck(input cond, input [255:0] nm); begin checks=checks+1;
        if(!cond) begin errors=errors+1; $display("  FAIL %0s",nm); end else $display("  ok   %0s",nm); end endtask

    initial begin
        repeat(4)@(posedge clk); resetn=1; @(posedge clk);

        // (1) W-before-AW to a TCM address must NOT deadlock (Codex #1/#2)
        @(negedge clk); s_wvalid=1; s_wdata=32'hFACE_1234; s_wstrb=4'hf; s_bready=1;
        repeat(3) @(posedge clk);                       // hold W with no AW: must stall, not commit
        @(negedge clk); s_awvalid=1; s_awaddr=32'h3001_0000;
        i=0; while(!(s_awvalid&&s_awready) && i<20) begin @(posedge clk); i=i+1; end
        @(negedge clk); s_awvalid=0;
        i=0; while(!s_bvalid && i<20) begin @(posedge clk); i=i+1; end
        ck(s_bvalid===1'b1, "W_before_AW completes (no deadlock)");
        @(negedge clk); s_bready=0; s_wvalid=0;

        // (2) WSTRB byte write must merge, not clobber (Codex #3)
        axil_write(32'h3000_0010, 32'hDEAD_BEEF, 4'hf);          // SCRATCH = DEADBEEF
        axil_write(32'h3000_0010, 32'h0000_00AA, 4'h1);          // byte0 only
        axil_read_resp(32'h3000_0010, rd, resp);
        ck(rd===32'hDEAD_BEAA, "WSTRB byte-merge (DEADBEAA)");

        // (3) out-of-window NPU addr -> SLVERR, not CSR-ID alias (Codex #5)
        axil_read_resp(32'h3003_0000, rd, resp);   // ADR-0044: 0x3002 = ITCM now
        ck(resp===2'b10 && rd!==32'h4E505530, "decode alias -> SLVERR");

        // (4) TCM out-of-range offset -> SLVERR, no wrap (Codex #6)
        axil_read_resp(32'h3001_8000, rd, resp);                 // word 8192 > 1024
        ck(resp===2'b10, "TCM out-of-range -> SLVERR");

        // (5) DMA LEN=0 -> done, no rogue burst (Codex #7)
        axil_write(32'h3000_0020, 32'h0,  4'hf);                 // SRC
        axil_write(32'h3000_0024, 32'h0,  4'hf);                 // DST
        axil_write(32'h3000_0028, 32'h0,  4'hf);                 // LEN=0
        axil_write(32'h3000_002C, 32'h1,  4'hf);                 // GO
        rd=0; for(i=0;i<50 && rd[3]===1'b0;i=i+1) axil_read_resp(32'h3000_0008,rd,resp);
        ck(rd[3]===1'b1 && d_arvalid===1'b0, "DMA LEN=0 done, no AR");

        $display("ADVERSARIAL: %0d checks, %0d errors", checks, errors);
        if(errors==0) $display("ADVERSARIAL_PASS"); else $display("ADVERSARIAL_FAIL");
        $finish;
    end
    initial begin #200000; $display("ADVERSARIAL_FAIL: timeout"); $finish; end
endmodule
`default_nettype wire
