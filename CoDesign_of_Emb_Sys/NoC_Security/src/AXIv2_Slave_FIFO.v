/*
	-ver1.0 AXI Slave with FIFO
		-The counting of number of data should be handle by your component.
		-This version is for those who don't know much about details of AXI.
		-The functionality of AXI Slave is majorly considered in this version.
		-if SLAVE_WREADY is asserted to 0, your component will receive one more data. 
			-Because AXI Slave is adding 1 cycle delay for data transaction.
	-ver2.0 Add one more buffer for AXI Master writing data to AXI Slave
	-ver2.1 optimization
	
*/

/*
	-in CNI_AXIv2
	-ver3.4 added an input signal indicate to stop w req
*/
/*
	-How to use AXIv2_Slave_FIFO for your component
		-When it is receiving data for AXI Master(handling burst write)
			-RW_ENABLE will become WRITE_ENABLE or READ_WRITE_ENABLE and last only 1 cycle.
			-Assert S_INPUT_RE to 1 in your component, SLAVE_WVALID indicates the writing data is valid.
			-Valid data comes from SLAVE_WDATAREG.
			-You should count the number of data you have got. 
		
		-When it is sending data to AXI Master(handling burst read)
			-RW_ENABLE will become READ_ENABLE or READ_WRITE_ENABLE and last only 1 cycle.
			-Assert S_INPUT_WE to 1 in your component, and put the valid data to SLAVE_RDATAREG in the meantime.
			-You should send total SLAVE_ARLEN amount of data.
*/
/*
	-Handle burst write example
=====================================================
always@(posedge clk)
begin	
	if((RW_ENABLE==WRITE_ENABLE || RW_ENABLE==READ_WRITE_ENABLE) && flag==1'b0)
	begin
		SLAVE_WREADY<=1'b1;
		AWLEN 	<= SLAVE_AWLEN;
		AWSIZE	<= SLAVE_AWSIZE;
		AWBURST	<= SLAVE_AWBURST;
		S_INPUT_RE <= 1'b1;
		flag <= 1'b1;
	end

end
always@(SLAVE_WVALID or flag or SLAVE_WDATAREG)
begin
	if(SLAVE_WVALID== 1'b1 && flag==1'b1)
	begin
		yourREG = SLAVE_WDATAREG;
	end	
end
=====================================================	
*/
/*
	-Handle burst read example
=====================================================	
always@(posedge clk)
begin
	if((RW_ENABLE==READ_ENABLE || RW_ENABLE==READ_WRITE_ENABLE)&& rflag == 1'b0)
	begin
		SLAVE_RADDRREG_REG <= SLAVE_RADDRREG;
		rflag <= 1'b1;
		yourARLEN 	<= SLAVE_ARLEN;
		yourARSIZE	<= SLAVE_ARSIZE;
		yourARBURST	<= SLAVE_ARBURST;
	end
	if(rflag==1'b1)
	begin
		S_INPUT_WE = 1'b1;
		SLAVE_RDATAREG = yourData;
	end		
end
=====================================================	
*/
module AXIv2_Slave_FIFO(
	//Global Signals
	ACLK, //Clock source
	ARESETn, //Reset source

	//Write address channel signals
	AWID, //Master-Write address ID
	AWADDR,//Master-Write address. address of the first transfer in a write burst
	AWLEN,//Master-Burst length. exact number of transfers in a burst
	AWSIZE, //Master-Burst size. This signal indicates the size of each transfer in the burst.
	AWBURST, //Master-Burst type.
	AWLOCK, //Master - NEW. Lock type
	AWCACHE,//Master-NEW. Cache type
	AWPROT,//Master - NEW. Protection type
	AWVALID, //Master - Write address valid. valid write address and control information are available:
	AWREADY,//Slave - Write address ready. Slave ready to accept address 

	//Write data channel signals
	WID,//Master-Write ID tag
	WDATA,//Master-Write data
	WSTRB,//Master-Write strobes
	WLAST,//Master-Write last
	WVALID,//Master-Write valid
	WREADY,//Slave-Write ready. signal indicates that the slave can accept the write data

	//Write response channel signals
	BID, //Slave-Response ID
	BRESP,//Slave-Write response
	BVALID,//Slave-Write response valid.
	BREADY,//Master-Response ready.

	//Read Address chann signals
	ARID, //Master-Read address ID
	ARADDR,//Master-Read address
	ARLEN,//Master-Burst length
	ARSIZE,//Master-Burst size
	ARBURST,//Master-Burst type
	ARLOCK, //Master - NEW. Lock type
	ARCACHE,//Master-NEW. Cache type
	ARPROT,//Master - NEW. Protection type
	ARVALID,//Master-Lock type
	ARREADY,//Master-Read address valid.

	RID, //Slave-Read ID tag.
	RDATA,//Slave-Read data.
	RRESP,//Slave-Read response
	RLAST,//Slave-Read last
	RVALID,//Slave-Read valid
	RREADY,//Master-Read ready
	
	
	//extract data to/from AXI Slave (connect with your component)
	SLAVE_AWID,
	SLAVE_ARID,
	// SLAVE_WID,
	SLAVE_RADDRREG,
	SLAVE_RDATAREG,
	SLAVE_WDATAREG,
	SLAVE_WADDRREG,
	RW_ENABLE,
	
	SLAVE_AWLEN,
	SLAVE_AWSIZE,	//already decoded
	SLAVE_AWBURST,
	SLAVE_ARLEN,	
	SLAVE_ARSIZE,	//already decoded
	SLAVE_ARBURST,	
	
	//FIFO related	
	S_INPUT_WE,		//enable write for FIFO buffer "SendBuffer"(AXI Master is reading from AXI Slave)
	S_INPUT_RE,		//enable read from FIFO buffer "ReceiveBuffer"(AXI Master is writing to AXI Slave)
	SLAVE_WVALID,
	
	STOP_WREQ,
	IssueRead,
	IssueWrite,
	
	Got_IssueRead,
	Got_IssueWrite
);

