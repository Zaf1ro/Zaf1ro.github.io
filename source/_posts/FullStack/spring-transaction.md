---
title: Spring Transaction
category:
  - Full Stack
  - Spring
tag:
  - Full Stack
abbrlink: 46eb
date: 2024-05-16 08:16:20
keywords:
description:
---

## 1. Transaction
数据库系统中, 一个Transaction(事务)应具备以下四种属性:
* Atomicity (原子性): 通常一个事务会包含多个statement(声明), 该属性可确保一个事务作为一个不可分割的单元, 声明要么全部成功, 要么全部失败. 之所以需要该属性, 是因为相比于所有声明都无效, 部分声明生效会引起更大问题.
* Consistency (一致性): 该属性确保事务只会将数据库从一种consistent state转化为另一种consistent state. 换句话说, 数据库中写入的所有数据都是有效的(constraint, trigger, cascade). 该属性可防止数据因非法事务而损坏.
* Isolation (隔离性): 数据库中可能存在多个事务同时执行, 该属性保证多个并发事务的执行结果与顺序执行的结果一致. 根据**isolation level**(隔离级别)不同, 并发事务之间的透明度也会不同.
* Durability (持久性): 数据库运行期间随时会发生系统故障(断电或崩溃), 该属性可保证committed transaction(已提交的事务)永远保持提交状态. 换句话说, 已提交的事务会保存在non-volatile memory(如磁盘)中.


## 2. Isolation Levels
事务中的隔离性决定了一个正在执行的事务如何观察其他事务对数据的增删改, 通常分为四个隔离级别:
* Read Uncommitted: 一个事务的执行期间可读取到另一个事务还未提交的结果
* Read Committed: 一个事务的执行期间只能读取到另一个事务已提交的结果
* Repeatable Read: 一个事务的执行期间对同一个数据的多次读取结果始终一致, 无论其他事务是否更新该数据
* Serializable: 数据库中所有事务都按照某个顺序依次执行

可以发现, 上述隔离级别从上向下隔离性越来越强, 但并发性越来越弱, 使用何种隔离级别取决于业务需求和并发要求.


## 3. Read Phenomena
当一个事务读取另一个事务正在更新的数据时, SQL 92将其分为三种read phenomena(读取现象). 假设我们拥有一个名为`users`的table, 其中包含两行数据:
| id  | name  | age |
|:---:|:-----:|:---:|
| 1   | Alice | 20  |
| 2   | Bob   | 25  |  

### 3.1 Dirty reads (脏读)
Read uncommitted隔离级别下的事务会读取到其他事务还未提交的数据, 造成脏读.

| Transaction 1 | Transaction 2 |
|:-------------:|:-------------:|
| BEGIN; <br> SELECT age FROM users WHERE id = 1; <br> -- retrieves 20 |  |
|  | BEGIN; <br> UPDATE users SET age = 21 WHERE id = 1; |
| SELECT age FROM users WHERE id = 1; <br> -- READ UNCOMMITTED: 21 <br> -- READ COMMITTED: 20 <br> -- REPEATABLE READ: 20 <br> -- SERIALIZABLE: 20 <br> COMMIT; | |

### 3.2 Non-repeatable reads (不可重复读)
Read committed隔离级别下的事务会读取到其他事务已提交的数据, 造成对同一数据的两次查询结果不一样, 也称为**不可重复读**.

| Transaction 1 | Transaction 2 |
|:-------------:|:-------------:|
| BEGIN; <br> SELECT age FROM users WHERE id = 1; <br> -- retrieves 20 |  |
|  | BEGIN; <br> UPDATE users SET age = 21 WHERE id = 1; <br> COMMIT; |
| SELECT age FROM users WHERE id = 1; <br> -- READ UNCOMMITTED: 21<br> -- READ COMMITTED: 21<br> -- REPEATABLE READ: 20<br> -- SERIALIZABLE: 20<br> COMMIT; |  |

### 3.3 Phantom reads (幻读)
Repeatable read隔离级别可保证一个事务中对同一数据的多次查询结果一致, 但无法保证对同一范围的多次搜索结果一致, 因为其他事务可能增加或删除数据, 也称为**幻读**.

