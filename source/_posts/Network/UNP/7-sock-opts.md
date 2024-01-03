---
title: Socket Options
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: abba
date: 2019-12-08 09:21:48
keywords:
description:
---

## 1. getsocketopt and setsockopt Functions
```c
#include <sys/socket.h>

/**
 * @brief get option for the socket referred to by the file 
 *        descriptor sockfd
 * @param level: the general code or some protocol-specific
 *        code (e.g. IPv4, IPv6, TCP)
 * @param optname: the name of socket option
 * @param optval: a pointer to a variable from which the new
 *        value of the option
 */
int getsockopt(int sockfd, int level, int optname, void *optval, 
               socklen_t *optlen);

/**
 * @brief set option for the socket referred to by the file
 *        descriptor sockfd
 */
int setsockopt(int sockfd, int level, int optname, const void *optval,
               socklen_t optlen);
```
以下是`getsockopt()`和`setsockopt()`所能操作的所有socket options:

| level    | optname      | get    | set    | Description | Flag | Datatype |
|:--------:|:------------:|:---:   | :---:  |:-----------:|:----:|:--------:|
|SOL_SOCKET|SO_BROADCAST  |&#x2714;|&#x2714;|Permit sending of broadcasr datagram     |&#x2714;|int|
|          |SO_DEBUG      |&#x2714;|&#x2714;|Enable debug tracing                     |&#x2714;|int|
|          |SO_DONTROUTE  |&#x2714;|&#x2714;|Bypass routing table lookup              |&#x2714;|int|
|          |SO_ERROR      |&#x2714;|        |Get pending error and clear              |        |int|
|          |SO_KEEPALIVE  |&#x2714;|&#x2714;|Periodically test if connection alive    |&#x2714;|int|
|          |SO_LINGER     |&#x2714;|&#x2714;|Linger on close if data to send          |        |struct linger|
|          |SO_OOBINLINE  |&#x2714;|&#x2714;|Leave received out-of-band data inline   |&#x2714;|int|
|          |SO_RCVBUF     |&#x2714;|&#x2714;|Receive buffer size                      |        |int|
|          |SO_SNDBUF     |&#x2714;|&#x2714;|Send buffer size                         |        |int|
|          |SO_RCVLOMAT   |&#x2714;|&#x2714;|Send buffer low-water mark               |        |int|
|          |SO_SNDLOMAT   |&#x2714;|&#x2714;|Receive buffer low-water mark            |        |int|
|          |SO_RCVTIMEO   |&#x2714;|&#x2714;|Receive timeout                          |        |struct timeval|
|          |SO_SNDTIMEO   |&#x2714;|&#x2714;|Send timeout                             |        |struct timeval|
|          |SO_REUSEADDR  |&#x2714;|&#x2714;|Allow local address reuse                |&#x2714;|int|
|          |SO_REUSEPORT  |&#x2714;|&#x2714;|Allow local port reuse                   |&#x2714;|int|
|          |SO_TYPE       |&#x2714;|        |Get socket type                          |        |int|
|          |SO_USELOOPBACK|&#x2714;|&#x2714;|Routing socket gets copy of what it sends|&#x2714;|int|
|IPPROTO_IP|IP_HDRINCL    |&#x2714;|&#x2714;|IP header included with data   |&#x2714;|int|
|          |IP_OPTIONS    |&#x2714;|&#x2714;|IP header options              |        ||
|          |IP_RECVDSTADDR|&#x2714;|&#x2714;|Return destination IP address  |&#x2714;|int|
|          |IP_RECVIP     |&#x2714;|&#x2714;|Return received interface index|&#x2714;|int|
|          |IP_TOS        |&#x2714;|&#x2714;|Type-of-service and precedure  |        |int|
|          |IP_TTL        |&#x2714;|&#x2714;|TTL                            |        |int|
|          |IP_MULTICAST_IP  |&#x2714;|&#x2714;|Specify outgoing interface  |        |struct in_addr|
|          |IP_MULTICAST_TTL |&#x2714;|&#x2714;|Specify outgoing TTL        |        |u_char|
|          |IP_MULTICAST_LOOP|&#x2714;|&#x2714;|Specify loopback            |        |u_char|
|IPPROTO_ICMPV6|ICMP6_FILTER|&#x2714;|&#x2714;|Specify ICMPv6 message types to pass|        |strcut icmp6_filter|
|IPPROTO_IPV6|IPV6_CHECKSUM    |&#x2714;|&#x2714;|Offset of checksum field for raw sockets|        |int|
|            |IPV6_DONTFRAG    |&#x2714;|&#x2714;|Drop instead of fragment large packets  |&#x2714;|int|
|            |IPV6_NEXTHOP     |&#x2714;|&#x2714;|Specify next-hop address                |        |int|
|            |IPV6_PATHMTU     |&#x2714;|&#x2714;|Retrieve current path MTU               |        |int|
|            |IPV6_RECVDSTOPTS |&#x2714;|&#x2714;|Receive destination options             |&#x2714;|int|
|            |IPV6_RECVHOPLIMIT|&#x2714;|&#x2714;|Receive unicast hop limit               |&#x2714;|int|
|            |IPV6_RECVHOPOPTS |&#x2714;|&#x2714;|Receive hop-by-hop options              |&#x2714;|int|
|            |IPV6_RECVPATHMTU |&#x2714;|&#x2714;|Receive path MTU                        |&#x2714;|int|
|            |IPV6_RECVPKTINFO |&#x2714;|&#x2714;|Receive packet information              |&#x2714;|int|
|            |IPV6_RECVRTHDR   |&#x2714;|&#x2714;|Receive source route                    |&#x2714;|int|
|            |IPV6_RECVTCLASS  |&#x2714;|&#x2714;|Receive traffic class                   |&#x2714;|int|
|            |IPV6_UNICAST_HOPS|&#x2714;|&#x2714;|Default unicast hop limit               |        |int|
|            |IPV6_USE_MIN_MTU |&#x2714;|&#x2714;|Use minimum MTU                         |&#x2714;|int|
|            |IPV6_V6ONLY      |&#x2714;|&#x2714;|Disable v4 compatibility                |&#x2714;|int|
|            |IPV6_XXX         |&#x2714;|&#x2714;|Sticky ancillary data                   |        ||
|            |IPV6_MULTICAST_IP  |&#x2714;|&#x2714;|Specify outgoing interface            |        |u_int|
|            |IPV6_MULTICAST_HOPS|&#x2714;|&#x2714;|Specify outgoing hop limit            |        |int|
|            |IPV6_MULTICAST_LOOP|&#x2714;|&#x2714;|Specify loopback                      |&#x2714;|u_int|
|            |IPV6_JOIN_GROUP    |        |&#x2714;|Join multicast group                  |        |strcut ipv6_mreq|
|            |IPV6_LEAVE_GROUP   |        |&#x2714;|Leave multicast group                 |        |strcut ipv6_mreq|
|IPPROTO_TCP|TCP_MAXSEG |&#x2714;|&#x2714;|TCP maximum segment size |        |int|
|           |TCP_NODELAY|&#x2714;|&#x2714;|Disable Nagle algorithm  |&#x2714;|int|

