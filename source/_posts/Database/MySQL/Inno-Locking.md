---
title: InnoDB Locking
abbrlink: b682
date: 2022-08-15 14:53:05
tag:
  - Database
category:
  - Database
  - MySQL
keywords:
description:
---

## 1. Shared and Exclusive Locks
InnoDB中存在两种**row-level locks**(行级锁)类型:
* shared lock(简写为**S锁**): 允许持有该锁的事务读取目标行, 且允许其他事务读取目标行, 但不允许其他事务对目标行进行更改或删除
* exclusive lock(简写为**X锁**): 允许持有该锁的事务更新或删除目标行, 但不允许其他事务对目标行加锁

若事务T1对于行r持有`S锁`, 之后事务T2请求获得行r上的锁, 分为两种情况:
* T2请求`S锁`: 立即获得该锁
* T2请求`X锁`: 无法立即获得该锁

若T1持有行r的`X锁`, 无论T2请求哪一种锁, 都无法立即获得, 只能等待T1释放锁.

## 2. Intention Locks
InnoDB允许**row-level lock**与**table-level lock**在一个table中共存. 为实现不同粒度的锁, InnoDB采用了**intention lock**(意向锁), 该锁是一种table-level lock(表级锁), 表示事务**有意**获得目标表中一些行的锁(shared或exclusive). 该锁由InnoDB自行申请和维护的, 无需用户手动操作. 以下是两种intention lock类型:
* Intention shared lock(简写为**IS锁**): 表示事务有意获得目标表中一些行的**row-level shared lock**
* Intention exclusive lock(简写为**IX锁**): 表示事务有意获得目标表中一些行的**row-level exclusive lock**

Intention lock协议:
* 在事务获得表中某一行的shared lock之前, 必须先获得该表的`IS锁`或更严格的锁
* 在事务获得表中某一行的exclusive lock前, 必须先获得该表的`IX锁`

总结一下, table-level locks分为两大类, 四种锁:
* 通过`LOCK`命令获得的table-level lock:
    * `LOCK TABLES ... READ`: shared lock(S)
    * `LOCK TABLES ... WRITE`: exclusive lock(X)
* 通过`SELECT FOR SHARE/UPDATE`命令获得的intention lock:
    * `SELECT ... FOR SHARE`: Intention shared lock(IS)
    * `SELECT ... FOR UPDATE`: Intention exclusive lock(IX)

以下是各种table-level locks的兼容性:
|  | X | IX | S | IS |
|:--:|:--:|:--:|:--:|:--:|
| X | Conflict | Conflict | Conflict | Conflict
| IX | Conflict | Compatible | Conflict | Compatible
| S | Conflict | Conflict | Compatible | Compatible
| IS | Conflict | Compatible | Compatible | Compatible

可以看到, 不同类型的intention lock彼此兼容, 因此锁请求可能构成死锁, 检测到死锁时会报错; 但intention lock与table-level lock不兼容, 当发生冲突时, 事务会被阻塞, 直到互斥的锁被释放.
需要注意的是, intention lock不与row-level lock互斥. 虽然intention lock让获取row-level lock分为两步:
1. 先获得目标表的intention lock
2. 再获得目标表中目标行的row-level lock

但如果不使用intention lock, 事务试图获得table-level lock时, 需进行以下两个步骤:
1. 检查目标表是否被table-level lock锁住
2. 若目标表未锁住, 检查表中的每一行是否被row-level lock锁住

由于每次获取table-level lock都需扫描整个表, 导致效率很低, 而采用intention lock可在第一步得知该表是否存在row-level lock.

## 3. InnoDB Index
InnoDB的index以**B+Tree**形式实现, **clustered index**(聚簇索引)将**primary key**(主键)映射为表中的每一行, **secondary index**(二级索引)则将其他key映射为主键, 因此当InnoDB通过二级索引查找某一行时, 需先通过二级索引找到该行的主键, 再通过聚簇索引找到行内数据.
Index中的数据根据key值顺序保存, 更适合范围查找; 由于随时保持顺序分布, 因此index中的每个record(索引记录)都有一个**heap number**, 以此表示每个record的位置. 任何index都包含两个特殊的record:
* infimum: 比任何key都小的index, heap no为0
* supremum: 比任何key都大的index, heap no为1

