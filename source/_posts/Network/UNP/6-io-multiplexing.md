---
title: I/O Multiplexing
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: e03d
date: 2019-12-04 14:15:55
keywords:
description:
---

## 1. Introduction
TCP中常常要面对这样一个问题: 多个file或socket需要同时处理. 例如: TCP client需从standard input中获取用户输入, 并读取来自socket的数据, 这种同时应对多个I/O conditions的能力称为**I/O multiplexing**(I/O多路复用). 
I/O multiplexing主要用于network application的以下场景:
* client处理多个descriptor
* 处理多个socket
* TCP server处理listening socket和其connected socket
* server同时处理TCP和UDP
* server同时处理多个protocols

## 2. I/O Models
以下是UNIX中的5种**I/O Model**:
* blocking I/O
* nonblocking I/O
* I/O multiplexing (select and poll)
* signal driven I/O (SIGIO)
* asynchronous I/O (the POSIX `aio_` functions)

无论是哪种I/O model, 所有读取操作都可拆分为以下步骤:
1. 等待数据就绪(network application中为等待数据到达socket)
2. 将数据从kernel复制到process中

### 2.1 Blocking I/O Model
Blocking I/O model是最常见的I/O model, 实现方式最简单. 以datagram socket为例, 读取操作的流程如下:
![Blocking I/O model](/images/Network/UNP/6-2-blocking-io-model.gif)

上述例子中, 调用`recvfrom()`会等待数据到达socket, 并主动将数据从kernel复制到process. 进程必须等待`recvfrom()`完成, 或被signal打断.

### 2.2 Nonblocking I/O Model
Nonblocking I/O model不阻塞进程, 进程立即获得结果. 以下是读取操作的流程:
![Nonblocking I/O model](/images/Network/UNP/6-2-nonblocking-io-model.gif)

前三次调用`recvfrom()`时, 由于socket未收到数据, kernel返回`EWOULDBLOCK`; 第四次调用`recvfrom()`, 其会将数据从kernel复制到process中. Nonblocking I/O model永不挂起的特性使得程序必须使用loop不断调用`recvfrom()`, 称为**polling**, 虽然不会长时间挂起, 但浪费CPU时间.

### 2.3 I/O Multiplexing Model
I/O Multiplexing model中, 进程使用`select`或`poll`阻塞多个system call. 以下是读取操作的流程:
![I/O multiplexing model](/images/Network/UNP/6-2-io-multiplexing-model.gif)

上述例子使用`select()`监听多个sockets, 一旦socket处于readable状态, 则通知进程并调用`recvfrom()`, 将数据从kernel复制到process中. 虽然`select()`阻塞进程, 但`select()`能够同时监听多个socket, multithreading blocking I/O可实现相同效果, 但更消耗资源.

### 2.4 Signal-Driven I/O Model
Signal-driven I/O model通过`SIGIO` signal提醒进程file descriptor已准备就绪. 以下是读取操作的流程:
![Signal-Driven I/O model](/images/Network/UNP/6-2-signal-driven-io-model.gif)

首先调用`sigaction()`设置一个signal handler, 该操作不会阻塞进程; socket收到数据时, 进程会收到`SIGIO`, 调用signal handler中的`recvfrom()`, 其将数据从kernel复制到process. 该model的优点在于不用阻塞进程, 但需设置signal handler.

### 2.5 Asynchronous I/O Model
POSIX.1定义了该I/O model: asynchronous function通知kernel开始读取操作, 操作完毕后, kernel通知function. 与signal-driven I/O model不同的是: asynchronous I/O会完成所有任务(等待数据, 将数据从kernel复制到process); signal-driven I/O则需手动读取数据.
![Asynchronous I/O model](/images/Network/UNP/6-2-asyn-io-model.gif)

POSIX.1的所有asynchronous I/O function以`aio_`或`lio_`开头, 且不会阻塞进程, 结束时用signal通知进程. 

### 2.6 Comparison of the I/O Models
以下是5种I/O models的读取操作对比:
![Comparison of the five I/O models](/images/Network/UNP/6-2-io-models.gif)


## 3. select Function
进程调用`select()`可通知kernel等待一个或多个事件发生, 当其中一个或多个事件发生时, 进程会被唤醒. `select()`可监听file descriptor的三种事件: 
* read
* write
* exception

