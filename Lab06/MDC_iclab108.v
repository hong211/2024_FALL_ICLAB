//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

// synopsys translate_off
`include "HAMMING_IP.v"
// synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;

wire signed [10:0] in_data_decode;
wire [4:0] mode_decode;
reg [1:0] mode;
reg [4:0] cnt;

reg signed[10:0] multi_small1_a, multi_small1_b;
wire signed[21:0] multi_small1_out;

reg signed[21:0] multi_mid1_a, multi_mid2_a;
reg signed[10:0] multi_mid1_b, multi_mid2_b;
wire signed[31:0] multi_mid1_out, multi_mid2_out;

reg signed[33:0] multi_large1_a;
reg signed[10:0] multi_large1_b;
wire signed[43:0] multi_large1_out;

reg signed[10:0] input_data[0:8];

reg signed[21:0] two_by_two[0:5];
reg signed[33:0] three_by_three[0:2];
reg signed[45:0] four_by_four;

wire signed[21:0] deter_substract1;

reg signed[33:0] mid_add1_a, mid_add1_b, mid_add2_a, mid_add2_b;
wire signed[33:0] mid_add1_out, mid_add2_out;

reg signed[45:0] large_add_a, large_add_b;
wire signed[45:0] large_add_out;

// ================ hamming ==============================

HAMMING_IP #(.IP_BIT(11)) I_HAMMING_IP_indata(.IN_code(in_data), .OUT_code(in_data_decode)); 
HAMMING_IP #(.IP_BIT(5)) I_HAMMING_IP_mode(.IN_code(in_mode), .OUT_code(mode_decode)); 

// ===============================================================
// ================ multiplier ==============================

assign multi_small1_out = multi_small1_a * multi_small1_b;
assign multi_mid1_out = multi_mid1_a * multi_mid1_b;
assign multi_mid2_out = multi_mid2_a * multi_mid2_b;
assign multi_large1_out = multi_large1_a * multi_large1_b;


assign deter_substract1 = multi_small1_out + ~ multi_large1_out[21:0] + 1;

assign mid_add1_out = mid_add1_a + mid_add1_b;
assign mid_add2_out = mid_add2_a + mid_add2_b;
assign large_add_out = large_add_a + large_add_b;

// ===============================================================



always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        cnt <= 0;
    end
    else begin
        
        if((in_valid || cnt > 0) && cnt < 17)begin
            cnt <= cnt + 1;
        end
        
        else begin
            cnt <= 0;
        end
    end
end

always @(posedge clk)begin
   
    if(in_valid && cnt == 0 && mode_decode == 5'b00100)begin
        mode <= 2'b00;
    end
    else if(in_valid && cnt == 0 && mode_decode == 5'b00110)begin
        mode <= 2'b01;
    end
    else if(in_valid && cnt == 0 && mode_decode == 5'b10110)begin
        mode <= 2'b11;
    end
    else begin
        mode <= mode;
    end
end

genvar i;
generate
    for(i = 0; i < 8; i = i + 1)begin
        always @(posedge clk)begin
            if(in_valid)begin
                input_data[i] <= input_data[i + 1];
            end
            else begin
                input_data[i] <= input_data[i + 1];
            end
        end
    end
endgenerate

always @(posedge clk)begin
    if(in_valid)begin
        input_data[8] <= in_data_decode;
    end
    else begin
        input_data[8] <= input_data[8];
    end
end



always @(*) begin
    if(mode == 0)begin
        multi_small1_a = input_data[3];
    end    
    else if(mode == 1)begin
        if(cnt[1:0] != 2'b01 && cnt <= 12)begin
            multi_small1_a = input_data[3];
        end
        else if(cnt == 9)begin
            multi_small1_a = input_data[1];
        end
        else if(cnt == 13 || cnt == 14)begin
            multi_small1_a = input_data[0];
        end
        else begin
            multi_small1_a = 0;
        end
        
    end
    else if(mode == 3)begin
        if(cnt == 6 || cnt == 7 || cnt == 8)begin
            multi_small1_a = input_data[3];
        end
        else if(cnt == 9)begin
            multi_small1_a = input_data[0];
        end
        else begin
            multi_small1_a = 0;
        end
    end
    else begin
        multi_small1_a = 0;
    end
end

always @(*) begin
    if(mode == 0)begin
        multi_small1_b = input_data[8];
    end    
    else if(mode == 1)begin
        if(cnt[1:0] != 2'b01 && cnt <= 12)begin
            multi_small1_b = input_data[8];
        end
        else if(cnt == 9)begin
            multi_small1_b = input_data[7];
           
        end
        else if(cnt == 13 || cnt == 14)begin
            multi_small1_b = input_data[6];
            
        end
        else begin
            multi_small1_b = 0;
        end
        
    end
    else if(mode == 3)begin
        if(cnt == 6 || cnt == 7 || cnt == 8)begin
            multi_small1_b = input_data[8];
        end
        else if(cnt == 9)begin
            multi_small1_b = input_data[7];
        end
        else begin
            multi_small1_b = 0;
        end
    end
    else begin 
        multi_small1_b = 0;
    end
end



always @(*) begin
   if(mode == 1)begin
        if(cnt == 8)begin
            multi_mid1_a = {{11{input_data[1][10]}},input_data[1]}; 
        end
        else if(cnt == 9 || cnt == 13)begin
            multi_mid1_a = two_by_two[1]; 
        end
        else if(cnt == 10 || cnt == 14)begin
            multi_mid1_a = two_by_two[3];
        end
        else if(cnt == 11 || cnt == 15)begin
            multi_mid1_a = two_by_two[0];
        end
        else begin
            multi_mid1_a = 0;
            
        end

    end
    else if(mode == 3)begin
        if(cnt == 7 || cnt == 8)begin
            multi_mid1_a = {{11{input_data[8][10]}},input_data[8]};
        end

        else if(cnt == 9)begin
            multi_mid1_a = two_by_two[4];
            
        end
        else if(cnt == 10)begin
            multi_mid1_a = two_by_two[2];
            
        end
        else if(cnt == 11 || cnt == 12)begin
            multi_mid1_a = two_by_two[0];
            
        end
        else if(cnt == 13)begin
            multi_mid1_a = {{22{two_by_two[2][21]}} ,two_by_two[2]};
        end
        else begin
            multi_mid1_a = 0;
            
        end
    end
    else begin
        multi_mid1_a = 0;
        
    end
end


always @(*) begin
   if(mode == 1)begin
        if(cnt == 8)begin
            multi_mid1_b = input_data[7];
        end

        else if(cnt == 9 || cnt == 13 || cnt == 10 || cnt == 14 || cnt == 11 || cnt == 15)begin
            multi_mid1_b = input_data[8];
        end
        
        else begin
            
            multi_mid1_b = 0;
       
        end

    end
    else if(mode == 3)begin
        if(cnt == 7 || cnt == 8)begin
            multi_mid1_b = input_data[2];
        end
        else if(cnt == 9 || cnt == 10 || cnt == 11 || cnt == 12)begin
            multi_mid1_b = input_data[8];
        end
        else if(cnt == 13)begin
            multi_mid1_b = input_data[4];
        end 
        else begin
            multi_mid1_b = 0;
        end
    end
    else begin
        multi_mid1_b = 0;
    end
end


always @(*) begin
   if(mode == 1)begin
        if(cnt == 8)begin
            
            multi_mid2_a = {{11{input_data[3][10]}},input_data[3]};
           
        end
        else if(cnt == 10 || cnt == 14)begin
            multi_mid2_a = two_by_two[2];
        end
        else if(cnt == 11 || cnt == 15)begin
            
            multi_mid2_a = two_by_two[4];
          
        end
        else if(cnt == 12 || cnt == 16)begin
            multi_mid2_a = two_by_two[1];
        end
        else begin
           
            multi_mid2_a = 0;

        end

    end
    else if(mode == 3)begin
        if(cnt == 7 || cnt == 8)begin
            multi_mid2_a = {{11{input_data[4][10]}},input_data[4]};
        end

        else if(cnt == 9)begin
            multi_mid2_a = two_by_two[1];
        end
        else if(cnt == 10 || cnt == 12)begin
            multi_mid2_a = two_by_two[3];

        end
        else if(cnt == 11)begin
            multi_mid2_a = two_by_two[5];
        end
        else if(cnt == 13)begin
            multi_mid2_a = two_by_two[2];
        end
        else begin
            multi_mid2_a = 0;
        end
    end
    else begin
        multi_mid2_a = 0;
    end
end





always @(*) begin
  
    if(cnt == 8 && mode == 1)begin
        multi_mid2_b = input_data[5];
    end
    else if((cnt == 7 || cnt == 8) && mode == 3)begin
        
        multi_mid2_b = input_data[6];
    end
    else if(cnt == 13)begin
        multi_mid2_b = input_data[4];
    end
    else if(cnt >= 9 )begin
        multi_mid2_b = input_data[8];
    end

    else begin
        
        multi_mid2_b = 0;
    end

end

always @(*) begin
    if(mode == 0)begin
        multi_large1_b = input_data[7];
    end    
    else if(mode == 1)begin
        if(cnt[1:0] != 2'b01 && cnt <= 12)begin
            
            multi_large1_b = input_data[7];
        end
        else if(cnt == 9)begin
            
            multi_large1_b = input_data[5];
        end
        else if(cnt == 13 || cnt == 14)begin
            
            multi_large1_b = input_data[4];
        end
        else begin
            
            multi_large1_b = 0;
        end
    end
    else if(mode == 3)begin
        if(cnt == 6 || cnt == 7 || cnt == 8)begin
            multi_large1_b = input_data[7];
        end
        else if(cnt == 9)begin
            multi_large1_b = input_data[4];
        end
        else if(cnt >= 10)begin
            multi_large1_b = input_data[8];
        end

        else begin
           
            multi_large1_b = 0;
        end
    end
    else begin
        
        multi_large1_b = 0;
    end
    
end



always @(*) begin
    if(mode == 0)begin
        multi_large1_a = input_data[4];
    end    
    else if(mode == 1)begin
        if(cnt[1:0] != 2'b01 && cnt <= 12)begin
            multi_large1_a = input_data[4];
        end
        else if(cnt == 9)begin
            multi_large1_a = input_data[3];
        end
        else if(cnt == 13 || cnt == 14)begin
            multi_large1_a = input_data[2];
        end
        else begin 
            multi_large1_a = 0;
        end
        
    end
    else if(mode == 3)begin
        if(cnt == 6 || cnt == 7 || cnt == 8)begin
            multi_large1_a = input_data[4];
        end
        else if(cnt == 9)begin
            multi_large1_a = input_data[3];
        end
        else if(cnt == 10)begin
            multi_large1_a = two_by_two[5];
        end
        else if(cnt == 11)begin
            multi_large1_a = two_by_two[4];
        end
        else if(cnt == 12)begin
            multi_large1_a = two_by_two[1];
        end
        else if(cnt == 13)begin
            multi_large1_a = four_by_four[33:0];
        end
        else if(cnt == 14)begin
            multi_large1_a = three_by_three[2];
        end
        else if(cnt == 15)begin
            multi_large1_a = three_by_three[1];
        end
        else if(cnt == 16)begin
            multi_large1_a = three_by_three[0];
        end

        else begin
            multi_large1_a = 0;
        end
       
    end
    else begin
        multi_large1_a = 0;
    end
    
    
end















always @(*) begin
    if(mode == 1)begin
        if(cnt == 8)begin
            mid_add1_a = {{2{multi_mid1_out[31]}},multi_mid1_out[31:0]};
        end
        else if(cnt >= 10 && cnt != 13)begin // cnt != 13
            mid_add1_a = three_by_three[0];
        end
        else begin
            mid_add1_a = 0;
            
        end
    end
    else if(mode == 3)begin
        if(cnt == 7 || cnt == 8)begin
            mid_add1_a = {{2{multi_mid1_out[31]}},multi_mid1_out[31:0]};
        end
        else if(cnt == 11)begin
            mid_add1_a = three_by_three[0];
        end
        else if(cnt == 12)begin
            mid_add1_a = three_by_three[1];
        end
        
        else begin
            mid_add1_a = 0;
        end
    end
    else begin
        mid_add1_a = 0;
        
    end
end



always @(*) begin
    if(mode == 1)begin
        if(cnt == 8)begin
            mid_add1_b = ~ {{2{multi_mid2_out[31]}},multi_mid2_out[31:0]} + 1;
        end
        else if(cnt == 9 || cnt == 13 || cnt == 11 || cnt == 15)begin
            mid_add1_b = {{2{multi_mid1_out[31]}},multi_mid1_out[31:0]};
           
        end
        else if(cnt == 10 || cnt == 14)begin
            mid_add1_b = ~{{2{multi_mid1_out[31]}},multi_mid1_out[31:0]} + 1;
        end
        else begin
            mid_add1_b = 0;
            
        end
    end
    else if(mode == 3)begin
        if(cnt == 8 || cnt == 7)begin
            mid_add1_b = ~ {{2{multi_mid2_out[31]}},multi_mid2_out[31:0]} + 1;
        end
        
        else if(cnt >= 9)begin
            mid_add1_b = {{2{multi_mid1_out[31]}},multi_mid1_out[31:0]};
        end
        else begin
            mid_add1_b = 0;
        end
    end
    else begin
        mid_add1_b = 0;
        
    end
end


always @(*) begin
    if(mode == 1)begin
        if(cnt >= 10 && cnt != 13)begin  // cnt != 13
            mid_add2_a = three_by_three[1];
        end
        else begin
            mid_add2_a = 0;
            
        end
    end
    else if(mode == 3)begin
       if(cnt == 10)begin
            mid_add2_a = three_by_three[0];
        end
        else if(cnt == 12 || cnt == 13)begin
            mid_add2_a = three_by_three[2];
        end
        else begin
            mid_add2_a = 0;
        end
    end
    else begin
        mid_add2_a = 0;
       
    end
end



always @(*) begin
    if(mode == 1)begin
        if(((cnt == 10 || cnt == 14 || cnt == 12 || cnt == 16)))begin
            mid_add2_b = {{2{multi_mid2_out[31]}},multi_mid2_out[31:0]};
        end
        else if(((cnt == 11 || cnt == 15)))begin
            mid_add2_b = ~{{2{multi_mid2_out[31]}},multi_mid2_out[31:0]} + 1;
        end

        else begin
            mid_add2_b = 0;
        end
    end
    else if(mode == 3)begin
       if(cnt == 9 || cnt == 12 || cnt == 13)begin
            mid_add2_b = {{2{multi_mid2_out[31]}},multi_mid2_out[31:0]};
        end
        else if(cnt == 10 || cnt == 11)begin
            mid_add2_b = ~{{2{multi_mid2_out[31]}},multi_mid2_out[31:0]} + 1;
        end
        else begin
          
            mid_add2_b = 0;
        end
    end
    else begin
      
        mid_add2_b = 0;
    end
end



always @(*) begin
    if(cnt == 9 || cnt == 12 || cnt == 14 || cnt == 16)begin
        large_add_b = {{2{multi_large1_out[43]}},multi_large1_out[43:0]};
    end
    else if(cnt == 10 || cnt == 11 || cnt == 13 || cnt == 15)begin
        large_add_b = ~ {{2{multi_large1_out[43]}},multi_large1_out[43:0]} + 1;
    end
    else begin
        large_add_b = 0;
    end

end


always @(*) begin
   
    if(cnt == 10)begin
        large_add_a = three_by_three[1];
    end
    else if(cnt == 11 || cnt == 12 || cnt >= 14)begin
        large_add_a = four_by_four;
    end
    else begin
        large_add_a = 0;
    end
   
end


always @(posedge clk) begin

        if(mode == 1 && cnt == 13)begin
            four_by_four <= three_by_three[1];
        end
        else if(mode == 3)begin
            if(cnt == 10)begin
                four_by_four <= {{12{mid_add1_out[33]}},mid_add1_out};
            end
            else if(cnt >= 11)begin
                four_by_four <= large_add_out;
            end
            else begin
                four_by_four <= 0;
            end
        end
        else begin
            four_by_four <= four_by_four;
        end
   
end

always @(posedge clk) begin
    
        // three_by_three <= three_by_three;
        if(mode == 0 )begin
            if(cnt[1:0] != 2'b01)begin
                three_by_three[0] <= three_by_three[1];
                three_by_three[1] <= three_by_three[2];
                three_by_three[2] <= deter_substract1;
            end
            else begin
                three_by_three <= three_by_three;
            end
            
        end
        else if(mode == 1)begin
            three_by_three[0] <= mid_add1_out;
            three_by_three[1] <= mid_add2_out;
            if(cnt == 13)begin
                three_by_three[2] <= three_by_three[0];
            end
            else begin
                three_by_three[2] <= three_by_three[2];
            end
        end
        else if(mode == 3)begin
            if(cnt == 9)begin
                three_by_three[1] <= mid_add1_out;
                three_by_three[0] <= mid_add2_out;
                three_by_three[2] <= three_by_three[2];
            end
            else if(cnt == 10)begin
                three_by_three[0] <= mid_add2_out;
                three_by_three[1] <= large_add_out[33:0];
                three_by_three[2] <= three_by_three[2];
            end
            else if(cnt == 11)begin
                three_by_three[0] <= mid_add1_out;
                three_by_three[1] <= three_by_three[1];
                three_by_three[2] <= mid_add2_out;
            end
            else if(cnt == 12)begin
                three_by_three[0] <= three_by_three[0];
                three_by_three[1] <= mid_add1_out;
                three_by_three[2] <= mid_add2_out;
            end
            else if(cnt == 13)begin
                three_by_three[0] <= three_by_three[0];
                three_by_three[1] <= three_by_three[1];
                three_by_three[2] <= mid_add2_out;
            end
            else begin
                three_by_three <= three_by_three;
            end
        end
        else begin
            three_by_three <= three_by_three;
        end

end


always @(posedge clk) begin
        two_by_two <= two_by_two;
        if(mode == 0 && cnt[1:0] != 2'b01)begin
            for(integer i = 0; i < 5; i = i + 1)begin
                two_by_two[i] <= two_by_two[i + 1];
            end
            two_by_two[5] <= three_by_three[0][21:0];
        end
        else if(mode == 1)begin
            if(cnt == 6 || cnt == 7 )begin
                two_by_two[2] <= deter_substract1;
                two_by_two[1] <= two_by_two[2];
                two_by_two[0] <= two_by_two[1];
            end
            else if(cnt == 8)begin
                two_by_two[3] <= mid_add1_out;
                two_by_two[2] <= deter_substract1;
                two_by_two[1] <= two_by_two[2];
                two_by_two[0] <= two_by_two[1];
            end
            else if(cnt == 9)begin
                two_by_two[4] <= deter_substract1;
            end
            else if(cnt == 10)begin
                two_by_two[5] <= deter_substract1;
            end
            else if(cnt == 11)begin
                two_by_two[2] <= deter_substract1;
            end
            else if(cnt == 12)begin
                two_by_two[0] <= two_by_two[5];
                two_by_two[1] <= two_by_two[2];
                two_by_two[2] <= deter_substract1;
            end
            else if(cnt == 13)begin
                two_by_two[3] <= deter_substract1;
            end
            else if(cnt == 14)begin
                two_by_two[4] <= deter_substract1;
            end
            
        end
        else begin
            if(cnt == 6)begin
                two_by_two[2] <= deter_substract1;
                two_by_two[1] <= two_by_two[2];
                two_by_two[0] <= two_by_two[1];
            end
            else if(cnt == 7)begin
                two_by_two[3] <= mid_add1_out;
                two_by_two[2] <= deter_substract1;
                two_by_two[1] <= two_by_two[2];
                two_by_two[0] <= two_by_two[1];
            end
            else if(cnt == 8)begin
                two_by_two[4] <= mid_add1_out;
                two_by_two[2] <= deter_substract1;
                two_by_two[1] <= two_by_two[2];
                two_by_two[0] <= two_by_two[1];
            end
            else if(cnt == 9)begin
                two_by_two[5] <= deter_substract1;
            end
        end

end


always @(*) begin
    if(cnt == 17)begin
        case (mode)
            0:  out_data = {two_by_two[0][21],two_by_two[0],
                            two_by_two[1][21],two_by_two[1],
                            two_by_two[2][21],two_by_two[2],
                            two_by_two[3][21],two_by_two[3],
                            two_by_two[4][21],two_by_two[4],
                            two_by_two[5][21],two_by_two[5],
                            three_by_three[0][21],three_by_three[0][21:0],
                            three_by_three[1][21],three_by_three[1][21:0],
                            three_by_three[2][21],three_by_three[2][21:0]}; 
            1:  out_data = {{17{three_by_three[2][33]}},three_by_three[2][33:0],
                            {17{four_by_four[33]}},four_by_four[33:0],
                            {17{three_by_three[0][33]}},three_by_three[0][33:0],
                            {17{three_by_three[1][33]}},three_by_three[1][33:0]};
            3:  out_data =  {{161{four_by_four[45]}},four_by_four};
            default: 
                out_data = 0;
        endcase
    //     if(mode == 0)begin
    //         out_data = {two_by_two[0][21],two_by_two[0],
    //                     two_by_two[1][21],two_by_two[1],
    //                     two_by_two[2][21],two_by_two[2],
    //                     two_by_two[3][21],two_by_two[3],
    //                     two_by_two[4][21],two_by_two[4],
    //                     two_by_two[5][21],two_by_two[5],
    //                     three_by_three[0][21],three_by_three[0][21:0],
    //                     three_by_three[1][21],three_by_three[1][21:0],
    //                     three_by_three[2][21],three_by_three[2][21:0]};
    //     end
    //     else if(mode == 1)begin
    //         out_data = {{17{three_by_three[2][33]}},three_by_three[2][33:0],
    //                     {17{four_by_four[33]}},four_by_four[33:0],
    //                     {17{three_by_three[0][33]}},three_by_three[0][33:0],
    //                     {17{three_by_three[1][33]}},three_by_three[1][33:0]};
    //     end
    //     else if(mode == 3)begin
    //         out_data =  {{161{four_by_four[45]}},four_by_four};
    //     end
    //     else begin
    //         out_data = 0;
    //     end
    end
    else begin
        out_data = 0;
    end
end



always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        out_valid <= 0;
    end
    else begin
        out_valid <= cnt == 16;
    end
end




endmodule