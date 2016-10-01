`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:02:56 05/28/2016
// Design Name:   ProgramCounter
// Module Name:   C:/Users/Zachary/Documents/Xilinx/NEStest/PCtester.v
// Project Name:  NEStest
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ProgramCounter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module PCtester;

	// Inputs
	reg [7:0] ADLin;
	reg [7:0] ADHin;
	reg inc_en;
	reg PCLin_en;
	reg PCHin_en;
	reg ADLin_en;
	reg ADHin_en;
	reg clock_ph2;
	reg rst;

	// Outputs
	wire [7:0] PCLout;
	wire [7:0] PCHout;

	// Instantiate the Unit Under Test (UUT)
	ProgramCounter uut (
		.rst(rst),
		.ADLin(ADLin), 
		.ADHin(ADHin), 
		.inc_en(inc_en), 
		.PCLin_en(PCLin_en), 
		.PCHin_en(PCHin_en), 
		.ADLin_en(ADLin_en), 
		.ADHin_en(ADHin_en), 
		.clock_ph2(clock_ph2), 
		.PCLout(PCLout), 
		.PCHout(PCHout)
	);

	initial begin
		// Initialize Inputs
		ADLin = 0;
		ADHin = 0;
		inc_en = 0;
		PCLin_en = 0;
		PCHin_en = 0;
		ADLin_en = 0;
		ADHin_en = 0;
		clock_ph2 = 0;
		rst = 0;
	end
	
	initial begin
		// Wait 100 ns for global reset to finish
		#600;
        
		rst = 1;
		
		// Add stimulus here
		ADLin = 100;
		ADHin = 2;
		PCLin_en = 1;
		PCHin_en = 1;
		inc_en = 1;
		
		#10000;
		PCLin_en = 0;
		PCHin_en = 0;
		ADLin_en = 1;
		ADHin_en = 1;
		inc_en = 0;
		
		#1000;
		ADLin_en = 0;
		ADHin_en = 0;
		PCLin_en = 1;
		PCHin_en = 1;
		inc_en = 1;

	end
	
	always begin
		#500;
		clock_ph2 = !clock_ph2;
	end
      
endmodule

