`timescale 1ns / 1ps

// Macro to reset all control lines:
`define RESET_OUTPUTS I_cycle <= 0;	R_cycle <= 0; DL_DB <= 0; AC_SB <= 0; ADD_SB <= 0; PCL_ADL <= 0; PCH_ADH <= 0;		\
					  SB_AC <= 0; ADL_ABL <= 0; ADH_ABH <= 0; I_PCint <= 0; PCL_PCL <= 0; PCH_PCH <= 0; SB_ADD <= 0;	\
					  nDB_ADD <= 0; DB_ADD <= 0; SUMS <= 0; ACR_C <= 0; AVR_V <= 0; DBZ_Z <= 0; SB_DB <= 0; DB7_N <= 0;	\
					  IR5_C <= 0; Z_ADD <= 0; ADD_ADL <= 0; DL_ADH <= 0; DL_ADL <= 0; Z_ADH <= 0; SB_X <= 0; SB_Y <= 0; \
                      X_SB <= 0; Y_SB <= 0; C_ONE <= 0; nONE_ADD <= 0; AC_DB <= 0; ADL_ADD <= 0; S_cycle <= 0; SB_ADH <= 0; \
					  C_ZERO <= 0; DB_SB <= 0; ADL_PCL <= 0; ADH_PCH <= 0; PCH_DB <= 0; SB_S <= 0; I_S <= 0; D_S <= 0;	\
					  S_SB <= 0; S_ADL <= 0; ONE_ADH <= 0; DB_P <= 0; R_nW_int <= 1; P_DB <= 0; PCL_DB <= 0; FF_ADH <= 0; \
                      FA_ADL <= 0; FE_ADL <= 0; CLR_INT <= 0; PL1_ADL <= 0; ONE_I <= 0; CLR_NMI <= 0; ANDS <= 0; \
                      EORS <= 0; ORS <= 0; IR5_I <= 0; ZERO_V <= 0; IR5_D <= 0; DB6_V <= 0;
	
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
    input irq_flag, nmi_flag, int_flag,                 // interrupt flags
	output reg I_cycle, R_cycle, S_cycle,		        // increment/reset/skip cycle counter
	output reg R_nW_int,
	output reg DL_DB, AC_SB, AC_DB, ADD_SB,	PCH_DB, P_DB, PCL_DB,   // bus control
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
    output reg SUMS, ANDS, EORS, ORS,        		     // ALU operation control
	output reg AVR_V, ACR_C, DBZ_Z, DB7_N, IR5_C, DB_P,	DB6_V, // Processor status flag control
    output reg IR5_I, ZERO_V, IR5_D,
    output reg FF_ADH, FA_ADL, FE_ADL, PL1_ADL,                 
    output reg CLR_INT, CLR_NMI, ONE_I
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
                        AND_IMM, AND_ABS, AND_ZPG, AND_ZPX, AND_ABX, AND_ABY, AND_INX, AND_INY,
						ORA_IMM, ORA_ABS, ORA_ZPG, ORA_ZPX, ORA_ABX, ORA_ABY, ORA_INX, ORA_INY,
                        EOR_IMM, EOR_ABS, EOR_ZPG, EOR_ZPX, EOR_ABX, EOR_ABY, EOR_INX, EOR_INY: begin  // next cycle: store ALU result, fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
				
							ADD_SB <= 1; SB_AC <= 1; SB_DB <= 1;					// move ADD to AC through SB
							DBZ_Z <= 1;	DB7_N <= 1;			                        // add result flags to status reg
						end
						CMP_IMM, CMP_ZPG, CMP_ABS, CMP_ZPX, CMP_ABX, CMP_ABY, CMP_INX, CMP_INY,
                        CPX_IMM, CPY_IMM: begin	// next cycle: set flags, fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
							
							ADD_SB <= 1; SB_DB <= 1;	// move alu result to DB (but not to accumulator)
							ACR_C <= 1; DBZ_Z <= 1;	DB7_N <= 1;			// add result flags to status reg
						end
						SEC, CLC, SEI, CLI, CLV, SED, CLD, TXA, TAX, TYA, TAY, 
                        TXS, TSX, PLA, PLP, PHA, PHP,
						LDA_IMM, LDA_ABS, LDA_ZPG, LDA_ZPX, LDA_ABX, LDA_ABY, LDA_INX, LDA_INY,
                        STA_ABS, STA_ZPG, STA_ZPX, STA_ABX, STA_ABY, STA_INX, STA_INY,
						LDX_IMM, LDX_ABS, LDX_ZPG, LDX_ZPY, LDX_ABY, 
						LDY_IMM, LDY_ABS, LDY_ZPG, LDY_ZPX, LDY_ABX,
						STX_ABS, STX_ZPG, STX_ZPY, STY_ABS, STY_ZPG, STY_ZPX, 
                        JMP_ABS, JMP_IND,
						JSR_ABS, RTS,
                        BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ,
                        BRK, RTI: begin	// next cycle: fetch next byte
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
						end
						BIT_ZPG, BIT_ABS: begin	// next cycle: fetch next byte, set result flag
							I_cycle <= 1;											// increment cycle counter
					
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;	// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;					// increment PC
							
							ADD_SB <= 1; SB_DB <= 1;	// move alu result to DB (but not to accumulator)
							DBZ_Z <= 1;	// set flag based on ALU result
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
                        AND_IMM: begin // next cycle: ALU and, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1;	// perform ALU add on AC, inverted DL
						end
                        ORA_IMM: begin // next cycle: ALU or, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ORS <= 1;	// perform ALU add on AC, inverted DL
						end
                        EOR_IMM: begin // next cycle: ALU xor, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; EORS <= 1;	// perform ALU add on AC, inverted DL
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
                        SEI, CLI: begin	// next cycle: set or clear interrupt-enable flag in status register, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							IR5_I <= 1;														// set interrupt flag to bit 5 of current opcode (1 if SEI, 0 if CLI)
						end
                        CLV: begin	// next cycle: clear overflow flag in status register, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							ZERO_V <= 1;												    // set overflow flag to 0
						end
                        SED, CLD: begin // next cycle: set or clear decimal flag in status register, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							IR5_D <= 1;														// set interrupt flag to bit 5 of current opcode (1 if SED, 0 if CLD)
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
						PLA, PLP: begin	// next cycle: put stack pointer out on address bus (ignore results), increment pointer
							I_cycle <= 1;	// increment cycle counter
							
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; I_S <= 1;	// output {0x01, S}, increment pointer
						end
						PHA: begin	// next cycle: put stack pointer out on address bus, Accumulator out on data bus, write
							I_cycle <= 1;
							
							AC_DB <= 1; R_nW_int <= 0;								// write A to
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// {0x01, S}
						end
						PHP: begin	// next cycle: put stack pointer out on address bus, P out on data bus, write
							I_cycle <= 1;
							
							P_DB <= 1; R_nW_int <= 0;								// write P to
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// {0x01, S}
						end
						JSR_ABS: begin	// next cycle: store address low in ALU, put stack pointer out on address bus
							I_cycle <= 1;	// increment cycle counter
							
							DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;     // send low-byte to ALU, add zero
							
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// output {0x01, S}
						end
                        RTS, RTI: begin  // next cycle: increment stack pointer to grab PCL next time, put out stack pointer to grab junk
                            I_cycle <= 1;   // increment cycle counter
                            
                            S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// output {0x01, S}
                            I_S <= 1;   // increment S
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
                        ADC_ABS, SBC_ABS, AND_ABS, ORA_ABS, EOR_ABS, LDA_ABS,
                        STA_ABS, CMP_ABS, BIT_ABS, LDX_ABS, LDY_ABS,
						STX_ABS, STY_ABS: begin  // next cycle: store address low-byte in ALU, fetch address high-byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;     // send low-byte to ALU, add zero
                        end
                        ADC_ZPG, SBC_ZPG, AND_ZPG, ORA_ZPG, EOR_ZPG, LDA_ZPG, 
						CMP_ZPG, BIT_ZPG, LDX_ZPG, LDY_ZPG: begin  // next cycle: output zero page address, fetch data
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output low-byte (DL) and zeros to address bus
                        end
						STA_ZPG: begin	// next cycle: output zero page address, write accumulator data
							I_cycle <= 1; 	// increment cycle counter
							
							DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output low-byte (DL) and zeros to address bus
							
							AC_DB <= 1; R_nW_int <= 0;	// write accumulator data to memory
						end
						STX_ZPG: begin // next cycle: output zero page address, write x data
							I_cycle <= 1; 	// increment cycle counter
							
							DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output low-byte (DL) and zeros to address bus
							
							X_SB <= 1; SB_DB <= 1; R_nW_int <= 0;	// write x data to memory
						end
						STY_ZPG: begin // next cycle: output zero page address, write y data
							I_cycle <= 1; 	// increment cycle counter
							
							DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output low-byte (DL) and zeros to address bus
							
							Y_SB <= 1; SB_DB <= 1; R_nW_int <= 0;	// write y data to memory
						end
                        ADC_ZPX, ADC_INX, SBC_ZPX, SBC_INX, AND_ZPX, AND_INX, 
                        ORA_ZPX, ORA_INX, EOR_ZPX, EOR_INX, LDA_ZPX, LDA_INX,
						STA_ZPX, STA_INX, CMP_ZPX, CMP_INX, LDY_ZPX, STY_ZPX: begin  // next cycle: add base address (DL) to X register
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;    // output base address low-byte (DL) and zeros to address bus - result ignored
                            
                            ADL_ADD <= 1; X_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1; // add x register to base address low-byte (DL)
                        end
						LDX_ZPY, STX_ZPY: begin	// next cycle: add base address (DL) to Y register
							I_cycle <= 1;	// increment cycle counter
							
							DL_ADL <= 1; Z_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;	// output base address low-byte and zeros to address bus - result ignored
							
							ADL_ADD <= 1; Y_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1;	// add x register to base address low-byte
						end
                        ADC_ABX, SBC_ABX, AND_ABX, ORA_ABX, EOR_ABX, LDA_ABX,
						STA_ABX, CMP_ABX, LDY_ABX: begin  // next cycle: add base address low-byte to X register, fetch base address high-byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; X_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add X register
                        end
                        ADC_ABY, SBC_ABY, AND_ABY, ORA_ABY, EOR_ABY, LDA_ABY,
						STA_ABY, CMP_ABY, LDX_ABY: begin  // next cycle: add base address low-byte to Y register, fetch base address high-byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
                            I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                            
                            DL_DB <= 1; DB_ADD <= 1; Y_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add Y register
                        end
						ADC_INY, SBC_INY, AND_INY, ORA_INY, EOR_INY, LDA_INY,
						STA_INY, CMP_INY: begin	// next cycle: fetch indirect addr low-byte in zero page, add 1 to indirect addr low-byte
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
                        BRK: begin  // next cycle: store PCH on stack
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCH_DB <= 1; R_nW_int <= 0;								// write PCH to
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// {0x01, S}
                            D_S <= 1;                                               // decrement S
                        end
					endcase
				end
                2: begin
                    case (IR)
                        ADC_ABS, SBC_ABS, AND_ABS, ORA_ABS, EOR_ABS, LDA_ABS,
                        CMP_ABS, BIT_ABS, LDX_ABS, LDY_ABS: begin  // next cycle: output address, fetch data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; DL_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;  // send low-byte (ALU) to ABL, send high-byte (DL) to ABH
                        end
                        STA_ABS: begin  // next cycle: output address, write accumulator data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; DL_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;  // send low-byte (ALU) to ABL, send high-byte (DL) to ABH
                            AC_DB <= 1; R_nW_int <= 0;      // write accumulator data to memory
                        end
						STX_ABS: begin  // next cycle: output address, write x data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; DL_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;  // send low-byte (ALU) to ABL, send high-byte (DL) to ABH
                            X_SB <= 1; SB_DB <= 1; R_nW_int <= 0;      // write x data to memory
                        end
						STY_ABS: begin  // next cycle: output address, write y data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; DL_ADH <= 1; ADL_ABL <= 1; ADH_ABH <= 1;  // send low-byte (ALU) to ABL, send high-byte (DL) to ABH
                            Y_SB <= 1; SB_DB <= 1; R_nW_int <= 0;      // write y data to memory
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
                        AND_ZPG: begin  // next cycle: perform and, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1;	// perform ALU and on AC, DL
                        end
                        ORA_ZPG: begin  // next cycle: perform or, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ORS <= 1;	// perform ALU or on AC, DL
                        end
                        EOR_ZPG: begin  // next cycle: perform xor, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; EORS <= 1;	// perform ALU xor on AC, DL
                        end
						LDA_ZPG: begin // next cycle: load data into AC
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;				// load data into AC
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						STA_ZPG, STX_ZPG, STY_ZPG: begin	// next cycle: fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
						end
						LDX_ZPG: begin // next cycle: load data into X
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_X <= 1;				// load data into X
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						LDY_ZPG: begin // next cycle: load data into Y
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_Y <= 1;				// load data into Y
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
                        CMP_ZPG: begin // next cycle: ALU subtract, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on AC, inverted DL (set carry to 1 automatically)
                        end
						BIT_ZPG: begin	// next cycle: ALU add, fetch next opcode, set flags
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1; 	// perform ALU and on AC
							
							DB7_N <= 1; DB6_V <= 1; DBZ_Z <= 1;	// set flags based on fetched memory (Z is only temporary)
						end
                        ADC_ZPX, SBC_ZPX, AND_ZPX, ORA_ZPX, EOR_ZPX, LDA_ZPX,
                        CMP_ZPX, LDX_ZPY, LDY_ZPX: begin  // next cycle: output ALU result and zeros to address bus to retrieve data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
                        end
						STA_ZPX: begin	// next cycle: output ALU result and zeros to address but to store data
							I_cycle <= 1; 	// increment cycle counter
							
							ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
							
							AC_DB <= 1; R_nW_int <= 0;	// write accumulator data to memory
						end
						STX_ZPY: begin	// next cycle: output ALU result and zeros to address bus to store data
							I_cycle <= 1; 	// increment cycle counter
							
							ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
							
							X_SB <= 1; SB_DB <= 1; R_nW_int <= 0;	// write x data to memory
						end
						STY_ZPX: begin	// next cycle: output ALU result and zeros to address bus to store data
							I_cycle <= 1; 	// increment cycle counter
							
							ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
							
							Y_SB <= 1; SB_DB <= 1; R_nW_int <= 0;	// write y data to memory
						end
                        ADC_ABX, ADC_ABY, SBC_ABX, SBC_ABY, AND_ABX, AND_ABY,
                        ORA_ABX, ORA_ABY, EOR_ABX, EOR_ABY, LDA_ABX, LDA_ABY,
                        CMP_ABX, CMP_ABY, LDY_ABX, LDX_ABY: begin  // next cycle: if carry=1, add 1 to BAH; if carry=0, output address (skip cycle 3)
                            if (carry) begin
                                S_cycle <= 1;
                                
                                DL_DB <= 1; DB_ADD <= 1; C_ONE <= 1; SUMS <= 1; // send high-byte to ALU, add 1
                            end
                            else begin
                                I_cycle <= 1;
                            end
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send (low-byte + X/Y) to ABL, send high-byte to ABH
                            
                        end
						STA_ABX, STA_ABY: begin	// next cycle: read from address regardless of page crossing, correct high-byte
							S_cycle <= 1;
							
							DL_DB <= 1; DB_ADD <= 1; C_ONE <= carry; SUMS <= 1; // send high-byte to ALU, add carry if appropriate
							
							ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send (low-byte + X/Y) to ABL, send high-byte to ABH
						end
                        ADC_INX, SBC_INX, AND_INX, ORA_INX, EOR_INX, LDA_INX,
						STA_INX, CMP_INX: begin  // next cycle: output ALU result and zeros to address bus to retrieve low-byte, increment ALU result
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH
                            
                            ADD_SB <= 1; SB_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ONE <= 1; // add 1 to (low-byte + X) 
                        end
						ADC_INY, SBC_INY, AND_INY, ORA_INY, EOR_INY, LDA_INY,
						STA_INY, CMP_INY: begin	// next cycle: output ALU result and zeros to addres bus to retrieve high byte, add Y to fetched low byte
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
						PLA, PLP: begin	// next cycle: put real stack pointer out on address bus
							I_cycle <= 1;	// increment cycle counter
							
							S_ADL <= 1; ADL_ABL <= 1;   // output {0x01, S+1}, hold pointer
						end                             // NOTE: don't have to output 0x01 to ADH/ABH again, because ABH will hold last value
						PHA, PHP: begin	// next cycle: fetch next opcode, decrement stack pointer
							R_cycle <= 1; 	// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							D_S <= 1;												// decrement stack pointer
						end
						JSR_ABS: begin	// next cycle: push PCH on stack, store ADL in S, decrement S in ALU
							I_cycle <= 1;	// increment cycle counter
							
							PCH_DB <= 1; R_nW_int <= 0;	// output PCH (stack address is already in ABH/ABL)
							S_ADL <= 1; ADL_ADD <= 1; nONE_ADD <= 1; C_ONE <= 1; SUMS <= 1;	// decrement S in ALU
							ADD_SB <= 1; SB_S <= 1;	// store address low-byte in S (so we can store it more than 1 cycle)
						end
                        RTS, RTI: begin  // next cycle: increment stack pointer, put out stack pointer to grab PCL (RTS) or P (RTI)
                            I_cycle <= 1;   // increment cycle counter
                            
                            S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// output {0x01, S}
                            I_S <= 1;   // increment S
                        end
                        BRK: begin  // next cycle: store PCL on stack
                            I_cycle <= 1;   // increment cycle counter
                            
                            PCL_DB <= 1; R_nW_int <= 0;								// write PCL to
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// {0x01, S}
                            D_S <= 1;                                               // decrement S
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
                        AND_ABS, AND_ZPX, AND_ABX, AND_ABY: begin  // next cycle: perform and, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1;	// perform ALU and on AC, DL
                        end
                        ORA_ABS, ORA_ZPX, ORA_ABX, ORA_ABY: begin  // next cycle: perform or, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ORS <= 1;	// perform ALU or on AC, DL
                        end
                        EOR_ABS, EOR_ZPX, EOR_ABX, EOR_ABY: begin  // next cycle: perform xor, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; EORS <= 1;	// perform ALU xor on AC, DL
                        end
						LDA_ABS, LDA_ZPX, LDA_ABX, LDA_ABY: begin // next cycle: load data into AC
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;				// load data into AC
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						LDX_ABS, LDX_ZPY, LDX_ABY: begin // next cycle: load data into X
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_X <= 1;				// load data into X
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						LDY_ABS, LDY_ZPX, LDY_ABX: begin // next cycle: load data into Y
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_Y <= 1;				// load data into Y
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
                        STA_ABS, STA_ZPX, STX_ABS, STX_ZPY, STY_ABS, STY_ZPX: begin  // next cycle: fetch next opcode
                            R_cycle <= 1;
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                        end
                        CMP_ABS, CMP_ZPX, CMP_ABX, CMP_ABY: begin  // next cycle: ALU subtract, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on AC, inverted DL (set carry to 1 automatically)
                        end
						BIT_ABS: begin	// next cycle: ALU add, fetch next opcode, set flags
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1; 	// perform ALU and on AC
							
							DB7_N <= 1; DB6_V <= 1; DBZ_Z <= 1;	// set flags based on fetched memory (Z is only temporary)
						end
                        ADC_INX, SBC_INX, AND_INX, ORA_INX, EOR_INX, LDA_INX,
						STA_INX, CMP_INX: begin // next cycle: store address low-byte, fetch address high byte
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; SUMS <= 1; C_ZERO <= 1;    // send low-byte to ALU, add zero
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; Z_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send zeros to ABH                            
                        end
						ADC_INY, SBC_INY, AND_INY, ORA_INY, EOR_INY, LDA_INY,
                        CMP_INY: begin	// next cycle: if carry=1, add 1 to BAH; if carry=0, output address (skip cycle 4)
							if (carry) begin
                                S_cycle <= 1;
                                
                                DL_DB <= 1; DB_ADD <= 1; C_ONE <= 1; SUMS <= 1; // send high-byte to ALU, add 1
                            end
                            else begin
                                I_cycle <= 1;	
                            end
							
							ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send (low-byte + Y) to ABL, send high-byte to ABH
						end
						STA_INY: begin	// next cycle: read address regardless of carry, fix high-byte
							S_cycle <= 1;
							
							DL_DB <= 1; DB_ADD <= 1; C_ONE <= carry; SUMS <= 1; // send high-byte to ALU, add carry if appropriate
							
							ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;  // send (low-byte + X/Y) to ABL, send high-byte to ABH
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
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC;
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;			// store value in accumulator
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
                        PLP: begin  // next cycle: fetch next opcode, store data in status register, set flags
                            R_cycle <= 1; 	// reset cycle counter to zero
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC;
                            
                            DL_DB <= 1; DB_P <= 1;  // store value in status register
                        end
						JSR_ABS: begin	// next cycle: push PCL on stack, decrement S in ALU
							I_cycle <= 1;   // increment cycle counter
							
							PCL_DB <= 1; R_nW_int <= 0;	// output PCL
							
							ADD_ADL <= 1; ADL_ABL <= 1; // output (S-1) to ABL (ABH still 0x01)
							ADL_ADD <= 1; nONE_ADD <= 1; C_ONE <= 1; SUMS <= 1;	// decrement S again
						end
                        RTS: begin  // next cycle: put out stack pointer to grab PCH, store PCL in ALU
                            I_cycle <= 1;   // increment cycle counter
                            
                            S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// output {0x01, S}
                            
                            DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; C_ZERO <= 1; SUMS <= 1;    // store PCL in ALU
                        end
                        BRK: begin  // next cycle: store P on stack
                            I_cycle <= 1;   // increment cycle counter
                            
                            P_DB <= 1; R_nW_int <= 0;								// write P to
							S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// {0x01, S}
                            D_S <= 1;                                               // decrement S
                        end
						RTI: begin	// next cycle: store P, fetch PCL from stack
							I_cycle <= 1;   // increment cycle counter
                            
                            S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// output {0x01, S}
                            I_S <= 1;   // increment S
													
							DL_DB <= 1; DB_P <= 1;  // store value in status register
						end
                    endcase
                end
                4: begin
                    case (IR)
                        ADC_ABX, ADC_ABY, SBC_ABX, SBC_ABY, AND_ABX, AND_ABY,
                        ORA_ABX, ORA_ABY, EOR_ABX, EOR_ABY, LDA_ABX, LDA_ABY,
                        CMP_ABX, CMP_ABY, LDY_ABX, LDX_ABY: begin // next cycle: output address to fetch data
                            I_cycle <= 1;
                            
                            ADD_SB <= 1; SB_ADH <= 1; ADH_ABH <= 1; // send incremented high-byte to ABH (low-byte already in ABL)
                        end
						STA_ABX, STA_ABY: begin	// next cycle: write accumulator data to memory
							I_cycle <= 1;
							
							AC_DB <= 1; R_nW_int <= 0;
						end
                        ADC_INX, SBC_INX, AND_INX, ORA_INX, EOR_INX, LDA_INX, CMP_INX: begin  //next cycle: send out fetched address to get data
                            I_cycle <= 1;   // increment cycle counter
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send high-byte to ABH  
                        end
						STA_INX: begin	// next cycle: write accumulator data to memory
							I_cycle <= 1;
							
							ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1; // send low-byte (ALU) to ABL, send high-byte to ABH  
							
							AC_DB <= 1; R_nW_int <= 0;	// write accumulator to memory
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
                        AND_INY: begin	// there was NOT a page crossing - perform and and fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1;	// perform ALU and on AC, DL
						end
                        ORA_INY: begin	// there was NOT a page crossing - perform or and fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ORS <= 1;	// perform ALU or on AC, DL
						end
                        EOR_INY: begin	// there was NOT a page crossing - perform xor and fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; EORS <= 1;	// perform ALU xor on AC, DL
						end
						LDA_INY: begin // there was NOT a page crossing - load data into AC
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;				// load data into AC
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
                        CMP_INY: begin // next cycle: ALU subtract, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on AC, inverted DL (set carry to 1 automatically)
                        end
                        JMP_IND: begin  // next cycle: fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; ADL_PCL <= 1;   // output ADL and set PCL = ADL
                            DL_ADH <= 1; ADH_ABH <= 1; ADH_PCH <= 1;    // output ADH and set PCH = ADH
                            
                            I_PCint <= 1;                               // increment new PC
                        end
						JSR_ABS: begin	// next cycle: fetch address high-byte
							I_cycle <= 1;   // increment cycle counter
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							
							ADD_SB <= 1; SB_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; C_ZERO <= 1; SUMS <= 1;	// store S+2 in ALU
						end
                        RTS: begin  // next cycle: put out PC to grab junk (last address of JSR), increment PC to grab opcode next time
                            I_cycle <= 1;   // increment cycle counter
                            
                            DL_ADH <= 1; ADH_ABH <= 1; ADD_ADL <= 1; ADL_ABL <= 1;  // output {PCH, PCL}
                            I_PCint <= 1; ADL_PCL <= 1; ADH_PCH <= 1;  // increment PC
                        end
                        BRK: begin  // next cycle: fetch PCL from appropriate interrupt vector, clear interrupts
                            I_cycle <= 1;   // increment cycle counter
                            
                            FF_ADH <= 1; ADH_ABH <= 1;  // high byte of 1st interrupt vector always 0xFF
                            if (nmi_flag) begin
                                FA_ADL <= 1;            // if NMI, low byte is 0xFA
                                CLR_NMI <= 1; //CLR_IRQ <= 1;   // clear NMI and IRQ flags
                            end
                            else begin
                                FE_ADL <= 1;            // else, low byte is 0xFE
                                //CLR_IRQ <= 1;           // clear IRQ flag --> should this be different for a software BRK??
                            end
                            ADL_ABL <= 1;
							
							CLR_INT <= 1;	// clear do-interrupt flag
                        end
						RTI: begin	// next cycle: store PCL, fetch PCH from stack
							I_cycle <= 1;   // increment cycle counter
                            
                            S_ADL <= 1; ADL_ABL <= 1; ONE_ADH <= 1; ADH_ABH <= 1; 	// output {0x01, S}
													
							DL_DB <= 1; DB_ADD <= 1; Z_ADD <= 1; C_ZERO <= 1; SUMS <= 1;    // store PCL in ALU
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
                        AND_ABX, AND_ABY, AND_INX: begin // perform and, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1;	// perform ALU and on AC, DL
                        end
                        ORA_ABX, ORA_ABY, ORA_INX: begin // perform or, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ORS <= 1;	// perform ALU or on AC, DL
                        end
                        EOR_ABX, EOR_ABY, EOR_INX: begin // perform xor, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; EORS <= 1;	// perform ALU xor on AC, DL
                        end
						LDA_ABX, LDA_ABY, LDA_INX: begin // load data into AC
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;				// load data into AC
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						STA_ABX, STA_ABY, STA_INX: begin	// next cycle: fetch next opcode
							R_cycle <= 1;
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
						end
                        CMP_ABX, CMP_ABY, CMP_INX: begin  // next cycle: ALU subtract, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on AC, inverted DL (set carry to 1 automatically)
                        end
						LDX_ABY: begin // next cycle: load data into X
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_X <= 1;				// load data into X
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						LDY_ABX: begin // next cycle: load data into Y
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_Y <= 1;				// load data into Y
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						ADC_INY, SBC_INY, AND_INY, ORA_INY, EOR_INY, LDA_INY,
                        CMP_INY: begin	// there was a page crossing - now output (low byte + Y) and (high byte + 1) to fetch data
							I_cycle <= 1;
                            
                            ADD_SB <= 1; SB_ADH <= 1; ADH_ABH <= 1; // send incremented high-byte to ABH (low-byte+Y already in ABL)
						end
						STA_INY: begin	// next cycle: write accumulator to memory
							I_cycle <= 1;
							
							ADD_SB <= 1; SB_ADH <= 1; ADH_ABH <= 1; // send incremented high-byte to ABH (low-byte+Y already in ABL)
							
							AC_DB <= 1; R_nW_int <= 0;	// write accumulator to memory
						end
						JSR_ABS: begin	// next cycle: fetch first opcode in subroutine, save stack pointer (-2) back to S
							R_cycle <= 1;	// reset cycle counter to 0
							
							DL_ADH <= 1; ADH_ABH <= 1; S_ADL <= 1; ADL_ABL <= 1;	// output opcode address
							
							I_PCint <= 1; ADL_PCL <= 1; ADH_PCH <= 1;				// increment PC
							
							ADD_SB <= 1; SB_S <= 1;	// store twice-decremented pointer back in S
						end
                        RTS: begin  // next cycle: put out PC to grab junk (last address of JSR), increment PC to grab opcode next time
                            R_cycle <= 1;   // reset cycle counter
                            
                            PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
                        end
                        BRK: begin  // next cycle: fetch PCH, store PCL, disable interrupts
                            I_cycle <= 1;   // increment cycle counter
                            
                            PL1_ADL <= 1; ADL_ABL <= 1; // add one to previous vector to fetch PCH
                            
                            DL_DB <= 1; DB_ADD <= 1; C_ZERO <= 1; Z_ADD <= 1; SUMS <= 1;    // store PCL in ALU
                            
                            ONE_I <= 1; // set interrupt disable in P
                        end
						RTI: begin  // next cycle: put out PC to grab next opcode
                            R_cycle <= 1;   // increment cycle counter
                            
                            DL_ADH <= 1; ADH_ABH <= 1; ADD_ADL <= 1; ADL_ABL <= 1;  // output {PCH, PCL}
                            I_PCint <= 1; ADL_PCL <= 1; ADH_PCH <= 1;  // increment PC
                        end
                    endcase  
                end
				6: begin
					case (IR)
						ADC_INY: begin	// next cycle: perform add, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU add on AC, DL
						end
						SBC_INY: begin	// next cycle: perform subtraction, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1;	// perform ALU subtraction on AC, DL
						end
                        AND_INY: begin	// next cycle: perform and, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ANDS <= 1;	// perform ALU and on AC, DL
						end
                        ORA_INY: begin	// next cycle: perform or, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; ORS <= 1;	// perform ALU or on AC, DL
						end
                        EOR_INY: begin	// next cycle: perform xor, fetch next opcode
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; EORS <= 1;	// perform ALU xor on AC, DL
						end
						LDA_INY: begin // next cycle: load data into AC
							R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; DB_SB <= 1; SB_AC <= 1;				// load data into AC
							DB7_N <= 1; DBZ_Z <= 1;                                 // add result flags to status reg
						end
						STA_INY: begin	// next cycle: fetch next opcode
							R_cycle <= 1;
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
						end
                        CMP_INY: begin  // next cycle: ALU subtract, fetch next opcode
                            R_cycle <= 1;													// reset cycle counter to 0
							
							PCL_ADL <= 1; ADL_ABL <= 1; PCH_ADH <= 1; ADH_ABH <= 1;			// output PC on address bus
							I_PCint <= 1; PCL_PCL <= 1; PCH_PCH <= 1;							// increment PC
							
							DL_DB <= 1; nDB_ADD <= 1; AC_SB <= 1; SB_ADD <= 1; SUMS <= 1; C_ONE <= 1;	// perform ALU add on AC, inverted DL (set carry to 1 automatically)
                        end
                        BRK: begin  // next cycle: fetch 1st opcode of interrupt routine, store new PC
                            R_cycle <= 1;   // reset cycle counter to 0
                            
                            ADD_ADL <= 1; ADL_ABL <= 1; DL_ADH <= 1; ADH_ABH <= 1;      // output new PC
                            I_PCint <= 1; ADL_PCL <= 1; ADH_PCH <= 1;      // increment new PC
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
	
	// PC increment skipped if we're on a single-byte instruction or on first two cycles of an interrupt:
	assign I_PC = ((cycle == 1'd1 && (IR == SEC || IR == CLC || IR == INX || IR == INY || IR == DEX || IR == DEY || IR == TAX || IR == TXA ||
									 IR == TAY || IR == TYA || IR == TXS || IR == TSX || IR == PLA || IR == PLP || IR == PHP || IR == PHA ||
                                     IR == RTS || IR == BRK || IR == RTI || IR == SEI || IR == CLI || IR == CLV || IR == SED || IR == CLD)) ||
                   (R_cycle && int_flag && IR != BRK)) ? 1'd0 : I_PCint;    // does this work for a software break??
	
	// Opcode definitions:
	localparam [7:0] ADC_IMM = 8'h69, SBC_IMM = 8'he9,  AND_IMM = 8'h29, ORA_IMM = 8'h09, EOR_IMM = 8'h49,
                     ADC_ABS = 8'h6d, SBC_ABS = 8'hed,  AND_ABS = 8'h2d, ORA_ABS = 8'h0d, EOR_ABS = 8'h4d,
					 ADC_ZPG = 8'h65, SBC_ZPG = 8'he5,  AND_ZPG = 8'h25, ORA_ZPG = 8'h05, EOR_ZPG = 8'h45,
                     ADC_ZPX = 8'h75, SBC_ZPX = 8'hf5,  AND_ZPX = 8'h35, ORA_ZPX = 8'h15, EOR_ZPX = 8'h55,
                     ADC_ABX = 8'h7d, SBC_ABX = 8'hfd,  AND_ABX = 8'h3d, ORA_ABX = 8'h1d, EOR_ABX = 8'h5d,
                     ADC_ABY = 8'h79, SBC_ABY = 8'hf9,  AND_ABY = 8'h39, ORA_ABY = 8'h19, EOR_ABY = 8'h59,
                     ADC_INX = 8'h61, SBC_INX = 8'he1,  AND_INX = 8'h21, ORA_INX = 8'h01, EOR_INX = 8'h41,
                     ADC_INY = 8'h71, SBC_INY = 8'hf1,  AND_INY = 8'h31, ORA_INY = 8'h11, EOR_INY = 8'h51,
					 
					 LDA_IMM = 8'ha9, 
					 LDA_ABS = 8'had, STA_ABS = 8'h8d,
					 LDA_ZPG = 8'ha5, STA_ZPG = 8'h85,
					 LDA_ZPX = 8'hb5, STA_ZPX = 8'h95,
					 LDA_ABX = 8'hbd, STA_ABX = 8'h9d,
					 LDA_ABY = 8'hb9, STA_ABY = 8'h99,
					 LDA_INX = 8'ha1, STA_INX = 8'h81,
					 LDA_INY = 8'hb1, STA_INY = 8'h91,
					 
					 SEC = 8'h38, CLC = 8'h18, SEI = 8'h78, CLI = 8'h58, CLV = 8'hb8, SED = 8'hf8, CLD = 8'hd8,
                     
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
