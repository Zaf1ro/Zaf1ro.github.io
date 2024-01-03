---
title: Raft
tags:
  - Distributed System
category:
  - Distributed System
  - Consensus
abbrlink: e16a
date: 2022-05-02 14:19:36
keywords:
description:
---

## 1. Introduction
Paxos于1989年由Leslie Lamport提出, 作为分布式系统中**共识问题**的解决方案, 一经推出就主导了共识算法的讨论: 大多数共识算法都基于Paxos. 然而, Paxos存在两个缺陷:
* Paxos对于初学者不友好: 很难用简单的语句解释整个算法, 且算法分为二个阶段, 如果没有深入理解, 可能无法明白两个阶段之间的关系, 也不清楚共识是如何达成的.
* Paxos没有提供一个良好的实现: Paxos论文没有说明一些实现细节, 且目前为止没有一个统一的实现.

由此, Raft应运而生, 由Diego Ongaro和John Ousterhout于2013年提出, 作为Paxos的替代, 主要用于实现分布式系统中的**replicated state machine**. 虽然提出的时间比Paxos晚了十多年, 但投入到很多应用中, 如etcd, RethinkDB等. Raft在不牺牲运行效率和安全性的同时, 更容易被理解和实现. Raft的前提与Paxos相同:
* 异步网络: 数据包延迟无上限, 可能丢失, 乱序, 或重复
* 非拜占庭容错: 算法中的节点保持诚实, 不会发送假消息
* 节点随时发生故障, 恢复后回到集群


## 2. Understandability
Raft使用以下两个技巧让算法更易理解:
* 拆分问题: 将一个大的问题拆分为多个小问题, 并逐个解答, 初学者可明确每一步的目的和作用. Raft将**达成共识**拆分为4个子问题:
    * Leader Election
    * Log Replication
    * Safety
    * Membership Changes
* 减少状态变换的次数: Raft会尽量减少需要考虑的状态数量, 通过消除不确定性来让系统更加连贯


## 3. Approach of the consensus problem in Raft
Paxos通过**多个proposer**和**多个acceptor**之间通信来达成共识; Raft则采用另一种思路: 若集群中存在一个leader, 其决定集群中其他服务器的数据, 那么同样能保证数据一致, 从而达成共识. 但引出一个问题: 整个系统的可用性与leader绑定, leader宕机会导致整个系统都无法提供服务. 为此, Raft算法让leader通过**election**(选举)产生, 让每个服务器都有机会成为leader:
* Leader Election: 检测leader是否发生故障, 并选出新的leader
* Log Replication: leader接收客户端的请求, 并将其应用到其他服务器上
* Safety:
    * Election Safety: 每个term(任期)最多只有一个leader
    * Leader Append-only: leader只能追加entry(条目), 不能修改或删除日志中的entry
    * Log Matching: 若两个服务器中的两个entry拥有相同的index和term, 则该index之前的entry也都相同
    * Leader Completeness: 在某个term(term为$n$)中某个entry(称为$entry_n$)被**提交**, $entry_n$会出现在该term之后(term为$m$, 满足$m > n$)所有leader的日志中
    * State Machine Safety: 若某个服务器在给定index处将entry应用到其状态机, 则其他服务器不能在相同index处应用其他entry


## 4. Raft Basics
一个Raft集群包含多个服务器, 通常为5个, 这样可容许2个服务器发生故障. 每个服务器只能处于以下三种**state**(状态)之一:
* Leader: 负责处理客户端的请求(若客户端连接到follower, follower会将leader的地址发送给客户端, 客户端再去连接leader)
* Follower: 不会主动发送任何消息, 只会回复leader和candidate的请求
* Candidate: 用于选举新的leader

以下是不同条件下的状态转换图:
![Transitions of States](/images/System-Design/Raft/4-1.png)

