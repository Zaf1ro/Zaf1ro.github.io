---
title: Elementary UDP Sockets
abbrlink: 80a7
date: 2019-12-16 08:40:26
category:
  - Network
  - UNP
tag:
  - Network
keywords:
description:
---

## 1. Introduction
UDP作为一种无连接, 不可靠的datagram protocol, 与面向连接, 可靠的byte stream相比, 其network application实现上有很大不同. 在UDP client/server架构中, 由于client不需要建立连接, 可直接调用`sendto()`发送数据; server也不需要accept connection, 只需要调用`recvfrom()`接收数据即可, 如下图:
![Socket functions for UDP client/server](/images/Network/UNP/8-1-udp-sock-func.gif)


## 2. recvfrom and sendto Functions
```c
/**
 * @brief receive message from the socket sockfd
 * @param src_addr: if src_addr is not NULL, the underlying protocol 
 *        provides the source address; If src_addr is NULL, nothing 
 *        is filled in
 * @return the number of bytes received on success; -1 on error
 */
ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags,
                 struct sockaddr *src_addr, socklen_t *addrlen);

/**
 * @brief transit a message to another socket
 * @param dest_addr: if sendto() is used on a connection-oriented 
 *        socket, the dest_addr and addrlen is ignored. Otherwise, 
 *        the address of the target is given by dest_addr
 * @return the number of characters sent on success; -1 on error
 */
ssize_t sendto(int sockfd, const void *buf, size_t len, int flags,
               const struct sockaddr *dest_addr, socklen_t addrlen);
```
对于UDP server, 由于无需调用`accept()`, 所以只能通过`recvfrom()`中的`src_addr`参数得知client端IP address; 对于UDP client, 由于无需调用`connect()`, 所以需要在`sendto()`中通过`dest_addr`指明server端IP address.
UDP允许发送的datagram长度为0, 也可以接收datagram长度为0的packet. `recvfrom()`返回0并不意味着断开connection, 因为UDP不存在connection的概念.


## 3. UDP Echo Server
```c
int main(int argc, char **argv)
{
  int                sockfd;
  struct sockaddr_in servaddr, cliaddr;

  sockfd = Socket(AF_INET, SOCK_DGRAM, 0);

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);

  Bind(sockfd, (SA *) &servaddr, sizeof(servaddr));

  /* perform server processing */
  dg_echo(sockfd, (SA *) &cliaddr, sizeof(cliaddr));
}

void dg_echo(int sockfd, SA *pcliaddr, socklen_t clilen)
{
  int       n;
  socklen_t len;
  char      mesg[MAXLINE];

  for ( ; ; ) {
    len = clilen;
    n = Recvfrom(sockfd, mesg, MAXLINE, 0, pcliaddr, &len);

    Sendto(sockfd, mesg, n, 0, pcliaddr, len);
  }
}
```
上述UDP server十分简洁, 但这其中也存在问题:
1. 由于UDP是connectionless protocol, 所以不存在EOF, 导致UDP server无法终止
2. 该UDP server为iterative server, 不是concurrent server. 通常来说, TCO server为concurrent, UDP server为iterative
3. UDP socket读取数据时, 需要从receive buffer中读入到进程中, 遵循FIFO的顺序. 每个socket receive buffer都有上限值, 传入流量过大会导致数据丢失


## 4. UDP Echo Client
```c
int main(int argc, char **argv)
{
  int                sockfd;
  struct sockaddr_in servaddr;

  if (argc != 2)
    err_quit("usage: udpcli <IPaddress>");

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_port = htons(SERV_PORT);
  Inet_pton(AF_INET, argv[1], &servaddr.sin_addr);

  sockfd = Socket(AF_INET, SOCK_DGRAM, 0);
  
  /* perform client processing */
  dg_cli(stdin, sockfd, (SA *) &servaddr, sizeof(servaddr));

  exit(0);
}

void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, socklen_t servlen)
{
  int  n;
  char sendline[MAXLINE], recvline[MAXLINE + 1];

  /* Read a line from standard input */
  while (Fgets(sendline, MAXLINE, fp) != NULL) {

    /* send the line to the server */
    Sendto(sockfd, sendline, strlen(sendline), 0, pservaddr, servlen);

    /* read vacj the server's echo */
    n = Recvfrom(sockfd, recvline, MAXLINE, 0, NULL, NULL);

    recvline[n] = 0;  /* null terminate */
    Fputs(recvline, stdout); /* print the echoed line to standard output */
  }
}
```
UDP client调用`sendto()`时, kernel会自动分配一个临时port. 因此与TCP相同, UDP client不需要调用`bind()`. 若`recvfrom()`的`src_addr`和`addrlen`为NULL, 说明接收端并不需要知道对端的IP address. 


