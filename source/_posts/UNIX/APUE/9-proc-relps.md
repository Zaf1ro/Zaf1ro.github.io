---
title: Process Relationships
tags:
  - Unix
category:
  - Unix
abbrlink: ba76
date: 2019-09-11 14:52:00
---

## 1. Terminal Logins
早期UNIX系统中, terminal要么是local(接线直连主机), 要么是remote(通过modem连接), 这些登录都要通过kernel内的terminal device driver.
随着bitmapped graphical terminal(位图图形终端)的出现, windowing system(窗口系统)提供了与主机交互的新方式. 应用程序可创建"terminal windows"(终端窗口)来模拟基于字符的terminal, 允许用户以熟悉的方式进行交互(如shell命令行).
有些系统允许用户登录后启动窗口系统, 其他系统会自动启动窗口系统. 我们现在讨论的是: 使用terminal登录UNIX系统, 无论使用何种terminal, 过程都是相似的:
* character-based terminal
* 模仿character-based terminal的graphical terminal
* 运行windowing system的graphical terminal


## 2. BSD Terminal Logins
`/etc/ttys`文件中每一行表示一个terminal device(一种特殊device file), 每一行包含terminal device的名字, 执行的命令(通常为`getty`), 和一些输入参数. 启动UNIX系统时, kernel会创建一个`init`进程(PID 1), 该进程会读取`/etc/ttys`并尝试启动每一个terminal device.
![Processes invoked by init to allow terminal logins](/images/UNIX/APUE/9-2-process-when-login.jpg)

上述所有进程的real user ID和effective user ID均为0(拥有superuser权限). 除了`init`进程, 其他进程的PPID均为1.
1. `init`进程调用`fork()`生成子进程, 子进程调用`exec`执行`getty`程序
2. `getty`调用`open()`打开terminal device, 并将file descriptor 0, 1, 2设置为该terminal device.
3. `getty`的输出与`login`类似: 等待用户输出用户名
4. 当用户输入用户名后, `getty`的任务结束, 并调用`login`程序, 等同于:
  ```c
  execle("/bin/login", "login", "-p", username, (char *)0, envp);
  ```
5. 虽然`init`调用`getty`时没有任何环境, 但`getty`会为`login`创造一个环境(`envp`), 其中包括terminal的名字, 一些`gettytab`中的环境字符串. `-p`表示`login`需保留传入的环境.
6. `login`执行以下操作:
   1. 调用`getpwnam()`获取password file entry
   2. 调用`getpass()`获取用户输入的password
   3. 调用`crypt()`对password加密, 并与password file entry中的`pw_passwd`对比
   4. 若多次登录失败(密码错误), 则调用`exit(1)`. `init`会收到进程结束的通知, 并继续调用`fork()`, `exec()`和`getty`程序.

![State of processes after login has been invoked](/images/UNIX/APUE/9-2-process-after-login.jpg)

若成功登陆后, `login`会执行以下操作:
* 调用`chdir()`切换到用户的home directory
* 调用`chown()`将terminal device的所有权交给用户
* 将terminal device的读写权限交给login user
* 调用`setgid()`和`initgroups()`设置group ID
* 初始化environment, 如下:
  * home directory(`HOME`)
  * shell(`SHELL`)
  * user name(`USER`和`LOGNAME`)
  * 默认路径(`PATH`)
* 调用`setuid()`将进程的user ID改为当前用户, 并调用shell
    ```c
    execl("/bin/sh", "-sh", (char *)0);
    ```

由于`login`所在的进程拥有superuser权限, 因此`setuid()`可修改所有user ID(real user ID, effective user ID, saved set-user-ID). `setgid()`也是相同的效果. 此时`login` shell仍在运行, 其parent process为`init`, 因此当`login`结束时, `init`会收到`SIGCHLD` signal, 并重复执行上述流程.

![Arrangement of processes after everything is set for a terminal login](/images/UNIX/APUE/9-2-process-of-login.jpg)

最后`login` shell会读取**start-up file**(Bourne shell中的`.profile`; GNU Bourne-again shell中的`.bash_profile`, `.bash_login`, 或`.profile`; C shell中的`.cshrc`和`.login`). 这些start-up file会修改或添加environment variables, 例如, 大部分用户会设置自己的`PATH`.


