//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter OUT = 3'd3;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] Kernel_ch1_reg[0:2][0:1][0:1], Kernel_ch2_reg[0:2][0:1][0:1], Weight_reg[0:2][0:7];
reg Opt_reg;
wire [inst_sig_width+inst_exp_width:0] activating_outcome_next;
reg [inst_sig_width+inst_exp_width:0] activating_outcome[0:7];
wire [inst_sig_width+inst_exp_width:0] exp_plus, exp_minus;
wire [inst_sig_width+inst_exp_width:0] a, b, c, d;
wire [inst_sig_width+inst_exp_width:0] temp1,temp2,temp3,temp4;
reg [inst_sig_width+inst_exp_width:0] exp[0:2], exp_acc;
wire [inst_sig_width+inst_exp_width:0] exp_sum_next, exp_sub_next;
wire [inst_sig_width+inst_exp_width:0] max_pooling_outcome_next;
//---------------------------------------------------------------------
//   Counter
//---------------------------------------------------------------------
reg [7:0] cnt;


always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        cnt <= 0;
    end
    else begin
        if(cnt == 112 || (!in_valid && cnt == 0)) cnt <= 0;
        else cnt <= cnt + 1;
    end
end

//---------------------------------------------------------------------
//  store opt && kernal && weight
//---------------------------------------------------------------------
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 3 ; i = i + 1)begin
            for(integer  j = 0; j < 2 ; j = j + 1)begin
                for(integer  k = 0; k < 2 ; k = k + 1)begin
                    Kernel_ch1_reg[i][j][k] <= 0;
                    Kernel_ch2_reg[i][j][k] <= 0;
                end
            end
        end
    end
    else begin
        Kernel_ch1_reg <= Kernel_ch1_reg;
        Kernel_ch2_reg <= Kernel_ch2_reg;
        if(cnt < 12 && in_valid)begin
            Kernel_ch1_reg[cnt[3:2]][cnt[1]][cnt[0]] <= Kernel_ch1;
            Kernel_ch2_reg[cnt[3:2]][cnt[1]][cnt[0]] <= Kernel_ch2;
        end
        else if(cnt == 95 || cnt == 96 || cnt == 97 || cnt == 98 || cnt == 99
            || cnt == 100 || cnt == 101 || cnt == 102 || cnt >= 108)begin
            Kernel_ch1_reg[0][0][0] <= Kernel_ch1_reg[0][0][1];
            Kernel_ch1_reg[0][0][1] <= Kernel_ch1_reg[0][1][0];
            Kernel_ch1_reg[0][1][0] <= Kernel_ch1_reg[0][1][1];
            Kernel_ch1_reg[0][1][1] <= Kernel_ch1_reg[1][0][0];

            Kernel_ch1_reg[1][0][0] <= Kernel_ch1_reg[1][0][1];
            Kernel_ch1_reg[1][0][1] <= Kernel_ch1_reg[1][1][0];
            Kernel_ch1_reg[1][1][0] <= Kernel_ch1_reg[1][1][1];
            Kernel_ch1_reg[1][1][1] <= activating_outcome_next;

        end
        if(cnt >= 102) begin
            Kernel_ch1_reg[2][0][0] <= Weight_reg[0][0];
            Kernel_ch1_reg[2][0][1] <= Weight_reg[0][1];
            Kernel_ch1_reg[2][1][0] <= Weight_reg[0][2];
            Kernel_ch1_reg[2][1][1] <= Weight_reg[0][3];
            
            Kernel_ch2_reg[2][0][0] <= Weight_reg[0][4];
            Kernel_ch2_reg[2][0][1] <= Weight_reg[0][5];
            Kernel_ch2_reg[2][1][0] <= Weight_reg[0][6];
            Kernel_ch2_reg[2][1][1] <= Weight_reg[0][7];
            
        end

        if(cnt >= 92)begin
            Kernel_ch2_reg[0][0][0] <= exp_sum_next;
            Kernel_ch2_reg[0][0][1] <= exp_sub_next;
            Kernel_ch2_reg[0][1][0] <= max_pooling_outcome_next;
        end
            
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 3 ; i = i + 1)begin
            for(integer  j = 0; j < 8 ; j = j + 1)begin
                Weight_reg[i][j] <= 0;
            end
        end
    end
    else begin
        Weight_reg <= Weight_reg;
        if(cnt < 24 && in_valid)begin
            Weight_reg[cnt[4:3]][cnt[2:0]] <= Weight;
        end
        else if(cnt == 102 || cnt == 103)begin
            Weight_reg[0] <= Weight_reg[1];
            Weight_reg[1] <= Weight_reg[2];
            Weight_reg[2] <=Weight_reg[2];
        end
        else 
            Weight_reg <= Weight_reg;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) Opt_reg <= 0;
    else if(in_valid && cnt == 0) Opt_reg <= Opt;
    else Opt_reg <= Opt_reg;
