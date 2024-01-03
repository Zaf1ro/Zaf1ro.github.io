---
title: Name and Address Conversions
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: 2b71
date: 2019-12-22 10:03:42
keywords:
description:
---

## 1. Domain Name Syste (DNS)
DNS用于映射hostname和IP address. hostname可以是简单的solaris或freebsd, 或**FQDN**(fully qualified domain name), 例如solaris.unpbook.com.
FQDN也称为absolute name, 必须以句号结尾(punctuation mark), DNA用户通常会忽略最后的句号. 最后的句号用于通知resolver这是一个FQDN, 无需搜索可能的所有domain.

### 1.1 Resource Records
DNS中的entry被称为resource record(RR), 以下是几种常见的RR:
1. A: A record将hostname映射为32-bit IPv4 address. 对于host为freebsd, domain为unpbook.com, 其A record为: 
```sh
freebsd IN A    12.106.32.254
        IN AAAA 3ffe:b80:1f8d:1:a00:20ff:fea7:686b
        IN MX   5 freebsd.unpbook.com.
        IN MX   10 mailhost.unpbook.com.
```
2. AAAA: AAAA record将hostname映射为128-bit IPv6 address. **AAAA**表示4倍的32-bit address, 也就是128-bit address
3. PTR: PTR record将IP address映射为hostname. 例如: 对于freebsd host, 其两个PTR为`254.32.106.12.in-addr.arpa`和`b.6.8.6.7.a.e.f.f.f.0.2.0.0.a.0.1.0.0.0.d.8.f.1.0.8.b.0.e.f.f.3.ip6.arpa`
4. MX: MX record标注某个host作为mail exchanger. 一个host可有多个MX record, 每个MX record有不同preference value, 按照从小到大排序.
5. CNAME: canonical name, 将一个hostname映射为另一个hostname.

### 1.2 Resolvers and Name Server
**Name server**会运行network service, 保存DNS record, 并回应请求. 而被client和server用于与name server通信的工具称为**resolver**, 通常为`gethostbyname()`和`gethostbyaddr()`, 前者用于将hostname映射为IPv4 address, 后者用于将IPv4 address映射为hostname.
![Typical arrangement of clients, resolvers, and name servers](/images/Network/UNP/11-1-cli-resolver-and-name-svr.gif)

上图表示application, resolver和name server之间的关系. 对于用户来说, 只需要在application code中调用resolver APIs即可. Resolver code会读取系统中的configuration file决定从哪个name server获取record, local name server的IP address通常保存在`/etc/resolv.conf`文件中. Local name server接收到请求后, 如果回复准确答案, 则向更高级的name serber发送请求. 通常情况下, DNS请求和回复为UDP, 如果数据过大, 会自动切换为TCP.

### 1.3 DNS Alternatives
在不使用DNS的情况, 也可以通过**static host file**(通常为`/etc/hosts`文件), **NIS**(Network Information System)或**LDAP**(Lightweight Directory Access Protocol)获取hostname和IP address. 但尤其每个系统实现不用, 使用的方法也有所不同, 因此需要通过resolver functions作为统一解决方案.


## 2. gethostbyname Function
无论调用`connect()`还是`sendto()`, 都需要知道对端的IP address, 但IP address不好记忆, 尤其是IPv6 address, 且随时可能更改, 因此需要通过将hostname映射为对应的IP address.
```c
#include <netdb.h>

extern int h_errno;

struct hostent {
 char *h_name;       /* canonical name of host */
 char **h_aliases;   /* ptr to array of ptrs to alias names */
 int h_addrtype;     /* host address type: AF_INET */
 int h_length;       /* length of address: 4 */
 char **h_addr_list; /* ptr to array of ptrs with IPv4 addrs */
};

/**
 * @brief return a structure of hostent for the given hostname
 * @param name: a hostname or an IPv4 address.
 *        1. If name ia an IPv4 address, just copy name into 
 *           the h_name field and h_addr_list[0] field of hostent
 *        2. If name doesn't end in a dot, the current domain 
 *           and its parent will be searched
 *        3. If name ends in a dot, only the current domain will
 *           be searched
 */
struct hostent *gethostbyname(const char *name);
```
`gethostbyname()`只返回IPv4 address, 因此该函数会随着IPv6的普及而逐渐消失, 推荐使用`getaddrinfo()`代替. 以下是**hostent**的结构图:
![hostent structure and the information it contains](/images/Network/UNP/11-2-hostent-struct.gif)

