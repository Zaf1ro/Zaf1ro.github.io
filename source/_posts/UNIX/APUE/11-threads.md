---
title: Threads
tags:
  - Linux
category:
  - Linux
abbrlink: '1101'
date: 2019-09-23 14:25:28
keywords:
description:
---

## 1. Thread Concepts
多线程让程序可在一个进程内执行多个事务, 每个线程负责一个事务, 这么做有以下好处:
* 简化异步事件代码: 由于每个线程处理一种事件类型, 因此每个线程内使用同步编程模型. 同步编程模型处理起来更简单.
* 共享数据: 多进程共享数据需要一些操作系统提供的工具, 如shared memory和file descriptor; 线程天生就共享同一内存地址空间和file descriptor.
* 提高吞吐量: 处理多个独立任务时, 可让每个线程负责一个任务, 以更好的利用多核CPU.
* 交互式程序: 将程序拆分给多个线程, 每个线程独立处理用户的输入和输出, 当线程执行高延迟I/O操作时, 可切换到其他线程并等待I/O完成.

多核或单核系统都能利用多线程的优势, 程序可使用任意数量的线程, 不必依照CPU的数量, 因此不会影响程序设计. 只要程序执行任务时会被阻塞, 就能让其他线程先执行, 从而提高单处理器上的响应时间和吞吐量.
线程由进程内的执行上下文所需的信息组成:
* Thread ID: 进程内的线程标识
* 一组寄存器值
* Stack
* 调度优先级和调度策略
* signal mask
* errno值
* 线程特定数据

以下是同一进程中不同线程共享的资源:
* text sement: 可执行程序代码
* data segment: 全局变量
* heap
* 当前工作目录
* 用户id和组id
* file descriptor

以下是线程独占的资源:
* 线程id
* context: 寄存器值, 包括程序计数器(PC), 栈指针寄存器(SP)
* stack
* errno值
* signal mask
* 调度优先级


## 2. Thread Identification
进程的PID在整个系统中唯一, 但thread ID不同: thread ID只在单个进程内唯一, 线程结束后会回收thread ID.
Thread ID以`pthread_t`类型标识, 由于POSIX.1没有规定`pthread_t`的实现, 因此为了程序的可移植性, 不能把`pthread_t`当做integer, 也不能用`==`判断两个thread ID是否相等:
* Linux 3.2.0使用unsigned long integer表示`pthread_t`
* FreeBSD 8.0和Mac OS X 10.6.8使用指向`pthread` struct的指针表示`pthread_t`

```c
/**
 * @brief return the thread ID of the calling thread
 */
pthread_t pthread_self(void);

/**
 * @brief compares two thread identifiers
 */
int pthread_equal(pthread_t tid1, pthread_t tid2);
```
`pthread_equal()`的主要用途: 让线程识别一个data structure内附带的thread ID. 例如: 一个master thread将任务放入队列, 线程池内的worker thread从队列中取出任务. Master会在每个任务内放入一个thread ID, 因此每个任务只会被特定worker执行:
![master thread and worker thread](/images/UNIX/11-2-master-worker-thread.png)


## 3. Thread Creation
```c
#include <pthread.h>

/**
 * @brief create a new thread with attributes specified by 
 *        attr within a process. The new thread starts 
 *        execution by invoking  start_rtn() with sole 
 *        argument arg
 * @param tidp: the thread ID of the newly created thread
 * @param attr: if null, the thread is created with default 
 *        attribute
 * @return 0 on success; error number on error and the 
 *         content of tidp is undefined
 */
int pthread_create(pthread_t *tidp, const pthread_attr_t *attr, 
                   void *(*start_rtn)(void *), void *arg);
```
UNIX不保证被创建的线程和当前线程之间的运行顺序. 虽然新建的线程会继承当前线程的signal mask, 但所有pending signal都会被清理.
UNIX中每个线程都拥有各自的errno, 但pthread functions不会使用到. 因为errno是为线程内运行的程序使用, pthread functions使用return value告知caller是否调用成功.


