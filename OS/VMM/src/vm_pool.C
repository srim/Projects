#include "vm_pool.H"
#include "console.H"
#include "page_table.H"

/*VM Pool constructor */
VMPool::VMPool(unsigned long _base_address,unsigned long _size, FramePool *_frame_pool,
          PageTable *_page_table)
{
	  base_address = _base_address;
	  size = _size;
	  frame_pool = _frame_pool;	
	  page_table = _page_table;
	  vm_pool_index = 0;
	  /*Call the register vmpool function with this object and get the corresoinding frame address */
	  vm_pool = (struct vm_pool_struct *) page_table->register_vmpool(this);
	  Console::puts("\nInside VM pool constructor\n");
	  Console::putui(base_address);  
	  Console::putui(size);  
	  pool_start_address = _base_address;
	
	 
}




unsigned long VMPool::allocate(unsigned long _size){ //WRITE RETURN ZERO PART
	
	  /* Allocates a region of _size bytes of memory from the virtual
   	  * memory pool. If successful, returns the virtual address of the
    	  * start of the allocated region of memory. If fails, returns 0. */
	
	/* set the local base address to pool address initially */
	int num_of_allocated_frames = (_size/1024);

	/*set the block start address and block size */
	vm_pool[vm_pool_index].block_start_address = pool_start_address;
	vm_pool[vm_pool_index].block_size = ((num_of_allocated_frames+1)*4096);

	/*  Next the loca_base_address to next free block */	
	Console::puts("\nInside allocate \n");
	Console::putui(vm_pool_index);
        Console::putui(vm_pool[vm_pool_index].block_start_address);
	Console::putui(vm_pool[vm_pool_index].block_size);
	Console::puts("\n\n");
	
	pool_start_address = (vm_pool[vm_pool_index].block_start_address + vm_pool	[vm_pool_index].block_size);

	
	unsigned long temp= vm_pool[vm_pool_index].block_start_address;
	
	Console::puts("\n \n");	
  	
	/* Return the block start address*/
	vm_pool_index++;
Console::putui(vm_pool_index);
	return (temp);
	

   }

 

   void VMPool::release(unsigned long _start_address) {
	 /* Releases a region of previously allocated memory. The region is identified by its start 		address, which was returned when the region was allocated. */
	int i;
	for (i=0; i<511; i++) {
		if(vm_pool[i].block_start_address == _start_address) {
			vm_pool[i].block_size = 0;
			vm_pool[i].block_start_address = 0;
		}
	}
	
}
  

 bool VMPool::is_legitimate(unsigned long _address) {
	  /* Returns FALSE if the address is not valid. An address is not valid
    	   * if it is not part of a region that is currently allocated. */
	 	
	if(_address != ((unsigned long)vm_pool))
		return true;
	
	for(int i=0; i<(vm_pool_index); i++)
	{
		if ((_address >= vm_pool[i].block_start_address) && (_address <= ((vm_pool[i].block_start_address) + (vm_pool[i].block_size))))
			{
				Console::puts("\nreturning true");
				return true;
			}
		else
		{
			Console::puts("\nreturning false");
			return false;
		}
	 }	
	
 
}