其中, `h_name`表示host的canonical name. 例如: 当对`solaris`调用`gethostbyname()`时, 其FQDN为`solaris.unpbook.com`, 也就是其canonical name. 不同于其他socket function, 出错时`gethostbyname()`不会设置errno, 而是在h_errno上设置以下常量:
* HOST_NOT_FOUND: 找不到host
* TRY_AGAIN: name server发生临时错误, 需要重新发送请求
* NO_RECOVERY: name server发生不可恢复的错误
* NO_DATA: host存在, 但name server中没有对应的IP address, 例如hostname只有MX record


## 3. gethostbyaddr Function
`gethostbyaddr()`用于将IPv4 address映射为hostname, 与`gethostbyname()`功能相反.
```c
#include <sys/socket.h>

/**
 * @brief return a structure of hostent for the  
 *        given host address `addr` of lengh `len`
 *        and address type `type`
 * @param addr a pointer to an in_addr structure 
 *        containing IPv4 address
 * @param len the size of in_addr structure
 * @param type AF_INET
 */
struct hostent *gethostbyaddr(const void *addr, socklen_t len, 
                              int type);
```


## 4. getservbyname and getservbyport Functions
Service和host一样, 都可以通过name标记, 每个service都有自己的name和port number, 因此查找一个service即可通过其name, 也可以通过port number.
```c
#include <netdb.h>

struct servent {
  char *s_name;     /* official service name */
  char **s_aliases; /* alias list */
  int s-port;       /* port number, network-byte order */
  char *s_proto;    /* protocol to use */
};

/**
 * @brief return a servent structure that matches 
 *        the service name and protocol type
 * @param name service name
 * @param proto If proto is NULL, any protocol will
 *        be matched
 */
struct servent *getservbyname(const char *name, const char *proto);

/**
 * @brief return a servent structure that matches 
 *        the port number and protocol type
 * @param port: port number
 * @param proto: same as proto in getservbyname()
 */
struct servent *getservbyport(int port, const char *proto);
```
以下程序使用`gethostbyname()`和`getservbyname()`来实现一个简易client:
```c
/* first command-line argument: hostname 
 * second command-line argument: service name
 */
int main(int argc, char **argv)
{
  int                sockfd, n;
  char               recvline[MAXLINE + 1];
  struct sockaddr_in servaddr;
  struct in_addr     **pptr;
  struct in_addr     *inetaddrp[2];
  struct in_addr     inetaddr;
  struct hostent     *hp;
  struct servent     *sp;

  if (argc != 3)
    err_quit("usage: daytimetcpcli1 <hostname> <service>");

  /* list all IP addresses for the hostname */
  if ( (hp = gethostbyname(argv[1])) == NULL) {
    if (inet_aton(argv[1], &inetaddr) == 0) {
      err_quit("hostname error for %s: %s", argv[1], 
               hstrerror(h_errno));
    } else {
      inetaddrp[0] = &inetaddr;
      inetaddrp[1] = NULL;
      pptr = inetaddrp;
    }
  } else {
    pptr = (struct in_addr **) hp->h_addr_list;
  }

  /* get the port number of the server */
  if ( (sp = getservbyname(argv[2], "tcp")) == NULL)
    err_quit("getservbyname error for %s", argv[2]);

  for ( ; *pptr != NULL; pptr++) {
    sockfd = Socket(AF_INET, SOCK_STREAM, 0);
    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = sp->s_port;
    memcpy(&servaddr.sin_addr, *pptr, sizeof(struct in_addr));
    printf("trying %s\n", Sock_ntop((SA *) &servaddr, 
           sizeof(servaddr)));

    /* if connect succeeds, terminate the loop */
    if (connect(sockfd, (SA *) &servaddr, sizeof(servaddr)) == 0)
      break;  /* success */
    err_ret("connect error");
    close(sockfd);
  }

  /* no call to connect succeeded */
  if (*pptr == NULL) err_quit("unable to connect");

  while ( (n = Read(sockfd, recvline, MAXLINE)) > 0) {
    recvline[n] = 0;  /* null terminate */
    Fputs(recvline, stdout);
  }
  exit(0);
}
```


