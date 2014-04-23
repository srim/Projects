/*
	-entire CNI module
	-Top module
	-modular design
		-AXI Slave
		-AXI Master
		-CNI Controller(CNIC)
		-PACK
		-DEPACK
		-Link Controller(LinkC)
*/
`include "constants.v"

/*
	-change the module name
    
    
*/

`timescale 1ns/1ps

module CNI_router_xy2_AXID32_stable(	
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
	
	//
    ENC_DATA,
    DEC_DATA,
    COUNTER_INTRUSION_DETECTED,
    PERM,
 counter_0,
 counter_1,
 counter_2,
 counter_3,
 counter_4,
 counter_5,
 counter_6,
 counter_7,
 counter_8,
 counter_9,
 counter_10,
 counter_11,
 counter_12,
 counter_13,
 counter_14,
 counter_15,
 sc_out_0,
 sc_out_1,
 sc_out_2,
 sc_out_3,
 sc_out_4,
sc_out_5,
 sc_out_6,
 sc_out_7,
 sc_out_8,
sc_out_9,
 sc_out_10,
 sc_out_11,
sc_out_12,
 sc_out_13,
sc_out_14,
 sc_out_15,
	
	//myx myy
	myx,
	myy,
	
	//router
	in_valid0,
	in_valid1,
	in_valid2,
	in_valid3,
	// myx,
	// myy,
	in0,
	in1,
	in2,
	in3,
	out_0,
	out_1,
	out_2,
	out_3,
	out_valid0,
	out_valid1,
	out_valid2,
	out_valid3,
	BP_0,
	BP_1,
	BP_2,
	BP_3,
	BPo_0,
	BPo_1,
	BPo_2,
	BPo_3	
 	
);

input 	[`XY_WIDTH-1:0]myx;
input 	[`XY_WIDTH-1:0]myy;

input clk;
input rst;

//AXI Master

output 	[3:0] M_AWID;
output 	[`AXIM_ADDR_WIDTH -1 :0] M_AWADDR;
output 	[3:0] M_AWLEN;
output 	[2:0] M_AWSIZE;
output 	[1:0] M_AWBURST;
output 	[1:0] M_AWLOCK;
output 	[3:0] M_AWCACHE;
output 	[2:0] M_AWPROT;

output 	M_AWVALID;  
input 	M_AWREADY;
output 	[3:0] M_WID;
output 	reg [`AXIM_DATA_WIDTH -1 :0] M_WDATA;
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
output reg S_AWREADY;
input 	[3:0] S_WID;
inout 	[`AXIS_DATA_WIDTH - 1:0] S_WDATA;
output 	[`AXIS_DATA_WIDTH - 1:0] ENC_DATA;
output 	[`AXIS_DATA_WIDTH - 1:0] DEC_DATA;
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

/* other declarations inlcuded */
output reg COUNTER_INTRUSION_DETECTED;
reg [2:0]BURST_SIZE ;
reg [13:0]DATA_LEN_BITS ;
reg [13:0] DATA_MASK;
reg [13:0] MASK;
reg [13:0]ENC_DATA ;
output [1:0]PERM;

//LinkC

//LinkC of MNI
wire	[`FLIT_WIDTH-1:0] M_p_data_out; 
wire	M_p_data_valid;
wire	M_p_LinkC_Status_in;

wire	[`FLIT_WIDTH-1:0] M_dp_data_in; 
wire	M_dp_data_read;
wire	M_dp_data_in_valid;

//LinkC of SNI
wire	[`FLIT_WIDTH-1:0] S_p_data_out; 
wire	S_p_data_valid;
wire	S_p_LinkC_Status_in;

wire	[`FLIT_WIDTH-1:0] S_dp_data_in; 
wire	S_dp_data_read;
wire	S_dp_data_in_valid;


wire	[`FLIT_WIDTH-1:0] data_in;
wire	data_in_valid;