| Transaction 1 | Transaction 2 |
|:-------------:|:-------------:|
| BEGIN; <br> SELECT name FROM users WHERE age > 17; <br> -- retrieves Alice and Bob |  |
|  | BEGIN; <br> INSERT INTO users VALUES (3, 'Carol', 26); <br> COMMIT; |
| SELECT name FROM users WHERE age > 17; <br> -- READ UNCOMMITTED: Alice, Bob and Carol <br> -- READ COMMITTED: Alice, Bob and Carol <br> -- REPEATABLE READ: Alice, Bob and Carol <br> -- SERIALIZABLE: Alice and Bob <br> COMMIT; |  |


## 4. JDBC
JDBC(Java Database Connectivity)是Java编程语言的一组API, 定义了client如何连接到数据库, 以及如何对数据库中的数据进行增删改查. JDBC driver则是client端的adapter, 用于将Java程序转换为数据库可理解的协议. JDBC诞生前, 由于存在多个数据库厂商, 且每个厂商提供的数据库驱动不同, 因此开发者需要熟悉数据库的驱动; 当切换到其他数据库时, 需要重新学习驱动并修改代码. 
JDBC让开发者无需在意不同数据库的区别, 只需学习如何调用JDBC的接口. 几乎所有数据库厂商都支持JDBC, 例如: PostgreSQL, IBM DB2, MySql, Oracle Database等. 由于JDBC从JDK 1.1开始就成为Java的一部分, 因此开发者无需额外安装.


## 5. Distributed Transaction
应用程序可借助**JTA**实现distributed transaction(分布式事务), 换句话说, 一个事务内可访问和更新多个计算机资源. 以下是分布式事务模型中会出现的组件:
* The application: 应用程序
* The application server: JavaEE Web容器, 如Tomcat, Jetty
* The transaction manager: 用于协调分布式事务中的资源, 决定是否提交事务或回滚事务
* The resource adapter: 负责应用程序/应用服务器与数据库之间的通信, 如JDBC
* The resource manager: 符合管理计算机资源的系统, 如RDBMS

### 5.1 Local Transaction Model
Java application访问relational database是一种最简单的本地事务处理模型, 该模型涉及以下组件:
* Application: Java编写的业务逻辑
* Resource manager: RDBMS(relational database management system), 例如Oracle或SQL Server
* Resource adapter: application与resource manager的沟通媒介, 本例中为JDBC driver

事务处理流程:
1. 应用程序向JDBC driver请求数据
2. JDBC driver将该请求翻译为RDMBMS可接受的格式, 并通过网络向database发送请求
3. RDBMS将数据返回给JDBC driver
4. JDBC driver将数据翻译为应用程序可接受的格式

### 5.2 Distributed Transaction Model
本地事务模型中, 一个应用程序只拥有一个数据库, 因此只需要借助数据库自身的事务机制即可执行事务; 但现实中, 一个大型项目会拥有多个不同类型的数据库, 若其中一个数据库无法执行某个更新操作, 则需回滚其他数据库提交的数据, 这时需要一个coordinator来协调不同resource manager, 称为**transaction manager**. Transaction manager负责决定是否进行commit或rollback: commit会导致事务成功执行, rollback则会让数据维持不变.

### 5.3 XA Transaction
在介绍JTA之前, 必须先了解XA Protocol. XA协议是由X/Open组织提出的分布式事务处理规范, 定义了transaction manager和resource manager之间的接口. 目前主流的数据库(如Oracle, DB2和MySQL innoDB)都支持XA协议.
XA协议中定义了2PC(Two-Phase Commit Protocol, 二阶段提交协议)和3PC(Three-Phase Commit Protocol, 三阶段提交协议), 这两种算法可实现分布式系统下的事务提交.

#### 5.3.1 2PC
二阶段提交将整个事务提交分为**prepare**和**commit**两个阶段:
1. Prepare: transaction manager会向每个resource manager发送prepare请求. resource manager回复`yes`表示可完成事务; `no`表示无法完成该事务.
2. Commit: 若某个resource manager回复`no`, 则向所有resource manager发送`rollback`请求; 若所有resource manager都回复`yes`, 则向所有resource manager发送`commit`请求.

2PC存在的问题:
* 同步阻塞: prepare阶段中, 所有resource manager都必须锁定数据库, 若其他事务想要修改数据, 需等待当前事务完成.
* 单点故障: 若prepare阶段成功, 但transaction manager崩溃, 则所有resource manager都处于锁定状态, 所有事务都将无限期等待.
* 数据不一致: 若prepare阶段成功, 但transaction manager向某个resource manager发送commit请求失败, 或resource manager宕机, 会导致部分数据更新, 部分未更新, 从而造成数据不一致.

