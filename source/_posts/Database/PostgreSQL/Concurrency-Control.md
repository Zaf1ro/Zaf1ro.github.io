---
title: PostgreSQL Concurrency Control
abbrlink: a7f0
date: 2022-08-07 10:35:52
tag:
  - Database
category:
  - Database
  - PostgreSQL
keywords:
description:
---

本文将讲解PostgreSQL面对两个或多个session同时访问同一数据的不同行为. 由于session访问数据的高效性与数据完整性无法兼得, 因此开发者需了解数据库的不同并发控制策略, 在保证数据完整性符合业务要求的前提下, 尽量提高数据访问速度.

## 1. Introduction
PostgreSQL为开发者提供了一系列管理**并发访问数据**的工具. PostgreSQL内部使用**MVCC**(Multiversion Concurrency Control)来维护数据一致性, 换句话说, 每条statement只能看到过去某个时间点的数据快照, 而不是当前的最新数据, 以此防止statement看到其他并发事务的更改, 为每个session提供**transaction isolation**(事务隔离). 与传统数据库通过**lock**(锁)来实现事务隔离不同, MVCC可减少**lock contention**(锁竞争), 并在多用户环境中实现更佳性能.
在MVCC并发控制模型中, 数据查询与写入并不冲突, 从而无需等到对方释放锁. 即使是最严格的事务隔离级别, PostgreSQL也使用MVCC(SSI, Serializable Snapshot Isolation). PostgreSQL还支持row级别和table级别的lock, 这样开发者可手动处理特定的冲突点, 无需每时每刻都使用更严格的事务隔离. 不过, MVCC在性能上通常比lock更好, 并且, 应用程序定义的advisory lock提供一种不绑定到任何一个事务的锁机制.


## 2. Transaction Isolation
SQL standard定义了四种事务隔离级别, 其描述了多个并发执行的事务作用于同一数据时产生的不同效果. **Serializable transaction**保证多个并发事务的执行结果与串行化执行的效果相同; 其他三种事务隔离级别由不同现象所定义, 换句话说, 对于多个并发事务, 不同的事务隔离级别定义了事务之间不同的交互方式, Serialzable事务隔离级别下, 多个并发事务之间不存在任何交互.

以下是并发事务中可能出现的现象:
* dirty read(脏读): 当前事务读取到其他并发事务的未提交数据(uncommited)
* nonrepeatable read(非重复读): 当前事务重读之前读过的数据时, 发现数据已被其他并发事务提交修改
* phantom read(幻读): 当前事务重新执行相同**search condition**的query时, 发现与之前搜索的结果不相同, 数据已被其他并发事务提交修改
* serialization amomaly(一致性异常): 不会出现上述现象, 但执行的结果无法与"串行执行并发事务"的结果吻合; 换句话说, 无论以何种顺序串行执行并发事务, 都无法实现该结果.

以下是四种事务隔离级别中允许和不允许出现的现象:

| Isolation Level |	Dirty Read | Nonrepeatable Read | Phantom Read | Serialization Anomaly |
|:---:|:---:|:---:|:---:|:---:|
| Read uncommitted | Allowed, but not in PG | Possible | Possible | Possible |
| Read committed | Not possible | Possible | Possible | Possible |
| Repeatable read | Not possible | Not possible	Allowed, but not in PG | Possible |
| Serializable | Not possible | Not possible | Not possible | Not possible |

PostgreSQL支持上述四种事务隔离级别, 但实际上只实现了三种事务隔离级别(由于PostgreSQL使用MVCC架构, 因此Read Uncommitted等同于Read Committed, 永远不存在dirty read). PostgreSQL中的Repeatable Read不存在phantom read, 但SQL standard并没有指定哪些现象必须发生在哪个事务隔离级别中, 而是某些现象不能发生在哪个事务隔离级别中.

