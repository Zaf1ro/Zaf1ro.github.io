---
title: The Transport Layer
category:
  - Network
  - UNP
tag:
  - Network
abbrlink: b4dd
date: 2019-11-11 14:24:02
keywords:
description:
---

## 1. The Big Picture
以下是TCP/IP protocols的总览:
![Overview of TCP/IP protocols](/images/Network/UNP/2-1-overview-of-tcpip.gif)

上图包含IPv4和IPv6, 左边的应用使用IPv4, 右边的应用使用IPv6. **tcpdump**使用BPF(BSD packet filter)或DLPI(datalink provider interface)与datalink直接通信. 图中**dashed line**以上的应用使用相对应的protocol通信, 以下是各个proctocol的详细描述:
* IPv4: Internet Protocol version 4. IPv4也称为IP, 80年代初被加入IP suite. 使用32-bit address, 为TCP, UDP, SCTP, ICMP, IGMP服务.
* IPv6: Internet Protocol version 6. IPv6在90年代中期被引入IP suite, 作为IPv4的替代品. 其拥有128-bit address, 用于解决IPv4地址不足的问题, 为TCP, UDP, SCTP, ICMPv6服务.
* TCP: Transmission Control Protocol. 作为connection-oriented protocol, 为用户提供一个可靠, 全双工的字节流. TCP socket是stream socket的典范. TCP负责处理acknowledge, timeout, retransmission和其他问题. 绝大多数应用使用TCP作为transport layer protocol. TCP可使用IPv4或IPv6.
* UDP: User Datagram Protocol. 作为connectionless protocol, 不保证数据能否达到目的地. UDP socket是datagram socket的典范.
* SCTP: Stream Control Transmission Protocol. 作为connection-oriented protocol, 和TCP一样提供可靠, 全双工association. **association**用于形容SCTP的单个连接(等同于TCP的connection), 因为SCTP支持mulitihomed(通信的双方使用多个接口进行传输信息). SCTP和UDP相同, 都会有message boundary(多次信息不会被合并). 虽然TCP, UDP和SCTP都支持IPv4和IPv6, 但SCTP支持一个association中同时使用IPv4和IPv6.
* ICMP: Internet Control Message Protocol. 用于处理router和host之间的error和control information. 一般由TCP/IP networking自动产生, 而不是进程创建. 例如: 执行**ping**和**traceroute**时, 会使用到ICMP.
* IGMP: Internet Group Management Protocol. IGMP被用于组播.
* ARP: Address Resolution Protocol. ARP用于将IPv4 address映射为hardware address. 通常用于组播网络, 例如: Ethernet, token ring, FDDI.
* RARP: Reverse Address Resolution Protocol. RARP用于将hardware address映射为IPv4 address. 
* ICMPv6: Internet Control Message Protocl version 6.
* BPF: BSD packet filter. 提供了一个datalink layer的接口. 通常出现在Berkeley-derived kernel中.
* DLPI: Datalink provider interface. 提供了一个datalink layer的接口. 通常出现在SVR4中.


## 2. User Datagram Protocol (UDP)
RFC 768首次将UDP加入到transport-layer protocol. 应用会将要传输的数据写入UDP socket, 然后被封装到UPD datagram中. UDP datagram不保证数据会被传输到目的地, 数据包到达的顺序也不确定, 也不保证对端收到一次或多次数据.
网络编程使用UDP要面对的最大问题就是可靠性. 若datagram到达目的端, 但checksum检查到错误, 则该datagram直接被丢弃. 每个UDP datagram都有一个长度, 对端收到UDP datagram后也可得知该datagram的长度. 但TCP作为byte-stream protocol则不存在record boundary. UDP提供connectionless service, 意味着: UDP client和server之间不需要维持某种联系, client可以随时向不同的server发送datagram, server也会随时从不同的client端获取datagram.


