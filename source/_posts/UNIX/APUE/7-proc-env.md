---
title: Process Environment
tags:
  - Linux
category:
  - Linux
abbrlink: 8ccf
date: 2019-08-29 08:29:12
---

## 1. main Function
一个C语言程序通过调用`main()`启动:
```c
/**
 * @brief start execution function in C program
 * @param argc number of command-line arguments
 * @param argv an array of pointers to the arguments
 */
int main(int argc, char *argv[]);
```
Kernel执行程序时, 会在执行`main()`前运行一个start-up routine. 可执行程序会指定start-up routine作为程序的起始地址. Start-up routine由C compiler设置, 从kernel中获得命令行参数和环境变量, 进行初始化工作(如初始化Standard I/O stream等), 并调用`main()`.


## 2. Process Termination
以下是几种中止进程的方式:
* 正常退出程序:
  * 从`main()`返回
  * 调用`exit()`, `_exit()`, 或`Exit()`
  * start routine返回最后一个线程
  * 最后一个线程调用`pthread_exit()`
* 非正常中止程序:
  * 调用`abort()`
  * 收到signal
  * 最后一个线程对cancellation request作响应

### 2.1 Exit Function
```c
/**
 * @brief cause normal process termination and the least 
 *        significant byte of status (status & 0xFF) is 
 *        returned to the parent. 
 *        All open streams are flushed and closed. Files 
 *        created by tmpfile() are removed.
 */
void exit(int status);

/**
 * @brief terminates the calling process immediately. 
 *        * open file descriptor are closed.
 *        * open streams are not flushed
 *        * children process are inherited by init.
 *        * parent process receives a SIGCHLD signal.
 *        * return the least significant byte of status 
 *          to parent process as exit status   
 *        * does not call any function registered with 
 *          atexit() or on_exit()
 */
void _Exit(int status);

/**
 * @brief same as _Exit()
 */
void _exit(int status);
```
ISO C定义了`exit()`和`_Exit()`, POSIX.1定义了`_exit()`, 因此函数定义在不同的header.

### 2.2 atexit Function
正常结束进程时(如调用`exit()`)会自动调用已注册的函数.
```c
/**
 * @brief register the given function to be called at normal 
 *        process termination (call exit() or return from main())
 * @param func the address of a function with no argument 
 *        and return value. Each function is called as many 
 *        times as it was registered.
 * @return 0 on success; nonzero on error.
 */
int atexit(void (*func)(void));
```
* 函数的执行顺序与注册顺序相反, 也就是说, 越晚注册的函数越先执行
* 同一函数可被注册多次, 且会被运行多次
* 执行`fork`后, child process与parent process拥有相同的函数
* 执行`exec`后, 所有注册的函数都会被移除
* 非正常中止进程不会触发注册的函数
* 若某个函数调用`_exit()`, 则不执行后续的函数

需要注意的是, 多次调用`exit()`会导致不可知的结果, 应避免这么做. 以下是C语言程序启动和中止的流程图:
![How a C program is started and how it terminates](/images/UNIX/APUE/7-2-flow-of-c-program.png)


## 3. Environment List
每个程序接收一个argument list(参数列表), 还会接收一个environment list(环境列表).
```c
/**
 * pointer to an array of pointers to string called 
 * "environment". 
 * The last pointer in this array has the value NULL
 */
extern char **environ;
```
environ的每个string按照**name=value**格式, 包含但不限以下字段:
1. USER: 登录用户的名称(一些BSD-derived program使用), 由`login()`设置
2. LOGNAME: 登录用户的名称(一些System-V derived program使用)
3. HOME: user's login directory
4. LANG: locale的名称, 用于locale分类
5. PWD: 当前working directory
6. SHELL: user's login shell的绝对路径

大多数UNIX系统可将environ作为`main()`的第三个参数:
```c
int main(int argc, char *argv[], char *envp[]);
```
但ISO C规定`main()`只能接受两个参数, 且environ作为参数并不比global variable更有优势, 所以通常情况不会将environ作为参数.


## 4. Memory Layout of a C program
一个C语言程序包含多块内存:
![Typical memory arrangement](/images/UNIX/APUE/7-4-memory-layout-of-c-program.png)

* Text Segment: CPU执行的机器指令. 该内存区域为固定大小, 只读, 可被多个进程共享.
* Initialized Data Segment: 初始化的global variable(全局变量)和static local variable(静态变量):
  ```c
  // global variable, outside the main function
  int maxcount = 99;
  ```
