---
title: Advanced I/O Functions
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: e76b
date: 2020-01-03 12:33:40
keywords:
description:
---

## 1. Introduction
本章主要包含以下几种I/O operations:
* 三种方法实现带倒计时的I/O operations
* `read()`和`write()`的替代: `recv()`和`send()`, `readv()`和`writev()`, `recvmsg()`和`sendmsg()`
* 如何判断socket receive buffer中的数据量
* 如何使用C standard I/O library操作socket


## 2. Socket Timeouts
以下是三种实现带倒计时功能I/O operations的方法:
1. 调用`alarm()`, 倒计时结束后向进程发送SIGALRM signal
2. 使用`select()`自带的计时器
3. 使用`SO_RCVTIMEO`和`SO_SNDTIMEO` socket option, 但不是所有系统都支持这两个socket options

上述三种方法可用于input和ouput操作, 但如果想为`connect()`设置倒计时, 则不能使用socket option; 对于`select()`中自带的倒计时, 必须将socket切换为nonblocking mode. 

### 2.1 connect with a Timeout Using SIGALRM
```c
static void connect_alarm(int signo)
{
  return; /* just interrupt the connect() */
}

int connect_timeo(int sockfd, const SA *saptr, socklen_t salen, 
                  int nsec)
{
  Sigfunc *sigfunc;
  int n;

  // establish a signal handler for SIGALRM
  sigfunc = Signal(SIGALRM, connect_alarm);
  if (alarm(nsec) != 0) // alarm clock for timeout
    err_msg("connect_timeo: alarm was already set");

  if ( (n = connect(sockfd, saptr, salen)) < 0) {
    close(sockfd); // prevent the incoming three-way handshake
    if (errno == EINTR) // interrupted by signal handler
      errno = ETIMEDOUT;
  }
  alarm(0); // turn off the alarm
  Signal(SIGALRM, sigfunc); // restore previous signal handler

  return(n);
}
```
上述方法存在三个问题:
1. 使用`alarm()`可以减少`connect()`的等待时间, 但不能延长等待时间. 以Berkeley-derived kernel为例, 其`connect()`默认等待时间为75秒, 假设`alarm()`设置为80秒, 则`connect()`在等待75秒后自动返回.
2. `alarm()`利用system call的可打断性, 实现`connect()`函数提前返回. 但某些library默认忽略接收到的`EINTER` signal, 导致`alarm()`无法打断system call.
3. 对于多线程项目, `alarm()`发出的`SIGALRM` signal会被进程的某个线程接收, 因此该方法只适合单线程项目.

### 2.2 recvfrom with a Timeout Using SIGALRM
```c
static void sig_alrm(int signo)
{
  return; /* just interrupt the recvfrom() */
}

void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, 
            socklen_t servlen)
{
  int n;
  char sendline[MAXLINE], recvline[MAXLINE + 1];

  // establish a signal handler for SIGALRM
  Signal(SIGALRM, sig_alrm);

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    Sendto(sockfd, sendline, strlen(sendline), 0, pservaddr, servlen);

    alarm(5); // alarm clock for five-second timeout

    if ((n = recvfrom(sockfd, recvline, MAXLINE, 0, NULL, NULL)) < 0) {
      if (errno == EINTR) // interrupted by signal handler
        fprintf(stderr, "socket timeout\n");
      else
        err_sys("recvfrom error");
    } else {
      alarm(0);
      recvline[n] = 0;  /* null terminate */
      Fputs(recvline, stdout);
    }
  }
}
```

### 2.3 recvfrom with a Timeout Using select
```c
int readable_timeo(int fd, int sec)
{
  fd_set rset;
  struct timeval tv;

  FD_ZERO(&rset);
  FD_SET(fd, &rset); // turn on the read descriptor

  tv.tv_sec = sec;
  tv.tv_usec = 0;

  // wait for the descriptor to become readable
  // return -1 if error occurs; 0 if timeout occurs; positive 
  // value specifying the number of ready descriptors
  return(select(fd+1, &rset, NULL, NULL, &tv));
}

void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, 
            socklen_t servlen)
{
  int n;
  char sendline[MAXLINE], recvline[MAXLINE + 1];

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    Sendto(sockfd, sendline, strlen(sendline), 0, pservaddr, servlen);

    n = readable_timeo(sockfd, 5);
    if (n < 0) {
      err_sys("readable_timeo error");
    }
    else if (n == 0) { // interrupted by select timeout
      fprintf(stderr, "socket timeout\n");
    } else {
      n = recvfrom(sockfd, recvline, MAXLINE, 0, NULL, NULL);
      recvline[n] = 0; /* null terminate */
      Fputs(recvline, stdout);
    }
  }
}
```

