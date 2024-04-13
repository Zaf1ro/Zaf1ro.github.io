---
title: Thread Control
tags:
  - Linux
category:
  - Linux
abbrlink: '7793'
date: 2019-09-27 12:22:47
keywords:
description:
---

## 1. Thread Limits
The Single UNIX Specification规定了几个关于thread的限制:

| Name of Limit | Description | sysconf Argument |
| :-----: | :-----: | :-----: |
| PTHREAD_DESTRUCTOR_ITERATIONS |  maximum number of times an implementation will try to destroy the thread-specific data when a thread exits | _SC_THREAD_DESTRUCTOR_ITERATIONS |
| PTHREAD_KEYS_MAX | maximum number of keys that can be created by a process | _SC_THREAD_KEYS_MAX |
| PTHREAD_STACK_MIN | minimum number of bytes that can be used for a thread’s stack | _SC_THREAD_STACK_MIN |
| PTHREAD_THREADS_MAX | maximum number of threads that can be created in a process | _SC_THREAD_THREADS_MAX |

但UNIX没有统一规定各个参数的具体数值:

| Limit | FreeBSD 8.0 | Linux 3.2.0 | Mac OS X 10.6.8 | Solaris 10 |
| :-----: | :-----: | :-----: | :-----: | :-----: |
| PTHREAD_DESTRUCTOR_ITERATIONS | 4 | 4 | 4 | no limit |
| PTHREAD_KEYS_MAX | 256 | 1024 | 512 | no limit |
| PTHREAD_STACK_MIN | 2048 | 16384 |  8192 |  8192 |
| PTHREAD_THREADS_MAX | no limit | no limit | no limit | no limit |



## 2. Thread Attributes
Pthread interface允许我们通过不同的参数来规范pthread和synchronization object(包含mutex, rwlock, condition variable和barrier)的行为. Pthread interface有以下同性:
1. 每个synchronization object都有自己的attribute object类型. 每个attribute object都可表示多个属性. thread上的程序无法知晓其attribute object, 且thread只能通过pthread函数来操作attribute object
2. Synchronization objectd的initialization function可设置其attribute object为默认值(设为null即可))
3. 每个attribute object也有其负责析构的function, 会销毁initialization function申请的所有资源
4. 每个attribute object都有一个get function和set function, 用于获取或设置attribute object中的属性

```c
#include <pthread.h>

/**
 * @brief initializes the thread attributes object pointed to
 *        by attr with default attribute values
 */
int pthread_attr_init(pthread_attr_t *attr);

/**
 * @brief free all dynamic memory allocated by pthread_attr_init()
 */
int pthread_attr_destroy(pthread_attr_t *attr);
```
pthread attribute object有四个属性, 且有对应的get和set function

### 2.1 detachstate
若创造thread时已确定不需要其termination status, 则可通过设置detachstate来实现新建thread分离出去并单独运行.
```c
#include <pthread.h>

/**
 * @brief store the detach state attribute of the thread 
 *        attributes object attr in the buffer pointed to by 
 *        detachstate
 */
int pthread_attr_getdetachstate(const pthread_attr_t *attr, 
                                int *detachstate);

/**
 * @brief set the detach state attribute of the thread 
 *        attributes object referred to by attr to the value 
 *        specified in detachstate
 */
int pthread_attr_setdetachstate(pthread_attr_t *attr, int detachstate);
```

