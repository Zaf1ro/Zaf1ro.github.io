---
title: Deadlock
category:
  - Concurrency
  - Basic
tag:
  - Concurrency
abbrlink: 2e0d
date: 2019-06-03 09:21:54
---

## 1 Intro 
一方面, lock在共享内存的并发开发中承担了重要角色, 但一方面它也印发了诸多问题: deadlocks(死锁), convoying(锁封护), starvation(饥饿), unfairness(非公平锁), data races(资源争抢). 但其实解决方法也有很多:

1. 利用Lock hierarchies(锁层级)来避免deadlock
2. 使用deadlock探测工具, 例如: linux的lockdep
3. 使用对锁友好的数据结构, 例如: array, hashtable, radix tree
4. 利用恰当的synchronization mechanism来避免错误, 例如: reference counters, statistical counters, non-blocking data structures, RCU


## 2. Reason of Deadlock
当一组thread中每个thread都拥有一把锁, 且同时还在等待被同组thread占有的锁时, 会发生死锁. 本质上即thread与lock之间形成一个环.
![Deadlock Cycle](/images/multithreading/Basic/locking-1.png)

上图中, thread A拥有lock 1且想要获取lock 2, thread B拥有lock 2和lock 4且想获取lock 3, thread C拥有lock 3且想获取lock 4. Thread B, Thread C, lock 3, lock 4之间形成了一个环, 从而导致死锁. 如果没有外部干预, 死锁情况会一直持续. 


## 3. Locking Hierarchies
锁层级目的是让锁的获取按照一定的顺序执行. 例如给每个锁编上数字编号, 若线程没有任何锁, 则可以获得任意编号的锁; 若线程已经拥有锁, 则只能获得比锁编号更高的锁, 不可获得编号相同或更低的锁.

### 3.1 Local Locking Hierarchies
锁层级的前提是全局性, 因此很难应用于库函数. 因为库函数调用的代码无法获知, 那也就无法遵循锁编号的顺序执行. 绝大多数情况下, 库函数并不会使用到调用者的代码, 这就可以保证库函数内部的锁层级正确执行; 但有时库函数也需要运行调用者的代码, 如qsort():
![Local Locking Hierarchy for qsort()](/images/multithreading/Basic/locking-2.png)

线程1和线程2分别拥有锁1和锁2, 在调用qsort()之前必须拥有锁3, qsort()需要调用外部的cmp()函数, 而cmp()需要锁2. 假设线程1优先获得锁3, 而线程2已经获取了锁2, 这时就会发生deadlock. 虽然依照锁层级, 线程1在拥有锁3后不应去获取锁2, 但qsort()事前不知道锁2的存在, 因此锁层级失效. 为避免这种情况的deadlock, 需要在获取任何未知锁前释放已经获取的锁: 当线程1获取锁3后想要获取外部的锁2时, 应先释放锁3.

### 3.2 Layered Locking Hierarchies
若库函数无法在获取外部锁时释放内部的所有锁, 这时只能通过将锁分离成不同层来解决. 以上述qsort()为例, 将cmp()的锁剥离为单独一层. 但这通常需要从设计层面上进行改进:
![Layered Locking Hierarchy for qsort()](/images/multithreading/Basic/locking-3.png)


## 4. Conditional Locking
有时业务逻辑让程序员无法实现锁层级, 例如在网络协议栈中, 报文流双向传输. 当报文从某一层向下一层流动时, 就需要同时获得两层的锁. 由于报文的双向性, 很容易导致死锁. 例如: 报文1从物理层向链路层传输, 其获得了物理层的锁; 报文2从链路层向物理层传输, 获得了链路层的锁, 双方都无法获得对方的锁.
因此应使用`spin_trylock()`来获取锁, `spin_trylock()`只会非阻塞性的获取的一次锁, 并立即返回结果(返回0则已获取锁, 返回非0则反之)
```cpp
/* Thread 1 */
pthread_mutex_lock(&m1); 
pthread_mutex_lock(&m2);
/* process data */ 
pthread_mutex_unlock(&m2);
pthread_mutex_unlock(&m1);

/* Thread 2 */
for (; ;) { 
  pthread_mutex_lock(&m2);   
  if(pthread_mutex_trylock(&m1) == 0) /* got it */ 
      break;
  /* didn't get it */ 
  pthread_mutex_unlock(&m2);
}
/* process data */ 
pthread_mutex_unlock(&m1);
pthread_mutex_unlock(&m2);
```


## 5. Acquire Needed Locks First
Conditional Locking需要获取所有必要的锁后才能处理事务, 因此不能为了获取某个锁而释放一个已经获取的锁, 只能释放所有的锁, 然后再获取该锁. 
由于无法释放锁的特性, Two-phase locking(两段锁协议)应运而生. Two-phase locking分为两个阶段: 第一阶段期间只获得锁, 不释放锁. 第一阶段结束后应获得所有必要的锁, 从而处理事务. 第二阶段期间只释放锁, 不获取锁. 这种锁协议保证事务处理按照某个顺序执行, 虽然避免了deadlock, 但可能造成livelock.


## 6. Single-Lock-at-a-Time Designs
Locking Hierarchies和Conditional Locking都是针对嵌套锁的情况来试图避免deadlock, 但如果任何时刻线程只拥有一把锁, 则死锁就无法形成. 例如: 如果可以将事务逻辑完美分割, 每个事务分片只需要一把锁, 特定分片的线程只需获取对应该分片的锁, 这时deadlock就不可能发生.


## 7. Signal/Interrupt Handlers
由于在signal handler中调用`pthread_mutex_lock()`是非法, 所以signal handler中的deadlock并不会发生. 但绝大多数的OS kernel都允许在interrupt handler中使用锁. 当需要在interrupt handler中获取锁时, 应阻塞信号或屏蔽中断. 不幸的是, 在一些操作系统里阻塞和解除阻塞信号都属于代价昂贵的操作. 所以出于性能上的考虑, 应用程序和signal handler之间的通信通常使用无锁同步机制.
