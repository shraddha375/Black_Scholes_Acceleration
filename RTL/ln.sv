`timescale 1ns / 1ps

module ln(
    input  logic signed [15:0] x_in,
    output logic signed [15:0] ln_out
    );
    
    // Clamp input to avoid ln(0) or ln(x < 0)
    logic signed [15:0] x_clamped;
    always_comb begin
        if (x_in < 16'sd10) // clamp at ~0.01 (0.01 * 1024 = ~10)
            x_clamped = 16'sd10;
        else if (x_in > 16'sd10240) // max x = 10.0 (10.0 * 1024)
            x_clamped = 16'sd10240;
        else
            x_clamped = x_in;
    end

    // Compute index and fractional offset
    logic [15:0] index;
    logic [9:0]  addr;
    
    always_comb begin
        index = x_clamped - 16'd10;    // Shift base to start at 0.01
        addr  = index / 20;            // 513 entries over [0.01,10] → step ≈ 0.0195 → 20 in Q6.10
    end

    // ROM values for interpolation
    logic signed [15:0] out;
    ln_rom rom_inst (
        .addr(addr),
        .out(out)
    );

    assign ln_out = out;
    
endmodule