### 2.1 Read Committed Isolation Level
Read Committed(简写为RC)是PostgreSQL的默认事务隔离级别. 该事务隔离级别下, `SELECT`只能看到已提交的数据, 无法看到未提交的数据, 或执行`SELECT`时正在提交的数据. 实际上, `SELECT`看到的是查询开始时的一个数据库快照, 但`SELECT`可以看到当前事务中已执行的修改, 即使这些修改尚未提交. 需要注意的是, 单个事务中两个连续的`SELECT`可能看到不同数据, 因为第二个`SELECT`执行前, 可能有其他事务提交了修改.

就**搜索目标行**来说, `UPDATE`, `DELETE`, `SELECT FOR UPDATE`, 和`SELECT FOR SHARE`与`SELECT`的行为一致: 他们只能看到command开始时已提交的数据; 但目标行被发现时, 可能已被其他并发事务更新(删除, 或锁定), 这时, 若其他事务正在提交或回滚, 当前事务需等待其他事务执行完毕, 分为两种情况:
* 第一个事务回滚修改: 当前事务继续更新目标行
* 第一个事务成功提交: 
    * 第一个事务删除目标行: 当前事务忽略该行
    * 第一个事务修改目标行: 当前事务的`WHERE`子句会重新评估查询条件, 若更新后的行符合搜索条件, 则继续使用该行.

`SELECT FOR UPDATE`和`SELECT FOR SHARE`意味着目标行会被锁定, 并返回给client.
对于带有`ON CONFLICT DO UPDATE`子句的`INSERT`命令, 若不发生其他错误, 要么插入行, 要么执行更新. 若其他事务已执行`INSERT`(但还没提交), 当前事务会等待其他事务提交, 并执行`UPDATE`(无论其他事务回滚或成功提交).
对于带有`ON CONFLICT DO NOTHING`子句的`INSERT`命令, 若其他事务的执行结果与当前语句发生冲突, 即使其他事务尚未提交, 也会放弃执行该命令. 需要注意的是, 这种情况只发生在RC中.
鉴于上述情况, 更改数据的命令可能看到不一致的快照: 其可能看到其他并发事务正在对目标行进行修改, 但不能看到这些命令对于其他行的影响. 这使得RC不适合复杂搜索条件的命令, 更适用于简单搜索条件的命令, 如更新银行余额:
```sql
BEGIN;
UPDATE accounts SET balance = balance + 100.00 WHERE acctnum = 12345;
UPDATE accounts SET balance = balance - 100.00 WHERE acctnum = 7534;
COMMIT;
```

若两个事务同时更新账户号为12345的余额, 则第二个事务会在第一个事务的修改上进行更新, 因为每个命令只作用于一行, 让当前事务看到其他事务的修改并不会产生任何数据不一致.
在RC中, 更复杂命令可能产生预料之外的结果: 假设一个`DELETE`命令想要删除数据, 但其他事务也在添加或删除数据, 例如, `website`表有一列`hits`, 表中有两行数据: `hits = 9`和`hits = 10`.
```sql
BEGIN;
UPDATE website SET hits = hits + 1;
-- run from another session: DELETE FROM website WHERE hits = 10;
COMMIT;
```

即使更新前和更新后都存在hits为10的行, 但`DELETE`不会删除任何数据: 执行`UPDATE`前, `DELETE`跳过hits为9的行; `UPDATE`执行完毕后, DELETE获得锁, 另一行的hits从10变为11, 不符合搜索条件.
由于RC会为每个命令分配一个新的快照(包含所有事务已提交的数据), 单个事务中靠后的命令会看到其他并发事务的提交. 因此, 之所以出现上述问题, 是因为单个命令无法看到数据库的一致视图.
RC提供的**partial transaction isolation**(部分事务隔离)对于某些应用程序是完全够用的, 且足够简单高效; 然而, 该事务隔离级别不适用于所有场景, 当业务需要执行复杂的查询和更新时, RC无法提供一个一致的数据库视图.

