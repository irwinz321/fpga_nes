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
	wire [7:0] IR_dbg, AC_dbg, X_dbg, Y_dbg, P_dbg, S_dbg;
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
		.P_dbg(P_dbg),
		.S_dbg(S_dbg)
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
		
			// program/data:
			0: Data_bus = LDX_IMM;	
			1: Data_bus = 8'hfd;
			2: Data_bus = TXS;
			3: Data_bus = PLP;
			4: Data_bus = PLA;
			5: Data_bus = ADC_IMM;
			6: Data_bus = 8'h41;
			7: Data_bus = 8'h00;
			8: Data_bus = 8'h00;
			
			16'h00fd: Data_bus = 8'h00;
			16'h00fe: Data_bus = 8'h00;
			16'h00ff: Data_bus = 8'h00;
			
			// stack:
			16'h01fa: Data_bus = 8'h00;
			16'h01fb: Data_bus = 8'h00;
			16'h01fc: Data_bus = 8'h00;
			16'h01fd: Data_bus = 8'h01;
			16'h01fe: Data_bus = 8'hff;
			16'h01ff: Data_bus = 8'h02;
			
			default: Data_bus = 8'h00;
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
                     ADC_ABS = 8'h6d, SBC_ABS = 8'hed,
					 ADC_ZPG = 8'h65, SBC_ZPG = 8'he5,
                     ADC_ZPX = 8'h75, SBC_ZPX = 8'hf5,
                     ADC_ABX = 8'h7d, SBC_ABX = 8'hfd,
                     ADC_ABY = 8'h79, SBC_ABY = 8'hf9,
                     ADC_INX = 8'h61, SBC_INX = 8'he1,
                     ADC_INY = 8'h71, SBC_INY = 8'hf1,
					 
					 SEC = 8'h38, CLC = 8'h18,
					 
					 INX = 8'he8, INY = 8'hc8, DEX = 8'hca, DEY = 8'h88, TAX = 8'haa, TXA = 8'h8a, TAY = 8'ha8, TYA = 8'h98,
                     TXS = 8'h9a, TSX = 8'hba, PHA = 8'h48, PLA = 8'h68, PHP = 8'h08, PLP = 8'h28,
					 
					 LDA_IMM = 8'ha9, LDX_IMM = 8'ha2, LDY_IMM = 8'ha0,
					 
					 CMP_IMM = 8'hc9, CPX_IMM = 8'he0, CPY_IMM = 8'hc0,
					 CMP_ABS = 8'hcd, CPX_ZPG = 8'he4, CPY_ZPG = 8'hc4,
					 CMP_ZPG = 8'hc5, CPX_ABS = 8'hec, CPY_ABS = 8'hcc,
					 CMP_ZPX = 8'hd5,
					 CMP_ABX = 8'hdd,
					 CMP_ABY = 8'hd9,
					 CMP_INX = 8'hc1,
					 CMP_INY = 8'hd1,
					 
					 JMP_ABS = 8'h4c,
					 JMP_IND = 8'h6c,
						
                     BPL = 8'h10, BMI = 8'h30, BVC = 8'h50, BVS = 8'h70, BCC = 8'h90, BCS = 8'hb0, BNE = 8'hd0, BEQ = 8'hf0;
      
endmodule