## 5. getaddrinfo Function
`gethostbyname()`和`gethostbyaddr()`不支持IPv4, 如果需要解析IPv6 address, 需要使用`getaddrinfo()`实现name-to-address和service-to-port, 定义于POSIX specification.
```c
struct addrinfo {
  int             ai_flags;      /* additional options using OR */
  int             ai_family;     /* AF_xxx */
  int             ai_socktype;   /* SOCK_xxx */
  int             ai_protocol;   /* 0 or IPPROTO_xxx for IPv4 and IPv6 */
  socklen_t       ai_addrlen;    /* length of ai_addr */
  struct sockaddr *ai_addr;      /* ptr to socket address structure */
  char            *ai_canonname; /* ptr to canonical name for host */
  struct addrinfo *ai_next;      /* ptr to next structure in linked list
*/
};

/**
 * @brief return one or more addrinfo structures, 
 *        each of which contains an Internet 
 *        address pointed to by `result`
 * @param hostname a hostname or an address string
 *        (dotted-decimal for IPv4 or a hex string 
 *        for IPv6)
 * @param service a service name or a decimal port 
 *        number string
 * @param hints a null pointer or a pointer to an 
 *        addrinfo structure that the caller fills 
 *        in with hints about the types of 
 *        information the caller wants returned
 */
int getaddrinfo(const char *hostname, const char *service,
                const struct addrinfo *hints, 
                struct addrinfo **result);
```
其中, `ai_flags`的可选项如下:
* AI_PASSIVE: 若设置该flag, 则result返回的address应能用于`bin()`, `listen()`, 或`accept()`, 也就是说, 该address用于passive socket.
* AI_NUMERICHOST: 让`getaddrinfo()`返回canonical name
* AI_NUMERICSERV: hostname参数必须为address string, 不能为hostname
* AI_V4MAPPED: 该option一般与`ai_family`设置为AF_INET6一同使用, 保证AAAA record无法找到时返回A record. 
* AI_ALL: 与AI_V4MAPPED一同使用, 返回hostname下的A record和AAAA record.
* AI_ADDRCONFIG: 若存在多个端口, 只返回给定IP version的IP address.

`hints`参数中除了ai_flags, 还可修改其他属性:
* ai_family
* ai_socktype
* ai_protocol

若`hints`为NULL, 则ai_flags, ai_socktype, ai_protocol都为0, 且ai_family为AF_UNSPEC.
`getaddrinfo()`返回一个链表, 其中每个node都表示一个addrinfo structure, 以下两种情况会导致返回多个nodes:
1. hostname下存在多个addresses, 每个addrinfo structure包含一个address
2. service下存在多个socket type, 每个addrinfo strcuture包含一种socket type

假设某一host下有两个IP address, 有4个addrinfo structures返回:
* 第一个IP address且socket type为`SOCK_STREAM`
* 第一个IP address且socket type为`SOCK_DGRAM`
* 第二个IP address且socket type为`SOCK_STREAM`
* 第二个IP address且socket type为`SOCK_DGRAM`

