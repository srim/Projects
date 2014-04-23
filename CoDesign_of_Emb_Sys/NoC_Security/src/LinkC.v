`include "constants.v"

module LinkC(
	clk,
	rst,
	
	//router
	data_in,
	data_in_valid,
	
	data_out,
	data_out_valid,
	
	BP,		//output
			//BP=1: router can send data to LinkC 
			//BP=0: router can't send data to LinkC
	
	BPo, 	//input
			//BPo = 1: router is available
			//BPo = 0: router is not available
	
	//MNI
	//pack
	M_WE_SBuf,
	M_SData,
	M_SBuf_FULL,
	
	//depack
	M_RData,
	M_RE_RBuf,
	M_RData_valid,
	
	//SNI
	//pack
	S_WE_SBuf,
	S_SData,
	S_SBuf_FULL,
	
	//depack
	S_RData,
	S_RE_RBuf,
	S_RData_valid	
	
);

input clk;
input rst;


//router
input	[`FLIT_WIDTH-1:0] data_in;
input	data_in_valid;

output	[`FLIT_WIDTH-1:0] data_out;
output	data_out_valid;

reg		[`FLIT_WIDTH-1:0] data_out;
reg		data_out_valid;

output 	BP;
input	BPo;

//MNI
//send buffer
wire	[`FLIT_WIDTH-1:0] M_SData_out;
wire	M_SData_out_valid;
reg		M_RE_SBuf,next_M_RE_SBuf;
//receive buffer
reg		[`FLIT_WIDTH-1:0] M_RData_in, next_M_RData_in;
reg		M_WE_RBuf,next_M_WE_RBuf;
wire	M_RBuf_FULL;

//pack
input	M_WE_SBuf;	//MNI Write Enable Send buffer
input	[`FLIT_WIDTH-1:0] M_SData;
wire	NM_SBuf_FULL;
output	M_SBuf_FULL;
assign 	M_SBuf_FULL =!NM_SBuf_FULL;
//depack
output	[`FLIT_WIDTH-1:0] M_RData;
input	M_RE_RBuf;
output	M_RData_valid;

//SNI
//send buffer
wire	[`FLIT_WIDTH-1:0] S_SData_out;
wire	S_SData_out_valid;
reg		S_RE_SBuf,next_S_RE_SBuf;
//receive buffer
reg		[`FLIT_WIDTH-1:0] S_RData_in, next_S_RData_in;
reg		S_WE_RBuf,next_S_WE_RBuf;
wire	S_RBuf_FULL;
//pack
input	S_WE_SBuf;
input	[`FLIT_WIDTH-1:0] S_SData;
wire	NS_SBuf_FULL;
output	S_SBuf_FULL;
assign 	S_SBuf_FULL =!NS_SBuf_FULL;
//depack
output	[`FLIT_WIDTH-1:0] S_RData;
input	S_RE_RBuf;
output	S_RData_valid;

//related to the router
//Send buffer
reg		[`FLIT_WIDTH-1:0] SData_REG, next_SData_REG;
reg		WE_SBuf, next_WE_SBuf;
wire	N_SBuf_FULL;

//receive buffer
wire	[`FLIT_WIDTH-1:0] RData;
wire	RData_valid;
reg		RE_RBuf, next_RE_RBuf;