Raft的运行时间可切分为多个**term**(任期), 每个term的长度不同, 且拥有一个唯一编号, term的编号自动增长. 每个term都以一次**election**(选举)开始. 当某个candidate赢得选举, 其会成为该term期间的leader. 特殊情况下, 没有candidate能获得超过半数的投票, 会导致该term没有leader, 系统会进入下一轮选举. Raft确保每个term最多存在一个leader.
![Time is divided into terms, and each term begins with an election](/images/System-Design/Raft/4-2.png)

不同服务器会在不同时间点看到term的过渡, 有些服务器甚至会错过整个election或term. Term作为一个**logical clock**(逻辑时钟), 能让服务器检测到一些过时信息, 如过期的leader. 每个服务器都会保存当前term的编号(term number). 服务器发送消息需携带term编号, 接收消息时需对比自身和对方的term编号. 以下是服务器接收到消息后的不同情况:
* 若自身编号小于对方编号, 则更新为对方编号
* 若candidate或leader发现自身的编号小于其他人, 则切换为follower
* 若自身编号大于对方编号, 则拒绝该请求

Raft的所有通信都是基于RPCs, 分为两种:
* RequestVote RPC: 由candidate初始化, 用于在election中请求其他服务器的选票
* AppendEntries RPC: 由leader初始化, 用于复制entry, 提供heartbeat

若接收端没有响应, 发送端会重试RPC, 且支持并行RPC.


## 5. Leader Election
Raft使用**heartbeat mechanism**(心跳机制)来检测leader状态. 当服务器启动时, 初始状态为follower. 只要follower在一段时间内收到leader或candidate的RPC, 就会一直保持follower状态. Leader会周期性地向所有follower发送heartbeat(没有entry的AppendEntries RPC). 若follower在一段时间内没有收到任何消息(**election timeout**, 选举超时), 则假定当前没有可用的leader, 并开始选举新的leader.
为开始一次选举, follower会让自身term编号加一, 并切换为candidate. 其会先为自己投一票, 并向其他服务器发送RequestVote RPC(假设term编号为$n$), 以下是可能出现的三种情况:
* 赢得选举: candidate获得超过半数的选票. 每个服务器只能在一个term内投一次票, 遵循**先来先得**原则. 一旦candidate赢得选举, 会切换为leader, 并向所有服务器发送heartbeat来防止新的选举.
* 其他服务器已成为leader: candidate等待选票时收到AppendEntries RPC(term编号为$m$). 若$m \leq n$, 则切换为follower; 若$m < n$, 则拒绝该RPC, 并继续保持candidate状态
* 没有获得半数投票: 若多个follower同时成为candidate, 可能导致每个candidate都无法获得多数投票, 称为**split vote**(分票). candidate会在超时后发起另一轮竞选.

Raft使用**randomized election timeout**(随机选举超时)来避免split vote. 每个candidate从固定区间(通常为$[150ms, 300ms]$)随机选择一个超时时间. 因此大多数情况下会有一个candidate赢得选举; 若发生split vote, 每个candidate会在开始下一轮选举前随机等待一段时间, 这大大降低出现split vote的概率.

以下是RequestVote RPC的内容:
* term: candidate的term编号
* candidateId: candidate的唯一标识符. 每个服务器维护一个`votedFor`, 表示当前term给哪个candidate投过票, 也就是`candidateId`
* lastLogIndex: candidate最后一个entry的index
* lastLogTerm: 上一项entry的term编号

以下是RequestVote RPC的回复:
* term: 用于candidate更新自身的term编号
* voteGranted: 表示candidate是否获得选票

## 6. Log Replication
一旦选出leader, leader会开始处理客户端的请求. 无论leader还是follower, 每个服务器都维护一个**log**(日志)副本, 日志由多个**entry**(记录)组成. 一个entry包含以下内容:
* 一个term编号, 该entry创建时leader所处的term
* 一个用于状态机执行的**command**(命令), 也就是客户端的请求内容

Leader收到客户端请求后, 会将entry追加到日志中(暂不执行command), 并向其他服务器发送AppendEntries RPC来复制该entry, 会发生两种情况:
* 超过半数的follower成功保存该entry, leader执行entry中的command, 并向客户端汇报结果
* 若发生follower宕机, 运行过慢, 或网络中断, leader会一直重试AppendEntries RPC, 直到follower成功保存该entry

