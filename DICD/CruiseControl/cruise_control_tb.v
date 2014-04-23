//************************************************************************
//	Name: Sridhar Mareguddi
//	Module Name: cruise_control_tb
//	Date: 03/03/2014
//***********************************************************************
`timescale 1ns/1ps

module cruise_control_tb;

        //input signal declarations
        reg throttle;
        reg set;
        reg accel;
        reg coast;
        reg cancel;
        reg resume;
        reg brake;
        reg clock;
        reg reset;

        //Output signals are of wire type
        wire[31:0] speed, cruise_speed;
        wire cruise_status;

	//call the module name with inputs and outputs
        cruise_control cc_instance(
        .throttle(throttle), 
	.set(set), .accel(accel), 
	.coast(coast), 
	.cancel(cancel), 
	.resume(resume), 
	.brake(brake), 
	.clock(clock), 
	.reset(reset), 	
	.speed(speed), 
	.cruise_speed(cruise_speed), 
	.cruise_status(cruise_status)
        );

initial begin

        //initialize inputs
        throttle=0;
        set=0;
        accel=0;
        coast=0;
        cancel=0;
        resume=0;
        brake=0;
        clock=0;
        reset=0;

	//Invoke reset signal
        #10;
        reset=1; #2; reset=0; #2;

	//Provide input signal to cruise control
        throttle=1; #60; //increase the speed of the vehicle to 30mph
	throttle=0; set=1; #2;// set pulse signal is turned on
	set=0; #18;
	throttle=1; #60;
	set=1; #2; set=0; #18; // when speed=60mph, throttle turned off
	throttle=0; #30;
	brake=1; #2; brake=0; #18;
	resume=1; #2; resume=0; #48;
	
	// 5 consecutive accel pulses increase cruise_speed to 55mph
	accel=1;#2;accel=0; #2;
	accel=1;#2;accel=0; #2;
	accel=1;#2;accel=0; #2;
	accel=1;#2;accel=0; #2;
	accel=1;#2;accel=0; #10;
	// 5 consecutive coast pulses decrease cruise_speed to 50mph
	coast=1;#2;coast=0;#2;
	coast=1;#2;coast=0;#2;
	coast=1;#2;coast=0;#2;
	coast=1;#2;coast=0;#2;
	coast=1;#2;coast=0;#10;
	
	//cancel pulse decrease speed by 1mph
	cancel=1; #2; cancel=0; #108;

$finish;

end

always

begin
    #1 clock=~clock;//generate clock
end

endmodule
