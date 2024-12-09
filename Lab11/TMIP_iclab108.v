module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================

parameter READ_IMAGE = 0;
parameter READ_SRAM = 1;
parameter ACTION = 3;
parameter OUTPUT = 2;



reg [6:0] addr;
reg [63:0] sram_data_in;
reg [63:0] sram_data_out;

reg [1:0] state, next_state;
reg [8:0] cnt;
reg [8:0] cnt_delay;
reg [1:0] cnt_rgb;
reg [7:0] template_reg[0:8];
reg [1:0] size_reg;
reg [7:0] red,green,blue;
wire [7:0] grayscale_outcome1, grayscale_outcome2,grayscale_outcome3;
reg [7:0] buffer[0:2][0:7];
reg wew;
reg  [7:0] image_reg;
reg [7:0] map[0:17][0:17];
reg [7:0] map_next[0:17][0:17];
reg [2:0] act[0:7];
reg [2:0] counter_action;
reg [3:0] col;
reg [3:0] col_next;
reg [4:0] row, row_next;

reg [7:0] multi_a, multi_b ,multi_c, multi_d , multi_e, multi_f;
wire [15:0] multi_out1, multi_out2, multi_out3;
reg [15:0] multi_o1, multi_o2, multi_o3;
reg [19:0] add_outcome;
reg [19:0] add;
reg [19:0] out_temp;
reg [1:0] size_temp;
reg [3:0] counter_set;

//==================================================================
// reg & wire
//==================================================================

wire [3:0] size = size_temp == 0 ? 3 : size_temp == 1 ? 7 : 15;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        counter_set <= 0;
    end
    else begin
        if(state == OUTPUT && cnt_rgb == 2 &&  cnt == 18)begin
            counter_set <= counter_set + 1;
        end
        else counter_set <= (counter_set == 8) ? 0 : counter_set;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        size_temp <= 0;
    end
    else begin
        if(state == READ_IMAGE)begin
            size_temp <= size_reg;
        end
        else if(state == ACTION )begin
            if(act[counter_action] == 3)begin
                size_temp <= (size_temp == 0) ? 0 : size_temp - 1;
            end
            else size_temp <= size_temp;    
        end
        else if(state == READ_SRAM)begin
            size_temp <= size_reg;
        end
        else size_temp <= size_temp;
    end
end


always @(posedge clk,negedge rst_n) begin
    if(!rst_n) begin
        for(integer i = 0; i < 8; i = i + 1) begin
            act[i] <= 0;
        end
    end
    else begin
        if(in_valid2)begin
            act[blue] <= action;
        end
        else if(state == OUTPUT)begin
            for(integer i = 0; i < 8; i = i + 1) begin
                act[i] <= 0;
            end
        end
        else begin
            act <= act;
        end
    end
end

always @(posedge clk) begin
    cnt_delay <= cnt;
end

always @(posedge clk) begin
    if(state == READ_IMAGE)begin
        size_reg <= (cnt == 0 && cnt_rgb == 0) ? image_size : size_reg;
    end
    else size_reg <= size_reg;
    

    template_reg[8] <= (cnt < 3 && state == READ_IMAGE) ? template : template_reg[8];
    template_reg[7] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[8] : template_reg[7];
    template_reg[6] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[7] : template_reg[6];
    template_reg[5] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[6] : template_reg[5];
    template_reg[4] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[5] : template_reg[4];
    template_reg[3] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[4] : template_reg[3];
    template_reg[2] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[3] : template_reg[2];
    template_reg[1] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[2] : template_reg[1];
    template_reg[0] <= (cnt < 3 && state == READ_IMAGE) ? template_reg[1] : template_reg[0];
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        state <= READ_IMAGE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        READ_IMAGE: begin
            if(size_reg == 0) next_state = (cnt == 17) ? READ_SRAM : READ_IMAGE;
            else if(size_reg == 1) next_state = (cnt == 65) ? READ_SRAM : READ_IMAGE;
            else next_state = (cnt == 257) ? READ_SRAM : READ_IMAGE;
        end
        READ_SRAM: begin
            if(size_reg == 0) next_state = (cnt == 2) ? ACTION : READ_SRAM;
            else if(size_reg == 1) next_state = (cnt == 8) ? ACTION : READ_SRAM;
            else next_state = (cnt == 32) ? ACTION : READ_SRAM;
        end
        ACTION: begin 
            if((act[counter_action] == 7 || ((act[counter_action] == 4 ||act[counter_action] == 5 || 
                act[counter_action] == 3) && act[counter_action + 1] == 7)))
                next_state = OUTPUT;
            else if(act[counter_action] == 6 && (row == 16 || row == size + 1) && act[counter_action + 1] == 7)
                next_state = OUTPUT;
            else
                next_state = ACTION;
        end
        OUTPUT:begin
            if(counter_set == 8) next_state = READ_IMAGE;
            else if(cnt_rgb == 2 && cnt == 19) next_state =  READ_SRAM;
            else next_state = OUTPUT;
        end
        default: next_state = READ_IMAGE;
    endcase
