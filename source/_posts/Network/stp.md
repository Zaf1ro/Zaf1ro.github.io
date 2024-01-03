---
title: STP (Spanning Tree Protocol)
category:
  - Network
tag:
  - Network
abbrlink: e976
date: 2017-08-18 09:15:08
---

## 1. Redundant Topology
冗余拓扑的优点: 可防止单点故障导致的网络不可用, 从而提高网络的可靠性.
以下为冗余拓扑的缺点:
* Broadcast storms(广播风暴): 未知的单播帧, 组播帧和广播帧, 这三种帧都会引发泛洪操作. 但由于冗余拓扑构成的环路会导致广播帧不断在不同网段循环, 造成广播风暴(网络带宽被占满, 主机会死机).
![Broadcast Storms](/images/Network/STP/1.1_1.png)
* Multiple Frame Copies(多帧拷贝): 此情况出现在Bridge刚启动时, A和B的Mac地址表还没有记录, A在接受到未知单播帧后会进行泛洪, B在收到未知单播帧后也会泛洪, 使得Y收到两次相同的数据帧. 
![Multiple Frame Copies](/images/Network/STP/1.1_2.png)
* MAC address table instability(MAC地址表不稳定): A和B在同时收到未知单播帧后会进行学习, 将X的MAC地址和Port 1绑定在一块, 然后从Port 2发送出去. A和B在收到对方的数据帧后会将X的MAC地址和Port 2绑定在一起, 并从Port 1发出去, 依次循环. 但如果A和B不是同时收到X的单播帧, 那么就不会出现这种情况
![MAC address table instability](/images/Network/STP/1.1_3.png)
    
由于无法从物理上解决环路带来的问题, 所以需要从软件层上进行处理.


## 2. STP(Spanning Tree Protocol)
### 2.1 概述
生成树协议在软件层面上杜绝了环路的存在, 使得某些接口在逻辑上关闭, 并在无可用接口时启用这些关闭的接口. STP发布在IEEE 802.1D, 并固化在Bridge中.

### 2.2 基本名词
* root bridge(根网桥): 用来集中转发数据, 通常为核心交换机(性能最强的switch)
* root port(根接口): 与root bridge开销最小的接口(不一定是直连接口)
* designed port(指定接口): 用于接收转发数据的接口
* nondesigned port(非指定接口): 不被使用的接口

### 2.3 基本规则
* 每个broadcast domain(每个VLAN)只有一个root bridge
* 每个非root bridge上都有一个root port
* root bridge上的接口都是designed port
* 每个broadcast domain中只有一个designed port
* 不使用non-designed port

![sample of STP model](/images/Network/STP/2.3_1.png)


## 3 Root Bridge选择策略
STP通过BPDU(Bridge Protocol Data Unit, 桥接协议数据单元)来选择root bridge, 每2秒发送一次来传送BPDU并重新协商. 

### 3.1 BPDU的结构
Bytes | Field
----|-----
2 | Protocol ID
1 | Version
1 | Message type
1 | Flags
8 | Root ID
4 | Cost of path
8 | Bridge ID
2 | Port ID
2 | Message age
2 | Max age
2 | Hellotime
2 | Forward delay

以下会介绍几个BPDU中主要的Field:
1. Root ID: 记录当前网段中root bridge的ID, 结构与Bridge ID相同.
2. Cost of Path: 用来选举root port, 开销由Link Speed决定, Link Speed越大, 开销越小, 越容易被选择为root port. 如下:

Link Speed | Cost
---- | ----
10Gb/s | 2
1Gb/s | 4
100Mb/s | 19
10Mb/s | 100

3. Bridge ID: Bridge ID用来标明自己. Bridge ID分为两块:
  * Bridge Priority(16bits): 标志该Bridge的优先级, 数值越小说明bridge优先级越高. 最大为65535, 默认为32768.
  * MAC Address(48bits): 标志该Bridge的MAC地址. 但两个Bridge优先级相同时, MAC地址越小越优先选择.
4. Port ID: 用来标明发出BPDU的端口编号(如: 24号端口)
5. Message age: BPDU最大存活时间(20s)
6. Max age: blocking state下的等待时间
7. Hellotime: 两台Bridge之间交换BPDU的时长(默认2s, 可调整为1s-10s)
8. Forward delay: Listening state和Learning state所停留的时间(15s)

### 3.2 接口的4个状态
![STP each port through 4 different states](/images/Network/STP/3.2_1.png)

1. root port和designed port都处在Forwarding state
2. non-designed port处在Blocking state
3. 当Forwarding state下的port在以下两种状态时切换到Listening state
  * 接口直接断掉
  * 两秒内没收到对方发来的BPDU, 会等待20s. 20s内还是未接收到BPDU. 
4. Listening state(15s)会从non-designed port中选择出一个作为root/designed port
5. 被选择出的root/designed port会进入Learning state(15s), 通过监听接口来填充该接口的MAC Table, 不进行转发操作(防止泛洪未知单播帧)
6. 最后从Learning state转换为Forwarding state, 进行正常的转发操作

整个故障处理时间为30s-50s

### 3.3 STP端口选择规则
1. 选取Root Bridge: 比较发送端的Bridge ID(先比较Birdge Priority, 如果相同再比较MAC Address)
2. 选取非Root Bridge的Root Port: 根据Cost of Path选择, 数值越小说明开销越小
3. 选取每个网段中的Designed Port: 由于Root Bridge上的接口都是Designed Port, 所以与Root Bridge直连的非Root Bridge上的接口一定不是Designed Port. 如果一个Segment中两个非Root Bridge的两个接口都不是Root Bridge, 那么根据Bridge ID决定那个接口是Designed Port.
4. Non-designed Port都被Block
  
若两个Bridge ID相同, 则比较Port ID, 取Port ID较小者.


## 4. STP引发的问题
刚开机的主机由于连入了Switch引起了网络拓扑变化, Switch的接入口应进入等待和学习时间(30s-50s), 那么刚开机的主机则需要等待, 直到Swtich上的接口切换为Forwarding状态. 这样会导致发送的某些数据包(如DHCP)就会无法抵达服务器.

### 4.1 PortFast
Switch可通过PortFast立即切换为Forwarding state.

### 4.2 PortFast适用范围 
PortFast只适用于Switch上的Access Port, 不适用与Trunk Port
