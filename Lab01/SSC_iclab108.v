//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output out_valid;
output [8:0] out_change;    

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

//================================================================
//    DESIGN
//================================================================
reg [3:0] a1, a2, a3, a4, a5, a6, a7, a8;
reg [4:0] a9, a10, a11, a12, a13, a14, a15, a16;

// 1. Check the card number
always @(*) begin
    a9 = card_num[63:60] + card_num[63:60];
    if(card_num[63] == 1 || (card_num[62] && card_num[61]) || (card_num[62] && card_num[60])) a1 = a9 - 9;
    else a1 = a9;
end
always @(*) begin
    a10 = card_num[55:52] + card_num[55:52];
    if(card_num[55] == 1 || (card_num[54] && card_num[53]) || (card_num[54] && card_num[52])) a2 = a10 - 9;
    else a2 = a10;
end
always @(*) begin
    a11 = card_num[47:44] + card_num[47:44];
    if(card_num[47] == 1 || (card_num[46] && card_num[45]) || (card_num[46] && card_num[44])) a3 = a11 - 9;
    else a3 = a11;
end
always @(*) begin
    a12 = card_num[39:36] + card_num[39:36];
    if(card_num[39] == 1 || (card_num[38] && card_num[37]) || (card_num[38] && card_num[36])) a4 = a12 - 9;
    else a4 = a12;
end
always @(*) begin
    a13 = card_num[31:28] + card_num[31:28];
    if(card_num[31] == 1 || (card_num[30] && card_num[29]) || (card_num[30] && card_num[28])) a5 = a13 - 9;
    else a5 = a13;
end

always @(*) begin
    a14 = card_num[23:20] + card_num[23:20];
    if(card_num[23] == 1 || (card_num[22] && card_num[21]) || (card_num[22] && card_num[20])) a6 = a14 - 9;
    else a6 = a14;
end

always @(*) begin
    a15 = card_num[15:12] + card_num[15:12];
    if(card_num[15] == 1 || (card_num[14] && card_num[13]) || (card_num[14] && card_num[12])) a7 = a15 - 9;
    else a7 = a15;
end



always @(*) begin
    a16 = card_num[7:4] + card_num[7:4];
    if(card_num[7] == 1 || (card_num[6] && card_num[5]) || (card_num[6] && card_num[4])) a8 = a16 - 9;
    else a8 = a16;
    
end

reg [7:0] sum;
assign sum = a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + card_num[3:0] + card_num[11:8] + card_num[19:16] + card_num[27:24] + card_num[35:32] + card_num[43:40] + card_num[51:48] + card_num[59:56];

// check card number is valid card number:(0 ~ 144)
reg out_valid_temp;
always @(*) begin
    if(sum == 50 || sum == 60 || sum == 70 || sum == 80 || sum == 90 || sum == 100 || sum == 110 || sum == 120) out_valid_temp = 1;
    else out_valid_temp = 0;
end

assign out_valid = out_valid_temp;

// 2. Calculate the total price
wire [7:0] total_price [0:7];

assign total_price[0] = ((snack_num[28])? price[31:28] : 0) + ((snack_num[29])? price[31:28]<<1 : 0) 
                    +(((snack_num[30])? price[31:28] << 2 : 0) + ((snack_num[31])? price[31:28]<<3 : 0));

assign total_price[1] =  ((snack_num[24])? price[27:24] : 0) + ((snack_num[25])? price[27:24]<<1 : 0) 
                    +(((snack_num[26])? price[27:24] << 2 : 0) + ((snack_num[27])? price[27:24]<<3 : 0));

assign total_price[2] = ((snack_num[20])? price[23:20] : 0) + ((snack_num[21])? price[23:20]<<1 : 0) 
                    +(((snack_num[22])? price[23:20]<<2 : 0) + ((snack_num[23])? price[23:20]<<3 : 0));

assign total_price[3] = ((snack_num[16])? price[19:16] : 0) + ((snack_num[17])? price[19:16]<<1 : 0) 
                    +(((snack_num[18])? price[19:16]<<2 : 0) + ((snack_num[19])? price[19:16]<<3 : 0));

assign total_price[4] =  ((snack_num[12])? price[15:12] : 0) + ((snack_num[13])? price[15:12]<<1 : 0) 
                    +(((snack_num[14])? price[15:12]<<2 : 0) + ((snack_num[15])? price[15:12]<<3 : 0));

assign total_price[5] = ((snack_num[8])? price[11:8] : 0) + ((snack_num[9])? price[11:8]<<1 : 0) 
                    +(((snack_num[10])? price[11:8]<<2 : 0) + ((snack_num[11])? price[11:8]<<3 : 0));

