---
title: SACK
category:
  - Network
tag:
  - Network
abbrlink: '5730'
date: 2016-06-14 20:28:20
---

## 1. TCP Selective Acknowledgment Options
一个会话中的多个丢包会对TCP吞吐量造成灾难性打击, TCP使用累计ACK机制来接收未被确认的segment. 这会强制要求sender等待一个RTT来查看是否丢包, 并且避免了重传那些这些的segment. 正是由于累计ACK机制, TCP会因多个segment丢失导致吞吐量下降.
SACK(The Selective Acknowledgement)正是为了解决多个segment丢失问题. receiver可以通知sender所有已经发送成功的segment, 所以sender只需要重传那些已经丢失的segment.
SACK拓展使用了两个TCP option:
* SACK-permitted. 用于启动SACK.
* SACK option本身. 在SACK-permitted之后就可以传输SACK本体.


## 2. SACK-Permitted Option
一般都在TCP的SYN和SYN-ACK中, 占2字节, 不能传送在非SYN的segment中.
```null
+----------+------------+
|  Kind=4  |  Length=2  |
+----------+------------+
```


## 3. Sack Option格式
SACK option用于同一会话中receiver传输给sender发送的ACK信息.

```null
                  +--------+--------+
                  | Kind=5 | Length |
+--------+--------+--------+--------+
|      Left Edge of 1st Block       |
+--------+--------+--------+--------+
|      Right Edge of 1st Block      |
+--------+--------+--------+--------+
|                                   |
/               . . .               /
|                                   |
+--------+--------+--------+--------+
|      Left Edge of nth Block       |
+--------+--------+--------+--------+
|      Right Edge of nth Block      |
+--------+--------+--------+--------+
```
SACK option中的每一个block都有同一个会话中receiver传输给sender的连续SEQ, 但同一个option中的两个block是不连续的. 一个block有两个32位的unsigned整数:
1. Left Edge of Block: 连续Seq中的第一个sequence number
2. Right Edge of Block: 该block中最后一个sequence number


## 4. 例子
下面用一个实例来说明整个SACK流程, 下面提到的sequence number都是相对值(relative), 并不是真实的sequence number.

### 4.1 SACK-permitted
首个SYN报文中的Options选项中会有SACK Permitted Option: Kind:4, Length:2
然后在SYN-ACK的报文中会有SACK Permitted Option: Kind:4, Length:2
这样双方都表明支持SACK.

### 4.2 丢包流程
1. sender给receiver发送的segment的seq number为72933, 长度为1448
2. receiver回复ACK, ack number为74381, 表明上一个segment已接收
3. sender给receiver发送的segment的seq number为77029, 长度为1448 - 发生了丢包
4. receiver发现segment丢失, 回复ack number为74381, 并且在Options中设置SACK:
    * Kind: 5
    * Length: 10
    * Left Edge of Block: 77029
    * Right Edge of Block: 78477
5. sender给receiver发送的segment的seq number为78477, 长度为1200
6. receiver发现丢失的segment还没重传, 继续回复ack number为74381, 并继续设置SACK:
    * Kind: 5
    * Length: 10
    * Left Edge of Block: 77029
    * Right Edge of Block: 79677
7. 后续的sender一直没有重传seq number为74381的segment, 所以receiver将ACK segment中的ack number设置为74381, 并不断扩大SACK中的block:
    * Kind: 5
    * Length: 10
    * Left Edge of Block: 77029
    * Right Edge of Block: 109517

### 4.3 重传
1. sender给receiver发送的segment的seq number为74381, 长度为1448
2. receiver发现sender重传了需要的segment, 但是还没有连上option中的Left Edge of Block(77029), 所以回复的ack number为75829, 并设置SACK:
    * Kind: 5
    * Length: 10
    * Left Edge of Block: 77029
    * Right Edge of Block: 109517
3. sender给receiver发送的segment的seq number为75829, 长度为1200
4. receiver发现重传的segment使得整个ack number连贯起来, 所以回复的ack number为109517, 并不再添加SACK option.


## 5. SACK优缺点
在高延迟的连接中, SACK对于有效利用所有可用带宽尤其重要, 使得出现丢包后只需重传所需数据即可, 这样能在不降低传输速率的基础上适应高丢包率.
缺点也很明显, 处理SACK需要消耗CPU资源, 尤其是处理无效和恶意的SACK时, 会占用大量资源.