## 3. Transmission Control Protocol (TCP)
RFC 793首次将TCP加入到transport-layer protocol, 之后经过了RFC 1323, RFC 2581, RFC 3390的更新. TCP为client和server建立一个可靠的connection, 当TCP发送数据给对端时, 对端必须回复一个acknowledgment, 否则TCP会自动重发; 若经过多次重传后, 对端依然不回复ACK, 则TCP放弃重传.
TCP并不能保证数据一定传到对端, 若数据无法被对端接收, 则会通知进程. TCP包含一套预估RTT(round-trip time)的算法, 这样就可以根据RTT决定等待ACK的时间. 不同网络环境下的RTT不同, 短则几十毫秒, 长则数秒. 
TCP会为发出的每个segment添加一个sequence number, 确保数据被有序的接收. 例如: 应用通过TCP socket发送2048 bytes的数据, TCP会将其拆分为两个segment: 第一个segment包含前1024 bytes的数据, 第二个segment包含后1024 bytes数据. 当对端接收到乱序segment时, 可根据sequence number自行调序; 也可以通过sequence number判断是否收到重复segment, 并丢弃重复数据.
TCP提供flow control保证sender发送的数据不会溢出receiver的buffer. TCP sender会维护一个**window**, 表示对端buffer的可用空间. 当receiver接收到数据时, window缩小; 当receiver从buffer中读取数据后, window变大. window为0时, sender必须等到buffer腾出空间才可发送数据.
最后, TCP connection是全双工的, connection的双方既可以发送数据, 也可以接收数据. 这也意味着通信双方既是sender, 也是receiver, 都需要维护window size1和sequence number.


## 4. Stream Control Transmission Protocol (SCTP)
RFC 2960首次将SCTP加入到transport-layer protocol中, 为client和server提供association. SCTP和TCP相同, 提供了可靠, 有序, 流控, 全双工的数据传输. SCTP中的**association**与TCP的connection不同, association表示两个系统之间的通信, connection则表示两个IP之间的通信, 一个association中可涉及多个IP addresses. SCTP为message-oriented, 提供单个record的有序数据传输, 每个record都有长度, 这一点与UDP相同.
SCTP为association的两端提供多个stream, 每个stream都可分别传输不同的数据. 这样就保证单个stream中的数据丢失不会阻塞整个数据传输. SCTP还提供multihomed, 通过支持多IP addresses来增加robustness. 即使某个IP address不可用, 也不会影响整个数据传输. 


## 5. TCP Connection Establishment and Termination
TCP connection的创建和终止有以下几个阶段:

### 5.1 Three-Way Handshake
TCP connection的创建需要满足以下几个条件:
1. server必须成功调用`socket()`, `bind()`, `listen()`并创建一个passive socket
2. client调用`connect()`发送SYN segment, 其中包括initial sequence number, 用于标示数据开头的sequence number
3. server回复ACK和自己的SYN, 其中包括server端的initial sequence number
4. client回复ACK

以下是TCP's three-way handshake的流程:
![TCP three-way handshake](/images/Network/UNP/2-5-tcp-handshake.gif)

client发送的SYN中initial sequence number和server回复的SYN+ACK中initial sequence number不必相同. 但server回复的SYN+ACK中, ACK必须等于client发出的SYN + 1, 因为默认SYN占一个byte数据. 

### 5.2 TCP Options
每个SYN都可拥有TCP options, 常见的options如下:
* MSS: maximum segment size. 表示单个TCP segment所能接受的最大byte数, 接收到SYN的一端会以该数值作为以后发送segment的最大bytes.
* Window scale: 由于TCP header中只有16bits来表示window大小, 所以window最大为65536 bytes. 但随着网速的不断提高, window也必须随着提高, 于是在RFC 1323中添加window scale option. 该scale规定了window的缩放大小, 由于window scale option最大可使用14 bits, 所以window的缩放因子范围为$[2^0 - 2^{14}]$, window的最大值为$65535 \times 2^{14}$ bytes. 为保持向后兼容性, 该option只会在SYN中出现.
* Timestamp: 该option用于防止高速连接下可能出现的data corruption, 可能由延迟, 重复或老旧的segment导致.

