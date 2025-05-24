`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 02:29:00 PM
// Design Name: 
// Module Name: ln_rom
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


module ln_rom(
    input logic [9:0] addr,
    output logic [15:0] out
    );
    
    // 513 entries to allow safe access to addr + 1 during interpolation
    logic signed [15:0] rom [0:512];

    // Initialize ROM from memory file (Q6.10 format)
    initial begin
        $readmemh("ln_table.mem", rom);
    end

    // Output the value at current address
    assign out = rom[addr];
    
endmodule