### 2.4 recvfrom with a Timeout Using the SO_RCVTIMEO Socket Option
```c
void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, 
            socklen_t servlen)
{
  int n;
  char sendline[MAXLINE], recvline[MAXLINE + 1];
  struct timeval tv;

  tv.tv_sec = 5;
  tv.tv_usec = 0;
  Setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    Sendto(sockfd, sendline, strlen(sendline), 0, pservaddr, servlen);

    n = recvfrom(sockfd, recvline, MAXLINE, 0, NULL, NULL);
    if (n < 0) {
      // interrupted by SO_RCVTIMEO socket option
      if (errno == EWOULDBLOCK) {
        fprintf(stderr, "socket timeout\n");
        continue;
      } else
        err_sys("recvfrom error");
    }

    recvline[n] = 0; // null terminate
    Fputs(recvline, stdout);
  }
}
```


## 3. recv and send Functions
```c
#include <sys/socket.h>

/**
 * @brief receive messages from a socket
 */
ssize_t recv(int sockfd, void *buff, size_t nbytes, int flags);

/**
 * @brief send a message on a socket
 */
ssize_t send(int sockfd, const void *buff, size_t nbytes, int flags);
```
相比于`read()`和`write()`, `recv()`和`send()`多了一个参数: `flags`. 通过flags, 可更改input和output operation的行为.

| flags | recv | send | Description |
|:-----:|:-----:|:-----:|:-----:|
| MSG_DONTROUTE |   | ✓ | Bypass routing table lookup |
| MSG_DONTWAIT  | ✓ | ✓ | Only this operation is nonblocking |
| MSG_OOB       | ✓ | ✓ | Send or receive out-of-band data |
| MSG_PEEK      | ✓ |   | Peek at incoming message |
| MSG_WAITALL   | ✓ |   | Wait for all the data |

* MSG_DONTROUTE: 若destination address为本地网络, 可使用该flag通知kernel无需进行routing table查询. 也可使用`SO_DONTROUTE` socket option让socket发出的所有datagram都通过routing table查询.
* MSG_DONTWAIT: 让单次I/O operation变为nonblocking. 与`fcntl()`的`O_NONBLOCK`功能相同, 但MSG_DONTWAIT只会影响单次I/O operation; O_NONBLOCK则永久改为nonblocking.
* MSG_OOB: 若`send()`使用该flag, 可将数据作为out-of-band data发送; 若`recv()`使用该flag, 会读取out-of-band data.
* MSG_PEEK: 只能被`recv()`使用, 用于查看socket receive buffer中的数据, 但不将数据从buffer中删除
* MSG_WAITALL: 只能被`recv()`使用. 只有buffer中数据大于或等于`nbytes`时才返回. 但以下三种特殊情况会让`recv()`立即返回: 
    * `recv()`被signal打断
    * 连接中断
    * 出现错误

`recv()`和`send()`存在一个缺陷: `flags`参数只能由进程传递给kernel, 而kernel无法传递给进程任何信息. 对于TCP/IP, 这并不算缺陷; 但对于OSI Protocol, 则需要从kernel中获取信息.


## 4. readv and writev Functions
`readv()`和`writev()`解决了读取或写入多个buffer的问题, 其中`readv()`称为**scatter read**(数据被读取到多个buffer中), `writev()`被称为**gather write**(一次output operation发送多个buffer数据).
```c
#include <sys/uio.h>

struct iovec {
  void *iov_base; /* starting address of buffer */
  size_t iov_len; /* size of buffer */
};

/**
 * @brief read iovcnt buffers from the file associated
 *        with the file descriptor `fd` into the buffers
 *        described by `iov`
 * @param iov: an array of iovec structure
 * @return number of bytes read on success; -1 on error
 *         and errno is set
 */
ssize_t readv(int fd, const struct iovec *iov, int iovcnt);

/**
 * @brief write iovcnt buffers of data described by 
 *        `iov` to the file associated with the file
 *        descriptor `fd`
 */
ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
```
`readv()`和`writev()`都是atomic operations, `writev()`会将所有iov数据作为一个UDP datagram发送. POSIX规定`IOV_MAX`常量为`iovcnt`的上限值, 不同UNIX系统拥有不同的`IOV_MAX`值.