## 3. Network Logins
serial terminal login与network login的主要区别: terminal与主机之间的**connection**是否为点对点. 
对于terminal login, `init`知道哪些terminal device可以登录, 并为每个terminal device生成各自`getty`进程; 但对于network login, 所有登录都通过kernel的network interface driver, 且无法得知何时发生. 网络中任何主机都可能登录当前主机, 因此与其为网络上每个主机创建`getty`进程, 不如等待网络请求.
为了给terminal login和network login一个统一入口, UNIX引入**pseudo terminal**(伪终端), 该driver用户模拟serial terminal的行为, 并将terminal操作映射为网络操作, 反之亦然.

### 3.1 BSD Network Logins
BSD中存在一个`inetd`进程, 也称为**internet superserver**, 其会等待绝大多数网络连接. 作为系统启动的一部分, `init`调用一个shell执行`/etc/rc` shell script, 该script会启动`inted`和其他daemon. 一旦该script中止运行, `inetd`的parent process变为`init`; `inetd`等待TCP/IP连接请求, 当连接达到主机时, `inetd`执行`fork()`, 并对合适的程序执行`exec`.
假设远程用户启动TELNET client开始登录, 向TELNET server发送TCP连接请求:
```sh
telnet hostname
```
client向hostname开启一个TCP连接, 下图展示了TELNET server中的进程执行:
![Sequence of processes involved in executing TELNET server](/images/UNIX/APUE/9-3-telnet-login.jpg)

`telnetd`开启一个pseudo terminal device, 并调用`fork()`拆分为两个进程:
* parent process(`telnetd`): 处理网络连接中的通信请求
* child process: 调用`exec`执行`login`程序. 调用`exec`前会将stdin, stdout, stderr指向该pseudo terminal device.

![Arrangement of processes after everything is set for a network login](/images/UNIX/APUE/9-3-network-login.jpg)

无论通过terminal还是network登录, 都会创建一个`login` shell, 其stdin, stdout, stderr指向terminal device或pseudo terminal device.


## 4. Process Groups
每个进程都有一个process ID, 且属于一个**process group**.
* 一个process group包含一个或多个进程, process group内的进程通常拥有相同任务.
* 当process group收到signal时, process group内的所有process都会收到signal. 
* 每个process group拥有一个唯一process group ID. Process group ID与process ID类似: 都为正整数, 存放在`pid_t`数据类型中.
* 每个process group可有零个或一个**process group leader**, 该进程的process ID与process group ID相同.
* 若process group中没有进程, 该group的生存周期结束.

```c
/**
 * @brief get the process group ID of the calling process
 */
pid_t getpgrp(void);

/**
 * @brief get the process group ID of the process whose 
 *        process ID is equal to `pid`
 * @param pid if it is 0, return the process group ID of 
 *        the calling process
 */
pid_t getpgid(pid_t pid);

/**
 * @brief set the PGID of the process specified by `pid` 
 *        to pgid.
 * @param pid If it is 0, use the process ID of the 
 *        calling process
 * @param pgid if it is 0, use `pid`
 */
int setpgid(pid_t pid, pid_t pgid);
```
`setpgid()`遵循以下规则:
* 进程只能设置自身和其child process的process group ID
* 当child process调用`exec`后, 进程无法修改其process group ID

我们可向一个process, 或一个process group发送signal. 相同的, `waitpid`函数允许我们等待某个process, 或某个process group中的一个process.


## 5. Sessions
Session包含一个或多个process group, session内的所有process group使用同一个terminal device. Session一般用于job control: session中某个process group作为**foreground process group**, 用于接收特殊字符产生的signal, 进程可设置当前session的foreground process group. 以下是terminal的访问控制:
* foreground process group中的进程允许读取terminal device; background process group中的进程尝试读取terminal device时会收到`SIGTTIN` signal.
* foreground process group中的进程允许写入terminal device; background process group中的进程尝试写入terminal device时会收到`SIGTTOU` signal.

当session中没有与foreground process group ID匹配的process ID或process group ID, 则terminal没有foreground process group.

以下就是一个session和三个process group:
![Arrangement of processes into process groups and sessions](/images/UNIX/APUE/9-5-process-group-and-session.jpg)

```c
/**
 * @brief create a new session if the calling process 
 *        is not a process group leader.
 *        * The calling process becomes the session 
 *          leader of the new session 
 *        * The calling process becomes the process  
 *          group leader of a new process group
 *        * The calling process has no terminal device
 * @return error if the calling process is already 
 *         a process group leader
 */
pid_t setsid(void);

/**
 * @brief return the session ID of the process with 
 *        process ID `pid`
 * @param pid If it is 0, return the session ID of 
 *        the calling process.
 */
pid_t getsid(pid_t pid);
```
由于没有session ID的概念, 所以session由session leader决定. Session leader的PID也相当于session ID.


