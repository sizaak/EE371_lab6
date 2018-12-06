module DE1_SoC (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW, GPIO_0,
					 CLOCK_50, CLOCK2_50, VGA_R, VGA_G, VGA_B, VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS,
					 PS2_CLK, PS2_DAT, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
					 AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT);
					 
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [35:0] GPIO_0;
	output logic [9:0] LEDR;
	input logic [3:0] KEY;
	input logic [9:0] SW;

	input CLOCK_50, CLOCK2_50;
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_BLANK_N;
	output VGA_CLK;
	output VGA_HS;
	output VGA_SYNC_N;
	output VGA_VS;
	

	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;

	logic reset;
	logic [9:0] x;
	logic [8:0] y;
	logic [7:0] r, g, b;
	logic done;
	
	inout PS2_CLK, PS2_DAT;
	wire button_left, button_right, button_middle;
	wire [UPPER_BITS-1:0] bin_x, bin_y;
	
	assign reset = SW[9];
	
	video_driver #(.WIDTH(640), .HEIGHT(480))
		v1 (.CLOCK_50, .reset, .x, .y, .r, .g, .b,
			 .VGA_R, .VGA_G, .VGA_B, .VGA_BLANK_N,
			 .VGA_CLK, .VGA_HS, .VGA_SYNC_N, .VGA_VS);
			 
	gameDisplay game(.CLOCK_50, .reset, .posX(x), .posY(y), .r, .g, .b, .L(button_left), .R(button_right), .s(SW[8]), .done);
	
	
	ps2 #(.WIDTH(10), .HEIGHT(10), .BIN(10), .HYSTERESIS(3))
			mouse (.start(SW[0]), .reset, .CLOCK_50, .PS2_CLK, .PS2_DAT, .button_left, 
					.button_right, .button_middle, .bin_x, .bin_y);
	
	parameter UPPER_BITS = $clog2(10>10?10:10);
	
	assign LEDR[9] = button_left;
	assign LEDR[0] = button_right;
	assign GPIO_0[0] = done; // pin for green LED = b
	
	part1 (.CLOCK_50, .CLOCK2_50, .KEY(KEY[0]), .FPGA_I2C_SCLK, .FPGA_I2C_SDAT, .AUD_XCK, 
		        .AUD_DACLRCK, .AUD_ADCLRCK, .AUD_BCLK, .AUD_ADCDAT, .AUD_DACDAT);

	
	//always_ff @(posedge CLOCK_50) begin
	//	r <= SW[7:0];
	//	g <= x[7:0];
	//	b <= y[7:0];
	//end
	
	
	assign HEX0 = '1;
	assign HEX1 = '1;
	assign HEX2 = '1;
	assign HEX3 = '1;
	assign HEX4 = '1;
	assign HEX5 = '1;
	
endmodule