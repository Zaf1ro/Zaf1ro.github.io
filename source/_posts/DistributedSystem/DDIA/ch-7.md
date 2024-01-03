---
title: Transactions
abbrlink: '4e8'
date: 2021-10-22 14:22:56
tags:
  - Distributed System
category:
  - Distributed System
keywords:
description:
---

数据库中很多地方都可能出错:
* 数据库软件或硬件可能在任何时间出错(包括写入过程)
* 应用程序可能在任何时间崩溃(包括一系列操作的中间)
* 网络中断可能会中断应用与数据库的连接, 或数据库节点间的连接
* 多个客户端同时写入数据库, 覆盖彼此的更新
* 由于数据只更新了一部分, 客户端可能读取到无意义的数据
* 客户端之间的竞争条件可能导致错误

为了实现可靠性, 系统必须处理这些故障, 确保其不会导致系统级别的故障. 然而, 实现容错机制需要仔细考虑所有可能出错的事情, 并进行大量测试, 以确保解决方案真正有效.
数十年来, **transaction**(事务)一直是简化这类问题的首选机制. 事务将多个读写操作合并成一个逻辑单元. 从概念上说, 事务中的所有读写作为单个操作执行: 要么整个事务成功**commit**(提交), 要么**abort**(中止)或**rollback**(回滚). 若事务失败, 应用可安全重试. 由于不会出现**partial failure**(部分失败), 事务让错误处理变得简单起来.
使用多了事务后, 我们会觉得事务是理所当然的, 但实际上并不是. 事务不是天然存在的, 其目的是为了简化应用的**programming model**(编程模型). 通过使用事务, 应用可忽略某些潜在的错误和并发问题, 因为数据库会替应用处理好一切(称为**safety guarantee**, 安全保证).
并不是所有的应用都需要事务, 有时弱化事务保证, 或完全放弃事务也是有好处的(例如, 为了获得更好的性能或更高可用性). 即使不使用事务也可实现一些安全保证.
如何知道你的应用是否需要事务? 想要回答这个问题, 需理解事务可提供什么样的安全保证, 以及付出的代价.

## 1. The Slippery Concept of a Transaction
现今几乎所有关系数据库和部分非关系数据库都支持事务, 其中大多数遵循IBM System R(第一个SQL数据库)在1975年引入的风格. 40年内实现细节虽然有所变动, 但总体思路大同小异.
2000年后, 非关系数据库(NoSQL)开始普及, 这类数据库的目标是在关系数据库的基础上, 提供新的数据模型, 并默认拥有replication(复制)和partitioning(分区). 事务则是这类变革的牺牲品: 许多新一代数据库或完全放弃事务, 或提供更弱的保证.
随着分布式数据库的热度上升, 人们普遍认为**transaction**(事务)与**scalability**(可伸缩性)是相悖的, 大型系统必须放弃事务以保证高性能和高可用性; 另一方面, 数据库厂商会将事务保证作为"重要应用"和"有价值数据"的基本要求. 这两点都被夸大了.
事实并非这么简单: 与其他技术设计选择一样, 事务有其优势和局限性. 为了理解这些权衡, 需了解事务能提供的保证.

### 1.1 The Meaning of ACID
事务所提供的的安全保证, 通常可描述为**ACID**, 分别表示**Atomicity**(原子性), **Consistency**(一致性), **Isolation**(隔离性), **Durability**(持久性). 由Theo Harder和Andreas Reuter于1983年提出, 旨在为数据库中的容错机制定义精确的术语.
然而, 不同数据库对ACID的实现不同. 例如, 隔离性的定义就很模糊不清. 当一个系统声明自己满足ACID时, 实际上并不清楚它能提供什么样的保证.
不符合ACID标准的系统会被称为**BASE**, 分别表示**Basically Available**(基本可用性), **Soft State**(软状态), 和**Eventual Consistency**(最终一致性), 这比ACID的定义还要模糊, 似乎BASE的唯一的定义就是"不是ACID", 即它可以表示任何你想要的保证.

#### 1.1.1 Atomicity
一般来说, 原子指无法分解为更小的东西. 这个词在计算机领域表示相似却又细微不同的东西. 例如, 在多线程编程中, 若一个线程执行一个原子操作, 意味着另一个线程无法看到该操作的中间过程. 系统要么处于该操作前的状态, 要么处于操作后的状态.
ACID的原子性与并发无关, 并不表示多个线程访问同一数据的情景, 该情况属于**隔离性**.
原子性的描述是, 当客户端执行多次写入时, 数据写入中途发生故障. 例如, 进程崩溃, 网络中断, 磁盘已满, 或违反某种完整性约束. 若写入被分配到原子事务中, 且事务由于故障而无法完成, 则事务将被**abort**(中止), 数据库必须丢弃或撤销事务中的所有写入.
若没有原子性, 写入中途发生故障后, 很难知道哪些写入已经生效, 哪些没有生效. 若应用程序重新执行, 可能导致数据重复或错误的数据. 原子性简化了该问题: 若事务被中止, 应用程序可确信数据没有任何变更, 可以安全地重试.
原子性的定义为: 能够在出错时中止事务, 丢弃该事务执行的所有写入. 也可称作**abortability**(可中止性).

#### 1.1.2 Consistency
**Consistency**(一致性)一词被赋予了太多含义:
* 异步复制系统中有**eventual consistency**(最终一致性), 还有**replica consistency**(副本一致性)
* **Consistency hashing**(一致性哈希)是一种用于重新分区的方式
* CAP定理中, 一致性表示**linearizability**(线性一致性)
* ACID中, 一致性指代数据库在应用程序的特定概念下处于"良好状态"

ACID一致性的概念为: 对数据的特定约束始终成真, 即**invariants**(不变式). 例如, 在会计系统中, 所有账户的credit(借)和debit(贷)必须相等. 若事务开始时数据库满足一些不变式, 且事务执行期间也满足不变式, 那么可以说, 不变式一直满足.
然而, 一致性的概念取决于应用程序对不变式的定义, 应用程序负责定义它的事务, 并保持一致性. 这并不是数据库能够保证的: 若写入了破坏一致性的数据, 数据库也不会阻止(一些特定类型的不变式可由数据库检查, 如外键约束或唯一约束. 但一般来说, 应用程序负责定义什么数据是有效的, 什么是无效的, 数据库只负责存储).
原子性, 隔离性, 和持久性是数据库的属性, 而一致性是应用程序的属性. 应用或许需要数据库的原子性和隔离性来实现一致性, 但并不仅仅取决于数据库. 因此, consistency不属于ACID.

#### 1.1.3 Isolation
大多数数据库都允许多个用户同时访问. 若用户读写数据库的不同部分, 则没有任何问题; 若访问相同记录, 则会遇到**concurrency problem**(并发问题, 即race condition).
![A race condition between two clients concurrently incrementing a counter](/images/System-Design/DDIA/ch-7-1.png)

上图是这类问题的一个简单例子: 两个客户端同时增加一个计数器. 每个客户端读取当前值, 加1, 并将新值写回(假设数据库没有内建的自增操作). 理论上计数器应从42变成44, 但由于竞争条件, 导致计数器为43.
Isolation意味着同时执行的事务相互隔离: 它们不会干扰到对方. 教科书将isolation称为**serializability**(可串行化), 意味着每个事务都认为自己是数据库中唯一运行的事务. 数据库也能确保多个事务被提交时, 其与串行运行的结果相同.
然而实践中很少用到可串行的隔离, 因为其会带来性能损失. 一些数据库甚至没有实现. 例如Oracle 11g. 在Oracle中, 有一种名为"可串行的"隔离级别, 但其实提供的是一种更弱的保证, 称为**snapshot isolation**(快照隔离).