#### 5.3.2 3PC
为解决2PC的问题, 3PC进行了一些改进:
* 引入了超时机制
* 将事务处理分为三个阶段: **canCommit**, **preCommit**, **doCommit**

1. canCommit: 该阶段中, transaction manager会询问resource manager是否可以执行事务. transaction manager在本地日志写入`BEGIN_COMMIT`, 进入`WAIT`状态, 并向所有resource manager发送`VOTE_REQEUEST`消息; resource manager尝试锁定数据, 若成功则回复`VOTE_ABORT`; 失败则回复`VOTE_COMMIT`. 若所有resource manager都回复`VOTE_COMMIT`, 则进入下一阶段.
2. preCommit: 该阶段会提交事务, 并且transaction manager和resource manager都有超时机制. Transaction manager向所有resource manager发送请求:
    * 若resource manager收到请求, 会提交事务, 并根据执行结果回复`YES`或`NO`
    * 若resource manager在超时前未收到请求, 也会自动提交事务, 并返回`YES`或`NO`
    * 若transaction manager收到所有`YES`回复, 会在本地日志写入`PREPARE_COMMIT`, 并进入下一阶段
    * 若transaction manager收到`NO`回复或等待超时:
        * transaction manager在本地日志中写入`GLOBAL_ABORT`, 并进入`ABORT`状态
        * transaction manager向所有resource manager发送`GLOBAL_ABORT`消息
3. doCommit: 该阶段决定事务是否提交. transaction manager向所有resource manager发送`GLOBAL_COMMIT`消息:
    * 若resource manager收到`GLOBAL_COMMIT`消息, 会回复`ACK`
    * 若transaction manager收到所有`ACK`, transaction manager在本地日志中写入`END_TRANSACTION`, 表示完成该事务
    * 若transaction manager未收到所有`ACK`, 则会向所有resource manager发送`GLOBAL_ABORT`, 并进入`ABORT`状态

相比于2PC, 3PC解决了单点故障问题, 并减少阻塞, 因为一旦resource manager无法收到transaction manager的消息, 会自动执行commit, 而不是一直锁定数据; 但这种机制也会导致数据一致性问题: 若transaction manager发出的`GLOBAL_ABORT`请求未被resource manager及时接收到, 会导致部分resource manager回滚数据, 而部分resource manager未执行回滚.

### 5.4 JTA
JTA指定了**transaction manager**与**application, application server和resource manager**之间的Java接口, 换句话说, JTA是XA协议的Java实现. JTA提供了以下三个接口:
* UserTransaction: 该接口允许application控制事务的边界
* TransactionManager: 该接口允许application server代表application控制事务边界
* XAResource: XA接口的Java映射

需要注意的是, JTA只是一个接口, 以下是JTA的不同实现方式:
* JavaEE容器中的JTA实现, 如Tomcat, Jetty
* 开源JTA实现, 如Atomikos, Bitronix
* ORM框架, 如Hibernate


## 6. Spring Transaction
使用Spring框架来管理事务有以下优点:
* Spring提供一个跨不同transaction API的编程模型, 包括JTA, JDBC, Hibernate, JPA
* 支持declarative transaction management(声明式事务管理)
* 相比于JTA, Spring框架提供了一个更简单的programmatic transaction management(编程式事务管理)

### 6.1 TransactionManager in Spring Transaction
Spring事务抽象的关键在于transaction strategy(事务策略). 一个事务策略由`TransactionManager`定义, 尤其是命令式事务管理的`org.springframework.transaction.PlatformTransactionManager`接口和反应式事务管理的`org.springframework.transaction.ReactiveTransactionManager`接口. 以下是`PlatformTransactionManager `的定义:
```java
public interface PlatformTransactionManager extends TransactionManager {
  /**
   * Return an active transaction or create a new one according to the specified propagation behavior.
   * 
   * @param definition a TransactionDefinition instance which describes propagation behavior, isolation level, timeout etc.
   * @return a transaction status object representing the new or current transaction
   */
	TransactionStatus getTransaction(TransactionDefinition definition) throws TransactionException;

  /**
   * Commit the given transaction, with regard to its status
   * 
   * @param status object returned by the getTransaction method
   */
	void commit(TransactionStatus status) throws TransactionException;

  /**
   * Perform a rollback of the given transaction.
   * 
   * @param status object returned by the getTransaction method
   */
	void rollback(TransactionStatus status) throws TransactionException;
}
```