## 4. Row-Level Locks
### 4.1 Record Locks
除了table-level lock, InnoDB还提供row-level lock, 分为以下三种:
* record lock: 也称为**rec-not-gap lock**, 只锁定某一行
* gap lock: 锁定两个record之间的所有记录, 但不包含左右边界本身
* next-key lock: 锁定两个两个record之间的所有记录, 且包含右边界

需要注意的是, InnoDB中所有row-level locks只会锁住索引记录, 不会锁住对应的数据. 因此, 所有row-level lock都需要挂靠在某个索引记录上, 例如:
* 若`id`列上某个索引记录(key值为1)上有一个record lock: 表示`id = 1`的行被锁定, `id`列需有唯一索引
* 若`id`列上某个索引记录(key值为1)上有一个gap lock: 表示`(?, 1)`区间被锁定, `?`表示索引值比1小且与1相邻的索引记录
* 若`id`列上某个索引记录(key值为1)上有一个next-key lock: 表示`(?, 1]`区间被锁定, `?`表示索引值比1小且与1相邻的索引记录

若表内没有任何index, InnoDB会为该表创建聚簇索引(行数作为主键), 并使用该index锁定记录.

### 4.2 Gap Locks
**Gap lock**负责锁住两个索引记录之间的所有key, 目的是解决**phantom read**(幻读)问题. 例如, `SELECT c1 FROM t WHERE c1 BETWEEN 10 and 20 FOR UPDATE`, 无论表中是否拥有`t.c1`为15的行, 该语句会阻塞其他事务插入`t.c1 = 15`, 因为`[10, 20]`区间都被锁定.
需要注意的是, 该锁类型只会在事务隔离级别为**Repeatable Read**时使用(RR要求不能出现幻读), **Read Committed**下不会使用该锁.
Gap lock可跨越单个索引值, 多个索引值, 甚至是空值. InnoDB的默认事务隔离级别为RR, 范围搜索时会自动使用gap lock; 但gap lock可能造成性能急剧下降, 有些业务会将事务隔离级别降为RC, 从而关闭gap lock.
锁定**unique index**(唯一索引, 包括主键)上的单行无需gap lock; 但若语句在查询条件中使用**multiple-column unique index**(多列唯一索引), 则仍需使用gap lock. 例如, `id`拥有唯一索引, `SELECT * FROM child WHERE id = 100`只需锁定id为100的行, 因此使用**record lock**; 若id列没有索引, 或**nonunique index**(非唯一索引), 则使用gap lock.
需要注意的是, 同一索引记录区间可被不同事务同时持有gap lock. 例如, 事务A持有一个shared gap lock, 事务B可在相同区间上持有一个exclusive gap lock. 之所以gap lock允许重叠, 因为当某个索引记录被移除时, 该记录上的gap lock需被合并. Gap lock的唯一目的是防止其他并发事务插入数据. Gap lock可以共存, 相同gap上的gap lock不会互相排斥, 也就是说, shared gap lock和exclusive gap lock没有区别, 它们不会阻塞彼此, 且功能相同.
若事务隔离级别改为RC, gap lock会自动关闭, 只用于**foreign-key constraint checking**(检查外键约束)和**duplicate-key checking**(重复键检查). 除了gap lock, 其他lock在RC下也有一些改变: 对于record lock, InnoDB不会锁住`WHERE`条件中无法在index中匹配的行; 对于`UPDATE`语句, InnoDB会将**最新提交**的数据返回给MySQL, MySQL以此确定数据是否匹配`UPDATE`的`WHERE`条件.

### 4.3 Next-Key Locks
Next-key lock是record lock和gap lock的结合, 也就是说, 该锁不仅锁定一个index record, 还锁定一个区间, 目的是解决**phantom read**(幻读)问题.
InnoDB中row-level lock的运行方式为: 当搜索一个index时, 会在对应的index record上设置shared lock或exclusive lock. 因此, row-level lock实际上是index-record lock. 若当前事务在某个index record上持有shared lock或exclusive lock, 其他事务无法在该record之前的区间插入新的index record.
假设index中包含10, 11, 13, 20四个record, next-key lock拥有以下几种可能:
```
(negative infinity, 10]
(10, 11]
(11, 13]
(13, 20]
(20, positive infinity)
```

对于最后一个区间, next-key会锁定大于最大值的区间, 其中, **positive infinity**表示高于index中任何一个值的pseudo-record(伪记录, 也就是supremum). 由于伪记录并不是一个真实的index record, 因此锁定最大的index record之后的区间.

