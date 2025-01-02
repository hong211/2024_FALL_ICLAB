module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input [1:0] in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg[7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output reg[31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output reg[7:0]  awlen_s_inf,
    output reg       awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output [127:0] wdata_s_inf,
    output reg        wlast_s_inf,
    output reg        wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output reg        bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]   arid_s_inf,
    output reg[31:0]  araddr_s_inf,
    output reg[7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output reg        arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output reg        rready_s_inf
    
);

// Your Design

parameter IDLE = 0;
parameter READ_DRAM = 2;
parameter OUTPUT = 1;
parameter DETERMINE = 5;
parameter AWAIT = 6;

reg [7:0] dram_data0[0:15];
reg [7:0] dram_data1[0:15];
reg [7:0] dram_data2[0:15];
reg [7:0] dram_data3[0:15];
reg [7:0] dram_data4[0:15];
reg [7:0] dram_data5[0:15];
reg [7:0] dram_data_shift[0:15];

reg [2:0] state, next_state;
reg [3:0] pic_no_reg;
reg [1:0] ratio_mode_reg;
reg [1:0] mode_reg;
reg r_valid_reg;

reg [8:0] cnt;
reg [7:0] auto_focus[0:5][0:5];

wire [7:0] diff_outcome [0:4];


// focus add layer
reg [9:0] six_first;
reg [8:0] six_second;
reg [10:0] six_third;
reg [13:0] six_total;
// reg [13:0] six_total_temp;

// focus add layer
reg [9:0] four_first;
reg [12:0] four_total;

// focus add layer
reg [9:0] two_tatal;


// exposure add layer
reg [8:0] first_1, first_2, first_3, first_4;
reg [7:0] first_5, first_6;

reg [10:0] second_1;
reg [9:0] second_2;

reg [17:0] third;

// average

reg [7:0] max, min;
reg [7:0] max_temp, min_temp;
reg [9:0] max_sum, min_sum;
reg [7:0] threshold_max, threshold_min;




reg [1:0] focus_ans [0:15];
reg [7:0] exposure_ans [0:15];
reg [7:0] average_ans [0:15];
reg flag [0:15];
reg [3:0] gobal_shifer[0:15];

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        cnt <= 0;
    end
    else begin
        case (state)
            READ_DRAM: begin
                if(bvalid_s_inf && bready_s_inf)begin
                    cnt <= 0;
                end
                else begin
                    cnt <= ((rready_s_inf && rvalid_s_inf) || cnt > 190) ? cnt + 1 : 0;
                end
            end
            default: cnt <= 0;
        endcase
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        IDLE:begin
            next_state = in_valid ? DETERMINE : IDLE;
        end
        DETERMINE:begin
            if(gobal_shifer[pic_no_reg] == 8)begin
                next_state = OUTPUT;
            end
            else if((mode_reg == 2'b01 && ((gobal_shifer[pic_no_reg] == 6 && ratio_mode_reg == 0) || (gobal_shifer[pic_no_reg] == 7 && ratio_mode_reg == 1)|| (gobal_shifer[pic_no_reg] == 7 && ratio_mode_reg == 0)))) begin
                next_state = OUTPUT;
            end
            else if(flag[pic_no_reg] && (mode_reg == 0 || (mode_reg == 2'b01 && ratio_mode_reg == 2) || mode_reg == 2))begin
                next_state = OUTPUT;
            end
            else begin
                next_state = AWAIT;
            end
        end 
        AWAIT:begin
            next_state = (arready_s_inf && arvalid_s_inf) ? READ_DRAM : AWAIT;
        end
        READ_DRAM:begin
            next_state = ((bvalid_s_inf && bready_s_inf) || cnt == 199) ? OUTPUT : READ_DRAM;
        end
        OUTPUT:begin
            next_state = IDLE;
        end        
        default: next_state = IDLE;
    endcase
end

// axi constants
assign arid_s_inf = 4'b0000;
assign arsize_s_inf = 3'b100;
assign arburst_s_inf = 2'b01;
assign awid_s_inf = 4'b0000;
assign awsize_s_inf = 3'b100;
assign awburst_s_inf = 2'b01;

always @(*) begin
    if(state == AWAIT || state == READ_DRAM)begin
        arlen_s_inf =  191;
    end
    else begin
        arlen_s_inf = 0;
    end
end

always @(*) begin
    if(state == AWAIT || state == READ_DRAM)begin
        araddr_s_inf = pic_no_reg * 12'hc00 + 17'h10000;
    end
    else begin
        araddr_s_inf = 0;
    end
end

always @(*) begin
    if(state == AWAIT)begin
        arvalid_s_inf = 1;
    end
    else begin
        arvalid_s_inf = 0;
    end
end


always @(*) begin
    if(state == READ_DRAM && cnt < 192)begin
        rready_s_inf = 1;
    end
    else begin
        rready_s_inf = 0;
    end
end

always @(*) begin
    if(state == READ_DRAM && rready_s_inf && r_valid_reg && cnt <= 2)begin
        awvalid_s_inf = 1;
    end
    else begin
        awvalid_s_inf = 0;
    end
end

always @(*) begin
    if(state == READ_DRAM && rready_s_inf && r_valid_reg)begin
        awaddr_s_inf = pic_no_reg * 12'hc00 + 17'h10000;
        awlen_s_inf = 191;
    end
    else begin
        awaddr_s_inf = 0;
        awlen_s_inf = 0;
    end
end

always @(*) begin
    if(state == READ_DRAM && cnt >= 3)begin
        wvalid_s_inf = 1;
        bready_s_inf = 1;
    end
    else begin
        wvalid_s_inf = 0;
        bready_s_inf = 0;
    end
end

assign wdata_s_inf = {dram_data5[15], dram_data5[14], dram_data5[13], dram_data5[12], dram_data5[11], 
                        dram_data5[10], dram_data5[9], dram_data5[8], dram_data5[7], dram_data5[6], 
                        dram_data5[5], dram_data5[4], dram_data5[3], dram_data5[2], dram_data5[1], dram_data5[0]};

always @(*) begin
    if(state == READ_DRAM && cnt == 197 )begin
        wlast_s_inf = 1;
    end
    else begin
        wlast_s_inf = 0;
    end
end

always @(posedge clk) begin
    r_valid_reg <= rvalid_s_inf;
end

always @(posedge clk) begin
    if(in_valid)begin
        pic_no_reg <= in_pic_no;
        ratio_mode_reg <= in_ratio_mode;
        mode_reg <= in_mode;
    end
    else begin
        pic_no_reg <= pic_no_reg;
        ratio_mode_reg <= ratio_mode_reg;
        mode_reg <= mode_reg;
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM  && rvalid_s_inf && rready_s_inf)begin
        dram_data0[15] <= rdata_s_inf[127:120];
        dram_data0[14] <= rdata_s_inf[119:112];
        dram_data0[13] <= rdata_s_inf[111:104];
        dram_data0[12] <= rdata_s_inf[103:96];
        dram_data0[11] <= rdata_s_inf[95:88];
        dram_data0[10] <= rdata_s_inf[87:80];
        dram_data0[ 9] <= rdata_s_inf[79:72];
        dram_data0[ 8] <= rdata_s_inf[71:64];
        dram_data0[ 7] <= rdata_s_inf[63:56];
        dram_data0[ 6] <= rdata_s_inf[55:48];
        dram_data0[ 5] <= rdata_s_inf[47:40];
        dram_data0[ 4] <= rdata_s_inf[39:32];
        dram_data0[ 3] <= rdata_s_inf[31:24];
        dram_data0[ 2] <= rdata_s_inf[23:16];
        dram_data0[ 1] <= rdata_s_inf[15:8];
        dram_data0[ 0] <= rdata_s_inf[7:0];
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data0[i] <= 0;
        end
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM && mode_reg == 1)begin
        case (ratio_mode_reg)
            0:begin
                for(integer i = 0; i < 16; i = i + 1)begin
                    dram_data1[i] <= dram_data0[i] >> 2;
                end
            end
            1:begin
                for(integer i = 0; i < 16; i = i + 1)begin
                    dram_data1[i] <= dram_data0[i] >> 1;
                end
            end
            3: begin
                for(integer i = 0; i < 16; i = i + 1)begin
                    dram_data1[i] <= (dram_data0[i][7]) ? 255 : dram_data0[i] << 1;
                end
            end
            default: dram_data1 <= dram_data0;
        endcase
    end
    else if(state == READ_DRAM)begin
        dram_data1 <= dram_data0;
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data1[i] <= 0;
        end
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM )begin
        dram_data2 <= dram_data1;
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data2[i] <= 0;
        end
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM)begin
        dram_data3 <= dram_data2;
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data3[i] <= 0;
        end
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM )begin
        dram_data4 <= dram_data3;
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data4[i] <= 0;
        end
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM )begin
        dram_data5 <= dram_data4;
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data5[i] <= 0;
        end
    end
