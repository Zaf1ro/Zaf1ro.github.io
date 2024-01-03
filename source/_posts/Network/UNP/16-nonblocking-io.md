---
title: Nonblocking I/O
abbrlink: 96d1
date: 2020-01-20 09:47:20
category:
  - Network
  - UNP
tag:
  - Network
keywords:
description:
---

## 1. Introduction
默认情况下socket是blocking, 若socket的操作无法立即完成, 则进程进入睡眠, 直到完成操作. 对于socket的操作分为以下4种类别:
1. Input Operation: 包括`read()`, `readv()`, `recv()`, `recvfrom()`和`recvmsg()`. 若进程对blocking socket调用上述任何一个input operation, 且socket receive buffer中没有数据, 则进程进入睡眠. 由于TCP为byte stream, 无论socket receive buffer中接收到单个byte数据或整个TCP segment, socket都会被唤醒; 由于UDP为datagram protocol, socket会在接收到UDP datagram后被唤醒; 对于nonblocking socket, 若input operation(TCP socket接收到一个byte, 或UDP socket接收到一个完整的datagram)无法被满足, 则返回**EWOULDBLOCK**.
2. Output Operation: 包括`write()`, `writev()`, `send()`, `sendto()`和`sendmsg()`. 对于blocking TCP socket, kernel会将进程中的数据复制到socket send buffer. 若socket send buffer中没有空间, 则进程进入睡眠; 对于nonblocking TCP socket, 若socket send buffer中没有空间, 则返回`EWOULDBLOCK`; 若socket send buffer还有空间, 则返回复制到buffer的数据字节数. 对于UDP output operation, 由于UDP没有socket send buffer, kernel会直接将进程中的数据复制到TCP/IP stack中, 因此即使是blocking UDP socket也不会阻塞.
3. Accept connection: 包括`accept()`. 若blocking socket调用`accept()`, 直到socket接收到连接之前之前, 进程都处于睡眠状态. 若nonblocking socket调用`accept()`, 且没有新的连接, 则返回`EWOULDBLOCK`.
4. Initiate connection: 包括TCP的`connect()`. 由于TCP connection需要three-way handshake, 对于blocking TCP socket, 直到连接建立完成之前, 进程都处于睡眠状态; 对于nonblocking TCP socket, 若connection还没建立, 则返回`EINPROGRESS`. 但并不是所有UNIX都会返回相同error, System V返回EAGAIN, Berkeley-derived返回EWOULDBLOCK, POSIX spcecification允许`connect()`返回其中任何一个错误.


## 2. Nonblocking Reads and Writes: str_cli Function (Revisited)
Nonblocking I/O的一大优势在于阻塞进程, 例如: 当进程调用`write()`向TCP blocking socket发送数据时, 可能因为socket send buffer已满而被阻塞. 这时可用nonblocking I/O来防止阻塞, 并去做其他事情. 但nonblocking I/O会复杂化buffer management, 假设client需要从stdin获取数据并发送至server; 从server接收数据并输出到stdout. 以下是程序需要维护的两个buffers: 
1. to: 负责缓冲stdin到server的数据. 其中toiptr指针表示socket发送数据的开端, tooptr指针表示stdin读取数据的开端, 每次从stdin读取的数据上限为$\text{to[MAXLINE]} - \text{toiptr}$, 若$\text{tooptr} == \text{toiptr}$时, 则将这两个指针重置到buffer头部.
![Buffer containing data from standard input going to the socket](/images/Network/UNP/16-2-data-from-stdio-to-sock.gif)
2. fr: 负责缓冲server到stdout的数据. 其中froptr指针表示stdout输出数据的开端, friptr指针表示server传来数据的开端.
![Buffer containing data from the socket going to standard output](/images/Network/UNP/16-2-data-from-sock-to-stdout.gif)

