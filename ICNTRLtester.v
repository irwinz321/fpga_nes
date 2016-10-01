`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:17:03 07/02/2016
// Design Name:   InstructionController
// Module Name:   C:/Users/Zachary/Documents/Xilinx/NEStest/ICNTRLtester.v
// Project Name:  NEStest
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: InstructionController
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ICNTRLtester;

	// Inputs
	reg clk_ph1;
	reg clk_ph2;
	reg rst;
	reg [7:0] data;
	reg inc_cycle;
	reg res_cycle;

	// Outputs
	wire [7:0] IR;
	wire [2:0] cycle;

	// Instantiate the Unit Under Test (UUT)
	InstructionController uut (
		.clk_ph1(clk_ph1), 
		.clk_ph2(clk_ph2), 
		.data(data), 
		.inc_cycle(inc_cycle), 
		.res_cycle(res_cycle), 
		.IR(IR), 
		.cycle(cycle),
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		clk_ph1 = 0;
		clk_ph2 = 1;
		data = 0;
		inc_cycle = 0;
		res_cycle = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#600;
		rst = 1;
        
		// Add stimulus here
		data = 65;
		inc_cycle = 1;
		#2000
		inc_cycle = 0;
		res_cycle = 1;
		#1000
		res_cycle = 0;

	end
	
	always begin
		#500;
		clk_ph2 = !clk_ph2;
		clk_ph1 = !clk_ph1;
	end
      
endmodule