其中, **Flag**表示该socket option只有两个选项: 开启或关闭. nonzero表示开启, zero表示关闭. 


## 2. Socket States
部分socket option需要在规定的时间写入和读取, 例如connected TCP socket. connected TCP socket会继承listening socket的部分socket options: 
* `SO_DEBUG`
* `SO_DONTROUTE`
* `SO_KEEPALIVE`
* `SO_LINGER`
* `SO_OOBINLINE`
* `SO_RCVBUF`
* `SO_RCVLOWAT`
* `SO_SNDBUF`
* `SO_SNDLOWAT`
* `TCP_MAXSEG`
* `TCP_NODELAY`

因此如果需为connected socket修改options, 需在调用`accept()`前为listening socket设置options.


## 3. Generic Socket Options
Generic socket options表示协议独立的socket options(可用于多种protocols). 但这其中也有一些options不适用于所有protocol, 例如: `SO_BROADCAST`虽然为generic, 但只适用于datagram socket.

### 3.1 SO_BROADCAST
该option可允许或禁止socket发送broadcast message. 只有datagram socket且网络支持broadcast message时, 才能使用该`SO_BROADCAST`. 对于TCP, SCTP, 或point-to-point link则不能使用. 由于发送broadcast message前必须设置该option, 因此在没有设置`SO_BROADCAST` option的socket上将目的地址设为broadcasr address会返回`EACCES`

