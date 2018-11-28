module gameDisplay(CLOCK_50, reset, posX, posY, VGA_R, VGA_G, VGA_B);
	
	input logic CLOCK_50, reset;
   input logic [10:0] posX, posY;    
    
   output logic [7:0] VGA_R, VGA_G, VGA_B;

	logic gameOver;
	logic [4:0] brick;
	logic borderLeft, borderRight, borderBottom, borderTop;
	logic [4:0] brickHit;
	logic [4:0] brickOn;
	logic paddle;
	
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
			VGA_R <= 0;
			VGA_G <= 0;
			VGA_B <= 0;
			paddleX <= 320;
		end else begin
			//if() // ball hits the bottom border -> gameOver
			
			VGA_R <= ((brickOn[0] && ~gameOver && brick[0]) || (brickOn[1] && ~gameOver && brick[1]) || 
							(brickOn[2] && ~gameOver && brick[2]) || (brickOn[3] && ~gameOver && brick[3]) ||
							(brickOn[4] && ~gameOver && brick[4]));
			VGA_G <= paddle && ~gameOver;
			VGA_B <= 0;
			
			
		end
	end
 
 // Ball logics
 
 
 // Paddle logics
 
 //TODO: brickHit, readme, ball logic, paddle move, gameOver, 
 

endmodule