end

always @(*) begin
    if(cnt > 66 && cnt <= 130)begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data_shift[i] <= dram_data2[i] >> 1;
        end
    end
    else begin
        for(int i = 0; i < 16; i = i + 1)begin
            dram_data_shift[i] <= dram_data2[i] >> 2;
        end
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM && cnt <= 168)begin
        if((cnt >= 29 && cnt <= 40) || (cnt >= 93 && cnt <= 104) || (cnt >= 157 && cnt <= 168))begin
            auto_focus[5][0] <= auto_focus[5][3];
            auto_focus[5][1] <= auto_focus[5][4];
            auto_focus[5][2] <= auto_focus[5][5];
            auto_focus[5][3] <= auto_focus[0][0] + ((cnt[0] == 1) ? (dram_data_shift[13]) : (dram_data_shift[0]));
            auto_focus[5][4] <= auto_focus[0][1] + ((cnt[0] == 1) ? (dram_data_shift[14]) : (dram_data_shift[1]));
            auto_focus[5][5] <= auto_focus[0][2] + ((cnt[0] == 1) ? (dram_data_shift[15]) : (dram_data_shift[2]));

            auto_focus[4][3] <= auto_focus[5][0]; auto_focus[4][0] <= auto_focus[4][3];
            auto_focus[4][4] <= auto_focus[5][1]; auto_focus[4][1] <= auto_focus[4][4];
            auto_focus[4][5] <= auto_focus[5][2]; auto_focus[4][2] <= auto_focus[4][5];
            
            auto_focus[3][3] <= auto_focus[4][0]; auto_focus[3][0] <= auto_focus[3][3];
            auto_focus[3][4] <= auto_focus[4][1]; auto_focus[3][1] <= auto_focus[3][4];
            auto_focus[3][5] <= auto_focus[4][2]; auto_focus[3][2] <= auto_focus[3][5];

            auto_focus[2][3] <= auto_focus[3][0]; auto_focus[2][0] <= auto_focus[2][3];
            auto_focus[2][4] <= auto_focus[3][1]; auto_focus[2][1] <= auto_focus[2][4];
            auto_focus[2][5] <= auto_focus[3][2]; auto_focus[2][2] <= auto_focus[2][5];

            auto_focus[1][3] <= auto_focus[2][0]; auto_focus[1][0] <= auto_focus[1][3];
            auto_focus[1][4] <= auto_focus[2][1]; auto_focus[1][1] <= auto_focus[1][4];
            auto_focus[1][5] <= auto_focus[2][2]; auto_focus[1][2] <= auto_focus[1][5];

            auto_focus[0][3] <= auto_focus[1][0]; auto_focus[0][0] <= auto_focus[0][3];
            auto_focus[0][4] <= auto_focus[1][1]; auto_focus[0][1] <= auto_focus[0][4];
            auto_focus[0][5] <= auto_focus[1][2]; auto_focus[0][2] <= auto_focus[0][5];


        end
        else begin
           auto_focus <= auto_focus;
        end
        
    end
    else if(state == READ_DRAM)begin
        if(cnt == 174)begin
            auto_focus[0][0] <= auto_focus[1][0];  auto_focus[0][1] <= auto_focus[2][0];
            auto_focus[1][0] <= auto_focus[1][1];  auto_focus[1][1] <= auto_focus[2][1];
            auto_focus[2][0] <= auto_focus[1][2];  auto_focus[2][1] <= auto_focus[2][2];
            auto_focus[3][0] <= auto_focus[1][3];  auto_focus[3][1] <= auto_focus[2][3];
            auto_focus[4][0] <= auto_focus[1][4];  auto_focus[4][1] <= auto_focus[2][4];
            auto_focus[5][0] <= auto_focus[1][5];  auto_focus[5][1] <= auto_focus[2][5];

            auto_focus[0][2] <= auto_focus[3][0];  auto_focus[0][3] <= auto_focus[4][0];
            auto_focus[1][2] <= auto_focus[3][1];  auto_focus[1][3] <= auto_focus[4][1];
            auto_focus[2][2] <= auto_focus[3][2];  auto_focus[2][3] <= auto_focus[4][2];
            auto_focus[3][2] <= auto_focus[3][3];  auto_focus[3][3] <= auto_focus[4][3];
            auto_focus[4][2] <= auto_focus[3][4];  auto_focus[4][3] <= auto_focus[4][4];
            auto_focus[5][2] <= auto_focus[3][5];  auto_focus[5][3] <= auto_focus[4][5];

            auto_focus[0][4] <= auto_focus[5][0];  auto_focus[0][5] <= auto_focus[0][0];
            auto_focus[1][4] <= auto_focus[5][1];  auto_focus[1][5] <= auto_focus[0][1];
            auto_focus[2][4] <= auto_focus[5][2];  auto_focus[2][5] <= auto_focus[0][2];
            auto_focus[3][4] <= auto_focus[5][3];  auto_focus[3][5] <= auto_focus[0][3];
            auto_focus[4][4] <= auto_focus[5][4];  auto_focus[4][5] <= auto_focus[0][4];
            auto_focus[5][4] <= auto_focus[5][5];  auto_focus[5][5] <= auto_focus[0][5];

        end

        else begin
            auto_focus[0] <= auto_focus[1];
            auto_focus[1] <= auto_focus[2];
            auto_focus[2] <= auto_focus[3];
            auto_focus[3] <= auto_focus[4];
            auto_focus[4] <= auto_focus[5];
            auto_focus[5] <= auto_focus[0];
        end

    end
    else begin
        for(integer i = 0; i < 6; i = i + 1)begin
            for(integer j = 0; j < 6; j = j + 1)begin
                auto_focus[i][j] <= 0;
            end
        end
    end
