---
title: Kafka Design
abbrlink: bbb8
date: 2021-05-23 15:05:47
tags:
  - Distributed System
category:
  - Distributed System
  - Kafka
keywords:
description:
---

## 1. Motivation
Kafka是一套被大公司用于处理实时数据的统一平台, 因此需要考虑很多使用场景, 例如:
* 为了处理大量事件流, 需要**high-throughput**(高吞吐量), 例如实时日志汇总
* 为了从离线系统中周期性地读取数据, 需要处理大量积压数据
* 为了处理传统通信, 需要**low-latency**(低延迟)
* 由于很多服务都依赖于该系统, 因此当硬件出错时, 该系统应保证**fault-tolerance**(容错性)

上述这些要求使得kafka更像一个database log, 而不是传统的messaging system.


## 2. Persistence
### 2.1 Don't fear the filesystem
Kafka十分依赖filesystem来存储和缓存消息. 程序员可能存在一个感觉: 磁盘很慢, 这种不仅让他们怀疑这类持久化结构能否提供优秀的性能. 实际上, 磁盘的确慢, 但并没有想象中的那么慢, 如果能适当地使用磁盘结构, 其速度通常会快过网络传输.
有关磁盘性能的一个事实: 硬盘的吞吐量与磁盘寻道的延迟密切相关. 以六个7000rpm SATA RAID-5阵列的硬盘为例, **线性写入**的速度为600MB每秒, 而**随机写入**的速度为100k每秒, 中间相差6000倍. 线性读写十分容易预判, 且被操作系统极大地优化. 现代操作系统提供read-ahead(预读)和write-behind(后写)技术来预读数据和一次写入多块数据.
为弥补硬盘的性能, 现代操作系统会越来越积极地将内存用于**disk cache**(硬盘缓存). 操作系统会将所有空闲的内存都作为硬盘缓存, 虽然回收内存时会有性能惩罚. 所有的硬盘读写都会经过统一的缓存. 若不使用direct I/O, 这一特性很难被关闭, 因此, 若进程在内存中保留所有数据, 这些数据依然会在OS pagecache中重复一遍. 
对于JVM, Java内存消耗存在以下两个特性:
* object的内存开销很大, 通过是object中所有数据占内存的两倍
* 虽然heap(堆)内的数据越来越多, Java垃圾回收变得越来越复杂和迟缓

综上所述, 使用文件系统并依赖于硬盘缓存, 这么做优于让程序在内存中维护数据. 对于32GB内存的系统, 可有28GB到30GB的空闲内存作为硬盘缓存. 此外, 即便kafka服务重启, 这些缓存还是可用的, 但如果让程序在内存中维护数据, 每次重启都需花费大量时间来申请缓存(10GB内存需要10分钟). 这样也能大大简化代码, 将缓存和文件操作都交由操作系统. 如果你的磁盘支持线性读取, 则预读能将有用的数据从硬盘中缓存到内存中.
因此, 与其让程序在内存中尽可能地放置数据, 并在内存即将耗尽之时flush入磁盘, 不如每次都写入数据(也就是写入磁盘缓存), 让内核决定何时flush. 

### 2.2 Constant Time Suffices
messageing system(消息系统)会为每个consumer创造一个queue, 称为persistent data structure(持久性数据结构), 一般由B-Tree或其他random access data structure(随机访问数据结构)构成, 用于存放消息的元数据. B-Tree是最多功能的数据结构, 使得消息系统支持事务性和非事务性语义. B-Tree的时间复杂度为**O(logN)**, 可以约等于常数时间, 但对于磁盘操作就不一样了. 磁盘寻道需要10ms, 一个磁盘在同一时间只能进行一次磁盘寻道, 并发能力受限. 因此当存在大量磁盘寻道时, 性能开销很大. 由于存储设备会混合使用速度较快的硬盘缓存和速度较慢的磁盘操作, 树形结构的性能会随着数据量的增大而骤减, 例如: 双倍的数据会导致不止双倍的性能降低.
若persistent queue只读取或追加文件, 这就与logging solution类似. 这种结构的优点在于, 所有操作的时间复杂度为**O(1)**, 且读取操作不会阻塞写入或其他读取操作. 由于性能与数据量无关, 因此服务器可以使用价格便宜, 转速较低的1+TB SATA drive. 虽然这些磁盘寻道速度慢, 但价格只有三分之一, 且三倍容量.
拥有近乎无限量的磁盘空间, 且没有任何性能代价, 这意味着Kafka拥有其他消息系统没有的优势. 举个例子, 在Kafka中, 与其删除掉已读的数据, Kafka可让数据保留很长时间(如一周), 让consumer有更多的灵活性.


## 3. Efficiency
Kafka一个主要应用: 处理网络活动数据, 这类应用需要十分大的容量: 每次网页访问可能产生几十次写入操作, 每个消息都至少会被consumer读取一次, 因此读取操作的代价越小越好. 在创建和运行过多个类似系统后, **效率**是多用户操作的关键. 若应用使用量的小幅增加导致下流基础设施服务成为瓶颈, 则每次小变动都成为问题. 通过提升速度, 可以确保在底层基础设备崩溃前, 应用先崩溃. 当集中式集群上的集中式服务有上百个应用时, 这一点尤为重要, 因为每天都会有使用方式上的改变.
上一节讲了磁盘的效率问题, 还剩下两个方面影响效率:
* 过多的小型I/O操作
* 过多的字节拷贝

### 3.1 Small I/O operations
小型I/O操作发生在两个地方:
* client和server之间的消息传输
* server自己的持久化操作

