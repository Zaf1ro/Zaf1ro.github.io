---
title: CS520-homework6
category:
  - Homework
tag:
  - Homework
abbrlink: 1307290456
date: 2017-11-21 14:10:48
---

##### Name: Jiaxu Duan
##### ID: 10427009

#### Q1
* processing delay
    * number of interrupts:
        * sender issues a system call to write a data packet: 1msec
        * recevier get the last bit of packet: 1msec
    * copy byte: 
        * sender's OS copies data to a keneral buffer: 1024usec
        * sender's OS copies data to the network controller board: 1024usec
        * recevier's OS copies arrived packet to a kernel buffer: 1024usec
        * receiver's OS copies data to the user space: 1024usec
* trasmission delay: 1024byte/(10Mb/s)=0.82msec
* propagation delay: 1msec

total time of transitting a packet: 1msec\*2+1024\*4usec+0.82msec+1msec=6.93msec
rate of data: 1024byte/15.096msec=(1.024\*10^-3MB)/(6.93\*10^-6sec)=147.76kB/s
percent: (147.76kB/s)(10Mb/s)=11.8%


#### Q2
time of one interrupt: 34\*10\*2=680usec
number of interrupts: 1sec/(680*10^-9)sec=1470588


#### Q3
1. inteleaving:
number of rotation: 7/8\*3+0.5=2.625+0.5=3.125
rotation rate: 300round/min=5round/sec
time of reading all sectors: 3.125\*(1/5)=0.625sec
data rate: 512\*8/0.625=6553.6bytes/sec
2. without interleaving:
number of rotation: 7/8+0.5=1.375
time of reading all sectors: 1.375\*0.2=0.275sec
data rate: 512\*8/0.275=14894.545bytes/sec
3. data rate degrade:
Data rate degrade: 14894.545-6553.6=8340.945bytes/sec
Degrade percent: 8340.945/6553.6=127.27%


#### Q4
algorithm | 1 | 2 | 3 | 4 | 5 | 6 | 7 | result
----|-----|-----|-----|-----|----|-----|----|----
FCFS | 20-10=10 | 22-10=12 | 22-20=2 | 20-2=18 | 40-2=38 | 40-6=34 | 38-6=32 | 146\*6=876msec
SSTF | 20-20=0 | 22-20=2 | 22-10=12 | 10-6=4 | 6-2=4 | 38-2=36 | 40-38=2 | 60\*6=360msec
SCAN | 20-20=0 | 22-20=2 | 38-22=16 | 40-38=2 | 40-10=30 | 10-6=4 | 6-2=4 | 58\*6=348msec


#### Q5
Because we can use arbitrarily long name and any printable character, so we can combine the directory name and filename together and take it as filename. Such as Java file named "tools.jar" in Linux, we can rewrite the filename as "/usr/lib/tools.jar" in Stupido v1.0


#### Q6
blocks of direct address = 10
block of Indirect address = 1024/4 = 256
Size of all = 10\*1MB + 256\*1MB = 266MB


#### Q7 
1. 1111 1111 1111 0000
2. 1000 0001 1111 0000
3. 1111 1111 1111 1100
4. 1111 1110 0000 1100


#### Q8
Yes, It is possible that for some particular block number the counters in both lists have the value 2. Such as below:
1. One process detects that block A is free(Because counter in free list is 1). So the process use A and add counter in used list, but didn't change counter which is in free block list to 0. So counter in used blocks list should be 1, and counter in free blocks list should be 1.
2. Another process detects that A is free as same, and didn't change counter in free list. So counter in free list should be 1, and counter in used list should be 2.
3. When the second process free process, it increases counter to 2 in free list. And before it decreases coutner in used list, operating system crashed. so counter in free list should be 2, and counter in used list should be 2.

How should this problem be corrected: We should set counter in free list to 0, and set counter in used list to 1.


#### Q9
UNIX uses Index Nodes to connect file name and block of disk. Each file has a table called i-node, and the table has file's attribute and addresses of blocks. When you open a file, Operating system can load the i-node into memory and get blocks of disk from i-node.


#### Q10
Please refer to the C porgram "q10.c"
