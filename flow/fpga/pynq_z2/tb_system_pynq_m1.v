`timescale 1 ns / 1 ps
`default_nettype none

module tb_system_pynq_m1;
    reg clk;
    reg btn0;
    wire [3:0] led;

    system_pynq_m1 dut (
        .clk(clk),
        .btn0(btn0),
        .led(led)
    );

    always #4 clk = ~clk;

    integer cycles;
    integer transitions;
    reg [3:0] last_led;

    initial begin
        clk = 1'b0;
        btn0 = 1'b1;
        cycles = 0;
        transitions = 0;
        last_led = 4'h0;
        $display("TB: hold BTN0 reset");
        repeat (8) @(posedge clk);
        btn0 = 1'b0;
        last_led = led;
        $display("TB: release BTN0 reset");
    end

    always @(posedge clk) begin
        cycles <= cycles + 1;

        if (!btn0 && (led !== last_led)) begin
            transitions <= transitions + 1;
            $display("LED transition %0d at cycle %0d: %b -> %b",
                     transitions + 1, cycles, last_led, led);
            last_led <= led;
        end

        if (transitions >= 8) begin
            $display("PASS: observed %0d LED transitions by cycle %0d", transitions, cycles);
            $finish;
        end

        if (cycles > 2000000) begin
            $display("FAIL: timeout after %0d cycles, transitions=%0d led=%b",
                     cycles, transitions, led);
            $fatal;
        end
    end
endmodule

`default_nettype wire
