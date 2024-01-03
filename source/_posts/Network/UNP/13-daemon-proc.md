---
title: Daemon Processes and the inetd Superserver
date: 2020-01-01 10:20:30
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: '2505'
keywords:
description:
---

## 1. Introduction
Daemon是一种运行在后台且不与任何controlling terminal绑定的进程. UNIX通常会在后台运行多个daemon, 用于执行administrative task. 由于缺少controlling terminal, daemon通常由system initialization script启动; 但如果daemon由shell prompt启动, 则需要与controll terminal解绑来避免job control, terminal session management和输出到terminal的信息.
以下是启动一个daemon的方法:
1. 系统启动时, 可通过system initialization script启动daemon. 这些script通常放置在`/etc`或`/etc/rc`中. Daemon具有superuser权限. 
2. `inetd`作为superserver, 是系统启动时运行的一个daemon, 用于为其他service提供网络服务. `inetd`会一直监听网络请求(Telnet, FTP等), 收到请求后唤醒相应的server(Telnet server, FTP server等).
3. `cron`作为一个系统启动时就开始运行的daemon, 用于在规定的时间运行特定程序, 被启动的程序也会以daemon的形式运行.
4. Daemon可通过user terminal启动, 一般用于测试或重启daemon

由于daemon没有controlling terminal, 所以需要其他方法来输出信息. 可通过`syslog()`将信息发送给syslogd daemon, 实现信息输出. 


## 2. syslogd Daemon
System administrator需要处理系统中不同service产生的不同message, 例如: FTP server接收到connection的通知信息, hardware failure的错误信息, DNS server回复的统计信息. 由于不同信息的优先级不同, 处理方式不同, 需要将各个信息传递到不同的地方. Syslogd daemon就是用于处理这些信息:
1. Syslogd daemon会创建一个UNIX domain socket名为`/dev/log`, 监听port 514并接收service或其他host发来的信息. 
2. `syslog.conf`文件作为syslogd daemon的配置文件, 用于分类信息, 通常放置在`/etc/syslog.conf`. 接收到的日志信息通常重定向到以下地方:
    * system console
    * 特定user
    * log file
    * 其他host上的syslogd daemon
    * 直接抛弃.
3. Syslog可以处理kernel传来的信息, 但不是直接写入`/dev/log`, 而是由其他daemon(klogd)处理

进程可通过创建UNIX domain datagram socket向syslogd所绑定的pathname发送信息, 也可调用`syslog()`发送信息. 一些新的系统中取消了UDP socket传递信息的方式, 因为可能导致系统遭受denial-of-service attack.


## 3. syslog Function
由于daemon没有controlling terminal, 所以`fprintf()`无法输出错误信息, 需调用`syslog()`输出log message:
```c
#include <syslog.h>

/**
 * @brief send message to the system logger
 * @param priority: formed by `facility` and `level`
 * @param message: log message, %m will be replaced by errno
 */
void syslog(int priority, const char *message, ...);
```
当application调用`syslog()`时, 会创建一个UNIX domain datagram, 并向syslogd daemon创建的pathname发起`connect()`. 以下是log message的level value:

| level | value | Description |
|:----:|:----:|:----:|
| LOG_EMERG   | 0 | System is unusable (highest priority) |
| LOG_ALERT   | 1 | Action must be taken immediately |
| LOG_CRIT    | 2 | Critical conditions |
| LOG_ERR     | 3 | Error conditions |
| LOG_WARNING | 4 | Warning conditions |
| LOG_NOTICE  | 5 | Normal but significant condition |
| LOG_INFO    | 6 | Informational |
| LOG_DEBUG   | 7 | Debug-level messages (lowest priority) |

以下是log message的facility value:

