---
title: HDFS Overview
abbrlink: fa37
date: 2022-04-11 16:38:10
tags:
  - Distributed System
category:
  - Distributed System
  - HDFS
keywords:
description:
---

## 1. Introduction
**Hadoop Distributed File System**(HDFS)首先是一个文件系统, 用于存储文件. 其使用传统的**hierarchical file system**(分层文件系统, HDFS中称为**namespace**): 我们可以创建, 删除文件, 也可以将一个文件从一个文件夹移动到另一个文件夹, 或重命名文件; 但HDFS的不同之处在于**分布式**: 其将多个机器集合为一个集群, 对外呈现出一个与传统文件系统无异的文件系统. HDFS与传统文件系统并不是对立的, HDFS集群中的单个机器仍使用传统文件系统, 并解放了单机的存储限制, 加入了**fault-tolerant**(容错).

## 2. Assumptions and Goals
HDFS的设计理念基于以下假设/目的:
* Hardware Failure(硬件故障): HDFS集群包含成百上千个机器, 每个机器都会存储数据. 假设一台机器出故障会导致整个系统瘫痪, 那么大部分时间下HDFS都无法工作, 因为机器越多, 出错概率越高. 因此, HDFS必须能快速检测故障, 并自动恢复.
* Streaming Data Access(流式数据访问): 与运行在传统文件系统上的应用不同, 在HDFS上运行的应用需要**流式数据访问**: 由于HDFS的设计目的是**批处理**而不是**用户交互**, 因此数据吞吐量比数据访问延迟更重要.
* Large Data Sets(大数据集): 在HDFS上运行的应用拥有超大数据集. HDFS中的一个文件通常是GB到TB大小. HDFS需支持上百万个这样的文件, 并通过增加机器数量来提高总数据带宽.
* Simple Coherency Model(简单一致性模型): 在HDFS上运行的应用需要**一次写入, 多次读取**的文件访问模型: 文件一旦创建, 就不需要修改(可以追加或截断, 不能随机写). 这种模型简化了一致性问题, 让高吞吐量数据访问变为可能.
* Moving Computation is Cheaper than Moving Data(移动计算比移动数据简单): 如果应用请求的**计算**在数据附近进行, 则计算的效率更高. 因此, 与其将数据移动到应用程序的位置, 不如将**计算**移动到数据的位置. HDFS为应用程序提供了接口, 让它们更靠近数据所在的位置.
* Portability Across Heterogeneous Hardware and Software Platforms(跨异构硬件和软件平台的可移植性): HDFS可从一个平台移植到另一个平台, 因此很多应用都可以选择HDFS.

HDFS的优点: 适合大数据(PB级数据, 百万文件), 无需特殊硬件(廉价机器), 高容错性(可防止文件丢失, 机器故障), 批处理, 高吞吐量(可横向拓展); 但缺点也很明显: 不支持低延迟数据访问, 写入后不可修改, 不支持并发写入, 不适合小文件存取.
因此适合HDFS的场景可以是:
* 存储层: NoSQL HBase
* 中间层: 资源及数据管理, 如YARN, Sentry
* 计算层: MapReduce, Impala, Spark
* 封装工具: 基于MapReduce, Spark等计算引擎的工具, 如Hive, Mahout
* 应用层: 数据分析, 机器学习, 数据挖掘, 图像处理, 网络爬虫


## 3. Architecture
1. HDFS将文件切分为**block**(块), 默认块大小为128MB. 磁盘的块一般为512字节, HDFS之所以设置的非常大, 是为了让磁盘将大部分时间用于读取, 而不是查找块: 磁盘查找块的平均时长为10ms, 读取速度为100MB/s, 因此HDFS读取某个块时, 查询只占1%的时间.
2. HDFS提供一个统一目录树(称为**namespace**), 客户端通过路径访问文件, 如: `hdfs://namenode:port/dir-a/dir-b/file.data`
3. HDFS采用master/slave架构, 集群中有一个master, 称为**NameNode**; 还有多个slave, 称为**DataNode**, 通常一个节点一个datanode. 
4. **NameNode**负责管理namespace(文件目录), 块映射, 副本数等, 统称为**metadata**(元数据)
5. **DataNode**负责管理block
6. 一个文件有多个副本(replica), 并存放在不同的datanode上
7. DataNode定期向namenode汇报block信息, NameNode负责保持副本数量
8. HDFS的内部机制对客户端公开, 客户端会直接读取或写入DataNode

![HDFS Architecture](/images/System-Design/HDFS/1-1.png)


## 4. NameNode
NameData主要有两项职责: 处理客户端的请求, 管理namespace(metadata). 元数据的存储机制如下:
* 内存中有一份完整的元数据
* 磁盘中有一份元数据在某个时间点(checkpoint)的快照(fsimage)
* 一份记录所有文件修改的日志(edits)

### 4.1 Secondary NameNode
当namenode启动时, 其会合并fsimage和edits文件(将fsimage更新至最新状态, 并清空edits). 但由于namenode只在启动时进行合并操作, 因此edits会变得非常大, 下次启动需花费很长时间进行合并. 由此诞生了**Secondary NameNode**, 其运行在另外一个节点, 定期从namenode读取并合并fsimage和edits. 并且, 如果NameNode崩溃, 可从secondary namenode恢复元数据.

