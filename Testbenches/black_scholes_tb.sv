`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 06:05:07 PM
// Design Name: 
// Module Name: black_scholes_tb
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


module black_scholes_tb();
    
    logic clk;
    logic rst;
    logic start;
    logic signed [15:0] S, K, r, sigma, T;
    logic done;
    logic signed [15:0] call_price;

    // Clock generation
    initial clk = 0;
    always #1 clk = ~clk;  // 500 MHz clock

    // Instantiate DUT
    black_scholes dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .S(S),
        .K(K),
        .r(r),
        .sigma(sigma),
        .T(T),
        .done(done),
        .call_price(call_price)
    );

    // Q6.10 fixed-point helpers
function automatic logic signed [15:0] to_q610(real x);
    return $rtoi(x * 1024.0);
endfunction

function automatic real from_q610(logic signed [15:0] x);
    return x / 1024.0;
endfunction

real test_vals[4][5];
localparam int NUM_TESTS = 4;

initial begin
    $display("=== Black-Scholes Accelerator Testbench ===");

    // Reset and idle
    rst = 1; start = 0;
    #4;
    rst = 0;

    // Test case list
    test_vals = '{
        '{25.0, 25.0, 0.05, 0.20, 1.0},
        '{30.0, 25.0, 0.03, 0.25, 1.0},
        '{25.0, 30.0, 0.05, 0.20, 1.0},
        '{20.0, 20.0, 0.01, 0.10, 2.0}
    };

    for (int i = 0; i < NUM_TESTS; i++) begin
        // Apply test inputs
        S     = to_q610(test_vals[i][0]);
        K     = to_q610(test_vals[i][1]);
        r     = to_q610(test_vals[i][2]);
        sigma = to_q610(test_vals[i][3]);
        T     = to_q610(test_vals[i][4]);

        // Start computation
        start = 1;
        #2;
        start = 0;

        // Wait for computation to complete
        wait(done == 1);
        #10;

        // Display result
        $display("\n--- Test Case %0d ---", i+1);
        $display("S      = %0f", from_q610(S));
        $display("K      = %0f", from_q610(K));
        $display("r      = %0f", from_q610(r));
        $display("sigma  = %0f", from_q610(sigma));
        $display("T      = %0f", from_q610(T));
        $display("Call   = %0f (Q6.10: 0x%04h)", from_q610(call_price), call_price);

        // Clear done for next run
        @(posedge clk); done <= 0;
        #10;
    end

    $display("\nAll test cases complete.");
    $finish;
    
    end

endmodule
