---
title: 数据库实现(1)
category:
  - Database
tag:
  - Database
abbrlink: 3122817517
date: 2017-11-24 12:25:58
---

#### 1. memory层次
1. 易丢失
    * cache
    * 内存
2. 不易丢失
    * secondary storage
        * virtual memory
        * disk
            * disk中以3-64kb为一个disk block, 通常包含一或多个sector
            * 内存中的disk block叫做一个buffer
        * file system
    * tertiary storage

#### 2. disk
* disk assembly
    * circular platter: covered with magntic material, 有两个surface
        * track: 除了接近中心的位置, track几乎占满了整个circular platter
            * sector: 将一个track分为好几个区域, 每个sector用gap分隔, 是最小的读写单元
            * gap: 占整个track的10%, 用于分隔sector并标记sector的起点
* head assembly
    * 每个surface都有一个disk head
    * disk head只会贴着surface运行, 不会碰到surface, 否则导致head crash

#### 3. disk controller的功能
* 控制head assembly, 将某个disk head移动到某个角度(圆周方向)
* 将head移动到某个sector(半径方向)
* 从sector中读取字节并传给主存
* 存储某个track上的数据, 以避免移动head

#### 4. dish的延迟(latency)
一共分为三个部分(大约10ms):
* seek time: disk controller将head assembly中某个head移动到指定track的所需时间(10ms能穿过所有track)
* rotational latency: disk controller将head移动到block的第一个sector的所需时间(大约5ms移动到指定sector)
* transfer time: disk controller读取或写入这些sector的所需时间(大约小于1ms)

#### 5. secondary storage的访问加速
由于访问secondary storage的平均时间为10ms, 当访问频率小于10ms, scheduling latency(调度延迟)将变为无限大. 所以有以下几种方法来减小延迟:
* 将被连续访问的block放在同一个track中, 可避免seek time
* 将大数据切割成多个小时据并放在不同的surface中, 这样可以发挥每个surface都有一个disk head的优势, 并发读写
* 将某些数据copy到其他disk, 原理与上一条相同, 还可以防止disk损坏导致的数据丢失
* 使用disk-scheduling algorithm(硬盘调度算法), 通过重新排序访问顺序来减少seek time和ratational time
* 提前将block载入内存(prefetch)

#### 6. disk failure
几种硬盘故障如下:
1. intermittent failure(间歇性失败): 第一次失败, 多读写几次可成功
2. media decay(媒介损坏): 一个或多个bit不能读取, 造成整个sector无法使用
3. write failure(写入失败): 无法写入某个sector或无法读取该sector之前写入的数据, 一种可能的原因是供电中断导致的写入失败
4. disk crash(磁盘崩溃): 整块disk都不能正常读写

#### 7. disk failure的解决方案
1. intermittent failure: 由于sector上的数据不会传给disk controller, 所以contoller无法确定数据是否为错. 如果controller有方法判断sector是够有错, 则可以重新访问sector, 直到获得了正确数据. 如果读取失败, 则默认写入也失败.
2. checksums: 每个sector后会有几个bit用来保证数据的正确性, 虽然有一定可能性导致错误的数据被漏查, 但这种可能性十分低. 最简单的检测方法是基于局部奇偶个1的检查, 位数越高(每一位针对一个字节), 漏查的可能性越低
3. 虽然checksums可以检查出media failure或读写错误, 但不能用于数据恢复, 一旦写入的数据错误, 则原来正确的数据也消失. Stable storage可用于恢复数据. 由于sector是对称的, 所以可通过对称sector实现数据恢复. 假设sector分为X<sub>L</sub>和X<sub>R</sub>操作如下:
    1. 先将新值赋予X<sub>L</sub>, 如果写入错误(通过checksums判断正确与否)则用X<sub>R</sub>恢复数据
    2. 如果X<sub>L</sub>写入正确, 则按步骤1将新值写入X<sub>R</sub>

#### 8. disk crash的恢复
如果数据没有存在其他媒介中, 那么disk crash后无法恢复数据. 所以通常的策略是RAID(Redundant Arrays of Independent, 独立磁盘构成的具有冗余能力的阵列). 一般mean time of failure(平均失效时间)之后50%的disk会crash. 现在disk的平均失效时间为10年.
最简单的策略就是为每个disk做拷贝, 其中一个disk成为data disk, 其他的成为redundant disk. Mirroring(镜像)通常称为RAID level 1, 镜像使得平均失效时间变长, 因为两个disk一起损坏的概率十分低