#### 1.1.4 Durability
数据库的其中一个设计目的是提供一个安全的数据存储空间, 不必担心数据丢失. **Durability**(持久性)作为一个承诺, 可保证事务提交时, 即使发生硬件故障或数据库崩溃, 写入的数据也不会丢失.
对于单节点数据库, 持久性意味着数据已被写入**nonvolatile**(非易失性)存储设备, 如硬盘或SSD. 通常还包括**write-ahead log**(预写日志)或类似的文件, 以便当磁盘上的数据结构损坏时进行恢复. 对于多节点数据库, 持久性意味着数据已被复制到多个节点上. 为了满足该保证, 数据库在通知用户事务提交成功前, 必须等到写入或复制完成.
完美的持久性并不存在: 若所有硬盘和所有备份同时损坏, 没有数据库能保证持久性.

### 1.2 Single-Object and Multi-Object Operations
在ACID中, 原子性和隔离性描述了客户端在同一事务中执行多次写入时, 数据库应怎么做.
* Atomicity: 包含多个写入的事务中途发生错误, 应中止事务, 并丢弃当前事务中的所有写入. 换句话说, 用户无需担心**partial failure**(部分失败).
* Isolation: 同时执行的多个事务互不干扰. 例如, 某个事务包含多个写入操作, 其他事务要么看到该事务的写入全部完成, 要么什么都看不到, 不存在中间状态.

当同时修改多个对象(行, 文档, 记录)时, 通常需要**multi-object transactions**(多对象事务)来保证多个数据同步. 下图是一个邮件应用的例子:
![Violating isolation: one transaction reads another transaction’s uncommitted writes](/images/System-Design/DDIA/ch-7-2.png)

执行以下查询语句来显示用户未读邮件数量:
```sql
SELECT COUNT（*）FROM emails WHERE recipient_id = 2 AND unread_flag = true
```

如果邮件过多, 可能会觉得上述查询太慢, 并决定用一个单独的字段(unread)来保存未读邮件的数量(一种反规范化). 当新邮件写入时, 需增加该计数器; 当读取邮件时, 需减少该计数器.
用户2会遇到异常情况: 邮件列表显示有未读消息, 但由于计数器还没增加, 因此显示零封未读消息. 隔离性可避免此类问题: 确保用户要么看到新邮件和增加后的计数器, 要么都看不到, 不会让看到中间状态.
![Atomicity ensures that if an error occurs any prior writes from that transaction are undone, to avoid an inconsistent state](/images/System-Design/DDIA/ch-7-3.png)

上图展现了原子性的重要性: 若事务中途发生错误, 邮件和未读计数器会失去同步. 在原子事务中, 若计数器更新失败, 则中止事务并回滚已写入的邮件.
多对象事务需要某种方式来确定哪些读写属于同一事务. 关系数据库中, 通常基于客户端与数据库之间的TCP连接: 在任意连接上, `BEGIN TRANSACTION`和`COMMIT`之间的语句被视为同一事务的一部分.
对于非关系数据库, 没有将多个操作组合在一起的方法. 即使存在**multi-object API**(多对象API, 例如, 某个key-value存储可能具备在一个操作中更新多个key的multi-put操作), 但不一定意味着其具有事务语义.

#### 1.2.1 Single-object writes
原子性和隔离性也适用于更新单个对象. 例如, 将一个20KB大小的JSON文档写入数据库:
* 若发送10KB之后网络中断, 数据库是否只存储了10KB的数据
* 若数据库覆盖旧值时发生故障, 新旧值是否会拼接在一起
* 若写入时另一个客户端读取该文档, 是否会看到部分更新的数据

绝大多数存储引擎都会提供单节点上对单个对象的原子性和隔离性. 原子性可通过日志实现崩溃恢复; 隔离性可通过对每个对象上锁(每次只允许一个线程访问对象).
某些数据库会提供更复杂的原子操作, 如自增操作, 这样就无需**read-modify-write**(读取-修改-写回)序列. 还有**compare-and-set**(CAS)操作: 仅当数据未被修改时才执行写操作.
这类单对象操作很有用, 因为可防止多个客户端同时写入同一对象所导致的更新丢失. 然而, 它们并不是通常意义上的事务. CAS和其他单一对象操作被称为**lightweight transaction**(轻量级事务), 不应被理解为ACID. 事务的定义为: 一种将多个对象上的多个操作合并为一个执行单元的机制.

#### 1.2.2 The need for multi-object transactions
许多分布式数据存储放弃了多对象事务, 因为很难跨分区实现, 而且多对象事务很难满足高可用性或高性能的需求. 实际上, 分布式数据库中实现事务没有什么本质问题.
但我们是否真的需要多对象事务? 能否只用key-value数据模型和单对象操作来实现应用需求? 在某些场景中, 单对象插入, 更新, 和删除是足够的. 但以下场景仍需写入多个对象:
* 关系数据模型中, 表中的行通常拥有对其他表的行的外键引用. 多对象事务可确保引用始终有效: 当写入几个相互引用的记录时, 外键必须是正确且最新的, 否则数据失去意义
* 文档数据模型中, 需要更新的字段通常位于同一个文档中, 因此可作为单个对象; 然而, 文档数据库缺乏join功能, 因此鼓励**denormalization**(非规范化). 当更新非规范化的信息时, 需要一次更新多个文档, 事务可防止非规范化数据失去同步
* 具有次级索引的数据库中(除key-value存储外的其他存储), 更新数据时可能需要更新多个index. 从事务的角度来看, 每个index都是不同的数据库对象: 若没有事务隔离性, 记录可能出现在第一个index中, 但未出现在第二个index.

#### 1.2.3 Handling errors and aborts
事务的一个关键特性为: 当发生错误时, 会自动中止并安全地重试. ACID数据库基于这样的理念: 如果数据库有可能违背原子性, 隔离性, 或持久性, 宁愿放弃事务也不会留下半成品.
然而并不是所有系统都遵循这一原则. 对于基于leaderless复制的数据库来说, 其遵守的原则是**尽力而为**, 换句话说, 数据库尽可能多做事, 若遇到错误, 不会撤销已完成的事情.
错误不可避免, 但很多开发人员倾向于只考虑乐观情况, 而忽略了错误处理. 例如, Rails的ActiveRecord和Django这类ORM(object-relational mapping, 对象关系映射)框架不会重试被中止的事务. 这类错误会抛出异常, 异常一层层向上传播, 所有用户输入都会被丢弃, 用户拿到一个错误消息. 这是不对的, 因为中止事务的目的在于安全重试.
重试事务是一种简单有效的错误处理机制, 但存在以下问题:
* 若事务成功执行, 但服务器发回的响应因网络故障而发送失败(客户端认为提交失败), 客户端会重新提交事务, 从而导致事务被执行两次, 除非有一个应用级的去重机制.
* 若负载过重导致了事务中止, 重试事务会导致问题变得更糟. 为避免这种负循环, 可限制重试次数, 使用**exponential backoff**(指数退避算法), 并单独处理过载相关的错误.
* 临时性错误(如死锁, 异常情况, 临时网络中断, 故障切换)值得重试, 永久性错误(如违反约束)则不值得重试
* 若事务存在数据库外的副作用, 即使事务被中止, 也可能发生副作用. 例如, 用户正在发送邮件, 我们不希望重试事务时重新发送邮件. 若想确保多个系统一起提交或中止, 可使用**two-phase commit**(两阶段提交)
* 若客户端进程重试时崩溃, 则数据丢失