## 5. Insert Intention Locks
Insert intention lock是一种gap lock, 执行`INSERT`命令时会先获得该锁. 当多个事务同时insert同一区间, 只要插入的位置不同, 则无需等待对方. 例如, index中存在两个record, 分别为为4和7, 两个事务尝试插入5和6, 在获得目标行的排它锁之前, 事务会用insert intention lock锁住`[4, 7]`区间, 且彼此不会相互阻塞, 因为插入的目标行不冲突.
下面例子展示了事务先获取insert intention lock, 之后获得排它锁. 该例包含两个客户端A和B, A创建一个包含两个index record(90和102)的表, 并启动一个事务来获得index record大于100的exclusive lock, 该锁包含102之前的gap lock.
```sql
mysql> CREATE TABLE child (id int(11) NOT NULL, PRIMARY KEY(id)) ENGINE=InnoDB;
mysql> INSERT INTO child (id) values (90),(102);

mysql> START TRANSACTION;
mysql> SELECT * FROM child WHERE id > 100 FOR UPDATE;
+-----+
| id  |
+-----+
| 102 |
+-----+
```

客户端B启动一个事务向gap插入一条record, 该事务会在等待exclusive lock时获得一个insert intention lock.
```sql
mysql> START TRANSACTION;
mysql> INSERT INTO child (id) VALUES (101);
```

## 6. AUTO-INC Locks
AUTO-INC lock是一种特殊的table-level lock, 只有事务插入的行带有`AUTO_INCREMENT`列时才会使用该锁. 最简单的情况下, 若事务向表中插入值, 其他事务必须等待该事务, 以保证第一个事务插入的行具有连续的键值.
`innodb_autoinc_lock_mode`配置选项可控制auto-increment locking的算法, 允许应用在**可预测的自动递增值序列**和**插入操作的最大并发性**之间进行权衡.


## 7. Predicate Locks for Spatial Indexes
InnoDB支持对包含spatial column的列进行SPATIAL indexing(空间索引). Next-key lock无法锁定涉及空间索引的操作, 因为多维数据没有绝对的排序概念, 因此无法判断键值区间.
InnoDB使用predicate lock为具有空间索引的表提供隔离级别, 空间索引包含MBR(minimum bounding rectangle, 最小边界矩形), InnoDB会对MBR值设置一个predicate lock来强制对index进行一致性读取, 其他事务不能插入或修改查询条件匹配的行.


## 8. Troubleshoot InnoDB Lock Issues
### 8.1 Preparation
查看InnoDB的锁之前, 需先确保MySQL的配置正确, 以下是一些常用命令:
* 查看事务隔离级别: `SHOW VARIABLES LIKE 'transaction_isolation';`
* 更改事务隔离级别: `SET TRANSACTION ISOLATION LEVEL ` + `SERIALIZABLE`/`REPEATABLE READ`/`READ COMMITTED`/`READ UNCOMMITTED`
* 查看自动提交: `SHOW VARIABLES LIKE 'autocommit';`
* 关闭自动提交: `SET autocommit = 0;`
* 开启InnoDB Monitor: `SET GLOBAL innodb_status_output = 1;`
* 开启InnoDB Lock Monitor: `SET GLOBAL innodb_status_output_locks = 1;`

### 8.1 Database Administration Statements
* 查看锁的整体情况: 
    ```sh
    mysql> show status like 'innodb_row_lock_%';
    +-------------------------------+--------+
    | Variable_name                 | Value  |
    +-------------------------------+--------+
    | Innodb_row_lock_current_waits | 1      |
    | Innodb_row_lock_time          | 479764 |
    | Innodb_row_lock_time_avg      | 39980  |
    | Innodb_row_lock_time_max      | 51021  |
    | Innodb_row_lock_waits         | 12     |
    +-------------------------------+--------+
    ```
    * `Innodb_row_lock_current_waits`: 当前等待锁的数量
    * `Innodb_row_lock_time`: 系统启动到现在，锁定的总时间长度
    * `Innodb_row_lock_time_avg`: 每次平均锁定的时间
    * `Innodb_row_lock_time_max`: 最长一次锁定时间
    * `Innodb_row_lock_waits`: 系统启动到现在总共锁定的次数  