end

//---------------------------------------------------------------------
// putting input to the map
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0] buffer1[0:4], buffer1_next[0:4];
reg [inst_sig_width+inst_exp_width:0] buffer2[0:4], buffer2_next[0:4];
reg [inst_sig_width+inst_exp_width:0] buffer3[0:4], buffer3_next[0:4];
reg [inst_sig_width+inst_exp_width:0] caculated_map[0:1][0:6], caculated_map_next[0:1][0:6];
reg [inst_sig_width+inst_exp_width:0] accumulate1, accumulate2, accumulate6;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 5 ; i = i + 1)begin
            buffer1[i] <= 0;
        end
    end
    else buffer1 <= buffer1_next;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 5 ; i = i + 1)begin
            buffer2[i] <= 0;
        end
    end
    else buffer2 <= buffer2_next;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 5 ; i = i + 1)begin
            buffer3[i] <= 0;
        end
    end
    else buffer3 <= buffer3_next;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 2 ; i = i + 1)begin
            for(integer  j = 0; j < 7 ; j = j + 1)begin
                caculated_map[i][j] <= 0;
            end
        end
    end
    else if(cnt == 102)begin
        caculated_map <= caculated_map_next;
        caculated_map[0][0] <=  Kernel_ch1_reg[0][0][1];
        caculated_map[0][1] <=  Kernel_ch1_reg[0][1][1];
        caculated_map[1][0] <=  Kernel_ch1_reg[1][0][1];
        caculated_map[1][1] <=  Kernel_ch1_reg[1][1][1];


        caculated_map[0][4] <=  Kernel_ch1_reg[0][1][0];
        caculated_map[0][5] <=  Kernel_ch1_reg[1][0][0];
        caculated_map[1][4] <=  Kernel_ch1_reg[1][1][0];
        caculated_map[1][5] <=  activating_outcome_next;
    end
    else caculated_map <= caculated_map_next;
end

always @(*) begin
    buffer1_next = buffer1;
    if(cnt < 25 && in_valid)begin
        buffer1_next[cnt % 5] = Img;
    end
    else if(cnt == 25 || cnt == 30 || cnt == 35 || cnt == 40 || cnt == 45 || cnt == 50 || cnt == 55 || cnt == 60 
        || cnt == 65 || cnt == 70 || cnt == 75 || cnt == 80 || cnt == 85 || cnt == 90)begin
        buffer1_next = buffer2;
    end
    
    else if(cnt == 97) begin
        for(integer  i = 0; i < 5 ; i = i + 1)begin
            buffer1_next[i] = 0;
        end
    end

    else begin
        buffer1_next = buffer1;
    end
end

always @(*) begin
    buffer2_next = buffer2;
    if(cnt < 50 && cnt > 24 && in_valid)begin
        buffer2_next[cnt % 5] = Img;
    end
    else if(cnt == 55 || cnt == 60 || cnt == 65 || cnt == 70 || cnt == 75 || cnt == 80 
    || cnt == 85 || cnt == 90)begin
        buffer2_next = buffer3;
    end
    else if(cnt == 97) begin
        for(integer  i = 0; i < 5 ; i = i + 1)begin
            buffer2_next[i] = 0;
        end
    end
    else begin
        buffer2_next = buffer2;
    end
end

always @(*) begin
    buffer3_next = buffer3;
    if(cnt > 49 &&cnt < 75 && in_valid)begin
        buffer3_next[cnt % 5] = Img;
    end
    else if(cnt == 97) begin
        for(integer  i = 0; i < 5 ; i = i + 1)begin
            buffer3_next[i] = 0;
        end
    end
    else begin
        buffer3_next = buffer3;
    end
end

