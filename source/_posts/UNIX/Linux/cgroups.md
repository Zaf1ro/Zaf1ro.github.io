---
title: Linux cgroups
category:
  - Unix
  - Linux
tags:
  - Unix
abbrlink: f10b
date: 2023-01-02 08:44:25
keywords:
description:
---

## 1. Introduction
cgroups全称为**control groups**, 作为Linux kernel的一个特性, 可将进程分配到不同的group, 并为每个group配置某个资源的限额或监控. 以下是cgroups中的一些名词解释:
* cgroup: cgroups中资源分配的最小单元, 包含零个或多个进程, 可关联一个或多个subsystem
* subsystem: 也称为**resource controller**, 用于限制或监控某种资源
* hierarchy: cgroup的组织形式, 类似于文件系统的树状结构. 系统中的每个进程都属于一个cgroup, 而每个cgroup属于一个hierarchy


## 2. Why are cgroups needed
Linux kernel有过很多为进程分组的尝试:
* child process: parent process的所有child process组成一个最简单的group, 用户可调用`wait()`检查该group是否为空. 若`wait()`返回`ECHILD`说明该group为空; 若`wait()`没有返回错误或没有返回, 说明该group不为空.
* process group: V7 Unix中, 当进程第一次打开一个tty, Unix会为其创建一个process group, 进程的所有child process都属于该process group. Process group用于简化kernel对多个进程进行signal操作, 但用户无法主动向某个group发送signal.
* job control: 4BSD引入**job control**, 用于让多个程序共用一个terminal, 用户可通过`Ctrl-Z`停止当前程序, 并让其他程序使用terminal, 因此需支持用户向process group发送signal(`kill()`的PID为负值). 一个job等同于一个process group, 多个job共享一个terminal, 其中一个job称为**foreground job**, 该job中的进程可接收signal和terminal输入, 并输出到terminal; 其他job称为**background job**, 该job种的进程读取或写入terminal时会收到`SIGTTIN`或`SIGTTOU`.
* session: 4.4BSD引入**session**, 每个进程属于一个process group, 每个process group属于一个session. Session用于为daemon process及其child process创建一个独立环境, 由于关闭terminal会关闭对应process group中的所有进程, 因此daemon process不能依赖任何terminal, daemon process可调用`setsid()`创建一个新的session, 让其自动创建新的process group, 并摆脱原terminal的控制.

上述对于进程的分组存在以下局限:
* 用户无法自定义group的名称
* 功能过于简单: 只能控制signal和terminal的I/O
* 层级过于简单: 进程只能分配到某个group中, 没有其他形式的组织结构

以下是cgroups的功能:
* 资源限制: 对cgroup中的进程进行资源总额限制
* 优先级分配: 通过分配cpu时间或I/O带宽, 从而控制进程运行的优先级
* 资源统计: 统计进程的资源使用量, 如cpu使用时长, 内存用量等
* 进程控制: 对cgroup中的进程执行挂起和恢复操作
 

## 3. cgroups version 1 and version 2
Linux kernel 2.6.24引入cgroup, 并在之后添加多个controller(subsystem), 但由于不同controller相互矛盾的设计, 以及多个hierarchy带来的复杂性, Linux 3.10引入**cgroup v2**, 并将之前的cgroup称为**cgroup v1**. 两个版本的cgroup有相似之处, 也有不同之处, 虽然可以在系统中同时使用cgroup v1和cgroup v2, 但推荐只使用cgroup v2.
cgroup(无论v1或v2)的任何操作都通过一个pseudo-filesystem实现, 称为**cgroupfs**, 因此没有添加任何新的API.


## 4. cgroups version 1
cgroups v1支持多个hierarchy, 也就是说, 一个系统中可存在多个hierarchy, 每个hierarchy可绑定零个或多个controller, 每个hierarchy包含系统内的所有进程.

### 4.1 cgroups v1 controllers
以下是cgroups v1中常见的controller:
* cpu: 系统繁忙时, 保证cgroup中进程的最低cpu使用率; 系统不忙时, 不会限制cpu使用率
* cpuacct: 统计cgroup中进程的cpu使用率
* cpuset: 为cgroup中的进程分配cpu和NUMA节点
* memory: 为cgroup中的进程设置process memory, kernel memory和swap的上限
* devices: 控制cgroup中的进程创建设备, 打开设备, 或写入设备
* freezer: 挂起或恢复cgroup中所有进程
* net_cls: 标记cgroup中进程的网络数据包, 允许**tc**控制数据包
* blkio: 控制cgroup中进程访问block device
* perf_event: 允许cgroup中进程被perf工具监控
* net_prio: 为cgroup中进程设置每个network interface的流量优先级

