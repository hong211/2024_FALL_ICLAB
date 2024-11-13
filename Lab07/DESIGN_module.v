module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output reg flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output reg fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

//////////////////////////////////////////
//  INPUT TO HANDSHAKE DESIGN           
//////////////////////////////////////////

parameter INPUT = 0;
parameter SEND_INPUT = 1;
parameter WAIT_OUTPUT = 2;

reg [29:0] input_data[0:5];
reg [7:0] cnt;
reg [1:0] state, next_state;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        state <= INPUT;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        INPUT: next_state = (cnt == 5) ? SEND_INPUT : INPUT;
        SEND_INPUT: next_state = (cnt == 5 && out_idle) ? WAIT_OUTPUT : SEND_INPUT;
        WAIT_OUTPUT: next_state = (cnt == 151 && out_valid)? INPUT : WAIT_OUTPUT;
        default: next_state = INPUT;
    endcase
end




always @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        cnt <= 0;
    end
    else begin
        case (state)
            INPUT:  cnt <= (in_valid) ? (cnt != 5) ? cnt + 1 : 0 : 0;
            SEND_INPUT: cnt <= (out_idle == 1) ? (cnt == 5) ? 0 : cnt + 1 : cnt; 
            WAIT_OUTPUT: begin
                if( (cnt != 151 || ~out_valid)) begin
                    cnt <= (~flag_fifo_to_clk1 || cnt < 2) ? cnt + 1 : cnt;
                end
                else begin
                    cnt <= 0;
                end
            end
            // cnt <= (cnt != 151 || ~out_valid) ? (~fifo_empty ) ? cnt + 1 : cnt : 0;
            default: cnt <= 0;
        endcase
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)begin
        for(integer i = 0 ; i < 6; i = i + 1) begin
            input_data[i] <= 0;
        end
    end
    else begin
        case (state)
            INPUT: begin
                if(in_valid) begin
                    input_data[5] <= {in_row, in_kernel};
                    input_data[4] <= input_data[5];
                    input_data[3] <= input_data[4];
                    input_data[2] <= input_data[3];
                    input_data[1] <= input_data[2];
                    input_data[0] <= input_data[1];
                end
                else begin
                    input_data <= input_data;
                end
            end
            SEND_INPUT: begin
                if(out_idle) begin
                    input_data[5] <= 0;
                    input_data[4] <= input_data[5];
                    input_data[3] <= input_data[4];
                    input_data[2] <= input_data[3];
                    input_data[1] <= input_data[2];
                    input_data[0] <= input_data[1];
                end
                else begin
                    input_data <= input_data;
                end
            end
            default: for(integer i = 0 ; i < 6; i = i + 1) begin
                input_data[i] <= 0;
            end
        endcase
    end
end

always @(*) begin
   
    case (state)
        INPUT: handshake_sready =  0;
        SEND_INPUT: handshake_sready =  out_idle;
        default: handshake_sready = 0;
    endcase

end

always @(posedge clk) begin
    handshake_din <=  (out_idle) ? input_data[0] : handshake_din;
end

always @(*) begin
    if(state == WAIT_OUTPUT) begin
        fifo_rinc = ~fifo_empty;
    end
    else begin
        fifo_rinc = 0;
    end
end


always @(*) begin
    
    
    if(state == WAIT_OUTPUT && (~flag_fifo_to_clk1) && cnt > 1) begin
        out_valid = (cnt <= 151);
    end
    else begin
        out_valid = 0;
    end


    
end

always @(*) begin

    if(state == WAIT_OUTPUT && (~flag_fifo_to_clk1 ) && cnt > 1) begin
        out_data = (cnt <= 151) ? fifo_rdata : 0;
    end
    else begin
        out_data = 0;
    end
    
end


endmodule


























module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;


//////////////////////////////////////////
assign busy = 0;

parameter INPUT = 0;
parameter CALCULATE_OUTPUT = 1;


reg [2:0] matrix[0:5][0:5];
reg [2:0] kernel[0:5][0:1][0:1];
reg [5:0] matrix_out[0:3];
reg [7:0] cnt;
reg [1:0] state, next_state;
wire [7:0] cnn_out;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        state <= INPUT;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    if(state == INPUT && cnt == 5 && in_valid) begin
        next_state = CALCULATE_OUTPUT;
    end
    else if(cnt == 150 && ~fifo_full) begin
        next_state = INPUT;
    end
    else if(state == CALCULATE_OUTPUT ) begin
        next_state = CALCULATE_OUTPUT;
    end
    else begin
        next_state = INPUT;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        cnt <= 0;
    end
    else begin
        case (state)
            INPUT: cnt <= (in_valid) ? (cnt != 5) ? cnt + 1 : 0 : cnt;
            CALCULATE_OUTPUT: cnt <= (cnt == 150 && ~fifo_full) ? 0 : (fifo_full)? cnt  : cnt + 1;
            default: cnt <= 0;
        endcase
    end
end

