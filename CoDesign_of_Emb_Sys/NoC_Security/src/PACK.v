`include "constants.v"
module PACK(
	
	clk,
	rst,
	
	//CNIC
	payload,
	flit_type,
	pack_enable,
	LinkC_Status_out,
	dest,
	src,
	SN_in,
	//LinkC
	data_out,
	data_valid,
	LinkC_Status_in
    
);
	
input clk;
input rst;

//CNIC
input 	[`PAYLOAD_WIDTH-1:0]	payload;
input	[`FLIT_TYPE_WIDTH-1:0] flit_type;
input	pack_enable;
output	LinkC_Status_out;
input	[(`XY_WIDTH<<1)-1:0]dest;
input	[(`XY_WIDTH<<1)-1:0]src;

input	[4:0]SN_in;

output	[`FLIT_WIDTH-1:0] data_out; 
reg [`FLIT_WIDTH-1:0] data_out;
output	data_valid;
reg [`PAYLOAD_WIDTH +5+`FLIT_TYPE_WIDTH-1:0]ENC_DATA;

input LinkC_Status_in;
reg[`PAYLOAD_WIDTH+5+`FLIT_TYPE_WIDTH-1:0] data_out_for_encryption;
reg flag_encrypt;

//encrypt  ENCRYPT(data_out_for_encryption, ENC_DATA,flag_encrypt);

assign	LinkC_Status_out = LinkC_Status_in;
assign  data_valid = pack_enable;
always @(*)
begin
    data_out_for_encryption= {payload,SN_in,flit_type};
    flag_encrypt= 1'b1;    
    data_out= {ENC_DATA,dest,src}; 
end


endmodule
