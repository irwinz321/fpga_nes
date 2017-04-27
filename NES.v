`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:48:26 03/14/2017 
// Design Name: 
// Module Name:    NES 
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
module NES(
	input clk_in,	// 100MHz
	input nreset,	// active low input
    input rx_in,
	output tx_out,	// UART tx line
	output [7:0] led_out
    );
    
    

	
// Declare variables:
wire R_nW;
wire [7:0] IR, X, Y, AC, S, P;
wire [15:0] PC;
reg clk_ph1 = 0, clk_ph2 = 0;
wire [7:0] data_bus_from_cpu;
reg [7:0] data_bus_to_cpu = 0;
wire [15:0] address_bus;
wire tx_buff_empty, tx_buff_full, tx_fifo_rd, tx_err_ovf, tx_err_unf, tx_busy;
wire rx_buff_empty, rx_buff_full, rx_fifo_rd, rx_err_ovf, rx_err_unf;
wire [7:0] tx_buff_data_out, rx_buff_data_out, rx_data;
reg [7:0] tx_buff_data_in = 0;
reg tx_buff_wr = 0;
reg uart_tx = 0;
reg nreset_int = 0; // internal reset for component modules	
    
    
// Instantiate UART module:
UART #(.NUM_BITS(8), .STOP_BIT(1), .BAUD_RATE(115200)) uart (.reset(nreset), .sys_clk(clk_in), .tx_data(tx_buff_data_out), .tx_enable(uart_tx), 
                                                             .tx_out(tx_out), .tx_busy(tx_busy), .rx_done(rx_done), .rx_in(rx_in), .rx_out(rx_data), 
                                                             .rx_enable(1'd1));

// Instantiate transmit FIFO buffer:
FIFO #(.d_width(8), .d_depth(32), .a_width(5)) tx_buffer (.clk(clk_in), .rst(nreset), .rd(tx_fifo_rd), .wr(tx_buff_wr), .data_in(tx_buff_data_in), 
                                                          .data_out(tx_buff_data_out), .full(tx_buff_full), .empty(tx_buff_empty), 
                                                          .err_ovf(tx_err_ovf), .err_unf(tx_err_unf)); 
                                                       
// Instantiate receive FIFO buffer:
FIFO #(.d_width(8), .d_depth(8), .a_width(3)) rx_buffer (.clk(clk_in), .rst(nreset), .rd(rx_fifo_rd), .wr(rx_done), .data_in(rx_data), 
                                                         .data_out(rx_buff_data_out), .full(rx_buff_full), .empty(rx_buff_empty), 
                                                         .err_ovf(rx_err_ovf), .err_unf(rx_err_unf)); 

// Instantiate the CPU:
CPU cpu_6502 (.sys_clock(clk_in), .clk_ph1(clk_ph1), .clk_ph2(clk_ph2), .rst(nreset_int), .irq(1'd1), .nmi(1'd1), .R_nW(R_nW),
			  .Data_bus_in(data_bus_to_cpu), .Data_bus_out(data_bus_from_cpu), .Addr_bus(address_bus), .IR_dbg(IR), .AC_dbg(AC), 
			  .X_dbg(X), .Y_dbg(Y), .P_dbg(P), .S_dbg(S), .PC_dbg(PC));
                                                       

// Set up UART to auto-transmit whatever's in the transmit buffer:
assign tx_fifo_rd = !(tx_buff_empty || tx_busy);	// if there's something in the buffer, read it (wait for tx to finish)
always @(posedge clk_in) begin	// delay uart_tx until buffer output is ready
	if (nreset == 0)
		uart_tx <= 0;
	else
		uart_tx <= tx_fifo_rd;
end

localparam [2:0] IDLE = 3'd0,
                 RX_PKT = 3'd1,
                 DO_CMD = 3'd2,
                 TX_PKT = 3'd3,
                 TX_DEL = 3'd4;
                 
reg [2:0] NES_state = IDLE;
reg [3:0] pkt_cnt = 0;
reg [7:0] cmd_byte = 0, data_byte = 0;
reg phase_count = 0;


assign rx_fifo_rd = !rx_buff_empty && NES_state == IDLE;    // read byte immediately on receive if we're in IDLE

// Interpret received packets:
always @(posedge clk_in) begin
    if (nreset == 0) begin
        nreset_int <= 0;
        pkt_cnt <= 0;
        NES_state <= IDLE;
        cmd_byte <= 0;
        data_byte <= 0;
        phase_count <= 0;
		tx_buff_wr <= 0;
		tx_buff_data_in <= 0;
		data_bus_to_cpu <= 0;
		clk_ph1 <= 0;
		clk_ph2 <= 0;
    end
    else begin
        nreset_int <= 1;
		tx_buff_wr <= 0;
		clk_ph1 <= 0;
		clk_ph2 <= 0;
        case (NES_state)
            IDLE: begin
                if (!rx_buff_empty) begin   // we've received a byte
                    NES_state <= RX_PKT;    // do something with it (rx_fifo_rd goes low here)
                    pkt_cnt <= pkt_cnt + 1'd1;   // we expect 2 bytes per packet
                end
            end
            RX_PKT: begin   // we've read a byte from the FIFO
                if (pkt_cnt == 1) begin
                    cmd_byte <= rx_buff_data_out;   // first byte = command
                    NES_state <= IDLE;              // wait for next byte
                end
                else begin
                    data_byte <= rx_buff_data_out;  // second byte = data for CPU
                    NES_state <= DO_CMD;            // implement command
                    pkt_cnt <= 0;                   // reset packet count
                end
            end
            DO_CMD: begin   
                if (cmd_byte == 0) begin         // restart CPU
                    phase_count <= 0;
                    nreset_int <= 0;
                    data_bus_to_cpu <= 0;
                    clk_ph1 <= 0;
                    clk_ph2 <= 0;
                end
                else if (cmd_byte == 1) begin    // step CPU
                    phase_count <= !phase_count;
                    data_bus_to_cpu <= data_byte;
                    clk_ph1 <= phase_count == 0;
                    clk_ph2 <= phase_count == 1;
                end
                NES_state <= TX_PKT;
            end
            TX_PKT: begin           // send status message back to Host
                tx_buff_wr <= 1;
                NES_state <= TX_DEL;
				pkt_cnt <= pkt_cnt + 1'd1;
                
                case (pkt_cnt)
                    0: begin    // send current phase
                        tx_buff_data_in <= cmd_byte == 0 ? 8'd0 : ({7'd0, !phase_count} + 8'd1);
                    end
                    1: begin    // send current instruction
                        tx_buff_data_in <= IR;
                    end
                    2: begin    // send current address bus high byte
                        tx_buff_data_in <= address_bus[15:8];
                    end
                    3: begin    // send current address bus low byte
                        tx_buff_data_in <= address_bus[7:0];
                    end
                    4: begin    // send current data bus (out)
                        tx_buff_data_in <= data_bus_from_cpu;
                    end
                    5: begin    // send current R/nW
                        tx_buff_data_in <= {7'd0, R_nW};
                    end
                    6: begin    // send current program pointer high byte
                        tx_buff_data_in <= PC[15:8];
                    end
                    7: begin    // send current program pointer low byte
                        tx_buff_data_in <= PC[7:0];
                    end
                    8: begin    // send current X register
                        tx_buff_data_in <= X;
                    end
                    9: begin    // send current Y register
                        tx_buff_data_in <= Y;
                    end
                    10: begin   // send current accumulator register
                        tx_buff_data_in <= AC;
                    end
                    11: begin   // send current stack pointer
                        tx_buff_data_in <= S;
                    end
                    12: begin   // send current CPU status register
                        tx_buff_data_in <= P;
                        NES_state <= IDLE;
						pkt_cnt <= 0;
                    end
                endcase
            end
            TX_DEL: begin           // wait one cycle to reset FIFO write line
                tx_buff_wr <= 0;
                NES_state <= TX_PKT;
            end
        endcase
    end
    

end

assign led_out = {phase_count, tx_err_unf, rx_err_unf, tx_fifo_rd, tx_buff_wr, rx_fifo_rd, rx_done, uart_tx};

endmodule
