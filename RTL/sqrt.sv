`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 04:49:45 PM
// Design Name: 
// Module Name: sqrt
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


module sqrt(
    input logic signed [15:0] x_in,
    output logic signed [15:0] sqrt_out
    );
    
    // Clamp input to [0.0, 16.0] → [0, 16384] in Q6.10
    logic signed [15:0] x_clamped;
    always_comb begin
        if (x_in < 16'sd0)
            x_clamped = 16'sd0;
        else if (x_in > 16'sd16384)
            x_clamped = 16'sd16384;
        else
            x_clamped = x_in;
    end

    // Compute ROM address: 0.03125 step size = 32 units in Q6.10
    logic [15:0] index;
    logic [9:0] addr;

    always_comb begin
        index = x_clamped;
        addr  = index / 32;
    end

    // ROM lookup
    sqrt_rom rom_inst (
        .addr(addr),
        .out(sqrt_out)
    );
    
endmodule