### 4.2 Tasks versus processes
cgroups v1中存在tasks和processes的概念, tasks表示线程, processes表示进程, 一个进程内的多个tasks可属于不同cgroup. 但将同一进程的线程分配到不同cgroup可能导致一些问题, 例如: 由于进程的所有线程共享一个address space, 因此不应使用memory controller.

### 4.3 Mount v1 controller
cgroups v1 hierarchy呈现为filesystem的层级结构, 使用hierarchy前需**mount** cgroup filesystem.
* 将一个controller挂载到一个hierarchy:
  ```sh
  mount -t cgroup -o cpu none /sys/fs/cgroup/cpu
  ```
* 将多个controller挂载到不同hierarchy:
  ```sh
  mount -t cgroup -o cpu,cpuacct none /sys/fs/cgroup/cpu,cpuacct
  ```
* 将多个controller挂载到一个hierarchy:
  ```sh
  mount -t cgroup -o cpu,memory cgroup /sys/fs/cgroup/cpu_memory
  ```
* 将所有controller挂载到一个hierarchy:
  ```sh
  mount -t cgroup -o all cgroup /sys/fs/cgroup
  ```

每个mount point都是一个hierarchy, hierarchy的根部文件夹称为**root cgroup**(如`/sys/fs/cgroup/cpu`), 每个hierarchy包含系统内所有进程, 用户可在root cgroup中创建并嵌套文件夹, 称为**child cgroup**, 因此每个hierarchy组成一个cgroup树状结构.
若将多个controller挂载到一个hierarchy, 该hierarchy中的进程会受到所有controller的影响; 若将多个controller挂载到不同的hierarchy, 则同一进程会出现在不同的hierarchy中, 例如: 进程可位于`/sys/fs/cgroup/cpu`, 其挂载cpu controller, 也可位于`/sys/fs/cgroup/memory`, 其挂载memory controller.

### 4.4 Unmount cgroups v1 filesystem
使用`umount`命令可卸载cgroup filesystem:
```sh
umount /sys/fs/cgroup/pids
```
需要注意的是, 只有hierarchy中所有child cgroup都没有进程时, umount才能真正卸载cgroups filesystem, 换句话说, 需在umount前将child cgroup中进程移至root cgroup. 需要注意的是, root cgroup中存在child cgroup不影响umount, 只要child cgroup中没有任何进程即可.

### 4.5 Creating cgroups and moving processes
假设已将cpu controller挂载到`/sys/fs/cgroup/cpu`, root cgroup包含的文件如下:
```sh
ls /sys/fs/cgroup/cpu
cgroup.clone_children  cpu.cfs_quota_us  cpu.uclamp.max  cpuacct.usage         cpuacct.usage_percpu_sys   cpuacct.usage_user
cgroup.procs           cpu.shares        cpu.uclamp.min  cpuacct.usage_all     cpuacct.usage_percpu_user  notify_on_release
cpu.cfs_period_us      cpu.stat          cpuacct.stat    cpuacct.usage_percpu  cpuacct.usage_sys          tasks
```
创建一个cgroup:
```sh
mkdir /sys/fs/cgroup/cpu/cg1
```
新建的cgroup不包含任何进程, 可将PID写入`cgroup.procs`文件:
```sh
echo $$ > /sys/fs/cgroup/cpu/cg1/cgroup.procs
```

* 写入PID时, 会将该进程的所有线程移入对应的cgroup
* 若PID为0, 会将当前进程移入对应的cgroup
* 一个进程只能出现在一个hierarchy中的一个cgroup, 写入一个cgroup时, 会自动将进程从其他cgroup中移除
* 读取`cgroup.procs`可获得该cgroup中所有PID
* cgroups v1支持同一进程中的不同线程处于不同cgroup: 将thread ID写入对应cgroup的`tasks`文件

### 4.6 Remove cgroup
移除cgroup前需满足以下条件:
* 该cgroup下没有任何child cgroup
  ```
  /sys/fs/cgroup/cpu# mkdir -p cg1/cg2
  /sys/fs/cgroup/cpu# rmdir cg1
  rmdir: failed to remove 'cg1': Device or resource busy
  ```
