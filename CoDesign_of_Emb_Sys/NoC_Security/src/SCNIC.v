`include "constants.v"
module SNIC(
	clk,
	rst,
	
	//AXI Master
	MASTER_AWID,
	MASTER_ARID,
	
	MASTER_AWLEN,
	MASTER_AWSIZE,
	MASTER_AWBURST,
	MASTER_ARLEN,
	MASTER_ARSIZE,
	MASTER_ARBURST,
	
	MASTER_RW_ENABLE, 		// 2bit indicating iniiate read or write 10 - read 11 - write

	MASTER_RADDR, 		// Address for read
	MASTER_RDATA, 	// Data which is read
	MASTER_RVALID,	//indicate output read data is available

	MASTER_WADDR, 		//Address for write
	MASTER_WDATA,  	//Data to be written

	M_INPUT_RE,			//enable read from FIFO buffer "ReceiveBuffer"
	M_INPUT_WE,			//enable write for FIFO buffer "SendBuffer"	
	bWReady,
	SFULL,
	W_BUSY,
	//PACK
	payload_out,
	flit_type_out,
	pack_enable,
	LinkC_Status_in,
	dest,
	src,
	SN_out,
	//DEPACK
	depack_enable,
	payload_in,
	flit_type_in,
	payload_in_valid,
	R2C_src,
	SN_in,
	
	CINC_STATUS,

	myx,
	myy	
);

input	[`XY_WIDTH-1:0]myx;
input	[`XY_WIDTH-1:0]myy;
	
input 	clk;
input 	rst;

//AXI Master
output	[`AXI_ID_WIDTH-1:0] MASTER_ARID;
reg		[`AXI_ID_WIDTH-1:0] MASTER_ARID, next_MASTER_ARID;
output	[`AXI_ID_WIDTH-1:0] MASTER_AWID;
reg		[`AXI_ID_WIDTH-1:0] MASTER_AWID, next_MASTER_AWID;

output 	[3:0] MASTER_AWLEN;
reg 	[3:0] MASTER_AWLEN, next_MASTER_AWLEN;
output 	[2:0] MASTER_AWSIZE;
reg 	[2:0] MASTER_AWSIZE,next_MASTER_AWSIZE;
output 	[1:0] MASTER_AWBURST;
reg 	[1:0] MASTER_AWBURST,next_MASTER_AWBURST;
output 	[3:0] MASTER_ARLEN;
reg 	[3:0] MASTER_ARLEN,next_MASTER_ARLEN;
output 	[2:0] MASTER_ARSIZE;
reg 	[2:0] MASTER_ARSIZE,next_MASTER_ARSIZE;
output 	[1:0] MASTER_ARBURST;
reg 	[1:0] MASTER_ARBURST,next_MASTER_ARBURST;
	
output  [1:0] MASTER_RW_ENABLE; 		// 2bit indicating iniiate read or write 10 - read 11 - write
reg  	[1:0] MASTER_RW_ENABLE,next_MASTER_RW_ENABLE;

output	[`AXIM_ADDR_WIDTH-1:0] MASTER_RADDR; 	// Address for read
reg		[`AXIM_ADDR_WIDTH-1:0] MASTER_RADDR, next_MASTER_RADDR;
input 	[`AXIM_DATA_WIDTH-1:0] MASTER_RDATA; 	// Data which is read
//bug fix
reg 	[`AXIM_DATA_WIDTH-1:0] MASTER_RDATA_REG, next_MASTER_RDATA_REG;

input	MASTER_RVALID;	//indicate output read data is available

output	[`AXIM_ADDR_WIDTH-1:0]	MASTER_WADDR; 		//Address for write
reg		[`AXIM_ADDR_WIDTH-1:0]	MASTER_WADDR,next_MASTER_WADDR;
output 	[`AXIM_DATA_WIDTH-1:0]	MASTER_WDATA;  	//Data to be written
reg 	[`AXIM_DATA_WIDTH-1:0]	MASTER_WDATA,next_MASTER_WDATA; 
output	M_INPUT_RE;		//enable read from AXIv2 Master FIFO buffer "ReceiveBuffer"
//reg		M_INPUT_RE;
reg		next_M_INPUT_RE, M_INPUT_RE_0;
output 	M_INPUT_WE;		//enable write for AXIv2 Master FIFO buffer "SendBuffer"
reg 	M_INPUT_WE, next_M_INPUT_WE;

input	bWReady;
input	SFULL;
input	W_BUSY;
//PACK
output	[`PAYLOAD_WIDTH-1:0] payload_out;
output	[`FLIT_TYPE_WIDTH-1:0] flit_type_out;
output	pack_enable;
input	LinkC_Status_in;
output 	[(`XY_WIDTH<<1)-1:0]dest;
output	[(`XY_WIDTH<<1)-1:0] src;
output	[4:0]SN_out;

reg		full_flag, next_full_flag;
reg		TEMP_VALID, next_TEMP_VALID;
//DEPACK	
output	depack_enable;
input	[`PAYLOAD_WIDTH-1:0] payload_in;
input	[`FLIT_TYPE_WIDTH-1:0] flit_type_in;
input	payload_in_valid;
input	[(`XY_WIDTH<<1)-1:0]R2C_src;
input	[4:0]SN_in;
reg		[4:0]SN_in_REG, next_SN_in_REG;
reg		depack_enable, next_depack_enable;
reg		[`PAYLOAD_WIDTH-1:0] payload_in_reg,next_payload_in_reg;

//PACK
reg		pack_enable, next_pack_enable;
reg		[`FLIT_TYPE_WIDTH-1:0] flit_type_out, next_flit_type_out;
reg		[`PAYLOAD_WIDTH-1:0] payload_out, next_payload_out;
reg 	[(`XY_WIDTH<<1)-1:0]dest, next_dest;
reg		[(`XY_WIDTH<<1)-1:0] temp_dest;	//hardcode now, the unit location of reading data
reg		[4:0]SN_out,next_SN_out;

//assign	src = 4'b0000;//hardcode
assign	src = {myy,myx};

output	[3:0] CINC_STATUS;
reg		[3:0] CINC_STATUS, next_CINC_STATUS;
reg		WT_W_DATA,next_WT_W_DATA;
parameter
//new FSM
[7:0]	IDLE 			= 1,
		REQ				= 2,
		W_READY			= 3,
		WRITE			= 4,
		READ			= 5,
		W_REJECT		= 6,
		ISSUE_WRITE_ADDR= 7,
		ISSUE_WRITE_ADDR_DONE= 8,
		REC_WDATA_DONE	= 9,
		READ_DONE 		= 10,
		WRITE_DONE		= 11; 

reg 	[7:0]CurrState, NextState;

reg		C2R_RW_REG,next_C2R_RW_REG;	//0 is read, 1 is write
reg 	[5:0] R2C_RCounter, next_R2C_RCounter;
reg 	[5:0] R2C_WCounter, next_R2C_WCounter;
reg		[(`XY_WIDTH<<1)-1:0] R2C_req_src,next_R2C_req_src;
reg		[(`XY_WIDTH<<1)-1:0] R2C_CONFLICT_src,next_R2C_CONFLICT_src;

reg 	[5:0] Reorder_WCounter, next_Reorder_WCounter;
reg		[`ES_WIDTH-1:0]ES,next_ES;
reg		[`PAYLOAD_WIDTH:0]ReorderBuf[0:(1<<`ES_WIDTH)-1];
reg		[`ES_WIDTH-1:0]ReorderBuf_Index,ReorderBuf_Clean_Index;
reg		[`PAYLOAD_WIDTH:0] ReorderBuf_Entry_In;
reg		[`PAYLOAD_WIDTH:0] ReorderBuf_Entry_Out;
reg		[`PAYLOAD_WIDTH:0] ReorderBuf_Clean_Entry;