end

always @(posedge clk, negedge rst_n) begin
    // if(state == IDLE) cnt <= 0;
    if(~rst_n)begin
        cnt <= 0;
    end
    else begin
        if(state == READ_IMAGE) begin
            if(size_reg == 0 && cnt == 17) cnt <= 0;
            else if(size_reg == 1 && cnt == 65) cnt <= 0;
            else if(size_reg == 2 && cnt == 257) cnt <= 0;
            else cnt <= (cnt_rgb == 2) ? cnt + 1 : cnt;
        end
        else if(state == READ_SRAM) begin
            if((in_valid2 && action > 2) || cnt > 0 || act[1] > 0)begin
                if(size_reg == 0) cnt <= (cnt == 2) ? 0 : cnt + 1;
                else if(size_reg == 1) cnt <= (cnt == 8) ? 0 : cnt + 1;
                else cnt <= (cnt == 32) ? 0 : cnt + 1;
            end
            else cnt <= 0;
            
        end
        else if(state == ACTION)begin
            
            if(next_state == OUTPUT)begin
                cnt <= 17;
            end
            else  begin
                if(act[counter_action] == 6)begin
                    if(size_temp == 0)begin
                        cnt <= (cnt == 5) ? 0 : cnt + 1;
                    end
                    else if(size_temp == 1)begin
                        cnt <= (cnt == 17) ? 0 : cnt + 1;
                    end
                    else if(size_temp == 2)begin
                        cnt <= (cnt == 65) ? 0 : cnt + 1;
                    end
                    
                end
                else cnt <= 0;
            end
                
        end
        else if(state == OUTPUT)begin
            cnt <= (cnt == 19) ? 0 : cnt + 1;
        end
        else cnt <= 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        cnt_rgb <= 0;
    end
    else begin
        if(state == READ_IMAGE) cnt_rgb <= (in_valid || cnt > 0) ? (cnt_rgb == 2) ? 0 : cnt_rgb + 1 : 0;
        else if(state == OUTPUT) begin
            if(cnt == 19 && cnt_rgb == 0)
                cnt_rgb <= 1 ;
            else if(cnt == 15 && row == size && col == size)
                cnt_rgb <= 2;
            else cnt_rgb <= (cnt == 19 && cnt_rgb == 2)? 0 : cnt_rgb;
        end
        else cnt_rgb <= 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        red <= 0;
        green <= 0;
        blue <= 0;
    end
    else begin
        red <= (state == READ_IMAGE && in_valid) ? (cnt_rgb == 0) ? image : red : 0;
        green <= (state == READ_IMAGE && in_valid) ? (cnt_rgb == 1) ? image : green : 0;
        if(state == READ_IMAGE && in_valid)
            blue <= (cnt_rgb == 2) ? image : blue;
        else blue <= (in_valid2) ? blue + 1 :0;
    end
end

assign grayscale_outcome1 = (red > green) ? (red > blue) ? red : blue : (green > blue) ? green : blue;
assign grayscale_outcome2 = (red + green + blue) / 3;
assign grayscale_outcome3 = (red /4) + (green /2) + (blue /4);

wire [7:0] sort_step1_next[0:6], sort2_step1_next[0:6], sort3_step1_next[0:6], sort4_step1_next[0:6];
reg [7:0] sort_step1[0:6], sort2_step1[0:6], sort3_step1[0:6], sort4_step1[0:6];
wire [7:0] sort_out_next, sort_out_next2, sort_out_next3, sort_out_next4;


find_medium_step1 u0(.a1(map[row[3:0]][col]), .a2(map[row[3:0] + 1][col]), .a3(map[row[3:0] + 2][col]), .a4(map[row[3:0]][col + 1]), .a5(map[row[3:0] + 1][col + 1]), 
    .a6(map[row[3:0] + 2][col + 1]), .a7(map[row[3:0]][col + 2]), .a8(map[row[3:0] + 1][col + 2]), .a9(map[row[3:0] + 2][col + 2]), .out(sort_step1_next));
find_medium_step1 u3(.a1(map[row[3:0]][col + 1]), .a2(map[row[3:0] + 1][col + 1]), .a3(map[row[3:0] + 2][col + 1]), .a4(map[row[3:0]][col + 2]), .a5(map[row[3:0] + 1][col + 2]), 
    .a6(map[row[3:0] + 2][col + 2]), .a7(map[row[3:0]][col + 3]), .a8(map[row[3:0] + 1][col + 3]), .a9(map[row[3:0] + 2][col + 3]), .out(sort2_step1_next));
find_medium_step1 u4(.a1(map[row[3:0]][col + 2]), .a2(map[row[3:0] + 1][col + 2]), .a3(map[row[3:0] + 2][col + 2]), .a4(map[row[3:0]][col + 3]), .a5(map[row[3:0] + 1][col + 3]), 
    .a6(map[row[3:0] + 2][col + 3]), .a7(map[row[3:0]][col + 4]), .a8(map[row[3:0] + 1][col + 4]), .a9(map[row[3:0] + 2][col + 4]), .out(sort3_step1_next));