### 2.2 Repeatable Read Isolation Level
**Repeatable Read**(简写为RR)只会让事务看到其开始时已提交的数据, 不会在事务执行过程中看到其他并发事务提交或未提交的数据(但单个事务中的命令可以看到之前命令的执行结果). PostgreSQL提供了比SQL standard更严格的隔离级别, 可防止除serialzation anomalies之外的所有现象.
该隔离级别与RC的区别在于: RR中的事务只能看到其第一个non-transaction-control statement开始执行时的数据库快照. 因此, 单个事务内的多个相同`SELECT`会得到相同结果, 换句话说, 当前事务不会在事务开始后看到其他并发事务的修改.
该隔离级别下的应用必须在serialization failure后重试事务. 就**搜索目标行**而言, `UPDATE`, `DELETE`, `SELECT FOR UPDATE`, 和`SELECT FOR SHARE`与`SELECT`的行为一致: 这些命令只会查找当前事务开始时快照内的数据; 然而, 目标行可能在此期间被其他并发事务修改(删除, 或锁定), 事务需等待前一个事务提交或回滚. 若前一个事务回滚, 则当前事务继续更新目标行; 若前一个事务成功提交, 由于RR事务隔离级别不允许修改或锁定其他事务修改的行, 因此当前事务必须回滚, 并返回以下信息:
```text
ERROR:  could not serialize access due to concurrent update
```

当应用接收到上述错误信息时, 其应放弃当前事务, 并重试整个事务. 第二次执行时, 该事务会看到其他事务提交的更改, 因此不存在任何逻辑冲突. 需要注意的是, 只有需要更新的事务需要重试, 只读事务不存在任何一致性冲突.
RR提供了一个强力保障: 每个事务都能看到一个完全且不变的数据库视图. 然而, 与串行执行并发事务相比, 该隔离级别下的数据库视图并不与其一致. 例如, 该隔离级别下的只读事务虽然可以看到批处理更新后的所有记录, 但无法知道哪些记录逻辑上属于该批处理. 如果不妥善使用显式锁来防止冲突的事务, 该隔离级别下无法通过事务正确地执行业务逻辑.
PostgreSQL中的RR由**Snapshot Isolation**(快照隔离)实现. 与使用锁来解决并发问题相比, 该技术在行为上和性能上有所区别. 一些系统可能将RR和Snapshot Isolation作为两种不同的隔离级别. 直到SQL standard制定后才正式确定这两种技术的允许现象.

### 2.3 Serializable Isolation Level
Serializable事务隔离级别提供了最严格的事务隔离级别, 其模拟了所有事务的串行执行: 事务就好像一个个串行执行, 而不是并行执行. 然而, 与RR级别相同, 应用也必须在serialization failure后重试整个事务. 实际上, 该事务隔离级别与RR上基本相同, 但会监控**一组并发事务的执行结果**与**串行执行事务的执行结果**是否一致. 这种监控不会引入任何超出RR的阻塞, 但还是会产生一些开销, 且当检测到**serialization anomaly**时会触发serialization failure.
以`mytab`表为例, 其中含有以下数据:
```text
 class | value
-------+-------
     1 |    10
     1 |    20
     2 |   100
     2 |   200
```

假设存在两个并发事务A和B, 两者都在RR事务隔离级别下同时执行, 事务A执行以下命令:
```sql
SELECT SUM(value) FROM mytab WHERE class = 1;
```
事务A得到结果30, 并向table插入一行value为30, class为2的新行.
事务B执行以下命令:
```sql
SELECT SUM(value) FROM mytab WHERE class = 2;
```
事务B得到结果300, 并向table插入一条value为300, class为1的新行. 两个事务都读取到各自事务开始时的数据库视图, 因此会成功执行; 但该结果无法与任何串行执行事务的结果匹配(先执行A再执行B, 或先执行B再执行A), 因此若使用Serializable事务隔离级别, 会让其中一个事务提交, 让另一个事务回滚, 并返回以下信息:
```text
ERROR: could not serialize access due to read/write dependencies among transactions
```

因为如果A在B之前执行, B会得到330, 而不是300; 相同的, 若B在A之前运行, A也会得到不同结果.
当使用Serializable事务隔离级别来防止anomalies时, 除非该事务成功提交, 否则事务所读到的数据随时可能无效, 即使是只读事务也不能避免, 除非从`deferrable read-only transaction`中读取数据, 因为这种事务会等到快照没有任何问题时才读取数据. 在任何情况下都不能依赖被中止事务中读到的数据, 只能重试, 直到成功提交.

