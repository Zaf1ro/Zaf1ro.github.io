---
title: ctype.h
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: e9d2
date: 2017-06-30 09:41:21
---

## 1. 简介
`ctype.h`是C标准库中的一部分, 包含几个有关测试字符是否属于特定的字符类别的函数. 所有函数都以int作为参数, int所表达的值必须为EOF或可转换的unsigned char. 如果参数符合规范, 所有函数都将返回一个非零整数; 如果不符合则返回零.


## 2. 函数列表
### 2.1 int isalnum(int c);
用于检查参数c是否为字母或数字, 参数c为整数, 返回值为True或者False
```c
#include <stdio.h>
#include <ctype.h>

int main()
{
  char str[] = "12ab@# \a";
  
  for (int i = 0; str[i] != '\0'; ++i)
    if (isalnum(str[i]))
      printf("str[%d] is alphanumeric:|%c|\n", i, str[i]);

  /* output:
   * str[0] is alphanumeric:|1|
   * str[1] is alphanumeric:|2|
   * str[2] is alphanumeric:|a|
   * str[3] is alphanumeric:|b|
   */

  return 0;
}
```

### 2.2 int isalpha(int c);
参数c是否为字母, 参数c为int类型数值, 若c为字符类型则返回非零否则返回零
```c
#include <stdio.h>
#include <ctype.h>

int main()
{
  char str[] = "12ab@# \a";
  
  for (int i = 0; str[i] != '\0'; ++i)
    if (isalpha(str[i]))
      printf("str[%d] is an alphabet:|%c|\n", i, str[i]);

  /* output:
   * str[2] is an alphabet:|a|
   * str[3] is an alphabet:|b|
   */

  return 0;
}
```

### 2.3 void iscntrl(int c);
判断参数c是否为控制符, 控制字符包括0x00-0x1F, 再加上0x7F(DEL), 参数c为int类型数值, 若为控制符则返回非零值;否则返回零. 控制字符在屏幕上不占位, 所以需要使用iscntrl()来检测
```c
#include <stdio.h>
#include <ctype.h>

int main(void) {
  char s[] = "ab12!@# \a\t";
  
  for (int i = 0; s[i] != '\0'; ++i)
    if (iscntrl(s[i]))
      printf("s[%d] is a control character:0x%x\n", i, s[i]);

  /* output:
   * s[8] is a control character:0x7
   * s[9] is a control character:0x9
   */

  return 0;
}
```

### 2.4 int isdigit(int c);
检查参数c是否为阿拉伯数字0-9, 参数c为int类型字符, 若c为阿拉伯数字, 则返回true; 否则返回0
```c
#include <stdio.h>
#include <ctype.h>

int main(void) {
  char a[] = "123@#$%FDSAzxcv";
  
  for (int i = 0; a[i] != '\0'; ++i)
    if (isdigit(a[i]))
      printf("%c is an digit character\n", a[i]);
  
  /* output:
    * 1 is an digit character
    * 2 is an digit character
    * 3 is an digit character
    */

  return 0;
}
```

### 2.5 int isgraph(int c);
该函数用来判断参数是否为除空格以外的可打印字符, 参数c为int类型整数, 若参数为非空格字符且是可打印的ASCII码, 那么返回非0值; 否则返回0
```c
#include <stdio.h>
#include <ctype.h>

int main(void) {
  char a[] = "1a $%^ \1\a";
  
  for (int i = 0; a[i] != '\0'; ++i)
    if(isgraph(a[i]))
      printf("str[%d] is a printable character: %c\n", i, a[i]);

  /* output:
    * str[0] is a printable character: 1
    * str[1] is a printable character: a
    * str[3] is a printable character: $
    * str[4] is a printable character: %
    * str[5] is a printable character: ^	
    */

  return 0;
}
```

