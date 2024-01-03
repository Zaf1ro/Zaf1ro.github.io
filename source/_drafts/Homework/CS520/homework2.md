---
title: CS520-homework-2
category:
  - Homework
tag:
  - Homework
abbrlink: 3592308730
date: 2017-09-26 16:47:30
---

NAME: Jiaxu Duan
CWID: 10427009

#### 1. Prove formally that the Shortest Job First scheduling algorithm is optimal in that it minimizes the average waiting time.
Suppose we have N processes which have to be scheduled. And arrangement of them is primarily random: {P<sub>0</sub>, P<sub>1</sub>, P<sub>2</sub>......}. 
If we use other sheduling algorithm, The average waiting time will be T1(T1 is uncertainty). T1=(M<sub>0</sub>)+(M<sub>0</sub>+M<sub>1</sub>)+......+(M<sub>0</sub>+M<sub>1</sub>+...+M<sub>n-1</sub>), M<sub>i</sub>is the waiting time of number i+1 process.
If M<sub>i</sub> is sorted in asending order, we can get the waiting time order like this: M<sub>k0</sub>, M<sub>k1</sub>...M<sub>kn-1</sub>. By Shortest Job Scheduling algorthim, T2=(M<sub>k0</sub>)+(M<sub>k0</sub>+M<sub>k1</sub>)+......+(M<sub>k0</sub>+M<sub>k1</sub>+...+M<sub>k(n-1)</sub>), M<sub>i</sub>.
Because each addend in T2 is smaller or equal to the addend in T1, T2 should be the lowest number of T1. And Shoetest Job Scheduling Algorthim is optimal.


#### 2. P 5.12
1. Draw four Gantt charts that illustrate the execution of these processes using the following scheduling algorithms

* FCFS

Time | 10ms | 11ms | 13ms | 14ms | 19ms
-----|-----|-----|----|----|-----
P<sub>1</sub> | out | | | |
P<sub>2</sub> | | out | | |
P<sub>3</sub> | | | out | |
P<sub>4</sub> | | | | out |
P<sub>5</sub> | | | | | out

* SJF

Time | 1ms | 2ms | 4ms | 9ms | 19ms
-----|-----|-----|----|----|-----
P<sub>2</sub> | out | | | |
P<sub>4</sub> | | out | | |
P<sub>3</sub> | | | out | |
P<sub>5</sub> | | | | out |
P<sub>1</sub> | | | | | out

* nonpreemptive priority

Time | 1ms | 6ms | 16ms | 18ms | 19ms
-----|-----|-----|----|----|-----
P<sub>2</sub> | out | | | |
P<sub>5</sub> | | out | | |
P<sub>1</sub> | | | out | |
P<sub>3</sub> | | | | out |
P<sub>4</sub> | | | | | out

* RR

Time | 1ms | 2ms | 3ms | 4ms |5ms | 6ms | 7ms | 8ms | 9ms | 10ms | 11ms | 12ms | 13ms | 14ms | 15ms | 16ms | 17ms | 18ms | 19ms 
-----|-----|-----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----
P<sub>1</sub> | out | | | | | out | | | out | | out | | out | | out | out | out | out | out 
P<sub>2</sub> | | out | | | | | | | | | | | | | | | | |
P<sub>3</sub> | | | out | | | | out | | | | | | | | | | | |
P<sub>4</sub> | | | | out | | | | | | | | | | | | | | |
P<sub>5</sub> | | | | | out | | | out | | out | | out | | out | | | | |

2. What is the turnaround time of each process for each of the scheduling algorithms in part a

* FCFS
P1 = 10
P2 = 11
P3 = 13
P4 = 14
P5 = 19

* SJF
P1 = 19
P2 = 1
P3 = 4
P4 = 2
P5 = 9
* nonpreemptive priority
P1 = 16
P2 = 1
P3 = 18
P4 = 19
P5 = 6

* RR
P1 = 19
P2 = 2
P3 = 7
P4 = 4
P5 = 14

3. What is the waiting time of each process for each of these scheduling algorithms

* FCFS
P1 = 0
P2 = 10
P3 = 11
P4 = 13
P5 = 14

* SJF
P1 = 9
P2 = 0
P3 = 2
P4 = 1
P5 = 4

* nonpreemptive priority
P1 = 6
P2 = 0
P3 = 16
P4 = 18
P5 = 1

* RR
P1 = 9
P2 = 1
P3 = 5
P4 = 3
P5 = 9

4. Which of the algorithms results in the minimum average waiting time

* FCFS
(0+10+11+13+14)/5=9.6
* SJF
(9+0+2+1+4)/5=3.2
* nonpreemptive priority
(6+0+16+18+1)/5=8.2
* RR
(9+1+5+3+9)/5=5.4
So SJF use the minimun average waiting time.


#### 3. P 5.3
1. What is the average turnaround time for these processes with the FCFS scheduling algorithm?
P1 = 8
P2 = 12-0.4 = 11.6
P3 = 13-1 = 12
P<sub>avg</sub> = (8+11.6+12)/3=10.53

2. What is the average turnaround time for these processes with the SJF scheduling algorithm
P1 = 8
P2 = 13-0.4 = 12.6
P3 = 9-1 = 8
P<sub>avg</sub> = (8+12.6+8)/3=9.53

3. Compute what the average turnaround time will be if the CPU is left idle for the first 1 unit and then SJF scheduling is used
P1 = 14
P2 = 6-0.4 = 5.6
P3 = 2-1 = 1
P<sub>avg</sub> = (14+5.6+1)/3=6.87


#### 4. What is the effect of this seating policy on large parties? If parties are seated strictly in the order in which they arrive, how will this affect the utilization of the table?
The seating policy will cause many empty seats which can not be used. For example, if there comes three person, and the second person leaves soon. The fourth person cannot sit on the seat which the second person just sat. In short, people who comes into this restaurant only can sit behind the last people's seat, he cannot bypass the people before him. 


#### 5. Please explain how this could happen and suggest a working solution
When two waiters turn on the red light simultaneously, They will not notice each other. So they both will enter the tunnel, a collusion occurs.
The solution which offered from manager is just like `Peterson solution`. Red light is like `turn`, but he didn't add `flag[n]` to this solution. He can add a green color light and its switch on the each side. When someone want to enter tunnel, he should turn on the red light and green light. So both side's red light and the other side's green light will be on. No other people can enter the tunnel.


