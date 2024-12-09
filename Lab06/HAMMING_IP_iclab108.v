//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0]  IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================

wire [3:0] error_bit[0:IP_BIT+4];
genvar i, j;

generate
    for(i = 0; i <= IP_BIT+4; i = i + 1) begin : error_gen
        if(i == 0)begin
            assign error_bit[i] = 0;
            
        end
        else begin
            assign error_bit[i] = (IN_code[IP_BIT + 4 - i] == 1'b1) ? error_bit[i - 1] ^ i : error_bit[i - 1];
        end
    end
endgenerate

reg [IP_BIT+4-1:0] IN_code_modifying;
generate
    for(j = 1; j <= IP_BIT+4; j = j + 1) begin
        always @(*) begin
            if(j == error_bit[ IP_BIT + 4])begin
                IN_code_modifying[IP_BIT + 4 - j] = ~ IN_code[IP_BIT + 4 - j] ;
            end
            else begin
                IN_code_modifying[IP_BIT + 4 - j] = IN_code[IP_BIT + 4 - j];
            end  
        end
    end
endgenerate

always @(*) begin
    OUT_code = {IN_code_modifying[IP_BIT+1], IN_code_modifying[IP_BIT-1:IP_BIT-3], IN_code_modifying[IP_BIT-5:0]};
end


endmodule