### 2.6 int islower(int c);
该函数用来判断参数是否为小写字母, 参数c为int类型整数, 若参数为小写字母, 则返回非0; 否则返回0
```c
#include <stdio.h>
#include <ctype.h>

int main(void) {
  char a[] = "123 @#$ abc ABC \a";
  
  for(int i = 0; a[i] != '\0'; ++i)
    if (islower(a[i]))
      printf("str[%d] is a lowercase character: %c\n", i, a[i]);

  /* output:
   * str[8] is a lowercase character: a
   * str[9] is a lowercase character: b
   * str[10] is a lowercase character: c 
   */

  return 0;
}
```

### 2.7 int isprint(int c);
该函数用来判断一个字符是否为打印字符,与isgraph不同,空格被认为是可打印的;参数c为int类型的数值,若参数为可打印字符,则返回非0,否则返回0
```c
#include <stdio.h>
#include <ctype.h>
  
int main(void) {
  char a[] = "1a @\a\b";
  
  for(int i = 0; a[i] != '\0'; ++i)
    if (isprint(a[i]))
      printf("str[%d] is a printable character: |%c|\n", i, a[i]);

  /* output:
   * str[0] is a printable character: |1|
   * str[1] is a printable character: |a|
   * str[2] is a printable character: | |
   * str[3] is a printable character: |@|
   */

  return 0;
}
```

### 2.8 int ispunct(int c);
该函数用来检测参数是否为标点符号或特殊符号 (非空格, 非数字和非英文字母), 参数c为int类型整数, 若参数为符号, 则返回非0; 否则返回0
```c
#include <stdio.h>
#include <ctype.h>

int main()
{
  char str[] = "12ab!@#$%^&*()\\ \a";
  
  for(int i = 0; str[i] != '\0'; ++i)
    if (ispunct(str[i]))
      printf("str[%d] is a punctuation:|%c|\n", i, str[i]);

  /* output:
   * str[4] is a punctuation:|!|
   * str[5] is a punctuation:|@|
   * str[6] is a punctuation:|#|
   * str[7] is a punctuation:|$|
   * str[8] is a punctuation:|%|
   * str[9] is a punctuation:|^|
   * str[10] is a punctuation:|&|
   * str[11] is a punctuation:|*|
   * str[12] is a punctuation:|(|
   * str[13] is a punctuation:|)|
   * str[14] is a punctuation:|\|
   */

  return 0;
}
```

### 2.9 int isspace(int c);
该函数判断参数是否为空格字符, 参数c为int类型整数, 若参数为空白字符, 则返回非0, 否则返回0
空格字符包括: ' '(0x20,空格),'\t'(0x09,tab),'\n'(0x0a,新的一行),'\v'(0x0b,垂直tab),'\f'(0x0c,换页),'\r'(0x0d,回车)
```c
#include <stdio.h>
#include <ctype.h>

int main()
{
  char s[] = "12ab!@ \t\n\v";
  
  for(int i = 0; s[i] != '\0'; ++i)
    if(isspace(s[i]))
      printf("s[%d] is a space:0x%x\n", i, s[i]);
  
  /* output:
   * s[6] is a space:0x20
   * s[7] is a space:0x9
   * s[8] is a space:0xa
   * s[9] is a space:0xb
   */
  
  return 0;
}
```

### 2.10 int isupper(int c);
该函数判断参数是否为大写英文字符,参数c为int型整数,若参数为大写英文字母返回非0,否则返回0
```c
#include <stdio.h>
#include <ctype.h>
  
int main()
{
  char s[] = "12abAB!@ ";

  for (int i = 0; s[i] != '\0'; ++i)
    if (isupper(s[i]))
      printf("s[%d] is an uppercase character:%c\n", i, s[i]);
  
  /* s[4] is an uppercase character:A
   * s[5] is an uppercase character:B
   */
  
  return 0;
}
```

### 2.11 int isxdigit(int c);
该函数判断参数是否为16进制数字, 参数c为int类型数值, 若参数c为16进制数字, 则返回非0, 否则返回0
十六进制数字: 0123456789ABCDEF
```c
#include <stdio.h>
#include <ctype.h>
  
int main()
{
  char s[] = "12abAB!@ ";

  for (int i = 0; s[i] != '\0'; ++i)
    if (isxdigit(s[i]))
      printf("s[%d] is a hexadecimal digit:%c\n", i, s[i]);
  
  /* s[0] is a hexadecimal digit:1
   * s[1] is a hexadecimal digit:2
   * s[2] is a hexadecimal digit:a
   * s[3] is a hexadecimal digit:b
   * s[4] is a hexadecimal digit:A
   * s[5] is a hexadecimal digit:B
   */
  
  return 0;
}
```

