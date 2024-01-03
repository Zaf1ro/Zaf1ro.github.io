---
title: Counting
category:
  - Concurrency
  - Basic
tag:
  - Concurrency
abbrlink: e99f
date: 2019-05-25 08:45:12
---

## 1. Intro
Counting(计数)似乎是最基础简单的操作, 但在并发系统中就变得具有挑战性. 单线程中的计数可写成以下处理:
```c
long counter = 0;

void inc_count(void)
{
  counter++;
}

long read_count(void)
{
  return counter;
}
```
很明显, 并发情况下并不能这么计数, 因为变量counter作为CPU争抢的资源, 必须有保护机制保证counter+1操作的consistency(一致性)
```c
atomic_t counter = ATOMIC_INIT(0);

void inc_count(void)
{
  atomic_inc(&counter);
}

long read_count(void)
{
  return atomic_read(&counter);
}
```
这里我们使用atomic operation来解决data race, 因为atomic operation适合于这种简单的操作(加减操作), 且代价比锁机制小. 然而对于超大数据量的情况, atomic operation的表现并不够快, 主要原因在于cache miss: 每当CPU想要对counter进行+1操作, counter所在cache很可能不在该CPU的cache中, 这时就需要移动counter到该CPU的cache中. 由于每个CPU都有机会更新counter, 导致大部分时间用于在cache之间移动counter, 如下图:
![Data Flow For Global Atomic Increment](/images/multithreading/Basic/counting-1.png)


## 2. Statistical Counter
假设有一台服务器每秒接受数百万个数据包, 每接受到一个数据包都要counter+1, 服务器上的监控器每隔5秒要读取计数器的数值. 该计数系统的特点在于: counter更新频率极高, 但读取频率很低.

### 2.1 Per-Thread Statistical Counters
为避免时间浪费在cache miss上, 可使用pre-thread variable让每个CPU维护自己的counter变量, 当需要读取计数结果时, 把每个线程的counter相加即可, 这样不需要频繁在cache之间移动:
![Data Flow For Per-Thread Increment](/images/multithreading/Basic/counting-2.png)

代码如下:
```c
DEFINE_PER_THREAD(long, counter);

void inc_count(void)
{
  __get_thread_var(counter)++;
}

long read_count(void)
{
  int t;
  long sum = 0;

  for_each_thread(t)
    sum += per_thread(counter, t);
  return sum;
}
```
虽然以上代码解决了`inc_count()`的速度问题, 但还存在另外两个问题:
1. 如果调用`read_count()`时`inc_count()`同样在运行, 则最后得到的计数结果并不是准确的, 因为并没有使用atomic operation或lock来保证一致性
2. gcc并未提供一个类似`for_each_thread()`的函数
3. Pre-thread variable随thread结束而被清除. 假设`read_count()`在某个计数thread运行结束后尝试获取该thread的counter变量, 会导致错误.

### 2.2 Eventually Consistent Array-Based Implementation
为解决以上三个问题, 可以在不影响`inc_count()`和`read_count()`的性能下提出以下三点解决方案:
1. 虽然不能在不使用atomic operation或lock且不断运行`inc_count()`的情况下获得准确的计数结果, 可以退而求其次, 尝试在所有thread运行结束后获得准确的总计数结果, 也就是Eventually Consistent(最终一致性)
2. 维护一个array来跟踪所有thread的pre-thread variables
3. Thread在结束之前将其pre-thread variable传给array

实现代码如下:
```c
long __thread counter = 0;
long *counterp[NR_THREADS] = { NULL };
long finalcount = 0;
DEFINE_SPINLOCK(final_mutex);

void inc_count(void)
{
  counter++;
}

// Add all counter variables from array `counterp`
long read_count(void)
{
  int t;
  long sum;
  
  spin_lock(&final_mutex);
  sum = finalcount;
  for_each_thread(t)
    if (counterp[t] != NULL)
        sum += *counterp[t];
  spin_unlock(&final_mutex);
  return sum;
}

// Must be called by each thread before its first use of this counter
void count_register_thread(void)
{
  int idx = smp_thread_id();
  
  spin_lock(&final_mutex);
  counterp[idx] = &counter;
  spin_unlock(&final_mutex);
}

// Must be called by each thread before thread exits
void count_unregister_thread(int nthreadsexpected)
{
  int idx = smp_thread_id();
  
  spin_lock(&final_mutex);
  finalcount += counter;
  counterp[idx] = NULL;
  spin_unlock(&final_mutex);
}
```
这样既可以保证`inc_count()`, `read_count()`的效率, 也能一定程度上保证数据一致性, 但也存在部分缺陷, 例如: 数组counterp的大小限制了线程的数量


