
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
`define PATNUM 5400
`define SEED 45


program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE= 1000;
parameter PATNUM = `PATNUM;
integer seed = `SEED;
integer latency;
integer total_latency;
integer patcount;
integer i;
integer file;

Action golden_action;
Formula_Type golden_formula;
Mode golden_mode;
Date golden_date;
Index golden_index[0:3];
logic signed[11:0] index_variation[0:3];
// Index_variation index_variation[0:3];

Data_Dir dram_data;
logic signed[12:0] dram_index_signed[0:3];
// Index_signed dram_index_signed[0:3];
Data_No golden_data_no;

Warn_Msg golden_warn_msg;
logic golden_complete;

logic [31:0] golden_risk;
Index G[0:3];
Index G_sorted [0:3];



Index temp [0:5];
Index max_dram;
Index min_dram;

integer index_check_cnt;

class rand_act;
    rand Action act;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint act_constraint{
        act inside {Index_Check, Update, Check_Valid_Date};
    }
endclass

class rand_date;
    randc Date date;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint date_constraint{
        date.M inside {[1:12]};
        (date.M==1 || date.M==3 || date.M==5 || date.M==7 || date.M==8 || date.M==10 || date.M==12) -> date.D inside {[1:31]};
        (date.M==4 || date.M==6 || date.M==9 || date.M==11) -> date.D inside {[1:30]};
        (date.M==2) -> date.D inside {[1:28]};
    }
endclass

