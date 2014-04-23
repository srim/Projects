/*
	-module included
		-AXI Slave
		-MNI Controller(MCNIC)
		-PACK
		-DEPACK
*/


`include "constants.v"

module CNI_MNI(
	clk,
	rst,
	
	//AXI Slave
	S_AWID, //Master-Write address ID
	S_AWADDR,//Master-Write address. address of the first transfer in a write burst
	S_AWLEN,//Master-Burst length. exact number of transfers in a burst
	S_AWSIZE, //Master-Burst size. This signal indicates the size of each transfer in the burst.
	S_AWBURST, //Master-Burst type.
	S_AWLOCK, //Master - NEW. Lock type
	S_AWCACHE,//Master-NEW. Cache type
	S_AWPROT,//Master - NEW. Protection type
	S_AWVALID, //Master - Write address valid. valid write address and control information are available:
	S_AWREADY,//Slave - Write address ready. Slave ready to accept address 

	//Write data channel signals
	S_WID,//Master-Write ID tag
	S_WDATA,//Master-Write data
	S_WSTRB,//Master-Write strobes
	S_WLAST,//Master-Write last
	S_WVALID,//Master-Write valid
	S_WREADY,//Slave-Write ready. signal indicates that the slave can accept the write data

	//Write response channel signals
	S_BID, //Slave-Response ID
	S_BRESP,//Slave-Write response
	S_BVALID,//Slave-Write response valid.
	S_BREADY,//Master-Response ready.

	//Read Address chann signals
	S_ARID, //Master-Read address ID
	S_ARADDR,//Master-Read address
	S_ARLEN,//Master-Burst length
	S_ARSIZE,//Master-Burst size
	S_ARBURST,//Master-Burst type
	S_ARLOCK, //Master - NEW. Lock type
	S_ARCACHE,//Master-NEW. Cache type
	S_ARPROT,//Master - NEW. Protection type
	S_ARVALID,//Master-Lock type
	S_ARREADY,//Master-Read address valid.

	S_RID, //Slave-Read ID tag.
	S_RDATA,//Slave-Read data.
	S_RRESP,//Slave-Read response
	S_RLAST,//Slave-Read last
	S_RVALID,//Slave-Read valid
	S_RREADY,//Master-Read ready
	
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
	dp_data_in_valid,
    anomaly_detected
    );

input 	[`XY_WIDTH-1:0]myx;
input 	[`XY_WIDTH-1:0]myy;

input clk;
input rst;

//AXI Slave
input 	[3:0] S_AWID;
input 	[`AXIS_ADDR_WIDTH - 1:0] S_AWADDR;
input 	[3:0] S_AWLEN;
input 	[2:0] S_AWSIZE;
input 	[1:0] S_AWBURST;
input 	[1:0] S_AWLOCK;
input 	[3:0] S_AWCACHE;
input 	[2:0] S_AWPROT;
input 	S_AWVALID;  
output 	S_AWREADY;
input 	[3:0] S_WID;
input 	[`AXIS_DATA_WIDTH - 1:0] S_WDATA;
input 	[3:0] S_WSTRB;
input  	S_WLAST;
input	S_WVALID;
output 	[3:0] S_BID;
output 	[1:0] S_BRESP;
output 	S_BVALID;
input  	S_BREADY;
output 	S_WREADY;
input 	[3:0] S_ARID;
input 	[`AXIS_ADDR_WIDTH - 1:0] S_ARADDR;
input 	[3:0] S_ARLEN;
input 	[2:0] S_ARSIZE;
input 	[1:0] S_ARBURST;
input 	[1:0] S_ARLOCK;
input	[3:0] S_ARCACHE;
input	[2:0] S_ARPROT;
input	S_ARVALID;  
output 	S_ARREADY;
output 	[3:0] S_RID;
output 	[`AXIS_DATA_WIDTH - 1:0] S_RDATA;
output 	S_RLAST;
output 	S_RVALID;
output 	[1:0] S_RRESP;
input 	S_RREADY;

output [1:0] anomaly_detected;

wire	[`AXI_ID_WIDTH -1 :0] SLAVE_AWID;
wire	[`AXI_ID_WIDTH -1 :0] SLAVE_ARID;

wire	[`AXIS_DATA_WIDTH-1:0] SLAVE_WDATA;
wire	[`AXIS_ADDR_WIDTH-1:0] SLAVE_WADDR;
wire	[`AXIS_ADDR_WIDTH-1:0] SLAVE_RADDR;
wire 	[`AXIS_DATA_WIDTH-1:0] SLAVE_RDATA;
wire	[3:0] SLAVE_AWLEN;
wire	[2:0] SLAVE_AWSIZE;	//already decoded //no need decode
wire	[1:0] SLAVE_AWBURST;
wire	[3:0] SLAVE_ARLEN;
wire	[2:0] SLAVE_ARSIZE;	//already decoded //no need decode
wire	[1:0] SLAVE_ARBURST;
wire	[1:0] SLAVE_RW_ENABLE;
wire 	S_INPUT_WE;		//enable write for FIFO buffer "SendBuffer"
wire 	S_INPUT_RE;
wire	SLAVE_WVALID;

wire	MCNIC_BUSY;
wire	IssueWrite;
wire	IssueRead;
wire	Got_IssueWrite;
wire	Got_IssueRead;
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


AXIv2_Slave_FIFO #(`AXI_ID_WIDTH) AXI_Slave(

	//Global Signals
	.ACLK(clk), //Clock source
	.ARESETn(rst), //Reset source

	//Write address channel signals
	.AWID(S_AWID), //Master-Write address ID
	.AWADDR(S_AWADDR),//Master-Write address. address of the first transfer in a write burst
	.AWLEN(S_AWLEN),//Master-Burst length. exact number of transfers in a burst
	.AWSIZE(S_AWSIZE), //Master-Burst size. This signal indicates the size of each transfer in the burst.
	.AWBURST(S_AWBURST), //Master-Burst type.
	.AWLOCK(S_AWLOCK), //Master - NEW. Lock type
	.AWCACHE(S_AWCACHE),//Master-NEW. Cache type
	.AWPROT(S_AWPROT),//Master - NEW. Protection type
	.AWVALID(S_AWVALID), //Master - Write address valid. valid write address and control information are available:
	.AWREADY(S_AWREADY),//Slave - Write address ready. Slave ready to accept address 

	//Write data channel signals
	.WID(S_WID),//Master-Write ID tag
	.WDATA(S_WDATA),//Master-Write data
	.WSTRB(S_WSTRB),//Master-Write strobes
	.WLAST(S_WLAST),//Master-Write last
	.WVALID(S_WVALID),//Master-Write valid
	.WREADY(S_WREADY),//Slave-Write ready. signal indicates that the slave can accept the write data

	//Write response channel signals
	.BID(S_BID), //Slave-Response ID
	.BRESP(S_BRESP),//Slave-Write response
	.BVALID(S_BVALID),//Slave-Write response valid.
	.BREADY(S_BREADY),//Master-Response ready.

	//Read Address chann signals
	.ARID(S_ARID), //Master-Read address ID
	.ARADDR(S_ARADDR),//Master-Read address
	.ARLEN(S_ARLEN),//Master-Burst length
	.ARSIZE(S_ARSIZE),//Master-Burst size
	.ARBURST(S_ARBURST),//Master-Burst type
	.ARLOCK(S_ARLOCK), //Master - NEW. Lock type
	.ARCACHE(S_ARCACHE),//Master-NEW. Cache type
	.ARPROT(S_ARPROT),//Master - NEW. Protection type
	.ARVALID(S_ARVALID),//Master-Lock type
	.ARREADY(S_ARREADY),//Master-Read address valid.

	.RID(S_RID), //Slave-Read ID tag.
	.RDATA(S_RDATA),//Slave-Read data.
	.RRESP(S_RRESP),//Slave-Read response
	.RLAST(S_RLAST),//Slave-Read last
	.RVALID(S_RVALID),//Slave-Read valid
	.RREADY(S_RREADY),//Master-Read ready
	
	
	//extract data to/from AXI Slave (connect with your component)
	.SLAVE_RADDRREG(SLAVE_RADDR),
	.SLAVE_RDATAREG(SLAVE_RDATA),
	.SLAVE_WDATAREG(SLAVE_WDATA),
	.SLAVE_WADDRREG(SLAVE_WADDR),
	.RW_ENABLE(SLAVE_RW_ENABLE),
	
	.SLAVE_AWLEN(SLAVE_AWLEN),
	.SLAVE_AWSIZE(SLAVE_AWSIZE),	//already decoded
	.SLAVE_AWBURST(SLAVE_AWBURST),
	.SLAVE_ARLEN(SLAVE_ARLEN),	
	.SLAVE_ARSIZE(SLAVE_ARSIZE),	//already decoded
	.SLAVE_ARBURST(SLAVE_ARBURST),	
	
	//FIFO related	
	.S_INPUT_WE(S_INPUT_WE),		//enable write for FIFO buffer "SendBuffer"(AXI Master is reading from AXI Slave)
	.S_INPUT_RE(S_INPUT_RE),		//enable read from FIFO buffer "ReceiveBuffer"(AXI Master is writing to AXI Slave)
	.SLAVE_WVALID(SLAVE_WVALID),
	
	.STOP_WREQ(MCNIC_BUSY),
	
	.IssueWrite(IssueWrite),
	.IssueRead(IssueRead),

	.Got_IssueWrite(Got_IssueWrite),
	.Got_IssueRead(Got_IssueRead),

	.SLAVE_AWID(SLAVE_AWID),
	.SLAVE_ARID(SLAVE_ARID)
);

