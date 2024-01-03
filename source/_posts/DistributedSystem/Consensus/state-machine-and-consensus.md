---
title: State Machine and Consensus
tags:
  - Distributed System
category:
  - Distributed System
abbrlink: '5557'
date: 2022-04-25 17:39:15
keywords:
description:
---

## 1. Model of Computation
在**电子计算机**诞生前, 人们已经发明了机械计算器(mechanical calculator), 并梦想铸造一台机器来计算任何数学陈述的**truth value**(真值), 例如: 4的算数平方根为5, 该陈述可判定为false. 于是, David Hilbert和Wilhelm Ackermann于1928年提出一个问题: 是否存在一个算法, 可根据输入(也就是一个数学陈述), 判断输入是否普遍正确(universally valid)并输出Yes或No, 该问题称为**Entscheidungsproblem**(可判定性问题).
证明`某个算法能够判断一切陈述`是十分困难的, 但证明`某个陈述无法被判断`是比较容易的. 图灵将该问题转化为: 是否存在一种算法, 其可以判断任意程序是否会永远运行, 或中途停止, 该问题称为**halt problem**(停机问题). 由于停机问题是众多陈述中的一种, 如果该问题无法被判断, 则Entscheidungsproblem不为真.
但这引出一个新的问题, 什么是算法, 或者说, 算法的边界在哪里? 如果不回答这个问题, 陈述是否能够被判断也无从解答. 为此, 图灵提出一种假想的机器, 称为**a-machine**(automatic machine, 自动机), 后来被称为**Turing machine**(图灵机).

### 1.1 Turing machine
图灵机使用一个无限长的**tape**(纸带)作为内存, tape上有一些**symbol**(符号), 这些符号构成了一个**alphabet**(字母表), 其中包含一个特殊符号**blank**(空字符). 一开始tape会有一些符号, 图灵机可在tape上左右移动, 并读取/写入tape上的符号. 以下是图灵机的数学模型:
一台图灵机是一个**7-tuple**(七元有序组): $(Q, \Sigma, \Gamma, \delta, q_\text{0}, q_\text{accpet}, q_{reject})$
* $Q$为有限非空的state集合
* $\Gamma$: 有限非空的symbol集合, 表示tape上的字符表
* $\Sigma$: 不包含空字符的字符表, $\Sigma \in \Gamma$
* $\delta$: $Q \times \Gamma \rightarrow Q \times \Gamma \times \\{ L,R,- \\}$ 是**transition function**(转移函数), 其中$L$表示向左移, $R$表示向右移, $-$表示不移动
* $q_\text{0} \in Q$为起始状态
* $q_\text{accept} \in Q$为接收状态, $q_\text{reject} \in Q$为拒绝状态, $q_\text{accept} \neq q_\text{reject}$

图灵机一开始从tape的最左端读取symbol, 直到遇到第一个空字符, 假设读取前n个symbol($w = w_1 w_2 \cdots w_n \in \Sigma$). 一旦图灵机启动, 会根据转移函数, 当前状态, 和当前读取的字符, 生成新的状态, 字符, 并在tape上移动. 若在某个时刻state进入$q_\text{accept}$, 则立刻停机并接受输入的字符; 若state进入$q_\text{reject}$, 则立即停机并拒绝输入的字符. 对于图灵机, state的修改, tape上内容的修改, 和tape上位置的更改, 这三者组成了图灵机的**configuration**(配置).

### 1.2 The Church-Turing Thesis
图灵证明了图灵机是一种十分强大的**model of computation**(计算模型), 并由此诞生了**The Church-Turing thesis**(邱奇-图灵论题): 任何计算或算法都可由一台图灵机来执行, 换句话说, **图灵机即算法**, 图灵机能解决的问题, 算法才能解决; 图灵机不能解决的问题, 任何算法都不能解决.
该论题的意义十分深刻, 其不仅指出算法的局限性, 还影响了计算机科学之后的发展: 在此之前, 人们认为`机械执行任务的过程`就是**computation**(计算), 而图灵机准确定义了什么是计算, 以至于现代计算机上运行的所有编程语言都遵循这一理念.
但需要注意, 该论题并不是一个数学定理, 也就是说, 其没有被证明; 但目前也没有任何例子来反驳该论题. 除了图灵机, 还有其他计算模型, 其中一些计算模型称为**Hyper computation**(超计算), 旨在研究比图灵机更强计算能力的计算机, 但目前只存在于理论, 由于现实世界的物理规则限制而无法构建.

