/*
    File: page_table.C

    Author: Sridhar M
            Department of Electrical and Computer Engineering
            Texas A&M University
    Date  : 

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
PageTable    *PageTable::current_page_table;
unsigned long   PageTable::shared_size;        /* size of shared address space */
FramePool	* PageTable::kernel_mem_pool;    /* Frame pool pointer for kernel memory */
FramePool     * PageTable::process_mem_pool;   /* Frame pool pointer for the process memory */



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
        unsigned long * page_table = (unsigned long *) (kernel_mem_pool->get_frame() * PAGE_SIZE);

	/* set the base address as zero */
        unsigned long address = 0;
	unsigned int i;


        /* map the first 4MB of memory as present */
        for(i=0; i<PAGE_TABLE_ENTRIES; i++)
        { 
	/* attribute set to: supervisor level, read/write, present(011 in binary)    */
	page_table[i] = address | 3; 
	address = address + 4096; // 4096 = 4kb
        }

       /* fill the first entry of the page directory */
	page_directory[0] =(unsigned int) page_table; 
	/* attribute set to: supervisor level, read/write, present(011 in binary) */
	page_directory[0] = page_directory[0] | 3;


        /* fill the rest of 1023 entries of page directory as not present */
        for(i=1; i<ENTRIES_PER_PAGE; i++)
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



void PageTable::handle_fault(REGS * _r) {

	/* read the lower 3 bits of error code */
        int error_code = _r->err_code & 7;
	/* read the 32-bit address that caused the page fault from CR2 register */
        unsigned long address = read_cr2();

        
	/*  Bit0 = 0 --> PAGE NOT PRESENT */
       // if ((error_code & 1) == 0) {            

                unsigned long * page_table;
                unsigned long * page_dir = current_page_table->page_directory;
                unsigned long pageDirIndex = (address & DIRECTORY_MASK) >> 22;
                unsigned long pageTableIndex = (address & PAGE_TABLE_MASK) >> 12;
                unsigned long * pageEntry;

                
                page_table = (unsigned long *) page_dir[pageDirIndex];

		/* page dierctory entry doesnt' exist ? */
                if (( page_dir[pageDirIndex] & 1) == 0) {
			/* Get new page table base address */
                        page_table = (unsigned long *) (kernel_mem_pool->get_frame() * PAGE_SIZE);

			/* bring all 1024 pages */
                        for(int i=0; i<PAGE_TABLE_ENTRIES; i++) {

                                unsigned long frameNo = process_mem_pool->get_frame();
                                if (frameNo == 0)
					Console::puts("OUT OF MEMORY\n");
                                pageEntry =(unsigned long *) (frameNo * PAGE_SIZE);                              
				/* make the corresponding page table entry as present */
                                page_table[i] = (unsigned long) pageEntry; /* attribute set to: user level, read/write, present(111 in binary) */
				page_table[i] |= 3;
				//Console::puts("Page table entry deosnt exist in directory"); 
                                Console::putui(i); 
                                Console::putui(frameNo); 
                        }

                                                        

                        page_dir[pageDirIndex] = (unsigned long) (page_table); // attribute set to: supervisor level, read/write, present(011 in binary)
                        page_dir[pageDirIndex] |= 3;//make the page drectory entry as present
                }



                pageEntry = (unsigned long *) page_table[pageTableIndex];
		/* Page table entry doesnt' exist */
                if ((page_table[pageTableIndex] & 1) == 0) {

                        pageEntry = (unsigned long *) (process_mem_pool->get_frame() * PAGE_SIZE);                                                      

                        page_table[pageTableIndex] = (unsigned long) (pageEntry);
                        page_table[pageTableIndex] |= 3;// mark entry as present

                }

	page_dir[pageDirIndex] = (unsigned long) (page_table); // attribute set to: supervisor level, read/write, present(011 in binary)
        page_dir[pageDirIndex] |= 3;//make the page drectory entry as present


        //}       

        /*else {
		/* error_code lsb bit set --> protection fault 
                Console::puts("PROTECTION FAULT - CANNOT OCCUR!\n");
                for(;;);
              

        }*/
}


