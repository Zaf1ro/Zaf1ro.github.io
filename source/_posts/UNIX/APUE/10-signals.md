---
title: Signals
category:
  - UNIX
  - APUE
tags:
  - UNIX
abbrlink: 277e
date: 2019-09-17 14:12:52
---

## 1. Introduction
电子计算机中, **interrupt**(也称为**trap**)会请求中断CPU正在执行的代码, 以便及时处理事件. 若interrupt被接受, CPU会暂停当前活动, 保存其状态, 并执行一个interrupt handler来处理该事件. interrupt通常比较短暂, 允许中断处理完毕后恢复原本的程序. Interrupt通常由硬件设备生成, 用于标识外部设备的状态变化.
Signal是软件层面的interrupt, 其是一种处理异步事件的方式, 大多数应用程序都需要处理signal. UNIX系统的早期版本就支持signal, 但并不可靠, signal会丢失, 且进程执行某些关键代码时无法屏蔽特定signal. 4.3BSD和SVR3对signal model做出了调整, 让其变得可靠. POSIX.1标准化了signal model.


## 2. Signal Concepts
* 每个signal都有一个名字, 以**SIG**开头. 例如:
  * `SIGABRT`: 进程调用`abort()`时产生的abort signal
  * `SIGALRM`: `alarm()`设置的timer响起产生的alarm signal
  FreeBSD 8.0支持32种不同的signal. Mac OS X 10.6.8和Linux 3.2.0支持31种signal, 而Solaris 10支持40种signal. FreeBSD, Linux, 和Solaris支持应用程序自定义的signal.
* signal以正整数常数的形式定义在`<signal.h>`中
  * 实现上, 不同signal定义在不同header文件中, 但都包含在`<signal.h>`中
  * kernel不应包含应用程序的header文件, 因此signal包含在kernel的header文件中, 再包含在用户级的header文件中:
    * `<sys/signal.h>`: FreeBSD 8.0和Mac OS X 10.6.8
    * `<bits/signum.h>`: Linux 3.2.0
    * `<sys/iso/signal_iso.h>`: Solaris 10
* signal不能为0, `kill()`的参数0表示process group中的所有进程, POSIX.1将其命名为null signal
* 以下是生成signal的几种方式:
  * 当用户按下某些按键时, 会生成terminal-generated signal. 例如: DELETE或Control-C会生成`SIGINT`
  * 硬件异常生成的signal. 硬件检测到异常后会通知kernel, kernel生成相应的signal. 例如, 访问无效内存地址时生成`SIGSEGV`
  * `kill()`允许一个进程向另一个进程发送signal, 通常用于中止background process.
  * 软件层面检测到异常会生成signal, 例如: 
    * `SIGURG`: out-of-band数据通过网络连接成功传输时产生该signal
    * `SIGPIPE`: 进程向pipe写入数据, 但没有reader时生成该signal
    * `SIGALRM`: 进程设置的alamrm clock到时间时生成该signal

Signal作为一种经典的异步事件, 随时都可能发生, 因此进程无法通过检查一个变量(如`error`)来判断signal是否到来; 进程必须告诉kernel: 出现signal时应如何处理.

### 2.1 Signal Disposition
以下是处理signal的三种方式:
* 无视signal: 除了`SIGKILL`和`SIGSTOP`, 其他signal均可被忽略或捕获
  * 上面两个signal为kernel和superuser提供了中止进程的方式, 因此无法被忽略
  * 无视硬件异常产生的signal可能导致undefined behavior.
* 捕获signal: 为捕获signal, 程序必须传给kernel一个signal-catching function(signal捕获函数), 该函数用于处理某一signal的情况
  * signal通常表示该进程之外突发的事件, 例如: 当进程接收到`SIGCHLD`, 说明其child process已中止, 因此signal-catching function中需调用`waitpid()`获取child process的PID和termination status
  * 当进程创建临时文件时, 需在`SIGTERM`(`kill()`发出的termination signal)的signal-catching function内清理临时文件
* 默认操作: 每个signal都有一个默认操作, 绝大多数signal的默认操作为**中止进程**

### 2.2 UNIX System Signals
以下是所有signal的详细信息:

| Name | Description | Default Action | 
| :-----: | :-----: | :-----: |
| SIGABRT | `abort()`生成, 进程异常退出 | terminate+core |
| SIGALRM | `alarm()`或`setitimer()`创建的timer超时后生成 | terminate |
| SIGBUS | 表示硬件错误, 通常由某些类型的内存故障生成 | terminate+core | 
| SIGCHLD | 进程暂停或中止时向parent process发送该signal, 若parent process需要得知child process的状态变化, 可在handler内调用`wait()` | ignore | 
| SIGCONT | 让暂停的进程继续运行, 进程无法阻塞该signal |  continue/ignore | 
| SIGFPE | 算数异常引发的signal, 例如: 除零活浮点溢出 | terminate+core | 
| SIGHUP | 与terminal中断时向session leader发送该signal. session leader进程终止时会向foreground process group中的所有进程发送该signal | terminate |
| SIGEMT | hardware fault触发的signal, 视系统而定 | terminate+core | 
| SIGILL | 进程执行非法硬件指令时发送该signal | terminate+core |
| SIGINFO | 当用户按下status key(通常为Control-T)时, terminal driver向foreground process group中的所有进程发送该signal, 通常用于获取foreground process group中所有进程的状态信息 | ignore | 
| SIGINT | 当用户按下interrupt key(通常为Control-C)时, terminal driver向foreground process group中的所有进程发送该signal, 用于中止失控的程序 | terminate |
| SIGQUIT | 当用户按下terminal quit key(通常为Control-backslash)时, terminal driver向foreground process group中的所有进程发送该signal, 通常会中止foreground process group的所有进程, 并生成core文件 | terminate+core |
| SIGIO | 异步I/O事件(例如file descriptor准备写入或输出) | terminate/ignore |
| SIGIOT | 硬件故障 | terminate+core |
| SIGKILL | kill进程, 无法被捕获或无视 | terminate |
| SIGPIPE | 进程向pipe或FIFO写入数据, 但pipe的reader已中止 | terminate |
| SIGPWR | 断电时uninterruptible power supply(UPS)提供电力, 或电量过低 | terminate/ignore |
| SIGSEGV | 进程进行了无效内存引用 | terminate+core |
| SIGSTOP | 用于暂停进程, 无法被捕获或无视 | stop process |
| SIGSYS | 进程调用非法的system call | terminate+core |
| SIGTERM | kill触发, 通知进程终止运行, 用于调用结束前的清理工作 | terminate |
| SIGTRAP | hardware fault触发的signal, 视系统而定 | terminate+core |
| SIGTSTP | 按下terminal suspend key(Control-Z)触发该signal, 用于停止进程运行 | stop process |
| SIGTTIN | background process group中的进程尝试读取controlling terminal的数据 | stop process |
| SIGTTOU | background process group中的进程尝试写入controlling terminal | stop process |
| SIGURG | 表示发生紧急情况, 接收到out-of-band data时也生成该signal | ignore |
| SIGUSR1 | 用户自定义的signal | terminate |
| SIGUSR2 | 用户自定义的signal | terminate |
| SIGVTALRM | `setitimer()`创建的virtual interval timer超时 | terminate |
| SIGWINCH | 进程调用`ioctl()`修改terminal的window size时, kernel向foreground process group中的所有进程发送该signal | ignore |
| SIGXCPU | 进程超过soft CPU time limit | terminate or terminate+core |
| SIGXFSZ | 进程超过soft file size limit| terminate or terminate+core |

