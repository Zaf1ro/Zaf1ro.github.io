---
title: TCP Client/Server
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: 66fb
date: 2019-11-23 20:41:04
---

## 1. Introduction
本章将编写一个简单的TCP client/server, 主要有以下功能:
1. client从standard iunput读取一行文本, 并写给server
2. server从network input读取文本, 并将该文本发送回client
3. client从network input读取文本, 并输出到standard output

整个TCP client/server的流程如下:
![Simple echo client and server](/images/Network/UNP/5-1-simple-echo-cli-svr.gif)
`fgets()`和`fputs()`为standard I/O functions, `writen()`和`readlin()`为自定义函数


## 2. TCP Echo Server: main Function
创建一个父进程listen请求, 子进程来处理请求
```c
int main(int argc, char **argv)
{
  int                listenfd, connfd;
  pid_t              childpid;
  socklen_t          clilen;
  struct sockaddr_in cliaddr, servaddr;

  /* Create a TCP socket */
  listenfd = Socket(AF_INET, SOCK_STREAM, 0);
  
  bzero(&servaddr, sizeof(servaddr));

  /* IP Address使用通配符, Port number使用SERV_PORT (9877) */
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);
  Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));
  
  /* Convert into a passive socket */
  Listen(listenfd, LISTENQ);
  
  for ( ; ; ) {
    clilen = sizeof(cliaddr);
    /* Wait for a client connection to complete */
    connfd = Accept(listenfd, (SA *) &cliaddr, &clilen);

    /* Create a child process to handle the new client */
    if ((childpid = Fork()) == 0) {
      /* Close listening socket in child process */
      Close(listenfd);
      str_echo(connfd);
      exit(0);
    }
    Close(connfd); /* Close the connected socket in parent process */
  }
}
```


## 3. TCP Echo Server: str_echo Function
`str_echo()`负责从client请求中读取数据, 并将数据发送回client
```c
void str_echo(int sockfd)
{
  ssize_t n;
  char    buf[MAXLINE];

again:
  /* Read data from the socket */
  while ((n = read(sockfd, buf, MAXLINE)) > 0)
    Writen(sockfd, buf, n); // echo back to the client

  if (n < 0 && errno == EINTR) /* EINTER代表accept()被打断, 需要重新执行 */
    goto again;
  else if (n < 0) /* 连接正常, 但client请求中无数据 */
    err_sys("str_echo: read error");
}
```


## 4. TCP Echo Client: main Function
与server连接并传输数据
```c
int main(int argc, char **argv)
{
  int sockfd;
  struct sockaddr_in servaddr;
  
  if (argc != 2)
    err_quit("usage: tcpcli <IPaddress>");
  
  sockfd = Socket(AF_INET, SOCK_STREAM, 0);
  
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_port = htons(SERV_PORT);

  /* take server's IP address from command-line argument */
  Inet_pton(AF_INET, argv[1], &servaddr.sin_addr);
  
  /* Establish the connection with the server */
  Connect(sockfd, (SA *) &servaddr, sizeof(servaddr));
  
  /* handle the rest of the client processing */
  str_cli(stdin, sockfd);
  
  exit(0);
}
```


## 5. TCP Echo Client: str_cli
`str_cli()`负责从standard input中读取文本, 发送给server并读取server传回的文本.
```c
void str_cli(FILE *fp, int sockfd)
{
  char sendline[MAXLINE], recvline[MAXLINE];

  /* read a line of text from standard input */
  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    /* Send text to server */
    Writen(sockfd, sendline, strlen(sendline));
    
    /* Read data from server */
    if (Readline(sockfd, recvline, MAXLINE) == 0)
      err_quit("str_cli: server terminated prematurely");
    
    /* Output data to standard output */
    Fputs(recvline, stdout);
  }
}
```


## 6. Normal Startup
```sh
$ tcpserv01 &
[1] 17870
```
当server启动时, 会依次调用`socket()`, `bind()`, `listen()`和`accept()`, 并阻塞于`accept()`. client运行前, 可执行`netstat`命令查看server的socket状态:
```sh
$ netstat -a
Active Internet connections (servers and established)
Proto Recv-Q  Send-Q  Local Address  Foreign Address  State
tcp   0       0       *:9877         *:*              LISTEN
```
从上述可得知: 该socket处于`LISTEN`状态, Local IP address为通配符, port number为9877, 可接收任意IP address和port number的请求.

