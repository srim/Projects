`include "constants.v"

module encrypt(M_WDATA,ENC_DATA,flag);

input flag;
output reg [`PAYLOAD_WIDTH+ 5+`FLIT_TYPE_WIDTH -1:0] ENC_DATA;
input [`PAYLOAD_WIDTH+ 5+`FLIT_TYPE_WIDTH -1:0] M_WDATA;
//reg [`PAYLOAD_WIDTH+ 5+`FLIT_TYPE_WIDTH -1:0] ENC_DATA;

always @(*)
begin
    if (flag == 1'b1)
        ENC_DATA = M_WDATA ^ `MASK;
end 
endmodule




 