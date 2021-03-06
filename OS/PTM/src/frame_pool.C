#include "frame_pool.H"
#include "console.H"

unsigned long FramePool:: bitmap_reg[256];

   const unsigned int FramePool::FRAME_SIZE;
   /* Size of a frame in bytes */

   const int FramePool::USED;
   const int FramePool::AVAILABLE;
   const int FramePool::MAX_FRAMES;

FramePool::FramePool(unsigned long _base_frame_no,
            	     unsigned long _nframes,	
            	     unsigned long _info_frame_no) {

        //Console::puts("inside framepool constructor\n");
	base_frame_no = _base_frame_no;
	nframes = _nframes;
	info_frame_no = _info_frame_no;

	/* All bits of bit map register marked as available */ 
	for(int i=0;i<256;i++){	
	bitmap_reg[i]= MARK_AVAILABLE;	
	}

        if (_info_frame_no == 0) {
          /*Kernel Frame Pool*/
          _info_frame_no = (2 * 1024 * 1024) /FRAME_SIZE; //_info_frame_no=512
        } 

       /* Mark initial 2MB as inaccessable or used */
        for (unsigned long i = 0; i < _info_frame_no; i++) {
                 Mark_Frames(_info_frame_no, MARK_USED);
        }
}



unsigned long FramePool::get_frame() {
	int flag_found=0,i,j;
        //Console::puts("inside get frame\n");
	//Console::putui(this->base_frame_no);
	if(this->base_frame_no <1024){  
	
		for(i=16; i< 32 ; i++){//1024 pages of kernel = 32 *32bit reg
			for (j=0;j<32;j++){
				if((bitmap_reg[i]& (1<<j)) == 0)
				{
				   Console::puts("\nin kernel frame\n");
				   Console::putui(32*i+j);
				   Mark_Frames( (32*i+j), MARK_USED);
				   return (32*i+j); 				
				}     
				
        }
	}
}
                
	else {  
	
		for(i=32; i< 256 ; i++){//4MB to 32 MB
			for (j=0;j<32;j++){
				if((bitmap_reg[i]& (1<<(j))) == 0)				
				{
				   Console::puts("in process get frame\n");
				   Mark_Frames( (32*i+j), MARK_USED);
				   return (32*i+j); 				
				}     
				
				}
       				 }
	}       
   }

void FramePool::Mark_Frames(unsigned long int _info_frame_no, int flag){
	int reg = _info_frame_no/32;	
	int bit_pos = _info_frame_no %32;
		
	if(flag==MARK_USED)
	bitmap_reg[reg]= (bitmap_reg[reg] | (1<<bit_pos));

	else if (flag==MARK_AVAILABLE)
	bitmap_reg[reg]= (bitmap_reg[reg] & (~(1<<bit_pos)));

}


void FramePool::mark_inaccessible(unsigned long _base_frame_no,
 	                          unsigned long _nframes) {

        for (unsigned long i = 0; i < _nframes; i++) {
                   Mark_Frames(base_frame_no+i, MARK_USED);
        }
}



void FramePool::release_frame(unsigned long _frame_no) {
        Mark_Frames(_frame_no, AVAILABLE);
}