为避免第一种情况, Kafka创建了一种新的传输协议, 称为**message set**(消息集), 该协议会将多个消息聚集在一起. 这使得一次网络请求发送多个消息, 比起一个个传输消息, 这样能平摊网络往返的开销. Server会将多个消息一次性添加到log文件中, consumer也会一次性获取多个连续消息. 这样简单的优化可以极大地加快速度, 批处理可使用更大的网络数据包, 更大的顺序磁盘操作, 连续的内存块. 所有这些都让Kafka将突发的随机写入流变为线性写入流, 传输给consumer.

### 3.2 Excessive byte copying
对于字节拷贝, 在低消息速率下并不是个问题, 但在负载变高时影响就很大了. 为了避免这种情况, Kafka采用标准化二进制消息格式, 该格式由producer, broker和consumer共享, 因此数据块在它们之间传输无需任何修改.
broker中的message log实际上是一个包含多个文件的文件夹, 每个message log都由一系列message set组成, 每个message set采用相同的格式, 由producer和consumer使用. 这种通用格式可以实现一个十分重要的优化: 持久化日志块的网络传输. 现代UNIX操作系统提供高度优化的方式, 用于将数据从pagecache传输到socket. Linux中为**sendfile**, 为理解sendfile的影响, 需要先理解数据如何从文件传输到socket:
1. 操作系统从磁盘读取数据到kernel的pagecache
2. 应用读取数据, 数据从kernel space转移到user space buffer
3. 应用将数据写回到kernel space中的socket buffer
4. 操作系统将socket buffer中的数据复制给NIC buffer, 然后发送至网络

这明显效率很低, 其中包含四次拷贝和两次system call. sendfile可以让数据从pagecache发送到网络, 从而避免拷贝从user space拷贝数据. 只需要将数据拷贝给NIC buffer即可.
通过上述zero-copy的优化, 数据只需要被拷贝到pagecache一次, 读取时直接从pagecache中发送到网络, 而不需要读取到user spce中. 这样数据读取速度可追平网络传输速度. 因此, 借助pagecache和sendfile, Kafka集群上的大部分读取操作都不是在磁盘执行, 而是直接通过cache获取. 

### 3.3 End-to-end Batch Compression
绝大多数情况下, Kafka的瓶颈不在于CPU或磁盘, 而在于**bandwidth**(带宽), 尤其是data center(数据中心)之间通过广域网传输数据. 用户当然可以自行压缩消息, 但这会导致糟糕的压缩率, 因为大量容易由相同类型消息之间的重复造成的. 更高效的方式是对多个消息进行压缩, 而不是单个消息.
Kafka支持一种高效的批处理格式, 一批消息可以被一起压缩, 并以这种形式发送到server端, server端会直接将压缩的数据写入日志, 数据只会被consumer解压. 目前Kafka支持GZIP, Snappy, LZ4和ZStandard压缩协议.


## 4. The Producer
### 4.1 Load balancing
当producer向partition的leader broker发送数据时, 不需要经过任何中间路由层. 为让producer实现这一点, 所有Kafka节点都可以随时向producer发送一个metadata, 其中包含服务器的活动状态和topic的partition, 以便让producer正确地发送请求.
Producer负责决定消息发送到哪个partition, 可以采取随机发送, 也可以使用负载均衡的方式, 或通过某些语义分区函数. 通过让用户设置key, 并对其哈希来暴露语义分区的接口. 举个例子, 若key使用user id, 则给定用户的数据会放置在同一个partition中. 这反过来使得consumer可对他们获得的数据做出**locality assumption**(局部性假设). 这种分区设计方式允许consumer采取局部性敏感的处理方式.

### 4.2 Asynchronous send
批处理是提高效率的重要方式之一, 通过让Kafka producer开启批处理, 能让更多的数据保留在内存中, 并在一次请求中发送更多数据. 批处理可以配置为堆积消息的上限数量或发送请求的上限延迟. 这样能保证一次传输更多字节, 让server端进行更少的I/O操作. 这种缓存方式是可配置的, 通过牺牲一些延迟来实现更好的吞吐量.


## 5. The Consumer
Kafka consumer通过向拥有partition的broker发送fetch请求来获取数据. Consumer可在请求中指定log的offset, 也可以重新获取之前消费过的数据.

### 5.1 Push vs. Pull
Kafka consumer的设计之处时存在一个争论: consumer应主动从broker拉取数据, 还是broker主动向consumer推送数据. Kafka选择了一种更保守的设计, 也就是让producer主动向broker推送数据, consumer主动从broker拉取数据; 另一些以日志为中心的系统(如Apache Flume)采用截然相反的策略: broker主动向consumer推送数据.
两种设计各有优缺点: 由于broker掌握着数据发送的速率, push模型的系统很难适应不同条件下的consumer, 可能导致consumer因网络拥塞或消息处理速度不足而丢失消息; Pull模型中的consumer掌握着更多的主动权, 因而对consumer更加友善, 通过某种backoff protocol(补偿协议)可以让consumer充分发挥传输效率, 但又不会超负荷. 因此Kafka选择了传统的pull模型.
Pull模型还有一个优势: broker可以一次向consumer发送多个消息. Push消息的模型在不知道consumer能否处理的情况下, 无法决定是发送一个消息, 还是一次发送多个消息; 而pull模型中的consumer可以从log的某个位置开始, 一次获取多个消息, 从而在不增加延迟的情况下实现更好的批处理.
Pull模型的缺点在于, 若broker没有任何数据, 则consumer会不断地轮询, 直到broker有新的消息. 为避免这种情况, broker可阻塞consumer的请求, 直到broker有数据时再回复请求, 从而减少broker的负载.
当然也可以使用其他拉取数据的设计, Producer可以先将数据写入本地的log中, 等待broker从producer拉取数据. 但Kafka的producer可能有上千个, 成千上万个磁盘并不能让事情变得可靠. 只需要大规模运行SLA的管道, 就不需要producer的持久化.

