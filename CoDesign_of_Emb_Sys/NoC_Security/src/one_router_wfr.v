/*
	-ver1.0 adjust the format, it doesn't support continuous data sending. 
		-modified dest location in in* (numbits*4+data_size-5 : numbits*4+data_size-6)
	
	-ver2.0 
		-Todo: make it to support sending data continuously.
			if ( buffer4[0]== 1'b0 && in_valid4==1'b1) => if (in_valid4==1'b1)
	
	-ver3.1
		-make it to support sending data continuously for the orther 3 ports
			if ( buffer*[0]== 1'b0 && in_valid*==1'b1) => if (in_valid*==1'b1)
	
	-ver 3.3 76'h8000000000000000001 -> 100'h8000000000000000000000001
			vc1[3]= buffer1_1[numbits*4+data_size+3 : 1]; -> vc1[3]= buffer1_1;
			
			added buffer4[0]=1'b0;
			if (buffer4_1[0]==1'b1 && buffer4_1!= 100'h8000000000000000000000001) ->if (buffer4_1[0]==1'b1)
			76'h0000000000000000001 -> 100'h0000000000000000000000001
			
	-ver 3.4
		
*/
module codesign_router(
	clk,
	reset, 
	in_valid0,
	in_valid1,
	in_valid2,
	in_valid3,
	in_valid4,
	myx,
	myy,
	in0,
	in1,
	in2,
	in3,
	in4,
	out_0,
	out_1,
	out_2,
	out_3,
	out_4,
	out_valid0,
	out_valid1,
	out_valid2,
	out_valid3,
	out_valid4,
	BP_0,
	BP_1,
	BP_2,
	BP_3,
	BP_4,
	BPo_0,
	BPo_1,
	BPo_2,
	BPo_3,
	BPo_4
);



parameter num_routers = 16;
parameter numbits=2;//clogb(num_routers)/2;
parameter data_size=88;

input clk,reset;

input[numbits*4+data_size-1 : 0] in0;//(src(2*numbits)+dest(2*numbits)+data(data_size))
input[numbits*4+data_size-1 : 0] in1;
input[numbits*4+data_size-1 : 0] in2;
input[numbits*4+data_size-1 : 0] in3;
input[numbits*4+data_size-1 : 0] in4;

input[numbits-1:0] myx;
input[numbits-1:0] myy;

input in_valid0;
input in_valid1;
input in_valid2;
input in_valid3;
input in_valid4;

output	[numbits*4+data_size-1 : 0] out_0;
reg		[numbits*4+data_size-1 : 0] out_0;
output	[numbits*4+data_size-1 : 0] out_1;
reg		[numbits*4+data_size-1 : 0] out_1;
output	[numbits*4+data_size-1 : 0] out_2;
reg		[numbits*4+data_size-1 : 0] out_2;
output	[numbits*4+data_size-1 : 0] out_3;
reg		[numbits*4+data_size-1 : 0] out_3;
output	[numbits*4+data_size-1 : 0] out_4;
reg		[numbits*4+data_size-1 : 0] out_4;

reg [7:0] test [0:7];

reg out_valid0;
reg out_valid1;
reg out_valid2;
reg out_valid3;
reg out_valid4;

output out_valid0;
output out_valid1;
output out_valid2;
output out_valid3;
output out_valid4;

// Incoming Back pressure signals
input  BP_0;
input  BP_1;
input  BP_2;
input  BP_3;
input  BP_4;
//reg [7:0] BF [0:16383];

//outgoing back pressure signals
output BPo_0;
output BPo_1;
output BPo_2;
output BPo_3;
output BPo_4;
// reg BPo_0;
// reg BPo_1;
// reg BPo_2;
// reg BPo_3;
//reg BPo_4;

reg	[numbits*4+data_size : 0] 	buffer0;//(4(src)+4(dest)+4(data)+1(busy or free) 0th bit indicates if buffer is free [12:0]
reg	[numbits*4+data_size+3 : 0] buffer0_1; //(4(src)+4(dest)+4(data)+3(RC)+1busy bit)
reg	[numbits*4+data_size : 0] 	buffer1;//4(src)+4(dest)+4(data)
reg	[numbits*4+data_size+3 : 0] buffer1_1; //(4(src)+4(dest)+4(data)+3(RC))
reg	[numbits*4+data_size : 0] 	buffer2;//(4(src)+4(dest)+4(data)
reg	[numbits*4+data_size+3 : 0] buffer2_1; //(4(src)+4(dest)+4(data)+3(RC))
reg	[numbits*4+data_size : 0] 	buffer3;//(4(src)+4(dest)+4(data)
reg	[numbits*4+data_size+3 : 0] buffer3_1; //(4(src)+4(dest)+4(data)+3(RC))
reg	[numbits*4+data_size : 0] 	buffer4;//(4(src)+4(dest)+4(data)
reg	[numbits*4+data_size+3 : 0] buffer4_1; //(4(src)+4(dest)+4(data)+3(RC))
reg	[numbits*4+data_size+3 : 0] buffer_out_0;
reg	[numbits*4+data_size+3 : 0] buffer_out_1;
reg	[numbits*4+data_size+3 : 0] buffer_out_2;
reg	[numbits*4+data_size+3 : 0] buffer_out_3;
reg	[numbits*4+data_size+3 : 0] buffer_out_4;
//vcs of node 0
reg	[numbits*4+data_size+3 : 0] vc0[0:5];//(4(src)+4(dest)+32(data)+3(RC)+1 busy or free bit)
reg	[numbits*4+data_size+3 : 0] vc1[0:5];
reg	[numbits*4+data_size+3 : 0] vc2[0:5];
reg	[numbits*4+data_size+3 : 0] vc3[0:5];
reg	[numbits*4+data_size+3 : 0] vc4[0:5];
//Round robin for node 0 initializations
reg ready,ready1,ready2,ready3,ready4;
reg ready_1,ready_11,ready_12,ready_13,ready_14;
reg ready_2,ready_21,ready_22,ready_23,ready_24;
reg ready_4,ready_41,ready_42,ready_43,ready_44;


wire BPo_0_wire;
wire BPo_1_wire;
wire BPo_2_wire;
wire BPo_3_wire;
wire BPo_4_wire;


//declarations because of modelstudio
reg p;
reg p1;
reg p2;
reg p3;
reg p4;
reg m;
reg m1;
reg m2;
reg m3;
reg m4;
reg q;
reg q1;
reg q2;
reg q3;
reg q4;

