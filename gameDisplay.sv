// Main module to control VGA display of the game
module gameDisplay(CLOCK_50, reset, posX, posY, r, g, b, L, R, s, done, victory, difficulty);
	
	input logic CLOCK_50, reset;
	input logic [9:0] posX; // current position of x pixel
	input logic [8:0] posY; // current position of y pixel
	input logic L, R, s; // Left button, Right button, Start signal
	input logic [1:0] difficulty;
    
	output logic [7:0] r, g, b; // red, green, blue colors for VGA
	output logic done, victory;
	
	logic gameOver, gameOver_reg;
	logic borderLeft, borderRight, borderBottom, borderTop; // border logics
	logic paddle;
	logic [10:0] paddleX; // center of the paddle
	logic paddleLeft, paddleRight; // logics for paddle direction
	integer ballX, ballY; // ball position for x and y direction
	logic signed [10:0] ball_xstep_prev, ball_ystep_prev, ball_xstep_next, ball_ystep_next; // ball speed logics
	logic [7:0] red, green, blue;
	integer brickWidth, brickHeight; // parameter for brick width and height
	integer ballColumn, ballRow, posColumn, posRow; // parameter to determine the location of the ball and pixel within bricks
	logic ballInbrick, posInbrick; // logics whether ball or pixel is within the bricks area
 
	// parameters for ball, paddle, bricks, and screen
	parameter radius = 4; // radius of the ball
	parameter brickRows = 5, brickColumns = 10; 
	parameter brickTop = 60, brickBottom = 240;
	parameter paddleYMin = 450, paddleYMax = 470, paddleWidth = 40;
	parameter rowMin1 = 60, rowMax1 = 100;
	parameter screenBottom = 480;
	parameter screenRightEdge = 640;
	parameter screenLeftEdge = 0;
	parameter screenTop = 0;
	
	logic [brickColumns:0] brick [brickRows:0]; // 2D array of brick wall
	logic [brickColumns:0] brickOn [brickRows:0]; // 2D array of logics for brick turned on
	
	logic [31:0] clk;
	clock_divider cdiv (.reset(Reset), .clock(CLOCK_50), .divided_clocks(clk)); // clock divider to slower the speed of ball and paddle
	
	//4 borders and brick width and height
	assign borderLeft = (posX == screenLeftEdge);
	assign borderRight = (posX == screenRightEdge);
	assign borderBottom = (posY == screenBottom);
	assign borderTop = (posY == screenTop);
	assign brickWidth = screenRightEdge / brickColumns;
	assign brickHeight = (brickBottom - brickTop) / brickRows;
	
	// [row y][column x]
	// checks if current pixel is within each brick position
	always_comb begin
		for (integer i = 0; i < brickRows; i++) begin
			for (integer j = 0; j < brickColumns; j++) begin
				brick[i][j] = (	posX >= j * brickWidth && 
								posX <= (j + 1) * brickWidth && 
								posY >= (i * brickHeight) + brickTop && 
								posY <= ((i + 1) * brickHeight) + brickTop);
			end
		end
	end
	
	// checks the location of the ball within bricks and if the ball is within the area of bricks
	assign ballColumn = (ballX * brickColumns) / screenRightEdge;
	assign ballRow = ((ballY - brickTop) * brickRows) / (brickBottom - brickTop);
	assign ballInbrick = (ballY >= brickTop & ballY <= brickBottom);
	
	// checks the location of the pixel within bricks and if the pixel is within the area of bricks
	assign posColumn = (posX * brickColumns) / screenRightEdge;
	assign posRow = ((posY - brickTop) * brickRows) / (brickBottom - brickTop);
	assign posInbrick = (posY >= brickTop & posY <= brickBottom);
	
	// checks if the pixel is within the paddle area
	assign paddle = (posX >= paddleX - paddleWidth && posX <= paddleX + paddleWidth 
							&& posY >= paddleYMin && posY <= paddleYMax);
	
	// checks if the pixel is within the ball area
	assign ball = (posX >= ballX - radius && posX <= ballX + radius
						&& posY >= ballY - radius && posY <= ballY + radius);
	
	assign done = gameOver; // outputs true when player fails to clear all the bricks
	
	always_ff @(posedge CLOCK_50) begin
		if(reset) begin // initializes to black background
			red <= 0;
			green <= 0;
			blue <= 0;
		end else begin
			// Determines VGA output colors for each logic
			red[5] <= (brickOn[posRow][posColumn] && posInbrick && ((posRow == 0) || (posRow == 1)))
						|| ((paddle || ball) && ~gameOver);
			blue[5] <= (brickOn[posRow][posColumn] && posInbrick && ((posRow == 1) || (posRow == 2) || (posRow == 3)))
						|| ((paddle || ball) && ~gameOver);
			green[5] <= (brickOn[posRow][posColumn] && posInbrick && ((posRow == 3) || (posRow == 4)))
						|| ((paddle || ball) && ~gameOver);
		end
		
	end

	assign r = red;
	assign g = green;
	assign b = blue;
	
	//-------------------Paddle logic-------------------//
	always_ff @(posedge clk[18 - difficulty]) begin
		if(reset) paddleX <= 320; // initializes the position of the paddle
		else begin
			// wait until start becomes true and updates the position of the paddle
			if (paddleLeft && s) paddleX <= paddleX - 1;
			else if (paddleRight && s) paddleX <= paddleX + 1;
		end
	end
	
	// Determines whether to move the position of the paddle
   always_comb begin
		if (L && ~R && (paddleX > (screenLeftEdge + paddleWidth))) begin //if left button is pressed -> paddle goes left
			paddleLeft = 1;
			paddleRight = 0;
		end else if (R && ~L && (paddleX < (screenRightEdge - paddleWidth))) begin //if right button is pressed -> paddle goes right
			paddleLeft = 0;
			paddleRight = 1;
		end else begin //if no buttons pressed -> paddle doesn't move
			paddleLeft = 0;
			paddleRight = 0;
		end
	end
	
 //---------------------Ball logics---------------------//
 