| facility | Description |
|:----:|:----:|
| LOG_AUTH     | Security / authorization messages |
| LOG_AUTHPRIV | Security / authorization messages (private) |
| LOG_CRON     | cron daemon |
| LOG_DAEMON   | System daemons |
| LOG_FTP      | FTP daemon |
| LOG_KERN     | Kernel messages |
| LOG_LOCAL0   | Local use |
| LOG_LOCAL1   | Local use |
| LOG_LOCAL2   | Local use |
| LOG_LOCAL3   | Local use |
| LOG_LOCAL4   | Local use |
| LOG_LOCAL5   | Local use |
| LOG_LOCAL6   | Local use |
| LOG_LOCAL7   | Local use |
| LOG_LPR      | Line printer system |
| LOG_MAIL     | Mail system |
| LOG_NEWS     | Network news system |
| LOG_SYSLOG   | Messages generated internally by syslogd |
| LOG_USER     | Random user-level messages (default) |
| LOG_UUCP     | UUCP system |

```c
#include <syslog.h>

/**
 * @brief open or reopen a connection to syslog in preparation 
 *        for submitting messages
 * @param ident: typically set to the program name
 * @param option: control the operation of openlog()
 * @param facility: specify what type of program is logging the 
 *        message
 */
void openlog(const char *ident, int option, int facility);

/**
 * @brief close the descriptor being used to write to the system
 *        logger
 */
void closelog(void);
```
以下是`openlog()`中所有option value:

| options | Description |
|:---:|:---:|
| LOG_CONS | Log to console if cannot send to syslogd daemon |
| LOG_NDELAY | Do not delay open, create socket now |
| LOG_PERROR | Log to standard error as well as sending to syslogd daemon |
| LOG_PID | Log the Process ID with each message |


## 4. daemon_init Function
```c
int daemon_init(const char *pname, int facility) {
  int i;
  pid_t pid;
  
  /* terminate the parent to disassociate from shell command */
  if ((pid = fork()) < 0) {
    fprintf(stderr, "fork error\n");
    return -1;
  } else if (pid) // parent
    _exit(0);

  /* child 1 is not a process group leader but gets own PID */
  if (setsid() < 0) { /* become the session leader of new session */
    fprintf(stderr, "setsid error\n");
    return -1;
  }

  /* ignore the SIGHUP signal to avoid all processes in the
   * session receive the signal when session leader terminates */
  signal(SIGHUP, SIG_IGN);

  /* child 2 won't be a session leader, so it cannot acquire
   * a controlling terminal */
  if ((pid = fork()) < 0) {
    return -1;
  } else if (pid)
    _exit(0);  // child 1 terminateds

  // daemon_proc = 1; // for err_xxx() functions
  chdir("/"); /* change working directory to the root directory */

  /* close all file descriptors */
  for (i = 0; i < MAXFD; i++) {
    close(i);
  }

  /* redirect stdin, stdout and stderr to /dev/null */
  open("/dev/null", O_RDONLY);
  open("/dev/null", O_WRONLY);
  open("/dev/null", O_RDWR);

  /* open a conection to syslog */
  openlog(pname, LOG_PID, facility);

  return 0;
}
```


## 5. inetd Daemon
UNIX系统中会有多个servers等待client发送请求, 例如: FTP, Rlogin, TFTP等. 4.3BSD之前, 每个server都会在系统启动时作为daemon进程运行, 收到client请求后调用`fork()`处理, 但这么做存在以下缺陷:
1. 每个daemon存在大量重复代码, 如创建socket, 调用`bind()`绑定server port等
2. 每个daemon占用process table的slot, 但绝大多数时间都处于睡眠状态

4.3BSD提出internet superserver: inetd daemon. 该daemon解决了两个问题:
1. 省去每个server进程切换为daemon process的过程
2. 省去每个server等待client请求, 只需要inetd一个进程等待即可

inetd的配置文件一般位于`/etc/inetd.conf`, 文件中每一行包含server的所有信息:
* service-name: 必须出现在`/etc/services`中
* socket-type: TCP或UDP
* protocol: 必须出现在`/etc/protocols`中
* wait-flag: TCP使用`nowait`, UDP使用`wait`
* login-name: 必须出现在`/etc/passwd`中
* server-program: exec执行所需的pathname
* server-program-arguments: exec执行所需的arguments

