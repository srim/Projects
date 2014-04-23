#!/usr/bin/python
from sys import argv

script, filename = argv #script is ./analyze.py

# log = open(filename)

# line = log.readline()

# print line

class data:
	def __init__(self,name, addr,cycle):
		self.name=name
		self.addr=addr
		self.cycle=cycle
	
	def	__le__(self,other):
		if(self.addr<=other.addr):
			return True;
		else:
			return False;

	def	__lt__(self,other):
		if(self.addr<other.addr):
			return True;
		else:
			return False;
			
datalist=[]		
throughput=0.0;
with open(filename) as log:
	for line in log:
		if(line[0]=='<'):
			splited_line = line.split(',')
			CPU = str(splited_line[0])
			addr = int(splited_line[1],16)
			cycle = int(splited_line[2])
			tmp_data = data(CPU,addr,cycle)
			datalist.append(tmp_data)
			# print tmp_data.name
		if(line[0]=='L' and line[1]=='O' and line[2]=='G'):
			splited_line = line.split(' ')
			if(line[9]==' '):
				# print splited_line[4]
				throughput=float(splited_line[4])

datalist.sort()
latency=0
sum_latency=0
avg_latency=0
total_num=0

outf = open('edited_'+filename,'w')
# for d in range(0,len(datalist)):
	# print datalist[d].name,datalist[d].addr,datalist[d].cycle
for d in range(0,len(datalist)-1):	
	# print datalist[d].name,datalist[d].addr,datalist[d].cycle
	if(datalist[d].addr==datalist[d+1].addr):
		outf.write(datalist[d].name+str(datalist[d].addr)+' '+str(datalist[d].cycle)+'\n')
		outf.write(datalist[d+1].name+str(datalist[d+1].addr)+' '+str(datalist[d+1].cycle)+'\n')
		# print datalist[d].name,datalist[d].addr,datalist[d].cycle
		# print datalist[d+1].name,datalist[d+1].addr,datalist[d+1].cycle
		latency=datalist[d+1].cycle-datalist[d].cycle
		total_num=total_num+1
		if(latency>0):
			sum_latency+=latency
		else:
			sum_latency-=latency
			
avg_latency = (sum_latency*1.0)/total_num
outf.write('avg_latency:'+str(avg_latency)+'\n');
outf.write('throughput:'+str(throughput)+'\n');
outf.write('packet_number:'+str(total_num)+'\n');
outf.close()
# print "avg_latency:%d",avg_latency
# print "packet number:%d",total_num
			