表格中`terminate`表示中止进程; core表示在进程的工作目录中创建一个名为**core**的文件, 其中保存进程的内存映像, 该文件用于debugger检查进程被中止时的状态; stop表示暂停当前进程.
以下情况不会生成core文件:
* 程序设置了set-user-ID, 但当前用户不是程序所有者
* 程序设置了set-group-ID, 但当前用户不是程序所有者
* 用户无权写入当前目录
* core文件已存在, 且用户无权写入
* core体积过大


## 3. signal Function
```c
typedef void (*sighandler_t)(int);

/**
 * @brief set the disposition of the signal `signum` to 
 *        `handler`, which is either SIG_IGN, SIG_DFL, 
 *        or the address of a function
 * @param handler one of the following options:
 *        * SIG_IGN: ignore the signal
 *        * SIG_DFL: use the default action
 *        * address of function: call the func when 
 *          the signal occurs
 */
sighandler_t signal(int signum, sighandler_t handler);
```

### 3.1 Program Start-Up
启动程序时, 所有signal都是默认行为. 调用`exec`时, 会有三种情况:
* 进程忽略某个signal, `exec`执行的程序仍忽略该signal
* 进程捕获某个signal, `exec`执行的程序将其改为默认行为
* 进程采用默认行为处理signal, `exec`执行的程序仍采用默认行为

由于`exec`不保存原程序的内存空间, 因此任何自定义的signal handler都会改为默认行为. 若shell不支持job control, 用户执行background process时(如`cc main.c &`), shell会将interrupt signal和quit signal的行为设置为**ignore**, 这样用户按下interrupt character时, background process不会受到影响.
`signal()`存在一个限制: 在不修改当前signal handler的前提下, 无法得知该signal的handler, 因此引入了`sigaction()`.

### 3.2 Process Creation
当进程调用`fork()`时, child process会继承parent process的signal handler. 由于child process会复制parent process的内存映像, signal handler的地址也会复制到child process中.


## 4. Unreliable Signals
早期UNIX系统的signal不可靠: 生成signal, 但进程没有接收到, 其中一个问题在于: 生成signal后, 会将handler重置为默认动作, 因此handler被调用后需调用`signal()`重新设置. 由于signal handler并不是一个原子操作, 因此会产生竞争:
```c
int sig_int(); /* signal handler */
signal(SIGINT, sig_int); /* establish handler */

sig_int()
{
  signal(SIGINT, sig_int); /* reestablish handler for next time */
  /* process the signal ... */
}
```
上述代码中, 调用`sig_int()`时会立刻调用`signal()`重新设置signal handler, 但存在一个特殊情况: 调用`sig_int()`之后与调用`signal()`之前存在一个时间间隙, 此时若生成`SIGINT`, 会使用默认行为处理该signal, 而不是调用`sig_int()`.
早期UNIX系统还存在一个问题: 进程没有一个atomic pause function. 以下面代码为例:
```c
int sig_int(); /* my signal handling function */
int sig_int_flag = 0; /* set nonzero when signal occurs */

main()
{
  signal(SIGINT, sig_int); /* establish handler */
  /* ... */
  while (sig_int_flag == 0)
    pause(); /* go to sleep, waiting for signal */
  /* ... */
}

sig_int()
{
  signal(SIGINT, sig_int); /* reestablish handler for next time */
  sig_int_flag = 1; /* set flag for main loop to examine */
}
```
进程调用`pause()`进入睡眠状态, 捕获到`SIGINT`时进程被唤醒, signal handler将`sig_int_flag`设置为非零值, 因此不会再次陷入休眠. 但存在一种特殊情况: **进入while循环之后**和调用pauae()之前存在一个时间间隙, 若此时接收到`SIGINT`, 则`sig_int_flag`变为非零值, 且调用`pause()`后进程永远不会醒来.


## 5. Interrupted System Calls
早期UNIX系统中, 若进程被一个较慢的system call阻塞时收到signal, 该system call会被中断, 返回错误并将`errno`设置为`EINTR`.

### 5.1 Slow System Calls
system call分为两种: **slow system call**和**fast system call**. slow system call会一直阻塞进程, 直到完成操作, 如下:
* 读取文件但当前没有数据(pipes, terminal device, 和network device)
* 写入文件但数据不能立即被接受(buffer溢出或其他原因)
* 打开文件但需要满足某些条件(modem响应后才可打开terminal device)
* 调用`pause()`或`wait()`
* 部分`ioctl()`操作
* 部分IPC函数

Disk I/O并不算作slow system call, 虽然读取或写入一个磁盘文件会暂时阻塞进程, 但除非硬件出错, I/O操作会很快返回.
可被中断的system call存在一个问题: 我们必须显式处理返回的错误. 假设被中断时需要重新数据, 如下:
```c
again:
  if ((n = read(fd, buf, BUFFSIZE)) < 0) {
    if (errno == EINTR)
      goto again; /* just an interrupted system call */
    /* handle other errors */
  }
```

### 5.2 Automatic Restarts of Interrupted System Calls
4.2BSD引入了新机制: 自动重启被中断的system call. 以下是可自动重启的system call:
* 只在slow device上才能被signal中断的函数:
  * `ioctl`
  * `read`
  * `readv`
  * `write`
  * `writev`
* 总会被signal中断的函数:
  * `wait`
  * `waitpid`

有些应用程序不想在signal打断时自动重试, 4.3BSD允许进程关闭该特性. POSIX.1要求system call只有设置了`SA_RESTART`时才会在signal中断时重试. 该flag可通过调用`sigaction()`设置.
对于可被signal中断的system call, 不同系统上的实现各不相同: System V默认不会重试被中断的system call; BSD则默认重试被中断的system call. FreeBSD 8.0, Linux 3.2.0和Mac OS X 10.6.8只会重试部分被signal打断的system call, 这些signal必须调用`signal()`注册了handler.
4.2BSD之所以选择自动重试system call, 因为有时用户并不清楚输入或输出设备是否为slow device. 以下是不同UNIX系统实现下的signal函数及其语义.
![signal function and their semantics](/images/UNIX/APUE/10-5-signal-semantics.png)


