---
title: Process Control
tags:
  - Linux
category:
  - Linux
abbrlink: c259
date: 2019-09-01 12:46:20
---

## 1. Process Indetifiers
每个进程都有一个唯一, 非负的PID(process ID, 进程ID). PID支持重用, 进程一旦被停用, 其PID会被其他新建进程重用. 但大多数UNIX系统会推迟该操作, 以保证新进程不会被误认为上一个进程. 以下是一些特殊进程, 具体细节因系统实现不同而不同:
* PID 0: scheduler process(调度进程), 用于进程调度, system process之一.
* PID 1: init process, bootstrap结束时由kernel调用, 程序位于`/etc/init`或`/sbin/init`:
  * 负责初始化UNIX系统
  * 该进程不会退出
  * 该进程不是system process, 而是普通进程
  * 该进程拥有superuser权限

```c
/**
 * @brief return the process ID (PID) of the calling process.
 *        This is often used by routines that generate unique
 *        temporary filename
 */
pid_t getpid(void);

/**
 * @brief return the process ID (PID) of parent of the calling
 *        process. This will be either the ID of the process 
 *        that created this process using fork(), or, if that
 *        process has already terminated, the ID of the process
 *        to which this process has been reparented (either init
 *        or a process defined via the prctl() 
 *        PR_SET_CHILD_SUBREAPER operation)
 */
pid_t getppid(void);

/**
 * @brief return the real user ID of the calling process
 */
uid_t getuid(void);

/**
 * @brief return the effective user ID of the calling process
 */
uid_t geteuid(void);

/**
 * @brief return the real group ID of the calling process
 */
gid_t getgid(void);

/**
 * @brief return the effective group ID of the calling process
 */
gid_t getegid(void);
```