### 5.3 TCP Connection Termination
想要终止一个TCP connection需要经过以下4步:
1. 进程调用`close()`, 导致socket端发送FIN segment, 进入**active close**阶段
2. 收到FIN的一端进入**passive close**阶段, 并回复ACK, 对socket调用的`read()`将收到EOF
3. 收到EOF的进程将会调用`close()`关闭socket, 并发送FIN
4. 对端回复ACK

以下是TCP connection termination的流程:
![Packets exchanged when a TCP connection is closed](/images/Network/UNP/2-5-pkt-exc-tcp-closed.gif)

TCP之所以两端都需要发送FIN和ACK, 是为了保证两端都发送完毕数据. 假设host A向host B发送FIN后, host B并没有数据需要向host A发送, 则可将step 2和step 3合并成一步, 直接发送FIN+ACK.

### 5.4 TCP State Transition Diagram
以下是TCP状态转换的流程:
1. CLOSED: 起始点, 超时或断开连接后进入此状态
2. LISTEN: server调用`socket()`, `bind()`, `listen()`后进入此状态, 等待client端请求连接
3. SYN_SENT: client调用`connect()`后发送SYN, 进入此状态并等待server回复. 若server无法连接, 进入CLOSED状态
4. SYN_RCVD: server收到SYN后回复SYN+ACK, 并从LISTEN切换至此状态
5. ESTABLISHED: client收到SYN+ACK后回复ACK, 并进入此状态; server收到ACK后也进入此状态
6. client和server交换数据, 接收方必须回复ACK表示已收到segment
7. 一端请求关闭连接(可以是client或server, 这里假设为client), 向server发送FIN, 并进入FIN_WAIT_1状态
8. server接收到FIN后回复ACK, 进入CLOSE_WAIT状态, 等待上层应用程序的指令
9. client接收到ACK后进入FIN_WAIT_2状态
10. server发起关闭请求, 发送FIN并进入LAST_ACK状态
11. client收到FIN后发送ACK, 进入TIME_WAIT状态, 经过2个MSL后进入CLOSED状态
12. server收到ACK后进入CLOSED状态

若client和server同时请求关闭连接, 则步骤如下:
1. client发送FIN并进入FIN_WAIT_1状态, 等待ACK; server同时也发送FIN, 进入FIN_WAIT_1状态
2. client收到FIN后进入CLOSING状态, 回复ACK; server同理
3. client收到ACK后进入TIME_WAIT状态, 经过2个MSL后进入CLOSED状态; server同理

以下是TCP状态转换图:
![TCP state transition diagram](/images/Network/UNP/2-5-tcp-state-transition.gif)


## 6. TIME_WAIT State
所有TCP状态中, 最让人不解的应为**TIME_WAIT**状态. 假设Host A向Host B主动发起断开连接的FIN, Host B回复FIN+ACK后, Host A回复ACK并进入TIME_WAIT状态, 等待2个MSL(maximum segment lifetime)后自我销毁. 其中MSL表示一个TCP segment在网络中存活的最长时间, 各系统实现的MSL不同, RFC 793出现于1981年, 当时segment从一端到另一端需要数分钟, 所以2MSL大约10分钟. 随着网络速度的提升, TIME_WAIT状态的持续时间也在不断减小. 
之所以需要一个TIME_WAIT状态, 是处于以下2个方面的考量:
1. 防止上次连接中的segment重新出现: 经过2MSL后, 上次连接的所有segment都会在网络中消失
2. 可靠的关闭TCP连接: 若Host A发出的ACK丢失, 则Host B会重发FIN. 若Host A进入CLOSED状态, 则会回复RST而不是ACK


## 7. SCTP Association Establishment and Termination
SCTP和TCP相同, 也是connection-oriented. 但SCTP的handshake与TCP不同:

### 7.1 Four-Way Handshake
1. server调用`socket()`, `bind()`, `listen()`来准备接受association
2. client调用`connect()`发送INIT请求建立association, 其中包含client端的可用IP address列表, 出站和入站的stream数量 
3. server回应INIT-ACK, 其中包含server端的IP address列表, initial sequence number, initiation tag, 出站和入站的stream数量, state cookie.
4. client回应COOKIE-ECHO, 其中包含cookie
5. server收到COOKIE-ECHO后通过对比MAC address验证, 验证通过后回应COOKIE-ACK

以下是SCTP four-way handshake的流程图:
![SCTP four-way handshake](/images/Network/UNP/2-7-sctp-handshake.gif)

### 7.2 Association Termination
与TCP不同, SCTP不需要four-way termination. 当一端主动请求关闭association, 另一端必须停止发送新数据, 只能将没有传完的数据传过去. 并且SCTP association termination没有TIME_WAIT状态.
![Packets exchanged when an SCTP association is closed](/images/Network/UNP/2-7-pkg-exc-sctp-closed.gif)


## 8. Port Numbers
进程可使用TCP, UDP, SCTP进行通信, 所有transport layer protocols都需要通过16-bit integer的port number来区分不同的进程. 由于client连接server时必须标明port number, 因此各application layer protocol使用固定port number, 例如: FTP使用TCP 21, TFTP使用UDP 69.
Client一端则使用临时端口, 一般由kernel随机挑选. Port number分为以下三类:
1. The well-known ports: 范围为$[0, 1023]$, 由IANA分配, 用于一些常用的服务
2. The registered ports: 范围为$[1024, 49151]$, IANA并不分配该区域的port number, 但会列出这些port的应用
3. The dynamic or private ports: 范围为$[49152, 65535]$, IANA不对此做任何管理, 可由进程占用

TCP connection需要四个要素: local IP address, local port, foreign IP address, foreign port. 对于SCTP来说, 需要一组local IP addresses, 一个local port, 一组foreign IP addresses, 一个foreign port. IP address和port number用于表示一个endpoint, 也称为socket. 


## 9. TCP Port Numbers and Concurrent Servers
并发server中, server主进程会一直产生子进程来处理新的连接. 假设我们现在有一个server, 其拥有`12.106.32.254`和`192.168.42.1` IP addresses, 并使用端口号**21**. server主进程进入LISTEN状态, 等待client的连接请求:
![TCP server with a passive open on port 21](/images/Network/UNP/2-9-tcp-server-on-port-21.gif)

其中, `{*:21, *:*}`表示server端的socket pair: server会持续监听任意local IP address上的21号port, 可以接收来自任意foreign IP address和foreign port number的连接请求.
假设有一个client尝试连接该server, 其IP address为**206.168.112.219**, port number为**1500**:
![Connection request from client to server](/images/Network/UNP/2-9-conn-req-from-cli-to-svr.gif)

当client和server完成TCP的三次握手后, server会调用`fork()`复制主进程, 并让子进程处理请求:
![Concurrent server has child handle client](/images/Network/UNP/2-9-child-handle-cli.gif)

其中, server的主进程被称为**listening socket**, server子进程被称为**connected socket**. 虽然两者都占用端口21, 但listening socket用于监听并接受新的连接请求, connected socket则用于与client交换数据. 若此时另一个client请求连接该server, 则结果如下:
![Second client connection with same server](/images/Network/UNP/2-9-cli-conn-with-same-svr.gif)


