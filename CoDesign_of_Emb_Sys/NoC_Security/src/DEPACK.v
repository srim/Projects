`include "constants.v"
module DEPACK(
	clk,
	rst,
	
	//CNIC
	depack_enable,
	flit_type,
	payload,
	payload_valid,
	R2C_src,
	SN_out,
	//LinkC
	data_read,
	data_in,
	data_in_valid
   
);
input clk;
input rst;
reg [`PAYLOAD_WIDTH+5+`FLIT_TYPE_WIDTH-1:0]data_in_1;
//CNIC
input 	depack_enable;
output	reg[`FLIT_TYPE_WIDTH-1:0] flit_type;
output 	reg[`PAYLOAD_WIDTH-1:0]	payload;
output	payload_valid;
output	[(`XY_WIDTH<<1)-1:0] R2C_src;
output	reg[4:0]SN_out;
//LinkC
input	[`FLIT_WIDTH-1:0] data_in; 
output	data_read;
input	data_in_valid;
reg [`PAYLOAD_WIDTH+5+`FLIT_TYPE_WIDTH-1:0]DATA_2_DECRYPT;
reg flag_decrypt;

assign	data_read = depack_enable;
assign	payload_valid = data_in_valid;
assign  R2C_src = data_in[(`XY_WIDTH<<1)-1:0];

always @ (*) 
begin
    DATA_2_DECRYPT = data_in[`FLIT_WIDTH-1:(`XY_WIDTH<<2)];
    flag_decrypt = 1'b1;
    payload = data_in_1[(`FLIT_WIDTH-8-1):(`XY_WIDTH<<2)];
    SN_out = data_in_1[(`XY_WIDTH<<2)-1:`FLIT_TYPE_WIDTH];
    flit_type = data_in_1[`FLIT_TYPE_WIDTH-1:0];
end

//decrypt DECRYPT(DATA_2_DECRYPT,data_in_1,flag_decrypt);

endmodule 