* 该cgroup没有包含任何进程
  ```sh
  /sys/fs/cgroup/cpu# echo $$ > cg1/cgroup.procs
  /sys/fs/cgroup/cpu# rmdir cg1
  rmdir: failed to remove 'cg1': Device or resource busy
  ```
  
### 4.7 Cgroups v1 release notification
若某个cgroup中没有任何child cgroup, 也不包含任何进程, 则可以说该cgroup为空. 每个hierarchy的root cgroup包含以下两个文件来决定是否通知用户cgroup为空:
* release_agent: 当cgroup为空时, kernel会触发该文件内的程序路径
* notify_on_release: 若为0, 则cgroup为空时不会触发release_agent中的程序; 若为1, 则触发


## 5. cgroups version 2
### 5.1 Background
截止Linux kernel 4.3, cgroups v1已拥有12个controller, 但随着越来越多的开发者使用cgroups, 很多开发者发现了cgroups设计上的不合理之处:
* 创建child cgroup时, 一些controller会将参数传给child cgroup, 而一些controller不会
* cgroups v1支持系统中存在多个hierarchy, 其为开发者提供一些灵活性, 开发者可根据需求将同一进程分配到不同的hierarchy; 但也引入很多问题:
  * 一个controller只能挂载到一个hierarchy: 对于资源分配类的controller, 这种实现很合理; 但对于freezer, 不同hierarchy中的cgroup可能都需要暂停或恢复进程. 当然也可以让一个controller挂载到多个hierarchy, 但实现上会十分复杂.
  * 不同controller的行为不同, 对于hierarchy的使用也不同: 有些controller会从上向下遍历hierarchy, 有些则从下向上
* 真正使用多个hierarchy的开发者很少
* controller的实现尽量避免侵入kernel, 但导致整合的很差

cgroups v2中, 所有controller挂载到一个unified hierarchy, 且系统只能有一个hierarchy. 以下是cgroups v2的新特性:
* cgroup v2只允许一个unified hierarchy, 且该hierarchy挂载所有controller
* 除了root cgroup, 进程只能驻留在leaf node中(没有任何child cgroup的cgroup)
* cgroup可通过`cgroup.subtree_control`文件选择是否开启child cgroup的某个controller
* 移除cgroups v1中的`tasks`文件, 因此一个进程的所有线程必须位于一个cgroup
* `cgroup.events`文件负责通知空的cgroup

### 5.2 cgroups v2 unified hierarchy
cgroups v1允许开发者将不同的controller挂载到不同的hierarchy, 这提供了一定的灵活性; 但实际中, 这么做的人很少, 且增加了维护的难度. cgroups v2中, 所有controller自动挂载到hierarchy上, 因此挂载cgroups v2 filesystem时无需指定controller:
```sh
mount -t cgroup2 none /mnt/cgroup2
```

### 5.3 cgroups v2 controllers
以下是cgroups v2中所有controller:
* cpu: 等同于cgroups v1的cpu和cpuacct
* cpuset: 等同于cgroups v1的cpuset
* freezer: 等同于cgroups v1的freezer
* hugetlb: 等同于cgroups v1的hugetlb
* io: 等同于cgroups v1的blkio
* memory: 等同于cgroups v1的memory
* perf_event: 等同于cgroups v1的perf_event
* pids: 等同于cgroups v1的pids
* rdma: 等同于cgroups v1的rdma

需要注意的是, 若同时使用cgroups v1和v2, 上述controller只能挂载到其中一个cgroups filesystem. 因此使用cgroups v2前, 需卸载controller所在的cgroups v1 filesystem.

### 5.4 cgroups v2 subtree control
以下是cgroups v2 filesystem中root cgroup包含的文件:
```sh
ls /sys/fs/cgroup
cgroup.controllers      cgroup.type      io.max               memory.max           memory.swap.high
cgroup.events           cpu.idle         io.pressure          memory.min           memory.swap.max
cgroup.freeze           cpu.max          io.prio.class        memory.numa_stat     memory.zswap.current
cgroup.kill             cpu.max.burst    io.stat              memory.oom.group     memory.zswap.max
cgroup.max.depth        cpu.pressure     io.weight            memory.peak          pids.current
cgroup.max.descendants  cpu.stat         memory.current       memory.pressure      pids.events
cgroup.procs            cpu.weight       memory.events        memory.reclaim       pids.max
cgroup.stat             cpu.weight.nice  memory.events.local  memory.stat
cgroup.subtree_control  io.bfq.weight    memory.high          memory.swap.current
cgroup.threads          io.latency       memory.low           memory.swap.events
```
cgroups v2 filesystem中, 每一个cgroup都包含以下两个文件:
* cgroup.controllers: 只读文件, 包含cgroup可使用的controller, 对应parent cgroup中`cgroup.subtree_control`文件内的controller
  ```sh
  cat x/y/cgroup.controllers
  cpu io memory pids
  ```
