/*
	-change the address decoder if it is necessary
*/

`include "constants.v"
module MNIC(
	clk,
	rst,
	
	//AXI Slave
	SLAVE_AWID,
	SLAVE_ARID,
	
	SLAVE_RADDR,
	SLAVE_RDATA,
	SLAVE_WDATA,
	SLAVE_WADDR,
	SLAVE_RW_ENABLE,
	
	SLAVE_AWLEN,
	SLAVE_AWSIZE,	//already decoded
	SLAVE_AWBURST,
	SLAVE_ARLEN,	
	SLAVE_ARSIZE,	//already decoded
	SLAVE_ARBURST,

	S_INPUT_WE,		//enable write for FIFO buffer "SendBuffer"(AXI Master is reading from AXI Slave)
	S_INPUT_RE,		//enable read from FIFO buffer "ReceiveBuffer"(AXI Master is writing to AXI Slave)
	SLAVE_WVALID,
	
	BUSY,
	//PACK
	payload_out,
	flit_type_out,
	pack_enable,
	LinkC_Status_in,
	dest,
	src,
	
	//DEPACK
	depack_enable,
	payload_in,
	flit_type_in,
	payload_in_valid,
	R2C_src,
	SN_in,
	
	CINC_STATUS,
	
	myx,
	myy,
	
	IssueRead,
	IssueWrite,
	Got_IssueRead,
	Got_IssueWrite,
    
    anomaly_detected
);

input	[`XY_WIDTH-1:0]myx;
input	[`XY_WIDTH-1:0]myy;
	
input 	clk;
input 	rst;

//AXI Slave
input	[`AXI_ID_WIDTH-1:0] SLAVE_AWID;
reg		[`AXI_ID_WIDTH-1:0] SLAVE_AWID_REG,next_SLAVE_AWID_REG;
input	[`AXI_ID_WIDTH-1:0] SLAVE_ARID;
reg		[`AXI_ID_WIDTH-1:0] SLAVE_ARID_REG,next_SLAVE_ARID_REG;

input 	[`AXIS_DATA_WIDTH-1:0] SLAVE_WDATA;
reg 	[`AXIS_DATA_WIDTH-1:0] SLAVE_WDATA_REG,next_SLAVE_WDATA_REG;

input 	[`AXIS_ADDR_WIDTH-1:0] SLAVE_WADDR;
reg		[`AXIS_ADDR_WIDTH-1:0] SLAVE_WADDR_REG;

input 	[`AXIS_ADDR_WIDTH-1:0] SLAVE_RADDR;
reg 	[`AXIS_ADDR_WIDTH-1:0] SLAVE_RADDR_REG;

output 	[`AXIS_DATA_WIDTH-1:0] SLAVE_RDATA;
reg 	[`AXIS_DATA_WIDTH-1:0] SLAVE_RDATA, next_SLAVE_RDATA;

input 	[3:0] SLAVE_AWLEN;
input 	[2:0] SLAVE_AWSIZE;	//already decoded //no need decode
input 	[1:0] SLAVE_AWBURST;
input 	[3:0] SLAVE_ARLEN;
input 	[2:0] SLAVE_ARSIZE;	//already decoded //no need decode
input 	[1:0] SLAVE_ARBURST;

reg 	[3:0] SLAVE_AWLEN_REG;
reg 	[2:0] SLAVE_AWSIZE_REG;	//already decoded //no need decode
reg 	[1:0] SLAVE_AWBURST_REG;
reg 	[3:0] SLAVE_ARLEN_REG;
reg 	[2:0] SLAVE_ARSIZE_REG;	//already decoded //no need decode
reg 	[1:0] SLAVE_ARBURST_REG;
reg intrusion_;
input 	[1:0] SLAVE_RW_ENABLE;

//FIFO buffer related
//ReceiveBuffer is for AXI Master writing data to AXI Slave
//SendBuffer is for AXI Master reading data from AXI Slave
output 	S_INPUT_WE;
reg		S_INPUT_WE,next_S_INPUT_WE;		//enable write for FIFO buffer "SendBuffer"
output 	S_INPUT_RE;
reg		S_INPUT_RE_0,next_S_INPUT_RE;
input	SLAVE_WVALID;

output 	BUSY;
reg		BUSY, next_BUSY;

input	IssueRead;
input	IssueWrite;
reg		IssueRead_REG;
reg		IssueWrite_REG;
output	Got_IssueRead;	
reg		Got_IssueRead,next_Got_IssueRead;	
output	Got_IssueWrite;
reg		Got_IssueWrite,next_Got_IssueWrite;
//PACK
output	[`PAYLOAD_WIDTH-1:0] payload_out;
output	[`FLIT_TYPE_WIDTH-1:0] flit_type_out;
output	pack_enable;
input	LinkC_Status_in;
output 	[(`XY_WIDTH<<1)-1:0] dest;
output	[(`XY_WIDTH<<1)-1:0] src;
//inout	[4:0] SN_out;

reg		full_flag, next_full_flag;
reg		TEMP_VALID, next_TEMP_VALID;

//DEPACK	
output	depack_enable;
input	[`PAYLOAD_WIDTH-1:0] payload_in;
input	[`FLIT_TYPE_WIDTH-1:0] flit_type_in;
input	payload_in_valid;
input	[(`XY_WIDTH<<1)-1:0]R2C_src;
input	[4:0]SN_in;