由于client和server处于同一主机, 所有指定server的IP address为`127.0.0.1`:
```sh
$ tcpcli01 127.0.0.1
```
Client会依次调用`socket()`和`connect()`. TCP的三次握手完成后, client的`connect()`调用完毕, server的`accept()`调用完毕. 连接建立后执行以下步骤:
1. client调用`str_cli()`, 阻塞于`fgets()`, 等待用户在command line输入字符 
2. server的`accept()`完成调用后, 调用`fork()`生成子进程: 子进程调用`readline()`等待client传来数据; 父进程继续调用`accept()`等待下一个client的请求

这其中存在三个可能阻塞的进程: client, server的prarent process, server的child process. 这时client与server已建立连接但client端还未输入数据, 执行`netstat`查看连接状态:
```sh
$ netstat -a
Active Internet connections (servers and established)
Proto Recv-Q  Send-Q  Local Address   Foreign Address  State
tcp   0       0       localhost:9877  localhost:42758  ESTABLISHED
tcp   0       0       localhost:42758 localhost:9877   ESTABLISHED
tcp   0       0       *:9877          *:*              LISTEN
```
从上向下依次为:
1. server子进程: 与client建立连接, 状态为`ESTABLISHED`. 
2. client进程: 与server建立连接, 其port number为kernel随机分配 (42758)
3. server父进程: 等待新的client请求

使用`ps`命令查看进程之间的状态:
```sh
$ ps -t pts/6 -o pid,ppid,tty,stat,args,wchan
PID    PPID   TTY    STAT  COMMAND           WCHAN
17870  22038  pts/6  S     ./tcpserv01       wait_for_connect
19315  17870  pts/6  S     ./tcpserv01       tcp_data_wait
19314  22038  pts/6  S     ./tcpcli01 127.0  read_chan
```
从上向下进程依次为:
1. server父进程: 其PID为17870, 处于`sleep`状态, 等待新的client请求 
2. server子进程: 其PID为19315, 其父进程PID为17870, 处于`sleep`状态, 等待client传入数据
3. client进程: 处于`sleep`状态, 等待用户I/O输入


## 7. Normal Termination
通过输入`EOF`(通常为Control-D)可终止client与server的连接:
```sh
$ tcpcli01 127.0.0.1
hello, world
hello, world
good bye
good bye
^D
```
输入EOF后立刻执行`netstat`命令:
```sh
$ netstat -a | grep 9877
Proto Recv-Q Send-Q  Local Address    Foreign Address State
tcp   0      0       *:9877           *:*             LISTEN
tcp   0      0       localhost:42758  localhost:9877  TIME_WAIT
```
以下是server和client正常终止连接的整个步骤:
1. client端输入EOF字符, `fgets()`返回NULL, `str_cli()`退出while循环并返回
2. client端`main()`中调用`exit()`开始退出进程
3. 进程退出时会关闭所有开启的file descriptor, 其中client的socket会被kernel关闭. client向server发送FIN, server回应ACK. 此时TCP 4-way handshake termination进行一半, server端socket处于`CLOSE_WAIT`状态, client端socket处于`FIN_WAIT_2`状态.
4. server收到FIN后, server子进程中`read()`返回0, `str_echo()`返回.
5. server子进程调用`exit()`, 开始关闭所有打开的file descriptor, 这时开始完成TCP 4-way handshake termination的后半段: server向client发送FIN, client回复ACK, client socket进入`TIME_WAIT`状态.
6. server子进程中止时向父进程发送`SIGCHLD` signal. 由于server父进程未设置signal handler, 因此server子进程成为**zombie**(僵尸进程):
```sh
$ ps -t pts/6 -o pid,tty,stat,args,wchan
PID    PPID   TT     STAT   COMMAND      WCHAN	
17870  22038  pts/6  S      ./tcpserv01  wait_for_connect
19315  17870  pts/6  Z      ./tcpserv01  do_exit
```


