`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 12:21:47 PM
// Design Name: 
// Module Name: norm_cdf
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


module norm_cdf(
    input logic signed [15:0] x_in,
    output logic signed [15:0] n_out
    );
    
    // Clamped input within [-5.0, 5.0] (Q4.12)
    logic signed [15:0] x_clamped;
    always_comb begin
        if (x_in < -16'sd20480)
            x_clamped = (-5 <<< 12);
        else if (x_in > (5 <<< 12))
            x_clamped = (5 <<< 12);
        else
            x_clamped = x_in;
    end
    
    // Offset to shift [-5.0, 5.0] → [0, 10.0]
    logic signed [16:0] x_offset;
    always_comb begin
        x_offset = x_clamped + (5 <<< 12); // 5.0 * 4096
    end

    // Compute ROM address and fractional offset
    logic [9:0] addr;
    logic [5:0] frac;
    always_comb begin
        addr = x_offset / 80;
        frac = x_offset % 80;
    end

    // ROM output
    logic [15:0] val1, val2;
    norm_rom lut (
        .addr(addr),
        .val1(val1),
        .val2(val2)
    ); 
    
    // Linear interpolation: val1 + ((val2 - val1) * frac) >> 6
    logic signed [15:0] delta;
    logic signed [21:0] interp_mult;
    logic signed [15:0] interp;

    always_comb begin
        delta        = val2 - val1;
        interp_mult  = delta * frac;          // Q4.12 * Q0.6 = Q4.18
        interp       = interp_mult[17:6];     // Shift back to Q4.12
        n_out        = val1 + interp;         // Final interpolated output
    end

endmodule