### 3.2 SO_DEBUG
该option只有TCP支持. 当启动该option后, kernel会一直跟踪该socket发出的所有packet的详细信息, 并可通过trpt程序查看. 

### 3.3 SO_DONTOUTE
该option会让所有发出的packets绕过路由机制. 例如: IPv4中, packet会根据目的地址和subnet来判断使用哪个local interface, 不会通过gateway(网关)转发; 若无法做出判断, 则返回`ENETUNREACH`. 也可通过在`send()`, `sendto()`或`sendmsg()`中设置`MSG_DONTROUTE` flag起到相同作用.

### 3.4 SO_ERROR
一般进程有两种方式获知socket error:
1. 进程中`select()`检测到error并返回
2. 进程使用signal-driven I/O model, SIGIO signal通知进程发生error

这时可以通过调用`getsockopt()`并设置该option来获取socket error, 且不可在`setsockopt()`中设置该option.

### 3.5 SO_KEEPALIVE
该option保证即便TCP connection中没有信息交换, socket也会每隔一段时间向对端发送**keep-alive probe**来探测对端是否存活. 以下是发送probe后的几种结果:
1. 对端回复ACK, socket将会继续等待一段时间并再次发送probe
2. 对端回复RST, 说明对端进程崩溃, 返回`ECONNRESET`并关闭socket
3. 对端无回复, socket会继续发送多个probe; 若仍无回复, 则返回`ETIMEOUT`并关闭socket

该option通常由server使用, 拥有检测client是否不可达(可能原因: client断开连接, 断电或主机崩溃). 这种情况成为half-open connection, keep-alive option专门用于检测该情况. 以下是检测TCP connection所能遇到的各种情况:

| Scenario | Peer process crashed | Peer host crashes | Peer host is unreachable |
|:---:|:---:|:---:|:---:|
| 本端TCP正在发送数据 | 对端TCP发送**FIN**, `select()`检测到socket可读; 若本端TCP发送了另一个packet, 则对端回复**RST**; 若进程在socket收到RST后依然发送数据, 则socket返回**SIGPIPE** | 本端TCP多次发送超时后发挥**ETIMEDOUT** | 本端TCP多次发送超时后返回EHOSTUNREACH |
| 本端TCP正在等待接收数据 | 对端TCP发送FIN, 本端`read()`返回**EOF** | 主动停止接受数据 | 主动停止接收数据 |
| Connection无数据交换且开启keep-alive | 对端TCP发送FIN, `select()`检测到socket可读 | 本端keep-alive probe多次发送超时后返回**ETIMEDOUT** | 本端keep-alive probe多次发送超时后返回**EHOSTUNREACH** |
| Connection无数据交换且未开启keep-alive | 对端TCP发送FIN, `select()`检测到socket可读 | 无事发生 | 无事发生 |

其中, 若本端TCP等待接收数据, 对端主机崩溃或不可达, 则需要本端主动发送数据, 根据返回来判断对端情况; 若本端不主动发送数据, 则需要keep-alive机制来自动断开连接; 若本端未开启keep-alive, 则本端会一直等待.

