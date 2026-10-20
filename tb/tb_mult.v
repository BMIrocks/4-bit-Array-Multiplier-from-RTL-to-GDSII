`timescale 1ns/1ps

module tb_mult;
    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;
    wire [7:0] p;
    integer    a_value;
    integer    b_value;
    integer    errors;
    reg  [7:0] expected;

    mult_array dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .p(p)
    );

    always #5 clk = ~clk;

    initial begin
        clk    = 1'b0;
        rst_n  = 1'b0;
        a      = 4'b0;
        b      = 4'b0;
        errors = 0;

        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        for (a_value = 0; a_value < 16; a_value = a_value + 1) begin
            for (b_value = 0; b_value < 16; b_value = b_value + 1) begin
                @(negedge clk);
                a = a_value[3:0];
                b = b_value[3:0];
                expected = a_value * b_value;

                @(posedge clk);
                @(posedge clk);
                // check 4 ns after the edge: the netlist flip-flops have a 1 ns delay,
                // and the inputs only change at the next falling edge (5 ns after)
                #4;
                if (p !== expected) begin
                    $display("MISMATCH: a=%0d b=%0d expected=%0d got=%0d", a_value, b_value, expected, p);
                    errors = errors + 1;
                end
            end
        end

        if (errors == 0)
            $display("PASS: 256 vectors checked, 0 errors");
        else
            $display("FAIL: 256 vectors checked, %0d errors", errors);
        $finish;
    end
endmodule