always @(posedge clk) begin
    
    case (state)
        INPUT: begin
            if(in_valid) begin
                kernel[5][0][0] <= in_data[2:0];
                kernel[5][0][1] <= in_data[5:3];
                kernel[5][1][0] <= in_data[8:6];
                kernel[5][1][1] <= in_data[11:9];
            
                kernel[4] <= kernel[5];
                kernel[3] <= kernel[4];
                kernel[2] <= kernel[3];
                kernel[1] <= kernel[2];
                kernel[0] <= kernel[1];
            end
            else begin
                kernel <= kernel;
            end
        end
        CALCULATE_OUTPUT: begin
            if(fifo_full)begin
                kernel <= kernel;
            end
            else if(cnt == 24 || cnt == 49 || cnt == 74 || cnt == 99 || cnt == 124 || cnt == 149)begin
                kernel[5][0][0] <= 0;
                kernel[5][0][1] <= 0;
                kernel[5][1][0] <= 0;
                kernel[5][1][1] <= 0;
                kernel[4] <= kernel[5];
                kernel[3] <= kernel[4];
                kernel[2] <= kernel[3];
                kernel[1] <= kernel[2];
                kernel[0] <= kernel[1];
            end
            else begin
                kernel <= kernel;
            end
            
            
        end
        default:begin
            for(integer i = 0 ; i < 6; i = i + 1) begin
                for(integer j = 0 ; j < 2; j = j + 1) begin
                    for(integer k = 0 ; k < 2; k = k + 1) begin
                        kernel[i][j][k] <= 0;
                    end
                end
            end
        end
    endcase
    
end

always @(posedge clk) begin
    
    case (state)
        INPUT: begin
            if(in_valid) begin
                matrix[5][0] <= in_data[14:12];
                matrix[5][1] <= in_data[17:15];
                matrix[5][2] <= in_data[20:18];
                matrix[5][3] <= in_data[23:21];
                matrix[5][4] <= in_data[26:24];
                matrix[5][5] <= in_data[29:27];
                matrix[4] <= matrix[5];
                matrix[3] <= matrix[4];
                matrix[2] <= matrix[3];
                matrix[1] <= matrix[2];
                matrix[0] <= matrix[1];
            end
            else begin
                matrix <= matrix;
            end
        end
        CALCULATE_OUTPUT: begin
            if(fifo_full)begin
                matrix <= matrix;
            end
            else if(cnt == 24 || cnt == 49 || cnt == 74 || cnt == 99 || cnt == 124 || cnt == 149)begin
                for(integer i = 0; i < 4; i = i + 1)begin
                    matrix[i][0] <= matrix[i + 2][2];
                    matrix[i][1] <= matrix[i + 2][3];
                    matrix[i][2] <= matrix[i + 2][4];
                    matrix[i][3] <= matrix[i + 2][5];
                    matrix[i][4] <= matrix[i + 2][0];
                    matrix[i][5] <= matrix[i + 2][1];
                end
                matrix[4][0] <= matrix[0][2];
                matrix[4][1] <= matrix[0][3];
                matrix[4][2] <= matrix[0][4];
                matrix[4][3] <= matrix[0][5];
                matrix[4][4] <= matrix[0][0];
                matrix[4][5] <= matrix[0][1];

                matrix[5][0] <= matrix[1][2];
                matrix[5][1] <= matrix[1][3];
                matrix[5][2] <= matrix[1][4];
                matrix[5][3] <= matrix[1][5];
                matrix[5][4] <= matrix[1][0];
                matrix[5][5] <= matrix[1][1];
            end
            else if(cnt % 5 == 4)begin
                for(integer i = 0; i < 5; i = i + 1)begin
                    matrix[i][0] <= matrix[i + 1][2];
                    matrix[i][1] <= matrix[i + 1][3];
                    matrix[i][2] <= matrix[i + 1][4];
                    matrix[i][3] <= matrix[i + 1][5];
                    matrix[i][4] <= matrix[i + 1][0];
                    matrix[i][5] <= matrix[i + 1][1];
                end
                matrix[5][0] <= matrix[0][2];
                matrix[5][1] <= matrix[0][3];
                matrix[5][2] <= matrix[0][4];
                matrix[5][3] <= matrix[0][5];
                matrix[5][4] <= matrix[0][0];
                matrix[5][5] <= matrix[0][1];
            end
            else begin
                for(integer i = 0 ; i < 6; i = i + 1) begin
                    matrix[i][0] <= matrix[i][1];
                    matrix[i][1] <= matrix[i][2];
                    matrix[i][2] <= matrix[i][3];
                    matrix[i][3] <= matrix[i][4];
                    matrix[i][4] <= matrix[i][5];
                    matrix[i][5] <= matrix[i][0];
                end
            end
        end
        default:begin
            for(integer i = 0 ; i < 6; i = i + 1) begin
                for(integer j = 0 ; j < 6; j = j + 1) begin
                    matrix[i][j] <= 0;
                end
            end
        end
    endcase
    
end



always @(posedge clk) begin
    
        if(state == CALCULATE_OUTPUT) begin
            matrix_out[0] <= (fifo_full) ? matrix_out[0] : matrix[0][0] * kernel[0][0][0]; 
            matrix_out[1] <= (fifo_full) ? matrix_out[1] : matrix[0][1] * kernel[0][0][1];
            matrix_out[2] <= (fifo_full) ? matrix_out[2] : matrix[1][0] * kernel[0][1][0];
            matrix_out[3] <= (fifo_full) ? matrix_out[3] : matrix[1][1] * kernel[0][1][1];
        end
        else begin
            for(integer i = 0 ; i < 4; i = i + 1) begin
                matrix_out[i] <= 0;
            end
        end
    
end


assign cnn_out = matrix_out[0] + matrix_out[1] + matrix_out[2] + matrix_out[3];
always @(*) begin
    if(state == CALCULATE_OUTPUT  && ~fifo_full && cnt > 0) begin
        out_valid = 1;
        out_data = cnn_out;
    end
    else begin
        out_valid = 0;
        out_data = 0;
    end
end





endmodule