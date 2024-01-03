---
title: CS520-homework-1
category:
  - Homework
tag:
  - Homework
abbrlink: 1326913088
date: 2017-09-19 16:47:30
---

NAME: Jiaxu Duan
CWID: 10427009

#### 1. Consider modifying the Enter_Critical procedure to assign the Id of the executing process (rather than other) so that the procedure looks like that:
```cpp
void Enter_Critical (int process) /* 0 or 1 */
{
    int other;
    other = 1 – process;
    flag[process] = TRUE; /* show my interest */
    turn = process; /* grab it! */
    while (flag [other] == TRUE && turn == process);
}
```
* No more than one process may be inside the critical section. `TRUE`
* No process outside the critical section may block access to it. `TRUE`
* No process should wait forever to enter the critical section. `TRUE`

Suppose process 1 set `turn` to 1, process 0 set `turn` to 0. Then process 1 can be in critical section, and process 0 will wait until process 1 exit the critical section.


#### 2. Does the busy waiting solution work when the two processes are running on a shared-memory multiprocessor?
It does not work in a multi-processor system. Because interrupts doesn't work on a multiprocessor.


#### 3. Study the Bakery Algorithm and prove the following property.
P<sub>i</sub> is in its critical section, and P<sub>k</sub> (k!=i) has already chosen its number[k], there are two cases: 
1. P<sub>k</sub> has already chosen its number when P<sub>i</sub> does the last test before entering its critical section. 
if (number[i], i)<(number[k], k), P<sub>i</sub> can not get into cirtical section before P<sub>k</sub>. P<sub>i</sub> will move in endless cycles until condition becomes false. If P<sub>k</sub> exits from its critical section, it will get a new number again. And the number it gets must be larger than P<sub>i</sub>'s.
2. P<sub>k</sub> did not chose its number when P<sub>i</sub> does the last test before entering its critical section.
Since P<sub>k</sub> has chosen its number when P<sub>i</sub> is in its critical section, P<sub>k</sub> must chose its number later than P<sub>i</sub>. According to the algorithm, P<sub>k</sub> can only get a bigger number than P<sub>i</sub>, so (number[i],i)<number([k],k) holds.


#### 4. When a computer is being developed, it is often first simulated by a program that runs one instruction at a time. (Even multiprocessors are simulated strictly sequentially like this.) Is it possible for a race condition to occur in such situations?
No. The sequential execution not possible in race condition. Race condition occurred when there is uncoordinated concurrent access to share data and they try to change it at the same time. And in this situation, there is one instruction at a time. Thus it will not cause the race condition.


#### 5. In early literature, semaphore operations wait and signal have been respectively referred to as P and V
Because the semaphone concepts was invented by Dutch computer scientist Edsger Dijkstra. In his earliest paper, he gave `passering`(passing) as the meaning for P, and `vrijgave`(release) as the meaning for V.


#### 6. Suppose a queue in a semaphore is implemented not as a first-in-first-out (FIFO) queue, but as last-in-first-out (LIFO) stack. Show how this can result in starvation, that is a situation when a process is indefinitely queued in a semaphore and thus can never progress.
Suppose semaphore use the LIFO. If the rate at which processes pushed into stack is faster than the rate at which the processes popping from stack. the process who first pushed into stack will never get into critical section. So it will cause starvation.


#### 7. One reason semaphores are used is for mutual exclusion—that is ensuring that only one process enter a critical session to avoid race conditions. The other reason is synchronization, that is ensuring the events happen in certain sequence. The lecture specifies three semaphores mutex, empty, and full. Which ones of these are used for mutual exclusion, and which ones—for synchronization? Explain your answer.
* synchronization: empty and full
* mutual exclusion: mutex
`Empty` represents the number of empty place in queue, and `full` represents the number of elements. There two semaphores will not let other process wait. 
`mutex` is designed to ensure that only one process will be in the critical section, so it's used for mutual exclusion. It prevents two processes running in the critical section at the same time.


#### 8. Study the Bounded_Buffer problem (Section 6.6.1) carefully. Suppose the two wait statements of Figure 6.10 were reversed by the programmer [so that wait(mutex) is executed before wait(empty)]. What will happen when the buffer is full?
Suppose the buffer is full, and producer try to add an item to buffer. First, producer get the mutex, so the consumer cannot get the mutex. Then the producer detect that buffer is full, so it begin to wait until consumer comsume an item. And consumer cannot get the mutex until the producer release the mutex.


#### 9. The Sleeping-Barber Problem.
```cpp
Semaphore barber = 0;   // number of barber
Semaphore customer = 0; // number of customer who want to cut hair
Semaphore mutex = 1;    // mutex
int waiting = 0;        // number of customer who waiting to cur hair
int SEATS = N;

def Barber(){
    while(True){
        wait(customer);     // need a customer
        wait(mutex);        // mutual exclusion
        waiting-=1;         // number of customer who waiting on seats -1
        signal(barber);     // go to work 
        signal(mutex);      // release
        // cutting hair......
    }
}

def Customer(){
    while(True){
        wait(mutex);            // mutual exclusion
        if(customers < SEATS){  // enough seat for customer
            waiting+=1;  // number of customer who waiting on seats +1
            signal(customer);
            signal(mutex);      // release
            wait(barber);
            // cutting hair......
        }
        else
            signal(mutex);      // full of customers
    }
}
```


#### 10. Artists and Viewers
```cpp
Semaphore Vmutex=1;     // mutex for viewer
Semaphore Amutex=1;     // mutex for artist
int numOfViewer = 0;

def Viewer(){
    while(true){
        wait(Vmutex);       // mutex for viewer
        ++numOfviewer;      // number of viewer +1
        if(numOfViewer==1)
            wait(Amutex);   // mutex for artist
        signal(Vmutex);     // release for viewer
        // enter the room
        numOfViewer--;
        if(numOfViewer==0)  // release for artist
            signal(Amutex);
    }
}

def Artist(){
    wait(Amutex);           // mutex for artist
    // enter the room
    signal(Vmutex);         // release for viewer
}
```