end

abs_diiffer diff0(.a(auto_focus[0][0]), .b(auto_focus[0][1]), .clk(clk), .c(diff_outcome[0]));
abs_diiffer diff1(.a(auto_focus[0][1]), .b(auto_focus[0][2]), .clk(clk), .c(diff_outcome[1]));
abs_diiffer diff2(.a(auto_focus[0][2]), .b(auto_focus[0][3]), .clk(clk), .c(diff_outcome[2]));
abs_diiffer diff3(.a(auto_focus[0][3]), .b(auto_focus[0][4]), .clk(clk), .c(diff_outcome[3]));
abs_diiffer diff4(.a(auto_focus[0][4]), .b(auto_focus[0][5]), .clk(clk), .c(diff_outcome[4]));

always @(posedge clk) begin
    if(READ_DRAM && cnt >= 170 && cnt <= 181)begin
        six_first <= diff_outcome[0] + diff_outcome[1] + diff_outcome[2];
        six_second <= diff_outcome[3] + diff_outcome[4];
    end
    else begin
        six_first <= 0;
        six_second <= 0;
    end
end

always @(posedge clk) begin
    six_third <= six_first + six_second;
end

always @(posedge clk) begin
    if(cnt == 184 || cnt == 185)begin
        six_total <= six_total / 6;
    end
    else if(state == READ_DRAM)begin
        six_total <= six_total + six_third;
    end
    else begin
        six_total <= 0;
    end