## 8. POSIX Signal Handling
signal可以理解为发送给进程的notification, 通知进程发生了某件事, 也称为software interrupt. signal是异步的, 因此进程无法得知signal何时到达. signal可由进程发出, 也可由kernel发出. `SIGCHLD`作为signal的一种, 由kernel发出, 用于通知父进程其子进程已中止.
每个signal都有一个disposition, 也称为action. 调用`sigaction()`可设置当前进程对某个signal的disposition:
1. 为特定signal提供一个signal handler: 进程捕获该signal后自动执行signal handler (`SIGKILL`和`SIGSTOP`无法设置signal handler):
```c
void handler(int signo);
```
2. 忽略signal: 将disposition设置为`SIG_IGN`可忽略指定signal (SIGKILL和SIGSTOP不可忽略)
3. 默认disposition: 将disposition设置为`SIG_DFL`会启用default disposition, 一般接收到signal后会中止进程, 部分signal的默认disposition为忽略该signal

### 8.1 signal Function
```c
typedef void Sigfunc(int); // a function with an integer argument

/**
 * @brief Change the action taken by a process on 
 *        receipt of a specific signal
 * @param signo: specify the signal except SIGKILL 
 *        and SIGSTOP
 * @param func: A new action for signal signo
 * @return The previous action is return on success;
 *         SIG_ERR on error
 */
Sigfunc* signal(int signo, Sigfunc* func)
{
  struct sigaction act, oact;

  act.sa_handler = func;
  sigemptyset(&act.sa_mask); /* 不阻塞其他signal */
  act.sa_flags = 0;

  if (signo == SIGALRM) /* SIGALRM通常表示I/O操作设置超时, 需要特殊处理 */
#ifdef	SA_INTERRUPT
    act.sa_flags |= SA_INTERRUPT; /* SunOS 4.x */
#endif
  else
#ifdef SA_RESTART
    act.sa_flags |= SA_RESTART; /* SVR4, 44BSD */
#endif

  if (sigaction(signo, &act, &oact) < 0)
    return(SIG_ERR);
  return(oact.sa_handler);
}

Sigfunc* Signal(int signo, Sigfunc *func)
{
  Sigfunc	*sigfunc;

  if ((sigfunc = signal(signo, func)) == SIG_ERR)
    err_sys("signal error");
  return(sigfunc);
}
```

### 8.2 POSIX Signal Semantics
POSIX的系统信号处理总结为以下几点:
1. 一旦设置了signal handler, 该signal handler会一直存在(旧版UNIX系统执行完毕后会移除signal handler)
2. 为保证一些关键代码不被signal handler中断, 需阻塞signal. `sigaction.sa_mask`指定哪些signal会被阻塞, 将`sa_mask`置为NULL表示: 除当前signal外, 不会阻塞其他signal.
3. 若多个signal被阻塞, 当进程解除阻塞时, 只会提交一个signal. 默认情况下UNIX的signal依照时序排队, 但POSIX real-time standard定义了某些signal会依照时序进入队列.
4. `sigpromask()`可阻塞或解除阻塞指定的signal集合, 这使得开发者可以保证某段代码不被signal打断.


## 9. Handle SIGCHLD Signals
Kernel将进程设置为zombie状态是为了保留子进程的信息, 让其父进程可以稍后获取这些信息, 其中包括: PID, termination status和子进程的资源利用率(CPU time, memory等). 如果父进程未处理其子进程的zombie状态且终止运行, 其所有子进程的PPID(parent PID)将置为1(init进程), 并负责清理这些zombies.

