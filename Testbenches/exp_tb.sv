`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 05:02:44 PM
// Design Name: 
// Module Name: exp_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module exp_tb(

    );
    
    // DUT interface
    logic signed [15:0] x_in;   // Q6.10 input
    logic signed [15:0] out;    // Q6.10 output

    // Instantiate DUT
    exp dut (
        .x_in(x_in),
        .exp_out(out)
    );

    // Convert real to Q6.10
    function logic signed [15:0] real_to_q610(input real r);
        return $rtoi(r * 1024.0);
    endfunction

    // Convert Q6.10 to real
    function real q610_to_real(input logic signed [15:0] val);
        return val / 1024.0;
    endfunction

    // Stimulus
    initial begin
        real test_val;
        $display("x_in (real) | exp(x_in) (real) | exp_out (hex) | exp_out (real)");
        $display("---------------------------------------------------------------");
        $display("---------------------------------------------------------------");

        test_val = -10.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %17.5f |     0x%04h    | %14.5f", test_val, $exp(test_val), out, q610_to_real(out));

        test_val = -5.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %17.5f |     0x%04h    | %14.5f", test_val, $exp(test_val), out, q610_to_real(out));

        test_val = -2.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %17.5f |     0x%04h    | %14.5f", test_val, $exp(test_val), out, q610_to_real(out));

        test_val = -1.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %17.5f |     0x%04h    | %14.5f", test_val, $exp(test_val), out, q610_to_real(out));

        test_val = -0.5; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %17.5f |     0x%04h    | %14.5f", test_val, $exp(test_val), out, q610_to_real(out));

        test_val = 0.0; x_in = real_to_q610(test_val); #10;
        $display("%11.5f | %17.5f |     0x%04h    | %14.5f", test_val, $exp(test_val), out, q610_to_real(out));

        $finish;
    end
    
endmodule
