// filter with size of N
 module N_fir #(parameter N=16) (reset, CLOCK_50, data_in, data_out, read);
	
	input logic reset, CLOCK_50, read;
	input logic signed [23:0] data_in;
	output logic signed [23:0] data_out;
	
	parameter DATA_SIZE = 24;
	
	logic empty, full, full_temp;
	logic signed [23:0] w_data, r_data; // FIFO data
	logic signed [23:0] accumulator_in, accumulator_out; // Accumulator data
	
	// Divide input by N
	assign w_data = data_in / N;
	assign full_temp = full;
	
	// Store in FIFO
	// Only write when read is true & only read when read is true and buffer is full
	fifo #(.DATA_WIDTH(DATA_SIZE), .ADDR_WIDTH($clog2(N))) fifo_unit
   (.clk(CLOCK_50), .reset, .rd(full_temp && read), .wr(read), .w_data, .empty, .full, .r_data);
	
	// Accumulator logic
	always_comb begin
		if(full_temp)
			accumulator_in = accumulator_out + (w_data - r_data);
		else 
			accumulator_in = accumulator_out + w_data;
	end

	always_ff @(posedge CLOCK_50) begin
		if(reset) begin 
			accumulator_out <= 0; // Initialize to zero
		end else begin
			if(read) begin // Update data
				accumulator_out <= accumulator_in;
				data_out <= accumulator_in;
			end
		end
		
	end
	

	
endmodule

module tb_N_fir();
	logic reset, CLOCK_50, read;
	logic signed [23:0] data_in;
	logic signed [23:0] data_out;
	
	parameter SIZE = 16;
	
	N_fir #(.N(SIZE)) dut (.*);
	
	parameter CLOCK_PERIOD = 100;
	
	initial begin
		CLOCK_50 <= 0;
		forever#(CLOCK_PERIOD/2) CLOCK_50 = ~CLOCK_50;
	end

	initial begin
		reset <= 1; read <= 0;@(posedge CLOCK_50);
		reset <= 0; read <= 1;
		for (int i = 0; i < SIZE * 2 + 1; i++) begin
			data_in <= 24'h000400; @(posedge CLOCK_50);
		end
		for (int j = 0; j < SIZE + 1; j++) begin
			data_in <= 24'h000800; @(posedge CLOCK_50);
			data_in <= 24'h000000; @(posedge CLOCK_50);
		end
		$stop;
	end

endmodule