### 9.1 Handle Zombies
若不及时处理这些zombie, 会占用大量kernel空间. 当调用`fork()`产生子进程后, 应调用`wait()`防止子进程变为zombie. 因此, 可为`SIGCHLD` signal创建一个signal handler, 在handler中调用`wait()`:
```c
Signal(SIGCHLD, sig_chld);

void sig_chld(int signo)
{
  pid_t pid;
  int   stat;

  pid = wait(&stat);

  // Not recommand to call I/O functions in signal handler
  printf("child %d terminated\n", pid);
  return;
}
```
注意, 必须在调用`fork()`之前调用`Signal (SIGCHLD, sig_chld);`. 加入signal handler后的运行结果如下:
```sh
$ tcpserv02 &
[2] 16939

$ tcpcli01 127.0.0.1
hi there
hi there
^D
child 16942 terminated
accept error: Interrupted system call
```
具体步骤:
1. client端输入EOF, client向server子进程发送FIN, server子进程回复ACK
2. server子进程终止运行
3. 被`accept()`阻塞的server父进程被SIGCHLD signal打断, 并开始执行signal handler, 调用`printf()`输出子进程PID
4. 由于server父进程的`accept()`被打断, 返回EINTR

部分操作系统会自动重启被signal打断的system call, 因此`accept()`不会报错, 例如4.4BSD. 

### 9.2 Handle Interrupted System Calls
当slow system call被阻塞时, 指代那些可能永远处于阻塞状态的system call, 绝大多数network function都属于slow system call. 例如`accept()`, 假如没有client发起连接请求, 则`accept()`将一直处于阻塞状态; server的`read()`也是同理, 假如没有client发送数据, 则`read()`将一直被阻塞.
当slow system call被阻塞时, 若其被signal打断, 则slow system call会将errno设置为EINTER. 不同UNIX系统对signal的中断有不同的处理方法, 即使在`sigaction struct`的flag标记为`SA_RESTART`, 也不能保证被中断的system call自动重启. 因此需要对这些可能被signal打断的slow system call进行额外处理:
```c
for ( ; ; ) {
  clilen = sizeof(cliaddr);
  if ((connfd = accept(listenfd, (SA*)&cliaddr, &clilen)) <0) {
    if (errno == EINTER) /* back to for() */
      continue;
    else
      err_sys("accept error");
  }
}
```
对于上述代码来说: 若系统不支持自动重启被打断的`accept()`, 则再次进入for循环; 否则for循环中的`accept()`自动重启, 不会再次进入循环.


## 10. wait and waitpid Functions
`wait()`用于处理中止的子进程.
```c
#include <sys/wait.h>

/**
 * @brief Wait for child process to change state
 * @param staloc: A pointer to the termination status
 * @return the PID of child process
 */
pid_t wait(int *staloc);

/**
 * @brief Wait for the terminated child process
 * @param pid: specify the PID of child process
 * @param staloc: same as wait()
 * @param options: specify additional options. The most
 *        common option is WNOHANG to tell kernel not 
 *        to block if there are no terminated children
 */
pid_t waitpid(pid_t pid, int *staloc, int options);
```
函数`wait()`和`waitpid()`均返回两个值: 子进程的PID和中止状态. 如果当前没有已中止的子进程, 那么`wait()`会一直阻塞直到有子进程终止. `waitpid()`可以指定某个进程的ID并指定附加选项, 最常用的option就是`WNOHANG`, 表示在没有终止子进程时不要阻塞.

### 10.1 Difference between wait and waitpid
为展示`wait()`与`waitpid()`的不同, 需要对client端代码进行修改, 让client端与server建立5个连接:
```c
int main(int argc, char **argv)
{
  int i, sockfd[5];
  struct sockaddr_in servaddr;

  if (argc != 2)
    err_quit("usage: tcpcli <IPaddress>");

  for (i = 0; i < 5; i++) {
    sockfd[i] = Socket(AF_INET, SOCK_STREAM, 0);

    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(SERV_PORT);
    Inet_pton(AF_INET, argv[1], &servaddr.sin_addr);

    Connect(sockfd[i], (SA *) &servaddr, sizeof(servaddr));
  }

  str_cli(stdin, sockfd[0]);  /* only the first connection send the data */

  exit(0); /* Close five connections at the same time */
}
```
当client调用`exit(0)`时, 会向各自server发送FIN, server父进程同时收到5个`SIGCHLD` signal, 如下图:
![Client terminates, closing all five connections, terminating all five children](/images/Network/UNP/5-10-cli-close-all-conn.gif)