wire	[`FLIT_WIDTH-1:0] data_out;
wire	data_out_valid;

wire 	BP;
wire	BPo;

//router
input[`FLIT_WIDTH-1:0] in0;//(src(2*numbits)+dest(2*numbits)+data(data_size))
input[`FLIT_WIDTH-1:0] in1;
input[`FLIT_WIDTH-1:0] in2;
input[`FLIT_WIDTH-1:0] in3;

input in_valid0;
input in_valid1;
input in_valid2;
input in_valid3;

output	[`FLIT_WIDTH-1:0] out_0;
output	[`FLIT_WIDTH-1:0] out_1;
output	[`FLIT_WIDTH-1:0] out_2;
output	[`FLIT_WIDTH-1:0] out_3;

output out_valid0;
output out_valid1;
output out_valid2;
output out_valid3;

input  BP_0;
input  BP_1;
input  BP_2;
input  BP_3;

output BPo_0;
output BPo_1;
output BPo_2;
output BPo_3;

output reg counter_0;
output reg counter_1;
output reg counter_2;
output reg counter_3;
output reg counter_4;
output reg counter_5;
output reg counter_6;
output reg counter_7;
output reg counter_8;
output reg counter_9;
output reg counter_10;
output reg counter_11;
output reg counter_12;
output reg counter_13;
output reg counter_14;
output reg counter_15;
output sc_out_0;
output sc_out_1;
output sc_out_2;
output sc_out_3;
output sc_out_4;
output sc_out_5;
output sc_out_6;
output sc_out_7;
output sc_out_8;
output sc_out_9;
output sc_out_10;
output sc_out_11;
output sc_out_12;
output sc_out_13;
output sc_out_14;
output sc_out_15;



/* if this is the first router (i.e the one associated with the traffic generator.
            call encrypt
            
   if (myx
    else 
            continue normal code execution */
            
 always @ (S_AWLEN,S_AWSIZE)
 begin

if ((S_AWLEN >3'b000) ||(S_AWSIZE >3'b110) || (S_AWLEN >3'b000 && S_AWSIZE >3'b100))
    COUNTER_INTRUSION_DETECTED=1;
end

//LOOK UP TABLE TO GENERATE CORRESPONDING INTRUSION SIGNAL
always @ (posedge COUNTER_INTRUSION_DETECTED)
begin
    if (myx ==0 && myy == 0)
            counter_0 = 1;
    if (myx ==0 && myy == 1)
            counter_1 = 1;
    if (myx ==0 && myy == 2)
            counter_2 = 1;
    if (myx ==0 && myy == 3)
            counter_3 = 1;
    if (myx ==1 && myy == 0)
            counter_4 = 1;
    if (myx ==1 && myy == 1)
            counter_5 = 1;
    if (myx ==1 && myy == 2)
            counter_6 = 1;
    if (myx ==1 && myy == 3)
            counter_7 = 1;
    if (myx ==2 && myy == 0)
            counter_8 = 1;
    if (myx ==2 && myy == 1)
            counter_9 = 1;
    if (myx ==2 && myy == 2)
            counter_10 = 1;
    if (myx ==2 && myy == 3)
            counter_11 = 1;
    if (myx ==3 && myy == 0)
            counter_12 = 1;
    if (myx ==3 && myy == 1)
            counter_13 = 1;
    if (myx ==3 && myy == 2)
            counter_14 = 1;
    if (myx ==3 && myy == 3)
            counter_15 = 1;
    S_AWREADY = 0;
end  
    
 //#50 ;COUNTER_INTRUSION_DETECTED=0;
  //  always @(counter_1 || counter_2 || counter_3 || counter_4 || counter_5 || counter_6 || counter_7 || counter_8 || counter_9 || counter_10 || counter_11 || counter_12 || counter_13 || counter_14 || counter_15 )
 //   begin
secure_core SECURE_CORE(
counter_0,
counter_1,
counter_2,
counter_3,
counter_4,
counter_5,
counter_6,
counter_7,
counter_8,
counter_9,
counter_10,
counter_11,
counter_12,
counter_13,
counter_14,
counter_15,
sc_out_0,
sc_out_1,
sc_out_2,
sc_out_3,
sc_out_4,
sc_out_5,
sc_out_6,
sc_out_7,
sc_out_8,
sc_out_9,
sc_out_10,
sc_out_11,
sc_out_12,
sc_out_13,
sc_out_14,
sc_out_15);
   // end
    
 
 apu APU(S_AWADDR,PERM);
    
  if(flit_type_in==`REQUEST && payload_in[`AXIS_ADDR_WIDTH+7]==1'b1 && WT_W_DATA==1'b0) //w req
			begin 
                if (PERM[1] ==1'b1)
                     M_AWREADY = 0;
             end 
          
   if(flit_type_in==`REQUEST && payload_in[`AXIS_ADDR_WIDTH+7]==1'b0) //r req
			begin 
                if (PERM[0] ==1'b1)
                     M_AWREADY = 0;
             end 
 
 
    
CNI_MNI MNI(
	.clk(clk),
	.rst(rst),
	
	//AXI Slave
	.S_AWID(S_AWID), //Master-Write address ID
	.S_AWADDR(S_AWADDR),//Master-Write address. address of the first transfer in a write burst
	.S_AWLEN(S_AWLEN),//Master-Burst length. exact number of transfers in a burst
	.S_AWSIZE(S_AWSIZE), //Master-Burst size. This signal indicates the size of each transfer in the burst.
	.S_AWBURST(S_AWBURST), //Master-Burst type.
	.S_AWLOCK(S_AWLOCK), //Master - NEW. Lock type
	.S_AWCACHE(S_AWCACHE),//Master-NEW. Cache type
	.S_AWPROT(S_AWPROT),//Master - NEW. Protection type
	.S_AWVALID(S_AWVALID), //Master - Write address valid. valid write address and control information are available:
	.S_AWREADY(S_AWREADY),//Slave - Write address ready. Slave ready to accept address 

	//Write data channel signals
	.S_WID(S_WID),//Master-Write ID tag
	.S_WDATA(S_WDATA),//Master-Write data
	.S_WSTRB(S_WSTRB),//Master-Write strobes
	.S_WLAST(S_WLAST),//Master-Write last
	.S_WVALID(S_WVALID),//Master-Write valid
	.S_WREADY(S_WREADY),//Slave-Write ready. signal indicates that the slave can accept the write data

	//Write response channel signals
	.S_BID(S_BID), //Slave-Response ID
	.S_BRESP(S_BRESP),//Slave-Write response
	.S_BVALID(S_BVALID),//Slave-Write response valid.
	.S_BREADY(S_BREADY),//Master-Response ready.

	//Read Address chann signals
	.S_ARID(S_ARID), //Master-Read address ID
	.S_ARADDR(S_ARADDR),//Master-Read address
	.S_ARLEN(S_ARLEN),//Master-Burst length
	.S_ARSIZE(S_ARSIZE),//Master-Burst size
	.S_ARBURST(S_ARBURST),//Master-Burst type
	.S_ARLOCK(S_ARLOCK), //Master - NEW. Lock type
	.S_ARCACHE(S_ARCACHE),//Master-NEW. Cache type
	.S_ARPROT(S_ARPROT),//Master - NEW. Protection type
	.S_ARVALID(S_ARVALID),//Master-Lock type
	.S_ARREADY(S_ARREADY),//Master-Read address valid.

	.S_RID(S_RID), //Slave-Read ID tag.
	.S_RDATA(S_RDATA),//Slave-Read data.
	.S_RRESP(S_RRESP),//Slave-Read response
	.S_RLAST(S_RLAST),//Slave-Read last
	.S_RVALID(S_RVALID),//Slave-Read valid
	.S_RREADY(S_RREADY),//Master-Read ready
	
	.CINC_STATUS(),
	
	//myx myy
	.myx(myx),
	.myy(myy),
	
	//LinkC
	.p_data_valid(M_p_data_valid),
	.p_data_out(M_p_data_out),
	.p_LinkC_Status_in(M_p_LinkC_Status_in),
	
	.dp_data_in(M_dp_data_in),
	.dp_data_read(M_dp_data_read),
	.dp_data_in_valid(M_dp_data_in_valid)
);



CNI_SNI SNI(
	.clk(clk),
	.rst(rst),
	
	//AXI Master
	//Write address channel signals
	.M_AWID(M_AWID), //Master-Write address ID
	.M_AWADDR(M_AWADDR),//Master-Write address. address of the first transfer in a write burst
	.M_AWLEN(M_AWLEN),//Master-Burst length. exact number of transfers in a burst
	.M_AWSIZE(M_AWSIZE), //Master-Burst size. This signal indicates the size of each transfer in the burst.
	.M_AWBURST(M_AWBURST), //Master-Burst type.
	.M_AWLOCK(M_AWLOCK), //Master - NEW. Lock type
	.M_AWCACHE(M_AWCACHE),//Master-NEW. Cache type
	.M_AWPROT(M_AWPROT),//Master - NEW. Protection type
	.M_AWVALID(M_AWVALID), //Master - Write address valid. valid write address and control information are available:
	.M_AWREADY(M_AWREADY),//Slave - Write address ready. Slave ready to accept address 

	//Write data channel signals
	.M_WID(M_WID),//Master-Write ID tag
	.M_WDATA(M_WDATA),//Master-Write data
	.M_WSTRB(M_WSTRB),//Master-Write strobes
	.M_WLAST(M_WLAST),//Master-Write last
	.M_WVALID(M_WVALID),//Master-Write valid
	.M_WREADY(M_WREADY),//Slave-Write ready. signal indicates that the slave can accept the write data

	//Write response channel signals
	.M_BID(M_BID), //Slave-Response ID
	.M_BRESP(M_BRESP),//Slave-Write response
	.M_BVALID(M_BVALID),//Slave-Write response valid.
	.M_BREADY(M_BREADY),//Master-Response ready.

	//Read Address chann signals
	.M_ARID(M_ARID), //Master-Read address ID
	.M_ARADDR(M_ARADDR),//Master-Read address
	.M_ARLEN(M_ARLEN),//Master-Burst length
	.M_ARSIZE(M_ARSIZE),//Master-Burst size
	.M_ARBURST(M_ARBURST),//Master-Burst type
	.M_ARLOCK(M_ARLOCK), //Master - NEW. Lock type
	.M_ARCACHE(M_ARCACHE),//Master-NEW. Cache type
	.M_ARPROT(M_ARPROT),//Master - NEW. Protection type
	.M_ARVALID(M_ARVALID),//Master-Lock type
	.M_ARREADY(M_ARREADY),//Master-Read address valid.

	.M_RID(M_RID), //Slave-Read ID tag.
	.M_RDATA(M_RDATA),//Slave-Read data.
	.M_RRESP(M_RRESP),//Slave-Read response
	.M_RLAST(M_RLAST),//Slave-Read last
	.M_RVALID(M_RVALID),//Slave-Read valid
	.M_RREADY(M_RREADY),//Master-Read ready
	
	.CINC_STATUS(),
	
	//myx myy
	.myx(myx),
	.myy(myy),

	//LinkC
	.p_data_valid(S_p_data_valid),
	.p_data_out(S_p_data_out),
	.p_LinkC_Status_in(S_p_LinkC_Status_in),
	
	.dp_data_in(S_dp_data_in),
	.dp_data_read(S_dp_data_read),
	.dp_data_in_valid(S_dp_data_in_valid)	
		
);

decrypt  DECRYPT (S_AWSIZE, S_AWLEN, S_WDATA, DEC_DATA);

assign S_WDATA<=DEC_DATA;



LinkC LC(

	.clk(clk),
	.rst(rst),
	
	//router
	.data_in(data_in),
	.data_in_valid(data_in_valid),
	
	.data_out(data_out),
	.data_out_valid(data_out_valid),
	
	.BP(BP),		//output
			//BP=1: router can send data to LinkC 
			//BP=0: router can't send data to LinkC
	
	.BPo(BPo), 	//input
			//BPo = 1: router is available
			//BPo = 0: router is not available
	
	//MNI
	//pack
	.M_WE_SBuf(M_p_data_valid),
	.M_SData(M_p_data_out),
	.M_SBuf_FULL(M_p_LinkC_Status_in),
	
	//depack
	.M_RData(M_dp_data_in),
	.M_RE_RBuf(M_dp_data_read),
	.M_RData_valid(M_dp_data_in_valid),
	
	//SNI
	//pack
	.S_WE_SBuf(S_p_data_valid),
	.S_SData(S_p_data_out),
	.S_SBuf_FULL(S_p_LinkC_Status_in),
	
	//depack
	.S_RData(S_dp_data_in),
	.S_RE_RBuf(S_dp_data_read),
	.S_RData_valid(S_dp_data_in_valid)		
	
);

codesign_router #(`NUM_ROUTER,`XY_WIDTH,`FLIT_WIDTH-(`XY_WIDTH<<2)) router(

	.clk(clk),
	.reset(rst), 
	.in_valid0(in_valid0),
	.in_valid1(in_valid1),
	.in_valid2(in_valid2),
	.in_valid3(in_valid3),
	.in_valid4(data_out_valid),
	.myx(myx),
	.myy(myy),
	.in0(in0),
	.in1(in1),
	.in2(in2),
	.in3(in3),
	.in4(data_out),
	.out_0(out_0),
	.out_1(out_1),
	.out_2(out_2),
	.out_3(out_3),
	.out_4(data_in),
	.out_valid0(out_valid0),
	.out_valid1(out_valid1),
	.out_valid2(out_valid2),
	.out_valid3(out_valid3),
	.out_valid4(data_in_valid),
	.BP_0(BP_0),
	.BP_1(BP_1),
	.BP_2(BP_2),
	.BP_3(BP_3),
	.BP_4(BP),
	.BPo_0(BPo_0),
	.BPo_1(BPo_1),
	.BPo_2(BPo_2),
	.BPo_3(BPo_3),
	.BPo_4(BPo)
);

   



endmodule
