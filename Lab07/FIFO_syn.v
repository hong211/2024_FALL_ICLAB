module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output reg flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

wire [5:0] w_addr;
wire [5:0] r_addr;
reg [WIDTH - 1:0] r_data;
wire web_w;

wire [$clog2(WORDS):0] wq2_rptr;
wire [$clog2(WORDS):0] rq2_wptr;

assign web_w = ~winc || wfull; 

reg [6:0] w_addr_one;
reg [6:0] r_addr_one;
reg rempty_bef1;






always @(posedge wclk, negedge rst_n) begin
    if(~rst_n) begin
        w_addr_one <= 0;
    end
    else begin
        if(winc && ~wfull) begin
            w_addr_one <= w_addr_one + 1;
        end
        else begin
            w_addr_one <= w_addr_one;
        end
    end
end

always @(*)begin
    wptr = (w_addr_one >> 1) ^ w_addr_one; 
end

always @(*) begin
    
    if({~wptr[6:5], wptr[4:0]} == wq2_rptr) begin
        wfull = 1;
    end
    else begin
        wfull = 0;
    end

end


assign rempty = rptr == rq2_wptr;

always @(*)begin
    rptr = (r_addr_one >> 1) ^ r_addr_one; 
end

always @(posedge rclk) begin
    if(rptr == rq2_wptr) begin
        rempty_bef1 <= 1;
    end
    else begin
        rempty_bef1 <= 0;
    end
end


always @(posedge rclk) begin
    flag_fifo_to_clk1 <= rempty_bef1;
end



always @(posedge rclk, negedge rst_n) begin
    if(~rst_n) begin
        r_addr_one <= 0;
    end
    else begin
        if(rinc) begin
            r_addr_one <= r_addr_one + 1;
        end
        else begin
            r_addr_one <= r_addr_one;
        end
    end
end



assign w_addr = w_addr_one[5:0];
assign r_addr = r_addr_one[5:0];




always @(posedge rclk) begin
    rdata <= r_data;
end


NDFF_BUS_syn #(.WIDTH(7)) u_rptr (
    .D(rptr),
    .Q(wq2_rptr),
    .clk(wclk),
    .rst_n(rst_n)
);
NDFF_BUS_syn #(.WIDTH(7)) u_wptr (
    .D(wptr),
    .Q(rq2_wptr),
    .clk(rclk),
    .rst_n(rst_n)
);
DUAL_64X8X1BM1 u_dual_sram(.A0(w_addr[0]), .A1(w_addr[1]), .A2(w_addr[2]), .A3(w_addr[3]), .A4(w_addr[4]), .A5(w_addr[5]),
                         .B0(r_addr[0]), .B1(r_addr[1]), .B2(r_addr[2]), .B3(r_addr[3]), .B4(r_addr[4]), .B5(r_addr[5]),
                         .DOB0(r_data[0]), .DOB1(r_data[1]), .DOB2(r_data[2]), .DOB3(r_data[3]), .DOB4(r_data[4]), .DOB5(r_data[5]), .DOB6(r_data[6]), .DOB7(r_data[7]),
                         .DIA0(wdata[0]), .DIA1(wdata[1]), .DIA2(wdata[2]), .DIA3(wdata[3]), .DIA4(wdata[4]), .DIA5(wdata[5]), .DIA6(wdata[6]), .DIA7(wdata[7]),
                         .WEAN(web_w), .WEBN(1'b1), .CKA(wclk), .CKB(rclk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b1), .OEB(1'b1));





endmodule