### 3.6 SO_LINGER
该option用于规定`close()`如何关闭一段connection, 只用于TCP和SCTP, 不适用于UDP. 通常, `close()`在调用后会立即返回, 若socket send buffer中还有数据未发送, 则kernel会自动发送给对方.
```c
struct linger {
  int l_onoff;  /* 0=off, nonzero=on */
  int l_linger; /* linger time, POSIX specifies units as seconds */
};
```
`getsocketopt()`会根据**l_onoff**和**l_linger**的不同值设置`close()`的不同行为:
1. 若`l_onoff`为零, 则`l_linger`将被忽略, `close()`保持默认行为
2. 若`l_onoff`为非零, 且`l_linger`为零, `close()`会让socket丢弃connection: 丢弃socket send buffer数据, 并向对端发送RST. 由于跳过了TIME_WAIT state, 因此无需等待2 MSL, 可能导致旧connection中的数据干扰新的connection.
3. 若`l_onoff`和`l_linger`都非零, 则kernel会阻塞`close()`一段时间: 若socket send buffer中仍有数据, 则进程进入睡眠状态, 直到达到以下某个其中一个条件:
  1. 所有数据都收到ACK确认, `close()`返回0
  2. linger time倒计时结束, `close()`返回socket send buffer中丢弃的数据字节数, 并将errno置为`EWOULDBLOCK`

若为nonblocking socket, 则SO_LINGER不起任何作用. 以下是`close()`默认情况下的操作:
![Default operation of close: it returns immediately](/images/Network/UNP/7-3-default-close.gif)

可以看到, client在调用`close()`后立即返回, server可能因进程崩溃或主机崩溃而未能获取数据. 而SO_LINGER option则能让`close()`等待一段时间, 确保数据已经保存在server的socket receive buffer中, 如下图:
![close with SO_LINGER socket option set and l_linger a positive value](/images/Network/UNP/7-3-close-with-opt-and-positive-val.gif)

但SO_LINGER还未解决一个问题: 若server将数据保存到socket receive buffer, 此时主机崩溃, client仍无法得知. 更糟的是, SO_LINGER可能因`l_linger`过小而提前返回:
![close with SO_LINGER socket option set and l_linger a small positive value](/images/Network/UNP/7-3-close-with-opt-and-small-positive-val.gif)

为解决server是否读取buffer数据的问题, 可使用`shutdown()`替代`close()`, 如下图:
![Using shutdown to know that peer has received our data](/images/Network/UNP/7-3-shutdown.gif)

可以看到, `shutdown()`只有收到FIN后才返回, 从而确保server已读取数据. 另一种方法则是使用application-level acknowledgement, 也称为application ACK. 假设client向server发送完毕数据后, 会调用`read()`等待application ACK; 而server进程在读取数据后会发送one-byte application ACK告知client数据已被读取; client在收到application ACK后调用`close()`关闭connection. 整个流程如下:
![Application ACK](/images/Network/UNP/7-3-application-ack.gif)

以下是`shutdown()`, `close()`, 和SO_LINGER的不同组合:

| Function | Description |
|:---:|:---:|
| shutdown, SHUT_RD | socket不再接受任何数据; 进程仍可发送数据, socket receive buffer中的数据会被丢弃, socket send buffer中的数据依旧会被发送至对端 |
| shutdown, SHUT_WR | socket不再发送任何数据; 进程仍可接收数据, 发送FIN后socket send buffer中数据会被发送至对端; 不影响socket receive buffer |
| close, l_onoff = 0 | socket不再接收或发送数据; socket send buffer中数据会被发送至对端. 若socket descriptor的reference count为0, 则开始TCP connection termination, 丢弃socket receive receive buffer中的数据 |
| close, l_onoff = 1, l_linger = 0 | socket不再接收或发送数据; 若socket descriptor的reference count为0, 则发送RST至对端, 丢弃socket send buffer和socket receive buffer中数据 |
| close, l_onoff = 1, l_linger != 0 | socket不再接收或发送数据; 若socket descriptor的reference count为0, 则发送FIN至对端, 等待socket send buffer中数据被发送和确认, 或linger time倒计时结束; 抛弃socket receive buffer中数据 |

