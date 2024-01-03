---
title: Paxos
tags:
  - Distributed System
category:
  - Distributed System
  - Consensus
abbrlink: fc33
date: 2022-04-29 13:27:30
keywords:
description:
---

## 1. Introduction
在不稳定的网络和随时发生故障的服务器的环境中, Paxos作为**consensus**(共识)的其中一个解决方案, 由Leslie Lamport于1989年提出, 成为分布式系统中实现**state machine replication**的主要方案. 

### 1.1 Consensus Problem
多个进程提议不同值, 共识算法需确保只有一个值被选中, 且**最终**每个进程都同步该值. 以下是共识的要求:
* 选中的值必须是提议值
* 只能选择一个值
* 在选出某个值之前, 进程不会认可任何一个提议值

### 1.2 Assumptions
Paxos基于以下假设:
* Process:
    * 不同进程运行速度不同
    * 进程随时发生故障
    * 进程会在发生故障后重新加入
* Network:
    * 进程间的通信需通过网络传输消息
    * 消息传递是异步的, 需经过不定时间(无延迟上限)抵达接收方
    * 消息可能丢失, 乱序, 或重复
* Number of process: 总体来说, 共识算法要求$2F+1$个进程, 才能容忍$F$个进程发生故障. 换句话说, 未发生故障的进程数量应占半数以上. 

### 1.3 Roles
Paxos共识算法中有三种身份:
* proposers(提议者): 负责发出提议值, 并试图说服acceptor同意, 并在发生冲突时充当协调者, 以推动协议继续进行.
* acceptors(接受者): 充当一个容错的媒介. Acceptor会被分配到一个小组, 称为**Quorum**(法定人数). 消息需发送给一个quorum中的所有acceptor.
* learners(学习者): 作为协议的复制因子. 一旦acceptor同意了提议, learner也会记录提议值. 为提高系统的可用性, 可增加额外的learner.

在实际实现中, 一个进程可担任多个身份. 

### 1.4 Limitation
以下是Paxos的一些限制:
* 进程必须永远诚实, 不会发送虚假消息
* 进程必须具有**persistent**(持久性), 换句话说, 进程必须记住自己所做过的动作
* 一次Paxos只能达成一次共识, 换句话说, 每次Paxos运行只能得到一个提议值. 如果想达成另一次共识, 需再次运行Paxos
* Paxos需要超过半数进程同意才能达成共识
* Paxos进程需知道多少acceptor组成了**majority**(多数)

### 1.5 Quorums
**Quorum**(法定人数)确保至少有一定数量的进程保留提议值, 从而保证了Paxos的一致性. Quorum可看做acceptor的子集, 每两个quorum至少共享一个acceptor. 通常来说, quorum会设置为超过半数的acceptor集合. 假设存在一个acceptor集合: `{A, B, C}`, 有三种quorum选择: `{A, B}`, `{A, C}`, `{B, C}`.


## 2. Choosing a Value
从Paxos的最简化模型出发: 集群中只有一个acceptor. 多个proposer向acceptor发起不同提议, acceptor选择第一个提议, 并拒绝剩下的提议. 这种方案实现简单, 但没有任何容错能力, 因此我们需要多个acceptor.
更进一步, proposer向一个acceptor集合发送提议, 每个acceptor选择是否接受该提议. 为防止提议丢失, 需要多个acceptor保留一个提议, 从而引出Paxos的第一个必要条件:
```text
P1: acceptor必须接受首个提议
```

但该条件引发一个问题: 若多个proposer同时提出不同的提议, 不同acceptor可能选择不同提议, 最终导致没有一个proposer能获得多数支持. 因此, 为满足**多数支持**和**P1**, acceptor必须能接受多个提议. 通过为每个提议分配一个唯一编号, 可通过编号区分不同提议. 因此, 一个提议由**编号**和**提议值**组成. 需要注意的是, 不同提议需持有不同编号, 这里先不讨论如何实现, 只将其当做一个前提.
当提议被超过半数acceptor接受时, 我们可以说该提议**chosen**(被选中). 一次流程可选中多个提议, 但必须保证它们的提议值是相同的, 由此引出Paxos的第二个必要条件:
```text
P2: 若提议值为$v$的提议被选中, 则编号更高的提议被选中时, 其提议值也一定为$v$
```

