module Program(input clk, INF.Program_inf inf);
import usertype::*;

state_t state, next_state;
logic [2:0] idx_cnt;
logic dram_get;
Index sel_max_min[0:3];
Index max, min;

// input register
Action action_reg;
Formula_Type formula_type_reg;
Mode mode_reg;
Date date_reg;
Data_No data_no_reg;
Index index_reg[0:3];
Index diff[0:3];
Index_variation index_reg_variation[0:3];
// dram register
Data_Dir dram_data;
Index_signed dram_index_signed[0:3];
// output register
Warn_Msg warn_msg_reg;
logic compete_reg;

Index_signed B;
Index C, D;
logic [1:0] max_idx, min_idx;
Index temp[0:3];
Index G_sorted[0:3];

logic [13:0] sum;
// Index formula_f_result;
logic [13:0] sumA;
logic signed[12:0] sumB;
logic signed[14:0] sum_next;
logic [11:0] threshold;

// logic [11:0] div_table[0:12285];

// genvar i;

// generate
//     for(i = 0; i < 4095; i = i + 1)begin
//         always_comb begin
//             div_table[i] = i / 3;
//             div_table[i + 4095] = (i + 4095) / 3;
//             div_table[i + 8190] = (i + 8190) / 3;
//         end
//     end
// endgenerate
// always_comb begin 
//     div_table[12285] = 4095;
    
// end