## 3. Approximate Limit Counters
假设需要设计一个计数器来监控某个structure(结构体): 
* allocate(分配)该结构体时计数器+1
* 销毁结构体时计数器-1
* 结构体的数量上限为10000个, 若申请数量超过上限则获取分配失败

### 3.1 Simple Limit Counter Implementation
一种简单的设计思路: 将10000这个限制值平均划分给多个thread，然后给每个thread一个固定个数的结构体池. 假如有100个thread，则每个thread管理100个结构体. 但这种设计无法应对一种常见情况: 某个thread一直被要求分配结构体, 另一个thread一直销毁结构体. 由于thread之间无法共享结构体, 导致thread会经常处于结构体过剩或饥饿的状态.
这时需要采用部分分治的方法, 除了每个thread维护一个counter外, 还要维护一个全局counter, 当出现结构体过剩或饥饿时及时扩大或缩小thread的资源池.
```c
// Pre-thread varibles
// thread's counter
unsigned long __thread counter = 0;
// upper bound of thread's counter
unsigned long __thread countermax = 0;

// Global variables
// upper bound for number of structures
unsigned long g_countermax = 10000;
// The total number of allocated structures
unsigned long g_counter = 0;
// Sum of all of the per-thread countermax variables
unsigned long g_reserve = 0;
// References the corresponding thread’s counter variable
unsigned long *counterp[NR_THREADS] = { NULL };

// Guards all of the global variables
DEFINE_SPINLOCK(gblcnt_mutex);

/**
 * @brief Adds the specified value `delta` to the counter.
 * @return If successful, return 1. Otherwise, return 0.
 */
int add_count(unsigned long delta)
{
  // fastpath
  if (countermax - counter >= delta) { // checks to see if there is room for delta on counter
    counter += delta;
    return 1;
  }
  
  // slowpath
  spin_lock(&gblcnt_mutex); // Before access global variables, acquire gblcnt_mutex
  globalize_count();
  if (g_countermax - g_counter - g_reserve < delta) { // no more room for structure
    spin_unlock(&gblcnt_mutex);
    return 0;
  }
  g_counter += delta;
  balance_count();
  spin_unlock(&gblcnt_mutex);
  return 1;
}

/**
 * @brief Subtracts the specified value `delta` from the counter
 * @return If successful, return 1. Otherwise, return 0.
 */
int sub_count(unsigned long delta)
{
  if (counter >= delta) {
    counter -= delta;
    return 1;
  }
  spin_lock(&gblcnt_mutex);
  globalize_count();
  if (g_counter < delta) {
    spin_unlock(&gblcnt_mutex);
    return 0;
  }
  g_counter -= delta;
  balance_count();
  spin_unlock(&gblcnt_mutex);
  return 1;
}

unsigned long read_count(void)
{
  int t;
  unsigned long sum;
  
  spin_lock(&gblcnt_mutex);
  sum = g_counter;
  for_each_thread(t)
    if (counterp[t] != NULL)
      sum += *counterp[t];
  spin_unlock(&gblcnt_mutex);
  return sum;
}
```
所有pre-thread variables和global variables之间的不等式如下:

$$
\begin{align}
\tag{1} \text{g_counter} + \text{g_reserve} \leq \text{g_countermax}  \\\\
\tag{2} \sum\_{i=1}^{nThreads}(countermax\_i) \leq \text{g_reserve} \\\\
\tag{3} counter\_i \leq countermax\_i
\end{align}
$$