`define DATAWIDTH 32		//data width
`define ADDRWIDTH 32		//address width

parameter ID_WIDTH = 4;

//Signal description
input 	ACLK;
input 	ARESETn;
input 	[3:0] AWID;
input 	[`ADDRWIDTH - 1:0] AWADDR;
input 	[3:0] AWLEN;
input 	[2:0] AWSIZE;
input 	[1:0] AWBURST;
input 	[1:0] AWLOCK;
input 	[3:0] AWCACHE;
input 	[2:0] AWPROT;


input 	AWVALID;  
output 	AWREADY;
reg  	AWREADY, next_AWREADY;		//Deam - enabled, "assign AWREADY = AWVALID; " is not working
input 	[3:0] WID;
reg		[3:0] WID_REG,next_WID_REG;
input 	[`DATAWIDTH - 1:0] WDATA;
reg 	[`DATAWIDTH - 1:0] WDATA_REG, next_WDATA_REG;
input 	[3:0] WSTRB;
input  	WLAST;
input	WVALID;

output 	[3:0] BID;
reg		[3:0] BID,next_BID;
output 	[1:0] BRESP;
reg 	[1:0] BRESP, next_BRESP;

output 	BVALID;
reg  	BVALID, next_BVALID;

input  	BREADY;

output 	WREADY;
reg 	WREADY,next_WREADY;

input 	[3:0] ARID;
reg		[3:0] ARID_REG;
input 	[`ADDRWIDTH - 1:0] ARADDR;
input 	[3:0] ARLEN;
input 	[2:0] ARSIZE;
input 	[1:0] ARBURST;
input 	[1:0] ARLOCK;
input	[3:0] ARCACHE;
input	[2:0] ARPROT;
input	ARVALID;  
output 	ARREADY;
reg  	ARREADY,next_ARREADY;		//Deam - added, ARREADY should always be 1

output 	[3:0] RID;
reg		[3:0] RID,next_RID;
output 	[`DATAWIDTH - 1:0] RDATA;
reg		[`DATAWIDTH - 1:0] RDATA, next_RDATA;

output 	RLAST;
reg 	RLAST, next_RLAST;

output 	RVALID;
reg 	RVALID, next_RVALID;

output 	[1:0] RRESP;
reg 	[1:0] RRESP, next_RRESP;  //Read Response

input 	RREADY;