以下是client端使用nonblocking socket接收并发送数据的代码:
```c
void str_cli(FILE *fp, int sockfd)
{
  int maxfdp1, val, stdineof;
  ssize_t n, nwritten;
  fd_set rset, wset;
  char to[MAXLINE], fr[MAXLINE];
  char *toiptr, *tooptr, *friptr, *froptr;

  /* set all descriptors to nonblocking */
  val = Fcntl(sockfd, F_GETFL, 0);
  Fcntl(sockfd, F_SETFL, val | O_NONBLOCK);

  val = Fcntl(STDIN_FILENO, F_GETFL, 0);
  Fcntl(STDIN_FILENO, F_SETFL, val | O_NONBLOCK);

  val = Fcntl(STDOUT_FILENO, F_GETFL, 0);
  Fcntl(STDOUT_FILENO, F_SETFL, val | O_NONBLOCK);

  toiptr = tooptr = to;	/* initialize buffer pointers */
  friptr = froptr = fr;
  stdineof = 0;

  maxfdp1 = max(max(STDIN_FILENO, STDOUT_FILENO), sockfd) + 1;
  for ( ; ; ) {
    FD_ZERO(&rset);
    FD_ZERO(&wset);

    // have not yet read an EOF on stdin, and at least one 
    // byte of data in the to buffer
    if (stdineof == 0 && toiptr < &to[MAXLINE])
      FD_SET(STDIN_FILENO, &rset); /* read from stdin */

    // at least one byte if data in the fr buffer
    if (friptr < &fr[MAXLINE])
      FD_SET(sockfd, &rset); /* read from socket */

    // there is data to write to server in the to buffer
    if (tooptr != toiptr)
      FD_SET(sockfd, &wset); /* data to write to socket */

    // there is data to send to stdout in the fr buffer
    if (froptr != friptr)
      FD_SET(STDOUT_FILENO, &wset); /* data to write to stdout */

    Select(maxfdp1, &rset, &wset, NULL, NULL);

    if (FD_ISSET(STDIN_FILENO, &rset)) { // stdin is readable
      if ((n = read(STDIN_FILENO, toiptr, &to[MAXLINE] - toiptr)) < 0) {
        if (errno != EWOULDBLOCK)
          err_sys("read error on stdin");
      } else if (n == 0) { // receive EOF from stdin
        stdineof = 1; /* all done with stdin */
        if (tooptr == toiptr) // no data in the to buffer
          Shutdown(sockfd, SHUT_WR); /* send FIN */
      } else {
        toiptr += n; /* read data from stdin */
        FD_SET(sockfd, &wset); /* try and write to socket below */
      }
    }

    if (FD_ISSET(sockfd, &rset)) { // socket is readable
      if ((n = read(sockfd, friptr, &fr[MAXLINE] - friptr)) < 0) {
        if (errno != EWOULDBLOCK)
          err_sys("read error on socket");
      } else if (n == 0) { // server closed
        if (stdineof)
          return; /* normal termination */
        else
          err_quit("str_cli: server terminated prematurely");
      } else {
        friptr += n; /* read data from socket */
        FD_SET(STDOUT_FILENO, &wset); /* try and write below */
      }
    }

    // stdout is writable and there's data in the fr buffer
    if (FD_ISSET(STDOUT_FILENO, &wset) && ((n = friptr - froptr) > 0)) {
      if ((nwritten = write(STDOUT_FILENO, froptr, n)) < 0) {
        if (errno != EWOULDBLOCK)
          err_sys("write error to stdout");
      } else {
        froptr += nwritten; /* writte data into stdout */
        if (froptr == friptr)
          froptr = friptr = fr; /* back to beginning of buffer */
      }
    }

    // socket is writable and there's data in the to buffer
    if (FD_ISSET(sockfd, &wset) && ((n = toiptr - tooptr) > 0)) {
      if ((nwritten = write(sockfd, tooptr, n)) < 0) {
        if (errno != EWOULDBLOCK)
          err_sys("write error to socket");
      } else { 
        tooptr += nwritten; /* write data into socket */
        if (tooptr == toiptr) {
          toiptr = tooptr = to; /* back to beginning of buffer */
          if (stdineof)
            Shutdown(sockfd, SHUT_WR); /* send FIN */
        }
      }
    }
  }
}
```
下图中没有展示ACK segment, 但也能大概表示整个数据传输的过程:
![Timeline of nonblocking example](/images/Network/UNP/16-2-timeline-of-nonblocking.gif)

Nonblocking的`str_cli()`虽然提高了传输速率, 但代码也随之变得复杂, 很容易产生bug. 以下是改进后的`str_cli()`:
```c
void str_cli(FILE *fp, int sockfd)
{
  pid_t pid;
  char sendline[MAXLINE], recvline[MAXLINE];

  if ((pid = Fork()) == 0) { /* child: server -> stdout */
    while (Readline(sockfd, recvline, MAXLINE) > 0)
      Fputs(recvline, stdout);

    kill(getppid(), SIGTERM); /* in case parent still running */
    exit(0);
  }

  /* parent: stdin -> server */
  while (Fgets(sendline, MAXLINE, fp) != NULL)
    Writen(sockfd, sendline, strlen(sendline));

  Shutdown(sockfd, SHUT_WR); /* EOF on stdin, send FIN */
  pause();
  return;
}
```
使用`fork()`产生子进程来分工处理. TCP connection为全双工, 父进程和子进程共享一个socket descriptor. 父进程负责从stdin读取数据, 并发送至server; 子进程负责从server获取数据, 并输出到stdout. 如下图:
![str_cli function using two processes](/images/Network/UNP/16-2-proc-of-str_cli.gif)