## 2. Weak Isolation Leaks
若两个事务不使用同一数据, 它们是可以安全地并行执行, 因为它们之间没有依赖关系. 当一个事务读取的数据同时被其他事务修改, 或两个事务同时修改同一数据时, 才会发生并发问题(race condition).
由于并发BUG只在特殊时序下才会触发, 因此很难通过测试发现. 这种时序问题很少发生, 也很难重现. 并发性也很难推理, 特别在大型应用中, 我们无法知道哪些代码正在访问数据库. 即使同一时间只有一个用户, 应用开发已经很麻烦; 若存在并发用户, 由于数据随时都会更新, 更难处理并发问题.
出于上述原因, 数据库会提供**transaction isolation**(事务隔离)来规避并发问题. 理论上, 隔离假装没有并发发生, 会让开发更加轻松: **serializable isolation**(可串行的隔离)意味着, 事务看起来就像串行执行.
实际上, 隔离没那么简单. 可串行隔离会带来性能损失, 许多数据库不愿支持该隔离级别. 因此, 系统通常使用更弱的隔离级别来防止一部分并发问题. 这些隔离级别难以理解, 且会导致隐蔽的错误, 但仍被广泛使用.
弱事务隔离导致的并发错误不仅仅是个理论问题, 还会造成资金损失. 因此存在一种很流行的评论: 若处理财务数据, 请使用ACID数据库. 但这是不对的, 即使主流的关系数据库系统也会使用弱隔离, 并不能完全防止错误发生.
比起盲目相信工具, 不如深入理解并发问题, 学习如何防止问题发生, 并使用工具构建可靠和正确的应用程序.

### 2.1 Read Committed
**Read Committed**(读已提交)是最基本的事务隔离级别, 其提供了两个保证:
1. 读数据时, 只能看到已提交的数据(没有dirty read, 脏读)
2. 写数据时, 只会覆盖已提交的数据(没有dirty write, 脏写)

#### 2.1.1 No dirty reads
假设一个事务写入数据, 但事务还未提交或中止; 若另一个事务能看到未提交的数据, 则称为**dirty read**(脏读).
![No dirty reads: user 2 sees the new value for x only after user 1’s transaction has committed](/images/System-Design/DDIA/ch-7-4.png)

对于*读已提交*隔离级别的事务, 必须防止脏读. 也就是说, 只有事务成功提交后, 其写入的数据才能被其他事务看到. 上图中, 用户1执行`x = 3`, 但用户2的`get x`仍读取到旧值2(因为用户1还未提交). 防止脏读可避免以下并发问题:
* 若事务需更新多个对象, 脏读会让其他事务看到部分更新. 例如, 用户看到未读邮件, 但看不到更新的计数器. 部分更新状态的数据库会让事务做出错误决定.
* 若事务被中止, 则所有写入数据都需要回滚. 若数据库允许脏读, 事务会看到将被回滚的数据.

#### 2.1.2 No dirty writes
两个事务同时更新同一对象会发生什么? 我们无法确定哪个事务先写入, 但通常认为后者覆盖前者的写入.
但如果前一个事务只进行了一部分, 如果后者覆盖前者的未提交数据, 则称为**dirty write**(脏写). 对于*读已提交*的隔离级别的事务, 必须防止脏写. 通常会推迟第二次写入, 等待第一个事务提交或中止. 通过防止脏写, 可避免以下并发问题:
![With dirty writes, conflicting writes from different transactions can be mixed up](/images/System-Design/DDIA/ch-7-5.png)

* 若事务更新多个对象, 脏写会导致不好结果. 上图中为二手车销售网站, Alice和Bob想购买同一辆车. 购买车辆需要两次数据库写入: 网站上的商品列表需要更新, 以反映买家的行为; 发票需发送给买家. 上图中, 商品列表上属于Bob(因为Bob成功更新listing表), 但发票属于Alice(因为Alice成功更新invoices表). *读已提交*可防止此类问题.
* 然而, *读已提交*不能防止两个计数器自增的竞争状态. 第一次写入提交后才进行的第二次写入, 因此不能算作脏写.

#### 2.1.3 Implementing read committed
*读已提交*是一种非常流行的隔离级别. Oracle 11g, PostgreSQL, SQL Server 2012, MemSQL都默认使用该隔离级别. 
数据库通常使用**row-level lock**(行锁)来避免脏写: 当事务想要修改某个对象时, 必须先获得该对象的锁. 事务提交或中止前都要持有该锁. 每个对象只能有一个事务持有其锁; 若其他事务想写入同一对象, 必须等前一个事务提交或中止. 这种锁定是数据库自动完成的.
如何避免脏读? 其中一种方法是使用锁, 任何事务读取数据时都要先获得锁, 读取后释放. 这样可保证读取时不会有脏值.
但读锁在实践中效果并不好. 一个长时间运行的写入事务会让只读事务等待很久. 等待锁的释放会导致应用的某个部分变慢, 从而触发连锁反应, 致使其他部分也变慢.
出于这个原因, 大多数数据库采用其他方法防止脏读: 对于每个写入的对象, 数据库会保留两个值: 之前提交的旧值和事务正在更新的新值, 其他事务只会读到旧值; 事务提交后, 其他事务可读取到新值.


### 2.2 Snapshot Isolation and Repeatable Read
从表面上看来, *读已提交*可能已经满足了事务的所有需求. 其允许中止事务(atomicity), 防止读取到部分的事务结果, 并防止并发写入造成的混乱. 
但即使使用*读已提交*的隔离级别, 也会遇到很多并发问题. 下图展示了一种可能遇到的并发问题:
![Read skew: Alice observes the database in an inconsistent state](/images/System-Design/DDIA/ch-7-6.png)

Alice有两个储蓄账户, 各有500元. 现在有一笔业务要从一个账户转账100元到另一个账户. 处理业务时她正好查看账户, 这时收款账户仍为500元, 还没收到转账; 但付款账户已经完成转账, 因此只有400元. 对于Alice, 总账户只有900元, 消失了100元.
这种异常称为**nonrepeatable read**(不可重复读)或**read skew**(读取偏差): 若Alice重新刷新页面, 会看到收款账户为600元. *读已提交*的隔离级别下, 读取偏差在是可容忍的: Alice查看的账户余额的确都已提交.
上述例子中的问题并不会长期存在, 只要Alice等几秒再刷新页面就能看到正确余额. 然而, 某些情况下是不能容忍这种短暂的不一致:
* Backups: 备份时需要复制整个数据库, 对于大型数据库, 可能要耗费数小时. 执行备份时, 数据库仍可接受写入. 因此, 被备份的数据将包含旧值和新值. 若需从这样的备份中恢复数据, 则将造成永久性的不一致
* Analytic queries and integrity checks: 有时需要一次扫描数据库中的大部分数据. 这类查询常出现在分析工作中, 或定期完整性检查中. 若不同时间点查询数据库中的不同区域, 返回的结果可能毫无意义.

**Snapshot isolation**(快照隔离)是这类问题的常见解决方案. 该方法让每个事务都从数据库的**consistent snapshot**(一致快照)中读取. 也就是说, 事务可以看到事务开始时数据库中的所有已提交数据. 即使数据随后被其他事务更改, 每个事务也只能看到特定时间点的旧数据.
快照隔离很适合长时间运行的只读查询, 例如备份和分析. 若查询的同时数据也在变化, 则很难理解查询的含义. 但当事务看到是数据库在某个时刻的一致快照时, 查询便容易理解.
PostgreSQL, 使用InnoDB引擎的MySQL, Oracle, SQL Server等数据库都支持快照隔离.

