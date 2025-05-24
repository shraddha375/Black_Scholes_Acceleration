`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 12:21:47 PM
// Design Name: 
// Module Name: norm_rom
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


module norm_rom(
    input [9:0] addr,
    output [15:0] val1,
    output [15:0] val2
    );
  
	logic [15:0] rom [0:512]; // 513 entries, 16 bit each
	
	initial begin
        $readmemh("norm_table.mem", rom);
	end

	assign val1 = rom[addr];
    assign val2 = (addr < 512) ? rom[addr + 1] : rom[addr];
    
endmodule