![Simple Limit Counter Variable Relationships](/images/multithreading/Basic/counting-3.png)

每当thread需要调用global variables时, 说明thread结构体过剩或饥饿, 需要调用`globalize_count()`和`balance_count()`来更新pre-thread variables和global variables:
```c
/**
 * @brief Clear out this thread’s counter state
 */
static void globalize_count()
{
  g_counter += counter;
  counter = 0;
  g_reserve -= countermax;
  countermax = 0;
}

/**
 * @brief Set this thread’s countermax to re-enable the fastpath
 */
static void balance_count()
{
  countermax = g_countermax - g_counter - g_reserve;
  countermax /= num_online_threads();
  g_reserve += countermax;
  counter = countermax / 2;
  if (counter > g_counter)
    counter = g_counter;
  g_counter -= counter;
}

/**
 * @brief Set up state for newly created threads
 */
void count_register_thread()
{
  int idx = smp_thread_id();
  
  spin_lock(&gblcnt_mutex);
  counterp[idx] = &counter;
  spin_unlock(&gblcnt_mutex);
}

/**
 * @brief Tear down state for a soon-to-be-exiting thread
 */
void count_unregister_thread(int nthreadsexpected)
{
  int idx = smp_thread_id();

  spin_lock(&gblcnt_mutex);
  globalize_count();
  counterp[idx] = NULL;
  spin_unlock(&gblcnt_mutex);
}
```
该计数系统还是存在两个互为矛盾的缺陷:
1. **部分分治**的思路让fastpath部分运行极快, 但当thread数量过多时, thread的countermax和counter数值过小, 因而导致无法进入fastpath, 运算性能下降.
2. 如果限制thread数量, 让单个thread的countermax的数值变大. 假设单个thread的countermax为R, 则g_countermax的accuracy(精确度)降低R/2. 因此精确度和运算性能之间形成了相互制衡.


## 4. Exact Limit Counters
实现一个精确上限的计数器有两种方式:
* 放弃单个thread的pre-thread variables, 全部使用global variables
* 使用atomic instruction操作单个线程的thread的pre-thread variables, 但允许thread之间相互操作

这里选择使用第二种方法来实现Exact Limit Counters