## 4. Thread Termination
线程内调用`exit()`, `_Exit()`, `_exit()`会导致整个进程终止运行. 若只想终止单个线程, 可使用以下方法:
1. call return from the start routine, the return value is the thread's exit code
2. cancelled by another thread in the same process
3. call pthread_exit()

```c
#include <pthread.h>

/**
 * @brief terminate the calling thread and return a value 
 *        via retval that is available to another thread 
 *        that calls pthread_join(). Any clean-up handlers 
 *        established by pthread_cleanup_push() that have 
 *        not been popped are popped and executed. All the 
 *        thread-specific data will be destoried after 
 *        clean-up handlers in an unspecified order
 */
void pthread_exit(void *retval);

/**
 * @brief wait for the thread specified by thread to 
 *        terminate. If thread has already terminated, then 
 *        returns immediately
 * @param retval: if not null, the copies the exit status 
 *        of target thread into the location pointed to by 
 *        retval. If target thread was cancelled, 
 *        PTHREAD_CANCELED is placed to retval
 * @return 0 on success; error number on error.
 */
int pthread_join(pthread_t thread, void **retval);
```
由于retval的类型为无类型指针, 所以可以传入一个structure. 但需要注意: 若retval指向的变量位于stack(临时变量), 线程调用`pthread_exit()`后销毁所有线程内的数据, 导致`pthread_join()`中retval获取的数据为无效数据. 因此应使用global variable或调用`malloc()`将数据创建在heap上.

```c
#include <pthread.h>

/**
 * @brief send a cancellation request to the thread tid. 
 *        Thread can call pthread_exit() with an argument 
 *        of PTHREAD_CANCELED to terminate itself; Or a   
 *        thread can elect to ignore or control how it is 
 *        cancelled
 */
int pthread_cancel(pthread_t tid);

/**
 * @brief push rtn onto the top of the stack of clean-up 
 *        handlers
 * @param arg: the argument of rtn
 */
void pthread_cleanup_push(void (*rtn)(void *), void *arg);

/**
 * @brief remove the routine at the top od the stack of 
 *        clean-up handlers, and execute is if execute is 
 *        nonzero
 */
void pthread_cleanup_pop(int execute);
```
`pthread_cleanup_pop()`会在以下三种情况下弹出clean-up handler并执行该handler:
1. thread is cancelled
2. thread terminates itself by calling pthread_exit()
3. thread calls pthread_cleanup_pop() with a nonzero execute argument

```c
#include <pthread.h>

/**
 * @brief mark the thread identified by tid as detached. 
 *        When a detached thread terminates, its resources 
 *        are automatically released back to system
 * @return 0 on success; error number on errpr
 */
int pthread_detach(pthread_t tid);
```



## 5. Thread Synchronization
由于thread之间共享内存, 所以需要确保数据一致性. 若每个线程不对其他线程的变量进行修改, 则不存在数据一致性问题. 当一个线程会修改其他线程可能读取或修改的变量时, 就需要采取策略来实现数据一致性.
若修改数据的操作是原子性的, 则不存在**竞争**, 因而不存在数据一致性问题. 而现在计算机系统都有多核处理器, 导致每个CPU会有cache来缓存数据, 也会导致数据不一致问题依然存在.

### 5.1 Mutexes
为保证数据在某一时间只被一个thread访问, 可采用pthread mutual-exclusion interface. Mutex作为一种锁, 可保证共享数据被访问前后都有锁保护. 若其他thread想获取mutex, 则thread被block. 
```c
#include <pthread.h>

/**
 * @brief initialize the mutex referenced by mutex with 
 *        attributes specified by attr
 * @param attr: if null, the default mutex attributes are 
 *        used
 * @return 0 on success; error number on error.
 */
int pthread_mutex_init(pthread_mutex_t *mutex, 
                       const pthread_mutexattr_t *attr);

/**
 * @brief Destroy the mutex object referenced by mutex
 */
int pthread_mutex_destroy(pthread_mutex_t *mutex);
```
PTHREAD_MUTEX_INITIALIZER会创建静态mutex object, `pthread_mutex_init()`则会创建动态mutex object(调用`malloc()`创造, 需要调用`pthread_mutex_destroy()`销毁).
```c
#include <pthread.h>

/**
 * @brief The mutex object referenced by mutex shall be 
 *        locked. If the mutex is already locked, the call 
 *        will block until the mutex is unlocked.
 * @return 0 on success; error number on error.
 */
int pthread_mutex_lock(pthread_mutex_t *mutex);

/**
 * @brief equal to pthread_mutex_lock(), except that if the 
 *        mutex object referenced by mutex is currently 
 *        locked, the call shall return immediately
 * @return same as pthread_mutex_lock()
 */
int pthread_mutex_trylock(pthread_mutex_t *mutex);

/**
 * @brief unlock the mutex object referenced by mutex
 * @return same as pthread_mutex_lock()
 */
int pthread_mutex_unlock(pthread_mutex_t *mutex);
```