```c
#include <sys/select.h>
#include <sys/time.h>

struct timeval {
  long tv_sec;  /* seconds */
  long tv_usec; /* microseconds */
};

void FD_CLR(int fd, fd_set *set);   /* remove a file descriptor from the set */
int  FD_ISSET(int fd, fd_set *set); /* test to see if a file descriptor is part of the set */
void FD_SET(int fd, fd_set *set);   /* add a file descriptor to the set */
void FD_ZERO(fd_set *set);          /* clear a set */

/**
 * @brief allow a program to monitor multiple file 
 *        descriptors waiting until one or more of 
 *        the file descriptors become "ready" for 
 *        I/O operation
 * @param nfds: the highest-numbered file descriptor
 * @param timeout: specify the interval that select()
 *        should block waiting for a file descriptor 
 *        to become ready
 * @return return the number of file descriptors 
 *         contained in the three returned descriptor
 *         sets; Or return -1 on error
 */
int select(int nfds, fd_set *readfds, fd_set *writefds,
           fd_set *exceptfds, struct timeval *timeout);
```

以下是`select()`的三种等待情况:
* 无限等待: 若`timeout`为NULL, 除非某个file descriptor处于ready状态, 否则`select()`会一直等待
* 最多等待一定时间: 若`timeout`指定的`timeval` struct不为0, 即便没有file descriptor处于ready状态, `select()`也会返回
* 不等待: 若`timeout`指定的`timeval` struct为0, `select()`立刻返回, 称为`polling`

若进程捕获到signal并从signal handler返回, 则自动打断`select()`并设置相应`errno`. `select()`中的`readfds`, `writefds`和`exceptfds`分别监听read, write和exception事件, 其中exception包含以下情况:
* socket收到out-of-band data
* packet mode下pseudo-terminal master收到control status information

`select()`通过`fd_set`设置或清除某个file descriptor的监听, 每个file descriptor占`fd_set`的一个bit; 当某个file descriptor被添加到`readfds`和`writefds`时, 表示同时监听该file descriptor的read和write事件. 以下是socket处于**ready**状态的几种情况:
1. socket处于readable状态:
    1. socket receive buffer中的字节数大于或等于low-water mark. Send buffer的low-water mark可通过SO_RCVLOWAT socket option设置, 默认为1.
    2. socket收到FIN后(TCP connection), `read()`不会阻塞, 返回0
    3. 当socket调用`listen()`变为passive listening socket, 且有一个或多个connection时, `accept()`不会阻塞
    4. 存在socket error时, `read()`不会阻塞, 返回-1
2. socket处于writable状态:
    1. socket send buffer中空闲空间大于或等于low-water mark, 且满足以下其中一个条件:
       * socket已连接
       * socket不需要连接(如: UDP)

        Receive buffer的low-water mark可通过`SO_SNDLOWAT` socket option设置, 默认为2048.
    2. socket已关闭连接, 调用`write()`会产生`SIGPIPE` signal
    3. socket调用non-blocking connect建立连接
    4. 存在socket error时, `write()`不会阻塞, 返回-1
3. socket处于exception状态: socket接收到out-of-band data

以下是socket状态的总结:

| Condition | Readable | Writable | Exception |
|:---------:|:--------:|:--------:|:---------:|
| Data to read                              | &#x2714; |  |  |
| Read half of the connection closed        | &#x2714; |  |  |
| New connection ready for listening socket | &#x2714; |  |  |
| Space available for writing               |  | &#x2714; |  |
| Write half of the connection closed       |  | &#x2714; |  |
| Pending error                             | &#x2714; | &#x2714; | &#x2714; |
| TCP out-of-band data                      |  |  | &#x2714; |


## 4. str_cli Function (Revisited)
以下是使用`select()`重写后的TCP client:
```c
void str_cli(FILE *fp, int sockfd)
{
  int     maxfdp1;
  fd_set  rset;
  char    sendline[MAXLINE], recvline[MAXLINE];

  FD_ZERO(&rset); /* initialize fd_set */
  for ( ; ; ) {
    FD_SET(fileno(fp), &rset);
    FD_SET(sockfd, &rset);
    maxfdp1 = max(fileno(fp), sockfd) + 1;
    Select(maxfdp1, &rset, NULL, NULL, NULL);

    if (FD_ISSET(sockfd, &rset)) {  /* socket is readable */
      if (Readline(sockfd, recvline, MAXLINE) == 0)
        err_quit("str_cli: server terminated prematurely");
      Fputs(recvline, stdout);
    }

    if (FD_ISSET(fileno(fp), &rset)) {  /* input is readable */
      if (Fgets(sendline, MAXLINE, fp) == NULL)
        return; /* all done */
      Writen(sockfd, sendline, strlen(sendline));
    }
  }
}
```
TCP client中要监听socket descriptor和stdin是否处于readable, 以下是socket处于readable状态的三种情况:
1. 对端TCP socket发送数据, `read()`返回值大于0
2. 对端TCP socket发送FIN, `read()`返回0
3. 对端TCP socket发送RST, `read()`返回-1


