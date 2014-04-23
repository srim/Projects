// Basic fifo
// Copyright 2005, Timothy Miller
// LGPL license

/*
	-Deam: modify fifo depth
	-Deam: add initial block
*/
module basic_fifo(
    clock,
    reset,
    
    data_in,
    enq,
    full,
    
    data_out,
    valid_out,
    deq
);

parameter fifo_width = 32;
parameter num_bit_depth = 4; //fifo_depth = (1<<num_bit_depth)
//parameter fifo_depth = 16;
// fifo depth is hard-wired to 16

input clock, reset;

input [fifo_width-1:0] data_in;
input enq;
output full;
reg full;

output [fifo_width-1:0] data_out;
reg [fifo_width-1:0] data_out;
output valid_out;
reg valid_out;
input deq;



reg [fifo_width-1:0] fifo_data [0:(1<<num_bit_depth)-1];
reg [num_bit_depth:0] fifo_head, fifo_tail;
reg [num_bit_depth:0] next_tail;


// accept input
wire next_full = fifo_head[num_bit_depth-1:0] == next_tail[num_bit_depth-1:0] &&
    fifo_head[num_bit_depth] != next_tail[num_bit_depth];
wire is_full = fifo_head[num_bit_depth-1:0] == fifo_tail[num_bit_depth-1:0] &&
    fifo_head[num_bit_depth] != fifo_tail[num_bit_depth];
	
initial 
begin
	fifo_tail = 0;
	next_tail = 1;
end	
always @(posedge clock) begin
    if (reset) begin
        fifo_tail <= 0;
        next_tail <= 1;
        full <= 0;
    end else begin
        if (!full && enq) begin
            // We can only enqueue when not full
            fifo_data[fifo_tail[num_bit_depth-1:0]] <= data_in;
            next_tail <= next_tail + 1;
            fifo_tail <= next_tail;
            
            // We have to compute if it's full on next cycle
            full <= next_full;
        end else begin
            full <= is_full;
        end
    end
end


// provide output
wire is_empty = fifo_head == fifo_tail;
always @(posedge clock) begin
    if (reset) begin
        valid_out <= 0;
        data_out <= 0;
        fifo_head <= 0;
    end else begin
        // If no valid out or we're dequeueing, we want to grab
        // the next data.  If we're empty, we don't get valid_out,
        // so we don't care if it's garbage.
        if (!valid_out || deq) begin
            data_out <= fifo_data[fifo_head[num_bit_depth-1:0]];
        end
        
        if (!is_empty) begin
            if (!valid_out || deq) begin
                fifo_head <= fifo_head + 1;
            end
            valid_out <= 1;
        end else begin
            if (deq) valid_out <= 0;
        end
    end
end


endmodule