always_ff @( posedge clk, negedge inf.rst_n ) begin
    if(~inf.rst_n) begin
        idx_cnt <= 2'b00;
    end else begin
        if(((idx_cnt == 3 && inf.index_valid || idx_cnt == 4) && (dram_get || inf.R_VALID)) || state == OUTPUT || state == DETER_DATE_IDX_CHECK || state == SEL_MAX_MIN) begin
            idx_cnt <= 2'b00;
        end
        else if(inf.index_valid || state == UPDATE_DATA || state == RISK_DIFF || state == ADD) begin
            idx_cnt <= idx_cnt + 2'b01;
        end
        else begin
            idx_cnt <= idx_cnt;
        end
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(~inf.rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    case (state)
        IDLE: begin
            if(inf.data_no_valid)begin
                next_state = READ_ADDRESS;
            end
            else begin
                next_state = IDLE;
            end
        end
        READ_ADDRESS:begin
            if(inf.AR_READY && inf.AR_VALID)begin
                next_state = (action_reg == Index_Check) ? READ_INDEX_CHECK : (action_reg == Update) ? READ_UPDATE : READ_CHECK_VALID_DATE;
            end
            else begin
                next_state = READ_ADDRESS;
            end
        end
        READ_INDEX_CHECK:begin
            if((idx_cnt == 3 && inf.index_valid || idx_cnt == 4) && (dram_get || inf.R_VALID))begin
                next_state = DETER_DATE_IDX_CHECK;
            end
            else begin
                next_state = READ_INDEX_CHECK;
            end
        end
        READ_UPDATE:begin
            if((idx_cnt == 3 && inf.index_valid || idx_cnt == 4) && (dram_get || inf.R_VALID))begin
                next_state = UPDATE_DATA;
            end
            else begin
                next_state = READ_UPDATE;
            end
        end
        
        READ_CHECK_VALID_DATE:begin
            next_state = inf.R_VALID ? DETER_DATE_CHECK : READ_CHECK_VALID_DATE;
        end

        /////////////////////////////////////////////////////////
        RISK_DIFF:begin
            next_state = ((idx_cnt == 3 )) ? (formula_type_reg == Formula_F || formula_type_reg == Formula_G) ? SORT : SEL_MAX_MIN : RISK_DIFF;
        end

        SORT:begin
            next_state = SEL_MAX_MIN;
        end

        SEL_MAX_MIN:begin
            next_state = ADD;
        end

        ADD:begin
            
            case (formula_type_reg)
                Formula_B, Formula_C: next_state = THRESHOLD;
                Formula_D, Formula_E: next_state = (idx_cnt == 2) ? THRESHOLD : ADD;
                Formula_G,Formula_F: next_state = (idx_cnt == 1) ? THRESHOLD : ADD;
                default: next_state = (idx_cnt == 2) ? DIV : ADD;
            endcase
        end

        DIV:begin
            next_state = THRESHOLD;
        end
        
        THRESHOLD:begin
            next_state = OUTPUT;
        end

        DETER_DATE_IDX_CHECK:begin
            next_state = (date_reg.M > dram_data.M ||  (date_reg.M == dram_data.M && date_reg.D >= dram_data.D)) ? 
                                            (formula_type_reg == Formula_A || formula_type_reg == Formula_D) ? SEL_MAX_MIN : 
                                            (formula_type_reg == Formula_B || formula_type_reg == Formula_C) ? SORT : RISK_DIFF : OUTPUT;
        end
        //////////////////////////////////////////////////////////
        UPDATE_DATA:begin
            next_state = ((idx_cnt == 3 )) ? WRITE_DRAM : UPDATE_DATA;
        end

        WRITE_DRAM:begin
            next_state = (inf.W_READY)? RESPONSE : WRITE_DRAM;
        end

        RESPONSE:begin
            next_state = (inf.B_VALID)? OUTPUT : RESPONSE;
        end
        //////////////////////////////////////////////////////////
        DETER_DATE_CHECK:begin
           next_state = OUTPUT;
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

always_ff @( posedge clk ) begin
    if(inf.sel_action_valid) begin
        action_reg <= inf.D.d_act[0];
    end
    else begin
        action_reg <= action_reg;
    end
end

always_ff @( posedge clk ) begin
    if(inf.formula_valid) begin
        formula_type_reg <= inf.D.d_formula[0];
    end
    else begin
        formula_type_reg <= formula_type_reg;
    end
end

always_ff @( posedge clk ) begin
    if(inf.mode_valid) begin
        mode_reg <= inf.D.d_mode[0];
    end
    else begin
        mode_reg <= mode_reg;
    end
end

always_ff @( posedge clk ) begin
    if(inf.date_valid) begin
        date_reg <= inf.D.d_date[0];
    end
    else begin
        date_reg <= date_reg;
    end
end

always_ff @( posedge clk ) begin
    if(inf.data_no_valid) begin
        data_no_reg <= inf.D.d_data_no[0];
    end
    else begin
        data_no_reg <= data_no_reg;
    end
end

always_ff @( posedge clk ) begin
    if(inf.index_valid) begin
        index_reg[3] <= inf.D.d_index[0];
        index_reg[2] <= index_reg[3];
        index_reg[1] <= index_reg[2];
        index_reg[0] <= index_reg[1];
    end
    else if(state == UPDATE_DATA)begin
        if(dram_index_signed[0] + index_reg_variation[0] < 0)begin
            index_reg[3] <= 0;
        end
        else if(dram_index_signed[0] + index_reg_variation[0] > 4095)begin
            index_reg[3] <= 4095;
        end
        else begin
            index_reg[3] <= dram_index_signed[0] + index_reg_variation[0];
        end
        index_reg[2] <= index_reg[3];
        index_reg[1] <= index_reg[2];
        index_reg[0] <= index_reg[1];
    end
    else if(state == RISK_DIFF)begin
        index_reg[3] <= index_reg[0];
        index_reg[2] <= index_reg[3];
        index_reg[1] <= index_reg[2];
        index_reg[0] <= index_reg[1];
    end
    else begin
        index_reg <= index_reg;
    end
end

always @(posedge clk) begin
    diff[3] <= ((dram_data.Index_A > index_reg[0]) ? dram_data.Index_A - index_reg[0]  : index_reg[0] - dram_data.Index_A);
    if(state == RISK_DIFF)begin
        diff[2] <= diff[3];
        diff[1] <= diff[2];
        diff[0] <= diff[1];
    end
    else begin
        diff[2] <= diff[2];
        diff[1] <= diff[1];
        diff[0] <= diff[0];
    end
end

assign index_reg_variation = index_reg;  // include signed bit

////////////////////////////////////////////
//               AXI  READ                    
////////////////////////////////////////////
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(~inf.rst_n)begin
        inf.AR_VALID <= 0;
        inf.AR_ADDR <= 0;
    end
    else if(next_state == READ_ADDRESS) begin
        inf.AR_VALID <= ~inf.AR_READY;
        inf.AR_ADDR <= inf.AR_READY ? 0 : 'h10000 + data_no_reg * 8;
    end
    else begin
        inf.AR_VALID <= 0;
        inf.AR_ADDR <= 0;
    end
end


always_comb begin 
   if((state == READ_INDEX_CHECK || state == READ_UPDATE || state == READ_CHECK_VALID_DATE) && ~dram_get) begin
        inf.R_READY = 1;
    end
    else begin
        inf.R_READY = 0;
    end
end

always_ff @( posedge clk ) begin
    if(state == READ_INDEX_CHECK || state == READ_UPDATE || state == READ_CHECK_VALID_DATE) begin
        dram_get <= (inf.R_VALID) ? 1 : dram_get;
    end
    else begin
        dram_get <= 0;
    end
end

always_ff @( posedge clk ) begin
    if(inf.R_VALID && inf.R_READY)begin
        dram_data.Index_A <= inf.R_DATA[63:52];
        dram_data.Index_B <= inf.R_DATA[51:40];
        dram_data.M <= inf.R_DATA[35:32];
        dram_data.Index_C <= inf.R_DATA[31:20];
        dram_data.Index_D <= inf.R_DATA[19:8];
        dram_data.D <= inf.R_DATA[4:0];
    end
    else if(state == UPDATE_DATA || state == RISK_DIFF)begin
        dram_data.Index_A <= dram_data.Index_B;
        dram_data.Index_B <= dram_data.Index_C;
        dram_data.M <= dram_data.M;
        dram_data.Index_C <= dram_data.Index_D;
        dram_data.Index_D <= dram_data.Index_A;
        dram_data.D <= dram_data.D;
    end

    else begin
        dram_data <= dram_data;
    end
end

always_comb begin
    dram_index_signed[0] = dram_data.Index_A;
    dram_index_signed[1] = dram_data.Index_B;
    dram_index_signed[2] = dram_data.Index_C;
    dram_index_signed[3] = dram_data.Index_D;
end

////////////////////////////////////////////
//             AXI  WRITE
////////////////////////////////////////////
always_ff @(posedge clk, negedge inf.rst_n) begin
    if(~inf.rst_n)begin
        inf.AW_VALID <= 0;
        inf.AW_ADDR <= 0;
    end
    else begin
        if(state == UPDATE_DATA && idx_cnt <= 2)begin
            inf.AW_VALID <= 1;
            inf.AW_ADDR <= 'h10000 + data_no_reg * 8;
        end
        else begin
            inf.AW_VALID <= 0;
            inf.AW_ADDR <= 0;
        end
    end
    
end

always_ff @(posedge clk, negedge inf.rst_n) begin 
    if(~inf.rst_n)begin
        inf.W_VALID <= 0;
        inf.W_DATA <= 0;
    end
    else begin
        if(state == WRITE_DRAM)begin
            inf.W_VALID <= ~inf.W_READY;
            inf.W_DATA <= inf.W_READY ? 0 : {index_reg[0], index_reg[1], {4'b0000, date_reg.M}, index_reg[2], index_reg[3], {3'b000, date_reg.D}};
        end
        else begin
            inf.W_VALID <= 0;
            inf.W_DATA <= 0;
        end
    end
    
end

always_comb  begin 
    if(state == RESPONSE)begin
        inf.B_READY = 1;
    end
    else begin
        inf.B_READY = 0;
    end
    
end


////////////////////////////////////////////
always_comb begin

    if((formula_type_reg == Formula_B || formula_type_reg == Formula_C))begin
        sel_max_min[0] = dram_data.Index_A;
        sel_max_min[1] = dram_data.Index_B;
        sel_max_min[2] = dram_data.Index_C;
        sel_max_min[3] = dram_data.Index_D;
    end
    else begin
        sel_max_min[0] = diff[0];
        sel_max_min[1] = diff[1];
        sel_max_min[2] = diff[2];
        sel_max_min[3] = diff[3];
    end
    
end

always_ff @(posedge clk) begin
    {temp[0],temp[2]} <= (sel_max_min[0] < sel_max_min[2]) ? {sel_max_min[0] , sel_max_min[2]} : {sel_max_min[2], sel_max_min[0]};
    {temp[1],temp[3]} <= (sel_max_min[1] < sel_max_min[3]) ? {sel_max_min[1] , sel_max_min[3]} : {sel_max_min[3], sel_max_min[1]};
end

always_ff @(*)begin
        {G_sorted[0],G_sorted[1]} = (temp[0] < temp[1]) ? {temp[0], temp[1]} : {temp[1], temp[0]};
        {G_sorted[2], G_sorted[3]} = (temp[2] < temp[3]) ? {temp[2], temp[3]} : {temp[3], temp[2]};
end

always_ff @( posedge clk ) begin
    if(state == SEL_MAX_MIN)begin
        case (formula_type_reg)
            Formula_A: begin
                B <= dram_data.Index_B;
                C <= dram_data.Index_C;
                D <= dram_data.Index_D;
            end
            Formula_B: begin
                B <= ~G_sorted[0] + 1;
                C <= 0;
                D <= 0;
            end
            Formula_C: begin
                B <= 0;
                C <= 0;
                D <= 0;
            end
            Formula_D: begin
                B <= dram_data.Index_B >= 2047;
                C <= dram_data.Index_C >= 2047;
                D <= dram_data.Index_D >= 2047;
            end
            Formula_E: begin
                B <= dram_data.Index_B >= index_reg[1];
                C <= dram_data.Index_C >= index_reg[2];
                D <= dram_data.Index_D >= index_reg[3];
            end
            Formula_F: begin
                B <= G_sorted[1];
                C <= G_sorted[2];
                D <= 0;
            end
            Formula_G: begin
                B <= G_sorted[1][11:2];
                C <= G_sorted[2][11:2];
                D <= 0;
            end
            default: begin
                B <= diff[1];
                C <= diff[2];
                D <= diff[3];
            end
        endcase
    end
    else begin
        B <= C;
        C <= D;
        D <= 0;
    end
    
end

always_comb begin
    if(state == ADD)begin
        sumA = sum;
    end
    else begin
        sumA = 0;
    end
end

always_comb begin
    if(state == ADD)begin
        sumB = B;
    end
    else begin
        sumB = 0;
    end
end

assign sum_next = $signed({1'b0, sumA}) + sumB;

always @(posedge clk) begin
    if(state == ADD)begin
        sum <= sum_next;
    end
    else if(state == DIV)begin
        sum <= sum >> 2;
    end
    else if(state == SEL_MAX_MIN)begin
         case (formula_type_reg)
            Formula_A: begin
                sum <= dram_data.Index_A;
            end
            Formula_B: begin
                sum <= G_sorted[3];
            end
            Formula_D: begin
                sum <= dram_data.Index_A >= 2047;
                
            end
            Formula_E: begin
                sum <= dram_data.Index_A >= index_reg[0];
                
            end
            Formula_G: begin
                sum <=  G_sorted[0][11:1];
            end
            Formula_H: begin
                sum <= diff[0];
            end
            default: begin
                sum <= G_sorted[0];
            end
        endcase
    end
    else begin
        sum <= sum;
    end
end

// always_ff @( posedge clk ) begin
//     formula_f_result <= div_table[sum];
// end

always_comb begin
    if(state == THRESHOLD)begin
        case (formula_type_reg)
            Formula_A, Formula_C: begin
                if(mode_reg == Insensitive)begin
                    threshold = 2047;
                end
                else if(mode_reg == Normal)begin
                    threshold = 1023;
                end
                else begin
                    threshold = 511;
                end
            end
            Formula_D, Formula_E: begin
                if(mode_reg == Insensitive)begin
                    threshold = 3;
                end
                else if(mode_reg == Normal)begin
                    threshold = 2;
                end
                else begin
                    threshold = 1;
                end
            end
            Formula_F:begin
                if(mode_reg == Insensitive)begin
                    threshold = 2400;
                end
                else if(mode_reg == Normal)begin
                    threshold = 1200;
                end
                else begin
                    threshold = 600;
                end
            end
            default: begin
                if(mode_reg == Insensitive)begin
                    threshold = 800;
                end
                else if(mode_reg == Normal)begin
                    threshold = 400;
                end
                else begin
                    threshold = 200;
                end
            end
        endcase
    end
    else begin
        threshold = 0;
    end
end

////////////////////////////////////////////
//             Output siganl
////////////////////////////////////////////


always_ff @( posedge clk ) begin
    if(state == DETER_DATE_IDX_CHECK || state == DETER_DATE_CHECK)begin
        if(date_reg.M > dram_data.M ||  (date_reg.M == dram_data.M && date_reg.D >= dram_data.D))begin // todate > dram_date
            warn_msg_reg <= No_Warn;
            compete_reg <= 1;
        end
        else begin
            warn_msg_reg <= Date_Warn;
            compete_reg <= 0;
            
        end
    end
    else if(state == THRESHOLD)begin
        
        if( sum >= threshold)begin
            warn_msg_reg <= Risk_Warn;
            compete_reg <= 0;
        end
        else begin
            warn_msg_reg <= No_Warn;
            compete_reg <= 1;
        end
       
        
    end

    else if(state == READ_UPDATE)begin
        warn_msg_reg <= No_Warn;
        compete_reg <= 1;
    end
    else if(state == UPDATE_DATA)begin
        if(dram_index_signed[0] + index_reg_variation[0] < 0 || dram_index_signed[0] + index_reg_variation[0] > 4095)begin
            warn_msg_reg <= Data_Warn;
            compete_reg <= 0;
        end
        else begin
            warn_msg_reg <= warn_msg_reg;
            compete_reg <= compete_reg;
        end
    end
    else if(state == OUTPUT)begin
        warn_msg_reg <= No_Warn;
        compete_reg <= 0;
    end
    else begin
        warn_msg_reg <= warn_msg_reg;
        compete_reg <= compete_reg;
    end
end

always_comb begin
    if(state == OUTPUT)begin
        inf.out_valid = 1;
        inf.warn_msg = warn_msg_reg;
        inf.complete = compete_reg;
    end
    else begin
        inf.out_valid = 0;
        inf.warn_msg = No_Warn;
        inf.complete = 0;
    end
end

endmodule