## 6. Controlling Terminal
Session和process group有以下几个特点:
1. 一个session只有一个**controlling terminal**(通常为登录时的terminal device或pseudo terminal device)
2. 与controlling terminal建立连接的session leader称为**controlling process**
3. 一个session内的process group分为一个**foreground process group**和多个**background process group**
4. 当用户按下terminal的interrupt key(通常为Control-C)或quit key(通常为Control-backslash)时, foreground process group中的所有进程都会收到interrupt signal
5. 若controlling terminal检测到modem或network中断, controlling process会收到hang-up signal

![Process groups and sessions showing controlling terminal](/images/UNIX/APUE/9-6-term-and-session.jpg)


## 7. tcgetpgrp, tcsetpgrp and tcgetsid Functions
进程可通过以下函数指定哪个process group为foreground process group, 这样terminal device driver就知道该向谁发送terminal input和terminal-generated signal.
```c
/**
 * @brief return the process group ID of the foreground 
 *        process group on the terminal associated to 
 *        `fd`
 * @param fd must be the controlling terminal of the 
 *        calling process
 */
pid_t tcgetpgrp(int fd);

/**
 * @brief make the process group with process group ID 
 *        `pgrp` the foreground process group on the 
 *        terminal associated to `fd`
 * @param fd must be the controlling terminal of the 
 *        calling process, and still be associated 
 *        with its session
 * @param pgrp must be a process group belonging to 
 *        the same session as the calling process
 */
int tcsetpgrp(int fd, pid_t pgrp);

/**
 * @brief return the session ID(session leader's PID) 
 *        of the current session that has the terminal
 *        associated to `fd` as controlling terminal
 * @param fd must be the controlling terminal of the 
 *        calling process
 */
pid_t tcgetsid(int fd);
```
若background process group内的进程调用`tcsetpgrp()`, 且该进程没有阻塞或忽略`SIGTTOU` signal, 该process group内的所有进程都会收到`SIGTTOU` signal.


## 8. Job Control
Job control允许我们在一个terminal内启动多个job(多个process group), 其中一个job可以访问terminal, 其他job在后台运行. Job control的实现需要以下几点:
* shell支持job control
* kernel中的terminal driver支持job control
* kernel支持job-control signals

在shell中使用job control时, job要么是**foreground job**(等同于foreground process group), 要么是**background job**(等同于background process group). 一个job就是一组进程, 通常使用**pipe**(管道)串联进程. 我们可以在前台启动一个job, 其中包含一个进程:
```sh
vi main.c
```
也可以在后台启动两个job:
```sh
pr *.c | lpr &
make all &
```
当我们启动一个background job时, shell会为其分配一个job identifier, 并输出所有process ID:
```sh
$ make all > Make.out &
[1] 1475
$ pr *.c | lpr &
[2] 1490
$   # just press RETURN
[2] + Done pr *.c | lpr &
[1] + Done make all > Make.out &
```
* 第一行的`make`的job编号为1, PID为1475. 第三行的job编号为2, PID为1490
* 当job结束且我们按下`RETURN`时, shell会告诉我们job已完成. 由于shell无法告知background job的状态改变, 因此需要我们输入`RETURN`.
* terminal driver可接收三种特殊字符并将其转换为特定signal:
  * interrupt character(Control-C): `SIGINT`
  * quit character(Control-Backslash): `SIGQUIT`
  * suspend character(Control-Z): `SIGTSTP`

可以存在一个或多个foreground job, 但只有foreground job可以接收terminal input(我们在terminal输入的字符). Background job可以去获取terminal input, 但terminal driver会向该background job发送`SIGTTIN` signal, 该signal通常会停止background job.
```sh
cat > temp.foo &   # background job, but will try to read from terminal
[1] 1681
$                  # press RETURN
[1] + Stopped (SIGTTIN) cat > temp.foo &
$ fg %1            # move the background job to the foreground
cat > temp.foo     # shell tells us which job is now in the foreground
hello, world       # enter one line
ˆD                 # type the end-of-file character
$ cat temp.foo     # check the content of file
hello, world
```
* 当后台的`cat`尝试从terminal读取字符时, terminal driver会向其发送`SIGTTIN` signal
* shell检测到child process的状态变化(通过`wait()`和`waitpid()`), 并通知用户该job已经停止
* `fg`命令将已停止的job改为foreground job(`tcsetpgrp()`), 并向该job发送`SIGCONT` signal(让job继续运行)
* 由于job已成为foreground job, 因此可以从terminal读取用户输入