class rand_Formula_Type;
    rand Formula_Type formula_type;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint data_no_constraint{
        formula_type inside {Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
    }
endclass

class rand_mode;
    rand Mode mode;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint mode_constraint{
        mode inside {Insensitive, Normal, Sensitive};
    }
endclass

class rand_data_no;
    rand Data_No data_no;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint data_no_constraint{
        data_no inside {[0:255]};
    }
endclass

class rand_Index;
    rand Index index;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint index_constraint{
        index inside {[0:4095]};
    }
endclass

rand_act act_rand = new(seed);
rand_date date_rand = new(seed);
rand_Formula_Type formula_type_rand = new(seed);
rand_mode mode_rand = new(seed);
rand_data_no data_no_rand = new(seed);
rand_Index index_rand = new(seed);

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  

// initial begin
//     forever@ (*)begin
//         if(inf.out_valid && (inf.sel_action_valid || inf.formula_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.index_valid))begin
//             $display("========================================================");   
//             $display("                          FAIL!                           ");    
//             $display("           input valid and output valid overlap           ");
//             $display("========================================================"); 
//             $finish;
//         end
//     end
// end


initial begin

    
    index_check_cnt = 0;
    reset_task;
    @(negedge clk);
    file = $fopen("../00_TESTBED/debug.txt", "w");
    $readmemh(DRAM_p_r, golden_DRAM);
    for( patcount = 0; patcount < PATNUM; patcount++) begin 
        // repeat($random(seed) % 'd4) @(negedge clk); // wait 0 - 3 cycles
        input_task;
        write_input_to_file;
        calculate_answer;
        write_ans_to_file;
        wait_out_valid;
        check_ans;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mExecution Cycle: %3d \033[0m", patcount + 1, latency);
    end
    display_pass;
    // repeat (3) @(negedge clk);
    $finish;
end

task reset_task;
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 'b0;
    inf.formula_valid = 1'b0;
    inf.mode_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.data_no_valid = 1'b0;
    inf.index_valid = 1'b0;
    inf.D = 'bx;

    total_latency = 0;

    force clk = 0;

    // Apply reset
    #(3); inf.rst_n = 1'b0; 
    #(1); inf.rst_n = 1'b1;
    
    // Check initial conditions
    // if (inf.out_valid !== 1'b0) begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  out valid should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.warn_msg !== No_Warn)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  warn_msg should be No_Warn after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.complete !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  complete should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.AR_VALID !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  AR_VALID should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.AR_ADDR !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  AR_ADDR should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.R_READY !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  R_READY should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.AW_VALID !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  AW_VALID should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.AW_ADDR !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  AW_ADDR should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.W_VALID !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  W_VALID should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.W_DATA !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  W_DATA should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    // if(inf.B_READY !== 1'b0)begin
    //     display_fail;
    //     $display("========================================================");   
    //     $display("                          FAIL!                           ");    
    //     $display("  B_READY should be 0 after initial RESET at %8t ", $time);
    //     $display("========================================================");  
    //     repeat (2) #CYCLE;
    //     $finish;
    // end

    release clk;
endtask //automatic

task input_task;
    inf.sel_action_valid = 1'b1;
    // i = act_rand.randomize();
    // inf.D.d_act[0] = act_rand.act;
    if(patcount < 300)begin
        inf.D.d_act[0] = Index_Check;
    end
    else if(patcount < 899)begin
        inf.D.d_act[0] = (patcount % 2 == 0) ? Index_Check : Update;
    end
    else if(patcount < 1199)begin
        inf.D.d_act[0] =  Update;
    end
    else if(patcount < 1798)begin
        inf.D.d_act[0] = (patcount % 2 == 0) ? Check_Valid_Date : Update;
    end
    else if(patcount < 2098)begin
        inf.D.d_act[0] =  Check_Valid_Date;
    end
    else if(patcount < 2698)begin
        inf.D.d_act[0] = (patcount % 2 == 0) ? Check_Valid_Date : Index_Check;
    end
    else if(patcount < 2700)begin
        inf.D.d_act[0] =  (patcount % 2 == 0) ? Check_Valid_Date : Update;
    end

    else begin
        inf.D.d_act[0] = Index_Check;
    end
    
    

    golden_action = inf.D.d_act[0];
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
    // repeat($random(seed) % 'd4) @(negedge clk);

    if(golden_action == Index_Check)begin
        inf.formula_valid = 1'b1;
        // i = formula_type_rand.randomize();
        // inf.D.d_formula[0] = formula_type_rand.formula_type;

        if(index_check_cnt < 450)begin
            inf.D.d_formula[0] = Formula_A;
        end
        else if(index_check_cnt < 900)begin
            inf.D.d_formula[0] = Formula_B;
        end
        else if(index_check_cnt < 1350)begin
            inf.D.d_formula[0] = Formula_C;
        end
        else if(index_check_cnt < 1800)begin
            inf.D.d_formula[0] = Formula_D;
        end
        else if(index_check_cnt < 2250)begin
            inf.D.d_formula[0] = Formula_E;
        end
        else if(index_check_cnt < 2700)begin
            inf.D.d_formula[0] = Formula_F;
        end
        else if(index_check_cnt < 3150)begin
            inf.D.d_formula[0] = Formula_G;
        end
        else begin
            inf.D.d_formula[0] = Formula_H;
        end
        

        golden_formula = inf.D.d_formula[0];
        @(negedge clk);
        inf.formula_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        inf.mode_valid = 1'b1;
        // i = mode_rand.randomize();
        // inf.D.d_mode[0] = mode_rand.mode;
        if(index_check_cnt % 3 == 0)begin
            inf.D.d_mode[0] = Insensitive;
        end
        else if(index_check_cnt % 3 == 1)begin
            inf.D.d_mode[0] = Normal;
        end
        else if(index_check_cnt % 3 == 2)begin
            inf.D.d_mode[0] = Sensitive;
        end

        golden_mode = inf.D.d_mode[0];
        @(negedge clk);
        inf.mode_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        index_check_cnt = index_check_cnt + 1;

        inf.date_valid = 1'b1;
        i = date_rand.randomize();
        inf.D.d_date[0] = date_rand.date;
        golden_date = inf.D.d_date[0];
        @(negedge clk);
        inf.date_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        inf.data_no_valid = 1'b1;
        i = data_no_rand.randomize();
        inf.D.d_data_no[0] = data_no_rand.data_no;
        golden_data_no = inf.D.d_data_no[0];
        @(negedge clk);
        inf.data_no_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        for(integer idx = 0; idx < 4 ; idx = idx + 1)begin
            inf.index_valid = 1'b1;
            i = index_rand.randomize();
            inf.D.d_index[0] = index_rand.index;
            golden_index[idx] = inf.D.d_index[0];
            @(negedge clk);
            inf.index_valid = 1'b0;
            inf.D = 'bx;
            // if(idx != 3) repeat($random(seed) % 'd4) @(negedge clk);
        end
    end

    else if(golden_action == Update)begin
        inf.date_valid = 1'b1;
        i = date_rand.randomize();
        inf.D.d_date[0] = date_rand.date;
        golden_date = inf.D.d_date[0];
        @(negedge clk);
        inf.date_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        inf.data_no_valid = 1'b1;
        i = data_no_rand.randomize();
        inf.D.d_data_no[0] = data_no_rand.data_no;
        golden_data_no = inf.D.d_data_no[0];
        @(negedge clk);
        inf.data_no_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        for(integer idx = 0; idx < 4 ; idx = idx + 1)begin
            inf.index_valid = 1'b1;
            i = index_rand.randomize();
            inf.D.d_index[0] = index_rand.index;
            golden_index[idx] = inf.D.d_index[0];
            index_variation[idx] = golden_index[idx];
            @(negedge clk);
            inf.index_valid = 1'b0;
            inf.D = 'bx;
            // if(idx != 3) repeat($random(seed) % 'd4) @(negedge clk);
        end
    end


    else if(golden_action == Check_Valid_Date)begin
        inf.date_valid = 1'b1;
        i = date_rand.randomize();
        inf.D.d_date[0] = date_rand.date;
        golden_date = inf.D.d_date[0];
        @(negedge clk);
        inf.date_valid = 1'b0;
        inf.D = 'bx;
        // repeat($random(seed) % 'd4) @(negedge clk);

        inf.data_no_valid = 1'b1;
        i = data_no_rand.randomize();
        inf.D.d_data_no[0] = data_no_rand.data_no;
        golden_data_no = inf.D.d_data_no[0];
        @(negedge clk);
        inf.data_no_valid = 1'b0;
        inf.D = 'bx;

    end
    dram_data.M = golden_DRAM[65536 + golden_data_no * 8 + 4];
    dram_data.D = golden_DRAM[65536 + golden_data_no * 8];
    dram_data.Index_A = { golden_DRAM[65536 + golden_data_no * 8 + 7], golden_DRAM[65536 + golden_data_no * 8 + 6][7:4]};
    dram_data.Index_B = {golden_DRAM[65536 + golden_data_no * 8 + 6][3:0], golden_DRAM[65536 + golden_data_no * 8 + 5]};
    dram_data.Index_C = {golden_DRAM[65536 + golden_data_no * 8 + 3], golden_DRAM[65536 + golden_data_no * 8 + 2][7:4]};
    dram_data.Index_D = {golden_DRAM[65536 + golden_data_no * 8 + 2][3:0], golden_DRAM[65536 + golden_data_no * 8 + 1] };


endtask

task calculate_answer;
    if(golden_action == Index_Check)begin
        
        
        

        {temp[0],temp[1]} = (dram_data.Index_A > dram_data.Index_B) ? {dram_data.Index_A, dram_data.Index_B} : {dram_data.Index_B, dram_data.Index_A};
        {temp[2],temp[3]} = (dram_data.Index_C > dram_data.Index_D) ? {dram_data.Index_C, dram_data.Index_D} : {dram_data.Index_D, dram_data.Index_C};
        max_dram = (temp[0] > temp[2]) ? temp[0] : temp[2];
        min_dram = (temp[1] < temp[3]) ? temp[1] : temp[3];

        G[0] = (dram_data.Index_A >= golden_index[0])? dram_data.Index_A - golden_index[0] : golden_index[0] - dram_data.Index_A;
        G[1] = (dram_data.Index_B >= golden_index[1])? dram_data.Index_B - golden_index[1] : golden_index[1] - dram_data.Index_B;
        G[2] = (dram_data.Index_C >= golden_index[2])? dram_data.Index_C - golden_index[2] : golden_index[2] - dram_data.Index_C;
        G[3] = (dram_data.Index_D >= golden_index[3])? dram_data.Index_D - golden_index[3] : golden_index[3] - dram_data.Index_D;

        {temp[0],temp[2]} = (G[0] < G[2]) ? {G[0] , G[2]} : {G[2], G[0]};
        {temp[1],temp[3]} = (G[1] < G[3]) ? {G[1] , G[3]} : {G[3], G[1]};
        {G_sorted[0],temp[4]} = (temp[0] < temp[1]) ? {temp[0], temp[1]} : {temp[1], temp[0]};
        {temp[5], G_sorted[3]} = (temp[2] < temp[3]) ? {temp[2], temp[3]} : {temp[3], temp[2]};
        {G_sorted[1], G_sorted[2]} = (temp[4] < temp[5]) ? {temp[4], temp[5]} : {temp[5], temp[4]};

        case (golden_formula)
            Formula_A:begin
                golden_risk = (dram_data.Index_A + dram_data.Index_B + dram_data.Index_C + dram_data.Index_D) / 4;
            end
            Formula_B:begin
                golden_risk = max_dram - min_dram;
            end
            Formula_C:begin
                golden_risk = min_dram;
            end
            Formula_D:begin
                golden_risk = ((dram_data.Index_A) >= 2047) + ((dram_data.Index_B) >= 2047) + ((dram_data.Index_C) >= 2047) + ((dram_data.Index_D) >= 2047);
            end
            Formula_E:begin
                golden_risk = ((dram_data.Index_A) >= golden_index[0]) + ((dram_data.Index_B) >= golden_index[1]) + ((dram_data.Index_C) >= golden_index[2]) + ((dram_data.Index_D) >= golden_index[3]);
            end
            Formula_F:begin
                golden_risk = (G_sorted[0] + G_sorted[1] + G_sorted[2]) / 3;
            end
            Formula_G:begin
                golden_risk = G_sorted[0] / 2 + G_sorted[1] / 4 + G_sorted[2] / 4;
            end
            Formula_H: begin
                golden_risk = (G[0] + G[1] + G[2] + G[3]) / 4;
            end
        endcase


        if(golden_date.M > dram_data.M || (golden_date.D >= dram_data.D && golden_date.M == dram_data.M))begin
            case (golden_formula)
                Formula_A, Formula_C:begin
                    case (golden_mode)
                        Insensitive:begin
                            golden_warn_msg = (golden_risk >= 2047) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 2047) ? 1'b0 : 1'b1;
                        end 
                        Normal:begin
                            golden_warn_msg = (golden_risk >= 1023) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 1023) ? 1'b0 : 1'b1;
                        end
                        Sensitive:begin
                            golden_warn_msg = (golden_risk >= 511) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 511) ? 1'b0 : 1'b1;
                        end
                    endcase
                end
                Formula_B,Formula_F,Formula_G,Formula_H:begin
                    case (golden_mode)
                        Insensitive:begin
                            golden_warn_msg = (golden_risk >= 800) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 800) ? 1'b0 : 1'b1;
                        end 
                        Normal:begin
                            golden_warn_msg = (golden_risk >= 400) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 400) ? 1'b0 : 1'b1;
                        end
                        Sensitive:begin
                            golden_warn_msg = (golden_risk >= 200) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 200) ? 1'b0 : 1'b1;
                        end
                    endcase
                end
                
                Formula_D,Formula_E:begin
                    case (golden_mode)
                        Insensitive:begin
                            golden_warn_msg = (golden_risk >= 3) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 3) ? 1'b0 : 1'b1;
                        end 
                        Normal:begin
                            golden_warn_msg = (golden_risk >= 2) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 2) ? 1'b0 : 1'b1;
                        end
                        Sensitive:begin
                            golden_warn_msg = (golden_risk >= 1) ? Risk_Warn : No_Warn;
                            golden_complete = (golden_risk >= 1) ? 1'b0 : 1'b1;
                        end
                    endcase
                end
                
            endcase
        end
        else begin
            golden_warn_msg = Date_Warn;
            golden_complete = 1'b0;
        end

        
        


    
       
    end
    else if(golden_action == Update) begin
        golden_warn_msg = No_Warn;
        golden_complete = 1'b1;
        dram_index_signed[0] = dram_data.Index_A;
        dram_index_signed[1] = dram_data.Index_B;
        dram_index_signed[2] = dram_data.Index_C;
        dram_index_signed[3] = dram_data.Index_D;
        if(dram_index_signed[0] + index_variation[0] > 4095)begin
            golden_index[0] = 4095;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else if(dram_index_signed[0] + index_variation[0] < 0)begin
            golden_index[0] = 0;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else begin
            golden_index[0] = dram_index_signed[0] + index_variation[0];
        end

        if(dram_index_signed[1] + index_variation[1] > 4095)begin
            golden_index[1] = 4095;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else if(dram_index_signed[1] + index_variation[1] < 0)begin
            golden_index[1] = 0;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else begin
            golden_index[1] = dram_index_signed[1] + index_variation[1];
        end

        if(dram_index_signed[2] + index_variation[2] > 4095)begin
            golden_index[2] = 4095;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else if(dram_index_signed[2] + index_variation[2] < 0)begin
            golden_index[2] = 0;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else begin
            golden_index[2] = dram_index_signed[2] + index_variation[2];
        end

        if(dram_index_signed[3] + index_variation[3] > 4095)begin
            golden_index[3] = 4095;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else if(dram_index_signed[3] + index_variation[3] < 0)begin
            golden_index[3] = 0;
            golden_warn_msg = Data_Warn;
            golden_complete = 1'b0;
        end
        else begin
            golden_index[3] = dram_index_signed[3] + index_variation[3];
        end

        golden_DRAM[65536 + golden_data_no * 8 + 4] = golden_date.M;
        golden_DRAM[65536 + golden_data_no * 8] = golden_date.D;
        {golden_DRAM[65536 + golden_data_no * 8 + 7], golden_DRAM[65536 + golden_data_no * 8 + 6][7:4]} = golden_index[0];
        {golden_DRAM[65536 + golden_data_no * 8 + 6][3:0], golden_DRAM[65536 + golden_data_no * 8 + 5]} = golden_index[1];
        {golden_DRAM[65536 + golden_data_no * 8 + 3], golden_DRAM[65536 + golden_data_no * 8 + 2][7:4]} = golden_index[2];
        {golden_DRAM[65536 + golden_data_no * 8 + 2][3:0], golden_DRAM[65536 + golden_data_no * 8 + 1]} = golden_index[3];
        
    end
    else begin
        if(golden_date.M > dram_data.M || (golden_date.D >= dram_data.D && golden_date.M == dram_data.M))begin
            golden_warn_msg = No_Warn;
            golden_complete = 1'b1;
        end
        else begin
            golden_warn_msg = Date_Warn;
            golden_complete = 1'b0;
        end
    end
