
module sqrt_tb (
    );
    
    // DUT signals
    logic signed [15:0] x_in;   // Q6.10 input
    logic signed [15:0] out;    // Q6.10 output

    // Instantiate the DUT
    sqrt dut (
        .x_in(x_in),
        .sqrt_out(out)
    );

    // Convert real → Q6.10
    function logic signed [15:0] real_to_q610(input real val);
        return $rtoi(val * 1024.0);
    endfunction

    // Convert Q6.10 → real
    function real q610_to_real(input logic signed [15:0] val);
        return val / 1024.0;
    endfunction

    // Testbench logic
    initial begin
        real test_val;
        $display(" x_in (real) | sqrt(x) (expected) | sqrt_out (hex) | sqrt_out (real)");
        $display("---------------------------------------------------------------");

        test_val = 0.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 0.25; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 1.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 2.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 5.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 10.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 16.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        test_val = 20.0; x_in = real_to_q610(test_val); #10;  // test clamping
        $display("%11.5f | %18.5f |     0x%04h     | %14.5f", test_val, $sqrt(test_val), out, q610_to_real(out));

        $finish;
    end
    
endmodule