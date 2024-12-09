/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//


reg [1:0] matrix_row;
reg [8:0] cnt;
reg signed [7:0] data[0:7][0:7];
reg signed [7:0] weight_1[0:7][0:7];
reg signed [18:0] map_q_next[0:7][0:7];
reg signed [18:0] map_q[0:7][0:7];
reg signed [18:0] map_k_next[0:7][0:7];
reg signed [18:0] map_k[0:7][0:7];
reg signed [18:0] map_v_next[0:7][0:7];
reg signed [18:0] map_v[0:7][0:7];
wire [3:0] size;
reg [18:0] linear_out;
reg [2:0] sel_linear_row;
reg [2:0] sel_linear_col;

reg signed [18:0] add1 [0:7];
reg signed [18:0] add2 [0:7];
reg signed [7:0] mul2;
reg signed [18:0] add_outcome[0:7];

reg signed[38:0] matmul1;
reg signed[36:0] relu_out[0:7][0:7];
reg signed[36:0] relu_out_next[0:7][0:7];

reg signed [36:0] mul_big1[0:7];
reg signed [18:0] mul_big2[0:7];
reg signed [56:0] add_big;

genvar i;
//==============================================//
//                 GATED_OR                     //
//==============================================//

wire G_clock_map_q[0:7];
wire G_clock_map_k[0:7];
wire G_clock_map_v[0:7];
wire G_clock_relu[0:15];
wire G_clock_out;
wire G_clock_row;

// wire mapq_ctrl;

//==============================================//
//                  design                      //
//==============================================//

assign size = 4'b0001 << matrix_row; 

always @(posedge clk, negedge rst_n) begin
	if(~rst_n)begin
		cnt <= 0;
	end
	else begin
		if(cnt == (192 + size * 8))begin
			cnt <= 0;
		end
		else if(in_valid || cnt != 0)begin
			cnt <= cnt + 1;
		end
		else begin
			cnt <= 0;
		end
	end
end


GATED_OR GATED_row(
	// Input signals
	.CLOCK(clk),
	.SLEEP_CTRL((cnt >= 1) && cg_en),
	.RST_N(rst_n),
	// Output signals
	.CLOCK_GATED(G_clock_row)
);

always @(posedge G_clock_row) begin
	
	if(in_valid && cnt == 0 && T == 1)begin
		matrix_row <= 0;
	end
	else if(in_valid && cnt == 0 && T == 4) begin
		matrix_row <= 2;
	end
	else if(in_valid && cnt == 0 && T == 8) begin
		matrix_row <= 3;
	end
	else if(cnt == 0)begin
		matrix_row <= 0;
	end
	else begin
		matrix_row <= matrix_row;
	end

end


always @(posedge clk) begin
	data <= data;
	if(in_valid && cnt < size * 8)begin
		data[cnt[8:3]][cnt[2:0]] <= in_data;
	end
	else if(cnt == (192 + size * 8) || cnt == 0)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			for(integer j = 0; j < 8; j = j + 1)begin
				data[i][j] <= 0;
			end
		end
	end
	else begin
		data <= data;
	end
end

always @(posedge clk) begin
	
	if(in_valid && cnt < 64)begin
		weight_1[cnt[8:3]][cnt[2:0]] <= w_Q;
	end
	else begin
		weight_1 <= weight_1;
	end
end

always @(*) begin
	if(cnt < 64)begin
		sel_linear_row = 0;
	end
	else if(cnt < 128)begin
		sel_linear_row = cnt[8:3] - 8;
	end
	else if(cnt < 256)begin
		sel_linear_row = cnt[8:3] - 16;
	end
	else begin
		sel_linear_row = 0;
	end
end

always @(*) begin
	sel_linear_col = cnt[2:0];
end

generate
	for( i = 0; i < 8; i = i + 1)begin
		GATED_OR GATED_maq(
			// Input signals
			.CLOCK(clk),
			.SLEEP_CTRL((cnt >= 128 || cnt < 64) && cg_en),
			.RST_N(rst_n),
			// Output signals
			.CLOCK_GATED(G_clock_map_q[i])
		);
	end
endgenerate


always @(*) begin
	map_q_next = map_q;
	if(cnt >= 64 && cnt < 128)begin
		map_q_next[sel_linear_row][cnt[2:0]] = add_big;
	end
end


generate
	for(i = 0; i < 8; i = i + 1)begin
		always @(posedge G_clock_map_q[i]) begin
			map_q[i] <= map_q_next[i];

		end
	end
endgenerate



// K V share adder and multiplier
always @(*) begin
	if(cnt >= 64 && cnt < 128 && in_valid)begin
		mul2 = w_K;
	end
	else if(cnt >= 128 && cnt < 192 && in_valid)begin
		mul2 = w_V;
	end
	else begin
		for(integer i = 0; i < 8; i = i + 1)begin
			mul2 = 0;
		end
	end
end

always @(*) begin
	if(cnt >= 64 && cnt < 192 && in_valid)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add2[i] = data[i][sel_linear_row] * mul2;
		end
	end
	else begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add2[i] = 0;
		end
	end
end

always @(*) begin
	if(cnt >= 64 && cnt < 128 && in_valid)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add1[i] = map_k[sel_linear_col][i];
			// transpose
		end
	end
	else if(cnt >= 128 && cnt < 192 && in_valid)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add1[i] = map_v[i][sel_linear_col];
		end
	end
	else begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add1[i] = 0;
		end
	end
end

always @(*) begin
	if(cnt >= 64 && cnt < 192 && in_valid)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add_outcome[i] = add1[i] + add2[i];
		end
	end
	else begin
		for(integer i = 0; i < 8; i = i + 1)begin
			add_outcome[i] = 0;
		end
	end
end