* `PlatformTransactionManager`: 事务的管理者, Spring事务的核心
* `TransactionDefinition`: 事务定义信息, 包括事务隔离级别, 传播行为, 超时, 只读, 回滚规则
* `TransactionStatus`: 事务本身

可以发现, Spring并不真正管理事务, 只提供了一种管理事务的接口, 开发者无需在意事务在底层如何管理, 只需按照`PlatformTransactionManager`的接口去管理事务. 使用该接口前, 必须先提供该接口的实现, 以下是`PlatformTransactionManager`的不同实现:
* `DataSourceTransactionManager`: JDBC
* `HibernateTransactionManager`: Hibernate
* `JpaTransactionManager`: JPA
* `JtaTransactionManager`: JTA, 支持分布式事务管理

### 6.2 TransactionDefinition
在讨论`TransactionDefinition`之前, 必须先了解什么是事务的传播. 例如, 方法A是一个事务方法, 当在方法A中调用方法B时, B是否应该作为事务的一部分. `TransactionDefinition`中定义了六种事务传播方式:
```java
int PROPAGATION_REQUIRED = 0;
int PROPAGATION_SUPPORTS = 1;
int PROPAGATION_MANDATORY = 2;
int PROPAGATION_REQUIRES_NEW = 3;
int PROPAGATION_NOT_SUPPORTED = 4;
int PROPAGATION_NEVER = 5;
int PROPAGATION_NESTED = 6;
```

| 事务传播类型 | 外部不存在事务 | 外部存在事务 | 适用场景 |
|:---:|:---:|:---:|:---:|
| PROPAGATION_REQUIRED | 开启一个新事务 | 加入外部事务 | 增删改 |
| PROPAGATION_REQUIRES_NEW | 开启一个新事务 | 挂起外部事务, 创建一个新事务 | 内外事务不相关 |
| PROPAGATION_SUPPORTS | 不开启新事务 | 加入外部事务 | 查询 |
| PROPAGATION_NOT_SUPPORTED | 不开启新事务 | 挂起外部事务 | 让当前函数跳出事务 |
| PROPAGATION_MANDATORY | 抛出异常 | 加入外部事务 | 保证当前函数处于某个事务之中 |
| PROPAGATION_NEVER | 不开启新事务 | 抛出异常 | 保证当前函数一定不处于某个事务之中 |
| PROPAGATION_NESTED | 开启一个新事务 | 加入外部事务 | 只适用于`DataSourceTransactionManager`和JDBC3 driver, 事务传播性质与`PROPAGATION_REQUIRED`相同, 但支持回滚到外部事务的save point |

```java
public interface TransactionDefinition {
    /**
     * Return the propagation behavior. The default is PROPAGATION_REQUIRED.
     */
    int getPropagationBehavior();
    
    /**
     * Return the isolation level. The default is ISOLATION_DEFAULT
     */
    int getIsolationLevel();

    /**
     * Return the the maximum amount of time that a transaction can run before it is
     * automatically rolled back.
     * Only for use with PROPAGATION_REQUIRED or PROPAGATION_REQUIRES_NEW.
     * The default value for the timeout property is -1.
     */
    int getTimeout();
    
    /**
     * Return whether to optimize as a read-only transaction.
     */
    boolean isReadOnly();

    /**
     * Return the name of this transaction
     */
    @Nullable
    String getName();
}
```

### 6.3 TransactionStatus
```java
public interface TransactionStatus{
  /**
   * Return true if the current transaction is a new transaction; return false if it 
   * participates in an existing transaction.
   */
  boolean isNewTransaction();

  /**
   * Return whether this transaction internally carries a savepoint, or, is this a nested
   * transaction based on a savepoint
   */
  boolean hasSavepoint();

  /**
   * Let transaction manager only rollback the current transaction, instead of throwing
   * an expcetion 
   */
  void setRollbackOnly();

  /**
   * Return whether the transaction has been marked as rollback-only
   */
  boolean isRollbackOnly();

  /**
   * Return whether this transaction has already been committed or rolled back.
   */
  boolean isCompleted;
}
```
