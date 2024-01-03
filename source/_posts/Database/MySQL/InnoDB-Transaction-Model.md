---
title: InnoDB Transaction Model
abbrlink: ed48
date: 2022-08-26 16:58:50
tag:
  - Database
category:
  - Database
  - MySQL
keywords:
description:
---

InnoDB事务模型旨在结合**multi-versioning database**(多版本数据库, 保留原始数据和最新修改的数据)和**two-phase locking**(二段锁协议, 每个事务的执行分为加锁和解锁两个阶段). 与Oracle类似, InnoDB会在行级上加锁, 并默认使用**nonlocking consistent read**(非锁定一致性读)查询数据. 通常情况下, 多个用户可锁住多个表中的多个行, 或多个行集合, 且不会造导致内存耗尽.

## 1. Transaction Isolation Levels
事务隔离是数据库的基础之一. **Isolation**是ACID中的`I`; 当多个事务同时执行查询或修改时, 不同的隔离级别会在性能, 可靠性, 一致性, 和可再现性上做出不同取舍. InnoDB提供了SQL standard中的四种事务隔离级别: 
* READ UNCOMMITTED
* READ COMMITTED
* REPEATABLE READ
* SERIALIZABLE

InnoDB的默认事务隔离级别为**REPEATABLE READ**. 用户可通过`SET TRANSACTION`语句修改隔离级别.

InnoDB中的每个事务隔离级别拥有自己的加锁策略. 对于ACID合规性较高的数据, 可使用默认的`REPEATABLE READ`; 对一致性和可再现性要求不高的场景(如批量报告), 可使用`READ COMMITTED`, 甚至是`READ UNCOMMITTED`, 来降低锁的开销. `SERIALIZABLE`比`REPEATABLE READ`更严格, 通常用于一些特殊场景, 如**XA transaction**, 以及解决并发和死锁问题.
以下是MySQL中的不同事务隔离级别, 使用频率从上往下依次降低:

### 1.1 REPEATABLE READ
InnoDB的默认隔离级别. 同一事务内的所有读取都基于第一次读取时的快照, 也就是说, 在同一事务执行多个`nonlocking SELECT`语句时, 其返回的结果一致; 对于`locking reads`(`SELECT FOR UPDATE/SHARE`), `UPDATE`, 和`DELETE`语句, 加锁方式取决于语句使用的是**unique index**(唯一索引)上的唯一搜索条件, 还是范围搜索条件:
    * 对于唯一索引上的唯一搜索条件, InnoDB只锁住单个索引记录
    * 对于其他搜索条件, InnoDB使用gap lock或next-key lock锁住扫描过的索引区间

### 1.2 READ COMMITTED
`locking read`, `UPDATE`, `DELETE`语句只会锁住索引记录, 不会锁住区间, 并允许其他事务插入区间, 导致出现**phantom row**(幻读). `Gap lock`只用于**foreign-key constraint checking**(外键约束检查)和**duplicate-key checking**(重复键检查).
只有基于行的binary logging才能使用`READ COMMITTED`, 若`binlog_format=MIXED`且使用该事务隔离级别, MySQL会自动改为row-based logging.
使用READ COMMITTED有以下影响:
* 对于`UPDATE`和`DELETE`语句, InnoDB只锁定被更新过删除的行. MySQL会释放不匹配`WHERE`条件的行上的record lock, 这可以显著降低死锁出现概率.
* 对于`UPDATE`语句, 若某一行已被锁住, InnoDB会执行`"semi-consistent read"`(半一致读): InnoDB会返回最新提交的数据给MySQL, MySQL决定哪些行匹配`WHERE`条件; 若某一行符合条件, MySQL会重读该行, 这时InnoDB会为该行上锁, 或等待该行上的锁释放.