output 	[`DATAWIDTH - 1:0] SLAVE_WDATAREG;
//reg 	[31:0] SLAVE_WDATAREG;

output 	[`ADDRWIDTH - 1:0] SLAVE_WADDRREG;
reg 	[`ADDRWIDTH - 1:0] SLAVE_WADDRREG,next_SLAVE_WADDRREG;

output 	[`ADDRWIDTH - 1:0] SLAVE_RADDRREG;
reg 	[`ADDRWIDTH - 1:0] SLAVE_RADDRREG,next_SLAVE_RADDRREG;

input 	[`DATAWIDTH - 1:0] SLAVE_RDATAREG;
reg		[`DATAWIDTH - 1:0] SLAVE_RDATAREG_REG;

output 	[3:0] SLAVE_AWLEN;
reg 	[3:0] SLAVE_AWLEN,next_SLAVE_AWLEN;

//output 	[7:0] SLAVE_AWSIZE;	//already decoded
//reg 	[7:0] SLAVE_AWSIZE;
output 	[2:0] SLAVE_AWSIZE;	//no need decoded
reg 	[2:0] SLAVE_AWSIZE,next_SLAVE_AWSIZE;

output 	[1:0] SLAVE_AWBURST;
reg 	[1:0] SLAVE_AWBURST,next_SLAVE_AWBURST;

output 	[3:0] SLAVE_ARLEN;
reg 	[3:0] SLAVE_ARLEN, next_SLAVE_ARLEN;

// output 	[7:0] SLAVE_ARSIZE;	//already decoded
// reg 	[7:0] SLAVE_ARSIZE;
output 	[2:0] SLAVE_ARSIZE;	//no need decoded
reg 	[2:0] SLAVE_ARSIZE, next_SLAVE_ARSIZE;

output 	[1:0] SLAVE_ARBURST;
reg 	[1:0] SLAVE_ARBURST, next_SLAVE_ARBURST;		
//RW_ENABLE = 10 read
//RW_ENABLE = 11 write
//RW_ENABLE = 01 read/write
//RW_ENABLE = 00 nothing
output 	[1:0] RW_ENABLE;
reg 	[1:0] RW_ENABLE;
reg 	[1:0] RW_ENABLE_REG;

//FIFO buffer related
//ReceiveBuffer is for AXI Master writing data to AXI Slave
//SendBuffer is for AXI Master reading data from AXI Slave
input 	S_INPUT_WE;			//enable write for FIFO buffer "SendBuffer"
input 	S_INPUT_RE;
reg 	Internal_RE, next_Internal_RE;		//enable read from FIFO buffer "SendBuffer"
reg		Internal_WE, next_Internal_WE;
output	SLAVE_WVALID;

input	STOP_WREQ; //stop send write req
//Internal Registers
reg 	[4:0]rNumBurstCount, next_rNumBurstCount;
wire 	[`DATAWIDTH - 1:0] TEMP_RDATA;
wire 	TEMP_RVALID;
reg 	[3:0] RBurstLen, next_RBurstLen;
reg 	TEMP_RREADY;

output	IssueWrite;
reg 	IssueWrite, next_IssueWrite;
output	IssueRead;
reg		IssueRead, next_IssueRead;	

input	Got_IssueWrite;
input	Got_IssueRead;

output	[ID_WIDTH-1:0] SLAVE_AWID;
reg		[ID_WIDTH-1:0] SLAVE_AWID, next_SLAVE_AWID;
output	[ID_WIDTH-1:0] SLAVE_ARID;
reg		[ID_WIDTH-1:0] SLAVE_ARID, next_SLAVE_ARID;


reg [7:0] rCurState,rNextState;
parameter [7:0]
	rIdle 	= 0,
	rWtData = 1,
	rSdData = 2,
	rDone	= 3;

reg [7:0] wCurState,wNextState;
parameter [7:0]
	wIdle 	= 0,
	wWtGotIssueW = 1,
	wWtData = 2,
	wSdData = 3,
	wDone	= 4;
	
parameter
	// Read Enable
	READ_ENABLE = 2'b10,
	//Write Enable 
	WRITE_ENABLE = 2'b11,
	//Read and Write Enable
	READ_WRITE_ENABLE = 2'b01,
	//Read and Write Disable
	READ_WRITE_DISABLE = 2'b00;
	
initial 
begin
	//other
	RW_ENABLE = READ_WRITE_DISABLE;
	RW_ENABLE_REG = READ_WRITE_DISABLE;
	
	rNumBurstCount = 5'b00000;
	TEMP_RREADY = 1'b0;
	
	rCurState 	= rIdle;
	rNextState 	= rIdle;	
	wCurState 	= wIdle;
	wNextState 	= wIdle;		
end

basic_fifo #(`DATAWIDTH,4) SendBuffer(
	.clock(ACLK),
	.reset(ARESETn),
	.data_in(SLAVE_RDATAREG),
	.enq(S_INPUT_WE),
	.full(),
	.data_out(TEMP_RDATA),
	.valid_out(TEMP_RVALID),
	.deq(Internal_RE)
);

basic_fifo #(`DATAWIDTH,4) ReceiveBuffer(
	.clock(ACLK),
	.reset(ARESETn),
	.data_in(WDATA_REG),	//SLAVE_WDATAREG <= WDATA;
	.enq(Internal_WE),
	.full(),
	.data_out(SLAVE_WDATAREG),
	.valid_out(SLAVE_WVALID),
	.deq(S_INPUT_RE)
);

