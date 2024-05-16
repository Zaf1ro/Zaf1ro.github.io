---
title: Macro Definition
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: '2828'
date: 2016-03-16 08:32:59
---

## 1. Basic
在C语言的宏中, `#`的功能是将其后面的宏参数进行**字符串化操作**(Stringfication), 其实就是对宏变量通过替换后在其左右各加上一个双引号:
```c
#define WARN_IF(EXP) \
  do { \
    if(EXP)	\
      fprintf(stder, "Warning:" #EXP "\n"); \
  } while(0)
```
当使用`WARN_IF(divider==0);`时, 被替换为
```c
do {
  if (divider == 0)
    fprintf(stderr, "Warning" "divider==0" "\n");
} while(0);
```


## 2. 符号分类
### 2.1 #if的使用
`#if`后面是表达式, 例如:
```c
#include <stdio.h>
#define LETTER 1
  
int main(void) {
#if LETTER
  printf("Yes\n");
#else
  printf("No\n");
#endif

  return 0;
}
```
如果`#if`的表达式成立, 则将`#if`和`#endif`之间的代码部分编译进去


### 2.2 #if defined ()的使用
`#if`后面是一个宏, 例如:
```c
#include <stdio.h>
#define LETTER 1

int main(void) {

#if defined (LETTER)
  printf("Yes\n");  // 输出Yes
#endif
  
  return 0;
}
```
如果defined后面的x已经定义, 那么会**编译if和endif之间的代码**

### 2.3 ifdef的使用
`#ifdef`的使用和`#if defined ()`相同, `#ifndef`的使用和`#if !defined ()`一样

### 2.4 else, elif
`#else`属于`#if`, 与C语言中的else相同, 例如:
```c
#include <stdio.h>
#include LETTER 1
  
int main(void) {
  
#ifdef LETTER
  printf("Yes\n");
#endif
  
  return 0;
}
```

### 2.5 undef
`#undef`可以取消其后面已经被定义的宏名定义, 例如:
```c
#include <stdio.h>
#define LETTER 1
  
int main(void) {

#if defined (LETTER)
  printf("Existed\n");    // 输出
#else
  printf("Not Existed\n");
#endif	

#undef LETTER
  
#if defined (LETTER)
  printf("Existed\n");
#else
  printf("Not Existed\n");  // 输出
#endif	

  return 0;
}
```

### 2.6 line
这个宏和`__LINE__`宏一起使用, `__LINE__`宏表示表示当前C语句在源文件的行数, 例如:
```c
#include <stdio.h>
#line 100

int main(void) {
  printf("__LINE__:%d\n", __LINE__);		
}
```
结果为`__LINE__:102`