always @(*) begin
    // up padding
    
    if(cnt == 5 || cnt == 35 || cnt == 65)begin
        caculated_map_next[1][1:5] = buffer1[0:4];
        // caculated_map_next[0][1:5] = (Opt_reg) ? buffer1[0:4] : '{4{32'b0}};
        for(integer i = 0; i < 5; i = i + 1)begin
            caculated_map_next[0][i+1] = (Opt_reg) ? buffer1[i] : 0;
        end
        caculated_map_next[1][0] = (Opt_reg) ? buffer1[0] : 0;
        caculated_map_next[0][0] = (Opt_reg) ? buffer1[0] : 0;
        caculated_map_next[1][6] = (Opt_reg) ? buffer1[4] : 0;
        caculated_map_next[0][6] = (Opt_reg) ? buffer1[4] : 0;
    end
    else if(cnt == 10 || cnt == 15 || cnt == 20 || cnt == 25 || cnt == 40 || cnt == 45 
    || cnt == 50 || cnt == 55 || cnt == 70 || cnt == 75 || cnt == 80 || cnt == 85)begin
        caculated_map_next[0][0] = caculated_map[1][3];
        caculated_map_next[0][1] = caculated_map[1][4];
        caculated_map_next[0][2] = caculated_map[1][5];
        caculated_map_next[0][3] = caculated_map[1][6];
        caculated_map_next[0][4] = caculated_map[1][0];
        caculated_map_next[0][5] = caculated_map[1][1];
        caculated_map_next[0][6] = caculated_map[1][2];
        caculated_map_next[1][1:5] = buffer1[0:4];
        caculated_map_next[1][0] = (Opt_reg) ? buffer1[0] : 0;
        caculated_map_next[1][6] = (Opt_reg) ? buffer1[4] : 0;
    end

    else if(cnt == 30 || cnt == 60 || cnt == 90)begin
        // caculated_map_next[1] = caculated_map[1];
        caculated_map_next[0][0] = caculated_map[1][3];
        caculated_map_next[0][1] = caculated_map[1][4];
        caculated_map_next[0][2] = caculated_map[1][5];
        caculated_map_next[0][3] = caculated_map[1][6];
        caculated_map_next[0][4] = caculated_map[1][0];
        caculated_map_next[0][5] = caculated_map[1][1];
        caculated_map_next[0][6] = caculated_map[1][2];
        caculated_map_next[1][0] = (Opt_reg) ? caculated_map[1][3]  : 0 ; 
        caculated_map_next[1][1] = (Opt_reg) ? caculated_map[1][4]  : 0 ; 
        caculated_map_next[1][2] = (Opt_reg) ? caculated_map[1][5]  : 0 ; 
        caculated_map_next[1][3] = (Opt_reg) ? caculated_map[1][6]  : 0 ; 
        caculated_map_next[1][4] = (Opt_reg) ? caculated_map[1][0]  : 0 ; 
        caculated_map_next[1][5] = (Opt_reg) ? caculated_map[1][1]  : 0 ; 
        caculated_map_next[1][6] = (Opt_reg) ? caculated_map[1][2]  : 0 ; 
    end
    else if(cnt == 112 || cnt == 95 ||  cnt == 0)begin
        for(integer i = 0; i < 2; i = i + 1)begin
            for(integer j = 0; j < 7; j = j + 1)begin
                caculated_map_next[i][j] = 0;
            end
        end
    end
    else if(cnt <= 94)begin
        for(integer  i = 0; i < 2 ; i = i + 1)begin
            caculated_map_next[i][0] = caculated_map[i][1];
            caculated_map_next[i][1] = caculated_map[i][2];
            caculated_map_next[i][2] = caculated_map[i][3];
            caculated_map_next[i][3] = caculated_map[i][4];
            caculated_map_next[i][4] = caculated_map[i][5];
            caculated_map_next[i][5] = caculated_map[i][6];
            caculated_map_next[i][6] = caculated_map[i][0];
        end
    end
    else caculated_map_next = caculated_map;
end


reg [inst_sig_width+inst_exp_width:0] map1_mul_conv1_next, map1_mul_conv2_next, map1_mul_conv3_next, map1_mul_conv4_next;
reg [inst_sig_width+inst_exp_width:0] map2_mul_conv1_next, map2_mul_conv2_next, map2_mul_conv3_next, map2_mul_conv4_next;
reg [inst_sig_width+inst_exp_width:0] map_mul6_conv1_next, map_mul6_conv2_next, map_mul6_conv3_next, map_mul6_conv4_next;