### 1.3 Halting problem
回到Entscheidungsproblem问题, 图灵用一个悖论证明了图灵机不可能判断停机问题:
1. 假设存在一个图灵机`H`, 其可以判断任何程序是否会永久运行. 若程序能够中途停止, 返回YES; 否则返回NO
2. 现在我们在图灵机`H`的输出端添加一个转换器, 当`H`返回YES时, 则掉入一个死循环; 否则中止运行, 并将该程序称为`H+`
3. 现在让图灵机`H`判断程序`H+`是否会永远运行:
     * 若`H`返回YES, 程序会陷入永久运行, 与判断结果相悖
     * 若`H`返回NO, 程序会中止运行, 与判断结果相悖

上述表明, 停机问题无法在图灵机上得到判断, Entscheidungsproblem也就得到了否定回答.


## 2. Finite-State Machine
**Finite-state machine**(FSM, 有限状态机), 也称为**finite-state automaton**(FSA), 其和图灵机一样, 也是一种**计算模型**. 任何时刻, FSM只处于一种**state**(状态); 接收到输入时, FSM会改变自身状态, 一种state到另一种state称为**transition**(过渡).
FSM可分为两类:
* Deterministic finite-state automaton(确定有限状态机, DFA)
* Nondeterministic finite-state automaton(非确定有限状态机, NFA)

这里先给出DFA的数学定义: 一个**5-tuple**(五元有序组), $(Q, \Sigma, \delta, q_\text{0}, F)$
* $Q$: state的有限集合
* $\Sigma$: 输入字符(symbol)的有限集合, 称为**alphabet**(字母表)
* $\delta$: 过渡函数, $Q \times \Sigma \rightarrow Q$
* $q_\text{0} \in Q$: 初始状态
* $F \subseteq Q$: 接受状态的集合

以下是DFA和NFA的区别:
* DFA中, $\delta$(过渡函数)的每个输入($\Sigma$中一个symbol)只有一个输出状态; NFA可有多个输出状态
* DFA中, $\delta$(过渡函数)的输入只包含$\Sigma$中的symbol; NFA可包含空字符$\varepsilon$

FSM可看作图灵机的子集, 其计算能力小于图灵机, 但更容易实现和理解. 两者的主要区别如下:
* 图灵机支持在tape(输入)上读写; FSM可读取输入, 但不能修改输入
* 图灵机支持在tape上左右移动; FSM只能一直向右读取(向前读取), 不能回读
* 图灵机的tape是无限大的; FSM没有tape这个内存概念, 换句话说, 没有保存信息的功能


## 3. State Machine Replication
回到分布式系统, 我们一般使用**state machine replication**(SMR, 状态机复制)来**复制服务器**和**协调客户端与服务器副本的交互**, 以提供容错能力. 该方法还为理解和设计**replication management protocol**(复制管理协议)提供了一个框架.
假设有两个服务器, 若它们能保持同步, 则互为对方的副本. 当一个服务器进行更新操作, 需告知另一个服务器, 以保持同步; 一旦其中一个服务器发生故障, 另一个服务器可接管服务. 
因此可将一个服务器视作一个FSM, 每个服务器都以相同初始状态开始, 并以相同顺序接收到相同输入, 服务器的状态也会保持一致. 但该FSM必须是**确定的**, 也就是DFA.
集群中最少需要三台服务器才能实现容错: 若某个服务器存在错误, 我们可对比该服务器和另外两个服务器的状态和输出, 以此判断该服务器是否出错. 进一步推论: 假设集群容许`F`台服务器发生故障, 则集群需要`2F+1`个副本. 需要注意的是, 这里提及的**故障**为随机独立故障, 如硬件错误.

