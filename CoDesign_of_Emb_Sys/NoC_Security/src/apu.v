`include "constants.v"

module apu(S_AWADDR,PERM,is_valid_memory_access);
            input [31:0]S_AWADDR;
            output [1:0]PERM; 
            input is_valid_memory_access;
            reg [1:0]PERM; 
always @(S_AWADDR) 
begin
            if ( S_AWADDR[27:0] >= `READ_PROTECT_ADDR_START && S_AWADDR[27:0] < `READ_PROTECT_ADDR_END)
            begin
                PERM = 2'b01;
            end
            else if (S_AWADDR[27:0] >= `WRITE_PROTECT_ADDR_START && S_AWADDR[27:0] < `WRITE_PROTECT_ADDR_END)
            begin
                PERM = 2'b10;
            end
            else
            begin
                PERM = 2'b00;
             end
end
endmodule
 