但还有一个问题需要注意: 如何在stdin返回EOF后, 确保TCP termination正常执行. 当父进程收到来自stdin的EOF后调用`shutdown()`向server端发送FIN, 但子进程会继续从server端接收数据并输出到stdout, 直到server端返回EOF. 当server端意外终止运行时, 子进程会收到EOF, 并需通知父进程停止向socket发送数据. 本例中子进程会向父进程发送`SIGTERM` signal.
当父进程从stdin收到EOF后会向server发送FIN, 并调用`pause()`等待子进程发送signal. `SIGTERM` signal默认会直接停止父进程运行. 
由于将原先的4个I/O stream拆分为2组, 因此没必要使用nonblocking I/O: 当父进程没有接收到stdin数据时, 无需向server发送数据; 当子进程没有接收来自server端的数据时, 无需向stdout输出数据. 以下是使用不同版本的`str_cli()`发送2000行文本的所需时间:

| str_cli() version | clock time (sec) |
|:----:|:----:|
| stop-and-wait | 354.0 |
| select and blocking I/O | 12.3 |
| nonblocking I/O | 6.9 |
| fork | 8.7 |
| threaded version | 8.5 |


## 3. Nonblocking connect
`connect()`调用nonblocking TCP socket时, 会立即返回`EINPROGRESS`, 并继续执行TCP three-way handshake. 之后调用`select()`检查`connect()`是否完成连接. 以下是nonblocking connect的用途:
1. 由于three-way handshake至少需要一个RTT才能完成, 因此进程可在等待`connect()`完成之前做其他事情
2. 同一时间建立多个connections
3. 为`connect()`设置计时器

Nonblocking connect还有一些需要注意的点:
* 即使socket为nonblocking, 若server与client处于同一host, 则`connect()`不会返回error, 而直接返回连接结果
* POSIX specification对于nonblocking connect有以下说明:
  * 当连接成功建立时, socket descriptor变为可写状态. 当socket descriptor的socket send buffer有足够空间时, 也会处于可写状态.
  * 当连接失败时, socket descriptor变为可读可写状态


## 4. Nonblocking connect: Daytime Client
以下`connect_nonb()`表示nonblocking connect:
```c
int connect_nonb(int sockfd, const SA *saptr, socklen_t salen, int nsec)
{
  int flags, n, error;
  socklen_t len;
  fd_set rset, wset;
  struct timeval tval;

  // set the socket to nonblocking
  flags = Fcntl(sockfd, F_GETFL, 0);
  Fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

  error = 0;
  if ((n = connect(sockfd, saptr, salen)) < 0)
    if (errno != EINPROGRESS)
      return -1;

  /* Do whatever we want while the connect is taking place. */

  if (n == 0) // connection is complete
    goto done;

  FD_ZERO(&rset);
  FD_SET(sockfd, &rset);
  wset = rset;
  tval.tv_sec = nsec; // initialize the timeval structure
  tval.tv_usec = 0;

  if ((n = Select(sockfd+1, &rset, &wset, NULL, nsec ? &tval
       : NULL)) == 0) {
    close(sockfd); /* timer expires */
    errno = ETIMEDOUT;
    return -1;
  }

  if (FD_ISSET(sockfd, &rset) || FD_ISSET(sockfd, &wset)) {
    len = sizeof(error);
    if (getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, 
        &len) < 0)
      return -1; /* find pending error */
  } else
    err_quit("select error: sockfd not set");

done:
  /* restore file status flags */
  Fcntl(sockfd, F_SETFL, flags); 

  if (error) {
    close(sockfd); /* just in case */
    errno = error;
    return -1;
  }
  return 0;
}
```
若调用`select()`前连接建立完成, 且对端传来数据时, `select()`会通知进程该socket descriptor可读可写, 与连接出错的结果相同, 因此需调用`getsockopt()`查看是否存在pending error. 除了`getsockopt()`, 以下方法也可判断连接是否建立成功:
* 调用`getpeername()`, 返回`ENOTCONN`: 连接建立失败, 需调用`getsockopt()`和`SO_ERROR`获取error
* 调用length为0的`read()`:
  * 返回-1: 连接建立失败
  * 返回0: 连接建立成功
