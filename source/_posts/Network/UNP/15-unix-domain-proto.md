---
title: UNIX Domain Protocols
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: 14f4
date: 2020-01-13 08:52:08
keywords:
description:
---

## 1. Introduction
UNIX domain protocols并不是真正的protocol suite, 而是在同一host实现client/server通信的方式. UNIX domain protocols可作为IPC(interprocess communication)的替代方案, 并提供了两种socket类型: stream socket和datagram socket. 虽然也提供了raw socket, 但其使用方法并没有文档记录, 且没有收录在POSIX中.
以下是使用UNIX domain socket的三个原因:
1. Berkeley-derived系统中, UNIX domain socket是TCP socket的两倍速度
2. UNIX domain socket可被用于在同一host的进程之间传输descriptor
3. 一些UNIX domain socket支持将client的user ID和group ID传输给server

UNIX domain中使用pathname作为client和server的potocol address, 而不是IPv4或IPv6 address. pathname指向的文件并不是普通的UNIX文件: 除了pathname绑定的UNIX domain socket, 其他用户无法访问该文件


## 2. UNIX Domain Socket Address Structure
```c
#include <sys/un.h>

/**
 * @brief return the sum of the size of the sun_family and the 
 *        string length of the file name string
 */
int SUN_LEN (struct sockaddr_un *p);

struct sockaddr_un {
  sa_family_t sun_family; /* AF_LOCAL */
  char sun_path[104];     /* null-terminated pathname */
};
```
由于历史原因, POSIX specification没有规定`sun_path`的长度, 一般来说, pathname的长度区间为$[92, 108]$, 且`sun_path`中的pathname必须以NULL结尾. 若`sunpath[0]`为0, 相当于IPv4的`INADDR_ANY`, 或IPv6的`IN6ADDR_ANY_INIT`. 
POSIX将UNIX domain protocols重命名为**local IPC**, 以移除对于UNIX系统的依赖, `AF_UNIX`改为`AF_LOCAL`. 以下是UNIX domain socket绑定pathname的例子:
```c
int main(int argc, char **argv)
{
  int sockfd;
  socklen_t len;
  struct sockaddr_un addr1, addr2;

  if (argc != 2)
    err_quit("usage: UNIXbind <pathname>");

  sockfd = Socket(AF_LOCAL, SOCK_STREAM, 0);

  /* delete the pathname if it already exists */
  unlink(argv[1]);

  bzero(&addr1, sizeof(addr1));
  addr1.sun_family = AF_LOCAL;

  /* avoid overflow if the pathname is too long */
  strncpy(addr1.sun_path, argv[1], sizeof(addr1.sun_path)-1);

  /* bind() will fail if the pathname already exists */
  Bind(sockfd, (SA *) &addr1, SUN_LEN(&addr1));

  len = sizeof(addr2);
  Getsockname(sockfd, (SA *) &addr2, &len);
  printf("bound name = %s, returned len = %d\n", addr2.sun_path, len);
  
  exit(0);
}
```
以下是程序运行结果:
```sh
% UNIXbind /tmp/moose
bound name = /tmp/moose, returned len = 13
```
可以看到, sockaddr_un structure的长度为13, 其中sun_family为2 bytes, pathname为11 bytes(包括最后的terminating null). 



## 3. socketpair Function
```c
#include <sys/socket.h>

/**
 * @brief create an unnamed pair of connected sockets in
 *        the specified domain of the specified type
 * @return return 0 on success; -1 on error, errno is set
 */
int socketpair(int family, int type, int protocol, int sockfd[2]);
```
其中, family必须为`AF_LOCAL`, protocol必须为0, type可以为`SOCK_STREAM`或`SOCK_DGRAM`, 返回的两个socket descriptors将存放于`sockfd[0]`和`sockfd[1]`. `socketpair()`和UNIX的`pipe()`相似: 返回两个file descriptor, 两个file descriptor相互连接. type为`SOCK_STREAM`的socket pair称为stream pipe, 与UNIX piipe相似, 但是是full-duplex(两个descriptors都可读可写)


