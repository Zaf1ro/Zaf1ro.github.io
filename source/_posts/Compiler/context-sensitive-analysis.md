---
title: Context Sensitive Analysis (1)
category:
  - Compiler
tag:
  - Compiler
abbrlink: ab2f
date: 2020-03-17 09:06:40
keywords:
description:
---

## 1. Introduction
语法正确代码仍可能包含严重错误, 导致编译无法完成, 这就需要compiler对程序的了解必须超越语法这个层次, 并建立一个庞大的知识库. 为此, complier需要跟踪每个值的流动, 值的类型, 程序与外部设备的交互, 程序本身的结构, 这种技术被称为**context-sensitive analysis**, 或称为**semantic elaboration**.
为从语法之外的视角考察程序, compiler需对代码做出一些抽象表示, 如type system(类型系统), storage map(存储映射), control-flow graph(控制流图). Compiler必须理解程序的namespace, 包括值的类型, 值与名称的映射. 当程序中出现一个名称**x**时, compiler需要考虑一下几个问题:
1. x存储了什么类型的值: 大多数programming language使用多种数据类型, 包括number, character, boolean, pointer. 除此之外还有复合类型, 例如array, structure, set, string.
2. x有多大: compiler必须知道x所占内存空间大小, 若x为number, 则可能是integer, floating-point number, complex number, 每个数值类型都可能拥有不同的大小. 对于array和string, 元素数量可能在编译时就能确定, 也可能运行时才能确定.
3. 若x为函数名, 则其需要什么参数; 若有返回值, 返回什么类型的值: 在调用函数之前, compiler必须知道几个问题: 函数需要多少个参数, 参数存放的位置, 每个参数的预期类型. 若函数返回一个值, 则需要将返回值传给谁, 返回值的类型是什么. 
4. x的生命周期是多长: compiler必须引用x时, x始终处于可访问的状态. 若x为local variable, compiler可通过在x的声明范围内保留x的值来描述x的生命周期; 若x为global variable或显式分配的structure, 则compiler很难判定其生存周期. Compiler当然可以一直为x保留一个空间, 但如果能更加精确地划分x的生存周期, 会节省不少空间.
5. 谁为x分配空间: x所占空间通过隐式还是显式分配, 若为显式分配, 则分配空间前x的地址是未知的; 若x为隐式分配, 则compiler需对x的地址有更多了解, 这样才能生成更高效的代码

对于类Algol的语言, 每个变量在使用前都必须声明, 以下是声明语句的production:
$$
\textit{ProcedureBody} \rightarrow \textit{Declarations} \ \textit{Executables}
$$

上述production显然无法确保变量在使用前被声明, 也无法保证变量不会重复声明, 因为parser使用的是context-free grammar. context-free grammar处理的是**syntactic category**(语法范畴), 而非特定变量. 为了实施**declare before use**的规则, 必须考虑上下文信息.



## 2. An Introduction to Type Systems
大多数programming language都会将一组性质关联到每个值, 这些性质集合称为**类型**. 类型规定了属于该类型的值的性质, 例如: 整数类型可为$[-2^{31}, 2^{31})$范围内的任意整数; red可为枚举类型colors的其中一个值. 当在C语言中声明一个structure时, 其实是定义了一种类型, 这种类型会为其object规定多个声明字段, 每个声明字段都拥有自己的类型. 这些语言自带或程序员自定义的类型所规定的的程序行为规则, 统称为type system(类型系统).

### 2.1 The Purpose of Type System
相对于context-free grammar, type system更能精确地规定程序的行为, 通过建立一个词汇表来描述程序的形式和行为, 并实现三个目的: safety, expressiveness, runtime effciency.

#### 2.1.1 Ensure Runtime Safety
Type system有利于compiler检测和避免运行时错误, 在有问题的程序运行之前就可被检测出, 但并不意味着所有运行时错误都能检测出. Type system会尽可能多地消除运行时错误, 这需要compiler为每个表达式推断类型, 且根据语言本身的语法规则来检查类型. 以FORTRAN77的加法运算符为例, 以下是$a+b$表达式中a和b的所有类型组合的结果:

| + | integer | real | double | complex |
|:---:|:---:|:---:|:---:|:---:|
| integer | integer | real | double | complex |
| real | real | real | double | complex |
| double | double | double | double | $\textit{illegal}$ |
| complex | complex | complex | $\textit{illegal}$ | complex |

这种为每个表达式都能分配一个无歧义类型的语言称为**strongly typed language**(强类型语言), 这种语言可让compiler保证程序执行前就可捕获大多数类型相关的错误. 若编译时就可确定每个表达式的类型, 则这种语言称为**statically typed**(静态类型); 若某些表达式只能在运行时确定类型, 则称为**dynamically typed**(动态类型). 另外还有两种类型系统较弱的语言, 一种为**untyped language**(无类型语言), 例如汇编和BCPL; 还有一种为**weakly typed language**(弱类型语言).

#### 2.1.2 Improve Expressiveness
具有良好的type system可让语言设计者更加精确地规定程序行为, 例如: operator overloading(运算符重载), 赋予运算符上下文相关的语义. 对于BCPL, 唯一的类型为cell, 因此只能用$+$表示整数加法, 而不能表示浮点加法; 而FORTRAN则只有一个$+$运算符表示所有数值相加, 利用类型信息来判断运算符应如何实现; C语言使用function prototype(函数原型)来将参数和返回值转换为合适的类型; Java会通过考察构造函数的参数列表, 选择默认构造函数或特化构造函数.

#### 2.1.3 Generate Better Code
Compiler可通过完善的类型系统生成更高效的代码, 以FORTRAN77中的加法实现为例, 以下是加法表达式的所有类型组合:

| $a$ | $b$ | $a + b$ | Code |
|:---:|:---:|:---:|:---:|
| integer | integer | ineteger | $\text{iADD} \\ r_a, r_b \Rightarrow r_{a+b}$ |
| integer | real | real | $\text{i2f} \\ f_a \Rightarrow r_{a_f} \\\\ \text{fADD} \\ r_{a_f}, r_b \Rightarrow r_{a_f+b}$ |
| integer | double | double | $\text{i2d} \\ r_a \Rightarrow r_{a_d} \\\\ \text{dADD} \\ r_{a_d}, r_b \Rightarrow r_{a_d+b}$ |
| real | real | real | $\text{fADD} \\ r_a, r_b \Rightarrow r_{a+b}$ |
| real | double | double | $\text{r2d} \\ r_a \Rightarrow r_{a_d} \\\\ \text{dADD} \\ r_{a_d}, r_b \Rightarrow r_{a_d+b}$ |
| double | double | double | $\text{dADD} \\ r_a, r_b \Rightarrow r_{a+b}$ |

如果在某种语言中, 编译时无法确定类型, 则一部分检查可推迟到运行时进行. 但运行时检查会影响代码的运行效率, 为此需要在安全性和开销之间做出平衡. 因为, 每个值不仅需要value字段, 还需要tag字段, 用于表示值类型. 但随着tag的引入, 每个值所占空间也变大, 即在内存中需要更多空间. 若变量存储在register中, 则其value和tag都需要分配register. tag也需要初始化, 读, 写, 比较等操作, 所有这些操作都增加了加法的开销. 以下是运行时类型检查的一个例子:
```code
// partial code for "$a+b \Rightarrow c$"
if (tag(a) = integer) then
  if (tag(b) = integer) then
    value(c) = value(a) + value(b);
    tag(c) = integer;
  else if (tag(b) = real) then
    temp = ConvertToReal(a);
    value(c) = temp + value(b);
    tag(c) = real;
  else if (tag(b) = $\cdots$) then
    // handle all other types $\cdots$
  else
    signal runtime type fault
else if (tag(a) = real) then
  if (tag(b) = integer) then
    temp = ConvertToReal(b);
    value(c) = value(a) + temp;
    tag(c) = real;
  else if (tag(b) = real) then
    value(c) = value(a) + value(b);
    tag(c) = real;
  else if (tag(b) = $\cdots$) then
    // handle all other types $\cdots$
  else
    signal runtime type fault
else if (tag(a) = $\cdots$) then
  // handle all other types $\cdots$
else
  signal illegal tag value;
```

