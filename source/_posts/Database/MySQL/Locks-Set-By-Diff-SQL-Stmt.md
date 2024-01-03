---
title: InnoDB Locks Set by Different SQL Statements
tag:
  - Database
category:
  - Database
  - MySQL
abbrlink: efcc
date: 2022-08-31 14:19:24
keywords:
description:
---

处理SQL语句时, `Locking Read`, `UPDATE`, 和`DELETE`会在扫描过的索引记录上加record lock. InnoDB不会记住`WHERE`条件, 只知道扫描了哪一部分索引. Lock通常指代**next-key lock**, 其会锁住一个索引记录和其之前的间隙.
若使用**secondary index**(二级索引)搜索, 且索引记录的锁为**exclusive**, InnoDB会锁住**clustered index**上对应的索引记录.
若未能找到匹配SQL语句的索引, MySQL必须扫描整个表, 并锁住表中的每一行, 导致其他用户无法写入任何数据, 因此最好为query创建合适的索引.
InnoDB的锁类型如下:

* `SELECT ... FROM`
该语句为**consistent read**, 从数据库快照中读取, 且只要不为`SERIALIZABLE`隔离级别, 就不会加任何锁. 若事务隔离级别为`SERIALIZABLE`, 则在索引记录上加`shared next-key lock`; 若使用**unique index**(唯一索引)搜索某一行, 则在对应的索引记录上加`record lock`.

* `SELECT ... FOR UPDATE`, `SELECT ... FOR SHARE`
上述语句使用唯一索引时, 会锁住扫描过的行, 并释放不匹配`WHERE`条件的行上的锁. 然而在某些情况下, 由于`结果行`与`原始数据源`之间的关系丢失, 不会立即释放锁, 例如在`UNION`中, 在判断被扫描的行是否符合条件之前, 这些行被插入到一个临时表. 此时, 临时表中的行与原始表中的行不存在任何关系, 原始表中的行直到查询结束之前都不会释放锁.

* Locking Read(`SELECT FOR UPDATE`, `SELECT FOR SHARE`, `UPDATE`, `DELETE`)
上述语句的加锁规则分为两种情况:
  * 具有唯一搜索条件的唯一索引: InnoDB使用`record lock`锁住目标行对应的索引记录
  * 范围搜索, 或非唯一索引: InnoDB使用`gap lock`或`next-key lock`锁住扫描的索引记录, 以防止其他事务插入到间隙中

* 对于扫描到的索引记录, `SELECT ... FOR UPDATE`会阻止其他事务执行`SELECT ... FOR SHARE`, 并阻止其他事务在特定事务隔离级别下读取. 

* `UPDATE ... WHERE ...`
该语句在扫描过的每个索引记录上添加`exclusive next-key lock`; 若使用唯一索引搜索到唯一一行, 则降级为`record lock`.

* 当`UPDATE`修改`clustered index`上的索引记录时, 会锁住受影响的**secondary index**(二级索引)上的记录. `UPDATE`还会在两种情况下在**secondary index**的记录上加`shared lock`:
  * 插入新的`secondary index`记录
  * 插入新的`secondary index`记录前, 执行`duplicate check scan`(重复检查扫描)

* `DELETE FROM ... WHERE ...`
该语句在每个扫描过的索引记录上添加`exclusive next-key lock`; 若使用唯一索引搜索到唯一一行, 则降级为`record lock`

* `INSERT`在被插入的行上添加`exclusive lock`. 该锁为`record lock`, 而不是`next-key lock`, 不会阻止其他事务插入到目标行的前后间隙

在插入行之前, 需先获得一种`gap lock`, 称为`insert intention gap lock`. 该锁表示当前事务**有意**插入, 若其他事务插入到同一间隙的不同位置, 则无需等待当前事务: 假设InnoDB中有两个索引记录, 值分别为4和7, 两个事务分别插入5和6, 在获得插入行的`exclusive lock`前, 两个事务会使用`insert intention lock`锁住`(4,7)`间隙, 且不会互相阻塞, 因为插入值不同.

若发生`duplicate-key error`(冲突键错误), 则会在重复的索引记录上添加`shared lock`. 若多个事务尝试插入同一行, 而该行已存在, 且其他事务持有该行的`exclusive lock`, 则`shared lock`会导致死锁; 若其他事务删除该行, 也会发生这种情况. 假设InnoDB中`table t1`的结构如下:
```sql
CREATE TABLE t1 (i INT, PRIMARY KEY (i)) ENGINE = InnoDB;
```

假设三个事务按从上向下的顺序执行:
1. 事务1:
  ```sql
  START TRANSACTION;
  INSERT INTO t1 VALUES(1);
  ```
