`include "constants.v"

module decrypt (S_WDATA, DEC_DATA,flag);

input flag;
input [`AXIS_DATA_WIDTH-1 :0]S_WDATA;
output reg[`AXIS_DATA_WIDTH-1:0] DEC_DATA;
reg[`AXIS_DATA_WIDTH-1:0] DEC_DATA;

always @(*)
begin
if (flag == 1'b1)
    DEC_DATA = (`MASK )^ S_WDATA;
end
endmodule 