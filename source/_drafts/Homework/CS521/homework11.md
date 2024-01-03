---
title: homework11
category:
  - Homework
tag:
  - Homework
abbrlink: 796008980
date: 2017-12-03 15:57:59
---


#### 1. P580 p5 
1. Will the 802.11 protocol completely break down in this situation? Discuss what happens when two stations, each associated with a different ISP, attempt to transmit at the same time.
Two APs can send data in the same channel in different time, because two APs have different SSIDs and MAC addresses. It guarantees that data can be identified by user.
But when two APs send data simultaneously, collision will happens. So it can fail to send data to user.
2. Now suppose that one AP operates over channel 1 and the other over channel 11. How do your answers change?
When two APs use two different channels, although they might send data at the same time, it doesn't lead to collision. Because data with AP is in different channel.             


#### 2. P580 p6
If the station doesn't go to step2, then it has more posibility to send next data. And it causes that other station cannot send data. So the station has to wait for a random time.


#### 3. P581 p7
Assume the transmission rate is S Mbps, then the time of transmitting a control frame and data frame are 256bits/S Mbps and 8256bits/S.
Total time: DIFS+3SIFS+3*256bits/S+8256/S


#### 4. P583 p12
Between the correspondent and original mobile user, it should has a foreign agent. When data passes through foreign agent, it has to be encapsulated by foreign agent.


#### 5. P583 p15 
Yes, two mobile nodes can use the same care-of-address. Beacuse foreign agent can decapsulates data and decide which mobile node should receive that data.


#### 6. P583 p16
Disadvantage: You have to provide MSRN to HLR once the MSRN changes
Advantage: HLR doesn't need to query VLR for your address, so it becomes faster.