## 5. Batch Input and Buffering
使用`select()`后, TCP client端就从stop-and-wait mode变为batch mode(批量模式). 之前server和client每次通信需要1个RTT时间, 但batch mode下数据以最快速度传输, 如下图:
![Time line of stop-and-wait mode: interactive input](/images/Network/UNP/6-5-stop-and-wait-mode.gif)

但batch mode存在一些问题:
1. 向stdio输入EOF时, 会导致connection完全关闭, 从而导致request还没发出, 或丢失还没接收的数据. 解决方案: 使用`shutdown()`向server发送FIN, 关闭one-half of the TCP connection, 这样可让client端的socket继续接收数据
2. buffering虽然提高network application的性能, 但增加了复杂度. 若stdio buffer中存在多行数据, `select()`只会被唤醒一次, 并调用`fgets()`从stdio中读取一行数据, 剩下的数据依然留在stdio buffer中.
3. `readline()`也存在buffer的问题: 由于`readline()`有自己的buffer, 所以需修改其实现.


## 6. shutdown Function
正常情况下, network application会调用`close()`来关闭connection, 但`close()`存在以下两个缺陷:
1. `close()`只会减少descriptor的reference count, 只有reference count降为0时, descriptor才会被关闭; `shutdown()`则直接开始TCP connection termination.
2. `close()`会停止双向数据传输(read和write). 当socket发送完数据后仍需接收数据, 则不能调用`close()`关闭connection

```c
#include <sys/socket.h>

/**
 * @brief Cause all or part of a full-duplex connection on the 
 * socket associated with the file descriptor socket to be shut down
 * @param how: shall be one of the following values:
 * 1. SHUT_RD: disable further receive operations
 * 2. SHUT_WR: disable further send operations
 * 3. SHUT_RDWR: disable further send and receive operations
 */
int shutdown(int socket, int how);
```


## 7. str_cli Function (Revisited Again)
使用`shutdown()`改写后的`str_cli()`如下:
```c
void str_cli(FILE *fp, int sockfd)
{
  int     maxfdp1, stdineof = 0;
  fd_set  rset;
  char    sendline[MAXLINE], recvline[MAXLINE];

  heartbeat_cli(sockfd, 1, 5);

  FD_ZERO(&rset);
  for ( ; ; ) {
    if (stdineof == 0)
      FD_SET(fileno(fp), &rset);
    FD_SET(sockfd, &rset);
    maxfdp1 = max(fileno(fp), sockfd) + 1;
    if (select(maxfdp1, &rset, NULL, NULL, NULL) < 0) {
      if (errno == EINTR)
        continue;
      else
        err_sys("select error");
    }

    if (FD_ISSET(sockfd, &rset)) {  /* socket is readable */
      if (Readline(sockfd, recvline, MAXLINE) == 0) {
        if (stdineof == 1)
          return;  /* normal termination */
        else
          err_quit("str_cli: server terminated prematurely");
      }

      Writen(STDOUT_FILENO, recvline, strlen(recvline));
    }

    if (FD_ISSET(fileno(fp), &rset)) {  /* input is readable */
      if (Fgets(sendline, MAXLINE, fp) == NULL) {
        stdineof = 1;
        alarm(0);  /* turn of heartbeat */
        Shutdown(sockfd, SHUT_WR);  /* send FIN */
        FD_CLR(fileno(fp), &rset);
        continue;
      }

      Writen(sockfd, sendline, strlen(sendline));
    }
  }
}
```


## 8. TCP Echo Server (Revisited)
TCP server也可用`select()`改写, 来替代client connection线程. 由于server端不需要监听写入操作, 所以只需要维护一个read descriptor set. 其中, 前三个file descriptors为stdio, stdout, stderr, 第四个file descriptor为listening descriptor; 剩下的descriptor为connected socket descriptor. 例如: `client`数组存储connected socket descriptor, `rset`维护read descriptor set, 如下图:
![Data structures for TCP server with just a listening socket](/images/Network/UNP/6-8-data-struct-tcp-svr-listen-sock.gif)

`client`数组中, **-1**表示不可用file descriptor; rset中, **0**表示不监听该file descriptor, **1**表示监听该file descriptor. 当client1与server建立连接后, server会将该connected descriptor添加到`client`和`rset`中, 如下图:
![Data structures after first client connection is established](/images/Network/UNP/6-8-data-struct-first-cli-conn.jpg)

