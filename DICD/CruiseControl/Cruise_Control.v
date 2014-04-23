`timescale 1ns/1ps

//*********************************************************************
//	Name: Sridhar Mareguddi
//	Module Name: cruise_control
//	Date: 03/03/2014
//*********************************************************************

`define idle   		 4'b1000
`define default_state    4'b0001
`define cruise  	 4'b0010
`define brake   	 4'b0100

module cruise_control(
	//input declarations
	input throttle,
	input set,
	input accel,
	input coast,
	input cancel,
	input resume,
	input brake,
	input clock,
	input reset,
	// output declarations
	output reg [31:0] speed,
	output reg [31:0] cruise_speed,
	output reg cruise_status
);

reg[3:0] current_state;        //Indicates the current state
reg[3:0] next_state;        //Indicates the next state
//reg[31:0] speed, cruise_speed;
//reg cruise_status;
reg resume_flag;


`ifndef SYNTHESIS
	initial
	begin
		next_state<=4'b0000;
	end
`endif

always@(posedge clock)
begin
	// If reset, make the current state as idle
    if(reset==1'b1)
        current_state<=`idle;
    else
        current_state<=next_state;
end
// monitor the change in current_state,set,brake,throttle,cancel,resume,reset
always@(current_state,set,brake,throttle,cancel,resume,reset)
begin

    

    case(current_state)

    	`idle:
    	begin
        	if(reset==1'b0)
            		next_state<=`default_state; // When reset, set next_state as default_state
        	else
            		next_state<=`idle; // Otherwise remain idle
    	end

    	`default_state:
    	begin
    		if((set==1'b1&&speed>=32'd45)||(resume==1'b1&&speed>=32'd0))
    		begin
        		next_state<=`cruise;// (set=1 and speed>45 )or (resume=1 and speed >0)
        		cruise_speed<=(resume==1)?cruise_speed:speed; // if resume=0 assign speed to cruise speed
        		resume_flag<=(resume==1)?1'b1:1'b0;// make resume flag=1 if resume is 1
    		end
    		else if(brake==1'b1)//if brake is set, make the state as brake
    	   		next_state<=`brake;
    		else
        		next_state<=`default_state;//else move to default_state
	end

	`brake:
	begin
    		if(throttle==1'b1)
        	next_state<=`default_state;

   		else if ((set==1'b1&&speed>32'd45)||(resume==1'b1&&speed>32'd0))
    		begin
        		next_state<=`cruise;//if set is 1 and speed is > 45, move to cruise state
        		cruise_speed<=(resume==1)?cruise_speed:speed;
        		resume_flag<=(resume==1)?1'b1:1'b0;
    		end

    		else
        		next_state<=`brake;
	end

	`cruise:
	begin
   	 	if(cancel==1'b1)
    		begin
        		next_state<=`default_state;//If cancel is pressed move to default state
        		resume_flag<=1'b0;
    		end
    		else if(brake==1'b1)
    		begin
        		next_state<=`brake;
        		resume_flag<=1'b0;
    		end
    		else
       			next_state<=`cruise;
	end
	endcase

end

always@(posedge clock)

begin
    case(current_state)

	`idle:
	begin
	    speed<=0;
	    cruise_speed<=0;
	    resume_flag<=1'b0;

	end

	`default_state:
	 begin
		 if(throttle==1'b1)
		 begin
		        speed<=speed+32'd1;
 		 end
		 else if(throttle==1'b0&&speed>32'd0)
		        speed<=speed-32'd1;
	 end

	`cruise:
	begin
		if(throttle==1)
		        speed<=speed+32'd1;
		else if(throttle==0)
		begin
		        if(resume_flag==1'b0)
		                speed<=(speed>cruise_speed)?(speed-1):cruise_speed;
		        else
		                speed<=(speed<cruise_speed)?(speed+1):cruise_speed;
		end
  		//if(accel==1)
        		cruise_speed<=cruise_speed+32'd1;
		//else if(coast==1&&speed>45)
		        cruise_speed<=cruise_speed-32'd1;
	end

	`brake:
	begin
		speed<=speed-32'd2;
	end
	endcase

end

always@(next_state)
begin
	    if(next_state==`cruise)
		        cruise_status=1'b1;
	    else
		        cruise_status=1'b0;
end
endmodule