```sql
CREATE TABLE t (
  a INT NOT NULL, 
  b INT
) ENGINE = InnoDB;
INSERT INTO t VALUES (1,2),(2,3),(3,2),(4,3),(5,2);
COMMIT;
```
以上表为例, 该表没有索引, 因此搜索和索引扫描会使用隐藏的`clustered index`(聚簇索引). 假设某个事务执行如下`UPDATE`语句:
```sql
# Session A
START TRANSACTION;
UPDATE t SET b = 5 WHERE b = 3;
```
之后第二个事务执行以下`UPDATE`语句:
```sql
# Session B
UPDATE t SET b = 4 WHERE b = 2;
```
当InnoDB执行`UPDATE`时, 会首先获得每一行的`exclusive lock`(排它锁), 并决定是否修改. 若InnoDB无需修改该行, 则释放该锁; 否则InnoDB会一直持有该锁, 直到事务结束.
使用`REPEATABLE READ`隔离级别时, 第一个`UPDATE`会获得每一行上的`x-lock`, 且不会释放任何一个锁:
```text
x-lock(1,2); retain x-lock
x-lock(2,3); update(2,3) to (2,5); retain x-lock
x-lock(3,2); retain x-lock
x-lock(4,3); update(4,3) to (4,5); retain x-lock
x-lock(5,2); retain x-lock
```
第二个`UPDATE`也会尝试获得每一行上的`x-lock`, 但由于第一个`UPDATE`已持有锁, 因此只能等待第一个`UPDATE`提交或回滚.
```text
x-lock(1,2); block and wait for first UPDATE to commit or roll back
```
使用`READ COMMITTED`时, 第一个`UPDATE`会先获得每一行上的`x-lock`, 并释放无需修改的行:
```text
x-lock(1,2); unlock(1,2)
x-lock(2,3); update(2,3) to (2,5); retain x-lock
x-lock(3,2); unlock(3,2)
x-lock(4,3); update(4,3) to (4,5); retain x-lock
x-lock(5,2); unlock(5,2)
```
对于第二个`UPDATE`, InnoDB执行`半一致读`, 向MySQL返回最新提交的行, MySQL负责判断哪些行符合`WHERE`条件:
```text
x-lock(1,2); update(1,2) to (1,4); retain x-lock
x-lock(2,3); unlock(2,3)
x-lock(3,2); update(3,2) to (3,4); retain x-lock
x-lock(4,3); unlock(4,3)
x-lock(5,2); update(5,2) to (5,4); retain x-lock
```

若`WHERE`条件中包含索引列, 且InnoDB使用该索引, 则只会在索引列上加锁. 以下面的表为例, 第一个`UPDATE`获得`b = 2`上的`x-lock`, 第二个`UPDATE`会被阻塞, 因此其也用到`b`列上的索引.
```sql
CREATE TABLE t (a INT NOT NULL, b INT, c INT, INDEX (b)) ENGINE = InnoDB;
INSERT INTO t VALUES (1,2,3),(2,2,4);
COMMIT;

# Session A
START TRANSACTION;
UPDATE t SET b = 3 WHERE b = 2 AND c = 3;

# Session B
UPDATE t SET b = 4 WHERE b = 2 AND c = 4;
```

### 1.3 READ UNCOMMITTED
`SELECT`语句会以非阻塞方式执行, 但可能使用旧的行数据, 因此该事务隔离级别下, 读取是不一致性, 也称为**dirty read**(脏读).

### 1.4 SERIALIZABLE
该隔离级别与`REPEATABLE READ`相似, 但若`autocommit`被关闭, InnoDB会将所有`SELECT`语句转换为`SELECT FOR SHARE`. 若开启`autocommit`, `SELECT`会成为单个事务, 该事务是只读的, 若以`nonlocking read`执行, 且无需阻塞其他事务, 则该事务可序列化.