### 4.1 Atomic Limit Counter Implementation
由于pre-thread variables有两个(counter和countermax), 但atomic operation只能对单个variable操作, 所以这里选择将counter和countermax放入一个int变量中, counter占前16位, countermax占后16位
```c
atomic_t __thread ctrandmax = ATOMIC_INIT(0); // counter and countermax
unsigned long g_countermax = 10000;
unsigned long g_counter = 0;
unsigned long g_reserve = 0;
atomic_t *counterp[NR_THREADS] = { NULL };
DEFINE_SPINLOCK(gblcnt_mutex);
#define CM_BITS (sizeof(atomic_t) * 4) // number of bits used for counter or countermax
#define MAX_COUNTERMAX ((1 << CM_BITS) - 1) // bitmask for counter or countermax

static void split_ctrandmax_int(int cami, int *c, int *cm)
{
  *c = (cami >> CM_BITS) & MAX_COUNTERMAX;
  *cm = cami & MAX_COUNTERMAX;
}

/**
 * @brief Extract counter `c` and countermax `cm` from ctrandmax `cam` 
 */
static void split_ctrandmax(atomic_t *cam, int *old, int *c, int *cm)
{
  unsigned int cami = atomic_read(cam);
  *old = cami;
  split_ctrandmax_int(cami, c, cm);
}

/**
 * @brief Combine counter `c` and countermax `cm` to ctrandmax
 */
static int merge_ctrandmax(int c, int cm)
{
  unsigned int cami;
  cami = (c << CM_BITS) | cm;
  return ((int)cami);
}
```
接下来是add_count()和sub_count():
```c
int add_count(unsigned long delta)
{
  int c;
  int cm;
  int old;
  int new;

  do {
    split_ctrandmax(&ctrandmax, &old, &c, &cm);
    if (delta > MAX_COUNTERMAX || c + delta > cm)
      goto slowpath;
    new = merge_ctrandmax(c + delta, cm);
  } while (atomic_cmpxchg(&ctrandmax, old, new) != old); 
  // atomically compares ctrandmax to old, replace ctrandmax with new if success
  return 1;

slowpath:
  spin_lock(&gblcnt_mutex);
  globalize_count();
  if (g_countermax - g_counter - g_reserve < delta) {
    // flush all threads’ local state to the global counters
    flush_local_count();
    if (g_countermax - g_counter - g_reserve < delta) { // no space for allocation
      spin_unlock(&gblcnt_mutex);
      return 0;
    }
  }
  g_counter += delta;
  balance_count();
  spin_unlock(&gblcnt_mutex);
  return 1;
}

int sub_count(unsigned long delta)
{
  int c;
  int cm;
  int old;
  int new;

  do {
    split_ctrandmax(&ctrandmax, &old, &c, &cm);
    if (delta > c)
      goto slowpath;
    new = merge_ctrandmax(c - delta, cm);
  } while (atomic_cmpxchg(&ctrandmax, old, new) != old);
  return 1;

slowpath:
  spin_lock(&gblcnt_mutex);
  globalize_count();
  if (g_counter < delta) {
    flush_local_count();
    if (g_counter < delta) {
      spin_unlock(&gblcnt_mutex);
      return 0;
    }
  }
  g_counter -= delta;
  balance_count();
  spin_unlock(&gblcnt_mutex);
  return 1;
}
```
`read_count()`的实现与Approximate Limit Counters基本相同, 唯一区别在于调用`split_ctrandmax()`提取counter:
```c
unsigned long read_count(void)
{
  int c;
  int cm;
  int old;
  int t;
  unsigned long sum;
  
  spin_lock(&gblcnt_mutex);
  sum = g_counter;
  for_each_thread(t)
    if (counterp[t] != NULL) { // get counter from ctrandmax
      split_ctrandmax(counterp[t], &old, &c, &cm);
      sum += c;
    }
  spin_unlock(&gblcnt_mutex);
  return sum;
}
```
最后是最重要的`flush_local_count()`和其他函数:
```c
static void globalize_count(void)
{
  int c;
  int cm;
  int old;

  split_ctrandmax(&ctrandmax, &old, &c, &cm);
  g_counter += c;
  g_reserve -= cm;
  old = merge_ctrandmax(0, 0);
  atomic_set(&ctrandmax, old);
}

static void flush_local_count(void)
{
  int c;
  int cm;
  int old;
  int t;
  int zero;
  
  if (g_reserve == 0)
    return;
  zero = merge_ctrandmax(0, 0);

  for_each_thread(t)
    if (counterp[t] != NULL) {
      // initializes countermax with zero
      old = atomic_xchg(counterp[t], zero);
      // update g_counter and g_reserve
      split_ctrandmax_int(old, &c, &cm);
      g_counter += c;
      g_reserve -= cm;
    }
}

static void balance_count(void)
{
  int c;
  int cm;
  int old;
  unsigned long limit;
  
  limit = g_countermax - g_counter - g_reserve;
  limit /= num_online_threads();
  if (limit > MAX_COUNTERMAX)
    cm = MAX_COUNTERMAX;
  else
    cm = limit;
  g_reserve += cm;
  c = cm / 2;
  if (c > g_counter)
    c = g_counter;
  g_counter -= c;
  old = merge_ctrandmax(c, cm);
  atomic_set(&ctrandmax, old);
}

void count_register_thread(void)
{
  int idx = smp_thread_id();
  spin_lock(&gblcnt_mutex);
  counterp[idx] = &ctrandmax;
  spin_unlock(&gblcnt_mutex);
}

void count_unregister_thread(int nthreadsexpected)
{
  int idx = smp_thread_id();
  spin_lock(&gblcnt_mutex);
  globalize_count();
  counterp[idx] = NULL;
  spin_unlock(&gblcnt_mutex);
}
```
由于`flush_local_count()`允许某个thread操作其他thread的pre-thread variables, 因而需要使用atomic operations来操作pre-thread variables. 尽管atomic operations让fastpath变慢, 但某些情况下是值得的.