assign total_price[6] =  ((snack_num[4])? price[7:4] : 0) + ((snack_num[5])? price[7:4]<<1 : 0) 
                    +(((snack_num[6])? price[7:4]<<2 : 0) + ((snack_num[7])? price[7:4]<<3 : 0));

assign total_price[7] = ((snack_num[0])? price[3:0] : 0) + ((snack_num[1])? price[3:0]<<1 : 0) 
                    +(((snack_num[2])? price[3:0]<<2 : 0) + ((snack_num[3])? price[3:0]<<3 : 0));


// 3.sort the total price (from large to small)
wire [7:0] total_price_sorted [0:7];
wire [7:0] temp [0:29];

assign {temp[0], temp[2]} = (total_price[0] > total_price[2]) ? {total_price[0], total_price[2]} : {total_price[2], total_price[0]};
assign {temp[1], temp[3]} = (total_price[1] > total_price[3]) ? {total_price[1], total_price[3]} : {total_price[3], total_price[1]}; 
assign {temp[4], temp[6]} = (total_price[4] > total_price[6]) ? {total_price[4], total_price[6]} : {total_price[6], total_price[4]};
assign {temp[5], temp[7]} = (total_price[5] > total_price[7]) ? {total_price[5], total_price[7]} : {total_price[7], total_price[5]};
assign {temp[8], temp[12]} = (temp[0] > temp[4]) ? {temp[0], temp[4]} : {temp[4], temp[0]};
assign {temp[9], temp[13]} = (temp[1] > temp[5]) ? {temp[1], temp[5]} : {temp[5], temp[1]};
assign {temp[10], temp[14]} = (temp[2] > temp[6]) ? {temp[2], temp[6]} : {temp[6], temp[2]};
assign {temp[11], temp[15]} = (temp[3] > temp[7]) ? {temp[3], temp[7]} : {temp[7], temp[3]};

assign {total_price_sorted[0], temp[16]} = (temp[8] > temp[9]) ? {temp[8], temp[9]} : {temp[9], temp[8]};
assign {temp[17], temp[18]} = (temp[10] > temp[11]) ? {temp[10], temp[11]} : {temp[11], temp[10]};
assign {temp[19], temp[20]} = (temp[12] > temp[13]) ? {temp[12], temp[13]} : {temp[13], temp[12]};
assign {temp[21], total_price_sorted[7]} = (temp[14] > temp[15]) ? {temp[14], temp[15]} : {temp[15], temp[14]};

assign {temp[22], temp[24]} = (temp[17] > temp[19]) ? {temp[17], temp[19]} : {temp[19], temp[17]};
assign {temp[23], temp[25]} = (temp[18] > temp[20]) ? {temp[18], temp[20]} : {temp[20], temp[18]};
assign {temp[26], temp[28]} = (temp[16] > temp[24]) ? {temp[16], temp[24]} : {temp[24], temp[16]};
assign {temp[27], temp[29]} = (temp[23] > temp[21]) ? {temp[23], temp[21]} : {temp[21], temp[23]};


assign {total_price_sorted[1], total_price_sorted[2]} = (temp[26] > temp[22]) ? {temp[26], temp[22]} : {temp[22], temp[26]};
assign {total_price_sorted[3], total_price_sorted[4]} = (temp[27] > temp[28]) ? {temp[27], temp[28]} : {temp[28], temp[27]};
assign {total_price_sorted[5], total_price_sorted[6]} = (temp[25] > temp[29]) ? {temp[25], temp[29]} : {temp[29], temp[25]};

// 4. Calculate the change
wire signed [9:0] b2, b3, b4, b5, b6, b7, b8, b9;
reg [8:0] out_change_temp;

assign b2 = out_valid ? input_money - total_price_sorted[0] : -1;
assign b3 = out_valid ? b2 - total_price_sorted[1] : -1;
assign b4 = out_valid ? b3 - total_price_sorted[2] : -1;
assign b5 = out_valid ? b4 - total_price_sorted[3] : -1;
assign b6 = out_valid ? b5 - total_price_sorted[4] : -1;
assign b7 = out_valid ? b6 - total_price_sorted[5] : -1;
assign b8 = out_valid ? b7 - total_price_sorted[6] : -1;
assign b9 = out_valid ? b8 - total_price_sorted[7] : -1;



always @(*) begin
    if(b2[9]) out_change_temp = input_money;
    else if(b3[9]) out_change_temp = b2;
    else if(b4[9]) out_change_temp = b3;
    else if(b5[9]) out_change_temp = b4;
    else if(b6[9]) out_change_temp = b5;
    else if(b7[9]) out_change_temp = b6;
    else if(b8[9]) out_change_temp = b7;
    else if(b9[9]) out_change_temp = b8;
    else out_change_temp = b9;
  
end

assign out_change = out_change_temp;

endmodule

