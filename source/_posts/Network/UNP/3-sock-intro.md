---
title: Sockets Introduction
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: '2e41'
date: 2019-11-15 20:37:28
keywords:
description:
---

## 1. Socket Address Structure
绝大多数socket function都需要一个指向socket address structure的指针作为参数. 所有socket address structure都以`sockaddr_`作为开头.

### 1.1 IPv4 Socket Address Structure
IPv4 Socket Address Structure定义在`<netinet/in.h>`:
```c
struct in_addr{
  in_addr_t s_addr; /* 32-bit IPv4 Address */
};

struct sockaddr_in {
  uint8_t        sin_len      /* length of structure (16) */
  sa_family_t    sin_family;  /* AF_INET */
  in_port_t      sin_port;    /* 16-bit TCP or UDP port number */
  struct in_addr sin_addr;    /* 32-bit IPv4 address */
  char           sin_zero[8]; /* unused */
}
```
补充:
* 4.3BSD-Reno发布时为支持OSI, 将`sin_len`加入到`sockaddr_in`中; 在这之前第一个成员变量为`sa_family`, 其类型`uint8_t`是POSIX.1中规定的数据类型, 以下是所有POSIX-compliant系统提供的数据类型:
  1. `int8_t`: Signed 8-bit integer
  2. `uint8_t`: Unsigned 8-bit integer
  3. `int16_t`: Signed 16-bit integer
  4. `uint16_t`: Unsigned 16-bit integer
  5. `int32_t`: Signed 32-bit integer
  6. `uint32_t`: Unsigned 32-bit integer
  7. `sa_family_t`: Address family of socket address structure
  8. `socklen_t`: Length of socket address structure, `uint32_t`
  9. `in_addr_t`: IPv4 address, `uint32_t`
  10. `in_port_t`: TCP or UDP port, `uint16_t`
* 用户不需要设置`sin_len`, 只有kernel接触该域: `bind()`, `connect()`, `sentto()`, `sendmsg()`这四个函数将socket address structure从进程传入kernel时, 都会经过`sockargs()`, 该函数负责填充`sin_len`; `accept()`, `recvfrom()`, `recvmsg()`, `getpeername()`, `getsockname()`这五个函数从kernel中取回到进程时, 会设置`sin_len`域.
* The POSIX specification只要求用户填写三个域: `sin_family`, `sin_addr``和sin_port`. `sin_zero`为填充位, 用来保证socket address structure至少16 bytes大小.
* `sa_family_t`为无符号整数类型, `in_port_t`至少16位无符号整数, `in_addr_t`至少32位无符号整数
* TCP和UDP port number都以network byte order(网络字节序)存储. 
* 两种访问`sockaddr_in`中32-bit IPv4 address的方式: 假设现在有一个名为`serv`的`sockaddr_in`结构体, 其中`serv.sin_addr`代表`in_addr struct`; `ser.sin_addr.s_addr`代表`in_addr_t`(an unsigned 32-bit integer)
* `sin_zero`不可用, 一般置为0. 通常先将整个socket address structure置0, 再填写其他域.
* Socket address structure只放置在主机中用于协助通信, 并不传输到网络中.

### 1.2 Generic Socket Address Structure
不同协议使用不同的socket address structure, socket function会接收并处理指向socket address structure的指针. 但如何将不同的socket address structure作为参数传入socket function成了一个问题: ANSI C提出`void *`作为接收不同指针类型的参数类型, 但socket function的出现早于ANSI C, 导致无法使用`void *`. 因此提出generic socket address structure作为解决方案.
```c
/* 定义在<sys/socket.h> */

struct sockaddr {
  uint8_t     sa_len;
  sa_family_t sa_family;   /* address family: AF_xxx value */
  char        sa_data[14]; /* protocol-specific address */
}
```
所以socket function只需要以`sockaddr`指针作为参数即可接受所有socket address structure. 以`bind()`为例:
```c
int bind(int, struct sockaddr *, socklen_t);
```
可将目标socket address structure强制转换为`sockaddr`指针, 再将`sockaddr`指针和长度传入`bind()`:
```c
struct sockaddr_in serv;
bind(sockfd, (struct sockaddr*)&serv, sizeof(serv));
```

### 1.3 IPv6 Socket Address Structure
IPv6 socket address structure定义在`<netinet/in.h>`中.
```c
struct in6_addr {
  uint8_t s6_addr[16]; /* 128-bit IPv6 address */
}
#define SIN6_LEN /* required for compile-time tests */

struct sockaddr_in6 {
  uint8_t         sin6_len;      /* length of this struct (28) */
  sa_family_t     sin6_family;   /* AF_INET6 */
  in_port_t       sin6_port;     /* transport layer port */
  uint32_t        sin6_flowinfo; /* flow information, undefined */
  struct in6_addr sin6_addr;     /* IPv6 address */
  uint32_t        sin6_scope_id; /* set of interfaces for a scope */
};
```
补充:
* 若系统支持socket address structure中的长度成员, 则必须定义`SIN6_LEN`常量
* IPv6 family为`AF_INET6`, IPv4 family为`AF_INET`
* `sin6_flowinfo`分为两个字段: 低字节的20位为flow label, 高字节的12位为保留位
2. `sin6_scope_id`用于标示scope zone, 常用于link-local address的接口索引