end


always @(posedge clk) begin
    if(READ_DRAM && ((cnt >= 171 && cnt <= 174) || (cnt >= 177 && cnt <= 180)))begin
        four_first <= diff_outcome[1] + diff_outcome[2] + diff_outcome[3];
    end
    else begin
        four_first <= 0;
    end
end

always @(posedge clk) begin
    if(cnt == 183 || cnt == 184)begin
        four_total <= four_total >> 2;
    end
    else if(state == READ_DRAM)begin
        four_total <= four_total + four_first;
    end
    else begin
        four_total <= 0;
    end
end

always @(posedge clk) begin
    if(cnt == 183 || cnt == 184)begin
        two_tatal <= two_tatal >> 1;
    end
    else if(state == READ_DRAM && ((cnt >= 172 && cnt <= 173) || (cnt >= 178 && cnt <= 179)))begin
        two_tatal <= two_tatal + diff_outcome[2];
    end
    else if(cnt == 198)begin
        if(mode_reg == 2'b01)begin
            two_tatal <= third[17:10];
        end
        else if(mode_reg == 2'b10)begin
            two_tatal <= max_sum >> 1;
        end
        else begin 
            two_tatal <= (two_tatal >= four_total && two_tatal >= six_total) ? 0 : (four_total >= six_total) ? 1 : 2;
        end
    end
    
    else if(state == DETERMINE && (flag[pic_no_reg] && (mode_reg == 0 || mode_reg == 2|| (mode_reg == 2'b01 && ratio_mode_reg == 2))))begin
        two_tatal <= mode_reg == 2'b01 ? exposure_ans[pic_no_reg] : mode_reg == 2'b00 ? focus_ans[pic_no_reg] : average_ans[pic_no_reg];
    end
    
    else if(state == READ_DRAM)begin
        two_tatal <= two_tatal;
    end
    else begin
        two_tatal <= 0;
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM)begin
        first_1 <= dram_data_shift[0] + dram_data_shift[1] + dram_data_shift[2];
        first_2 <= dram_data_shift[3] + dram_data_shift[4] + dram_data_shift[5];
        first_3 <= dram_data_shift[6] + dram_data_shift[7] + dram_data_shift[8];
        first_4 <= dram_data_shift[9] + dram_data_shift[10] + dram_data_shift[11];
        first_5 <= dram_data_shift[12] + dram_data_shift[13];
        first_6 <= dram_data_shift[14] + dram_data_shift[15];
    end
    else begin
        first_1 <= 0;
        first_2 <= 0;
        first_3 <= 0;
        first_4 <= 0;
        first_5 <= 0;
        first_6 <= 0;
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM )begin
        second_1 <= first_1 + first_2 + first_3;
        second_2 <= first_4 + first_5 + first_6;
    end
    else begin
        second_1 <= 0;
        second_2 <= 0;
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM)begin
        third <= third + second_1 + second_2;
    end
    else begin
        third <= 0;
    end
end


find_max_min max_min(.a(dram_data1[0]), .b(dram_data1[1]), .c(dram_data1[2]), .d(dram_data1[3]), .e(dram_data1[4]), 
        .f(dram_data1[5]), .g(dram_data1[6]), .h(dram_data1[7]), .i(dram_data1[8]), .j(dram_data1[9]), .k(dram_data1[10]), .l(dram_data1[11]), 
        .m(dram_data1[12]), .n(dram_data1[13]), .o(dram_data1[14]), .p(dram_data1[15]), .clk(clk), .result_max(max_temp), .result_min(min_temp));


assign threshold_max = (cnt == 3 || cnt == 67 || cnt == 131) ? 'h00 : max; 
assign threshold_min = (cnt == 3 || cnt == 67 || cnt == 131) ? 'hff : min;

always @(posedge clk) begin
    if(state == READ_DRAM && cnt >= 3)begin
        max <= max_temp > threshold_max ? max_temp : threshold_max;
        min <= min_temp < threshold_min ? min_temp : threshold_min;
    end
    else begin
        max <= 0;
        min <= 0;
    end
end

always @(posedge clk) begin
    if(state == READ_DRAM && (cnt == 195 || cnt == 67 || cnt == 131))begin
        max_sum <= max_sum + max;
        min_sum <= min_sum + min;
    end
    else if(state == READ_DRAM && cnt == 196)begin
        max_sum <= max_sum / 3;
        min_sum <= min_sum / 3;
    end
    else if(state == READ_DRAM && cnt == 197)begin
        max_sum <= max_sum  + min_sum;
        min_sum <= 0;
    end
    else if(state == READ_DRAM)begin
        max_sum <= max_sum;
        min_sum <= min_sum;
    end
    else begin
        max_sum <= 0;
        min_sum <= 0;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 16; i = i + 1)begin
            flag[i] <= 0;
        end
    end
    else begin
        flag <= flag;
        if(state == READ_DRAM && cnt == 197)begin
            flag[pic_no_reg] <= 1;
        end
        
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 16; i = i + 1)begin
            focus_ans[i] <= 0;
        end
    end
    else begin
        focus_ans <= focus_ans;
        if(state == READ_DRAM && cnt == 198)begin
            focus_ans[pic_no_reg] <= (two_tatal >= four_total && two_tatal >= six_total) ? 0 : (four_total >= six_total) ? 1 : 2;
        end
        else if(gobal_shifer[pic_no_reg] == 8)begin
            focus_ans[pic_no_reg] <= 0;
        end
        
    end
end


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 16; i = i + 1)begin
            exposure_ans[i] <= 0;
        end
    end
    else begin
        exposure_ans <= exposure_ans;
        if(state == READ_DRAM && cnt == 198)begin
            exposure_ans[pic_no_reg] <= third[17:10];
        end
        else if(gobal_shifer[pic_no_reg] == 8)begin
            exposure_ans[pic_no_reg] <= 0;
        end
        
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 16; i = i + 1)begin
            average_ans[i] <= 0;
        end
    end
    else begin
        if(state == READ_DRAM && cnt == 198)begin
            average_ans[pic_no_reg] <= max_sum >> 1;;
        end
        else if(gobal_shifer[pic_no_reg] == 8)begin
            average_ans[pic_no_reg] <= 0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0; i < 16; i = i + 1)begin
            gobal_shifer[i] <= 0;
        end
    end
    else begin
        gobal_shifer <= gobal_shifer;
        
        if(mode_reg == 1 && ratio_mode_reg == 0 && state == DETERMINE)begin
            gobal_shifer[pic_no_reg] <= gobal_shifer[pic_no_reg] <= 5 ? gobal_shifer[pic_no_reg] + 2 : 8;
        end
        else if(mode_reg == 1 && ratio_mode_reg == 1 && state == DETERMINE)begin
            gobal_shifer[pic_no_reg] <= gobal_shifer[pic_no_reg] <= 6 ? gobal_shifer[pic_no_reg] + 1 : 8;
        end
        else if(mode_reg == 1 && ratio_mode_reg == 3 && state == DETERMINE)begin
            gobal_shifer[pic_no_reg] <= gobal_shifer[pic_no_reg] > 0 ? (gobal_shifer[pic_no_reg] == 8) ? 8 : gobal_shifer[pic_no_reg] - 1 : 0;
        end
    end
