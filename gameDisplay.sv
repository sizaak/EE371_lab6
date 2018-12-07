module gameDisplay(CLOCK_50, reset, posX, posY, r, g, b, L, R, s, done, victory);
	
	input logic CLOCK_50, reset;
	input logic [9:0] posX;
	input logic [8:0] posY;
	input logic L, R, s;
    
	output logic [7:0] r, g, b;
	output logic done, victory;
	
	logic gameOver;
	logic borderLeft, borderRight, borderBottom, borderTop;
	logic paddle;
	logic [10:0] paddleX; // center of the paddle
	logic paddleLeft, paddleRight;
	logic [10:0] ballX, ballY;
	logic signed [10:0] ball_xstep_prev, ball_ystep_prev, ball_xstep_next, ball_ystep_next;
	logic [3:0] count;
	logic [7:0] red, green, blue;
	integer countX, countY;
	integer brickWidth, brickHeight;
	integer ballColumn, ballRow, posColumn, posRow;
	logic ballInbrick, posInbrick;
	
	logic [brickColumns:0] brick [brickRows:0];
	logic [brickColumns:0] brickCrush [brickRows:0];
	logic [brickColumns:0] brickOn [brickRows:0];
 
	parameter radius = 4;
	parameter brickRows = 5, brickColumns = 10;
	parameter brickTop = 60, brickBottom = 240;
	
	parameter brickLeft1 = 0, brickRight1 = 127;
	parameter brickLeft2 = 128, brickRight2 = 255;
	parameter brickLeft3 = 256, brickRight3 = 383;
	parameter brickLeft4 = 384, brickRight4 = 512;
	parameter brickLeft5 = 513, brickRight5 = 640;
	
	parameter paddleYMin = 450, paddleYMax = 470, paddleWidth = 40;
	parameter rowMin1 = 60, rowMax1 = 100;
	parameter screenBottom = 480;
	parameter screenRightEdge = 640;
	parameter screenLeftEdge = 0;
	parameter screenTop = 0;
	
	logic [31:0] clk;
	clock_divider cdiv (.reset(Reset), .clock(CLOCK_50), .divided_clocks(clk));
	
	//4 borders
	assign borderLeft = (posX == screenLeftEdge);
	assign borderRight = (posX == screenRightEdge);
	assign borderBottom = (posY == screenBottom);
	assign borderTop = (posY == screenTop);
	assign brickWidth = screenRightEdge / brickColumns;
	assign brickHeight = (brickBottom - brickTop) / brickRows;
	// [row y][column x]
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
	assign ballColumn = (ballX * brickColumns) / screenRightEdge;
	assign ballRow = ((ballY - brickTop) * brickRows) / (brickBottom - brickTop);
	assign ballInbrick = (ballY >= brickTop & ballY <= brickBottom);
	assign posColumn = (posX * brickColumns) / screenRightEdge;
	assign posRow = ((posY - brickTop) * brickRows) / (brickBottom - brickTop);
	assign posInbrick = (posY >= brickTop & posY <= brickBottom);

	// Brick logics
	// 5 X 3 brick : 640 X 480 pixels
	/*
	assign brick[0] = (posX >= brickLeft1 && posX <= brickRight1 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[1] = (posX >= brickLeft2 && posX <= brickRight2 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[2] = (posX >= brickLeft3 && posX <= brickRight3 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[3] = (posX >= brickLeft4 && posX <= brickRight4 && posY >= rowMin1 && posY <= rowMax1);
	assign brick[4] = (posX >= brickLeft5 && posX <= brickRight5 && posY >= rowMin1 && posY <= rowMax1);
	*/
	assign paddle = (posX >= paddleX - paddleWidth && posX <= paddleX + paddleWidth 
							&& posY >= paddleYMin && posY <= paddleYMax);
	assign ball = (posX >= ballX - radius && posX <= ballX + radius
						&& posY >= ballY - radius && posY <= ballY + radius);
	assign done = gameOver;
	
	always_ff @(posedge CLOCK_50) begin
		if(reset) begin
			red <= 0;
			green <= 0;
			blue <= 0;
		end else begin
			red[5] <= brickOn[posRow][posColumn] && posInbrick;
			//red[5] <= ((brickOn[0] && ~gameOver && brick[0]) || (brickOn[1] && ~gameOver && brick[1]) || 
			//				(brickOn[2] && ~gameOver && brick[2]) || (brickOn[3] && ~gameOver && brick[3]) ||
			//				(brickOn[4] && ~gameOver && brick[4]));
			green[5] <= (paddle && ~gameOver);
			blue[5] <= (ball && ~gameOver);
		end
		
	end


	assign r = red;
	assign g = green;
	assign b = blue;
	
	//-------------------Paddle logic-------------------//

	
	always_ff @(posedge clk[16]) begin
		if(reset) paddleX <= 320;
		else begin
			if (paddleLeft && s) paddleX <= paddleX - 1;
			else if (paddleRight && s) paddleX <= paddleX + 1;
			
		end
	end
	
	
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
 