reg [2:0]buf1;
reg [2:0]buf2;
reg [2:0]buf3;
reg [2:0]buf4;
reg [2:0]buf5;
reg[2:0] rr_port_0;
reg[2:0] rr_vc_0;
reg sel0_0;
reg[2:0] counter_out_0;
reg[2:0] mux_in_0;
reg[2:0] mux_out_0;
//RR for node 1
reg[2:0] rr_port_1;
reg[2:0] rr_vc_1;
reg sel0_1;
reg[2:0] counter_out_1;
reg[2:0] mux_in_1;
reg[2:0] mux_out_1;
//RR for node 2
reg[2:0] rr_port_2;
reg[2:0] rr_vc_2;
reg sel0_2;
reg[2:0] counter_out_2;
reg[2:0] mux_in_2;
reg[2:0] mux_out_2;
//RR for node 3
reg[2:0] rr_port_3;
//reg BP_3;
reg[2:0] rr_vc_3;
reg sel0_3;
reg[2:0] counter_out_3;
reg[2:0] mux_in_3;
reg[2:0] mux_out_3;
//RR for node 4
reg[2:0] rr_port_4;
reg[2:0] rr_vc_4;
reg sel0_4;
reg[2:0] counter_out_4;
reg[2:0] mux_in_4;
reg[2:0] mux_out_4;

//output port 0 
reg sel1_0;
reg[2:0] counter1_out_0;
reg[2:0] mux1_in_0;
reg[2:0] mux1_out_0;

//output port 1
reg sel1_1;
reg[2:0] counter1_out_1;
reg[2:0] mux1_in_1;
reg[2:0] mux1_out_1;

//output port 2 
reg sel1_2;
reg[2:0] counter1_out_2;
reg[2:0] mux1_in_2;
reg[2:0] mux1_out_2;

//output port 0 
reg sel1_3;
reg[2:0] counter1_out_3;
reg[2:0] mux1_in_3;
reg[2:0] mux1_out_3;

//output port 4 
reg sel1_4;
reg[2:0] counter1_out_4;
reg[2:0] mux1_in_4;
reg[2:0] mux1_out_4;
//Route Computation last two bits indicate the route to be taken and first bit indicates whether busy or not
reg [2:0] rc_0;
reg [2:0] rc_1;
reg [2:0] rc_2;
reg [2:0] rc_3;
reg [2:0] rc_4;

wire [4:0] outport_status;
assign outport_status = {buffer_out_4[0],buffer_out_3[0],buffer_out_2[0],buffer_out_1[0],buffer_out_0[0]};
//Route Computation Task 
/* //xy routing
task rc_task;
input [numbits-1:0] my_x;
input [numbits-1:0] my_y;
input [numbits-1:0] dst_x;
input [numbits-1:0] dst_y;
output [2:0] port_out;
reg [2:0] port_out;

if(dst_x>my_x)
begin
	port_out=3'b001;
end
else if(dst_x<my_x)
	begin
		port_out=3'b011;
	end
else if(dst_y<my_y)
	begin
	port_out=3'b010;
	end
else  if(dst_y>my_y)
	begin
		port_out=3'b000;
	end
	else
		begin
			port_out=3'b100;
		end

endtask
*/

//West-First routing
task rc_task_wfr;
input [numbits-1:0] my_x;
input [numbits-1:0] my_y;
input [numbits-1:0] dst_x;
input [numbits-1:0] dst_y;
input [4:0] outport_status;
output [2:0] port_out;
reg [2:0] port_out;

if(dst_x<my_x)
begin
	port_out=3'b011;
end	
else if(dst_x>my_x && dst_y<my_y)
	begin
		if(outport_status[1] <outport_status[2])	
			port_out=3'b001;	//port 1 is free
		else
			port_out=3'b010;
	end
else if(dst_x>my_x  && dst_y>my_y)
	begin
		if(outport_status[1] <outport_status[0])
			port_out=3'b001;	//port 1 is free
		else
			port_out=3'b000;
	end
else if(dst_x>my_x && dst_y==my_y)
	begin	
		port_out=3'b001;
	end	
else if(dst_x==my_x && dst_y<my_y)
	begin
		port_out=3'b010;
	end	
else if(dst_x==my_x && dst_y>my_y)
	begin
		port_out=3'b000;
	end	
else if(dst_x==my_x && dst_y==my_y)
	begin
		port_out=3'b100;
	end
endtask

