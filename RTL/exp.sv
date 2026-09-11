`timescale 1ns / 1ps

module exp(
    input  logic signed [15:0] x_in,
    output logic signed [15:0] exp_out
    );
    
     // Clamp input
    logic signed [15:0] x_clamped;
    always_comb begin
        if (x_in < -16'sd10240)
            x_clamped = -16'sd10240;
        else if (x_in > 16'sd0)
            x_clamped = 16'sd0;
        else
            x_clamped = x_in;
    end

    // Compute ROM address
    logic [15:0] offset;
    logic [9:0]  addr;

    always_comb begin
        offset = x_clamped + 16'd10240;  // shift range to [0, 10240]
        addr   = offset / 20;            // step size = 20 (0.0195)
    end
    
    logic signed [15:0] out;
    
    // ROM lookup
    exp_rom rom_inst (
        .addr(addr),
        .out(out)
    );
    
    assign exp_out = out;
    
endmodule