### 5.2 Consumer Position
消息消耗的速度也是影响messaging system运行效率的关键之一. 绝大多数的messaging system会把**metadata**(包含消息消耗进度的文件)保存在broker端, 当消息传递给consumer时, broker需立即记录该事件, 或等到consumer确认消费完毕后记录. 这种设计很符合直觉, 对于单个服务器来说, 服务器无需将metadata发送给他人; 由于broker明白哪些消息已被消耗, 因此可删除被消费的消息, 已减轻服务器负载.
但上述设计存在一个问题: broker如何确定consumer是否消费了传递的消息. 若broker发出消息后默认该消息已被consumer消费, 则可能因为网络故障或consumer宕机导致消息未消费, broker会错误清除未被消费的消息. 为解决该问题, 一些messaging system添加了**acknowledgement**机制: 当broker发送消息后, 该消息的状态为**sent**(已发送); 等到consumer返回ack后, broker再将消息的状态改为**consumed**(已消费). 这种方法可解决消息丢失问题, 但也会产生新的问题:
* 若consumer成功接收并处理消息, 但在发送ack前宕机, 导致该消息在broker端的状态仍为**sent**
* Broker需为所有已发送的消息保存多个状态, 导致性能下降
* Broker如何处理状态为**sent**, 却始终未被consumer确认的消息

Kafka的处理方式则不同: Kafka对partition进行分类, 称为**topic**. 同一时间, 一个topic只能被订阅了该topic的consumer group中的一个consumer消耗, 这意味着每个consumer在每个partition的位置只是一个整数, 即下一个要被消耗的消息的偏移量. 这使得消耗量的状态很小, 每个partition只有一个数字. 该状态可被定期检查, 让消息确认的代价变得很低.
这种策略还有一个额外的好处, consumer可以选择一个旧的offset来重复消耗消息.这违背了queue的定义, 但这也是很多consumer需要的功能. 举个例子, 如果consumer的代码中有一个bug, 但该consumer已经处理过一些消息, 可以让consumer修复完bug后重新处理消息.

### 5.3 Offline Data Load
可拓展的持久性允许consumer周期性的加载数据, 例如, 可以周期性地将散装数据批量的加载到离线系统中, 如Hadoop或关系型数据仓库.
以Hadoop为例, 通过将负载划分各个map task中, 实现数据加载的并行化, 每个task可由node/topic/partition组成. Hadoop提供了任务管理, 失败的任务会自动重启, 且没有数据重复的危险.

### 5.4 Static Membership
**Static membership**(静态成员)旨在提高stream applicatiomn, consumer group和其他基于group rebalance protocol的应用的可用性. Rebalance protocol依赖于group coordinator为group member分配entity id. 这些生成的id是临时性的, 并会在member重启和重新加入时更改. 对于consumer, 在执行管理操作时, 例如代码部署, 配置更新, 周期性重启时, 这种**dynamic membership**(动态成员)会导致大部分任务重新分配给不同实例. 对于大型状态程序, 每次更换任务都需长时间来恢复本地状态, 导致应用周期性或永远无法使用. 基于上述观察, Kafka的group management protocol允许group member提供一个持久的entity id. 根据id, group membership可保持不变, 因此也无需触发rebalance.
如果想使用static membership:
* 升级broker cluser和client到2.4或以上版本, 并且确保升级后的broker中的**inter.broker.protocol.version**为2.3或以上
* 在consumer中, 设置一个独一无二的**GROUP_INSTANCE_ID_CONFIG**(consumer group内不重复即可)
* 在Kafka stream application中, 设置一个独一无二的**GROUP_INSTANCE_ID_CONFIG**

若broker版本低于2.3, 但client仍然设置**GROUP_INSTANCE_ID_CONFIG**, client会检测broker的版本, 并抛出**UnsupportedException**; 若存在两个具有相同id的client, 则会触发broker的防护机制, client会立即关闭并抛出**FencedInstanceIdException**.


## 6. Message Delivery Semantics
在对producer和consumer的工作方式有了些许了解后, 我们来讨论Kafka在producer和consumer之间提供的**semantic guarantee**(语义保证). 以下是几种可能的消息传递保证:
* At most once: 消息可能会丢失, 但不会重传
* At least once: 消息不会丢失, 但可能会重传
* Exactly once: 消息不会丢失, 也不会重传

值得注意的是, message delivery semantic分为两个问题:
* 发送一个消息的持久性保证
* 消耗一个消息的持久性保证