PostgreSQL使用**predicate locking**来确保serializability, 该方法会判断当前事务是否会对其他并发事务读取到的数据产生影响, 这种lock不会造成任何阻塞, 因此不会导致死锁. 当多个并发事务同时执行时, lock会定义并标记不同事务之间的依赖关系, 以此判断哪些执行会造成serialization anomalies. 相比之下, RC或RR为了保证数据一致性, 可能需要对整个table加锁, 以防止其他事务使用该table; 或使用`SELECT FOR UPDATE`或`SELECT FOR SHARE`, 这么做不仅会阻塞其他事务, 还会导致磁盘读取.

与其他数据库一样, PostgreSQL中的predicate locks也基于事务实际访问的数据, 这些lock会在`pg_locks`中以**SIReadLock**模式存在. 执行查询期间所用的锁取决于其使用的query plan, 且为防止跟踪锁而导致内存耗尽, 会将多个细颗粒锁合并为几个粗颗粒锁. 只读事务中, 若检测到不会发生导致serialization anomaly的冲突, 则会在事务完成前释放SIRead锁. 实际上, 只读事务会在启动时判断并避免使用predicate lock; 若应用显式请求一个`SERIALIZABLE READ ONLY DEFERRABLE`事务, 则PostgreSQL会阻塞该事务, 直到检测到无冲突发生; 否则, SIRead锁会在事务结束后保留, 直到重叠事务完成.

Serializable事务隔离级别可简化开发, 其保证任何一组成功提交的并发事务都与串行执行事务的效果相同. 开发者可以确信, 事务要么正确地提交, 要么不会提交. 由于开发者很难判断哪些事务会导致读写依赖, 且需要手动回滚以防止serialization anomaly, 因此该事务隔离级别提供了一种通用方案来处理serialization failure(返回值为40001的SQLSTATE). 虽然检测依赖关系和重试事务有一定性能代价, 但相比于使用显式锁, `SELECT FOR UPDATE`, 或`SELECT FOR SHARE`, serializable在很多情况下都是最佳选择.

尽管PostgreSQL可保证多个并发事务在无依赖的前提下提交, 但无法防止串行执行事务时不会发生的异常, 例如, 事务插入一条重复主键的新行, 从而导致唯一约束冲突. 开发者需显式确认插入的键是否重复: 在事务中找到键的最大值, 将其加一, 并作为新的键值.

