---
title: Tools of Parallel-Programming Trade
category:
  - Concurrency
  - Basic
tag:
  - Concurrency
abbrlink: d031
date: 2019-05-21 13:52:54
---

## 1. Scripting Languages
```bash
compute_it 1 > compute_it.1.out &
compute_it 2 > compute_it.2.out &
wait
cat compute_it.1.out
cat compute_it.2.out
```
* &表示程序后台运行
* wait command阻塞shell直到两个程序结束运行
* cat输出结果


## 2. POSIX Multiprocessing
### 2.1 POSIX Process Creation and Destruction
```c
int pid = fork();
if (pid == 0) {
  /* child */
} else if(pid < 0) {
  /* parent, upon error */
  perror("fork");
  exit(-1);
} else {
  /* parent, pid == child ID */
}
```
* `fork()`创建进程
* `fork()`调用后返回两次pid, 一次是parent process, 一次是child process
  * 若pid == 0, 则为child process
  * 若pid < 0, 则`fork()`执行失败
  * 若pid > 0, 则为parent process, pid即为child process的ID
* Parent process可通过调用`wait()`来等待child process完成执行

`wait()`只能等待一个child process, 若parent process需要等待多个child process:
```c
void waitall(void) 
{
  int pid;
  int status;
  
  for (;;) {
    pid = wait(&status);
    if (pid == -1) {
      if (errno == ECHILD) 
        break;
      perror("wait");
      exit(-1);
    }
  }
}
```
* `wait()`阻塞parent process, 直到有child process结束运行
* `wait()`返回pid > 0, 则说明有一个child process结束运行
* `wait()`返回pid == -1, 则说明发生错误
* 若pid为-1且errno为ECHILD, 则说明没有等待中的child process

### 2.2 POSIX Thread Creation and Destruction
```c
int x = 0;

void *mythread(void *arg)
{
  x = 1;
  printf("Child process set x=1\n");
  return NULL;
}

int main(int argc, char *argv[]) 
{
  pthread_t tid;
  void *vp;
  
  if (pthread_create(&tid, NULL, mythread, NULL) != 0) {
    perror("pthread_create");
    exit(-1);
  }
  
  if (pthread_join(tid, &vp) != 0) {
    perror("pthread_join");
    exit(-1);
  }
  
  printf("Parent process sess x=%d\n", x);
  return 0;
}
```
pthread_create负责创建一个线程, pthread_join负责等待指定ID的线程执行完毕.
```c
#include <pthread.h>

/**
 * @brief Creates a new thread
 * @param thread: A pointer to store ID of the new thread
 * @param attr: Attributes of thw new thread
 * @param start_routine: execution method of the new thread
 * @param arg: the argument of start_routine
 */
int pthread_create(pthread_t *thread, const pthread_attr_t *attr,
                   void *(*start_routine)(void *), void *arg);

/**
 * @brief Waits for the thread specified by thread ID to terminate
 * @param thread: Joinable thread
 * @param retval: The result of thread execution method
 */
int pthread_join(pthread_t thread, void **retval);
```
必须确保只有一个thread在修改x值, 当存在多个thread同时想要读取或刷新数据时, 该情况被称为"data race".

### 2.3 POSIX Locking
POSIX Locking可避免data race的情况出现. 最简单的锁类型为互斥锁(pthread_mutex_t)
```c
// initialize lock_a and lock_b
pthread_mutex_t lock_a = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t lock_b = PTHREAD_MUTEX_INITIALIZER;
int x = 0;

void *lock_reader(void *arg)
{
  int i;
  int newx = -1;
  int oldx = -1;
  pthread_mutex_t *pmlp = (pthread_mutex_t *)arg;

  if (pthread_mutex_lock(pmlp) != 0) { // try to acquire lock_a
    perror("lock_reader:pthread_mutex_lock");
    exit(-1);
  }
  for (i = 0; i < 100; i++) {
    newx = READ_ONCE(x);
    if (newx != oldx) {
      printf("lock_reader(): x = %d\n", newx);
    }
    oldx = newx;
    poll(NULL, 0, 1);
  }
  if (pthread_mutex_unlock(pmlp) != 0) {
    perror("lock_reader:pthread_mutex_unlock");
    exit(-1);
  }
  return NULL;
}

void *lock_writer(void *arg)
{
  int i;
  pthread_mutex_t *pmlp = (pthread_mutex_t *)arg;
  
  if (pthread_mutex_lock(pmlp) != 0) {
    perror("lock_writer:pthread_mutex_lock");
    exit(-1);
  }
  for (i = 0; i < 3; i++) {
    WRITE_ONCE(x, READ_ONCE(x) + 1);
    poll(NULL, 0, 5);
  }
  if (pthread_mutex_unlock(pmlp) != 0) {
    perror("lock_writer:pthread_mutex_unlock");
    exit(-1);
  }
  return NULL;
}
```
* `lock_reader()`不断读取x的数值
* `lock_writer()`不断修改x的数值