### 3.7 SO_OOBINLINE
当开启该option后, out-of-band data将会被放入normal input queue中. 

### 3.8 SO_RCVBUF and SO_SNDBUF
每个socket都有自己的send buffer和receive buffer. TCP, UDP和SCTP都有receive buffer, 进程会从receive buffer中读取数据. 对于TCP而言, 不存在receive buffer溢出情况, 因为TCP有flow control: 每次数据交换都会告诉对端receive buffer的剩余空间大小, 对端会据此发送相应大小的数据; 若对端并不遵守flow control, 则多余数据会被抛弃. 由于UDP没有flow control, 超出receive buffer空间的大量数据涌入会导致数据丢失. 
SO_RCVBUF和SO_SNDBUF可用于修改buffer size. 当设置TCP socket receive buffer size时, 调用`setsockopt()`的时机十分重要, 因为TCP window scale option会在SYN中交换. 对于client, 应在调用`connect()`之前设置buffer size; 对于serber, 应在调用`listen()`之前设置buffer size.
TCP socket buffer size应至少为四倍的MSS, 因为TCP使用**fast recovery algorithm**来检测发出的数据是否丢失: 当发送端收到三次DACK时说明数据丢失, 需要重发指定的数据. 为防止buffer空间被浪费, TCP socket buffer的大小应为MSS的偶数倍. 

### 3.9 SO_RCVLOWAT and SO_SNDLOWAT
每个socket都有一个receive low-water mark和send low-water mark, 可通过这两个options设置. receive low-water mark作为`select()`判断socket receive buffer中数据是否可读的条件, 默认为1字节; send low-water mark作为`select()`判断socket send buffer中数据是否可写的条件, 通常为2048字节(TCP); 对于UDP来说, 由于发送的数据不需要备份保留, 所以socket send buffer中的可用空间始终不变, 只要socket send buffer大于low-water mark, UDP socket始终处于可写状态.

### 3.10 SO_RCVTIMEO and SO_SNDTIMEO
用于设置socket receive和send的timeout.
* 受timeout影响的receive function: `read()`, `readv()`, `recdv()`, `recvfrom()`, `recvmsg()`
* 受timeout影响的send function: `write()`, `writev()`, `send()`, `sendto()`, `sendmsg()`. 

### 3.11 SO_REUSEADDR and SO_REUSEPORT
SO_REUSEADDR socket option有以下用途:
1. SO_REUSEADDR允许listening server绑定已被connected socket使用的端口, 情况如下:
    1. 启动一个listening server
    2. 某client请求连接, 使用一个child process作为connected socket处理client请求
    3. listening server终止运行, 但其child process仍在运行
    4. 另一个listening server启动并使用相同端口
2. 若server使用wildcard address作为local address, SO_REUSEADDR socket option允许其他server在使用不同的local IP address的前提下复用port. 假设local host的primary IP address为`198.69.10.2`, 另外两个IP aliases为`198.69.10.128`和`198.69.10.129`. Server A使用wildcard address和80端口; Server B使用`198.69.10.128`和80端口(使用SO_REUSEADDR), 第三个Server C使用`198.69.10.129`和80端口(使用SO_REUSEADDR). 目的地址为`198.69.10.128`且端口号为80的请求由server B接收; 目的地址为`198.69.10.129`且端口号为80的请求由server C接收; server A负责接收目的地址为`198.69.10.2`且端口号为80的请求.
3. SO_REUSEADDR允许同一进程下的多个socket使用同一port时, 只要每个socket绑定不同的local IP address即可. 通常UDP server会使用这一特性, 因为当系统不支持IP_RECVDSTADDR socket option时(无法获取请求的destination address), UDP server接收请求后, 无法确定使用哪个local address作为source address回复client; 而TCP server可调用`getsockname()`获取目的地址.
4. SO_REUSEADDR允许多个socket绑定同一IP address和port, 只支持UDP socket. 该特性一般用于multicast(组播), 多个socket将local address设为相同组播地址和端口, 但发来的数据destination address为该组播地址且端口相同时, 每个socket都会收到一份数据; 但若多个socket使用同一unicast(单播)地址, 则不同系统会决定不同socket获得数据. 

