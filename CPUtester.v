`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:47:07 09/18/2016
// Design Name:   CPU
// Module Name:   C:/Users/Zachary/Documents/Xilinx/NEStest/CPUtester.v
// Project Name:  NEStest
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: CPU
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module CPUtester;

	// Inputs
	reg clk_ph1;
	reg clk_ph2;
	reg rst;
	reg [7:0] Data_bus;

	// Outputs
	wire [15:0] Addr_bus;
	wire [20:0] Controls;
	wire [10:0] opcode;
	wire [7:0] ALURESULT;

	// Instantiate the Unit Under Test (UUT)
	CPU uut (
		.clk_ph1(clk_ph1), 
		.clk_ph2(clk_ph2), 
		.rst(rst), 
		.Data_bus(Data_bus), 
		.Addr_bus(Addr_bus), 
		.Controls(Controls), 
		.opcode(opcode),
		.ALURESULT(ALURESULT)
	);

	initial begin
		// Initialize Inputs
		clk_ph1 = 0;
		clk_ph2 = 1;
		rst = 0;
		Data_bus = 0;

		// Wait 100 ns for global reset to finish
		#600;
		rst = 1;
        
		// Add stimulus here
//		Data_bus = 8'h69;
//		
//		#2400;
//		Data_bus = 8'h07;
//		
//		#1000;
//		Data_bus = 8'h69;
//		
//		#2400;
//		Data_bus = 8'h02;

	end
	
	always @(*) begin
		case (Addr_bus) 
			0: Data_bus = 8'h69;	
			1: Data_bus = 8'h4;
			2: Data_bus = 8'h38;
			3: Data_bus = 8'he9;
			4: Data_bus = 8'h4;
			5: Data_bus = 8'h38;
			6: Data_bus = 8'he9;
			7: Data_bus = 8'h4;
//			6: Data_bus = 8'h02;
//			4: Data_bus = 8'h69;
//			5: Data_bus = 8'h01;
//			6: Data_bus = 8'h69;
//			7: Data_bus = 8'd246;
//			8: Data_bus = 8'h69;
//			9: Data_bus = 8'd1;
//			10: Data_bus = 8'h69;
//			11: Data_bus = 8'd128;
//			0: Data_bus = 8'h38;
//			1: Data_bus = 8'h69;
//			2: Data_bus = 8'h02;
			default: Data_bus = 8'd0;
		endcase
	end
	
	always begin
		#500;
		clk_ph2 = !clk_ph2;
		clk_ph1 = !clk_ph1;
	end
      
endmodule