## 5. Lost Datagrams
上述UDP client/server并不可靠. 当client的datagram在传输过程中丢失后, client将被阻塞在`recvfrom()`; 当server回复的datagram在传输过程中丢失后, client也会被阻塞在`recvfrom()`. 其中一种解决方案: 为`recvfrom()`设置倒计时.
仅仅在`recvfrom()`中添加倒计时器还不足以解决问题, 因为当倒计时结束后, client无法分辨数据丢失是因为datagram没有传给server, 还是server端回复丢失. 


## 6. Verify Received Response
由于只要知道client的port number就可以向client发送数据, 因为client所接收的数据可能来自不同的server. 这时就需要从`recvfrom()`中获取对端IP address和port, 从而判断数据是否来自指定server. 以下是修改后的client端:
```c
void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, socklen_t servlen)
{
  int             n;
  char            sendline[MAXLINE], recvline[MAXLINE + 1];
  socklen_t       len;
  struct sockaddr *preply_addr;

  preply_addr = Malloc(servlen);

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    Sendto(sockfd, sendline, strlen(sendline), 0, pservaddr, servlen);

    len = servlen;
    n = Recvfrom(sockfd, recvline, MAXLINE, 0, preply_addr, &len);
    if (len != servlen || memcmp(pservaddr, preply_addr, len) != 0) {
      printf("reply from %s (ignored)\n",
          Sock_ntop(preply_addr, len));
      continue;
    }

    recvline[n] = 0;	/* null terminate */
    Fputs(recvline, stdout);
  }
}
```
但上述方法存在一个问题: 当server并没有绑定某个IP address时, kernel会为server选择一个IP address. 当server存在多个outgoing interfaces时, 也就拥有多个IP address of the interfaces. 当server使用nonprimary IP address时, 会导致发送的数据被client忽略.
其中一个解决方案为: client不对IP address进行甄别, 而通过domain name判断数据是否来自指定server, 这就需要DNS的帮助. 另一种方法为: server为每个IP address分配一个socket, 并各自调用`bind()`绑定一个IP address, 使用`select()`监听所有socket. 


## 7. Server Not Running
当server并未运行, 但client依然发送数据时, client会被一直阻塞在`recvfrom()`. 当client发送数据后, 会收到ICM port unreachable, 但该ICMP error不会被client process返回, 因此client会一直阻塞在`recvfrom()`.
上述ICMP error称为**asynchronous error**, 由`sendto()`产生. `sendto()`成功返回只说明socket send buffer有足够空间放置数据, 只有在UDP socket调用`connect()`建立连接后, asynchronous error才会返回到UDP socket. 
假设UDP client向三个不同的server发送数据, client使用loop调用`recvfrom()`来获取server回复; 前两个server成功回复client, 第三个主机上server没有运行, 回复ICMP port unreachable error message. 这时client需要知道datagram的destination IP address和destination UDP port, 但`recvfrom()`只返回errno, 只有UDP socket调用`connect()`绑定IP asynchronous error并获取额外信息. 对于Linux, 即使是unconnected socket, 也可以收到ICMP **destination unreachable** error, 前提是未设置**SO_BSDCOMPAT** socket option. 


