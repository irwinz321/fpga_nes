`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:25:53 02/24/2017 
// Design Name: 
// Module Name:    FIFO 
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
module FIFO
	#(
      parameter d_width = 8,        // width of data entries (8 bit default)
      parameter d_depth = 32,       // depth of data entries (32 default)
      parameter a_width = 5         // width of data addresses (log(32) default)
     )
    (
      input clk, rst,               		// clock, reset
      input rd, wr, [d_width-1:0] data_in,  // read/write enable, data to store
      output reg [d_width-1:0] data_out,    // read data
      output full, empty,           		// buffer status
      output reg err_ovf, err_unf   		// overflow/underflow error flags
     );
     
// Define buffer container and read/write pointers:
reg [d_width-1:0] buffer [d_depth-1:0];
reg [a_width-1:0] rd_ptr = 0;
reg [a_width-1:0] wr_ptr = 0;

// Define buffer status:
reg [a_width-1:0] buff_cnt = 0;   // number of elements currently stored (<= d_depth)

// Set status flags:
assign full = buff_cnt == d_depth - 1;
assign empty = buff_cnt == 0;

// Detect positive edge on read/write enable (to avoid double-reading/writing):
reg rd_delay = 0, wr_delay = 0;
wire rd_int, wr_int;
always @(posedge clk) begin
	if (rst == 0) begin
		rd_delay <= 0;
		wr_delay <= 0;
	end
	else begin
		rd_delay <= rd;
		wr_delay <= wr;
	end
end
assign rd_int = (rd & !rd_delay);
assign wr_int = (wr & !wr_delay);

// Read/write from buffer:
always @(posedge clk) begin

    err_ovf <= 0;
	err_unf <= 0;

    if (rst == 0) begin
    
        rd_ptr <= 0;
        wr_ptr <= 0;
		buff_cnt <= 0;
		err_ovf <= 0;
		err_unf <= 0;
        
    end
    else begin
        
        if (full) begin
            if (wr_int && rd_int) begin //successful write and read - no size change
                data_out <= buffer[rd_ptr];
                if (rd_ptr + 1 == d_depth)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'd1;
                
                buffer[wr_ptr] <= data_in;
                if (wr_ptr + 1 == d_depth)
                    wr_ptr <= 0;
                else
                    wr_ptr <= (wr_ptr + 1'd1);
            end
            else begin  
                if (rd_int) begin   //successful read - size decrement
                    data_out <= buffer[rd_ptr];
                    if (rd_ptr + 1 == d_depth)
                        rd_ptr <= 0;
                    else
                        rd_ptr <= rd_ptr + 1'd1;
						
					buff_cnt <= buff_cnt - 1'd1;
                end
				else if (wr_int) begin	//unsuccessful write - overflow
					err_ovf <= 1;
				end
            end
            
        end
        else if (empty) begin
            if (rd_int && wr_int) begin //successful write and read - no size change
                data_out <= data_in;
            end
            else begin  
                if (wr_int) begin   //successful write - size increment
                    buffer[wr_ptr] <= data_in;
                    if (wr_ptr + 1 == d_depth)
                        wr_ptr <= 0;
                    else
                        wr_ptr <= (wr_ptr + 1'd1);
						
					buff_cnt <= buff_cnt + 1'd1;
                end
				else if (rd_int) begin	//unsuccessful read - underflow
					data_out <= 0;
					err_unf <= 1;
				end
            end
        end
        else begin
            if (wr_int) begin   //successful write - size increment
                buffer[wr_ptr] <= data_in;
                if (wr_ptr + 1 == d_depth)
                    wr_ptr <= 0;
                else
                    wr_ptr <= (wr_ptr + 1'd1);
					
            end
            if (rd_int) begin   //successful read - size decrement
                data_out <= buffer[rd_ptr];
                if (rd_ptr + 1 == d_depth)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'd1;
					
            end
			
			if (rd_int && !wr_int)
				buff_cnt <= buff_cnt - 1'd1;
			else if (wr_int && !rd_int)
				buff_cnt <= buff_cnt + 1'd1;
        end
        
    end
    
end

endmodule
