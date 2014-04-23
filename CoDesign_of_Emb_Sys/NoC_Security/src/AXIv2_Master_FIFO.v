/*
	ver2.1 Disable using INPUT_WVALID
	ver2.2 integrate with true dummyCore and NIC
	ver2.3 add comments and add `define DWIDTH and `define AWIDTH
	ver2.4 add reset for Receive FIFO and Send FIFO
*/
/*
	-added SFULL output
*/
module AXIv2_Master_FIFO(

  //Global Signals
  ACLK, //Clock source
  ARESETn, //Reset source
  RSTSFIFO,	//reset Send FIFO
  RSTRFIFO, //reset Receive FIFO
  //AXI Master Related
  
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
  
  //connect with dummyCore 
  
  //AXI config
  INPUT_AWID,
  INPUT_ARID,
  
  INPUT_AWLEN,
  INPUT_AWSIZE,
  INPUT_AWBURST,
  INPUT_ARLEN,
  INPUT_ARSIZE,
  INPUT_ARBURST,
  
  RW_ENABLE, 		// 2bit indicating iniiate read or write 10 - read 11 - write
  
  INPUT_RADDR, 		// Address for read
  OUTPUT_RDATA, 	// Data which is read
  OUTPUT_RVALID,	//indicate output read data is available
  
  INPUT_WADDR, 		//Address for write
  INPUT_WDATA,  	//Data to be written
 
  INPUT_RE,			//enable read from FIFO buffer "ReceiveBuffer"
  INPUT_WE,			//enable write for FIFO buffer "SendBuffer"
  //FULL,				//indicate whether the FIFO buffer is full or not
  WBUFFER_EMPTY,				//indicate whether the SendBuffer is empty or not
  //valid_out
  
  bWReady,
  SFULL,
  W_BUSY
);

`define DWIDTH 32		//data width
`define AWIDTH 32		//address width

parameter ID_WIDTH = 4;

//Signal description
input ACLK;
input ARESETn;
input RSTSFIFO;
input RSTRFIFO;

output [3:0] AWID;
reg	   [ID_WIDTH-1:0] AWID;
output [`AWIDTH -1 :0] AWADDR;
output [3:0] AWLEN;
output [2:0] AWSIZE;
output [1:0] AWBURST;
output [1:0] AWLOCK;
output [3:0] AWCACHE;
output [2:0] AWPROT;

output AWVALID;  
input AWREADY;
//reg  AWREADY;
output [3:0] WID;
reg	   [ID_WIDTH-1:0] WID;
output [`DWIDTH -1 :0] WDATA;
output [3:0] WSTRB;
output  WLAST,WVALID;
input WREADY;
reg WREADY_r;
input [3:0] BID;
input [1:0] BRESP;
input BVALID;
output  BREADY;


output [3:0] ARID;
reg	   [ID_WIDTH-1:0] ARID;
output [`AWIDTH -1:0] ARADDR;
output [3:0] ARLEN;
output [2:0] ARSIZE;
output [1:0] ARBURST;
output [1:0] ARLOCK;
output[3:0] ARCACHE;
output[2:0] ARPROT;
output  ARVALID;  
input ARREADY;


input [3:0] RID;
input [`DWIDTH -1 :0] RDATA;
input RLAST,RVALID;
input [1:0] RRESP;
output RREADY;

//Output registers
reg  AWVALID,ARVALID;
//reg  WLAST;
//reg  WVALID;
reg [1:0] AWBURST ,ARBURST ;
reg [2:0] ARSIZE,AWSIZE;
reg [3:0] AWLEN,ARLEN;
//reg [31:0] WDATA;



reg BREADY,RREADY;
reg [`AWIDTH -1:0] AWADDR;
reg [`AWIDTH -1:0] ARADDR;
//Required for logic
reg [`DWIDTH -1 :0] TESTDATAREG;	//??
reg [`AWIDTH -1:0] ADDRREG;		//??

reg [7:0] wNumBurstCount;   // It should be equal to Burst size in the beginning
reg [7:0] burstSize;

