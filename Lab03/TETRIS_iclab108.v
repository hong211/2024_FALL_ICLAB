/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter PLACE = 1'b0;
parameter DELETE = 1'b1;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg cs, ns;
reg map[13:0][0:5], map_next[13:0][0:5];
reg [3:0] cnt;
reg [2:0]score_temp;

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

// cnt
always @(posedge clk, negedge rst_n) begin
	if(!rst_n) cnt <= 0;
	else begin
		if(fail) cnt <= 0;
		else if(score_valid) cnt <= cnt + 4'b1;
		else cnt <= cnt;
	end
	
end


wire fail_valid = map[12][0] || map[12][1] || map[12][2] || map[12][3] || map[12][4] || map[12][5];

wire dele0 = map[0][0] && map[0][1] && map[0][2] && map[0][3] && map[0][4] && map[0][5];
wire dele1 = map[1][0] && map[1][1] && map[1][2] && map[1][3] && map[1][4] && map[1][5];
wire dele2 = map[2][0] && map[2][1] && map[2][2] && map[2][3] && map[2][4] && map[2][5];
wire dele3 = map[3][0] && map[3][1] && map[3][2] && map[3][3] && map[3][4] && map[3][5];
wire dele4 = map[4][0] && map[4][1] && map[4][2] && map[4][3] && map[4][4] && map[4][5];
wire dele5 = map[5][0] && map[5][1] && map[5][2] && map[5][3] && map[5][4] && map[5][5];
wire dele6 = map[6][0] && map[6][1] && map[6][2] && map[6][3] && map[6][4] && map[6][5];
wire dele7 = map[7][0] && map[7][1] && map[7][2] && map[7][3] && map[7][4] && map[7][5];
wire dele8 = map[8][0] && map[8][1] && map[8][2] && map[8][3] && map[8][4] && map[8][5];
wire dele9 = map[9][0] && map[9][1] && map[9][2] && map[9][3] && map[9][4] && map[9][5];
wire dele10 = map[10][0] && map[10][1] && map[10][2] && map[10][3] && map[10][4] && map[10][5];
wire dele11 = map[11][0] && map[11][1] && map[11][2] && map[11][3] && map[11][4] && map[11][5];

wire clean = dele0 || dele1 || dele2 || dele3 || dele4 || dele5 || dele6 || dele7 || dele8 || dele9 || dele10 || dele11;

always @(*) begin
	case (cs)
		PLACE:begin
			if(!in_valid) ns = PLACE;
			else ns = DELETE;
		end 
		DELETE:begin
			if(clean != 0) ns = DELETE;
			else ns = PLACE;
		end
		default: ns = PLACE;
	endcase
end

always @(posedge clk, negedge rst_n) begin
	if(!rst_n)begin
		cs <= PLACE;
	end
	else begin
		cs <= ns;
	end
end
//map
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)begin
		for(integer i = 0; i < 14; i = i + 1)begin
			for(integer j = 0; j < 6; j = j + 1)begin
				map[i][j] <= 0;
			end
		end
	end
	else map <= map_next;
end
// map_next