always_ff @(posedge clk[20 - difficulty]) begin
	// Initializes ball position, ball direction, and the status of bricks
	if(reset) begin
		ballX <= 320;
		ballY <= 445;
		gameOver <= 1'b0;
		ball_xstep_prev <= 3;
		ball_ystep_prev <= -3;
		brickOn[0] <= 10'b1111111111;
		brickOn[1] <= 10'b1111111111;
		brickOn[2] <= 10'b1111111111;
		brickOn[3] <= 10'b1111111111;
		brickOn[4] <= 10'b1111111111;
	end else begin
		if(s) begin // waits until start signal is true
			// updates the position of the ball and logics for bounce off the brick
			if (ballInbrick & brickOn[ballRow][ballColumn]) begin
				brickOn[ballRow][ballColumn] <= 0;
				ball_xstep_prev <= ball_xstep_next;
				ball_ystep_prev <= -ball_ystep_next;
				ballX <= ballX + ball_xstep_next;
				ballY <= ballY - ball_ystep_next;
			end else begin
				ball_xstep_prev <= ball_xstep_next;
				ball_ystep_prev <= ball_ystep_next;
				ballX <= ballX + ball_xstep_next;
				ballY <= ballY + ball_ystep_next;
			end
		end
	end
	
	if(gameOver_reg) gameOver <= 1'b1;
end
 
 // Determines the direction of the ball movement