* cgroup.subtree_control: 可读写文件, 决定cgroup的child cgroup可使用哪些controller. 能添加到该文件的controller必须是`cgroup.controllers`内的controller子集. 开启controller使用`+`, 禁用controller使用`-`:
  ```sh
  echo '+pids -memory' > x/y/cgroup.subtree_control
  ```

由于`cgroup.subtree_control`中的controller是`cgroup.controllers`的子集, 因此一旦cgroup中的某个controller被禁用, 则其下面的所有cgroup都无法使用该controller. 
将controller添加到`cgroup.subtree_control`后, child cgroup会自动创建controller对应的interface file. 例如, 向`cgroup.subtree_control`添加`pids`, child cgroup自动创建`pids.max`文件.

### 5.5 No internal processes
cgroups v2遵循"无内部进程"规则: 简单来说, 除了root cgroup, 进程只能驻留在leaf node中(cgroup没有任何child cgroup). 之所以设置这条规则, 因为很难决定如何让cgroups将资源划分给parent cgroup和child cgroup.
假设cgroups filesystem中存在`/cf1/cg2`, 则进程只能驻留在`/cg1/cg2`, 不能驻留在`/cg1`. 推荐实践方法: 将用于容纳进程的cgroup命名为`leaf`, 其他cgroup根据分类需求命名, 因此上文应改为`/cg1/leaf`, 这样开发者可清晰地知道哪些cgroup用于容纳进程, 哪些cgroup用于分类进程.
实际上, 该规则更加复杂: 非root cgroup不能同时满足以下两个条件:
* cgroup包含进程
* cgroup的`cgroup.subtree_control`文件非空

因此, cgroups v2 filesystem中可能存在一个cgroup: 其包含进程, 但也拥有child cgroup; 但该cgroup在清空进程前, 不能向`cgroup.subtree_control`文件添加任何controller.

### 5.6 cgroups v2 cgroup.events file
cgroups v2中每个非root cgroup都拥有一个只读文件, 名为`cgroup.events`. 该文件由多个key-value pair组成, key和value由空格分隔, 每个key-value pair各占一行:
```sh
$ cat mygrp/cgroup.events
populated 1
frozen 0
```
* populated: 若为1, 则cgroup或其嵌套child cgroup拥有进程; 否则为0
* frozen: 若为1, 则cgroup中所有进程已被挂起; 否则为0

### 5.7 cgroups v2 release notification
cgroups v2提供了一个提醒空cgroup的新机制: cgroups v1的`release_agent`和`notify_on_release`被移除, 取而代之的是`cgroup.events`文件的`populated`值, 该值为0时表示cgroup及其嵌套child group内没有任何进程; 否则为1.
相比于cgroups v1, cgroups v2的新机制拥有以下优点:
* cgroups v2允许一个进程同时监控多个`cgroup.events`文件; cgroups v1需为每次通知创建单独进程
* cgroups v2允许多个进程同时监控一个cgroup; cgroups v1只能为一个cgroup设置一个release agent

### 5.8 cgroups v2 cgroup.stat file
cgroups v2中的每个cgroup都拥有一个只读文件, 名为`cgroup.stat`, 该文件包含多个key-value pair.
```sh
cat mygrp/cgroup.stat
nr_descendants 0
nr_dying_descendants 0
```
* nr_descendants: 当前cgroup及其嵌套child cgroup中, **living cgroup**的数量
* nr_dying_descendants: 当前cgroup及其嵌套child cgroup中, **dying cgroup**的数量

创建cgroup后, cgroup的状态为`living`; 用户删除cgroup时, cgroup状态先切换为`dying`, 并在一段时间后真正删除(时长取决于系统负载). 处于dying状态的cgroup无法添加任何进程, 也无法回到living状态.




