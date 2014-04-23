# include <sys/types.h>
# include <sys/stat.h>
# include <fcntl.h>
# include <sys/ioctl.h>
# include <stdio.h>
# include <unistd.h>
# include <stdlib.h>
# include "sound.h"

int main()
{

char ch;
int fd,option;
fd=open("/dev/irq_test",O_RDWR);

if(fd==-1)
{
  printf("Failed to open device! \n");
  return -1;
}

while(1)
{
  
  printf("Enter your option :\n");
  printf(" 1. MUTE \n");
  printf(" 2. Audio Min \n");
  printf(" 3. Audio Mid \n");
  printf(" 4. Audio Max \n");
  printf(" 5. Adjust PlayBack Rate to 48 KHz \n");
  printf(" 6. Adjust PlayBack Rate to 1.1025 KHz \n");
  scanf("%d", &option);

	//while(1);


  switch (option)
	{

	case 1:
  		ioctl(fd, ADJUST_AUX_VOL, AC97_VOL_MUTE);
  		sleep(5);
		break;
	case 2:
  		ioctl(fd, ADJUST_AUX_VOL, AC97_VOL_MIN);
  		sleep(5);
		break;
	case 3:
  		ioctl(fd, ADJUST_AUX_VOL, AC97_VOL_MID);
  		sleep(5);
		break;
	case 4:
  		ioctl(fd, ADJUST_AUX_VOL, AC97_VOL_MAX);
  		sleep(5);
		break;
	case 5:
  		ioctl(fd, ADJUST_PLAYBACK_RATE, AC97_PCM_RATE_48000_HZ);
  		sleep(10);
		break;
	case 6:
  		ioctl(fd, ADJUST_PLAYBACK_RATE, AC97_PCM_RATE_11025_HZ);
		sleep(10);
		break;
	default:
		printf(" Invalid option - Try again ");
		break;
	}
}

close(fd);
return 0;
}