### 2.2 stackaddr, stacksize
每个thread都有一个stack, 在创建thread时, 其stack的大小就被确定下来. attribute object可通过stacksize开调整stack的地址和大小
```c
#include <pthread.h>

/**
 * @brief store the stack address and stack size attributes 
 *        of the thread attributes object referred to by attr
 *        in the buffers pointed to by stackaddr and stacksize
 */
int pthread_attr_getstack(const pthread_attr_t *attr, 
                          void **stackaddr, size_t *stacksize);

/**
 * @brief set the stack address and stack size attributes of 
 *        the thread attributes object referred to by attr to
 *        the values specified in stackaddr and stacksize
 */
int pthread_attr_setstack(pthread_attr_t *attr,
                          void *stackaddr, size_t stacksize);
```
一般情况下不需要调用这两个函数, UNIX会自动分配好所需的内存. 除非需要指定某块内存作为thread的stack. 当调用pthread_attr_setstack()后, 程序会接管stack的管理权, 因此guard size也需要程序自行设置, 必要时还需要设置guard area, 所以应避免使用该函数.
```c
#include <pthread.h>

/**
 * @brief store the stack size attribute of the thread 
 *        attributes object referred to by attr in the buffer
 *        pointed to by stacksize
 */
int pthread_attr_getstacksize(const pthread_attr_t *attr, 
                              size_t *stacksize);

/**
 * @brief set the stack size attribute of the thread 
 *        attributes object referred to by attr to the value 
 *        specified in stacksize
 */
int pthread_attr_setstacksize(pthread_attr_t *attr, 
                              size_t stacksize);
```
上述两个函数可在不修改stackaddr的基础上获取或设置stacksize, 但需要注意两点:
1. 设置的stacksize不可小于PTHREAD_STACK_MIN, 否则返回EINVAL
2. 若设置的stacksize不为STACK_ALIGN的倍数, UNIX则会向上取整至STACK_ALIGN的倍数

### 2.3 guardsize
当thread发生stack overflow后, guard area会作为一块buffer来保存变量.
```c
#include <pthread.h>

/**
 * @brief store the guard size attribute of the thread 
 *        attribute object to by attr in the buffer pointed 
 *        to by guardsize
 */
int pthread_attr_getguardsize(const pthread_attr_t *attr, 
                              size_t *guardsize);

/**
 * @brief set the guard size attribute of the thread 
 *        attributes object referred to by attr to the value 
 *        specified in guardsize
 */
int pthread_attr_setguardsize(pthread_attr_t *attr, size_t guardsize);
```
guardsize会向上取整到memory page的整数倍. 若guardsize为0, 则不需要缓存数据. 若数据已经写满stack并写入guard area后, thread会受到SIGSEGV signal. 



