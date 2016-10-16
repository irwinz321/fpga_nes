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
	wire [7:0] IR_dbg, AC_dbg, X_dbg, Y_dbg, P_dbg;
    wire [15:0] PC_dbg;
    wire [2:0] cycle_dbg;

	// Instantiate the Unit Under Test (UUT)
	CPU uut (
		.clk_ph1(clk_ph1), 
		.clk_ph2(clk_ph2), 
		.rst(rst), 
		.Data_bus(Data_bus), 
		.Addr_bus(Addr_bus), 
		.IR_dbg(IR_dbg),
		.AC_dbg(AC_dbg),
		.cycle_dbg(cycle_dbg),
		.PC_dbg(PC_dbg),
		.X_dbg(X_dbg),
		.Y_dbg(Y_dbg),
		.P_dbg(P_dbg)
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

	end
	
	// program:
	always @(*) begin
		case (Addr_bus) 
			0: Data_bus = INX;	
			1: Data_bus = INX;
			2: Data_bus = ADC_ZPX;
			3: Data_bus = 8'h0a;
			4: Data_bus = ADC_ABX;
			5: Data_bus = 8'h04;
			6: Data_bus = 8'h01;
			7: Data_bus = ADC_ABX;
			8: Data_bus = 8'hff;
			9: Data_bus = 8'h01;
			10: Data_bus = 8'h00;
			11: Data_bus = 9'h00;
			
			12: Data_bus = 8'h05;
			16'h0106: Data_bus = 8'h06;
			16'h0201: Data_bus = 8'h07;
			default: Data_bus = 8'd0;
		endcase
	end
	
	// clock phase gen:
	always begin
		#500;
		clk_ph2 = !clk_ph2;
		clk_ph1 = !clk_ph1;
	end
	
	
	// Opcode definitions:
	localparam [7:0] ADC_IMM = 8'h69, SBC_IMM = 8'he9,  
                     ADC_ABS = 8'h6d,
					 ADC_ZPG = 8'h65,
                     ADC_ZPX = 8'h75,
                     ADC_ABX = 8'h7d,
					 
					 SEC = 8'h38, CLC = 8'h18,
					 
					 INX = 8'he8, INY = 8'hc8, DEX = 8'hca, DEY = 8'h88, TAX = 8'haa, TXA = 8'h8a, TAY = 8'ha8, TYA = 8'h98;
      
endmodule