#### 2.2.1 Implementing snapshot isolation
与*读已提交*相似, snapshot isolation也使用写锁来防止脏写. 这意味着, 当某个事务写入时, 其他事务的写入会被阻塞. 但读取时无需任何锁. 从性能的角度来说, 快照隔离的一个关键原则是: 读不会阻塞写, 写也不会阻塞读, 这样就允许数据库对一致性快照进行长时间查询时, 同时处理写入请求, 且两者不会争夺任何锁.
为实现快照隔离, 数据库需保留一个对象的多个不同提交版本, 因为不同事务在不同的时间点看到的数据库状态不同. 由于数据库需要维护单个对象的多个版本, 该技术被称为**multi-version concurrency control**(MVCC, 多版本并发控制).
*读已提交*只需保留对象的两个版本: 已提交的版本和被覆盖但尚未提交的版本. 然而, *快照隔离*使用MVCC实现*读已提交*的隔离级别: 每个查询使用单独的快照, 而整个事务使用相同的快照.
![Implementing snapshot isolation using multi-version objects](/images/System-Design/DDIA/ch-7-7.png)

上图展示了PostgreSQL如何基于MVCC实现快照隔离. 当一个事务开始时, 其会获得一个唯一且永远增长的**transaction ID**(txid). 事务写入的数据都会标记事务ID.
表的每一行都含有一个**created_by**字段, 其中包含该行插入到表中的事务ID. 此外, 每行都有一个**deleted_by**字段, 初始为空. 若某个事务删除该行, 实际上并不会真的删除, 而是将`deleted_by`字段设置该事务的事务ID. 之后如果没有事务访问该行, 垃圾回收进程会将该行删除, 并释放空间.
`UPDATE`在数据库内部翻译为`DELETE`和`INSERT`. 以转账为例, 当事务从转账账户扣除100元时, 余额从500元变为400元. accounts表会包含两行: 一行的余额为500元, 被标记为该事务删除; 另一行余额为400元, 由该事务创建.

#### 2.2.2 Visibility rules for observing a consistent snapshot
当一个事务从数据库读取数据, 事务ID用于决定哪些对象可以被查看. 通过仔细地规定可视规则, 数据库可向应用程序呈现一致的数据库快照, 如下:
1. 事务开始时, 忽略当前正在执行的事务(尚未提交或尚未中断)的所有写入
2. 被中止的事务的写入会被忽略
3. 更大事务ID的事务(该事务开始后的事务)的所有写入都会被忽略
4. 所有其他写入对应用都是可见的

这些规则适用于创建和删除对象. 对于转账例子, 当事务12读取账户2时, 会看到500元余额, 因为删除操作由事务13执行, 事务12看不到该操作, 事务13创建的400元余额也无法被事务12看到.
换句话说, 若满足以下两个条件, 则数据对事务可见:
* 读事务开始时, 创建该对象的事务已提交
* 读事务开始时, 对象未被标记删除; 或被标记为删除, 但事务还未提交

一个长时间运行的事务会长时间使用快照, 从被覆盖或删除的数据中读取(从其他事务的角度来看). 由于从不覆盖数据, 而是创建数据的新副本, 因此数据库的额外开销很小.

#### 2.2.3 Indexes and snapshot isolation
Index如何在多版本的数据库中工作? 其中一种解决方法是让索引指向对象的所有版本, 且需要索引查询过滤掉当前事务不可见的对象. 当垃圾回收删除所有事务都不可见的旧对象版本时, 对应的索引条目也应被删除.
实践中, 实现细节决定了多版本并发控制的性能. 例如, 若同一对象的不同版本可放入同一页面, 则PostgreSQL的优化可避免更新索引.
CouchDB, Datomic, 和LMDB使用另一种方法. 虽然它们也使用B-tree, 但它们使用一种**append-only/copy-on-write**(仅追加/写时拷贝)的变种, 更新时不覆盖tree的页面, 而是为每个修改页面创建一个副本. 从父页面到根节点都会级联更新, 以指向子页面的新版本. 不受写入影响的页面不需要被复制.
对于仅追加的B-tree, 每个写入事务都会创建一个新的B-tree, 从该根节点衍生出的树就是数据库的一致性快照. 由于后续写入不会修改现有的B-tree, 因此也没必要根据事务ID过滤对象, 后续写入只能创建自己的树根. 然而, 这种方法需要一个负责压缩和垃圾回收的后台进程.

#### 2.2.4 Repeatable read and naming confusion
快照隔离是一个有用的隔离级别, 尤其对于只读事务. 然而, 许多数据库虽然实现了该隔离级别, 却以不同名称称呼. 在Oracle中称为**serializable**(可串行化), 在PostgreSQL和MySQL中称为**repeatable read**(可重复读).
出现这种命名混淆是因为SQL standard中没有快照隔离的概念, 这套标准基于System R在1975年定义的隔离级别, 那时快照隔离还未发明. 然而, 该标准定义了与快照隔离十分相似的repeatable read.
不幸的是, SQL standard对于隔离级别的定义存在瑕疵, 比较模糊. 虽然很多数据库实现了可重复读, 但提供的保证存在很大差异.

### 2.3 Preventing Lost Updates
*读已提交*和*快照隔离*主要保证了并发写入时只读事务能看到什么, 但忽略了两个事务并发写入的问题.
并发写入事务之间还有几种有趣的冲突. 其中最出名的为**lost update**(丢失更新)问题, 以两个并发的计数器增量为例.
若应用从数据库读取, 修改, 并写回修改的值, 有可能发生丢失更新的问题. 若两个事务同时执行, 由于后者的写入会覆盖前者, 因此会丢失其中一个值. 该问题会发生于不同的情景:
* 增加计数器或更新账户余额(读取当前数值, 计算新值, 并写回新值)
* 在复杂值中进行本地修改, 例如: 向JSON文档的列表中添加元素(需要解析文档, 进行更改, 并写回修改的文档)
* 两个用户同时编辑一个wiki页面, 每个用户将整个页面内容发送到服务器以保存其更改, 覆盖当前数据库中的所有内容

#### 2.3.1 Atomic write operations
许多数据库提供了**atomic update**(原子更新)操作, 从而无需在应用代码中实现**read-modify-write**(读取-修改-写入)序列. 以下指令在大部分关系数据库中是并发安全的:
```sql
UPDATE counters SET value = value + 1 WHERE key = 'foo';
```

文档数据库(如MongoDB)提供了对JSON文档进行部分修改的原子操作, Redis提供了修改数据结构(如优先队列)的原子操作. 但并不是所有的写操作都可以用原子操作的方式表示, 例如, 涉及任意文本编辑的wiki页面更新, 但如果可以用原子操作, 其仍是最优选择.
原子操作通常通过为读取的对象添加**exclusive lock**(排他锁)来实现, 更新完成前其他事务都不能读取该值. 这种技术称为**cursor stability**(游标稳定性). 另一种选择是让所有原子操作在单个线程执行.
不幸的是, ORM框架很容易执行不安全的read-modify-write序列, 其产生的bug很难通过测试发现.

#### 2.3.2 Explicit locking
若数据库的内置原子操作无法提供所需功能, 还有另一种解决方法: 应用显式锁定需要更新的对象. 当应用执行**read-modify-write**序列时, 其他事务需等待该事务完成序列后再读取.
例如, 多人游戏中多个玩家可以同时移动同一棋子. 但原子操作是不够的, 因为应用程序需确保玩家的移动符合游戏规则, 涉及的一些业务逻辑可能无法直接用数据库查询实现. 但我们可用锁防止两个玩家同时移动同一棋子, 如下:
```sql
BEGIN TRANSACTION;
SELECT * FROM figures
	WHERE name = 'robot' AND game_id = 222
FOR UPDATE;

-- 检查棋子的移动是否合理, 然后更新之前SELECT返回的棋子位置
UPDATE figures SET position = 'c4' WHERE id = 1234;
COMMIT;
```
`FOR UPDATE`子句表示数据库应锁住查询返回的所有行. 虽然很有用, 但要仔细考虑业务逻辑, 很容易忘记在代码中加锁, 从而导致竞争条件.

