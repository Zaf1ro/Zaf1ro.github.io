---
title: Elementary TCP Sockets
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: d1c8
date: 2019-11-19 20:42:05
---

## 1. Introduction
UNIX可以让一个server同时与多个client建立连接并通信. 本章会调用让server调用`fork()`, 为每个client创建一个进程. 通常情况下, TCP server会先启动, 之后client启动并试图连接server. Server处理完毕请求后回复client, 直到client关闭本次连接. 整个流程如下图:
![Socket functions for elementary TCP client/server](/images/Network/UNP/4-1-sock-func-for-tcp-cli-svr.gif)

## 2. socket Function
想要进行network I/O操作, 必须先执行`socket()`创建一个socket对象.
```c
#include <sys/socket.h>

/**
 * @brief create an endpoint for communication and returns a 
 *        file descriptor of that endpoint
 * @param family: the protocol family
 * @param type: the communication semantics
 * @param protocl: a particular protocol to be used with the 
 *        socket
 * @return a file descriptor on success; -1 on error and errno
 *         is set.
 */
int socket(int family, int type, int protocol)
```
`socket()`参数所能使用的常量:
* family:
  * AF_INET: IPv4 protocols
  * AF_INET6: IPv6 protocols 
  * AF_LOCAL: UNIX domain protocols
  * AF_ROUTE: Routing socket
  * AF_KEY: Key socket
* type:
 * SOCK_STREAM: stream socket
 * SOCK_DRGAM: datagram socket
 * SOCK_SEQPACKET: sequenced packet socket
 * SOCK_RAW: raw socket
* protocol
 * IPPROTO_TCP: TCP transport protocol
 * IPPROTO_UDP: UDP transport protocol
 * IPPROTO_SCTP: SCTP transport protocol

以下是family和type的可用组合:

|                | AF_INET | AF_INET6 | AF_LOCAL | AF_ROUTE | AF_KEY |
|:--------------:|:-------:|:--------:|:--------:|:--------:|:------:|
| SOCK_STREAM    | TCP,SCTP| TCP,SCTP | Yes      |          |        |
| SOCK_DGRAM     | UDP     | UDP      | Yes      |          |        |
| SOCK_SEQPACKET | SCTP    | SCTP     | Yes      |          |        |
| SOCK_RAW       | IPv4    | IPv6     |          | Yes      | Yes    |

Protocol family分为两种: `AF_xxx`和`PF_xxx`. `AF_`代表address family, `PF_`表示protocol family. 原本计划设计一个支持多个address family的protocol family, `PF_`用于创建socket, `AF_`用于socket address structure中; 但实际上并没有实现, `<sys/socket.h>`中`PF_`与`AF_`值相同, 因此本例使用`AF_`作为family参数.


## 3. connect Function
`connect()`可用于TCP client向TCP server发起连接:
```c
#include <sys/socket.h>

/**
 * @brief connect the socket referred to by the file descriptor
 *        sockfd to the address specified by addr
 * @param sockfd: socket descriptor
 * @param addr: a pointer to a socket address structure
 * @param len: the size of addr 
 * @return 0 on success; -1 on error and errno is set
 */
int connect(int sockfd, const struct sockaddr* addr, socklen_t len);
```
addr指向的socket address structure必须含有server的IP address和port. Client调用`connect()`之前不需要调用`bind()`, 内核会自动为client分配一个临时端口. `connect()`会初始化TCP三次握手, 只有完成连接或出错后才会返回, 以下是几种错误的可能性:
1. Client发出SYN后无回复, 返回`ETIMEDOUT`.
2. Client发出SYN后, server回复RST, 表示server指定端口没有程序运行, client返回`ECONNREFUSED`.
3. client发出SYN后, 中间路由返回ICMP "destination unreachable". Client还会多次尝试发送SYN, 若仍没收到回复, 则返回`EHOSTUNREACH`或`ENETUNREACH`.