* 再次调用`connect()`, 返回`EISCONN`: 连接建立成功.

若blocking connect被中断, `connect()`立即返回`EINTR`, 但这并不意味着连接就此中断. 实际上, kernel还会继续完成剩下的连接, 因此不能再次调用`connect()`, 否则返回`EADDRINUSE`. 这时应调用`select()`等待连接完成, select的返回结果与nonblocking connect相同: 若连接成功建立, 则socket处于可写状态; 若连接建立失败, 则socket处于可读可写状态.


## 5. Nonblocking connect: Web Client
Web client作为nonblocking connect的典型实例, 使用nonblocking connect与web server建立HTTP连接. 由于一个web page经常需要访问多个web server, 所以不能顺序访问各个web server, 需要调用nonblocking connect同一时间与多个web server建立连接. 假设web client需要建立三个connections:
* 1st connection: 建立连接需要10个单位时间
* 2nd connection: 建立连接需要15个单位时间
* 3rd connection: 建立连接需要4个单位时间

以下是不同方式建立连接的时序图:
![Establishing multiple connections in parallel](/images/Network/UNP/16-5-multi-conn-in-parallel.gif)

由于平行连接会共享同一网络带宽, 且需要考虑到TCP slow start等算法的影响, 所以实际建立连接所需时间会比上图所示的要长. 但可以看到, 并行建立连接的确比顺序建立连接消耗更少时间.
但上一节所用的`connect_nonb()`在这里并不适用, 因为`connect_nonb()`只有连接建立完成后返回, 而web client需要跟踪所有正在建立的connections. 假设web client需要从web server读取文件, 以下是一个示例:
```sh
% web 2 www.foobar.com / image1.gif image2.gif image3.gif image4.gif
```
上述command-line arguments中: 
* 需要建立的connections数量: `2`
* web server的host为`www.foobar.com`
* server的home page路径为`/`
* 需要从server获取的4个文件: `image1.gif`, `image2.gif`, `image3.gif`, `image4.gif`

