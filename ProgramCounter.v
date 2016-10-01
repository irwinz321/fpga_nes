`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:23:32 05/27/2016 
// Design Name: 
// Module Name:    ProgramCounter 
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
module ProgramCounter(
	input wire rst, 					// Reset signal
	input wire [7:0] ADLin, ADHin,		// Address Bus low & high bytes
	input wire INC_en, 					// Increment PC enable
	input wire PCLin_en, PCHin_en,		// PCLS = PC enable -> program counter feedback
	input wire ADLin_en, ADHin_en,		// PCLS = AD enable -> program counter load value
	input wire CLOCK_ph2,				// System clock (phase 2)
	output wire [7:0] PCLout, PCHout	// PC Bus output
    );
	

// Declare signals:
reg [7:0] PCL, PCH;			// PC register low & high bytes - init to 1st instruction addr.
reg [7:0] PCLS, PCHS;		// PC select register low & high bytes
reg PCLC;					// PC low-byte carry bit
reg [7:0] PCL_inc, PCH_inc;	// Incremented PC

// Select PC source: previous PC or new value from Address Bus:
always @(*) begin
	
	if (PCLin_en)
		PCLS <= PCL;		// load previous PC register value
	else if (ADLin_en)
		PCLS <= ADLin;		// load address bus value
	else
		PCLS <= PCL;		// default: previous PC - should never happen?
		
	if (PCHin_en)
		PCHS <= PCH;		// load previous PC register value
	else if (ADHin_en)
		PCHS <= ADHin;		// load address bus value
	else
		PCHS <= PCH;		// default: previous PC - should never happen?
		
end

// Increment PC:
always @(*) begin

	{PCLC, PCL_inc} = PCLS + 1;	// Increment low-byte with carry out
	PCH_inc = PCHS + PCLC;		// Increment high-byte with carry in
	
end

// Latch PC on phase 2 clock:
always @(posedge CLOCK_ph2) begin
	
	if (rst == 0) begin			// initialize PC to 1st instruction address
		PCL <= 0;
		PCH <= 0;
	end
	else begin
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