end



always @(*) begin
    if(state == OUTPUT)begin
        out_data = two_tatal;
    end
    else begin
        out_data = 0;
    end
end

always @(*) begin
    if(state == OUTPUT)begin
        out_valid = 1;
    end
    else begin
        out_valid = 0;
    end
end

endmodule


module abs_diiffer (
    input [7:0] a,
    input [7:0] b,
    input clk,
    output reg [7:0] c
);

wire [7:0] temp1, temp2;
assign {temp1, temp2} = (a > b) ? {a, b} : {b, a};

always @(posedge clk) begin
    c <= temp1 - temp2;
end

endmodule


module find_max_min (
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    input [7:0] d,
    input [7:0] e,
    input [7:0] f,
    input [7:0] g,
    input [7:0] h,
    input [7:0] i,
    input [7:0] j,
    input [7:0] k,
    input [7:0] l,
    input [7:0] m,
    input [7:0] n,
    input [7:0] o,
    input [7:0] p,
    input clk,
    output reg [7:0] result_max,
    output reg [7:0] result_min
);
    wire [7:0] temp_max[0:7];
    wire [7:0] temp_min[0:7];
    wire [7:0] temp_max_second[0:3], temp_min_second[0:3];
    reg [7:0] temp_max_third[0:1], temp_min_third[0:1];

    assign {temp_max[0], temp_min[0]} = (a > b) ? {a, b} : {b, a};
    assign {temp_max[1], temp_min[1]} = (c > d) ? {c, d} : {d, c};
    assign {temp_max[2], temp_min[2]} = (e > f) ? {e, f} : {f, e};
    assign {temp_max[3], temp_min[3]} = (g > h) ? {g, h} : {h, g};
    assign {temp_max[4], temp_min[4]} = (i > j) ? {i, j} : {j, i};
    assign {temp_max[5], temp_min[5]} = (k > l) ? {k, l} : {l, k};
    assign {temp_max[6], temp_min[6]} = (m > n) ? {m, n} : {n, m};
    assign {temp_max[7], temp_min[7]} = (o > p) ? {o, p} : {p, o};

    assign temp_max_second[0] = (temp_max[0] > temp_max[1]) ? temp_max[0] : temp_max[1];
    assign temp_max_second[1] = (temp_max[2] > temp_max[3]) ? temp_max[2] : temp_max[3];
    assign temp_max_second[2] = (temp_max[4] > temp_max[5]) ? temp_max[4] : temp_max[5];
    assign temp_max_second[3] = (temp_max[6] > temp_max[7]) ? temp_max[6] : temp_max[7];

    assign temp_min_second[0] = (temp_min[0] < temp_min[1]) ? temp_min[0] : temp_min[1];
    assign temp_min_second[1] = (temp_min[2] < temp_min[3]) ? temp_min[2] : temp_min[3];
    assign temp_min_second[2] = (temp_min[4] < temp_min[5]) ? temp_min[4] : temp_min[5];
    assign temp_min_second[3] = (temp_min[6] < temp_min[7]) ? temp_min[6] : temp_min[7];

    always @(posedge clk) begin
        temp_max_third[0] <= (temp_max_second[0] > temp_max_second[1]) ? temp_max_second[0] : temp_max_second[1];
        temp_max_third[1] <= (temp_max_second[2] > temp_max_second[3]) ? temp_max_second[2] : temp_max_second[3];

        temp_min_third[0] <= (temp_min_second[0] < temp_min_second[1]) ? temp_min_second[0] : temp_min_second[1];
        temp_min_third[1] <= (temp_min_second[2] < temp_min_second[3]) ? temp_min_second[2] : temp_min_second[3];
    end

    always @(*) begin
        result_max = (temp_max_third[0] > temp_max_third[1]) ? temp_max_third[0] : temp_max_third[1];
        result_min = (temp_min_third[0] < temp_min_third[1]) ? temp_min_third[0] : temp_min_third[1];
    end

    
  


endmodule