## 8. Summary of UDP Example
![Summary of UDP client/server from client's perspective](/images/Network/UNP/8-8-udp-from-cli.gif)
client必须在`sendto()`中指定server的IP address和port number, 但一般不指定自己的IP address和port number, 会在client第一次调用`sendto()`时由kernel自动分配. client的临时port number不会改变, 但IP address会改变: 当client所在的主机多有个IP address时, 会由于出接口不同而导致IP address不同; 当client绑定一个IP address, 但kernel发送的出接口使用其他IP address时, datagram中的source IP address还是会修改为绑定的IP address.

![Summary of UDP client/server from  server's perspective](/images/Network/UNP/8-8-udp-from-svr.gif)
server可能需要获得四种数据: source IP address, destination IP address, source port number, destination port number. 以下是TCP server和UDP server所需调用的函数:

| From client's IP datagram | TCP server | UDP server |
|:---:|:---:|:---:|
| Source IP address | accept | recvfrom |
| Source port number | accept | recvfrom |
| Destination IP address | getsockname | recvmsg |
| Destination port number | getsockname | getsockname |

TCP server可以轻松地获取socket任何信息, 但UDP server需要设置`IP_RECVDSTADDR` socket option(IPv4)或**IPV6_PKTINFO** socket option(IPv6), 并通过`recvmsg()`获取destination IP address. 由于UDP是无连接的, 所以每个接收到的datagram的destination IP address都可能不同. 


## 9. connect Function with UDP
当UDP socket调用`connect()`时, 并不会像TCP connection一样进行three-way handshake. kernel保留foreign IP address和foreign port number, 返回所有connection error(例如: unreachable destination), 并且. 相对于unconnected UDP socket, connected UDP socket有以下几点不同:
1. connected UDP socket无法指定destination IP address和port, 一切发出的datagram都会使用`connect()`指定的IP address和port. 因此使用`write()`或`send()`发送数据, 而不是`sendto()`
2. connected UDP socket不再调用`recvfrom()`接收数据, 而使用`read()`, `recv()`或`recvmsg()`, 且kernel只会为connected UDP socket返回特定datagram(datagram中的source IP address和port与`connect()`中一致)
3. connected UDP socket返回asynchronous error

以下是TCP和UDP socket对于不同发送和接收函数的处理:

| Type of socket | write or send | sendto that doesn't specify a destination | sendto that specifies a destination |
|:---:|:---:|:---:|:---:|
| TCP socket | OK | OK | EISCONN |
| connected UDP socket | OK | OK | EISCONN |
| unconnected TCP socket | EDESTADDRREQ | EDESTADDRREQ | OK |

以下是connected UDP socket流程图:
![Connected UDP socket](/images/Network/UNP/8-9-udp-sock.gif)

当kernel发现接收到的datagram中source IP address或port与`connect()`中指定的IP address或port不符时, 会将该datagram传给其他UDP socket; 若没有UDP socket匹配该datagram, 则产生ICMP port unreachable error. 当UDP socket使用`connect()`后, 就只能与指定对端通信; 但connected UDP socket可再次调用`connect()`与另一个对端建立连接, 原因如下:
* 需要指定其他IP address和port
* 与指定对端断开连接

与UDP socket不同, 每个TCP socket只能调用一次`connect()`. 对于unconnected UDP socket, 将`connect()`中socket address structure的family member设置为**AF_UNSPEC**, 可能返回**EAFNOSUPPORT** error; 但对于connected UDP socket, 设置**AF_UNSPEC**意味着该socket断开连接. 
对于Berkeley-derived kernel, 当进程对unconnected UDP socket调用`sendto()`时, kernel会先connect socket(指定foreign IP address和foreign port number, 其中包括检查struct sockadd_in参数, 处理特殊IP address, 决定outgoing interface), 发送datagram, 最后unconnect socket(将foreign IP address和foreign port number置零). 若unconnected UDP socket调用`sendto()`发送两个datagram, 步骤如下:
1. Connect the socket
2. Output the first datagram
3. Unconnect the socket
4. Connect the socket
5. Output the second datagram
6. Unconnect the socket

第一次调用`sendto()`会在routing table中查找并保存destination IP address对应的outgoing interface; 第二次调用`sendto()`则跳过查找步骤, 直接从cached routing table information中找到destination IP address对应的outgoing interface.
当socket调用`connect()`后再调用`write()`发送两个datagram时, 步骤如下:
1. Connect the socket
2. Output first datagram
3. Output second datagram

可以看到, kernel只copy了一次foreign IP address和foreign port number. 当socket需要向特定IP address发送多个数据时, 可调用`connect()`提高发送效率.


## 10. dg_cli Function (Revisited)
```c
void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, 
            socklen_t servlen)
{
  int  n;
  char sendline[MAXLINE], recvline[MAXLINE + 1];

  Connect(sockfd, (SA *) pservaddr, servlen);

  while (Fgets(sendline, MAXLINE, fp) != NULL) {
    Write(sockfd, sendline, strlen(sendline));
    n = Read(sockfd, recvline, MAXLINE);
    recvline[n] = 0;  /* null terminate */
    Fputs(recvline, stdout);
  }
}
```
当修改后的client端向没有运行server程序的主机发送数据时, `recvline()`会捕获ICMP error. 但与TCP client不同, UDP client只有在发送第一个数据后才能接收到ICMP error, 而TCP client在调用`connect()`时就收到error. 大部分kernel都支持connected UDP socket返回ICMP error, 只要少数kernel不支持该特性.


## 11. Lack of Flow Control with UDP
假设UDP client向server发送2000个datagram, 每个datagram为1400 bytes, 以下是client端:
```c
#define	NDG   2000  /* datagrams to send */
#define	DGLEN 1400  /* length of each datagram */

void dg_cli(FILE *fp, int sockfd, const SA *pservaddr, 
            socklen_t servlen)
{
  int  i;
  char sendline[DGLEN];

  for (i = 0; i < NDG; i++) {
    Sendto(sockfd, sendline, DGLEN, 0, pservaddr, servlen);
  }
}
```
以下是server端:
```c
static void recvfrom_int(int);
static int  count;

void dg_echo(int sockfd, SA *pcliaddr, socklen_t clilen)
{
  socklen_t len;
  char      mesg[MAXLINE];

  // terminate the server with interrupt key
  Signal(SIGINT, recvfrom_int); 

  for ( ; ; ) {
    len = clilen;
    Recvfrom(sockfd, mesg, MAXLINE, 0, pcliaddr, &len);
    count++;
  }
}

static void recvfrom_int(int signo)
{
  printf("\nreceived %d datagrams\n", count);
  exit(0);
}
```
运行client/server后发现, 只有30个datagram被server调用`recvfrom()`接收, 剩下的datagram都因为socket receive buffer空间不足而丢弃. 为提高接受率, 可选择扩大socket receive buffer容量:
```c
static void recvfrom_int(int);
static int  count;

void dg_echo(int sockfd, SA *pcliaddr, socklen_t clilen)
{
  int       n;
  socklen_t len;
  char      mesg[MAXLINE];

  Signal(SIGINT, recvfrom_int);

  n = 220 * 1024;
  Setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &n, sizeof(n));

  for ( ; ; ) {
    len = clilen;
    Recvfrom(sockfd, mesg, MAXLINE, 0, pcliaddr, &len);
    count++;
  }
}

static void recvfrom_int(int signo)
{
  printf("\nreceived %d datagrams\n", count);
  exit(0);
}
```
再次运行client/server后, 成功接收的datagram数量上升至103, 虽然并没有全部接收, 但已经比之前情况好一些. 根据不同的kernel, socket receive buffer上限也不同. 



## 12. Determine Outgoing Interface with UDP
connected UDP socket在传输期间会锁定一个outgoing interface, 因为UDP socket调用`connect()`后, kernel会为该socket分配一个local IP address, 该IP address根据destination IP address和routing table决定, 并使用outgoing interface上的primary IP address.
UDP socket调用`connect()`后可使用`getsockname()`获取local IP address和port number:
```c
int main(int argc, char **argv)
{
  int                sockfd;
  socklen_t          len;
  struct sockaddr_in cliaddr, servaddr;

  sockfd = Socket(AF_INET, SOCK_DGRAM, 0);
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_port = htons(SERV_PORT);
  Inet_pton(AF_INET, argv[1], &servaddr.sin_addr);

  Connect(sockfd, (SA *) &servaddr, sizeof(servaddr));

  len = sizeof(cliaddr);
  Getsockname(sockfd, (SA *) &cliaddr, &len);
  printf("local address %s\n", Sock_ntop((SA *) &cliaddr, len));
}
```
但并不是所有kernel都支持该特性.


## 13. TCP and UDP Echo Server Using select
以下代码使用**select**同时监听UDP socket和TCP socket:
```c
int main(int argc, char **argv)
{
  int                listenfd, connfd, udpfd, nready, maxfdp1;
  char               mesg[MAXLINE];
  pid_t              childpid;
  fd_set             rset;
  ssize_t            n;
  socklen_t          len;
  const int          on = 1;
  struct sockaddr_in cliaddr, servaddr;
  void               sig_chld(int);

  /* create listening TCP socket */
  listenfd = Socket(AF_INET, SOCK_STREAM, 0);
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);

  /* allow socket to be bound to an identical socket address */
  Setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
  Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));

  Listen(listenfd, LISTENQ);

  /* create UDP socket */
  udpfd = Socket(AF_INET, SOCK_DGRAM, 0);
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family      = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port        = htons(SERV_PORT);

  Bind(udpfd, (SA *) &servaddr, sizeof(servaddr));

  Signal(SIGCHLD, sig_chld);  /* must call waitpid() */

  FD_ZERO(&rset);
  maxfdp1 = max(listenfd, udpfd) + 1;
  for ( ; ; ) {
    FD_SET(listenfd, &rset);
    FD_SET(udpfd, &rset);
    
    /* wait only for readability on the TCP and UDP sockets */
    if ( (nready = select(maxfdp1, &rset, NULL, NULL, NULL)) < 0) {
      if (errno == EINTR)
        continue; /* back to for() */
      else
        err_sys("select error");
    }

    if (FD_ISSET(listenfd, &rset)) {
      len = sizeof(cliaddr);
      connfd = Accept(listenfd, (SA *) &cliaddr, &len);
  
      if ( (childpid = Fork()) == 0) {  /* child process */
        Close(listenfd);  /* close listening socket */
        str_echo(connfd); /* process the request */
        exit(0);
      }
      Close(connfd);  /* parent closes connected socket */
    }

    if (FD_ISSET(udpfd, &rset)) {
      len = sizeof(cliaddr);
      n = Recvfrom(udpfd, mesg, MAXLINE, 0, (SA *) &cliaddr, &len);

      Sendto(udpfd, mesg, n, 0, (SA *) &cliaddr, len);
    }
  }
}
```