## 2. Autocommit, Commit, and Rollback
InnoDB中所有用户行为都被包含在**transaction**(事务)中. 若已开启`autocommit`, 每个SQL语句都成为一个事务. MySQL默认会为每个连接开启`autocommit`, 因此MySQL会在每个SQL语句后自动提交; 若SQL语句返回错误, 则根据错误类型选择提交或回滚.
开启`autocommit`后, 可使用`START TRANSACTION`或`BEGIN`语句开启一个**multiple-statement transaction**(多语句事务), 并以`COMMIT`或`ROLLBACK`语句结束.
若想关闭`autocommit`, 可执行`SET autocommit = 0`, session会自动开启一个事务, 直到遇到`COMMIT`或`ROLLBACK`才开启下一个事务.
若session关闭了`autocommit`且没有提交事务, MySQL会回滚该次事务.
即使没有执行`COMMIT`或`ROLLBACK`, 某些语句会导致事务结束, 例如: DDL语句(`ALTER EVENT`, `ALTER FUNCTION`, `ALTER PROCEDURE`, `ALTER SERVER`等), 修改table的语句(`ALTER USER`, `CREATE USER`, `DROP USER`等), 事务控制或锁语句(`BEGIN`, `LOCK TABLES`等), 管理语句(`ANALYZE TABLE`, `CACHE INDEX`, `CHECK TABLE`, `FLUSH`等), 控制replication的语句(`START REPLICA`, `STOP REPLICA`, `RESET REPLICA`等).
`COMMIT`意味着, 当前事务中的所有修改都会呈现给其他session. `ROLLBACK`则表示当前事务中的任何修改都会被撤回. `COMMIT`和`ROLLBACK`都会释放当前事务持有的所有锁.

### 2.1 Grouping DML Operations with Transactions
默认情况下, MySQL服务器会开启新的连接的`autocommit`, 换句话说, 每个SQL语句都会自动提交. 这种行为模式可能和其他数据库不同, 因为其他数据库的通常做法为: 发出一系列DML语句, 并一起提交或回滚.
若使用多语句事务, 可关闭`autocommit`, 并以`COMMIT`或`ROLLBACK`结束每个事务; 若不想关闭`autocommit`, 需以`START TRANSACTION`开始一个事务, 并以`COMMIT`或`ROLLBACK`结束每个事务. 以下是两个事务, 第一个事务提交, 第二个事务回滚:
```sql
mysql> CREATE TABLE customer (a INT, b CHAR (20), INDEX (a));
Query OK, 0 rows affected (0.00 sec)
mysql> -- Do a transaction with autocommit turned on.
mysql> START TRANSACTION;
Query OK, 0 rows affected (0.00 sec)
mysql> INSERT INTO customer VALUES (10, 'Heikki');
Query OK, 1 row affected (0.00 sec)
mysql> COMMIT;
Query OK, 0 rows affected (0.00 sec)
mysql> -- Do another transaction with autocommit turned off.
mysql> SET autocommit=0;
Query OK, 0 rows affected (0.00 sec)
mysql> INSERT INTO customer VALUES (15, 'John');
Query OK, 1 row affected (0.00 sec)
mysql> INSERT INTO customer VALUES (20, 'Paul');
Query OK, 1 row affected (0.00 sec)
mysql> DELETE FROM customer WHERE b = 'Heikki';
Query OK, 1 row affected (0.00 sec)
mysql> -- Now we undo those last 2 inserts and the delete.
mysql> ROLLBACK;
Query OK, 0 rows affected (0.00 sec)
mysql> SELECT * FROM customer;
+------+--------+
| a    | b      |
+------+--------+
|   10 | Heikki |
+------+--------+
1 row in set (0.00 sec)
```

### 2.2 Transactions in Client-Side Languages
在PHP, Perl DBI, JDBC, ODBC, 或MySQL的标准C调用接口中, 可向MySQL server发送**transaction control statement**(事务控制语句, 如`COMMIT`), 就像发送其他SQL语句一样. 