// initializations of busy bit which is the 0th bit of all vc's
initial 
begin
	vc0[0]= 76'h0;
	vc0[1]= 76'h0;
	vc0[2]= 76'h0;
	vc0[3]= 76'h0;
	vc0[4]= 76'h0;
	vc0[5]= 76'h0;
	vc1[0]= 76'h0;
	vc1[1]= 76'h0;
	vc1[2]= 76'h0;
	vc1[3]= 76'h0;
	vc1[4]= 76'h0;
	vc1[5]= 76'h0;
	vc2[0]= 76'h0;
	vc2[1]= 76'h0;
	vc2[2]= 76'h0;
	vc2[3]= 76'h0;
	vc2[4]= 76'h0;
	vc2[5]= 76'h0;
	vc3[0]= 76'h0;
	vc3[1]= 76'h0;
	vc3[2]= 76'h0;
	vc3[3]= 76'h0;
	vc3[4]= 76'h0;
	vc3[5]= 76'h0;
	vc4[0]= 76'h0;
	vc4[1]= 76'h0;
	vc4[2]= 76'h0;
	vc4[3]= 76'h0;
	vc4[4]= 76'h0;
	vc4[5]= 76'h0;

	buffer_out_0[0]=0;
	buffer_out_1[0]=0;
	buffer_out_2[0]=0;
	buffer_out_3[0]=0;
	buffer_out_4[0]=0;
	buffer0[0]=0;
	buffer1[0]=0;
	buffer2[0]=0;
	buffer3[0]=0;
	buffer4[0]=0;

	buffer0_1=0;
	buffer1_1=0;
	buffer2_1=0;
	buffer3_1=0;
	buffer4_1=0;
	sel0_0=1'b1;
	rr_port_0= 3'b0;
	rr_port_1= 3'b0;
	rr_port_2= 3'b0;
	rr_port_3= 3'b0;
	rr_port_4= 3'b0;
	//BP_1=1'b1;
	sel0_1=1'b1;
	//BP_2=1'b1;
	sel0_2=1'b1;
	//BP_3=1'b1;
	sel0_3=1'b1;
	//BP_4=1'b1;
	sel0_4=1'b1;
	counter_out_0 = 3'b0;
	mux_out_0 = 3'b0;
	mux_in_0 = 3'b0;
	counter_out_1 = 3'b0;
	mux_out_1 = 3'b0;
	mux_in_1 = 3'b0;
	counter_out_2 = 3'b0;
	mux_out_2 = 3'b0;
	mux_in_2 = 3'b0;
	counter1_out_0 = 3'b0;
	mux1_out_0 = 3'b0;
	mux1_in_0 = 3'b0;
	counter1_out_1 = 3'b0;
	mux1_out_1 = 3'b0;
	mux1_in_1 = 3'b0;
	counter1_out_2 = 3'b0;
	mux1_out_2 = 3'b0;
	mux1_in_2 = 3'b0;
	counter1_out_3 = 3'b0;
	mux1_out_3 = 3'b0;
	mux1_in_3 = 3'b0;
	counter1_out_4 = 3'b0;
	mux1_out_4 = 3'b0;
	mux1_in_4 = 3'b0;
	sel1_0 = 1;
	sel1_1 = 1;
	sel1_2 = 1;
	sel1_3 = 1;
	sel1_4 = 1;
	ready = 1'b0;
	ready1 = 1'b0;
	ready2= 1'b0;
	ready3 = 1'b0;
	ready4 = 1'b0;

	buf1=3'b0;
	buf2=3'b0;
	buf3=3'b0;
	buf4=3'b0;
	buf5=3'b0;

	// BPo_0=1;
	// BPo_1=1;
	// BPo_2=1;
	// BPo_3=1;
	//BPo_4=1; 	//Deam - disable

	/*out_0[0]=1'b0;
	out_1[0]=1'b0;
	out_2[0]=1'b0;
	out_3[0]=1'b0;
	out_4[0]=1'b0;*/
	p=0;
	 p1=0;
	p2=0;
	p3=0;
	p4=0;
	m=0;
	m1=0;
	m2=0;
	m3=0;
	m4=0;
end
//in0
//change sensitivity

/*
cni U_in_0_cni(	.address(in0_t),
				.read_write(1'b1),
				.data(4'b0000), 
				.in_x(in0), 
				.clk(clk));

cni U_in_1_cni(	.address(in1_t),
				.read_write(1'b1),
				.data(4'b0001), 
				.in_x(in1), 
				.clk(clk));

cni U_in_2_cni(	.address(in2_t),
				.read_write(1'b1),
				.data(4'b0011), 
				.in_x(in2), 
				.clk(clk));
cni U_in_3_cni(	.address(in3_t),
				.read_write(1'b1),
				.data(4'b1111), 
				.in_x(in3), 
				.clk(clk));
cni U_in_4_cni(	.address(in4_t),
				.read_write(1'b1),
				.data(4'b1101), 
				.in_x(in4), 
				.clk(clk));			

*/

