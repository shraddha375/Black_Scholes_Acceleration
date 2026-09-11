`timescale 1ns / 1ps

module sqrt_rom(
    input  logic        [9:0] addr,
    output logic signed [15:0] out
    );
    
    logic signed [15:0] rom [0:512];

    initial begin
        $readmemh("sqrt_table.mem", rom);
    end

    assign out = rom[addr];
    
endmodule
