---
title: IPv4 and IPv6 Interoperability
abbrlink: b4e
date: 2019-12-31 09:02:04
category:
  - Network
  - UNP
tag:
  - Network
keywords:
description:
---

## 1. Introduction
随着Internet的发展, IPv4逐渐被IPv6取代. 在此期间, 使用IPv4的应用会和使用IPv6的应用并行发展, 并共享网络设备. 因此, 一个client application必须同时支持IPv4和IPv6 server; Server application也必须支持IPv4和IPv6 client. 本章假设所有host和router都支持**dual-stack**, 也就是说, host和router拥有完整的IPv4 protocol stack和IPv6 protocol stack. 


## 2. IPv4 Client, IPv6 Server
得益于IPv4-mapped IPv6 address, dual-stacks的IPv6 server可处理IPv4和IPv6的client, 如下图:
![IPv6 server on dual-stack host serving IPv4 and IPv6 clients](/images/Network/UNP/12-2-ipv6-svr.gif)

上图中的IPv4 client和IPv6 client所发出的datagram信息如下:
* IPv4: 发送IPv4 datagram, Ethernet header中**type**为`0x8000`, TCP header的**destination port**为`9999`, IPv4 header中**destination IP address**为`206.62.226.42`
* IPv6: 发送IPv6 datagram, Ethernet header中**type**为`0x86dd`, TCP header中**destination port**为`9999`, IPv6 header中**destination IP address**为`5f1b:df00:ce3e:e200:20:800:2b37:6426`

当server host收到datagram后, 检测到destination socket为IPv6 socket, 会自动将IPv4 source address转换为IPv4-mapped IPv6 address, 因此对于socket来说, 两个datagram的source IP address都为IPv6. 以下是IPv4 TCP client与IPv6 server通讯的步骤:
1. 启动IPv6 server, 创建IPv6 listening socket, 并绑定wildcard address
2. 虽然server拥有A record和AAAA record, 但IPv4 client只会调用`gethostbyname()`获取server的A record
3. client调用`connect()`发送IPv4 STN, 尝试与server建立连接
4. server host收到IPv4 SYN后会传给IPv6 listening socket, 并设置flag通知socket该connection使用IPv4-mapped IPv6 address, 并回复IPv4 SYN/ACK. 当three-way handshake完成后, `accept()`返回IPv4-mapped IPv6 address. 
5. 当server通过IPv4-mapped IPv6 address向client发送数据时, 其IP stack会将destination address转换为IPv4 address. 因此IPv4 client与server之间的传输都是通过IPv4 datagram
6. 除非server检查IPv6 address, 否则server不会察觉到与IPv4 client通信; 同理, IPv4 client也不会察觉到与IPv6 server通信.,

![Processing of received IPv4 or IPv6 datagrams, depending on type of receiving socket](/images/Network/UNP/12-2-proc-of-ipv4-ipv6-datagram.gif)

* 当IPv4 socket接收或发送IPv4 datagram时, kernel不会做任何处理
* 当IPv6 socket接收或发送IPv6 datagram时, kernel不会做任何处理
* 当IPv6 socket接收IPv4 datagram时, kernel会将source IPv4 address转换为IPv4-mapped IPv6 address; 向IPv4 client发送数据时, kernel会将IPv4-mapped IPv6 address转换为IPv4 address
* IPv6 address无法转换为IPv4 address, 因此IPv4 socket无法接收IPv6 datagram

dual-stack host中的listenin socket应遵循以下规则:
1. listening IPv4 socket只接收IPv4 client的connection
2. 如果server host有listening IPv6 socket, 且socket没有设置`IPV6_V6ONLY` socket option, 则socket可接受IPv4 client或IPv6 client. 对于IPv4 client, server host会自动转换为IPv4-mapped IPv6 address
3. 若server的listening IPv6 socket只绑定了IPv6 address, 或设置了IPV6_V6ONLY socket option, 则socket只能接收IPv6 client connection


## 3. IPv6 Client, IPv4 Server
以下是IPv6 TCP client与IPv4 server通信的过程:
1. IPv4 server所在的host只支持IPv4 address, 且运行一个IPv4 listening socket
2. IPv6 client调用`getaddrinfo()`获取server IP address, 其中`hints.ai_family`为**AF_INET6**, `hints.ai_flags`中设置**AI_V4MAPPED**. 由于server只有A record, 因此返回IPv4-mapped IPv6 address
3. IPv6 client调用`connect()`向IPv4-mapped IPv6 address发起连接, kernel会自动将destination address转换为IPv4 address, 因此server接收到IPv4 SYN
4. server回复IPv4 SYN/ACK, 成功建立连接