## 6. Reentrant Functions
进程收到signal后, 正在运行的指令会被signal handler中断. handler运行结束后会继续执行被暂停的命令, 与硬件中断类似.
在signal handler中, 我们无法得知当前进程执行到哪一步:
* 若进程在运行`malloc()`时收到signal, 并将执行权转移给signal handler, signal handler中再次调用`malloc()`, 从而导致进程中的`malloc()`维护的列表被中途修改, 进而导致无法预测的异常.
* 进程正在执行某个函数, 如`getpwnam()`, 该函数会将运行结果保存在一个静态位置, 而signal handler内也会执行该函数, 从而导致进程的运行结果被signal handler覆盖.

The Single UNIX Specification规定了signal handler内可安全使用的函数, 这些函数都是reentrant(可重入的), 被称为**async-signal safe**. 以下是所有的reentrant functions:
![Reentrant functions that may be called from a signal handler](/images/UNIX/APUE/10-6-reentrant-func.png)

大部分函数都没有囊括在内, 主要因为以下几点原因:
1. 使用了static data structure
2. 调用了`malloc()`或`free()`
3. standard I/O library的一部分

使用上述函数时需主要几点:
* standard I/O library的大多数实现都会用到global data structure
* 即使在signal handler内使用安全函数, 也需要注意: 每个线程只有一个`errno`变量, 例如, signal handler内调用`read()`可能会修改`main()`的`errno`值. 因此在signal handler内调用函数时要保存并之后恢复`errno`
* `longjmp`和`siglongjmp`不是安全函数, 因为进程收到signal时可能正在更新某个data structure. 调用`siglongjmp`会让进程执行其他操作, 而不是继续未完成的data structure.


## 7. SIFCLD Semantics
`SIGCLD`和`SIGCHLD`存在一些混淆: `SIGCLD`源自System V, 与BSD的`SIGCHLD`有不同的语义. POSIX.1也命名为`SIGCHLD`.
当child process状态发生变化时, parent process会收到`SIGCHLD`, parent process可通过调用`wait()`获取child process的termination status. 
System V处理`SIGCLD`的方式则不同: 
1. SIG_DFL: `SIGCLD`的默认动作为无视该signal, 但也不会丢弃该signal, parent process可用`wait()`来获取child parent的信息, 否则child process变为zombie.
2. SIG_IGN: 若将`SIGCLD`的handler设置为`SIG_IGN`, 则child process的信息会被无视并丢弃. `wait()`会阻塞parent process, 直到child process中止, 并将`errno`设为`ECHILD`, child process不会变为zombie.
3. 自定义处理方式: kernel会在`signal()`执行后立即检查是否存在child process状态改变.


## 8. Reliable-Signal Terminology and Semantics
以下是有关signal的一些名词定义:
* 发生某些事件时, 会向进程**generate**(生成)对应的signal, 以下是可触发signal的事件:
  * 硬件故障
  * 软件状况(alarm timer到时间)
  * terminal-generated signal
  * 调用`kill()`
* 当需要对signal采取行动时, 会向进程**deliver**(发送)signal
* signal的generate和delivery之间的时间称为**pending**(待定)
* 进程可以选择**block**(阻塞)signal的delivery. 若signal被阻塞, 且signal的handler为默认行为或捕获signal, 则signal维持pending状态, 直到:
  * 进程unblock(解除阻塞)signal
  * 将signal handler改为`SIG_IGN`(忽略该signal)
* 只有delivery时系统才判断是否将signal阻塞, 而不是generate, 这么做允许进程在signal发送前修改signal的handler. `sigpending()`可可查看哪些signal被block或处于pending状态.
* 若进程解除阻塞signal前, 已存在多个被阻塞signal, POSIX.1允许系统向该进程传递一次或多次signal. 若系统传递signal多次, 我们可以说signal被queue(排队). 绝大多数UNIX系统不会对signal排队, 只会传递一次signal.
* POSIX.1没有规定signal的传递顺序, 因此, 与进程当前状态相关的signal会比其他signal提前到达.
* 每个进程都有一个signal mask, 其决定了哪些signal可以被传递给当前进程, 哪些signal被阻塞. 每种signal占一个bit, 若bit为1, 表示该signal被阻塞. 进程可调用`sigprocmask()`来检查和修改signal mask. 由于signal数量超出integer的bit数, POSIX.1规定了一种新的数据类型: `sigset_t`.


## 9. kill and raise Functions
```c
/**
 * @brief send any signal to any process or process. 
 *        group. A process needs permission to send
 *        a signal:
 *        * The superuser can send a signal to any 
 *          process
 *        * The RUID or EUID of the sending process
 *          must equal the RUID or saved set-user-ID
 *          of the target process
 * @param pid must be one of the following value
 *        * pid > 0: signal is sent to the process  
 *          with the ID specified by pid
 *        * pid = 0: no signal is sent, but but  
 *          existence and permission checks are still
 *          performed
 *        * pid = -1: signal is sent to all process 
 *          for which the calling process has permission
 *          to send signals, except for init
 *        * pid < -1: signal is sent to every process 
 *          in the process group whose ID is -pid
 */
int kill(pid_t pid, int signo);

/**
 * @brief send a signal to the calling process. In a 
 *        single-threaded program it is equivalent to
 *        kill(getpid(), signo);
 */
int raise(int signo);
```
若`kill()`的参数`signo`为0, `kill()`不会发送任何signal, 但会检查其他错误, 通常用于检查目标进程是否存在; 若目标进程不存在, `kill()`返回-1, 并将`errno`设为`ESRCH`.


## 10. alarm and pause Functions
```c
/**
 * @brief arrange for a SIGALRM signal to be delivered 
 *        to the calling process in `sec` seconds.
 * @param sec if it is 0, any pending alarm is canceled
 * @return return the number of seconds remaining until
 *         any previously scheduled alarm was due to be
 *         delivered, or zero if there was no previously
 *         scheduled alarm.
 */
unsigned int alarm(unsigned int sec);

/**
 * @brief suspend the calling thread until a signal
 * @return -1 on error and errno is set
 */
int pause(void);
```
* 每个进程的线程共享一个timer, 因此`alarm()`会覆盖当前正在运行的timer, 并返回之前timer剩余的时间
* `alaram()`和`setitimer()`共享一个timer, 调用其中一个函数会影响另一个函数. 
* `execve()`会保留`alarm()`生成的timer, 但`fork()`不会保留
* `sleep()`可能使用`SIGALRM`, 因此不要混用`sleep()`和`alarm()`
* 由于`SIGALRM`的默认中止进程, 因此大多数进程都会选择捕获该信号