4.4BSD引入SO_REUSEPORT socket option用于支持组播数据传输, 其用途覆盖了SO_REUSEADDR中的第4个特性:
1. SO_REUSEPORT允许多个socket绑定相同IP address和port.
2. 若socket并不与其他socket的IP address和port相同, 则不能设置该option

SO_REUSEADDR socket option存在一个安全隐患: 当socket A绑定wildcard address和port 5555后, socket B绑定198.69.10.2和port 5000会导致之后所有的流量转向socket B. 因此所有绑定相同port的specific IP address都需要superuser权限. 

### 3.12 SO_TYPE
该option返回socket type, 例如SOCK_STREAM或SOCK_DGRAM.

### 3.13 SO_USELOOPBACK
该option只用于routing domain. 默认情况下开启该option, 使得socket收到所有发出数据的备份.


## 4. IPv4 Socket Options
### 4.1 IP_HDRINCL
通常kernel会为每个datagram设置IP header, 但通过该option可自行设置. 以下几种情况IP header还是会被kernel修改:
* IP header checksum会被自动计算并保存
* 若进程将IP identification设置为0, kernel会自动设置该field
* 若进程将source IP address设置为`INADDR_ANY`, kernel会将其置为外出接口的primary IP address
* IP option的设置与系统实现有关. 有些系统会将所有IP_OPTIONS socket option设置的IP options添加到IP header中; 有些系统则只会添加部分IP options
* 有些系统要求某些field以host byte order写入, 而其他系统要求某些field以network byte order写入

### 4.2 IP_OPTIONS
该option可用于为IPv4 header设置IP option.

### 4.3 IP_RECVDSTADDR
该option用于获取接收到的UDP datagram中的destination IP address.

### 4.4 IP_RECVIF
该option用于获取接收到的UDP datagram中的interface index.

### 4.5 IP_TOIS
该option用于设置TOS field(type-of-service), 其中包括DSCP和ECN fields. 应用设置一个与运营商协商好的DSCP value来提供更好的网络服务, 例如: 低延迟或高流量的数据传输.

### 4.6 IP_TTL
该option可设置或获取socket中的TTL值. 默认情况下, TCP和UDP socket的TTL为64, raw socket的TTL为255, 但无法从接收的datagram中获取TTL.


## 5. ICMPv6 Socket Option
ICMPv6只有一个socket option: `ICMPV6_FILTER`. 该option可规定socket接收哪些ICMPv6 message type. 包含ICMPv6 message type的结构体为`icmpv6_filter`.


## 6. IPv6 Socket Options
### 6.1 IPV6_CHECKSUM
该option用于开启或关闭checksum processing. 若该option为非负值, kernel为每个发出的packet计算并添加checksum; 并验证每个接收到的packet的正确性. 若该option为-1, 则kernel不会计算checksum; 也不会验证接收到的packet中的checksum.

### 6.2 IPV6_DONTFRAG
该option用于停止UDP和raw socket的自动分片. 若packet大于输出接口的MTU, 则自动丢弃该packet, 且不会返回任何错误. 若启动该option, 推荐使用IPV6_RECVPATHMTU socket option检测MTU的变化.