使用serializable事务隔离级别时, 需考虑以下问题以提升性能:
* 尽量将事务声明为**READ ONLY**
* 控制数据库连接的数量, 尽量使用连接池
* 尽量控制事务内的命令数
* 不要让事务长时间闲置, 设置**idle_in_transaction_session_timeout**参数以自动断开超时会话
* 不要使用显式锁, `SELECT FOR UPDATE`, 和`SELECT FOR SHARE`
* 当predicate lock table内存不足时, 会将多个page-level predicate lock合并为一个relation-level predicate lock, 可通过提高`max_pred_locks_per_transaction`, `max_pred_locks_per_relation, 和`max_pred_locks_per_page`来减少合并操作, 以此减少serialization failure的出现频率.
* 线性扫描需要一个relation-level predicate lock, 导致serialization failure的出现频率升高. 减少`random_page_cost`, 提高`cpu_tuple_cost`可让数据库尽量使用索引扫描. 开发者需在**减少回滚和重启次数**和**查询执行时间的整体变化**之间做出平衡.

Serializable事务隔离级别使用的技术为**Serializable Snapshot Isolation**, 其在Snapshot Isolation的基础上添加了检查serialization anomaly的功能.


## 3. Explicit Locking
PostgreSQL提供了很多种**lock mode**(锁模式)来控制数据的并发访问. 当MVCC无法给出想要的行为, 应用可显式操作这些模式. PostgreSQL中的大部分命令也会在执行时自动获得适当的锁, 以确保相关的表不会被删除或修改. 例如, 数据库不允许多个TRUNCATE命令对同一个table同时执行, 因此TRUNCATE会获得该table的ACCESS EXCLUSIVE锁. 若想列出所有未释放的锁, 可使用**pg_locks**系统视图.

### 3.1 Table-Level Locks
以下是PostgreSQL中所有可用的table-level locks:
* ACCESS SHARE: SELECT命令会获得相应table的该锁模式. 一般来说, 任何只读且不修改数据的查询都会获得该锁模式.
* ROW SHARE: `SELECT FOR UPDATE`和`SELECT FOR SHARE`命令会获得相应table的该锁模式.
* ROW EXCLUSIVE: `UPDATE`, `DELETE`, 和`INSERT`命令会获得相应table的该锁模式. 一般来说, 任何试图修改数据的命令都会获得该锁模式.
* SHARE UPDATE EXCLUSIVE: `VACUUM`, `ANALYZE`, `CREATE INDEX CONCURRENTLY`, `CREATE STATISTICS`, `COMMENT ON`, `REINDEX CONCURRENTLY`, 特殊的`ALTER INDEX`和`ALTER TABLE`命令会获得相应table的该锁模式
* SHARE: `CREATE INDEX`命令会获得相应table的该锁模式, 该模式可防止表受到并发数据更改的影响.
* SHARE ROW EXCLUSIVE: `CREATE TRIGGER`和部分`ALTER TABLE`命令会获得相应table的该锁模式, 该模式可防止表发生并发数据修改(包括自己), 因此每次仅有一个session持有该锁.
* EXCLUSIVE: `REFRESH MATERIALIZED VIEW CONCURRENTLY`命令会获得相应table的该锁模式, 该模式可与`ACCESS SHARE`锁并发, 例如, 从表中只读数据才能与持有该锁模式的事务并发执行.
* ACCESS EXCLUSIVE: `DROP TABLE`, `TRUNCATE`, `REINDEX`, `CLUSTER`, `VACUUM FULL`, 和`REFRESH MATERIALIZED VIEW`命令会获得相应table的该锁模式; `ALTER INDEX`和`ALTER TABLE`的一些模式也会获得该锁模式. 该模式确保仅持有该锁模式的事务可以访问相应table.

一旦获得锁, 锁会一直持有到事务结束; 但若锁在创建快照后获取, 那么在回滚快照时会立即释放锁, 这与ROLLBACK命令会取消快照后所有影响一致. PL/pgSQL异常块中获取的锁也是同样机制: 从异常块中抛出错误会释放块中获得的所有锁. 以下是锁模式之间的冲突关系:

| Requested Lock Mode | ACCESS SHARE | ROW SHARE | ROW EXCLUSIVE | SHARE UPDATE EXCLUSIVE | SHARE | SHARE ROW EXCLUSIVE | EXCLUSIVE | ACCESS EXCLUSIVE |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| ACCESS SHARE |  |  |  |  |  |  |  | X |
| ROW SHARE |  |  |  |  |  |  | X | X |
| ROW EXCLUSIVE	|  |  |  |  | X | X | X | X |
| SHARE UPDATE EXCLUSIVE |  |  | X |  | X | X | X | X |
| SHARE |  |  | X | X |  | X | X | X |
| SHARE ROW EXCLUSIVE |  |  | X | X | X | X | X | X |
| EXCLUSIVE |  | X | X | X | X | X | X | X |
| ACCESS EXCLUSIVE | X | X | X | X | X | X | X | X |

### 3.2 Row-Level Locks
除了table-level lock, PostgreSQL也提供row-level lock. 以下为自动申请row-level lock的语句:
* FOR UPDATE: 该锁会锁住`SELECT`匹配的行以用于更改. 该锁模式可防止行被其他事务锁住, 修改, 或删除. 若其他事务试图执行`UPDATE`, `DELETE`, `SELECT FOR UPDATE`, `SELECT FOR NO KEY UPDATE`, `SELECT FOR SHARE`, 或`SELECT FOR KEY SHARE`将会被阻塞, 直到当前事务结束; 相反的, `SELECT FOR UPDATE`会等待其他事务结束. 在REPEATABLE READ或SERIALIZABLE事务隔离级别的事务中, 若被锁定的行在事务开始后发生了变化, 则会引发错误.
`FOR UPDATE`锁模式也可被`DELETE`和`UPDATE`获取. 需要注意的是, 当前`UPDATE`考虑的情况为: 可在唯一索引, 可用于外键的列(不考虑部分索引和表达式索引).
* FOR NO KEY UPDATE: 行为与`FOR UPDATE`类似, 但排他性较低: 不会阻塞同一行上的`SELECT FOR KEY SHARE`命令, 不获取`FOR UPDATE`锁的`UPDATE`命令均获取该锁.
* FOR SHARE: 行为与`FOR NO KEY UPDATE`类似, 但为共享锁, 而不是排它锁. 该锁会阻塞同一行上的`UPDATE`, `DELETE`, `SELECT FOR UPDATE`, 和`SELECT FOR NO KEY UPDATE`命令, 但不会阻塞`SELECT FOR SHARE`和`SELECT FOR KEY SHARE`命令.
* FOR KEY SHARE: 行为与`FOR SHARE`类似, 但排他性更低: 会阻塞`SELECT FOR UPDATE`, 但不会阻塞`SELECT FOR NO KEY UPDATE`. 该锁会阻塞其他事务执行`DELETE`或更改键值的`UPDATE`操作, 但不会阻塞其他`UPDATE`操作, 也不会阻塞`SELECT FOR NO KEY UPDATE`, `SELECT FOR SHARE`, 和`SELECT FOR KEY SHARE`命令.

PostgreSQL不会在内存中记录被更改的行的信息, 所以不会限制同一时间锁定的行数; 但锁定行会导致磁盘写, 例如, `SELECT FOR UPDATE`需修改选中的行来锁定该行, 从而导致磁盘写操作. 以下是row-level lock不同锁之间的冲突关系:

| Requested Lock Mode | FOR KEY SHARE | FOR SHARE | FOR NO KEY UPDATE | FOR UPDATE |
|:---:|:---:|:---:|:---:|:---:|
| FOR KEY SHARE |  |  |  | X |
| FOR SHARE |  |  | X | X |
| FOR NO KEY UPDATE |  | X | X | X |
| FOR UPDATE | X | X | X | X |

### 3.3 Page-Level Locks
除了table-level lock和row-level lock, 还有page-level share/exclusive lock用于控制shared buffer pool中table page的读写. 这些锁会在目标行被提取或更新后立即释放. 通常情况下, 开发者无需关心page-level lock.

### 3.4 Deadlocks
显式使用锁增加deadlock(死锁)的出现概率, 表示两个或多个事务都在等待对方释放锁. 例如, 事务1已持有table A上的排它锁, 并尝试获得table B上的排它锁; 事务2已持有table B的排它锁, 并尝试获得table A上的排它锁, 两者都无法继续执行. PostgreSQL会自动检测死锁, 并中止其中一个事务, 让其他事务继续执行(很难预测哪个事务会被中止). 
需要注意的是, row-level lock也可能导致死锁. 换句话说, 即使没有显式使用锁, 也会发生死锁. 假设两个并发事务更新同一table, 事务1执行以下命令:
```sql
UPDATE accounts SET balance = balance + 100.00 WHERE acctnum = 1;
```
事务1成功获得**acctnum**为1的行上的row-level lock. 之后事务2执行以下命令:
```sql
UPDATE accounts SET balance = balance + 100.00 WHERE acctnum = 2;
UPDATE accounts SET balance = balance - 100.00 WHERE acctnum = 1;
```
上述命令中, 第一个`UPDATE`命令成功获得**acctnum**为2的行上的row-level lock; 但第二个`UPDATE`命令发现目标行已被锁定, 只能等待事务1释放锁. 现在事务1执行以下命令:
```sql
UPDATE accounts SET balance = balance - 100.00 WHERE acctnum = 22222;
```
事务1试图获得row-level lock, 但由于事务2已经持有, 因此两个事务陷入死锁. PostgreSQL会检测到该情况, 并放弃其中一个事务.
解决死锁最好的方法就是避免死锁: 确保应用程序以**一致顺序**在多个对象上获取锁. 对于上述例子, 若两个事务均使用相同顺序更新行, 则不会发生死锁. 事务还需保证第一个获取的锁是所需的最严格(最排它)的锁模式. 若无法事前验证, 可重试被死锁中止的事务.
只要没有检测到死锁, 事务会一直等待其他事务释放某个table-level lock或row-level lock. 因此, 应用程序不应持有事务太长时间.

### 3.5 Advisory Locks
PostgreSQL提供了一种可创建具有应用程序自定义含义的lock的方法, 称为**advisory lock**(咨询锁), 之所以称为咨询锁, 因为系统不会强制使用它们. 该锁可实现一些MVCC模型不易实现的锁策略. 例如, 咨询锁的一个常见用途是: 模拟"平面文件"数据管理系统的悲观锁定策略. 在table中设置一个flag也能实现相同功能, 但咨询锁更快, 避免了table过大, 且会在session结束时自动清理.
PostgreSQL中有两种获取咨询锁的方法: session级别和transaction级别. 一旦获得session级别的咨询锁, 直到session显式释放或session结束才能释放. 与其他锁请求不同的是, session级别的咨询锁不遵循事务语义: 事务期间获得锁, 即使事务回滚也仍被保留; 即使事务执行失败, 仍可解锁. 一个锁可被同一个进程获取多次, 每一个锁请求必须有对应的解锁请求. Transaction级别的锁请求在行为上更像普通的锁请求: 锁会在事务结束时自动释放, 应用无需任何解锁操作. 若只是短时间使用咨询锁, 则使用transaction级别的锁更方便. 对同一咨询锁的标识符, session级别和transaction级别的锁请求会相互阻塞. 若一个session已经持有给定的咨询锁, 即使其他session还在等待该锁, 该session仍能成功请求额外锁, 无论持有的锁或请求的锁是session级别或transaction级别, 请求相同.
与其他锁相同, 可在**pg_locks**系统视图中查看当前session持有的所有咨询锁.
咨询锁和其他锁都保存在一个共享内存池中, 内存池大小由`max_locks_per_transaction`和`max_connections`配置变量决定, 若耗尽服务器的内存, 则无法再获得任何锁. 服务器内持有的咨询锁上限数量通常从几万到几十万, 具体取决于服务器的配置方式.


## 4. Data Consistency Checks at the Application Level
Read Committed事务隔离级别很难达成事务规则的数据完整性, 因为每个语句都会改变数据视图, 一旦发生写冲突, 即使单个语句也可能无法遵循其数据快照.
虽然Repeatable Read事务隔离级别能提供一个一致的视图, 但MVCC快照提供的数据一致性检查仍存在问题, 称为**read/write conflict**(读/写冲突). 当一个事务读取数据时, 其无法看到其他并发事务修改后的结果, 假设现在有两个并发事务A和B, A只写入数据, B只读取数据, 则无论A或B哪个事务在全局时间上先执行, 都像是B先执行(因为B看不到A更改后的数据). 如果B不打算写入数据, 那么一切正常; 若B在读取后写入数据, 且存在并发事务C读取该数据, 则C应在A和B之前执行. 但C并不一定第一个提交, 完整性检查也无法正常工作.
Serializable事务隔离级别则在Repeatable Read的基础上添加了无阻塞的监控功能, 负责检测读写冲突. 当检测到冲突时, 会让其中一个事务回滚来避免冲突.

### 4.1 Enforcing Consistency with Serializable Transactions
若使用serializable事务隔离级别来处理所有写入和读取操作, 则可提供一个一致的数据, 无需额外操作来确保一致性. 若可通过一个架构来让回滚的事务自动重试, 则开发者无需确保事务是否提交成功. 开发者可将`default_transaction_isolation`设置为`serializable`, 并确保事务隔离级别始终为serializable, 例如, 在trigger中检查事务隔离级别.

### 4.2 Enforcing Consistency with Explicit Blocking Locks
当进行non-serializable写入时, 需确保写入行的有效性, 并防止其他并发事务修改该行, 因此开发者需使用`SELECT FOR UPDATE`, `SELECT FOR SHARE`或适当的`LOCK TABLE`语句(`SELECT FOR UPDATE`和`SELECT FOR SHARE`只会锁住返回的行, 以防止其他并发事务对其进行更改; `LOCK TABLE`会锁住整个表). 当移植到PostgreSQL时, 需考虑以上问题.
还需要注意的是, `SELECT FOR UPDATE`不能让其他并发事务永不更改或删除选中的行, 该命令只能暂时想要更改或删除选中行的并发事务, 一旦当前事务被回滚或提交, 被阻塞的并发事务依然可以继续更新或删除操作, 因此, 事务应在持有锁时执行`UPDATE`.
在non-serializable MVCC下, 全局有效性检查需一些额外考虑. 例如, 银行系统可能需要检查一个table中的入账总和是否等于另一个table的借机总和, 且两个table都在不断更新. 在Read Committed事务隔离级别下, 比较两个`SELECT sum(...)`的结果是不可靠的, 因为第二个query可能包含第一个query没有的事务; 在repeatable read事务隔离级别下, 单个事务所看到的是数据都是事务开始前的提交的数据, 但引发出另一个问题: query的结果是否是当前时间下的数据之和. 若repeatable read事务隔离允许在一致性检查前进行更改, 则事务看到的数据会携带一部分事务开始后的提交, 这时开发者想要一个毫无争议的一致数据, 需要`SHARE lock`来保证被锁住的table没有任何未提交的更改.
需要注意的是, 若开发者依赖于显式锁来防止并发更改, 更应该使用Read Committed事务隔离, 或在repeatable read事务隔离下, 执行query前谨慎地获取锁. Repeatable read事务隔离下的锁可保证其他事务不会更改table, 但如果先看到快照, 再获得锁, 快照中的数据可能不是最新版本. Repeatable Read事务隔离下的快照会在事务的第一个query或数据修改命令(`SELECT`, `INSERT`, `UPDATE`,`DELETE`)开始时确定下来, 因此可以在确定快照前获得锁.


## 5. Caveats
一些DDL命令(`TRUNCATE`和一些重写表的`ALTER TABLE`命令)对于MVCC是不安全的. 这意味着, 如果并发事务在DDL命令提交前确定快照, 会在DDL命令提交后看到一个空表. 该情况只发生于一种情况: 在DDL命令开始前, 事务未曾访问相关table. 任何访问了相关table的事务至少获得一个`ACCESS SHARE` table lock, 该锁会阻塞DDL命令, 直到当前事务完成. 因此, 对于单个table上的连续query, DDL命令不会造成任何不一致; 但会造成目标table和其他table之间的数据不一致.


## 6. Locking and Indexes
虽然PostgreSQL提供了一系列方法来无阻塞读取/写入table数据, 但还不支持对每个index提供无阻塞读取/写入. 以下是不同index类型的访问方式:
* B-tree, GiST and SP-GiST indexes: 使用短期共享/排它的page-level, 当index row被获取或插入后立即释放锁. 这类index提供了无死锁情况下的最高并发性.
* Hash indexes: 使用share/exclusive hash-bucket-level lock控制读写访问. 当整个bucket处理结束后释放锁. 该lock提供比index-level更好的并发性, 但可能发生死锁.
* GIN indexes: 使用短期share/exclusive page-level locks控制读写访问. 当index row被获取或插入后立即释放锁. 需要注意的是, 添加一个GIN-indexed value通常会为每一行产生多个index key的插入, 因此GIN可能为了插入一个单值做大量工作.

目前, B-tree index具有最好的并发性能. 由于B-tree index相比于hash index拥有更多特性, 因此当并发应用需要为**scalar data**(标量数据, 只包含一个单值, 而不是复合数据)添加索引时, 更推荐使用B-tree index; 但如果是non-scalar data, 则推荐使用GiST, SP-GiST, 或GIN indexes.
