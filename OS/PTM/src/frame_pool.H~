/*
    File: frame_pool.H

    Author: R. Bettati
            Department of Computer Science
            Texas A&M University
    Date  : 09/03/05

    Description: Management of the Free-Frame Pool.


*/

#ifndef _FRAME_POOL_H_                   // include file only once
#define _FRAME_POOL_H_

/*--------------------------------------------------------------------------*/
/* DEFINES */
/*--------------------------------------------------------------------------*/
#define MARK_USED 1
#define MARK_AVAILABLE 0
/* -- (none) -- */

/*--------------------------------------------------------------------------*/
/* INCLUDES */
/*--------------------------------------------------------------------------*/
#include "console.H"
/* -- (none) -- */

/*--------------------------------------------------------------------------*/
/* DATA STRUCTURES */
/*--------------------------------------------------------------------------*/

typedef char UINT8;


/*--------------------------------------------------------------------------*/
/* F r a m e   P o o l  */
/*--------------------------------------------------------------------------*/

class FramePool {
private:
     /* -- DEFINE YOUR FRAME POOL DATA STRUCTURE(s) HERE. */
   unsigned long base_frame_no;
   unsigned long nframes;
   unsigned long info_frame_no;
   UINT8 * free_frames;
   static unsigned long bitmap_reg[256];

public:
   static const unsigned int FRAME_SIZE = 4096;
   /* Size of a frame in bytes */

   static const int USED = 1;
   static const int AVAILABLE = 0;
   static const int MAX_FRAMES = (32 * 1024 * 1024) / (FRAME_SIZE);


   FramePool(unsigned long _base_frame_no,
             unsigned long _nframes,
             unsigned long _info_frame_no);
   /* Initializes the data structures needed for the management of this
      frame pool. This function must be called before the paging system
      is initialized.
      _base_frame_no is the frame number at the start of the physical memory
      region that this frame pool manages.
      _nframes is the number of frames in the physical memory region that this
      frame pool manages.
      e.g. If _base_frame_no is 16 and _nframes is 4, this frame pool manages
      physical frames numbered 16, 17, 18 and 19
      _info_frame_no is the frame number (within the directly mapped region) of
      the frame that should be used to store the management information of the
      frame pool. However, if _info_frame_no is 0, the frame pool is free to
      choose any frame from the pool to store management information.
      */

   unsigned long get_frame();
   /* Allocates a frame from the frame pool. If successful, returns the frame
    * number of the frame. If fails, returns 0. */

   void mark_inaccessible(unsigned long _base_frame_no,
                          unsigned long _nframes);
   /* Mark the area of physical memory as inaccessible. The arguments have the
    * same semanticas as in the constructor.
    */

   void release_frame(unsigned long _frame_no);
   /* Releases frame back to the given frame pool.
      The frame is identified by the frame number. */

   void Mark_Frames(unsigned long frame_no, int flag);
};
#endif