## 3. Consistent Nonlocking Reads
**Consistent read**意味着: InnoDB使用**multi-versioning**(多版本控制)向每一个query展示数据库在某个时间点的快照. Query只能看到该时间点之前已提交的更改, 不能看到该时间点之后的提交, 或之前尚未提交的更改, 唯一的例外是当前事务中该query之前的更改. 该例外导致了一些异常现象: 当更新表中某些行时, `SELECT`可能看到更新后的最新数据, 也可能看到旧数据. 若其他session同时更新该表, 当前session观察到的表状态可能从未存在于数据库中.
`REPEATABLE READ`事务隔离级别下, 同一事务中的每个**consistent read**都会从事务开始时创建的快照中读取; 若想获得更新版本的数据, 可提交当前事务, 并发起另一个query.
`READ COMMITTED`事务隔离级别下, 同一事务中的每个**consistent read**都读取最新版本的快照.
InnoDB中, `READ COMMITTED`和`REPEATABLE READ`事务隔离级别下的`SELECT`语句默认使用**consistent read**, 不会设置任何锁, 因此其他session可以并发修改该表.
在`REPEATABLE READ`事务隔离级别下, 执行**consistent read**(`SELECT`语句)时, InnoDB会为该事务提供一个时间点, query根据该时间点查看数据库. 若其他事务在该时间点后删除某一行并提交, 当前事务无法看到该行被删除, insert和update的处理方式类似.
若想提前时间点, 可提交当前事务, 并执行`SELECT`或`START TRANSACTION WITH CONSISTENT SNAPSHOT`. 上述技术称为**multi-versioned concurrency control**(多版本并发控制).
以下例子中, 只有session A和B都提交后, A才能看到B插入的行, 说明A的快照时间点早于B提交修改:
```text
          Session A              Session B
 |
 |      SET autocommit=0;     SET autocommit=0;
 |
 |      SELECT * FROM t;
time    empty set
 |                              
 |                            INSERT INTO t VALUES (1, 2);
 |                               
 |      SELECT * FROM t;
 v      empty set

                              COMMIT;

        SELECT * FROM t;
        empty set

        COMMIT;

        SELECT * FROM t;
        ---------------------
        |    1    |    2    |
        ---------------------
```
若想看到最新版本的数据库状态, 可切换为`READ COMMITTED`隔离级别, 或使用**locking read**: `SELECT * FROM t FOR SHARE;`
`READ COMMITTED`隔离级别下, 同一事务中的每个**consistent read**都会读取到最新快照. 使用`FOR SHARE`会给`SELECT`选中的行上锁, 阻塞其他事务修改或删除, 直到当前事务结束.
**Consistent read**无法作用于DDL语句:
* 由于MySQL无法使用一个被dropped的表, 因此`DROP TABLE`无法使用**consistent read**
* `ALTER TABLE`会复制一个临时表, 并在完成复制后删除原表, 同一事务中再次执行**consistent read**时, 新表中的行不可见, 事务返回`ER_TABLE_DEF_CHANGED`, 表示表定义已更改, 需重试事务

对于不携带`FOR UPDATE`或`FOR SHARE`的`SELECT`子句, 例如`INSERT INTO ... SELECT`, `UPDATE ... (SELECT)`, 和`CREATE TABLE ... SELECT`, 它们使用不同类型的读取方式:
* 默认情况下, `SELECT`子句会锁住扫描过的索引
* 若不想上锁, 可降级为`READ UNCOMMITTED`或`READ COMMITTED`


## 4. Locking Reads
在同一事务中查询, 并插入或更新相关数据时, 普通的`SELECT`语句无法给予相应的保护, 因为其他事务也可以更新或删除目标行. InnoDB提供两种**locking reads**
* `SELECT ... FOR SHARE`: 在所读行上设置一个**shared mode lock**. 其他事务可以读取, 但不能修改; 若目标行被修改, 但还未提交, 则当前事务需等待对方结束, 并读取最新值.
* `SELECT ... FOR UPDATE`: 锁住扫描过的索引记录, 就像执行`UPDATE`语句一样. 其他事务无法更新目标行, 无法执行`SELECT ... FOR SHARE`, 也无法在某些事务隔离级别下读取数据. **Consistent read**会忽略**read view**上的任何锁(旧版本的记录无法被锁定).

`FOR SHARE`和`FOR UPDATE`获得的锁会在事务提交或回滚后被释放.
外部语句中的**locking read**不会锁定嵌套子查询中的行, 除非子查询也使用**locking read**:
```sql
SELECT * FROM t1 WHERE c1 = (SELECT c1 FROM t2) FOR UPDATE;
```
若想锁住`t2`表中的行, 可在子查询中添加`locking read`:
```sql
SELECT * FROM t1 WHERE c1 = (SELECT c1 FROM t2 FOR UPDATE) FOR UPDATE;
```