Kafka的语义很简单. 当发布一个消息时, 会有一个**消息被提交到日志中**的概念. 一旦发布的消息被**提交**到日志中, 只要复制了包含该消息的partition的broker状态为alive, 该消息就不会被丢失. 下一节将详细地描述committed message的定义, alive partition, 还有尝试处理的不同失败类型. 我们假设有一个完美的, 不会丢包的broker, 并尝试理解对于producer和consumer的保证. 如果一个producer尝试发布一个消息并遇到网络错误, 那就无法确定该错误发生在消息commit前还是commit后, 类似于自动生成的key插入数据库table的语义.
Kafka的语义很简单, 在0.11.0.0版本之前, 若producer没有收到象征着消息被commit的响应, 只能重发该消息. 若上一个消息成功消息, 那么重发的消息会被重复写入一遍log, 符合**at-least-once**的传递语义. 从0.11.0.0版本开始, Kafka producer也支持了idempotent delivery option(幂等交付选项), 该选项保证重发数据不会造成log中数据的重复. 为此, borker为每个producer分配了一个ID, 并会对相同ID的producer发送的相同序列号的消息去重. Producer还支持使用类似业务的语义向多个topic partition发送消息, 例如: 所有消息要么全部成功写入, 要么全部失败. 目的在于在Kafka topic之间实现exactly-once的处理.
并非所有用例都需要如此强力的保证. 对于延迟敏感的实例来说, 我们需要确定producer的承受能力. 若producer需要等待消息被commit, 那么可能需要10ms. 但producer也可以异步发送消息, 或只等待leader确认, 不需要follower拥有消息. 
现在来从consumer的角度描述语义. 若所有副本拥有相同的日志, 且拥有相同的偏移量. Consumer控制日志的偏移量. 若consumer从未崩溃, 其可以将位置信息保存在内存中; 但如果consumer崩溃, 我们希望新的consumer可以接管该topic partition, 并从一个合适的位置进行处理. 假设consumer读取了一些消息, 以下是几个处理消息和更新位置的选项:
1. Consumer接收消息, 将位置保存在log中, 最后处理数据. 若consumer在保存位置后, 处理消息之前崩溃, 则新的consumer就会在保存后的位置处开始处理, 之前的消息无法再被处理. 这种语义称为**at-most-once**, 因为在consumer处理消息失败时, 消息可能不会被处理.
2. Consumer接收消息, 处理消息, 最后保存位置. 若consumer在处理消息后, 保存位置前崩溃, 新的consumer会接收到已被处理的消息. 这种语义称为**at-least-once**. 大多数情况下, 消息有一个**primary key**(主键), 因此更新操作是幂等的(接收到同一个消息两次只会用一个副本覆盖另一条记录).

那么如何实现**exactly-once**语义? 当从一个Kafka topic消费消息, 并向另一个topic生产消息时, 我们可以利用0.11.0.0的transactional producer功能. Consumer的位置被当做一条消息保存在topic中, 因此我们可以将**写入topic**和**写入offset**放置在一个transaction中. 若transaction被中止, 则consumer的位置不会更新, 生成的消息也可能不会被其他consumer消费(取决于consumer的隔离级别). 以下是两种isolation level:
* 默认隔离级别为**read_uncommitted**: 所有消息对consumer都可见, 即使该消息是被中止的transaction的一部分.
* read_committed: consumer只能消费已被成功提交的transaction中的消息, 或没有包含在transaction中的消息.

当写入一个外部系统时, 如何协调**更新consumer位置**和**consumer对外输出**. 一种经典的解决方案为, 在保存consumer位置和保存consumer输出之间, 引入**two-phase commit**(二阶段提交). 但其实有一种更简单的方法: 让consumer将位置和输出放在同一个地方. 这么做有一个优点, 很多consumer写入的输出系统不支持二阶段提交. 以Kafka Connect为例, 该连接器将HDFS中的数据和其读取的数据偏移量一起填充, 以确保数据和偏移量都被更新或都不更新. 对于需要更强语义的数据系统, 我们遵循类似的方法, 为此可以让消息不携带主键, 以允许数据去重.
所以Kafka支持Kafka Stream中的**exactly-once delivery**, 并且在Kafka topic之间传输和处理数据时, transactional producer/consumer可提供exactly-once delivery. 对于外部系统, Kafka提供Kafka Connect实现exactly-once delivery. 默认情况下, Kafka提供at-least-once delivery. 通过禁用producer重试, 并在consumer处理消息之前提交偏移量, 用户可实现at-most-once delivery.


## 7. Replication
kafka会在可配置的多个服务器上复制每个topic的partition(通过设置replication factor来设定副本数量). 但集群中某个服务器崩溃时, 可自动故障转移到副本, 从而在出故障时保证可用性. 其他messaging system提供了类似的副本功能, 但根据我们的观点, 这些功能是格格不入的, 没有被大量使用, 且存在很多缺陷: 副本处于非活动状态, 吞吐量收到严重影响, 需要手动配置等. Kafka默认开启副本, 也可以通过将replication factor设置为1来实现无副本的topic.
Kafka的副本单元为topic partition. 故障未发生时, Kafka的每个partition都有有一个leader和0个或0个以上的follower. 副本的总数量, 也就是replication factor, 由leader和follower组成. 所有对于partition的读写操作都须通过leader. 通常情况下, partition的数量比broker多, leader会平均分布在broker上. Follower上的log与leader上的log完全相同, 它们具有相同的偏移量, 相同顺序的消息(leader在某些时间点可能在log末尾有一些还未来得及复制的消息). 
Follower和Kafka consumer一样从leader获取消息, 并将其添加到自己的log. 让follower从leader拉取数据, 而不是leader推送数据, 这么做可以让follower批处理日志条目. 与大多数分布式系统一样, 自动处理故障需要对节点的**alive**状态做出明确定义. 对于Kafka, 节点活跃度有两个条件:
1. 节点必须能够和ZooKeeper保持会话(通过ZooKeeper的心跳机制)
2. 对于follower, 其必须能复制leader上的数据, 且不能落后太多