日志的组织形式如下:
![Logs are composed of entries, which are numbered sequentially](/images/System-Design/Raft/4-3.png)

以下是AppendEntries RPC的内容:
* term: leader的term编号
* leaderId: follower以此将客户端的请求重定向
* prevLogIndex: 上一个entry的index
* prevLogTerm: 上一项entry的term编号
* entries: 需要追加的entry列表. 如果是heartbeat, 则为空; 否则处于效率考虑, 可一次传递多个entry
* leaderCommit: 表示leader已提交的entry中, index最大的entry. 每个服务器都会维护一个`commitIndex `, 表示已提交的entry中, index最大的entry. 若$leaderCommit > commitIndex$, follower会提交之前的entry

以下是AppendEntries RPC的回复:
* term: follower的term编号, 用于leader更新自身的term编号
* success: true表示prevLogIndex和prevLogTerm成功匹配follower的日志

当一个entry被超过半数的服务器保存, leader会认为该entry被成功**committed**(提交). Raft保证所有已提交的entry都是持久的(如保存在磁盘), 且最终会被所有服务器执行. 
当一个entry被提交, 其index之前的entry也一定被提交. Leader会维护一个`nextIndex`列表, 表示每个follower下一个entry的index, 向follower发送AppendEntries RPC(包括heartbeat)时会包含该值($prevLogIndex = nextIndex - 1$).
**AppendEntries Consistency Check**表示follower收到AppendEntries RPC时进行的一致性检查. Leader发送AppendEntries RPC时, 会携带上一条entry的index(prevLogIndex)和term编号(prevLogTerm). 以下是follower可能面对的两种情况:
* 若follower在日志中找到`prevLogIndex`和`prevLogTerm`指定的entry(称为$entry_n$):
    * 若存在冲突的entry(index相同但term不同), 则删除日志中冲突的entry
    * 在$entry_n$后追加新的entry(`entries`列表里的所有entry)
    * 若$leaderCommit > commitIndex$, 则将`commitIndex`更新为$min(leaderCommit, index\\_of\\_last\\_entry)$
    * 回复AppendEntries RPC
    * 若`commitIndex`被更新, 则将已提交entry的command应用到状态机
* 若follower无法找到在日志中找到$entry_n$, 则拒绝该RPC

通过保证以下属性, Raft实现了Log Matching属性:
* index和term编号的组合可唯一标识一个entry, 换句话说, 若两个entry拥有相同index和term编号, 则它们拥有相同的command
* 若不同日志中的两个entry拥有相同index和term编号, 则该entry之前的所有entry都相同: 当AppendEntries返回时, leader从而知道follower的日志是否与自己匹配, 调整`nextIndex`, 并重新发送AppendEntries RPC.

正常运行时, leader和follower的日志保持同步, AppendEntries的一致性检查也不会失败; 但leader宕机会导致日志不一致(leader没有将所有entry复制到其他服务器上), 这些不一致会在一系列leader和follower的故障中加剧. 下图展示了leader和follower日志不一致的不同可能:
![Inconsistence of Logs in Followers](/images/System-Design/Raft/4-4.png)

上图中, 每个格子表示一个entry, 格子中的数字表示term编号. `a,b`缺少一些entry, `c,d,e,f`存在一些未提交的entry. 以f为例, 其作为term 2的leader, 写入entry后发生故障, 恢复后又成为term 3的leader, 并再次宕机.
Raft中, leader会强制follower与自己同步日志, 换句话说, follower中冲突的entry会被leader的entry覆盖. 
为了让follower的日志与自己的日志保持一致, leader必须找到所有日志一致的最新entry, 删除该entry后的所有entry, 并将该entry之后leader拥有的entry发送给follower. 所有这些操作都是为了维持AppendEntries RPC的一致性检查. 解决冲突的具体流程如下:
* 找到leader和follower的最后一个共同认可的entry, 称为$entry_m$
* 将follower日志中的$entry_m$往后的所有entry删除
* 将leader中从$entry_m$往后的entry同步给follower


