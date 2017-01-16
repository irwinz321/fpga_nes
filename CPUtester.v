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
	reg rst, irq, nmi;
	reg [7:0] Data_bus_in;

	// Outputs
	wire [15:0] Addr_bus;
	wire [7:0] Data_bus_out;
	wire R_nW;
	wire [7:0] IR_dbg, AC_dbg, X_dbg, Y_dbg, P_dbg, S_dbg;
    wire [15:0] PC_dbg;
    wire [3:0] cycle_dbg;
	
	// Useful signals;
	reg [7:0] cycle_count;

	// Instantiate the Unit Under Test (UUT)
	CPU uut (
		.clk_ph1(clk_ph1), 
		.clk_ph2(clk_ph2), 
		.rst(rst),
		.irq(irq),
		.nmi(nmi),
		.Data_bus_in(Data_bus_in), 
		.Addr_bus(Addr_bus), 
		.Data_bus_out(Data_bus_out),
		.R_nW(R_nW),
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
		irq = 1;
		nmi = 1;
		cycle_count = 0;
		Data_bus_in = 0;

		// Wait 100 ns for global reset to finish
		#600;
		rst = 1;

	end
	
	// program:
	always @(*) begin
		case (Addr_bus) 
		
			// program/data:
			0: Data_bus_in = NOP;
			1: Data_bus_in = NOP;
			2: Data_bus_in = LDX_IMM;	
			3: Data_bus_in = 8'h01;
			4: Data_bus_in = INC_ZPG;
			5: Data_bus_in = 8'h10;
			6: Data_bus_in = NOP;
			7: Data_bus_in = NOP;
			8: Data_bus_in = INC_ABS;		
			9: Data_bus_in = 8'h12;
			10: Data_bus_in = 8'h00;
			11: Data_bus_in = INC_ABX;
			12: Data_bus_in = 8'h12;
			13: Data_bus_in = 8'h00;
			14: Data_bus_in = 8'h00;
			
			16'h0010: Data_bus_in = 8'hff;	
			16'h0011: Data_bus_in = 8'h00;
			16'h0012: Data_bus_in = 8'h0f;
			16'h0013: Data_bus_in = 8'h7f;
			16'h0014: Data_bus_in = 8'h4a;
			
			16'h0102: Data_bus_in = ADC_IMM;
			16'h0103: Data_bus_in = 8'h01;
			
			// ISR:
			16'h2000: Data_bus_in = ADC_IMM;
			16'h2001: Data_bus_in = 8'h01;
			16'h2002: Data_bus_in = ADC_IMM;
			16'h2003: Data_bus_in = 8'h02;
			16'h2004: Data_bus_in = RTI;
			
			// stack:
			16'h01fa: Data_bus_in = 8'h00;
			16'h01fb: Data_bus_in = 8'h00;
			16'h01fc: Data_bus_in = 8'h00;
			16'h01fd: Data_bus_in = 8'h20;
			16'h01fe: Data_bus_in = 8'h04;
			16'h01ff: Data_bus_in = 8'h00;
			
			// interrupt vectors:
			16'hfffa: Data_bus_in = 8'h00;	// nmi
			16'hfffb: Data_bus_in = 8'h20;
			16'hfffe: Data_bus_in = 8'h00;	// irq
			16'hffff: Data_bus_in = 8'h20;
			
			default: Data_bus_in = 8'h00;
		endcase
	end
	
	// interrupts:
	always @(posedge clk_ph1) begin
		
		cycle_count = cycle_count + 8'd1;
		
		// IRQ
		//if (cycle_count >= 5 && cycle_count < 20)
		//	irq <= 0;
		//else
		//	irq <= 1;
			
		// NMI
		//if (cycle_count >= 5 && cycle_count < 20)
		//	nmi <= 0;
		//else
		//	nmi <= 1;
	end
	
	// clock phase gen:
	always begin
		#500;
		clk_ph2 = !clk_ph2;
		clk_ph1 = !clk_ph1;
	end
	
	
	// Opcode definitions:
	localparam [7:0] ADC_IMM = 8'h69, SBC_IMM = 8'he9, AND_IMM = 8'h29, ORA_IMM = 8'h09, EOR_IMM = 8'h49,
                     ADC_ABS = 8'h6d, SBC_ABS = 8'hed, AND_ABS = 8'h2d, ORA_ABS = 8'h0d, EOR_ABS = 8'h4d,
					 ADC_ZPG = 8'h65, SBC_ZPG = 8'he5, AND_ZPG = 8'h25, ORA_ZPG = 8'h05, EOR_ZPG = 8'h45,
                     ADC_ZPX = 8'h75, SBC_ZPX = 8'hf5, AND_ZPX = 8'h35, ORA_ZPX = 8'h15, EOR_ZPX = 8'h55,
                     ADC_ABX = 8'h7d, SBC_ABX = 8'hfd, AND_ABX = 8'h3d, ORA_ABX = 8'h1d, EOR_ABX = 8'h5d,
                     ADC_ABY = 8'h79, SBC_ABY = 8'hf9, AND_ABY = 8'h39, ORA_ABY = 8'h19, EOR_ABY = 8'h59,
                     ADC_INX = 8'h61, SBC_INX = 8'he1, AND_INX = 8'h21, ORA_INX = 8'h01, EOR_INX = 8'h41,
                     ADC_INY = 8'h71, SBC_INY = 8'hf1, AND_INY = 8'h31, ORA_INY = 8'h11, EOR_INY = 8'h51,
                     
                     LSR_ACC = 8'h4a, ASL_ACC = 8'h0a, ROL_ACC = 8'h2a, ROR_ACC = 8'h6a,
                     LSR_ZPG = 8'h46, ASL_ZPG = 8'h06, ROL_ZPG = 8'h26, ROR_ZPG = 8'h66,
                     LSR_ZPX = 8'h56, ASL_ZPX = 8'h16, ROL_ZPX = 8'h36, ROR_ZPX = 8'h76,
                     LSR_ABS = 8'h4e, ASL_ABS = 8'h0e, ROL_ABS = 8'h2e, ROR_ABS = 8'h6e,
                     LSR_ABX = 8'h5e, ASL_ABX = 8'h1e, ROL_ABX = 8'h3e, ROR_ABX = 8'h7e,
					 
					 INC_ZPG = 8'he6, DEC_ZPG = 8'hc6,
					 INC_ZPX = 8'hf6, DEC_ZPX = 8'hd6,
					 INC_ABS = 8'hee, DEC_ABS = 8'hce,
					 INC_ABX = 8'hfe, DEC_ABX = 8'hde,
					 
					 LDA_IMM = 8'ha9, 
					 LDA_ABS = 8'had, STA_ABS = 8'h8d,
					 LDA_ZPG = 8'ha5, STA_ZPG = 8'h85,
					 LDA_ZPX = 8'hb5, STA_ZPX = 8'h95,
					 LDA_ABX = 8'hbd, STA_ABX = 8'h9d,
					 LDA_ABY = 8'hb9, STA_ABY = 8'h99,
					 LDA_INX = 8'ha1, STA_INX = 8'h81,
					 LDA_INY = 8'hb1, STA_INY = 8'h91,
					 
					 SEC = 8'h38, CLC = 8'h18, SEI = 8'h78, CLI = 8'h58, CLV = 8'hb8, SED = 8'hf8, CLD = 8'hd8,
					 
					 NOP = 8'hea,
                     
                     BRK = 8'h00, RTI = 8'h40,
					 
					 INX = 8'he8, INY = 8'hc8, DEX = 8'hca, DEY = 8'h88, TAX = 8'haa, TXA = 8'h8a, TAY = 8'ha8, TYA = 8'h98,
                     TXS = 8'h9a, TSX = 8'hba, PHA = 8'h48, PLA = 8'h68, PHP = 8'h08, PLP = 8'h28,
					 
					 LDX_IMM = 8'ha2, LDY_IMM = 8'ha0,
					 LDX_ZPG = 8'ha6, LDY_ZPG = 8'ha4, STX_ZPG = 8'h86, STY_ZPG = 8'h84,
					 LDX_ZPY = 8'hb6, LDY_ZPX = 8'hb4, STX_ZPY = 8'h96, STY_ZPX = 8'h94,
					 LDX_ABS = 8'hae, LDY_ABS = 8'hac, STX_ABS = 8'h8e, STY_ABS = 8'h8c,
					 LDX_ABY = 8'hbe, LDY_ABX = 8'hbc,
					 
					 CMP_IMM = 8'hc9, CPX_IMM = 8'he0, CPY_IMM = 8'hc0, BIT_ZPG = 8'h24,
					 CMP_ABS = 8'hcd, CPX_ZPG = 8'he4, CPY_ZPG = 8'hc4,	BIT_ABS = 8'h2c,
					 CMP_ZPG = 8'hc5, CPX_ABS = 8'hec, CPY_ABS = 8'hcc,
					 CMP_ZPX = 8'hd5,
					 CMP_ABX = 8'hdd,
					 CMP_ABY = 8'hd9,
					 CMP_INX = 8'hc1,
					 CMP_INY = 8'hd1,
					 
					 JMP_ABS = 8'h4c, JSR_ABS = 8'h20, RTS = 8'h60,
					 JMP_IND = 8'h6c,
						
                     BPL = 8'h10, BMI = 8'h30, BVC = 8'h50, BVS = 8'h70, BCC = 8'h90, BCS = 8'hb0, BNE = 8'hd0, BEQ = 8'hf0;  
endmodule

