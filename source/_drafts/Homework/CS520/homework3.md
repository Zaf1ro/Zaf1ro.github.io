---
title: CS520-homework-3
category:
  - Homework
tag:
  - Homework
abbrlink: 2702800748
date: 2017-10-10 20:45:54
---

#### 1. Does the distance between the adjacent buses remain the same? If not, what should be done to ensure that it be the same?
In the most randomized condition, the adjacent buses cannot remain the same distance. But there are several way to keep the same distance:
1. If there are no person come to wait for bus, so each bus can run at a constant speed.
2. If the broading time is 0, it also can keep the buses at a constant speed.
3. If there're N stops and N buses, and each bus starts on each point. No matter the broading time and arrival rate, the distance between two will be same.
4. If one bus arrive into a stop, the posterior bus can wait for it. In this case, it can keep same distance.


### 2. What is the average size of a waiting queue at each stop
Suppose:
* number of stops: 5
* number of buses: 3
* time between any two stops: 1 min
* arrival rate: 2 person/min
* broading time: 2 seconds
* simulation time: 1 hour
T<sub>avg_num_of_waiting_queue</sub> = 6.4

1. If we change the arrival time to 3 person/min:
T<sub>avg_num_of_waiting_queue</sub> = 9.48

2. If we change the broading time to 10 seconds:
T<sub>avg_num_of_waiting_queue</sub> = 7.94

3. If we change the time between stop to 2 mins:
T<sub>avg_num_of_waiting_queue</sub> = 11.6

4. If we change the number of buses to 4:
T<sub>avg_num_of_waiting_queue</sub> = 5.66
5. If we change the number of stops to 6:
T<sub>avg_num_of_waiting_queue</sub> = 8.68


#### Conclusion:

positive correlation:
* number of stops
* time between two stops
* arrival time
* broading time

negative correlation:
* number of buses