find_medium_step1 u5(.a1(map[row[3:0]][col + 3]), .a2(map[row[3:0] + 1][col + 3]), .a3(map[row[3:0] + 2][col + 3]), .a4(map[row[3:0]][col + 4]), .a5(map[row[3:0] + 1][col + 4]),
    .a6(map[row[3:0] + 2][col + 4]), .a7(map[row[3:0]][col + 5]), .a8(map[row[3:0] + 1][col + 5]), .a9(map[row[3:0] + 2][col + 5]), .out(sort4_step1_next));


always @(posedge clk) begin
    sort_step1 <= sort_step1_next;
    sort2_step1 <= sort2_step1_next;
    sort3_step1 <= sort3_step1_next;
    sort4_step1 <= sort4_step1_next;
end

find_medium_step2 u1(.a0(sort_step1[0]), .a1(sort_step1[1]), .a2(sort_step1[2]), .a3(sort_step1[3]), .a4(sort_step1[4]), .a5(sort_step1[5]), .a6(sort_step1[6]),
                .out(sort_out_next)); 

find_medium_step2 u2(.a0(sort2_step1[0]), .a1(sort2_step1[1]), .a2(sort2_step1[2]), .a3(sort2_step1[3]), .a4(sort2_step1[4]), .a5(sort2_step1[5]), .a6(sort2_step1[6]),
                .out(sort_out_next2));

find_medium_step2 u6(.a0(sort3_step1[0]), .a1(sort3_step1[1]), .a2(sort3_step1[2]), .a3(sort3_step1[3]), .a4(sort3_step1[4]), .a5(sort3_step1[5]), .a6(sort3_step1[6]),
                .out(sort_out_next3));

find_medium_step2 u7(.a0(sort4_step1[0]), .a1(sort4_step1[1]), .a2(sort4_step1[2]), .a3(sort4_step1[3]), .a4(sort4_step1[4]), .a5(sort4_step1[5]), .a6(sort4_step1[6]),
                .out(sort_out_next4));


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 3; i = i + 1) begin
            for(integer j = 0; j < 8; j = j + 1) begin
                buffer[i][j] <= 0;
            end
        end
    end
    else begin
        if(cnt_rgb == 0 && cnt > 0 && state == READ_IMAGE)begin
            buffer[0][7] <= grayscale_outcome1;
            buffer[1][7] <= grayscale_outcome2;
            buffer[2][7] <= grayscale_outcome3;
            for(integer i = 0; i < 3; i = i + 1) begin
                for(integer j = 0; j < 7; j = j + 1) begin
                    buffer[i][j] <= buffer[i][j + 1];
                end
            end
        end
        else if(state == ACTION && act[counter_action] == 6 )begin
            buffer[1][7] <= sort_out_next4;
            buffer[1][6] <= sort_out_next3;
            buffer[1][5] <= sort_out_next2;
            buffer[1][4] <= sort_out_next;
            buffer[1][3] <= buffer[1][7];
            buffer[1][2] <= buffer[1][6];
            buffer[1][1] <= buffer[1][5];
            buffer[1][0] <= buffer[1][4];
            buffer[0][7] <= buffer[1][3];
            buffer[0][6] <= buffer[1][2];
            buffer[0][5] <= buffer[1][1];
            buffer[0][4] <= buffer[1][0];
            buffer[0][3] <= buffer[0][7];
            buffer[0][2] <= buffer[0][6];
            buffer[0][1] <= buffer[0][5];
            buffer[0][0] <= buffer[0][4];
            
            
        end
        else if(state == READ_SRAM)begin
            for(integer i = 0; i < 3; i = i + 1) begin
                for(integer j = 0; j < 8; j = j + 1) begin
                    buffer[i][j] <= 0;
                end
            end
        end
        else buffer <= buffer;
    end
end

always @(*) begin
    if(state == READ_IMAGE)begin
        case (cnt_delay[2:0])
            0 : wew = cnt_delay == 0;
            default: wew = 1;
        endcase
    end
    else wew = 1;
    
end

always @(*) begin
    if(cnt_rgb == 1)begin
        sram_data_in = {buffer[0][0], buffer[0][1], buffer[0][2], buffer[0][3], buffer[0][4], buffer[0][5], buffer[0][6], buffer[0][7]};
    end
    else if(cnt_rgb == 2)begin
        sram_data_in = {buffer[1][0], buffer[1][1], buffer[1][2], buffer[1][3], buffer[1][4], buffer[1][5], buffer[1][6], buffer[1][7]};
    end
    else if(cnt_rgb == 0)begin
        sram_data_in = {buffer[2][0], buffer[2][1], buffer[2][2], buffer[2][3], buffer[2][4], buffer[2][5], buffer[2][6], buffer[2][7]};
    end
    else sram_data_in = 0;
end