#### 2.3.3 Automatically detecting lost updates
原子操作和锁通过强制**读取-修改-写入**序列来防止丢失更新. 另一种思路是让事务并行执行, 若检测到丢失更新, 则终止该事务, 并重试读取-修改-写入序列.
这种方法的优点在于, 数据库可以结合快照隔离高效地检查丢失更新. 实际上, PostgreSQL的可重复读, Oracle的可串行化, 和SQL Server的快照隔离级别, 都会自动检测丢失更新, 并中止该事务. 然而, MySQL/InnoDB的repeatable read不会检测丢失更新. 一些人认为, 只有数据库能够防止丢失更新, 才能算作快照隔离.
丢失更新检测是一个很好的功能, 因为它不需要应用代码使用任何特殊的数据库功能. 你可能会忘记使用锁或原子操作而导致出错, 但丢失更新的检测是自动的, 因此不太容易出错.

#### 2.3.4 Compare-and-set
如果数据库不提供事务, 一般会提供**compare-and-set**(CAS, 比较并设置). 此操作的目的在于避免丢失更新: 只有数据从上次读取到现在从未修改过, 才允许更新发生; 若当前值与之前读取的值不匹配, 则不更新, 必须重试读取-修改-写入序列.
例如, 为了防止两个用户同时编辑同一wiki页面, 只有从用户开始编辑到提交更改, 期间该wiki页面从未被更改过, 才允许更新:
```sql
-- 取决于数据库的实现, 该语句可能安全, 也可能不安全
UPDATE wiki_pages SET content = 'new content'
  WHERE id = 1234 AND content = 'old content';
```

若wiki内容与**old content**不匹配, 则更新不生效. 但若数据库允许`WHERE`子句从旧快照读取, 则该语句无法防止丢失更新, 因为即使发生了另一个并发写入, `WHERE`条件也依然为真. 使用CAS操作前要检查其是否安全.

#### 2.3.5 Conflict resolution and replication
在复制数据库中, 防止丢失更新需要考虑另一个维度: 由于副本存在于多个节点, 不同节点上的数据可能被并发修改, 因此需采取额外措施来防止丢失更新.
锁和CAS操作假设只有一个最新的数据副本. 但multi-leader或leaderless复制允许多个写入并发执行, 并异步复制到副本上, 因此无法保证最新数据副本只有一个. 因此, 锁或CAS操作不适用这种情况.
复制数据库中有一种常见的解决方法: 允许多个写入并发执行, 并创建多个冲突版本的值(称为**sibling**), 并使用应用代码或特殊数据结构解决和合并这些版本.
原子操作可以在复制数据库中很好地工作, 尤其当它们具有**commutative**(可交换性, 即不同副本上以不同顺序执行时, 仍能获得相同的结果)时. 例如, 递增计数器将元素添加到集合中, 这个操作具有可交换性. 这是Riak2.0数据类型背后的思想, 其可防止复制副本时造成丢失更新. 当某个值被多个客户端同时修改时, Riak会自动合并这些更新, 以免丢失更新.
另一方面, **LWW**(last write wins, 最后写入胜利)这种解决冲突的方法很容易造成丢失更新. 然而, 很多复制数据库默认使用LWW.


### 2.4 Write Skew and Phantoms
当多个事务并发写入同一对象时, 会发生两种竞争条件: 脏写和丢失更新. 为防止数据损坏, 无论是让数据库自动执行, 或通过锁或原子写入, 都必须防止这类竞争条件.
然而, 这并不是并发写入引起的所有的竞争条件. 本节将展示更多冲突例子. 例如, 一个管理医生轮班的应用程序, 通常会有多个医生同时值班, 但至少有一个医生值班, 医生可因私人原因(如生病)在应用上请假.
假设医院内只有Alice和Bob两个值班医生, 两人都想要请假. 当两人同时点击请假按钮时, 可能发生以下情况:
![Example of write skew causing an application bug](/images/System-Design/DDIA/ch-7-8.png)

应用会先检查当前是否有两个或两个以上的医生正在值班, 如果是, 则批准请假. 由于数据库使用快照隔离, 两个查询都返回2, 因此两个事务都进入下个阶段. Alice的记录改为请假状态, Bob也一样. 两个事务都提交成功, 导致没有医生值班, 违反了至少一个医生值班的保证.

#### 2.4.1 Characterizing write skew
这种异常称为**write skew**(写偏差). 它不是脏读, 也不是丢失更新, 因为两个事务更新的是两个不同的对象(各自的值班记录). 这种冲突很隐蔽, 但显然是一个竞争条件: 若两个事务保证顺序执行, 则后者无法请假. 这种异常行为也只会在事务并发执行时发生.
写偏差可视作丢失更新的泛化. 若两个事务并发读取相同对象, 然后更新不同对象, 则可能发生写偏差; 当多个事务并发更新同一事务时, 则可能发生脏写或丢失更新.
对于丢失更新, 我们有很多解决方法; 但对于写偏差, 选择更受限:
* 由于涉及多个对象, 因此单对象的原子操作没有帮助
* 快照隔离的实现中, 自动检测丢失更新对此没有帮助. PostgreSQL的可重复读，MySQL/InnoDB的可重复读，Oracle可串行化, SQL Server的快照隔离级别, 这些都不会自动检测写偏差. 写偏差的检查需要真正的可串行化隔离.
* 某些数据库允许配置constraint(约束), 由数据库强制执行(如唯一性, 外键约束, 或单个值的约束). 然而, 本例中需要对多个对象施加约束, 大多数数据库没有这种内置约束, 但可使用**trigger**(触发器)或**materialized view**(物化视图)来实现.
* 若没有可串行化的隔离级别, 可显式锁住事务使用的行. 代码如下(`FOR UPDATE`告诉数据库锁住查询返回的所有行):
  ```sql
  BEGIN TRANSACTION;

  SELECT * FROM doctors
    WHERE on_call = TRUE 
    AND shift_id = 1234 FOR UPDATE;

  UPDATE doctors
    SET on_call = FALSE
    WHERE name = 'Alice' 
    AND shift_id = 1234;
    
  COMMIT;
  ```

#### 2.4.2 More examples of write skew
以下是一些写偏差的例子:
1. Meeting room booking system
假设同一个会议室在同一时间不能进行多次预定. 当用户预定时, 需先检查订阅是否冲突(预定时间范围重叠的同一会议室), 若没有发现冲突, 则创建预定.
```sql
BEGIN TRANSACTION;

-- 检查是否存在重叠的预定
SELECT COUNT(*) FROM bookings
WHERE room_id = 123 AND 
	end_time > '2015-01-01 12:00' AND start_time < '2015-01-01 13:00';

-- 若查询返回0, 则执行以下语句
INSERT INTO bookings(room_id, start_time, end_time, user_id)
  VALUES (123, '2015-01-01 12:00', '2015-01-01 13:00', 666);

COMMIT;
```
快照隔离无法阻止用户同时写入冲突的预定. 为了防止预定冲突, 需要可串行化的隔离级别.

2. Multiplayer game
我们可以使用锁来防止丢失更新(确保两个玩家不会在同一时间移动同一棋子). 但锁不能防止两个玩家将两个棋子移动到同一位置. 或许可使用唯一约束, 否则会出现写偏差.

3. Claiming a username
网站中每个用户都有唯一用户名, 两个用户可能同时用同时创建相同名称的用户. 事务会先检查用户名是否被占用, 若没有, 则成功创建用户. 然而, 快照隔离下这是不安全的. 需使用唯一约束解决(第二个事务注册用户时会因违反唯一约束而中止).

4. Preventing double-spending
一些服务允许用户使用钱或积分, 需在支付前检查付款是否超过余额. 我们插入一个临时消费项目, 列出账户内所有项目, 并检查总和是否为正值. 若两笔支出并发写入账户, 可能导致支出大于余额, 但两个事务都不会觉察到.