always_ff @(posedge clk[19]) begin
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
		if(s) begin
			brickOn[ballColumn][ballRow] <= 0;
			ball_xstep_prev <= ball_xstep_next;
			ball_ystep_prev <= ball_ystep_next;
			ballX <= ballX + ball_xstep_next;
			ballY <= ballY + ball_ystep_next;
		end
	end
	
	if(gameOver_reg) gameOver <= 1'b1;
end
 
always_comb begin
	if(reset) begin
		ball_xstep_next = 3;
		ball_ystep_next = -3;
	end else begin
		if((ballX + radius) >= screenRightEdge /*|| (brickCrush[1] && (ballX+radius) >= brickRight2)  
			|| (brickCrush[2] && (ballX+radius) >= brickRight3) || (brickCrush[3] && (ballX+radius) >= brickRight4)
			|| (brickCrush[4] && (ballX+radius) >= brickRight5)*/) begin
			ball_xstep_next = -ball_xstep_prev; // -1
			ball_ystep_next = ball_ystep_prev;
		end else if((ballX - radius) <= screenLeftEdge /*|| (brickCrush[0] && (ballX-radius) <= brickLeft1)
						|| (brickCrush[1] && (ballX-radius) <= brickLeft2) || (brickCrush[2] && (ballX-radius) <= brickLeft3)
						|| (brickCrush[3] && (ballX-radius) <= brickLeft4)*/) begin
			ball_xstep_next = -ball_xstep_prev;
			ball_ystep_next = ball_ystep_prev;
		end else if((ballY - radius) <= screenTop /*|| ((brickCrush != 0) && (ballY-radius) <= rowMax1)*/) begin
			ball_xstep_next = ball_xstep_prev;
			ball_ystep_next = -ball_ystep_prev;
		//end else if((ballY + radius) >= screenBottom) begin 
		//	ball_xstep_next = ball_xstep_prev;
		//	ball_ystep_next = 11'b11111111111;
		end else if((ballY + radius) >= paddleYMin && ballX <= (paddleX+paddleWidth)
					&& ballX >= (paddleX-paddleWidth)) begin
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
 
logic gameOver_reg;

assign gameOver_reg = (ballY + radius) >= screenBottom;
assign victory = (brickOn[0] == 10'b0000000000 &
					brickOn[1] == 10'b0000000000 &
					brickOn[2] == 10'b0000000000 &
					brickOn[3] == 10'b0000000000 &
					brickOn[4] == 10'b0000000000);

//assign gameOver = 0;


//---------------------Brick logics---------------------//
/*
assign brickCrush[0] = ball && brick[0];
assign brickCrush[1] = ball && brick[1];
assign brickCrush[2] = ball && brick[2];
assign brickCrush[3] = ball && brick[3];
assign brickCrush[4] = ball && brick[4];

logic [4:0] brickOn_next;
always_comb begin
if(reset) brickOn_next = 5'b11111;
else begin
	brickOn_next = brickOn;
	if(brickCrush[0]) brickOn_next[0] = 0;
	else if(brickCrush[1]) brickOn_next[1] = 0;
	else if(brickCrush[2]) brickOn_next[2] = 0;
	else if(brickCrush[3]) brickOn_next[3] = 0;
	else if(brickCrush[4]) brickOn_next[4] = 0;
end
end


always_ff @(posedge CLOCK_50)
	brickOn <= brickOn_next;
*/

endmodule

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

module tb_gameDisplay();
	logic CLOCK_50, reset;
	logic [9:0] posX;
	logic [8:0] posY;
	logic r, b, g, L, R;
	
	parameter CLOCK_PERIOD = 100;
	
	gameDisplay dut (.CLOCK_50, .reset, .posX, .posY, .r, .g, .b, .L, .R);
	
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