### 6.3 IPV6_NEXTHOP
该option用于指定下一跳地址, 需要superuser权限.

### 6.4 IPV6_PATHMTU
该option无法设置, 只能读取. 用于表示当前path-MTU discovery下的MTU值.

### 6.5 IPV6_RECVDSTOPTS
该option允许进程通过`recvmsg()`获取IPv6 packet中的destination options. 默认为关闭状态.

### 6.6 IPV6_RECVHOPLIMIT
该option允许进程通过`recvmsg()`获取IPv6 packet中的hop limit field. 默认为关闭状态.

### 6.7 IPV6_RECVHOPOPTS
该option允许进程通过`recvmsg()`获取IPv6 packet中的hop-by-hop options. 默认为关闭状态.

### 6.8 IPV6_RECVPATHMTU
该option允许进程通过`recvmsg()`获取IPv6 packet中的path MTU值.

### 6.9 IPV6_RECVPKTINFO
该option允许进程通过`recvmsg()`获取IPv6 packet中的两种信息: destination IPv6 address和interface index.

### 6.10 IPV6_RECVRTHDR
该option允许进程通过`recvmsg()`获取IPv6 packet中的routing header. 默认为关闭状态.

### 6.11 IPV6_RECVTCLASS
该option允许进程通过`recvmsg()`获取IPv6 packet中的traffic class, 其中包括DSCP和ECN fields. 默认为关闭状态.

### 6.12 IPV6_UNICAST_HOPS
与IPv4的IP_TTL类似, 可通过该option获取或设置当前socket的hop limit值. 

### 6.13 IPV6_USE_MIN_MTU
该option用于决定socket使用path MTU discovery或minimum IPv6 MTU:
1. option = 1: 任何目的地址都使用minimum MTU来避免分片
2. option = 0: 任何目的地址都使用path MTU discovery
3. option = -1: 单播地址使用path MTU discovery; 组播地址使用minimum MTU

### 6.14 IPV6_V6ONLY
该option要求socket只能发送和接收IPv6 packet. 默认为关闭状态.


## 7. TCP Socket Options
### 7.1 TCP_MAXSEG
该option允许进程获取或设置TCP connection中的MSS, 表示单个TCP sgment所能传输的最大字节数. MSS会在本端MSS和对端的MSS中取一个最小值, 对端MSS会在TCP three-way handshake中传输给本端; 若TCP支持path MTU discovery, MSS也可能在数据交换时修改. 并不是所有系统都支持修改MSS, 对于4.4BSD来说, 只能设置更小的MSS.

### 7.2 TCP_NODELAY
该option可用于在TCP connection中停止使用Nagle algorithm, 默认情况下启动该算法. Nagle algorithm用于减少发出small packet的数量: 其中, small packet表示数据小于MSS的packet, 若socket中有还没得到ACK确认的数据, 则暂时不发送small packet. 至于为什么防止发送small packet: TCP header有20字节, IP header有20字节, 若数据只有几个字节, 则sement的有效传输效率很低.
Rlogin和Telnet client会产生大量small packet, 因为用户每次敲击键盘都会产生单独的packet. 对于fast LAN, Nagle algorithm不会产生太大影响; 但对于slow WAN, nagle algorithm会将网络延迟放大. 例如: Telnet client需要向server发送**"hello"**, 每个字符输入的间隔为250 ms, client与server的RTT为600 ms. 当不开启Nagle algorithm时, 情况如下图:
![Six characters echoed by server with Nagle algorithm disabled](/images/Network/UNP/7-7-svr-with-nagle-disabled.gif)

可以看到, 每个packet都得到server的ACK, 总共需要1800 ms. 但当开启Nagle algorithm后, 情况如下图:
![Six characters echoed by server with Nagle algorithm enabled](/images/Network/UNP/7-7-svr-with-nagle-enabled.gif)

