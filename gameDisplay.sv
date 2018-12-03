module gameDisplay(CLOCK_50, reset, posX, posY, r, g, b);
	
	input logic CLOCK_50, reset;
   input logic [9:0] posX;
	input logic [8:0] posY;    
    
   output logic [7:0] r, g, b;

	logic gameOver;
	logic [4:0] brick;
	logic borderLeft, borderRight, borderBottom, borderTop;
	logic [4:0] brickOn;
	logic paddle;
	logic [10:0] paddleX; // center of the paddle
	logic signed [1:0] paddle_step;
	logic [4:0] brickCrush;
	logic [10:0] ballX, ballY;
	logic signed [1:0] ball_xstep, ball_ystep;
	logic [3:0] count;
	logic [7:0] red, green, blue;
 
	parameter radius = 4;
	parameter brickLeft1 = 0, brickRight1 = 127;
	parameter brickLeft2 = 128, brickRight2 = 255;
	parameter brickLeft3 = 256, brickRight3 = 383;
	parameter brickLeft4 = 384, brickRight4 = 512;
	parameter brickLeft5 = 513, brickRight5 = 640;
	parameter paddleYMin = 450, paddleYMax = 470, paddleWidth = 40;
	parameter rowMin1 = 60, rowMax1 = 100;
	
	//4 borders
   assign borderLeft = (posX == 0);
	assign borderRight = (posX == 640);
	assign borderBottom = (posY == 480);
	assign borderTop = (posY == 0);

	// Brick logics
	// 5 X 3 bricks : 640 X 480 pixels
	assign brick[0] = (posX >= brickLeft1 && posX <= brickRight1 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[1] = (posX >= brickLeft2 && posX <= brickRight2 && posY >= rowMin1 && posY <= rowMax1);
   assign brick[2] = (posX >= brickLeft3 && posX <= brickRight3 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[3] = (posX >= brickLeft4 && posX <= brickRight4 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[4] = (posX >= brickLeft5 && posX <= brickRight5 && posY >= rowMin1 && posY <= rowMax1);
	assign paddle = (posX >= paddleX - paddleWidth && posX <= paddleX + paddleWidth 
							&& posY >= paddleYMin && posY <= paddleYMax);
 
	always_ff @(posedge CLOCK_50) begin
		if(reset) begin
			gameOver <= 1'b0;
			brickOn <= 5'b11111;
			brickHit <= 5'b00000;
			red <= 0;
			green <= 0;
			blue <= 0;
		end else begin
			red <= ((brickOn[0] && ~gameOver && brick[0]) || (brickOn[1] && ~gameOver && brick[1]) || 
							(brickOn[2] && ~gameOver && brick[2]) || (brickOn[3] && ~gameOver && brick[3]) ||
							(brickOn[4] && ~gameOver && brick[4])) || (ball && ~gameOver);
			green <= (paddle && ~gameOver) || (ball && ~gameOver);
			blue <= (ball && ~gameOver);
		end
		if(brickOn == 5'b00000) gameOver = 0;
	end


	assign r = red;
	assign g = green;
	assign b = blue;
	
	//-------------------Paddle logic-------------------//

	
	always_ff @(posedge CLOCK_50) begin
		if(reset) paddleX <= 320;
		else paddleX <= paddleX + paddle_step;
	end
	
	
   always_comb begin
		if(L && ~R && ~borderLeft) paddle_step = -1; //if left button is pressed -> paddle_step = -1;
		else if(R && ~L && ~borderRight) paddle_step = 1; //if right button is pressed -> paddle_step = 1;
		else paddle_step = 0; //if no buttons pressed -> paddle_step = 0;
	end
	
	
 
 //---------------------Ball logics---------------------//
 
 
 // Initially ball starts at center of (320, 475) with radius of 5
 always_ff @(posedge CLOCK_50) begin
	if(reset) begin
		ballX <= 320;
		ballY <= 475;
		countX <= 0;
		countY <= radius;
	end else begin
		if((posX == 640) && (posY == 480)) begin //when drawing is done, update ball position
			ballX <= ballX + ball_xstep;
			ballY <= ballY + ball_ystep;
			countX <= 0;
			countY <= radius;
		end else begin
			if(posY < ballY && count >= 0 &&) begin
				if(posX == ballX + countX)
					countY <= countY - 1;
				else
					countX <= countX + 1;
			end else if(posY >= ballY && count <= 5) begin
				if(posX == ballX + countX)
					countY <= countY + 1;
				else
					countX <= countX - 1;
			end
			
		end
	end
 end
 
 assign ball = ((posX >= ballX - countX) && (posX < ballX + countX) 
					&& (posY >= ballY - countY) && (posY <= ballY + countY));
 
 always_comb begin
	if((ballX - radius) == 0) ball_xstep = 1;
	else if((ballX + radius) == 640) ball_xstep = -1;
	else if((ballY - radius) == 0) ball_ystep = 1;
	else if((ballY + radius) >= paddleMin && (ballX + radius) <= (paddleX + paddleWidth)
				&& (ballX - radius) >= (paddleX - paddleWidth)) ball_ystep = -1;
	else if((ballY + radius) == 480) gameOver = 1;
 end
 
 
 
 //---------------------Brick logics---------------------//
 
 assign brickCrush[0] = ((ballY <= rowMax1) && ((ballX-count) > brickLeft1) && ((ballX + count) < brickRight1));
 assign brickCrush[1] = ((ballY <= rowMax1) && ((ballX-count) > brickLeft2) && ((ballX + count) < brickRight2));
 assign brickCrush[2] = ((ballY <= rowMax1) && ((ballX-count) > brickLeft3) && ((ballX + count) < brickRight3));
 assign brickCrush[3] = ((ballY <= rowMax1) && ((ballX-count) > brickLeft4) && ((ballX + count) < brickRight4));
 assign brickCrush[4] = ((ballY <= rowMax1) && ((ballX-count) > brickLeft5) && ((ballX + count) < brickRight5));
 
 always_comb begin
	if(brickCrush[0]) brickOn[0] = 0;
	else if(brickCrush[1]) brickOn[1] = 0;
	else if(brickCrush[2]) brickOn[2] = 0;
	else if(brickCrush[3]) brickOn[3] = 0;
	else if(brickCrush[4]) brickOn[4] = 0;
 end

endmodule

module tb_gameDisplay();
	logic CLOCK_50, reset;
	logic [9:0] posX;
	logic [8:0] posY;
	
	parameter PERIOD = 100;
	
	gameDisplay dut (.CLOCK_50, .reset, .posX, .posY, .r, .g, .b);
	
	initial begin
		CLOCK_50 <= 0;
		forever#(CLOCK_PERIOD/2) CLOCK_50 = ~CLOCK_50;
	end
	
	integer i,j;
	initial begin
		reset <= 1; @(posedge CLOCK_50);
		reset <= 0; posX <= 0; posY <= 0; @(posedge CLOCK_50);
		for(i=0; i<480; i++) begin
			for(j=0; j<640; j++) begin
				posX <= posX + 1;
			end
			posY <= posY + 1;
		end
	end

endmodule