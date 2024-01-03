---
title: TCP Congestion Control
category:
  - Network
tag:
  - Network
abbrlink: '9637'
date: 2016-06-13 21:37:08
---

## 1. Definitions
1. SEGMENT: TCP/IP的一个数据包或确认包
2. SENDER MAXIMUM SEGMENT SIZE (SMSS): sender所能传输的最大segment大小. 这一个值基于网络中的最大传输单元, path MTU discovery algorithm, RMSS或其他因素. SMSS不包含TCP/IP header和options
3. RECEIVER MAXIMUM SEGMENT SIZE (RMSS): receiver能够接受的最大segment大小. 该值在设置在TCP handshanke中的MSS option中. 若没有设置MSS option, 那就为536 bytes. RMSS不包含TCP/IP header和options
4. FULL-SIZED SEGMENT: 一个segment能包含的最大数据字节数
5. RECEIVER WINDOW (rwnd): 表示所能接收的最大数据量
6. CONGESTION WINDOWS (cwnd): 表示所能发送的最大数据量. 在任何时刻, TCP中segment的sequence number必须遵循: TCP发送的segment中**sequence number**不能大于 已接收的**acknowledged number**中的最大值 与 **cwnd**和**rwnd**中的最小值 之和. 公式表示: $tcp.seq \leq max(ack.seq) + min(cwnd, rwnd)$
7. INITIAL WINDOW(IW): 表示TCP three-way handshake后sender的congestion window大小
8. LOSS WINDOW(LW): 表示TCP sender的重传计时器检测到丢包后的cwnd大小
9. RESTART WINDOW(RW): 表示TCP重传后的cwnd大小
10. FLIGHT SIZE: 表示已经发出但还未被ACK确认的data数量
11. DUPLICATE ACKNOWLEDGMENT: 当一个ACK满足以下4个条件才能算作"重复的":
	* 接收到ACK的一端有未发送的数据
	* 将要到来的ACK没有携带任何数据
	* 未设置SYN和FIN bits
	* ACK中的acknowledgment number与当前连接中已接收到的当前最大acknowledgment number相同



## 2. Congestion Control Algorithms
以下是4种congestion control algorithms:
* slow start (慢启动)
* congestion avoidance (拥塞避免)
* fast retransmit (快速重传)
* fast recovery (快速恢复)

TCP sender可以在congestion control algorithm的基础上更加保守, 但不能更加激进.

### 2.1 Slow Start and Congestion Avoidance
Slow start和congestion avoidance由sender实现, 用于控制发出的数据量. 为实现算法, 需为每个TCP connection添加两个变量: 
1. cwnd(congestion window): sender在接收到ACK前所能发出的最大数据量
2. rwnd(receiver window): receiver所能接受的最大数据量

min(cwnd, rwnd)控制了该connection中的数据传输传输速率上限. **ssthresh**变量用于判断connection处于slow start还是congestion avoidance. 

在一个未知的网络发送数据时, 为避免突然传入大量数据导致的网络拥塞, 需要TCP不断探测网络的传输空间. slow start应用于传输的初始阶段, 和retransmission timer检测到丢包后的恢复阶段. slow start还会启动**ACK clock**, 这样TCP sender就可以在slow start, congestion avoidance和loss recovery中发送数据.

### 2.2 ssthreth(慢启动阀值, slow start threshold)
它被用来决定是否启动慢启动或拥塞控制算法来控制数据传输.(例如:增加到advertised window的最大值)ssthresh的初始化值应设置的非常高, 但ssthresh必须在拥塞时减少. 在网络条件允许的情况下可以将ssthresh设置的尽量高, 而不是受某些主机的限制, 因为这样可以控制发送速率. 在终端系统对网络情况有详细了解的情况下, 更加仔细地设置ssthresh有很多好处.(例如, 终端主机没有在沿路造成拥塞).

### 2.2 IW
IW作为cwnd的初始值, 必须遵循以下规则:
$$
IW = 
\begin{cases}
\text{2SMSS and <= 2segments}, \ \text{SMSS > 2190 bytes} \\\\[2ex]
\text{3SMSS and <= 3segments}, \ \text{SMSS > 1095 bytes and SMSS <= 2190 bytes} \\\\[2ex]
\text{4SMSS and <= 4segments}, \ \text{SMSS <= 1095 bytes}
\end{cases}
$$