以下是web程序的header file:
```c
/* web.h */

#define MAXFILES 20 /* Maximum number of files */
#define SERV "80"   /* port number or service name */

struct file {
  char *f_name; /* filename */
  char *f_host; /* hostname or IPv4/IPv6 address */
  int f_fd;     /* descriptor */
  int f_flags;  /* F_xxx below */
} file[MAXFILES];

#define	F_CONNECTING 1  /* connect() in progress */
#define	F_READING 2     /* connect() complete; now reading */
#define	F_DONE 4        /* all done */

#define GET_CMD "GET %s HTTP/1.0\r\n\r\n"

/* globals */
int nconn, nfiles, nlefttoconn, nlefttoread, maxfd;
fd_set rset, wset;

/* function prototypes */
void home_page(const char *, const char *);
void start_connect(struct file *);
void write_get_cmd(struct file *);
```
以下web程序的代码:
```c
#include	"web.h"

int main(int argc, char **argv)
{
  int i, fd, n, maxnconn, flags, error;
  char buf[MAXLINE];
  fd_set rs, ws;

  if (argc < 5)
    err_quit("usage: web <nconn> <hostname> <homepage> <file1> ...");
  
  maxnconn = atoi(argv[1]); /* maximum number of connections */
  nfiles = min(argc - 4, MAXFILES); /* number of files */
  
  /* fill in with the information from the command-line arguments */
  for (i = 0; i < nfiles; i++) { 
    file[i].f_name = argv[i + 4];
    file[i].f_host = argv[2];
    file[i].f_flags = 0;
  }

  /* create a TCP connection to he server's home page */
  home_page(argv[2], argv[3]);

  FD_ZERO(&rset);
  FD_ZERO(&wset);
  maxfd = -1;
  nlefttoread = nlefttoconn = nfiles;
  nconn = 0;

  while (nlefttoread > 0) { 
    /* there are additional connections to establish */
    while (nconn < maxnconn && nlefttoconn > 0) {
      for (i = 0 ; i < nfiles; i++) // find a nonconnected file
        if (file[i].f_flags == 0)
          break;
      if (i == nfiles) /* no files need to be connected */ 
        err_quit("nlefttoconn = %d but nothing found", nlefttoconn);
      start_connect(&file[i]);
      nconn++;
      nlefttoconn--;
    }

    rs = rset;
    ws = wset;
    n = Select(maxfd+1, &rs, &ws, NULL, NULL);

    for (i = 0; i < nfiles; i++) {
      flags = file[i].f_flags;
      if (flags == 0 || flags & F_DONE)
        continue;
      fd = file[i].f_fd;

      /* nonblocking connect is finished */
      if (flags & F_CONNECTING && (FD_ISSET(fd, &rs) || 
          FD_ISSET(fd, &ws))) { 
        n = sizeof(error);
        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &n) < 0 ||
            error != 0) {
          err_ret("nonblocking connect failed for %s", file[i].f_name);
        }
        /* connection established */
        FD_CLR(fd, &wset); /* no more writeability test */
        write_get_cmd(&file[i]); /* send HTTP request to the server */
      } 
      /* socket descriptor is ready for reading data from server */
      else if (flags & F_READING && FD_ISSET(fd, &rs)) {
        /* connection is closed by the server */
        if ((n = Read(fd, buf, sizeof(buf))) == 0) { 
          Close(fd);
          file[i].f_flags = F_DONE; /* clears F_READING */
          FD_CLR(fd, &rset);
          nconn--;
          nlefttoread--;
        } else {
          printf("read %d bytes from %s\n", n, file[i].f_name);
        }
      }
    }
  }
  exit(0);
}
```
以下是`home_page()`的实现. 由于只是读取server的home page, 所以并不需要使用nonblocking connect:
```c
#include "web.h"

void home_page(const char *host, const char *fname)
{
  int fd, n;
  char line[MAXLINE];

  fd = Tcp_connect(host, SERV); /* blocking connect() */

  n = snprintf(line, sizeof(line), GET_CMD, fname);
  Writen(fd, line, n); /* send an HTTP GET command */

  for ( ; ; )
    if ((n = Read(fd, line, MAXLINE)) == 0)
      break; /* server closed connection */

  Close(fd);
}
```
以下是start_connect(), 该函数负责实现nonblocking connect:
```c
#include "web.h"

void start_connect(struct file *fptr)
{
  int fd, flags, n;
  struct addrinfo *ai;

  /* convert the hostname and service name to addrinfo structure */
  ai = Host_serv(fptr->f_host, SERV, 0, SOCK_STREAM);

  fd = Socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
  fptr->f_fd = fd;

  /* set socket nonblocking */
  flags = Fcntl(fd, F_GETFL, 0);
  Fcntl(fd, F_SETFL, flags | O_NONBLOCK);

  /* initiate nonblocking connect to the server. */
  if ((n = connect(fd, ai->ai_addr, ai->ai_addrlen)) < 0) {
    if (errno != EINPROGRESS)
      err_sys("nonblocking connect error");
    fptr->f_flags = F_CONNECTING;
    FD_SET(fd, &rset); /* wait for read and write */
    FD_SET(fd, &wset);
    if (fd > maxfd) /* update maxfd if necessary */ 
      maxfd = fd;
  } else if (n >= 0) /* connect is already done */
    write_get_cmd(fptr); /* send the GET command to the server */
}
```
以下是`write_get_cmd()`的实现:
```c
#include "web.h"

void write_get_cmd(struct file *fptr)
{
  int n;
  char line[MAXLINE];

  n = snprintf(line, sizeof(line), GET_CMD, fptr->f_name);
  Writen(fptr->f_fd, line, n); /* write GET command to the server */

  fptr->f_flags = F_READING; /* convert to F_CONNECTING */
  FD_SET(fptr->f_fd, &rset); /* will read server's reply */
  if (fptr->f_fd > maxfd)
    maxfd = fptr->f_fd;
}
```


## 6. Nonblocking accept
当server使用`select()`后, `select()`负责检测listening socket是否可读, 因此只要在`select()`检测到可读后调用`accept()`即可, `accept()`也不必设为nonblocking. 但存在一个特殊情况: TCP client建立连接后立即向server发送RST. 以下是整个通信过程:
1. client与server进行TCP three-way handshake
2. server端的`select()`检测listening socket可读并返回
3. client向server发送RST
4. server收到RST, kernel自动抛弃已经建立的连接
5. server调用`accept()`后发现无连接, 进入阻塞, 直到其他连接到来

以下是解决方法的步骤:
1. 将listening socket设为nonblocking
2. 忽略`accpet()`返回的error (Berkeley-derived: `EWOULDBLOCK`, POSIX: `ECONNABORTED`, SVR4: `EPROTO`, signal: `EINTR`)