//Deam - add, temporary registers
reg [`AWIDTH -1:0] TEMPWADDRREG;	//??
wire [`DWIDTH -1 :0] TEMPWDATAREG;	//??
reg [`AWIDTH -1:0] TEMPRADDRREG;		//??
reg wFIRSTBYTE;
reg rFIRSTBYTE;
reg wDONE;
reg rDONE;
reg [3:0] WSTRB;
reg [1:0] rrw_enable;
reg [7:0] rNumBurstCount;   // 
reg [7:0] rburstSize;

output OUTPUT_RVALID;
//reg OUTPUT_RVALID;

output WBUFFER_EMPTY;
//AXI config
input [ID_WIDTH-1:0] INPUT_AWID;
input [ID_WIDTH-1:0] INPUT_ARID;
input [3:0] INPUT_AWLEN;
input [2:0] INPUT_AWSIZE;
input [1:0] INPUT_AWBURST;
input [3:0] INPUT_ARLEN;
input [2:0] INPUT_ARSIZE;
input [1:0] INPUT_ARBURST;	
	
//FIFO buffer related
//ReceiveBuffer is for AXI Master receving data from AXI Slave
//SendBuffer is for AXI Master sending data to AXI Slave 
input INPUT_RE;			//enable read from FIFO buffer "ReceiveBuffer"
input INPUT_WE;			//enable write for FIFO buffer "SendBuffer"
//output FULL;			//indicate whether the FIFO buffer is FULL or not
//output EMPTY;			//indicate whether the FIFO buffer is empyt or not
reg Internal_WE;		//enable write for FIFO buffer "ReceiveBuffer"
reg Internal_RE;		//enable read from FIFO buffer "SendBuffer"
wire RFULL;
output SFULL;
wire SVALID;

//Internal Register to store values
reg  [2:0] mWriteSize;
reg  [3:0] mWriteBurstLen;
reg  [1:0] mWburstType;


reg  [2:0] mReadSize;
reg  [3:0] mReadBurstLen;
reg  [1:0] mRburstType;

output 	bWReady;
reg 	bWReady;  // Change this signal to initiate write 
reg bRReady; // Change this signal to initiate read
reg bStartRead;
//Temporary to trigger to write TODO: Change it later
reg [31:0]  bWReadyCycle;  //Aalap - Commented	??
reg [31:0] bRReadyCycle;     					//??


reg    [1:0]   rw_enable;
input  [1:0]   RW_ENABLE;
input  [`AWIDTH -1 :0]  INPUT_RADDR;
output [`DWIDTH -1 :0]  OUTPUT_RDATA;
input  [`AWIDTH -1:0]  INPUT_WADDR;
input  [`DWIDTH -1 :0]  INPUT_WDATA;
// inout  [31:0]  INPUT_WDATA;
//reg [31:0] OUTPUT_RDATA;

output 	W_BUSY;
reg		W_BUSY;

assign WVALID = SVALID && wFIRSTBYTE && (~wDONE);
assign WLAST = (wNumBurstCount == (mWriteBurstLen)) && wFIRSTBYTE && WVALID;
//Temporary for test;
parameter 
    WRITE_START_CYCLE = 4'b0011,

//Temporary for test
    READ_START_CYCLE = 4'b0011,
    /*
    * ARBURST or AWBURST signal selects the burst type.
    */
    W_BURST_TYPE_FIXED = 2'b00,
    W_BURST_TYPE_INCR   = 2'b01,
    W_BURST_TYPE_WRAP = 2'b10,
    
    /*
    *ARSIZE or AWSI ZE signal specifies the maximum number of data bytes to transfer in each beat, or data transfer, within a burst
    */
    W_BURST_SIZE_1 = 3'b000,
    W_BURST_SIZE_2 = 3'b001,
    W_BURST_SIZE_4 = 3'b010,
    W_BURST_SIZE_8 = 3'b011,
    W_BURST_SIZE_16 = 3'b100,
    W_BURST_SIZE_32 = 3'b101,
    W_BURST_SIZE_64 = 3'b110,
    W_BURST_SIZE_128 = 3'b111,
    
    /*
    *AWLEN or ARLEN signal specifies the number of data transfers that occur within each burst
    */
     W_BURST_LEN_1 =  4'b000,
     W_BURST_LEN_2 = 4'b001,
     W_BURST_LEN_3 = 4'b010,
     W_BURST_LEN_4 = 4'b011,
     W_BURST_LEN_5 = 4'b100,
     W_BURST_LEN_6 = 4'b101,
     W_BURST_LEN_7 = 4'b110,
     W_BURST_LEN_8 = 4'b111,
     W_BURST_LEN_9 = 4'b1000,
     W_BURST_LEN_10 = 4'b1001,
     W_BURST_LEN_11 = 4'b1010,
     W_BURST_LEN_12 = 4'b1011,
     W_BURST_LEN_13 = 4'b1100,
     W_BURST_LEN_14 = 4'b1101,
     W_BURST_LEN_15 = 4'b1110,
     W_BURST_LEN_16 = 4'b1111,
    
    
    // Response signals
     AXI_RESP_OKAY = 2'b00,
     AXI_RESP_EXOKAY = 2'b01,
     AXI_RESP_SLVERR = 2'b10,
     AXI_RESP_DECERR = 2'b11,
    
   //TEMP parameter to initiate write cycle
    //TEST: Initiate write at cycle 3 and cycle 22
     TEMP_AXI_WRITE_INITIATE = 4'b0011,
     TEMP_AXI_WRITE_INITIATE2 = 8'h16,  
     
        
     TEMP_AXI_READ_INITIATE = 8'h28,
     TEMP_AXI_READ_INITIATE2 = 8'h3F,

    // Read Enable
		READ_ENABLE = 2'b10,
	//Write Enable 
		WRITE_ENABLE = 2'b11,
	//Read and Write Enable
		READ_WRITE_ENABLE = 2'b01;



initial begin
    //FIFO related
	WREADY_r = 1'b0;
    //WLAST = 1'b1;   // Followed from the signal captured from sample AXI master
    //WVALID = 1'b0;
    
    BREADY = 1'b0;
    bWReady = 1'b1;  // Set it as enable write from the beginning
    
    bRReady = 1'b0;
    TESTDATAREG = 32'h01;
    wNumBurstCount = 8'h00;
    
    //temporary trigger cycle to initiate write
    bWReadyCycle = 4'b00;
    bRReadyCycle  =  4'b00;


    //Read init 
    RREADY = 1'b1;
	
	//Deam - added
	rw_enable = 2'b00;
	rrw_enable = 2'b00;
	wFIRSTBYTE = 1'b0;
	rFIRSTBYTE = 1'b0;
	wDONE = 1'b0;
	rDONE = 1'b0;
	rNumBurstCount = 8'h00;

end

basic_fifo #(`DWIDTH) ReceiveBuffer(
	.clock(ACLK),
	.reset(RSTRFIFO),
	.data_in(RDATA),
	.enq(Internal_WE),
	.full(RFULL),
	.data_out(OUTPUT_RDATA),
	.valid_out(OUTPUT_RVALID),
	.deq(INPUT_RE)
);	