![Example of information returned by getaddrinfo](/images/Network/UNP/11-2-return-of-getaddrinfo.jpg)

若hints参数中设置了AI_CANONNAME flag, 返回的第一个addrinfo中的`ai_canonname`会返回host的canonical name. hints参数中的ai_protocol可选项如下:
* IPPROTO_IP: 0
* IPPROTO_IPV4: 4
* IPPROTO_IPV6: 41
* IPPROTO_UDP: 17
* IPPROTO_TCP: 6

ai_socktype的可选项如下:
* 0: any type of socket type can be returned
* SOCK_STREAM: connection-based byte stream
* SOCK_DGRAM: connectionless, unreliable datagram

以下是不同service和ai_socktype下addrinfo structure的返回数量:

| ai_socktype | TCP only | UDP only | TCP and UDP |
|:----:|:----:|:----:|:----:|
| 0 | 1 | 1 | 2 |
| SOCK_STREAM | 1 | error | 1 |
| SOCK_DGRAM | error | 1 | 1 |

`getaddrinfo()`主要用于以下方法:
* 可被TCP或UDP client用于解析hostname和service. TCP client会调用`socket()`和`connect()`遍历所有IP addresses, 直到成功连接某个IP address; UDP client也可以使用`sendto()`或`connect()`尝试向多个IP address发送请求.
* 若client只需要处理特定socket type, 则可以通过hint参数中的ai_socktype标记socket type
* server一般会指定service, 并将hostname置为NULL, 且在hints参数中标记`AI_PASSIVE` flag, 返回的socket address structure应该包含`INADDR_ANY`(Ipv4)或`IN6ADDR_ANY_INIT`(IPv6)
* 若server调用`recvfrom()`获得client的socket address structure, 其中ai_addrlen表示大小
* 若server只处理特定socket type, 可使用hints参数中的ai_socktype指定socket type
* TCP和UDP server可使用`select()`或`poll()`对`getaddrinfo()`返回的每个IP address分别创建listening socket


## 6. gai_strerror Function
`gai_strerror()`可将`getaddrinfo()`返回的错误值转换为响应字符串
```c
#include <netdb.h>

/**
 * @brief address and name information error description
 * @param error shall be one of the following values:
 *        * EAI_AGAIN: Temporary failure in name resolution
 *        * EAI_BADFLAGS: Invalid value for ai_flags
 *        * EAI_FAIL: Unrecoverable failure in name resolution
 *        * EAI_FAMILY: ai_family not supported
 *        * EAI_MEMORY: Memory allocation failure
 *        * EAI_NONAME: hostname or service not provided, 
 *          or not known
 *        * EAI_OVERFLOW: User argument buffer overflowed
 *        * EAI_SERVICE: service not supported for ai_socktype
 *        * EAI_SOCKTYPE: ai_socktype not supported
 *        * EAI_SYSTEM: System error returned in errno
 */
const char *gai_strerror (int error);
```


## 7. freeaddrinfo Function
`getaddrinfo()`中的addrinfo structure是动态分配的, 这时需要调用`freeaddrinfo()`释放内存.
```c
#include <netdb.h>

/**
 * @brief free the memory that was allocated for 
 *        the dynamically allocated linked list
 * @param ai point to the first addrindfo structure 
 *        returned by getaddrinfo(). All the structures
 *        in the linked list are freed, along with any 
 *        dynamic storaged pointed to by other structures
 *        (socket address structure and canonical hostname)
 */
void freeaddrinfo (struct addrinfo *ai);
```


## 8. getaddrinfo Function: IPv6
![Summary of getaddrinfo and its actions and results](/images/Network/UNP/11-2-summary-of-getaddrinfo.jpg)

