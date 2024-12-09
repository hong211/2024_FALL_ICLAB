/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 6.1
`endif
`ifdef GATE
    `define CYCLE_TIME 6.1
`endif

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency = 0;
real CYCLE = `CYCLE_TIME;
integer input_file;
integer PATNUM;
integer i_pat, i, j , k, a;
integer latency;
integer partial_latency = 0;
integer minimum_latency = 0;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [2:0] trash_terominoes , trash_position;

reg [2:0]golden_tetrominoes, golden_position;

reg golden_fail;
reg [3:0] golden_score;
reg [71:0] golden_tetris;

reg map[15:0][0:5];

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//---------------------------------------------------------------------
//  Check SPEC5
//---------------------------------------------------------------------


//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial begin
	input_file = $fopen("../00_TESTBED/input.txt","r");
	a = $fscanf(input_file,"%d",PATNUM);
	// Initialize signals
    reset_task;
	@ (negedge clk);
	for(i = 0; i < PATNUM; i = i + 1) begin
		a = $fscanf(input_file,"%d",i_pat);
		golden_score = 0;
		golden_tetris = 0;
		for(j = 0; j < 16; j = j + 1)begin
			for(k = 0; k < 6; k = k + 1)begin
				map[j][k] = 0;
			end
		end
		partial_latency = 0;
		for(j = 0; j < 16; j = j + 1) begin
			minimum_latency = minimum_latency + 1;
			input_task;
			wait_score_valid_task;
			check_score;
			if(golden_fail === 1)begin
				for (k = j + 1; k < 16 ; k = k + 1)begin
					a = $fscanf(input_file,"%d %d", trash_terominoes, trash_position);
				end
				break;
			end
			if(j < 15)begin 
				if(tetris !== golden_tetris)begin
					display_fail;
					$display("                    SPEC-7 FAIL                   ");
					$display("********************************************************");     
					$display("                          FAIL!                           ");
					$display("*  tetris is not equal to golden_tetris at * tetris = %d, golden_tetris = %d", tetris, golden_tetris);
					$display("********************************************************");
					repeat (2) @(negedge clk);
					$finish;
				end
				check_score_valid_one_cycle_task;
				repeat ($urandom_range(0,3)) @(negedge clk);
			end
		end
		check_tetris;
		check_tetris_and_score_valid_one_cycle_task;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mExecution Cycle: %3d", i_pat + 1, partial_latency); 
	end

	display_pass;
	$display("                  Congratulations!               ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
	$display("              minimum latency = %7d", minimum_latency);


	$finish;
end

// Task to reset the system
task reset_task; begin 
	rst_n = 1'b1;
	in_valid = 1'b0;
	tetrominoes = 'bx;
	position = 'bx;
	total_latency = 0;

	force clk = 0;

	// Apply reset
	#CYCLE; rst_n = 1'b0; 
	#CYCLE; rst_n = 1'b1;
	
	// Check initial conditions
	if (score_valid !== 0 || score !== 0 || tetris_valid !== 0 || tetris !== 0 || fail !== 0) begin
		display_fail;
		$display("                    SPEC-4 FAIL                   ");
		$display("************************************************************");  
		$display("                          FAIL!                           ");    
		$display("*  Output signals should be 0 after initial RESET at %8t *", $time);
		$display("************************************************************");
		repeat (2) #CYCLE;
		$finish;
	end
	#CYCLE; release clk;
end endtask

task input_task; begin
	// Read input
	// @(negedge clk);
	in_valid = 1'b1;
	a = $fscanf(input_file,"%d %d", golden_tetrominoes, golden_position);
	tetrominoes = golden_tetrominoes;
	position = golden_position;
	@(negedge clk);
	in_valid = 1'b0;
	tetrominoes = 'bx;
	position = 'bx;

end endtask

task wait_score_valid_task; begin
	latency = 1;
	
	while (score_valid !== 1'b1) begin
		if(score_valid === 0)begin
			if(score !== 0 || fail  !== 0 || tetris_valid  !== 0)begin
				display_fail;
				$display("                    SPEC-5 FAIL                   ");
				$display("************************************************************");  
				$display("                          FAIL!                           ");    
				$display("*  score or fail or tetris_valid are not low when score_valid is low at %8t *", $time);
				$display("************************************************************");
				repeat (2) #CYCLE;
				$finish;
			end
		end
		if(tetris_valid === 0)begin
			if(tetris !== 0)begin
				display_fail;
				$display("                    SPEC-5 FAIL                   ");
				$display("************************************************************");  
				$display("                          FAIL!                           ");    
				$display("*  tetris are not low when tetris_valid is low at %8t *", $time);
				$display("************************************************************");
				repeat (2) #CYCLE;
				$finish;
			end
		end
		latency = latency + 1;
		if (latency === 1000) begin
			display_fail;
			$display("                    SPEC-6 FAIL                   ");
			$display("********************************************************");     
			$display("                          FAIL!                           ");
			$display("*  The execution latency exceeded 1000 cycles at %8t   *", $time);
			$display("********************************************************");
			repeat (2) @(negedge clk);
			$finish;
		end
		@(negedge clk);
	end

	if(score_valid === 0)begin
			if(score !== 0 || fail  !== 0 || tetris_valid  !== 0)begin
				display_fail;
				$display("                    SPEC-5 FAIL                   ");
				$display("************************************************************");  
				$display("                          FAIL!                           ");    
				$display("*  score or fail or tetris_valid are not low when score_valid is low at %8t *", $time);
				$display("************************************************************");
				repeat (2) #CYCLE;
				$finish;
			end
		end
		if(tetris_valid === 0)begin
			if(tetris !== 0)begin
				display_fail;
				$display("                    SPEC-5 FAIL                   ");
				$display("************************************************************");  
				$display("                          FAIL!                           ");    
				$display("*  tetris are not low when tetris_valid is low at %8t *", $time);
				$display("************************************************************");
				repeat (2) #CYCLE;
				$finish;
			end
		end

	partial_latency = partial_latency + latency;
	total_latency = total_latency + latency;
end endtask

task check_score_valid_one_cycle_task; begin
	@(negedge clk);
	if (score_valid === 1'b1) begin
		display_fail;
		$display("                    SPEC-8 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  score_valid exceed one cycle %8t   *", $time);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end
end endtask

task check_tetris_and_score_valid_one_cycle_task; begin
	@(negedge clk);
	if (score_valid === 1'b1) begin
		display_fail;
		$display("                    SPEC-8 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  score_valid exceed one cycle %8t   *", $time);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end
	if (tetris_valid === 1'b1) begin
		display_fail;
		$display("                    SPEC-8 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  tetris_valid exceed one cycle %8t   *", $time);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end
end endtask

task check_score; begin
	place_tetromino;
	caclulate_score;
	check_fail;
	if(score !== golden_score)begin
		display_fail;
		$display("                    SPEC-7 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  score is not equal to golden_score at * score = %d, golden_score = %d", score, golden_score);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end
	if(fail !== golden_fail)begin
		display_fail;
		$display("                    SPEC-7 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  fail is not equal to golden_fail at * fail = %d, golden_fail = %d", fail, golden_fail);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end
	
	
	
end endtask

task check_tetris; begin
	integer i, j;
	for(int i = 0; i < 16; i = i + 1)begin
		for(int j = 0; j < 6; j = j + 1)begin
			golden_tetris[6 * i + j] = map[i][j];
		end
	end

	if(fail !== golden_fail)begin
		display_fail;
		$display("                    SPEC-7 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  fail is not equal to golden_fail at * fail = %d, golden_fail = %d", fail, golden_fail);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end

	if(tetris !== golden_tetris)begin
		display_fail;
		$display("                    SPEC-7 FAIL                   ");
		$display("********************************************************");     
		$display("                          FAIL!                           ");
		$display("*  tetris is not equal to golden_tetris at * tetris = %d, golden_tetris = %d", tetris, golden_tetris);
		$display("********************************************************");
		repeat (2) @(negedge clk);
		$finish;
	end
end endtask

integer l;

task place_tetromino; begin
	integer i;
	case (golden_tetrominoes)
		0:begin
			for(i = 14 ; i >= 1 ; i = i - 1)begin
				if(map[i - 1][golden_position] === 1 || map[i - 1][golden_position + 1] === 1)begin
					map[i][golden_position] = 1;
					map[i][golden_position + 1] = 1;
					map[i + 1][golden_position] = 1;
					map[i + 1][golden_position + 1] = 1;
					break;
				end
				
			end
			if(i == 0)begin
				map[0][golden_position] = 1;
				map[0][golden_position + 1] = 1;
				map[1][golden_position] = 1;
				map[1][golden_position + 1] = 1;
			end
		end 
		1:begin
			for(i = 12 ; i >= 1 ; i = i - 1)begin
				if(map[i - 1][golden_position] === 1)begin
					map[i][golden_position] = 1;
					map[i + 1][golden_position] = 1;
					map[i + 2][golden_position] = 1;
					map[i + 3][golden_position] = 1;
					break;
				end
				
			end
			if(i == 0)begin
				map[0][golden_position] = 1;
				map[1][golden_position] = 1;
				map[2][golden_position] = 1;
				map[3][golden_position] = 1;
			end
			
		end
		2:begin
			for(i = 15 ; i >= 1 ; i = i - 1)begin
				if(map[i - 1][golden_position] === 1 || map[i - 1][golden_position + 1] === 1 
				|| map[i - 1][golden_position + 2] === 1 || map[i - 1][golden_position + 3] === 1)begin
					map[i][golden_position] = 1;
					map[i][golden_position + 1] = 1;
					map[i][golden_position + 2] = 1;
					map[i][golden_position + 3] = 1;
					break;
				end
				
			end
			if(i == 0)begin
				map[0][golden_position] = 1;
				map[0][golden_position + 1] = 1;
				map[0][golden_position + 2] = 1;
				map[0][golden_position + 3] = 1;
			end
			
		end
		3:begin
			for(i = 13 ; i >= 1 ; i = i - 1)begin
				if(map[i - 1][golden_position + 1] === 1 || map[i + 1][golden_position] === 1 )begin
					map[i][golden_position + 1] = 1;
					map[i + 1][golden_position + 1] = 1;
					map[i + 2][golden_position + 1] = 1;
					map[i + 2][golden_position] = 1;
					break;
				end
				
			end
			if(i == 0)begin
				map[0][golden_position + 1] = 1;
				map[1][golden_position + 1] = 1;
				map[2][golden_position + 1] = 1;
				map[2][golden_position] = 1;
			end
			
		end
		4:begin
			for(i = 14 ; i >= 1 ; i = i - 1)begin
				if(map[i - 1][golden_position] === 1 || map[i][golden_position + 1] === 1 
				|| map[i][golden_position + 2] === 1)begin
					map[i][golden_position] = 1;
					map[i + 1][golden_position] = 1;
					map[i + 1][golden_position + 1] = 1;
					map[i + 1][golden_position + 2] = 1;
					break;
				end
				
			end
			if(i == 0)begin
				map[0][golden_position] = 1;
				map[1][golden_position] = 1;
				map[1][golden_position + 1] = 1;
				map[1][golden_position + 2] = 1;
			end
			
		end
		5:begin
			for(i = 13 ; i >= 1 ; i = i -1)begin
				if(map[i - 1][golden_position] === 1 || map[i - 1][golden_position + 1] === 1 )begin
					map[i][golden_position] = 1;
					map[i][golden_position + 1] = 1;
					map[i + 1][golden_position] = 1;
					map[i + 2][golden_position] = 1;
					break;
				end
			
			end
			if(i == 0)begin
				map[0][golden_position] = 1;
				map[0][golden_position + 1] = 1;
				map[1][golden_position] = 1;
				map[2][golden_position] = 1;
			end
			
		end
		6:begin
			for(i = 13 ; i >= 1 ; i = i - 1)begin
				if(map[i][golden_position] === 1 || map[i - 1][golden_position + 1] === 1 )begin
					map[i + 1][golden_position] = 1;
					map[i + 2][golden_position] = 1;
					map[i + 1][golden_position + 1] = 1;
					map[i][golden_position + 1] = 1;
					break;
				end
			end
			if(i == 0)begin
				map[1][golden_position] = 1;
				map[2][golden_position] = 1;
				map[0][golden_position + 1] = 1;
				map[1][golden_position + 1] = 1;
			end
			
		end
		7:begin
			for(i = 14 ; i >= 1 ; i = i - 1)begin
				if(map[i - 1][golden_position] === 1 || map[i - 1][golden_position + 1] === 1 || map[i][golden_position + 2] === 1)begin
					map[i][golden_position] = 1;
					map[i][golden_position + 1] = 1;
					map[i + 1][golden_position + 1] = 1;
					map[i + 1][golden_position + 2] = 1;
					break;
				end
				
			end
			if(i == 0)begin
				map[0][golden_position] = 1;
				map[0][golden_position + 1] = 1;
				map[1][golden_position + 1] = 1;
				map[1][golden_position + 2] = 1;
			end
		end
	endcase
		
	

end endtask

task check_fail;begin
	integer i, j;
	golden_fail = 0;
	for(i = 12 ; i < 16 ; i = i + 1)begin
		for(j = 0 ; j < 6 ; j = j + 1)begin
			if(map[i][j] === 1)begin
				golden_fail = 1;
				break;
			end
		end
		if(golden_fail === 1)begin
			break;
		end
	end
end endtask

reg full;
task caclulate_score;begin
	integer  i, j, k;
	for(i = 0 ; i <= 15 ; i = i + 1)begin
		full = 1'b1;
		for (int j = 0; j < 6; j = j + 1) begin
			if (map[i][j] === 0) begin
                full = 1'b0;
                break;
			end	
		
		end

		if(full)begin
			for (k = i; k < 15; k = k + 1) begin
                map[k] = map[k + 1];
			end
			for(j = 0 ; j < 6 ; j = j + 1)begin
				map[15][j] = 0;
			end
			i = i - 1;
			golden_score = golden_score + 1;
		end
            
	end
end endtask










task display_fail; begin
    $display("        ----------------------------               ");
    $display("        --                        --       |\__||  ");
    $display("        --  OOPS!!                --      / X,X  | ");
    $display("        --                        --    /_____   | ");
    $display("        --  \033[0;31mSimulation FAIL!!\033[m   --   /^ ^ ^ \\  |");
    $display("        --                        --  |^ ^ ^ ^ |w| ");
    $display("        ----------------------------   \\m___m__|_|");
    $display("\n");
end endtask

task display_pass; begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  \033[0;32mSimulation PASS!!\033[m     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end endtask

endmodule
// for spec check



// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