## 5. recvmsg and sendmsg Functions
```c
#include <sys/socket.h>

/* specified in POSIX */
struct msghdr {
  void         *msg_name;      /* protocol address */
  socklen_t    msg_namelen;    /* size of protocol address */
  struct iovec *msg_iov;       /* scatter/gather array */
  int          msg_iovlen;     /* # elements in msg_iov */
  void         *msg_control;   /* ancillary data (cmsghdr struct) */
  socklen_t    msg_controllen; /* length of ancillary data */
  int          msg_flags;      /* flags returned by recvmsg() */
};

/**
 * @brief receive message from a socket
 */
ssize_t recvmsg(int sockfd, struct msghdr *msg, int flags);

/**
 * @brief transmit a message to another socket
 */
ssize_t sendmsg(int sockfd, struct msghdr *msg, int flags);
```
补充:
1. `msg_name`和`msg_namelen`用于无需建立连接的socket, 如UDP socket. `recvmsg()`中的`msg_name`表示sender's source address, `sendmsg()`中`msg_name`表示receiver's destination address. 对于TCP socket或connected UDP socket, `sendmsg()`可将`msg_name`置为NULL. 
2. `msg_iov`和`msg_iovlen`表示input/output buffer及大小. 其中, `msg_iov`为一个iovec struct组成的链表, `msg_iovlen`表示链表的长度.
3. `msg_control`和`msg_controllen`表示optional ancillary data的位置和长度

`recvmsg()`和`sendmsg()`包含两类flags:
1. msg_flags: 只用于`recvmsg()`, kernel会通过`msg_flags`将flag值传递给进程; 会被`sendmsg()`忽略
2. flags: 进程传递给kernel的参数, 用于修改input和output的行为

![Summary of input and output flags by various I/O functions](/images/Network/UNP/14-5-flag-of-io-func.gif)

以下是`recvmsg()`可收到的6种`msg_flags`:
* MSG_BCAST: 当datagram为link-layer broadcast或destination IP address为broadcast address时, 返回该flag
* MSG_MCAST: 当datagram为link-layer multicast时, 返回该flag
* MSG_TRUNC: 当进程的buffer(所有iovec空间)不足以接收所有data时, 返回该flag
* MSG_CTRUNC: 当进程的buffer(msg_controllen)不足以接收所有ancillary data, 返回该flag
* MSG_EOR: 当`send()`未设置MSG_EOR时, `recvmsg()`不返回该flag; 当`send()`设置MSG_EOR时, `recvmsg()`返回该flag
* MSG_OOB: 对于TCP out-iof-band data, 该flag不会返回; 其他protocol suites会返回该flag

假设UDP socket调用`recvmsg()`前, msghdr structure如下:
![Data structures when recvmsg is called for a UDP socket](/images/Network/UNP/14-5-recvmsg-udp-sock.gif)

其中:
* protcol address: 16 bytes
* ancillary data: 20 bytes
* iovec 1: 100 bytes
* iovec 2: 60 bytes
* iovec 3: 80 bytes
* UDP socket设置IP_RECVDSTADDR socket option用于获取UDP datagram的destination IP address

假设收到来自`192.6.38.100`, port为2000的70-bytes UDP datagram, 其destination IP address为`206.168.112.96`, 则`recvmsg()`返回的msghdr structure如下:
![Update of msghdr structure when recvmsg returns](/images/Network/UNP/14-5-msghdr-recvmsg-return.gif)

以下是`recvmsg()`调用前后的变化:
* 向`msg_name`所指向的buffer添加一个internet socket address structure, 其中包括source IP address和source UDP port
* `msg_namelen`用于表示`msg_name`的长度, 为16 bytes
* 前100 bytes存放在第一个iovec 1中, 接下来的60 bytes存放在iovec 2中, 最后的10 bytes存放在iovec 3中. `recvmsg()`返回170, 表示接收到的所有字节数
* `msg_control`指向cmsghdr structure, 其中`cmsg_len`为16, `cmsg_level`为IPPROTO_IP, `cmsg_type`为IP_RECVDSTADDR, 接下来4-bytes用于存放destination IP address
* `msg_controllen`表示ancilly data, 更新为16 bytes
* 由于无flag返回, 所有`msg_flags`无变化

以下是不同I/O functions的对比:
![Comparison of the five groups of I/O functions](/images/Network/UNP/14-5-group-of-io-func.gif)


