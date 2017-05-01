`timescale 1ns / 1ps
/***********************************************************************
* Instruction and cycle controller. Keeps track of the current and upcoming
* CPU cycles during execution of the current instruction. Also takes care
* of loading in new instructions at the appropriate time. Finally, it also
* inserts a BRK instruction when interrupts are detected, in order to start
* off the interrupt service routine.
*
* Written by Zach Irwin. Edited 4/30/2017.
*
************************************************************************/
module InstructionController(
	input sys_clock, rst,	         // Main system clock and reset
    input clk_ph1,			         // clock phase 1
    input [7:0] PD,			         // pre-decode register
    input I_cycle, R_cycle, S_cycle, // increment/reset/skip cycle counter lines
    input int_flag,                  // perform interrupt
    output reg [7:0] IR,             // instruction register
    output reg [2:0] cycle,          // current instruction cycle
    output [2:0] next_cycle          // next instruction cycle
    );
    
// Signal declarations:
wire [7:0] opcode;      // Opcode to put into instruction register
    
// Decide what the next cycle count should be:
assign next_cycle = (R_cycle == 1) ? 3'd0                                             // if reset_cycle, reset count to 0
                                   : (I_cycle == 1) ? cycle + 3'd1                    // else, if increment_cycle, increment count
                                                    : (S_cycle == 1) ? cycle + 3'd2   // else, if skip_cycle, increment count twice
                                                                     : cycle;         // else, don't change count
    
// Decide what gets loaded into the instruction register (change only on T1 cycle):
assign opcode = (next_cycle == 1) ? (int_flag ? 8'd0 : PD)  // on next T1, load new opcode or BRK (0) if doing an interrupt
                                  : IR;                     // if not T1 cycle, keep last opcode
    
// Latch new values on ph1:
always @(posedge sys_clock) begin

	if (rst == 0) begin
		cycle <= 0;				// Reset cycle counter to 0
		IR <= 0;				// Reset IR - starts out in BRK to start reset routine
	end
	else if (clk_ph1) begin
		cycle <= next_cycle;    // Latch cycle    
        IR <= opcode;           // Latch opcode
	end
    
end
    
endmodule