### 5.2 Deadlock Avoidance
单个锁造成死锁的可能性不大, 除非thread在获得mutex后继续尝试获取该mutex. 若锁的数量大于1个后, 死锁的可能性就变得很大, 例如: thread 1和thread 2都需要获取mutex A和mutex B. Thread 1已获取mutex A, 尝试获取mutex B; Thread 2已获取mutex B, 尝试获取mutex A. 若thread 1或thread 2都不打算释放已获取的mutex, 则两个thread都陷入死锁并一直等待.
避免死锁的方法之一: 控制获取锁的顺序. 若thread 1和thread 2必须在获取mutex A后才能获取mutex B, 则死锁永远不会发生. 但程序随体积变大, 锁的获取顺序不再容易控制, 这时可采用另一种策略: 若当前无法获取mutex, 则等待一段时间后再尝试获取(调用`pthread_mutex_trylock()`防止阻塞该thread).

###  5.3 pthread_mutex_timedlock Function
```c
#include <pthread.h>
#include <time.h>

/**
 * @brief lock the mutex object referenced by mutex. If the 
 *        mutex is already locked, the calling thread shall 
 *        block until the mutex becomes available. This wait
 *        shall be terminated when specified timeout tsptr 
 *        expires
 * @return 0 on success; error number on error
 */
int pthread_mutex_timedlock(pthread_mutex_t *mutex, 
                            const struct timespec *tsptr);
```
若函数超时但依然没有获得锁, 则返回ETIMEDOUT error number. 

### 5.4 Reader-Writer Lock
Reader-writer lock与mutex相似, 但提供了更好的并发性. Mutex让资源在某一时刻有且只有一个thread能够访问; Read-writer lock则允许多个reader threads同时访问资源, 但有且只有一个writer可以写入. 
虽然Reader-writer lock的实现多种多样, 但当writer试图获取锁时, 都会屏蔽新来reader获取锁的请求. 若不屏蔽新来reader的锁请求, writer可能陷入饥饿而长期无法获取资源的使用权. 
Reader-writer lock适用于大量读取但写入频率较低的情况. Reader-writer lock也被称为shared–exclusive lock, 因为reader共享资源访问, 而writer则不允许资源被其他writer或reader访问. 
```c
#include <pthread.h>

/**
 * @brief allocate any resources required to use the read-
 *        write lock referenced by rwlock and initialize 
 *        the lock to an unlocked state with attributes 
 *        referenced by attr
 * @param attr: if null, the default read-write lock 
 *        attributes shall be used
 * @return 0 on success; error number on error
 */
int pthread_rwlock_init(pthread_rwlock_t *rwlock, 
                        const pthread_rwlockattr_t *attr);

/**
 * @brief destroy the read-write lock object referenced by 
 *        rwlock and release any resources used by the lock
 */
int pthread_rwlock_destroy(pthread_rwlock_t *rwlock);
```
与mutex相同, Single UNIX Specification定义了一个宏定义: PTHREAD_RWLOCK_INITIALIZER用于创建静态的rwlock.
```c
#include <pthread.h>

/**
 * @brief apply a read lock to the read-write lock 
 *        referenced by rwlock. If there's no writer hold 
 *        the lock and no writer blocked on the lock, the 
 *        calling thread acquires the read lock
 */
int pthread_rwlock_rdlock(pthread_rwlock_t *rwlock);

/**
 * @brief apply a write lock to the read-write lock 
 *        referenced by rwlock. If there's no reader and 
 *        writer holds the lock, the calling thread acquires
 *        the writer lock
 */
int pthread_rwlock_wrlock(pthread_rwlock_t *rwlock);

/**
 * @brief release a lock held on the read-write lock object 
 *        referenced by rwlock. 
 */
int pthread_rwlock_unlock(pthread_rwlock_t *rwlock);
```
 