若节点满足上述两个条件, 则称之为**in sync**, 这样避免了alive或failed的模糊性. Leader负责跟踪in sync状态的节点集合. 若某个follower崩溃, 卡顿, 或落后太多, leader会将其从in sync副本列表中移除. 卡顿和滞后的副本由replica.lag.time.max.ms配置决定. 
在分布式系统术语中, Kafka仅解决**fail/recover**类型的故障, 例如节点突然停止工作, 之后又恢复工作. Kafka不处理**Byzantine**类型的故障, 例如节点产生任意或恶意的回复.
现在可以精确定义什么是**消息被提交**: 当partition的所有in sync副本都将该消息写入log中. 只有被提交的消息才能转交给consumer. 这意味着consumer无须担心消息会因为leader的崩溃而丢失. 另一方面, producer可以权衡**延迟**与**持久性**, 并决定是否等待消息被提交. 这偏好通过producer端ack的设置来控制. 需要注意的是, topic有一个最少in-sync副本的数量设置, 当producer请求ack时会检查该数值. 若producer请求一个不太严格的ack, 即使in-sync副本数小于设定值, 消息也会被提交和消费. 
只要有一个活着的同步副本, 就不会丢失已提交的消息, 这是Kafka可以保证的. 在短暂的故障转移后, 若出现节点故障, Kafka仍是可用的. 但如果存在网络分区, Kafka可能仍不可用.

### 7.1 Replicated Logs: Quorums, ISRs, and State Machines
从本质上来说, 一个Kafka partition就是一个**replicated log**(复制日志). 复制日志是分布式数据系统中最基本的primitive之一, 并且有很多实现方法. 可以将复制日志作为primitive, 以状态机样式来时先分布式系统.
复制日志模拟了按照一系列值顺序达成共识的过程(通常对日志条目进行编号: 0,1,2...). 有很多实现的方法, 最简单且最快速的方法是由leader选择值顺序. 只要leader存活, 所有follower只需要复制值并订阅leader即可.
只要leader不崩溃, 我们就不需要follower. 当leader崩溃时, 需要从follower中选举出新的leader. 但follower本身也有落后或崩溃的风险, 因此必须保证选择最新的follower. 日志复制算法必须提供一个最基本的保证: 当通知client一个已提交的消息, 这时leader崩溃, 新选的leader必须有该消息. 这存在一个权衡点: 若leader在宣布该消息已被提交前等待更多的follower确认, 则会有更多潜在的可选举leader.
如果选择所需要的ACK数量, 还有选择leader时需要对比的日志数, 这样保证有重叠, 称为**Quorum**.
一种常见的权衡方式为: 使用**多数票**来实现消息提交和leader选举. 这不是Kafka的实现方式, 但可以通过研究这种方法来了解其中取舍. 假设我们有$2f+1$个副本, 若在leader宣布消息提交前必须有$f+1$个副本接收到该消息, 且选举新的leader时, 必须从至少$f+1$个副本中选取日志最完整的follower作为新的leader, 则只要崩溃的节点数不超过$f$个, leader就可以拥有所有提交的消息. 因为对于任意$f+1$个副本, 至少有一个副本拥有所有已提交的消息, 该副本拥有最完整的日志, 因此也会被选举为新的leader. 每个算法还需要处理许多其他细节(例如, 精确定义什么使得日志更加完整, 确保leader崩溃时或修改集群中的一组服务器时, 如何保证日志的一致性), 目前我们暂时忽略这些问题.
多数票方法有一个很好的特性: 延迟取决于最高的服务器. 若replication factor为3, 则延迟取决于最高的follower, 而不是最慢的. ZooKeeper的Zab, Raft和Viewstamped Replication存在很多算法. 与Kafka的实现最相似的学术期刊为Microsoft的PacificA.
多数票方法的缺点在于, 不需要几次节点崩溃就会让系统没有可被选举的leader. 为容许一次故障就需要三份数据拷贝, 为容许两次故障则需要5份数据拷贝. 对于实际系统而言, 只有足够的冗余性才能容忍单个故障是不够的. 每次写5次副本, 使用5倍的存储空间, 和1/5的带宽, 在大容量的数据存储上并不可行. 这就是为什么Quorum算法更多的出现在共享集群配置, 例如ZooKeeper, 而不是主流数据存储. 例如, HDFS的namenode的高可用性基于多数票机制, 但数据存储不是.
Kafka采用一个稍微不同的方式来选择其quorum集合. Kafka动态地维护一组in-sync replicas(ISR), 而不是多数票. 只有ISR组内的成员有资格选举leader. 只有所有ISR都收到了消息, 该消息才可被认作已提交, 只写入partition不能认为提交成功. 每当发生变动时, ISR都会保存到ZooKeeper中. 因此, ISR中的任何副本都有资格作为leader. 这对于Kafka这种拥有多partition且需要保证节点负载均衡的模型来说十分重要. 通过ISR模型和$f+1$份副本, Kafka topic可在不丢失任何已提交消息的前提下容忍$f$次故障.
对于大多数用例, 这种权衡是合理的. 实践中, 为了容忍$f$次故障, 多数票和ISR方法都需等待相同个数的副本确认来确认消息被提交. (例如: 为了容忍一次故障, 多数票需要三分副本和一个ack, ISR方法需要两个副本和一个ack). 不需要最慢的服务器就能确保消息提交, 这是多数票方法的优点. 但是, 我们可以通过让client自行决定是否等待消息提交来改善这种情况, 并且, 由于ISR方法需要较小的replication factor,
 从而带来额外的吞吐量和磁盘空间.
两种设计还有一个十分重要的不同之处, Kafka并不需要之前故障的节点恢复时保有数据完整性. 复制算法依赖于**stable storage**的存在并不少见, stable storage(存储稳定)指在故障恢复场景中, 数据不会丢失且不会违背一致性. 上述假设有两个问题: 第一, 在实际的持久性数据系统操作中, 磁盘错误是很常见的错误, 且其无法保证数据完整性. 第二, 我们不希望在每次写入数据后都调用fsync来保证一致性, 这会让性能下降两三个数量级. Kafka协议允许副本重新加入到ISR集合中, 在重新加入前, 即便其丢失了unflush数据, 也需要重新同步. 