### 10.1 sleep1 example
使用`alarm()`和`pause()`可实现一个简易sleep function
```c
#include <signal.h>
#include <unistd.h>

static void sig_alrm(int signo)
{
  /* nothing to do, just return to wake up the pause */
}

unsigned int sleep1(unsigned int seconds)
{
  if (signal(SIGALRM, sig_alrm) == SIG_ERR)
    return seconds;
  alarm(seconds);   /* start the timer */
  pause();          /* next caught signal wakes us up */
  return alarm(0);  /* turn off timer, return unslept time */
}
```
上述代码存在三个问题:
* 调用`alarm()`会替代进程设置的timer, 需保存`alarm()`的返回值并依情况而定: 
  * 若返回值小于`seconds`, 则需等待之前timer
  * 若返回值大于`seconds`, 则在`sleep1()`返回前调用`alarm()`完成接下来的倒计时
* `sleep1()`调用`signal()`修改`SIGALRM`的handler, 需保存`signal()`的返回值, 并在`sleep1()`返回前恢复之前的handler
* 第一次调用`alarm()`与`pause()`之间存在竞争条件, 若调用`pause()`之前进程收到signal, 进程会被一直挂起

### 10.2 sleep2 example
以下是修改过后的sleep function:
```c
#include <setjmp.h>
#include <signal.h>
#include <unistd.h>

static jmp_buf env_alrm;

static void sig_alrm(int signo)
{
  longjmp(env_alrm, 1);
}

unsigned int sleep2(unsigned int seconds)
{
  if (signal(SIGALRM, sig_alrm) == SIG_ERR)
    return seconds;
  if (setjmp(env_alrm) == 0) {
    alarm(seconds); /* start the timer */
    pause(); /* next caught signal wakes us up */
  }
  return alarm(0); /* turn off timer, return unslept time */
}
```
上述代码还存在一个隐患: 若`SIGALRM`还存在其他handler, 处理完signal后调用`longjmp()`不会还原进程设置的handler.
`alarm()`一般用于中断I/O操作, 如下:
```c
int main(void)
{
  int n;
  char line[MAXLINE];
  if (signal(SIGALRM, sig_alrm) == SIG_ERR)
    err_sys("signal(SIGALRM) error");
  
  alarm(10);
  if ((n = read(STDIN_FILENO, line, MAXLINE)) < 0)
    err_sys("read error");
  alarm(0);
  
  write(STDOUT_FILENO, line, n);
  exit(0);
}

static void sig_alrm(int signo)
{
  /* nothing to do, just return to interrupt the read */
}
```
某些UNIX系统的`read()`会自动启动, 则`SIGALRM`无法打断`read()`, 仍需调用`longjmp()`


## 11. Signal Sets
**signal set**是一种表示多个signal的数据类型, 用于`sigprocmask()`阻塞某些signal. 以下是设置`sigset_t`的函数:
```c
/**
 * @brief initialize and empty a signal set
 */
int sigemptyset(sigset_t *set);

/**
 * @brief initialize the signal set pointed to by set
 */
int sigfillset(sigset_t *set);

/**
 * @brief add a signal to a signal set
 */
int sigaddset(sigset_t *set, int signo);

/**
 * @brief delete a signal from a signal set
 */
int sigdelset(sigset_t *set, int signo);

/**
 * @brief test whether the signal specified by `signo`
 *        is a member of the set pointed to by `set`
 * @return 1 if the specified signal is a member of 
 *         the specified set, or 0 if it is not
 */
int sigismember(const sigset_t *set, int signo);
```
以下是`<signal.h>`的实现:
```c
#define sigemptyset(ptr) (*(ptr) = 0)
#define sigfillset(ptr) (*(ptr) = ˜(sigset_t)0, 0) // return 0

#define SIGBAD(signo) ((signo) <= 0 || (signo) >= NSIG)

int sigaddset(sigset_t *set, int signo)
{
  if (SIGBAD(signo)) {
    errno = EINVAL;
    return -1;
  }
  *set |= 1 << (signo - 1); /* turn bit on */
  return 0;
}

int sigdelset(sigset_t *set, int signo)
{
  if (SIGBAD(signo)) {
    errno = EINVAL;
    return -1;
  }
  *set &= ˜(1 << (signo - 1)); /* turn bit off */
  return 0;
}

int sigismember(const sigset_t *set, int signo)
{
  if (SIGBAD(signo)) {
    errno = EINVAL;
    return -1;
  }
  return (*set & (1 << (signo - 1))) != 0;
}
```


## 12. sigprocmask Function
```c
/**
 * @brief fetch and/or change the signal mask of the
 *        calling thread
 * @param how the way in which the set is changed,  
 *        shall be one of the following values:
 *        * SIG_BLOCK: The set of blocked signals is 
 *          the union of the current set and the `set`
 *          argument
 *        * SIG_UNBLOCK: The signals in `set` are 
 *          removed from the current set of blocked
 *          signals
 *        * SIG_SETMASK: The set of blocked signals 
 *          is set to the argument set.
 * @param set if it is null, then signal mask is 
 *        unchanged, the current value of the signal 
 *        mask is returned in `oldset`
 * @param oset if it is not null, the previous mask 
 *        is stored in `oldset`
 */
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
```


## 13. sigpending Function
```c
/**
 * @brief return the signal set that are blocked from 
 *        delivery to the calling thread in the location 
 *        pointed to by set
 * @return 0 on success; -1 on error and errno is set
 */
int sigpending(sigset_t *set);
```


## 14. sigaction Function
```c
struct sigaction {
  /* signal handler, SIG_IGN, or SIG_DFL */
  void (*sa_handler)(int);
  /* a mask of signals which should be blocked */
  sigset_t sa_mask;
  /* a set of flags which modify the behavior of the signal */
  int sa_flags;            
  /* alternative real-time handler */
  void (*sa_sigaction)(int, siginfo_t *, void *);
};

/**
 * @brief change the action taken by a process on 
 *        receipt of a specific signal
 * @param signum the signal and can be any valid 
 *        signal except SIGKILL and SIGSTOP
 * @param act if not null, it points to a structure 
 *        specifying the action to be assiocated 
 *        with the specified signal
 * @param oldact is non-NULL, the previous action 
 *        is saved in oldact
 */
int sigaction(int signum, const struct sigaction *act,
              struct sigaction *oldact);
```
若`sigaction()`的参数`act`为NULL, 用于查询当前signal handler. 以下是`sigaction struct`中`sa_flags`的可选项:

| Option | Description |
| :-----: | :-----: |
| SA_INTERRUPT | 不会重试被目标signal打断的system call |
| SA_NOCLDSTOP | 若signum为`SIGCHLD`, child process停止或恢复运行时不产生`SIGCHLD` |
| SA_NOCLDWAIT | 若signum为`SIGCHLD`, child process中止时不将其变为zombie |
| SA_NODEFER | 进程执行目标signal的signal handler时, 不将该signal加入signal mask中 |
| SA_ONSTACK | 若存在可用的alternative signal stack(`sigaltstack()`生成), 则使用该stack的signal handler. |
| SA_RESETHAND | 将目标signal的handler改为`SIG_DFL`(默认行为), 并清除signal handler的`SA_SIGINFO` flag |
| SA_RESTART | 自动重试被目标signal打断的system call |
| SA_SIGINFO | `act`使用`sa_sigaction`, 而不是`sa_handler` |

通常signal handler的类型如下:
```c
void handler(int signo);
```
若sigaction struct中设置`SA_SIGINFO`, 则signal handler的函数类型变为:
```c
void handler(int signo, siginfo_t *info, void *context);
```
`siginfo` struct包含signal如何生成的原因. 所有遵循POSIX.1的UNIX系统都至少包含`si_signo`和`si_code`. 以下是`siginfo` struct的定义:
```c
struct siginfo {
  int si_signo;  /* signal number */
  int si_errno;  /* if nonzero, errno value from errno.h */
  int si_code;   /* additional info (depends on signal) */
  pid_t si_pid;  /* sending process ID */
  uid_t si_uid;  /* sending process real user ID */
  void *si_addr; /* address that caused the fault */
  int si_status; /* exit value or signal number */
  union sigval si_value; /* application-specific value */
  /* possibly other fields also */
};

union sigval {
	int sival_int; // an integer value
	void *sival_ptr; // or a pointer value
};
```
* 若handler的`signo`为`SIGCHLD`, 将会设置`si_pid`, `si_status`, 和`si_uid`
* 若handler的`signo`为`SIGBUS`, `SIGILL`, `SIGFPE`, 或`SIGSEGV`, 将会在`si_addr`设置出错的地址
* `si_errno`包含导致该signal的错误码

`context`参数是一个无类型指针, 可转换为`ucontext_t` struct, 在signal传递时标识上下文:
```c
/* pointer to context resumed when this context returns */
ucontext_t *uc_link;
/* signals blocked when this context is active */ 
sigset_t uc_sigmask; 
stack_t uc_stack; /* stack used by this context */
/* machine-specific representation of saved context */
mcontext_t uc_mcontext;
```

### 14.1 Example: signal Function
使用`sigaction()`可实现`signal()`功能:
```c
Sigfunc *signal(int signo, Sigfunc *func)
{
  struct sigaction act, oact;
  act.sa_handler = func;
  sigemptyset(&act.sa_mask); /* initialize sa_mask */
  act.sa_flags = 0;
  if (signo == SIGALRM) {
#ifdef SA_INTERRUPT
    act.sa_flags |= SA_INTERRUPT;
#endif
  } else {
    act.sa_flags |= SA_RESTART;
  }
  if (sigaction(signo, &act, &oact) < 0)
    return SIG_ERR;
  return oact.sa_handler;
}
```
* 必须使用`sigemptyset`初始化`sa_mask`, 因为`sa_mask = 0`不一定表示空白的signal mask
* 上述代码为除`SIGALRM`之外的signal设置`SA_RESTART` flag, 因此所有被signal终端的system call都会自动重试.
* 部分UNIX系统定义了`SA_INTERRUPT` flag, 系统会自动重试被中断的system call, 只有设置该flag才能放弃重试.

### 14.2 Example: signal_intr Function
以下代码可防止被signal中断的system call重试:
```c
Sigfunc *signal_intr(int signo, Sigfunc *func)
{
  struct sigaction act, oact;
  act.sa_handler = func;
  sigemptyset(&act.sa_mask);
  act.sa_flags = 0;
#ifdef  SA_INTERRUPT
  act.sa_flags |= SA_INTERRUPT;
#endif
  if (sigaction(signo, &act, &oact) < 0)
    return(SIG_ERR);
  return(oact.sa_handler);
}
```


## 15. sigsetjmp and siglongjmp Functions
`longjmp()`通常用于从signal handler跳转至`main()`, 但`longjmp()`存在一个缺陷: 当进程收到signal时, 会开始执行handler, 并自动该signal加入signal mask, 以避免后续signal打断handler. 调用`longjmp()`从signal handler跳出时, 由于POSIX.1没有定义`setjmp()`和`longjmp()`是否处理signal mask, 不同UNIX系统会有不同行为:
* FreeBSD 8.0, Mac OS X 10.6.8: `setjmp()`保存当前signal mask, `longjmp()`恢复signal mask
* Linux 3.2.0, Solaris 10: `setjmp()`和`longjmp()`不保存和恢复signal mask
* FreeBSD和Mac OS X提供了`_setjmp()`和`_longjmp()`, 这两个函数不会保存和恢复signal mask

为统一行为, POSIX.1提供了专门用于signal handler内的跳转函数:
```c
/**
 * @brief set jump point for a non-local goto
 * @param savemask if it is not 0, save the current
 *        signal mask of the calling thread as part
 *        of the calling environment.
 */
int sigsetjmp(sigjmp_buf env, int savemask);

/**
 * @brief non-local goto with signal handling. 
 *        restore the saved signal mask if and only
 *        if the `env` argument was initialized by
 *        a call to `sigsetjmp()` with a non-zero
 *        `savemask` argument
 */
void siglongjmp(sigjmp_buf env, int val);
```


## 16. sigsuspend Function
之前我们讨论了如何block或unblock某个signal, 该方法可保证关键代码区不被signal中断, 但如果想要unblock某个signal, 如何收到之前被block的signal? 假设目标signal为`SIGINT`, 以下为错误代码:
```c
sigset_t newmask, oldmask;

sigemptyset(&newmask);
sigaddset(&newmask, SIGINT);

/* block SIGINT and save current signal mask */
if (sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0)
  err_sys("SIG_BLOCK error");

/* critical region of code */

/* restore signal mask, which unblocks SIGINT */
if (sigprocmask(SIG_SETMASK, &oldmask, NULL) < 0)
  err_sys("SIG_SETMASK error");

/* window is open */
pause(); /* wait for signal to occur */

/* continue processing */
```
对于上述代码, 被阻塞的signal可能在调用`sigprocmask(SIG_SETMASK, &oldmask, NULL)`后立即传递给进程, `pause()`没有收到signal, 让进程一直陷入挂起状态. 因此, 我们需要一种方法, 将**恢复signal mask**和**挂起进程**变为一个原子操作:
```c
/**
 * @brief temporarily replace the current signal mask of 
 *        the calling thread with the signal mask given 
 *        by `mask` and then suspend the thread until 
 *        delivery of a signal whose action is to invoke 
 *        a signal handler or to terminate a process
 *        * if the signal terminates the process, then 
 *          sigsuspend() does not return.
 *        * if the signal is caught, then sigsuspend() 
 *          returns after the signal handler returns, 
 *          and the signal mask is restored to the 
 *          state before the call to sigsuspend().
 */
int sigsuspend(const sigset_t *mask);
```
* 由于进程不能阻塞`SIGKILL`和`SIGSTOP`, 因此将这两个signal作为`sigsuspend()`的参数没有意义
* `sigsuspend()`通常与`sigprocmask()`一起使用, 用于防止某段代码被signal中断