* 查看所有用户的当前操作: 
    ```sh
    mysql> SHOW FULL PROCESSLIST;
    +----+-----------------+-----------+--------+---------+--------+------------------------+-----------------------+
    | Id | User            | Host      | db     | Command | Time   | State                  | Info                  |
    +----+-----------------+-----------+--------+---------+--------+------------------------+-----------------------+
    |  5 | event_scheduler | localhost | NULL   | Daemon  | 193808 | Waiting on empty queue | NULL                  |
    |  8 | root            | localhost | testdb | Sleep   |    509 |                        | NULL                  |
    | 20 | root            | localhost | testdb | Sleep   |  68025 |                        | NULL                  |
    | 22 | root            | localhost | testdb | Query   |      0 | init                   | SHOW FULL PROCESSLIST |
    +----+-----------------+-----------+--------+---------+--------+------------------------+-----------------------+
    ```
* 查看InnoDB Monitor的信息: 该命令可显示更多细节, 包括当前事务持有的锁
    ```
    mysql> SHOW ENGINE INNODB STATUS;
    ...

    ------------
    TRANSACTIONS
    ------------
    Trx id counter 2361
    Purge done for trx's n:o < 2358 undo n:o < 0 state: running but idle
    History list length 0
    LIST OF TRANSACTIONS FOR EACH SESSION:
    ---TRANSACTION 421939754615480, not started
    0 lock struct(s), heap size 1128, 0 row lock(s)
    ---TRANSACTION 421939754614688, not started
    0 lock struct(s), heap size 1128, 0 row lock(s)
    ---TRANSACTION 421939754613104, not started
    0 lock struct(s), heap size 1128, 0 row lock(s)
    ---TRANSACTION 421939754612312, not started
    0 lock struct(s), heap size 1128, 0 row lock(s)
    ---TRANSACTION 2360, ACTIVE 3 sec
    2 lock struct(s), heap size 1128, 1 row lock(s)
    MySQL thread id 8, OS thread handle 123145549533184, query id 248 localhost root
    TABLE LOCK table `testdb`.`t1` trx id 2360 lock mode IX
    RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`t1` trx id 2360 lock_mode X locks rec but not gap
    Record lock, heap no 2 PHYSICAL RECORD: n_fields 4; compact format; info bits 0
    0: len 4; hex 80000001; asc     ;;
    1: len 6; hex 00000000072f; asc      /;;
    2: len 7; hex 82000000870110; asc        ;;
    3: len 4; hex 8000000a; asc     ;;

    ...
    ```
* 查看当前所有持有的锁:
    ```sh
    mysql> SELECT * FROM performance_schema.data_locks;
    +--------+---------------------------------------+-----------------------+-----------+----------+---------------+-------------+----------------+-------------------+------------+-----------------------+-----------+---------------+-------------+-----------+
    | ENGINE | ENGINE_LOCK_ID                        | ENGINE_TRANSACTION_ID | THREAD_ID | EVENT_ID | OBJECT_SCHEMA | OBJECT_NAME | PARTITION_NAME | SUBPARTITION_NAME | INDEX_NAME | OBJECT_INSTANCE_BEGIN | LOCK_TYPE | LOCK_MODE     | LOCK_STATUS | LOCK_DATA |
    +--------+---------------------------------------+-----------------------+-----------+----------+---------------+-------------+----------------+-------------------+------------+-----------------------+-----------+---------------+-------------+-----------+
    | INNODB | 140464777903240:1063:140464966621120  |                  2360 |        49 |       91 | testdb        | t1          | NULL           | NULL              | NULL       |       140464966621120 | TABLE     | IX            | GRANTED     | NULL      |
    | INNODB | 140464777903240:2:4:2:140464967740448 |                  2360 |        49 |       91 | testdb        | t1          | NULL           | NULL              | PRIMARY    |       140464967740448 | RECORD    | X,REC_NOT_GAP | GRANTED     | 1         |
    +--------+---------------------------------------+-----------------------+-----------+----------+---------------+-------------+----------------+-------------------+------------+-----------------------+-----------+---------------+-------------+-----------+
    ```
