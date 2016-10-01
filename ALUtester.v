`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:16:03 09/22/2016
// Design Name:   ALU
// Module Name:   C:/Users/Zachary/Documents/Xilinx/NEStest/ALUtester.v
// Project Name:  NEStest
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ALU
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ALUtester;

	// Inputs
	reg SUM_en;
	reg AND_en;
	reg EOR_en;
	reg OR_en;
	reg SR_en;
	reg INV_en;
	reg [7:0] Ain;
	reg [7:0] Bin;
	reg Cin;

	// Outputs
	wire [7:0] RES;
	wire Cout;
	wire OVFout;

	// Instantiate the Unit Under Test (UUT)
	ALU uut (
		.SUM_en(SUM_en), 
		.AND_en(AND_en), 
		.EOR_en(EOR_en), 
		.OR_en(OR_en), 
		.SR_en(SR_en), 
		.INV_en(INV_en), 
		.Ain(Ain), 
		.Bin(Bin), 
		.Cin(Cin), 
		.RES(RES), 
		.Cout(Cout), 
		.OVFout(OVFout)
	);

	initial begin
		// Initialize Inputs
		SUM_en = 0;
		AND_en = 0;
		EOR_en = 0;
		OR_en = 0;
		SR_en = 0;
		INV_en = 0;
		Ain = 0;
		Bin = 0;
		Cin = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		Ain = 9;
		Bin = 8'hFF;
		Cin = 0;
		INV_en = 0;
		{SUM_en, AND_en, EOR_en, OR_en, SR_en} = 5'b10000;
		
		

	end
      
endmodule