还可以对协议优化, 来减少AppendEntries被拒绝的次数. 例如, 当follower发现冲突的entry时, 可返回冲突的entry和当前term中最小index的entry, leader可直接跳过该term中的所有冲突entry, 将`nextIndex`调低到一个合理值. 这样每个term内只需一次AppendEntries RPC, 而不是每个冲突entry都要发送一个AppendEntries RPC. 实际生产环境中, 这种优化不是那么必要, 因为故障发生的概率很低, 因此很少出现日志不一致.
有了上述机制, leader无需任何额外消息或机制就能恢复日志一致性, 日志会自动收敛, leader也无需覆盖或删除自身日志中的entry.
这种日志复制机制展现了理想共识的特许不过: 
* 只要多数服务器正常运行, Raft就能接受, 复制, 和应用新的entry
* 正常情况下, 单个速度较慢的follower不会影响整个集群的性能.
* 个别较慢的follower不影响集群性能


## 7. Safety
到目前为止所描述的机制还不能确保每个状态机都以相同顺序执行相同命令. 例如, 当leader提交多个entry时, 某个follower不可用, 之后该follower成为leader, 并覆盖之前leader提交的entry, 导致不同状态机上执行不同的命令. 因此, Raft算法需要限制哪些服务器可以成为leader, 该限制可确保任何term内的leader包含所有之前term提交的entry. 

### 7.1 Election Restriction
基于leader的共识算法中, 所有leader最终必须拥有所有已提交的entry. Viewstamped Replication中, 即便节点并未包含所有提交的entry仍可成为leader, 但leader必须寻找遗漏的entry. 
Raft没有选择这么做, 因为这么做会引入额外的复杂性; 相反, Raft采用更加的处理方式: 只允许拥有所有已提交entry的服务器赢得选举. 这么做确保entry的流向是单向的: entry只会由leader发送给follower, 且leader不会重写自身的entry.
以下是leader的选举过程:
* candidate向其他服务器发送RequestVote RPC时, 会携带`lastLogIndex`和`lastLogTerm`, 表示candidate中最后一个entry的index和term编号
* 服务器收到RequestVote RPC后, 若candidate**不落后**于服务器, 则投票给该candidate; 若落后于自身, 则拒绝该RPC
* 假设接收到RequestVote RPC的服务器中, 最后一个entry的index为$index_m$, term编号为$term_m$, candidate**不落后**于该服务器的情况如下:
  * $lastLogTerm > term_m$
  * $lastLogTerm == term_m$且$index_m \leq index_m$

若candidate的日志不落后于半数服务器, 说明该candidate拥有所有已提交的entry. 

### 7.2 Committing Entries from Previous Terms
一旦entry被保存在多数服务器上, leader就可以认为该entry已提交. 若leader在提交entry前崩溃, 那么下一个leader可负责复制和提交该entry. 然而, 这么做可能将已提交的entry覆盖, 从而引发日志不一致.
![why a leader cannot determine commitment using log entries from older terms](/images/System-Design/Raft/4-5.png)

上图中, 最上面的数字表示entry的index, 每个框表示entry的term, 从左往右表示时间轴.
1. a: S1作为term a的leader, 将$entry_2$复制到S2
2. b: S1宕机, S5被选为term 3的leader, 接收到客户端请求, 并将新entry写入日志
3. c: S5宕机, S1被选为term 4的leader. S1写入$entry_4$, 并继续同步之前term的$entry_2$, 成功将$entry_2$复制到超过半数的服务器上(S1/S2/S3)

接下来分为两种情况:
1. d: S1宕机, S5被选为新的leader. 如果允许提交之前term的entry, S5会将之前的entry复制到所有服务器上, 可以看到, 已提交的entry被覆盖.
2. e: 不提交之前term的entry, S1会在c时刻同步$entry_4$. 当超过半数的服务器拥有$entry_4$时, S5也不可能成为leader

