---
title: SQLite Lock Management
tag:
  - Database
category:
  - Database
  - SQLite
abbrlink: 97cc
date: 2017-08-02 16:27:25
---

## 1. 锁机制的目的
SQLite为了顺序化的处理transaction而使用了锁机制, 这样能有效地管理事务请求数据库的顺序. SQLite的锁机制有一条原则: SQLite的锁是database级别的. 上锁和解锁都只针对database本身, 不针对某个row或page.


## 2. 五种锁状态
1. NOLOCK
该状态的transaction不拥有database的锁. 这种状态下该transaction不能读或写该database. 而其他transaction可在其锁状态允许的条件下读或写database. 当一个transaction刚被创建时, NOLOCK就是它的初始状态.
2. SHARED
该锁仅允许读取database. 同一时间可有多个transaction拥有某个database的shared lock, 因此会database file会被同时访问. 当database file上有shared lock时, 不允许transaction写入该file.
3. Reserved
该锁允许读取database. 这意味着transaction将会在未来写入database file. 同一时间只能有一个reserved lock在某个database上. 但该锁可以和任意数量的shared lock共存. 其他transaction可添加shared lock到该database上.
4. PENDING
该锁允许读取database. 这意味着transaction急切地想要写入database. 该锁会等待该database上的所有shared lock被清除, 并获取exclusive lock. 该锁依然可以和shared lock共存, 但不能允许其他transaction获取新的shared lock.
5. EXCLUSIVE
该锁允许写入(也可以读取)database. 只有该锁允许transaction写入database file, 并且不能和其他exclusive lock共存.


## 3. 锁机制流程
### 3.1 状态转换
通常情况下, 锁状态的转换从NO LOCK到SHARED LOCK到RESERVED LOCK到PENDING LOCK, 最后到EXCLUSIVE LOCK. 如果有journal需要回滚, 则SHARED LOCK会直接变为PENDING LOCK. 
![Locking state transition diagram](/images/SQLite/lock-management-1.png)

1. read transaction:
    1. NOLOCK到PENDING: 获取PENDING LOCK是获取SHARED LOCK的第一步. 如果有其他transaction获取PENDING LOCK, 那么会导致本transaction无法获取PENDING LOCK. 
    2. 如果成功获取PENDING LOCK, transaction会继续获取SHARED LOCK, 并释放PENDING LOCK.
2. write transaction
    1. 和read transaction一样, 获取SHARED LOCK.
    2. 获取RESERVED LOCK
    3. 为获取EXCLUSIVE LOCK, 必须先获取PENDING LOCK, 以阻止其他transaction获取SHARED LOCK.
    4. 获得PENDING LOCK后, 继续获得EXCLUSIVE LOCK. 如果成功获取EXCLUSIVE LOCK, 则进行写磁盘操作.

### 3.2 引发的问题
锁机制虽然解决了并发控制问题, 但也引入了其他问题: 两个SHRED LOCK都想获取RESERVED LOCK, 其中一个变为RESERVED LOCK后, 另外一个转为等待. RESERVED LOCK想要获取EXCLUSIVE LOCK, 但由于另一个SHARED LOCK不肯被清理, 所以就导致了两个锁陷入死锁(DEADLOCK).
对于DEADLOCK, 有两种解决方法:
* 预防
* 检测并消除

SQLite采用了第一种方法: 预防. 锁的获取是非阻塞模式, 当某个请求锁的行为失败时, 会重试一定次数. 如果全部失败, 则返回SQLITE_BUSY错误码给application. Application可以重新请求锁或放弃这个transaction. 因此, SQLite没有死锁的风险.



## 4. Linux和Windows的锁系统
SQLite通过使用原生系统的锁系统来实现自己的锁系统. 

### 4.1 Linux锁系统
以下为Linux锁系统的分类: 

* 建议锁(advisory)
    * 锁文件(lock files)
    * 记录锁(record locking)
* 强制锁(mandatory)

