/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end


/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */


Action act_reg;
logic [1:0] idx_cnt;

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();


covergroup formula_type_cov @(posedge clk iff inf.formula_valid) ;
    option.at_least = 150;
    option.per_instance = 1;
    eight_type: coverpoint inf.D.d_formula[0] {
        bins f_type[] = {Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
    }
endgroup

formula_type_cov formula_cov = new();


covergroup mode_cov @(posedge clk iff inf.mode_valid) ;
    option.at_least = 150;
    option.per_instance = 1;
    threemode: coverpoint inf.D.d_mode[0] {
        bins d_mode[] = {Insensitive, Normal, Sensitive};
    }
endgroup

mode_cov mode_3_cov = new();

Formula_Type f_type;
always_ff @( posedge clk ) begin
    if(inf.formula_valid) begin
        f_type <= inf.D.d_formula[0];
    end
    else begin
        f_type <= f_type;
    end
end

covergroup cross_cov @(posedge clk iff  inf.mode_valid) ;
    option.at_least = 150;
    option.per_instance = 1;
    formula_type_cov: coverpoint f_type {
        bins type_[] = {Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
    }
    mode_cov: coverpoint inf.D.d_mode[0] {
        bins mode_[] = {Insensitive, Normal, Sensitive};
    }
    cross_ : cross formula_type_cov, mode_cov ;
endgroup

cross_cov cross_in_cov = new();

covergroup Warn_cov @(negedge clk iff inf.out_valid) ;
    option.at_least = 50;
    option.per_instance = 1;
    out_warn: coverpoint inf.warn_msg {
        bins warn_msg[] = {No_Warn, Date_Warn, Risk_Warn, Data_Warn};
    }
endgroup

Warn_cov out_warn_cov = new();

covergroup action_trans_cov @(posedge clk iff inf.sel_action_valid) ;
    option.at_least = 300;
    option.per_instance = 1;
    action: coverpoint inf.D.d_act[0] {
        bins d_act[] = ([Index_Check: Check_Valid_Date] => [Index_Check: Check_Valid_Date]);
    }
endgroup

action_trans_cov action_cov = new();

covergroup index_cov @(posedge clk iff (inf.index_valid && act_reg == Update) ) ;
    option.at_least = 1;
    option.per_instance = 1;
    option.auto_bin_max = 32;
    index: coverpoint inf.D.d_index[0];
endgroup

index_cov idx_cov = new();


///////////////////////////////////////////////////////////////
//                       Assertion
///////////////////////////////////////////////////////////////


always_ff @(posedge clk) begin
    if(inf.sel_action_valid)begin
        act_reg = inf.D.d_act[0];
    end
    else begin
        act_reg = act_reg;
    end
end

always_ff @(posedge clk, negedge inf.rst_n) begin
    if(~inf.rst_n)begin
        idx_cnt = 0;
    end
    else begin
        if(inf.index_valid)begin
            idx_cnt = idx_cnt + 1;
        end
        else begin
            idx_cnt = idx_cnt;
        end
    end
end

property reset_assert;
    @(posedge inf.rst_n) ##1
    (inf.out_valid === 0 && inf.warn_msg === No_Warn && inf.complete === 0
    && inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0
    && inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0);
endproperty

assert property (reset_assert) else begin
    $display("========================================================");     
    $display("               Assertion 1 is violated                ");
    $display("========================================================");  
    $fatal;
end

logic input_over;

always @(*) begin
    case (act_reg)
        Index_Check, Update: input_over = (idx_cnt == 3 && inf.index_valid === 1);
        Check_Valid_Date: input_over = (inf.date_valid === 1);
        default: input_over = 0;
    endcase
end

property latency_assert;
    @(posedge clk) (input_over |-> ##[1:999] inf.out_valid === 1);
endproperty

assert property (latency_assert) else begin
    $display("========================================================");     
    $display("               Assertion 2 is violated                ");
    $display("========================================================");  
    $fatal;
end

property output_assert;
    @(negedge clk) (inf.complete === 1) |-> inf.warn_msg === No_Warn;
endproperty

assert property (output_assert) else begin
    $display("========================================================");     
    $display("               Assertion 3 is violated                ");
    $display("========================================================");  
    $fatal;
end

property Index_check_input_valid_assert;
    @(posedge clk) ((inf.sel_action_valid === 1 && (inf.D.d_act[0] == Index_Check)) 
                     |-> ##[1:4] inf.formula_valid === 1  ##[1:4] inf.mode_valid === 1  ##[1:4] inf.date_valid === 1
                     ##[1:4] inf.data_no_valid === 1 ##[1:4] inf.index_valid === 1  ##[1:4] inf.index_valid === 1
                     ##[1:4] inf.index_valid === 1  ##[1:4] inf.index_valid === 1);
endproperty

property Update_input_valid_assert;
    @(posedge clk) ((inf.sel_action_valid === 1 && ( inf.D.d_act[0] == Update)) 
                    |-> ##[1:4] inf.date_valid === 1  ##[1:4] inf.data_no_valid === 1 ##[1:4] inf.index_valid === 1 
                     ##[1:4] inf.index_valid === 1 ##[1:4] inf.index_valid === 1  ##[1:4] inf.index_valid === 1);
endproperty

property check_Date_input_valid_assert;
    @(posedge clk) ((inf.sel_action_valid === 1 && (inf.D.d_act[0] == Check_Valid_Date))
                     |-> ##[1:4] inf.date_valid === 1  ##[1:4] inf.data_no_valid === 1);
endproperty

assert property (Index_check_input_valid_assert) else begin
    $display("========================================================");     
    $display("               Assertion 4 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (Update_input_valid_assert) else begin
    $display("========================================================");     
    $display("               Assertion 4 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (check_Date_input_valid_assert) else begin
    $display("========================================================");     
    $display("               Assertion 4 is violated                ");
    $display("========================================================");  
    $fatal;
end



property sel_action_valid_overlap_assert;
    @(posedge clk) (inf.sel_action_valid === 1 |-> (inf.formula_valid === 0 && inf.mode_valid === 0 
                    && inf.date_valid === 0 && inf.data_no_valid === 0 && inf.index_valid === 0));
endproperty

property formula_valid_overlap_assert;
    @(posedge clk) (inf.formula_valid === 1 |-> (inf.sel_action_valid === 0  && inf.mode_valid === 0 
                    && inf.date_valid === 0 && inf.data_no_valid === 0 && inf.index_valid === 0));
endproperty

property mode_valid_overlap_assert;
    @(posedge clk) (inf.mode_valid === 1 |-> (inf.sel_action_valid === 0 && inf.formula_valid === 0  
                    && inf.date_valid === 0 && inf.data_no_valid === 0 && inf.index_valid === 0));
endproperty

property date_valid_overlap_assert;
    @(posedge clk) (inf.date_valid === 1 |-> (inf.sel_action_valid === 0 && inf.formula_valid === 0 && inf.mode_valid === 0 
                     && inf.data_no_valid === 0 && inf.index_valid === 0));
endproperty

property data_no_valid_overlap_assert;
    @(posedge clk) (inf.data_no_valid === 1 |-> (inf.sel_action_valid === 0 && inf.formula_valid === 0 && inf.mode_valid === 0 
                    && inf.date_valid === 0  && inf.index_valid === 0));
endproperty

property index_valid_overlap_assert;
    @(posedge clk) (inf.index_valid === 1 |-> (inf.sel_action_valid === 0 && inf.formula_valid === 0 && inf.mode_valid === 0 
                    && inf.date_valid === 0 && inf.data_no_valid === 0 ));
endproperty

assert property (sel_action_valid_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 5 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (formula_valid_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 5 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (mode_valid_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 5 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (date_valid_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 5 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (data_no_valid_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 5 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (index_valid_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 5 is violated                ");
    $display("========================================================");  
    $fatal;
end

property out_valid_one_cycle_assert;
    @(negedge clk) (inf.out_valid === 1 |=>  inf.out_valid === 0);
endproperty

assert property (out_valid_one_cycle_assert) else begin
    $display("========================================================");     
    $display("               Assertion 6 is violated                ");
    $display("========================================================");  
    $fatal;
end


property next_invalid_assert;
    @(posedge clk) (inf.out_valid === 1 |->  ##[1:4] inf.sel_action_valid === 1);
endproperty

assert property (next_invalid_assert) else begin
    $display("========================================================");     
    $display("               Assertion 7 is violated                ");
    $display("========================================================");  
    $fatal;
end


logic [1:0] day_; // 0 is 31 days, 1 is 30 days, 2 is 28 days

always_comb begin
    case (inf.D.d_date[0].M)
        1, 3, 5, 7, 8, 10, 12: day_ = 0;
        4, 6, 9, 11: day_ = 1;
        2: day_ = 2;
        default: day_ = 0;
    endcase
end


property Month_assert;
    @(posedge clk) (inf.date_valid === 1 |-> (inf.D.d_date[0].M inside{[1:12]}));
endproperty


property Day_31_assert;
    @(posedge clk) (inf.date_valid === 1 && day_ === 0 |-> (inf.D.d_date[0].D inside{[1:31]}));
endproperty

property Day_30_assert;
    @(posedge clk) (inf.date_valid === 1 && day_ === 1 |-> (inf.D.d_date[0].D inside{[1:30]}));
endproperty

property Day_28_assert;
    @(posedge clk) (inf.date_valid === 1 && day_ === 2 |-> (inf.D.d_date[0].D inside{[1:28]}));
endproperty

assert property (Month_assert) else begin
    $display("========================================================");     
    $display("               Assertion 8 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (Day_31_assert) else begin
    $display("========================================================");     
    $display("               Assertion 8 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (Day_30_assert) else begin
    $display("========================================================");     
    $display("               Assertion 8 is violated                ");
    $display("========================================================");  
    $fatal;
end

assert property (Day_28_assert) else begin
    $display("========================================================");     
    $display("               Assertion 8 is violated                ");
    $display("========================================================");  
    $fatal;
end



property AR_AW_overlap_assert;
    @(posedge clk) (inf.AR_VALID === 1 |->  inf.AW_VALID !== 1);
endproperty

assert property (AR_AW_overlap_assert) else begin
    $display("========================================================");     
    $display("               Assertion 9 is violated                ");
    $display("========================================================");  
    $fatal;
end



endmodule