## 3. Synchronization Attributes
### 3.1 Mutex Attributes
```c
#include <pthread.h>

/**
 * @brief initialize a mutex attributes object attr with the 
 *        default value for all of the attributes
 */
int pthread_mutexattr_init(pthread_mutexattr_t *attr);

/**
 * @brief destroy a mutex attributes object
 */
int pthread_mutexattr_destroy(pthread_mutexattr_t *attr);
```
mutex attribute有三个属性:
1. process-shared
```c
#include <pthread.h>

/**
 * @brief store the value of the process-shared attribute 
 *        from the attributes object referenced by attr
 */
int pthread_mutexattr_getpshared(const pthread_mutexattr_t *attr, 
                                 int *pshared);

/**
 * @brief set the process-shared attribute in an initialized 
 *        attributes object referenced by attr
 * @param pshared: shall be one of the following values
 *        1. PTHREAD_PROCESS_SHARED: mutex shall be operated 
 *           upon by any thread in any process
 *        2. PTHREAD_PROCESS_PRIVATE: mutex shall only be 
 *           operated upon by threads created within the 
 *           same process
 */
int pthread_mutexattr_setpshared(pthread_mutexattr_t *attr, 
                                 int pshared);
```
2. robust
```c
#include <pthread.h>

/**
 * @brief store the value of the robust attribute of the 
 *        mutex attribute object referred to by attr in 
 *        robust
 */
int pthread_mutexattr_getrobust(const pthread_mutexattr_t *attr, 
                                int *robust);

/**
 * @brief set the value of the robust attribute of the mutex 
 *        attribute object referred to by attr to the value 
 *        specified in robust
 * @param robust: shall be one of the following values
 *        1. PTHREAD_MUTEX_STALLED: default value. If owner 
 *           dies without unlocking it, the mutex remains 
 *           locked and other threads will block
 *        2. PTHREAD_MUTEX_ROBUST: If owner dies without 
 *           unlocking it, any attempts to call 
 *           pthread_mutex_lock() will succeed and return 
 *           EOWNERDEAD to indicate that the mutex is in an 
 *           inconsistent state
 */
int pthread_mutexattr_setrobust(pthread_mutexattr_t *attr, 
                                int robust);

/**
 * @brief make a robust mutex consistent if it is in an 
 *        inconsistent state. A mutex can be left in an 
 *        inconsistent state if its owner terminates while 
 *        holding the mutex
 */
int pthread_mutex_consistent(pthread_mutex_t * mutex);
```
3. type
```c
#include <pthread.h>

/**
 * @brief store the value of type attribute of the mutex 
 *        attribute object referred to by attr in *type
 */
int pthread_mutexattr_gettype(const pthread_mutexattr_t *attr, 
                              int *type);

/**
 * @brief set the value of the type attribute of the mutex 
 *        attribute
 * @param type: shall be one of the following values
 *        1. PTHREAD_MUTEX_NORMAL: does not detect deadlock
 *        2. PTHREAD_MUTEX_ERRORCHECK: provides error 
 *           checking. It shall return an error if relock a 
 *           mutex or unlock an unlocked mutex
 *        3. PTHREAD_MUTEX_RECURSIVE: allows the same thread 
 *           to lock it multiple times without first 
 *           unlocking it
 *        4. PTHREAD_MUTEX_DEFAULT: recursively lock a mutex 
 *           or unlock an unlocked mutex results in undefined
 *           behavior. An implementation may map this mutex 
 *           to one of the other mutex types
 */
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int type);
```

### 3.2 Reader-Writer Lock Attributes
```c
#include <pthread.h>

/**
 * @brief initialize a read-write lock attributes object attr
 *        with the default value for all of the attributes
 */
int pthread_rwlockattr_init(pthread_rwlockattr_t *attr);

/**
 * @brief destroy a read-write lock attributes object
 */
int pthread_rwlockattr_destroy(pthread_rwlockattr_t *attr);
```
Reader-writer lock attribute只有一个属性: process-shared
```c
#include <pthread.h>

/**
 * @brief store the value of the process-shared attribute
 *        from the attribute object referenced by attr
 */
int pthread_rwlockattr_getpshared(const pthread_rwlockattr_t *attr, 
                                  int *pshared);

/**
 * @brief set the process-shared attribute in an attribute 
 *        object referenced by attr
 * @param pshared: same as pthread_mutexattr_setpshared()
 */
int pthread_rwlockattr_setpshared(pthread_rwlockattr_t *attr,
                                  int pshared);
```

### 3.3 Condition Variable Attributes
```c
#include <pthread.h>

/**
 * @brief initialize a condition variable attributes object 
 *        attr with the default value for all of the attributes
 */
int pthread_condattr_init(pthread_condattr_t *attr);

/**
 * @brief set the object referenced by attr to an invalid value
 */
int pthread_condattr_destroy(pthread_condattr_t *attr);
```
Condition variable attribute有两个属性:
1. process-shared
```c
#include <pthread.h>

/**
 * @brief store the value of the process-shared attribute 
 *        from the attribute object referenced by attr
 */
int pthread_condattr_getpshared(const pthread_condattr_t *attr, 
                                int *pshared);

/**
 * @brief set the process-shared attribute in an attributes 
 *        object referenced by attr
 * @pshared: same as pthread_mutexattr_setpshared()
 */
int pthread_condattr_setpshared(pthread_conda *attr, int pshared);
```
2. clock ID
```c
#include <pthread.h>

/**
 * @brief store the value of the clock attribute from the 
 *        attribute object referenced by attr
 */
int pthread_condattr_getclock(const pthread_condattr_t *attr,
                              clockid_t *clock_id);

/**
 * @brief set the clock id attribute in an attributes object 
 *        referenced by attr
 * @param clock_id: used for pthread_cond_timedwait()
 */
int pthread_condattr_setclock(pthread_condattr_t *attr,
                              clockid_t clock_id);
```

