---
title: CS520-homework4
category:
  - Homework
tag:
  - Homework
abbrlink: 2749745780
date: 2017-10-24 18:25:09
---

#### 1. In the lecture, we noted that process trajectories (a two-process case) can travel only North or East. What condition prevented them from moving diagonally (i.e., North-East)? Under which condition could they move North-East? Could they move South-West? 
1. They can only go north or east because that's only one CPU. So there's only one instruction can be processed at one time.
2. They can go north-east when there are two CPUs for Process A and B
3. They cannot go south-west. Because process's instruction cannot go back.


#### 2. 7.15
Suppose there was a deadlock in this system, so the situation should be that each process has one resouce and wait for another one. But since there are four resources and three processes. Even every process has one resouce, there should be one process can has another resouce. So this process will return its resources when it finish.


#### 3. 7.16
Suppose:
N: sum of need<sub>i</sub>
A: sum f allocation
M: sum of max<sub>i</sub>
If there was a deadlock, A should be m. Because sum of maximun needs < m+n, N+A<m+n, and N+m<m+n, so N<n. It means there at least one process only need 0 resource(it contradicts the condition). So there shouldn't have a deadlock.


#### 4. Problem 7.20
1. content of the matrix need
p0 = (0,0,1-1,2-2) = (0,0,0,0)
p1 = (1-1,7,5,0) = (0,7,5,0)
p2 = (2-1,3-3,5-5,6-4) = (1,0,0,2)
p3 = (0,6-6,5-3,2-2) = (0,0,2,0)
p4 = (0,6-0,5-1,6-4) = (0,6,4,2)
2. Yes, it's safe. Because the `available` can satisfy p0 and p3. Once p3 release its resouce, others can run.
3. Yes it can. `Available` will be (1, 1, 0, 0). And the order of  ordering of processes will be p0, p2, p3, p1, and p4.


#### 5. 
There are three way to prevent this deadlock situation:
1. set a timer on each process
If process was locked by other process, then the timer will start to count down for random seconds. If time runs out, the process must release its lock.
2. check the deadlock
If process A was lock by other resource, it will start to find which process hold lock on the resource. If process A find  process B which hold the lock on the resource, A will find whether process B wants A's resource. If yes, process A will release its resource and let process B takes its resource.
3. check the order of lock
All processes have an order of lock. For example, if process A is trying to get lock, process B cannot try to get any lock. So each process has to be sure that the prior process has got their resource.


#### 6. Prove that the worst complexity of Banker’s Algorithm is O(n2m), where n an m are, respectively, the number of processes and the number of resource types.
n: number of processes
m: number of types of resource
Prove:
First, we have to find a process which it's `need` is less than `available`. At the worst situation, it will go through all processes. This will consume `n` steps.
Second, every time we check the relationship between `need` of process and `available` we have. We have to check each type of resource. At the worst situation, it will go through each type of resource. So this will consume `m` steps.
Finally, the two procedures above just pick one suitable process. At the worst situation, it will pick up all processes. so it will consume `n` steps.
So the complexity of Bank algorithm is (n^2)*m