* 查看当前所有等待的锁:
    ```sh
    mysql> SELECT * FROM performance_schema.data_lock_waits;
    +--------+---------------------------------------+----------------------------------+----------------------+---------------------+----------------------------------+---------------------------------------+--------------------------------+--------------------+-------------------+--------------------------------+
    | ENGINE | REQUESTING_ENGINE_LOCK_ID             | REQUESTING_ENGINE_TRANSACTION_ID | REQUESTING_THREAD_ID | REQUESTING_EVENT_ID | REQUESTING_OBJECT_INSTANCE_BEGIN | BLOCKING_ENGINE_LOCK_ID               | BLOCKING_ENGINE_TRANSACTION_ID | BLOCKING_THREAD_ID | BLOCKING_EVENT_ID | BLOCKING_OBJECT_INSTANCE_BEGIN |
    +--------+---------------------------------------+----------------------------------+----------------------+---------------------+----------------------------------+---------------------------------------+--------------------------------+--------------------+-------------------+--------------------------------+
    | INNODB | 140464777904032:2:4:2:140464967745056 |                             2361 |                   61 |                  31 |                  140464967745056 | 140464777903240:2:4:2:140464967740448 |                           2360 |                 49 |                91 |                140464967740448 |
    +--------+---------------------------------------+----------------------------------+----------------------+---------------------+----------------------------------+---------------------------------------+--------------------------------+--------------------+-------------------+--------------------------------+
    ```

## 9. How Locks Work
InnoDB的上锁步骤涉及数据库的很多方面, 以下是需要考虑的问题:
* 不同的SQL语句: `SELECT FOR UPDATE`, `UPDATE`, `DELETE`, `INSERT`
* 不同的Index类型: 唯一索引, 非唯一索引, 无索引
* 不同的事务隔离级别: `Read Committed`, `Repeatable Read`
* 不同的锁类型: `Table-level lock`, `Row-level lock`, `Insert intention lock`, `Auto-increment lock`

### 9.1 Rules of Locking on Row-Level Locks
其中最复杂的为`row-level lock`, 因为其涉及的命令更多, 锁类型更多, 且加锁情况更多, 因此需考虑不同语句下的不同加锁情况. Row-level lock的加锁规则包含以下几条:
* 锁的基础类型为next-key lock(前开后闭区间)
* 查找索引过程中, 能访问到的索引记录才能被上锁
* 若等值查询能找到指定的索引记录, 则next-key lock降级为record lock
* 若等值查询向右遍历时, 最后一个值不满足等值条件时, next-key lock降级为gap lock
* 唯一索引上的范围查询会一直向右遍历, 直到不满足条件

### 9.2 Status of Row-level locks
使用`SHOW ENGINE INNODB STATUS`查看事务持有/等待的锁时, 需了解InnoDB Monitor输出的内容, 以下是不同row-level locks的例子:
* Next-key lock, 最普通的row-level lock: 
    ```
    RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`t1` trx id 2359 lock_mode X
    ```
* Record lock, 写作rec-not-gap locks:
    ```
    RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`t1` trx id 2360 lock_mode X locks rec but not gap
    ```
* Gap lock, 写作gap before rec:
    ```
    RECORD LOCKS space id 2 page no 4 n bits 72 index PRIMARY of table `testdb`.`t1` trx id 2362 lock_mode X locks gap before rec
    ```

### 9.3 Locking on Different Index
假设事务隔离级别为**Repeatable Read**, 存在表`t1`, 其描述如下:
```sh
mysql> describe t1;
+-------+------+------+-----+---------+-------+
| Field | Type | Null | Key | Default | Extra |
+-------+------+------+-----+---------+-------+
| id    | int  | NO   | PRI | NULL    |       |
| col1  | int  | YES  | MUL | NULL    |       |
| col2  | int  | YES  |     | NULL    |       |
+-------+------+------+-----+---------+-------+
```
其中`id`列为主键, `col1`列拥有非唯一索引(名为`idx1`), `col2`列无索引. `t1`包含的数据如下:
```sh
mysql> select * from t1;
+----+------+------+
| id | col1 | col2 |
+----+------+------+
|  1 |   10 |  100 |
|  5 |   50 |  500 |
| 10 |  100 | 1000 |
+----+------+------+
```