### 3.4 Barrier Attribute
```c
#include <pthread.h>

/**
 * @brief initialize a barrier attribute object attr with the
 *        default value for all of the attributes
 */
int pthread_barrierattr_init(pthread_barrierattr_t *attr);

/**
 * @brief set the object referenced by attr to an invalid value
 */
int pthread_barrierattr_destroy(pthread_barrierattr_t *attr);
```
Barrier attribute只有一个属性: process-shared
```c
#include <pthread.h>

/**
 * @brief store the value of the process-shared attribute 
 *        from the attribute object referenced by attr
 */
int pthread_barrierattr_getpshared(const pthread_barrierattr_t *attr, 
                                   int *pshared);

/**
 * @brief set the process-shared attribute in an attribute 
 *        object referenced by attr
 * @pshared: same as pthread_mutexattr_setpshared()
 */
int pthread_barrierattr_setpshared(pthread_barrierattr_t *attr, 
                                   int pshared);
```



## 4. Reentrancy
POSIX.1规定了一套符合thread-safe的方式来管理FILE对象: 使用flockfile()或ftrylockfile()来为FILE对象加锁, 文件操作完毕后调用funlockfile()解锁
```c
#include <stdio.h>

/**
 * @brief nonblocking version of flockfile()
 * @return 0 for success; nonzero for failure
 */
int ftrylockfile(FILE *fp);

/**
 * @brief wait for *fp to be no longer locked by other thread
 *        then make the current thread the owner of *fp, and 
 *        increment the lockcount
 */
void flockfile(FILE *fp);

/**
 * @brief decrement the lock count, unlock the *fq when 
 *        lockcount become 0
 */
void funlockfile(FILE *fp);
```
Standard I/O函数在被调用时会自行获得锁, 从而保证thread-safe. 但多次调用getchar()和putchar()会导致时间大量浪费在锁操作上. 为避免不必要的多次加锁, 可使用非加锁的character-at-a-time I/O函数:
```c
#include <stdio.h>

int getchar_unlocked(void);
int getc_unlocked(FILE *fp);
int putchar_unlocked(int c);
int putc_unlocked(int c, FILE *fp);
```
上述4个函数在调用前必须调用flockfile()保证thread-safe, 完毕后要调用funlockfile()解锁.



## 5. Thread-Specific Data
Thread-specific data用于存储和寻找特定线程相关的数据, 数据与特定线程绑定后, 数据就不再拥有同步问题, 因为该数据不与其他线程共享.
尽管原则上thread-specific data上的数据不可被其他线程访问, 但由于单个进程下的所有线程共享内存空间, 所以若其他线程得知thread-specific data的内存地址, 则还是可以访问. Pthread使用key, value对应关系模型将thread-specific与一个共享的key结合在一起.
```c
#include <pthread.h>

/**
 * @brief create a thread-specific data *keyp visible to all 
 *        threads in the process
 * @param destructor: When the thread exits, if the destructor
 *        has been set to a non-null value, the destructor 
 *        function is called
 * @return 0 on success; error number on error.
 */
int pthread_key_create(pthread_key_t *keyp, void (*destructor)(void *));

/**
 * @brief delete a thread-specific data key previously 
 *        returned by pthread_key_create(). Shall not invoke 
 *        the destructor function associated with the key.
 */
int pthread_key_delete(pthread_key_t key);
```
虽然pthread_key_create()创建的key可被所有thread使用, 但每个key所对应的thread-specific data因所处线程不同而不同. 若某线程拥有所有key且每个key都有自己的destructor, 当线程退出时destructor的调用顺序以系统实现而准.
为防止多个线程调用pthread_key_create()导致单个key不断被初始化, Pthread提供pthread_once()来保证单个key只会被初始化一次.
```c
#include <pthread.h>
pthread_once_t initflag = PTHREAD_ONCE_INIT;

/**
 * @brief the first call to pthread_once() by any thread in a
 *        process shall call initfn(). Subsequent calls of 
 *        pthread_once() with the same once_ctl shall not 
 *        call the initfn
 * @param once_ctl: determine whether the associated 
 *        initialization routine has been called
 *        (PTHREAD_ONCE_INIT)
 * @return 0 on success; error number on error.
 */
int pthread_once(pthread_once_t *once_ctl, void (*initfn)(void));
```
Key创建完毕后可将其与thread-specific data绑定:
```c
#include <pthread.h>

/**
 * @brief create a thread-specific data key visible to all 
 *        threads in the process
 */
void *pthread_getspecific(pthread_key_t key);

/**
 * @brief associate a thread-specific value with a key obtained
 *        via a previous call to pthread_key_create()
 */
int pthread_setspecific(pthread_key_t key, const void *value);
```