always_comb begin
	if(reset) begin
		ball_xstep_next = 3;
		ball_ystep_next = -3;
	end else begin
		if((ballX + radius) >= screenRightEdge) begin // When ball hits the right edge of the screen
			ball_xstep_next = -ball_xstep_prev;
			ball_ystep_next = ball_ystep_prev;
		end else if((ballX - radius) <= screenLeftEdge) begin // When ball hits the left edge of the screen
			ball_xstep_next = -ball_xstep_prev;
			ball_ystep_next = ball_ystep_prev;
		end else if((ballY - radius) <= screenTop) begin // When ball hits the top edge of the screen
			ball_xstep_next = ball_xstep_prev;
			ball_ystep_next = -ball_ystep_prev;
		end else if((ballY + radius) >= paddleYMin && ballX <= (paddleX+paddleWidth)
					&& ballX >= (paddleX-paddleWidth)) begin // When ball hits the paddle
					
			// Determines the angle which ball should move based on the position of the ball within the paddle
			if (ballX <= (paddleX - ((paddleWidth/5)*4))) begin
				ball_xstep_next = -3;
				ball_ystep_next = -1;
			end else if (ballX <= (paddleX - ((paddleWidth/5)*3))) begin
				ball_xstep_next = -3;
				ball_ystep_next = -2;
			end else if (ballX <= (paddleX - ((paddleWidth/5)*2))) begin
				ball_xstep_next = -3;
				ball_ystep_next = -3;
			end else if (ballX <= (paddleX - ((paddleWidth/5)*1))) begin
				ball_xstep_next = -2;
				ball_ystep_next = -3;
			end else if (ballX <= paddleX) begin
				ball_xstep_next = -1;
				ball_ystep_next = -3;
			end else if (ballX <= (paddleX + ((paddleWidth/5)*1))) begin
				ball_xstep_next = 1;
				ball_ystep_next = -3;
			end else if (ballX <= (paddleX + ((paddleWidth/5)*2))) begin
				ball_xstep_next = 2;
				ball_ystep_next = -3;
			end else if (ballX <= (paddleX + ((paddleWidth/5)*3))) begin
				ball_xstep_next = 3;
				ball_ystep_next = -3;
			end else if (ballX <= (paddleX + ((paddleWidth/5)*4))) begin
				ball_xstep_next = 3;
				ball_ystep_next = -2;
			end else begin
				ball_xstep_next = 3;
				ball_ystep_next = -1;
			end
		end else begin
			ball_xstep_next = ball_xstep_prev;
			ball_ystep_next = ball_ystep_prev;	
		end
	end	
end

assign gameOver_reg = (ballY + radius) >= screenBottom; // When the ball hits the bottom of the screen

// True when the player clears all the bricks
assign victory = (brickOn[0] == 10'b0000000000 &
					brickOn[1] == 10'b0000000000 &
					brickOn[2] == 10'b0000000000 &
					brickOn[3] == 10'b0000000000 &
					brickOn[4] == 10'b0000000000);

endmodule

// Module to divide the given clock into 32 slower clocks
module clock_divider (reset, clock, divided_clocks); 
  input logic clock, reset; 
  output logic [31:0] divided_clocks;

  always_ff @(posedge clock) begin 
    if(reset) begin
      divided_clocks <= 0;
    end else begin
      divided_clocks <= divided_clocks + 1;
    end
  end 
endmodule

// testbench for the module
module tb_gameDisplay();
	logic CLOCK_50, reset;
	logic [9:0] posX; // current position of x pixel
	logic [8:0] posY; // current position of y pixel
	logic L, R, s; // Left button, Right button, Start signal
	logic [1:0] difficulty;
    
	logic [7:0] r, g, b; // red, green, blue colors for VGA
	logic done, victory;
	
	parameter CLOCK_PERIOD = 100;
	
	gameDisplay dut (.CLOCK_50, .reset, .posX, .posY, .r, .g, .b, .L, .R, .s, .done, .victory, .difficulty);
	
	initial begin
		CLOCK_50 <= 0;
		forever#(CLOCK_PERIOD/2) CLOCK_50 = ~CLOCK_50;
	end
	
	integer i,j;
	initial begin
		reset <= 1; @(posedge CLOCK_50);
		reset <= 0; s <= 0; posX <= 0; posY <= 0; L <= 0; R <= 0; difficulty <= 2'b10; @(posedge CLOCK_50);
		for(i=0; i<480; i++) begin
			for(j=0; j<640; j++) begin
				posX <= posX + 1;@(posedge CLOCK_50);
			end
			posY <= posY + 1;
		end
		s <= 1; posX <= 0; posY <= 0; R <= 1; @(posedge CLOCK_50);
		for(i=0; i<480; i++) begin
			for(j=0; j<640; j++) begin
				posX <= posX + 1;@(posedge CLOCK_50);
			end
			posY <= posY + 1;
		end
		posX <= 0; posY <= 0; R <= 1; @(posedge CLOCK_50);
		for(i=0; i<480; i++) begin
			for(j=0; j<640; j++) begin
				posX <= posX + 1;@(posedge CLOCK_50);
			end
			posY <= posY + 1;
		end
		$stop;
	end

endmodule