initial
begin
	//temp_dest = 4'b0001; //y,x
	CurrState = IDLE;
	NextState = IDLE;
	
	ReorderBuf_Clean_Index=0;
	ReorderBuf_Index=0;			
end

//bug fix
assign	M_INPUT_RE = (LinkC_Status_in & M_INPUT_RE_0);

always@(*)
begin
	next_MASTER_AWID <= MASTER_AWID;
	next_MASTER_ARID <= MASTER_ARID;
	next_MASTER_AWLEN <=  MASTER_AWLEN;
	next_MASTER_AWSIZE<= MASTER_AWSIZE;
	next_MASTER_AWBURST<= MASTER_AWBURST;
	next_MASTER_WADDR<= MASTER_WADDR;
	next_MASTER_WDATA<= MASTER_WDATA; 
	
	next_MASTER_ARLEN<= MASTER_ARLEN;
	next_MASTER_ARSIZE<= MASTER_ARSIZE;
	next_MASTER_ARBURST<= MASTER_ARBURST;
	next_MASTER_RW_ENABLE<= MASTER_RW_ENABLE;
	next_MASTER_RADDR<=  MASTER_RADDR;
	next_M_INPUT_RE<= M_INPUT_RE_0;
	//next_M_INPUT_RE<= M_INPUT_RE;
	next_MASTER_RDATA_REG<=MASTER_RDATA_REG;
	
	
	next_M_INPUT_WE<=  M_INPUT_WE;
	
	next_depack_enable <=  depack_enable;
	
	next_pack_enable<= pack_enable;
	next_flit_type_out<= flit_type_out;
	next_payload_out<= payload_out;
	next_dest<= dest;
	next_SN_out<=SN_out;
	
	next_full_flag <= full_flag;
	next_TEMP_VALID<=TEMP_VALID;
	
	next_CINC_STATUS<= CINC_STATUS;
	next_WT_W_DATA<=WT_W_DATA;
	
	next_C2R_RW_REG<= C2R_RW_REG;
	next_R2C_req_src<= R2C_req_src;
	next_payload_in_reg<= payload_in_reg;
	next_R2C_CONFLICT_src<= R2C_CONFLICT_src;
	next_R2C_RCounter<= R2C_RCounter;
	next_R2C_WCounter<= R2C_WCounter;
	
	next_SN_in_REG<=SN_in_REG;
	case(CurrState)
	IDLE://1
	begin
		next_depack_enable <= 1'b1;
		next_pack_enable <= 1'b0;
		next_M_INPUT_RE	<= 1'b0;
		next_M_INPUT_WE <= 1'b0;		
		//response to the received read request
		if(payload_in_valid == 1'b1)	//&& MASTER_RVALID==1'b1
		begin
			next_payload_in_reg <= payload_in;
			next_R2C_req_src <= R2C_src;
			next_dest <= R2C_src;
			
			if(flit_type_in==`REQUEST && payload_in[`AXIS_ADDR_WIDTH+7]==1'b1 && WT_W_DATA==1'b0) //w req
			begin
				NextState <= ISSUE_WRITE_ADDR;
				next_CINC_STATUS[`R2C_Wreq] <= 1'b1;				
			end
			else if(flit_type_in==`REQUEST && payload_in[`AXIS_ADDR_WIDTH+7]==1'b1 && WT_W_DATA==1'b1) //w req conflict
			begin
				NextState <= W_REJECT;
			end
			else if(flit_type_in==`REQUEST && payload_in[`AXIS_ADDR_WIDTH+7]==1'b0) //read request
			begin
				NextState <= READ;
				next_CINC_STATUS[`R2C_Rreq] <= 1'b1;
				
				next_MASTER_RADDR <= payload_in[`AXIS_ADDR_WIDTH-1:0];
				next_MASTER_RW_ENABLE <= `READ_ENABLE;
				next_MASTER_ARLEN <= payload_in[`AXIS_ADDR_WIDTH+3:`AXIS_ADDR_WIDTH];
				next_R2C_RCounter <= payload_in[`AXIS_ADDR_WIDTH+3:`AXIS_ADDR_WIDTH] + 1;
				
				next_MASTER_ARSIZE <= payload_in[`AXIS_ADDR_WIDTH+6:`AXIS_ADDR_WIDTH+4];
				next_MASTER_ARBURST <= payload_in[`AXIS_ADDR_WIDTH+9:`AXIS_ADDR_WIDTH+8];	
				
				next_MASTER_ARID <= payload_in[`AXIS_ADDR_WIDTH+`AXI_ID_WIDTH-1+10:`AXIS_ADDR_WIDTH+10];
				next_SN_out <= 0;
			end
			else if(flit_type_in==`WDATA_BODY && WT_W_DATA==1'b1)
			begin
				NextState <= WRITE;
				next_SN_in_REG <= SN_in;
			end
		end
		
	end													
	ISSUE_WRITE_ADDR://7
	begin
		next_depack_enable <= 1'b0;
		next_pack_enable <= 1'b0;
		if(W_BUSY==1'b0 && SFULL==1'b0)	//issue burst write address
		begin
			next_MASTER_WADDR <= payload_in_reg[`AXIS_ADDR_WIDTH-1:0];
			next_MASTER_RW_ENABLE <= `WRITE_ENABLE;
			next_MASTER_AWLEN <= payload_in_reg[`AXIS_ADDR_WIDTH+3:`AXIS_ADDR_WIDTH];
			next_R2C_WCounter <= payload_in_reg[`AXIS_ADDR_WIDTH+3:`AXIS_ADDR_WIDTH] + 1;
			next_Reorder_WCounter <= payload_in_reg[`AXIS_ADDR_WIDTH+3:`AXIS_ADDR_WIDTH] + 1;
			
			next_MASTER_AWSIZE <= payload_in_reg[`AXIS_ADDR_WIDTH+6:`AXIS_ADDR_WIDTH+4];
			next_MASTER_AWBURST <= payload_in_reg[`AXIS_ADDR_WIDTH+9:`AXIS_ADDR_WIDTH+8];
			
			next_MASTER_AWID <= payload_in_reg[`AXIS_ADDR_WIDTH+`AXI_ID_WIDTH-1+10:`AXIS_ADDR_WIDTH+10];
			
			next_M_INPUT_WE	<= 1'b1;
			next_MASTER_WDATA<=payload_in_reg[`AXIS_ADDR_WIDTH+10+`AXI_ID_WIDTH+`AXIS_DATA_WIDTH-1:`AXIS_ADDR_WIDTH+10+`AXI_ID_WIDTH];
			
			NextState <= WRITE_DONE;
		end		
	end
	WRITE_DONE://11
	begin
		next_depack_enable <= 1'b0;
		next_M_INPUT_WE	<= 1'b0;
		
		next_MASTER_RW_ENABLE <= `READ_WRITE_DISABLE;
		
		NextState <= IDLE;
		next_WT_W_DATA <= 1'b0;
		next_CINC_STATUS[`R2C_Wreq]<=1'b0;
		//ReorderBuf_Clean_Index <= 0;
	end
	READ:
	begin
		next_depack_enable <= 1'b0;
	
		if(CINC_STATUS[`R2C_Rreq]==1'b1)
		begin
			next_MASTER_RW_ENABLE <= `READ_WRITE_DISABLE;	//already issue the read address		
			if(LinkC_Status_in==1'b1)
			begin
				if(R2C_RCounter==0 && full_flag==1'b0)
				begin
					NextState <= READ_DONE;
					next_M_INPUT_RE <= 1'b0;
					next_pack_enable <= 1'b0;
					next_full_flag <= 1'b0;
					next_TEMP_VALID<=1'b0;
				end				
				else
				begin
				
					if(full_flag==1'b1 && (R2C_RCounter<MASTER_ARLEN+1))
					begin
						next_full_flag <= 1'b0;
						next_pack_enable <= 1'b1;
						next_M_INPUT_RE <= 1'b0;
					end
					else
					begin
						next_M_INPUT_RE <= 1'b1;
						if(MASTER_RVALID==1'b1 || TEMP_VALID==1'b1)
						begin
							next_full_flag <= 1'b0;
							next_R2C_RCounter <= R2C_RCounter - 1;
							next_pack_enable <= 1'b1;
							//next_flit_type_out <= `DATA_BODY;
							next_flit_type_out <= `RDATA_BODY;
							if(TEMP_VALID==1'b1)
							begin
								next_payload_out <= MASTER_RDATA_REG;
								next_TEMP_VALID<=1'b0;
							end	
							else
								next_payload_out <= MASTER_RDATA;
								
							next_dest <= R2C_req_src;
							next_SN_out <= SN_out + 1;
						end
						else
						begin
							next_pack_enable <= 1'b0;
						end
					end	
				end
			end
			else
			begin
				//next_M_INPUT_RE <= 1'b0;
				next_pack_enable <= 1'b0;
				
				next_full_flag <= 1'b1;
				if(MASTER_RVALID==1'b1)
				begin
					next_MASTER_RDATA_REG<=MASTER_RDATA;
					next_TEMP_VALID<=1'b1;
				end
				// else
					// next_TEMP_VALID<=1'b0;
			end
		
		end
	end
	READ_DONE:
	begin
		//next_depack_enable <= 1'b1;
		next_pack_enable <= 1'b0;
		
		next_CINC_STATUS <= 4'b0000;
		NextState <= IDLE;
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
		MASTER_AWID <= next_MASTER_AWID;
		MASTER_ARID <= next_MASTER_ARID;
	
		MASTER_AWLEN <= next_MASTER_AWLEN;
		MASTER_AWSIZE<=next_MASTER_AWSIZE;
		MASTER_AWBURST<=next_MASTER_AWBURST;
		MASTER_WADDR<=next_MASTER_WADDR;
		MASTER_WDATA<=next_MASTER_WDATA; 
		
		MASTER_ARLEN<=next_MASTER_ARLEN;
		MASTER_ARSIZE<=next_MASTER_ARSIZE;
		MASTER_ARBURST<=next_MASTER_ARBURST;
		MASTER_RW_ENABLE<=next_MASTER_RW_ENABLE;
		MASTER_RADDR<= next_MASTER_RADDR;
		
		MASTER_RDATA_REG<=next_MASTER_RDATA_REG;
		M_INPUT_RE_0<=next_M_INPUT_RE;
		//M_INPUT_RE<=next_M_INPUT_RE;
		M_INPUT_WE<= next_M_INPUT_WE;
		
		depack_enable <= next_depack_enable;
		
		pack_enable<=next_pack_enable;
		flit_type_out<=next_flit_type_out;
		payload_out<=next_payload_out;
		dest<=next_dest;
		SN_out<=next_SN_out;
		
		full_flag<=next_full_flag;
		TEMP_VALID<=next_TEMP_VALID;
		
		CINC_STATUS<=next_CINC_STATUS;
		WT_W_DATA<=next_WT_W_DATA;
		
		C2R_RW_REG<=next_C2R_RW_REG;
		R2C_req_src<=next_R2C_req_src;
		payload_in_reg<=next_payload_in_reg;
		R2C_CONFLICT_src<=next_R2C_CONFLICT_src;
		R2C_RCounter<=next_R2C_RCounter;
		R2C_WCounter<=next_R2C_WCounter;
		
		ES<=next_ES;
		Reorder_WCounter<=next_Reorder_WCounter;
		
		ReorderBuf[ReorderBuf_Index]<=ReorderBuf_Entry_In;
		ReorderBuf_Entry_Out<=ReorderBuf[next_ES];
		ReorderBuf[ReorderBuf_Clean_Index]<=0;	

		SN_in_REG <= next_SN_in_REG;
	end
end

endmodule