TCP通常都会将IW设置为4个分片或4KB, 因为大多数WEB会话都会短时间维持. IW决定了TCP流多快能够完成. 虽然全球的网速每年不断提升, 但IW大小一直没改变过. 
RFC3390文档中提到, SYN/ACK和SYN/ACK的确认报文都不能提高cwnd. 进一步来说, 如果SYN或SYN/ACK丢失了, 那么在正确重传了SYN报文后, IW会设置为一个segment大小, 包含大约SMSS个字节.
当超过一个segemnt大小的IW用于Path MTU Discovery时, 发现MSS过大. 这时应减小cwnd以防止大量更小的分片涌入网络(因为SMSS大于MSS的情况下, 会对数据包进行拆分, 造成很多小segment). cwnd应以旧片段大小和新片段大小的比例进行减少. 

### 2.4 Slow Start
当$cwnd < ssthresh$时, 使用slow start; 当$cwnd > ssthresh$时, 使用congestion avoidance. 当$cwnd == sshthresh$, sender可以使用slow start或congestion avoidance.
slow start阶段中, 每收到一个ACK, 就可以将cwnd增加至多一个SMSS字节大小, 当cwnd超过sshthresh或发生拥塞时结束. cwnd增加的规则可以遵循: $cwnd += min(N, SMSS)$, N表示刚刚被ACK确认的字节数. 这种修正作为**Appropriate Byte Counting**的一部分收录在RFC3465文档中, 用于防止receiver端估计拆分ACK导致sender端的cwnd迅速扩大问题(ACK Division).

### 2.5 Congestion Avoidance
Congestion avoidance阶段中, cwnd会每隔一个RTT(round-trip time)增加一个segment大小, 直到检测到拥塞发生. 以下是congestion avoidance增加cwnd的规则:
1. cwnd可以增加一个SMSS字节数
2. 每个RTT后都应增加cwnd
3. cwnd每次增量不得超过一个SMSS字节数

推荐方法: congestion avoidance期间, cwnd每次的增加量应为被ACK确认的字节数. 当ACK确认的data字节数达到cwnd大小时, 就可以将cwnd增加SMSS个字节. 需要注意, cwnd不能在一个RTT后增加超过SMSS个字节, 这种方法还解决了两个问题:
* Delayed ACK
* ACK Division导致cwnd增长过快

另一个congestion avoidance中增加cwnd的公式: $\text{cwnd += SMSS * SMSS / cwnd}$. 这种cwnd增加只针对收到ACK的情况, 相当于一个"每隔一个RTT就增加一个segment大小". 由于TCP中都是整数计算, 所以当$\text{cwnd > SMSS * SMSS}$时, 理论上不会增加cwnd, 但实现中hi增加1 byte. 某些实现中会为该公式增加一个常量参数, 但由于影响性能, 所以在RFC2525被明确指出不应添加常量. 
某些实现会将byte作为cwnd的最小单元; 另一些实现将segment作为cwnd的最小单元. 对于不同的cwnd单元, 会采用不同的cwnd增加公式.

### 3.6 ssthresh
当TCP sender的retransmission timer检测到丢包, 并且该segment还未重传时, ssthresh遵循以下规则: $\text{ssthresh = max(FlightSize / 2, 2 * SMSS)}$
FlightSize就是没有ACK确认字节总数. 另一方面, 当sender的重传计时器检测到分片丢失, 并将指定分片已经重传至少一次后, ssthresh将变为常量. 
一个很容易犯的错误就是一味地使用cwnd而不使用FlightSize, 因为在某些实现中, Flight Size增加远远多于rwnd.
此外, 如果发生超时, cwnd的大小就不能大于丢失窗口(LW)的大小, 也就是一个full-sized segment大小. 因此, 在重传那些丢失的segment之后, sender使用慢启动算法将cnwd大小提升到新的ssthresh值, 并接着使用拥塞避免继续工作.
