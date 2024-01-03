---
title: Memory Alignment
category:
  - C/C++
tag:
  - C/C++
abbrlink: c196
date: 2016-03-27 10:47:07
---

## 1. 原因
1. 内存读取的速度相对于CPU的处理速度来说太慢
2. 由于指令需要分取立即数和各种action, 所以一字节长的指令无法全部用来表示地址空间. 地址线宽度计算公式: $wordSize-\log_2{(wordSize/byteSize)}$. 若一个32位CPU的字长为32bit, 字节大小为8bit, 那么地址线宽度为$32-\log_2{(32/8)}=30$, 所以可选择的地址单元个数为$2^{30}$. 由于每个单位的大小为4字节, 所以可管理$2^{30}*4=2^{32}$字节的内存
1. 以一个内存单元为4字节的32位CPU为例, 如果我们要读取地址为2, 长度为4字节的数据, 那么该数据所占据的内存位置为2-5, 我们需要先读取0-3空间, 取出2-3字节数据, 再读取4-7地址空间, 取出4-5字节数据, 拼在一起就是我们要获取的目标数据. 这样导致只是4字节的数据需要读取两次


## 2. 解决方案
1. 前面变量大小必须为后面变量大小的整数倍, 否则就补齐
2. 整个struct的大小必须为最大变量大小的整数倍


## 3. 例子
```c
#include <stdio.h>

struct Test1 {
  int a;  // 变量大小为4字节
  char b; // 变量大小为1字节, 但前面的变量a大小为4字节
          // 根据第一准则, b后面需要填充3字节
  long c; // 变量大小为4字节
} test1;

struct Test2 {
  int a;  // 变量大小为4字节
  char b; // 变量大小为1字节
  char c; // 变量大小为1字节, 整个结构体的大小为6字节
          // 但最大变量为4字节, 根据第二准则, 应在最后填充2字节
} test2;

int main(void) {
  /* The size of Test1 is 12 */
  printf("The size of Test1 is %d\n", sizeof(test1));
  
  /* The size of Test2 is 8 */
  printf("The size of Test2 is %d\n", sizeof(test2));
  
  return 0;
}
```


## 4. 编译器设置
### 4.1 对齐系数
每个平台上的编译器都有自己默认的"对齐系数", 程序员可以通过
```c 
#pragma pack(n), n = 1, 2, 4, 8, 16
```
来改变系数, n就是指定的"对齐系数"

### 4.2 对齐条件
1. 使用#pragma pack(n), 编译器将按照n个字节对齐
2. 使用#pragma pack(), 取消自定义的字节对齐方式
3. 如果#pragma pack(n)中指定的n大于结构体重最大的成员的size, 则其不起作用, 结构体仍按照size最大成员进行对齐

### 4.3 例子
```c
#include <stdio.h>
  
#pragma pack(1) // 将对齐系数调为1
struct Test1 {
  int a;
  char b;
  long c; // 变量大小为4, 需要对齐
          // 但由于对齐系数为1, 所以不需要填充
} test1;

#pragma pack()  // 关闭自定义的对齐规则
struct Test2 {
  int a;
  char b;
  long c; // 变量大小为4, 由于前面变量大小为1, 
          // 所以需要在前面填充3个字节
} test2;
  
int main(void) {
  /* The size of Test1 is 9 */
  printf("The size of Test1 is %d\n", sizeof(test1));
  
  /* The size of Test2 is 12 */
  printf("The size of Test2 is %d\n", sizeof(test2));

  return 0;
}
```