#### 2.4.3 Phantoms causing write skew
以上所有例子都有以下特征:
1. 执行`SELECT`语句, 检查是否满足某种条件(至少一名医生值班, 会议室没有重叠预定, 用户名未被占用, 落子点没有棋子, 账户中余额大于某个值).
2. 根据上述查询的结果, 应用代码决定是否继续
3. 若继续执行, 则写入数据(INSERT, UPDATE, 或DELETE)并提交事务. 第三步的写入破坏了第二步的先决条件. 换句话说, 若写入后重复第一步的查询, 会得到不同结果.

上述步骤可能以不同的顺序发生. 例如: 先写入再执行`SELECT`查询, 最后判断是否中止该事务.
在医生值班的例子中, 第三步的写入的行是第一步返回的行, 因此可锁住第一步的行. 然而其他例子则不同: 它们会查看满足某些条件的行是否存在, 如果不存在则插入行. 若第一步不返回任何行, 则锁不了任何数据.
一个事务的写入改变了另一个事务的查询结果, 称为**phantom**(幻读). 快照隔离可防止只读查询中出现幻读; 但读写事务中, 幻读会导致写偏差.

#### 2.4.4 Materializing conflicts
如果幻读的问题在于没有对象可以加锁, 可人为引入一个锁对象. 以预定会议室为例, 可创建一个关于时间槽和会议室的表. 表中每一行对应特定时间段(如15分钟)的指定房间. 可提前插入所有会议室的所有时间段(如接下来的6个月).
当用户预定会议室时, 可锁住(SELECT FOR UPDATE)特定时间段的特定会议室. 获得锁后, 再检查预定是否重叠, 最后写入新的预定. 该表并不用于存储预定相关的信息, 只是为了防止某个会议室在某个时间段被同时预定.
这种方法称为**materializing conflict**(物化冲突), 其将幻读转换为某些行的锁冲突. 然而, 这种方法很难实现, 且容易出错, 让并发控制机制出现在数据模型中是很丑陋的做法. 因此, 该方法应作为不得已为之的手段. 大多数情况下, 更适合使用可串行化的隔离级别.


## 3. Serializability
*读已提交*和*快照隔离*不能防止所有竞争条件, 还有一些棘手的问题, 如写偏差和幻读:
* 隔离级别难以理解, 且不同数据库的实现不一致(repeatable read的定义完全不同)
* 很难判断在特定隔离级别下应用程序代码是否安全; 尤其是大型项目, 很难知道并发发生的所有事
* 没有很好检测竞争条件的工具. 原则上, **static analysis**(静态分析)可能有所帮助, 但研究成果无法应用到实践. 由于并发问题都是不确定的, 因此检测十分困难, 只有在某些时序下才能发现问题.

从1970年就发现了上述问题, 当时引入了较弱的隔离级别. 研究人员的答案也很简单: 使用**serializable isoaltion**(可串行化的隔离).
可串行化隔离通常被视为最强的隔离级别. 即使事务并发执行, 最终的结果和串行执行一样, 就像没有并发发生. 因此数据库可保证, 若事务能单独运行, 则多个事务并发执行也能保持正确. 换句话说, 其可防止所有可能的竞争条件.
如果可串行化隔离这么有用, 为什么没有被大范围使用? 为回答这一问题, 需要了解该隔离级别的实现, 其如何运行. 以下是三种实现可串行化隔离的方式:
* 以串行顺序执行事务
* **Two-phase locking**(2PL, 二阶段锁定) 
* 乐观并发控制技术, 如**serializable snapshot isolation**(可串行化快照隔离)

以下都以单节点数据库为前提.

### 3.1 Actual Serial Execution
最简单的方法就是完全移除并发: 单个线程中只执行一个事务. 这样就完全绕开了冲突检测和防止事务冲突的问题, 从而实现可串行化的隔离级别.
虽然这种想法很早就提出, 但直到2007年才被开始使用. 如果多线程并发在过去30年都有不错的性能表现, 为什么现在转向了单线程执行? 主要是以下两点原因:
* RAM足够便宜, 很多场景都可将完整数据集放入内存. 当事务所需的数据都在内存中时, 事务执行的速度比从磁盘加载快很多.
* OLTP事务通常很短, 只包含少量读写操作, 通常是只读的, 因此可使用一致性快照(使用快照隔离), 摆脱了串行执行循环.

VoltDB/H-Store, Redis, 和Datomic实现了串行化执行事务. 单线程可避免锁的协调开销, 因此有时比并发执行更快. 但其吞吐量受限于单个CPU的吞吐量. 为了充分使用单线程, 需采用与传统事务不同的数据结构.

#### 3.1.1 Encapsulating transactions in stored procedures
在数据库的早期阶段, 数据库事务可包含用户的整个活动流程. 例如, 预定机票是一个多阶段过程(查询路线, 费用, 和座位; 决定行程; 订座, 输入乘客信息; 付款). 数据库设计者认为, 若整个流程作为一个事务, 就可以原子化地执行.
然而, 人类活动相对于计算机来说非常缓慢. 若数据库事务需要等待用户输入, 则必须能支持大量并发事务, 其中大多数事务处于空闲状态. 绝大多数数据库都无法高效实该工作, 因此大多数OLTP应用程序会避免在事务中等待用户, 以保证事务简短. 对于Web应用, 事务会在同一个HTTP请求中提交, 不会横跨多个请求. 新的HTTP请求开启一个新的事务.
即使不考虑用户交互, 事务仍以交互的方式执行, 一次一个语句. 应用执行查询, 读取结果, 并根据查询结果执行另一次查询. 查询和数据在应用程序代码(某个机器)与数据库服务器(另一个机器)之间来回发送.
对于交互式事务, 大部分时间都消耗在应用与数据库之间的传输上. 若不允许数据库并发处理, 则吞吐量会十分低, 因为数据库大部分时间都在等待当前事务的下一个查询. 为获得更好的性能, 需要并行处理多个事务.
出于以上原因, 单线程串行事务处理系统不允许交互式的多语句事务. 相反, 应用程序必须提前将整个事务代码作为**stored procedure**(存储过程)提交给数据库. 下图展示了两者的不同. 若事务所需的所有数据都在内存中, 则存储过程执行很快, 无需等待网络或磁盘I/O.
![The difference between an interactive transaction and a stored procedure](/images/System-Design/DDIA/ch-7-9.png)

#### 3.1.2 Pros and cons of stored procedures
存储过程在关系数据库中存在了很长时间, 自1999年起就成为SQL standard的一部分. 但出于以下原因, 其饱受诟病:
* 每个数据库供应商有自己的存储过程语言(Oracle的PL/SQL, SQL Server的T-SQL, PostgreSQL的PL/pgSQL等). 这些语言没有跟上其他编程语言的发展, 以现在的眼光看来, 书写起来非常丑陋和过时, 且缺乏库的支持.
* 数据库中运行的代码很难管理: 相比于应用程序代码, 这类代码更难调试, 也很难版本控制, 部署, 和测试, 更难以集成到指标收集系统进行监控.
* 由于单个数据库会被多个服务器共享, 因此数据库对性能更加敏感. 一个糟糕的存储过程所造成的开销远大于应用程序中的糟糕代码.

上述问题都是可以解决的. 现代存储过程的实现已经放弃了PL/SQL, 转向通用编程语言: VoltDB使用Java或Groovy, Datomic使用Java或Clojure, Redis使用Lua.
存储过程和内存存储使得单线程上执行所有事务变得可行. 由于其无需等待I/O, 且没有并发控制的开销, 因此拥有相当高的吞吐量.
VoltDB还将存储过程用于复制: 与其将事务的写入复制到其他节点, 不如在每个节点都执行存储过程. 因此VoltDB要求: 存储过程需为**deterministic**(确定性的, 不同节点上存储过程运行的结果相同). 例如, 若事务需使用当前日期和时间, 则必须使用特殊的确定性API实现.