以下是`inetd.conf`的一些例子:
```sh
ftp     stream  tcp  nowait  root  /usr/bin/ftpd     ftpd -1
telnet  stream  tcp  nowait  root  /usr/bin/telnetd  telnetd
login   stream  tcp  nowait  root  /usr/bin/rlogind  rlogind -s
```

以下是inetd执行的步骤:
![Steps performed by inetd](/images/Network/UNP/13-5-steps-of-inetd.gif)

1. 启动时, 会读取`/etc/inetd.conf`文件信息, 并为所以service创建socket, 每个新建的socket会被添加到`select()`中.
2. 对service-name和protocol调用`getservbyname()`可获取TCP和UDP port, 并调用`bind()`为socket绑定wildcard IP address个port number
3. 对于TCP socket, 需要调用`listen()`接收client请求
4. inetd大部分时间处于sleep状态, 只有socket处于readable状态时, `select()`才会接触阻塞
5. `select()`返回后, inetd daemon会调用`fork()`生成child process来处理请求. child process会关闭除socket descriptor之外所有descriptor; 调用`dup2()`复制descriptor 0, 1, 2; 关闭socket descriptor, 这样开启的只有descriptor 0, 1, 2; 调用`getpwnam()`获取login username对应的password file entry; 若username不为root, 则调用`setgid()`和`setuid()`, 将child process的UID和GID改为0.
6. 若为stream socket, 需要关闭socket. parent process再次调用`select()`等待socket可读.

假设inetd正在运行, 收到一个FTP client请求:
![inetd descriptors when connection request arrives for TCP port 21](/images/Network/UNP/13-5-inetd-when-req-arrive.gif)

inetd收到请求后, 调用`fork()`创建新的进程, 并与所有listening socket断开:
![inetd descriptors in child](/images/Network/UNP/13-5-inetd-in-child-proc.gif)

之后child process开始复制descriptor 0, 1, 2, 并关闭connected socket:
![inetd descriptors after dup2](/images/Network/UNP/13-5-inetd-after-dup2.gif)

最后child process调用exec执行真正的server程序, server可通过descriptor 0, 1, 2与client通信. 以上场景基于`nowait`, 意味着接收另一个service的connection之前, inetd不需要等待一段时间再终止child process. `wait` flag可改变parent process的执行步骤:
1. 调用`fork()`返回后, parent process会保存child process的PID. 得知child process终止运行后, 运行`waitpid()`回收.
2. parent process会使用FD_CLR讲child process所使用的socket从`select()`中移除, 直到child process停止运行.
3. 当child process终止运行时, 其parent process会受到SIGCHLD signal, parent process可通过signal handler获取child process的PID, 并恢复`select()`对socket的监听.

之所以当datagram server存在连接时将socket从`select()`中移除, 就是为了防止inetd中`select()`不断检测socket的可读性: 对于TCP server, 当`select()`检测到socket可读时会让listening socket创建连接, 并通过connected socket处理请求; 但对于datagram socket, 由于不存在连接一说, 所以inetd调用`fork()`后的child process依旧使用原来的socket. 假设inetd没有关闭`select()`对socket可读性的监听, 且`fork()`执行后parent process首先执行, 则会再次检测到该socket可读, 并再次调用`fork()`. 为避免循环检测socket可读性, 必须在`fork()`前停止对socket可读性的监听; child process运行结束后向parent process发送`SIGCHLD` signal, 因此parent process会恢复`select()`对datagram socket的可读性监听. 


## 6. daemon_inetd Function
```c
#include <syslog.h>

extern int daemon_proc; /* defined in error.c */

void daemon_inetd(const char *pname, int facility)
{
  daemon_proc = 1; /* for our err_XXX() functions */
  openlog(pname, LOG_PID, facility);
}
```
相对于`daemon_init()`, `daemon_inetd()`使用inetd将进程变为daemon, 并通过设置`daemon_proc` flag实现error message的输出.