### 16.1 Example of sigsuspend to protect a critial region
```c
#include "apue.h"

static void sig_int(int);

int main(void)
{
  sigset_t newmask, oldmask, waitmask;

  pr_mask("program start: ");

  if (signal(SIGINT, sig_int) == SIG_ERR)
    err_sys("signal(SIGINT) error");
  sigemptyset(&waitmask);
  sigaddset(&waitmask, SIGUSR1);
  sigemptyset(&newmask);
  sigaddset(&newmask, SIGINT);

  /* Block SIGINT and save current signal mask. */
  if (sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0)
    err_sys("SIG_BLOCK error");

  /* Critical region of code. */
  pr_mask("in critical region: ");

  /* Pause, allowing all signals except SIGUSR1. */
  if (sigsuspend(&waitmask) != -1)
    err_sys("sigsuspend error");

  pr_mask("after return from sigsuspend: ");

  /* Reset signal mask which unblocks SIGINT. */
  if (sigprocmask(SIG_SETMASK, &oldmask, NULL) < 0)
    err_sys("SIG_SETMASK error");

  /* And continue processing ... */
  pr_mask("program exit: ");

  exit(0);
}

static void sig_int(int signo)
{
  pr_mask("\nin sig_int: ");
}
```
以下是代码的运行结果:
```sh
$ ./a.out
program start:
in critical region: SIGINT
ˆC                          # type the interrupt character
in sig_int: SIGINT SIGUSR1
after return from sigsuspend: SIGINT
program exit:
```

### 16.2 Example of sigsuspend to wait for a signal handler to set a global variable
以下代码捕获interrupt signal和quit signal, 进程收到quit signal时才唤醒`main()`:
```c
#include "apue.h"

volatile sig_atomic_t quitflag; /* set nonzero by signal handler */

/* one signal handler for SIGINT and SIGQUIT */
static void sig_int(int signo)
{
  if (signo == SIGINT)
    printf("\ninterrupt\n");
  else if (signo == SIGQUIT)
    quitflag = 1; /* set flag for main loop */
}

int main(void)
{
  sigset_t newmask, oldmask, zeromask;

  if (signal(SIGINT, sig_int) == SIG_ERR)
    err_sys("signal(SIGINT) error");
  if (signal(SIGQUIT, sig_int) == SIG_ERR)
    err_sys("signal(SIGQUIT) error");

  sigemptyset(&zeromask);
  sigemptyset(&newmask);
  sigaddset(&newmask, SIGQUIT);

  /* Block SIGQUIT and save current signal mask. */
  if (sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0)
    err_sys("SIG_BLOCK error");

  while (quitflag == 0)
    sigsuspend(&zeromask);

  /* SIGQUIT has been caught and is now blocked; do whatever. */
  quitflag = 0;

  /* Reset signal mask which unblocks SIGQUIT. */
  if (sigprocmask(SIG_SETMASK, &oldmask, NULL) < 0)
    err_sys("SIG_SETMASK error");

  exit(0);
}
```
以下是输出结果:
```sh
$ ./a.out
ˆC           # type the interrupt character
interrupt
ˆC           # type the interrupt character again
interrupt
ˆC           # and again
interrupt
ˆ\ $         # now terminate with the quit character
```

### 16.3 Example of signals that synchronize a parent and child
以下代码通过signal同步parent process和child process:
```c
#include "apue.h"

static volatile sig_atomic_t sigflag; /* set nonzero by sig handler */
static sigset_t newmask, oldmask, zeromask;

/* one signal handler for SIGUSR1 and SIGUSR2 */
static void sig_usr(int signo)
{
  sigflag = 1;
}

void TELL_WAIT(void)
{
  if (signal(SIGUSR1, sig_usr) == SIG_ERR)
    err_sys("signal(SIGUSR1) error");
  if (signal(SIGUSR2, sig_usr) == SIG_ERR)
    err_sys("signal(SIGUSR2) error");
  sigemptyset(&zeromask);
  sigemptyset(&newmask);
  sigaddset(&newmask, SIGUSR1);
  sigaddset(&newmask, SIGUSR2);
  /* Block SIGUSR1 and SIGUSR2, and save current signal mask */
  if (sigprocmask(SIG_BLOCK, &newmask, &oldmask) < 0)
    err_sys("SIG_BLOCK error");
}

void TELL_PARENT(pid_t pid)
{
  kill(pid, SIGUSR2);     /* tell parent we're done */
}

void WAIT_PARENT(void)
{
  while (sigflag == 0)
    sigsuspend(&zeromask);  /* and wait for parent */
  sigflag = 0;

  /* Reset signal mask to original value */
  if (sigprocmask(SIG_SETMASK, &oldmask, NULL) < 0)
    err_sys("SIG_SETMASK error");
}

void TELL_CHILD(pid_t pid)
{
  kill(pid, SIGUSR1);         /* tell child we're done */
}

void WAIT_CHILD(void)
{
  while (sigflag == 0)
    sigsuspend(&zeromask);  /* and wait for child */
  sigflag = 0;

  /* Reset signal mask to original value */
  if (sigprocmask(SIG_SETMASK, &oldmask, NULL) < 0)
    err_sys("SIG_SETMASK error");
}
```


## 17. abort Function
```c
/**
 * @brief unblock the SIGABRT signal, and then raise 
 *        that signal for the calling process. This 
 *        results in the abnormal termination of the
 *        process unless the SIGABRT signal is caught
 *        and the signal handler does not return
 */
void abort(void);
```
* ISO C没有规定`abort()`是否应flush buffered data, 是否关闭open stream, 或是否删除temporary files
* POSIX.1允许`abort()`在进程终止前调用`fclose()`关闭standard I/O streams.

