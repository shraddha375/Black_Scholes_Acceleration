`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 04:49:45 PM
// Design Name: 
// Module Name: sqrt_rom
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


module sqrt_rom(
    input logic [9:0] addr,
    output logic signed [15:0] out
    );
    
    logic signed [15:0] rom [0:512];

    initial begin
        $readmemh("sqrt_table.mem", rom);
    end

    assign out = rom[addr];
    
endmodule