## 6. Cancel Options
Pthread的线程还有另外两个属性: cancelability state, cancelability type. 这两个属性会影响pthread_cancel()的行为.
1. cancelability state
```c
#include <pthread.h>

/**
 * @brief set the cancelability state of the calling thread 
 *        to the value given in state
 * @param state: shall be one of the following values:
 *        1. PTHREAD_CANCEL_ENABLE: The thread is cancelable
 *        2. PTHREAD_CANCEL_DISABLE: The thread is not 
 *           cancelable. A call to pthread_cancel() will not 
 *           kill the thread, the cancellation request remains
 *           pending until the cancelability state is enabled
 * @param oldstate: The previous cancelability state of the 
 *        thread
 */
int pthread_setcancelstate(int state, int *oldstate);
```
    POSIX.1规定cancellation point只会在以下函数被调用时发生:
![Cancellation points defined by POSIX.1](/images/UNIX/thread-ctl-1.jpg)

2. cancelability type
```c
#include <pthread.h>

/**
 * @brief set the cancelability type of the calling thread to
 *        the value given in type
 * @param type: shall be one of the following values:
 *        1. PTHREAD_CANCEL_DEFERRED: keep the cancellation 
 *           request pending until the next cancellation point
 *        2. PTHREAD_CANCEL_ASYNCHRONOUS: cancel the calling 
 *           thread as soon as the cancellation request is 
 *           received
 * @param oldtype: The previous cancelability type of the 
 *        thread
 */
int pthread_setcanceltype(int type, int *oldtype);
```



## 7. Threads and Signals
每个线程都有自己的signal mask, 但所有线程共享进程的signal handler. 当单个线程block signal后, 其他线程也会屏蔽该signal. Hardware fault引发的signal会发送到引发该错误的线程, 其他原因产生的signal会随机发给一个线程.
sigprocmask()用于进程阻塞signal, 但多线程下调用signpromask()的行为以系统实现而定. POSIX.1提供了以下函数用于线程阻塞signal:
```c
#include <signal.h>

/**
 * @brief same as sigpromask()
 * @param how: shall be one of the following values:
 *        1. SIG_BLOCK: add the set of signals to the signal 
 *           mask
 *        2. SIG_SETMASK: replace the signal mask with the 
 *           set of signals
 *        3. SIG_UNBLOCK: remove the set of signals from the 
 *           signal mask
 * @return 0 on success; error number on error
 */
int pthread_sigmask(int how, const sigset_t *set, sigset_t *oset);
```
线程可调用sigwait()来等待一个或多个signals
```c
#include <signal.h>

/**
 * @brief suspend execution of the calling thread until one 
 *        of the signals specified in the signal set set 
 *        becomes pending
 * @param signop: the number of the signal that was delivered
 */
int sigwait(const sigset_t *set, int *signop);
```
使用sigwait()时需要注意以下几点:
*  若sigwait()调用前已经有signal处于pending状态, sigwait()直接返回. 
* sigwait()返回前会移除所有处于pending状态的signals; 若系统支持queued signals, 则sigwait()只会移除第一个signal, 剩余signal还会留在queue中. 
* 调用sigwait()前必须先阻塞signals. sigwait()会自动unblock这些signals并等待其到来. sigwait()返回前会恢复signal mask.
* 若多个线程都调用了sigwait(), signal到来时只有一个线程会被唤醒, 其他线程继续等待.

