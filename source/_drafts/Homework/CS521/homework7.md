---
title: CS521-homework7
category:
  - Homework
tag:
  - Homework
abbrlink: 4217521166
date: 2017-10-26 12:23:38
---

### Jiaxu Duan
### 10427009


#### P41
If the ratio linear decrease on loss of 1 and 2 is the same. The resulting AIAD algorith, convergo will be an equal share alogorithm. But if the ratio linear decrease on loss of 1 and 2 is not same. It will not be an equal share algorithm. Because on of connection's throughput will go to 0.


#### P51
1. What are their congestion window sizes after 2200msec
Their congestion windows are 2 and 2

time(msec) | C1 window size | Sending speed | C2 window size | Sending Speed
----|----|----|----|-----
0 | 15 | 150 | 10 | 100
100 | 7 | 70 | 5 | 50
200 | 3 | 30 | 2 | 20
300 | 1 | 10 | 1 | 10
400 | 2 | 20 | 2 | 20
500 | 1 | 10 | 1 | 10
600 | 2 | 20 | 2 | 20
700 | 1 | 10 | 1 | 10
800 | 2 | 20 | 2 | 20
900 | 1 | 10 | 1 | 10
1000 | 2 | 20 | 2 | 20
1100 | 1 | 10 | 1 | 10
1200 | 2 | 20 | 2 | 20
1300 | 1 | 10 | 1 | 10
1400 | 2 | 20 | 2 | 20
1500 | 1 | 10 | 1 | 10
1600 | 2 | 20 | 2 | 20
1700 | 1 | 10 | 1 | 10
1800 | 2 | 20 | 2 | 20
1900 | 1 | 10 | 1 | 10
2000 | 2 | 20 | 2 | 20
2100 | 1 | 10 | 1 | 10
2200 | 2 | 20 | 2 | 20

2. In the long run, will these two connections get about the same share of the bandwidth of the congested link?
Yes, Becasue AIMD algorithm of TCP and they both have the same RTT

3. In the long run, will these two connections get synchronized eventually? If so, what are their maximum window sizes?
Yes, and their max window size is 2

4. Will this synchronization help to improve the utilization of the shared link? Why? Sketch some idea to break this synchronization.
No, this synchronization won't improve the link utilization. Because two connections oscillates between max window size and min window sizw. One way that can break the synchronization is to change the congestion window algorithm. We can decrease the congestion window by contant number instead of decrease by half. 