#### 3.1.3 Partitioning
顺序执行让并发控制变得简单, 但事务的吞吐量被限制为单机单核的处理速度. 只读事务可使用快照隔离在其他地方执行, 但对于写入吞吐量高的应用, 单线程事务的处理器会成为一个瓶颈.
为了利用多核和多节点, 可对数据进行**partition**(分区). 如果能对数据集进行分区, 那么每个事务只需在单个分区上读写, 每个分区也就拥有自己的事务处理线程. 此时可为每个CPU分配一个分区, 事务吞吐量与CPU核心数呈线性关系.
然而, 对于需要访问多分区的事务, 数据库必须在各个分区间协调事务. 存储过程需对所有分区加锁, 以确保整个系统的可串行性.
跨分区事务的开销比单分区事务大得多, VoltDB大概每秒处理1000个跨分区写入, 比单分区事务低好几个数量级, 且无法通过增加机器来增加吞吐量.
事务能否划分为单分区取决于数据结构. key-value数据很容易分区, 但带有多个二级索引的数据通常需要跨分区.

#### 3.1.4 Summary of serial execution
在特定条件下, 可使用串行执行事务来实现可串行化的隔离级别:
* 事务小且快, 只要有一个慢事务, 就会拖慢其他事务处理
* 数据集可放入内存中. 很少被访问到的数据可放入磁盘, 一旦单线程事务需访问磁盘数据, 整个系统都会变得很慢
* 写入吞吐量必须低到单个CPU就能处理, 否则需将事务划分至单个分区, 且无需跨分区协调
* 可使用跨分区事务, 但其有很大局限性


### 3.2 Two-Phase Locking(2PL)
近30年来, 数据库只有一种广泛使用的串行化算法: **two-phase locking**(两阶段锁定, 2PL).
锁用于防止脏写: 当两个事务同时写入同一对象时, 锁可保证后者必须等待前者完成(提交或中止); 2PL与其类似, 但对锁的要求更高. 如果没有写入, 则允许多个事务同时读取同一象; 一旦有事务写入(修改或删除), 需先获得**exclusive access**(独占访问)权限:
* 若事务A正在读取对象, 事务B想要写入该对象, B需等待A提交或中止
* 若事务A正在写入对象, 事务B想要读取该对象, B需等待A提交或中止

在2PL中, 写入不仅会阻塞其他写入, 还会阻塞读取, 反之亦然. 快照隔离遵循: 读取和写入互不阻塞, 这也是快照隔离和2PL的区别. 由于2PL提供了可串行化, 因此可防止所有竞争条件的发生, 包括丢失更新和写偏差.

#### 3.2.1 Implementation of two-phase locking
MySQL和SQL Server使用2PL实现可串行化隔离界别, DB2使用2PL实现可重复读隔离级别.
读写的阻塞由数据库中对象添加锁来实现. 锁有两种模式: **shared mode**(共享模式)和**exclusive mode**(独占模式). 锁的使用如下:
* 若事务要读取一个对象, 必须先获得共享锁. 多个事务可同时持有共享锁, 但若某个事务已持有该对象的排它锁, 则其他事务必须等待.
* 若事务要写入一个对象, 必须先获得排它锁. 其他事务无法再获得任何锁(无论是共享锁还是排它锁), 必须等待当前事务完成.
* 若事务先读取对象, 之后要写入对象, 则需将共享锁升级为排它锁. 升级锁与直接获得排它锁的流程相同.
* 事务获得锁后, 事务完成前(提交或中止)不能丢弃锁. 这就是**二阶段**的由来: 第一阶段获取锁(事务开始时), 第二阶段释放锁(事务结束时)

由于大量使用锁, 可能会发生: 事务A等待事务B释放锁, B也在等待A释放锁, 称为**deadlock**(死锁). 数据库会自动检测死锁并终止其中一个事务. 被中止的事务需由应用程序重试.

#### 3.2.2 Performance of two-phase locking
2PL的缺点在于性能开销: 相比于弱隔离, 2PL的吞吐量和查询响应时间都很差.
一部分是因为获得和释放锁的开销, 但更多是并发性的降低. 若两个并发事务导致了竞争条件, 则必须让一个事务等待另一个事务完成.
由于传统关系数据库是为交互式应用而设计, 其并不限制事务的持续时间. 因此, 当一个事务需要等待另一个事务时, 并没有限制等待时间. 即使每个事务都很短, 当多个事务想要访问同一个对象时, 也会形成一个队列, 一个事务可能要等待多个事务完成后才能执行.
因此, 使用2PL的数据库的延迟不稳定, 高百分比的响应可能非常慢. 一个很慢的事务, 或一个访问大量数据的事务就能让整个系统暂停.
虽然基于锁的读已提交的隔离级别可能发生死锁, 但基于2PL的可串行化的隔离级别更容易发生死锁(取决于事务的访问模式). 这可能造成额外的性能问题: 当事务因死锁而中止, 重试需要重做很多工作. 频繁的死锁会导致巨大浪费.

#### 3.2.3 Predicate locks
之前讨论过phantom(幻读)的问题, 即一个事务会改变另一个事务的查询结果. 具有可串行化隔离级别的数据库必须防止幻读.
会议室预定的例子中, 当某个事务搜索一个时间范围内会议室的已有预定时, 其他事务不能同时插入或更新同一时间段且同一会议室的其他预定(可向其他会议室添加预定, 也可在不同时间范围为会议室添加预定). 那么如何实现呢?
**Predicate lock**(谓词锁)可实现上述功能. 其类似于共享/排它锁, 但不属于特定对象(如表中的一行), 其属于某种搜索条件下的任意对象, 例如:
```sql
SELECT * FROM bookings
  WHERE room_id = 123 AND
    end_time > '2018-01-01 12:00' AND 
    start_time < '2018-01-01 13:00';
```

谓词锁限制访问的步骤如下:
* 若事务A读取某种条件下的对象, 如`SELECT`查询, 必须先获得该查询条件上的**shared-mode predicate lock**(共享谓词锁). 若事务B持有该搜索条件下某个对象的排它锁, 则A必须等待B释放锁.
* 若事务A想要插入, 更新, 或删除某些对象, 其必须先检查旧值或新值是否与现有的谓词锁匹配. 若事务B持有匹配的谓词锁, 则A必须等待B完成(提交或中止).

谓词锁适用于当前尚未添加, 但未来可能添加的对象. 若2PL包含谓词锁, 则可防止任何形式的写偏差和其他竞争条件, 从而实现可串行化.

#### 3.2.3 Index-range locks
但谓词锁的性能不佳: 若事务拥有太多锁, 查询匹配的锁会非常耗时. 因此, 大多数2PL数据库使用**index-range locking**(索引范围锁, 也称为next-key locking), 可视为简化版的谓词锁.
扩大谓词锁匹配的对象集合不会造成任何问题, 以此简化的谓词锁必然安全. 例如, room_id为123且时间段为12pm到1pm的谓词锁, 可将该锁简化为: room_id为123的任意时间, 或时间段为12pm到1pm的所有会议室. `满足简化后谓词的对象集合`一定包含`满足原始谓词的对象集合`.
在会议室预定数据库中, 会在**room_id**列上有一个索引, 或在**start_time**和**end_time**上有索引(若不创建索引, 数据库中查询会变得很慢):
* 假设**room_id**上有索引, 且数据库使用该索引查找room_id为123的已有预定. 数据库可将共享锁附加到该索引, 表示事务正在搜索123号会议室的预定.
* 若数据库使用基于时间的索引来查找已有预定, 可将共享锁附加到该索引的一系列值上, 表示事务正在搜索12pm到1pm之间的所有预定.