```c
#include <signal.h>

/**
 * @brief send the signal signo to thread
 * @param signo: if 0, no signal is sent
 * @return 0 on success; error number on error
 */
int pthread_kill(pthread_t thread, int signo);
```



## 8. Threads and fork
线程调用fork()时会发生两件事:
1. 整个进程的内存地址空间都会复制到child process中: child process继承parent process中所有的synchronization object(mutex, rwlock, condition variable)
2. child process只会复制一个线程, 也就是parent process中调用fork()的线程: 若child process不打算执行exec, 且存在被其他线程获得的锁, 由于其他线程并未被fork()复制, 被获取的锁将永远被释放, 从而导致死锁

为避免多线程中fork()导致的inconsistent state, POSIX.1提出了以下函数:
```c
#include <pthread.h>

/**
 * @brief declare fork handlers to be called before and after
 *        fork() in the context of the thread that called 
 *        fork()
 * @param prepare: shall be called in the parent before 
 *        fork() creates the child process
 * @param parent: shall be called in the parent after fork() 
 *        has created the child process, but before fork has 
 *        returned
 * @param child: shall be called in the context of the child 
 *        process before returning from fork
 */
int pthread_atfork(void (*prepare)(void), void (*parent)(void), 
                   void (*child)(void));
```
pthread_atfork()有两种用法:
1. prepare()为child process解锁, fork()将无锁状态复制给child process. 创建child process后, parent()再次加锁, 保证parent process中的程序可以正常解锁.
2. prepare()中获取所有锁, fork()将所有锁的拥有权复制给child process. 创建child process后, child()负责解锁.

fork()用于多进程, thread用于多线程, 实际编程中不推荐多进程和多线程混用, 容易导致死锁. 以下是pthread_atfork()的缺陷:
* 部分synchronization object不方便重新初始化, 例如: condition variable, barrier
* child process解锁由parent process获取的锁时可能触发error
* Recursive mutex无法被解锁, 因为无法获知加锁次数
* 若child process只允许调用async-signal function, 则child()无法解锁, 因为解锁操作是non-async-signal function
* signal handler中调用fork()导致pthread_atfork()中只能调用async-signal function



## 9. Threads and I/O
由于线程共享进程中的所有file descriptor, 所以对file descriptor的非原子操作会导致文件操作出错, 例如:
```c
/* Thread A */
lseek(fd, 300, SEEK_SET);
read(fd, buf1, 100);

/* Thread B */
lseek(fd, 700, SEEK_SET);
read(fd, buf2, 100);
```
上述代码中thread A和thread B的交错执行会导致读取位置错误, 因此POSXI.1提出以下函数:
```c
#include <unistd.h>

/**
 * @brief read up to count bytes from file descriptor fd at 
 *        offset into the buffer starting at buf. The file 
 *        offset is not changed
 * @return the number of bytes read on success; -1 on error 
 *         and errno is set
 */
ssize_t pread(int fd, void *buf, size_t count, off_t offset);

/**
 * @brief write up to count bytes from the buffer starting at
 *        buf to the file descriptor fd at offset. The file 
 *        offset is not changed
 * @return the number of bytes written on success; -1 on 
 *         error and errno is set
 */
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
```
移动file offset和读取/写入操作变为原子操作.
