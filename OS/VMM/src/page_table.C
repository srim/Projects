/*
    File: page_table.C

    Author: Sridhar M
            Department of Electrical and Computer Engineering
            Texas A&M University
    Date  : March 08, 2014

    Description: Basic Paging.

*/

/*--------------------------------------------------------------------------*/
/* INCLUDES */
/*--------------------------------------------------------------------------*/

#include "exceptions.H"
#include "frame_pool.H"
#include "page_table.H"
#include "paging_low.H"

/*--------------------------------------------------------------------------*/
/* DEFINES */
/*--------------------------------------------------------------------------*/
PageTable    	*PageTable::current_page_table;
unsigned long   PageTable::shared_size;        /* size of shared address space */
FramePool	* PageTable::kernel_mem_pool;    /* Frame pool pointer for kernel memory */
FramePool     	* PageTable::process_mem_pool;   /* Frame pool pointer for the process memory */
VMPool 		*PageTable::vmpointer[];	/* Virtual memory pointer array */


/*--------------------------------------------------------------------------*/
/* FORWARDS */
/*--------------------------------------------------------------------------*/

/* -- (none) -- */

/*--------------------------------------------------------------------------*/
/* P A G E - T A B L E  */
/*--------------------------------------------------------------------------*/


void PageTable::init_paging(FramePool * _kernel_mem_pool,
                            FramePool * _process_mem_pool,
                            const unsigned long _shared_size){
 /* Sets the global parameters for the paging subsystem. */

     kernel_mem_pool  = _kernel_mem_pool;
     process_mem_pool = _process_mem_pool;
     shared_size      = _shared_size;
}


PageTable::PageTable() {
	/* Get the first frame and multiply by page size to get the start address of page directory */
        page_directory  = (unsigned long *) (kernel_mem_pool->get_frame() * PAGE_SIZE);

	/* Get the next free frame and multiply by page size to get the start address of page table*/
        unsigned long * page_table = (unsigned long *) (process_mem_pool->get_frame() * PAGE_SIZE);

	/* set the base address as zero */
        unsigned long address = 0;
	unsigned int i;

	/* Make the last page directory entry point to Page Directory */
        page_directory[1023]=(unsigned long )page_directory;
	
	
        /* map the first 4MB of memory as present */
        for(i=0; i<PAGE_TABLE_ENTRIES-1; i++)
        { 
	/* attribute set to: supervisor level, read/write, present(011 in binary)    */
	page_table[i] = address | 3; 
	address = address + 4096; // 4096 = 4kb
        }

	/* fill the first entry of the page directory */
	page_directory[0] =(unsigned int) page_table; 
	/* attribute set to: supervisor level, read/write, present(011 in binary) */
	page_directory[0] = page_directory[0] | 3;
	page_directory[1023]= page_directory[1023] | 3; //Make 1023 Page Directory entry


        /* fill the rest of 1023 entries of page directory as not present */
        for(i=1; i<ENTRIES_PER_PAGE-2; i++)
        {
		/* attribute set to: supervisor level, read/write, not present(010 in binary) */
                page_directory[i] = 0 | 2; 
        }  
}




void PageTable::load() {
	/* Assign the current object to current-page_table */
        current_page_table = this;
}




/* write_cr3, read_cr3, write_cr0, and read_cr0 all come from the assembly functions */
void PageTable::enable_paging() {

	/* put that page directory address into CR3 */
        write_cr3((unsigned long)(current_page_table->page_directory)); 
	/* set the paging bit in CR0 to 1 */
        write_cr0(read_cr0() | 0x80000000);
}


/* Register pool gets current vm_pool object */
unsigned long PageTable::register_vmpool(VMPool *_pool) {

	//Console::puts("\n Inside Register vmpool\n");
	static int pool_count = 0;
   //The page table needs to know about where it gets its pages from.
    // For this, we have VMPools register with the page table.
	vmpointer[pool_count] = _pool;
	pool_count++; // increment pool_count whenever a new pool is created
	return (kernel_mem_pool->get_frame() * 4096); //return the frame address
} 


void PageTable::handle_fault(REGS * _r) {
	
	/* read the lower 3 bits of error code */
        int error_code = _r->err_code & 7;
	/* read the 32-bit address that caused the page fault from CR2 register */
        unsigned long address = read_cr2();


	
	/*  Bit0 = 0 --> PAGE NOT PRESENT */
       if ((error_code & 1) == 0) {    
	
	//Console::puts("\n inside page fault \n");

		/* For each address in code and heap pool check if address is legitimate */
		
		for (int i=0; i<2; i++) {
			if((current_page_table->vmpointer[i]->is_legitimate(address)) == TRUE) {
				Console::puts("\n Legitimate passed \n");
				break;
			}
			else {
				Console::puts("\n Is Legitimate returning false\n");
				while(1);
			}          
		}

		

		//Console::putui(address);
			             
                unsigned long * page_table;
                unsigned long * page_dir = current_page_table->page_directory;
                unsigned long pageDirIndex = (address & DIRECTORY_MASK) >> 22;
                unsigned long pageTableIndex = (address & PAGE_TABLE_MASK) >> 12;
                unsigned long * pageEntry;
		unsigned long *virtual_address = (unsigned long*) (0xfffff000 | (pageDirIndex<<2));
               	unsigned long *virtual_address2 = (unsigned long*) (0xffc00000 | ( pageDirIndex<<12) | (pageTableIndex <<2));
		
		//Console::putui(pageDirIndex);

		/* page dierctory entry doesnt' exist ? */


		if(((*virtual_address) & 1) == 0){
			page_table = (unsigned long *) (process_mem_pool->get_frame() * PAGE_SIZE);
			*virtual_address = (unsigned long) page_table;
			*virtual_address |= 0x03;

			unsigned long *virtual_address3 = (unsigned long*) (0xffc00000 | ( pageDirIndex<<12));
			
			for(int i=0; i<1024; i++)
			page_table[i] |= 0x02;
		}
		
		
			//Console::puts("\nInside virtual address_2\n");
			
			unsigned long frame = (unsigned long) (process_mem_pool->get_frame() * PAGE_SIZE);
			*virtual_address2 = (unsigned long)frame;
			*virtual_address2 |= 0x03;
			//Console::puts("\nInside vaddr outside \n");	
	}
	else
	{
	/* error_code lsb bit set --> protection fault */
                Console::puts("PROTECTION FAULT - CANNOT OCCUR!\n");
                for(;;);
	}
              		


}