无论那种方式, 搜索条件的近似值都指向一个索引. 若另一个事务想要插入, 更新, 或删除同一会议室或同一时间区间的预定, 其必须更新索引中的相同部分, 这时会遇到共享锁并等待锁释放.
这种方法可防止幻读和写偏差. 索引范围锁不如谓词锁精确, 但开销更小. 若找不到合适的索引用于索引范围锁, 数据库会为整个表附加共享锁.

### 3.3 Serializable Snapshot Isolation(SSI)
现在有两种实现可串行化的方式: 2PL(性能差)和串行执行(没有伸缩性); 还有弱隔离级别: 性能很好, 但容易造成竞争条件(丢失更新, 写偏差, 幻读等). 所以可串行化的隔离级别和高性能无法兼得么?
有一种算法称为**serializable snapshot isolation**(可串行化快照隔离), 其提供了可串行化隔离级别, 但相对于快照隔离只有很小的性能代价.
SSI于2008年被首次提出, 既可用于单节点数据库(PostgreSQL 9.1后的可串行化隔离级别), 也可用于分布式数据库(FoundationDB使用类似算法). 但由于SSI与其他并发控制算法相比还很年轻, 还需要在实践中证明自己的性能表现, 未来可能成为新的默认选项.

#### 3.3.1 Pessimistic versus optimistic concurrency control
2PL是一种**悲观的并发控制机制**: 若某件事可能出错(其他事务持有想要的锁), 必须等到安全后再做任何事. 就像多线程编程中的**mutual exclusion**(互斥).
从某种意义来说, 串行执行是一种极度的悲观: 每个事务都对整个数据库持有排它锁. 为了补偿这种悲观, 必须让每个事务快速执行, 换句话说, 事务只能短暂地持有锁.
相比之下, SSI是一种**乐观的并发控制技术**: 即使存在潜在危险也不阻止事务, 而是继续执行, 并希望一切能会好起来. 提交事务时, 数据库检查是否发生了不好的事(即是否破坏了隔离); 若发生了坏事, 则中止事务并重试. 只有可串行化的事务才会被允许提交.
乐观并发控制很早就存在, 其优缺点都被讨论了很久. 当发生大量争夺时(多个事务试图访问同一对象), 由于大部分事务都会被中止, 因此性能不佳. 若系统已处于高负载下, 重试事务会带来额外负担, 致使性能变差. 
但如果有足够的备用容量, 且事务争抢不多, 则乐观并发控制技术比悲观好很多. 可交换的原子操作可减少争夺: 例如, 多个事务同时增加一个计数器, 增加的顺序并不重要, 并发增量可全部提交且无需冲突.
SSI基于快照隔离, 即事务中的所有读取都来自一致性快照. 相比于快照隔离, SSI增加了一个算法来检测写入之间的串行冲突, 并决定中止哪些事务.

#### 3.3.2 Decision based on an outdated premise
快照隔离的写偏差存在一个模式循环: 事务读取数据, 根据查询结果决定接下来的操作(写入数据库). 但快照隔离中查询返回的数据可能不是最新值.
换句话说, 事务基于一个**前提**(事务开始时为真的事实, 如, 当前值班医生有两位)采取行动; 然而, 当事务提交时, 最初的数据可能已经改变, 也就是前提不再成立.
应用程序查询数据时(如, 现在有几个值班医生), 数据库并不知道应用程序如何使用该查询结果. 为安全起见, 数据库会假设: 任何查询结果的任何改变都会让事务的写入无效. 换句话说, 事务中的查询和写入可能存在因果依赖. 为提供可串行化的隔离级别, 若事务在过时的前提下执行操作, 数据库必须中止该事务.
那么数据库如何知道查询结果是否被改变? 以下是两种需要考虑的情况:
* 检测对旧MVCC对象版本的读取(读之前存在未提交的写入)
* 检测影响先前读取的写入(读之后发生写入)

#### 3.3.3 Detecting stale MVCC reads
快照隔离通过MVCC(多版本并发控制)来实现, 事务从一致性快照中读取数据时, 会忽略其他事务尚未提交的写入. 下图中, 由于事务42尚未提交, 因此事务43看到Alice的`on_call = true`. 然而, 当事务43提交时, 事务42已经提交. 这意味着, 事务开始时尚未提交的写入已经生效, 事务43的前提不再为真.
![Detecting when a transaction reads outdated values from an MVCC snapshot](/images/System-Design/DDIA/ch-7-10.png)

为防止上述异常, 数据库需要跟踪事务因MVCC可见规则而忽略的写入. 事务提交时, 数据库应判断之前被忽略的写入是否提交. 如果写入已提交, 则中止该事务.
为什么要等到提交时才判断, 而不是在事务42提交时直接中止事务43? 因为如果事务43是一个只读事务, 则没必要中止, 因为没有写偏差的风险. 事务43读取时, 数据库并不知道其之后会写入. 此外, 事务43提交时, 事务42可能被中止或尚未提交, 因此事务43读取的不一定是旧值. 为避免无意义的中止, SSI会保留一致性快照的读取能力.

#### 3.3.4 Detecting writes that affect prior reads
下图展示当一个事务读取数据后, 该查询结果被其他事务修改:
![In serializable snapshot isolation, detecting when one transaction modifies another transaction’s reads](/images/System-Design/DDIA/ch-7-11.png)

在2PL中我们讨论了索引范围锁, 其允许数据库锁住某个查询匹配的所有行, 如`WHERE shift_id = 1234`. SSI使用类似的技术, 但不会阻塞其他事务.
事务42和43都查询`shift_id = 1234`的值班医生. 若`shift_id`上有索引, 则数据库可使用索引项1234记录两个事务读取的事实(若没有索引, 则在表级别上进行跟踪). 这类信息只需要保留一段时间: 当某个事务完成, 且所有并发事务完成后, 就可以删除该信息.
当事务写入数据库时, 必须在索引中查找最近读取过该数据的其他事务. 这一过程和在键范围上获取写锁类似, 但不会阻塞事务的读操作. 只是通知其他事务: 你读取的数据可能是过时的.
事务43通知42其之前读取的数据已过时, 反之亦然. 事务42先提交: 虽然事务43的写入影响了42, 但43还未提交, 因此写入还未生效. 然而, 当事务43提交时, 事务42的冲突写入已被提交, 因此事务43必须中止.

#### 3.3.5 Performance of serializable snapshot isolation
实现细节会影响算法的实际表现. 例如, 其中一个权衡是跟踪读取和写入的**granularity**(颗粒度). 若数据库详细跟踪每个事务的活动, 虽然可以准确确定哪些事务需被中止, 但开销很大. 简略的记录能让运行更快, 但会导致不必要的中止.
某些情况下, 事务可以读取其他事务重写过的数据: 有时无论执行过程如何, 结果都是串行的. PostgreSQL使用这一理论来减少不必要的中止.
相比于2PL, 可串行化快照的最大优点是: 一个事务不会因其他事务已经持有锁而被阻塞. 就像快照隔离中写入不会阻塞读取, 读取也不会阻塞写入. 这种设计让查询延迟更容预测. 只读查询不需要任何锁, 非常适合频繁读取的场景.
与串行执行相比, 可串行化快照隔离不会受到单核CPU的吞吐量的限制: FoundationDB会检测多台机器上的串行化冲突, 允许拓展更高的吞吐量. 即使数据分片到多台机器, 事务仍可在保证可串行化隔离级别的同时, 同时读写多个分片.
事务中止率会严重影响SSI的性能. 例如, 一个长时间读写的事务很容易被中止, 因此SSI要求事务尽量短小(长时间的只读事务不受影响). 但相比于2PL和串行执行, SSI对长时间读写事务的敏感度更低.