由于一个提议至少有一个acceptor接受时才能被选中, 因此P2也可等同于以下条件:
```text
P2a: 若提议值为$v$的提议被选中, 那么被acceptor接受且编号更高的提议, 其提议值一定为$v$. 换句话说, 一个更高编号的提议想要被acceptor接受, 其必须为$v$
```

由于异步网络通信, 被选中的提议可能没有被一些acceptor收到, 假设该acceptor为$c$, 且某个proposer故障重启后提出一个编号更高且提议值不同的提议, 由于$c$第一次收到提议, P1要求$c$接受该提议, 但由此破坏了**P2a**. 为满足P1和P2a, 不能只依赖于acceptor决定提议是否接受:
```text
P2b: 若提议值为$v$的提议被选中, 则proposer发出编号更高的提议时, 其提议值也必须为$v$
```

为满足P2b, 需证明其是否成立. 假设某个提议被选中, 其提议值为$v$, 编号为$m$, 那么满足编号$n > m$的提议, 其提议值也应为$v$. 由于编号为$n$的提议已被选中, 一定存在超过半数的acceptor接收了该提议, 也就是说, 任意一个超过半数acceptor的子集, 该集合至少包含一个acceptor, 其接受的提议值为$v$. 因此, 若想要编号为$m$的提议拥有$v$, 需确保以下条件:
```text
P2c: 对于提议值为$v$, 编号为$n$的提议, 任意一个超过半数acceptor的集合(称为$S$)满足以下两个条件之一:
1. $S$中不存在acceptor接受过编号小于$n$的提议, 也就是说, 该提议是这些acceptor收到的第一个提议
2. $S$中acceptor接受的所有编号小于$n$的提议中, $v$是编号最高的提议, 也就是说, 该提议不是这些acceptor收到的第一个提议
```

为满足P2c, 假设proposer想要提出一个编号为$n$的提议, 其必须了解编号小于$n$的最大编号提议, 这些提议已经或即将被超过半数的acceptor接受. 了解已经选中的提议很简单, 但了解即将被选中的提议很困难, 因此, proposer要求acceptor不能接收编号小于$n$的提议, 以下是**提出提议**的算法:
1. Proposer向一个acceptor集合发送编号为$n$的请求(称为**prepare**请求). 若出现以下两种情况, 则acceptor必须回复请求:
    * 若acceptor没有接受过提议, 回复proposer, 并不再接受编号小于$n$的提议
    * 若acceptor接受过编号小于$n$的提议(假设编号为$m$, $m < n$且$m$为接受过的最大编号), 回复编号$m$的提议
2. 若proposer收到超过半数acceptor的回复, 则可发起一个提议(称为**accept**请求), 假设编号为$n$, 提议值为$v$, $v$有以下两种可能:
    * 在第一步中, acceptor回复了接受过的提议, $v$为回复的提议中最大编号的提议值
    * 在第一步中, 所有acceptor都没有回复任何提议, proposer可使用最初的提议值

对于acceptor, 其会接收到两种请求: **prepare**和**accept**. 对于prepare请求, acceptor可回复任意prepare请求; 对于accept请求, acceptor遵循以下条件:
```text
P1a: 对于编号为$n$的提议, 若没有接受过编号大于$n$的prepare请求, 则可以接受该提议
```


## 3. Basic Paxos
该协议是Paxos众多实现中最基础的一种. 该协议需要两个**phase**(阶段)才能达成共识.

### 3.1 Phase 1
#### 3.1.1 Phase 1a: Prepare
Proposer生成一个消息, 称为**prepare**消息, `n`为提议的**proposal number**(提议编号, 可看做消息的唯一标识符). `n`必须大于该proposer之前发送过的prepare消息的编号, 换句话说, 一个proposer上消息的编号是单调递增的. Proposer会向一个acceptor集合发送prepare消息. 需要注意的是, prepare消息不包含提议值, 只包含提议编号`n`.

#### 3.1.2 Phase 1b: Promise
当acceptor收到prepare消息时, 会比较**该消息中的编号**(假设为`n`)和**之前回复过的prepare消息中的最大编号**(假设为`m`, 该编号的提议值为$v_m$), 存在三种可能:
* acceptor没有接受过任何promise消息, 则必须接收该提议, 并回复一个**promise**消息. 
* $n > m$: acceptor会回复一个**promise**消息, $(n, v_m, m)$, $v_m$为编号`m`的提议值, 并忽略后续编号小于`n`的prepare消息.
* $n \leq m$: 原则上, acceptor不需要回复proposer, 但可回复**denial**来优化性能, 让proposer不必再发起提议