### 2.12 int tolower(int c);
该函数将参数转换为小写字母, 参数c为int类型数值, 若成功将参数转换为小写字母, 则返回其小写字母; 否则返回原有字符
```c
#include <stdio.h>

int main(void) {
  char s[] = "12abAB !@#\t\a";

  for(int i = 0; s[i] != '\0'; ++i)
    s[i] = tolower(s[i]);
  
  printf("%s\n", s);
  
  /* output:
   * 12abab !@#
   */

  return 0;
}
```

### 2.13 int toupper(int c)
该函数将参数转换为大写字母, 参数c为int类型数值, 若参数可以转换为大写字符, 则返回该参数的大写字符; 否则返回原字符
```c
#include <stdio.h>

int main(void) {
  char s[] = "12abAB !@#\t\a";

  for(int i = 0; s[i] != '\0'; ++i)
    s[i] = toupper(s[i]);
  
  printf("%s\n", s);
  
  /* output:
   * 12ABAB !@#
   */

  return 0;
}
```


## 3. ctype.h的实现
### 3.1 字符分类
* 数字: 0-9中的一个十进制数
* 十六进制数字: 数字或字母表的前6个字母(A-Z, a-z)
* 小写字母: a-z中的一个
* 大写字母: A-Z中的一个
* 字母: 大写字母或小写字母
* 字母数字: 字母或数字
* 图形字符: 占据一个打印位置, 输出到显示设备时可见的字符
* 标点符号: 非字母数字的图形字符
* 打印字符: 图形字符或空格字符' '
* 空格: 空格字符' '和其他5个控制字符(换页PF, 换行NL, 回车CR, 水平制表符HT, 垂直制表VT)
* 控制字符: 上述5个控制字符, 退格符BS和警报符BEL, 上述字符中的一个字符

这几类字符就包含了ctype.h的全部函数功能, 其中会有包含的关系, 可总结为下图:
![字符类别](/images/C/CLib/ctype-1.png)

### 3.2 ctype.h头文件
`<ctype.h>`中声明的函数代码都是围绕着3个转换表构建的, 通过对ASCII表的重建, 使得只用位与运算就可以知道字符的类别. 以下是ctype.h的头文件.
```c
// ctype.h standard header
#ifndef CTYPE
#define CTYPE

#define _XA 0x200 /* extra alphabetic */
#define _XS 0x100 /* extra space */
#define _BB 0x80  /* BEL, BS, etc */
#define _CN 0x40  /* CR, FF, HT, NL, VT */
#define _DI 0x20  /* 0-9 */
#define _LO 0x10  /* a-z */
#define _PU 0x08  /* punctuation */
#define _SP 0x04  /* space */
#define _UP 0x02  /* A-Z */
#define _XD 0x01  /* 0-9, A-F, a-f */

extern const short* _Ctype, *_Tolower, *_Toupper;

/* macros */
#define isalnum(c)  ( _Ctype[(int)(c)] & (_DI|_LO|_UP|_XA) )
#define isalpha(c)  ( _Ctype[(int)(c)] & (_LO|_UP|_XA) )
#define iscntrl(c)  ( _Ctype[(int)(c)] & (_BB|_CN) )
#define isdigit(c)  ( _Ctype[(int)(c)] & _DI )
#define isxdigit(c) ( _Ctype[(int)(c)] & _XD )

#define isgraph(c)  ( _Ctype[(int)(c)] & (_DI|_LO|_PU|_UP|_XA) )
#define isprint(c)  ( _Ctype[(int)(c)] & (_DI|_LO|_PU|_SP|_UP|_XA) )
#define ispunct(c)  ( _Ctype[(int)(c)] & _PU )
#define isspace(c)  ( _Ctype[(int)(c)] & (_CN|_SP|_XS) )

#define isupper(c)  ( _Ctype[(int)(c)] & _UP )
#define islower(c)  ( _Ctype[(int)(c)] & _LO )
#define tolower(c)  _Tolower[(int)(c)]
#define toupper(c)  _Toupper[(int)(c)]
#endif // CTYPE
```

