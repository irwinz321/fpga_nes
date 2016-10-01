`timescale 1ns / 1ps

// Macro to reset all control lines:
`define RESET_OUTPUTS I_cycle <= 0;	R_cycle <= 0; DL_DB <= 0; AC_SB <= 0; ADD_SB <= 0; PCL_ADL <= 0; PCH_ADH <= 0;		\
					  SB_AC <= 0; ADL_ABL <= 0; ADH_ABH <= 0; I_PCint <= 0; PCL_PCL <= 0; PCH_PCH <= 0; SB_ADD <= 0;		\
					  nDB_ADD <= 0; DB_ADD <= 0; SUMS <= 0; ACR_C <= 0; AVR_V <= 0; DBZ_Z <= 0; SB_DB <= 0; DB7_N <= 0;	\
					  IR5_C <= 0;
	
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:29:02 09/07/2016 
// Design Name: 
// Module Name:    InstructionDecoder 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module InstructionDecoder(
	input clk_ph2,								// clock phase 2
	input rst,									// reset signal
	input [2:0] cycle,							// current instruction cycle
	input [7:0] IR,								// instruction register
	output reg I_cycle, R_cycle,				// increment/reset cycle counter
	output reg DL_DB, AC_SB, ADD_SB,			// bus control
	output reg PCL_ADL, PCH_ADH,				// bus control
	output reg SB_AC, SB_DB,					// bus control
	output reg ADL_ABL, ADH_ABH,				// output address control
	output reg PCL_PCL, PCH_PCH,				// program counter control
	output wire I_PC, 
	output reg SB_ADD, nDB_ADD, DB_ADD,			// ALU input control
    output reg SUMS,                    		// ALU operation control
	output reg AVR_V, ACR_C, DBZ_Z, DB7_N, IR5_C		// Processor status flag control
    );
	
	// Declare signals:
	reg I_PCint;	// internal PC increment control - allows skipping of PC increment for single-byte instructions
	
	// Decode current opcode based on cycle:
	always @(posedge clk_ph2) begin
		
		if (rst == 0) begin
			`RESET_OUTPUTS	// Reset control lines - also sets the initial values
		end
		else begin
		
			`RESET_OUTPUTS	// Reset all control lines so we don't forget any
			
			// Switch on cycle first, then opcode:
			case (cycle)
				0: begin
					case (IR)
						ADC_IMM, SBC_IMM: begin  // next cycle: store ALU result, fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
					
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
							
							ADD_SB <= 1; SB_AC <= 1; SB_DB <= 1;					// move ADD to AC through SB
							
							AVR_V <= 1; ACR_C <= 1; DBZ_Z <= 1;	DB7_N <= 1;			// add result flags to status reg
						end
						SEC, CLC: begin	// next cycle: fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
					
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
						end
							
						default: begin  // next cycle: fetch next byte  (should only happen on reset)
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
					
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
						end
					endcase
				end
				1: begin   
					case (IR)
						ADC_IMM: begin  // next cycle: ALU add, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
					
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
						end
						SBC_IMM: begin // next cycle: ALU subtract (add inverse), fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
					
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, inverted DL
						end
						SEC, CLC: begin	// next cycle: set or clear carry flag in status register, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							IR5_C <= 1;														// set carry flag to bit 5 of current opcode (1 if SEC, 0 if CLC)
						end
							
					endcase
				end
				default: begin  // next cycle: fetch first opcode, reset cycle (should only happen on reset)
					R_cycle <= 1;											// reset cycle counter to 0
					
					PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
								
					I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
				end
			endcase
				
		end
	
	end
	
	// PC increment skipped if we're on a single-byte instruction:
	assign I_PC = (cycle == 1 && (IR == SEC || IR == CLC)) ? 0 : I_PCint;
	
	// Opcode definitions:
	localparam [7:0] ADC_IMM = 8'h69, SBC_IMM = 8'he9, SEC = 8'h38, CLC = 8'h18;
		

endmodule