### 3.2 Phase 2
#### 3.2.1 Phase 2a: Accept
若proposer收到超过半数acceptor的promise消息, 即可将提议值发送给acceptor, 存在两种情况:
* acceptor没有接受过提议, 则proposer可使用原本的提议值$x$
* acceptor之前接受过提议, proposer会收到提议的编号$m$和提议值$x_m$. proposer会放弃原本的提议值$x$, 而是用$x_m$

Proposer向acceptor发送**accept**消息, 其中包含编码和提议值. Acceptor收到的消息存在两种可能:
* $(n, v=x_m)$: proposer最初的提议被某个acceptor的接收值替代
* $(n, v=x)$: proposer的提议拥有最大编号

#### 3.2.2 Phase 2b: Accepted
当acceptor收到accept消息(编号为$n$, 提议值为$v$), acceptor存在两种情况:
* 若acceptor没有在Phase 1b中接受过编号大于$n$, 则将$v$作为该acceptor的提议值, 并将该**accepted**消息发送给proposer和learner
* 若已接受过编号大于$n$的提议, 则忽略该消息


## 4. Milestones
整个Paxos算法中存在三个关键时间点:
* 假设proposer提出的prepare请求, 其编号为$n$. 超过半数的acceptor接受prepare请求时, 任何编号小于$n$的提议都将被拒绝/忽略
* 超过半数的acceptor接受accept消息时, 标志着已经达成共识, 且不会再被改变
* proposer或learner收到超过半数acceptor回复的accepted消息时, 它们知道共识已经达成


## 5. Flow of Messages in Paxos
以下是Paxos算法中的一些常见情况:

### 5.1 Normal situation
下图中包含2个proposer和3个acceptor(每个竖线表示一个节点). 第一个proposer成功达成共识(编号为5, 提议值为$v_1$), 第二个proposer接受共识.
```text
Proposer    Acceptor
 |          |  |  |
 |--------->|->|->|     Prepare(5)
 |<---------|<-|<-|     Promise(5)
 |--------->|->|->|     Accept(5, $v_1$)
 |<---------|<-|<-|     Accepted(5, $v_1$)
    |       |  |  |
    |------>|->|->|     Prepare(4)
    |       |  |  |     No Response...
    |------>|->|->|     Prepare(6)
    |<------|<-|<-|     Promise(6, 5, $v_1$)
    |------>|->|->|     Accept(6, $v_1$)
    |<------|<-|<-|     Accepted(6, $v_1$)
```

### 5.2 Majority of Promises
下图中包含两个proposer, 三个acceptor. 第一个proposer获得超过半数acceptor的支持, 第二个proposer的编号为4(小于5), 永远无法获得共识.
```text
Proposer    Acceptor
 |          |  |  |
 |--------->|->|  |     Prepare(5)
 |<---------|<-|  |     Promise(5)
    |------>|->|->|     Prepare(4)
    |<------------|     Promise(4)  
```

### 5.3 Contention
下图中包含两个proposer, 三个acceptor, 两个propose的提议被互相否定, 需要一个退避算法来避免整个Paxos陷入活锁.
```text
Proposer    Acceptor
 |          |  |  |
 |--------->|->|  |     Prepare(5)
 |<---------|<-|  |     Promise(5)
    |------>|->|  |     Prepare(6)
    |<------|<-|  |     Promise(6)
 |--------->|->|  |     Accept(5, $v_1$)
 |          |  |  |     No Response...
    |------>|->|  |     Accept(6, $v_2$)
    |       |  |  |     No Response...
 |--------->|->|  |     Prepare(7)
 |<---------|<-|  |     Promise(7)
    |------>|->|  |     Prepare(8)
    |<------|<-|  |     Promise(8)
 |--------->|->|  |     Accept(7, $v_1$)
 |          |  |  |     No Response...
    |------>|->|  |     Accept(8, $v_2$)
 |          |  |  |     No Response...
```

### 5.4 Majority of Accepts
当超过半数acceptor回复了accepted消息时, 无论其他proposer的编号是高是低, 其提议值都不会被选中.
```text
Proposer    Acceptor
 |          |  |  |
 |--------->|->|  |     Prepare(5)
 |<---------|<-|  |     Promise(5)
 |--------->|->|  |     Accept(5, $v_1$)
 |<---------|<-|  |     Accepted(5, $v_1$)
```
