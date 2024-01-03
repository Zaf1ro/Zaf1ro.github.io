---
title: SQLite Architecture
tag:
  - Database
category:
  - Database
  - SQLite
abbrlink: '7310'
date: 2015-10-30 18:32:40
---

## 1. Interface(接口):
![Architecture-Of-SQLite](/images/SQLite/arch-of-SQLite.gif)
大部分SQLite库的公共接口都可以在main.c, legacy.c, vdbeapi.c, 它们是分散在其他文件夹中, 因为它们可以在文件范围内访问数据结构. sqlite3\_get\_table()在table.c中执行, sqlite3\_mprintf()在printf.c中执行, sqlite3\_complete()在tokenize.c中执行. Tcl接口在tclsqlite.c中执行. 
为防止与其他软件命名冲突, 所有SQLite库的外部符号都用sqlite3作为前缀, 这些用**sqlite_**开头的符号都为了外部使用. 



## 2. Tokenizer(分词器)
当含有SQL表达式的字符串被执行, 接口(Interface)会将这条字符串传给分词器. 分词器的工作就是把字符串拆分为token, 并且将这些token一个个传给解析器(parser). 分词器用c硬编码在tokenize.c文件中. 
在这个设计中, 是分词器来调用解析器. 而熟悉YACC和BISON的人通常习惯做相反的工作:让解析器调用分词器. SQLite的作者对这两种方式都尝试过, 发现让分析器来调用解析器表现得更优秀. 



## 3. Parser(解析器)
解析器的任务就是根据token的上下文环境来**为每个token分配含义**. SQLite的解析器使用[Lemon](http://www.sqlite.org/src/doc/trunk/doc/lemon.html) LALR解析生成器. Lemon和YACC/BISON做同样的工作, 但它使用一种出错率更低的输入语法；Lemon同样会生成一个可重用的、线程安全的解析器. 并且Lemon定义了无终端解除程序(non-terminal destructor)的概念, 这使得遇到语法错误时也不会导致内存泄露. Lemon驱动的源文件可在parse.y文件中找到. 
由于Lemon在开发机上是一个不怎么常见的项目, 所以lemon的全部源文件都放在SQLite的tool子文件夹中, lemon的文档都保存在doc子文件夹中. 



## 4. Code Generator(代码生成器)
当解析器将所有tokens集合成完整的SQL语句后, 将**调用代码生成器来创建虚拟机代码(virtual machine code)**, 它将完成SQL表达式的要求. 代码生成器包括许多文件: attach.c, auth.c, build.c, delete.c, expr.c, insert.c, pragma.c, select.c, trigger.c, update.c, vacuum.c, where.c. 
* expr.c: 表达式的代码生成
* where.c: 处理SELECT、UPDATE、DELETE表达式中的WHERE子句的代码生成
* attach.c, delete.c, insert.c, select.c, trigger.c, update.c和vacuum.c: 同名的SQL语句的代码生成(如:select语句由select.c生成代码)　
* 其他SQL语句的代码生成在build.c中实现
* auth.c执行了sqlite3\_set\_authorizer()的功能



## 5. Virtual Machine(虚拟机)
代码生成器生成的项目由虚拟机来执行, 虚拟机使用一个特殊设计过的抽象计算引擎来操纵数据库文件. 虚拟机有一个用于作为媒介存储的栈, 每个指令包含一个操作码和三个额外的操作数. 虚拟机全部位于一个独立的vdbe.c文件中, 并且虚拟机有一个自己的头文件: vdbe.h, 用于定义一个虚拟机和其他SQLite库的接口:
* vdbeInt.h: 定义了虚拟机的结构
* vdbeaux.c: 虚拟机所使用的组件、其他库用来创建VM程序的接口模块
* vdbeapi.c: 包括虚拟机的外部接口, 例如: sqlite3\_bind\_...
* vdbemem.c: 用来执行一个内部对象"Mem", 它包含一些独立的值(string, integer, float, BLOB)

SQLite用C程序来执行SQL函数, 大部分内置SQL函数都可以在func.c文件中找到, 日期和时间的转换都在date.c



## 6. B-Tree
SQLite使用B-Tree来将数据库存储在硬盘上, B-Tree实现的源文件是btree.c. 在数据库中, 一个独立的B-Tree可用于所有table和index, 所有的B-Tree都存储在同一个磁盘文件中. 详细的文件格式可以在btree.c的开头注释中找到



## 7. Page Cache(页面缓存)
B-Tree模块要求信息来自硬盘上固定的程序块, 默认块大小为1024字节, 但可在512-65536字节之间改变. 页面缓存负责读取、写入和缓存这些块. 页面缓存也实现了回滚和原子提交这些抽象概念, 并且保证数据库文件上锁. B-Tree驱动请求从页面缓存中获取特定的页面, 并且当要修改、提交、回滚修改时通知页面缓存, 页面缓存负责使这一切快速、安全、高效的完成. 实现页面缓存的代码位于pager.c中. 页面缓存子系统的接口位于pager.h头文件中. 



## 8. OS Interface(系统接口)
为了实现POSIX和Win32系统的兼容性, SQLite使用了一个抽象层来实现操作系统的接口. 这个操作系统层(OS abstraction layer)的接口实现源码在os.h中. 每一个被支持的操作系统都有其自己的实现: UNIX的os_unix.c、Windows的os_win.c等等, 每一个操作系统的接口实现也都有其头文件: os_unix.h、os_win.h等等. 



## 9. Utilities(实用程序)
内存分配和无大小写区分的字符串比较函数都在util.c文件中. 解析器使用的符号表(Symbol table)由哈希表(hash table)实现, 它存在hash.c文件. utf.c文件包含Unicode转换子函数. SQLite在printf.c文件中实现了一个私有的printf(), 还有random.c中的一个随机数生成器. 



## 10. Test Code(测试代码)
如果你想统计回归测试脚本(意为: 重新测试未改变的项目代码, 防止新的改动对原先代码产生影响)的数量, SQLite接近一半的代码将会被测试. 有许多assert()函数在主要代码文件中. 另外, test1.c到test5.c, 再加上md5.c拓展应用, 用于测试目的. os_test.c后台接口用于模仿电源切断来验证页面管理程序的事故恢复机制.