always @(*)begin

	case (cs)
		PLACE:begin
			map_next = map;
			if(in_valid)begin
				case (tetrominoes)
				'd0:begin
					if(map[11][position] || map[11][position + 4'd1]) begin
						map_next[12][position] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[13][position] = 1;
						map_next[13][position + 4'd1] = 1;
					end
					else if(map[10][position] || map[10][position + 4'd1]) begin
						map_next[11][position] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[12][position] = 1;
						map_next[12][position + 4'd1] = 1;
					end
					else if(map[9][position] || map[9][position + 4'd1]) begin
						map_next[10][position] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[11][position] = 1;
						map_next[11][position + 4'd1] = 1;
					end
					else if(map[8][position] || map[8][position + 4'd1]) begin
						map_next[9][position] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[10][position] = 1;
						map_next[10][position + 4'd1] = 1;
					end
					else if(map[7][position] || map[7][position + 4'd1]) begin
						map_next[8][position] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[9][position] = 1;
						map_next[9][position + 4'd1] = 1;
					end
					else if(map[6][position] || map[6][position + 4'd1]) begin
						map_next[7][position] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[8][position] = 1;
						map_next[8][position + 4'd1] = 1;
					end
					else if(map[5][position] || map[5][position + 4'd1]) begin
						map_next[6][position] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[7][position] = 1;
						map_next[7][position + 4'd1] = 1;
					end
					else if(map[4][position] || map[4][position + 4'd1]) begin
						map_next[5][position] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[6][position] = 1;
						map_next[6][position + 4'd1] = 1;
					end
					else if(map[3][position] || map[3][position + 4'd1]) begin
						map_next[4][position] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[5][position] = 1;
						map_next[5][position + 4'd1] = 1;
					end
					else if(map[2][position] || map[2][position + 4'd1]) begin
						map_next[3][position] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[4][position] = 1;
						map_next[4][position + 4'd1] = 1;
					end
					else if(map[1][position] || map[1][position + 4'd1]) begin
						map_next[2][position] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[3][position] = 1;
						map_next[3][position + 4'd1] = 1;
					end
					else if(map[0][position] || map[0][position + 4'd1]) begin
						map_next[1][position] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[2][position] = 1;
						map_next[2][position + 4'd1] = 1;
					end

					else begin
						map_next[0][position] = 1;
						map_next[0][position + 4'd1] = 1;
						map_next[1][position] = 1;
						map_next[1][position + 4'd1] = 1;
					end
				end
				'd1:begin
					if(map[11][position])begin
						map_next[12][position] = 1;
						map_next[13][position] = 1;
						// map_next[14][position] = 1;
						// map_next[15][position] = 1;
					end
					else if(map[10][position])begin
						map_next[11][position] = 1;
						map_next[12][position] = 1;
						map_next[13][position] = 1;
						// map_next[14][position] = 1;
					end
					else if(map[9][position])begin
						map_next[10][position] = 1;
						map_next[11][position] = 1;
						map_next[12][position] = 1;
						map_next[13][position] = 1;
					end
					else if(map[8][position])begin
						map_next[9][position] = 1;
						map_next[10][position] = 1;
						map_next[11][position] = 1;
						map_next[12][position] = 1;
					end
					else if(map[7][position])begin
						map_next[8][position] = 1;
						map_next[9][position] = 1;
						map_next[10][position] = 1;
						map_next[11][position] = 1;
					end
					else if(map[6][position])begin
						map_next[7][position] = 1;
						map_next[8][position] = 1;
						map_next[9][position] = 1;
						map_next[10][position] = 1;
					end
					else if(map[5][position])begin
						map_next[6][position] = 1;
						map_next[7][position] = 1;
						map_next[8][position] = 1;
						map_next[9][position] = 1;
					end
					else if(map[4][position])begin
						map_next[5][position] = 1;
						map_next[6][position] = 1;
						map_next[7][position] = 1;
						map_next[8][position] = 1;
					end
					else if(map[3][position])begin
						map_next[4][position] = 1;
						map_next[5][position] = 1;
						map_next[6][position] = 1;
						map_next[7][position] = 1;
					end
					else if(map[2][position])begin
						map_next[3][position] = 1;
						map_next[4][position] = 1;
						map_next[5][position] = 1;
						map_next[6][position] = 1;
					end
					else if(map[1][position])begin
						map_next[2][position] = 1;
						map_next[3][position] = 1;
						map_next[4][position] = 1;
						map_next[5][position] = 1;
					end
					else if(map[0][position])begin
						map_next[1][position] = 1;
						map_next[2][position] = 1;
						map_next[3][position] = 1;
						map_next[4][position] = 1;
					end

					else begin
						map_next[0][position] = 1;
						map_next[1][position] = 1;
						map_next[2][position] = 1;
						map_next[3][position] = 1;
					end
				end
				'd2:begin
					if(map[11][position]|| map[11][position + 4'd1]
					|| map[11][position + 2]|| map[11][position + 3])begin
						map_next[12][position] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[12][position + 2] = 1;
						map_next[12][position + 3] = 1;
					end
					else if(map[10][position]|| map[10][position + 4'd1]
					|| map[10][position + 2]|| map[10][position + 3])begin
						map_next[11][position] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[11][position + 2] = 1;
						map_next[11][position + 3] = 1;
					end
					else if(map[9][position]|| map[9][position + 4'd1]
					|| map[9][position + 2]|| map[9][position + 3])begin
						map_next[10][position] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[10][position + 2] = 1;
						map_next[10][position + 3] = 1;
					end
					else if(map[8][position]|| map[8][position + 4'd1]
					|| map[8][position + 2]|| map[8][position + 3])begin
						map_next[9][position] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[9][position + 2] = 1;
						map_next[9][position + 3] = 1;
					end
					else if(map[7][position]|| map[7][position + 4'd1]
					|| map[7][position + 2]|| map[7][position + 3])begin
						map_next[8][position] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[8][position + 2] = 1;
						map_next[8][position + 3] = 1;
					end
					else if(map[6][position]|| map[6][position + 4'd1]
					|| map[6][position + 2]|| map[6][position + 3])begin
						map_next[7][position] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[7][position + 2] = 1;
						map_next[7][position + 3] = 1;
					end
					else if(map[5][position]|| map[5][position + 4'd1]
					|| map[5][position + 2]|| map[5][position + 3])begin
						map_next[6][position] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[6][position + 2] = 1;
						map_next[6][position + 3] = 1;
					end
					else if(map[4][position]|| map[4][position + 4'd1]
					|| map[4][position + 2]|| map[4][position + 3])begin
						map_next[5][position] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[5][position + 2] = 1;
						map_next[5][position + 3] = 1;
					end
					else if(map[3][position]|| map[3][position + 4'd1]
					|| map[3][position + 2]|| map[3][position + 3])begin
						map_next[4][position] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[4][position + 2] = 1;
						map_next[4][position + 3] = 1;
					end
					else if(map[2][position]|| map[2][position + 4'd1]
					|| map[2][position + 2]|| map[2][position + 3])begin
						map_next[3][position] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[3][position + 2] = 1;
						map_next[3][position + 3] = 1;
					end
					else if(map[1][position]|| map[1][position + 4'd1]
					|| map[1][position + 2]|| map[1][position + 3])begin
						map_next[2][position] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[2][position + 2] = 1;
						map_next[2][position + 3] = 1;
					end
					else if(map[0][position]|| map[0][position + 4'd1]
					|| map[0][position + 2]|| map[0][position + 3])begin
						map_next[1][position] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[1][position + 2] = 1;
						map_next[1][position + 3] = 1;
					end
					else begin
						map_next[0][position] = 1;
						map_next[0][position + 4'd1] = 1;
						map_next[0][position + 2] = 1;
						map_next[0][position + 3] = 1;
					end
				end
				'd3:begin
			
					if(map[11][position + 4'd1])begin
						map_next[12][position + 4'd1] = 1;
						map_next[13][position + 4'd1] = 1;
						// map_next[14][position + 4'd1] = 1;
						// map_next[14][position] = 1;
					end
					else if(map[10][position + 4'd1])begin
						map_next[11][position + 4'd1] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[13][position + 4'd1] = 1;
						map_next[13][position] = 1;
					end
					else if(map[9][position + 4'd1]|| map[11][position])begin
						map_next[10][position + 4'd1] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[12][position] = 1;
					end
					else if(map[8][position + 4'd1]|| map[10][position])begin
						map_next[9][position + 4'd1] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[11][position] = 1;
					end
					else if(map[7][position + 4'd1]|| map[9][position])begin
						map_next[8][position + 4'd1] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[10][position] = 1;
					end
					else if(map[6][position + 4'd1]|| map[8][position])begin
						map_next[7][position + 4'd1] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[9][position] = 1;
					end
					else if(map[5][position + 4'd1]|| map[7][position])begin
						map_next[6][position + 4'd1] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[8][position] = 1;
					end
					else if(map[4][position + 4'd1]|| map[6][position])begin
						map_next[5][position + 4'd1] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[7][position] = 1;
					end
					else if(map[3][position + 4'd1]|| map[5][position])begin
						map_next[4][position + 4'd1] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[6][position] = 1;
					end
					else if(map[2][position + 4'd1]|| map[4][position])begin
						map_next[3][position + 4'd1] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[5][position] = 1;
					end
					else if(map[1][position + 4'd1]|| map[3][position])begin
						map_next[2][position + 4'd1] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[4][position] = 1;
					end
					else if(map[0][position + 4'd1]|| map[2][position])begin
						map_next[1][position + 4'd1] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[3][position] = 1;
					end

					else begin
						map_next[0][position + 4'd1] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[2][position] = 1;
					end
				end	
				'd4:begin
					if(map[11][position])begin
						map_next[12][position] = 1;
						map_next[13][position] = 1;
						map_next[13][position + 4'd1] = 1;
						map_next[13][position + 2] = 1;
					end
					else if(map[10][position]|| map[11][position + 4'd1] ||  map[11][position + 2])begin
						map_next[11][position] = 1;
						map_next[12][position] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[12][position + 2] = 1;
					end
					else if(map[9][position]|| map[10][position + 4'd1] ||  map[10][position + 2])begin
						map_next[10][position] = 1;
						map_next[11][position] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[11][position + 2] = 1;
					end
					else if(map[8][position]|| map[9][position + 4'd1] ||  map[9][position + 2])begin
						map_next[9][position] = 1;
						map_next[10][position] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[10][position + 2] = 1;
					end
					else if(map[7][position]|| map[8][position + 4'd1] ||  map[8][position + 2])begin
						map_next[8][position] = 1;
						map_next[9][position] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[9][position + 2] = 1;
					end
					else if(map[6][position]|| map[7][position + 4'd1] ||  map[7][position + 2])begin
						map_next[7][position] = 1;
						map_next[8][position] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[8][position + 2] = 1;
					end
					else if(map[5][position]|| map[6][position + 4'd1] ||  map[6][position + 2])begin
						map_next[6][position] = 1;
						map_next[7][position] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[7][position + 2] = 1;
					end
					else if(map[4][position]|| map[5][position + 4'd1] ||  map[5][position + 2])begin
						map_next[5][position] = 1;
						map_next[6][position] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[6][position + 2] = 1;
					end
					else if(map[3][position]|| map[4][position + 4'd1] ||  map[4][position + 2])begin
						map_next[4][position] = 1;
						map_next[5][position] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[5][position + 2] = 1;
					end
					else if(map[2][position]|| map[3][position + 4'd1] ||  map[3][position + 2])begin
						map_next[3][position] = 1;
						map_next[4][position] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[4][position + 2] = 1;
					end
					else if(map[1][position]|| map[2][position + 4'd1] ||  map[2][position + 2])begin
						map_next[2][position] = 1;
						map_next[3][position] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[3][position + 2] = 1;
					end
					else if(map[0][position]|| map[1][position + 4'd1] ||  map[1][position + 2])begin
						map_next[1][position] = 1;
						map_next[2][position] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[2][position + 2] = 1;
					end
					else begin
						map_next[0][position] = 1;
						map_next[1][position] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[1][position + 2] = 1;
					end
				end
				'd5:begin
					if(map[11][position]|| map[11][position + 4'd1] )begin
						map_next[12][position] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[13][position] = 1;
						// map_next[14][position] = 1;
					end
					else if(map[10][position]|| map[10][position + 4'd1] )begin
						map_next[11][position] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[12][position] = 1;
						map_next[13][position] = 1;
					end
					else if(map[9][position]|| map[9][position + 4'd1] )begin
						map_next[10][position] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[11][position] = 1;
						map_next[12][position] = 1;
					end
					else if(map[8][position]|| map[8][position + 4'd1])begin
						map_next[9][position] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[10][position] = 1;
						map_next[11][position] = 1;
					end
					else if(map[7][position]|| map[7][position + 4'd1])begin
						map_next[8][position] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[9][position] = 1;
						map_next[10][position] = 1;
					end
					else if(map[6][position]|| map[6][position + 4'd1] )begin
						map_next[7][position] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[8][position] = 1;
						map_next[9][position] = 1;
					end
					else if(map[5][position]|| map[5][position + 4'd1])begin
						map_next[6][position] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[7][position] = 1;
						map_next[8][position] = 1;
					end
					else if(map[4][position]|| map[4][position + 4'd1] )begin
						map_next[5][position] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[6][position] = 1;
						map_next[7][position] = 1;
					end
					else if(map[3][position]|| map[3][position + 4'd1] )begin
						map_next[4][position] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[5][position] = 1;
						map_next[6][position] = 1;
					end
					else if(map[2][position]|| map[2][position + 4'd1] )begin
						map_next[3][position] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[4][position] = 1;
						map_next[5][position] = 1;
					end
					else if(map[1][position]|| map[1][position + 4'd1] )begin
						map_next[2][position] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[3][position] = 1;
						map_next[4][position] = 1;
					end
					else if(map[0][position]|| map[0][position + 4'd1])begin
						map_next[1][position] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[2][position] = 1;
						map_next[3][position] = 1;
					end
					else begin
						map_next[0][position] = 1;
						map_next[0][position + 4'd1] = 1;
						map_next[1][position] = 1;
						map_next[2][position] = 1;
					end
				end
				'd6:begin
					if(map[11][position + 4'd1] )begin
						map_next[13][position] = 1;
						// map_next[14][position] = 1;
						map_next[13][position + 4'd1] = 1;
						map_next[12][position + 4'd1] = 1;
					end
					else if(map[11][position]|| map[10][position + 4'd1])begin
						map_next[12][position] = 1;
						map_next[13][position] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[11][position + 4'd1] = 1;
					end
					else if(map[10][position]|| map[9][position + 4'd1] )begin
						map_next[11][position] = 1;
						map_next[12][position] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[10][position + 4'd1] = 1;
					end
					else if(map[9][position]|| map[8][position + 4'd1] )begin
						map_next[10][position] = 1;
						map_next[11][position] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[9][position + 4'd1] = 1;
					end
					else if(map[8][position]|| map[7][position + 4'd1] )begin
						map_next[9][position] = 1;
						map_next[10][position] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[8][position + 4'd1] = 1;
					end
					else if(map[7][position]|| map[6][position + 4'd1] )begin
						map_next[8][position] = 1;
						map_next[9][position] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[7][position + 4'd1] = 1;
					end
					else if(map[6][position]|| map[5][position + 4'd1])begin
						map_next[7][position] = 1;
						map_next[8][position] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[6][position + 4'd1] = 1;
					end
					else if(map[5][position]|| map[4][position + 4'd1])begin
						map_next[6][position] = 1;
						map_next[7][position] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[5][position + 4'd1] = 1;
					end
					else if(map[4][position]|| map[3][position + 4'd1] )begin
						map_next[5][position] = 1;
						map_next[6][position] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[4][position + 4'd1] = 1;
					end
					else if(map[3][position]|| map[2][position + 4'd1])begin
						map_next[4][position] = 1;
						map_next[5][position] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[3][position + 4'd1] = 1;
					end
					else if(map[2][position]|| map[1][position + 4'd1] )begin
						map_next[3][position] = 1;
						map_next[4][position] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[2][position + 4'd1] = 1;
					end
					else if(map[1][position]|| map[0][position + 4'd1] )begin
						map_next[2][position] = 1;
						map_next[3][position] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[1][position + 4'd1] = 1;
					end
					else begin
						map_next[1][position] = 1;
						map_next[2][position] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[0][position + 4'd1] = 1;
					end
				end
				'd7:begin
					
					if(map[11][position]|| map[11][position + 4'd1] )begin
						map_next[12][position] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[13][position + 4'd1] = 1;
						map_next[13][position + 2] = 1;
					end
					else if(map[10][position]|| map[10][position + 4'd1] ||  map[11][position + 2])begin
						map_next[11][position] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[12][position + 4'd1] = 1;
						map_next[12][position + 2] = 1;
					end
					else if(map[9][position]|| map[9][position + 4'd1] ||  map[10][position + 2])begin
						map_next[10][position] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[11][position + 4'd1] = 1;
						map_next[11][position + 2] = 1;
					end
					else if(map[8][position]|| map[8][position + 4'd1] ||  map[9][position + 2])begin
						map_next[9][position] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[10][position + 4'd1] = 1;
						map_next[10][position + 2] = 1;
					end
					else if(map[7][position]|| map[7][position + 4'd1] ||  map[8][position + 2])begin
						map_next[8][position] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[9][position + 4'd1] = 1;
						map_next[9][position + 2] = 1;
					end
					else if(map[6][position]|| map[6][position + 4'd1] ||  map[7][position + 2])begin
						map_next[7][position] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[8][position + 4'd1] = 1;
						map_next[8][position + 2] = 1;
					end
					else if(map[5][position]|| map[5][position + 4'd1] ||  map[6][position + 2])begin
						map_next[6][position] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[7][position + 4'd1] = 1;
						map_next[7][position + 2] = 1;
					end
					else if(map[4][position]|| map[4][position + 4'd1] ||  map[5][position + 2])begin
						map_next[5][position] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[6][position + 4'd1] = 1;
						map_next[6][position + 2] = 1;
					end
					else if(map[3][position]|| map[3][position + 4'd1] ||  map[4][position + 2])begin
						map_next[4][position] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[5][position + 4'd1] = 1;
						map_next[5][position + 2] = 1;
					end
					else if(map[2][position]|| map[2][position + 4'd1] ||  map[3][position + 2])begin
						map_next[3][position] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[4][position + 4'd1] = 1;
						map_next[4][position + 2] = 1;
					end
					else if(map[1][position]|| map[1][position + 4'd1] ||  map[2][position + 2])begin
						map_next[2][position] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[3][position + 4'd1] = 1;
						map_next[3][position + 2] = 1;
					end
					else if(map[0][position]|| map[0][position + 4'd1] ||  map[1][position + 2])begin
						map_next[1][position] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[2][position + 4'd1] = 1;
						map_next[2][position + 2] = 1;
					end
					else begin
						map_next[0][position] = 1;
						map_next[0][position + 4'd1] = 1;
						map_next[1][position + 4'd1] = 1;
						map_next[1][position + 2] = 1;
					end
				end
				endcase
			end
			
		end 
		DELETE:begin
			map_next = map;
			if(dele0)begin
				for(integer i = 0; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if (dele1) begin
				for(integer i = 1; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele2)begin
				for(integer i = 2; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele3)begin
				for(integer i = 3; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele4)begin
				for(integer i = 4; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele5)begin
				for(integer i = 5; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele6)begin
				for(integer i = 6; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele7)begin
				for(integer i = 7; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele8)begin
				for(integer i = 8; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele9)begin
				for(integer i = 9; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele10)begin
				for(integer i = 10; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(dele11)begin
				for(integer i = 11; i < 13 ; i = i + 1)begin
					map_next[i] = map[i + 1];
				end
				for(integer i = 0; i < 6 ; i = i + 1)begin
					map_next[13][i] = 0;
				end
			end
			else if(fail || cnt == 15)begin
				for(integer i = 0; i < 14; i = i + 1)begin
					for(integer j = 0; j < 6; j = j + 1)begin
						map_next[i][j] = 0;
					end
				end
			end
			else begin
				map_next = map;
			end
		end
		default:begin
			for(integer i = 0; i < 14; i = i + 1)begin
				for(integer j = 0; j < 6; j = j + 1)begin
					map_next[i][j] = 0;
				end
			end
		end
	endcase
	
	
end

always @(posedge clk) begin
	
		case (cs)
			PLACE: score_temp <= (cnt == 0) ? 0 : score_temp;
			DELETE: score_temp <= ((clean) ? score_temp + 1 : (fail) ? 0 : score_temp);
			default: score_temp <= 0;
		endcase
	// end
end

always @(*) begin
	if(cs == DELETE && !clean)begin
		score = score_temp;
		score_valid = 1;
	end
	else begin
		score = 0;
		score_valid = 0;
	end
end

always @(*) begin
	if(cs == DELETE && !clean && (cnt == 15 || fail))begin
		// for(integer i = 0 ; i < 12 ; i = i + 1)begin
		// 	for(integer j = 0 ; j < 6 ; j = j + 1)begin
		// 		tetris[6 * i + j] = map[i][j];
		// 	end
		// end
		tetris = {map[11][5], map[11][4], map[11][3], map[11][2], map[11][1], map[11][0],
					map[10][5], map[10][4], map[10][3], map[10][2], map[10][1], map[10][0],
					map[9][5], map[9][4], map[9][3], map[9][2], map[9][1], map[9][0],
					map[8][5], map[8][4], map[8][3], map[8][2], map[8][1], map[8][0],
					map[7][5], map[7][4], map[7][3], map[7][2], map[7][1], map[7][0],
					map[6][5], map[6][4], map[6][3], map[6][2], map[6][1], map[6][0],
					map[5][5], map[5][4], map[5][3], map[5][2], map[5][1], map[5][0],
					map[4][5], map[4][4], map[4][3], map[4][2], map[4][1], map[4][0],
					map[3][5], map[3][4], map[3][3], map[3][2], map[3][1], map[3][0],
					map[2][5], map[2][4], map[2][3], map[2][2], map[2][1], map[2][0],
					map[1][5], map[1][4], map[1][3], map[1][2], map[1][1], map[1][0],
					map[0][5], map[0][4], map[0][3], map[0][2], map[0][1], map[0][0]
					};
		tetris_valid = 1;
	end
	else begin
		tetris = 0;
		tetris_valid = 0;
	end
end



always @(*) begin
	if(cs == DELETE && !clean)begin
		fail = fail_valid;
	end
	else begin
		fail = 0;
	end
end


endmodule