以下是运行结果:
```sh
$ tcpserv03 &
[1] 20419
$ tcpcli04 127.0.0.1
hello
hello
^D
child 20426 terminated
```
只有第一个子进程的`SIGCHLD` signal被捕获, 其他4个子进程变成zombies:
```sh
PID    TTY    TIME      COM
20419  pts/6  00:00:00  tcpserv03
20421  pts/6  00:00:00  tcpserv03 <defanct>
20422  pts/6  00:00:00  tcpserv03 <defanct>
20423  pts/6  00:00:00  tcpserv03 <defanct>
```
可以得知, `wait()`并不足以防止zombie出现. 因为相同类型的signal不会进入队列等待: 当第二个`SIGCHLD`到达时, 发现第一个`SIGCHLD`占用signal handler, 因而被阻塞; 但当第三个`SIGCHLD`到达时, 发现第一个`SIGCHLD`依然占用signal handler, 将会丢弃该signal. 由于不同signal handler的处理时长不同, 生成多个同类型signal时, 可能出现不同数量的zombie. 解决方法是在signal handler中使用`while`循环, 不断查询是否出现中止的child process:
```c
void sig_chld(int signo)
{
  pid_t pid;
  int   stat;
  
  while ((pid = waitpid(-1, &stat, WNOHANG)) > 0)
    printf("child %d terminated\n", pid);
  return;
}
```
`waitpid()`可通过`WNOHANG`保证没有子进程中止时立即返回, `wait()`则无法设置为非阻塞模式.

### 10.2 Correct version of TCP server
以下是能够正确处理`accept()`发出的`EINTR`和防止zombie出现的server端:
```c
int main(int argc, char **argv)
{
  int                listenfd, connfd;
  pid_t              childpid;
  socklen_t          clilen;
  struct sockaddr_in cliaddr, servaddr;
  void               sig_chld(int);

  listenfd = Socket(AF_INET, SOCK_STREAM, 0);

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);

  Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));
  Listen(listenfd, LISTENQ);
  Signal(SIGCHLD, sig_chld);

  for ( ; ; ) {
    clilen = sizeof(cliaddr);
    if ( (connfd = accept(listenfd, (SA *) &cliaddr, &clilen)) < 0) {
      if (errno == EINTR)
        continue;
      else
        err_sys("accept error");
    }

    if ( (childpid = Fork()) == 0) { /* child process */
      Close(listenfd); /* close listen socket */
      str_echo(connfd);
      exit(0);
    }
    Close(connfd);
  }
}
```


## 11. Connection Abort before accept Returns
还有另外一种打断slow system call的情况: 在client和server完成TCP 3-way handshake后, client发送RST, 而此时连接仍在队列中等待server调用`accept()`接收. 
![Receiving an RST for an ESTABLISHED connection before accept is called](/images/Network/UNP/5-11-recv-rst-before-accept.gif)

不同的系统对此有不同的处理:
1. Berkeley-derived会自动将该completed connection从队列中移除
2. POSIX会将errno设为`ECONNABORTED`
3. SVR4 implementation会将errno设为`EPROTO`


## 12. Termination of Server Process
为模拟server崩溃的情况, 需要先让client和server建立连接, 然后kill掉server的子进程, 以下是操作步骤:
1. 依次启动server和client, 让client发送一行文本来测试连接是否成功
2. 找到server子进程的PID并调用**kill**杀死. server子进程被终止后, 其所有open descriptor也会被关闭, 其connected socket会向client发送FIN, client回应ACK
3. server父进程接收到`SIGCHLD` signal并读取termination status
4. client的`fgets()`被阻塞, 会一直等待用户在command-line输入文本
5. `netstat`的执行结果如下:
  ```sh
  $ netstat -a | grep 9877
  Proto Recv-Q Send-Q  Local Address      Foreign Address  State
  tcp   0      0       *:9877             *:*              LISTEN
  tcp   0      0       localhost:9877     localhost:43604  FIN_WAIT2
  tcp   1      0       localhost:*:43604  localhost:9877   CLOSE_WAIT
  ```
  可以看出, TCP 4-way handshake termination已经进行了一半.
