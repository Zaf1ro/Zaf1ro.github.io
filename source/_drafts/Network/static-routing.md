---
title: 静态路由
category:
  - Network
  - CCNA
tag:
  - Network
abbrlink: 4256969218
date: 2017-09-04 23:32:38
---

### 1. 路由功能
* 负责在不同网段直接进行转发(3层路由)
* 通过Routing table(路由表)进行三层数据转发
* 维护Routing table信息
* 在冗余路径中进行最优路由
* 在三层转发时使用特定的转发策略

1. 默认情况下, 路由器只知道直连的路由信息
2. 非直连路由信息可通过static routes来获取

### 2. 静态路由
1. 优点:
* 占用路由器资源少
* 严格控制路由转发
* 支持广泛

2. 缺点:
* 出现网络拓扑变化时无法自动更新
* 网络规模较大时, 配置维护十分复杂

3. 路由器路由条目匹配方式
1. 路由器对数据进行精确匹配
2. 路由器只匹配子网掩码规定的位, 但优先匹配最长掩码
3. 最终必须找到一个出接口才能转发
4. 如果未匹配上, 则丢到数据包并返回ICMP报错信息

4. Static Route Configuration
```shell
RouteX(config)# ip route network [mask] {address | interface} [distance] [permanent]
```
ip route: 命令名称
network: 目标网络的IP
mask: 子网掩码
address: 下一跳IP
interface: 出接口

虽然下一跳IP和出接口两者都可以作为参数, 但由于路由器递归查找路由表, 所以填写出接口更能省去一条搜索时间:

目标网段 | 下一跳IP
-----|-----
192.168.1.0/24 | s0/0
10.1.128.0/23 | 172.16.32.3
172.16.32.0/23 | 192.168.1.254

如果想要找到10.1.128.3的出接口, 首先匹配到下一跳为172.16.32.3, 然后匹配到下一跳为192.168.1.254, 最后匹配到s0/0出接口
如果我们把172.16.32.0/23的下一跳IP改为s0/0出接口, 那么就减少一次路由搜索
但是写下一跳IP可以防止路由条目由于出接口状态变为down而消失

5. Default Routes(缺省路由)
由于路由条目太多, 所以设置一个缺省路由转发. 通过都将连向互联网的出接口或下一跳IP设置为缺省路由条目, 例如:
```sh
RouteX(config)# ip route 0.0.0.0 0.0.0.0 172.16.2.2
```
缺省路由的IP Address和子网掩码都是0, 代表任意IP Address. 缺省路由最不精准, 所以永远是最后一个被匹配.

### 3. 路由表
1. 路由条目的类型: 
    1. C: connected
    2. S: static
    3. O: OSPF
    4. B: BGP
    等等
2. 路由条目的destination network(目标网段)和subnet mask(子网掩码)
3. administrative distance(管理距离)和metric(度量值)
4. 下一跳IP地址或出接口