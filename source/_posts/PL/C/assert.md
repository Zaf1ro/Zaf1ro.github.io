---
title: assert.h
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: '485'
date: 2016-03-14 18:29:24
---

## 1. 概述
assert宏的原型定义在`<assert.h>`中,其作用是如果条件返回错误,则终止程序执行,原型定义:
```c
#include <assert.h>

void assert(int expression);
```

assert的作用是计算expression,如果其值为假(为0),则先向stderr打印一条出错信息,然后通过abort终止程序运行,例如:
```c
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

int main(void)
{
  FILE* fp;
  fp = open("test.txt", "w");

  assert(fp); // 由于是写入方式,所以不会报错,如果test.txt不存在则创建名为test.txt的文件
  fclose(fp);

  fp = open("test2.txt", "r");
  assert(fp); // 如果test2.txt不存在则直接报错并退出程序
  fclose(fp); // 如果打不开test2.txt则不会执行该语句

  return 0;
}
```


## 2. 缺点
1. 频繁调用会极大地影响程序的性能,增加额外的开销.在调试结束后,可以在`<assert.h>`前插入`#define NDEBUG`禁止assert调用:
```c
#include <stdio.h>
#define NDEBUG
#include <assert.h>
```
2. 当向代码中添加assert时要确保这些断言没有副作用:
```c
assert(m++ > 0);       // 最终m的值可能因编译器不同而不同
assert(myFunc(0) == 1) // 要确保myFunc()没有副作用
```
3. 一个assert只能检查一个条件,如果需要检查多个条件,那么需要写多条assert:
```c
assert(a>0 && b<0);
// error
assert(a > 0);
assert(b < 0);
// correct
```


## 3. 使用场景:
1. 捕获逻辑错误: 条件必须为真,根据程序的逻辑可以设置断言
  ```c
  assert(numMols > 0);    // 判断数量是否大于0
  ```
2. 检查结果: 对于得到的数值进行判断
  ```c
  assert(numMols < nums); // 确保结果小于某个值
  ```
3. 查找未处理的错误: 使用断言来找到程序中可能出现的错误,例如判断文件是否打开


## 4. 宏 NDEBUG
需要注意的是, assert虽然使得代码变得简单, 但并不应该出现在正式产品中. 程序的终止对于用户并无价值, 只能在调试程序时使用assert, 所以需要一种方法来将断言在特定情况下无效化. 我们可以通过定义宏NDEBUG来改变assert的展开方式:
* 如果没有定义NDEBUG, 则头文件会将assert展开为一个表达式, 并判断断言是否为假, 如果为假则输出错误信息并终止程序
  ```c
  #include <assert.h>

  void assert(int expression);
  ```
* 如果定义了NDEBUG, 则头文件将assert定义为不执行任何操作的静止形式
  ```c
  #define NDEBUG  /* disable assertion */
  #include <assert.h>

  #define assert(ignore) ((void) 0)
  ```


## 5. 一个简单的assert宏
```c
#define assert(test) if(!(test)) \
  fprintf(stderr, "Assertion failed: %s, file %s, line %i\n", \
  #test, __FILE__, __LINE__)
```
上述的assert编写存在以下几个问题:
1. 宏不应调用库的任何输出函数, 例如fprintf, 也不能引用宏stderr. 因为这些名字只有在`<stdio.h>`中正确声明或定义时才能使用, 由于程序中不一定包含`<stdio.h>`, 所以可能导致程序编译失败.
2. 宏应能扩展为一个void类型的表达式, 因为程序可能将assert包含在一个表达式中, 这时就不能使用if语句, 需要换一个条件操作符, 例如: `(assert(0<x), x<y)`
3. 宏应该可扩展为有效且紧凑的代码, 但这个版本的assert却调用了一个需要传递5个参数的函数.


## 6. 正确版本
```c
// assert.h

#undef assert /* remove existing definition */

#ifdef NDEBUG
  #define assert(test) ((void) 0)
#else /* NDEBUG not defined */
  void _Assert(char *);

  #define _STR(x) _VAL(x)
  #define _VAL(x) #x
  #define assert(test) ((test) ? (void) 0 \
   : _Assert(__FILE__":"_VAL(__LINE__)" "#test))
#endif
```
`__LINE__`作为一个宏, 需要先用宏将其转换为十进制常量, 再将其转换为字符串常量
```c
// xassert.c

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

void _Assert(char* mesg)
{
  fputs(mesg, stderr);
  fputs(" -- assertion failed\n", stderr);
  abort();
}
```
以下是测试代码:
```c
/* test assert macro */
#define NDEBUG
#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>

static int val = 0;

static void field_abort(int sig)
{
  if (val == 1) {  /* expected result */
    puts("SUCCESS testing <assert.h>");
    exit(EXIT_SUCCESS);
  } else {  /* unexpected result */
    puts("FAILURE testing <assert.h>");
    exit(EXIT_FAILURE);
  }
}

static void dummy()
{
  int i = 0;
  assert(i == 0);
  assert(i == 1);
}

#undef NDEBUG
#include <assert.h>

int main()
{
  assert(signal(SIGABRT, &field_abort) != SIG_ERR);
  dummy();
  assert(val == 0);  /* should not abort */
  ++val;
  fputs("Sample assertion failure message -- \n", stderr);
  assert(val == 0);  /* should abort */
  puts("FAILURE testing <assert.h>");
  return(EXIT_FAILURE);
}
```