* Uninitialized Data Segment: 未初始化的全局变量和静态变量, 由kernel自动初始化, 例如:
  ```c
  // uninitialized global variables, outside the main function
  long sum[1000];
  ```
* Stack: 临时变量. 所有临时变量都在该内存区域生成, 包括地址, 寄存器, 变量. 该内存区域的地址从高位向低位增长.
* Heap: 动态内存分配的变量(malloc或new). 该内存区域的地址从低位向高位增长.


## 5. Shared Libraries
绝大多数UNIX系统支持**shared libraries**, 从而让executable file(执行文件)不必含有某些公共功能的代码实现, 该方式的优缺点如下:
* 优点:
  * 大大减少了文件体积
  * 对shared libraries的修改不需要重新编译整个程序
* 缺点: 增加runtime开销(第一次运行程序或调用shared library时需链接shared libraries). 

```c
gcc -static hello.c // use static libraries
gcc hello.c // gcc defaults to use shared libraries
```


## 6. Memory Allocation
```c
/**
 * @brief allocate `size` bytes and returns a pointer to
 *        the allocated memory. The memory is not initialized.
 * @param size if it is 0, then malloc() returns either NULL,
 *        or a unique pointer value that can later be passed
 *        to free().
 */
void *malloc(size_t size);

/**
 * @brief allocate memory for an array of `nmemb` elements of
 *        `size` bytes each and return a pointer to the 
 *        allocated memory. The memory is set to 0.
 *        If the multiplication of `nmemb` and `size` would
 *        result in integer overflow, then return an error.
 */
void *calloc(size_t nmemb, size_t size);

/**
 * @brief change the size of the memory block pointed to 
 *        by `ptr` to `size` bytes. 
 *        The content will be unchanged in the range from
 *        the start of the region up to the minimum of the
 *        old and new sizes.
 * @param ptr if it is null, then the call is equivalent 
 *        to `malloc(size)`
 * @param size if it is larger than old size, the added 
 *        memory will not be initialized.
 */
void *realloc(void *ptr, size_t size);

/**
 * @brief free the memory space pointed to by `ptr`, which 
 *        must have been returned by a previous call to malloc(),
 *        calloc(), or realloc(). If free() has already been 
 *        called before, undefined behavior occurs.
 * @param ptr if is NULL, no operation is performed
 */
void free(void *ptr);
```
`malloc()`, `calloc`()或`realloc()`申请内存时, 申请的内存空间会比参数`size`大一些, 因为还需放置该区域的空间大小. 当调用free()时一般也不会直接缩小heap空间, 而是暂时保留该区域内存, 用于下次申请时使用.
进程应只对自己申请的内存区域进行操作, 对其他内存空间进行操作会造成不可知的影响. 释放一个已经被释放的内存区域也十分危险, 因为该内存区域可能正被其他进程使用. 只申请不释放内存也存在隐患, 未被释放的内会会造成内存泄漏.


## 7. Environment Variables
UNIX kernel不对environment variable做任何处理, 只有application需要操作environment variable. 例如, shell会用到很多environment variables, 如`HOME`和`USER`.
```c
/**
 * @brief search the environment list to find the environment 
 *        variable `name`, and return a pointer to the 
 *        corresponding `value` string
 * @return a pointer to the corresponding value string
 */
char *getenv(const char *name);

/**
 * @brief change or add the value of environment variables
 * @param str must be the form of "name=value". If name does 
 *        not already exist in the environment, then string is
 *        added to the environment. 
 *        If name does exist, then the value of name in the 
 *        environment is changed to value.
 *        Some implementation may not make copies of the string 
 *        pointed to by `str`
 * @return 0 on success; nonzero on error and errno is set
 */
int putenv(char *str);

/**
 * @brief add the variable `name` to the environment with the 
 *        value `value`, if `name` does not exist. If `name` 
 *        does exist, then its value is changed to value if 
 *        `rewrite` is nonzero.
 *        This function makes copies of the strings pointed to 
 *        by name and value
 */
int setenv(const char *name, const char *value, int rewrite);

/**
 * @brief delete the environment variable `name` from the 
 *        environment.
 *        If `name` does not exist, the current environment 
 *        shall be unchanged
 * @return 0 on success; -1 on error and errno is set
 */
int unsetenv(const char *name);
```