## 2. fork Function
```c
/**
 * @brief create a new process by duplicating the calling process
 * @return PID of the child process is returned in the parent
 *         process, return 0 in the child process; return -1 in 
 *         the parent process
 */
pid_t fork(void);
```
Child process的`fork()`返回值为0, 而不是PPID(parent process's PID), 因为child process可通过`getppid()`获得PPID. 一个进程可拥有多个child process, 因此parent process的`fork()`返回值为child process的PID.
有些UNIX系统会提供`fork()`的变种, 如Linux的`clone()`.

### 2.1 Memory Sharing
Child process会复制parent process的大部分内存数据, 包括data segment, heap, stack, 因此两者不共享数据, 除了text segment(read-only).
由于复制数据会降低运行速度, 且**fork-exec model**(`fork()`生成的child process执行`exec()`以运行其他程序)被广泛使用, 因此child process并没有必要复制parent process的数据, **copy-on-write**(COW)应运而生: child process一开始不会复制parent process的数据, 而是共享同一区域内存. 只有当其中一方(child process或parent process)试图写入数据时才会复制被修改的内存区域.

### 2.2 File Sharing
`fork()`会对parent process的每个file descriptor调用`dup()`, 因此child process与parent process共享file descriptor. 由于parent process与child process指向相同的table entry, 因此child process可以在parent process所在文件的相同位置继续读写.
![Sharing of open files between parent and child after fork](/images/UNIX/APUE/8-2-sharing-of-open-files.jpg)

若parent process和child process在没有同步机制的情况下对同一file descriptor进行操作, 很可能导致数据丢失或逻辑错误. 有以下两种方法保证同步:
* parent process等待child process的操作完毕后再执行操作.
* parent process和child process各自关闭不需要的file descriptor, 避免两个进程操作同一file descriptor

### 2.3 Other Sharing
以下是parent process和child process的相同之处:
* real user ID, real group ID, effective user ID, 和effective group ID
* supplementary group IDs
* process group ID
* session ID
* controlling terminal
* set-user-ID和set-group-ID bits
* current working directory
* root directory
* file mode creation mask
* signal mask和dispositions
* 所有打开的file descriptor的close-on-exec flag
* environment variables
* attached shared memory segments
* memory mappings
* resource limits

以下是parent process与child process的不同之处:
* child process拥有自己的PID
* child process的PPID与parent process的PID相同, 因此, child process的PPID一定与parent process的PPID不同(init的PPID为0)
* child process的进程资源利用率(`getrusage()`)和CPU使用时长(`times()`)重置为0
* child process的等待信号队列重置为空
* child process不会继承parent process的memory lock(`mlock()`)
* child process不会继承parent process对semaphore的修改(`semop()`)
* child process不会继承parent process的record lock(`fcntl()`)
* child process不会继承parent process的timer(`setitimer()`, `alarm()`, `timer_create()`)
* child process不会继承parent process未完成的异步I/O操作(`aio_read()`, `aio_write(3)`), 也不会继承异步I/O上下文(`io_steup()`)

以下是`fork()`执行失败的主要原因:
* 系统内的进程数量达到上限: 进程数达到`RLIMIT_NPROC`资源上限, 或达到PID数量上限
* 该real user ID的child process数量达到上限

## 3. vfork Function 
```c
/**
 * @brief create a child process and block parent
 */
pid_t vfork(void);
```
`vfork()`与`fork()`存在两点不同:
* `vfork()`生成的child process不复制parent process的地址空间, 因此共享parent process的所有数据. 只有调用`exec()`或`exit()`才会退出parent process的地址空间.
* `fork()`不保证child process和parent process的执行顺序, 而`vfork()`要求child process必须在parent process之前运行, 需要阻塞parent process, 直到child process调用`exec()`或`exit()`退出进程.


## 4. exit Functions
以下是五种**正常中止进程**的方式:
* `main()`中调用`return()`, 相当于调用`exit()`
* 调用`exit()`. 会调用所有`atexit()`注册的exit handler, 并关闭所有I/O streams. 由于`exit()`由ISO C定义, 所以不处理file descritptor, 多进程, 和任务控制.
* 调用`_exit()`或`_Exit()`. ISO C定义`_Exit()`中止进程且不调用exit handler. `_exit()`由POSIX.1定义, 因此会关闭file descriptor, 并将所有child process的parent process改为init.
* 进程的最后一个线程的start routine调用`return()`, 该线程的返回值不会作为进程的返回值, 而是以0提出.
* 进程的最后一个线程调用`pthread_exit()`. 

以下是三种**异常中止进程**的方式:
* 调用`abort()`, 不会删除临时文件, 不关闭stream buffer, 也不会调用`atexit()`注册的exit handler
* 进程收到特定signal
  * 进程调用`abort()`
  * 其他进程向当前进程发送signal
  * kernel发送signal, 如发生错误
* 进程的最后一个线程回应cancellation request

无论进程如何中止, kernel都会关闭所有open file descriptor, 并释放内存. 进程被中止时, 其parent process会收到exit status. 若进程调用`exit()`, `_exit()`, 或`_Exit()`中止进程, 则exit status为其参数; 若进程异常中止, kernel会生成一个termination status, 其parent process可通过`wait()`或`waitpid()`获取termination status.
若进程中止时, 其child process仍未退出, 则child process的PPID改为1(init), 这样可保证任何进程在任何时刻都有一个PPID. 
若child process中止时, 其parent process仍未退出, kernel会将中止的进程信息保留在内存中, 以便后续parent process调用`wait()`或`waitpid()`获取termination status. 保存的进程信息包括: 被中止进程的PID, CPU运行时间, termination status. 这些已被中止但未被parent process知晓的进程称为**zombie process**. 
若进程的parent process为init, 则该进程永远不会成为zombie process, 因为无论进程何时中止, init都会调用`wait()`获取其termination status. init的child process有两种生成方式:
* init直接生成的进程(`getty`)
* 进程的parent process中止, 其parent process转为init


## 5. wait and waitpid Functions
无论进程如何中止, kernel都会向其parent process发送`SIGCHLD`信号. 该信号为异步提醒, parent process可选择忽略该信号, 或提供一个signal handler处理该信号, 且信号默认处理会被忽略. `wait()`和``waitpid()`可提供以下功能:
* 若所有child process都在运行, 则阻塞当前进程
* 若某个child process被中止, 则立刻返回该child process的termination status
* 若没有任何child process, 则立即返回错误

```c
/**
 * @brief suspend execution of the calling thread until one 
 *        of its child process terminates. The call of 
 *        wait(&wstatus) is equal to waitpid(-1, &wstatus, 0)
 * @param wstatus store the termination status
 * @return PID of terminated child process on success; -1 
 *         on error.
 */
pid_t wait(int *wstatus);

/**
 * @brief suspend execution of the calling thread until a 
 *        child process specified by `pid` has changed state.
 *        By default, waitpid() waits only for terminated 
 *        children, but this behavior is modifiable via 
 *        the `options` argument.
 * @param pid PID of child process:
 *        * <-1: wait for any child process whose process 
            group ID is equal to the absolute value of `pid`
 *        * -1: wait for any child process
 *        * 0: wait for any child process whose process group 
 *          ID is equal to that of the calling process
 *        * >0: wait for the child process whose process ID is
 *          equal to the value of `pid`
 * @param options an OR of zero or more of the following values:
 *        * WNOHANG: return immediately if pid is not available
 *        * WUNTRACED: return if a child process has stopped 
 *        * WCONTINUED: return if a stopped child process has 
 *          been resumed by delivery of SIGCONT
 */
pid_t waitpid(pid_t pid, int *wstatus, int options);
```
`waitpid()`与`wait()`的区别:
1. `waitpid()`可等待指定PID的child process, `wait()`只能等待当前进程的child process
2. `waitpid()`提供nonblocking模式, 无需阻塞当前进程
3. `waitpid()`提供WUNTRACED和WCONTINUED来支持job control


## 6. waitid Function
Single UNIX Specification提供了额外的函数来获取exit status.
```c
/**
 * @brief wait for a child process to change state
 * @param idtype specify which child process it waits for
 *        * P_PID: wait for the child process which PID 
 *          matches `id`
 *        * P_PGID: wait for any child process whose 
 *          process group ID matches `id`
 *        * P_ALL: wait for any child process, `id` is 
 *          ignored
 * @param infop: store the current state of a child process
 * @param options: same as the option argument in waitpid()
 */
int waitid(idtype_t idtype, id_t id, siginfo_t *infop, 
           int options);
```


## 7. wait3 and wait4 Function
```c
/**
 * @brief same as waitpid(), but additionally return 
 *        resource usage information about the child
 *        in the structure pointed to by rusage
 */
pid_t wait3(int *status, int options, struct rusage *rusage);
pid_t wait4(pid_t pid, int *status, int options, 
            struct rusage *rusage);
```
`wait3(status, options, rusage);`等同于`waitpid(-1, status, options)`, 但会返回额外的资源使用信息, 其中包括user CPU运行时间, system CPU运行时间, page fault的数量, 接收到的signal数量等. 


## 8. exec Functions
当进程调用`exec`时, 进程开始执行新程序, 其PID不会改变, 但text segment, data segment, heap, stack都会被替换. 
```c
/**
 * @brief The exec() family of functions replaces the 
 *        current process image with a new process image
 * @param path path of the executed program
 * @param arg a list of one or more pointers to 
 *        null-terminated strings that represent the 
 *        argument list available to the executed program
 * @param envp an array of pointers to null-terminated
 *        strings that represent the argument list 
 *        available to the new program
 * @param file filename of the executed program. If 
 *        fileanme contains a slash, it is taken as a 
 *        pathname. Otherwise, the executable file is 
 *        searched for in the directories specified by the 
 *        PATH env variable
 * @param fd file descriptor of the executed program
 */
int execl(const char *path, const char *arg, ...);
int execv(const char *path, char *const argv[]);
int execle(const char *path, const char *arg, ..., 
           char *const envp[]);
int execve(const char *path, char *const argv[], 
           char *const envp[]);
int execlp(const char *file, const char *arg, ...);
int execvp(const char *file, char *const argv[]);
int fexecve(int fd, char *const argv[], char *const envp[]);
```
除了PID, exec后的进程还继承了原本的一些属性:
* PID和PPID
* real user ID和real group ID
* supplementary group IDs
* process group ID
* session ID
* controlling terminal
* alarm时钟剩余的时间
* current working directory
* root directory
* file mode creation mask
* file lock
* process signal mask
* pending signal
* resource limits
* nice value
* tms_utime, tms_stime, tms_cutime, 和tms_cstime

若`exec()`执行的程序设置了set-user-ID bit, 则EUID(effective user ID)会改为程序文件的owner ID; 若没有设置set-user-ID bit, 则EUID不变.
UNIX系统的实现中, 只有`execve()`在kernel中调用system call, 其他的exec函数为库函数, 最后通过调用`execve()`来调用system call
![Relationship of the exec functions](/images/UNIX/APUE/8-8-exec-func.png)

还有三种情况需要考虑:
* 若file descriptor设置了close-on-exec flag, 则exec会关闭该file descriptor
* exec会关闭所有directory streams, 因为`opendir()`会调用`fcntl()`, 为每个directory stream设置close-on-exec flag
* exec会保留进程原本的real user ID和real group ID, 但若程序文件设置了set-user-ID bit或set-group-ID bit, 则effective user ID会改变; 否则effective user ID保持不变, effective group ID同理.


## 9. Change User IDs and Group IDs
UNIX系统中的权限和访问控制基于user ID和group ID. 当进程需要额外权限时, 需将自身的user ID或group ID改为其他合适的ID. 设计应用时应遵循**least-privilege model**(最少权限模型), 保证非必要用户无权限访问某些文件, 以降低安全风险.
```c
/**
 * @brief set the effective user ID of the calling process
 *        it is equivalent to setresuid(uid, uid, uid)
 */
int setuid(uid_t uid);

/**
 * @brief set the effective group ID of the calling process
 *        it is equivalent to setresgid(gid, gid, gid)    
 */
int setgid(gid_t gid);
```
`setuid()`遵循以下规则:
* 若进程为privileged process, 则将real user ID, effective user ID, 和saved set-user-ID设置为`uid`
* 若进程不为privileged process, 但`uid`与进程的real user ID, effective user ID, 或saved set-user-ID相同, 则将effective user ID设置为`uid`
* 若不满足上述两条规则, 则返回-1, 并设置errno

`setgid()`同理

以下是user ID被改变的情况:
{% raw %}
<table>
  <tr>
    <td rowspan="2">ID</td>
    <td colspan="2">exec</td>
    <td colspan="2">setuid(uid)</td>
  </tr>
  <tr>
    <td>set-user-ID bit off</td>
    <td>set-user-ID bit on</td>
    <td>superuser</td>
    <td>unprivileged user</td>
  </tr>
  <tr>
    <td>real user ID</td>
    <td>unchanged</td>
    <td>unchanged</td>
    <td>set to uid</td>
    <td>unchanged</td>
  </tr>
  <tr>
    <td>effective user ID</td>
    <td>unchanged</td>
    <td>set from user ID of program file</td>
    <td>set to uid</td>
    <td>set to uid</td>
  </tr>
  <tr>
    <td>saved set-user-ID</td>
    <td>copied from effective user ID</td>
    <td>copied from effective user ID</td>
    <td>set to uid</td>
    <td>unchanged</td>
  </tr>
</table>
{% endraw %}

### 9.1 setreuid, setregid Functions
```c
/**
 * @brief set real and effective user IDs of the calling 
 *        process.
 *        it is equivalent to setresuid(ruid, euid, -1)
 *
 * @return 0 on success; -1 on error and errno is set
 */
int setreuid(uid_t ruid, uid_t euid);

/**
 * @brief set real and effective group IDs of the calling 
 *        process.
 *        it is equivalent to setresgid(rgid, euid, -1)
 */
int setregid(gid_t rgid, gid_t egid);

/**
 * @brief set the real user ID, effective user ID,
 *        and saved set-user-ID of the calling process.
 */
int setresuid(uid_t ruid, uid_t euid, uid_t suid);

/**
 * @brief set the real group ID, effective group ID,
 *        and saved set-group-ID of the calling process.
 */
int setresgid(gid_t rgid, gid_t egid, gid_t sgid);
```
`setresuid()`遵循以下规则:
* 若`ruid`, `euid`, 或`sgid`为-1, 则不修改real user ID, effective user ID, 或saved set-user-ID.
* 若进程为privileged process, 则可将real user ID, effective user ID, 和saved set-user-ID设置为任意值
* 若进程为unprivileged process, 则只能设置effective user ID, 且effective user ID必须为当前进程的real user ID, effective user ID, 或saved set-user-ID

`setresgid()`与上述同理.

### 9.2 seteuid and setegid Functions
```c
/**
 * @brief set effective user ID of the callig process
 *        If the process has privilege, it can set 
 *        effective user ID to any value; If the process 
 *        does not have privilege, effective user id can 
 *        only be set to real user ID or saved set-user-ID
 *        it is equivalent to setresgid(-1, euid, -1)
 * @return 0 on suceess; -1 on error and errno is set
 */
int seteuid(uid_t uid);

/**
 * @brief set effective group ID of the calling process
 */
int setegid(gid_t gid);
```
`seteuid()`遵循以下规则:
* 若进程为privileged process, 则可将effective user ID设置为任意值
* 若进程不为privileged process, 则只能将effective user ID设置为real user ID or saved set-user-ID

`setegid()`与上述同理. 相比于`setuid()`, 该函数不会修改saved set-user-ID, 因此当privileged process使用`setuid()`降级自身权限以运行程序, 运行后无法恢复到superuser, 这时可使用`seteuid()`.

以下是所有可以更改user ID的函数:
![Summary of all the functions that set the various user IDs](/images/UNIX/APUE/8-8-set-user-id.png)

### 9.3 Example
Linux 3.2.0添加了`at`程序, 可在指定时间点执行一些命令. 该程序的set-user-ID为`daemon`. 为防止权限泄露, 执行命令时必须在user和daemon切换, 以下是执行步骤:
1. 假设`at`程序的owner为root, 且设置了set-user-ID bit:
  * real user ID = our user ID (不变)
  * effective user ID = root (由于开启set-user-ID bit, 因此修改EUID)
  * saved set-user-ID = root
2. `at`程序调用`seteuid()`, 将EUID改为进程的real user ID:
  * real user ID = our user ID (不变)
  * effective user ID = our user ID
  * saved set-user-ID = root (不变)
3. 当`at`访问daemon的配置文件(包含用户输入的命令和执行时间)时, `at`会调用`seteuid`将EUID设置为root:
  * real user ID = our user ID (不变)
  * effective user ID = root
  * saved set-user-ID = root (不变)
4. 访问root的文件后, `at`会调用`seteuid()`降低权限, 将EUID改回为user ID:
  * real user ID = our user ID (不变)
  * effective user ID = our user ID
  * saved set-user-ID = root (不变)
5. daemon以root权限运行, 为运行用户输入的命令, daemon调用`fork()`生成子进程, 并让子进程调用`setuid()`, 由于child process也是以root权限执行, 因此会修改所有ID:
  * real user ID = our user ID
  * effective user ID = our user ID
  * saved set-user-ID = our user ID


## 10. Interpreter Files
现代UNIX系统中, interpreter file(解释器文件)作为文本文件, 会以`#!pathname [optional-argument]`作为第一行, 感叹号和路径名之间的空格使可选的, 最常见的开头如下:
```text
#!/bin/sh
```
* pathname通常为absolute pathname(绝对路径), 因为该路径不会执行特殊操作(不会使用`PATH`)
* interpreter file的处理在kernel进行, 会作为`exec`系统调用的一部分
* kernel执行的文件不是interpreter file, 而是第一行指定的文件

相比于使用interpreter, interpreter file有以下优点:
* 隐藏pathname: 用户不必知道使用哪个pathname, 直接执行文件即可:
  ```sh
  /* Without using interpreter file */
  awk -f awkexample optional-arguments

  /* Using interpreter file */
  awkexample optional-arguments
  ```
* interpreter file提供了一种高效获取多个options的方式:
  ```sh
  /* Without using interpreter file */
  awk ’BEGIN {
    for (i = 0; i < ARGC; i++)
      printf "ARGV[%d] = %s\n", i, ARGV[i]
    exit
  }’ $*
  ```
  ```sh
  /* Using interpreter file */
  #!/usr/bin/awk -f
  BEGIN {
    for (i = 0; i < ARGC; i++)
      printf "ARGV[%d] = %s\n", i, ARGV[i]
    exit
  }
  ```
3. UNIX默认使用`/bin/sh`作为shell, interpreter file可指定其他shell
  ```text
  #!/bin/csh
  ```

以下是UNIX执行interpreter file的流程:
1. shell读取命令并对文件名调用`execlp`, 由于interpreter file为可执行文件, 而不是机器可执行码, 因此会返回错误.
2. 以interpreter file内的pathname作为shell
3. shell执行文件, 但运行`awk`, shell会调用`fork()`, `exec()`, 和`wait()`


## 11. system Function
ISO C定义了`system()`, 该函数的实现依赖于系统调用.
```c
#include <stdlib.h>

/**
 * @brief use fork() to create a child process that 
 *        executes the shell command specified in `cmd` 
 *        using execl() as follows:  
 *        execl("/bin/sh", "sh", "-c", cmd, (char *) NULL);
 * @return return after the command has been completed.
 *         The return value is one of the following:
 *         * nonzero if `cmd` is NULL, and shell is
 *           available; 0 if no shell is available
 *         * -1 if child process could not be created
 *           or its status could not be retrieved
 *         * if a shell could not be executed in the  
 *           child process, then the return value is 
 *           as though the child shell terminated by
 *           calling _exit() with status 127
 *         * if all system calls succeed, the return 
 *           value is the termination status of the
 *           child shell
 */
int system(const char *cmd);
```
在设置了set-user-ID bit的执行程序内调用`system()`可能造成安全漏洞, 因此永远不要这么做. 若以root权限执行程序, `system()`执行`fork()`和`exec()`后, child process的EUID会变为superuser, 而不是parent process的EUID, set-group-ID同理.


## 12. Process Accounting
UNIX系统中可开启**process accounting**(进程会计), 每当进程结束时, kernel都会写入一条**accounting record**(会计记录), 该记录会包含一些二进制数据, 如command名字, CPU占用时间, user ID, group ID, 和开始时间. `acct()`函数可用于开启或关闭process accounting:
```c
/**
 * @brief enable or disable process accounting. 
 * @param filename If it is an existing file, 
 *        accounting is turned on, and records for 
 *        each terminating process are appended to 
 *        filename as it terminates.
 *        If it is NULL, causes accounting to be 
 *        turned off.
 */
int acct(const char *filename);
```


## 13. Process Scheduling
UNIX只有粗粒度的进程调度, 每个进程的调度策略和优先级由kernel决定. 通过修改nice值, 可让低优先级的进程优先被执行. 越小的nice值, 进程的优先级越高, 因此, nice值也可以理解为: nice的进程不会占用太多CPU的时间, 会为其他进程腾出更多运行时间. 只有privileged process可以降低nice值, 非privileged process只能增加nice值来降低自身优先级.
```c
/**
 * @brief add `inc` to the nice value for the calling 
 *        thread. The range of nice value is [-20, 19]
 * @return new nice value is returned on success; 
 *         -1 on error and errno is set
 */
int nice(int inc);

/**
 * @brief obtain the scheduling priority of the process, 
 *        process group, or user as indicated by `which`
 *        and `who`.
 * @param which must be one of the following values:
 *        * PROI_PROCESS: process
 *        * PROI_PRGP: process group
 *        * PRIO_USER: user ID
 * @param who zero for the calling process, the process 
 *        group of the calling process, or the real user
 *        ID of the calling process.
 */
int getpriority(int which, id_t who);

/**
 * @brief set the scheduling priority of the process, 
 *        process group, or users as indicated by 
 *        `which`, `who`, and `prio`
 * @param prio a value in the range -20 to 19
 */
int setpriority(int which, id_t who, int prio);
```
The Single UNIX Specification规定nice值的范围为$[0, 2*\text{NZERO}-1]$, `NZERO`由系统决定. 但没有规定fork()创造的child process如何继承nice value.


## 14. Process Times
任何进程都可通过调用`times()`获取自身进程和其已中止子进程的以下三种时间:
* User CPU time: 进程在user space中执行指令所使用的CPU时间
* System CPU time: 进程在kernel space中执行指令所使用的CPU时间
* Wall clock: User CPU time和System CPU time之和

```c
struct tms {
  clock_t tms_utime;  /* user CPU time */
  clock_t tms_stime;  /* system CPU time */
  clock_t tms_cutime; /* terminated user CPU time of children */
  clock_t tms_cstime; /* terminated system CPU time of children */
};

/**
 * @brief store the current process times in the 
 *        struct `tms` that `buf` points to.
 * @return the number of clock ticks that have 
 *         elapsed since a point in the past. 
 *         return -1 on error and errno is set.
 */
clock_t times(struct tms *buf);
```