basic_fifo #(`DWIDTH) SendBuffer(
	.clock(ACLK),
	.reset(RSTSFIFO),
	.data_in(INPUT_WDATA),
	.enq(INPUT_WE),
	.full(SFULL),
	.data_out(WDATA), //TEMPWDATAREG
	.valid_out(SVALID),
	.deq(Internal_RE)
);	

	
always @(posedge  ARESETn)
    begin
           //WLAST = 1'b1;   // Followed from the signal captured from sample AXI master
            //WVALID = 1'b0;
    
            BREADY = 1'b1;
            bWReady = 1'b1;  // Set it as enable write from the beginning
    
            bRReady = 1'b1;
            TESTDATAREG = 32'h01;
            wNumBurstCount = 8'h00;
            
            //Read init 
            RREADY = 1'b1;
        end


//Deam - Write Logic
//issue the writing address and data
always@(WREADY)
begin
	WREADY_r = WREADY;
	if(WREADY_r == 1'b0)
		Internal_RE = 1'b0;
	else
		Internal_RE = 1'b1;
end
always@(posedge ACLK) 
begin
	
	if((RW_ENABLE == WRITE_ENABLE || RW_ENABLE == READ_WRITE_ENABLE) && bWReady)
	begin
		rw_enable <= RW_ENABLE;
		
		AWADDR <= INPUT_WADDR;
		
		//Todo: mWriteBurstLen, mWburstType and mWriteSize become input
		// initBurstWrite(W_BURST_SIZE_4,W_BURST_TYPE_INCR,W_BURST_LEN_16);
		// AWLEN 	<=	mWriteBurstLen;
		// AWBURST <=  mWburstType;
		// AWSIZE 	<= 	mWriteSize;
		AWLEN <= INPUT_AWLEN;
		AWSIZE <= INPUT_AWSIZE;
		AWBURST <= INPUT_AWBURST;	
		mWriteBurstLen <= INPUT_AWLEN;
		
		AWID<=INPUT_AWID;
		WID<=INPUT_AWID;
		//Todo: become input?
		WSTRB	<=	4'b1111;
		
		wNumBurstCount <= 0;
		//Todo: 
		//AWLOCK = 0;
		//AWCACHE = 0;
		
		AWVALID <= 1'b1;	
			
		//WVALID <= 1'b1;
		BREADY <= 1'b1;
		WREADY_r <= 1'b1;
		//WLAST <= 1'b0;
		wDONE <= 1'b0;
		wFIRSTBYTE <= 1'b1;
		
		//enable read from SendBuffer
		//Internal_RE <= 1'b1;
		if(INPUT_AWLEN==0)
			WREADY_r <= 1'b0;
		else
			WREADY_r <= 1'b1;

		W_BUSY <= 1'b1;
	end
	
	
	if(wFIRSTBYTE == 1'b1 && wDONE == 1'b0 && SVALID == 1'b1)
	begin
		//WVALID  <= 1'b1;
		//WDATA 	<= TEMPWDATAREG;
		WSTRB	<=	4'b1111;
		//slave received the last data successfully 
		if(WREADY == 1'b1)
		begin				
			wNumBurstCount <= wNumBurstCount+1;	

			if(wNumBurstCount == (mWriteBurstLen))
			begin
				//WLAST <= 1'b1;					
				rw_enable <= 2'b00;
				wFIRSTBYTE <= 1'b0;	
				wDONE <= 1'b1;
			end			
		end
		/*
		if(wNumBurstCount == (mWriteBurstLen))
		begin
			//WLAST <= 1'b1;					
			rw_enable <= 2'b00;
			wFIRSTBYTE <= 1'b0;	
			wDONE <= 1'b1;
		end
		*/
	end
	// else if(SVALID == 1'b0)
		// WVALID  <= 1'b0;
	if(wDONE == 1'b1)
	begin
		//WVALID <= 1'b0;
		WSTRB	<=	4'bzzzz;
		WREADY_r <=1'b0;
	end	
	if(AWREADY == 1'b1 && wFIRSTBYTE==1'b1)
	begin
		bWReady <= 1'b0;
		AWADDR 	<= 32'bzz;
		AWVALID <= 1'b0;
		AWLEN  	<= 4'bzzz;
		AWBURST <= 2'bzz;
		AWSIZE  <= 3'bzz;		
	end
end
//WE can export bWReady to notify writing is done(but it results in increasing latency)
always@(posedge ACLK)
begin
	if((BVALID == 1'b1) && (BRESP == AXI_RESP_OKAY))
	begin
		BREADY 	<= 1'b0;
		bWReady <= 1'b1;		
		wNumBurstCount <= 8'h01;	
		wDONE <= 1'b0;
		W_BUSY <= 1'b0;
	end
end


//Deam - Read Logic

//issue the read address
always@(posedge ACLK) 
begin
	if((RW_ENABLE == READ_ENABLE || RW_ENABLE == READ_WRITE_ENABLE) && bRReady)
	begin
		rrw_enable <= RW_ENABLE;
		
		ARADDR <= INPUT_RADDR;
		//OUTPUT_RVALID <= 1'b0;
		
		//Todo: mWriteBurstLen, mWburstType and mWriteSize become input
		// initBurstRead(W_BURST_SIZE_4,W_BURST_TYPE_INCR,W_BURST_LEN_16);
		// ARLEN 	<=	mReadBurstLen;
		// ARBURST <=  mRburstType;
		// ARSIZE 	<= 	mReadSize;

		ARLEN <= INPUT_ARLEN;
		ARSIZE <= INPUT_ARSIZE;
		ARBURST <= INPUT_ARBURST;
		
		ARID<=INPUT_ARID;
		//mRriteBurstLen <= INPUT_ARLEN;		
		ARVALID <= 1'b1;		
		rNumBurstCount <= 8'h00;
		rFIRSTBYTE <= 1'b1;
		rDONE <=1'b0;
	end
	
	if(ARREADY == 1'b1 && ARVALID == 1'b1)
	begin
		ARADDR 		<= 32'bzz;
		ARVALID 	<= 1'b0;
		ARLEN    	<= 4'bzzz;
		ARBURST 	<= 2'bzz;
		ARSIZE     	<= 3'bzz;
		
		bRReady 	<= 1'b0;
	end
	
	if(rDONE == 1'b1)
	begin
		//OUTPUT_RVALID <= 1'b0;
		rDONE <=1'b0;
		rFIRSTBYTE 	<= 1'b0;	
	end
end

//fetch the RDATA to ReceiveBuffer
always@ (rFIRSTBYTE or RVALID or RLAST)
begin
	if(rFIRSTBYTE == 1'b1 && RVALID == 1'b1)	//RRESP == AXI_RESP_OKAY
	begin
		//indicate the RDATA is available
		//OUTPUT_RVALID = 1'b1;
		
		//enable write for ReceiveBuffer
		Internal_WE = 1'b1;
		
		if(RLAST == 1'b1)
		begin
			rrw_enable 	= 2'b00;
			bRReady		= 1'b1;
			rDONE = 1'b1;			
		end
	end
	else if(RVALID == 1'b0)
		Internal_WE = 1'b0;
end
		           
endmodule
