---
title: limits.h
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: aa5d
date: 2017-09-03 14:20:24
---

## 1. 简介
### 1.1 历史
C语言的第一次标准化始于1980年, 当时由一个称作`/usr/group`的组织进行标准化工作, 现在更名为UniForum. `/usr/group`开始定义UNIX和类UNIX系统的具体含义中, 他们成立了一个标准委员会来专注于C编程环境, 这个委员会称为X3J11.
当要构造一个体系结构独立的描述时, 其中一个工作就是找出不同计算机体系结构之间哪些地方发生了变化. 当一个应用程序从一个系统移到另一个系统时, 某个关键值可能会改变. 所以需要对该值重新命名. 要制定测试该值的规则, 并定义该值的变化范围.
`/usr/group`发明了标准头文件`<limits.h>`来捕捉不同计算机体系结构之间的变化, 碰巧`<limits.h>`又定义了处理整数值的变化范围, 但X3J11决定为浮点类型加入范围定义时, 没有添加到`<limits.h>`中, 而是添加到了标准头文件`<float.h>`中. 虽然应该把`<limits.h>`改名为`<integer.h>`, 但为了保持连贯性, 所以头文件名一直保留下来.


### 1.2 <limits.h>的内容
以下是`<limits.h>`的宏定义:

Macro | Value | Description
----|----|----
CHAR_BIT | 8 | 一byte中的bit数量.
SCHAR_MIN | -128 | signed char的最小值.
SCHAR_MAX | +127 | signed char的最大值.
UCHAR_MAX | 255 | unsigned char的最大值.
CHAR_MIN | -128 | char的最小值.
CHAR_MAX | +127 | char的最大值.
MB_LEN_MAX | 16 | 多byte的char拥有byte的最多数量.
SHRT_MIN | -32768 | short int的最小值.
SHRT_MAX | +32767 | short int的最大值.
USHRT_MAX | 65535 | unsigned short int的最大值.
INT_MIN | -2147483648 | int的最小值.
INT_MAX | +2147483647 | int的最大值.
UINT_MAX | 4294967295 | unsigned int的最大值.
LONG_MIN | -9223372036854775808 | long int的最小值.
LONG_MAX | +9223372036854775807 | long int的最大值.
ULONG_MAX | 18446744073709551615 | unsigned long int的最大值.

### 1.3 <limits.h>的使用
1. 防止越界: 假设`VAL_MIN`和`VAL_MAX`为某个数据类型的最小值和最大值, 为防止界限溢出, 应使用以下代码:
  ```c
  #include <assert.h>
  #include <limits.h>
  #if VAL_MIN<INT_MIN || INT_MAX>VAL_MAX
  // error value out of range
  #endif
  ```
2. 类型适应: 控制一个程序中的类型选择:
  ```c
  #include <assert.h>
  #include <limits.h>
  #if VAL_MIN<INT_MIN || INT_MAX<VAL_MAX
    typedef long Val_t;
  #else
    typedef int Val_t;
  #endif
  ```
  这样就可以把这个范围(`[VAL_MIN, VAL_MAX]`)的所有变量声明为`Val_t`类型.