* `getaddrinfo()`主要应对两种输入: socket address structure的类型, 需要从DNS或其他数据库中搜索的record类型
* `hints`参数中的ai_family表示返回的socket address structure类型. 若ai_family为AF_INET, 则返回的addrinfo structure中的ai_addr不能为sockaddr_in6; 同理, 若ai_family为AF_INET6, 则不能返回sockaddr_in.
* 若`hints`参数中的ai_family为`AF_UNSPEC`, 则返回所有查到的protocol family
* 若ai_flags设置了AI_PASSIVE且没有设置hostname, 则在sockaddr_in6中返回IPv6 wildcard address(IN6ADDR_ANY_INIT), sockaddr_in structure中返回 IPv4 wildcard address(INADDR_ANY)
* hints参数中的ai_family和ai_flags用于标识搜索DNS中的record类型和返回的地址类型, 如上图表格所示.
* hostname可谓IPv6 hex string或IPv4 dotted-decimal string, 但必须与ai_family匹配: IPv6 hex string不能与AF_INET一起输入, IPv4 dotted-decimal string和AF_INET6不能一起输入, 但AF_UNSPEC可以与任何IP address组合.


## 9. getaddrinfo Function: Examples
假设某程序使用`getaddrinfo()`, 并可接收以下参数: hostname, service name, address family, socket type, AI_CANONNAME flag. 其中, `-f`表示address family, `-c`表示canonical name, `-h`表示hostname, `-s`表示service name, `-t`表示socket type.
```sh
% testga -f inet -c -h freebsd4 -s domain
socket (AF_INET, SOCK_DGRAM, 17), ai_canonname = freebsd4.unpbook.com
       address: 135.197.17.100:53
socket (AF_INET, SOCK_DGRAM, 17)
       address: 172.24.37.94:53
socket (AF_INET, SOCK_STREAM, 6), ai_canonname = freebsd4.unpbook.com
       address: 135.197.17.100:53
socket (AF_INET, SOCK_STREAM, 6)
       address: 172.24.37.94:53
```
也可以指定socket type来获取host上的所有IPv4 addresses:
```sh
% testga -f inet -t stream -h gateway.tuc.noao.edu -s daytime
socket (AF_INET, SOCK_STREAM, 6)
       address: 140.252.108.1:13
socket (AF_INET, SOCK_STREAM, 6)
       address: 140.252.1.4:13
socket (AF_INET, SOCK_STREAM, 6)
       address: 140.252.104.1:13
```
通过不指定address family, 可获取host上的所有IPv4和IPv6 address:
```sh
freebsd % testga -h aix -s ftp -t stream
socket (AF_INET6, SOCK_STREAM, 6)
       address: [3ffe:b80:1f8d:2:204:acff:fe17:bf38]:21
socket (AF_INET, SOCK_STREAM, 6)
       address: 192.168.42.2:21
```
通过设置AI_PASSIVE flag可获取wildcard address:
```sh
% testga -p -s 8888 -t stream
socket (AF_INET6, SOCK_STREAM, 6)
       address: [: :]: 8888
socket (AF_INET, SOCK_STREAM, 6)
       address: 0.0.0.0:8888
```


## 10. host_serv Function
`host_serv()`可让调用者在不必生成hints structure的前提下调用`getaddrinfo()`
```c
struct addrinfo *host_serv(const char *host, const char *serv, 
                           int family, int socktype) 
{
  int    n;
  struct addrinfo hints, *res;

  bzero(&hints, sizeof(struct addrinfo));
  hints.ai_flags = AI_CANONNAME;  /* always return canonical name */
  hints.ai_family = family; /* AF_UNSPEC, AF_INET, AF_INET6, etc. */
  hints.ai_socktype = socktype; /* 0, SOCK_STREAM, SOCK_DGRAM, etc. */

  if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
    return(NULL);

  return(res);	/* return pointer to first on linked list */
}
```


