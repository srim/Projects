/*
	-integrate the SNI with the router
*/

`include "constants.v"

module CNI_SNI(
	clk,
	rst,
	
	//AXI Master
	//Write address channel signals
	M_AWID, //Master-Write address ID
	M_AWADDR,//Master-Write address. address of the first transfer in a write burst
	M_AWLEN,//Master-Burst length. exact number of transfers in a burst
	M_AWSIZE, //Master-Burst size. This signal indicates the size of each transfer in the burst.
	M_AWBURST, //Master-Burst type.
	M_AWLOCK, //Master - NEW. Lock type
	M_AWCACHE,//Master-NEW. Cache type
	M_AWPROT,//Master - NEW. Protection type
	M_AWVALID, //Master - Write address valid. valid write address and control information are available:
	M_AWREADY,//Slave - Write address ready. Slave ready to accept address 

	//Write data channel signals
	M_WID,//Master-Write ID tag
	M_WDATA,//Master-Write data
	M_WSTRB,//Master-Write strobes
	M_WLAST,//Master-Write last
	M_WVALID,//Master-Write valid
	M_WREADY,//Slave-Write ready. signal indicates that the slave can accept the write data

	//Write response channel signals
	M_BID, //Slave-Response ID
	M_BRESP,//Slave-Write response
	M_BVALID,//Slave-Write response valid.
	M_BREADY,//Master-Response ready.

	//Read Address chann signals
	M_ARID, //Master-Read address ID
	M_ARADDR,//Master-Read address
	M_ARLEN,//Master-Burst length
	M_ARSIZE,//Master-Burst size
	M_ARBURST,//Master-Burst type
	M_ARLOCK, //Master - NEW. Lock type
	M_ARCACHE,//Master-NEW. Cache type
	M_ARPROT,//Master - NEW. Protection type
	M_ARVALID,//Master-Lock type
	M_ARREADY,//Master-Read address valid.

	M_RID, //Slave-Read ID tag.
	M_RDATA,//Slave-Read data.
	M_RRESP,//Slave-Read response
	M_RLAST,//Slave-Read last
	M_RVALID,//Slave-Read valid
	M_RREADY,//Master-Read ready
	
	CINC_STATUS,
	
	//myx myy
	myx,
	myy,
	
	//LinkC
	p_data_valid,
	p_data_out,
	p_LinkC_Status_in,
	
	dp_data_in,
	dp_data_read,
	dp_data_in_valid//,
   // anomaly_detected
);

input 	[`XY_WIDTH-1:0]myx;
input 	[`XY_WIDTH-1:0]myy;

input clk;
input rst;

//AXI Master
wire RSTSFIFO;
wire RSTRFIFO;

output 	[3:0] M_AWID;
output 	[`AXIM_ADDR_WIDTH -1 :0] M_AWADDR;
output 	[3:0] M_AWLEN;
output 	[2:0] M_AWSIZE;
output 	[1:0] M_AWBURST;
output 	[1:0] M_AWLOCK;
output 	[3:0] M_AWCACHE;
output 	[2:0] M_AWPROT;

//output [1:0] anomaly_detected;

output 	M_AWVALID;  
input 	M_AWREADY;
output 	[3:0] M_WID;
output 	[`AXIM_DATA_WIDTH -1 :0] M_WDATA;
output 	[3:0] M_WSTRB;
output  M_WLAST;
output	M_WVALID;
input 	M_WREADY;
input 	[3:0] M_BID;
input 	[1:0] M_BRESP;
input 	M_BVALID;
output  M_BREADY;

output 	[3:0] M_ARID;
output 	[`AXIM_ADDR_WIDTH -1:0] M_ARADDR;
output 	[3:0] M_ARLEN;
output 	[2:0] M_ARSIZE;
output 	[1:0] M_ARBURST;
output 	[1:0] M_ARLOCK;
output	[3:0] M_ARCACHE;
output	[2:0] M_ARPROT;
output  M_ARVALID;  
input 	M_ARREADY;

