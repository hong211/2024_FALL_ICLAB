module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;



//==============================================//
//                 reg declaration              //
//==============================================//
reg base1, base2, base3; // Base status
reg [3:0] score_A_calculate; 
reg [2:0] score_B_calculate; // Score of team A and B
reg [1:0] out;

//==============================================//
//             Current State Block              //
//==============================================//

wire over;
assign over = (((action == 7) || (action == 6 )) && out == 2) || ((action == 6 && base1) && out > 0);

// out
always @(posedge clk) begin
    if(in_valid)begin
        if(action <= 4) out <= out;
        else if(over && inning == 3 && half) out <= 3;
        else if(over) out <= 0;
        else if(action == 6 && base1) out <= {1'b1 ,out[0]};
        else out <= out + 1; 
    end
    else out <= 0;

    
end

// base1       
always @(posedge clk)begin
    if(in_valid)begin
        if(action == 0 || action == 1) base1 <= 1;
        else if(action == 7 && out < 2) base1 <= base1;
        else base1 <= 0;
    end
    else base1 <= 0;
end

// base2
always @(posedge clk)begin
    if(in_valid)begin
        if(action == 2 || (action == 0 && base1)) base2 <= 1;
        else if(((action == 1) && out < 2) || action == 5) base2 <= base1;
        else if((action == 7 && out < 2) || action == 0) base2 <= base2;
        else base2 <= 0;
    end    
    else base2 <= 0;
end

// base3
always @(posedge clk) begin
    
    if(in_valid)begin
        if((action == 0 && base1 && base2) || (action == 1 && base2 && out < 2) || action == 3) base3 <= 1;
        else if((action == 1 && out == 2) || (action == 2 && out < 2)) base3 <= base1;
        else if((action == 5) || (action == 6 && out == 1 && !base1) || (action == 6 && out == 0)) base3 <= base2;
        else if(action == 0) base3 <= base3;
        else base3 <= 0;
    end
    else base3 <= 0;
end

    
reg [2:0] score;
always @(*) begin
    if(in_valid)begin
        if((action == 0 && base1 && base2 && base3) || (action == 5 && base3) || 
            (action == 6 && ((out == 1 && !base1) || (out == 0)) && base3)  || 
            (action == 7 && out < 2 && base3))
            score = 1;
        else if (action == 4)
            score =  base1 + base2 + base3 + 1;
        else if((action == 2 && out == 2) || action == 3) 
            score =  base1 + base2 + base3;
        else if((action == 1 && out == 2) || (action == 2 && out < 2)) 
            score = base2 + base3;

        else if((action == 1 && out < 2)) score = base3;
        else score = 0;

    end
    else score = 0;
end
// B_stop_increase
reg B_stop_increase;
always @(posedge clk) begin
    if(in_valid && inning == 3 && !half && over && score_B_calculate > score_A_calculate) B_stop_increase <= 1;
    else if (in_valid && inning == 3 && half) B_stop_increase <= B_stop_increase;
    else B_stop_increase <= 0;

end

wire [3:0]score_temp;

assign score_temp = (((half) ? score_B_calculate : score_A_calculate) + score);

always @(posedge clk) begin
    if(in_valid)begin
        if(!half)score_A_calculate <= score_temp;
        else score_A_calculate <= score_A_calculate;
    end
    else if(out == 3) score_A_calculate <= score_A_calculate;
    else score_A_calculate <= 0;
end

always @(posedge clk) begin
    if(in_valid)begin
        if(half && !B_stop_increase)score_B_calculate <= score_temp;
        else score_B_calculate <= score_B_calculate;
    end
    else if(out == 3) score_B_calculate <= score_B_calculate;
    else score_B_calculate <= 0;
end


// out_valid_temp

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else out_valid <= out == 3;
end


// score_A
always @(*) begin
    if(out_valid)begin
        score_A = score_A_calculate;
    end
    else score_A = 0;
end

// score_B
always @(*) begin
    if(out_valid)begin
        score_B = score_B_calculate;
    end
    else score_B = 0;
end

// result
always @(*) begin
    
    if(out_valid)begin
        if(score_A_calculate > score_B_calculate) result = 0;
        else if(score_A_calculate < score_B_calculate) result = 1;
        else result = 2;
    end
    else result = 0;

end


endmodule
