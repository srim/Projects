module secure_core (
clk,
rst,
intrusion_0,
intrusion_1,
intrusion_2,
intrusion_3,
intrusion_4,
intrusion_5,
intrusion_6,
intrusion_7,
intrusion_8,
intrusion_9,
intrusion_10,
intrusion_11,
intrusion_12,
intrusion_13,
intrusion_14,
intrusion_15,
sc_out_0,
sc_out_1,
sc_out_2,
sc_out_3,
sc_out_4,
sc_out_5,
sc_out_6,
sc_out_7,
sc_out_8,
sc_out_9,
sc_out_10,
sc_out_11,
sc_out_12,
sc_out_13,
sc_out_14,
sc_out_15
);

input clk;
input rst;
input [1:0] intrusion_0;
input [1:0] intrusion_1;
input [1:0] intrusion_2;
input [1:0] intrusion_3;
input [1:0] intrusion_4;
input [1:0] intrusion_5;
input [1:0] intrusion_6;
input [1:0] intrusion_7;
input [1:0] intrusion_8;
input [1:0] intrusion_9;
input [1:0] intrusion_10;
input [1:0] intrusion_11;
input [1:0] intrusion_12;
input [1:0] intrusion_13;
input [1:0] intrusion_14;
input [1:0] intrusion_15;

output  sc_out_0;
output  sc_out_1;
output  sc_out_2;
output  sc_out_3;
output  sc_out_4;
output  sc_out_5;
output  sc_out_6;
output  sc_out_7;
output  sc_out_8;
output  sc_out_9;
output  sc_out_10;
output  sc_out_11;
output  sc_out_12;
output  sc_out_13;
output  sc_out_14;
output  sc_out_15;

reg  sc_out_0;
reg  sc_out_1;
reg  sc_out_2;
reg  sc_out_3;
reg  sc_out_4;
reg  sc_out_5;
reg  sc_out_6;
reg  sc_out_7;
reg  sc_out_8;
reg  sc_out_9;
reg  sc_out_10;
reg  sc_out_11;
reg  sc_out_12;
reg  sc_out_13;
reg  sc_out_14;
reg  sc_out_15;

always @(*)
begin
    if(intrusion_0 == 2'b01 || intrusion_0 == 2'b10 || intrusion_0 == 2'b11)
                sc_out_0 = 1'b1;
    if(intrusion_1== 2'b01 || intrusion_1 == 2'b10 || intrusion_1 == 2'b11)
                sc_out_1 = 1'b1;
    if(intrusion_2== 2'b01 || intrusion_2 == 2'b10 || intrusion_2 == 2'b11)
                sc_out_2 = 1'b1;
    if(intrusion_3== 2'b01 || intrusion_3 == 2'b10 || intrusion_3 == 2'b11)
                sc_out_3 = 1'b1;
    if(intrusion_4== 2'b01 || intrusion_4 == 2'b10 || intrusion_4 == 2'b11)
                sc_out_4 = 1'b1;
    if(intrusion_5== 2'b01 || intrusion_5 == 2'b10 || intrusion_5 == 2'b11)
                sc_out_5 = 1'b1;
    if(intrusion_6== 2'b01 || intrusion_6 == 2'b10 || intrusion_6 == 2'b11)
                sc_out_6 = 1'b1;
    if(intrusion_7== 2'b01 || intrusion_7 == 2'b10 || intrusion_7 == 2'b11)
                sc_out_7 = 1'b1;
    if(intrusion_8== 2'b01 || intrusion_8 == 2'b10 || intrusion_8 == 2'b11)
                sc_out_8 = 1'b1;
    if(intrusion_9== 2'b01 || intrusion_9 == 2'b10 || intrusion_9 == 2'b11)
                sc_out_9 = 1'b1;
    if(intrusion_10== 2'b01 || intrusion_10 == 2'b10 || intrusion_10 == 2'b11)
                sc_out_10 = 1'b1;
    if(intrusion_11== 2'b01 || intrusion_11 == 2'b10 || intrusion_11 == 2'b11)
                sc_out_11 = 1'b1;
    if(intrusion_12== 2'b01 || intrusion_12 == 2'b10 || intrusion_12 == 2'b11)
                sc_out_12 = 1'b1;
    if(intrusion_13== 2'b01 || intrusion_13 == 2'b10 || intrusion_13 == 2'b11)
                sc_out_13 = 1'b1;
    if(intrusion_14== 2'b01 || intrusion_14 == 2'b10 || intrusion_14 == 2'b11)
                sc_out_14 = 1'b1;
    if(intrusion_15== 2'b01 || intrusion_15 == 2'b10 || intrusion_15 == 2'b11)
                sc_out_15 = 1'b1;
      
        end 
endmodule