### 1.4 New Generic Socket Address Structure
sockaddr_storage可放置任何大小的socket address, 定义在<netinet/in.h>:
```c
struct sockaddr_storage {
  uint8_t     ss_len;    /* length of this struct */
  sa_family_t ss_family; /* address family: AF_xxx value */
}
```
与sockaddr的差别:
1. `sockaddr_storage`提供最严格的的对齐要求
2. `sockaddr_storage`可容纳任何大小的socket address structure

### 1.5 Comparison of Socket Address Structures
![Comparison of various socket address structures](/images/Network/UNP/3-1-sock-addr-structs.gif)


## 2. Value-Result Arguments
所有socket function都会接收两个参数: socket address structure和其长度. 根据socket address structure传输的方向不同, 长度的传参方式也不同.

### 2.1 From Process to Kernel
`bind()`, `connect()`, 和`sendto()`会将指向socket address structure的指针和length作为参数. 以`connect()`为例:
```c
struct sockaddr_in serv;
connect(sockfd, (SA *)&serv, sizeof(serv));
```
结果如下:
![Socket address structure passed from process to kernel](/images/Network/UNP/3-2-sock-addr-struct-from-proc-to-kernel.gif)

### 2.2 From Kernel to Process: 
`accept()`, `recvfrom()`, `getsockname()`, 和`getpeername()`这四个函数将指向socket address structure的指针和指向length的指针作为参数, 以`getpeername()`为例:
```c
struct sockaddr_un cli;
socklen_t len;

len = sizeof(cli);
getpeername(UNIXfd. (SA *)&cli, &len);
```
结果如下:
![Socket address structure passed from kernel to process](/images/Network/UNP/3-2-sock-addr-struct-from-kernel-to-proc.gif)


## 3. Byte Ordering Functions
内存中有两种存储字节的方式: 以低序字节开头的little-endian byte order(小端字节序)和以高序字节开头的big-endian byte order(大端字节序). 以16-bit integer为例:
![Little-endian byte order and big-endian byte order for a 16-bit integer](/images/Network/UNP/3-3-little-and-big-endian-byte-order.gif)

不同的系统使用不同的字节序, 统称为host byte order(主机字节序). 但对于网络的发送方和接收方, 它们可能使用不同的字节序, 从而导致数据解析错误. 为此, 在发送和接收任何数据前都必须将系统中的host byte order转换为network byte order(网络字节序). network byte order采用big-endian byte order, 为方便byte order的转换, The POSIX Specification提供了以下函数:
```c
#include <netinet/in.h>

/* host byte order to network byte order(short or long) */
uint16_t htons(uint16_t host16bitvalue);
uint32_t htonl(uint32_t host32bitvalue);

/* network byte order to host byte order(short or long) */
uint16_t ntohs(uint16_t net16bitvalue);
uint32_t ntohl(uint32_t net32birvalue);
```
其中, **h**表示host, **n**表示network, **s**表示short(16-bit), **l**表示long(32-bit).  


## 4. Byte Manipulation Functions
操纵多字节字段的函数有两组: **b**开头的函数组和**mem**开头的函数组

### 4.1 Functions Whose Names Begin with b
自4.2BSD起, 几乎所有遵循POSIX.1的UNIX系统都包含以下函数:
```c
#include <string.h>

/* Write nbytes number of bytes to 0 at dest */
void bzero(void* dest, size_t nbytes);		

/* Copy nbytes bytes from src to dest */
void bcopy(const void* src, void* dest, size_t nbytes);		

/* Compare the two byte sequences p1 and p2 of nbytes bytes,
 * If they are equal or nbytes is zero, returns 0;
 * Otherwise, return non-zero.
 */
int bcmp(const void* p1, const void* p2, size_t nbytes);	
```

### 4.2 Functions Whose Names Begin with mem
mem开头的函数来自ANSI C standard, 所有支持ANSI C library的系统都可用以下函数:
```c
#include <string.h>

/* Set the len number of bytes to the value c at dest */
void* memset(void* dest, int c, size_t len);

/* Copy bytes number of bytes from src to dest */
void* memcpy(void* dest, const void* src, size_t nbytes);

/* Compare the first nbytes bytes of ptr1 to ptr2,
 * If they match, return 0; otherwise return non-zero
 */
int memcmp(const void* p1, const void* p2, size_t nbytes);
```
`memcmp()`对比的数据单位为unsigned char. 当p1的某个unsigned char比p2对应的unsigned char大, 则返回值大于0; 否则返回值小于0.


