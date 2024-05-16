---
title: errno.h
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: '6437'
date: 2017-07-05 16:20:20
---

## 1. 简介
### 1.1 历史
UNIX对错误的系统调用采用一种简单的指示方式, 用汇编语言实现, 使用条件编码的进位标志来测试. 
* 如果进位标志被清零, 则说明系统调用成功
* 如果进位标志不为零, 则说明系统调用错误

一个机器寄存器记录了一个很小的整数, 用来说明错误的性质

### 1.2 C中的错误处理
C采用一个具有外部连接的数据对象, 任何失败的系统调用都从内核中存储一个叫做errno的整型变量作为错误编码. 所以必须早点访问errno, 如果另一个系统调用也失败了, 原来的错误编码将会被后来的错误编码覆盖. 但一个成功的系统调用不会覆盖errno的错误编码. 
`<errno.h>`头文件定义了整数变量errno, 它是通过系统调用设置的，在错误事件中表明了什么发生了错误. 

### 1.3 数学错误
除了系统调用的错误, 数学错误也算入errno中, 可分为几类:
* 向上溢出: 数值太大导致结果不能作为指定类型的浮点值表示
* 向下溢出: 数值太小导致结果不能作为指定类型的浮点值表示
* 有效值丢失: 没有位置容纳结果类型指示的有效位
* 域错误: 接受一个指定的参数而结果没有被定义

但"有效位丢失"是一个不确定是否要报告的错误. 不同的程序员对于这个问题有不同的看法, 有些情况下有效位丢失并不是一个严重问题.


## 2. <errno.h>的使用
不同的系统对于错误编码的值设置不同, 如果需要为某个系统写代码, 那不得不去学习他的错误代码文档. 如果编写可移植代码, 则要避免任何附加的错误代码假设, 如下:
```c
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>

int main()
{
  int a = sqrt(-1);
  if (errno)
    printf("invalid!errno=%d", errno);  // invalid!errno=33
  return 0;
}
```


## 3. <errno.h>的实现
`<errno.h>`的主要目的在于建立errno这个宏, 当调用其他库函数时, 如果出现错误则对这个宏进行修改, 覆盖为相应的错误编码. errno在程序启动时为0, 但不能被任何库函数设置为0.
```c
/* errno.h standard header */
#ifndef _ERRNO
#define _ERRNO
#ifndef _YVALS
#include <yvals.h>
#endif // _YVALS

/* error codes */
#define EDOM   _EDOM
#define ERANGE _ERANGE
#define EFPOS  _EFPOS

/* add your codes */

#define _NERR _ERRMAX   /* 最后一个code+1 */
extern int errno;

#endif // _ERRNO
```
这里errno面临一个问题: 有时errno对于错误的说明过于模糊, 有时又过于清楚. 由于任何库函数都能对errno进行不同的修改, 所以唯一能依赖的只有C标准中明确规定的错误行为, 例如: 调用`sqrt(-1)`就可以知道errno包含了EDOM值. 
由于不同系统的错误编码不同, 所以部分库函数需要知道错误编码的有效范围, 或者一些特定的错误编码, 这时就需要`<yvals.h>`来规范
```c
#define MY_YVALS_H /* 宏保护 */

/* errno属性 */
#define _EDOM   33 /* 用来确定宏EDOM的值 */
#define _ERANGE 34 /* 用来确定宏ERANGE的值 */
#define _EFPOS  35 /* 用来确定宏EFPOS的值 */
#define _ERRMAX 36 /* 用来确定错误编码的范围 **/
```
errno.c确保errno初始化为0, 并#undef预处理指令来保证<errno.h>的安全性
```c
/* errno storage */
#include <errno.h>
#undef errno

int errno = 0;
```