## 11. tcp_connect Function
tcp_connect()可通过hostname获取server IP address并建立连接.
```c
int tcp_connect(const char *host, const char *serv)
{
  int             sockfd, n;
  struct addrinfo hints, *res, *ressave;

  bzero(&hints, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
    err_quit("tcp_connect error for %s, %s: %s", host, serv, 
              gai_strerror(n));
  ressave = res;

  do {
    sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sockfd < 0)
      continue; /* ignore this one */

    if (connect(sockfd, res->ai_addr, res->ai_addrlen) == 0)
      break;  /* success */

    Close(sockfd);  /* ignore this one */
  } while ( (res = res->ai_next) != NULL);

  if (res == NULL)  /* errno set from final connect() */
    err_sys("tcp_connect error for %s, %s", host, serv);

  freeaddrinfo(ressave);

  return sockfd;
}
```


## 12. tcp_listen Function
```c
int tcp_listen(const char *host, const char *serv, 
               socklen_t *addrlenp)
{
  int       listenfd, n;
  const int on = 1;
  struct addrinfo	hints, *res, *ressave;

  bzero(&hints, sizeof(struct addrinfo));
  hints.ai_flags = AI_PASSIVE;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
    err_quit("tcp_listen error for %s, %s: %s", host, serv, 
              gai_strerror(n));
  ressave = res;

  do {
    listenfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (listenfd < 0)
      continue; /* error, try next one */

    Setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
    if (bind(listenfd, res->ai_addr, res->ai_addrlen) == 0)
      break;  /* success */

    Close(listenfd);  /* bind error, close and try next one */
  } while ( (res = res->ai_next) != NULL);

  if (res == NULL)  /* errno from final socket() or bind() */
    err_sys("tcp_listen error for %s, %s", host, serv);

  Listen(listenfd, LISTENQ);

  if (addrlenp)
    *addrlenp = res->ai_addrlen;  /* return size of protocol address */

  freeaddrinfo(ressave);

  return(listenfd);
}
```


## 13. udp_client Function
```c
int udp_client(const char *host, const char *serv, SA **saptr, 
               socklen_t *lenp)
{
  int    sockfd, n;
  struct addrinfo	hints, *res, *ressave;

  bzero(&hints, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_DGRAM;

  if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
    err_quit("udp_client error for %s, %s: %s", host, serv, 
             gai_strerror(n));
  ressave = res;

  do {
    sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sockfd >= 0)
      break;  /* success */
  } while ( (res = res->ai_next) != NULL);

  if (res == NULL)  /* errno set from final socket() */
    err_sys("udp_client error for %s, %s", host, serv);

  *saptr = Malloc(res->ai_addrlen);
  memcpy(*saptr, res->ai_addr, res->ai_addrlen);
  *lenp = res->ai_addrlen;

  freeaddrinfo(ressave);

  return(sockfd);
}
```


## 14. udp_connect Function
```c
int udp_connect(const char *host, const char *serv)
{
  int sockfd, n;
  struct addrinfo hints, *res, *ressave;

  bzero(&hints, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_DGRAM;

  if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
    err_quit("udp_connect error for %s, %s: %s", host, serv, 
              gai_strerror(n));
  ressave = res;

  do {
    sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sockfd < 0)
      continue; /* ignore this one */

    if (connect(sockfd, res->ai_addr, res->ai_addrlen) == 0)
      break;  /* success */

    Close(sockfd);  /* ignore this one */
  } while ( (res = res->ai_next) != NULL);

  if (res == NULL)  /* errno set from final connect() */
    err_sys("udp_connect error for %s, %s", host, serv);

  freeaddrinfo(ressave);

  return(sockfd);
}
```