```c
printf("Creating two threads using same lock:\n");
if (pthread_create(&tid1, NULL, lock_reader, &lock_a) != 0) {
  perror("pthread_create");
  exit(-1);
}
if (pthread_create(&tid2, NULL, lock_writer, &lock_a) != 0) {
  perror("pthread_create");
  exit(-1);
}
if (pthread_join(tid1, &vp) != 0) {
  perror("pthread_join");
  exit(-1);
}
if (pthread_join(tid2, &vp) != 0) {
  perror("pthread_join");
  exit(-1);
}

/* output:
 * Creating two threads using same lock:
 * lock_reader(): x = 0
 */
```
lock_reader和lock_writer使用同一个lock: lock_a. 当`lock_reader()`运行时, `lock_writer()`将会被阻塞, 因为无法获得lock_a.

### 2.4 POSIX Reader-Writer Locking
POSIX API还提供了另一个锁: 读写锁(pthread_rwlock_t)
```c
/**
 * @brief initialize pthread_rwlock_t statically
 */ 
PTHREAD_RWLOCK_INITIALIZER 

/**
 * @brief initialize initialize pthread_rwlock_t dynamically
 */ 
int pthread_rwlock_init(pthread_rwlock_t *restrict rwlock, 
                        const pthread_rwlockattr_t *restrict attr); 

/**
 * @brief lock a reader-writer lock object for reading
 * @param A pointer to reader-writer lock
 */
int pthread_rwlock_rdlock(pthread_rwlock_t *rwlock);
```
如果critical section(获取锁和解锁之间的代码)过小, 那么rwlock的性能并不比mutex lock好, 因为获取rwlock时需要额外的逻辑处理(区分reader lock和writer lock和避免writer starvation), 大部分时间将会浪费在获取锁和解锁上. rwlock的优势在于scalability(扩展性), 也就是可以存在多个thread同时拥有reader lock, 所以rwlock需要在critical section处理较长时间时使用, 例如critical section需要I/O等待时间.

### 2.5 Atomic Operations
Reader-writer lock在应对较小的critical section时比较吃力, 这是更应使用atomic operations(原子操作)来处理. 以下是GCC自带的Atomic Builtins:
```c
/**
 * @brief Perform the operation suggested by the name, 
 * @return The value that had previously been in memory
 */
type __sync_fetch_and_add(type *ptr, type value_);
type __sync_fetch_and_sub(type *ptr, type value_);
type __sync_fetch_and_or(type *ptr, type value_);
type __sync_fetch_and_and(type *ptr, type value_);
type __sync_fetch_and_xor(type *ptr, type value_);
type __sync_fetch_and_nand(type *ptr, type value_);

/**
 * @brief Perform the operation suggested by the name
 * @return The new value after operation
 */
type __sync_add_and_fetch(type *ptr, type value_);
type __sync_sub_and_fetch(type *ptr, type value_);
type __sync_or_and_fetch(type *ptr, type value_);
type __sync_and_and_fetch(type *ptr, type value_);
type __sync_xor_and_fetch(type *ptr, type value_);
type __sync_nand_and_fetch(type *ptr, type value_);

/**
 * @brief Perform an atomic compare and swap, 
 *        if the current value of *ptr is oldval, 
 *        then write newval into *ptr.
 * @return The contents of *ptr before the operation
 */
type __sync_val_compare_and_swap(type *ptr, type oldval type newval);

/**
 * @brief Issues a full memory barrier. 
 */
void __sync_synchronize();
```
C11也提供了atomic operations:
```c
#include <stdatomic.h>
/**
 * @brief Atomically loads atomic variable.
 * @param obj: pointer to the atomic object to access.
 * @return The current value pointed to obj
 */
C atomic_load(const volatile A* obj);

/**
 * @brief Atomically replaces the value of the variable 
 *        pointed to `obj` with `desired`.
 * @param obj: pointer to the atomic object to modify
 * @param desired: The value to be stored in the atomic object.
 */
void atomic_store(volatile A* obj , C desired);

/**
 * @brief Atomically perform obj the operation suggested by the name with arg
 * @return The value obj held previously.
 */
C atomic_fetch_add(volatile A* obj, M arg);
C atomic_fetch_sub(volatile A* obj, M arg);
C atomic_fetch_or(volatile A* obj, M arg);
C atomic_fetch_xor(volatile A* obj, M arg);
C atomic_fetch_and(volatile A* obj, M arg);

/**
 * @brief Establishes memory synchronization ordering of 
 *        non-atomic and relaxed atomic accesses
 * @param order: the memory ordering executed by this fence
 */
void atomic_thread_fence(memory_order order);
```

### 2.6 Per-Thread Variables
Pre-thread variables也称为thread-specific data(线程私有变量). 顾名思义, 该变量在每个线程都存在, 但每个线程的该变量却与其他线程的同名变量互不影响, 以下是POSIX提供的primitives:
```c
#include <pthread.h>

/**
 * @brief Create a thread-specific data key visible to all threads in the process
 * @return If successful, return 0. Otherwise, return an error number
 */
int pthread_key_create(pthread_key_t *key, void (*destructor)(void *));

/**
 * @brief Deletes thread-specific data keys created with pthread_key_create(), 
 *        The data associated with key do not need to be NULL when the key is deleted.
 * @return If successful, return 0. Otherwise, return an error number
 */
int pthread_key_delete(pthread_key_t key);

/**
 * @brief Associates the data `value` with the key `key`.
 * @return If successful, return 0. Otherwise, return -1 and set errno
 */
int pthread_setspecific(pthread_key_t key, void *value);

/**
 * @brief Get the value currently bound to the key on the calling thread
 */
void *pthread_getspecific(pthread_key_t key);
```
