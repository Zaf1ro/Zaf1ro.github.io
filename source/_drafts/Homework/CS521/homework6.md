---
title: CS521-homework6
category:
  - Homework
tag:
  - Homework
abbrlink: 2355459224
date: 2017-10-19 18:33:16
---

* Name: Jiaxu Duan
* CWID: 10427009


### P293 Q25 
1. Why does an application have more control of what data is sent in a segment?
Because TCP may send more than one message in a segment when application writes a single message into TCP buffer. But UDP can guarantee that application's message will be in a segment.

2. Why does an application have more control on when the segment is sent?
Because TCP have to consider achout flow control and congestion control, and UDP doesn't need that.


### P293 Q26
1. What is the maximum value of L such that TCP sequence numbers are not exhausted?
max number of sequence number = 2^32 = 4.2Gbytes
So the max number of bytes is 4.2Gbytes

2. For the L you obtain in (a), find how long it takes to transmit the file.
number of segments: 2^32/536 = 8012999
length of total header: 8012999*66 = 528857934
transmisson time: (2^32+528857934)/(155&times;1024&times;1024/8)=237.43s


### P293 Q27
1. In the second segment sent from Host A to B, what are the sequence number, source port number, and destination port number?
sequence number: 127+80=207
source port number: 302
destination port number: 80

2. If the first segment arrives before the second segment, in the acknowledgment of the first arriving segment, what is the acknowledgment number, the source port number, and the destination port number?
acknowledgement number: 127+80=207
source port number: 80
destination port number: 302

3. If the second segment arrives before the first segment, in the acknowledgment of the first arriving segment, what is the acknowledgment number?
acknowledgement number: 127

4. For each segment in your figure, provide the sequence number and the number of bytes of data; for each acknowledgment that you add, provide the acknowledgment number
A->B seq=127,size=80
A->B seq=207,size=40
B->A ack=247
A->B seq=127,size=80


### P294 Q28
Becasue the link capacity is 100Mbps, so sender A can only be 100Mbps. Host B's receive rate is 40Mbps, so the buffer will be filled up, and B will set RcvWindow to 0. Host A will stop send data until the RcvWindow>0 and repeat above.


### P295 Q37
1. How many segments has Host A sent in total and how many ACKs has Host B sent in total? What are their sequence numbers?
    1. GBN: total 9 segents sent from A: 12345 and 2345. B send 8 ack to A: 1111 and 2345. 
    2. SR: A send 6 segments to B: 12345 and 2. B send 5 ack to A: 1345 and 2
    3. TCP: A send 6 segments to B: 12345 and 2. B send 5 ack to A: 12222 and 6

2. If the timeout values for all three protocol are much longer than 5 RTT, then which protocol successfully delivers all five data segments in shortest time interval?
TCP, because TCP has fast retransmit.