## 8. setjmp and longjmp Functions
C语言中`goto`只能在同一函数内进行逻辑跳转, 若需要跨函数跳转, 则调用`setjmp()`和`longjmp()`, 称为**nonlocal goto**. 每次调用函数时, 会在stack区创建于一个stack frame来放置函数所需的所有数据, 函数间的跳转等同于stack frame的转移. 为回到之前的stack frame, 需先使用`setjmp()`记录当前stack frame, 并保存到`jmp_buf`类型的变量中; `longjmp()`会跳转到最近一次调用`setjmp()`的stack frame, 并修改`setjmp()`的返回值来帮助判断是否为`longjmp()`导致的跳转.
```c
/**
 * @brief save various information about the calling environment
 *        (stack pointer, instruction pointer, values of other 
 *        registers and the signal mask) in the buffer `env` for 
 *        later use by longjmp()
 * @return 0 when called directly; nonzero when called by longjmp()
 */
int setjmp(jmp_buf env);

/**
 * @brief use the information saved in `env` to transfer control 
 *        back to the point where setjmp() was called to retore 
 *        the stack to its state at the time of the setjmp() call
 * @param val should not be 0
 */
void longjmp(jmp_buf env, int val);
```
由于`env`需在不同的函数中使用, 所以应为global variable. 需要注意的是, 调用`longjmp()`后, `setjmp()`所在函数内的local variable和register variable不一定保留修改后的值, 绝大多数情况下, 编译器不会回滚local variable和register variable.
GCC编译时, 若使用`Optimization`选项, 会导致`setjmp()`所在函数内的所有local variable和register variable回滚, 但不会影响global variable, static variable, 和volatile variable. 


## 9. getrlimit and setrlimit Functions
每个进程的资源都有上限值, 可通过以下函数对上限值进行操作:
```c
struct rlimit {
  rlim_t rlim_cur; /* soft limit: current limit */
  rlim_t rlim_max; /* hard limit: maximum value for rlim_cur */
};

/**
 * @brief get resource limits
 * @param resource the type of resource
 */
int getrlimit(int resource, struct rlimit *rlptr);

/**
 * @brief set the limits on the consumption of a variety of 
 *        resources
 */
int setrlimit(int resource, const struct rlimit *rlptr);
```
以下是进程资源的一些规则:
* 子进程会继承父进程的上限值
* 每个线程都会共享进程的上限值
* 将soft limit调至当前进程已拥有的资源量以下也不会失败

`setrlimit()`的`rlptr`参数遵循以下规则:
* $\text{soft limit} \le \text{hard limit}$
* 进程可降低hard limit, 但必须遵守上一条规则
* 只有superuser才能提高hard limit

`getrlimit()`和`setrlimit()`的`resource`参数必须为以下之一:
* RLIMIT_AS: 进程的virtual memory(地址空间)的最大值, 以byte为单位, 向下取整至page大小(虚拟内存的最小单元)
* RLIMIT_CORE: core文件(包含非正常程序退出时产生的core dump)的最大体积, 单位为byte. 若设为0, 则不会生成core file; 若core dump超出体积上限则截断.
* RLIMIT_CPU: 进程占用CPU的单次最长运行时间, 单位为秒. 但进程达到soft limit, 会向进程发送`SIGXCPU` signal, 该信号会中止进程, 但可捕获, 因此程序可决定是否继续执行; 若进程继续执行, 接下来每秒都会收到`SIGXCPU`, 直到达到hard limit, 进程收到`SIGKILL`.
* RLIMIT_DATA: data segment的最大体积, 单位为byte, 向下取整至page大小, 该值会影响`brk()`, `sbrk()`, 和`mmap()`
* RLIMIT_FSIZE: 进程创建文件的最大体积, 单位为byte, 超出限制时进程收到`SIGXFSZ` signal
* RLIMIT_MEMLOCK: 进程将虚拟内存常驻在RAM的最大空间, 单位为byte, 该值会影响`mlock()`, `mlockall()`, 和`mmap()`
* RLIMIT_MSGQUEUE: POSIX message queue所能使用的最大内存空间, 单位为byte
* RLIMIT_NICE: `nice()`所能设置的最大nice值, 实际nice值上限为`20 - rlim_cur`
* RLIMIT_NOFILE: 进程所能打开的最大file descriptor数量
* RLIMIT_NPROC: 当前进程所能创建的最大线程数
* RLIMIT_NPTS: 当前进程能打开的最大pseudo terminal数量
* RLIMIT_RSS: 最大RSS(resident set size, 进程占用RAM的空间, 剩余空间放置在swap space)
* RLIMIT_SBSIZE: 当前进程所拥有的最大socket buffer空间
* RLIMIT_SIGPENDING: 等待当前进程接收的最大signal队列长度
* RLIMIT_STACK: 最大stack空间, 单位为byte
* RLIMIT_SWAP: 当前进程所能拥有的最大swap空间