一段时间后, client2与server建立连接, 情况如下:
![Data structures after second client connection is established](/images/Network/UNP/6-8-data-struct-second-cli-conn.jpg)

client1与server断开连接, `client[0]`置为-1, rset中`descriptor 4`置为0, 如下图:
![Data structures after first client terminates its connection](/images/Network/UNP/6-8-data-struct-first-cli-terminate.gif)

使用`select()`的TCP server端代码如下:
```c
int main(int argc, char **argv)
{
  int       i, maxi, maxfd, listenfd, connfd, sockfd;
  int       nready, client[FD_SETSIZE];
  ssize_t   n;
  fd_set    rset, allset;
  char      buf[MAXLINE];
  socklen_t clilen;
  struct sockaddr_in cliaddr, servaddr;

  listenfd = Socket(AF_INET, SOCK_STREAM, 0);

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);

  Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));

  Listen(listenfd, LISTENQ);

  maxfd = listenfd;  /* initialize */
  maxi = -1;  /* index into client[] array */
  for (i = 0; i < FD_SETSIZE; i++)
    client[i] = -1;  /* -1 indicates available entry */
  FD_ZERO(&allset);
  FD_SET(listenfd, &allset);

  for ( ; ; ) {
    rset = allset;  /* structure assignment */
    nready = Select(maxfd+1, &rset, NULL, NULL, NULL);

    if (FD_ISSET(listenfd, &rset)) {  /* new client connection */
      clilen = sizeof(cliaddr);
      connfd = Accept(listenfd, (SA *) &cliaddr, &clilen);

      /* use the first unused entry for the connected socket */
      for (i = 0; i < FD_SETSIZE; i++)
        if (client[i] < 0) {
          client[i] = connfd;  /* save descriptor */
          break;
        }

      if (i == FD_SETSIZE) err_quit("too many clients");

      FD_SET(connfd, &allset);  /* add new descriptor to set */
      if (connfd > maxfd) maxfd = connfd;  /* for select */
      if (i > maxi) maxi = i;  /* max index in client[] array */

      /* no more readable descriptors */
      if (--nready <= 0) continue;
    }

    for (i = 0; i <= maxi; i++) {  /* check all clients for data */
      if ((sockfd = client[i]) < 0) continue;
      if (FD_ISSET(sockfd, &rset)) {
        if ((n = Read(sockfd, buf, MAXLINE)) == 0) {
          Close(sockfd);
          FD_CLR(sockfd, &allset);
          client[i] = -1;
        } else {
          Writen(sockfd, buf, n);
        }
        /* no more readable descriptors */
        if (--nready <= 0) break;
      }
    }
  }
}
```



## 9. pselect Function
POSIX.1引入了`pselect()`, 并在很多UNIX系统中使用.
```c
#include <sys/select.h>
#include <sys/time.h>
#include <sys/types.h>

/**
 * @brrief Same as select()
 */
int pselect(int nfds, fd_set *readfds, fd_set *writefds,
            fd_set *exceptfds, const struct timespec *timeout,
            const sigset_t *sigmask);
```
虽然`pselect()`功能上与`select()`相同, 但存在以下几点不同:
1. `select()`使用**struct timeval**(仅支持microseconds)作为timeout类型; `pselect()`则使用**struct timespec**(支持nanoseconds)
2. `select()`没有sigmask参数, `pselect()`则支持屏蔽特定signal

需要注意:
```c
ready = pselect(nfds, &readfds, &writefds, &exceptfds, timeout, &sigmask);
```
相当于原子性地执行以下代码:
```c
sigset_t origmask;
sigprocmask(SIG_SETMASK, &sigmask, &origmask);
ready = select(nfds, &readfds, &writefds, &exceptfds, timeout);
sigprocmask(SIG_SETMASK, &origmask, NULL);
```
可以看出, `pselect()`的sigmask只用于运行时, 调用结束后会恢复原本的signal mask; `select()`不会修改signal mask. 这导致一个问题: 假设某个signal已经被block, 但又需要`select()`运行时捕获该signal, 则需要调用`sigprocmask()`解除signal的block, 并在`select()`运行结束后调用`sigprocmask()`恢复对该signal的block. 因而产生了两个race condition: 
* 解除阻塞signal后, 调用`select()`前signal到达, 导致signal丢失
* `select()`调用后, 重新阻塞signal前signal到达, 导致signal丢失

因此引入`pselect()`解决该问题.