### 7.2 Unclean leader election: What if they all die?
Kafka对于数据丢失的保障建立在至少有一个存活的in-sync replica上. 如果某个partition的所有节点都故障, 则失去保障. 当所有副本都挂掉时, 系统可以采用以下两种方案:
1. 等待ISR中的某个副本回复, 并将其选举为新的leader(数据不一定完整)
2. 选择第一个恢复的副本作为leader, 不需要是ISR中的一员

这是一种**可用性**和**一致性**之间的权衡. 若我们选择等待ISR中的副本, 则副本故障期间系统是不可用的; 若副本全部被破坏或数据丢失, 那么服务将永远处于瘫痪状态. 若我们允许一个非in-sync replica作为leader, 其log会成为消息的真实来源, 但实际可能存在数据丢失. 从0.11.0.0开始, Kafka选择使用第一种策略, 并倾向于等待一致的副本. 该属性可通过**unclean.leader.election.enable**配置, 来平衡实际用例中的可用性和一致性.
这种困境不光存在于Kafka, 其存在于所有基于Quorum的方案. 举个例子, 对于多数票方案, 若大多数服务器遭遇永久故障, 要么选择丢失所有数据, 要么选择违反一致性, 将集群中其他存活的服务器的数据作为真实数据源. 

### 7.3 Availability and Durability Guarantees
当写入Kafka时, producer可以通过选择不同的ack(0, 1, -1)来决定是否等待数据提交. **所有副本的确认**并不保证所有副本都收到消息. 默认情况下, 当acks=all时, 所有in-sync replica都收到消息后就完成了确认. 例如: 若一个topic仅配置了两个副本, 一个失败, 另一个成功, 那么写入操作还是被认作成功的. 但如果其余副本也失败了, 则写入的数据会丢失. 虽然这能最大程度上确保partition的可用性, 但对于需要更需要持久性而非可用性的用例来说, 这种策略是不受欢迎的. 因此, Kafka提供了两种topic级别的配置, 以此平衡持久性和可用性:
1. 关闭unclean leader election: 若所有副本都不可用, partition会处于不可用状态, 直到最近的leader恢复可用. 这可能导致不可用, 但不会丢失数据.
2. 指定一个最小ISR大小: 如果ISR的副本数大于某个特定值, 则该partition接受写操作. 这样可以防止单个副本遭遇故障后消息丢失的问题. 只有acks=all时这一设置才有效, 至少有特定个in-sync replica收到消息, producer才会收到确认. 这个选项提供了一个可用性和持久性之间的权衡. 若给最小ISR数量一个较大值, 则可以保证更好的持久性, 因为消息会被写入更多的副本, 丢失消息的概率也会降低; 但这也会降低可用性, 若in-sync replica的存活数量小于阈值, 该partition将不支持写入操作. 

### 7.4 Replica Management
上述的讨论只围绕着一个log, 也就是一个topic中的一个partition. 然而, 在Kafka集群中会有成百上千个partition. 我们尝试以轮询的方式平衡集群中的partition, 避免大量topic的partition集中在少数节点. 同样, 我们尝试平衡leader, 这样每个节点都能承担一定比例的leader职责.
Leader的选举过程也很重要, 这决定了不可用窗口期的长度. 一个简单的leader选举实现可以是: 当某个节点出现故障, 为该节点上的所有partition都举行一次选举. 相反, 我们可以推选一个broker作为**controller**. 这个controller会检测broker层面的故障, 并负责为故障节点中的所有受影响partition分配新的leader. 这样可以批处理多个修改leader的通发生故障, 剩余的broker中会有一个成为新的controller.


## 8. Log Compaction
**Log compaction**(日志压缩)确保在Kafka中, 对于单个topic partition的log数据来说, 每个message key至少保留一个最新值. 它能解决一些特殊场景, 例如, 应用在崩溃或系统故障后恢复, 或是维护完成后程序重启. 让我们详细研究这些用例, 并阐述压缩是如何工作的.
目前为止, 我们只描述过一个简单的方法来保存数据, 也就是在一段固定时间后, 或日志大小达到某个阈值后删除旧数据. 这种方式对于临时时间类数据十分有效, 例如, 每个记录独立存在的日志系统. 但还存在另一种数据流方式: 对于键控修改的可变数据日志, 例如, 对数据表的更改.
让我们以一个具体的例子讨论这种流. 假设我们有一个topic保存用户邮箱地址. 每当用户修改其邮箱地址时, 我们都会向该topic发送一个消息, key为用户id. 假设用户的id为**123**, 每个消息都包含邮箱地址的更改(其他id的消息被忽略):

```text
123 => bill@microsoft.com
        .
        .
        .
123 => bill@gatesfoundation.org
        .
        .
        .
123 => bill@gmail.com
```
日志压缩给我们提供了更精细的日志保存机制, 从而为每个primary key至少保留最新的更新(例如: bill@gmail.com). 这么做保证了日志包含每个key对应的最终值的完整快照, 而不是最近更新的key. 这意味着下游consumer可以从改topic恢复其状态, 无需保留所有更改的日志. 下面是log compaction的一些用例:
1. Database change subscription(数据库更改订阅): 多个数据系统共享一个数据集合是十分常见的, 其中有些系统是RDBMS, 有些是key-value store. 举个例子, 现在有一个数据库, 一个cache, 一个搜索集群, 一个Hadoop集群. 对于数据库的每次修改都需反应在其他系统中. 如果只处理实时更新, 则只需要最新的日志; 但如果用于重新加载缓存或恢复故障搜索节点, 则需要完整数据集.
2. Event sourcing(事件源): 这是一种应用设计风格, 将查询处理和应用程序设计结合到一起, 并将日志修改作为应用的主要存储.
3. Journaling for high-availability(高可用日志): 进程通过将对本地状态的修改写入日志中, 可实现本地计算的容错性, 这样其他进程就可以在本进程故障时加载修改日志. 一个具体的例子是, 在流查询系统中处理计数, 聚合和其他类似于"分组"的操作.