以下是POSIX.1的`abort()`实现:
```c
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void abort(void) /* POSIX-style abort() function */
{
  sigset_t         mask;
  struct sigaction action;

  /* caller can't ignore SIGABRT */
  sigaction(SIGABRT, NULL, &action);
  if (action.sa_handler == SIG_IGN) {
    action.sa_handler = SIG_DFL;
    sigaction(SIGABRT, &action, NULL);
  }
  
  if (action.sa_handler == SIG_DFL)
    fflush(NULL); /* flush all open stdio streams */

  /* caller can't block SIGABRT */
  sigfillset(&mask);
  sigdelset(&mask, SIGABRT); /* turned off SIGABRT */
  sigprocmask(SIG_SETMASK, &mask, NULL);
  kill(getpid(), SIGABRT); /* send the signal */

  /* process caught SIGABRT and returned */
  fflush(NULL); /* flush all open stdio streams */
  action.sa_handler = SIG_DFL;
  sigaction(SIGABRT, &action, NULL); /* reset to default */
  sigprocmask(SIG_SETMASK, &mask, NULL); /* just in case ... */
  kill(getpid(), SIGABRT); /* and one more time */
  exit(1); /* this should never be executed ... */
}
```


## 18. system Function
* POSIX.1要求`system()`忽略`SIGINT`和`SIGQUIT`: 因为`system()`的调用者并不是该函数的进程, `system()`会调用`fork()`, 其child process才是执行者. parent process和child process会一并收到`SIGINT`或`SIGQUIT`, 实际上只需要child process接收该signal.
* POSIX.1要求`system()`阻塞`SIGCHLD`: 避免parent process过早收到`SIGCHLD`

### 18.1 Example of system invoking ed editor
以下代码使用`system()`启动ed editor, 会捕获interrupt signal和quit signal并输出:
```c
#include "apue.h"

static void sig_int(int signo)
{
  printf("caught SIGINT\n");
}

static void sig_chld(int signo)
{
  printf("caught SIGCHLD\n");
}

int main(void)
{
  if (signal(SIGINT, sig_int) == SIG_ERR)
    err_sys("signal(SIGINT) error");
  if (signal(SIGCHLD, sig_chld) == SIG_ERR)
    err_sys("signal(SIGCHLD) error");
  if (system("/bin/ed") < 0)
    err_sys("system() error");
  exit(0);
}
```
以下为输出:
```sh
$ ./a.out
a          # append text to the editor’s buffer
Here is one line of text
.          # period on a line by itself stops append mode
1,$p       # print first through last lines of buffer to see what’s there
Here is one line of text
w temp.foo # write the buffer to a file
25         # editor says it wrote 25 bytes
q          # and leave the editor
caught SIGCHLD
```
* 中止editor时, kernel向parent process发送`SIGCHLD`, parent process收到该signal, 并执行signal handler.
* POSIX.1要求`system()`期间阻塞`SIGCHLD`.

再次运行上述代码, 这次向editor发送interrupt signal:
```c
$ ./a.out
a              # append text to the editor’s buffer
hello, world
.              # period on a line by itself stops append mode
1,$p           # print first through last lines to see what’s there
hello, world
w temp.foo     # write the buffer to a file
13             # editor says it wrote 13 bytes
ˆC             # type the interrupt character
?              # editor catches signal, prints question mark
caught SIGINT  # and so does the parent process
q              # leave editor
caught SIGCHLD
```
下图为运行editor时的进程安排如下:
![arrangement of the processes when the editor is running](/images/UNIX/APUE/10-18-proc-when-editor-running.png)

当用户按下interrupt key时, terminal driver向foreground process group中的所有进程发送`SIGINT`, `/bin/sh`忽略该signal, `a.out`和`/bin/ed`应收到该signal; 但由于`a.out`正在执行`system()`, 因此只有`/bin/ed`收到`SIGINT`和`SIGQUIT`, `a.out`只有在`system()`运行结束后才能收到这两个signal.

### 18.2 Implementation of system with signal handling
以下代码使用signal handling实现`system()`
```c
#include <sys/wait.h>
#include <errno.h>
#include <signal.h>
#include <unistd.h>

int system(const char *cmdstring) /* with appropriate signal handling */
{
  pid_t pid;
  int status;
  struct sigaction ignore, saveintr, savequit;
  sigset_t chldmask, savemask;

  if (cmdstring == NULL)
    return 1;

  /* ignore SIGINT and SIGQUIT */
  ignore.sa_handler = SIG_IGN; 
  sigemptyset(&ignore.sa_mask);
  ignore.sa_flags = 0;
  if (sigaction(SIGINT, &ignore, &saveintr) < 0)
    return -1;
  if (sigaction(SIGQUIT, &ignore, &savequit) < 0)
    return -1;

  sigemptyset(&chldmask);
  sigaddset(&chldmask, SIGCHLD); /* block SIGCHLD */
  if (sigprocmask(SIG_BLOCK, &chldmask, &savemask) < 0)
    return -1;

  if ((pid = fork()) < 0) {
    status = -1;
  } else if (pid == 0) { /* child */
    /* restore previous signal actions & reset signal mask */
    sigaction(SIGINT, &saveintr, NULL);
    sigaction(SIGQUIT, &savequit, NULL);
    sigprocmask(SIG_SETMASK, &savemask, NULL);
    execl("/bin/sh", "sh", "-c", cmdstring, (char *)0);
    _exit(127);
  } else { /* parent */
    while (waitpid(pid, &status, 0) < 0)
      if (errno != EINTR) {
        status = -1; /* error other than EINTR */
        break;
      }
  }

  /* restore previous signal actions & reset signal mask */
  if (sigaction(SIGINT, &saveintr, NULL) < 0)
    return -1;
  if (sigaction(SIGQUIT, &savequit, NULL) < 0)
    return -1;
  if (sigprocmask(SIG_SETMASK, &savemask, NULL) < 0)
    return -1;

  return status;
}
```
* 调用`system()`的进程在执行`system()`期间不会收到interrupt或quit signal
* 命令执行结束后, `system()`会调用`sigprocmask`解除`SIGCHLD`的阻塞


## 19. sleep, nanosleep and clock_nanosleep Functions
```c
/**
 * @brief cause the calling thread to sleep
 */
unsigned int sleep(unsigned int seconds);
```
`sleep()`会在以下两种情况停止睡眠:
* 已经过`seconds`参数指定的时间, 返回0
* 进程收到signal并执行signal handler, 返回剩余未睡眠的秒数