## 6. Ancillary Data
`sendmsg()`和`recvmsg()`可通过`msg_control`和`msg_controllen`传递和接收ancillary data. Ancillary data也称为**control information**, 以下是总结:
![Summary of uses for ancillary data](/images/Network/UNP/14-6-use-of-ancillary-data.gif)

一个Ancillary data可包含多个ancillary data objects, 每个object都以cmsghdr struct开头, 如下:
```c
struct cmsghdr {
  socklen_t cmsg_len;   /* length in bytes, including this structure */
  int       cmsg_level; /* originating protocol */
  int       cmsg_type;  /* protocol-specific type */
 /* followed by unsigned char cmsg_data[] */
};
```

假设control buffer中有两个ancillary data object, `msg_control`指向第一个ancillary data object, `msg_controllen`表示ancillary data的总长度. 每个ancillary data object指向一个cmsghdr structure, `cmsg_type`和`data`之间会存在padding, 可使用`CMSG_xxx` macro可获取所有padding:
![Ancillary data containing two ancillary data objects](/images/Network/UNP/14-6-data-object-in-ancillary-data.gif)

以下是用于简化ancillary data的marcos:
```c
#include <sys/socket.h>
#include <sys/param.h>

/* @brief return a pointer to the first cmsghdr in the ancillary
 *        data buffer associated with mhdrptr 
 */
struct cmsghdr *CMSG_FIRSTHDR(struct msghdr *mhdrptr);

/**
 * @brief return the next valid cmsghdr after the passed cmsgptr
 */
struct cmsghdr *CMSG_NXTHDR(struct msghdr *mhdrptr, struct
                            cmsghdr *cmsgptr);

/**
 * @brief return a pointer to the data portion of a cmsghdr
 */
unsigned char *CMSG_DATA(struct cmsghdr *cmsgptr);

/**
 * @brief return the value to store in cmsg_len given the amount 
 *        of data
 */
unsigned int CMSG_LEN(unsigned int length);

/**
 * @brief return the total sizeof an ancillary data object given 
 *        the amount of data
 */
unsigned int CMSG_SPACE(unsigned int length);
```


## 7. How Much Data Is Queued?
有时进程需在不读取数据的情况下, 知道多少数据阻塞在socket buffer:
1. 若buffer没有可读数据, 且进程不想被kernel阻塞, 可使用nonblocking I/O
2. 若进程想要读取数据, 又不想让数据从buffer中移除, 可使用`MSG_PEEK` flag; 若不确定是否有数据, 可使用nonblocking I/O和`MSG_DONTWAIT` flag. 对于TCP socket, 两次`recv()`可能获得长度不同的数据, 因为可能有数据在中途接收; 但对于UDP socket, 两次`recv()`获取的结果相同, 即使中途接收到新的数据. 
3. 部分UNIX系统支持`ioctl()`中使用`FIONREAD`, 该参数会返回socket receive buffer的字节数. Berkeley-derived系统返回的字节数还包括sender IP address和port number (IPv4 16-bytes, IPv6 24-bytes)


## 8. Sockets and Standard I/O
`read()`和`write()`等I/O functions都属于UNIX I/O. 这些函数直接作用于file descritpor, 并作为system call由UNIX kernel实现. 除此之外还可使用standard I/O, 该library可用于非UNIX系统, 支持ANSI C. 除了兼容性, standard I/O还为input/output stream提供**buffering**, 可提高input/output operation效率. 但伴随着stream buffering, 使用standard I/O需注意以下问题:
* `fdopen()`可将任何file descriptor变为standard I/O stream, 也可通过`fileno()`获取对应的file descriptor. 
* TCP/UDP socket为full-duplex. 当使用`r+`模式打开stream时, 该stream也是full-duplex(可读可写). 但对于full-duplex stream, 若调用output function后调用input function, 两个操作之间需调用`fflush()`, `fseek()`, `fsetpos()`, 或`rewind()`; 若input function后调用output function, 除非input function读取到EOF, 否则需调用`fseek()`, `fsetpos()`, 或`rewind()`. 
* full-duplex stream最简单的使用方式: 为一个file descriptor创造两个stream, 一个用于读取, 一个用于写入

