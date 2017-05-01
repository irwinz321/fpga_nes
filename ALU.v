`timescale 1ns / 1ps
/***********************************************************************
* Arithmetic and Logic Unit for the MOS 6502 processor. Performs 6 
* intrinsic operations (add, and, or, exclusive-or, shift right, and
* rotate right). The add function can be used to subtract by inverting
* the input. 
*
* The ALU has a carry in and carry out bit to perform >8 bit operations. 
* For an add op, carry is set if the (unsigned) result is >255, and cleared 
* otherwise. For a subtract op, carry is interpreted as a borrow bit - so 
* it is cleared if the (signed) result is less than zero, and set otherwise.
* As a note, the ALU doesn't care about all this, it calculates things the
* same way regardless (other than inverting the B input if subtracting. It 
* relies on the programmer to set or clear the carry input as needed for the 
* correct operation. It just so happens that the math works out for both 
* signed and unsigned operation (for add and subtract).
*
* The ALU also computes an overflow bit, which detects whether an operation 
* results in a number that can't fit in a signed byte. So basically, if both
* inputs (after inverting B if necessary) are the same sign, overflow will be
* set if the result is a different sign. For example, 127+1=-128. Note that
* this can't happen if the inputs are of different signs, since the result
* will always be less than the inputs, and will therefore fit in a signed byte.
*
* Written by Zach Irwin. Edited 4/29/2017.
*
************************************************************************/
module ALU(  
    input wire SUM_en, AND_en, EOR_en, OR_en, SR_en, INV_en, ROR_en, // Operation control
    input wire [7:0] Ain, Bin, 									     // Data inputs
	input wire Cin, 											     // Carry in
	output reg [7:0] RES,										     // Operation result
    output reg Cout, 											     // Carry out
	output wire OVFout											     // Overflow out
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
			{Cout, RES} = Ain + Bint + Cin;	    // add with carry-in, carry-out
        else if (AND_en)
            RES = Ain & Bin;				    // and
        else if (EOR_en)
            RES = Ain ^ Bin;				    // xor
        else if (OR_en)
            RES = Ain | Bin;				    // or
        else if (SR_en)
            {RES, Cout} = {Ain,1'd0} >> 1;	    // shift right with carry-out
		else if (ROR_en)
			{RES, Cout} = {Cin,Ain,1'd0} >> 1;	// shift right with carry-in, carry-out
		
    end
	
	// Set overflow flag (set if both inputs are same sign, but output is a different sign):
    assign OVFout = (Ain[7] && Bint[7] && (!RES[7])) || ((!Ain[7]) && (!Bint[7]) && RES[7]);
	 
endmodule