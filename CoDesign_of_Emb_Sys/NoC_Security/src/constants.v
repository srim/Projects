`ifdef CONSTANTS_V
`else
`define CONSTANTS_V

//configuration
`define AXIS_DATA_WIDTH 32
`define AXIS_ADDR_WIDTH 32
`define AXIM_DATA_WIDTH 32
`define AXIM_ADDR_WIDTH 32

`define READ_PROTECT_ADDR_START 28'h4000000
`define READ_PROTECT_ADDR_END 28'h6000000
`define WRITE_PROTECT_ADDR_START 28'hA000000
`define WRITE_PROTECT_ADDR_END 28'hE000000

`define NUM_ROUTER 16
`define XY_WIDTH 2
`define BYTE_LEN 8
`define MASK 88'hAAAAAAAAAAAAAAAAAAAAAA
//`define PAYLOAD_WIDTH 48+`AXIS_DATA_WIDTH	//Wreq+WData	//need to modify
//`define PAYLOAD_WIDTH 80//48
`define PAYLOAD_WIDTH 48+`AXIS_DATA_WIDTH	//burst 1 write
`define FLIT_WIDTH (`XY_WIDTH<<2)+3+5+`PAYLOAD_WIDTH	//64(src,dest,filt type,SN,payload)
`define FLIT_TYPE_WIDTH 3
`define ES_WIDTH 5	//reorder buf depth
`define	LC_SBUF_DEPTH 4
`define	LC_RBUF_DEPTH 4
`define	LC_NI_BUF_DEPTH 2

`define AXI_ID_WIDTH 4

`define REJECT_WT_TIME 150

// Read Enable
`define	READ_ENABLE 2'b10
//Write Enable 
`define WRITE_ENABLE 2'b11
//Read and Write Enable
`define READ_WRITE_ENABLE 2'b01
//Read and Write Disable
`define READ_WRITE_DISABLE 2'b00

//flit type
`define REQUEST 3'b001
`define	FEEDBACK 3'b010
`define	WDATA_BODY 3'b011
`define DATA_BODY 3'b100
`define RDATA_BODY 3'b101

//Feedback flit payload
`define READY 2'b00
`define N_READY 2'b01
`define ERROR 2'b10
`define DONE 2'b11

//CINC_STATUS
`define R2C_Rreq 0
`define R2C_Wreq 1
`define C2R_Rreq 2
`define C2R_Wreq 3



`endif
