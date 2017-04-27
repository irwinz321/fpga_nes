`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:09:27 01/21/2017 
// Design Name: 
// Module Name:    UART 
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
module UART 
  #(parameter NUM_BITS = 8,		// number of data bits in a transmission
	parameter STOP_BIT = 1,		// number of stop bits to transmit
	parameter BAUD_RATE = 19200	// UART baud rate (min: 14400)
   )			
   (input reset,			// system reset (active low)
	input sys_clk,			// master system clock (100 MHz)
	input [7:0] tx_data,	// data byte to be transmitted
	input tx_enable,		// flag to send data (transient, not held)
	input rx_enable,		// flag to enable receiving
	input rx_in,			// rx input (from serial port)
	output tx_busy,			// flag to indicate transmitting
	output rx_busy,			// flag to indicate receiving
	output tx_out,			// tx output (to serial port)
    output rx_done,         // flag to indicate a byte was received
	output [7:0] rx_out		// rx output (received byte)
    );
    

/**** Clock generation logic ****/

localparam rx_clk_div = 100000000/(8*BAUD_RATE);	// calculate divider from specified baud rate
reg [9:0] rx_div_cnt = 0;	// counter to divide sys_clk
reg [2:0] tx_div_cnt = 0;	// counter to divide rx_clk
reg rx_clk_en = 0;			// rx clock enable = 8 * baud rate
reg tx_clk_en = 0;			// tx clock enable = baud rate

// Generate RX clock (at specified 8x baud rate):
always @(posedge sys_clk) begin

	if (reset == 0) begin							// reset count, clock enable
		rx_div_cnt <= 0;
		rx_clk_en <= 0;
	end
	else begin
		if (rx_div_cnt == (rx_clk_div - 1)) begin	// set rx_clk_en high after count reached
			rx_clk_en <= 1;
			rx_div_cnt <= 0;
		end
		else begin									// increment rx_clk divider, reset rx_clk_en
			rx_clk_en <= 0;
			rx_div_cnt <= rx_div_cnt + 1'd1;
		end
	end
	
end

// Generate TX clock (RX clock divided by 8):
always @(posedge sys_clk) begin

	if (reset == 0) begin						// reset count, clock enable
		tx_div_cnt <= 0;
		tx_clk_en <= 0;
	end
	else if (rx_clk_en) begin					// divide rx clock
		if (tx_div_cnt == 7) begin				// set tx_clk_en high after count reached
			tx_div_cnt <= 0;		
			tx_clk_en <= 1;			
		end
		else begin								// increment tx_clk divider, reset tx_clk_en
			tx_div_cnt <= tx_div_cnt + 1'd1;	
			tx_clk_en <= 0;			
		end
	end
	else begin									// make sure tx_clk_en is only high for 1 sys clock
		tx_clk_en <= 0;
	end
	
end


/**** Receive logic ****/

// RX state declaration:
localparam [2:0] RX_IDLE = 3'd0,	// idle state
                 RX_START = 3'd1,	// check start bit
                 RX_WAIT = 3'd2,	// wait for next bit	
                 RX_RECV = 3'd3,	// sample current bit
                 RX_DONE = 3'd4;	// RX complete
				 
// RX variable declarations:
reg [3:0] rx_bit_cnt = 0;		// count bits received
reg [2:0] rx_smp_cnt = 0;		// count samples of each bit
reg [2:0] rx_smp = 0;       	// actual samples of each bit
reg [2:0] rx_state = RX_IDLE;	// current RX state
reg [7:0] rx_data = 0;			// received data

// RX state machine:
always @(posedge sys_clk) begin

    if (reset == 0) begin												// reset state machine
        rx_bit_cnt <= 0;
        rx_smp_cnt <= 0;
		rx_smp <= 0;
		rx_state <= RX_IDLE;
		rx_data <= 0;
    end
    else if (rx_clk_en) begin											// operate on RX clock
    
        case (rx_state)
		
            RX_IDLE: begin
                if (rx_enable && !rx_in) begin							// detect start bit
                    rx_state <= RX_START;
                    rx_smp_cnt <= 1'd1;
                    rx_smp <= 1'd1;
                end
            end
            RX_START: begin												// validate start bit with 5 samples
                if (rx_smp_cnt == 4) begin  	
                    if (rx_smp >= 3) begin    							// valid start bit = 3/5 samples low
                        rx_state <= RX_WAIT;							// if valid, wait for next bit time
                    end
                    else begin
                        rx_state <= RX_IDLE;							// if not valid, go back to idle
                    end
                    rx_smp_cnt <= 0;
                    rx_smp <= 0;
                end
                else begin  											// sample RX line, increment count
                    rx_smp_cnt <= rx_smp_cnt + 1'd1;
                    rx_smp <= rx_smp + !rx_in;
                end
                
            end
            RX_WAIT: begin												// wait for next bit time (4 clocks)
                if (rx_smp_cnt == 3) begin
                    rx_state <= RX_RECV;								// once wait is done, start sampling bit
                    rx_smp_cnt <= 0;
                end
                else begin												// increment count
                    rx_smp_cnt <= rx_smp_cnt + 1'd1;
                end
            end
            RX_RECV: begin												// sample current bit 4x
                if (rx_smp_cnt == 3) begin
					if (rx_bit_cnt < NUM_BITS) begin					// store data bit
						rx_data[rx_bit_cnt] <= ((rx_smp + rx_in) > 2);	// data bit = high if 3/4 samples high
						rx_bit_cnt <= rx_bit_cnt + 1'd1;
						rx_state <= RX_WAIT;							// move back to wait for next bit
					end
					else if (rx_bit_cnt < (NUM_BITS+STOP_BIT-1)) begin	// wait for stop bits (no storage)
						rx_bit_cnt <= rx_bit_cnt + 1'd1;
						rx_state <= RX_WAIT;
					end
					else begin											// once past data+stop bits, we're done
						rx_state <= RX_DONE;
					end
                    rx_smp_cnt <= 0;
                    rx_smp <= 0;
                end
                else begin												// sample bit value, increment count
                    rx_smp_cnt <= rx_smp_cnt + 1'd1;
                    rx_smp <= rx_smp + rx_in;
                end
            end
            RX_DONE: begin												// done with RX, go back to idle
                rx_state <= RX_IDLE;
                rx_bit_cnt <= 0;
                rx_smp_cnt <= 0;
                rx_smp <= 0;
            end
			
		endcase
		
    end
    
end


/**** Transmit clock enable generation logic ****/

// TX state declaration:
localparam [1:0] TX_IDLE = 2'd0,	// idle state
				 TX_DATA = 2'd1,	// send data bits
				 TX_STOP = 2'd2,	// send stop bits
				 TX_DONE = 2'd3;	// done with transmission

// TX variable declarations:				 
reg [3:0] tx_bit_cnt = 0;		// count bits transmitted
reg [7:0] tx_data_int = 0;		// data byte to be transmitted 
reg tx_out_int = 1;				// current output bit
reg [1:0] tx_state = TX_IDLE;	// current TX state
reg tx_start = 0;				// latched signal to start transmission

// Latch tx_enable signal until transmission starts:
always @(posedge sys_clk) begin

	if (reset == 0) begin											// reset start signal and data
		tx_start <= 0;
		tx_data_int <= 0;
	end
	else if (tx_state == TX_IDLE && tx_enable && !tx_start) begin	// latch enable and current data
		tx_start <= 1;
		tx_data_int <= tx_data;
	end
	else if (tx_state == TX_DATA && tx_start && tx_bit_cnt == 0) begin
		tx_start <= 0;
	end
	//else if (tx_busy) begin											// reset start signal during tx
	//	tx_start <= 0;
	//end
	
end

// TX state machine:
always @(posedge sys_clk) begin

    if (reset == 0) begin								// reset state machine
        tx_bit_cnt <= 0;
		tx_state <= TX_IDLE;
		tx_out_int <= 1;
    end
    else if (tx_clk_en) begin							// operate on TX clock
    
        case (tx_state)
		
            TX_IDLE: begin								// wait for start signal
				if (tx_start) begin						// pull line low for start	
					tx_state <= TX_DATA;
					tx_out_int <= 0;			
					tx_bit_cnt <= 0;				
				end
				else begin								// keep line high during idle
					tx_out_int <= 1;			
				end
			end
			TX_DATA: begin								// transmit data bits
				tx_out_int <= tx_data_int[tx_bit_cnt];	// send nth data bit
				if (tx_bit_cnt == (NUM_BITS-1)) begin	// if on last bit, move to stop state
					tx_state <= TX_STOP;
					tx_bit_cnt <= 0;
				end
				else begin								// increment bit count
					tx_bit_cnt <= tx_bit_cnt + 1'd1;	
				end
			end
			TX_STOP: begin								// transmit stop bits
				tx_out_int <= 1;						// pull line high for stop
				if (tx_bit_cnt == (STOP_BIT-1)) begin	// if on last stop bit, move to done state
					tx_state <= TX_DONE;
				end
				else begin
					tx_bit_cnt <= tx_bit_cnt + 1'd1;	// increment bit count
				end
			end
			TX_DONE: begin								// reset state back to idle
				tx_state <= TX_IDLE;
				tx_bit_cnt <= 0;
				tx_out_int <= 1;
			end
		endcase
		
	end
end


/**** Assign outputs: ****/

assign tx_out = tx_out_int;					// current output on TX line
assign tx_busy = (tx_state != TX_IDLE || tx_start);		// set if currently transmitting
assign rx_out = rx_data;					// received data byte
assign rx_busy = (rx_state != RX_IDLE);		// set if currently receiving
assign rx_done = (rx_state == RX_DONE);		// set once byte is complete

endmodule
