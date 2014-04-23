/* 
    Author: Joshua Capehart
			Based on code by:
			R. Bettati
            Department of Computer Science
            Texas A&M University
			
			A thread scheduler.

*/
//#ifndef SCHEDULER_H
//#define SCHEDULER_H

/*--------------------------------------------------------------------------*/
/* DEFINES 
/*--------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------*/
/* INCLUDES 
/*--------------------------------------------------------------------------*/
#include "scheduler.H"
#include "machine.H"
#include "thread.H"
#include <cstddef>
#include "console.H"
#include <stdlib.h>
/*--------------------------------------------------------------------------*/
/* SCHEDULER
/*--------------------------------------------------------------------------*/

  Scheduler::Scheduler()
  {
	first-> next = NULL;
	first-> prev = NULL;
	last -> next = NULL;
	last -> prev = NULL;
	   
   }

void Scheduler:: yield()
   {
		   /* Called by the currently running thread in order to give up the CPU. 
			  The scheduler selects the next thread from the ready queue to load onto 
			  the CPU, and calls the dispatcher function defined in 'threads.h' to
			  do the context switch. */
			  //find 1st element in queue and call dipacth2(thread) and update pointers
			  
			  
					Thread* thread;
					/* check for empty thread queue */
					if(first==NULL)
					{
						Console::puts("\n\n...queue is empty...\n\n");
						return;
					}
					
					/* if only one thread exist*/
					if(first==last)
					{
					thread=first->thread;
					delete(first);
					first=NULL;
					//return thread;
					}
					
				/* Get the thread from queue head and call dipatch_to next thread */
					temp=first;
					thread=temp->thread;
					first=first->next;
					delete(temp);
					//return thread;
					Thread::dispatch_to(first->thread);
				
	  }
	  
	  
	  

   void Scheduler:: resume(Thread * _thread)
   {
	   /* Add the given thread to the ready queue of the scheduler. This is called
		  for threads that were waiting for an event to happen, or that have 
		  to give up the CPU in response to a preemption. */
		  add(_thread);
	}

   void Scheduler:: add(Thread * _thread)
   {
	   /* Make the given thread runnable by the scheduler. This function is called
		  typically after thread creation. Depending on the
		  implementation, this may not entail more than simply adding the 
		  thread to the ready queue (see scheduler_resume). */
	  
		
			/* Allocate Ready_Queue struct size of memory*/
			//temp=(struct Ready_Queue*)malloc(sizeof(struct Ready_Queue));
			temp = new struct Ready_Queue [sizeof(struct Ready_Queue)];		
			/* Add the current thread to queue */
			temp->thread=_thread;
			temp->next=NULL;
			
			/*if no thread exists, make first and last pointers to point to this thread and update pointers */
			if(first==NULL)
			{
				first=last=temp;
				first->prev=NULL;
				return;
			}
			else /* Add thread to queue and update pointers */
			{
				last->next=temp;
				temp->prev=last;
				last=temp;
			}
		
	
}  
	  
	  

   void Scheduler::terminate(Thread * _thread)
   {
   /* Remove the given thread from the scheduler in preparation for destruction
      of the thread. */
		
		
		/* if none thread exists, print error and return */
		if(first==NULL)
			{
				Console::puts("No Thread exists; Cannot remove");
				return;
			}

		/*If a signle thread exists, remove and return */
		else if(first==last)
		{
			first=NULL;
			Console::puts("All thread removed ");
			return;
		}

		else
			{
				//remove thread from queue and update pointers
				for(temp=first; temp<last ; temp=temp->next)
				{
                                            
					if(temp->thread	== _thread)
					{							
					   temp->prev->next = temp->next;
				   	   temp->next->prev = temp->prev;				
				   	   delete (temp);
					   yield();
				 	}
				}
			}
}


					