## 10. Buffer Sizes and Limitations
IP datagram的大小受到以下条件限制:
* IPv4 datagram最大为65535 bytes, 其中包含IPv4的header
* IPv6 datagram最大为65575 bytes, 其中包含40bytes的IPv6 header. 虽然IPv6的长度依然受16 bits length field的限制, 但IPv6的header不包含在其中; IPv6的jumbo payload option可以将length field扩展为32 bits, 但只有在支持MTU(maximum transimission unit)超过65535 bytes的datalink layer protocol上才能使用该option.
* MTU的大小由硬件决定, Ethernet的MTU为1500 bytes, 而PPP(Point-to-Point)的MTU则可配置, SLIP link的MTU可以为1006或296 bytes. IPv4的最小MTU为68 bytes, 其中包括IPv4 header(20 bytes的固定header长度, 30 bytes的option fields)和最小fragment(8 bytes). 而IPv6的最小MTU为1280 bytes, 若IPv6的datalink layer protocol的MTU小于1280 bytes, 则需要将IPv6 datagram分片传输.
* 两个host之间的最小MTU称为path MTU. 通常情况下, path MTU即为Ethernet MTU(1500 bytes). 由于Internet中路由是非对称的, 所以是两个host下的不同方向, MTU也可能不同. 当IP datagram的长度超出MTU时, 需要进行fragmentation(分片). 对于IPv4, host和IPv4 router都可进行分片处理; 对于IPv6, 只有host进行分片处理.
* IPv4 header中可设置**DF**(don't fragment) bit要求datagram不被分片, 设置该bit后, 无论host还是router都无法对该datagram进行分片, 若datagram的长度超过MTU, 则返回ICMPv4 "destination unreachable, fragmentation needed but DF bit set" error message. 由于IPv6不支持router分片, 若其datagram的长度超过MTU, 则router返回ICMPv6 "packet too big" error message.
* IPv4的DF bit和IPv6用于path MTU discovery. 当TCP使用IPv4传输datagram时, 会为所有datagram设置DF bit. 若之后收到ICMP "destination unreachable", 则减少data长度. Path MTU discovery对于IPv4是可选的, 但对于IPv6是强制性的.
* IPv4和IPv6都定义了minimum reassembly buffer size, 表示最小datagram长度, 其中IPv4为576 bytes, IPv6为1500 bytes. 因此IPv4的很多应用(DNS, RIP, TFTP, SNMP等)为了避免超过这个576 bytes, 选择使用UDP作为transport layer protocol, 因为UDP的header更短, 可以腾出更多空间传输数据.
* TCP还定义了MSS(maximum segment size), 表示单个TCP segment中最大数据字节数, 用于避免分片. 在Ethernet的环境中使用IPv4, 则MSS为1460 bytes; 而对于IPv6, 其MSS则为1440 byte (IPv4 header长度为20 bytes, IPv6 header长度为40 bytes, TCP header长度为20 bytes)
* 由于TCP中MSS option为16 bits option, 因此最大支持65535 bytes. 对于IPv4上的TCP segment没有问题, 但由于IPv6支持jumbo payload option, 因此16 bits MSS option远远不够. RFC 2675规定, 若IPv6上的TCP header将MSS设为65535, 则表示MSS为无限长, 该TCP segment的数据可以为任意长. 

### 10.1 TCP Output
以下是TCP socket发送数据时的长度检查和处理过程:
![Steps and buffers involved when an application writes to a TCP socket](/images/Network/UNP/2-10-tcp-socket-write-buf.gif)

每个TCP都有一个send buffer, 并且可以通过**SO_SNDBUF** socket option来修改send buffer大小. 当进程调用`write()`时, kernel会复制application buffer中的数据到send buffer. 若socket buffer没有足够空间, 则进程进入sleep. 因此, `write()`调用成功只能说明数据被复制到send buffer, 不能确保数据已经被发送到对端.
当数据被发出后, TCP并不会立即删除send buffer中的数据, 需要等到对端传来ACK后才能删除数据. TCP层需要确保$len(data) \leq \text{MSS}$, 并为数据加上TCP header. 传给IP层后, IP层通过routing table找到目的IP address并转发给datalink. 每个datalink都有一个输出队列, 若队列已满, 则segment被丢弃; TCP检测到该错误后会重传, 并不会通知进程.

### 10.2 UDP Output
以下是UDP socket发送数据的流程:
![Steps and buffers involved when an application writes to a UDP socket](/images/Network/UNP/2-10-upd-socket-write-buf.gif)

UDP socket并不存在send buffer, 因为UDP是不可靠的, 发送后不需要保留数据. 但可通过`SO_SNDBUF` socket option设置UDP datagram中能承载的最大数据量, 若超出上限值, 则返回`EMSGSIZE`. 
UDP会为segment加上8-bytes header, IPv4或IPv6为segment加上header后通过routing table决定出接口, 并传递给datalink的输出队列. 若datagram超过MSS, 则进行分片. `write()`的返回表示UDP socket已经将数据传递到datalink的输出队列. 若输出队列中没有足够空间, 则返回`ENOBUFS`.

### 10.3 SCTP Output
以下是SCTP socket发送数据的流程:
![Steps and buffers involved when an application writes to an SCTP socket](/images/Network/UNP/2-10-sctp-socket-write-buf.gif)

SCTP和TCP同样是可靠传输, 因此也拥有send buffer, 并可通过`SO_SNDBUF` socket option修改buffer大小. 当进程调用`write()`后, kernel会将进程中的数据复制到send buffer中. 若没有足够空间, 则进入sleep状态. 因此SCTP socket的`write()`成功调用只表示数据被复制到send buffer中, 并不能保证数据被对端接收. 发送数据后, 数据仍会在send buffer中保留, 直到收到对端发来的SACK后再删除缓存的数据.


## 11. Standard Internet Services
以下是Standard TCP/IP services:

| Name    | TCP port | UDP port | RFC | Description |
|:-------:|:--------:|:--------:|:---:|:-----------:|
| echo    | 7        | 7        | 862 | Server returns whatever the client sends |
| discard | 9        | 9        | 863 | Server discards whatever the client sends |
| daytime | 13       | 13       | 867 | Server returns the time and data in a human-readable format |
| chargen | 19       | 19       | 864 | TCP server sends a continual stream of characters, until the connection is terminated by the client. UDP server sends a datagram containing a random number of characters eac time the client sends a datagram |
| time    | 37       | 37       | 868 | Server returns the time as a 32-bit binary number. This number represents the number of seconds since January 1, 1900, UTC |

### 12 Protocol Usage by Common Internet Applications
以下是一些Internet application使用的protocol:

| Application | IP     | ICMP   | UDP    | TCP    | SCTP    |
|:-----------:|:------:|:------:|:------:|:------:|:-------:|
| ping        |        |&#x2714;|        |        |         |
| traceroute  |        |&#x2714;|&#x2714;|        |         |
| OSPF        |&#x2714;|        |        |        |         |
| RIP         |        |        |&#x2714;|        |         |
| BGP         |        |        |        |&#x2714;|         |
| BOOTP       |        |        |&#x2714;|        |         |
| DHCP        |        |        |&#x2714;|        |         |
| NTP         |        |        |&#x2714;|        |         |
| TFTP        |        |        |&#x2714;|        |         |
| SNMP        |        |        |&#x2714;|        |         |
| SMTP        |        |        |        |&#x2714;|         |
| Telnet      |        |        |        |&#x2714;|         |
| SSH         |        |        |        |&#x2714;|         |
| FTP         |        |        |        |&#x2714;|         |
| HTTP        |        |        |        |&#x2714;|         |
| NHTP        |        |        |        |&#x2714;|         |
| LPR         |        |        |        |&#x2714;|         |
| DNS         |        |        |&#x2714;|&#x2714;|         |
| NFS         |        |        |&#x2714;|&#x2714;|         |
| Sun RPC     |        |        |&#x2714;|&#x2714;|         |
| DCE RPC     |        |        |&#x2714;|&#x2714;|         |
| IUA         |        |        |        |        |&#x2714; |
| M2UA, M3UA  |        |        |        |        |&#x2714; |
| H.248       |        |        |&#x2714;|&#x2714;|&#x2714; |
| H.323       |        |        |&#x2714;|&#x2714;|&#x2714; |
| SIP         |        |        |&#x2714;|&#x2714;|&#x2714; |