### 4.2 Checkpoint Node
**Checkpoint node**会定期从namenode读取fsimage和edits, 合并, 并返还给namenode, 其运行在一个单独的节点. Secondary NameNode和Checkpoint Node的差别在于: secondary namenode只负责合并, 方便namenode之后读取; checkpoint node则将合并后的元数据返还给namenode. 以下是其工作流程:
1. Checkpoint NameNode向namenode发送请求, namenode将新的操作记录写入一个新的edits
2. NameNode向Checkpoint NameNode传输fsimage和旧的edits文件, checkpoint namenode合并两个文件, 产生一个新的fsimage
3. Checkpoint NameNode将新的fsimage传回NameNode
4. NameNode使用新的fsimage

### 4.3 Backup Node
**Backup Node**在内存中维护最新的namespace, 与namenode保持同步. 但backup node无需从namenode下载fsimage和edits, 因为内存中已有完整的namespace, 因此在backup node创建checkpoint只需将内存中的namespace存入磁盘, 硬件要求上与namenode相同.
当前版本(Hadoop 3.3.2), 集群中只能有一个backup node, 但可以有多个checkpoint node. 如果使用backup node, 则可让namenode无需持久化存储, 让backup node承担持久化的责任.


## 5. DataNode
**DataNode**有几项职责:
* 处理来自客户端的读写请求
* 管理block(创建, 删除, 复制)
* 定期向namenode汇报自己持有的block信息
* 定期向namenode发送心跳

如果datanode进程崩溃, 或网络故障导致无法与namenode通信, namenode不会立即判定该datanode死亡, 超过一定时间无心跳才认为datanode死亡. 
DataNode只负责管理block, 无需知道哪些block属于哪些文件. Block被保存在本地文件系统, 且不会将所有block放在同一个文件夹中, 因为单个文件夹的文件数量过多会影响效率.
启动datanode时, 其会扫描本地文件系统中的所有block, 生成一个汇总列表(称为**Blockreport**), 并发送给namenode.

### 5.1 Data Replication
单个文件会被切分为多个block, 因此除了最后一个block, 其余block都是相同大小. HDFS的容错基于block的**replcation**(复制), 因此datanode中的block也称为**replica**. 单个replica的数量称为**replication factor**(复制因子), 由于datanode不能持有同一block的多个replica, 因此该值也等同于datanode数量.
![Data Replication](/images/System-Design/HDFS/1-2.png)

### 5.2 Replica Placement
如何放置replica决定了HDFS的容错和性能. HDFS采用**rack-aware replica placement policy**(机架感知副本放置策略)来提高带宽利用率, 可靠性和可用性. 
大型HDFS集群的datanode会分布在多个机架上, 不同机架的节点(datanode)通过交换机通信. 在大多数情况下, 同一机架内的网络带宽大于不同机架间的网络带宽.
NameNode通过**Hadoop Rack Awareness**(Hadoop机架感知)来判断哪些datanode属于哪个**rack ID**(机架ID). 其中一种策略是: 每个replica放在不同的机架, 这样即使某个机架发生故障, 也不会丢失数据, 并且读取数据时可充分利用多个机架的带宽. 这种策略让负载平衡变得容易, 但写入时需将replica传输给多个机架.
一般情况下, HDFS的复制因子为3, 其放置策略为: 如果writer在datanode上, 则在该datanode上放置第一个replica; 否则选择与writer同机架的任意一个datanode. 第二个放在不同机架的datanode上, 最后一个放在与第二个datanode同机架的另一个datanode上. 该策略可减少机架间的写入流量. 由于机架出故障的概率小于单个节点出故障的概率, 因此不会降低可靠性和可用性. 但该策略不能提高读取带宽, 因为三份replica被放在两个机架上, 而不是三个. 该策略无法均匀分布replioca, 因为两个replica在同一个机架, 另一个replica在其他机架.
若复制因子大于3, 则随机放置第四个以及其他replica, 同时保持每个机架持有的replica数不超过一个上限: $(replicas - 1) / racks + 2$

### 5.3 Replica Selection
为减少全局带宽的消耗和读取延迟, HDFS会让reader的请求尽可能靠近replica. 如果reader和replica处于同一机架, 则优先读取该replica; 若HDFS集群横跨多个数据中心, 则优先选择本地的数据中心.