#### 9.3.1 Unique Index
1. 等值查询:
    * 命中某个索引记录: next-key lock降级为record lock, 锁住`id = 1`的索引记录
      ```sh
      select * from t1 where id = 1 for update;
      +---------------+-------------+------------+-----------+---------------+-----------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE     | LOCK_DATA |
      +---------------+-------------+------------+-----------+---------------+-----------+
      | testdb        | t1          | NULL       | TABLE     | IX            | NULL      |
      | testdb        | t1          | PRIMARY    | RECORD    | X,REC_NOT_GAP | 1         |
      +---------------+-------------+------------+-----------+---------------+-----------+
        ```
    * 未命中任何索引记录: 在索引记录5处停止, 但由于`5 != 2`, 因此next-key lock降级为gap lock, 锁住`(1, 5)`区间
      ```sh
      mysql> select * from t1 where id = 2 for update;
      +---------------+-------------+------------+-----------+-----------+-----------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA |
      +---------------+-------------+------------+-----------+-----------+-----------+
      | testdb        | t1          | NULL       | TABLE     | IX        | NULL      |
      | testdb        | t1          | PRIMARY    | RECORD    | X,GAP     | 5         |
      +---------------+-------------+------------+-----------+-----------+-----------+
      ```
2. 范围查询:
    * 单区间: 在后一个索引记录上加gap lock
      ```sh
      mysql> select * from t1 where id > 5 and id < 10 for update;
      +---------------+-------------+------------+-----------+-----------+-----------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA |
      +---------------+-------------+------------+-----------+-----------+-----------+
      | testdb        | t1          | NULL       | TABLE     | IX        | NULL      |
      | testdb        | t1          | PRIMARY    | RECORD    | X,GAP     | 10        |
      +---------------+-------------+------------+-----------+-----------+-----------+
        ```
    * 多区间: 由多个next-key lock组成, 下面语句会锁住多个区间: `(1, 5]`, `(5, 10]`, 和`(10, supremum)`
      ```sh
      mysql> select * from t1 where id > 1 for update;
      +---------------+-------------+------------+-----------+-----------+------------------------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA              |
      +---------------+-------------+------------+-----------+-----------+------------------------+
      | testdb        | t1          | NULL       | TABLE     | IX        | NULL                   |
      | testdb        | t1          | PRIMARY    | RECORD    | X         | supremum pseudo-record |
      | testdb        | t1          | PRIMARY    | RECORD    | X         | 5                      |
      | testdb        | t1          | PRIMARY    | RECORD    | X         | 10                     |
      +---------------+-------------+------------+-----------+-----------+------------------------+
      ```
    * 需要注意的是, 范围搜索可能锁定额外区间:
      ```sh
      mysql> select * from t1 where id < 2 for update;
      +---------------+-------------+------------+-----------+-----------+-----------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA |
      +---------------+-------------+------------+-----------+-----------+-----------+
      | testdb        | t1          | NULL       | TABLE     | IX        | NULL      |
      | testdb        | t1          | PRIMARY    | RECORD    | X         | 1         |
      | testdb        | t1          | PRIMARY    | RECORD    | X,GAP     | 5         |
      +---------------+-------------+------------+-----------+-----------+-----------
      ```
      上述语句锁住两个区间:`(infimum, 1]`和`(1, 5]`, 下面SQL语句的含义与上述相同, 但锁定的范围更小:
      ```sh
      mysql> select * from t1 where id <= 1 for update;
      +---------------+-------------+------------+-----------+-----------+-----------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA |
      +---------------+-------------+------------+-----------+-----------+-----------+
      | testdb        | t1          | NULL       | TABLE     | IX        | NULL      |
      | testdb        | t1          | PRIMARY    | RECORD    | X         | 1         |
      +---------------+-------------+------------+-----------+-----------+-----------+
      ```
      上述语句只锁住一个区间:`(infimum, 1]`, 因为InnoDB会从第一个满足条件的索引记录开始(infimum), 一直向右遍历, 直至不符合条件(对于第一个语句, InnoDB会在索引记录5停止扫描, 由于`5 > 2`, 降级为gap lock; 对于第二个语句, 由于索引记录1满足等值查询, next-key lock不会降为gap lock, 也无需向右继续遍历).