//assign RW_ENABLE
// always@(IssueWrite or IssueRead or STOP_WREQ)
// begin
		// case({IssueWrite,IssueRead})
		// 2'b00:
		// begin
			// RW_ENABLE <= READ_WRITE_DISABLE;
		// end
		// 2'b10:
		// begin
			// RW_ENABLE <= WRITE_ENABLE;
		// end
		// 2'b01:
		// begin
			// RW_ENABLE <= READ_ENABLE;
		// end
		// 2'b11:
		// begin
			// RW_ENABLE <= READ_WRITE_ENABLE;
		// end	
		// endcase
// end
/*
	burst write
*/

always@(*)
begin
	next_SLAVE_WADDRREG <= SLAVE_WADDRREG;
	next_SLAVE_AWSIZE 	<= SLAVE_AWSIZE;
	next_SLAVE_AWLEN 	<= SLAVE_AWLEN;
	next_SLAVE_AWBURST 	<= SLAVE_AWBURST;
	
	next_IssueWrite		<= IssueWrite;
	next_AWREADY		<= AWREADY;
	wNextState 			<= wCurState;
	next_WREADY 		<= WREADY;	
	next_BVALID 		<= BVALID;
	next_BRESP 			<= BRESP;	
	next_Internal_WE 	<= Internal_WE;
	next_WDATA_REG		<= WDATA_REG;
	
	next_WID_REG		<= WID_REG;
	next_BID			<= BID;
	
	next_SLAVE_AWID		<= SLAVE_AWID;

	case(wCurState)
	wIdle:
	begin
		if(STOP_WREQ==1'b0 && AWVALID == 1'b1)
		begin
			next_SLAVE_WADDRREG <= AWADDR;
			next_SLAVE_AWSIZE 	<= AWSIZE;
			next_SLAVE_AWLEN 	<= AWLEN;
			next_SLAVE_AWBURST 	<= AWBURST;
			
			next_IssueWrite		<= 1'b1;
			next_AWREADY		<= 1'b1;
			wNextState 			<= wWtGotIssueW;
			
			next_Internal_WE 	<= 1'b0;
			next_SLAVE_AWID 	<= AWID;
			//if(WVALID == 1'b1 && AWLEN> 0)
			begin
				next_WREADY 		<= 1'b0;
				//next_Internal_WE 	<= 1'b1;
			end	
		end
		else
			next_AWREADY		<= 1'b0;
	end
	wWtGotIssueW:
	begin
		next_AWREADY		<= 1'b0;
		if(Got_IssueWrite==1'b1)
		begin
			next_IssueWrite	<= 1'b0;
			wNextState 		<= wWtData;
			next_WREADY 	<= 1'b1;
		end
	end
	wWtData:
	begin
		if(WVALID == 1'b1)
		begin
			next_WID_REG		<= WID;
			next_Internal_WE 	<= 1'b1;
			next_WDATA_REG 		<= WDATA;
			if(WLAST == 1'b1)
			begin
				next_WREADY 	<= 1'b0;
				wNextState 		<= wDone;
				
				next_BVALID <= 1'b1;
				next_BRESP 	<= 2'b00;
				//next_BID	<=	WID_REG;
				next_BID	<=	WID;
			end
		end
		else
		begin
			next_Internal_WE 	<= 1'b0;
		end			
	end
	wDone:
	begin
		next_Internal_WE <= 1'b0;
		next_WREADY <= 1'b0;		
		if(BREADY == 1'b1)
		begin
			next_BVALID <= 1'b0; 
			next_BRESP <= 2'bzz;
			wNextState 	<= wIdle;
		end
		// else
		// begin
			// next_BVALID <= 1'b1;
			// next_BRESP <= 2'b00;
			// next_BID	<=	WID_REG;		
		// end
	end
	endcase
end

always@(posedge ACLK)
begin
	SLAVE_WADDRREG 	<= next_SLAVE_WADDRREG;
	SLAVE_AWSIZE 	<= next_SLAVE_AWSIZE;
	SLAVE_AWLEN 	<= next_SLAVE_AWLEN;
	SLAVE_AWBURST 	<= next_SLAVE_AWBURST;	
	IssueWrite		<= next_IssueWrite;
	AWREADY			<= next_AWREADY;
	wCurState 		<= wNextState;
	WREADY 			<= next_WREADY;	
	BVALID 			<= next_BVALID;
	BRESP 			<= next_BRESP;	
	Internal_WE 	<= next_Internal_WE;
	WDATA_REG		<= next_WDATA_REG;
	WID_REG			<= next_WID_REG;
	BID				<= next_BID;
	
	SLAVE_AWID		<= next_SLAVE_AWID;
end

/*
	burst read
*/


always@(*)
begin
	next_SLAVE_RADDRREG<=SLAVE_RADDRREG;	
	next_ARREADY<=ARREADY;
	next_SLAVE_ARSIZE<=SLAVE_ARSIZE;	
	next_SLAVE_ARLEN<=SLAVE_ARLEN;	
	next_SLAVE_ARBURST<=SLAVE_ARBURST;	
	next_RBurstLen<=RBurstLen;
	next_rNumBurstCount<=rNumBurstCount;	
	next_IssueRead<=IssueRead;
	next_RRESP<=RRESP;
	next_RVALID<=RVALID;	
	next_RDATA<=RDATA;
	next_RLAST<=RLAST;
	next_rNumBurstCount<=rNumBurstCount;
	next_Internal_RE<=Internal_RE;
	rNextState<=rCurState;
	next_RID<=RID;
	next_SLAVE_ARID		<= SLAVE_ARID;
	case(rCurState)
	rIdle:
	begin
		if(STOP_WREQ==1'b0 && ARVALID == 1'b1)
		begin
			//COPY Read address to your register
			next_SLAVE_RADDRREG <= ARADDR;
			
			//start to check the FIFO buffer
			//TEMP_RREADY <= 1'b1;
			next_ARREADY <= 1'b1;
			
			next_SLAVE_ARSIZE <= ARSIZE;

			next_SLAVE_ARLEN 	<= ARLEN;
			next_SLAVE_ARBURST 	<= ARBURST;	
			next_RBurstLen		<= ARLEN + 1;
			next_rNumBurstCount <= ARLEN + 1;
			//IssuedReadAddr 	<= 1'b1;
			next_IssueRead	<= 1'b1;
			
			rNextState <= rWtData;
			next_Internal_RE <= 1'b1;
			
			ARID_REG <= ARID;
			
			next_SLAVE_ARID <= ARID;
		end
		else
			next_ARREADY <= 1'b0;
	end
	rWtData:
	begin
		next_ARREADY <= 1'b0;
		if(Got_IssueRead==1'b1)
		begin
			next_IssueRead	<= 1'b0;
		end	
		
		if(rNumBurstCount==0)
		begin
			next_ARREADY <= 1'b0;
			next_RRESP 	<= 2'bzz;
			next_RVALID <= 1'b0;
			next_RDATA 	<= 32'hzzzzzzzz;
			next_RLAST <= 1'b0;			
			rNextState <= rDone;
			next_Internal_RE <= 1'b0;
		end
		else
		begin
			
			if(TEMP_RVALID==1'b1)
			begin
				next_RDATA <= TEMP_RDATA;
				next_RVALID <= 1'b1;	
				rNextState <= rSdData;
				
				next_RID<=ARID_REG;
				if(rNumBurstCount==1)
				begin
					next_RLAST <= 1'b1;
				end

				next_Internal_RE <= 1'b0;
			end
			else
				next_RVALID <= 1'b0;
		end	
	end
	rSdData:
	begin
		if(RREADY==1'b1)
		begin
			next_rNumBurstCount <= rNumBurstCount - 1;
			next_RRESP 	<= 2'b00;
			next_RVALID <= 1'b0;			
			rNextState <= rWtData;
			next_Internal_RE <= 1'b1;
		end		
	end
	rDone:
	begin
		next_Internal_RE <=0;
		rNextState <= rIdle;
	end
	endcase
end

always@(posedge ACLK)
begin
	SLAVE_RADDRREG	<=next_SLAVE_RADDRREG;
	ARREADY			<=next_ARREADY;
	SLAVE_ARSIZE	<=next_SLAVE_ARSIZE;
	SLAVE_ARLEN		<=next_SLAVE_ARLEN;
	SLAVE_ARBURST	<=next_SLAVE_ARBURST;
	RBurstLen		<=next_RBurstLen;
	rNumBurstCount	<=next_rNumBurstCount;
	IssueRead		<=next_IssueRead;
	RRESP			<=next_RRESP;
	RVALID			<=next_RVALID;
	RDATA			<=next_RDATA;
	RLAST			<=next_RLAST;
	rNumBurstCount	<=next_rNumBurstCount;
	Internal_RE		<=next_Internal_RE;
	rCurState		<=rNextState;
	RID				<=next_RID;
	SLAVE_ARID		<=next_SLAVE_ARID;
end
endmodule