## 4. Socket Functions
UNIX domain socket与其他socket function有很多不同之处, 以下是POSIX规定中的不同:
1. `bind()`中的pathname的文件访问权限应为0777(read, execute by user, group, and other), 由当前umask值修改
2. pathname应是一个absolute pathname(绝对路径), 而不是relative pathname(相对路径). 当调用者处于不同的工作路径时, relative pathname会导致使用的pathname各不相同. 如果需要使用relative pathname, 则需要将client和server放置在同一目录下
3. `connect()`中的pathname应为土匪同类型的UNIX domain socket, 以下是可能遇到的错误:
  1. pathname存在但不是socket
  2. pathname存在且为socket, 但没有绑定任何socket descriptor
  3. pathname存在且为socket, 但类型错误
4. `connect()`对UNIX domain socket进行权限测试, 相当于`open()`以write-only方式打开pathname
5. UNIX domain stream socket与TCP socket相同, 都提供了byte stream interface
6. 若`connect()`为UNIX domain stream socket创建连接, 且listening socket queue已满, `connect()`立即返回`ECONNREFUSED`. 但与TCP socket不同, 若listening socket queue已满, TCP server会无视SYN, TCP client会再次发送SYN
7. UNIX domain datagram socket与UDP socket类似: 都提供了非可靠的datagram serivce
8. 对于UNIX domain datagram socket, 若没有绑定某个pathname就发送数据, kernel不会自动为socket绑定某个pathname. 但对于UDP socket, kernel会在发送数据时自动为socket分配一个port number. 这也意味着, 若sender在没有绑定pathname的情况下发送数据, receiver无法回复, 因为无法获知sender的pathname


## 5. UNIX Domain Stream Client/Server
以下是UNIX domain stream server:
```c
#define	UNIXSTR_PATH "/tmp/UNIX.str"

int main(int argc, char **argv)
{
  int listenfd, connfd;
  pid_t childpid;
  socklen_t clilen;
  struct sockaddr_un cliaddr, servaddr;
  void sig_chld(int);

  /* create a UNIX domain stream socket */
  listenfd = Socket(AF_LOCAL, SOCK_STREAM, 0);

  unlink(UNIXSTR_PATH); /* remove the pathname if it exists */
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sun_family = AF_LOCAL;
  strcpy(servaddr.sun_path, UNIXSTR_PATH);

  Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));

  Listen(listenfd, LISTENQ);

  Signal(SIGCHLD, sig_chld);

  for ( ; ; ) {
    clilen = sizeof(cliaddr);
    if ((connfd = accept(listenfd, (SA *) &cliaddr, &clilen)) < 0) {
      if (errno == EINTR)
        continue; /* back to for() */
      else
        err_sys("accept error");
    }

    if ((childpid = Fork()) == 0) { /* child process */
      Close(listenfd); /* close listening socket */
      str_echo(connfd); /* process request */
      exit(0);
    }
    Close(connfd); /* parent closes connected socket */
  }
}
```

以下是UNIX domain stream client:
```c
int main(int argc, char **argv)
{
  int sockfd;
  struct sockaddr_un servaddr;

  sockfd = Socket(AF_LOCAL, SOCK_STREAM, 0);

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sun_family = AF_LOCAL;
  strcpy(servaddr.sun_path, UNIXSTR_PATH);

  Connect(sockfd, (SA *) &servaddr, sizeof(servaddr));

  str_cli(stdin, sockfd);

  exit(0);
}
```


## 6. UNIX Domain Datagram Client/Server
以下是UNIX domain datagram server:
```c
#define	UNIXDG_PATH "/tmp/UNIX.dg"

int main(int argc, char **argv)
{
  int sockfd;
  struct sockaddr_un servaddr, cliaddr;

  /* create a UNIX domain datagram socket */
  sockfd = Socket(AF_LOCAL, SOCK_DGRAM, 0);

  unlink(UNIXDG_PATH);
  bzero(&servaddr, sizeof(servaddr));
  servaddr.sun_family = AF_LOCAL;
  strcpy(servaddr.sun_path, UNIXDG_PATH);

  Bind(sockfd, (SA *) &servaddr, sizeof(servaddr));

  dg_echo(sockfd, (SA *) &cliaddr, sizeof(cliaddr));
}
```
以下是UNIX domain datagram client:
```c
int main(int argc, char **argv)
{
  int sockfd;
  struct sockaddr_un cliaddr, servaddr;

  sockfd = Socket(AF_LOCAL, SOCK_DGRAM, 0);

  bzero(&cliaddr, sizeof(cliaddr)); /* bind an address for us */
  cliaddr.sun_family = AF_LOCAL;
  strcpy(cliaddr.sun_path, tmpnam(NULL));

  /* unlike UDP client, must bind a pathname to socket */
  Bind(sockfd, (SA *) &cliaddr, sizeof(cliaddr));

  /* fill in server's address */
  bzero(&servaddr, sizeof(servaddr)); 
  servaddr.sun_family = AF_LOCAL;
  strcpy(servaddr.sun_path, UNIXDG_PATH);

  dg_cli(stdin, sockfd, (SA *) &servaddr, sizeof(servaddr));

  exit(0);
}
```
注意: 若client中不调用`bind()`绑定pathname, 则server的`recvfrom()`返回null pathname, 导致server调用`sendto()`时发生错误