## 15. udp_server Function
```c
int
udp_server(const char *host, const char *serv, socklen_t *addrlenp)
{
  int sockfd, n;
  struct addrinfo hints, *res, *ressave;

  bzero(&hints, sizeof(struct addrinfo));
  hints.ai_flags = AI_PASSIVE;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_DGRAM;

  if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
    err_quit("udp_server error for %s, %s: %s", host, serv, 
              gai_strerror(n));
  ressave = res;

  do {
    sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sockfd < 0)
      continue; /* error - try next one */

    if (bind(sockfd, res->ai_addr, res->ai_addrlen) == 0)
      break;  /* success */

    Close(sockfd);  /* bind error - close and try next one */
  } while ( (res = res->ai_next) != NULL);

  if (res == NULL)  /* errno from final socket() or bind() */
    err_sys("udp_server error for %s, %s", host, serv);

  if (addrlenp) /* return size of protocol address */
    *addrlenp = res->ai_addrlen;

  freeaddrinfo(ressave);

  return(sockfd);
}
```


## 16. getnameinfo Function
```c
#include <netdb.h>

/**
 * @brief inverse of getaddrinfo(), convert a socket 
 *        address to a corresponding host and service
 * @param addr pointer to a socket address structure
 * @param addrlen size of addr
 * @param host pointer to caller-allocated buffer, 
 *        NULL for no hostname
 * @param serv pointer to caller-allocated buffer, 
 *        NULL for no service name
 * @param flags modify the behavior of getnameinfo():
 *        * NI_NAMEREQD: an error is returned if the 
 *          hostname cannot be determined
 *        * NI_DGRAM: the service is datagram based 
 *          rather than stream based
 *        * NI_NOFQDN: only return the hostname part
 *          of the fully qualified domain name for 
 *          local hosts
 *        * NI_NUMERICHOST: return the numeric form 
 *          of hostname
 *        * NI_NUMERICSERV: return the numeric form 
 *          of service address
 */
int getnameinfo(const struct sockaddr *addr, 
      socklen_t addrlen, char *host, socklen_t hostlen,
      char *serv, socklen_t servlen, int flags);
```


## 17. Re-entrant Functions
Reentrant function意味着函数运行中途被打断后不会影响之前的程序运转. reentrant需要遵循以下几个原则:
1. 尽量不要使用global和static变量. 尽管有方法防止global和static变量影响程序, 但有时也会造成不可知的影响
2. 运行时不可修改代码
3. 程序内不可运行non-reentrant function

`gethostbyname()`和`gethostbyaddr()`都不是re-entrant functions, 因为这两个函数共享static variable:
```c
static struct hostent host;  /* result stored here */

struct hostent *
gethostbyname(const char *hostname)
{
  /* call DNS functions for A record */
  /* fill in host structure */
  return (&host) ;
}

struct hostent *
gethostbyaddr(const char *addr, socklen_t len, int family)
{
  /* call DNS functions for PTR query in in-addr.arpa domain */
  /* fill in host structure */
  return (&host);
}
```
假设进程运行`gethostbyname()`时被signal打断, signal handler中运行`gethostbyaddr()`导致`host`变量被覆盖, 造成reentrancy problem. 关于reentrant function的总结如下:
* `gethostbyname()`, `gethostbyaddr()`, `getservbyname()`, `getservbyport()`为non-renentrant function, 因为使用static structure.
* 部分系统为以上4个函数提供了reentrant functions, 以`_r`为后缀
* `inet_pton()`和`inet_ntop()`为reentrant functions
* `inet_ntoa()`为non-reentrant function, 部分UNIX系统会提供reentrant version
* `getnameinfo()`只有在调用reentrant function时才可能为reentrant function
* `errno`是一个线程共享的global variable, 因此需要在signal handler开始时保存errno, 退出时恢复errno