![Processing of client requests, depending on address type and socket type](/images/Network/UNP/12-3-proc-of-cli-req.gif)

* IPv4 TCP/UDP socket在`connect()`/`snedto()`中指定IPv4 address时, 不做任何处理
* IPv6 TCP/UDP socket在`connect()`/`sendto()`中指定IPv6 address时, 不做任何处理
* IPv6 TCP/UDP socket在`connect()`/`sendto()`中指定IPv4-mapped IPv6时, kernel会将source IPv6 address转换为IPv4 address
* IPv4 socket无法在`connect()`/`sendto()`中指定IPv6 address

以下是IPv4/IPv6 client与server通信的各种情况:

|  | IPv4 server (IPv4-only host, A only) | IPv6 server (IPv6-only host, AAAA only) | IPv4 server (dual-stack host, A and AAAA) | IPv6 server (dual-stack host, A and AAAA) |
|:---:|:---:|:---:|:---:|:---:|
| IPv4 client, IPv4-only host | IPv4 | (no) | IPv4 | IPv4 |
| IPv6 client, IPv6-only host | (no) | IPv6 | (no) | IPv6 |
| IPv4 client, dual-stack host | IPv4 | (no) | IPv4 | IPv4 |
| IPv6 client, dual-stack host | IPv4 | IPv6 | (no*) | IPv6 |

实际上, 没有设备只支持IPv6, 因此所有`(no)`的情况是不存在的. 但存在一个特例, 就是`(no*)`: 当client选择使用AAAA record并发送IPv6 datagram时, 无法建立连接; 当client选择使用A record并发送IPv4-mapped IPv6 address时, 会顺利建立连接.


## 4. IPv6 Address-Testing Macros
UNIX提供了一些函数, 可以帮助IPv6 application分辨对端为IPv6 address或IPv4-mapped IPv6 address, 和IPv6 address的其他属性.
```c
#include <netinet/in.h>

/* :: */
int IN6_IS_ADDR_UNSPECIFIED(const struct in6_addr *aptr);

/* ::1 */
int IN6_IS_ADDR_LOOPBACK(const struct in6_addr *aptr);

/* ff00::/8 */
int IN6_IS_ADDR_MULTICAST(const struct in6_addr *aptr);

/* fe80::/10 */
int IN6_IS_ADDR_LINKLOCAL(const struct in6_addr *aptr);

/* fec0::/10 */
int IN6_IS_ADDR_SITELOCAL(const struct in6_addr *aptr);

/* ::ffff/96 */
int IN6_IS_ADDR_V4MAPPED(const struct in6_addr *aptr);

/* ::ffff/96 */
int IN6_IS_ADDR_V4COMPAT(const struct in6_addr *aptr);

/* ff01::/16 */
int IN6_IS_ADDR_MC_NODELOCAL(const struct in6_addr *aptr);

/* ff02::/16 */
int IN6_IS_ADDR_MC_LINKLOCAL(const struct in6_addr *aptr);

/* ff05::/16 */
int IN6_IS_ADDR_MC_SITELOCAL(const struct in6_addr *aptr);

/* ff08::/16 */
int IN6_IS_ADDR_MC_ORGLOCAL(const struct in6_addr *aptr);

/* ff0e::/16 */
int IN6_IS_ADDR_MC_GLOBAL(const struct in6_addr *aptr);
```


## 5. Source Code Portability
绝大多数application都是用IPv4. 若需要将application切换为IPv6, 则需要考虑对端能否接收IPv6 datagram. 最直接方法即使用**#ifdefs**判断是够可用IPv6, 问题在于后续维护代码时需要很小心.
把程序改为protocl-independent是一种更好的方法. 首先移除`gethostbyname()`和`gethostbyaddr()`, 使用`getaddrinfo()`和`getnameinfo()`代替, 这样就可以获取socket address structure, 并使用`bind()`, `connect()`, `recvfrom()`等函数操作. socket的任何接收发送操作对于上层程序来说, 是透明的. 
当编译程序时, 有些host支持IPv4和IPv6时, 而有些host只支持IPv4, 这时就需要对host网络兼容性做一些判断: 可通过name server获取所有AAAA records并尝试建立连接, 若全部失败, 再尝试连接A record.
