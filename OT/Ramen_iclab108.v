module Ramen(
    // Input Registers
    input clk, 
    input rst_n, 
    input in_valid,
    input selling,
    input portion, 
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


//==============================================//
//             Parameter and Integer            //
//==============================================//

// ramen_type
parameter TONKOTSU = 0;
parameter TONKOTSU_SOY = 1;
parameter MISO = 2;
parameter MISO_SOY = 3;

// initial ingredient
parameter NOODLE_INIT = 12000;
parameter BROTH_INIT = 41000;
parameter TONKOTSU_SOUP_INIT =  9000;
parameter MISO_INIT = 1000;
parameter SOY_SAUSE_INIT = 1500;


parameter IDLE = 0;
parameter BUY = 1;
parameter OUTPUT = 2;

reg [1:0]cs, ns;
reg [1:0] ramen_type_reg;
reg portion_reg;
reg [15:0] noodle, broth, tonkotsu_soup, miso, soy_sause;
reg [15:0] noodle_next, broth_next, tonkotsu_soup_next, miso_next, soy_sause_next;
reg [2:0] cnt;

reg [6:0] tonku,tonku_soy,mi, mi_soy;


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        ramen_type_reg <= 0;
        portion_reg <= 0;
    end
    else begin
        if(in_valid && cnt == 0)begin
          ramen_type_reg <= ramen_type;
        end
        else begin
          ramen_type_reg <= ramen_type_reg;
        end

        if(in_valid && cnt == 1)begin
          portion_reg <= portion;
        end
        else begin
          portion_reg <= portion_reg;
        end
    end
end
//==============================================//
//                 reg declaration              //
//==============================================// 


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
       cnt <= 0;
    end
    else if(cnt == 3)begin
      cnt <= 0;
    end
    else if(cnt != 0 || in_valid)begin
      cnt <= cnt + 1;
    end
    else begin
      cnt <= 0;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
      cs <= IDLE;
    end
    else begin
      cs <= ns;
    end
end

always @(*) begin
    case (cs)
        IDLE: ns = (in_valid) ? BUY : IDLE;
        BUY: ns = (selling) ? BUY :  OUTPUT;
        OUTPUT : ns = IDLE;
        default: ns = IDLE;
    endcase
end

always @(posedge clk , negedge rst_n) begin
    if(~rst_n)begin
        noodle <= 0;
        broth <=0;
        tonkotsu_soup <= 0;
        soy_sause <= 0;
        miso <= 0;
    end
    else begin
        noodle <= noodle_next;
        broth <= broth_next;
        tonkotsu_soup <= tonkotsu_soup_next;
        soy_sause <= soy_sause_next;
        miso <= miso_next;
    end
end



always @(*) begin
    case (cs)
        IDLE:begin
            noodle_next = NOODLE_INIT;
        end 
        BUY:begin
            if(cnt == 3 && success)begin
                noodle_next = noodle - (portion_reg ? 150 : 100);
            end
            else begin
                noodle_next = noodle;
            end
            
        end
        OUTPUT:begin
            noodle_next = NOODLE_INIT;
        end
        default: begin
            noodle_next = 0;
        end
    endcase
end


always @(*) begin
    case (cs)
        IDLE:begin
            broth_next = BROTH_INIT;
        end 
        BUY:begin
            if(cnt == 3 && success)begin
                if(portion_reg == 0)begin
                    if(ramen_type_reg == MISO)begin
                        broth_next = broth - 400;
                    end
                    else begin
                        broth_next = broth - 300;
                    end
                end

                else begin
                    if(ramen_type_reg == MISO)begin
                        broth_next = broth - 650;
                    end
                    else begin
                        broth_next = broth - 500;
                    end
                end
            end
            else begin
                broth_next = broth;
            end
            
        end
        OUTPUT:begin
            broth_next = BROTH_INIT;
        end
        default: begin
            broth_next = 0;
        end
    endcase
end

always @(*) begin
    case (cs)
        IDLE:begin
            tonkotsu_soup_next = TONKOTSU_SOUP_INIT;
        end 
        BUY:begin
            if(cnt == 3 && success)begin
                if(portion_reg == 0)begin
                    if(ramen_type_reg == TONKOTSU)begin
                        tonkotsu_soup_next = tonkotsu_soup - 150;
                    end
                    else if(ramen_type_reg == TONKOTSU_SOY) begin
                        tonkotsu_soup_next = tonkotsu_soup - 100;
                    end
                    else if(ramen_type_reg == MISO) begin
                        tonkotsu_soup_next = tonkotsu_soup;
                    end
                    else begin
                        tonkotsu_soup_next = tonkotsu_soup - 70;
                    end
                end
               else begin
                    if(ramen_type_reg == TONKOTSU)begin
                        tonkotsu_soup_next = tonkotsu_soup - 200;
                    end
                    else if(ramen_type_reg == TONKOTSU_SOY) begin
                        tonkotsu_soup_next = tonkotsu_soup - 150;
                    end
                    else if(ramen_type_reg == MISO) begin
                        tonkotsu_soup_next = tonkotsu_soup;
                    end
                    else begin
                        tonkotsu_soup_next = tonkotsu_soup - 100;
                    end
               end
                
            end
            else begin
                tonkotsu_soup_next = tonkotsu_soup;
            end
            
        end
        OUTPUT:begin
            tonkotsu_soup_next = TONKOTSU_SOUP_INIT;
        end
        default: begin
            tonkotsu_soup_next = 0;
        end
    endcase
end

always @(*) begin
    case (cs)
        IDLE:begin
            soy_sause_next = SOY_SAUSE_INIT;
        end 
        BUY:begin
            if(cnt == 3 && success)begin 
                if(portion_reg == 0)begin
                    if(ramen_type_reg == TONKOTSU)begin
                        soy_sause_next = soy_sause;
                    end
                    else if(ramen_type_reg == TONKOTSU_SOY) begin
                        soy_sause_next = soy_sause - 30;
                    end
                    else if(ramen_type_reg == MISO) begin
                        soy_sause_next = soy_sause;
                    end
                    else begin
                        soy_sause_next = soy_sause - 15;
                    end
                end
               else begin
                    if(ramen_type_reg == TONKOTSU)begin
                        soy_sause_next = soy_sause;
                    end
                    else if(ramen_type_reg == TONKOTSU_SOY) begin
                        soy_sause_next = soy_sause - 50;
                    end
                    else if(ramen_type_reg == MISO) begin
                        soy_sause_next = soy_sause;
                    end
                    else begin
                        soy_sause_next = soy_sause - 25;
                    end
               end
            end
            else begin
                soy_sause_next = soy_sause;
            end
            
        end
        OUTPUT:begin
            soy_sause_next = SOY_SAUSE_INIT;
        end
        default: begin
            soy_sause_next = 0;
        end
    endcase
end



always @(*) begin
    case (cs)
        IDLE:begin
            miso_next = MISO_INIT;
        end 
        BUY:begin
            if(cnt == 3 && success)begin 
               if(portion_reg == 0)begin
                    if(ramen_type_reg == TONKOTSU)begin
                        miso_next = miso;
                    end
                    else if(ramen_type_reg == TONKOTSU_SOY) begin
                        miso_next = miso;
                    end
                    else if(ramen_type_reg == MISO) begin
                        miso_next = miso - 30;
                    end
                    else begin
                        miso_next = miso - 15;
                    end
                end
               else begin
                    if(ramen_type_reg == TONKOTSU)begin
                        miso_next = miso;
                    end
                    else if(ramen_type_reg == TONKOTSU_SOY) begin
                        miso_next = miso;
                    end
                    else if(ramen_type_reg == MISO) begin
                        miso_next = miso  - 50;
                    end
                    else begin
                        miso_next = miso - 25;
                    end
               end
            end
            else begin
                miso_next = miso;
            end
            
        end
        OUTPUT:begin
            miso_next = MISO_INIT;
        end
        default: begin
            miso_next = 0;
        end
    endcase
end















always @(*) begin
    if(cs == BUY && cnt == 3)begin
        out_valid_order = 1;
        if(portion_reg == 0)begin
            if(ramen_type_reg == TONKOTSU)begin
                success = (noodle >= 100) && (broth >= 300) && (tonkotsu_soup >= 150);
            end
            else if(ramen_type_reg == TONKOTSU_SOY)begin
                success = (noodle >= 100) && (broth >= 300) && (tonkotsu_soup >= 100) && (soy_sause >= 30);
            end
            else if(ramen_type_reg == MISO)begin
                success = (noodle >= 100) && (broth >= 400)&& (miso >= 30);
            end
            else begin
                success = (noodle >= 100) && (broth >= 300) && (tonkotsu_soup >= 70) && (soy_sause >= 15) && (miso >= 15);
            end
        end

         else begin
            if(ramen_type_reg == TONKOTSU)begin
                success = (noodle >= 150) && (broth >= 500) && (tonkotsu_soup >= 200);
            end
            else if(ramen_type_reg == TONKOTSU_SOY)begin
                success = (noodle >= 150) && (broth >= 500) && (tonkotsu_soup >= 150) && (soy_sause >= 50);
            end
            else if(ramen_type_reg == MISO)begin
                success = (noodle >= 150) && (broth >= 650)&& (miso >= 50);
            end
            else begin
                success = (noodle >= 150) && (broth >= 500) && (tonkotsu_soup >= 100) && (soy_sause >= 25) && (miso >= 25);
            end
        end
    end
    else begin
        out_valid_order = 0;
        success = 0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        tonku <= 0;
    end
    else begin
        if(cs == IDLE)begin
            tonku <= 0;
        end
        else if(cs == BUY && cnt == 3 && success && ramen_type_reg == TONKOTSU) begin
            tonku <= tonku + 1;
        end
        else begin
            tonku <= tonku;
        end
    end
end


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        tonku_soy <= 0;
    end
    else begin
        if(cs == IDLE)begin
            tonku_soy <= 0;
        end
        else if(cs == BUY && cnt == 3 && success && ramen_type_reg == TONKOTSU_SOY) begin
            tonku_soy <= tonku_soy + 1;
        end
        else begin
            tonku_soy <= tonku_soy;
        end
    end
end



always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        mi <= 0;
    end
    else begin
        if(cs == IDLE)begin
            mi <= 0;
        end
        else if(cs == BUY && cnt == 3 && success && ramen_type_reg == MISO) begin
            mi <= mi + 1;
        end
        else begin
            mi <= mi;
        end
    end
end


always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        mi_soy <= 0;
    end
    else begin
        if(cs == IDLE)begin
            mi_soy <= 0;
        end
        else if(cs == BUY && cnt == 3 && success && ramen_type_reg == MISO_SOY) begin
            mi_soy <= mi_soy + 1;
        end
        else begin
            mi_soy <= mi_soy;
        end
    end
end



always @(*) begin
    if(cs == OUTPUT)begin
        sold_num = {tonku, tonku_soy, mi, mi_soy};
    end
    else begin
        sold_num = 0;
    end
end




always @(*) begin
    if(cs == OUTPUT)begin
        total_gain = tonku * 200 + tonku_soy * 250 + mi * 200 + mi_soy * 250;
    end
    else begin
        total_gain = 0;
    end
end

always @(*) begin
    if(cs == OUTPUT)begin
        out_valid_tot = 1;
    end
    else begin
        out_valid_tot = 0;
    end
end
//==============================================//
//                    Design                    //
//==============================================//








endmodule