RST出现情况:
* 对端指定端口没有进程运行(三次握手中)
* 对端想取消已有连接(三次握手之后)
* 对端接收到一个根本不存在的segment

`connect()`会将socket状态从`CLOSED`切换到`SYN_SENT`, 如果成功建立连接则切换到`ESTABLISHED`, 若失败则该socket不可再用, 必须被关闭.


## 4. bind Function
`bind()`会为socket分配一个local protocol address(包括一个32-bit IPv4 address或128-bit IPv6 address和一个16bit TCP或UDP port number). 
```c
#include <sys/socket.h>

/**
 * @brief Assign the address specified by addr to the socket 
 * referred to by the file descriptor sockfd
 * @param sockfd: the file descriptor of socket
 * @param addr: a pointer to the socket address structure
 * @param len: the size of the socket address structure
 */
int bind(int sockfd, const struct sockaddr* addr, socklen_t len);
```
client不需调用`bind()`, 内核会自动分配一个临时port. server则需手动调用`bind()`, 因为server必须使用固定port来保持与client的连接.
bind可以指定IP address和port number, 也可以不指定:

| IP Address | Port    | Result |
|:----------:|:-------:|:----------:|
| 通配符      |    0    |	Kernel chooses IP address and port |
| 通配符      | nonzero | Kernel chooses IP address, specfies port |
| 本地IP地址  |    0    |	Kernel specifies IP address, chooses port |
| 本地IP地址  | nonzero | Kernel sepecifies IP address and port |

对于IPv4, 通配符为`INADDR_ANY`;, 通知内核来选择IP地址.
```c
struct sockaddr_in servaddr;
servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
```
对于IPv6, 通配符为`in6addr_any`:
```c
struct sockaddr_in6 serv;
serv.sin6_addr = in6addr_any;
```
`bind()`不会返回临时分配的port number, 需调用`getsockname()`来获取protocol address. `bind()`最常返回的错误为 `EADDRINUSE`, 表示address已被使用.



## 5. listen Function
`listen()`只会被TCP server调用.
1. 当socket被创建后会即可向外发送请求, `listen()`可将未建立连接的socket变为passive socket, 将socket状态从`CLOSED`切换为`LISTEN`.
2. `listen()`的`backlog`参数表示kernel为socket保留的最大连接数量

```c
#include <sys/socket.h>

/**
 * @brief mark the socket referred to by sockfd as a passive 
 *        socket
 * @param sockfd: a file descriptor refers to socket of 
 *        type SOCK_STREAM or SOCK_SEQPACKET
 * @param backlog: the maximum length to which the queue of 
 *        pending connections for sockfd
 */
int listen(int sockfd, int backlog);
```

Kernel为passoive socket维护了两个队列, 两个队列长度之和即为`backlog`:
* Incomplete connection queue: 收到SYN但还没完成YCP三次握手, socket位于`SYN_RCVD`状态
* Completed connection queue:	完成TCP三次握手, socket位于`ESTABLISHED`状态

以下是kernel维护的两个queue:
![The two queues maintained by TCP for a listening socket](/images/Network/UNP/4-5-two-queues-by-tcp.gif)

以下是TCP三次握手的流程:
![TCP three-way handshake and the two queues for a listening socket](/images/Network/UNP/4-5-handshake-and-two-queue-by-tcp.gif)

当server收到client的SYN时, 会将该请求加入到incompleted queue并回复ACK. 若ACK回复超时, 则将该请求从imcomplete queue中移除; 若收到client发来的SYN-ACK后, 将该请求从imcomplete queue移至completed queue尾部. 进程调用`accpet()`会从completed queue取出并处理首部第一个请求; 若completed queue为空, 则进程进入睡眠状态. 
backlog的数值一般为**5**, 但并不适用于现在网络, Berkeley-derived系统为`backlog`添加了模糊因子(乘以1.5). 不要将`backlog`定义为0. 因为各系统对于0都有不同的处理方式, 若不想接受任何请求, 直接关闭passive socket.
在不考虑报文丢失或重传的情况下, 连接请求在imcompleted queue停留的时间为1 RTT.
当queue已经占满时, TCP server会忽略client发送的SYN且不发送RST. 因为拥塞是暂时的, 且client会再次发送SYN来请求连接. 如果server回复RST, 则client所调用的`connect()`会报错; 而不回复RST可让client的`connect()`自动重发SYN.


