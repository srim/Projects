obj-m := audio_test.o
audio_test-objs:= xac97.o audio_buffer.o
all :
	make -C /homes/grad/sridharm/ecen449/lab9/linux-2.6.35.7 M=$(PWD) modules
clean : 
	make -C /homes/grad/sridharm/ecen449/lab9/linux-2.6.35.7 M=$(PWD) clean