## 7. Passing Descriptors
当提到在进程之间传输descriptor时, 一般会想到:
* 父进程调用`fork()`后, 其子进程与其共享descriptor
* 子进程执行`exec()`后, 其仍保留descriptor

父进程调用`fork()`后, 对descriptor调用`close()`, 其子进程仍保留这些descriptor, 相当于父进程将descriptor传递给其子进程. UNIX系统提供了另一种传递descriptor的方式: 该方法不需要两个进程之间存在任何关系, 只需要双方创建UNIX domain socket, 并通过`sendmsg()`传输descriptor.
以下是两个进程之间传输descriptor的步骤:
1. 创建一个UNIX domain socket, 可以使stream socket, 也可以是datagram socket
  * 若想让子进程将descriptor传递给父进程, 则父进程可调用`socketpair()`创建一个stream pipe来交换descriptor
  * 若进程之间并无关系, 则server需要创建一个UNIX domain stream socket并绑定pathname, 允许client调用`connect()`发起连接; client可向server请求某些descriptor, server可通过socket回应.
2. 调用`open()`, `pipe()`, `mkfifo()`, `socket()`, 或`accept()`返回descriptor, 该方法支持任何类型的descriptor.
3. sending process可创建一个`msghdr struct`, 其中包含descriptor. POSIX.1中规定, descriptor作为ancillary data传输. 若sending process调用`sendmsg()`, 会将descriptor reference加一, 因此, 即使sending process关闭descriptor, descriptor也不会真正关闭.
4. receiving process调用`recvmsg()`接收descriptor. 接收到的descriptor number会与之前不同, 因为receiving process会通过file table entry重新创建一个descriptor.

若receiver调用`recvmsg()`时没有为ancillar data分配足够空间, 则descriptor会被自动关闭; 若receiver接收到的descriptor超过进程最大descriptor数量, 也会自动关闭descriptor.
假设有一个名为mycat的程序, 负责从command-line argument中获取pathname, 打开文件并将文件内容输出到stdout. 但不直接调用`open()`打开文件, 而是创建stream pipe, 调用`fork()`生成子进程, 让子进程打开文件并将file descriptor传回父进程, 最后由父进程打开并输出. 调用`socketpair()`创建stream pipe后如下图:
![mycat program after creating stream pipe using socketpair](/images/Network/UNP/15-7-socketpair-create-stream-pipe.gif)

之后进程调用`fork()`, 并让子进程调用`exec()`运行openfile程序, 父进程关闭`[1]` descriptor, 子进程关闭`[0]` descriptor, 如下图:
![mycat program after invoking openfile program](/images/Network/UNP/15-7-invoke-openfile-program.gif)

其中, 父进程需要通过`exec()`传给子进程(openfile程序)三个信息: 
* 文件pathname
* open mode
* 对端stream pipe的descriptor number(本例中为`[1]`)