generate
	for( i = 0; i < 8; i = i + 1)begin
		GATED_OR GATED_mak(
			// Input signals
			.CLOCK(clk),
			.SLEEP_CTRL((cnt >= 128 || (cnt > 0 && cnt < 64)) && cg_en),
			.RST_N(rst_n),
			// Output signals
			.CLOCK_GATED(G_clock_map_k[i])
		);
	end
endgenerate

always @(*) begin
	map_k_next = map_k;
	if(cnt >= 64 && cnt < 128 )begin
		for(integer i = 0; i < 8; i = i + 1)begin
			map_k_next[sel_linear_col][i] = add_outcome[i];
			// transpose
		end
	end
	else if(cnt == 0)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			for(integer j = 0; j < 8; j = j + 1)begin
				map_k_next[i][j] = 0;
			end
		end
	end
end

generate
	for(i = 0; i < 8; i = i + 1)begin
		always @(posedge G_clock_map_k[i]) begin
			
			map_k[i] <= map_k_next[i];
		end
	end
endgenerate


generate
	for( i = 0; i < 8; i = i + 1)begin
		GATED_OR GATED_mav(
			// Input signals
			.CLOCK(clk),
			.SLEEP_CTRL((cnt < 128 && cnt > 0 ) && cg_en),
			.RST_N(rst_n),
			// Output signals
			.CLOCK_GATED(G_clock_map_v[i])
		);
	end
endgenerate

always @(*) begin
	map_v_next = map_v;
	if(cnt >= 128 && cnt < 192 )begin
		for(integer i = 0; i < 8; i = i + 1)begin
			map_v_next[i][sel_linear_col] = add_outcome[i];
		end
	end
	else if(cnt == 0)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			for(integer j = 0; j < 8; j = j + 1)begin
				map_v_next[i][j] = 0;
			end
		end
	end
end

generate
	for(i = 0; i < 8; i = i + 1)begin
		always @(posedge G_clock_map_v[i], negedge rst_n) begin
			if(~rst_n)begin
				for(integer j = 0; j < 8; j = j + 1)begin
					map_v[i][j] <= 0;
				end
			end
			else begin
				map_v[i] <= map_v_next[i];
			end
		end
	end
endgenerate


always @(*) begin
	if(cnt >= 64 && cnt < 128)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			mul_big1[i] = data[sel_linear_row][i];
			mul_big2[i] = weight_1[i][sel_linear_col];
		end
	end
	else if(cnt >= 128 && cnt < 192)begin
		for(integer i = 0; i < 8; i = i + 1)begin
			mul_big1[i] = map_q[sel_linear_row][i];
			mul_big2[i] = map_k[i][sel_linear_col];
		end
	end
	else if(cnt >= 192 && cnt < (192 + size * 8))begin
		for(integer i = 0; i < 8; i = i + 1)begin
			mul_big1[i] = relu_out[sel_linear_row][i];
			mul_big2[i] = map_v[i][sel_linear_col];
		end
	end
	else begin
		for(integer i = 0; i < 8; i = i + 1)begin
			mul_big1[i] = 0;
			mul_big2[i] = 0;
		end
	end
end

always @(*) begin
	if(cnt >= 64 && cnt < (192 + size * 8))begin
		add_big = mul_big1[0] * mul_big2[0] +
					mul_big1[1] * mul_big2[1] +
					mul_big1[2] * mul_big2[2] +
					mul_big1[3] * mul_big2[3] +
					mul_big1[4] * mul_big2[4] +
					mul_big1[5] * mul_big2[5] +
					mul_big1[6] * mul_big2[6] +
					mul_big1[7] * mul_big2[7];
	end
	else begin
		add_big = 0;
	end
end

always @(*) begin
	if(cnt >= 128 && cnt < 192)begin
		matmul1 = add_big;
	end
	else begin
		matmul1 = 0;
	end
end

generate
	for( i = 0; i < 16; i = i + 1)begin
		GATED_OR GATED_rel(
			// Input signals
			.CLOCK(clk),
			.SLEEP_CTRL((cnt < 128) && cg_en),
			.RST_N(rst_n),
			// Output signals
			.CLOCK_GATED(G_clock_relu[i])
		);
	end
endgenerate

always @(*) begin
	relu_out_next = relu_out;
	if(cnt >= 128 && cnt < 192)begin
		relu_out_next[sel_linear_row][sel_linear_col] = (matmul1 > 0) ? matmul1 / 3 : 0;
	end
end

generate
	for(i = 0; i < 16; i = i + 1)begin
		if(i % 2 == 0)begin
			always @(posedge G_clock_relu[i]) begin
				relu_out[i/2][0:3] <= relu_out_next[i/2][0:3];
			end
		end
		else begin
			always @(posedge G_clock_relu[i]) begin
				relu_out[i/2][4:7] <= relu_out_next[i/2][4:7];
			end
		end
		
	end
endgenerate


GATED_OR GATED_out(
	// Input signals
	.CLOCK(clk),
	.SLEEP_CTRL((cnt <= 191) && cg_en),
	.RST_N(rst_n),
	// Output signals
	.CLOCK_GATED(G_clock_out)
);

always @(posedge G_clock_out, negedge rst_n) begin
	if(~rst_n)begin
		out_data <= 0;
	end
	else begin
		if(cnt >= 192 && cnt < (192 + size * 8))begin
			out_data <= add_big;
		end
		else begin
			out_data <= 0;
		end
	end
	
end

always @(posedge clk, negedge rst_n) begin
	if(~rst_n)begin
		out_valid <= 0;
	end
	else begin
		if(cnt >= 192 && cnt < (192 + size * 8))begin
			out_valid <= 1;
		end
		else begin
			out_valid <= 0;
		end
	end
	
end






endmodule