#### 9. 奇偶校验(parity bits)
除了使用与data disk同样多数量的redundant disk之外, 也可以使用一块冗余块来实现RAID level 4. Redundant disk的每一位都用来表示多个data disk的checksums, 例如:
* 假设有三个data disk: 1111 0000, 1010 1010, 0011 1000
* 可用一个Redundant disk来表示一个奇偶块: 0110 0010
读取时不需要访问Redundant disk, 只有写入时才能用到. 但写入一个块时, 不仅需要修改data disk, 还需要修改redundant disk中的对应块. 当某个data disk发生故障时, 可通过其他data disk和redundant di sk来推断出损坏块的数据(模2求和). 除非两个磁盘同时损坏, 一般能保证data disk的故障恢复

#### 10. 多个disk崩溃的处理
针对多个disk的崩溃, 可使用最高RAID级别(RAID level 6), 例如:
1. 有四个disk, disk内容分别为111, 110, 101, 011
2. Redundant disk有三块
    * 第一块为1,2,3disk的parity bits(100)
    * 第二块为1,2,4disk的parity bits(010)
    * 第三块为1,3,4disk的parity bits(001)
如果第一块和第二块disk损坏, 则第一块disk可通过第三块Redundant disk恢复数据; 第二块disk通过第一块Redundant disk恢复

#### 11. 定长的record
定长的record头部都会有一个header(一块定长的区域):
* 指向schema的指针: 可以根据该指针找到record的fields
* record的长度: 用于跳过header
* Timestamps: 标明record最近一次被修改或读取的时间
* 指向field的指针: 可替代schema信息
定长的record在block中依次放置, 每个block头部都会有一个block header(块头部):
* 指向一个或多个block, 通常这些block可以组成一个network
* block在该network中的角色信息
* block里的tuple属于哪个relation
* 每个record在block中的偏移量
* 最后一次修改或访问的timestamps

#### 12. database address space
block和record一般存在database address space, 也就是secondary storage的地址空间. 有两种地址来表示address space中的地址:
1. Physical Address
表示secondary storage中的真实地址, 有以下几个部分:
    * 所连接到host(一个database可能链接多个host)
    * block所在的disk ID
    * disk中的柱面位置(surface)
    * track的位置
    * block在track中的偏移
2. Logical Address
每个block或record都有一个逻辑地址, 用于组建一个map table, 一个logical address对应于一个physical address. 通常physical address比较长, 最小为8字节.

#### 13. 

#### 1. 数据库特性
1. 两个重要特性:
    1. 管理持续性数据(manage persistent data)
    2. 高效地获取大量数据(access large amounts of data effectively)
2. 其他特性:
    1. 至少支持一种数据模型, 用于表示抽象的数学模型
    2. 支持用户使用高级语言来获取, 操作, 建立数据模型
    3. 事务管理, 提供正确, 并发的数据库访问
    4. 访问控制, 阻止未授权用户的访问, 并检查数据的能否被访问
    5. 可靠性, 系统崩溃时不会丢失数据


#### 2. 数据模型
* record: 数据库文件中包含的一条条的就是record, 例如:
```sql
record
    name: char[30];
    manager: char[30];
end
```
* relation: 所有record可抽象为一个relation, 例如:
```sql
EMPLOYEES(NAME, MANAGER)        // EMPLOYEES为relation的名字
```
* field: 上述relation中, NAME和MANAGER称为field, 也可称为attribute
* tuple: relation中的record称为tuple

1. 读入sql
2. exit,quit -> 退出
3. 检查;符号
4. 将sql添加入log
5. 执行sql
    1. 整理sql
        1. 去除空格(单个空格,多个空格,头部和尾部空格),tab,换行,;,^,+
        2. 在 ( ) , = <> < > 前后加空格
        3. 通过空格将sql分割
    2. 判断sql的类型
        1. 长度为0: 空指令
        2. quit
        3. help
        4. create
        5. show
        6. drop
        7. use
        8. insert
        9. exec
        10. select
        11. delete
        12. update
        13. unknown
    3. run
        1. createDatabase
            * 获得DB name和sql type, 放入st(SQLCreateDatabase)中
            * api->createDatabase
                * 将Database放入cm_的dbs_中
                * 写入db name的数据库文件
        2. 
