module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output reg sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;


NDFF_syn ack_sync(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));
NDFF_syn req_sync(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));

always @(posedge sclk or negedge rst_n)begin
    if(~rst_n)begin
        sreq <= 0;
    end
    else begin
        if(sack) sreq <= 0;
        else if(sready) sreq <= 1;
        else sreq <= sreq;
    end
end

always @(posedge sclk or negedge rst_n)begin
    if(~rst_n)begin
        sidle <= 0;
    end
    else begin
        if( ~sack && ~sreq && ~sready) sidle <= 1;
        else sidle <= 0;
    end
end



always @(posedge dclk, negedge rst_n) begin
    if(~rst_n)begin
        dack <= 0;
    end
    else begin
        if(dreq && ~dbusy) dack <= 1;
        else dack <= 0;
    end
end

always @(posedge dclk, negedge rst_n) begin
    if(~rst_n)begin
        dout <= 0;
    end
    else begin
        if(dreq && ~dbusy) dout <= din;
        else dout <= dout;
    end
end

always @(posedge dclk, negedge rst_n) begin
    if(~rst_n)begin
        dvalid <= 0;
    end
    else begin
        if(dreq && ~dbusy && ~dack) dvalid <= 1;
        else dvalid <= 0;
    end
end

endmodule