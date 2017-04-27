`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:07:01 03/16/2017
// Design Name:   NES
// Module Name:   C:/Users/Zachary/Documents/Xilinx/NEStest/NEStester.v
// Project Name:  NEStest
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: NES
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module NEStester;

	// Inputs
	reg clk_in;
	reg nreset;
	reg rx_in;

	// Outputs
	wire tx_out;
	wire [7:0] led_out;

	// Instantiate the Unit Under Test (UUT)
	NES uut (
		.clk_in(clk_in), 
		.nreset(nreset),  
		.tx_out(tx_out), 
		.led_out(led_out),
		.rx_in(rx_in)
	);

	initial begin
		// Initialize Inputs
		clk_in = 0;
		nreset = 0;
		rx_in = 1;

		// Wait 100 ns for global reset to finish
		#600;
        
		// Add stimulus here
		nreset = 1;
		
		#50;
		rx_in = 0;
		#1736
		rx_in = 1;
		#1736
		rx_in = 0;
		#12152;
		rx_in = 1;
		
		#2000;
		rx_in = 0;
		#15624;
		rx_in = 1;
		
		#300000;
		rx_in = 0;
		#1736
		rx_in = 1;
		#1736
		rx_in = 0;
		#12152;
		rx_in = 1;
		
		#2000;
		rx_in = 0;
		#15624;
		rx_in = 1;
	end
	
	always begin
		#1;
		clk_in = !clk_in;
	end
      
endmodule