6. 继续在client端输入文本, 结果如下:
  ```sh
  $ tcpcli01 127.0.0.1
  hello
  hello

  // here we kill the server child process

  another line
  str_cli: server terminated prematurely
  ```
  当输入`another line`时, `str_cli()`仍会调用调用`writen()`, 因为虽然client接收到FIN, 但并不意味着server已经停止.
7. 由于server子进程已经关闭, 所以没有相对应的进程回应, kernel自动回复RST.
8. client收到FIN, `readline()`返回0. 因此server传来的RST并没有收到, client中止运行并关闭所有file descriptor.

若收到RST后调用`readline()`, 则返回`ECONNRESET`. 本例的问题在于: 当client收到FIN时, client正在被`fgets()`阻塞. client端有两个file descriptor: 与server相连的socket和user input. 当前`str_cli()`中只能在同一时间阻塞其中一个file descriptor, 可使用`select`或`poll`实现任意file descriptor的阻塞.


## 13. SIGPIPE Signal
若client忽略`readline()`的错误并继续向server传递数据, 则client进程会收到`SIGPIPE` signal, 该signal默认中止进程, 但进程可捕获该signal, 为其设置signal handler或忽略. 若进程继续调用`write()`传送数据, 则`write()`返回`EPIPE`:
```c
void str_cli(FILE *fp, int sockfd)
{
  char sendline[MAXLINE], recvline[MAXLINE];

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    Writen(sockfd, sendline, 1);
    sleep(1);
    Writen(sockfd, sendline+1, strlen(sendline)-1);

    if (Readline(sockfd, recvline, MAXLINE) == 0)
      err_quit("str_cli: server terminated prematurely");

    Fputs(recvline, stdout);
  }
}
```
注意: 由于第一次`writen()`只会收到RST; 只有第二次调用`writen()`才能收到`SIGPIPE` signal. 所以上述代码将`writen()`拆成两次运行, 以下是运行结果:
```sh
$ tcpcli11 127.0.0.1
hi, there
hi, there

// here we kill server child process

bye
Broken pipe
```
可以看出, 第二次调用`writen()`会直接触发`SIGPIPE` signal, 进程被终止运行. 可以根据应用所处的情况, 为`SIGPIPE` signal设置signal handler. 若程序中有多个socket使用`writen()`, signal handler无法告知是哪个`writen()`引起的`SIGPIPE` signal, 只能通过`writen()`的返回值是否为`EPIPE`判断.


## 14. Crash of Server Host
为测试server host崩溃的情况, 必须将client与server分别运行在不同的host上. 先启动server, 再启动client, 在client中输入一行文字确保connection已经建立. 之后断开server的网络连接, 再在client端输入一段文字, 步骤如下:
1. 这里假设不是shut down, 而是crash, 所以server端不会有任何信息发送给client.
2. 当在client端输入文本后, 会调用`writen()`发送给server, 紧接着被`readline()`阻塞.
3. 由于TCP要求发送的每一个报文都必须有ACK确认, 所以client会不断重发数据, 而不同系统的重传机制不同. 当client最终放弃重传后, client进程会收到一个错误. 由于client阻塞于`readline()`, 所以`readline()`会返回`ETIMEDOUT`. 如果某个中间路由器发现server不可达, 则会回复client一个名为"destination unreachable"的ICMP报文, client返回`EHOSTUNREACH`或`ENETUNREACH`

倘若不想依赖于系统的重传机制, 可在`readline()`中设置倒计时来判断对端是否unreachable. 本例中只能通过向server发送数据才可得知server host crash, 也可通过设置`SO_KEEPALIVE`来获知对端是否crash.


## 15. Crash and Reboot of Server Host
为模拟server崩溃后重启的情况, 需要先建立server与client的连接, server断开网络并重启程序, 最后接入网络, 步骤如下:
1. 启动server和client, client端输入数据来确保连接成功
2. server crashes and reboots
3. client端输入数据, 并传给server
4. 由于server重启后丢失所有连接信息, 所以并不识别client的数据, 回复RST
5. client收到RST后, `readline()`返回`ECONNRESET`