#### 9.3.2 Non-unique Index
1. 等值查询:
    * 命中某个索引记录: 
      ```sh
      mysql> select * from t1 where col1 = 10 for update;
      +---------------+-------------+------------+-----------+---------------+-----------+
      | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE     | LOCK_DATA |
      +---------------+-------------+------------+-----------+---------------+-----------+
      | testdb        | t1          | NULL       | TABLE     | IX            | NULL      |
      | testdb        | t1          | idx1       | RECORD    | X             | 10, 1     |
      | testdb        | t1          | PRIMARY    | RECORD    | X,REC_NOT_GAP | 1         |
      | testdb        | t1          | idx1       | RECORD    | X,GAP         | 50, 5     |
      +---------------+-------------+------------+-----------+---------------+-----------+
      ```
      InnoDB锁住`primary key`(主键)和`idx1`(非唯一索引), 加锁过程分为两个步骤:
      1. 在`idx1`中查找值为`col1 = 10`的索引记录, 找到目标记录(10)和其下一个记录(50). 之所以扫描10之后的记录, 因为如果不锁住索引记录50之前的区间, 其他事务仍能插入`id > 1`且`col1 = 10`的行.
      2. 向下查找索引记录10和50对应的clustered index:
          * 以next-key lock形式锁住索引记录10下的所有clustered index记录, 也就是`$(-\infty, 1]$`
          * 以record lock形式锁住`id = 1`的主键记录
          * 以gap lock形式锁住索引记录50下的第一个clustered index记录, 也就是`(1, 5)`

      需要注意的是, 由于锁住了`col1 = 50 and id = 5`之前的区间, 任何`$col1 \in [10, 50)$`或`$col1 = 50 and id < 5$`的insert语句都会被阻塞.
    * 未命中任何索引记录: 从左向右扫描时, 由于找不到`idx1`中值为11的索引记录, 会停在50(第一个不满足条件的索引记录), 并锁住50下的第一个clustered index记录之前的区间(gap lock).
    ```sh
    mysql> select * from t1 where col1 = 11 for update;
    +---------------+-------------+------------+-----------+-----------+-----------+
    | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA |
    +---------------+-------------+------------+-----------+-----------+-----------+
    | testdb        | t1          | NULL       | TABLE     | IX        | NULL      |
    | testdb        | t1          | idx1       | RECORD    | X,GAP     | 50, 5     |
    +---------------+-------------+------------+-----------+-----------+-----------+
    ```
2. 范围查询:
    * 单区间: 在第一个不满足条件的非唯一索引记录(50)的第一个clustered index记录(5)上加gap lock
    ```sh
    mysql> select * from t1 where col1 > 10 and col1 < 50 for update;
    +---------------+-------------+------------+-----------+-----------+-----------+
    | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA |
    +---------------+-------------+------------+-----------+-----------+-----------+
    | testdb        | t1          | NULL       | TABLE     | IX        | NULL      |
    | testdb        | t1          | idx1       | RECORD    | X         | 50, 5     |
    +---------------+-------------+------------+-----------+-----------+-----------+
    ```
    * 多区间: 依旧是先扫描`idx1`, 再对每个clustered index记录添加next-key lock, 最后对符合条件的主键记录添加record lock.
    ```sh
    mysql> select * from t1 where col1 > 30 for update;
    +---------------+-------------+------------+-----------+---------------+------------------------+
    | OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE     | LOCK_DATA              |
    +---------------+-------------+------------+-----------+---------------+------------------------+
    | testdb        | t1          | NULL       | TABLE     | IX            | NULL                   |
    | testdb        | t1          | idx1       | RECORD    | X             | supremum pseudo-record |
    | testdb        | t1          | idx1       | RECORD    | X             | 50, 5                  |
    | testdb        | t1          | idx1       | RECORD    | X             | 100, 10                |
    | testdb        | t1          | PRIMARY    | RECORD    | X,REC_NOT_GAP | 5                      |
    | testdb        | t1          | PRIMARY    | RECORD    | X,REC_NOT_GAP | 10                     |
    +---------------+-------------+------------+-----------+---------------+------------------------+
    ```

#### 9.3.3 No Index
由于没有采用任何索引, 因此InnoDB会对全表的clustered index记录添加next-key lock.
```sh
select * from t1 where col2 = 100 for update;
+---------------+-------------+------------+-----------+-----------+------------------------+
| OBJECT_SCHEMA | OBJECT_NAME | INDEX_NAME | LOCK_TYPE | LOCK_MODE | LOCK_DATA              |
+---------------+-------------+------------+-----------+-----------+------------------------+
| testdb        | t1          | NULL       | TABLE     | IX        | NULL                   |
| testdb        | t1          | PRIMARY    | RECORD    | X         | supremum pseudo-record |
| testdb        | t1          | PRIMARY    | RECORD    | X         | 1                      |
| testdb        | t1          | PRIMARY    | RECORD    | X         | 5                      |
| testdb        | t1          | PRIMARY    | RECORD    | X         | 10                     |
+---------------+-------------+------------+-----------+-----------+------------------------+
```