以下是POSIX.1中`sleep()`的实现:
```c
static void sig_alrm(int signo)
{
  /* nothing to do, just returning wakes up sigsuspend() */
}

unsigned int sleep(unsigned int seconds)
{
  struct sigaction newact, oldact;
  sigset_t newmask, oldmask, suspmask;
  unsigned int unslept;
  
  /* set our handler, save previous information */
  newact.sa_handler = sig_alrm;
  sigemptyset(&newact.sa_mask);
  newact.sa_flags = 0;
  sigaction(SIGALRM, &newact, &oldact);

  /* block SIGALRM and save current signal mask */
  sigemptyset(&newmask);
  sigaddset(&newmask, SIGALRM);
  sigprocmask(SIG_BLOCK, &newmask, &oldmask);

  alarm(seconds);
  suspmask = oldmask;

  /* make sure SIGALRM isn’t blocked */
  sigdelset(&suspmask, SIGALRM);

  /* wait for any signal to be caught */
  sigsuspend(&suspmask);

  /* some signal has been caught, SIGALRM is now blocked */
  unslept = alarm(0);

  /* reset previous action */
  sigaction(SIGALRM, &oldact, NULL);

  /* reset signal mask, which unblocks SIGALRM */
  sigprocmask(SIG_SETMASK, &oldmask, NULL);
  
  return unslept;
}
```
上述代码中不会影响进程`SIGALRM`的signal handler, 且没有用到`longjmp()`或`siglongjmp()`

```c
#include <time.h>

struct timespec {
  time_t tv_sec;  /* seconds */
  long tv_nsec;   /* nanoseconds */
};

/**
 * @brief suspend the execution of the calling thread 
 *        until
 *        * at least the time specified in `req` has 
 *          elapsed
 *        * the delivery of a signal that triggers a 
 *          handler or that terminates the process
 * @param req if the call is interrupted by a signal 
 *        handler, the remaining time into the strcuture 
 *        pointed to by `rem` unless `rem` is NULL
 * @return 0 on successfully sleeping for the requested 
 *         interval; -1 on error and errno is set
 */
int nanosleep(const struct timespec *req, struct timespec *rem);

/**
 * @brief allow the calling thread to sleep for an 
 *        interval specified with nanosecond precision.
 *        allow the caller to select the clock against
 *        which the sleep interval is to be measured.
 *        allow the sleep interval to be specified as 
 *        either an absolute or a relative value.
 * @param clock_id specifies the clock against which 
 *        the sleep interval is to be measured, shall 
 *        be one of the following values
 *        * CLOCK_REALTIME: a settable system-wide 
 *          real-time clock
 *        * CLOCK_MONOTONIC: a nonsettable, monotonically
 *          increasing clock that measures time since 
 *          some unspecified point in the past that 
 *          does not change after system startup
 *        * CLOCK_PROCESS_CPUTIME_ID: A per-process 
 *          clock that measures CPU time consumed by 
 *          all threads in the process
 * @param flags control whether the delay is absolute
 *        or relative
 *        * 0: `req` is interrupted as an interval 
 *          relative to the current value of the clock 
 *          specified by `clock_id`
 *        * TIMER_ABSTIME: `req` is interrupted as an 
 *          absolue time as measured by `clock_id`. 
 *          if `req` is less than or equal to the 
 *          current value of the clock, then return 
 *          immediately without suspending
 */
int clock_nanosleep(clockid_t clock_id, int flags, 
      const struct timespec *req, struct timespec *rem);
```
* POSIX.1规定, `nanosleep()`应使用`CLOCK_REALTIME`测量时间
* 若`nanosleep()`被signal中断, 且执行signal handler, 则将剩余未睡眠时间写入`rem`指向的结构体(若`rem`不为NULL).
* 若UNIX系统不支持nanosecond, 则四舍五入`req`.


## 20. sigqueue Function
大部分UNIX系统不支持对signal排队, 但还是存在部分系统支持该特性. 为实现queue signal, 需满足以下条件:
* 调用`sigaction()`设置signal handler时, 需指定`SA_SIGINFO`; 若不指定该flag, 可能不会queue signal.
* `sigaction` struct中使用`sa_sigaction`, 而不是`sa_handler`. 
1. 使用`sigqueue()`发送signal

```c
union sigval {
  int sival_int;
  void *sival_ptr;
};

/**
 * @brief send the signal specified in `sig` to 
 *        the process whose PID is given in `pid`
 * @param value specify an accompanying item of
          data to be sent with signal
 * @return 0 on success, -1 on error and errno is set
 */
int sigqueue(pid_t pid, int sig, const union sigval value)
```
POSIX.1规定了`SIGQUEUE_MAX`表示signal队列的长度上限.


## 21. Job Control Signals
POSIX.1规定以下6种signal作为**job-control signal**:
* `SIGCHLD`: child process停止运行或中止
* `SIGCONT`: 若进程已被停止, 继续运行进程
* `SIGSTOP`: 停止目标进程(无法被handler处理或无视)
* `SIGTSTP`: interactive stop signal
* `SIGTTIN`: background process group中的进程从controlling terminal读取数据
* `SIGTTOU`: background process group中的进程向controlling terminal写入数据

除了`SIGCHLD`, 大部分进程都不会接触上述signal, 因为shell负责处理剩下5个signal: 
* 当用户按下suspend character时, terminal driver向foreground process group中的所有进程发送`SIGTSTP`
* 当恢复某个job时, 会向指定process group中的所有进程发送`SIGCONT`
* 当backgroup process group中的进程尝试从terminal读取或写入数据时, background process group中的所有进程都收到`SIGTTIN`或`SIGTTOU`
* job-control signals之间也存在交互: 当stop signals(SIGTSTP, SIGSTOP, SIGTTIN, SIGTTOU)中的某一个发送给进程, 被阻塞的`SIGCONT`会被直接丢弃; 当`SIGCONT`发送至进程时, 所有被阻塞的stop signal也会被丢弃.
* 当进程处于停止状态时, `SIGCONT`会让进程恢复运行; 但若进程处于运行状态, `SIGCONT`会被忽略.


## 22. Signal Names and Numbers
```c
/**
 * @brief display a message on stderr consisting 
 *        of the string `s`, a colon, a space, 
 *        a string describing the signal number 
 *        `sig`, and a trailing newline
 */
void psignal(int sig, const char *s);

/**
 * @brief like psignal(), but use siginfo struct
 *        as parameter
 */
void psiginfo(const siginfo_t *info, const char *s);
```
上述两个函数会将signal的描述输出到`stderr`, 若不想输出到`stderr`, 可调用以下函数:
```c
/**
 * @brief return a string describing the signal
 *        number passed in the argument `sig`
 */
char *strsignal(int sig);
```
不同UNIX系统的`strsignal()`输出不同: 若无法识别`sig`:
* Solaris 10返回一个null pointer
* FreeBSD 8.0, Linux 3.2.0, Mac OS X 10.6.8返回一个string表示`sig`无法识别

除此之外Solaris还提供了一组函数用于signal number和signal name的互相转换:
```c
int sig2str(int signo, char *str);
int str2sig(const char *str, int *signop);
```
