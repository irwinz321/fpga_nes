`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:49:06 09/17/2016 
// Design Name: 
// Module Name:    CPU 
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
module CPU(
	input clk_ph1, clk_ph2,		// Clock phases - this will change to a single clock... eventually.
	input rst,					// System reset
	input [7:0] Data_bus,		// Output Data Bus
	output [15:0] Addr_bus,   	// Output Address Bus
    output [7:0] IR_dbg, AC_dbg, X_dbg, Y_dbg, P_dbg, S_dbg,
    output [15:0] PC_dbg,
    output [2:0] cycle_dbg
    );
	
	// Signal declarations:
	wire I_cycle, R_cycle, DL_DB, AC_SB, ADD_SB, PCL_ADL, PCH_ADH, SB_AC, ADL_ABL, ADH_ABH, I_PC, PCL_PCL, PCH_PCH, SB_ADD, nDB_ADD, DB_ADD, SUMS,
			ACR_C, AVR_V, SB_DB, DBZ_Z, DB7_N, IR5_C, Z_ADD, ADD_ADL, DL_ADH, DL_ADL, Z_ADH, SB_X, SB_Y, X_SB, Y_SB, C_ONE, nONE_ADD, AC_DB, ADL_ADD,
            S_cycle, SB_ADH, C_ZERO, DB_SB, ADL_PCL, ADH_PCH, PCH_DB, SB_S, I_S, D_S;	// control lines
	wire [7:0] IR;							// instruction register
	wire [2:0] cycle;						// cycle counter
	wire [7:0] PCL, PCH;					// program counter high and low byte registers
	wire [7:0] DB, SB, ADL, ADH;			// internal busses (data bus, system bus, address bus low and high)
	wire [7:0] AI, BI, ALU_result;			// ALU signals (Ainput, Binput, result)
	wire C, OVF;							// ALU result flags (carry, overflow)
    wire CI;                               // ALU carry in - allows bit to be set to 1 for incrementing
	reg Creg, OVFreg;						// ALU reslt flags (carry, overflow) - registers to latch wire values until storage
	reg [7:0] PD, DL, AC, ADD, ABL, ABH,    // top-level registers (pre-decode, data latch, accumulator, adder hold, output address bus low and high)
              P, X, Y, S;                  	// top-level registers (CPU status, X index, Y index, stack pointer)
	
	// Select inputs to internal busses:
	assign SB = AC_SB ? AC : (ADD_SB ? ADD : (X_SB ? X : (Y_SB ? Y : 8'd0)));   // Select System Bus input (AC, ADD, X, Y, ...)
	assign DB = DL_DB ? DL : (AC_DB ? AC : (SB_DB ? SB : (PCH_DB ? PCH : 8'd0)));	            // Select Data Bus input (DL, AC, SB, ...)
	assign ADL = PCL_ADL ? PCL : (ADD_ADL ? ADD : (DL_ADL ? DL : 8'd0));		// Select Address Low Bus input (PCL, ADD, DL, ...)
	assign ADH = Z_ADH ? 8'd0 : (PCH_ADH ? PCH : (DL_ADH ? DL : ((SB_ADH & DB_SB) ? DB : (SB_ADH ? SB : 8'd0))));	// Select Address High Bus input (ZERO, PCH, DL, SB...)
	
	// Select ALU inputs:
	assign AI = Z_ADD ? 8'd0 : (nONE_ADD ? 8'hfe : ((SB_ADD & DB_SB) ? DB : (SB_ADD ? SB : 8'd0)));    // Select ALU input A (ZERO, 0xFE, SB, DB when SB/DB connected)
	assign BI = (DB_ADD || nDB_ADD) ? DB : (ADL_ADD ? ADL : 8'd0);	    // Select ALU input B (DB, ADL)
    assign CI = C_ONE ? 1'd1 : (C_ZERO ? 1'd0 : P[0]);                    // Select ALU carry input (ONE, ZERO, or status reg carry)
	
	
	// Latch registers on phase 1:
	always @(posedge clk_ph1) begin
		if (rst == 0) begin
			AC <= 8'd0;
			ABL <= 8'd0;
			ABH <= 8'd0;
			P <= 8'd0;
            X <= 8'd0;
            Y <= 8'd0;
            S <= 8'hff;
		end
		else begin
			AC <= (SB_AC & DB_SB) ? DB : (SB_AC ? SB : AC);			// AC has inputs from SB, DB when SB/DB connected
            
			ABL <= (ADL_ABL ? ADL : ABL);		// ABL has inputs from ADL only	- holds value otherwise
			ABH <= (ADH_ABH ? ADH : ABH);		// ABH has inputs from ADH only - holds value otherwise
            
			P[0] <= (ACR_C ? Creg : (IR5_C ? IR[5] : P[0]));    // Status reg bit 0 - carry flag
			P[1] <= (DBZ_Z ? (~| DB) : P[1]);	                // Status reg bit 1 - zero flag
			//P[2]								                // Status reg bit 2 - interrupt disable flag
			//P[3]								                // Status reg bit 3 - decimal mode flag (setting/clearing does nothing for NES Ricoh CPU)
			//P[4]								                // Status reg bit 4 - break flag
			P[5] <= 1'd1;						                // Status reg bit 5 - expansion flag (not used)
			P[6] <= (AVR_V ? OVFreg : P[6]);	                // Status reg bit 6 - overflow flag
			P[7] <=	(DB7_N ? DB[7] : P[7]);		                // Status reg bit 7 - negative/sign flag
            
            X <= (SB_X & DB_SB) ? DB : (SB_X ? SB : X);         // X Index has inputs from SB (or DB when SB/DB are connected) - holds value otherwise
            Y <= (SB_Y & DB_SB) ? DB : (SB_Y ? SB : Y);         // Y Index has inputs from SB (or DB when SB/DB are connected) - holds value otherwise
            
            S <= I_S ? S + 8'h01 : (D_S ? S - 8'h01 : (SB_S ? SB : S)); // Stack point can be incremented/decremented, or get input from SB - holds otherwise
		end		
	end
	
	// Latch registers on phase 2:
	always @(posedge clk_ph2) begin
		if (rst == 0) begin
			PD <= 0;
			DL <= 0;
			ADD <= 0;
			Creg <= 0;
			OVFreg <= 0;
		end
		else begin
			PD <= Data_bus;		// input data gets latched to PD automatically
			DL <= Data_bus;		// input data gets latched to DL automatically
			ADD <= ALU_result;	// alu result stored in ADD
			Creg <= C;			// alu carry flag latched for storage in P next cycle
			OVFreg <= OVF;		// alu overflow flag latched for storage in P next cycle
		end
	end
	
	// Instruction controller sets IR and Cycle Counter:
	InstructionController ic (.rst(rst), .clk_ph1(clk_ph1), .I_cycle(I_cycle), .R_cycle(R_cycle), .S_cycle(S_cycle), .PD(PD), .IR(IR), .cycle(cycle));
	
	// Instruction decoder uses IR and Cycle counter to determine which control lines active on NEXT cycle:
	InstructionDecoder id (.clk_ph2(clk_ph2), .rst(rst), .cycle(cycle), .IR(IR), .I_cycle(I_cycle), .R_cycle(R_cycle), .carry(C), .A_sign(AI[7]), .P(P),
						   .DL_DB(DL_DB), .AC_SB(AC_SB), .ADD_SB(ADD_SB), .PCL_ADL(PCL_ADL), .PCH_ADH(PCH_ADH), .SB_AC(SB_AC), .ADL_ABL(ADL_ABL), .ADH_ABH(ADH_ABH), 
						   .I_PC(I_PC), .PCL_PCL(PCL_PCL), .PCH_PCH(PCH_PCH), .SB_ADD(SB_ADD), .nDB_ADD(nDB_ADD), .DB_ADD(DB_ADD), .SUMS(SUMS), .AVR_V(AVR_V), .ACR_C(ACR_C),
						   .DBZ_Z(DBZ_Z), .SB_DB(SB_DB), .DB7_N(DB7_N), .IR5_C(IR5_C), .Z_ADD(Z_ADD), .ADD_ADL(ADD_ADL), .DL_ADH(DL_ADH), .DL_ADL(DL_ADL), .Z_ADH(Z_ADH),
                           .X_SB(X_SB), .Y_SB(Y_SB), .SB_X(SB_X), .SB_Y(SB_Y), .C_ONE(C_ONE), .nONE_ADD(nONE_ADD), .AC_DB(AC_DB), .S_cycle(S_cycle), .SB_ADH(SB_ADH),
						   .ADL_ADD(ADL_ADD), .C_ZERO(C_ZERO), .DB_SB(DB_SB), .ADL_PCL(ADL_PCL), .ADH_PCH(ADH_PCH), .PCH_DB(PCH_DB), .SB_S(SB_S), .I_S(I_S), .D_S(D_S));
						   
	// Program counter sets current... program counter: 					   
	ProgramCounter pc (.rst(rst), .CLOCK_ph2(clk_ph2), .ADLin(ADL), .ADHin(ADH), .INC_en(I_PC), .PCLin_en(PCL_PCL), .PCHin_en(PCH_PCH),
					   .ADLin_en(ADL_PCL), .ADHin_en(ADH_PCH), .PCLout(PCL), .PCHout(PCH));
	
	// Arithmetic and logic unit performs all operations:
	ALU alu (.SUM_en(SUMS), .AND_en(1'd0), .EOR_en(1'd0), .OR_en(1'd0), .SR_en(1'd0), .INV_en(nDB_ADD),
			 .Ain(AI), .Bin(BI), .Cin(CI), .RES(ALU_result), .Cout(C), .OVFout(OVF));
		
	// Set CPU outputs:
	assign Addr_bus = {ABH, ABL};	// Address Bus
	
	
	
	// purely for viewing signals in simulation
    assign IR_dbg = IR;
    assign AC_dbg = AC;
    assign cycle_dbg = cycle;
    assign PC_dbg = {PCH, PCL};
	assign X_dbg = X;
	assign Y_dbg = Y;
	assign P_dbg = P;
    assign S_dbg = S;

endmodule