## 18. gethostbyname_r and gethostbyaddr_r Functions
Linux和Solaris都提供了name-to-address和address-toname的reentrant functions:
```c
int gethostbyname_r(const char *hostname, struct hostent *result, 
                    char *buf, size_t buflen, int *h_errnop);

int gethostbyaddr_r(const void *addr, socklen_t len, int type,
                    struct hostent *result, char *buf, 
                    size_t buflen, int *h_errnop);
```
可以看到, 这两个functions都多了很多参数. `buf`由调用者申请空间, 用于保存canonical hostname, `buflen`为buf的大小. 虽然没有规定buf应为多少, 但通常设置为8192 bytes可满足绝大多数hostname; 当发生错误时, 错误码保存在`h_errnop`. 需要注意的是, 并不是所有系统支持reentrancy的`gethostbyname()`和`gethostbyaddr()`, UNIX 98和POSIX specification中这两个function不需要thread-safe或reentrant. 


## 19. Obsolete IPv6 Address Lookup Functions
### 19.1 RES_USE_INET6 Constant
由于`gethostbyname()`无法指定address family, 所以引入**RES_USE_INET6** constant来指定address family. 开启RES_USE_INET6后, `gethostbyname()`会优先搜索AAAA record, 若没有AAAA record, 再查看A record. 由于`hostent`只有一个address length, 所以`gethostbyname()`只能返回IPv6或IPv4 address. RES_USE_INET6也可以返回IPv4-mapped IPv6 adddress.

### 19.2 gethostbyname2 Function
```c
#include <sys/socket.h>
#include <netdb.h>

/**
 * @brief same as gethostbyname(), but permit to
 *        specify address family
 * @param af address family, AF_INET or AF_INET6
 */
struct hostent *gethostbyname2(const char *name, int af);
```

### 19.3 getipnodebyname Function
RES_USE_INET6和`gethostbyname2()`已在RFC 2553废弃, 因为RES_USE_INET6是一个global constant. 因此引入`getipnodebyname()`解决IPv6 address问题.
```c
#include <sys/socket.h>
#include <netdb.h>

/**
 * @brief return a pointer to the hostent structure
 * @param af: same as hints.ai_family in getaddrinfo()
 * @param flags: same as hints.ai_flags in getaddrinfo()
 * @return the return value is dynamically allocated, must be 
 *         freed with freehostent()
 */
struct hostent *getipnodebyname(const char *name, int af,
                                int flags, int *error_num);

struct hostent *getipnodebyaddr(const void *addr, size_t len,
                                int af, int *error_num);
```
`getipnodebyname()`和`getipnodebyaddr()`已在RFC 3493废弃.


## 20. Other Networking Information
上述所有函数主要围绕4类信息: host. network, protocol, service. 这4类信息都保存在各自文件中, 可通过以下函数获取:
1. getXXXent functions: 打开并读取文件中的一个entry
2. setXXXent functions: 打开并回到文件头部
3. endXXXent functions: 关闭文件

```c
struct hostent *gethostent(void);
void sethostent(int stayopen);
void endhostent(void);

struct servent *getservent(void);
void setservent(int stayopen);
void endservent(void);

struct netent *getnetent(void);
void setnetent(int stayopen);
void endnetent(void);

struct protoent *getprotoent(void);
void setprotoent(int stayopen);
void endprotoent(void);
```
每个函数都定义了自己的structure: hostent, netent, protoent, servent. 除了get, set, end functions, 还有一类函数称为keyed lookup functions, 其名字一般为`getXXXbyYYY`, keyed lookup function不会返回文件中的每个entry, 而是根据参数的要求匹配相应的entry.

| Information | Data file | Structure | Keyed lookup functions |
| Hosts | /etc/hosts | hostent | gethostbyaddr, gethostbyname |
| Networks | /etc/networks | netent | getnetbyaddr, getnetbyname |
| Protocols | /etc/protocols | protoent | getprotobyname, getprotobynumber |
| Services | /etc/services | servent | getservbyname, getservbyport |

使用DNS的条件如下:
1. host和network需要通过网络发送DNS请求获取, protocl和service则需要通过本机文件获取. 
2. 当需要获取host和network时, 只能通过keyed lookup function查询. 而不能用`gethostent()`获取