## 2. <limits.h>的实现
大部分计算机都是用8bits的char类型, 2bytes的short类型和4bytes的long类型, 但也有一些常见的变种:
* int类型可能为2bytes或4bytes
* char类型与signed char和unsigned char的取值范围相同
* 有符号的值使用2的补码(two's complement)进行编码
* 一个多byte的char类型的byte数可能任意正整数

为了适应这些变种, 需要定义一些参数来做判断:
* _ILONG: 如果int类型为4bytes, 则为非零
* _CSIGN: 如果char类型有符号, 则为非零
* _C2: 如果使用2的补码, 则为1, 否则为0
* _MBMAX: 单个多byte的字符在最坏情况下的长度

### 2.1 实现代码
```c
/* limits.h standard header -- 8-bit version */
#ifndef _LIMITS
#define _LIMITS
#ifndef _YVALS
#include <yvals.h>
#endif

/* char properties */
#define CHAR_BIT	8
#if _CSIGN
#define CHAR_MAX	127
#define CHAR_MIN	(-127-_C2)
#else
#define CHAR_MAX	255
#define CHAR_MIN	0
#endif

/* int properties */
#if _ILONG
#define INT_MAX		2147483647
#define INT_MIN		(-2147483647-_C2)
#define UINT_MAX	4294967295U
#else
#define INT_MAX		32767
#define INT_MIN		(-32767-_C2)
#define UINT_MAX	65535U
#endif

/* long properties */
#define LONG_MAX	2147483647
#define LONG_MIN	(-2147483647-_C2)

/* multibyte properties */
#define MB_LEN_MAX	_MBMAX

/* signed char properties */
#define SCHAR_MAX	127
#define SCHAR_MIN	(-127-_C2)

/* short properties */
#define SHRT_MAX	32767
#define SHRT_MIN	(-32767-_C2)

/* unsigned properties */
#define UCHAR_MAX	255
#define ULONG_MAX	4294967295
#define USHRT_MAX	65535U
#endif
```

剩下的变量存在yvals.h中
```c
/* yvals.h values header */

/* integer properties */
#define _C2		  1
#define _CSIGN	1
#define _ILONG	0
#define _MBMAX	8
```


## 3. <limits.h>的测试
可通过以下程序获得一个可读的摘要, 摘要记录了`<limits.h>`中定义的的宏的值.
```c
/* test limits macros */
#include <limits.h>
#include <stdio.h>

int main(){
  /* test basic properties of limits.h macros */
  printf("CHAR_BIT = %2i   MB_LEN_MAX = %2i\n\n",
  CHAR_BIT, MB_LEN_MAX);
  printf(" CHAR_MAX = %10i   CHAR_MIN = %10i\n",
  CHAR_MAX, CHAR_MIN);
  printf("SCHAR_MAX = %10i  SCHAR_MIN = %10i\n",
  SCHAR_MAX, SCHAR_MIN);
  printf("UCHAR_MAX = %10u\n\n", UCHAR_MAX);
  printf(" SHRT_MAX = %10i   SHRT_MIN = %10i\n",
  SHRT_MAX, SHRT_MIN);
  printf("USHRT_MAX = %10u\n\n", USHRT_MAX);
  printf("  INT_MAX = %10i  INT_MIN = %10i\n",
  INT_MAX, INT_MIN);
  printf(" UINT_MAX = %10u\n\n", UINT_MAX);
  printf(" LONG_MAX = %10li   LONG_MIN = %10li\n",
  LONG_MAX, LONG_MIN);
  printf("ULONG_MAX = %10lu\n", ULONG_MAX);
#if CHAR_BIT < 8 || CHAR_MAX < 127 || 0 < CHAR_MIN \
  || CHAR_MAX != SCHAR_MAX && CHAR_MAX != UCHAR_MAX
#error bad char properties
#endif
#if INT_MAX < 32767 || -32767 < INT_MIN || INT_MAX < SHRT_MAX
#error bad int properties
#endif
#if LONG_MAX < 2147483647 || -2147483647 < LONG_MIN || LONG_MAX < INT_MAX
#error bad long properties
#endif
#if MB_LEN_MAX < 1
#error bad MB_LEN_MAX
#endif
#if SCHAR_MAX < 127 || -127 < SCHAR_MIN
#error bad signed char properties
#endif
#if SHRT_MAX < 32767 || -32767 < SHRT_MIN || SHRT_MAX < SCHAR_MAX
#error bad short properties
#endif
#if UCHAR_MAX < 255 || UCHAR_MAX / 2 < SCHAR_MAX
#error bad unsigned char properties
#endif
#if UINT_MAX < 65535 || UINT_MAX / 2 < INT_MAX || UINT_MAX < USHRT_MAX
#error bad unsigned int properties
#endif
#if ULONG_MAX < 4294967295 || ULONG_MAX / 2 < LONG_MAX || ULONG_MAX < UINT_MAX
#error bad unsigned long properties
#endif
#if USHRT_MAX < 65535 || USHRT_MAX / 2 < SHRT_MAX || USHRT_MAX < UCHAR_MAX
#error bad unsigned short properties
#endif
  puts("SUCCESS testing <limits.h>");
  return (0);
}
```
下面是输出结果, 测试的系统下char和unsigned char表示相同
```c
CHAR_BIT = 8            MB_LEN_MAX =  2
CHAR_MAX = 127          CHAR_MIN = -128
SCHAR_MAX = 127         SCHAR_MIN = -128
UCHAR_MAX = 255

SHRT_MAX = 32767        SHRT_MIN = -32768
USHRT_MAX = 65535

INT_MAX = 2147483647    INT_MIN = -2147483648
UINT_MAX = 4294967295

LONG_MAX = 2147483647   LONG_MIN = -2147483648
ULONG_MAX = 4294967295
SUCCESS testing <limits.h>
```