## 6. Write File
```java
Configuration conf = new Configuration();
conf.set("fs.defaultFS","hdfs://node1:8020");
FileSystem fs = FileSystem.get(conf);
Path path = new Path("/helloworld.txt");
FSDataOutputStream out = fs.create(path);
BufferedWriter bufferedWriter = new BufferedWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8));
bufferedWriter.write("Java API to write data in HDFS");
bufferedWriter.newLine();
bufferedWriter.close();
fs.close();
```
以下是用户上传文件的流程:
1. 客户端调用`DistributedFileSystem`(FileSystem的子类)对象的`create()`函数, 返回一个`HdfsDataOutputStream`对象(其父类为`FSDataOutputStream`, `FSDataOutputStream`的父类为`java.io.OutputStream`). `FSDataOutputStream`封装了一个`DataOutputStream`对象.
2. 创建`DFSOutputStream`的过程中, 会向namenode发起RPC连接, 请求创建文件. NameNode会检查文件是否存在, 路径问题, 权限问题, 配额问题, 加密问题, 网络问题等. 如果检查通过, NameNode会在edits留下一个记录, 并返回; 否则, 客户端抛出异常.
3. `DFSOutputStream`的父类`FSOutputSummer`负责向`dataQueue`写入packet, 并唤醒`DataStreamer`
4. `DFSOutputStream`中包含一个`DataStreamer`对象, 其作为一个单独的线程(调用`run()`启动线程), 负责与namenode的RPC server通信, 以及向datanode传输数据.
5. `DataStreamer`在向datanode发送数据前, 需要先向namenode申请block: `nextBlockOutputStream()`中调用namenode RPC server的`addBlock()`.
6. NameNode根据**机架感知策略**选择三个datanode, 并返回给`DataStreamer`
7. `DataStreamer`拥有一个数据队列(`dataQueue`), 其从队列中取出第一个packet, 并发送给第一个datanode. 这里需要区分三种文件分块:
    * block: 每个文件都被切分为多个block, 默认为128MB
    * packet: 客户端与datanode传输数据的基本单元, 默认为64KB
    * chunk: 客户端与datanode传输数据时的校验值, 默认512字节
每个packet都包含一个chunk, 因此, 真实数据与校验值的比例为$128:1$(64KB:0.5KB)
8. `DataStreamer`通过socket与datanode的`DataXceiverServer`建立数据管道
9. `DataXceiverServer`创建一个`DataXceiver`线程, 负责接收文件, 并传递给下游datanode
10. 上游datanode负责接收下游datanode的写入结果, 并层层上传, 最后汇总并上传给`DataStreamer`
11. `DataStreamer`发送packet后, 会将该packet移至`ackQueue`, 收到ACK后从`ackQueue`中移除; 如果超时, 则认为写入失败, 将packet移回到`dataQueue`(datanode之间的传输同理)
12. 如果无法与datanode建立管道, 则向namenode申请放弃该block, 并重新申请block和datanode列表
13. 如果成功建立数据管道, 但传输失败:
    * 当datanode检测到错误(如校验失败), 会关闭所有socket连接
    * 当客户端检测到传输失败(如超时), 会向其他datanode建立新的管道


## 7. Read File
```java
Configuration conf = new Configuration();
conf.set("fs.defaultFS","hdfs://node1:8020");
FileSystem fs = FileSystem.get(conf);
Path path = new Path("/helloworld.txt");
FSDataInputStream in = fs.open(inFile);
BufferedReader buff = new BufferedReader(new InputStreamReader(in));
String s = null;
while ((s = buff.readLine()) != null) {
  System.out.println(s);
}
buff.close();
in.close();
fs.close();
```
以下是用户读取文件的流程:
1. 与写入数据相同, 客户端调用`DistributedFileSystem`(FileSystem的子类)对象的`open()`函数, 返回一个`HdfsDataInputStream`对象(其父类为`FSDataInputStream`, `FSDataInputStream`的父类为`java.io.InputStream`). `FSDataInputStream`封装了一个`DFSInputStream`对象.
2. 创建`DFSInputStream`的过程中, 会向namenode发起RPC连接, 并远程调用`getBlockLocations()`来获取该文件的所有block信息. NameNode借助namespace获得文件对应的block信息, 并根据客户端的位置对datanode进行排序, 最后返还给`LocatedBlocks`对象
3. `LocatedBlocks`包含一个`LocatedBlock`列表, `LocatedBlock`对象主要包含以下信息:
    * b: block的信息, 包含block的字节数, block的ID等
    * offset: block第一个字节在文件中的偏移量
    * locs: block处于哪些datanode上
4. 客户端调用`FSDataInputStream`的`opne()`函数读取文件, 其会调用`DFSInputStream`的`read()`函数
5. HDFS中, 读取通常需要经过datanode, 因此客户端请求文件时, 需通过TCP socket与datanode连接, 并让datanode发送给客户端; 但如果客户端与数据处于同一位置, 可绕过datanode, 直接访问数据, 称为**short-circuit**(短路)
6. DataNode的DataXceiverServer线程会一直等待请求, 一旦有新的请求, 就创建一个守护线程`DataXceiver`用于处理请求. 每个请求都有一个**操作码**(Op), 用于区分请求的类型(读, 写, 复制等).
7. 通常从磁盘读取数据时, 首先内核读出数据, 放入kernel space, 然后从kernel space传递给user space的应用buffer, 再从buffer移动到kernel space的socket buffer; HDFS使用`java.nio.channels.FileChannel`的`transferTo()`支持Linux系统上的**零拷贝**, 让磁盘里的数据不经过user space, 直接传给socket buffer.
8. 客户端 会将接收到的packet以追加的模式合并为目标文件, 并写入本地