reg		depack_enable, next_depack_enable;
reg		[`PAYLOAD_WIDTH-1:0] payload_in_reg,next_payload_in_reg;

//PACK
reg		pack_enable;
reg		next_pack_enable;
reg		[`FLIT_TYPE_WIDTH-1:0] flit_type_out, next_flit_type_out;
reg		[`PAYLOAD_WIDTH-1:0] payload_out, next_payload_out;
reg 	[(`XY_WIDTH<<1)-1:0] dest, next_dest;
reg		[(`XY_WIDTH<<1)-1:0] temp_dest;	//hardcode now, the unit location of reading data
reg	[4:0]	next_SN_out;
reg   [4:0]  SN_out;
integer i;

//assign	src = 4'b0000;//hardcode, but it's useless. Becasue router will provide the myx and myy
assign	src = {myy[1:0],myx[1:0]};

output	[3:0] CINC_STATUS;
reg		[3:0] CINC_STATUS, next_CINC_STATUS;

parameter
//new FSM
[7:0]	IDLE 			= 1,
		REQ				= 2,
		WT_RESP_RDY		= 3,
		WRITE			= 4,
		READ			= 5,
		W_REJECT		= 6,
		W_DONE			= 7,
		ERR				= 8,
		RESP_DONE		= 9,
		//READY
		Double_REQ 		= 10; 

reg 	[7:0]CurrState, NextState;
 reg [4:0] i_1=5'b00000;
reg		C2R_RW_REG,next_C2R_RW_REG;	//0 is read, 1 is write
reg 	[5:0] C2R_RCounter, next_C2R_RCounter;
reg 	[5:0] C2R_WCounter, next_C2R_WCounter;
reg		[31:0] W_REJECT_Counter,next_W_REJECT_Counter;

//new register
reg		[4:0]NM,next_NM;

reg 	[5:0] Reorder_RCounter, next_Reorder_RCounter;

reg		[`ES_WIDTH-1:0]ES,next_ES;
//reg		[1+`PAYLOAD_WIDTH-1:0]ReorderBuf[0:(1<<`ES_WIDTH)-1];	//|v|Data
reg		[`PAYLOAD_WIDTH:0]ReorderBuf[0:(1<<`ES_WIDTH)-1];
reg		[1+`PAYLOAD_WIDTH-1:0]mask_valid;

reg	[`ES_WIDTH-1:0]ReorderBuf_Index,ReorderBuf_Clean_Index;
reg	[`PAYLOAD_WIDTH:0] ReorderBuf_Entry_In;
reg	[`PAYLOAD_WIDTH:0] ReorderBuf_Entry_Out;
reg	[`PAYLOAD_WIDTH:0] ReorderBuf_Clean_Entry;

output [1:0]anomaly_detected;
reg current_counter;
reg next_counter;
reg is_consecutive;
reg intrusion_counter;
reg [1:0]anomaly_detected;
reg next_current_counter;
reg next_next_counter;
reg next_intrusion_counter;
reg is_valid_memory_access;
reg apu_write_counter;
reg apu_read_counter;
reg anomaly_dos_detected;
reg anomaly_apu_detected;
wire [1:0]PERM;

task decode_address;
input 	[`AXIS_ADDR_WIDTH-1:0] address;
output 	[(`XY_WIDTH<<1)-1:0] dest;
reg 	[(`XY_WIDTH<<1)-1:0] dest;