assign BPo_0_wire=!(buffer0[0] & vc0[0] & vc0[1] & vc0[2] & vc0[3] & vc0[4] & vc0[5] & 100'h0000000000000000000000001);
assign BPo_0=BPo_0_wire;

always @(posedge clk)
begin
	if(in_valid0==1'b1 && BPo_0_wire==1'b1)
	begin
		buffer0 <= {in0,1'b1}; //0th bit indicates whether buffer empty or not
		//append the route computation bits
		//rc_task(myx,myy,in0[numbits*3-1:numbits*2],in0[numbits*4-1:numbits*3],rc_0);
		rc_task_wfr(myx,myy,in0[numbits*3-1:numbits*2],in0[numbits*4-1:numbits*3],outport_status,rc_0);
		buffer0_1 <= {rc_0[2:0],in0,1'b1};
	end
	else if(BPo_0_wire==1'b1)
	begin
		buffer0[0]<=1'b0;
	end
	if(buffer0[0]==1'b1)
	begin
		if((vc0[0]&1)==0)
		begin
			vc0[0]<= buffer0_1;
		end
		else if((vc0[1]&1)==0)
		begin
			vc0[1]<= buffer0_1;
		end
		else if((vc0[2]&1)==0)
		begin
			vc0[2]<= buffer0_1;
		end
		else if((vc0[3]&1)==0)
		begin
			vc0[3]<= buffer0_1;
		end
		else if((vc0[4]&1)==0)
		begin
			vc0[4]<= buffer0_1;
		end
		else if((vc0[5]&1)==0)
		begin
			vc0[5]<= buffer0_1;
		end
	end
end


assign BPo_1_wire=!(buffer1[0] & vc1[0] & vc1[1] & vc1[2] & vc1[3] & vc1[4] & vc1[5] & 100'h0000000000000000000000001);
assign BPo_1=BPo_1_wire;

always @(posedge clk)
begin
	if(in_valid1==1'b1 && BPo_1_wire==1'b1)
	begin
		buffer1 <= {in1,1'b1}; //0th bit indicates whether buffer empty or not
		//append the route computation bits
		//rc_task(myx,myy,in1[numbits*3-1:numbits*2],in1[numbits*4-1:numbits*3],rc_1);
		rc_task_wfr(myx,myy,in1[numbits*3-1:numbits*2],in1[numbits*4-1:numbits*3],outport_status,rc_1);		
		buffer1_1 <= {rc_1[2:0],in1,1'b1};
	end
	else if(BPo_1_wire==1'b1)
	begin
		buffer1[0]<=1'b0;
	end
	if(buffer1[0]==1'b1)
	begin
		if((vc1[0]&1)==0)
		begin
			vc1[0]<= buffer1_1;
		end
		else if((vc1[1]&1)==0)
		begin
			vc1[1]<= buffer1_1;
		end
		else if((vc1[2]&1)==0)
		begin
			vc1[2]<= buffer1_1;
		end
		else if((vc1[3]&1)==0)
		begin
			vc1[3]<= buffer1_1;
		end
		else if((vc1[4]&1)==0)
		begin
			vc1[4]<= buffer1_1;
		end
		else if((vc1[5]&1)==0)
		begin
			vc1[5]<= buffer1_1;
		end
	end
end


assign BPo_2_wire=!(buffer2[0] & vc2[0] & vc2[1] & vc2[2] & vc2[3] & vc2[4] & vc2[5] & 100'h0000000000000000000000001);
assign BPo_2=BPo_2_wire;

always @(posedge clk)
begin
	if(in_valid2==1'b1 && BPo_2_wire==1'b1)
	begin
		buffer2 <= {in2,1'b1}; //0th bit indicates whether buffer empty or not
		//append the route computation bits
		//rc_task(myx,myy,in2[numbits*3-1:numbits*2],in2[numbits*4-1:numbits*3],rc_2);
		rc_task_wfr(myx,myy,in2[numbits*3-1:numbits*2],in2[numbits*4-1:numbits*3],outport_status,rc_2);		
		buffer2_1 <= {rc_2[2:0],in2,1'b1};
	end
	else if(BPo_2_wire==1'b1)
	begin
		buffer2[0]<=1'b0;
	end
	if(buffer2[0]==1'b1)
	begin
		if((vc2[0]&1)==0)
		begin
			vc2[0]<= buffer2_1;
		end
		else if((vc2[1]&1)==0)
		begin
			vc2[1]<= buffer2_1;
		end
		else if((vc2[2]&1)==0)
		begin
			vc2[2]<= buffer2_1;
		end
		else if((vc2[3]&1)==0)
		begin
			vc2[3]<= buffer2_1;
		end
		else if((vc2[4]&1)==0)
		begin
			vc2[4]<= buffer2_1;
		end
		else if((vc2[5]&1)==0)
		begin
			vc2[5]<= buffer2_1;
		end
	end
end


assign BPo_3_wire=!(buffer3[0] & vc3[0] & vc3[1] & vc3[2] & vc3[3] & vc3[4] & vc3[5] & 100'h0000000000000000000000001);
assign BPo_3=BPo_3_wire;

always @(posedge clk)
begin
	if(in_valid3==1'b1 && BPo_3_wire==1'b1)
	begin
		buffer3 <= {in3,1'b1}; //0th bit indicates whether buffer empty or not
		//append the route computation bits
		//rc_task(myx,myy,in3[numbits*3-1:numbits*2],in3[numbits*4-1:numbits*3],rc_3);
		rc_task_wfr(myx,myy,in3[numbits*3-1:numbits*2],in3[numbits*4-1:numbits*3],outport_status,rc_3);		
		buffer3_1 <= {rc_3[2:0],in3,1'b1};
	end
	else if(BPo_3_wire==1'b1)
	begin
		buffer3[0]<=1'b0;
	end
	if(buffer3[0]==1'b1)
	begin
		if((vc3[0]&1)==0)
		begin
			vc3[0]<= buffer3_1;
		end
		else if((vc3[1]&1)==0)
		begin
			vc3[1]<= buffer3_1;
		end
		else if((vc3[2]&1)==0)
		begin
			vc3[2]<= buffer3_1;
		end
		else if((vc3[3]&1)==0)
		begin
			vc3[3]<= buffer3_1;
		end
		else if((vc3[4]&1)==0)
		begin
			vc3[4]<= buffer3_1;
		end
		else if((vc3[5]&1)==0)
		begin
			vc3[5]<= buffer3_1;
		end
	end
end


assign BPo_4_wire=!(buffer4[0] & vc4[0] & vc4[1] & vc4[2] & vc4[3] & vc4[4] & vc4[5] & 100'h0000000000000000000000001);
assign BPo_4=BPo_4_wire;

always @(posedge clk)
begin
	if(in_valid4==1'b1 && BPo_4_wire==1'b1)
	begin
		buffer4 <= {in4,1'b1}; //0th bit indicates whether buffer empty or not
		//append the route computation bits
		//rc_task(myx,myy,in4[numbits*3-1:numbits*2],in4[numbits*4-1:numbits*3],rc_4);
		rc_task_wfr(myx,myy,in4[numbits*3-1:numbits*2],in4[numbits*4-1:numbits*3],outport_status,rc_4);
		buffer4_1 <= {rc_4[2:0],in4,1'b1};
	end
	else if(BPo_4_wire==1'b1)
	begin
		buffer4[0]<=1'b0;
	end
	if(buffer4[0]==1'b1)
	begin
		if((vc4[0]&1)==0)
		begin
			vc4[0]<= buffer4_1;
		end
		else if((vc4[1]&1)==0)
		begin
			vc4[1]<= buffer4_1;
		end
		else if((vc4[2]&1)==0)
		begin
			vc4[2]<= buffer4_1;
		end
		else if((vc4[3]&1)==0)
		begin
			vc4[3]<= buffer4_1;
		end
		else if((vc4[4]&1)==0)
		begin
			vc4[4]<= buffer4_1;
		end
		else if((vc4[5]&1)==0)
		begin
			vc4[5]<= buffer4_1;
		end
	end
end


always @(posedge clk)
begin
	//selecting 1 vc in roundrobin fashion 
	if(reset) 
	begin 
		counter_out_0 <= 3'b0;
		mux_out_0 = 3'b0;
		mux_in_0 = 3'b0;
	end
	else 
	begin 
		if (counter_out_0 < 3'b101) 
		begin
			counter_out_0 <= counter_out_0+1; 
		end 
		else 
		begin
			counter_out_0 <= 3'b0; 
		end
		mux_out_0 = (~buffer_out_0[0])? counter_out_0 : mux_in_0;
		mux_in_0 = mux_out_0;
		rr_vc_0 = mux_out_0;
	end 
	//send to the output buffer if buffer_out is free

	if (rr_vc_0 == 3'b000 && vc0[0]&1'b1 == 1'b1 && buffer_out_0[0]==1'b0) 
	begin
		buffer_out_0= vc0[0];
		vc0[0]=vc0[0]&1'b0;
	/*ready=1'b1;
	ready1=1'b1;
	ready2=1'b1;
	ready3=1'b1;
	ready4=1'b1;*/
    //check this 
		buffer_out_0[0]=1'b1;
	end
	else if (rr_vc_0 == 3'b001 && vc0[1]&1'b1==1'b1 && buffer_out_0[0]==1'b0) 
	begin
		buffer_out_0= vc0[1];
		vc0[1]=vc0[1]&1'b0;
	/*ready=1'b1;
	ready1=1'b1;
	ready2=1'b1;
	ready3=1'b1;
	ready4=1'b1;*/
    //check this
		buffer_out_0[0]=1'b1;
	end
	else if (rr_vc_0 == 3'b010&& vc0[2]&1'b1==1'b1 && buffer_out_0[0]==1'b0) 
	begin
		buffer_out_0= vc0[2];
		vc0[2]=vc0[2]&1'b0;
	/*ready=1'b1;
	ready1=1'b1;
	ready2=1'b1;
	ready3=1'b1;
	ready4=1'b1;*/
   //check this
		buffer_out_0[0]=1'b1;
	end

	else if (rr_vc_0==3'b011 && vc0[3]&1'b1==1'b1 && buffer_out_0[0]==1'b0) 
	begin
		buffer_out_0= vc0[3];
		vc0[3]=vc0[3]&1'b0;
		buffer_out_0[0]=1'b1;
	end

	else if (rr_vc_0==3'b100&& vc0[4]&1'b1==1'b1 && buffer_out_0[0]==1'b0) 
	begin
		buffer_out_0= vc0[4];
		vc0[4]=vc0[4]&1'b0;
	/*ready=1'b1;
	ready1=1'b1;
	ready2=1'b1;
	ready3=1'b1;
	ready4=1'b1;*/
     //check this
		buffer_out_0[0] =1'b1;
	end

	else if (rr_vc_0== 3'b101&& vc0[5]&1'b1==1'b1 && buffer_out_0[0]==1'b0)
	begin
		buffer_out_0= vc0[5] ;
		vc0[5]=vc0[5]&1'b0;
		buffer_out_0[0] =1'b1;
	end
end

always@ (posedge clk)
begin
//selecting 1 vc in roundrobin fashion 
	if(reset) begin 
		counter_out_1 <= 3'b0;
		mux_out_1 = 3'b0;
		mux_in_1 = 3'b0;
	end
	else 
	begin 
		if (counter_out_1 < 3'b101) 
		begin
			counter_out_1 <= counter_out_1+1; 
		end 
		else 
		begin
			counter_out_1 <= 3'b0; 
		end
		mux_out_1 = (~buffer_out_1[0])? counter_out_1 : mux_in_1;
		mux_in_1 = mux_out_1;
		rr_vc_1 = mux_out_1;
	end 
		//send to the output buffer if buffer_out is free

	if (rr_vc_1 == 3'b000 && vc1[0]&1'b1 == 1'b1 && buffer_out_1[0]==1'b0) 
	begin
		buffer_out_1= vc1[0] ;
		vc1[0]=vc1[0]&1'b0;
	 //check this
		buffer_out_1[0]=1'b1;
	end
	else if (rr_vc_1 == 3'b001 && vc1[1]&1'b1==1'b1 && buffer_out_1[0]==1'b0) 
	begin
		buffer_out_1= vc1[1] ;
		vc1[1]=vc1[1]&1'b0;
	 //check this
		buffer_out_1[0]=1'b1;
	end
	else if (rr_vc_1 == 3'b010&& vc1[2]&1'b1==1'b1 && buffer_out_1[0]==1'b0 ) 
	begin
		buffer_out_1= vc1[2] ;
		vc1[2]=vc1[2]&1'b0;
	 //check this
		buffer_out_1[0]=1'b1;
	end
	else if (rr_vc_1==3'b011 && vc1[3]&1'b1==1'b1 && buffer_out_1[0]==1'b0 ) 
	begin
		buffer_out_1= vc1[3] ;
		vc1[3]=vc1[3]&1'b0;
		//check this
		buffer_out_1[0]=1'b1;
	end
	else if (rr_vc_1==3'b100&& vc1[4]&1'b1==1'b1 && buffer_out_1[0]==1'b0) 
	begin
		buffer_out_1= vc1[4] ;
		vc1[4]=vc1[4]&1'b0;
		//check this
		buffer_out_1[0] =1'b1;
	end
	else if (rr_vc_1== 3'b101&& vc1[5]&1'b1==1'b1 && buffer_out_1[0]==1'b0)
	begin
		buffer_out_1= vc1[5];
		vc1[5]=vc1[5]&1'b0;
		//check this
		buffer_out_1[0] =1'b1;
	end
end

always @(posedge clk)
begin
//selecting 1 vc in roundrobin fashion 
	if(reset) begin 
		counter_out_2 <= 3'b0;
		mux_out_2 = 3'b0;
		mux_in_2 = 3'b0;
	end
	else 
	begin 
		if (counter_out_2 < 3'b101) 
		begin
			counter_out_2 <= counter_out_2+1; 
		end 
		else 
		begin
			counter_out_2 <= 3'b0; 
		end
		mux_out_2 = (~buffer_out_2[0])? counter_out_2 : mux_in_2;
		mux_in_2 = mux_out_2;
		rr_vc_2 = mux_out_2;
	end 
	//send to the output buffer if buffer_out is free
	if (rr_vc_2 == 3'b000 && vc2[0]&1'b1 == 1'b1 && buffer_out_2[0]==1'b0) 
	begin
		buffer_out_2= vc2[0];
		vc2[0]=vc2[0]&1'b0;
		//check this
		buffer_out_2[0]=1'b1;
	end
	else if (rr_vc_2 == 3'b001 && vc2[1]&1'b1==1'b1 && buffer_out_2[0]==1'b0) 
	begin
		buffer_out_2= vc2[1] ;
		vc2[1]=vc2[1]&1'b0;
		 //check this
		buffer_out_2[0]=1'b1;
	end
	else if (rr_vc_2 == 3'b010&& vc2[2]&1'b1==1'b1 && buffer_out_2[0]==1'b0) 
	begin
		buffer_out_2= vc2[2];
		vc2[2]=vc2[2]&1'b0;
		 //check this
		buffer_out_2[0]=1'b1;
	end
	else if (rr_vc_2==3'b011 && vc2[3]&1'b1==1'b1 && buffer_out_2[0]==1'b0) 
	begin
		buffer_out_2= vc2[3] ;
		vc2[3]=vc2[3]&1'b0;
		 //check this
		buffer_out_2[0]=1'b1;
	end
	else if (rr_vc_2==3'b100&& vc2[4]&1'b1==1'b1 && buffer_out_2[0]==1'b0) 
	begin
		buffer_out_2= vc2[4] ;
		vc2[4]=vc2[4]&1'b0;
		 //check this
		buffer_out_2[0] =1'b1;
	end
	else if (rr_vc_2== 3'b101&& vc2[5]&1'b1==1'b1 && buffer_out_2[0]==1'b0)
	begin
		buffer_out_2= vc2[5];
		vc2[5]=vc2[5]&1'b0;
		 //check this
		buffer_out_2[0]=1'b1;
	end
end

always @(posedge clk)
begin
	//selecting 1 vc in roundrobin fashion 
	if(reset) begin 
		counter_out_3 <= 3'b0;
		mux_out_3 = 3'b0;
		mux_in_3 = 3'b0;
	end
	else 
	begin 
		if (counter_out_3 < 3'b101) 
		begin
			counter_out_3 <= counter_out_3+1; 
		end 
		else 
		begin
			counter_out_3 <= 3'b0; 
		end
		mux_out_3 = (~buffer_out_3[0])? counter_out_3 : mux_in_3;
		mux_in_3 = mux_out_3;
		rr_vc_3 = mux_out_3;
	end 
	//send to the output buffer if buffer_out is free

	if (rr_vc_3 == 3'b000 && vc3[0]&1'b1== 1'b1 && buffer_out_3[0]==1'b0) 
	begin
		buffer_out_3= vc3[0];
		vc3[0]=vc3[0]&1'b0;
		//check this
		buffer_out_3[0]=1'b1;
	end
	else if (rr_vc_3 == 3'b001 && vc3[1]&1'b1==1'b1 && buffer_out_3[0]==1'b0) 
	begin
		buffer_out_3= vc3[1];
		vc3[1]=vc3[1]&1'b0;
		//check this
		buffer_out_3[0]=1'b1;
	end
	else if (rr_vc_3 == 3'b010&& vc3[2]&1'b1==1'b1 && buffer_out_3[0]==1'b0) 
	begin
		buffer_out_3= vc3[2] ;
		vc3[2]=vc3[2]&1'b0;
		//check this
		buffer_out_3[0]=1'b1;
	end

	else if (rr_vc_3==3'b011 && vc3[3]&1'b1==1'b1 && buffer_out_3[0]==1'b0) 
	begin
		buffer_out_3= vc3[3] ;
		vc3[3]=vc3[3]&1'b0;
		 //check this
		buffer_out_3[0]=1'b1;
	end
	else if (rr_vc_3==3'b100&& vc3[4]&1'b1==1'b1 && buffer_out_3[0]==1'b0) 
	begin
		buffer_out_3 = vc3[4] ;
		vc3[4]=vc3[4]&1'b0;
		 //check this
		buffer_out_3[0] =1'b1;
	end
	else 
	if (rr_vc_3== 3'b101 &&  vc3[5]&1'b1==1'b1 && buffer_out_3[0]==1'b0)
	begin
		buffer_out_3= vc3[5];
		vc3[5]=vc3[5]&1'b0;
		buffer_out_3[0]=1'b1;
	end
end

always @(posedge clk)
begin
//selecting 1 vc in roundrobin fashion 
	if(reset) begin 
		counter_out_4 <= 3'b0;
		mux_out_4 = 3'b0;
		mux_in_4 = 3'b0;
	end
	else 
	begin 
		if (counter_out_4 < 3'b101) 
		begin
			counter_out_4 <= counter_out_4+1; 
		end 
		else 
		begin
			counter_out_4 <= 3'b0; 
		end
		mux_out_4 = (~buffer_out_4[0])? counter_out_4 : mux_in_4;
		mux_in_4 = mux_out_4;
		rr_vc_4 = mux_out_4;
	end 
	//send to the output buffer if buffer_out is free

	if (rr_vc_4 == 3'b000 && vc4[0]&1'b1 == 1'b1 && buffer_out_4[0]==1'b0) 
	begin
		buffer_out_4= vc4[0] ;
		vc4[0]=vc4[0]&1'b0;
		 //check this
		buffer_out_4[0]=1'b1;
	end
	else if (rr_vc_4 == 3'b001 && vc4[1]&1'b1==1'b1 && buffer_out_4[0]==1'b0) 
	begin
		buffer_out_4= vc4[1] ;
		vc4[1]=vc4[1]&1'b0;
		 //check this
		buffer_out_4[0]=1'b1;
	end
	else if (rr_vc_4 == 3'b010&& vc4[2]&1'b1==1'b1 && buffer_out_4[0]==1'b0) 
	begin
		buffer_out_4= vc4[2];
		vc4[2]=vc4[2]&1'b0;
		buffer_out_4[0]=1'b1;
	end

	else if (rr_vc_4==3'b011 && vc4[3]&1'b1==1'b1 && buffer_out_4[0]==1'b0) 
	begin
		buffer_out_4= vc4[3] ;
		vc4[3]=vc4[3]&1'b0;
		buffer_out_4[0]=1'b1;
	end

	else if (rr_vc_4==3'b100&& vc4[4]&1'b1==1'b1 && buffer_out_4[0]==1'b0) 
	begin
		buffer_out_4= vc4[4] ;
		vc4[4]=vc4[4]&1'b0;
		 //check this
		buffer_out_4[0]=1'b1;
	end

	else if (rr_vc_4== 3'b101&& vc4[5]&1==1'b1 && buffer_out_4[0]==1'b0)
	begin
		buffer_out_4= vc4[5] ;
		vc4[5]=vc4[5]&1'b0;
		 //check this
		buffer_out_4[0] =1'b1;
	end
end


//rr for outport 0 
always @(posedge clk)
	if (BP_0)
	begin 
		if (counter1_out_0 < 3'b100) 
		begin
			counter1_out_0 <= counter1_out_0+1; 
		end 
		else 
		begin
			counter1_out_0 <= 3'b0; 
		end
		mux1_out_0 = (sel1_0)? counter1_out_0 : mux1_in_0;
		mux1_in_0 = mux1_out_0;
		rr_port_0 = mux1_out_0;
	end

//rr for outport1
always @(posedge clk)
	if(BP_1)
	begin
		if (counter1_out_1 < 3'b100) 
		begin
			counter1_out_1 <= counter1_out_1+1; 
		end 
		else 
		begin
			counter1_out_1 <= 3'b0; 
		end
		mux1_out_1 = (sel1_1)? counter1_out_1 : mux1_in_1 ;
		mux1_in_1 = mux1_out_1;
		rr_port_1 = mux1_out_1;
	end

//rr for outport2 
always @(posedge clk)
	if(BP_2)
	begin
		if (counter1_out_2 < 3'b100) 
		begin
			counter1_out_2 <= counter1_out_2+1; 
		end 
		else 
		begin
			counter1_out_2 <= 3'b0; 
		end
		mux1_out_2 = (sel1_2)? counter1_out_2 : mux1_in_2 ;
		mux1_in_2 = mux1_out_2;
		rr_port_2 = mux1_out_2;
	end 

//rr for outport3
always @(posedge clk)
	if(BP_3)
	begin
		if (counter1_out_3 < 3'b100) 
		begin
			counter1_out_3 <= counter1_out_3+1; 
		end 
		else 
		begin
			counter1_out_3 <= 3'b0; 
		end
		mux1_out_3 = (sel1_3)? counter1_out_3 : mux1_in_3 && BP_3;
		mux1_in_3 = mux1_out_3;
		rr_port_3 = mux1_out_3;
	end 

//rr for output port 4 
always @(posedge clk)
	if(BP_4)
	begin
		if (counter1_out_4< 3'b100) 
		begin
			counter1_out_4<= counter1_out_4+1; 
		end 
		else 
		begin
			counter1_out_4<= 3'b0; 
		end
		mux1_out_4= (sel1_4)? counter1_out_4: mux1_in_4&& BP_4;
		mux1_in_4= mux1_out_4;
		rr_port_4 = mux1_out_4;
	end 

// output port logic  for each buffer_out_0 if initial two bits 
//fill in output buffer from in0 
//port zero


always @(posedge clk)
begin
	//Deam- disable , 	
    // out_valid0=1'b0;
	// out_valid1=1'b0;
	// out_valid2=1'b0;
	// out_valid3=1'b0;
	// out_valid4=1'b0;
	
	//Deam- added
	
	if(BP_0==1'b1)
		out_valid0=1'b0;
	
	if(BP_1==1'b1)	
		out_valid1=1'b0;
	
	if(BP_2==1'b1)
		out_valid2=1'b0;
	
	if(BP_3==1'b1)
		out_valid3=1'b0;
	
	if(BP_4==1'b1)
		out_valid4=1'b0;	

//always @(posedge clk)
//begin
//rr_port_0 code 
	if (buffer_out_0[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b000 && rr_port_0==3'b000 && ready==1'b0 && buffer_out_0[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_0[numbits*4+data_size-1 : 0] =  buffer_out_0[numbits*4+data_size : 1]; 
		ready=1'b1;
		sel1_0=1'b1;
		out_valid0=1'b1;
		buffer_out_0[0]=1'b0; 
	end
	else if (buffer_out_0[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b001 && rr_port_1==3'b000 && ready1==1'b0 && buffer_out_0[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_1[numbits*4+data_size-1 : 0] =  buffer_out_0[numbits*4+data_size : 1]; 
		ready1=1'b1;
		sel1_1=1'b1;
		out_valid1=1'b1;
		buffer_out_0[0]=1'b0;
	end
	else if (buffer_out_0[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b010 && rr_port_2==3'b000 && ready2==1'b0 && buffer_out_0[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_2[numbits*4+data_size-1 : 0] =  buffer_out_0[numbits*4+data_size : 1]; 
		ready2=1'b1;
		sel1_2=1'b1;
		out_valid2=1'b1;
		buffer_out_0[0]=1'b0;
	end
	else if (buffer_out_0[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b011 && rr_port_3==3'b000 && ready3==1'b0 && buffer_out_0[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_3[numbits*4+data_size-1 : 0] =  buffer_out_0[numbits*4+data_size : 1]; 
		sel1_3 = 1'b1;
		out_valid3=1'b1;
		buffer_out_0[0] = 1'b0;
		ready3 = 1'b1;
	end
	else if (buffer_out_0[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b100 && rr_port_4==3'b000 && ready4==1'b0 && buffer_out_0[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_4[numbits*4+data_size-1 : 0] =  buffer_out_0[numbits*4+data_size : 1]; 
		sel1_4 =  1'b1;
		buffer_out_0[0] = 1'b0;
		ready4 = 1'b1;
		out_valid4=1'b1;
	end
	else
	begin
		ready= !BP_0;
		ready1= !BP_1;
		ready2=!BP_2;
		ready3= !BP_3;
		ready4= !BP_4;
	end

	//always @(posedge clk)
	if (buffer_out_1[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b000 && rr_port_0==3'b001 && ready==1'b0 && buffer_out_1[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_0[numbits*4+data_size-1 : 0] =  buffer_out_1[numbits*4+data_size : 1]; 
		ready=1'b1;
		sel1_0=1'b1;
		out_valid0=1'b1;
		buffer_out_1[0]=1'b0;
	end
	else if (buffer_out_1[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b001 && rr_port_1==3'b001 && ready1==1'b0 && buffer_out_1[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_1[numbits*4+data_size-1 : 0] =  buffer_out_1[numbits*4+data_size : 1]; 
		ready1=1'b1;
		sel1_1=1'b1;
		out_valid1=1'b1;
		buffer_out_1[0]=1'b0;
	end
	else if (buffer_out_1[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b010 && rr_port_2==3'b001 && ready2==1'b0 && buffer_out_1[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_2[numbits*4+data_size-1 : 0] =  buffer_out_1[numbits*4+data_size : 1]; 
		ready2=1'b1;
		sel1_2=1'b1;
		out_valid2=1'b1;
		buffer_out_1[0]=1'b0;
	end
	else if (buffer_out_1[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b011 && rr_port_3==3'b001 && ready3==1'b0 && buffer_out_1[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_3[numbits*4+data_size-1 : 0] =  buffer_out_1[numbits*4+data_size : 1]; 
		sel1_3=1'b1;
		out_valid3=1'b1;
		buffer_out_1[0]=1'b0;
		ready3=1'b1;
	end
	else if (buffer_out_1[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b100 && rr_port_4==3'b001 && ready4==1'b0 && buffer_out_1[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_4[numbits*4+data_size-1 : 0] =  buffer_out_1[numbits*4+data_size : 1]; 
		sel1_4=1'b1;
		out_valid4=1'b1;
		buffer_out_1[0]=1'b0;
		ready4=1'b1;
	end
	else
	begin
		ready = !BP_0;
		ready1= !BP_1;
		ready2= !BP_2;
		ready3= !BP_3;
		ready4= !BP_4;
	end
	/////done until here
	// buffer_out_2 to output 
	//always @(posedge clk)
	if (buffer_out_2[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b000 && rr_port_0==3'b010 && ready==1'b0 && buffer_out_2[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_0[numbits*4+data_size-1 : 0] =  buffer_out_2[numbits*4+data_size : 1]; 
		ready=1'b1;
		sel1_0=1'b1;
		out_valid0=1'b1;
		buffer_out_2[0]=1'b0;
	end
	else if (buffer_out_2[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b001 && rr_port_1==3'b010 && ready1==1'b0 && buffer_out_2[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_1[numbits*4+data_size-1 : 0] =  buffer_out_2[numbits*4+data_size : 1]; 
		ready1=1'b1;
		sel1_1=1'b1;
		out_valid1=1'b1;
		buffer_out_2[0]=1'b0;
	end
	else if (buffer_out_2[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b010 && rr_port_2==3'b010 && ready2==1'b0 && buffer_out_2[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_2[numbits*4+data_size-1 : 0] =  buffer_out_2[numbits*4+data_size : 1]; 
		ready2=1'b1;
		sel1_2=1'b1;
		out_valid2=1'b1;
		buffer_out_2[0]=1'b0;
	end
	else if (buffer_out_2[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b011 && rr_port_3==3'b010 && ready3==1'b0 && buffer_out_2[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_3[numbits*4+data_size-1 : 0] =  buffer_out_2[numbits*4+data_size : 1]; 
		ready3=1'b1;
		sel1_3=1'b1;
		out_valid3=1;
		buffer_out_2[0]=1'b0;
	end
	else if (buffer_out_2[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b100 && rr_port_4==3'b010 && ready4==1'b0 && buffer_out_2[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_4[numbits*4+data_size-1 : 0] =  buffer_out_2[numbits*4+data_size : 1]; 
		ready4=1'b1;
		out_valid4=1;
		sel1_4=1'b1;
		buffer_out_2[0]=1'b0;
	end
	else
	begin
		ready= !BP_0;
		ready1= !BP_1;
		ready2= !BP_2;
		ready3= !BP_3;
		ready4= !BP_4;
	end

	//always @(posedge clk)
	if (buffer_out_3[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b000 && rr_port_0==3'b011 && ready==1'b0 && buffer_out_3[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_0[numbits*4+data_size-1 : 0] =  buffer_out_3[numbits*4+data_size : 1]; 
		ready=1'b1;
		sel1_0=1'b1;
		out_valid0=1'b1;
		buffer_out_3[0]=1'b0;
	end
	else if (buffer_out_3[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b001 && rr_port_1==3'b011 && ready1==1'b0 && buffer_out_3[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_1[numbits*4+data_size-1 : 0] =  buffer_out_3[numbits*4+data_size : 1]; 
		ready1=1'b1;
		sel1_1=1'b1;
		out_valid1=1'b1;
		buffer_out_3[0]=1'b0;
	end
	else if (buffer_out_3[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b010 && rr_port_2==3'b011 && ready2==1'b0 && buffer_out_3[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_2[numbits*4+data_size-1 : 0] =  buffer_out_3[numbits*4+data_size : 1]; 
		ready2=1'b1;
		sel1_2=1'b1;
		out_valid2=1'b1;
		buffer_out_3[0]=1'b0;
	end
	else if (buffer_out_3[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b011 && rr_port_3==3'b011 && ready3==1'b0 && buffer_out_3[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_3[numbits*4+data_size-1 : 0] =  buffer_out_3[numbits*4+data_size : 1]; 
		ready3=1'b1;
		out_valid3=1'b1;
		sel1_3=1'b1;
		buffer_out_3[0]=1'b0;
	end
	else if (buffer_out_3[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b100 && rr_port_4==3'b011 && ready4==1'b0 && buffer_out_3[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_4[numbits*4+data_size-1 : 0] =  buffer_out_3[numbits*4+data_size : 1]; 
		ready4=1'b1;
		out_valid4=1'b1;
		sel1_4=1'b1;
		buffer_out_3[0]=1'b0;
	end
	else
	begin
		ready= !BP_0;
		ready1= !BP_1;
		ready2= !BP_2;
		ready3= !BP_3;
		ready4= !BP_4;
	end

	//always @(posedge clk)
	if (buffer_out_4[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b000 && rr_port_0==3'b100 && ready==1'b0 && buffer_out_4[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_0[numbits*4+data_size-1 : 0] =  buffer_out_4[numbits*4+data_size : 1]; 
		ready=1'b1;
		out_valid0=1'b1;
		sel1_0=1'b1;
		buffer_out_4[0]=1'b0;
	end
	else if (buffer_out_4[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b001 && rr_port_1==3'b100 && ready1==1'b0 && buffer_out_4[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_1[numbits*4+data_size-1 : 0] =  buffer_out_4[numbits*4+data_size : 1]; 
		ready1=1'b1;
		sel1_1=1'b1;
		out_valid1=1'b1;
		buffer_out_4[0]=1'b0;
	end
	else if (buffer_out_4[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b010 && rr_port_2==3'b100 && ready2==1'b0 && buffer_out_4[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_2[numbits*4+data_size-1 : 0] =  buffer_out_4[numbits*4+data_size : 1]; 
		ready2=1'b1;
		sel1_2=1'b1;
		out_valid2=1'b1;
		buffer_out_4[0]=1'b0;
	end
	else if (buffer_out_4[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b011 && rr_port_3==3'b100 && ready3==1'b0 && buffer_out_4[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_3[numbits*4+data_size-1 : 0] =  buffer_out_4[numbits*4+data_size : 1]; 
		ready3=1'b1;
		out_valid3=1'b1;
		sel1_4=1'b1;
		buffer_out_4[0]=1'b0;
	end
	else if (buffer_out_4[numbits*4+data_size+3 : numbits*4+data_size+1]==3'b100 && rr_port_4==3'b100 && ready4==1'b0 && buffer_out_4[0]==1'b1)  //send packets only if buffer out is empty 
	begin
		out_4[numbits*4+data_size-1 : 0] =  buffer_out_4[numbits*4+data_size : 1]; 
		ready4=1'b1;
		out_valid4=1'b1;
		sel1_4=1'b1;
		buffer_out_4[0]=1'b0;
	end
	else
	begin
		ready= !BP_0;
		ready1= !BP_1;
		ready2= !BP_2;
		ready3= !BP_3;
		ready4= !BP_4;
	end
end
endmodule 