---
title: VLAN
category:
  - Network
tag:
  - Network
abbrlink: 3b60
date: 2017-06-15 14:45:21
---

## 1. 交换设备
### 1.1 Hub
* 二层设备, 只能连接同一网段的设备
* 带宽平分
* 同一时间两个设备发送给Hub的信号会冲突
* 只能应用于少量的主机
* 某个设备发出的信息会被Hub连接的其他所有设备收到

![Hub](/images/Network/VLAN/1.1_1.png)

Host A发送给Host B信息, Host C和D也能收到信息

### 1.2 Bridge
* 具有二层的过滤功能(根据MAC信息)
* 可以连接不同的网段
* 由于是软件来过滤和转发信息, 所以不能全速转发
* 具有少量端口
* 两个接口的传输速率必须相同

![Bridge](/images/Network/VLAN/1.2_1.png)

Host A发送给Host B信息, 其他Host不会收到信息

### 1.3 Switch
* 二层设备, 连接不同网段
* 由于是硬件处理, 可达到线速转发, 并实现过滤功能(基于MAC地址)
* 有大量端口
* 使用了微分段(Micro Segmentation)技术, 为每个网段都划分不同的冲突域(Collision Domain), 所以不会产生信号冲突
* 接口全双工模式(可同时收发信息)
* 接口速率调节(两端的传输速率可不同)

![Bridge](/images/Network/VLAN/1.3_1.png)

Host A发送给Host B信息, 其他Host不会收到信息

### 1.4 MAC Table
Switch通过MAC Table实现过滤功能, 这样其他主机就不会收到信息, 因此减少了网络上的负荷并提高了安全性
* Switch启动时, MAC Table为空. 
* 在收到第一个数据包后, 会记录该接口和源MAC地址. 
* 由于不知道往哪个接口转发, 所以执行泛洪操作(flooding, 向所有接口转发).
* 目的主机在接受到数据包后会作出响应, Switch因此学习到了目的主机的MAC地址

除了目标地址未知时进行的泛洪操作, Broadcast和Multicast也进行泛洪操作.

### 1.5 Transmitting Frames
Switch有三种传输数据包模式:
* Cut-Through: 最快, 最不可靠. 在接收到目的地址后立即转发, 不进行FCS校验.
* Fragment-Free: 检查前64字节(因为冲突产生的数据包小于64字节), 并立即转发, 不进行FCS校验.
* Store and Forward: 最可靠, 最慢. 完全读取数据包, 并进行FCS校验, 再进行转发.


## 2. VLAN
### 2.1 现在企业网络结构
由于交换机的接口有限, 并且主机并不一定在同一楼层或者同一楼, 所以需要对网络进行分层.
![现在企业网络架构](/images/Network/VLAN/2.1_1.png)

* 最上面一层为接入层(Access Layer), 直接连接主机, 一般分布在大楼的每一层中. 接入层的设备通常为中低端设备, 不需要太高性能. 只具有基本的网络防护策略.
* 中间层为汇聚层(Distribution Layer), 一般布置在每一层的机房, 负责汇聚接入层的数据. 并且设备为多层交换机(具有路由功能), 并且一般为中高端设备. 具有一定的交换策略(数据的隔离和优先级选择等).
* 最下面一层为骨干层(Campus Backbone), 负责全网的数据交换和转发, 设备采用高端设备. 不做任何策略, 只负责高速转发数据.

为了实现冗余性, 一般在多层之间采取多线互连, 这样能避免单点故障导致的网络不可用. 

### 2.2 现有设计网络架构中的问题
* 由于交换机不隔离Broadcast domain, 所以导致全网Broadcast domain增大
* 未知单播包和组播会导致泛洪, 所以导致全网转发效率降低
* 主机数量增加的同时导致管理变得困难
* 会导致未知的网络安全隐患

### 2.3 VLAN概述
VLAN(Virtual LAN)通过对Switch中接口的逻辑划分实现了网络的分段(Segmentation), 灵活性(Flexibility)和安全性(Security). 这样就将物理上连接的接口通过逻辑划分来拆分成多个广播域和子网, 这样不同VLAN的广播, 泛洪都不会跨到其他VLAN之中.

### 2.4 VLAN划分
* 按照物理位置划分: 每个楼层的主机一个VLAN, 或某些地区的主机一个VLAN
* 按照部门职能划分: 根据公司部门的不同来划分不同的VLAN
* 按照流量类型划分: 一般需要单独划分VLAN的Traffic type有以下几种:
  * IP telephony(语音流量)
  * IP Multicast(组播流量, 可能是组内的视频流量)
  * Network management
  * Normal data

### 2.5 VLAN Trunking
由于VLAN的划分, 导致两个Switch上的数据无法通信. 如果想实现两个Switch的VLAN互连, 需要为每个VLAN多一个接口互连另一个Switch, 很明显这样是不可能的. 所以需要另一种方法来使得两个Swtich中相同VLAN能够通信. 
![Trunk](/images/Network/VLAN/2.5_1.png)

需要在每个Switch开一个Trunk接口, 并通过Trunk协议来区分不同的VLAN流量, 有两种Trunk协议:
* 802.1Q
IEEE标准协议, 在原数据帧中插入4bytes, 但需要重新计算FCS. 如果Trunk线路中出现了没有Tag的流量, 则统一归为Native VLAN(一种特殊的VLAN划分)中.
![802.1Q](/images/Network/VLAN/2.5_2.png)

* ISL
思科的私有协议, 支持PVST, 并使用封装形式来处理数据帧, 这样就不会修改原数据帧
![ISL](/images/Network/VLAN/2.5_3.png)


## 3. VTP
由于企业网络可能包含上百台Switch, 手工配置十分麻烦, 并且后期维护和修改也很复杂, 容易出现安全隐患. 为了简化大型网络配置, 可使用VTP协议.
![VTP](/images/Network/VLAN/3.1_1.png)

VTP协议采用C/S结构, 其中一台Switch作为Server, 其他的Swtich作为Client. 通过Server端组播VLAN配置信息来部署Client上的VLAN. 由于是Switch之间的连接, 所以需要通过Trunk接口连接. VLAN策略的发送是自动的, 并且是递归的, 每一个Client在接收到信息后会转发给所连接的剩下的Client.
还可以通过VTP Domain来划分Server上不同的策略, Client只会同步和其VTP Domain相同的策略信息. 以下是VTP协议在Switch中的三种模式:
* Server
  * 创建VLAN
  * 删除VLAN
  * 修改VLAN
  * 发送VTP通告(2层协议, 周期性发送)
  * 同步
* Client
  * 不能创建VLAN
  * 不能删除VLAN
  * 不能修改VLAN
  * 发送VTP通告
  * 同步
* Transparent
  * 创建本地VLAN
  * 删除本地VLAN
  * 修改本地VLAN
  * 发送VTP通告
  * 不同步
    
在不设置VTP协议时, Switch默认为Server mode. VTP server和client会同步最新的revision number(每一次更新server会将revision number加1), 从而通过revision number来让client判断该VTP通告是否为最新. 