因此, Raft选择只提交当前term内的entry. 由于Log Matching属性, 一旦当前term的entry被提交, 之前的term的entry也会提交.

### 7.3 Safety Argument
为证明Leader Completeness Property特性, 我们可用反证法证明: 假设存在一个leader(其term为$T$, 称为$leader_T$), 现在$leader_T$提交一个entry(称为$entry_T$), 但该entry没有被未来的leader(term为$U, U > T$, 称为$leader_U$)保存.
1. 由于leader不能删除或覆盖自身日志中的任何entry, 因此, $entry_T$不可能在选举期间从$leader_U$的日志中移除
2. $leader_T$将$entry_T$复制到超过半数的服务器上; $leader_U$获得超过半数的选票才能成为新的leader. 因此, 这两个集合至少共享一个节点
3. 由于follower只能接收大于或等于自己term number的请求, 因此, follower必须在投票给$leader_U$前接受$leader_T$发来的$entry_T$; 否则, follower会拒绝$leader_T$的AppendEntries请求
4. 由于$leader_T$拥有$entry_T$, leader不会删除任何entry, 并且follower与leader发生冲突时, follower才会删除entry, 因此follower为$leader_U$投票时仍保留$entry_T$
5. 当follower给$leader_U$投票时, $leader_U$的日志必须与follower一样新, 这导致了以下两个悖论之一:
    1. $leader_U$的日志至少与follower一样长, 但我们的前提是$leader_U$缺少$entry_T$, 构成悖论
    2. $leader_U$的日志长度大于voter, 因此$leader_U$之前的leader必然包含已提交的entry, 通过Log Matching属性, $leader_U$也必然包含$entry_T$, 构成悖论

由此, 所有term大于$T$的leader必然包含$entry_T$.

### 7.4 Follower and Candidate Crashes
到目前为止, 我们只关注了leader宕机的情况. 相比之下, follower和candidate宕机更容易处理, 且两者的处理方式相同. 
若一个follower或candidate宕机, 则RequestVote和AppendEntries请求都会失败:
* Raft会无限重试: 只要服务器恢复, RPC就会成功完成
* 若节点完成RPC之后宕机, 会在重启后收到相同的RPC. Raft的RPC是**idempotent**(幂等的), 因此多次调用不会造成任何破坏. 例如, 当一个follower收到AppendEntries RPC, 如果entry已经存在于follower的日志中, 其会忽略该RPC.

### 7.5 Timing and availability
Raft的**安全性**不依赖于**timing**(时序), 换句话说, Raft集群不会因为某个事件发生时间快于或慢于某个预期时间而出错. 但Raft的**可用性**依赖于时序, 例如, 若消息传递时间长于服务器崩溃的间隔时间, 则candidate永远等到选票, 也就无法成为leader. 当集群中没有leader时, 也就失去了可用性.
对于Raft的leader选举, 只要遵循下面的时序条件, Raft就能保证选举出一个leader让集群稳定运行:
$$
broadcastTime \leq electionTimeout \leq MTBF
$$

* boardcastTime: 一个服务器向其他服务器发送消息并收到响应的平均时间
* electionTimeout: 选举超时时间
* MTBF: 单个服务器上两次故障的平均间隔时间, 也称为**平均故障时间**

上述不等式可理解为:
1. boardcastTime应比electionTimeout小一个数量级, 这样leader可以稳定向follower发送heartbeat, 避免follower发起新的选举. 由于electionTimeout是随机挑选的, 因此split vote发生的概率很低.
2. electionTimeout应比MTBF小几个数量级, 由于leader宕机时整个集群不可用, 应将electionTime调低来降低不可用时长占总时长的比例.

boardcastTime和MTBF是底层系统的属性, 不可变; 而electionTimeout是我们可以设置的. Raft通常要求接收方将收到的信息保存在稳定的存储设备中, 因此取决于存储技术, boardcastTime会有0.5ms到20ms的波动. 因此, electionTimeout通常为10ms到500ms, MTBF通常为几个月或更久.