### 4.1 Locking Read Examples
假设当前事务想向`child`表中插入一个新行, `child`中的每一行都对应`parent`表中的一行. 应用程序代码需确保引用的完整性.
首先, 使用**consistent read**查询`parent`来确保目标行存在. 但不能安全地将目标行插入到`child`中, 因为其他事务仍可在`SELECT`和`INSERT`之间删除目标行. 为避免潜在风险, 需使用`SELECT ... FOR SHARE`:
```sql
SELECT * FROM parent WHERE NAME = 'Jones' FOR SHARE;
```
执行上述查询后, 事务可安全地插入`child`表并提交, 任何想要获得`parent`表中目标行上的**exclusive lock**的事务都需等待当前事务完成.
再举个例子, 假设`CHILD_CODES`表中有一个**integer counter**(整数计数)列, 该列作为唯一标识符, 用于标识`CHILD`表中的每个child. 由于两个事务会看到某个counter的相同值, 且添加同一标识符到`CHILD`表中会引发**duplicate-key error**(重复键错误), 因此无需使用**consistent read**或**shared mode read**.
若使用`FOR SHARE`, 由于两个事务同时访问counter时, 至少一个事务会在更新counter时会因死锁而终止.
为实现读取并增加counter, 需使用`FOR UPDATE`锁住读取的行, 并增加counter:
```sql
SELECT counter_field FROM child_codes FOR UPDATE;
UPDATE child_codes SET counter_field = counter_field + 1;
```

`SELECT ... FOR UPDATE`读取最新版本的数据, 在读取的行上设置**exclusive lock**, 与`UPDATE`设置的锁相同.
上述只是`SELECT ... FOR UPDATE`如何工作的一个例子. 在MySQL中, 生成唯一标识符可通过一次访问来完成:
```sql
UPDATE child_codes SET counter_field = LAST_INSERT_ID(counter_field + 1);
SELECT LAST_INSERT_ID();
```
`SELECT`语句仅访问标识符信息, 不访问任何表.

### 4.2 Locking Read Concurrency with NOWAIT and SKIP LOCKED
若某一行被事务锁住, 执行`SELECT ... FOR UPDATE`或`SELECT ... FOR SHARE`的事务需等待当前事务释放锁. 然而, 如果事务想要立即返回, 等待行锁就没有必要.
为避免其他事务等待释放锁, 可使用`NOWAIT`和`SKIP LOCKED`选项:
* NOWAIT: 使用`NOWAIT`的**locking read**不会等待锁释放, 而是直接返回错误.
* SKIP LOCKED: 使用`SKIP LOCKED`的**locking read**不会等待锁释放, 而是将被锁的行从结果中移除.

`NOWAIT`和`SKIP LOCKED`只用于row-level lock. 若语句基于replication, 则`NOWAIT`或`SKIP LOCKED`会变得不安全.
假设存在两个session: session 1开启一个事务, 获得了一个记录上的行锁; session 2尝试对相同记录进行**locking read**, 并带有`NOWAIT`选项. 由于目标行已被session 1锁住, 因此立即返回错误; session 3尝试对相同记录进行**locking read**, 并带有`SKIP LOCKED`选项, 返回除session 1锁定之外的行.
```sql
# Session 1:
mysql> CREATE TABLE t (i INT, PRIMARY KEY (i)) ENGINE = InnoDB;
mysql> INSERT INTO t (i) VALUES(1),(2),(3);
mysql> START TRANSACTION;
mysql> SELECT * FROM t WHERE i = 2 FOR UPDATE;
+---+
| i |
+---+
| 2 |
+---+

# Session 2:
mysql> START TRANSACTION;
mysql> SELECT * FROM t WHERE i = 2 FOR UPDATE NOWAIT;
ERROR 3572 (HY000): Do not wait for lock.

# Session 3:
mysql> START TRANSACTION;
mysql> SELECT * FROM t FOR UPDATE SKIP LOCKED;
+---+
| i |
+---+
| 1 |
| 3 |
+---+
```
