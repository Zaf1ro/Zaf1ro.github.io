---
title: VLSM (Variable-Length Subnet Mask)
category:
  - Network
tag:
  - Network
abbrlink: 4ca2
date: 2017-06-13 19:54:27
---

## 1. 特定网络需求的满足
每个IPv4可拆分为网络部分(network part)和主机部分(host part), 分为了A, B, C, D, E五类:

Class | Network Part | Octet | Private Address
-----|-----|-----|-----
A | 0xxxxxxx | 0.x.x.x - 127.x.x.x | 10.0.0.0 – 10.255.255.255  127.0.0.0 - 127.255.255.255
B | 10xxxxxx xxxxxxxx | 128.x.x.x - 191.x.x.x | 172.16.0.0 – 172.31.255.255  169.254.0.0 - 169.254.255.255
C | 110xxxxx xxxxxxxx xxxxxxxx | 192.x.x.x - 223.x.x.x | 192.168.0.0 – 192.168.255.255
D | N/A | 224.x.x.x to 239.x.x.x | N/A
E | N/A | 240.x.x.x to 255.x.x.x | N/A

由于D类IP用于组播地址, E类IP用于未来和实验使用, 所以并不能用于公网(public network)中.
以一个B类地址为例: `172.16.0.0`, 需要将这个网段分给200台主机, 其中100台给A部门, 100台给B部门. 由于B类地址的host part有16位, 所以可用的IP地址有6万多个, 如果只把这个网段的IP地址分给这200台主机就过于浪费IP地址.


## 2. Subnetting(子网划分)
子网划分的意义在于从host part中借某些IP address作为subnet. 以上述为例, 可将`172.16.0.0`拆分为多个subnet已达到节约IP address的目的. 并且, subnet可再拆分为多个subnet

### 2.1 Subnet Mask(子网掩码)
由于subnet的存在, 某IP address中的host part并不能表示出该IP address所处在的subnet, 这时就需要subnet mask来表示全新的network part和host part

128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 | Subnet Mask
-----|-----|-----|-----|-----|-----|-----|-----|-----
1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 128
1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 192
1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 224
1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 240
1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 248
1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 252
1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 254
1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 255

上面为8位bits所表示的subnet mask, 以下是部分subnet mask

Prefix size | Subnet mask | Available subnets | Usable hosts per subnet
-----|-----|-----|-----
/24 | 255.255.255.0 | 1 | $2^8 - 2$
/25 | 255.255.255.128 | 2 | $2^7 - 2$
/26 | 255.255.255.192 | 4 | $2^6 - 2$
/27 | 255.255.255.224 | 8 | $2^5 - 2$
/28 | 255.255.255.240 | 16 | $2^4 - 2$
/29 | 255.255.255.248 | 32 | $2^3 - 2$
/30 | 255.255.255.252 | 64 | $2^2 - 2$
/31 | 255.255.255.254 | 128 | $2^1 - 2$

### 2.2 Example
* 假如我们需要将`172.16.0.0/16`划分为100个subnet, 那么host part需要最大能有多少位?
* 由于需要100个subnet, 那么起码需要7位network part($2^7 = 128 > 100$), 由于该private network已经有16位network part, 再加上需要的7位, network part总共需要23位, 所以剩下的host part最多能有9位.


## 3. VLSM
可变长子网掩码可以通过不同掩码长度来满足subnet的不同IP address数量

### 3.1 Example
![VLSM示例](/images/Network/VLSM/3.1_1.png)

上图中A, B, C三个subnet的host part有5位, 所以可容纳32个IP address. D, E两个subnet的host part有8位, 所以可容纳256个IP address. 两个网段的subnet mask不同可满足不同的IP address数量

### 3.2 Steps to determine subnet address
* 假设IP Address: `192.168.221.37`, Subnet Mask: `/29`, 求Subnet的相关信息

Step | Description | Example
-----|-----|-----
1 | 将IP Address拆为二进制 | 最后八位: 0010 0101
2 | 将Subnet Mask拆为二进制 | 最后八位: 1111 1000
3 | 将IP Address和Subnet Mask对齐 | 0010 0101  1111 1000
4 | 将IP Address和Subnet Mask取与操作 | 最后八位: 0010 0000
5 | 通过上述操作后得到的IP Address可得到如下信息 | Network Address: 192.168.221.32  Subnet Mask: 255.255.255.248  First host address: 192.168.221.33  Last host address: 192.168.221.38  Boardcast address: 192.168.221.39  Next Subnet: 192.168.221.40

* 假设IP Address: `172.16.139.46`, Subnet Mask: `/20`, 求Subnet的相关信息