#### 4.1.1 建议锁
建议锁不由内核强制执行, 也就是说, 如果其他进程想往加了锁的文件访问并写入数据, 那么内核不会阻拦. 因此建议锁不能阻止进程对文件的访问, 只能依赖于各个进程访问文件之前检查文件是否加锁.
1. 锁文件
每个需要加锁的数据文件都要有一个锁文件(lock file). 当某个数据文件的锁文件存在时, 则认为该数据文件已经被加锁, 别的进程不应访问. 当锁不存在时, 则可以创建一个锁文件并访问数据文件.
2. 记录锁
记录锁克服了锁文件的缺点, 可以对文件的任何一部分加锁. 并且记录锁由内核持有, 这样拥有记录锁的进程消失时, 记录锁也会被释放. 当记录锁依然是建议性的, 有读锁(read lock)和写锁(write lock)两种. 这两种锁有以下几点特性:
    * 多个读锁可存在于一个文件的同一块区域
    * 只有一个thread能拥有某块区域的写锁
    * 读锁和写锁可存在于同一文件, 但不能是同一区域
    * 如果某一thread在某一文件区域已经加锁, 但施加了新锁, 那么之前的锁会被新锁替代
          
#### 4.1.2 强制锁
强制锁由内核执行, 当文件被上锁后, 则内核会阻止其他进程对其进行读写操作. 采用强制锁对性能影响很大, 因为每次读写操作都必须检查是否有锁存在.

### 4.2 Windows锁系统
Windows的锁都是强制锁(mandatory locks), 相关API函数:
* LockFile(): 加锁区域不能重叠, 只有Exclusive Lock.
* LockFileEx(): 可对文件加Shared Lock和Exclusive Lock. Shared Lock可与Shared Lock重叠, 但Exclusive Lock不能与任何锁重叠.
* 通过字节范围锁(byte range locks)可对文件某一部分进行读写操作.
* Windows不允许正在执行的文件被打开用来读写操作.

### 4.3 SQLite锁状态与原生系统锁系统
* SHARED LOCK通过文件上部分范围的read lock来实现
* EXCLUSIVE LOCK通过文件上所有字节的write lock来实现
* RESERVED LOCK通过文件上单个字节的write lock来实现
* PENDING LOCK通过文件上另一个位置上单个字节的write lock来实现



## 5. 锁状态具体内容
### 5.1 锁的偏移
以下为SQLite各个锁状态在代码中的体现:
![File offsets that are used to set POSIX locks](/images/SQLite/lock-management-2.png)

```c
#define PENDING_BYTE (0x40000000)
#define RESERVED_BYTE (PENDING_BYTE+1)
#define SHARED_FIRST (PENDING_BYTE+2)
#define SHARED_SIZE 510
```

* SHARED LOCK: 在SHARED_FIRST区域加read-lock(使用LockFileEx()), 即获取SHARED LOCK
* RESERVED LOCK: 在RESERVED_BYTE字节处加write-lock, 即获取REVERSED LOCK
* PENDING LOCK: 在PENDING_BYTE字节处加write-lock, 即获取PENDING LOCK
* EXCLUSIVE LOCK: 由于EXCLUSIVE LOCK不允许其他进程拥有SHARED LOCK, 所以EXCLUSIVE LOCK和SHARED LOCK使用相同的文件区域, 并添加write-lock.

### 5.2 锁的定义
```c
#define NO_LOCK         0
#define SHARED_LOCK     1
#define RESERVED_LOCK   2
#define PENDING_LOCK    3
#define EXCLUSIVE_LOCK  4
```
随着锁级别的升高, 其类型值也在变大

### 5.3 锁页(lock-type lock)
SQLite把这512字节(PENDING占1byte, REVERSED占1byte, SHARED占510bytes)作为锁页, 该页是原生系统的加锁区域, 用于实现文件的并发访问.
锁页位于1073741824字节和1073742335字节之间, 即1G的位置, 小于1G的数据库文件则没有此页. 由于SQLite并不对锁页进行读写, 而原生系统可以对不存在的文件区域进行加锁, 所以SQLite把锁页的位置定在了0X40000000, 这样可以省去512字节空间. Windows中被上锁的空间将被操作系统保留, 由于这个原因, SQLite不能把数据存在被上锁的空间中. 
以下是如何利用Linux系统锁来实现SQLite锁状态:
![Relationship between SQLite locks and Linux locks](/images/SQLite/lock-management-3.png)