DW_fp_mult_inst U1(.inst_a(caculated_map[0][0]), .inst_b(Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][0]), 
                .inst_rnd(3'b000), .z_inst(map1_mul_conv1_next), .status_inst());
DW_fp_mult_inst U2(.inst_a(caculated_map[0][1]), .inst_b(Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][1]),
                .inst_rnd(3'b000), .z_inst(map1_mul_conv2_next), .status_inst());
DW_fp_mult_inst U3(.inst_a(caculated_map[1][0]), .inst_b(Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][0]),
                .inst_rnd(3'b000), .z_inst(map1_mul_conv3_next), .status_inst());
DW_fp_mult_inst U4(.inst_a(caculated_map[1][1]), .inst_b(Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][1]),
                .inst_rnd(3'b000), .z_inst(map1_mul_conv4_next), .status_inst());

DW_fp_mult_inst U5(.inst_a(caculated_map[0][0]), .inst_b(Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][0]),
                .inst_rnd(3'b000), .z_inst(map2_mul_conv1_next), .status_inst());
DW_fp_mult_inst U6(.inst_a(caculated_map[0][1]), .inst_b(Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][1]),
                .inst_rnd(3'b000), .z_inst(map2_mul_conv2_next), .status_inst());
DW_fp_mult_inst U7(.inst_a(caculated_map[1][0]), .inst_b(Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][0]),
                .inst_rnd(3'b000), .z_inst(map2_mul_conv3_next), .status_inst());
DW_fp_mult_inst U8(.inst_a(caculated_map[1][1]), .inst_b(Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][1]),
                .inst_rnd(3'b000), .z_inst(map2_mul_conv4_next), .status_inst());

assign ker1 = (cnt == 6 || cnt == 11 || cnt == 16 || cnt == 21 || cnt == 26 || cnt == 31 || cnt == 36 || cnt == 41 || cnt == 46 || cnt == 51 || cnt == 56 || cnt == 61 || cnt == 66 || cnt == 71 || cnt == 76 || cnt == 81 || cnt == 86 || cnt == 91);


DW_fp_mult_inst U9(.inst_a(ker1 ? caculated_map[0][5] : caculated_map[0][4]), .inst_b(ker1 ? Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][0] : Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][0]),
                .inst_rnd(3'b000), .z_inst(map_mul6_conv1_next), .status_inst());
DW_fp_mult_inst U10(.inst_a(ker1 ? caculated_map[0][6] : caculated_map[0][5]), .inst_b(ker1 ? Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][1] : Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][0][1]),
                .inst_rnd(3'b000), .z_inst(map_mul6_conv2_next), .status_inst());
DW_fp_mult_inst U11(.inst_a(ker1 ? caculated_map[1][5] : caculated_map[1][4]), .inst_b(ker1 ? Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][0] : Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][0]),
                .inst_rnd(3'b000), .z_inst(map_mul6_conv3_next), .status_inst());
DW_fp_mult_inst U12(.inst_a(ker1 ? caculated_map[1][6] : caculated_map[1][5]), .inst_b(ker1 ? Kernel_ch1_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][1] : Kernel_ch2_reg[(cnt <= 35) ? 0 : cnt <= 65 ? 1 : 2][1][1]),
                .inst_rnd(3'b000), .z_inst(map_mul6_conv4_next), .status_inst());

reg [inst_sig_width+inst_exp_width:0] map1_mul_conv1, map1_mul_conv2, map1_mul_conv3, map1_mul_conv4;
reg [inst_sig_width+inst_exp_width:0] map2_mul_conv1, map2_mul_conv2, map2_mul_conv3, map2_mul_conv4;
reg [inst_sig_width+inst_exp_width:0] map_mul6_conv1, map_mul6_conv2, map_mul6_conv3, map_mul6_conv4;


always @(posedge clk,negedge rst_n) begin
    if(~rst_n)begin
        map1_mul_conv1 <= 32'b0;
        map1_mul_conv2 <= 32'b0;
        map1_mul_conv3 <= 32'b0;
        map1_mul_conv4 <= 32'b0;

        map2_mul_conv1 <= 32'b0;
        map2_mul_conv2 <= 32'b0;
        map2_mul_conv3 <= 32'b0;
        map2_mul_conv4 <= 32'b0;

        map_mul6_conv1 <= 32'b0;
        map_mul6_conv2 <= 32'b0;
        map_mul6_conv3 <= 32'b0;
        map_mul6_conv4 <= 32'b0;
    end
    else begin
        map1_mul_conv1 <= map1_mul_conv1_next;
        map1_mul_conv2 <= map1_mul_conv2_next;
        map1_mul_conv3 <= map1_mul_conv3_next;
        map1_mul_conv4 <= map1_mul_conv4_next;

        map2_mul_conv1 <= map2_mul_conv1_next;
        map2_mul_conv2 <= map2_mul_conv2_next;
        map2_mul_conv3 <= map2_mul_conv3_next;
        map2_mul_conv4 <= map2_mul_conv4_next;

        map_mul6_conv1 <= map_mul6_conv1_next;
        map_mul6_conv2 <= map_mul6_conv2_next;
        map_mul6_conv3 <= map_mul6_conv3_next;
        map_mul6_conv4 <= map_mul6_conv4_next;
    end
    
end

reg [inst_sig_width+inst_exp_width:0] add_outcome_1, add_outcome_2, add_outcome_6;

reg [inst_sig_width+inst_exp_width:0] conv1_output[0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] conv2_output[0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] conv1_output_shift[0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] conv2_output_shift[0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] conv1_output_next[0:5][0:5];
reg [inst_sig_width+inst_exp_width:0] conv2_output_next[0:5][0:5];

reg [inst_sig_width+inst_exp_width:0]  full_contected;

wire [inst_sig_width+inst_exp_width:0] x1,y1,z1,w1;


assign x1 = (cnt <= 107) ? map2_mul_conv1 : exp[0];
assign y1 = (cnt <= 107) ? map2_mul_conv2 : exp[1];
assign z1 = (cnt <= 107) ? map2_mul_conv3 : exp[2];
assign w1 = (cnt <= 107) ? map2_mul_conv4 : 32'b0_00000000_00000000000000000000000;

wire [inst_sig_width+inst_exp_width:0] store1, store2, store3, store4, store5, store6;

DW_fp_add_inst U53(.inst_a(map1_mul_conv1), .inst_b(map1_mul_conv2), 
            .inst_rnd(3'b000), .z_inst(store1), .status_inst());
DW_fp_add_inst U54(.inst_a(map1_mul_conv3), .inst_b(map1_mul_conv4),
            .inst_rnd(3'b000), .z_inst(store2), .status_inst());
DW_fp_add_inst U55(.inst_a(store1), .inst_b(store2),
            .inst_rnd(3'b000), .z_inst(add_outcome_1), .status_inst());

DW_fp_add_inst U52(.inst_a(x1), .inst_b(y1), 
            .inst_rnd(3'b000), .z_inst(store3), .status_inst());
DW_fp_add_inst U51(.inst_a(z1), .inst_b(w1),
            .inst_rnd(3'b000), .z_inst(store4), .status_inst());
DW_fp_add_inst U50(.inst_a(store3), .inst_b(store4),
            .inst_rnd(3'b000), .z_inst(add_outcome_2), .status_inst()); 

DW_fp_add_inst U56(.inst_a(map_mul6_conv1), .inst_b(map_mul6_conv2),
            .inst_rnd(3'b000), .z_inst(store5), .status_inst());
DW_fp_add_inst U59(.inst_a(map_mul6_conv3), .inst_b(map_mul6_conv4),    
            .inst_rnd(3'b000), .z_inst(store6), .status_inst());
DW_fp_add_inst U57(.inst_a(store5), .inst_b(store6),
            .inst_rnd(3'b000), .z_inst(add_outcome_6), .status_inst()); 



always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        full_contected <= 0;
    end
    else begin
        full_contected <= accumulate6;

    end

end

always @(*) begin
    conv1_output_shift = conv1_output;
    conv2_output_shift = conv2_output;

    if(cnt == 12 || cnt == 17 || cnt == 22 || cnt == 27 || cnt == 32 || cnt == 37 || cnt == 42 || cnt == 47 || 
    cnt == 52 || cnt == 57 || cnt == 62 || cnt == 67 || cnt == 72 || cnt == 77 || cnt == 82 || cnt == 87 || cnt == 92 || cnt == 97)begin
        // conv1_output_next[0] = conv1_output[1];
        for(integer i = 0; i < 5; i = i + 1)begin
            conv1_output_shift[i][0] = conv1_output[i + 1][1];
            conv1_output_shift[i][1] = conv1_output[i + 1][2];
            conv1_output_shift[i][2] = conv1_output[i + 1][3];
            conv1_output_shift[i][3] = conv1_output[i + 1][4];
            conv1_output_shift[i][4] = conv1_output[i + 1][0];
            conv1_output_shift[i][5] = conv1_output[i + 1][5];

            conv2_output_shift[i][0] = conv2_output[i + 1][1];
            conv2_output_shift[i][1] = conv2_output[i + 1][2];
            conv2_output_shift[i][2] = conv2_output[i + 1][3];
            conv2_output_shift[i][3] = conv2_output[i + 1][4];
            conv2_output_shift[i][4] = conv2_output[i + 1][0];
            conv2_output_shift[i][5] = conv2_output[i + 1][5];
        end
        
        conv1_output_shift[5][0] = conv1_output[0][1];
        conv1_output_shift[5][1] = conv1_output[0][2];
        conv1_output_shift[5][2] = conv1_output[0][3];
        conv1_output_shift[5][3] = conv1_output[0][4];
        conv1_output_shift[5][4] = conv1_output[0][0];
        conv1_output_shift[5][5] = conv1_output[0][5];

        conv2_output_shift[5][0] = conv2_output[0][1];
        conv2_output_shift[5][1] = conv2_output[0][2];
        conv2_output_shift[5][2] = conv2_output[0][3];
        conv2_output_shift[5][3] = conv2_output[0][4];
        conv2_output_shift[5][4] = conv2_output[0][0];
        conv2_output_shift[5][5] = conv2_output[0][5];
    end
    else if(cnt >= 7 && cnt < 97)begin
        for(integer i = 0; i < 6; i = i + 1)begin
            conv1_output_shift[i][0] = conv1_output[i][1];
            conv1_output_shift[i][1] = conv1_output[i][2];
            conv1_output_shift[i][2] = conv1_output[i][3];
            conv1_output_shift[i][3] = conv1_output[i][4];
            conv1_output_shift[i][4] = conv1_output[i][0];
            conv1_output_shift[i][5] = conv1_output[i][5];

            conv2_output_shift[i][0] = conv2_output[i][1];
            conv2_output_shift[i][1] = conv2_output[i][2];   
            conv2_output_shift[i][2] = conv2_output[i][3];
            conv2_output_shift[i][3] = conv2_output[i][4];
            conv2_output_shift[i][4] = conv2_output[i][0];
            conv2_output_shift[i][5] = conv2_output[i][5];            
        end
    end
end

wire ker1_add = (cnt == 7 || cnt == 12 || cnt == 17 || cnt == 22 || cnt == 27 || cnt == 32 || cnt == 37 || cnt == 42 || cnt == 47 || cnt == 52 || cnt == 57 || cnt == 62 || cnt == 67 || cnt == 72 || cnt == 77 || cnt == 82 || cnt == 87 || cnt == 92);
wire ker2_add = (cnt == 8 || cnt == 13 || cnt == 18 || cnt == 23 || cnt == 28 || cnt == 33 || cnt == 38 || cnt == 43 || cnt == 48 || cnt == 53 || cnt == 58 || cnt == 63 || cnt == 68 || cnt == 73 || cnt == 78 || cnt == 83 || cnt == 88 || cnt == 93);



DW_fp_add_inst U16(.inst_a(conv1_output_shift[0][0]), .inst_b(add_outcome_1), 
            .inst_rnd(3'b000), .z_inst(accumulate1), .status_inst());
DW_fp_add_inst U17(.inst_a(conv2_output_shift[0][0]), .inst_b(add_outcome_2), 
            .inst_rnd(3'b000), .z_inst(accumulate2), .status_inst());
DW_fp_add_inst U18(.inst_a(cnt > 99 ? add_outcome_1 : ker1_add ? conv1_output_shift[0][5] : conv2_output_shift[0][5]), .inst_b(add_outcome_6), 
            .inst_rnd(3'b000), .z_inst(accumulate6), .status_inst());



always @(*) begin
    
    conv1_output_next = conv1_output_shift;
    conv2_output_next = conv2_output_shift;
    if(ker1_add)begin
        conv1_output_next[0][5] = accumulate6;
    end
    else if(ker2_add)begin
        conv2_output_next[0][5] = accumulate6;
    end

    if(cnt >= 7 && cnt <= 97)begin
        conv1_output_next[0][0] = accumulate1;
        conv2_output_next[0][0] = accumulate2;
    end
    else if (cnt == 111)begin
        for(integer i = 0; i < 6; i = i + 1)begin
            for(integer j = 0; j < 6; j = j + 1)begin
                conv1_output_next[i][j] = 0;
                conv2_output_next[i][j] = 0;
            end
        end
    end
end
always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer  i = 0; i < 6 ; i = i + 1)begin
            for(integer  j = 0; j < 6 ; j = j + 1)begin
                conv1_output[i][j] <= 0;
                conv2_output[i][j] <= 0;
            end
        end
    end
    
    else begin
        conv1_output <= conv1_output_next;
        conv2_output <= conv2_output_next;
    end
end

reg [inst_exp_width+inst_sig_width:0] choose_maxpool[0:8];

always @(*) begin
    case (cnt)
        92:begin
            choose_maxpool[0] = conv1_output[2][1];
            choose_maxpool[1] = conv1_output[2][2];
            choose_maxpool[2] = conv1_output[2][3];
            choose_maxpool[3] = conv1_output[3][1];
            choose_maxpool[4] = conv1_output[3][2];
            choose_maxpool[5] = conv1_output[3][3];
            choose_maxpool[6] = conv1_output[4][1];
            choose_maxpool[7] = conv1_output[4][2];
            choose_maxpool[8] = conv1_output[4][3];
        end 
        93:begin
            choose_maxpool[0] = conv2_output[1][0];
            choose_maxpool[1] = conv2_output[1][1];
            choose_maxpool[2] = conv2_output[1][2];
            choose_maxpool[3] = conv2_output[2][0];
            choose_maxpool[4] = conv2_output[2][1];
            choose_maxpool[5] = conv2_output[2][2];
            choose_maxpool[6] = conv2_output[3][0];
            choose_maxpool[7] = conv2_output[3][1];
            choose_maxpool[8] = conv2_output[3][2];
        end
        94:begin
            choose_maxpool[0] = conv1_output[1][2];
            choose_maxpool[1] = conv1_output[1][3];
            choose_maxpool[2] = conv1_output[1][5];
            choose_maxpool[3] = conv1_output[2][2];
            choose_maxpool[4] = conv1_output[2][3];
            choose_maxpool[5] = conv1_output[2][5];
            choose_maxpool[6] = conv1_output[3][2];
            choose_maxpool[7] = conv1_output[3][3];
            choose_maxpool[8] = conv1_output[3][5];
        end
        95:begin
            choose_maxpool[0] = conv2_output[1][1];
            choose_maxpool[1] = conv2_output[1][2];
            choose_maxpool[2] = conv2_output[1][5];
            choose_maxpool[3] = conv2_output[2][1];
            choose_maxpool[4] = conv2_output[2][2];
            choose_maxpool[5] = conv2_output[2][5];
            choose_maxpool[6] = conv2_output[3][1];
            choose_maxpool[7] = conv2_output[3][2];
            choose_maxpool[8] = conv2_output[3][5];
        end
        96:begin
            choose_maxpool[0] = conv1_output[4][2];
            choose_maxpool[1] = conv1_output[4][3];
            choose_maxpool[2] = conv1_output[4][4];
            choose_maxpool[3] = conv1_output[5][2];
            choose_maxpool[4] = conv1_output[5][3];
            choose_maxpool[5] = conv1_output[5][4];
            choose_maxpool[6] = conv1_output[0][2];
            choose_maxpool[7] = conv1_output[0][3];
            choose_maxpool[8] = conv1_output[0][4];
        end
        97:begin
            choose_maxpool[0] = conv2_output[4][1];
            choose_maxpool[1] = conv2_output[4][2];
            choose_maxpool[2] = conv2_output[4][3];
            choose_maxpool[3] = conv2_output[5][1];
            choose_maxpool[4] = conv2_output[5][2];
            choose_maxpool[5] = conv2_output[5][3];
            choose_maxpool[6] = conv2_output[0][1];
            choose_maxpool[7] = conv2_output[0][2];
            choose_maxpool[8] = conv2_output[0][3];
        end
        98:begin
            choose_maxpool[0] = conv1_output[3][3];
            choose_maxpool[1] = conv1_output[3][4];
            choose_maxpool[2] = conv1_output[3][5];
            choose_maxpool[3] = conv1_output[4][3];
            choose_maxpool[4] = conv1_output[4][4];
            choose_maxpool[5] = conv1_output[4][5];
            choose_maxpool[6] = conv1_output[5][3];
            choose_maxpool[7] = conv1_output[5][4];
            choose_maxpool[8] = conv1_output[5][5];
        end
        99:begin
            choose_maxpool[0] = conv2_output[3][3];
            choose_maxpool[1] = conv2_output[3][4];
            choose_maxpool[2] = conv2_output[3][5];
            choose_maxpool[3] = conv2_output[4][3];
            choose_maxpool[4] = conv2_output[4][4];
            choose_maxpool[5] = conv2_output[4][5];
            choose_maxpool[6] = conv2_output[5][3];
            choose_maxpool[7] = conv2_output[5][4];
            choose_maxpool[8] = conv2_output[5][5];
        end
        default: begin
            for(integer i = 0; i < 9; i = i + 1)begin
                choose_maxpool[i] = 0;
            end
        end
    endcase
end


wire [inst_sig_width+inst_exp_width:0] cmp1, cmp2, cmp3, cmp4, cmp5, cmp6, cmp7;
DW_fp_cmp_inst U19(.inst_a(choose_maxpool[0]), .inst_b(choose_maxpool[1]), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp1), .z1_inst(), .status0_inst(), .status1_inst());
DW_fp_cmp_inst U20(.inst_a(choose_maxpool[2]), .inst_b(choose_maxpool[3]), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp2), .z1_inst(), .status0_inst(), .status1_inst());
DW_fp_cmp_inst U21(.inst_a(choose_maxpool[4]), .inst_b(choose_maxpool[5]), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp3), .z1_inst(), .status0_inst(), .status1_inst());
DW_fp_cmp_inst U22(.inst_a(choose_maxpool[6]), .inst_b(choose_maxpool[7]), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp4), .z1_inst(), .status0_inst(), .status1_inst());

DW_fp_cmp_inst U23(.inst_a(cmp1), .inst_b(cmp2), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp5), .z1_inst(), .status0_inst(), .status1_inst());
DW_fp_cmp_inst U24(.inst_a(cmp3), .inst_b(cmp4), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp6), .z1_inst(), .status0_inst(), .status1_inst());
DW_fp_cmp_inst U25(.inst_a(cmp5), .inst_b(cmp6), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(cmp7), .z1_inst(), .status0_inst(), .status1_inst());
DW_fp_cmp_inst U26(.inst_a(cmp7), .inst_b(choose_maxpool[8]), .inst_zctr(1'b1), .aeqb_inst(), .altb_inst(), .agtb_inst(), .unordered_inst()
                , .z0_inst(max_pooling_outcome_next), .z1_inst(), .status0_inst(), .status1_inst());


assign temp1 = cnt <= 100 ? Kernel_ch2_reg[0][1][0] : full_contected; 
assign temp2 = {~Kernel_ch2_reg[0][1][0][31] ,Kernel_ch2_reg[0][1][0][30:0]};
// assign temp3 = full_contected[2];

DW_fp_exp_inst U27(.inst_a(temp1), .z_inst(exp_plus), .status_inst());
DW_fp_exp_inst U28(.inst_a(temp2), .z_inst(exp_minus), .status_inst());

assign a = Opt_reg ? exp[0] : 32'b0_01111111_00000000000000000000000;
assign b = Opt_reg ? exp[1] : 32'b0_00000000_00000000000000000000000;
assign c = Opt_reg ? exp[0] : 32'b0_01111111_00000000000000000000000;
assign d = exp[1];

DW_fp_addsub_inst U40(.inst_a(a), .inst_b(b),.inst_op(1'b1) ,.inst_rnd(3'b000), .z_inst(exp_sub_next), .status_inst());
DW_fp_add_inst U30(.inst_a(c), .inst_b(d), .inst_rnd(3'b000), .z_inst(exp_sum_next), .status_inst());


wire [inst_sig_width+inst_exp_width:0] div = (cnt <= 108) ? Kernel_ch2_reg[0][0][1] : exp[0];
wire [inst_sig_width+inst_exp_width:0] div2 = (cnt <= 108) ? Kernel_ch2_reg[0][0][0] : exp_acc;

DW_fp_div_inst U31(.inst_a(div), .inst_b(div2), .inst_rnd(3'b000), .z_inst(activating_outcome_next), .status_inst());

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        for(integer i = 0; i < 3; i = i + 1)begin
            exp[i] <= 0;
        end
    end
    else if(cnt < 105)begin
        exp[0] <= exp_plus;
        exp[1] <= exp_minus;
        exp[2] <= 0;
    end
    
    else if(cnt <= 107)begin
        exp[0] <= exp[1];
        exp[1] <= exp[2];
        exp[2] <= exp_plus;
        
    end
    else if(cnt == 108)begin
        exp <= exp;
    end
    else begin
        exp[0] <= exp[1];
        exp[1] <= exp[2];
        exp[2] <= 0;
    end
    
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)begin
        exp_acc <= 0;
    end
    else if(cnt == 108)begin
        exp_acc <= add_outcome_2;
    end
    else begin
        exp_acc <= exp_acc;
    end
    
    
end

always @(*) begin
    if(cnt == 110 || cnt == 111 || cnt == 112)begin
       out = Kernel_ch1_reg[1][1][1];
       out_valid = 1;
    end
    else begin
        out = 0;
        out_valid = 0;
    end
end

endmodule



module DW_fp_mult_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_mult
    DW_fp_mult #(sig_width, exp_width, ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule


module DW_fp_sum4_inst( inst_a, inst_b, inst_c, inst_d, inst_rnd, z_inst, status_inst );

    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    input [inst_sig_width+inst_exp_width : 0] inst_a;
    input [inst_sig_width+inst_exp_width : 0] inst_b;
    input [inst_sig_width+inst_exp_width : 0] inst_c;
    input [inst_sig_width+inst_exp_width : 0] inst_d;
    input [2 : 0] inst_rnd;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_sum4
    DW_fp_sum4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .d(inst_d),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) );
endmodule

module DW_fp_add_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_add
    DW_fp_add #(sig_width, exp_width, ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule

module DW_fp_cmp_inst( inst_a, inst_b, inst_zctr, aeqb_inst, altb_inst,
agtb_inst, unordered_inst, z0_inst, z1_inst, status0_inst,
status1_inst);
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input inst_zctr;
    output aeqb_inst;
    output altb_inst;
    output agtb_inst;
    output unordered_inst;
    output [sig_width+exp_width : 0] z0_inst;
    output [sig_width+exp_width : 0] z1_inst;
    output [7 : 0] status0_inst;
    output [7 : 0] status1_inst;
    // Instance of DW_fp_cmp
    DW_fp_cmp #(sig_width, exp_width, ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .zctr(inst_zctr), .aeqb(aeqb_inst), 
    .altb(altb_inst), .agtb(agtb_inst), .unordered(unordered_inst),
    .z0(z0_inst), .z1(z1_inst), .status0(status0_inst),
    .status1(status1_inst) );
endmodule

module DW_fp_div_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    parameter faithful_round = 0;
    
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_div
    DW_fp_div #(sig_width, exp_width, ieee_compliance, faithful_round) U1
    ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst));
endmodule

module DW_fp_exp_inst( inst_a, z_inst, status_inst );
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch = 0;

    input [inst_sig_width+inst_exp_width : 0] inst_a;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_exp
    DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U1 (
    .a(inst_a),
    .z(z_inst),
    .status(status_inst) );
endmodule

module DW_fp_addsub_inst( inst_a, inst_b, inst_rnd, inst_op, z_inst,
status_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    input inst_op;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_addsub
    DW_fp_addsub #(sig_width, exp_width, ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd),
    .op(inst_op), .z(z_inst), .status(status_inst) );
endmodule



