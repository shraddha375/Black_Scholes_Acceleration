`timescale 1ns / 1ps

module exp_rom(
    input  logic [9:0]  addr,
    output logic [15:0] out
    );
    
     // ROM table
    logic signed [15:0] rom [0:512];

    initial begin
        $readmemh("exp_neg_table.mem", rom);
    end

    assign out = rom[addr];
    
endmodule