Single UNIX Specification还定义了以下函数用于防止死锁发生:
```c
#include <pthread.h>

/**
 * @brief apply a read lock but never block
 * @return 0 on success; EBUSY if a writer holds the lock 
 *         or a writer blocked on it
 */
int pthread_rwlock_tryrdlock(pthread_rwlock_t *rwlock);

/**
 * @brief apply a write lock but never block
 * @return same as pthread_rwlock_tryrdlock()
 */
int pthread_rwlock_trywrlock(pthread_rwlock_t *rwlock);
```
Single UNIX Specification还提供了带超时功能的reader-writer locks, 可用于防止为了获取rwlock而陷入无限的阻塞
```c
#include <pthread.h>
#include <time.h>

/**
 * @brief apply a read lock to the read-write lock 
 *        referenced by rwlock. If the lock cannot be 
 *        acquire, this wait shall be terminated when the 
 *        specified timeout tsptr expires.
 */
int pthread_rwlock_timedrdlock(pthread_rwlock_t *rwlock, 
                               const struct timespec *tsptr);

/**
 * @brief apply a write lock to the read-write lock 
 *        referenced by rwlock. If the lock cannot be 
 *        acquired, this wait shall be terminated when the 
 *        specified timeout expires
 */
int pthread_rwlock_timedwrlock(pthread_rwlock_t *rwlock, 
                               const struct timespec *tsptr);
```

### 5.5 Condition Variable
Mutex虽然解决了安全访问共有资源问题, 但没有解决线程之间的状态同步问题: 当某一线程想要保持阻塞, 直到某一事件发生时再运行, 那么就需要一个variable来提醒该线程.
```c
/* in thread 1 */
pthread_mutex_lock(mx); /* protecting state access */
while (state != GOOD) {
  pthread_mutex_unlock(mx);
  wait_for_event();
  pthread_mutex_lock(mx);
}
pthread_mutex_unlock(mx);

/* in thread 2 */
pthread_mutex_lock(mx); /* protecting state access */
state = GOOD;
pthread_mutex_unlock(mx);
signal_event(); /* expecting to wake thread 1 up */
```
上述代码看似解决了状态同步问题, 但存在一个bug: 当thread 1执行完`pthread_mutex_unlock()`后, CPU的执行权可能转移到thread 2. Thread 2在执行完后再次回到thread 1, 而这时thread 1调用`wait_for_event()`并陷入永久的睡眠. 问题的关键在于无法实现原子性的unlock和wait连续操作.
```c
/* in thread 1 */
pthread_mutex_lock(mx); /* protecting state access */
while (state != GOOD) {
  pthread_cond_wait(cond, mx); /* unlocks the mutex and sleeps, then locks it back */
}
pthread_mutex_unlock(mx);

/* in thread 2 */
pthread_mutex_lock(mx); /* protecting state access */
state = GOOD;
pthread_cond_signal(cond); /* expecting to wake thread 1 up */
pthread_mutex_unlock(mx);
```
Conditional variable则很好的实现了这一功能.

```c
#include <pthread.h>

/**
 * @brief initialize the condition variable referenced by 
 *        cond with attributes referenced by attr
 * @param attr: if null, the default condition shall be used
 * 
 */
int pthread_cond_init(pthread_cond_t *cond, 
                      const pthread_condattr_t *attr);

/**
 * @brief destroy the given condition variable specified by 
 *        cond
 */
int pthread_cond_destroy(pthread_cond_t *cond);

/**
 * @brief block on a condition variable
 */
int pthread_cond_wait(pthread_cond_t *cond, 
                      pthread_mutex_t *mutex);

/**
 * @brief same as pthread_cond_wait(), except that an error 
 *        is returned if the absolute time specified by
 *        tsptr passes
 */
int pthread_cond_timedwait(pthread_cond_t *cond, 
                           pthread_mutex_t *mutex, 
                           const struct timespec *tsptr);

/**
 * @brief unblock at least one of the threads that are 
 *        blocked on the specified condition variable cond
 */
int pthread_cond_signal(pthread_cond_t *cond);

/**
 * @brief unblock all threads currently blocked on the 
 *        specified condition variable cond
 */
int pthread_cond_broadcast(pthread_cond_t *cond);
```

