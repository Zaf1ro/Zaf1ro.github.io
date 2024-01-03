---
title: CS521-homework5
category:
  - Homework
tag:
  - Homework
abbrlink: 359408930
date: 2017-10-12 18:45:13
---

* Name: Jiaxu Duan
* CWID: 10427009


### P282 Q1 
 | source port | destination port 
A->S | 4000 | 23
B->S | 4001 | 23
S->A | 23 | 4000
S->B | 23 | 4001


### P282 Q3
```text
 01010011
+01100110
---------
 10111001
+01110100
---------
100101101 -> 00101110
```
One's complement: 11010001


### P289 p10
We can add timer on each side. "Wait for ACK or NAK0" and "Wait for ACK or NAK1"
No matter ACK or packet is lost, the timer will let sender or receiver to retransmit ACK or packet.


### P290 p14
In NAK protocol, packet X can be detected only when packet X+1 is received. If sender sends packet infrequently, packet X will be recovered after a long time until packet X+1 detected. So I prefer ACK protocol for this situation.
If sender sends packet frequently, we should use NAK protocol. Because NAK can reduce the number of feedback than ACK protocol.


### P293 p24
* With the SR protocol, it is possible for the sender to receive an ACK for a packet that falls outside of its current window.
True.
* With GBN, it is possible for the sender to receive an ACK for a packet that falls outside of its current window.
True.
* The alternating-bit protocol is the same as the SR protocol with a sender and receiver window size of 1.
True.
* The alternating-bit protocol is the same as the GBN protocol with a sender and receiver window size of 1.
True.


### P301 Wireshark Lab: Exploring TCP
![TCP download file](/images/Homework/521_5_1.png)