### 2.2 Type Checking
类型系统可分为四个组成部分: 基础类型, 也称为内建类型; 根据现有类型构建的新类型规则; 用于确定两种类型是否等价的规则; 为表达式推断类型的规则. 

#### 2.2.1 Base Type
大多数语言都提供了基础类型, 包括: number, character和boolean. 
1. Number: 几乎所有语言都会提供一种或多种number类型, 通常包括整数和浮点数. 部分语言不会指定number类型的长度, 但会用类型之间的比例给compiler一定空间调整. 例如: FORTRAN中double是real的两倍长, 但并没有指明double或real的具体长度; 另外一些语言会规定每个类型的实现细节. 例如: Java会为byte, short, int和long规定具体长度, 保证Java程序在不同系统, 不同硬件上具有相同行为.
2. Character: 字符可以是8bit长度的ASCII字符集, 也可以是16bit长度的Unicode字符集. 大多数语言规定字符集是有序的, 因此可用**比较运算符**来为字符排序.
3. Boolean: 大多数语言只包含一种boolean类型, 该类型只有两种值: true和false. 为boolean类型的操作包括and, or, xor和not. C语言将boolean值看做无符号整数的一个子区间, 其中包括0(false)和1(true).

#### 2.2.2 Compound and Constructed Types
虽然语言对硬件提供了足够的抽象类型, 但不足以表示程序所需要的信息. 程序通常需要处理更为复杂的数据结构, 如graph, tree, table, array, record, list, stack等, 这些数据结构由一个或多个对象组成, 每个对象有自身的类型. 
1. Array: 数组是使用最广泛的聚合类型. 数组表示多个同一类型的对象, 每个对象拥有不同的名字. 例如: C语言中的**int a[100][200]**, 表示为$100 \times 200 = 20,000$个整数分配存储空间, 并确保这些整数可通过名字**a**访问到, 每个下标分别表示不同的存储位置. 
2. String: 串和数组有相同属性, C语言就是用字符数组来实现字符串. 但两者存在一些差异: 对于串的操作, 如连接, 转换和计算长度, 对于数组则不一定有对应操作.
3. Enumerate: 枚举类型允许创建包含常数值的集合, 以C语言为例, 可声明enum WeekDay {Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday}. Compiler会为枚举类型中的每个成员映射不同的值, 枚举类型的各个成员是有序的, 因此可以用运算符比较同一枚举类型中的成员, 如: Monday < Tuesday; 但比较不同枚举类型的成员则失去意义, 有些语言也会限制比较行为, 使其只能作用于同一个枚举类型的成员.
4. Structures and Variants
Structure(结构), 也称为record(记录), 可将多个任意类型的对象聚合在一起. 结构的成员需要明确标注名称, 以C语言为例, 以下是一个tree中节点结构的声明, 节点可能有一个子节点, 也可能有两个子节点:
```c
struct Node1 {
  struct Node1 *left;
  unsigned Operator;
  int Value;
}

struct Node2 {
  struct Node2 *left;
  struct Node2 *right;
  unsigned Operator;
  int Value
}
```
  结构的类型可表示为其中所有成员类型的有序乘积. Node1的类型可表示为$(\text{Node1\*}) \times \text{unsigned} \times \text{int}$, Node2的类型可表示为$(\text{Node2\*} \times \text{Node2\*} \times \text{unsigned} \times \text{int})$. Node1作为一种程序员创造的新类型, 也具备基础类型的属性, 例如: 指向Node1类型的指针递增时, 会移动Node1类型大小的空间; 可将任意指针转换为Node1\*类型
5. Pointer
指针是抽象的内存地址, 程序员可通过指针来操作任意数据类型. 指针允许程序保存一个地址, 而后使用该指针来表示地址所在的对象. 一般来说, 创建对象的同时会生成指针, 如C语言的malloc和Java的new; 一些语言也提供获取对象地址的方法, 如C语言的&运算符.
为防止程序员使用**T**类型的指针引用**S**类型的对象, 一些语言会限制不同类型指针和对象之间的引用: 若指针的类型为integer, 则指向的对象类型必须为integer; 若指向boolean, 则造成类型错误. 创建新对象也应返回一个具有适当类型的对象, 例如: Java的new会返回一个类型化的对象, 而C语言的malloc会返回一个void类型的指针, 需要程序员进行类型转换.
一些语言允许直接操作指针, 比如: 指针的算术运算, 包括递增和递减; 允许程序创建新的指针, 这些操作都会造成安全隐患.

