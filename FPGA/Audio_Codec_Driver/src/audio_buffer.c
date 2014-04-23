#include "xac97.h"
#include "audio_samples.h"
#include "irq_test.h"

#include "/homes/grad/sridharm/ecen449/lab9/microblaze_0/include/xparameters.h"
         


#define PHY_ADDR XPAR_OPB_AC97_CONTROLLER_REF_0_BASEADDR
#define MEMSIZE XPAR_OPB_AC97_CONTROLLER_REF_0_HIGHADDR - XPAR_OPB_AC97_CONTROLLER_REF_0_BASEADDR

void * virt_addr; 
static struct file_operations fops = {
  .read = device_read,
  .write = device_write,
  .open = device_open,
  .release = device_release,
  .ioctl = device_ioctl
};


int my_init(void)
{
  printk(KERN_INFO "MAPPING VIRTUAL ADDRESS\n");
  virt_addr = ioremap(PHY_ADDR,MEMSIZE);  

  init_waitqueue_head(&queue);	/* initialize the wait queue */

  /* Initialize the semaphor we will use to protect against multiple
     users opening the device  */
  sema_init(&sem, 1);

  Major = register_chrdev(0, DEVICE_NAME, &fops);
  if (Major < 0) {		
    printk(KERN_ALERT "Registering char device failed with %d\n", Major);
    return Major;
  }
  printk(KERN_INFO "Registered a device with dynamic Major number of %d and virt_addr = %d\n", Major,(unsigned int)virt_addr);
  printk(KERN_INFO "Create a device file for this device with this command:\n'mknod /dev/%s c %d 0'.\n", DEVICE_NAME, Major);

  return 0;		/* success */
}

/*
 * This function is called when the module is unloaded, it releases
 * the device file.
 */
void my_cleanup(void)
{
  /* 
   * Unregister the device 
   */
  unregister_chrdev(Major, DEVICE_NAME);
  printk(KERN_ALERT "Unmapping Virtual Address Space...\n");
  iounmap((void*)virt_addr);
}


/* 
 * Called when a process tries to open the device file, like "cat
 * /dev/irq_test".  Link to this function placed in file operations
 * structure for our device file.
 */
static int device_open(struct inode *inode, struct file *file)
{
  int irq_ret;

  if (down_interruptible (&sem))
	return -ERESTARTSYS;	

  /* We are only allowing one process to hold the device file open at
     a time. */
  if (Device_Open){
    up(&sem);
    return -EBUSY;
  }
  Device_Open++;
  
  /* OK we are now past the critical section, we can release the
     semaphore and all will be well */
  up(&sem);
  

  /* Initialize the audio codec */
  XAC97_InitAudio(virt_addr,0);

  /** Enable VRA Mode **/
  XAC97_WriteReg(virt_addr, AC97_ExtendedAudioStat, AC97_EXTENDED_AUDIO_CONTROL_VRA);
   /* Set Playback rate */
  //XAC97_WriteReg(virt_addr,AC97_PCM_DAC_Rate, AC97_PCM_RATE_11025_HZ);
  XAC97_WriteReg(virt_addr,AC97_PCM_DAC_Rate0, AC97_PCM_RATE_11025_HZ);
  
  XAC97_WriteReg(virt_addr, AC97_AuxOutVol, AC97_VOL_MAX);
 
  /* request a fast IRQ and set handler */ 
  irq_ret = request_irq(IRQ_NUM, irq_handler, 0 /*flags*/ , DEVICE_NAME, NULL);
  if (irq_ret < 0) {		/* handle errors */
    printk(KERN_ALERT "Registering IRQ failed with %d\n", irq_ret);
    return irq_ret;
  }
  try_module_get(THIS_MODULE);	/* increment the module use count
				   (make sure this is accurate or you
				   won't be able to remove the module
				   later. */
  
  msg_Ptr = NULL;
  printk(KERN_ALERT "RANDOM PRINT \n");
  return 0;
}

/* 
 * Called when a process closes the device file.
 */
static int device_release(struct inode *inode, struct file *file)
{
  Device_Open--;		/* We're now ready for our next caller */
  
  XAC97_ClearFifos(CLEAR_PLAYBACK_FIFO);
  XAC97_SoftReset(virt_addr);
  free_irq(IRQ_NUM, NULL);
  /* 
   * Decrement the usage count, or else once you opened the file,
   * you'll never get get rid of the module.
   */
  //kfree(msg_queue);
  module_put(THIS_MODULE);
  
  return 0;
}

static ssize_t device_read(struct file *filp,	/* see include/linux/fs.h   */
			   char *buffer,	/* buffer to fill with data */
			   size_t length,	/* length of the buffer     */
			   loff_t * offset)
{
   
   /* not allowing writes for now, just printing a message in the
     kernel logs. */
  printk(KERN_ALERT "Sorry, READ operation isn't supported.\n");
  return -EINVAL;		/* Fail */
}

/*  
 * Called when a process writes to dev file: echo "hi" > /dev/hello 
 * Next time we'll make this one do something interesting.
 */
static ssize_t device_write(struct file *filp, const char *buff, size_t len, loff_t * off)
{

    /* not allowing writes for now, just printing a message in the
     kernel logs. */
  printk(KERN_ALERT "Sorry, WRITE operation isn't supported.\n");
  return -EINVAL;		/* Fail */
}

static int device_ioctl(struct inode *inode ,struct file * file, unsigned int cmd, unsigned int *val_ptr) 
{

  u16 val;
  get_user(val,(u16 *)val_ptr);

  switch(cmd)
  {
	case ADJUST_AUX_VOL:
	printk("inside aux volume \n");
	XAC97_WriteReg(virt_addr, AC97_AuxOutVol, val);
	break;
	
	case ADJUST_MAST_VOL:
	printk("inside mast volume \n");
	XAC97_WriteReg(virt_addr, AC97_MasterVol, val);
	break;
	
	case ADJUST_PLAYBACK_RATE:
	XAC97_WriteReg(virt_addr, AC97_PCM_DAC_Rate, val);	
	break;

	default:
	printk(KERN_INFO "Unsupported control command\n");
	return -EINVAL;
   }
   return 0;
}


irqreturn_t irq_handler(int irq, void *dev_id) {
  static int counter = 0;	/* keep track of the number of
  				   interrupts handled */
  static int i=0;

  while(XAC97_isInFIFOFull(virt_addr)!=1)
  {
	XAC97_WriteFifo(virt_addr, audio_samples[i]);
	XAC97_WriteFifo(virt_addr, audio_samples[i]);
	i++;
	if(i==NUM_SAMPLES)
		i=0;
  }
  sprintf(msg, "IRQ Num %d called, interrupts processed %d times\n", irq, counter++);
  msg_Ptr = msg;

  wake_up_interruptible(&queue);   /* Just wake up anything waiting
				      for the device */
  return IRQ_HANDLED;
}

/* These define info that can be displayed by modinfo */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Paul Gratz and Others");
MODULE_DESCRIPTION("Module which creates a audio device driver and allows user interaction with it");

/* Here we define which functions we want to use for initialization
   and cleanup */
module_init(my_init);
module_exit(my_cleanup);