openfile程序将descriptor传回父进程后终止运行, 父进程可通过exit status得知文件是否被打开. 使用另一个程序打开文件有一个好处: 可通过设置**set-user-ID**获取临时root权限, 可让进程打开一些本无权限打开的文件. 以下是mycat程序:
```c
int my_open(const char *pathname, int mode)
{
  int   fd, sockfd[2], status;
  pid_t childpid;
  char  c, argsockfd[10], argmode[10];

  /* create a stream pipe*/
  Socketpair(AF_LOCAL, SOCK_STREAM, 0, sockfd);

  if ((childpid = Fork()) == 0) { /* child process */
    Close(sockfd[0]);
    snprintf(argsockfd, sizeof(argsockfd), "%d", sockfd[1]);
    snprintf(argmode, sizeof(argmode), "%d", mode);
    execl("./openfile", "openfile", argsockfd, pathname, argmode, (char *)NULL);
    err_sys("execl error");
  }

  /* parent process - wait for the child to terminate */
  Close(sockfd[1]); /* close the end we don't use */

  /* wait for the child to terminate */
  Waitpid(childpid, &status, 0);

  /* WIFEXITED convert termination status into exit signal */
  if (WIFEXITED(status) == 0) 
    err_quit("child did not terminate");
  if ((status = WEXITSTATUS(status)) == 0) {
    /* receive descriptor across a stream pipe */
    Read_fd(sockfd[0], &c, 1, &w); 
  } else {
    errno = status; /* set errno value from child's status */
    fd = -1;
  }

  Close(sockfd[0]);
  return(fd);
}

int main(int argc, char **argv)
{
  int  fd, n;
  char buff[BUFFSIZE];

  if (argc != 2)
    err_quit("usage: mycat <pathname>");

  if ((fd = my_open(argv[1], O_RDONLY)) < 0)
    err_sys("cannot open %s", argv[1]);

  while ((n = Read(fd, buff, BUFFSIZE)) > 0)
    Write(STDOUT_FILENO, buff, n);

  exit(0);
}
```
以下是`read_fd()`函数, 包含两种模式: `msg_control`和`msg_accrights`
```c
ssize_t read_fd(int fd, void *ptr, size_t nbytes, int *recvfd)
{
  struct msghdr msg;
  struct iovec iov[1];
  ssize_t n;

#ifdef HAVE_MSGHDR_MSG_CONTROL
  union {
    struct cmsghdr cm;
    char control[CMSG_SPACE(sizeof(int))];
  } control_un;
  struct cmsghdr *cmptr;

  msg.msg_control = control_un.control;
  msg.msg_controllen = sizeof(control_un.control);
#else
  int newfd;
  msg.msg_accrights = (caddr_t) &newfd;
  msg.msg_accrightslen = sizeof(int);
#endif

  msg.msg_name = NULL;
  msg.msg_namelen = 0;

  iov[0].iov_base = ptr;
  iov[0].iov_len = nbytes;
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;

  if ((n = recvmsg(fd, &msg, 0)) <= 0)
    return(n);

#ifdef HAVE_MSGHDR_MSG_CONTROL
  if ((cmptr = CMSG_FIRSTHDR(&msg)) != NULL &&
      cmptr->cmsg_len == CMSG_LEN(sizeof(int))) {
    if (cmptr->cmsg_level != SOL_SOCKET)
      err_quit("control level != SOL_SOCKET");
    if (cmptr->cmsg_type != SCM_RIGHTS)
      err_quit("control type != SCM_RIGHTS");
    /* return the pointer to the ancillary data */ 
    *recvfd = *((int *) CMSG_DATA(cmptr));
  } else
    *recvfd = -1; /* descriptor was not passed */
#else
  if (msg.msg_accrightslen == sizeof(int))
    *recvfd = newfd; /* return the newly created descriptor */
  else
    *recvfd = -1; /* descriptor was not passed */
#endif

  return(n);
}
```
以下是openfile程序:
```c
ssize_t write_fd(int fd, void *ptr, size_t nbytes, int sendfd)
{
  struct msghdr msg;
  struct iovec iov[1];

#ifdef HAVE_MSGHDR_MSG_CONTROL
  union {
    struct cmsghdr cm;
    char control[CMSG_SPACE(sizeof(int))];
  } control_un;
  struct cmsghdr *cmptr;

  msg.msg_control = control_un.control;
  msg.msg_controllen = sizeof(control_un.control);

  cmptr = CMSG_FIRSTHDR(&msg);
  cmptr->cmsg_len = CMSG_LEN(sizeof(int));
  cmptr->cmsg_level = SOL_SOCKET;
  cmptr->cmsg_type = SCM_RIGHTS;
  *((int *) CMSG_DATA(cmptr)) = sendfd;
#else
  msg.msg_accrights = (caddr_t) &sendfd;
  msg.msg_accrightslen = sizeof(int);
#endif

  msg.msg_name = NULL;
  msg.msg_namelen = 0;

  iov[0].iov_base = ptr;
  iov[0].iov_len = nbytes;
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;

  return(sendmsg(fd, &msg, 0));
}

int main(int argc, char **argv)
{
  int fd;

  if (argc != 4)
    err_quit("openfile <sockfd#> <filename> <mode>");

  /* open the file by pathname */
  if ((fd = open(argv[2], atoi(argv[3]))) < 0)
    exit((errno > 0) ? errno : 255 );

  /* send the descriptor across a UNIX domain socket */
  if (write_fd(atoi(argv[1]), "", 1, fd) < 0)
    exit((errno > 0) ? errno : 255 );

  exit(0);
}
```


