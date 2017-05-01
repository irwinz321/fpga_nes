`timescale 1ns / 1ps
/***********************************************************************
* Program counter for the MOS 6502 processor. Keeps track of the location
* of the current and next program byte in memory. In normal operation, it
* will keep incrementing the instruction pointer to fetch the next byte. Since
* the 6502 has a 16-bit address space, the program counter has 2 8-bit registers,
* a low and high byte (PCL and PCH).
*
* It can also be loaded with a new arbitrary location (in the case of branch,
* jump, etc.), and will increment starting from that point. The new address
* gets latched on phase 2.
*
* Written by Zach Irwin. Edited 4/29/2017.
*
************************************************************************/
module ProgramCounter(
	input wire sys_clock, rst,		    // Main system clock and reset
    input wire clk_ph2,				    // Phase 2 clock enable
	input wire [7:0] ADLin, ADHin,	    // Address Bus low & high bytes
	input wire INC_en, 				    // Increment PC enable
	input wire PCLin_en, PCHin_en,	    // Use current PC
	input wire ADLin_en, ADHin_en,	    // Load new value into PC
	output wire [7:0] PCLout, PCHout    // PC Bus output
    );
	

// Declare signals:
reg [7:0] PCL, PCH;			// PC register low & high bytes
reg [7:0] PCLS, PCHS;		// PC select register low & high bytes
reg PCLC;					// PC low-byte carry bit (to increment high-byte)
reg [7:0] PCL_inc, PCH_inc;	// Incremented PC

// Select PC source: previous PC or new value from Address Bus:
always @(*) begin
	
	if (PCLin_en)
		PCLS <= PCL;		// load previous PC register value
	else if (ADLin_en)
		PCLS <= ADLin;		// load address bus value
	else
		PCLS <= PCL;		// default: previous PC
		
	if (PCHin_en)
		PCHS <= PCH;		// load previous PC register value
	else if (ADHin_en)
		PCHS <= ADHin;		// load address bus value
	else
		PCHS <= PCH;		// default: previous PC
		
end

// Increment PC:
always @(*) begin

	{PCLC, PCL_inc} = PCLS + 1'd1;	// Increment low-byte with carry out
	PCH_inc = PCHS + PCLC;		    // Increment high-byte with carry from PCL
	
end

// Latch PC on phase 2 clock:
always @(posedge sys_clock) begin
	
	if (rst == 0) begin			// initialize PC to zero (will be replaced)
		PCL <= 0;
		PCH <= 0;
	end
	else if (clk_ph2) begin
		if (INC_en) begin		// if Increment enabled, latch incremented PC
			PCL <= PCL_inc;
			PCH <= PCH_inc;
		end
		else begin				// else, latch passed-through value
			PCL <= PCLS;
			PCH <= PCHS;
		end
	end
		
end

// Assign outputs:
assign PCLout = PCL;
assign PCHout = PCH;


endmodule