以下是使用standard I/O替代UNIX I/O后的`str_echo()`:
```c
void str_echo(int sockfd)
{
  char line[MAXLINE];
  FILE *fpin, *fpout;

  fpin = Fdopen(sockfd, "r"); // one for input
  fpout = Fdopen(sockfd, "w"); // one for output

  while (Fgets(line, MAXLINE, fpin) != NULL)
    Fputs(line, fpout);
}
```
运行client和server后, 结果如下:
```sh
% tcpcli02 206.168.112.96
hello, world          // nothing is echoed
and hi                // still no echo
hello??               // still no echo
^D
hello, world          // three echoed lines are output
and hi
hello??
```
以下是client/server的整个流程:
* 用户在client输入第一行并传输至server
* server调用`fgets()`获取数据, 并由`fputs()`输出给fpout stream
* 由于standard I/O stream为fully buffered, 当buffer没有装满时, stream会将数据保存在buffer中, 而不是将数据写入descriptor
* 用户在client输入第二行并传输至server
* server调用`fgets()`, `fputs()`后, 由于buffer依然没有装满, 因此无输出
* 用户在client输入第三行, 情况如上
* 用户在client输入EOF, `str_cli()`调用`shutdown()`并向server发送FIN
* server的`fgets()`收到FIN, 并返回null
* `str_echo()`返回, child process调用`exit()`完成终止
* `exit()`调用cleanup function, 输出buffer的所有数据到fpout
* server的fpout将数据传递给client, client的`str_cli(`)输出数据
* server的child process结束终止, 向client发送FIN完成TCP four-way termination
* client的`str_cli()`接收到EOF并返回

以下是standard I/O Library的三种buffering类型:
1. Fully buffered: 只有buffer没有剩余空间, 进程调用`exit()`, 或进程调用`fflush()`时, 才发生I/O operation
2. Line buffered: 只有输入newline, 进程调用`fflush()`, 或进程调用`exit()`时, 才发生I/O operation
3. Unbuffered: 每当调用standard I/O output function时都发生I/O operation

对于大部分UNIX系统, standard I/O library遵循以下规则:
* Standard error采用**unbuffered**
* terminal dervice采用**line buffered**
* 除去terminal dervice, 其他stream都采用**fully buffered**

由于socket不是terminal device, 所以`str_echo()`中的stream采用fully buffered. 可调用`setvbuf()`将stream变为line buffered, 也可在每次调用`fputs()`后调用`fflush()`. 但无论怎么解决, 都可能导致socket出错, 且与**Nagle algorithm**冲突. 最好的解决方法就是避免在socket programming中使用standard I/O library.


## 9. Advanced Polling
虽然大多数系统支持`select()`和`poll()`, 但这两个函数都未被收录在POSIX中, 且每个系统对于`select()`和`poll()`的实现各不相同, 导致兼容性问题. 以下是替代方案:

### 9.1 /dev/poll Interface
Solaris提供了一个特殊文件: `/dev/poll`, 该文件提供了一种可扩展的方式来轮询多个file descriptor. 对于`select()`和`poll()`, 每次循环都需要将file descriptor再添加一遍, poll device则不需要.
打开`/dev/poll`后, polling program会初始化一个**pollfd** structure. 该array会被kernel调用`write()`写入/dev/poll, 然后调用`ioctl()`, DO_POLL来等待事件, 以下是`ioctl()`传入的structure:
```c
struct dvpoll {
  struct pollfd* dp_fds; /* point to a buffer used to hold an array of pollfd */
  int dp_nfds;           /* the size of buffer */
  int dp_timeout;        /* timeout in milliseconds */
}
```

以下是`/dev/poll`的例子:
```c
void str_cli(FILE *fp, int sockfd)
{
  int stdineof;
  char buf[MAXLINE];
  int n;
  int wfd;
  struct pollfd	pollfd[2];
  struct dvpoll	dopoll;
  int i;
  int result;

  wfd = Open("/dev/poll", O_RDWR, 0);
  
  // fill in an array of pollfd structure
  pollfd[0].fd = fileno(fp);
  pollfd[0].events = POLLIN;
  pollfd[0].revents = 0;

  pollfd[1].fd = sockfd;
  pollfd[1].events = POLLIN;
  pollfd[1].revents = 0;

  Write(wfd, pollfd, sizeof(struct pollfd) * 2);

  stdineof = 0;
  for ( ; ; ) {
    /* block until /dev/poll detects file descriptor is ready */
    dopoll.dp_timeout = -1;
    dopoll.dp_nfds = 2;
    dopoll.dp_fds = pollfd;
    result = Ioctl(wfd, DP_POLL, &dopoll);

    /* loop through ready file descriptors */
    for (i = 0; i < result; i++) {
      if (dopoll.dp_fds[i].fd == sockfd) {
        /* socket is readable */
        if ( (n = Read(sockfd, buf, MAXLINE)) == 0) {
          if (stdineof == 1)
            return; /* normal termination */
          else
            err_quit("str_cli: server terminated prematurely");
        }
        Write(fileno(stdout), buf, n);
      } else {
        /* input is readable */
        if ( (n = Read(fileno(fp), buf, MAXLINE)) == 0) {
          stdineof = 1;
          Shutdown(sockfd, SHUT_WR); /* send FIN */
          continue;
        }
        Writen(sockfd, buf, n);
      }
    }
  }
}
```