## 16. Shutdown of Server Host
当server host关机时, init进程会向所有正在运行的进程发送`SIGTERM`, 等待一定时间(一般为5-20秒)后再发出`SIGKILL`, 这给予进程一个安全结束的时间. 若server不设置signal handler捕获`SIGTERM`, 则server最后会被`SIGKILL`强制终止, 所有open file descriptor都会被关闭, 这就与**Termination of Server Process**情况相同.


## 17. Summary of TCP Example
无论是client还是server, 连接前需配置以下属性: 
* local IP address
* local port
* foreign IP address
* foreign port

1. 从client的角度:
Foreign IP和foreign port作为`connect()`的参数; 而local IP address和local port可由`connect()`自动选择, 也可调用`bind()`指定local IP address和local port:
![Summary of TCP client/server from client's perspective](/images/Network/UNP/5-17-tcp-from-cli.gif)

2. 从server的角度:
server通过调用`bind()`设置local IP address和local port. 若`bind()`中使用0作为local port或使用通配符作为local IP address, 则需要调用`getsockname()`获取local IP address或local port. foreign IP address和foreign port需要调用`accept()`获取, 也可通过`getpeername()`获取.
![Summary of TCP client/server from server's perspective](/images/Network/UNP/5-17-tcp-from-svr.gif)


## 18. Data Format
上述例子中server不会检查数据格式, 只会读入一行数据. 在实际项目中必须关注数据交换的格式

### 18.1 Pass Text Strings between Client and Server
本例server既然从client获取一行数据, 但数据必须包含两个整数, 并以空格分割:
```c
#include "unp.h"

void str_echo(int sockfd)
{
  long    arg1, arg2;
  ssize_t n;
  char    line[MAXLINE];

  for ( ; ; ) {
    if ( (n = Readline(sockfd, line, MAXLINE)) == 0)
      return; /* 对端关闭连接 */

    if (sscanf(line, "%ld%ld", &arg1, &arg2) == 2) /* 从字符串中提取整数 */
      snprintf(line, sizeof(line), "%ld\n", arg1 + arg2);
    else
      snprintf(line, sizeof(line), "input error\n"); /* 将结果转化为字符串 */

    n = strlen(line);
    Writen(sockfd, line, n);
  }
}
```

### 18.2  Pass Binary Structures between Client and Server
现在将client和server修改为传递二进制值, 下面是client端的`str_cli()`
```c
struct args {
  long arg1;
  long arg2;
};

struct result {
  long sum;
};

void str_cli(FILE *fp, int sockfd)
{
  char          sendline[MAXLINE];
  struct args   args;
  struct result result;

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    if (sscanf(sendline, "%ld%ld", &args.arg1, &args.arg2) != 2) {
      printf("invalid input: %s", sendline);
      continue;
    }
    Writen(sockfd, &args, sizeof(args));

    if (Readn(sockfd, &result, sizeof(result)) == 0)
      err_quit("str_cli: server terminated prematurely");

    printf("%ld\n", result.sum);
  }
}

void str_echo(int sockfd)
{
  ssize_t       n;
  struct args   args;
  struct result result;

  for ( ; ; ) {
    if ((n = Readn(sockfd, &args, sizeof(args))) == 0)
      return; /* connection closed by other end */

    result.sum = args.arg1 + args.arg2;
    Writen(sockfd, &result, sizeof(result));
  }
}
```

1. 测试1: 在两个SPARC主机上运行client和server
```sh
$ tcpcli09 12.106.32.254
11 22
33          // correct
-11 -44	
-55         // correct
```
2. 测试2: 在两个不同的主机上运行client和server(例如: client在big-endian order的SPARC上运行, server在little-endian order的linux上运行)
```sh
$ tcpcli09 206.168.112.96
1 2         
3           // correct
-22 -77
-16777314   // wrong
```

上述例子存在三个问题:
1. 不同系统以不同的格式存储二进制数, 例如: little-endian和big-endian
2. 不同系统对于相同的数据类型有不同的解释, 例如32位UNIX的**long**使用32bits, 64位UNIX的**long**使用64bits
3. 不同系统pack structure的方式不同

两种通用的解决方法:
1. 将numeric data转换为text string传递
2. 显式定义所支持的数据类型的binary formats, 例如: number of bits, big or little-endian
