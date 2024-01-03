---
title: CRC (Cyclic Redundancy Check)
category:
  - Network
tag:
  - Network
abbrlink: bd06
date: 2016-10-22 14:56:56
---

## 1. Cyclic Redundancy Check
CRC(循环冗余校验,Cyclic Redundary Check)是一种根据数据产生的简短固定位数校验码的一种散列函数, 主要用于检测或校验数据传输或保存后可能出现的错误


## 2. Error Control Coding
Error Control Coding(差错控制编码): 在要传输的k个bit数据后添加n-k比特的冗余位, 这样形成的n个bit的传输帧作为整体传输. 所添加的n-k个bit数据必须满足以下两个规则:
1. `T mod P == 0`
2. `T = 2^(n-k)*D + F`

其中P是双方原定的除数, F为帧检验序列(FCS, Frame Check Sequence), 对端接受到数据后可通过第一条规则来检测数据是否出错, 为0则没错, 为1则丢弃数据.


## 3. FCS in Ethernet
以下是有关FCS(帧检验序列)的流程如下:
1. 在进行CRC检验时, 发送方和接收方先预先规定一个除数, 成为G(x), 最高位和最低位必须为1
2. 假设信息字段为K位, 校验字段为R位, 则总长度为K+R, 双方预先预定的多项式为`G(x)`, 则`V(x)=A(x)G(x)=xRM(x)+r(x)`. `M(x)`为K位的信息多项式, `r(x)`为R-1位的检验多项式

Ethernet的帧校验序列(FCS)为4字节, 使用差错控制编码, 例如:
信息字段为`1101011011`(长度为10位, M(x)), 检验字段`G(x)=x^4+x+1(r=4)`, 所以除数为10011, `1101011011(0000) / 10011 = 1110`, 发送帧为`(1101011011)(1110)`, 接收端计算: `11010110111110 / 10011 = 0`, 数据正确; 若接受端发现商不为0, 则数据不正确


## 4. Header Checksum in IP
IP层的校验功能由IP报文的**Header Checksum**(首部校验和)实现, 正如名称所写, 首部校验和只针对IP报文的首部, 数据部分都交给了下一层的校验码进行校验, 长度为16bit. 步骤如下:
1. 首部校验和的字段设为0
2. 将首部其他字段分为几个单位长度为16位的字段
3. 将所有字段相加, 如果相加的和超过了16位, 则将超出部分加入最低位
4. 和取反则为校验位

例如: IP首部字段为: `4500 0028 272a 4000 4006 c0a8 0064 0e98 4c1b`, 首部之和为: `2 0817`; 由于首部之和超过16位, 因此把将2加入`0817`, 变为`0819`. 对`0819`取反, 为`F7E6`, 因此该IP报文的首部校验码为`F7E6`.


## 5. Checksum in TCP
TCP的校验码算法与IP层相同(16bits的字段相加, 多出16bits的位数加到尾数上, 再取反), 但是校验的内容不仅是TCP层的数据, 还包括部分IP层的数据(Pseudo Header):

TCP部分:
* Source Port(16bits)
* Destination Port(16bits)
* Seq Number(32bits)
* Ack Number(32bits)
* Data Offset+Reverve+Flags(16bits)
* Window Size(16bits)
* Options(n bits)
* Data(n bits)

假IP头部:
* Source Address(32bits)
* Destination Address(32bits)
* Reverved(0x00)+Protocol(0x06)
* TCP length(IP层的Total Length - IP层的Header Length)


## 6. Checksum in UDP
算法与TCP的checksum计算相同, 只是校验的内容有所不同, 包含两部分:
* IP部分与TCP校验区域相同
* UDP全部字段, 包括data部分