2. 事务2:
  ```sql
  START TRANSACTION;
  INSERT INTO t1 VALUES(1);
  ```
3. 事务3:
  ```sql
  START TRANSACTION;
  INSERT INTO t1 VALUES(1);
  ```
4. 事务1:
  ```sql
  ROLLBACK;
  ```

事务1获得该行的`exclusive lock`, 事务2和3的插入操作导致重复键错误, 并获得该行的`shared key`; 当事务1回滚时会释放`exclusive lock`, 此时事务2和3都试图将自己的`shared lock`升级为`exclusive lock`, 并导致死锁: 事务2和事务3都不愿放弃自己的`shared lock`, 因此两者都无法获得`exclusive lock`.
若表中包含键值为1的行, 且三个事务按照以下顺序执行, 也会出现类似情况:
1. Session 1:
  ```sql
  START TRANSACTION;
  DELETE FROM t1 WHERE i = 1;
  ```
2. Session 2:
  ```sql
  START TRANSACTION;
  INSERT INTO t1 VALUES(1);
  ```
3. Session 3:
  ```sql
  START TRANSACTION;
  INSERT INTO t1 VALUES(1);
  ```
4. Session 1:
  ```sql
  COMMIT;
  ```

第一个事务获得目标行的`exclusive lock`, 事务2和3的操作导致重复键错误, 并获得目标行的`shared lock`. 当事务1提交时, 其释放拥有的`exclusive lock`, 并导致死锁: 由于事务2和3都不愿释放自己的`shared lock`, 因此无法获得`exclusive lock`.

* `INSERT ... ON DUPLICATE KEY UPDATE`
该语句与`INSERT`不同, 当发生重复键错误时, 该语句会获得目标行的`exclusive lock`, 而不是`shared lock`. 不同键值类型会导致不同的锁类型:
  * 主键重复: `exclusive record lock`
  * 唯一键重复: `exclusive next-key lock`

* `REPLACE`
当没有唯一键冲突时, 该语句与`INSERT`上锁行为相同; 当发生冲突时, 会在目标行上放置`exclusive next-key lock`

* `INSERT INTO T SELECT ... FROM S WHERE ...`
该语句会在所有插入行上设置`exclusive record lock`, 若事务隔离级别为`READ COMMITTED`, 则InnoDB执行`consistent read`(不设置任何锁); 否则, InnoDB会在扫描过的行上设置`shared next-key lock`. 使用基于statement的二进制日志进行回滚恢复时, 每条SQL语句都必须按照与最初完全相同的方式执行, 因此必须设置锁.

* `CREATE TABLE ... SELECT ...`
分为两种上锁情况:
  * `REPEATABLE READ`隔离级别: `SELECT`会给扫描过的索引记录设置`shared next-key lock`
  * `READ COMMITTED`隔离级别: 与`consistent read`相同, 不会设置任何锁

*  `REPLACE INTO t SELECT ... FROM s WHERE ...`, `UPDATE t ... WHERE col IN (SELECT ... FROM s ...)`
`SELECT`子句会在扫描过的索引记录上设置`shared next-key lock`

* 若table中有`FOREIGN KEY`约束, 任何需要检查约束条件的`insert`, `update`, `delete`都需要设置`shared record lock`. 

* `LOCK TABLES`会设置`table lock`. 但这些锁由MySQL设置, 而不是InnoDB. 若`innodb_table_locks = 1`且`autocommit = 0`, 则InnoDB可知道`table-level lock`, MySQL也可以知道`row-level lock`; 否则InnoDB无法检测到`table lock`相关的死锁. 并且, 由于MySQL不知道`row-level lock`, 有可能在其他事务已设置`row-level lock`的情况下, 为当前事务设置`table-level lock`

* `LOCK TABLES`会在`innodb_table_locks = 1`时为每个table设置两个锁(IS和IX). 若不想设置`table lock`, 可改为`innodb_table_locks = 0`. MySQL 8.0后, 若执行`LOCK TABLES ... WRITE`, 即使`innodb_table_locks = 0`, 仍会为目标表上锁, `LOCK TABLES ... READ`同理.

* 所有InnoDB lock都会在事务提交或中止时释放, 因此, 若`autocommit = 1`(已开启自动提交), 则无需任何`LOCK TABLES`, 因此每条语句都是一个单独事务, 语句执行完毕后立即释放锁.

* 若`autocommit = 1`, 则不应在事务中使用`LOCK TABLES`, 因为`LOCK TABLES`会自动提交当前事务, 并开启新的事务