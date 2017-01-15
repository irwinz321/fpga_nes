`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:32:27 12/10/2016 
// Design Name: 
// Module Name:    InterruptController 
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
module InterruptController(
	input clk_ph1, clk_ph2,			// Clock phases 
	input rst, irq, nmi,			// System reset, IRQ (active low), NMI (active low)
	input int_clr, nmi_clr, irq_mask,		// Clear perform-interrupt flag, clear NMI-pending flag, IRQ mask bit
    input [3:0] cycle, next_cycle,     // Current and next instruction cycles
    input [7:0] IR,                      // Current instruction
	output reg irq_out, nmi_out, int_out	// Flags for pending IRQ/NMI and perform-interrupt signal outputs
    );


	// Signal declarations:
	reg irq_det, nmi_det, nmi_pre;	// IRQ detection, NMI detection, NMI previous value (for edge detection)
    //reg irq_int, nmi_int;           // Internal latches for IRQ and NMI detection
    wire branch;                    // Flag to indicate if current opcode is a branch
    
	// Detect external interrupts on Phi2:
	always @(posedge clk_ph2) begin
        
		irq_det <= 0;						// IRQ gets reset every cycle
		nmi_pre <= nmi;						// Latch old NMI value for edge detection
		
		if (rst == 0) begin					// Default values
			irq_det <= 0;
			nmi_det <= 0;
			nmi_pre <= 1;
		end
		else begin
			irq_det <= !irq && !irq_mask;								// Level detection - only if not masked	
			nmi_det <= nmi_clr ? 1'd0 : (!nmi && nmi_pre) ? 1'd1 : nmi_det;	// Edge detection - stays high until cleared 
		end
		
	end
	
	// Set internal latches on Phi1:
	always @(posedge clk_ph1) begin
    
        if (rst == 0) begin         // Default values
            irq_out <= 0;
            nmi_out <= 0;
        end
        else begin	
            irq_out <= irq_det;     // Change value on Phi1
            nmi_out <= nmi_det;     // Change value on Phi1
        end
	end
    
    // Set flags if current opcode is a branch instruction:
    assign branch = (IR == BPL || IR == BMI || IR == BVC || IR == BVS || IR == BCC || IR == BCS || IR == BNE || IR == BEQ);
    
    // Poll internal latch status on Phi1 of certain cycles:
    //  -> technically should be Phi2, but to get the timing right, we'll do it on the next Phi1
    always @(posedge clk_ph1) begin
        
        if (rst == 0 || int_clr) begin
            //irq_out <= 0;
            //nmi_out <= 0;
			int_out <= 0;
        end
        else if ((IR != BRK) && ((next_cycle == 0 && !(branch && cycle == 2)) || (next_cycle == 2 && branch))) begin
           // irq_out <= irq_clr ? 1'd0 : (irq_int ? 1'd1 : irq_out);
            //nmi_out <= nmi_clr ? 1'd0 : (nmi_int ? 1'd1 : nmi_out);
			int_out <= int_clr ? 1'd0 : ((irq_out || nmi_out) ? 1'd1 : int_out);
        end
    end
    
    
	
	// Opcode definitions:
	localparam [7:0] BPL = 8'h10, BMI = 8'h30, BVC = 8'h50, BVS = 8'h70, BCC = 8'h90, BCS = 8'hb0, BNE = 8'hd0, BEQ = 8'hf0, BRK = 8'h00;

endmodule