MNIC MNI_controller(
	.clk(clk),
	.rst(rst),
	
	//AXI Slave
	.SLAVE_AWID(SLAVE_AWID),
	.SLAVE_ARID(SLAVE_ARID),
	
	.SLAVE_RADDR(SLAVE_RADDR),
	.SLAVE_RDATA(SLAVE_RDATA),
	.SLAVE_WDATA(SLAVE_WDATA),
	.SLAVE_WADDR(SLAVE_WADDR),
	.SLAVE_RW_ENABLE(SLAVE_RW_ENABLE),
	
	.SLAVE_AWLEN(SLAVE_AWLEN),
	.SLAVE_AWSIZE(SLAVE_AWSIZE),	//already decoded
	.SLAVE_AWBURST(SLAVE_AWBURST),
	.SLAVE_ARLEN(SLAVE_ARLEN),	
	.SLAVE_ARSIZE(SLAVE_ARSIZE),	//already decoded
	.SLAVE_ARBURST(SLAVE_ARBURST),

	.S_INPUT_WE(S_INPUT_WE),		//enable write for FIFO buffer "SendBuffer"(AXI Master is reading from AXI Slave)
	.S_INPUT_RE(S_INPUT_RE),		//enable read from FIFO buffer "ReceiveBuffer"(AXI Master is writing to AXI Slave)
	.SLAVE_WVALID(SLAVE_WVALID),
	
	.BUSY(MCNIC_BUSY),
	//PACK
	.payload_out(payload_out),
	.flit_type_out(flit_type_out),
	.pack_enable(pack_enable),
	.LinkC_Status_in(p_LinkC_Status_out),
	.dest(dest),
	.src(src),
	
	//DEPACK
	.depack_enable(depack_enable),
	.payload_in(payload_in),
	.flit_type_in(flit_type_in),
	.payload_in_valid(payload_in_valid),
	.R2C_src(R2C_src),
	.SN_in(SN_depack),
	.CINC_STATUS(CINC_STATUS),
	
	.myx(myx),
	.myy(myy),

	.IssueWrite(IssueWrite),
	.IssueRead(IssueRead),

	.Got_IssueWrite(Got_IssueWrite),
	.Got_IssueRead(Got_IssueRead),
    .anomaly_detected(anomaly_detected)
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