上述的场景中, 主要用于处理修改的实时反馈, 但当机器故障, 需要重新加载数据, 或重新处理数据时, 还需要加载完整日志. Log compaction允许使用相同的topic支持上述两种场景.
如果我们拥有无限的日志保留时间, 且在日志中保留每一个修改, 则需要从系统启动就实时记录系统的状态. 有了完整日志, 我们就可以通过回放前N个日志记录来恢复到任何一个时间点. 这种假想的完整日志实际中并不可行, 因为即便是稳定的数据集, 日志也会无限增长. 丢弃掉旧的更新作为一种简单的日志保存机制, 可以防止日志空间无限扩张; 但日志也无法让系统从原始状态恢复到当前状态, 因为旧的更新被丢弃.
相比于基于时间的粗粒度日志保存方案, Log compaction提供了一种更细粒度, 保存每个记录的保存方式. 通过保留同一key的最新更新, 可保证每个key至少有一个最新状态. 日志保存策略的单元是topic, 所以一个集群中的多个topic可采用不同的保存方式: 某些topic根据时间或空间删除旧数据, 某另外一些topic使用log compaction来保留最新的更新.
Log compaction的灵感来自于Linkedin的一个古老且成功的基础设施: 一个成为Databus的数据库日志更新缓存服务. 与其他日志存储系统不同, Kafka提供订阅服务, 并为**线性读写**组织数据. 与Databus不同的是, Kafka作为消息源, 即使在上游数据源无法重放的情况下依然有用.

### 8.1 Log Compaction Basics
下图是Kafka log的逻辑结构图, 每个message都有一个偏移量:
![Log Cleaner Anatomy](/images/Kafka/log_cleaner_anatomy.png)

Log Head与传统的Kafka log相同. 它具有密集的, 顺序的偏移量并保留所有消息. Log compaction为处理log Tail添加了一个选项. 上图的log中有一个压缩后的Log Tail. 注意, log tail内的消息保留原始的偏移量, 从一开始创建就不会被修改. 即使该偏移量上的消息被压缩, 所有偏移量在日志中仍是有效的. 这种情况下, 无法区分该位置与下一个出现在日志中的最高偏移量. 举个例子, 上图中偏移量36, 37和38都是相同的位置, 对这三个偏移量的读取只会返回以偏移量38为起始的消息.
压缩还允许删除操作. 当一个消息的值为空时, 意味着该消息从日志中删除. 这种记录也被成为**tombstone**(墓碑). 此删除标记会导致所有拥有相同key的旧消息被删除; 但删除标记比较特殊, 它们会在一段时间后从日志中清空以释放空间, 该时间点称为**delete retention point**.
压缩通过周期性重新复制log segment在后台完成, 清理操作不会阻塞读取操作, 并可通过设置I/O吞吐量来防止影响producer和consumer. 实际压缩一个log segment过程如下:
![log Compaction](/images/Kafka/log_compaction.png)

### 8.2 What guarantees does log compaction provide?
压缩提供了以下保证:
1. 任何跟上log head的consumer都看到所有写入的数据. 这些消息有顺序的偏移量. topic的**min.compaction.lag.ms**设置可保证消息在写入后, 压缩前滞留的最短时间. topic的**max.compaction.lag.ms**设置可保证消息写入和消息符合压缩条件的最大延迟.
2. 消息的顺序依然保持不变, 压缩不会更改顺序, 只会删除一部分消息.
3. 消息的偏移量保持不变, 偏移量是消息在日志中某个位置的永久标识符.
4. 任何从头开始处理日志的consumer都能以写入顺序, 至少读取到每个记录的最新状态. 此外, 如果consumer在topic的**delete.retention.ms**设置(默认24小时)的时间段内读取到log head, 则可以看到所有删除标记. 换句话说, 由于移除删除标记与读取数据同时进行, 如果consumer的延迟超过delete.retention.ms, 则会错过删除标记.

### 8.3 Log Compaction Details
Log compaction由log cleaner处理, 这是一个后台运行的线程池, 用于重新复制log segment文件, 删除出现在log head中具有相同key的记录. 每个conpactor线程工作原理如下:
1. 挑选log head与log tail比例最高的日志
2. 为log head中的每个key的最新值做一个摘要
3. 从头到尾复制整个日志, 期间删除相同key的记录. 新的log segment会替代旧的记录, 因此只需保留一个segment大小的额外磁盘空间即可.
4. log head的摘要本质上是一个空间紧凑的哈希表, 每个条目占24字节. 若有8GB的清理缓存区, 则每次清理可处理266GB的log head(假设有1000条消息).

### 8.4 Configuring The Log Cleaner
Log cleaner默认启动. 该服务会启动一个cleaner线程池. 如果想在某个topic开启日志清理, 可添加一下配置:
```text
log.cleanup.policy=compact
```

**log.cleanup.policy**是broker配置设置中的一个属性, 在broker的server.properties文件中. 它会影响集群里中所有没有配置日志清理的topic. 通过设计压缩的时延, 可以让log head的尺寸保持的尽量小:
```text
log.cleaner.min.compaction.lag.ms
```