wire	[`FLIT_WIDTH-1:0] temp_data_out;
wire	temp_data_out_valid;


wire NBP;
assign BP= !NBP;

//MNI
basic_fifo #(`FLIT_WIDTH,`LC_NI_BUF_DEPTH) MNI_s_FIFO_Buf(	//send buffer
    .clock(clk),
    .reset(rst),
    
    .data_in(M_SData),
    .enq(M_WE_SBuf),
    .full(NM_SBuf_FULL),
    
    .data_out(M_SData_out),
    .valid_out(M_SData_out_valid),
    .deq(M_RE_SBuf)
);

basic_fifo #(`FLIT_WIDTH,`LC_NI_BUF_DEPTH) MNI_r_FIFO_Buf( 	//receive buffer
    .clock(clk),
    .reset(rst),
    
    .data_in(M_RData_in),
    .enq(M_WE_RBuf),
    .full(M_RBuf_FULL),
    
    .data_out(M_RData),
    .valid_out(M_RData_valid),
    .deq(M_RE_RBuf)
);

//SNI
basic_fifo #(`FLIT_WIDTH,`LC_NI_BUF_DEPTH) SNI_s_FIFO_Buf(	//send buffer
    .clock(clk),
    .reset(rst),
    
    .data_in(S_SData),
    .enq(S_WE_SBuf),
    .full(NS_SBuf_FULL),
    
    .data_out(S_SData_out),
    .valid_out(S_SData_out_valid),
    .deq(S_RE_SBuf)
);

basic_fifo #(`FLIT_WIDTH,`LC_NI_BUF_DEPTH) SNI_r_FIFO_Buf( 	//receive buffer
    .clock(clk),
    .reset(rst),
    
    .data_in(S_RData_in),
    .enq(S_WE_RBuf),
    .full(S_RBuf_FULL),
    
    .data_out(S_RData),
    .valid_out(S_RData_valid),
    .deq(S_RE_RBuf)
);

basic_fifo #(`FLIT_WIDTH,`LC_SBUF_DEPTH) s_FIFO_Buf(	//send buffer
    .clock(clk),
    .reset(rst),
    
    .data_in(SData_REG),
    .enq(WE_SBuf),
    .full(N_SBuf_FULL),
    
    .data_out(temp_data_out),
    .valid_out(temp_data_out_valid),
    .deq(BPo)
);

basic_fifo #(`FLIT_WIDTH,`LC_RBUF_DEPTH) r_FIFO_Buf( 	//receive buffer
    .clock(clk),
    .reset(rst),
    
    .data_in(data_in),
    .enq(data_in_valid),
    .full(NBP),
    
    .data_out(RData),
    .valid_out(RData_valid),
    .deq(RE_RBuf)
);

//solve the 1 cycle delay issue
always@(temp_data_out or temp_data_out_valid or BPo)
begin
	if(BPo==1'b1)
	begin
		data_out = temp_data_out;
		data_out_valid = temp_data_out_valid;
	end	
end



//Send FSM
parameter	[3:0]
	S_CHECK_MNI = 0,
	S_MNI		= 1,
	S_CHECK_SNI	= 2,
	S_SNI		= 3;
	
reg		[3:0] S_CurState,S_NextState;

initial
begin
	S_CurState = S_CHECK_MNI;
	S_NextState = S_CHECK_MNI;
end
	
always@(*)
begin
	next_WE_SBuf	<= WE_SBuf;
	next_M_RE_SBuf  <= M_RE_SBuf;
	next_S_RE_SBuf  <= S_RE_SBuf;
	S_NextState     <= S_CurState;
	next_SData_REG 	<= SData_REG;
	case(S_CurState)
	S_CHECK_MNI:	//Check MNI Send Buffer
	begin
		next_WE_SBuf<= 1'b0;
		next_M_RE_SBuf <= 1'b0;
		next_S_RE_SBuf <= 1'b0;
		if(M_SData_out_valid==1'b1)
		begin
			S_NextState <= S_MNI;
			next_SData_REG <= M_SData_out;
		end
		else
		begin
			S_NextState <= S_CHECK_SNI;
		end
	end
	S_MNI:		//put the MNI send entry to Send Buffer
	begin
		
		if(N_SBuf_FULL == 1'b0)	//wait for Send buffer being available
		begin
			next_WE_SBuf<= 1'b1;
			S_NextState	<=S_CHECK_SNI;
			next_M_RE_SBuf <= 1'b1;
		end
	end
	S_CHECK_SNI: 	//Check SNI Send Buffer
	begin
		next_WE_SBuf<= 1'b0;
		next_M_RE_SBuf <= 1'b0;
		next_S_RE_SBuf <= 1'b0;
		if(S_SData_out_valid==1'b1)
		begin
			S_NextState <= S_SNI;
			next_SData_REG <= S_SData_out;
		end
		else
		begin
			S_NextState <= S_CHECK_MNI;
		end		
		
	end
	S_SNI:		//put the SNI send entry to Send Buffer
	begin	
		if(N_SBuf_FULL == 1'b0)	//wait for Send buffer being available
		begin
			next_WE_SBuf<= 1'b1;
			S_NextState	<=S_CHECK_MNI;
			next_S_RE_SBuf <= 1'b1;
		end
	end	
	endcase
end	
always@(posedge clk)
begin
	WE_SBuf		<= next_WE_SBuf;
	M_RE_SBuf  	<= next_M_RE_SBuf;
	S_RE_SBuf  	<= next_S_RE_SBuf;
	S_CurState  <= S_NextState;
	SData_REG 	<= next_SData_REG;	
end


//Receive FSM
parameter	[3:0]
	R_IDLE 	= 0,
	R_MNI	= 1,
	R_SNI	= 2;
	
reg		[3:0] R_CurState,R_NextState;

initial
begin
	R_CurState = R_IDLE;
	R_NextState = R_IDLE;
end

always@(*)
begin
	next_RE_RBuf	<= RE_RBuf;
	next_M_RData_in <= M_RData_in;
	next_M_WE_RBuf  <= M_WE_RBuf;
	next_S_RData_in <= S_RData_in;
	next_S_WE_RBuf  <= S_WE_RBuf;
	R_NextState		<= R_CurState;
	
	case(R_CurState)
	R_IDLE:
	begin
		next_M_WE_RBuf <= 1'b0;
		next_S_WE_RBuf <= 1'b0;
		if(RData_valid == 1'b1)
		begin
			if(RData[(`XY_WIDTH<<2)+`FLIT_TYPE_WIDTH-1:(`XY_WIDTH<<2)] == `FEEDBACK || 
				RData[(`XY_WIDTH<<2)+`FLIT_TYPE_WIDTH-1:(`XY_WIDTH<<2)] == `RDATA_BODY)
			begin
				R_NextState <= R_MNI;
				next_M_RData_in <= RData;
			end
			else if(RData[(`XY_WIDTH<<2)+`FLIT_TYPE_WIDTH-1:(`XY_WIDTH<<2)] == `REQUEST || 
					RData[(`XY_WIDTH<<2)+`FLIT_TYPE_WIDTH-1:(`XY_WIDTH<<2)] == `WDATA_BODY)
			begin
				R_NextState <= R_SNI;
				next_S_RData_in <= RData;
			end
			next_RE_RBuf <= 1'b1;
		end
	end
	R_MNI:
	begin
		next_RE_RBuf <= 1'b0;
		if(M_RBuf_FULL==1'b0)
		begin
			next_M_WE_RBuf	<=1'b1;
			R_NextState 	<= R_IDLE;
		end
	end
	R_SNI:
	begin
		next_RE_RBuf <= 1'b0;
		if(S_RBuf_FULL==1'b0)
		begin
			next_S_WE_RBuf	<=1'b1;
			R_NextState 	<= R_IDLE;
		end
	end		
	endcase
end
always@(posedge clk)
begin
	RE_RBuf		<= next_RE_RBuf;
	M_RData_in 	<= next_M_RData_in;
	M_WE_RBuf  	<= next_M_WE_RBuf;
	S_RData_in 	<= next_S_RData_in;
	S_WE_RBuf  	<= next_S_WE_RBuf;
	R_CurState	<= R_NextState;
end
endmodule