## 8. Receive Sender Credentials
UNIX domain socket可使用ancillary data传输user credentials. 当client与server通信时, server需要知道client是否拥有权限来执行服务. FreeBSD中通过`cmsgcred struct`来传输credentials:
```c
#include <sys/socket.h>

truct cmsgcred {
  pid_t cmcred_pid;     /* PID of sending process */
  uid_t cmcred_uid;     /* real UID of sending process */
  uid_t cmcred_euid;    /* effective UID of sending process */
  gid_t cmcred_gid;     /* real GID of sending process */
  short cmcred_ngroups; /* number of groups */
  gid_t cmcred_groups[CMGROUP_MAX]; /* groups */
};
```
通常`CMGROUP_MAX`为16, `cmcred_ngroups`至少为1, `cmcred_groups`的第一个元素为effective group ID. 不同UNIX系统对于发送credentials有不同的要求: FreeBSD不要求receiver做任何特殊处理, 调用`recvmsg()`就可通过ancillart data接收credentials, 但sender调用`sendmsg()`时必须添加`cmsgcred struct`, 该结构体由kernel填充. 这使得server可通过UNIX domain socket验证client的身份.
以下例子中, server请求credentials, client发送自身的credentials. sender端代码如下:
```c
#define CONTROL_LEN (sizeof(struct cmsghdr) + sizeof(struct cmsgcred))

/* read client's credentials into cmsgcredptr */
ssize_t read_cred(int fd, void *ptr, size_t nbytes, struct cmsgcred *cmsgcredptr)
{
  struct msghdr msg;
  struct iovec iov[1];
  char control[CONTROL_LEN];
  int n;

  msg.msg_name = NULL;
  msg.msg_namelen = 0;
  iov[0].iov_base = ptr;
  iov[0].iov_len = nbytes;
  msg.msg_iov = iov;
  msg.msg_iovlen = 1;
  msg.msg_control = control;
  msg.msg_controllen = sizeof(control);
  msg.msg_flags = 0;

  if ((n = recvmsg(fd, &msg, 0)) < 0)
    return(n);

  cmsgcredptr->cmcred_ngroups = 0; /* indicates no credentials returned */
  if (cmsgcredptr && msg.msg_controllen > 0) {
    struct cmsghdr *cmptr = (struct cmsghdr *) control;

    if (cmptr->cmsg_len < CONTROL_LEN)
      err_quit("control length = %d", cmptr->cmsg_len);
    if (cmptr->cmsg_level != SOL_SOCKET)
      err_quit("control level != SOL_SOCKET");
    if (cmptr->cmsg_type != SCM_CREDS)
      err_quit("control type != SCM_CREDS");
    memcpy(cmsgcredptr, CMSG_DATA(cmptr), sizeof(struct cmsgcred));
  }

  return(n);
}

/* print the credentials from client socket: sockfd */
void str_echo(int sockfd)
{
  ssize_t n;
  int i;
  char buf[MAXLINE];
  struct cmsgcred cred;

again:
  /* read credentials from ancillary data */
  while ((n = read_cred(sockfd, buf, MAXLINE, &cred)) > 0) {
    if (cred.cmcred_ngroups == 0) {
      printf("(no credentials returned)\n");
    } else {
      printf("PID of sender = %d\n", cred.cmcred_pid);
      printf("real user ID = %d\n", cred.cmcred_uid);
      printf("real group ID = %d\n", cred.cmcred_gid);
      printf("effective user ID = %d\n", cred.cmcred_euid);
      printf("%d groups:", cred.cmcred_ngroups - 1);
      for (i = 1; i < cred.cmcred_ngroups; i++)
        printf(" %d", cred.cmcred_groups[i]);
      printf("\n");
    }
    Writen(sockfd, buf, n);
  }

  if (n < 0 && errno == EINTR)
    goto again;
  else if (n < 0)
    err_sys("str_echo: read error");
}
```