### 3.3 ASCII表重建
以下是xctype.c, xtolower.c, xtoupper.c的表实现.
```c
/* xctype.c _Ctype conversion -- ASCII version */
#include <limits.h>
#include <stdio.h>
#include <ctype.h>

#if EOF != -1 || UCHAR_MAX != 255
#error WRONG CTYPE table
#endif

/* macros */
#define XDI (_DI|_XD)
#define XLO (_LO|_XD)
#define XUP (_UP|_XD)

/* static data */
static const short ctype_tab[257] = { 0, /* EOF */
  _BB, _BB, _BB, _BB, _BB, _BB, _BB, _BB,
  _BB, _CN, _CN, _CN, _CN, _CN, _BB, _BB,
  _BB, _BB, _BB, _BB, _BB, _BB, _BB, _BB,
  _BB, _BB, _BB, _BB, _BB, _BB, _BB, _BB,
  _SP, _PU, _PU, _PU, _PU, _PU, _PU, _PU,
  _PU, _PU, _PU, _PU, _PU, _PU, _PU, _PU,
  XDI, XDI, XDI, XDI, XDI, XDI, XDI, XDI,
  XDI, XDI, _PU, _PU, _PU, _PU, _PU, _PU,
  _PU, XUP, XUP, XUP, XUP, XUP, XUP, _UP,
  _UP, _UP, _UP, _UP, _UP, _UP, _UP, _UP,
  _UP, _UP, _UP, _UP, _UP, _UP, _UP, _UP,
  _UP, _UP, _UP, _PU, _PU, _PU, _PU, _PU,
  _PU, XLO, XLO, XLO, XLO, XLO, XLO, _LO,
  _LO, _LO, _LO, _LO, _LO, _LO, _LO, _LO,
  _LO, _LO, _LO, _LO, _LO, _LO, _LO, _LO,
  _LO, _LO, _LO, _PU, _PU, _PU, _PU, _BB,
};

const short *_Ctype = &ctype_tab[1];
```

```c
/* xtolower.c _Tolower conversion table -- ASCII version */
#include <limits.h>
#include <stdio.h>
#include <ctype.h>

#if EOF != -1 || UCHAR_MAX != 255
#error WRONG CTYPE table
#endif

/* static data */
static const short tolow_tab[257] = { EOF,
 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
 0x40,  'a',  'b',  'c',  'd',  'e',  'f',  'g',
  'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
  'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
  'x',  'y',  'z', 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
 0x60,  'a',  'b',  'c',  'd',  'e',  'f',  'g',
  'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
  'p',  'q',  'r',  's',  't',  'u',  'v',  'w',
  'x',  'y',  'z', 0x7b, 0x7c, 0x7d, 0x7e, 0x7f,

 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7,
 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
};

const short *_Tolower = &tolow_tab[1];
```

```c
/* xtoupper.c _Toupper conversion table -- ASCII version */
#include <limits.h>
#include <stdio.h>
#include <ctype.h>

#if EOF != -1 || UCHAR_MAX != 255
#error WRONG CTYPE table
#endif

/* static data */
static const short toup_tab[257] = { EOF,
 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
 0x40,  'A',  'B',  'C',  'D',  'E',  'F',  'G',
  'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',
  'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',
  'X',  'Y',  'Z', 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
 0x60,  'A',  'B',  'C',  'D',  'E',  'F',  'G',
  'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',
  'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',
  'X',  'Y',  'Z', 0x7b, 0x7c, 0x7d, 0x7e, 0x7f,

 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7,
 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7,
 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7,
 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7,
 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
};

const short *_Toupper = &toup_tab[1];
```