#### 2.2.3 Type Equivalence
对于任何一个类型系统, 都需要一个关键组件: 判断两个类型声明是否等价. 以C语言中的两个自定义类型为例:
```c
struct Tree {
  struct Tree *left;
  struct Tree *right;
  int value
}
struct STree {
  struct STree *left;
  struct STree *right;
  int value
}
```
不同语言对于以上两个类型声明是否等价会有不同的答案, 一般来说, 存在两种等价性判断机制:
1. name equivalence: 若两个声明的名称相同, 则两者等价. 若采用该方法, 则**Tree**和**STree**不等价. 理论上, 程序员可为所有类型取不同的名字, 但随着程序规模, 作者数量, 代码文件长度的增加, 维护名字一致性变得困难.
2. structural equivalence: 若两个类型声明具有相同结构(由同一组字段组成, 且字段排列顺序相同), 则两者等价. 若采用该方法, 则**Tree**和**STree**等价.

#### 2.2.4 Inference Rules
Inference rule(类型推断规则)会为每个操作符规定操作数类型和结果类型之间的映射. 以赋值运算符为例, 其拥有一个操作数和一个结果值, 只要保证操作数的类型和结果类型相匹配即可, 例如: 可将integer赋值给integer variable, 但不能将structure赋值给integer variable.
操作数类型和结果类型之间的关系, 可用表格来定义, 也可用一个规则来规定, 例如: 在Java中, 两个不同精度的integer相加时, 结果类型为精度更高的integer类型. 类型推断规则也可指出程序中的类型错误, 例如: 混合类型表达式在很多语言中都是非法的, Java中无法将integer赋值给character. 一些语言还要求compiler自动执行隐式类型转换, 例如: Java中, 对于integer和floating-point的相加操作, 会强制进行隐式类型转换, 将精度较低的integer转换为精度较高的floating-point. 但若赋值操作中, 左值精度低于右值精度, 则会产生类型错误.

#### 2.2.5 Declaration and Inference
大部分语言都规定: declare before use(先声明后使用), 每个变量都必须有明确定义的类型. 这也要求compiler需要一种方式标注每个常量的类型, 常见的方法有两种:
1. 常量类型本身包含类型: 2是integer, 2.0是floating-point
2. 从常量的上下文来推断类型: **sin(2)**中的2应为floating-point, 而**x=2**中则根据x的类型来推断2的类型

#### 2.2.6 Infer Types for Expressions
类型推断的目的在于为程序中每个表达式分配一个类型. 为了让parse tree中的每个子节点都被分配类型, 需要声明每个变量, 为所有常量推断类型, 获得所有函数的类型信息. 理论上, compiler可按照post-order来遍历parse tree, 并为每个表达式分配一个类型. 若存在违反类型推断规则的语句, 则报错; 若语言本身无法进行类型推断, 则需要将类型推断推迟到运行时.

#### 2.2.7 Interprocedural Aspects pof Type Inference
表达式的类型推断依赖于其他过程, 即使是最简单的类型系统, 表达式也会包含函数调用. Compiler必须检查每个调用, 确保actual parameter和formal parameter类型兼容, 并确保返回值类型, 以供下一步推断使用. 
为理解函数调用过程, compiler需为每个函数分配一个type signature(类型签名). 以C语言为例, strlen()的操作数类型为char*, 返回值类型为int, 其function prototype(函数原型)如下:
```c
unsigned int strlen(const char *s);
```
该原型声明strlen可接受一个类型为char*的不可变参数, 并返回一个非负integer. 为执行准确的类型推断, compiler需获得每个函数的type signature, 以下是几种常见的获取方式:
1. 取消separate compilation(分离编译), 让整个程序作为一个单元来编译
2. compiler可要求程序员为每个函数提供一个type signature
3. compiler可将类型检查推迟到link或runtime, 这样可保证检查时获得所有信息
4. 将compiler嵌入到程序开发系统中, 以此获得更多的信息