## 6. accept Function
Server调用`accept()`从completed queue的首部取出一个请求. 若completed queue为空, 则进程进入睡眠.
```c
#include <sys/socket.h>

/**
 * @brief extract the first connection request on the queue
 *        of pending connections for the listening socket 
 *        sockfd, creates a new connected socket
 * @param sockfd: a socket which is listening for connection
 * @param addr: a pointer to a socket address structure
 * @param len: length of the structure pointed to by addr
 * @return A file descriptor for the accepted socket on success;
 *         -1 on error and errno is set
 */
int accept(int sockfd, struct sockaddr* addr, socklen_t* len);
```
`accpet()`成功调用后返回一个全新的file descriptor, 表示与client的TCP connection. 因此`accept()`实际上返回以下三个数据:
1. return value: 表示与client的TCP connection
2. 参数addr: 表示client的protocol address
3. 参数len: 表示参数addr的大小


## 7. fork and exec Functions
在创建concurrent server之前, 必须先学习`fork()`和`exec()`的使用

### 7.1 fork Function
```c
#include <unistd.h>

/**
 * @brief create a new process by duplicating the calling process
 * @return PID of child process is returned in the parent on 
 *         success; 0 is returned in the child; -1 is 
 *         returned on error
 */
pid_t fork(void);
```
`fork()`虽然只调用一次, 但会返回两个值. 因此调用`fork()`需使用**if**来判断当前进程为父进程还是子进程. 之所以子进程中的`fork()`不返回父进程PID, 是因为`getppid()`可获取当前进程的父进程PID; 但由于一个进程可拥有多个子进程, 因此父进程需通过`fork()`获取子进程的PID.
`fork()`可用于server的并发处理: server在成功调用`accept()`后调用`fork()`, 父进程和子进程会共享connected socket: 子进程负责读取和写入connected socket, 父进程负责关闭connected socket. 以下是`fork()`的两种用法:
1. 进程调用`fork()`复制自身, 并使用子进程完成其他任务, 如: network server
2. 进程调用`fork(),` 在子进程中调用`exec()`替代原本进程数据来执行其他任务, 如: shell执行程序


### 7.2 exec Function
exec有6种不同的函数表示, 区别如下:
1. 执行的程序目录: filename或pathname
2. 执行程序的参数: 可变参数或数组指针 
3. 执行程序的环境变量: 使用当前进程的环境变量或指定新的环境变量

```c
#include <unistd.h>
int execl(const char *pathname, const char *arg0, ... /* (char *)0 */);
int execv(const char *pathname, char *const argv[]);
int execle(const char *pathname, const char *arg0, ... /* (char *)0, char *const envp[] */);
int execve(const char *pathname, char *const argv[], char *const envp[]);
int execlp(const char *filename, const char *arg0, ... /* (char *)0 */);
int execvp(cosnt char *filename, char *const argv[]);
```
以下是6种exec函数的关系图:
![Relationship among the six exec functions](/images/Network/UNP/4-7-exe-func.gif)


