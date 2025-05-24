`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 12:27:38 PM
// Design Name: 
// Module Name: norm_cdf_tb
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


module norm_cdf_tb(

    );
    
    localparam int PERIOD = 2;

    // Clock Generation
    logic clk;
    initial clk = 0;
    always #(PERIOD / 2) clk = ~clk;
    
    logic signed [15:0] x_in;    // Q4.12 input
    logic        [15:0] n_out;   // Q4.12 output

    // Instantiate the DUT
    norm_cdf dut (
        .x_in(x_in),
        .n_out(n_out)
    );

    // Convert Q4.12 to real for debug printing
    function real q4_12_to_real(input logic signed [15:0] val);
        return val / 4096.0;
    endfunction

    initial begin
        $display("     x_in (dec) |   x_in (hex) |   n_out (hex) |   n_out (dec)");
        $display("-------------------------------------------------------------");

        foreach (x_in_val[i]) begin
            x_in = x_in_val[i];
            #1; // Wait for combinational logic to settle
            $display("%13.6f |    0x%04h    |    0x%04h     |  %1.6f",
                q4_12_to_real(x_in), x_in, n_out, q4_12_to_real(n_out));
        end

        $finish;
    end

    // Predefined test cases in Q4.12
    logic signed [15:0] x_in_val[0:9];
    initial begin
        x_in_val[0] = -5 <<< 12;        // -5.0 (edge)
        x_in_val[1] = -2.75 * 4096;     // -2.75 → should interpolate
        x_in_val[2] = -2.5  * 4096;     // -2.5
        x_in_val[3] = -1.23 * 4096;     // mid-bin test
        x_in_val[4] =  0.0;             // center
        x_in_val[5] =  1.73 * 4096;     // mid-bin positive
        x_in_val[6] =  2.5  * 4096;     // 2.5
        x_in_val[7] =  2.75 * 4096;     // 2.75 → should interpolate
        x_in_val[8] =  5.0  * 4096;     // 5.0 (edge)
        x_in_val[9] =  6.0  * 4096;     // Out-of-bounds, clamped
    end

endmodule
