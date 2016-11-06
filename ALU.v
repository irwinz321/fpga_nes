`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:53:16 05/21/2016 
// Design Name: 
// Module Name:    ALU 
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
module ALU(  
    input wire SUM_en, AND_en, EOR_en, OR_en, SR_en, INV_en,	// Operation control
    input wire [7:0] Ain, Bin, 									// Data inputs
	input wire Cin, 											// Carry in
	output reg [7:0] RES,										// Operation result
    output reg Cout, 											// Carry out
	output wire OVFout											// Overflow out
    );
	
	// Declare signals:
	wire [7:0] Bint;
	 
	// Select inverted or non-inverted B input:
    assign Bint = INV_en ? ~Bin : Bin;
    
	// Perform requested operation:
    always @(*) begin
	 
		// Defaults:
		RES = 0;
		Cout = 0;
		
		// Operations:
        if (SUM_en)
			{Cout, RES} = Ain + Bint + Cin;	// add with carry-in, carry-out
        else if (AND_en)
            RES = Ain & Bin;				// and
        else if (EOR_en)
            RES = Ain ^ Bin;				// xor
        else if (OR_en)
            RES = Ain | Bin;				// or
        else if (SR_en)
            {RES, Cout} = Ain >> 1;			// shift right with carry-out
		
    end
	
	// Set overflow flag (set if both inputs are same sign, but output is a different sign):
	assign OVFout = (Ain[7] && Bin[7] && (!RES[7])) || ((!Ain[7]) && (!Bin[7]) && RES[7]);		// TODO: check this - also, Bin probably needs to take Cin into account for 2s comp.
	//assign OVFout = (Ain[7] ~^ Bint[7]) & (Cout ^ RES[7]);
	 
endmodule