### 3.1 The State Machine Approach
基于DFA的服务器集群可按照以下步骤实现一个具有容错能力的服务:
1. 将状态机拷贝到多个独立服务器上
2. 接收客户端请求, 并编码为状态机的输入
3. 选择一个输入的**ordering**(顺序)
4. 在每个未发生故障的服务器上执行输入
5. 将状态机的输出返还给客户端
6. 监视副本间的状态差异

上述步骤蕴含了两个抽象:
* Agreement: 每个未出故障的状态机都接收到每个请求
* Order: 每个未出故障的状态机都以相同顺序处理请求

可以发现, 若想实现上述两个抽象, 不可避免要面对服务器间的通信.

### 3.2 Agreement
为实现**Agreement**抽象, 通信协议需指定某个服务器(称为transmitter)以以下方式将**输入**传播给其他服务器:
* 所有未出故障的服务器都同意相同的值
* 若transmitter未出故障, 则所有未出故障的服务器都使用它的输入作为自己的输入

若每当客户端发出请求时, 其都能遵循上述两个要求, 并发送到所有服务器, 则该集群实现了**Agreement**. 需要注意的是, Agreement并没有指定transimitter, 客户端或集群中的某个服务器都可成为transimitter(一般不会让客户端作为transmitter).

### 3.3 Order
为实现**Order**抽象, 客户端需为请求分配一个唯一标识符, 让服务器根据该标识符的排序关系处理请求. 然而, 只是让服务器按升序处理收到的请求并不意味着每个服务器都以相同顺序处理请求: 服务器收到请求`p`并处理, 之后可能收到标识符小于`p`的请求.
以下是几种消息传递顺序的保证:
* Single-source FIFO: 若某个服务器发送消息$m_1$和$m_2$, 其他进程不会在收到$m_1$前收到$m_2$
* Totally ordered: 若某个服务器在$m_2$前收到$m_1$, 其他进程也不会在$m_1$前收到$m_2$. 与FIFO不同的是: FIFO追求的是发送端和接收端的消息顺序一致, totally ordered追求的是所有接收端的消息一致, 可以与发送端不一致
* Causally ordered: 若某个服务器先发送$m_1$, 后发送$m_2$, 则所有服务器都以相同顺序接收. 与FIFO不同的是, FIFO中, 接收端在收到$m_2$前不能收到任何其他消息; causally ordered中, 接收端在收到$m_2$前可收到其他服务器的消息


## 4. Consensus
SMR提供的容错能力很美好, 但其实现涉及到分布式系统中的一个基本问题: **Consensus**(共识), 换句话说, 如何让多个实体对某个事件达成一致. 计算机领域中大量使用到共识, 如云计算, 时钟同步, PageRank, 负载均衡, 区块链等. SMR依赖于共识来决定请求以何种顺序提交给每个服务器.
共识问题需要多个进程(服务器)对单个数值形成**agreement**(约定). 由于进程会崩溃或运行错误, 共识协议应具备容错能力. 因此, 进程需以某种方式与其他进程通信, 并对某个值达成共识. 所有共识算法都有以下特性:
* Uniform Agreement: 不存在两个决定不同的节点
* Integrity: 不存在决定两次的节点
* Validity: 若节点决定了值v, 则v一定是由某个节点所提议
* Termination: 由所有未崩溃的节点做决定

共识问题很容易联想到人类社会决定或表达意见的一种方法: **voting**(投票), 当一个群体中的个体对某个事件持有不同意见时, 每个人可选择支持或反对, 以此决定整个群体对该事件的决定. 分布式系统中的共识问题也采用类似的方法: 所有进程都认可**majority value**(多数值), 每个进程提出自己的值, 超过半数的值将作为整个集群的值.


### 4.1 Consensus Protocols
分布式系统中, 最常用的公式算法为**Paxos**, 和其变种**Raft**. 这类算法有以下特征:
* synchronous(同步的)
* 依赖一个选举出的leader
* 可以接受节点崩溃, 但不能接受**Byzantine failure**(拜占庭故障, 集群中的节点会说谎)

Google实现了一个分布式锁服务, 称为**Chubby**. Chubby在文件中维护锁信息, 并为实现高可用性, 将文件复制到多个地方. 该服务也是基于Paxos共识算法.