这可用于防止消息的存在短于某个时间段而被压缩. 如果不设置该属性, 除了最后一个segment, 其余所有log segment都有资格被压缩. 当前写入的segment不会被压缩, 即使其中所有消息都滞后于最小压缩时延. Log cleaner还可以设置一个最大时延, 以确保未被压缩的log head有资格进行日志压缩:
```text
log.cleaner.max.compaction.lag.ms
```
若日志很少有数据写入, 该属性可保证一定时间后该segment符合压缩资格. 如果不设置该属性, log中的log head比例可能很难超过min.cleanable.dirty.ratio, 因此迟迟不会被压缩. 该属性并不能保证压缩一定执行, 还需要考虑log cleaner线程的可用性, 还有实际压缩时间的影响. 


## 9. Quotas
当producer和consumer请求broker资源时, Kafka cluster课对此进行配额配置. 以下是两种Kafka broker可以设置的配额:
1. 网络带宽配额: 定义了字节速率阈值(自0.9起)
2. 请求速率配额: 将CPU使用阈值定义为网络和I/O线程百分比(自0.11起)

### 9.1 Why are quotas necessary?
Producer和consumer可能会生产/消耗大量数据, 或频繁发送请求, 从而垄断broker的资源, 造成网络饱和. 配置配额可以防止上述问题发生, 在多用户集群中尤为重要, 因为一小群行为不良的client会降低所有行为良好的client的用户体验. 实际上, 当将Kafka作为服务运行时, 可以根据商定的合同强制执行API限制.

### 9.2 Client groups
Kafka client的身份为user principal, 其代表一个安全集群中的经过身份验证的用户. 在一个支持非验证client身份的集群中, user principal是一组未验证身份的用户, 由broker通过可配置的PrincipalBuilder挑选. Client-id作为client逻辑分组, 是由client应用挑选的有意义的名称. 元组(user, client-id)定义了一个安全的client逻辑分组, 这些client共享client-id和user principal.
配额可用于(user, client-id), user, 或client-id组. 对于一个给定的连接, 会使用最匹配该连接的配额. 一个配额组的所有连接共享其配额. 举个例子, 如果(user="test-user", client-id="test-client")有10MB每秒的生产配额, 所有user为test-user, 且client-id为test-client的producer共享该配额.

### 9.3 Quota Configuration
配额配置可按照(user, client-id), user和lcient-id分组. 如果需要更高或更低的配额, 可以从任何配额级别覆盖默认配额. 该机制和对于topic的日志配置覆盖类似. user和(user, client-id)配额会写入ZooKeeper的/config/users下, client-id配额写入/config/clients下. 这些配额会被所有broker读取, 并立即生效. 这使得我们无需重启整个集群即可修改配额. 每个分组的默认配额也可以使用相同方式动态更新.
以下是配额的配置顺序:
1. /config/users/\<user\>/clients/\<client-id\>
2. /config/users/\<user\>/clients/\<default\>
3. /config/users/\<user\>
4. /config/users/\<default\>/clients/\<client-id\>
5. /config/users/\<default\>/clients/\<default\>
6. /config/users/\<default\>
7. /config/clients/\<client-id\>
8. /config/clients/\<default\>

Broker的属性(quota.producer.default, quota.consumer.default)也能用于为client-id分组设置网络带宽配额的默认值. 这些属性已被弃用, 并会在之后的版本移除. client-id的默认配额与其他配额一样, 都可以在ZooKeeper设置.

### 9.4 Network Bandwidth Quotas
网络带宽配额定义为字节速率阈值, 由一组内的所有client共享. 默认情况下, 每个唯一的client组都会收到一个固定的配额, 由集群配置, 单位为bytes/sec. 该配额基于每个代理定义的. 在client被限制前, 每组client可以向每个broker发布/获取X字节/秒.

### 9.5 Request Rate Quotas
请求率配额定义为: 在一个配额窗口内, 一个client在每个broker上使用request handler I/O thread和network thread的时间比. 配额的n%表示一个线程的n%, 因此总配额为((num.io.threads + num.network.threads) * 100)%. 在被限制前, 每个client组都可以在一个配额窗口内使用不超过n%的I/O和network thread. 由于I/O和network的线程数量与broker的内核数成正比, 请求率配额也表示每组client共享的CPU使用率.

### 9.6 Enforcement
默认情况下, 每个client组都会收到一个由集群配置的固定配额, 该配额是基于每个broker定义的. 每个client都可以在被限制前使用该配额. 之所以让client掌握每个broker的配额, 而不是让客户端掌握整个集群的配额, 是因为后者需要让client配额在每个broker上共享. 实现这种配额方式比配额本身的实现都难. 
当超出配额时broker应作何反应? 首先, broker计算出能让该client降低到配额以下的延迟量, 并返回一个携带延迟的恢复. 如果是获取数据的请求, 则回复中不会携带任何数据. 然后, broker会将该client的channel静音, 不处理来自该client的任何请求, 直到延迟结束. 当Kafka client收到一个含有非零延迟持续时间的回复后, 会避免在延迟期间发送请求. 因此, 来自受限client的请求会被双方阻塞. 即使旧的client实现不考虑延迟响应, broker也会通过静音channel的方法限制client. 受限的client只有在延迟结束后才会收到响应.
字节率和线程使用率会在多个小窗口上测量(如: 30个窗口, 每个窗口1秒), 以便快速检测和纠正配额违规. 通常情况下, 设置较大的测量窗口(如10个窗口, 每个窗口30秒)会在经历突发流量激增后, 产生长时间延迟, 导致用户体验交叉.
