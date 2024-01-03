---
title: RCU
category:
  - Concurrency
  - Basic
tag:
  - Concurrency
abbrlink: de50
date: 2019-07-02 19:51:07
---

## 1. Intro
Read-Copy-Update(RCU)作为一种同步机制为reader端提供了极快的读取速度和高并发性. 与RCU相同使用场景的锁应为rwlock(读写锁), 它们都适用于Reader-Writer(RCU的updater可理解为rwlock中的writer)的场景,  但也存在些许不同:
1. RCU允许多个reader和最多一个updater并发运行, rwlock只允许多个reader同时运行.
2. rwlock需要使用spinlock来确保有且只有一个writer进入critical section, RCU不需要spinlock.
3. rwlock需要counter来统计当前reader数量, RCU不需要counter.

用一张图可以更容易地理解RCU和rwlock的区别:
![RCU and rwlock](/images/multithreading/Basic/rcu-1.png)

从图上可以看出: 使用rwlock时, writer的同步极大阻碍了性能, 因为每一次writer想进入critical section都需要等待所有reader读取完毕. 且reader和writer对counter和spinlock的访问也会导致大量cache miss.
但RCU并不是完美的, RCU的使用场景比较局限, 主要适用于以下几个场景:
1. RCU只能保护动态分配的数据结构, 必须通过指针来访问该数据结构
2. 受RCU保护的critical section不能sleep(Sleepable RCU暂不讨论)
3. 读写不对称, 对updater性能无要求, 但对reader要求极高(读多写少)
4. reader对新旧数据不敏感


## 2. RCU Implementation
RCU涉及的数据有两种: 一个是指向要保护数据的指针, 称为RCU protected pointer. 另外一个是通过指针访问的共享数据, 称为RCU protected data. Reader始终通过RCU protected pointer来访问RCU protected data. 当Updater需要修改RCU protected data时可以先创建一个副本, 然后将RCU protected pointer指向新的副本. 由于指针赋值是原子操作, 所以不需要锁. 整个RCU update分为两部分:
1. Removal: updater分配一个RCU protected data并更新数据, 更新完毕后将RCU protected pointer指向新副本, 这之后的reader读取的都将是最新数据. 图中Reader 0和1读取的是旧数据, Updater此时修改了pointer指向, 因此reader 2和3读取的都是新数据.
2. Reclamation: RCU是一个等待事物结束的方式. 当RCU protected pointer不再指向旧数据时, 需要寻找时机来回收旧数据. 首先不能立即回收, 因为可能还有reader在使用旧数据; 其次不能太晚回收, 因为大量的update会产生大量旧数据, 从而导致内存占用严重. 最完美的回收时间应为旧数据最后一个reader退出的时间, 也就是说没有reader在访问旧数据. 从RCU protected pointer转移到最后一个reader离开旧数据的等待时间称为grace period.


## 3. RCU Synchronize
整个RCU的实现中最难的一部分就是判断grace period的结束, 内核中实现的函数为`synchronize_rcu()`.
![Grace Period](/images/multithreading/Basic/rcu-2.png)

`synchronize_rcu()`会等待所有已经进行的reader完成读取, 不会等待函数调用之后的reader, 例如:

|   | CPU 0 | CPU 1 | CPU 2 |
|:-:|:-----:|:-----:|:-----:|
| 0 | rcu_read_lock()   |                         |                   | 
| 1 |                   | enter synchronize_rcu() |                   |
| 2 |                   |                         | rcu_read_lock()   | 
| 3 | rcu_read_unlock() |                         |                   | 
| 4 |                   | exit synchronize_rcu()  |                   |
| 5 |                   |                         | rcu_read_unlock() |

### 3.1 Read-side
在Tree RCU的实现中, rcu_read_lock和rcu_read_unlock的实现非常简单，分别是关闭抢占和打开抢占:
```cpp
static inline void __rcu_read_lock(void)
{
  preempt_disable();
}
 
static inline void __rcu_read_unlock(void)
{
  preempt_enable();
}
```
RCU的reader不允许critical section被block, 所以reader进入critical section之前会将该CPU设置为non-preemptive(非抢占模式), 离开critical section将CPU重新设置为preemptive(抢占模式). 所以如果每个CPU都发生过抢夺, 说明不在rcu_read_lock和rcu_read_unlock之间.

### 3.2 Quiescent State
reader的critical section之外的时间都称之为quiescent state, RCU在CPU进入quiescent state后会调用回调函数标记该CPU已退出critical section. 为避免抢夺某个全局变量来统计所有CPU都进入过quiescent state, RCU使用Tree RCU来减轻竞争. 
![Tree RCU](/images/multithreading/Basic/rcu-3.png)

Tree RCU使用rcu_node节点来管理CPU: 假设有4个CPU, rcu_node1管理CPU1和CPU2，rcu_node2管理CPU3和CPU4, 再用一个rcu_node3作为根节点管理rcu_node1和2. 当CPU1和CPU2经历quiescent state后清除rcu_node1中的对应位，CPU3和CPU4经历经历quiescent state后清除rcu_node2中的对应位。rcu_node1和rcu_node2中的对应位都清除后，就可以清除增加的rcu_node3中的对应位.