## 10. poll Function
```c
#include <poll.h>

struct pollfd {
  int   fd;       /* file descriptor */
  short events;   /* requested events */
  short revents;  /* returned events */
};

/**
 * @brief Same as select(), wait for one of a set of file 
 *        descriptors to become ready to perform I/O
 * @param fds: the set of file descriptors
 * @param nfds: the number of items in the fds
 * @param timeout: the minimum number of milliseconds that 
 *        polls() will block
 * @return a positive number for the number of ready descriptor; 
 *         0 for the timeout and no file descriptor are ready; 
 *         -1 for error and errno is set
 */
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
```
`pollfd struct`不仅包含file descriptor, 还包含可监听事件(events)与已发生事件(revents). 以下是事件(event)分类:

| Constant | events | revents | Description |
|:--------:|:------:|:-------:|:-----------:|
| POLLIN   |&#x2714;|&#x2714; | Normal or priority band data can be read |
|POLLRDNORM|&#x2714;|&#x2714; | Normal data can be read |
|POLLRDBAND|&#x2714;|&#x2714; | Priority band data can be read |
| POLLPRI  |&#x2714;|&#x2714; | High-priority data cab be read |
| POLLOUT  |&#x2714;|&#x2714; | Normal data can be writen |
|POLLWRNORM|&#x2714;|&#x2714; | Normal data can be writen |
|POLLWRBAND|&#x2714;|&#x2714; | Priority band data can be writen |
| POLLERR  |        |&#x2714; | Error has occurred |
| POLLHUP  |        |&#x2714; | Hangup has occurred |
| POLLNVAL |        |&#x2714; | Descriptor is not an open file |

`poll()`将所有数据分为三种: normal, priority band, 和high-priority. 对于TCP或UDP数据, POSIX.1的`poll()`将其分类如下:
* 所有TCP和UDP数据都为normal
* TCP的out-of-band data为priority band
* TCP connection被中断(例如, 收到FIN)也是normal
* TCP connection发生的error(例如, 收到RST或超时)可被当做normal, 也可被当做POLLERR
* listening socket收到新的connection时, 可被当做normal或priority band
* nonblocking connect的执行完毕会让socket处于可写状态

`timeout`参数表示`poll()`在返回前等待多长时间:

| timeout value | Description |
|:-------------:|:-----------:|
| INFTIM        | Wait forever |
| 0             | Return immediately, do not block |
| > 0           | Wait specified number of milliseconds |



## 11. TCP Echo Server (Revisited Again)
以下为`poll()`替代`select()`后的TCP server:
```c
int main(int argc, char **argv)
{
  int     i, maxi, listenfd, connfd, sockfd;
  int     nready;
  ssize_t n;
  char	  buf[MAXLINE];
  socklen_t clilen;
  struct pollfd client[OPEN_MAX];
  struct sockaddr_in cliaddr, servaddr;

  listenfd = Socket(AF_INET, SOCK_STREAM, 0);

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);

  Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));
  Listen(listenfd, LISTENQ);

  client[0].fd = listenfd;
  client[0].events = POLLRDNORM;
  for (i = 1; i < OPEN_MAX; i++)
    client[i].fd = -1;  /* -1 indicates available entry */
  maxi = 0;  /* max index into client[] array */

  for ( ; ; ) {
    nready = Poll(client, maxi+1, INFTIM);

    /* new client connection */
    if (client[0].revents & POLLRDNORM) {
      clilen = sizeof(cliaddr);
      connfd = Accept(listenfd, (SA *) &cliaddr, &clilen);

      /* find an entry for the new descriptor */
      for (i = 1; i < OPEN_MAX; i++)
        if (client[i].fd < 0) {
          client[i].fd = connfd;
          break;
        }

      if (i == OPEN_MAX) err_quit("too many clients");

      client[i].events = POLLRDNORM;

      if (i > maxi) maxi = i;  /* update max index */

      /* no more readable descriptors */
      if (--nready <= 0) continue;
    }

    /* check all clients for data */
    for (i = 1; i <= maxi; i++) {
      if ((sockfd = client[i].fd) < 0) continue;

      if (client[i].revents & (POLLRDNORM | POLLERR)) {
        if ((n = read(sockfd, buf, MAXLINE)) < 0) {
          if (errno == ECONNRESET) {  /* connection reset by client */
            Close(sockfd);
            client[i].fd = -1;
          } else
            err_sys("read error");
        } else if (n == 0) {  /* connection closed by client */
          Close(sockfd);
          client[i].fd = -1;
        } else
          Writen(sockfd, buf, n);

        /* no more readable descriptors */
        if (--nready <= 0) break;
      }
    }
  }
}
```