可以看到, client只有收到ACK后才发送packet, 导致整个传输用时2400 ms. 通常Nagle algorithm会搭配另一个TCP algorithm: delayed ACK algorithm, 该算法为了等待本端发送数据, 并将数据和ACK一起发送至对端, 会在收到对端数据后推迟一段时间(50-200 ms), 可节省一个TCP segment. 但对于server端不需要回复数据的情况, delayed ACK algorithm会整体传输速率, 这时应设置TCP_NODELAY socket option. 
还有另外一种需要关闭Nagle algorithm的情况: client需要向server发送多段request, server根据全部的request决定回复内容. 例如: client总共需要向server发送400 byte的request, 其中前4 byte为request type, 后396 byte为request data. 当client调用`write()`发送request type后, 由于还未得到ACK确认, 因此client端停止发送request data; server端接收到request type后需要等待request data才能做出回应, 因此只有等delayed ACK algorithm倒计时结束才能发送ACK. 对于这种情况, 有3种解决方法:
1. 使用`writev()`替代`write()`, `writev()`可实现一次I/O call中写入多个数据 (推荐方法)
2. 将request type和request data写入同一buffer中, 并对该buffer调用`write()`
3. 使用TCP_NODELAY socket option关闭Nagle algorithm, 并调用`write()`两次 (不推荐)


## 8. fcntl Function
fcntl表示**file control**. fcntl, ioctl和routing socket的对比总结如下:

| Operation | fcntl | ioctl | Routing socket | POSIX |
|:---:|:---:|:---:|:---:|:---:|
| Set socket for nonblocking I/O | F_SETFL, O_NONBLOCK | FIONBIO |  | fcntl |
| Set socket for signal-driven I/O | F_SETFL, O_ASYNC | FIOASYNC |  | fcntl |
| Set socket owner | F_SETOWN | SIOCSPGRP or FIOSETOWN |  | fcntl |
| Get socket owner | F_GETOWN | SIOCGPGRP or FIOGETOWN |  | fcntl |
| Get # bytes in socket receive buffer |  | FIONREAD |  |  |
| Test for socket at out-of-band mark |  | SIOCATMARK |  | sockatmark |
| Obtain interface list |  | SIOCGIFCONF | sysctl |  |
| Interface operations |  | SIOC[GS]IFxxx |  |  |
| ARP cache operations |  | SIOCxARP | RTM_xxx |  |
| Routing table operations |  | SIOCxxxRT | RTM_xxx |  |

前五个operations可被所有进程使用; 中间两个为interface operations; 最后两个operations用于ARP和routing table, 只能由管理员进程操作. 

```c
#include <fcntl.h>

/**
 * @brief perform a operation on the open file descriptor fd
 */
int fcntl(int fd, int cmd, ... /* arg */ );
```
网络编程中, `fcntl()`用于以下情况:
* `F_SETFL`和`N_NONBLOCK`: socket变为nonblocking I/O
* `F_SETFL`和`O_ASYNC`: socket变为signal-driven I/O, 当ocket状态改变时, 进程收到`SIGIO` signal
* `F_SETOWN`: 可设置socket owner(process ID或process group ID), 用于接收`SIGIO`和`SIGURG` signal

以下为设置或取消nonblocking I/O:
```c
int flags;
flags |= O_NONBLOCK;
if (fcntl(fd, F_SETFL, flags) < 0)
  err_sys("F_SETFL error");

int flags;
flags &= ~O_NONBLOCK;
if (fcntl(fd, F_SETFL, flags) < 0)
  err_sys("F_SETFL error");
```
当设置socket owner时, F_SETOWN可接收两种参数:
* positive integer: process ID
* negative integer: 其绝对值为process group ID

当socket owner为process ID时, 只有该进程会收到signal; 当socket owner为process group ID时, process group中的所有进程都会收到signal; 当socket刚被创建时, 其不拥有socket owner. 但当connected socket被创建时, 会从listening socket继承socket owner.