### 5.6 Spin Locks
Spin Lock功能上与mutex相同, 都是控制公共资源的访问. 但与mutex不同的是, thread无法获得spin lock时会不断尝试获取, CPU不断运转来保证thread一直尝试获取spin lock; 而无法获取mutex时会thread被阻塞, thread会让出CPU让其他thread运行.
Spin lock之所以这样设计是因为context switch的时间过长, 每次获取mutex失败后都要经历阻塞thread, 载入其他线程等操作. Lock mutex与unlock mutex之间的实际运行代码长度过短时, CPU的大部分时间都会浪费在context switch. 这时spin lock的优势就展现出来: 无需处理context switch.
```c
#include <pthread.h>

/**
 * @brief allocate any resources required to use the spin 
 *        lock referenced by lock and initialize the lock 
 *        to an unlocked state
 * @param pshared: the process-shared attribute
 *        1. PTHREAD_PROCESS_SHARED: permit the spin lock 
 *           to be operated by any thread in any other 
 *           processes
 *        2. PTHREAD_PROCESS_PRIVATE: only be operated by 
 *           threads created within the same process
 */
int pthread_spin_init(pthread_spinlock_t *lock, int pshared);

/**
 * @brief destroy the spin lock referenced by lock and 
 *        release any resources used by the lock
 */
int pthread_spin_destroy(pthread_spinlock_t *lock);

/**
 * @brief lock the spin lock referenced by lock if it is 
 *        not held by any thread. Otherwise, the thread 
 *        shall spin until the lock becomes available
 */
int pthread_spin_lock(pthread_spinlock_t *lock);

/**
 * @brief lock the spin lock referenced by lock if it is 
 *        not held by any thread. Otherwise, the function 
 *        shall fail
 */
int pthread_spin_trylock(pthread_spinlock_t *lock);

/**
 * @brief elease the spin lock referenced by lock
 */
int pthread_spin_unlock(pthread_spinlock_t *lock);
```
虽然spin lock有一定好处, 但实际使用情况却十分有限, 原因如下:
1. 现代处理器context switch所需时间越来越短
2. mutex实现加入了spin lock思想: mutex获取失败后不会立刻阻塞, 而是再尝试一定次数. 若这之后依旧没有获得mutex, 则陷入阻塞

### 5.7 Barriers
Barriers作为同步机制之一, 可让多个并发运行的threads协同工作. Thread到达barrier后会进行等待, 直到指定数量的线程到达该barrier后再一起恢复运行.
```c
#include <pthread.h>

/**
 * @brief allocate any resources required to use the barrier
 *        referenced by barrier and initialize the barrier 
 *        with attributes referenced by attr
 * @param count: the number of threads before any of them 
 *        successfully return from the call
 */
int pthread_barrier_init(pthread_barrier_t *barrier, 
                         const pthread_barrierattr_t *attr, 
                         unsigned int count);

/**
 * @brief destroy the barrier referenced by barrier and 
 *        release any resources used by the barrier
 */
int pthread_barrier_destroy(pthread_barrier_t *barrier);

/**
 * @brief synchronize participating threads at the barrier 
 *        referenced by barrier. The calling thread shall 
 *        block until the required number of threads have 
 *        called pthread_barrier_wait() specifying the 
 *        barrier
 * @return one thread receives PTHREAD_BARRIER_SERIAL_THREAD
 *         the other threads receive 0. This allows one 
 *         thread to continue as the master to act on the 
 *         results of the work done by all threads
 */
int pthread_barrier_wait(pthread_barrier_t *barrier);
```
barrier在使用中不能修改count. 若想重置count, 必须调用`pthread_barrier_destroy()`和`pthread_barrier_init()`重新设置count.