always @(*) begin
    if(state == READ_IMAGE && cnt == 0)begin
        addr = 0;
    end
    else if(state == READ_IMAGE)begin
        case (cnt_delay[2:0])
            3'b000: addr = cnt_rgb == 1 ? cnt_delay[8:3] - 1 : cnt_rgb == 2 ? cnt_delay[8:3] + 31 : cnt_delay[8:3] + 63;            
            default: addr = 0;
        endcase
    end
    else if(state == READ_SRAM )begin
        if(act[0] == 0)begin
            addr = cnt;
        end
        else if(act[0] == 1)begin
            addr = cnt + 32;
        end
        else begin
            addr = (cnt + 64) < 96 ? cnt + 64 : 95;
        end
    end
    else  addr = 0;
    
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        counter_action <= 1;
    end
    else begin
        if(state == ACTION)begin
            if(act[counter_action] == 3 || act[counter_action] == 4 || act[counter_action] == 5)counter_action <= counter_action + 1;
            else if(act[counter_action] == 6)begin
                if(row == size + 1)begin
                    counter_action <= counter_action + 1;
                end
                else counter_action <= counter_action;
            end
        end
        else counter_action <= 1;
    end
end




always @(*) begin
    
    map_next = map;
    case (state)
        READ_SRAM: begin
            if(size_reg == 0 )begin
                map_next[3][1] = sram_data_out[63:56];
                map_next[3][2] = sram_data_out[55:48];
                map_next[3][3] = sram_data_out[47:40];
                map_next[3][4] = sram_data_out[39:32];
                map_next[4][1] = sram_data_out[31:24];
                map_next[4][2] = sram_data_out[23:16];
                map_next[4][3] = sram_data_out[15:8];
                map_next[4][4] = sram_data_out[7:0];
                map_next[1] = map[3];
                map_next[2] = map[4];

            end
            else if(size_reg == 1)begin
                map_next[8][1] = sram_data_out[63:56];
                map_next[8][2] = sram_data_out[55:48];
                map_next[8][3] = sram_data_out[47:40];
                map_next[8][4] = sram_data_out[39:32];
                map_next[8][5] = sram_data_out[31:24];
                map_next[8][6] = sram_data_out[23:16];
                map_next[8][7] = sram_data_out[15:8];
                map_next[8][8] = sram_data_out[7:0];
                map_next[7] = map[8];
                map_next[6] = map[7];
                map_next[5] = map[6];
                map_next[4] = map[5];
                map_next[3] = map[4];
                map_next[2] = map[3];
                map_next[1] = map[2];
            end
            else if(size_reg == 2 )begin
                map_next[16][9] = sram_data_out[63:56];
                map_next[16][10] = sram_data_out[55:48];
                map_next[16][11] = sram_data_out[47:40];
                map_next[16][12] = sram_data_out[39:32];
                map_next[16][13] = sram_data_out[31:24];
                map_next[16][14] = sram_data_out[23:16];
                map_next[16][15] = sram_data_out[15:8];
                map_next[16][16] = sram_data_out[7:0];
                map_next[16][1:8] = map[16][9:16];
                map_next[15][9:16] = map[16][1:8]; map_next[15][1:8] = map[15][9:16];
                map_next[14][9:16] = map[15][1:8]; map_next[14][1:8] = map[14][9:16];
                map_next[13][9:16] = map[14][1:8]; map_next[13][1:8] = map[13][9:16];
                map_next[12][9:16] = map[13][1:8]; map_next[12][1:8] = map[12][9:16];
                map_next[11][9:16] = map[12][1:8]; map_next[11][1:8] = map[11][9:16];
                map_next[10][9:16] = map[11][1:8]; map_next[10][1:8] = map[10][9:16];
                map_next[9][9:16] = map[10][1:8]; map_next[9][1:8] = map[9][9:16];
                map_next[8][9:16] = map[9][1:8]; map_next[8][1:8] = map[8][9:16];
                map_next[7][9:16] = map[8][1:8]; map_next[7][1:8] = map[7][9:16];
                map_next[6][9:16] = map[7][1:8]; map_next[6][1:8] = map[6][9:16];
                map_next[5][9:16] = map[6][1:8]; map_next[5][1:8] = map[5][9:16];
                map_next[4][9:16] = map[5][1:8]; map_next[4][1:8] = map[4][9:16];
                map_next[3][9:16] = map[4][1:8]; map_next[3][1:8] = map[3][9:16];
                map_next[2][9:16] = map[3][1:8]; map_next[2][1:8] = map[2][9:16];
                map_next[1][9:16] = map[2][1:8]; map_next[1][1:8] = map[1][9:16];
            end
        end
        ACTION:begin
            case (act[counter_action])
                3:begin
                    if(size_temp == 0)begin
                        map_next = map;
                    end
                    else begin
                        for(integer i = 1; i < 9; i = i + 1) begin
                            for(integer j = 1; j < 9; j = j + 1) begin
                                map_next[i][j] = maxpooling(map[2 * i - 1][2 * j - 1], map[2 * i - 1][2 * j], map[2 * i][2 * j - 1], map[2 * i][2 * j]);
                            end
                        end
                        if(size_temp == 1)begin
                            for(integer i = 5; i < 18; i = i + 1) begin
                                for(integer j = 1; j < 18; j = j + 1) begin
                                    map_next[i][j] = 0;
                                end
                            end
                            for(integer i = 1; i < 5; i = i + 1) begin
                                for(integer j = 5; j < 18; j = j + 1) begin
                                    map_next[i][j] = 0;
                                end
                            end
                        end
                        else if(size_temp == 2)begin
                            for(integer i = 9; i < 18; i = i + 1) begin
                                for(integer j = 1; j < 18; j = j + 1) begin
                                    map_next[i][j] = 0;
                                end
                            end
                            for(integer i = 1; i < 9; i = i + 1) begin
                                for(integer j = 9; j < 18; j = j + 1) begin
                                    map_next[i][j] = 0;
                                end
                            end
                        end
                    end
                end 
                4:begin
                    for(integer i = 1; i < 17; i = i + 1) begin
                        for(integer j = 1; j < 17; j = j + 1) begin
                            map_next[i][j] = ~map[i][j];
                        end
                    end
                     if(size_temp == 0)begin
                        for(integer i = 5; i < 18; i = i + 1) begin
                            for(integer j = 1; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                        for(integer i = 1; i < 5; i = i + 1) begin
                            for(integer j = 5; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                    end
                    else if(size_temp == 1)begin
                        for(integer i = 9; i < 18; i = i + 1) begin
                            for(integer j = 1; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                        for(integer i = 1; i < 9; i = i + 1) begin
                            for(integer j = 9; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                    end

                end
                5:begin
                    if(size_temp == 0)begin
                        for(integer i = 1; i < 5; i = i + 1) begin
                            for(integer j = 1; j < 5; j = j + 1) begin
                                map_next[i][j] = map[i][5 - j];
                            end
                        end
                    end
                    else if(size_temp == 1)begin
                        for(integer i = 1; i < 9; i = i + 1) begin
                            for(integer j = 1; j < 9; j = j + 1) begin
                                map_next[i][j] = map[i][9 - j];
                            end
                        end
                    end
                    else if(size_temp == 2)begin
                        for(integer i = 1; i < 17; i = i + 1) begin
                            for(integer j = 1; j < 17; j = j + 1) begin
                                map_next[i][j] = map[i][17 - j];
                            end
                        end
                    end
                    
                    
                end
                6:begin
                    if(cnt == 0)begin
                        map_next[0][0] = map[1][1];
                        map_next[0][size + 2] = map[1][size + 1];
                        map_next[size + 2][0] = map[size + 1][1];
                        map_next[size + 2][size + 2] = map[size + 1][size + 1];
                        for(integer i = 0; i <= size ; i = i + 1)begin
                            map_next[0][i + 1] = map[1][i + 1];
                            map_next[size + 2][i + 1] = map[size + 1][i + 1];
                            map_next[i + 1][0] = map[i + 1][1];
                            map_next[i + 1][size + 2] = map[i + 1][size + 1];
                        end
                    end
                    else if(row >= 1)begin
                        if(size_temp == 0)begin
                            if(row == 4)begin
                                map_next[3][1] = buffer[1][4];
                                map_next[3][2] = buffer[1][5];
                                map_next[3][3] = buffer[1][6];
                                map_next[3][4] = buffer[1][7];
                                map_next[4][1] = sort_out_next;
                                map_next[4][2] = sort_out_next2;
                                map_next[4][3] = sort_out_next3;
                                map_next[4][4] = sort_out_next4;
                            end

                            else begin
                                
                                map_next[row - 1][4] = buffer[1][7];
                                map_next[row - 1][3] = buffer[1][6];
                                map_next[row - 1][2] = buffer[1][5];
                                map_next[row - 1][1] = buffer[1][4];
                            end
                            
                            
                        end
                        else if(size_temp == 1)begin
                            if(row == 8)begin
                                map_next[7][5] = buffer[1][0];
                                map_next[7][6] = buffer[1][1];
                                map_next[7][7] = buffer[1][2];
                                map_next[7][8] = buffer[1][3];
                                map_next[8][1] = buffer[1][4];
                                map_next[8][2] = buffer[1][5];
                                map_next[8][3] = buffer[1][6];
                                map_next[8][4] = buffer[1][7];
                                map_next[8][5] = sort_out_next;
                                map_next[8][6] = sort_out_next2;
                                map_next[8][7] = sort_out_next3;
                                map_next[8][8] = sort_out_next4;
                            end
                            else if(col == 0)begin
                                // map_next[row - 1][3] = buffer[1][3];
                                map_next[row - 1][8] = buffer[1][3];
                                map_next[row - 1][7] = buffer[1][2];
                                map_next[row - 1][6] = buffer[1][1];
                                map_next[row - 1][5] = buffer[1][0];
                            end
                            
                            else begin
                                map_next[row][col] = buffer[1][3];
                                map_next[row][col - 1] = buffer[1][2];
                                map_next[row][col - 2] = buffer[1][1];
                                map_next[row][col - 3] = buffer[1][0];
                            end
                        end
                        else if(size_temp == 2)begin
                            
                            if(row == 16)begin
                                map_next[15][13] = buffer[0][0];
                                map_next[15][14] = buffer[0][1];
                                map_next[15][15] = buffer[0][2];
                                map_next[15][16] = buffer[0][3];
                                map_next[16][1] = buffer[0][4];
                                map_next[16][2] = buffer[0][5];
                                map_next[16][3] = buffer[0][6];
                                map_next[16][4] = buffer[0][7];
                                map_next[16][5] = buffer[1][0];
                                map_next[16][6] = buffer[1][1];
                                map_next[16][7] = buffer[1][2];
                                map_next[16][8] = buffer[1][3];
                                map_next[16][9] = buffer[1][4];
                                map_next[16][10] = buffer[1][5];
                                map_next[16][11] = buffer[1][6];
                                map_next[16][12] = buffer[1][7];
                                map_next[16][13] = sort_out_next;
                                map_next[16][14] = sort_out_next2;
                                map_next[16][15] = sort_out_next3;
                                map_next[16][16] = sort_out_next4;
                            end
                            else if(col == 0)begin
                                map_next[row - 1][16] = buffer[0][3];
                                map_next[row - 1][15] = buffer[0][2];
                                map_next[row - 1][14] = buffer[0][1];
                                map_next[row - 1][13] = buffer[0][0];
                            end
                            else begin
                                map_next[row][col] = buffer[0][3];
                                map_next[row][col - 1] = buffer[0][2];
                                map_next[row][col - 2] = buffer[0][1];
                                map_next[row][col - 3] = buffer[0][0];

                            end
                           
                        end
                    end

                    if(size_temp == 0 && row == 4)begin
                        for(integer i = 5; i < 18; i = i + 1) begin
                            for(integer j = 0; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                        for(integer i = 0; i < 5; i = i + 1) begin
                            for(integer j = 5; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                        for(integer i = 0 ; i < 5 ; i = i + 1) begin
                            map_next[i][0] = 0;
                            map_next[0][i] = 0;
                        end
                    end
                    else if(size_temp == 1 && row == 8)begin
                        for(integer i = 9; i < 18; i = i + 1) begin
                            for(integer j = 0; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                        for(integer i = 0; i < 9; i = i + 1) begin
                            for(integer j = 9; j < 18; j = j + 1) begin
                                map_next[i][j] = 0;
                            end
                        end
                        for(integer i = 0 ; i < 9 ; i = i + 1) begin
                            map_next[i][0] = 0;
                            map_next[0][i] = 0;
                        end
                    end
                    else if(size_temp == 2 && row == 16)begin
                        for(integer i = 0 ; i < 18 ; i = i + 1) begin
                            map_next[i][0] = 0;
                            map_next[0][i] = 0;
                            map_next[i][17] = 0;
                            map_next[17][i] = 0;
                        end
                    end
                end


            endcase
        end
        OUTPUT:begin
            if(cnt == 19 && cnt_rgb == 2)begin
                for(integer i = 0; i < 18; i = i + 1) begin
                    for(integer j = 0; j < 18; j = j + 1) begin
                        map_next[i][j] = 0;
                    end
                end
            end
            else begin
                map_next = map;
            end
        end
        
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 18; i = i + 1) begin
            for(integer j = 0; j < 18; j = j + 1) begin
                map[i][j] <= 0;
            end
        end
    end
    else map <= map_next;
end


always @(*) begin
    if(state == OUTPUT)begin
        if(cnt == 15)begin
            row_next = (col == size) ? row + 1 : row;
            col_next = (col == size) ? 0 : col + 1;
        end
        else begin
            row_next = row;
            col_next = col;
        end
    end
    else if(state == ACTION && act[counter_action] == 6)begin
        row_next = (row == size + 1|| cnt == 0)? 0 : (col == size - 3) ? row + 1 :  row;
        col_next = (col == size - 3 || cnt == 0 || row == size + 1) ? 0 : col + 4;
    end
    else begin
        row_next = 0;
        col_next = 0;
    end
end

always @(posedge clk,negedge rst_n) begin
    if(~rst_n)begin
        row <= 0;
        col <= 0;
    end
    else begin
        row <= row_next;
        col <= col_next;
    end
end

always @(*) begin
    
    if(cnt == 16)begin
        multi_a = map[row][col];
        multi_b = map[row][col + 1];
        multi_c = map[row][col + 2];
        multi_d = template_reg[0];
        multi_e = template_reg[1];
        multi_f = template_reg[2];
    end
    else if(cnt == 17)begin
        multi_a = map[row + 1][col];
        multi_b = map[row + 1][col + 1];
        multi_c = map[row + 1][col + 2];
        multi_d = template_reg[3];
        multi_e = template_reg[4];
        multi_f = template_reg[5];
    end
    else if(cnt == 18)begin
        multi_a = map[row + 2][col];
        multi_b = map[row + 2][col + 1];
        multi_c = map[row + 2][col + 2];
        multi_d = template_reg[6];
        multi_e = template_reg[7];
        multi_f = template_reg[8];
    end
    else begin
        multi_a = 0;
        multi_b = 0;
        multi_c = 0;
        multi_d = 0;
        multi_e = 0;
        multi_f = 0;
    end
    
end

assign multi_out1 = state == OUTPUT ? (multi_a * multi_d) : 0;
assign multi_out2 = state == OUTPUT ? (multi_b * multi_e) : 0;
assign multi_out3 = state == OUTPUT ? (multi_c * multi_f) : 0;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        multi_o1 <= 0;
        multi_o2 <= 0;
        multi_o3 <= 0;
    end
    else begin
        multi_o1 <= multi_out1;
        multi_o2 <= multi_out2;
        multi_o3 <= multi_out3;
    end
end

always @(*) begin
    if(cnt <= 15 || state == ACTION)begin
        add_outcome = 0;
    end
    else begin
        add_outcome = add + multi_o1 + multi_o2 + multi_o3;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        add <= 0;
    end
    else begin
        add <= add_outcome;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        out_temp <= 0;
    end
    else begin
        if(cnt == 19)begin
            out_temp <= add_outcome;
        end
        else begin
            out_temp[19:1] <= out_temp[18:0];
        end
    end
end

always @(*) begin
    if(state == OUTPUT && cnt_rgb)begin
        out_valid = 1;
        out_value = out_temp[19];
    end
    else begin
        out_valid = 0;
        out_value = 0;
    end
end





















MEM_grayscale sram0(.A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]), .A4(addr[4]),
                    .A5(addr[5]), .A6(addr[6]), .DO0(sram_data_out[0]), .DO1(sram_data_out[1]),
                    .DO2(sram_data_out[2]), .DO3(sram_data_out[3]), .DO4(sram_data_out[4]), .DO5(sram_data_out[5]),
                    .DO6(sram_data_out[6]), .DO7(sram_data_out[7]), .DO8(sram_data_out[8]), .DO9(sram_data_out[9]),
                    .DO10(sram_data_out[10]), .DO11(sram_data_out[11]), .DO12(sram_data_out[12]), .DO13(sram_data_out[13]),
                    .DO14(sram_data_out[14]), .DO15(sram_data_out[15]), .DO16(sram_data_out[16]), .DO17(sram_data_out[17]),
                    .DO18(sram_data_out[18]), .DO19(sram_data_out[19]), .DO20(sram_data_out[20]), .DO21(sram_data_out[21]),
                    .DO22(sram_data_out[22]), .DO23(sram_data_out[23]), .DO24(sram_data_out[24]), .DO25(sram_data_out[25]),
                    .DO26(sram_data_out[26]), .DO27(sram_data_out[27]), .DO28(sram_data_out[28]), .DO29(sram_data_out[29]),
                    .DO30(sram_data_out[30]), .DO31(sram_data_out[31]), .DO32(sram_data_out[32]), .DO33(sram_data_out[33]),
                    .DO34(sram_data_out[34]), .DO35(sram_data_out[35]), .DO36(sram_data_out[36]), .DO37(sram_data_out[37]),
                    .DO38(sram_data_out[38]), .DO39(sram_data_out[39]), .DO40(sram_data_out[40]), .DO41(sram_data_out[41]),
                    .DO42(sram_data_out[42]), .DO43(sram_data_out[43]), .DO44(sram_data_out[44]), .DO45(sram_data_out[45]),
                    .DO46(sram_data_out[46]), .DO47(sram_data_out[47]), .DO48(sram_data_out[48]), .DO49(sram_data_out[49]),
                    .DO50(sram_data_out[50]), .DO51(sram_data_out[51]), .DO52(sram_data_out[52]), .DO53(sram_data_out[53]),
                    .DO54(sram_data_out[54]), .DO55(sram_data_out[55]), .DO56(sram_data_out[56]), .DO57(sram_data_out[57]),
                    .DO58(sram_data_out[58]), .DO59(sram_data_out[59]), .DO60(sram_data_out[60]), .DO61(sram_data_out[61]),
                    .DO62(sram_data_out[62]), .DO63(sram_data_out[63]), .DI0(sram_data_in[0]), .DI1(sram_data_in[1]),
                    .DI2(sram_data_in[2]), .DI3(sram_data_in[3]), .DI4(sram_data_in[4]), .DI5(sram_data_in[5]),
                    .DI6(sram_data_in[6]), .DI7(sram_data_in[7]), .DI8(sram_data_in[8]), .DI9(sram_data_in[9]),
                    .DI10(sram_data_in[10]), .DI11(sram_data_in[11]), .DI12(sram_data_in[12]), .DI13(sram_data_in[13]),
                    .DI14(sram_data_in[14]), .DI15(sram_data_in[15]), .DI16(sram_data_in[16]), .DI17(sram_data_in[17]),
                    .DI18(sram_data_in[18]), .DI19(sram_data_in[19]), .DI20(sram_data_in[20]), .DI21(sram_data_in[21]),
                    .DI22(sram_data_in[22]), .DI23(sram_data_in[23]), .DI24(sram_data_in[24]), .DI25(sram_data_in[25]),
                    .DI26(sram_data_in[26]), .DI27(sram_data_in[27]), .DI28(sram_data_in[28]), .DI29(sram_data_in[29]),
                    .DI30(sram_data_in[30]), .DI31(sram_data_in[31]), .DI32(sram_data_in[32]), .DI33(sram_data_in[33]),
                    .DI34(sram_data_in[34]), .DI35(sram_data_in[35]), .DI36(sram_data_in[36]), .DI37(sram_data_in[37]),
                    .DI38(sram_data_in[38]), .DI39(sram_data_in[39]), .DI40(sram_data_in[40]), .DI41(sram_data_in[41]),
                    .DI42(sram_data_in[42]), .DI43(sram_data_in[43]), .DI44(sram_data_in[44]), .DI45(sram_data_in[45]),
                    .DI46(sram_data_in[46]), .DI47(sram_data_in[47]), .DI48(sram_data_in[48]), .DI49(sram_data_in[49]),
                    .DI50(sram_data_in[50]), .DI51(sram_data_in[51]), .DI52(sram_data_in[52]), .DI53(sram_data_in[53]),
                    .DI54(sram_data_in[54]), .DI55(sram_data_in[55]), .DI56(sram_data_in[56]), .DI57(sram_data_in[57]),
                    .DI58(sram_data_in[58]), .DI59(sram_data_in[59]), .DI60(sram_data_in[60]), .DI61(sram_data_in[61]),
                    .DI62(sram_data_in[62]), .DI63(sram_data_in[63]), .CK(clk), .WEB(wew), .OE(1'b1), .CS(1'b1));


//==================================================================
// design
//==================================================================



function [7:0] maxpooling;
    input [7:0] a, b, c, d;
    reg [7:0] temp1, temp2;
    begin
        temp1 = (a > b) ? a : b;
        temp2 = (c > d) ? c : d;
        maxpooling = (temp1 > temp2) ? temp1 : temp2;
    end
    
endfunction

  
endmodule

module find_medium_step1(
    a1, a2, a3, a4, a5, a6, a7, a8, a9, out
    );

    input [7:0] a1, a2, a3, a4, a5, a6, a7, a8, a9;
    output wire[7:0] out [0:6];
    wire [7:0] temp[0:14];

    assign {temp[0],temp[3]} = (a1 > a4) ? {a1 , a4} : {a4 , a1};
    assign {temp[1],temp[6]} = (a2 > a8) ? {a2 , a8} : {a8 , a2};      
    assign {temp[2],temp[5]} = (a3 > a6) ? {a3 , a6} : {a6 , a3}; 
    assign {temp[4],temp[7]} = (a5 > a9) ? {a5 , a9} : {a9 , a5};

    assign {temp[8],temp[13]} = (temp[0] > temp[6]) ? {temp[0] , temp[6]} : {temp[6] , temp[0]};
    assign {temp[9],temp[11]} = (temp[2] > temp[4]) ? {temp[2] , temp[4]} : {temp[4] , temp[2]};
    assign {temp[12],out[5]} = (temp[5] > a7) ? {temp[5] , a7} : {a7 , temp[5]};
    assign {temp[10],temp[14]} = (temp[3] > temp[7]) ? {temp[3] , temp[7]} : {temp[7] , temp[3]};
    
    assign out[1] = (temp[8] > temp[9]) ? temp[9] : temp[8];
    assign {out[0],out[2]} = (temp[1] > temp[10]) ? {temp[1] , temp[10]} : {temp[10] , temp[1]};
    assign {out[3],out[4]} = (temp[11] > temp[12]) ? {temp[11] , temp[12]} : {temp[12] , temp[11]};
    assign out[6] = (temp[14] > temp[13]) ? temp[14]  :temp[13];

endmodule


module find_medium_step2(
    a0, a1, a2, a3, a4, a5, a6, out
    );

    input [7:0] a0, a1, a2, a3, a4, a5, a6;
    output wire[7:0] out;
    wire [7:0] temp[0:14];

    assign temp[1] = (a0 > a3) ? a3 : a0;
    assign temp[2] = (a6 > a4) ? a6 : a4;
    assign {temp[0],temp[3]} = (a2 > a5) ? {a2 , a5} : {a5 , a2};
    assign {temp[4],temp[6]} = (a1 > temp[1]) ? {a1 , temp[1]} : {temp[1] , a1};
    assign {temp[5],temp[7]} = (temp[0] > temp[2]) ? {temp[0] , temp[2]} : {temp[2] , temp[0]};
    assign {temp[8],temp[9]} = (temp[4] > temp[5]) ? {temp[4] , temp[5]} : {temp[5] , temp[4]};
    assign {temp[10],temp[11]} = (temp[6] > temp[7]) ? {temp[6] , temp[7]} : {temp[7] , temp[6]};
    assign out = (temp[9] > temp[10]) ? temp[10] : temp[9];

endmodule
