VMPool 		*PageTable::vmpointer[];	/* Virtual memory pointer array */
unsigned long PageTable::register_vmpool(VMPool *_pool) {
    // For this, we have VMPools register with the page table.