endtask




task wait_out_valid; begin
    latency = 0;
    while (inf.out_valid !== 1'b1) begin
        latency = latency + 1;
        // if (latency == MAX_CYCLE) begin
        //     display_fail;
        //     $display("========================================================");    
        //     $display("                          FAIL!                           ");
        //     $display("     The execution latency exceeded %d cycles         ", MAX_CYCLE);
        //     $display("========================================================");  
        //     repeat (2) @(negedge clk);
        //     $finish;
        // end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans; 
    if (inf.warn_msg !== golden_warn_msg ) begin
        display_fail;
        $display("========================================================");     
        $display("                      Wrong Answer                         ");
        $display("            Warn_Msg is %d, golden Warn_Msg is %d     ", inf.warn_msg,golden_warn_msg);
        $display("========================================================");  
        repeat (2) @(negedge clk);
        $finish;
    end
    if (inf.complete !== golden_complete ) begin
        display_fail;
        $display("========================================================");     
        $display("                      Wrong Answer                          ");
        $display("            Compelete is %d, golden Complete is %d     ", inf.complete,golden_complete);
        $display("========================================================");  
        repeat (2) @(negedge clk);
        $finish;
    end
    @(negedge clk);
    // if(inf.out_valid === 1)begin
    //     $display("========================================================");     
    //     $display("                          FAIL!                         ");
    //     $display("                Outvalid only 1 cycle                   ");
    //      $display("========================================================");  
    // end
endtask

task write_input_to_file;
    $fwrite(file, "===========  PATTERN NO.%4d  ==============\n", patcount);
    if(golden_action == Index_Check)begin
        $fwrite(file, "Index_Check\n");
        $fwrite(file, "Formula_Type: %0d\n", golden_formula);
        $fwrite(file, "Mode: %0d\n", golden_mode);
        $fwrite(file, "Date: %0d/%0d\n", golden_date.M, golden_date.D);
        $fwrite(file, "Data_No: %0d\n", golden_data_no);
        $fwrite(file, "Index_A: %0d\n", golden_index[0]);
        $fwrite(file, "Index_B: %0d\n", golden_index[1]);
        $fwrite(file, "Index_C: %0d\n", golden_index[2]);
        $fwrite(file, "Index_D: %0d\n", golden_index[3]);
    end
    else if(golden_action == Update)begin
        $fwrite(file, "Update\n");
        $fwrite(file, "Date: %0d/%0d\n", golden_date.M, golden_date.D);
        $fwrite(file, "Data_No: %0d\n", golden_data_no);
        $fwrite(file, "Index_A variation: %0d\n", index_variation[0]);
        $fwrite(file, "Index_B variation: %0d\n", index_variation[1]);
        $fwrite(file, "Index_C variation: %0d\n", index_variation[2]);
        $fwrite(file, "Index_D variation: %0d\n", index_variation[3]);
    end
    else if(golden_action == Check_Valid_Date)begin
        $fwrite(file, "Check_Valid_Date\n");
        $fwrite(file, "Date: %0d/%0d\n", golden_date.M, golden_date.D);
        $fwrite(file, "Data_No: %0d\n", golden_data_no);
    end

    $fwrite(file, "=============dram_data===========================\n");
    $fwrite(file, "Date: %0d/%0d\n", dram_data.M, dram_data.D);
    $fwrite(file, "Index_A: %0d\n", dram_data.Index_A);
    $fwrite(file, "Index_B: %0d\n", dram_data.Index_B);
    $fwrite(file, "Index_C: %0d\n", dram_data.Index_C);
    $fwrite(file, "Index_D: %0d\n", dram_data.Index_D);
    $fwrite(file, "===============================================\n");
endtask

task write_ans_to_file;
    if(golden_action == Index_Check)begin
        $fwrite(file, "G: %0d %0d %0d %0d\n", G[0], G[1], G[2], G[3]);
        $fwrite(file, "G_sorted: %0d %0d %0d %0d\n", G_sorted[0], G_sorted[1], G_sorted[2], G_sorted[3]);
        $fwrite(file, "Risk: %0d\n", golden_risk);
        $fwrite(file, "Warn_Msg: %0d\n", golden_warn_msg);
        $fwrite(file, "Complete: %0d\n", golden_complete);
    end
    else if(golden_action == Update)begin
        $fwrite(file, "Updated Index_A: %0d\n", golden_index[0]);
        $fwrite(file, "Updated Index_B: %0d\n", golden_index[1]);
        $fwrite(file, "Updated Index_C: %0d\n", golden_index[2]);
        $fwrite(file, "Updated Index_D: %0d\n", golden_index[3]);
        $fwrite(file, "Warn_Msg: %0d\n", golden_warn_msg);
        $fwrite(file, "Complete: %0d\n", golden_complete);
    end
    else if(golden_action == Check_Valid_Date)begin
        $fwrite(file, "Warn_Msg: %0d\n", golden_warn_msg);
        $fwrite(file, "Complete: %0d\n", golden_complete);
    end
    $fwrite(file, "\n\n");
endtask //write_ans_to_file







task display_fail;
    // $display("-----------------------------------------------------------------");
    // $display("                          FAIL!                                  ");
    // $display("                Your execution cycles = %5d cycles                ", total_latency);
    // $display("                Your clock period = %.1f ns                       ", CYCLE);
    // $display("                Total Latency = %.1f ns                          ", total_latency * CYCLE);
    // $display("-----------------------------------------------------------------");
endtask

task display_pass; begin
    $display("-----------------------------------------------------------------");
    $display("                       Congratulations                         ");
    $display("                You have passed all patterns!                     ");
    $display("                Your execution cycles = %5d cycles                ", total_latency);
    // $display("                Your clock period = %.1f ns                       ", CYCLE);
    // $display("                Total Latency = %.1f ns                          ", total_latency * CYCLE);
    $display("-----------------------------------------------------------------");
    // repeat (2) @(negedge clk);
    $finish;
end endtask

endprogram
