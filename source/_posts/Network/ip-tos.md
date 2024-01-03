---
title: TOS and DS
category:
  - Network
tag:
  - Network
abbrlink: 33da
date: 2016-05-31 22:52:12
---

## 1. TOS简介:
Internet中提供的服务质量天差地别, 有的需要可靠的服务, 有的需要低延迟. 但总是要作出权衡的: 最高吞吐量的路线可能不是延迟最低或最廉价的路线. 需要根据不同应用的需求进行调节.
由于Internet自身无法优化应用的路线, 所以IP协议提供了一个简单的方式帮助Internet处理特定packet, 该方法称为**Type of Service**(TOS).


## 2. TOS结构:
``` 
   0     1     2     3     4     5     6     7
+-----+-----+-----+-----+-----+-----+-----+-----+
|                 |                       |     |
|   PRECEDENCE    |          TOS          | MBZ |
|                 |                       |     |
+-----+-----+-----+-----+-----+-----+-----+-----+
```
TOS包括三个部分, 长度为8 bits:
* PRECEDENCE
* TOS
* MBZ

### 2.1 PRECEDENCE(优先级)
```
   0     1     2   
+-----+-----+-----+
|                 |
|   PRECEDENCE    |
|                 |
+-----+-----+-----+
```
**PRECEDENCE**表示数据包的优先级. 若路由器进入拥塞状态, 会优先丢弃优先级较低的packet. Precedence数值越大, 则IP packet越重要. 

二进制 | 英文 | 中文
------------|--------------|-----------
000 | Routine | 普通
001 | Priority | 有限的
010 | Immediate | 立即的
011 | Flash | 闪电般的
100 | Flash Override | 比闪电般还快的
101 | Critical | 极重要的
110 | Internetwork Control | 网间控制
111 | Network Control | 网络控制

### 2.2 TOS(服务类型)
```
      0           1           2           3
+-----------+-----------+-----------+-----------+
|           |           |           |           |
|   Delay   |Throughput |Reliability|    Cost   |
|           |           |           |           |
+-----------+-----------+-----------+-----------+
```

类型名称 | 0 | 1
------------|--------------|-----------
Delay | normal(普通) | low(低延迟)
Throughtput | normal(普通) | high(高吞吐量)
Reliability | normal(普通) | high(高可靠性)
Cost | normal(普通) | low(低花费)

### 2.3 MBZ
```
      0
+-----------+
|           |
|    MBZ    |
|           |
+-----------+
```
未使用, 必须为0(除非在Internet协议实验中会有使用到这一bit), 路由器会忽略MBZ.

### 2.4 变更
RFC文档编号 | 更改内容
------------|--------------
RFC-791 | 引入Delay, Throughput, 和Reliability(简称: DTR).
RFC-1349 | 引入Lowcost
RFC-2474 | 重新定义TOS为DS Field(Differentiated Services), 且8 bits都被重新定义



## 3. DS(Differentiated Services, 差分服务)
```
   0     1     2     3     4     5     6     7
+-----+-----+-----+-----+-----+-----+-----+-----+
|                                   |           |
|                DSCP               |    CU     |
|                                   |           |
+-----+-----+-----+-----+-----+-----+-----+-----+
```
包含二个field, 总长为8bit:
* DSCP
* CU

### 3.1 DSCP(Differentiated Services Codepoint, 区分服务代码点)
```
   0     1     2     3     4     5 
+-----+-----+-----+-----+-----+-----+
|                                   |
|                DSCP               |
|                                   |
+-----+-----+-----+-----+-----+-----+
```
#### 3.1.1 概述
虽然是一个新的field, 但网络中仍然有很多不兼容DS field的设备, 并且precedenhce对于PHB(Per-hob Behaviour)来说已经有大量应用, 所以向前兼容是不可避免的. 我们希望DS能在兼容DS的节点中仍然使用. 因此使用codepoint对应TOS中的precedence, codepoint也称为DSCP值. 
理论上我们使用DSCP时可以设计出64种(2^6)通讯类型, 但实际网络中我们通常将PHB总结为以下4种类型:

#### 3.1.2 分类
1. CS(Class Selector, 类加速器): 与IP的precedence field保持兼容性, 格式为`xxx 000`.
| DSCP | Binary | Hex | Decimal | Typical application | Examples |
| :----: | :---:| :---: | :---: | :---: | :---: |
| CS0 | 000 000 | 0x00 | 0  |   | 	 |
| CS1 | 001 000 | 0x08 | 8  | Scavenger | YouTube, Gaming, P2P |
| CS2 | 010 000 | 0x10 | 16 | OAM | SNMP,SSH,Syslog |
| CS3 | 011 000 | 0x18 | 24 | Signaling | SCCP,SIP,H.323 |
| CS4 | 100 000 | 0x20 | 32 | Realtime | TelePresence |
| CS5 | 101 000 | 0x28 | 40 | Broadcast video | Cisco IPVS |
| CS6 | 110 000 | 0x30 | 48 | Network control | EIGRP,OSPF,HSRP,IKE |
| CS7 | 111 000 | 0x38 | 56 |   |    |

2. EF(Expedited Forwarding, 加速转发): 确保PHB低延迟(low delay)和低丢包率(low loss)和尽量少的抖动(low jitter), 格式为`101 110`. 这些属性适合于声音, 视频和其他实时服务. EF总是被给予更高的优先权.

3. AF(Assured Forwarding, 确保转发): 在规定的条件下确保传递成功, 格式为`xxx yy0`, x表示丢包可能性从小到大, y表示三个级别, y值越小丢包率越小, 反之亦然.
| 级别 | 低 | 中 | 高 | 极高 |
| :---: | :---: | :---: | :---: | :---: |
| 低丢包可能性 | AF11 (001 010) | AF21 (010 010) | AF31 (011 010) | AF41 (100 010) |
| 中丢包可能性 | AF12 (001 100) | AF22 (010 100) | AF32 (011 100) | AF42 (100 100) |
| 高丢包可能性 | AF13 (001 110) | AF23 (010 110) | AF33 (011 110) | AF43 (100 110) |

4. DF(Default Forwarding, 默认): 尽最大努力型的通讯, 格式为`000 000`

#### 3.1.3 具体应用
* CS6和CS7默认用于协议报文, 因为如果这些报文无法接收的话会引起协议中断, 而且是大多数厂商硬件队列里最高优先级的报文.
* EF用于承载语音的流量, 因为语音要求低延迟, 低抖动, 低丢包率, 是仅次于协议报文的最重要的报文.
* AF4用来承载语音的信令流量, 这里大家可能会有疑问为什么这里语音要优先于信令呢? 其实是这样的, 这里的信令是电话的呼叫控制, 你是可以忍受在接通的时候等待几秒钟的, 但是绝对不能允许在通话的时候的中断. 所以语音要优先于信令.
* AF3可以用来承载IPTV的直播流量, 直播的实时性很强需要连续性和大吞吐量的保证.
* AF2可以用来承载VOD的流量, 相对于直播VOD要求实时性不是很强, 允许有时延或者缓冲.
* AF1可以承载不是很重要的专线业务, 因为专线业务相对于IPTV和VOICE来讲,IPTV和VOICE是运营商最关键的业务, 需要最优先来保证. 当然面向银行之类需要钻石级保证的业务来讲, 可以安排为AF4甚至为EF
* 最不重要的业务是Internet业务, 可以放在BE模型来传输. 这也是我们为什么老抱怨网络不好
可以说, 有了DSCP, 就初步实现了通讯业务中的时间管理, 我们日常的通讯业务才能保质保量地高效运行

### 3.2 CU(currently unused)
保留位, 一般兼容DS的设备会忽略这个field. 现在作为ECN(Explicit Congestion Notification, 显式拥塞通知)位.