`stty`可让background job无法向terminal输出数据:
```shell
$ cat temp.foo &   # start background job
[1] 1719
$ hello, world     # the output from the background job
we press RETURN    # stop background job
[1] + Done cat temp.foo & 
$ stty tostop      # prevent background job outputing to terminal
$ cat temp.foo &   # start background again
[1] 1721
$                  # press RETURN and the background job is stopped
[1] + Stopped(SIGTTOU) cat temp.foo &
$ fg %1            # move the stopped job to the foreground
cat temp.foo       # shell tells us which job is now in the foreground
hello, world       # output successfully
```
禁止background job输出到terminal后, 当`cat`尝试向terminal输出字符时, terminal driver会阻止background job的输出, 并向该job发送`SIGTTOU` signal. 使用`fg`命令后, job移至前台并顺利输出. 下图为job control的流程:
![Summary of job control features with foreground and background jobs, and terminal driver](/images/UNIX/APUE/9-8-job-ctrl-with-fg-and-bg-job.jpg)


## 9. Shell Execution of Prgrams
本节将讨论shell如何执行程序, 以及和process group, terminal, session的关系.

### 9.1 The shell without job control: the Bourne shell on Solaris¶
```sh
$ ps -o pid,ppid,pgid,sid,comm
PID   PPID  PGID  SID  COMMAND
949   947   949   949  sh
1774  949   949   949  ps
```
* `ps`命令的parent process为shell
* 由于shell不支持job control, 因此shell和`ps`程序处于同一session和同一foreground process group

```sh
$ ps -o pid,ppid,pgid,sid,comm &
PID   PPID  PGID  SID  COMMAND
949   947   949   949  sh
1812  949   949   949  ps
```
后台执行上述命令时, 唯一变动就是PID. 由于shell不支持job control, 因此不会为background job创建一个新的process group, background job也依然拥有terminal.

```sh
$ ps -o pid,ppid,pgid,sid,comm | cat1
PID   PPID  PGID  SID  COMMAND
949   947   949   949  sh
1823  949   949   949  cat1
1824  1823  949   949  ps
```
上述为shell处理pipeline的情况: `cat1`与`cat`程序相同, 只是名字不同. `cat1`为shell的child process, `ps`为`cat1`的child process. 看起来shell调用`fork()`生成自身副本, 该副本又调用`fork()`处理pipeline前面的部分.

```sh
$ ps -o pid,ppid,pgid,sid,comm | cat1 &
```
后台执行上述命令时, 唯一变动就是PID.由于shell不支持job control, background process的process group ID仍为949, session的process group ID也不变.
若background process尝试从terminal读取输入, 如`cat > temp.foo &`, 由于shell不支持job control, 若background process没有重定向自己的stdin, shell会自动将其stdin重定向到`/dev/null`. 读取`/dev/null`会返回一个end-of-file, 因此background process会读取到end-of-file并立即中止.

### 9.2 The shell with job control: Bourne-again shell on Linux
```sh
$ ps -o pid,ppid,pgid,sid,tpgid,comm
PID   PPID  PGID  SID   TPGID  COMMAND
2837  2818  2837  2837  5796   bash
5796  2837  5796  2837  5796   ps
```
* `ps`命令拥有自己的process group.
* `ps`命令是所在process group的leader. 该process group为foreground process group, 因为其拥有controlling terminal.
* `ps`命令执行期间, login shell为background process group.
* 两个process group属于同一session.

```sh
$ ps -o pid,ppid,pgid,sid,tpgid,comm &
PID   PPID  PGID  SID   TPGID  COMMAND
2837  2818  2837  2837  2837   bash
5797  2837  5797  2837  2837   ps
```
后台执行上述命令时:
* `ps`命令依然拥有自己的process group
* process group(5797)为background process group
* login shell为foreground process group

```sh
$ ps -o pid,ppid,pgid,sid,tpgid,comm | cat1
PID   PPID  PGID  SID   TPGID  COMMAND
2837  2818  2837  2837  5799   bash
5799  2837  5799  2837  5799   ps
5800  2837  5799  2837  5799   cat1
```
pipeline中执行两个进程:
* `ps`和`cat1`属于一个新的process group, 作为foreground process group
* login shell为其他进程的parent process. 但与Bourne shell不同的是, 其先创建`ps`, 后创建`cat1`

```shell
$ ps -o pid,ppid,pgid,sid,tpgid,comm | cat1 &
PID  PPID PGID SID  TPGID COMMAND
2837 2818 2837 2837 2837  bash
5801 2837 5801 2837 2837  ps
5802 2837 5801 2837 2837  cat1
```
后台执行上述命令: 结果相同, 但`ps`和`cat1`所在的process group为background process group.