## 5. Address Conversion Functions
UNIX提供了两组函数负责将Internet address在ASCII string和network byte order value之间转换:
1. `inet_aton()`, `inet_ntoa()`, `inet_addr()`: 负责IPv4地址在dotted-decimal string(例如: `206.168.112.96`)和32-bit network byte order value之间的转换.
```c
#include <arpa/inet.h>

/* Convert the character string pointed to by strptr 
 * into 32-bit network byte ordered value 
 */
int inet_aton(const char* strptr, struct in_addr* addrptr);

/* Same as inet_aton(), return the 32-bit network byte ordered value */
int_addr_t inet_addr(const char* strptr);

/* Convert the 32-bit network byte ordered value to character string */
char* inet_ntoa(struct in_addr inaddr);
```
2. `inet_pton()`, `inet_ntop()`: 负责IPv4和IPv6地址在ASCII string和network byte ordered value之间转换.
```c
#include <arpa/inet.h>

/* Convert the presentation of address pointed to by strptr 
 * to the numeric address addrptr
 */
int inet_pton(int family, const char* strptr, void* addrptr);

/* Convert the numeric address addrptr to the presentation of 
 * address pointed to by strptr
 */
const char* inet_ntop(int family, const void* addrptr, char* strptr, size_t len);
```
其中, **p**表示presentation, **n**表示numeric. **family**支持`AF_INET`(IPv4)和`AF_INET6`(IPv6), 若family无法识别, 则返回报错且将`errno`置为`EAFNOSUPPORT`. `inet_ntop()`中的len参数表示strptr的长度, 若len过小, 则将`errno`置为`ENOSPC`. 
![Summary of address conversion functions](/images/Network/UNP/3-5-addr-conv-func.gif)


## 6. readn, writen and readline Functions
Stream socket(例如: TCP socket)拥有`read()`和`write()`函数, 用于接收和发送数据. 不同于文件I/O的read和write, stream socket的read和write可能会接收或发出比目标要求少的数据, 因为kernel中的buffer存在上限. 这就需要多次调用read和nonblocking write(blocking write不会出现这种情况). 以下函数会不断读取或写入数据, 直到数据被读取或写入完毕.
```c
ssize_t readn(int fd, void *ptr, size_t n)
{
  size_t  nleft;
  ssize_t nread;

  nleft = n;
  while (nleft > 0) {
    if ((nread = read(fd, ptr, nleft)) < 0) {
      if (nleft == n) return(-1); /* error, return -1 */
      else break; /* error, return amount read so far */
    } else if (nread == 0) {
      break; /* EOF */
    }
    nleft -= nread;
    ptr += nread;
  }
  return(n - nleft); /* return >= 0 */
}

ssize_t writen(int fd, const void *ptr, size_t n)
{
  size_t  nleft;
  ssize_t nwritten;

  nleft = n;
  while (nleft > 0) {
    if ((nwritten = write(fd, ptr, nleft)) < 0) {
      if (nleft == n) return(-1); /* error, return -1 */
      else break; /* error, return amount written so far */
    } else if (nwritten == 0) {
      break; /* EOF */ 
    }
    nleft -= nwritten;
    ptr   += nwritten;
  }
  return(n - nleft); /* return >= 0 */
}

ssize_t readline(int fd, void *vptr, size_t maxlen)
{
  ssize_t n, rc;
  char    c, *ptr;

  ptr = vptr;
  for (n = 1; n < maxlen; n++) {
again:
    if ((rc = read(fd, &c, 1)) == 1) {
      *ptr++ = c;
      if (c == '\n')
        break; /* newline is stored, like fgets() */
    } else if (rc == 0) {
      *ptr = 0;
      return(n - 1); /* EOF, n - 1 bytes were read */
    } else {
      if (errno == EINTR)
        goto again;
      return(-1);	/* error, errno set by read() */
    }
  }

  *ptr = 0; /* null terminate like fgets() */
  return(n);
}
/* end readline */

```
上述`readline()`每次都需调用`read()`读取单个字节, 导致效率低下. 修改后的`readline()`如下:
```c
static int  read_cnt;
static char *read_ptr;
static char read_buf[MAXLINE];

static ssize_t my_read(int fd, char *ptr)
{
  if (read_cnt <= 0) {
again:
    if ( (read_cnt = read(fd, read_buf, sizeof(read_buf))) < 0) {
      if (errno == EINTR)
        goto again;
      return(-1);
    } else if (read_cnt == 0)
      return(0);
    read_ptr = read_buf;
  }

  read_cnt--;
  *ptr = *read_ptr++;
  return(1);
}

ssize_t readline(int fd, void *vptr, size_t maxlen)
{
  ssize_t n, rc;
  char    c, *ptr;

  ptr = vptr;
  for (n = 1; n < maxlen; n++) {
    if ( (rc = my_read(fd, &c)) == 1) {
      *ptr++ = c;
      if (c == '\n')
        break; /* newline is stored, like fgets() */
    } else if (rc == 0) {
      *ptr = 0;
      return(n - 1); /* EOF, n - 1 bytes were read */
    } else
      return(-1); /* error, errno set by read() */
  }

  *ptr = 0; /* null terminate like fgets() */
  return(n);
}
```
上述`readline()`一次读取`MAXLINE`个字节, 因而效率提高.
