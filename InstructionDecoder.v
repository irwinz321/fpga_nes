`timescale 1ns / 1ps

// Macro to reset all control lines:
`define RESET_OUTPUTS I_cycle <= 0;	R_cycle <= 0; DL_DB <= 0; AC_SB <= 0; ADD_SB <= 0; PCL_ADL <= 0; PCH_ADH <= 0;		\
					  SB_AC <= 0; ADL_ABL <= 0; ADH_ABH <= 0; I_PCint <= 0; PCL_PCL <= 0; PCH_PCH <= 0; SB_ADD <= 0;	\
					  nDB_ADD <= 0; DB_ADD <= 0; SUMS <= 0; ACR_C <= 0; AVR_V <= 0; DBZ_Z <= 0; SB_DB <= 0; DB7_N <= 0;	\
					  IR5_C <= 0; Z_ADD <= 0; ADD_ADL <= 0; DL_ADH <= 0; DL_ADL <= 0; Z_ADH <= 0; SB_X <= 0; SB_Y <= 0; \
                      X_SB <= 0; Y_SB <= 0; C_ONE <= 0; nONE_ADD <= 0; AC_DB <= 0; ADL_ADD <= 0; S_cycle <= 0; SB_ADH <= 0; \
					  C_ZERO <= 0; DB_SB <= 0; ADL_PCL <= 0; ADH_PCH <= 0; PCH_DB <= 0; SB_S <= 0; I_S <= 0; D_S <= 0;	\
					  S_SB <= 0; S_ADL <= 0; ONE_ADH <= 0;
	
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
	input clk_ph2,								        // clock phase 2
	input rst,									        // reset signal
	input [2:0] cycle,							        // current instruction cycle
	input [7:0] IR,								        // instruction register
    input carry, A_sign,                                // ALU carry bit and A input sign bit (for page crossing)
    input [7:0] P,                                      // processor status register (for branching)
	output reg I_cycle, R_cycle, S_cycle,		        // increment/reset/skip cycle counter
	output reg DL_DB, AC_SB, AC_DB, ADD_SB,	PCH_DB,     // bus control
    output reg DL_ADH, DL_ADL,
	output reg PCL_ADL, PCH_ADH, ADD_ADL, Z_ADH,        // bus control
	output reg ADL_PCL, ADH_PCH,
	output reg SB_AC, SB_DB, SB_X, SB_Y, X_SB, Y_SB,    // bus control
    output reg SB_ADH, DB_SB,                       
    output reg SB_S, S_ADL, ONE_ADH, S_SB, I_S, D_S,                          
	output reg ADL_ABL, ADH_ABH,				        // output address control
	output reg PCL_PCL, PCH_PCH,				        // program counter control
	output wire I_PC, 
	output reg SB_ADD, nDB_ADD, DB_ADD,	Z_ADD, C_ONE, nONE_ADD, ADL_ADD, C_ZERO,   	// ALU input control
    output reg SUMS,                    		        // ALU operation control
	output reg AVR_V, ACR_C, DBZ_Z, DB7_N, IR5_C		// Processor status flag control
    );
	
	// Declare signals:
	reg I_PCint;	// internal PC increment control - allows skipping of PC increment for single-byte instructions3
	
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
						ADC_IMM, ADC_ABS, ADC_ZPG, ADC_ZPX, ADC_ABX, ADC_ABY, ADC_INX, ADC_INY,
						SBC_IMM, SBC_ABS, SBC_ZPG, SBC_ZPX, SBC_ABX, SBC_ABY, SBC_INX, SBC_INY: begin  // next cycle: store ALU result, fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
				
							ADD_SB <= 1; SB_AC <= 1; SB_DB <= 1;					// move ADD to AC through SB
							
							AVR_V <= 1; ACR_C <= 1; DBZ_Z <= 1;	DB7_N <= 1;			// add result flags to status reg
						end
						CMP_IMM, CPX_IMM, CPY_IMM: begin	// next cycle: set flags, fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
							
							ACR_C <= 1; DBZ_Z <= 1;	DB7_N <= 1;			// add result flags to status reg
						end
						SEC, CLC, TXA, TAX, TYA, TAY, TXS, TSX,
						LDA_IMM, LDX_IMM, LDY_IMM, 
                        JMP_ABS, JMP_IND,
                        BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ: begin	// next cycle: fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
						end
                        INX, DEX: begin  // next cycle: fetch next byte, store new value in X
                            I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
                            
                            ADD_SB <= 1; SB_X <= 1; SB_DB <= 1;                     // move ADD to X through SB
                            DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
                        end
                        INY, DEY: begin  // next cycle: fetch next byte, store new value in Y
                            I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
                            
                            ADD_SB <= 1; SB_Y <= 1; SB_DB <= 1;                     // move ADD to Y through SB
                            DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
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
						CMP_IMM: begin // next cycle: ALU subtract (add inverse), fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on AC, inverted DL (set carry to 1 automatically)
						end
						CPX_IMM: begin // next cycle: ALU subtract (add inverse), fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; X_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on X, inverted DL (set carry to 1 automatically)
						end
						CPY_IMM: begin // next cycle: ALU subtract (add inverse), fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; Y_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on Y, inverted DL (set carry to 1 automatically)
						end
						SEC, CLC: begin	// next cycle: set or clear carry flag in status register, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							IR5_C <= 1;														// set carry flag to bit 5 of current opcode (1 if SEC, 0 if CLC)
						end
                        INX: begin // next cycle: ALU add 1 to X register, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            X_SB <= 1; SB_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ONE <= 1;  // add 1 to X register
                        end
                        DEX: begin // next cycle: ALU add -1 to X register, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            X_SB <= 1; SB_DB <= 1; DB_ADD <= 1; nONE_ADD <= 1; SUMS <= 1; C_ONE <= 1;  // add -1 to X register
                        end
                        TXA: begin // next cycle: send X register to AC through SB and DB, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            X_SB <= 1; SB_DB <= 1; SB_AC <= 1; DB7_N <= 1; DBZ_Z <= 1;
                        end
                        TAX: begin // next cycle: send AC register to X through SB and DB, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            SB_X <= 1; AC_DB <= 1; AC_SB <= 1; DB7_N <= 1; DBZ_Z <= 1;
                        end
                        TXS: begin  // next cycle: send X register to S through SB, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            X_SB <= 1; SB_S <= 1;     // transfer X to S
                        end
						TSX: begin	// next cycle: send S register to X through SB, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            S_SB <= 1; SB_X <= 1; SB_DB <= 1; DB7_N <= 1; DBZ_Z <= 1;	// transfer S to X, set flags
						end
						PLA: begin	// next cycle: put stack pointer out on address bus (ignore results), increment pointer
							I_cycle <= 1;	// increment cycle counter
							
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; I_S <= 1;	// output {0x01, S}, increment pointer
						end
                        INY: begin // next cycle: ALU add 1 to Y register, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            Y_SB <= 1; SB_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ONE <= 1;  // add 1 to Y register
                        end
                        DEY: begin // next cycle: ALU add -1 to Y register, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            Y_SB <= 1; SB_DB <= 1; DB_ADD <= 1; nONE_ADD <= 1; SUMS <= 1; C_ONE <= 1;  // add 1 to Y register
                        end
                        TYA: begin // next cycle: send Y register to AC through SB and DB, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            Y_SB <= 1; SB_DB <= 1; SB_AC <= 1; DB7_N <= 1; DBZ_Z <= 1;
                        end
                        TAY: begin // next cycle: send AC register to Y through SB and DB, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            SB_Y <= 1; AC_DB <= 1; AC_SB <= 1; DB7_N <= 1; DBZ_Z <= 1;
                        end
                        ADC_ABS, SBC_ABS: begin  // next cycle: store address low-byte in ALU, fetch address high-byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;     // send low-byte to ALU, add zero
                        end
                        ADC_ZPG, SBC_ZPG: begin  // next cycle: output zero page address, fetch data
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output low-byte (DL) and zeros to address bus
                        end
                        ADC_ZPX, ADC_INX, SBC_ZPX, SBC_INX: begin  // next cycle: add base address (DL) to X register
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output base address low-byte (DL) and zeros to address bus - result ignored
                            
                            ADL_ADD <= 1; X_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1; // add x register to base address low-byte (DL)
                        end
                        ADC_ABX, SBC_ABX: begin  // next cycle: add base address low-byte to X register, fetch base address high-byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; X_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add X register
                        end
                        ADC_ABY, SBC_ABY: begin  // next cycle: add base address low-byte to Y register, fetch base address high-byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; Y_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add Y register
                        end
						ADC_INY, SBC_INY: begin	// next cycle: fetch indirect addr low-byte in zero page, add 1 to indirect addr low-byte
							I_cycle <= 1;   // increment cycle counter
                            
                            DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output low-byte (DL) and zeros to address bus
							
							ADL_ADD <= 1; Z_ADD <= 1; C_ONE <= 1; SUMS <= 1; // send low-byte to ALU, add 1
						end
						LDA_IMM: begin // next cycle: load data into AC
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;				// load data into AC
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						LDX_IMM: begin // next cycle: load data into X
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_X <= 1;				// load data into X
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						LDY_IMM: begin // next cycle: load data into Y
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_Y <= 1;				// load data into Y
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						JMP_ABS, JMP_IND: begin // next cycle: store addr low byte, fetch addr high byte
							I_cycle <= 1;   // increment cycle counter
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC (ignored for JMP_ABS, replaced by ADL, ADH)
							
							DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add zero
						end	
                        BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ: begin  // check flag, next cycle: take branch if flag condition met, fetch next opcode if not
                            if ((IR == BPL && P[7] == 0) || 		// BPL: result is positive - take branch
							    (IR == BMI && P[7] == 1) ||
								(IR == BVC && P[6] == 0) ||
								(IR == BVS && P[6] == 1) || 
								(IR == BCC && P[0] == 0) ||
								(IR == BCS && P[0] == 1) ||
								(IR == BNE && P[1] == 0) ||
								(IR == BEQ && P[1] == 1)) 	begin		// BMI: result is negative - take branch
								
                                I_cycle <= 1;   // increment cycle counter
                                
                                DL_DB <= 1; DB_SB <= 1; SB_ADD <= 1; 
                                ADL_ADD <= 1; C_ZERO <= 1; SUMS <= 1;  // add offset (DL) to PC low-byte
                            end
                            else begin
                                R_cycle <= 1;   // reset cycle counter to 0
                            end    
							
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                        end
					endcase
				end
                2: begin
                    case (IR)
                        ADC_ABS, SBC_ABS: begin  // next cycle: output address, fetch data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; DL_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;  // send low-byte (ALU) to ABL, send high-byte (DL) to ABH
                        end
                        ADC_ZPG: begin  // next cycle: perform add, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
                        end
						SBC_ZPG: begin  // next cycle: perform subtraction, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU subtraction on AC, DL
                        end
                        ADC_ZPX, SBC_ZPX: begin  // next cycle: output ALU result and zeros to address bus to retrieve data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
                        end
                        ADC_ABX, ADC_ABY, SBC_ABX, SBC_ABY: begin  // next cycle: if carry=1, add 1 to BAH; if carry=0, output address (skip cycle 3)
                            if (carry) begin
                                S_cycle <= 1;
                                
                                DL_DB <= 1; DB_ADD <= 1; C_ONE <= 1; SUMS <= 1; // send high-byte to ALU, add 1
                            end
                            else begin
                                I_cycle <= 1;
                            end
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send (low-byte + X/Y) to ABL, send high-byte to ABH
                            
                        end
                        ADC_INX, SBC_INX: begin  // next cycle: output ALU result and zeros to address bus to retrieve low-byte, increment ALU result
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
                            
                            ADD_SB <= 1; SB_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ONE <= 1; // add 1 to (low-byte + X) 
                        end
						ADC_INY, SBC_INY: begin	// next cycle: output ALU result and zeros to addres bus to retrieve high byte, add Y to fetched low byte
							I_cycle <= 1;   // increment cycle counter
							
							ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send incremented indirect low-byte (ALU) to ABL, send zeros to ABH
							
							Y_SB <= 1; SB_ADD <= 1; DL_DB <= 1; DB_ADD <= 1; SUMS <= 1; C_ZERO <= 1; // add Y to fetched low-byte
						end
                        JMP_ABS: begin // next cycle: set PC to (ADL, ADH) and output to fetch next opcode
                            R_cycle <= 1;   // reset cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; ADL_PCL <= 1;   // output ADL and set PCL = ADL
                            DL_ADH <= 1; ADH_ABH <= 1; ADH_PCH <= 1;    // output ADH and set PCH = ADH
                            
                            I_PCint <= 1;                               // increment new PC
                        end
                        JMP_IND: begin // next cycle: fetch ADL from indirect addr, increment low-byte of indirect addr
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send out indirect addr (IAL from ALU, IAH from DL)
                            PCL_PCL <= 1; PCH_PCH <= 1;							// don't increment PC
                            
                            ADD_SB <= 1; SB_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ONE <= 1; // add 1 to low-byte 
                        end
                        BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ: begin  // next cycle: if carry/borrow, add 1 to PC high byte; else, output new PC
                            if (carry != A_sign) begin  // either a carry or a borrow happened -> fix PCH
                                I_cycle <= 1;   // increment cycle counter
                                
                                PCH_DB <= 1; DB_ADD <= 1; SUMS <= 1; nONE_ADD <= A_sign; C_ONE <= 1; // add 1 to PCH if offset positive, subtract 1 if offset negative
                            end
                            else begin
                                R_cycle <= 1;   // reset cycle counter to 0
                                I_PCint <= 1;  // increment PC
                            end
							
                            ADL_PCL <= 1;
                            ADD_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1; // output {PCL+offset, PCH}
                            
                        end
						PLA: begin	// next cycle: put real stack pointer out on address bus
							I_cycle <= 1;	// increment cycle counter
							
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1;	// output {0x01, S+1}, hold pointer
						end
                    endcase
                end
                3: begin
                    case (IR)
                        ADC_ABS, ADC_ZPX, ADC_ABX, ADC_ABY: begin  // next cycle: perform add, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
                        end
						SBC_ABS, SBC_ZPX, SBC_ABX, SBC_ABY: begin  // next cycle: perform subtraction, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU subtraction on AC, DL
                        end
                        ADC_INX, SBC_INX: begin // next cycle: store address low-byte, fetch address high byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add zero
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH                            
                        end
						ADC_INY, SBC_INY: begin	// next cycle: if carry=1, add 1 to BAH; if carry=0, output address (skip cycle 4)
							if (carry) begin
                                S_cycle <= 1;
                                
                                DL_DB <= 1; DB_ADD <= 1; C_ONE <= 1; SUMS <= 1; // send high-byte to ALU, add 1
                            end
                            else begin
                                I_cycle <= 1;	
                            end
							
							ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send (low-byte + Y) to ABL, send high-byte to ABH
						end
                        JMP_IND: begin  // next cycle: store address low-byte, output incremented indirect address to fetch high byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; 	// send out indirect addr (IAL+1 from ALU, IAH from previous)
                            PCL_PCL <= 1; PCH_PCH <= 1;							// don't increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add zero
                        end
                        BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ: begin  // next cycle: fetch next opcode
                            R_cycle <= 1;   // reset cycle counter to zero
                            
                            ADD_SB <= 1; SB_ADH <= 1; ADH_ABH <= 1; ADH_PCH <= 1; I_PCint <= 1; // output corrected address, store high byte in PC and increment
                        end
						PLA: begin	// next cycle: fetch next opcode, store data in accumulator, set flags
							R_cycle <= 1; 	// reset cycle counter to zero
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;			// store value in accumulator
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
                    endcase
                end
                4: begin
                    case (IR)
                        ADC_ABX, ADC_ABY, SBC_ABX, SBC_ABY: begin // next cycle: output address to fetch data
                            I_cycle <= 1;
                            
                            ADD_SB <= 1; SB_ADH <= 1; ADH_ABH <= 1; // send incremented high-byte to ABH (low-byte already in ABL)
                        end
                        ADC_INX, SBC_INX: begin  //next cycle: send out fetched address to get data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send high-byte to ABH  
                        end
						ADC_INY: begin	// there was NOT a page crossing - perform add and fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
						end
						SBC_INY: begin	// there was NOT a page crossing - perform subtraction and fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU subtraction on AC, DL
						end
                        JMP_IND: begin  // next cycle: fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; ADL_PCL <= 1;   // output ADL and set PCL = ADL
                            DL_ADH <= 1; ADH_ABH <= 1; ADH_PCH <= 1;    // output ADH and set PCH = ADH
                            
                            I_PCint <= 1;                               // increment new PC
                        end
                    endcase
                end
                5: begin
                    case (IR)
                        ADC_ABX, ADC_ABY, ADC_INX: begin // perform add, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
                        end
						SBC_ABX, SBC_ABY, SBC_INX: begin // perform subtraction, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU subtraction on AC, DL
                        end
						ADC_INY, SBC_INY: begin	// there was a page crossing - now output (low byte + Y) and (high byte + 1) to fetch data
							I_cycle <= 1;
                            
                            ADD_SB <= 1; SB_ADH <= 1; ADH_ABH <= 1; // send incremented high-byte to ABH (low-byte+Y already in ABL)
						end
                    endcase
                end
				6: begin
					case (IR)
						ADC_INY: begin	// perform add, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
						end
						SBC_INY: begin	// perform subtraction, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU subtraction on AC, DL
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
	
	// PC increment skipped if we're on a single-byte instruction (implied addressing):
	assign I_PC = (cycle == 1'd1 && (IR == SEC || IR == CLC || IR == INX || IR == INY || IR == DEX || IR == DEY || IR == TAX || IR == TXA ||
									 IR == TAY || IR == TYA || IR == TXS || IR == TSX || IR == PLA || IR == PLP || IR == PHP || IR == PHA)) ? 1'd0 : I_PCint;
	
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
