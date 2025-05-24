`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 04:11:38 PM
// Design Name: 
// Module Name: ln_tb
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


module ln_tb(

    );
   
    localparam int PERIOD = 2;

    // Clock Generation
    logic clk;
    initial clk = 0;
    always #(PERIOD / 2) clk = ~clk;
    
    // Inputs and outputs
    logic signed [15:0] x_in;     // Q6.10 input
    logic signed [15:0] ln_out;   // Q6.10 output

    // Instantiate the DUT
    ln dut (
       .x_in(x_in),
       .ln_out(ln_out)
    );

    // Convert Q6.10 to real for printing
    function real q610_to_real(input logic signed [15:0] val);
        return val / 1024.0;
    endfunction

    // Convert real to Q6.10
    function logic signed [15:0] real_to_q610(input real r);
        return $rtoi(r * 1024.0);
    endfunction

    // Apply test vectors
    initial begin
        // Define test values inline (Vivado doesn't always like real arrays)
        real test_val;
        $display("x_in (real) | ln(x_in) (real) | ln_out (hex) | ln_out (real)");
        $display("-------------------------------------------------------------");

        test_val = 0.01;  x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 0.1;   x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 0.5;   x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 1.0;   x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 2.718; x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 5.0;   x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 10.0;  x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        test_val = 12.0;  x_in = real_to_q610(test_val); #10;
        $display("%10.5f | %14.5f |   0x%04h   | %13.5f",
                 test_val, $ln(test_val), ln_out, q610_to_real(ln_out));

        $finish;
    end
    
endmodule