Step | Description | Example
-----|-----|-----
1 | 将IP Address拆为二进制 | 最后十六位: 1000 1011 0010 1110
2 | 将Subnet Mask拆为二进制 | 最后十六位: 1111 0000 0000 0000
3 | 将IP Address和Subnet Mask对齐 | 1000 1011 0010 1110  1111 0000 0000 0000
4 | 将IP Address和Subnet Mask取与操作 | 最后十六位: 1000 0000 0000 0000
5 | 通过上述操作后得到的IP Address可得到如下信息 | Network Address: 172.16.128.0  Subnet Mask: 255.255.240.0  First host address: 172.16.128.1  Last host address: 172.16.143.254  Boardcast address: 172.16.143.255  Next Subnet: 172.168.144.0

* 假设某Subnet为: `172.16.32.0/20`, 需要将该Subnet分出四个Subnet, 其中每个Subnet都有50个Host, 求Subnet的相关信息

![VLSM示例2](/images/Network/VLSM/3.2_1.png)

可以看出, 这个网络中需要规划8个subnet, 其中1号到4号subnet分别需要两个IP Address, 分别对应两个路由器的一端, 而5号到8号subnet则分别需要50个IP Address.
划分子网时需先满足需要IP Address最多数量的子网, 该例中需要的最多IP Address为50个, 所以host part需要有6位($2^6 = 64 > 50$), 而`172.16.32.0`这个子网的mask为20位, 所以剩下可分配的host part为12位, 所以划分子网后剩下的network part为6位($32 - 20 - 6$)
```TeX
Subnetted Address: 172.16.32.0/20
1010 1100 0001 0000 0010 0000 0000 0000

VLSM Address: 172.16.32.0/26

5st subnet: 最后16位: 0010 0000 0000 0000 172.16.32.0/26
6st subnet: 最后16位: 0010 0001 0000 0000 172.16.32.64/26
7st subnet: 最后16位: 0010 0010 0000 0000 172.16.32.128/26
8st subnet: 最后16位: 0010 0011 0000 0000 172.16.32.192/26
```
剩下的4个subnet分别需要2个IP Address, 所以需要2位($2^2 = 4 > 2$)host part即可满足, 其他位都可以设为network part. 我们把`172.16.33.0/26`切分给`/30`.
```
Subnetted Address: 172.16.32.0/20
1010 1100 0001 0000 0010 0000 0000 0000

VLSM Address: 172.16.32.0/30

1st subnet: 最后8位: 0011 0000 0000 0000 172.16.33.0/30
2st subnet: 最后16位: 0011 0000 0000 0100 172.16.33.4/30
3st subnet: 最后8位: 0011 0000 0000 1000 172.16.33.8/30
4st subnet: 最后8位: 0011 0000 0000 1100 172.16.33.12/30
```
最后还剩下59个`/29`的subnet和12个`/30`的subnet


## 4. Route Summarization(路由汇总)
由于Router中的routing table需要记录所有路由信息来转发信息, 但是由于VLSM的mask, 导致routing table变得十分大, 转发的效率也变得很低, 这时就需要Route Summarization. 路由汇总有两个好处:
* 减少向上游路由汇报的路由条目
* 隐藏下游拓扑变动

### 4.1 路由匹配规则
1. Router在匹配IP Address时只比对subnet mask规定的位数
例如: `172.16.0.0/20`和`172.16.3.1/20`, 由于这两个IP Address的前20位一样, 所以Router认为是同一网段.
2. Router按照最长匹配(long prefix match)的原则

IP Address | Subnet Mask | Name
-----|-----|-----
192.16.5.33 | /32 | Host
192.16.5.32 | /27 | Subnet
192.16.5.0 | /24 | Network
102.16.0.0 | /16 | Block of Networks
0.0.0.0 | /0 | Default

`192.16.5.33`与下面的四组IP Address都匹配, 但是依照最长匹配原则, 还是会转发到`192.16.5.32`的subnet中

### 4.2 汇总
多个subnet中可能只有个别位有变化, 例如:

IP Address | 最后16位
-----|-----
172.16.168.0/24 | 1010 1000 0000 0000
172.16.169.0/24 | 1010 1001 0000 0000
172.16.170.0/24 | 1010 1010 0000 0000
172.16.171.0/24 | 1010 1011 0000 0000
172.16.172.0/24 | 1010 1100 0000 0000
172.16.173.0/24 | 1010 1101 0000 0000
172.16.174.0/24 | 1010 1110 0000 0000
172.16.175.0/24 | 1010 1111 0000 0000

上述几个subnet中只有22, 23, 24位在变化,其他的位数都没有改变, 所以可将这几个subnet的路由信息汇总为一条: `172.16.168.0/21`

### 4.3 汇总的缺陷
不连续的网络中汇总会导致上游路由对下游路由不够了解, 导致数据包走向不正确的subnet