### 9.2 kqueue Interface
FreeBSD 4.1引入**kqueue** interface, 让进程可以注册一个event filter, 其中event包括file I/O, asychronous I/O, file modification notification, process tracking, 和signal handling.
```c
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

struct kevent {
  uintptr_t ident; /* identifier (e.g., file descriptor) */
  short filter;    /* filter type (e.g., EVFILT_READ) */
  u_short flags;   /* action flags (e.g., EV_ADD) */
  u_int fflags;    /* filter-specific flags */
  intptr_t data;   /* filter-specific data */
  void *udata;     /* opaque user data */
};

/**
 * @brief return a new kqueue descriptor which can
 *        be used with kevent()
 */
int kqueue(void);

/**
 * @brief register events with the queue, and return
 *        any pending events to the user
 * @param changelist a pointer to an array of kevent
 *        structures of all changes
 * @param nchanges the size of changelist
 * @param eventlist a pointer to an array of kevent
 *        structures
 * @param nevents the size of eventlist
 * @param timeout a timespec structure of timeout
 */
int kevent(int kq, const struct kevent *changelist, 
      int nchanges, struct kevent *eventlist, int nevents,
      const struct timespec *timeout);

/**
 * @brief initialize a kevent structure
 */
void EV_SET(struct kevent *kev, uintptr_t ident, 
      short filter, u_short flags, u_int fflags,
      intptr_t data, void *udata);
```
以下是kevent的所有flags:
![flags for kevent operations](/images/Network/UNP/14-9-kevent-flag.gif)

以下是kevent的所有filters:
![filters for kevent operations](/images/Network/UNP/14-9-kevent-filter.gif)

以下是kqueue的例子:
```c
void str_cli(FILE *fp, int sockfd)
{
  int kq, i, n, nev, stdineof = 0, isfile;
  char buf[MAXLINE];
  struct kevent kev[2];
  struct timespec ts;
  struct stat st;

  /* determine if it is a file or other descriptor */
  isfile = ((fstat(fileno(fp), &st) == 0) &&
        (st.st_mode & S_IFMT) == S_IFREG);

  /* set up two kevent structures */
  EV_SET(&kev[0], fileno(fp), EVFILT_READ, EV_ADD, 0, 0, NULL);
  EV_SET(&kev[1], sockfd, EVFILT_READ, EV_ADD, 0, 0, NULL);

  kq = Kqueue(); /* get a kqueue descriptor */

  /* set the timeout ot zero to allow a nonblocking call to kevent */ 
  ts.tv_sec = ts.tv_nsec = 0; 
  Kevent(kq, kev, 2, NULL, 0, &ts); 

  for ( ; ; ) {
    nev = Kevent(kq, NULL, 0, kev, 2, NULL);

    for (i = 0; i < nev; i++) {
      if (kev[i].ident == sockfd) { /* socket is readable */
        if ( (n = Read(sockfd, buf, MAXLINE)) == 0) {
          if (stdineof == 1)
            return; /* normal termination */
          else
            err_quit("str_cli: server terminated prematurely");
        }

        Write(fileno(stdout), buf, n);
      }

      if (kev[i].ident == fileno(fp)) { /* input is readable */
        n = Read(fileno(fp), buf, MAXLINE);
        if (n > 0)
          Writen(sockfd, buf, n);

        if (n == 0 || (isfile && n == kev[i].data)) {
          stdineof = 1;
          Shutdown(sockfd, SHUT_WR); /* send FIN */
          kev[i].flags = EV_DELETE;
          Kevent(kq, &kev[i], 1, NULL, 0, &ts); /* remove kevent */
          continue;
        }
      }
    }
  }
}
```