if(address<32'h10000000)
begin
	dest=4'b0000;//y,x
end
else if(address<32'h20000000)
begin
	dest=4'b0001;//y,x
end
else if(address<32'h30000000)
begin
	dest=4'b0010;//y,x
end
else if(address<32'h40000000)
begin
	dest=4'b0011;//y,x
end
else if(address<32'h50000000)
begin
	dest=4'b0100;//y,x
end
else if(address<32'h60000000)
begin
	dest=4'b0101;//y,x
end
else if(address<32'h70000000)
begin
	dest=4'b0110;//y,x
end
else if(address<32'h80000000)
begin
	dest=4'b0111;//y,x
end
else if(address<32'h90000000)
begin
	dest=4'b1000;//y,x
end
else if(address<32'ha0000000)
begin
	dest=4'b1001;//y,x
end
else if(address<32'hb0000000)
begin
	dest=4'b1010;//y,x
end
else if(address<32'hc0000000)
begin
	dest=4'b1011;//y,x
end
else if(address<32'hd0000000)
begin
	dest=4'b1100;//y,x
end
else if(address<32'he0000000)
begin
	dest=4'b1101;//y,x
end
else if(address<32'hf0000000)
begin
	dest=4'b1110;//y,x
end
else if(address>=32'hf0000000)
begin
	dest=4'b1111;//y,x
end

endtask

assign	S_INPUT_RE = (LinkC_Status_in & S_INPUT_RE_0);

initial
begin
	//temp_dest = 4'b0001; //y,x
	CurrState = IDLE;
	NextState = IDLE;
	ReorderBuf_Clean_Index=0;
	ReorderBuf_Index=0;	
    current_counter = 1'b0;
    next_counter = 1'b1;
    is_consecutive = 1'b0;
    intrusion_counter = 1'b0;
    anomaly_detected = 2'b0;
    anomaly_dos_detected = 1'b0;
    anomaly_apu_detected = 1'b0;
    apu_read_counter = 1'b0;
    apu_write_counter = 1'b0;
end

apu APU(SLAVE_WADDR_REG,PERM,is_valid_memory_access);

always@(*)
begin
	next_SLAVE_WDATA_REG <= SLAVE_WDATA_REG;
	
	next_S_INPUT_WE   <=  S_INPUT_WE;
	next_S_INPUT_RE<=S_INPUT_RE_0;
	next_depack_enable <=  depack_enable;
	
	next_BUSY <= BUSY;
	
	next_pack_enable<= pack_enable;
	next_flit_type_out<= flit_type_out;
	next_payload_out<= payload_out;
	next_dest<= dest;
	next_SN_out<=SN_out;

	next_full_flag <= full_flag;
	next_TEMP_VALID<=TEMP_VALID;
	
	next_CINC_STATUS<= CINC_STATUS;
	next_C2R_RW_REG<= C2R_RW_REG;
	next_payload_in_reg<= payload_in_reg;
	
	next_C2R_RCounter<=C2R_RCounter;
	next_C2R_WCounter<=C2R_WCounter;
	next_W_REJECT_Counter <= W_REJECT_Counter;
	
	next_Got_IssueWrite<=Got_IssueWrite;
	next_Got_IssueRead<=Got_IssueRead;
	
	next_SLAVE_AWID_REG<=SLAVE_AWID_REG;
	next_SLAVE_ARID_REG<=SLAVE_ARID_REG;
	case(CurrState)
	IDLE:
	begin
		//next_depack_enable <= 1'b1;
		next_pack_enable <= 1'b0;
		next_S_INPUT_WE	<= 1'b0;
		ReorderBuf_Clean_Index <= 0 ;
		
		//if(SLAVE_RW_ENABLE == `WRITE_ENABLE)
		if(IssueWrite == 1'b1)
		begin
			NextState <= REQ;
			
			next_SLAVE_AWID_REG<=SLAVE_AWID;
			SLAVE_AWLEN_REG<=SLAVE_AWLEN;
			SLAVE_AWSIZE_REG<=SLAVE_AWSIZE;	
			SLAVE_AWBURST_REG<=SLAVE_AWBURST;
			SLAVE_WADDR_REG <= SLAVE_WADDR;
			
			next_C2R_RW_REG <= 1'b1;	//indicate the request of C2R is write
			next_CINC_STATUS[`C2R_Wreq] <= 1'b1;
			
			next_C2R_WCounter <= SLAVE_AWLEN+1;	//maybe useless right now

            next_current_counter = current_counter + 1;
        
         if(SLAVE_AWLEN>4'b0111)
            begin
                next_next_counter = next_counter + 1;
                    if (next_next_counter - next_current_counter != 1)
                              is_consecutive=1;
                    else
                            next_intrusion_counter = intrusion_counter +1 ;
             end          
       
           if (is_consecutive == 1'b1)
              begin
                    next_next_counter = 1'b1;
                    next_current_counter = 1'b0;
                    next_intrusion_counter = 1'b0;
              end
              
           if(next_intrusion_counter ==5)
            begin
                next_next_counter = 1'b1;
                next_current_counter = 1'b0;
                next_intrusion_counter = 1'b0;
                anomaly_dos_detected = 1'b1;
            end

            is_valid_memory_access = 1'b1;
            
            if (PERM [1] == 1'b1 && PERM[0] == 1'b0)
                begin
                    next_Got_IssueWrite <= 1'b0;
                    apu_write_counter = apu_write_counter+1;
                end
            
             if (apu_write_counter == 5)
                  anomaly_apu_detected = 1'b1;
             
        next_BUSY <= 1'b1;
		next_Got_IssueWrite <= 1'b1;
		
		if(anomaly_dos_detected==1'b1)		
		anomaly_detected= (anomaly_detected | 2'b01);
		
		if(anomaly_apu_detected==1'b1)		
		anomaly_detected= (anomaly_detected | 2'b10);
        
        end		
		//else if(SLAVE_RW_ENABLE == `READ_ENABLE)
		else if(IssueRead == 1'b1)
		begin
			NextState <= REQ;
			next_SLAVE_ARID_REG<=SLAVE_ARID;
			SLAVE_ARLEN_REG<=SLAVE_ARLEN;
			SLAVE_ARSIZE_REG<=SLAVE_ARSIZE;	
			SLAVE_ARBURST_REG<=SLAVE_ARBURST;
			SLAVE_RADDR_REG <= SLAVE_RADDR;
			
			next_C2R_RW_REG <= 1'b0;	//indicate the request of C2R is read
			
			next_CINC_STATUS[`C2R_Rreq] <= 1'b1; 
			
			next_C2R_RCounter <= SLAVE_ARLEN+1;
			
			next_Reorder_RCounter <= SLAVE_ARLEN+1;
			
          is_valid_memory_access = 1'b1;
            
            if (PERM [1] == 1'b0 && PERM[0] == 1'b1)
                begin
                    next_Got_IssueRead <= 1'b0;
                    apu_read_counter = apu_read_counter+1;
                end
            
             if (apu_read_counter == 5)
                  anomaly_apu_detected = 1'b1;
        
			next_BUSY <= 1'b1;
			
			next_Got_IssueRead <= 1'b1;
		end
	end
	REQ:
	begin
		next_depack_enable <= 1'b0;
		next_BUSY <= 1'b1;
		
		if(LinkC_Status_in==1'b1)
		begin
			
			next_flit_type_out <= `REQUEST;
			next_SN_out <= 0;
		
			if(CINC_STATUS[`C2R_Wreq] == 1'b1 )
			begin
				if(SLAVE_WVALID==1'b1)
				begin
					next_S_INPUT_RE <= 1'b1;
					next_payload_out <= {SLAVE_WDATA,
										SLAVE_AWID_REG,	
										SLAVE_AWBURST_REG,
										1'b1,
										SLAVE_AWSIZE_REG,
										SLAVE_AWLEN_REG,
										SLAVE_WADDR_REG};										
					NextState <= WRITE;
					next_pack_enable <= 1'b1;
					decode_address(SLAVE_WADDR_REG,temp_dest);
					//next_W_REJECT_Counter<=0;
				end
			end
			else if(CINC_STATUS[`C2R_Rreq] == 1'b1 )
			begin
				
				next_pack_enable <= 1'b1;
				next_payload_out <= {SLAVE_ARID_REG,	
									SLAVE_ARBURST_REG,
									1'b0,
									SLAVE_ARSIZE_REG,
									SLAVE_ARLEN_REG,
									SLAVE_RADDR_REG};
				
				NextState <= READ;
				decode_address(SLAVE_RADDR_REG,temp_dest);
			end
			
			next_NM <= 1;
			next_ES <= 1;
			
			
			next_dest <= temp_dest;//hardcore now
		end
	end
	WRITE:
	begin
		next_depack_enable <= 1'b0;
		next_S_INPUT_RE <= 1'b0;
		next_pack_enable <= 1'b0;
		NextState <= IDLE;
		

		if(IssueRead == 1'b0)
			next_BUSY <= 1'b0;
		next_Got_IssueWrite <= 1'b0;
		next_CINC_STATUS[`C2R_Wreq] <=1'b0;		
	end
	READ:
	begin
		next_depack_enable <= 1'b1;
		next_pack_enable <= 1'b0;
		if(CINC_STATUS[`C2R_Rreq]==1'b1)
		begin
			if(Reorder_RCounter==0)
			begin//finally receive all the data
				NextState <= IDLE;
				
				next_Got_IssueRead <= 1'b0;
				//if(next_CINC_STATUS[`C2R_Wreq]==1'b0)
				if(IssueWrite == 1'b0)
				begin
					next_BUSY <= 1'b0;
					//IssueRead_REG <= 1'b0;
				end	
				//next_CINC_STATUS <= 4'b0000;
				next_CINC_STATUS[`C2R_Rreq] <=1'b0;
				next_S_INPUT_WE <= 1'b0;
			end
			else
			begin
				if(C2R_RCounter==0)
				begin
					//data in ReorderBuf
					if(ReorderBuf_Entry_Out[`PAYLOAD_WIDTH]==1)
					begin
						next_Reorder_RCounter <= Reorder_RCounter - 1;
						
						next_S_INPUT_WE <= 1'b1;
						//next_SLAVE_RDATA <= ReorderBuf[ES][`PAYLOAD_WIDTH-1:0];
						//next_SLAVE_RDATA <= ReorderBuf[ES];
						next_SLAVE_RDATA <= ReorderBuf_Entry_Out[`PAYLOAD_WIDTH-1:0];
						next_ES <= ES + 1;
						ReorderBuf_Clean_Index <= ES;
					end
					else
						next_S_INPUT_WE <= 1'b0;
					ReorderBuf_Index <= 0;
					ReorderBuf_Entry_In <= 0;					
				end
				else
				begin
					//if(payload_in_valid == 1'b1 && flit_type_in==`DATA_BODY)
					if(payload_in_valid == 1'b1 && flit_type_in==`RDATA_BODY)
					begin
						next_C2R_RCounter <= C2R_RCounter - 1;
						if(SN_in==ES)
						begin
							next_S_INPUT_WE <= 1'b1;
							next_SLAVE_RDATA <= payload_in;
							
							next_Reorder_RCounter <= Reorder_RCounter - 1;
							next_ES <= ES + 1;
							ReorderBuf_Clean_Index <= ES;
						end
						else
						begin	//handle disorder
							//ReorderBuf[SN_in] <= {1'b1,payload_in};
							
							ReorderBuf_Index <= SN_in;
							//ReorderBuf_Index <= SN_in-1;
							ReorderBuf_Entry_In <= {1'b1,payload_in};
							
							//if(ReorderBuf[ES][`PAYLOAD_WIDTH]==1)
							//if((ReorderBuf[ES]& mask_valid) == (1<<`PAYLOAD_WIDTH))
							if(ReorderBuf_Entry_Out[`PAYLOAD_WIDTH]==1)
							begin
								next_S_INPUT_WE <= 1'b1;
								//next_SLAVE_RDATA <= ReorderBuf[ES][`PAYLOAD_WIDTH-1:0];
								//next_SLAVE_RDATA <= ReorderBuf[ES];
								next_SLAVE_RDATA <= ReorderBuf_Entry_Out[`PAYLOAD_WIDTH-1:0];
								next_ES <= ES + 1;
								ReorderBuf_Clean_Index <= ES;
								next_Reorder_RCounter <= Reorder_RCounter - 1;
							end
							else
								next_S_INPUT_WE <= 1'b0;
						end
						
					end
					else
						next_S_INPUT_WE <= 1'b0;
				end
			end			
		end	
	end
	endcase		
end



always@(posedge clk)
begin
	if(rst)
		CurrState <= IDLE;
	else
		CurrState <= NextState;
end

always@(posedge clk)
begin
	if(rst)
	begin
		depack_enable <= 1'b0;
	end
	else
	begin	
		SLAVE_WDATA_REG <= next_SLAVE_WDATA_REG;
		S_INPUT_WE <= next_S_INPUT_WE;
		//S_INPUT_RE<=next_S_INPUT_RE;
		S_INPUT_RE_0<=next_S_INPUT_RE;	
		SLAVE_RDATA<=next_SLAVE_RDATA;
		
		BUSY <= next_BUSY;
		
		depack_enable <= next_depack_enable;
		
		pack_enable<=next_pack_enable;
		flit_type_out<=next_flit_type_out;
		payload_out<=next_payload_out;
		dest<=next_dest;
		SN_out<=next_SN_out;

		full_flag<=next_full_flag;
		TEMP_VALID<=next_TEMP_VALID;
		
		CINC_STATUS<=next_CINC_STATUS;
		C2R_RW_REG<=next_C2R_RW_REG;
		payload_in_reg<=next_payload_in_reg;
		
		C2R_RCounter<=next_C2R_RCounter;
		C2R_WCounter<=next_C2R_WCounter;
		W_REJECT_Counter<=next_W_REJECT_Counter;
		
		ES<=next_ES;
		Reorder_RCounter<=next_Reorder_RCounter;
		
		ReorderBuf[ReorderBuf_Index]<=ReorderBuf_Entry_In;
		ReorderBuf_Entry_Out<=ReorderBuf[next_ES];
		ReorderBuf[ReorderBuf_Clean_Index]<=0;
		
		Got_IssueWrite<=next_Got_IssueWrite;
		Got_IssueRead<=next_Got_IssueRead;			
			
        
        /* update current pointers with next pointer */
            next_next_counter<= next_counter + 1  ;
//            SLAVE_ARID   <=next_SLAVE_ARID_REG;
//			SLAVE_ARLEN <=SLAVE_ARLEN_REG;
//			SLAVE_ARSIZE  <=  SLAVE_ARSIZE_REG;	
//			SLAVE_ARBURST <=  SLAVE_ARBURST_REG;
//			SLAVE_RADDR  <= SLAVE_RADDR_REG ;
            SLAVE_AWID_REG<=next_SLAVE_AWID_REG;       
            current_counter <=  next_current_counter;
            next_counter <= next_next_counter;
            intrusion_counter <= next_intrusion_counter;
            
	end
end

endmodule