## 8. Concurrent Servers
若sever需服务多个client, 最简单的方式就是让server为每个client调用`fork()`处理请求:
```c
pid_t pid;
int listenfd, connfd;

listenfd = Socket( ... );

/* fill in sockaddr_in{} with server's well-known port */
Bind(listenfd, ... );
Listen(listenfd, LISTENQ);

for ( ; ; ) {
  connfd = Accept (listenfd, ... ); /* probably blocks */
  if((pid = Fork()) == 0) {
    Close(listenfd); /* child closes listening socket */
    doit(connfd);    /* process the request */
    Close(connfd);   /* done with this client */
    exit(0);         /* child terminates */
  }
  Close(connfd); /* parent closes connected socket */
}
```
当`accept()`返回后, 说明server与client成功建立连接. 这时调用`fork()`让子进程与父进程共享connfd: 子进程负责与client的通信, 父进程负责等待新的连接.
对TCP connection调用`close()`会向client发送FIN终止连接, 上述代码中子进程父进程虽然分别调用`close()`, 但并不会发送两次FIN: 每个file或socket都有一个reference count, 当server调用`fork()`后, connfd的refernece count会从1变为2, 每次调用`close()`都会使该socket的reference count减1, 只有当reference count变为0时才会向client发送FIN. 因此只有最后一次调用`close()`才会发送FIN.
以下是client与server之间的连接状态流程:
1. server调用`accept()`之前:
![Status of client/server before call to accept returns](/images/Network/UNP/4-8-before-accept-return.gif)

2. server调用`accept()`后:
![Status of client/server after return from accept](/images/Network/UNP/4-8-after-accept-return.gif)

3. server调用`fork()`后:
![Status of client/server after fork returns](/images/Network/UNP/4-8-after-fork-return.gif)

4. 父进程调用`close(connfd)`, 子进程调用`close(listenfd)`后
![Status of client/server after parent and child close appropriate sockets](/images/Network/UNP/4-8-after-parent-child-close-sock.gif)


## 9. close Function
`close()`用于关闭socket并中止TCP连接.
```c
#include <unistd.h>

/**
 * @brief close a file descriptor
 * @param sockfd: A file descriptor for socket
 * @return 0 on success; -1 on error and errno is set
 */
int close(int sockfd);
```
调用`close()`后, server会继续将未发送完毕的数据发送给client, 之后再进行TCP four-packet connection termination. 如果需要强制关闭一段connection, 可调用`shutdown()`. 不调用`close()`也很危险, 每个系统的file descriptor都有数量上限, 不调用`close()`会导致connected socket用光所有file descriptor; 而且不调用`close()`会让TCP connection一直保持连接状态. 


## 10. getsockname and getpeername Functions
`getsockname()`和`getpeername()`用于获取socket的local protocol address和foreign protocol address.
```c
#include <sys/socket.h>

int getsockname(int sockfd, struct sockaddr* localaddr, socklen_t* addrlen);

int getpeername(int sockfd, struct sockaddr* peeraddr, socklen_t* addrlen);
```
以下是`getsockname()`和`getpeername()`的使用情景:
* client调用`connect()`后可通过`getsockname()`获取当前connection使用的local IP address和port number.
* server在调用`bind()`时使用0作为port number, 可调用`getsockname()`获取kernel自动分配的local port number.
* `getsockname()`也可用于获取address family:
```c
int sockfd_to_family(int sockfd)
{
  struct sockaddr_storage ss;
  socklen_t len;

  len = sizeof(ss);
  if (getsockname(sockfd, (SA *) &ss, &len) < 0)
    return(-1);
  return(ss.ss_family);
}
```
* server在调用`bind()`时将通配符作为IP address, 可调用getsockname()获取kernel自动分配的IP address
* server调用`accept()`后, 调用`fork()`复制自身并执行exec来运行其他程序, 这时只能通过调用`getpeername()`来获取client的protocol address, 因为exec会抹除子进程中的所有内存数据, 包括foreign protocol address. 如下图:
![Example of inetd spawning a server](/images/Network/UNP/4-10-inetd-spawn-server.gif)

  调用exec后, connfd会和peer's address一样被清除. 但调用`getpeername()`时又必须使用connfd. 因此在调用exec时可将connfd作为参数传入, 或者在调用exec之前为connfd创建一个descriptor.