## 10. Orphaned Process Groups
若child process仍在运行, 但其parent process中止, 则该child process称为**orphaned**, 其parent process改为init(PID 1).
```c
#include "apue.h"
#include <errno.h>

static void sig_hup(int signo)
{
  printf("SIGHUP received, pid = %ld\n", (long)getpid());
}

static void pr_ids(char *name)
{
  printf("%s: pid = %ld, ppid = %ld, pgrp = %ld, tpgrp = %ld\n",
    name, (long)getpid(), (long)getppid(), (long)getpgrp(),
    (long)tcgetpgrp(STDIN_FILENO));
  fflush(stdout);
}

int main(void)
{
  char c;
  pid_t pid;
  pr_ids("parent");

  if ((pid = fork()) < 0) {
    err_sys("fork error");
  } else if (pid > 0) { /* parent */
    sleep(5);           /* sleep to let child stop itself */
  } else {              /* child */
    pr_ids("child");
    signal(SIGHUP, sig_hup); /* establish signal handler */
    kill(getpid(), SIGTSTP); /* stop ourself */
    pr_ids("child");         /* prints only if we’re continued */
    if (read(STDIN_FILENO, &c, 1) != 1)
      printf("read error %d on controlling TTY\n", errno);
  }
  exit(0);
}
```
以下是运行结果:
```sh
$ ./a.out
parent: pid = 6099, ppid = 2837, pgrp = 6099, tpgrp = 6099
child: pid = 6100, ppid = 6099, pgrp = 6099, tpgrp = 6099
SIGHUP received, pid = 6100
child: pid = 6100, ppid = 1, pgrp = 6099, tpgrp = 2837
read error 5 on controlling TTY
```
* 当前程序成为foreground process group, parent process和child process处于同一process group(6099), shell的process group为2837
* 调用`fork()`后, parent process调用`sleep()`, 保证child process先执行
* child process建立`SIGHUP`的signal handler
* child process调用`kill()`, 向自身发送`SIGSTP`. 该signal会暂停child process, 等同于用户在terminal输入suspend character(Control-Z)
* 当parent process中止时, child process成为orphaned, 因此其paraent process ID为1, 也就是`init`进程
* 此时, child process成为**orphaned process group**的一员:
  * 当controlling process中止时, 其他session就可以使用其terminal. 为防止之前session中其他进程使用terminal, 该session中的所有process group都被标记为**orphaned process group**
  * 当process group成为orphan, 所有进程都会收到`SIGHUP`. 通常来说, 该signal会让进程终止, 但进程可选择忽略该signal, 或为该signal建立handler, 进程仍可在orphan process group中运行.
* shell收到两条输出, 来自login shell和child process. child process的PPID为1
* child process调用`read()`尝试从terminal读取输入. `read()`返回error, 并将errno设置为`EIO`.
  * 当background process group中的进程尝试读取terminal输入时, background process group会收到`SIGTTIN`; 但对于orphaned process group, 若kernel使用该signal停止进程, 则进程可能永远无法继续运行.
* 由于parent process以foreground job执行, 因此parent process中止后, child process会被放入background process group中.


## 11. FreeBSD Implementation
![FreeBSD implementation of sessions and process groups](/images/UNIX/APUE/9-11-impl-of-session-and-proc-grp.jpg)

`session`: 每个session都有该一个structure
* s_count: session内的process group数量. 若该field为0, 则释放`session`
* s_leader: 指向session leader的`proc` structure
* s_ttyvp: 指向controlling terminal的`vnode` structure
* s_ttyp: 指向controlling terminal的`tty` structure
* s_sid: session ID(PID of session leader process)

调用`setsid()`时, 会在kernel中分配一个`session`. `s_count`为1, `s_leader`指向当前进程的`proc`, `s_sid`为当前进程的PID, 由于新建session没有controlling terminal, 因此`s_ttyvp`和`s_ttyp`为NULL.

`tty`: 每个terminal device和pseudo terminal device都有该structure
* t_session: 指向controlling terminal的`session` structure
* t_pgrp: 指向foreground process group的`pgrp` structure. Terminal driver使用该field向foreground process group发送signal(interrupt, quit, suspend).
* t_termios: 包含special character和terminal相关信息的structure
* t_winsize: 包含当前terminal大小的`winsize` structure

`pgrp`: 包含一个process group相关信息的structure
* pg_id: process group ID
* pg_session: 指向当前process group所属的session的`session` structure
* pg_members: 指向一个`proc` structure列表, 包含当前process group的所有进程