input 	[3:0] M_RID;
input 	[`AXIM_DATA_WIDTH -1 :0] M_RDATA;
input 	M_RLAST;
input	M_RVALID;
input 	[1:0] M_RRESP;
output 	M_RREADY;

wire	[`AXI_ID_WIDTH-1:0] MASTER_AWID;
wire	[`AXI_ID_WIDTH-1:0] MASTER_ARID;
wire 	[3:0] MASTER_AWLEN;
wire 	[2:0] MASTER_AWSIZE;
wire 	[1:0] MASTER_AWBURST;
wire 	[3:0] MASTER_ARLEN;
wire 	[2:0] MASTER_ARSIZE;
wire 	[1:0] MASTER_ARBURST;
wire  	[1:0] MASTER_RW_ENABLE;
wire	[`AXIM_ADDR_WIDTH-1:0] MASTER_RADDR; 	// Address for read
wire	[`AXIM_DATA_WIDTH-1:0] MASTER_RDATA; 	// Data which is read
wire	MASTER_RVALID;	//indicate output read data is available
wire	[`AXIM_ADDR_WIDTH-1:0]	MASTER_WADDR; 		//Address for write
wire 	[`AXIM_DATA_WIDTH-1:0]	MASTER_WDATA;  	//Data to be written
wire	M_INPUT_RE;		//enable read from AXIv2 Master FIFO buffer "ReceiveBuffer"
wire 	M_INPUT_WE;		//enable write for AXIv2 Master FIFO buffer "SendBuffer"

wire	bWReady;
wire	SFULL;
wire	W_BUSY;
//PACK
wire	[`PAYLOAD_WIDTH-1:0] payload_out;
wire	[`FLIT_TYPE_WIDTH-1:0] flit_type_out;
wire	pack_enable;
wire	p_LinkC_Status_out;
wire 	[(`XY_WIDTH<<1)-1:0]dest;
wire	[(`XY_WIDTH<<1)-1:0] src;

output	[`FLIT_WIDTH-1:0] p_data_out; 
output	p_data_valid;
input	p_LinkC_Status_in;

wire	[4:0] SN_pack;
//DEPACK	
wire	depack_enable;
wire	[`PAYLOAD_WIDTH-1:0] payload_in;
wire	[`FLIT_TYPE_WIDTH-1:0] flit_type_in;
wire	payload_in_valid;
wire	[(`XY_WIDTH<<1)-1:0]R2C_src;

input	[`FLIT_WIDTH-1:0] dp_data_in; 
output	dp_data_read;
input	dp_data_in_valid;

wire	[4:0] SN_depack;

output	[3:0] CINC_STATUS;

AXIv2_Master_FIFO #(`AXI_ID_WIDTH) AXI_Master (
  //Global Signals
  .ACLK(clk), //Clock source
  .ARESETn(rst), //Reset source
  .RSTSFIFO(),	//reset Send FIFO
  .RSTRFIFO(), //reset Receive FIFO
  //AXI Master Related
  
  //Write address channel signals
  .AWID(M_AWID), //Master-Write address ID
  .AWADDR(M_AWADDR),//Master-Write address. address of the first transfer in a write burst
  .AWLEN(M_AWLEN),//Master-Burst length. exact number of transfers in a burst
  .AWSIZE(M_AWSIZE), //Master-Burst size. This signal indicates the size of each transfer in the burst.
  .AWBURST(M_AWBURST), //Master-Burst type.
  .AWLOCK(M_AWLOCK), //Master - NEW. Lock type
  .AWCACHE(M_AWCACHE),//Master-NEW. Cache type
  .AWPROT(M_AWPROT),//Master - NEW. Protection type
  .AWVALID(M_AWVALID), //Master - Write address valid. valid write address and control information are available:
  .AWREADY(M_AWREADY),//Slave - Write address ready. Slave ready to accept address 
 
 //Write data channel signals
  .WID(M_WID),//Master-Write ID tag
  .WDATA(M_WDATA),//Master-Write data
  .WSTRB(M_WSTRB),//Master-Write strobes
  .WLAST(M_WLAST),//Master-Write last
  .WVALID(M_WVALID),//Master-Write valid
  .WREADY(M_WREADY),//Slave-Write ready. signal indicates that the slave can accept the write data
  
  //Write response channel signals
  .BID(M_BID), //Slave-Response ID
  .BRESP(M_BRESP),//Slave-Write response
  .BVALID(M_BVALID),//Slave-Write response valid.
  .BREADY(M_BREADY),//Master-Response ready.
  
  //Read Address chann signals
  .ARID(M_ARID), //Master-Read address ID
  .ARADDR(M_ARADDR),//Master-Read address
  .ARLEN(M_ARLEN),//Master-Burst length
  .ARSIZE(M_ARSIZE),//Master-Burst size
  .ARBURST(M_ARBURST),//Master-Burst type
  .ARLOCK(M_ARLOCK), //Master - NEW. Lock type
  .ARCACHE(M_ARCACHE),//Master-NEW. Cache type
  .ARPROT(M_ARPROT),//Master - NEW. Protection type
  .ARVALID(M_ARVALID),//Master-Lock type
  .ARREADY(M_ARREADY),//Master-Read address valid.
  
  .RID(M_RID), //Slave-Read ID tag.
  .RDATA(M_RDATA),//Slave-Read data.
  .RRESP(M_RRESP),//Slave-Read response
  .RLAST(M_RLAST),//Slave-Read last
  .RVALID(M_RVALID),//Slave-Read valid
  .RREADY(M_RREADY),//Master-Read ready 
  
  //connect with dummyCore 
  
  //AXI config
  .INPUT_AWID(MASTER_AWID),
  .INPUT_ARID(MASTER_ARID),
  
  .INPUT_AWLEN(MASTER_AWLEN),
  .INPUT_AWSIZE(MASTER_AWSIZE),
  .INPUT_AWBURST(MASTER_AWBURST),
  .INPUT_ARLEN(MASTER_ARLEN),
  .INPUT_ARSIZE(MASTER_ARSIZE),
  .INPUT_ARBURST(MASTER_ARBURST),
  
  .RW_ENABLE(MASTER_RW_ENABLE), 		// 2bit indicating iniiate read or write 10 - read 11 - write
  
  .INPUT_RADDR(MASTER_RADDR), 		// Address for read
  .OUTPUT_RDATA(MASTER_RDATA), 	// Data which is read
  .OUTPUT_RVALID(MASTER_RVALID),	//indicate output read data is available
  
  .INPUT_WADDR(MASTER_WADDR), 		//Address for write
  .INPUT_WDATA(MASTER_WDATA),  	//Data to be written
 
  .INPUT_RE(M_INPUT_RE),			//enable read from FIFO buffer "ReceiveBuffer"
  .INPUT_WE(M_INPUT_WE),			//enable write for FIFO buffer "SendBuffer"
  //FULL(),				//indicate whether the FIFO buffer is full or not
  .WBUFFER_EMPTY(),				//indicate whether the SendBuffer is empty or not
  
  .bWReady(bWReady),
  .SFULL(SFULL),
  .W_BUSY(W_BUSY)
);



SNIC SNI_controller(
	.clk(clk),
	.rst(rst),

	//AXI Master
	.MASTER_AWID(MASTER_AWID),
	.MASTER_ARID(MASTER_ARID),
	.MASTER_AWLEN(MASTER_AWLEN),
	.MASTER_AWSIZE(MASTER_AWSIZE),
	.MASTER_AWBURST(MASTER_AWBURST),
	.MASTER_ARLEN(MASTER_ARLEN),
	.MASTER_ARSIZE(MASTER_ARSIZE),
	.MASTER_ARBURST(MASTER_ARBURST),
	
	.MASTER_RW_ENABLE(MASTER_RW_ENABLE), 		// 2bit indicating iniiate read or write 10 - read 11 - write

	.MASTER_RADDR(MASTER_RADDR), 		// Address for read
	.MASTER_RDATA(MASTER_RDATA), 	// Data which is read
	.MASTER_RVALID(MASTER_RVALID),	//indicate output read data is available

	.MASTER_WADDR(MASTER_WADDR), 		//Address for write
	.MASTER_WDATA(MASTER_WDATA),  	//Data to be written

	.M_INPUT_RE(M_INPUT_RE),			//enable read from FIFO buffer "ReceiveBuffer"
	.M_INPUT_WE(M_INPUT_WE),		//enable write for FIFO buffer "SendBuffer"	
	.bWReady(bWReady),
	.SFULL(SFULL),
	.W_BUSY(W_BUSY),
	//PACK
	.payload_out(payload_out),
	.flit_type_out(flit_type_out),
	.pack_enable(pack_enable),
	.LinkC_Status_in(p_LinkC_Status_out),
	.dest(dest),
	.src(src),
	.SN_out(SN_pack),
	//DEPACK
	.depack_enable(depack_enable),
	.payload_in(payload_in),
	.flit_type_in(flit_type_in),
	.payload_in_valid(payload_in_valid),
	.R2C_src(R2C_src),
	.SN_in(SN_depack),
	.CINC_STATUS(CINC_STATUS),
	
	.myx(myx),
	.myy(myy)	
);

PACK pack(

	.clk(clk),
	.rst(rst),
	
	//CNIC
	.payload(payload_out),
	.flit_type(flit_type_out),
	.pack_enable(pack_enable),
	.LinkC_Status_out(p_LinkC_Status_out),
	.dest(dest),
	.src(src),
	.SN_in(SN_pack),
	//LinkC
	.data_out(p_data_out),
	.data_valid(p_data_valid),
	.LinkC_Status_in(p_LinkC_Status_in)	

);

DEPACK depack(

	.clk(clk),
	.rst(rst),
	
	//CNIC
	.depack_enable(depack_enable),
	.flit_type(flit_type_in),
	.payload(payload_in),
	.payload_valid(payload_in_valid),
	.R2C_src(R2C_src),
	.SN_out(SN_depack),
	//LinkC
	.data_read(dp_data_read),
	.data_in(dp_data_in),
	.data_in_valid(dp_data_in_valid)
	
);
endmodule







