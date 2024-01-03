---
title: JVM (1)
tags:
  - Java
category:
  - Java
  - JVM
abbrlink: f4a1
date: 2017-11-06 08:58:48
keywords:
description:
---

## 1. Java源码级编译器的功能
1. 源代码
2. 词法分析器
3. Token流
4. 语法分析器
5. 语法树/抽象语法树
6. 语义分析器
7. 注解抽象语法树
8. 字节码生成器
9. JVM字节码


## 2. Java的处理方式
1. Java程序源码
2. 源码 -> Java源码级编译器 -> Class文件
3. Class文件 -> 类加载器 -> Class的内部表示
4. Java虚拟机的解释器/编译器
    1. JIT编译器
        1. 机器无关优化
        2. 机器相关优化
        3. 寄存器分配器
        4. 目标代码生成器 
    2. 字节码解释器


## 3. Java平台
1. JVM: 执行符合规范的class文件
2. JRE: 包括JVM与类库
3. JDK: 包含JRE和一些开发工具, 如javac


## 4. Java源码级编译器
功能: 将符合Java语言规范的源码编译为符合Java虚拟机规范的Class文件
1. Sun的JDK中使用javac(Java编写)
    1. JDK 1.3后不支持-O优化参数, 因为已将优化移至编译器后端
    2. JDK 1.4.2后不再使用jsr/ret指令实现finally语句
    3. JDK 1.5后泛型的实现通过GJC(Generic Java Compiler)
2. 其他Java源码级编译器: Eclipse Compiler for Java, Jikes


## 5. javac工作流程
1. 解析(parse)
2. 输入到符号表(enter)
3. 注解处理(annotation processing)
4. 分析与代码生成
    1. 属性标注与检查(Attr与Check)
    2. 数据流分析(Flow)
    3. 将泛型类型转换为裸类型(TransType)
    4. 解除语法糖(Lower)
    5. 生成Class文件(Gen)


## 6. parse
### 6.1 词法分析
1. 使用com.sun.tools.javac.parser.Scanner
2. ad-hoc方式构造的词法分析器
3. 根据词法将字节序列转换为token序列
```java
int y = x + 1;
/* name: int, Token.INT
 * name: y  , Token.IDENTIFIER
 * name: =  , Token.EQ
 * name: x  , Token.IDENTIFIER
 * name: +  , Token.PLUS
 * stringVal: 1, Token.INTILITERAL
 * name: ;  , Token.SEMI
 */
```

### 6.2 语法分析
1. com.sun.tools.javac.parser.Parser
2. **递归下降**+**运算符优先级式**语法分析器
3. 根据语法由token序列生成抽象语法树
4. 之后步骤在抽象语法树上进行
```java
int y = x + 1;
/* JCVariableDecl 
 *    - JCPrimitiveTypeTree(vartype): typetag: 4(int)
 *    - Name(name): y
 *    - JCBinary(init): tag: 69(+)
 *      - JCIdent(lhs)
 *        - Name: x
 *      - OperatorSymbol(operator): + (int, int)
 *      - JCLiteral(rhs): 1
 */
```


## 7. 将符号输入到符号表(enter)
### 7.1 实现工具
com.sun.tools.javac.comp.Enter

### 7.2 处理步骤
* 每个编译单元的抽象语法树的顶层节点都先被放到待处理列表中
* 逐个处理列表中的节点
* 所有类符号被输入到外围作用域癿符号表中
* 若找到package-info.java，将其顶局树节点加入到待处理列表中
* 确定类的参数(对泛型类型而言), 超类型和接口
* 根据需要添加默认构造器
* 将类中出现的符号输入到类自身的符号表中
* 分析和校验代码中的注解(annotation)

```java
public class CompilerTransformationDemo {}  /* 完成类定义前 */

public class CompilerTransformationDemo {   /* 完成类定义后 */
  public CompilerTransformationDemo() {
    super();
  }
}
```


## 8. annotation processing
### 8.1 使用工具
com.sun.tools.javac.processing.JavacProcessingEnvironment

### 8.2 功能: 支持用户自定义的注解处理
* JSR 269进入该功能(Java 6)
* 可读取语法树中任意元素(包括注释)
* 可以改变类型定义
* 可以创建新的类型


## 9. 标注(Attr)和检查(Check)
### 9.1 使用工具
* com.sun.tools.javac.comp.Attr
* com.sun.tools.javac.comp.Check

### 9.2 功能
* 将语法树中名字, 表达式等元素与变量, 方法, 类型等联系到一起
* 检查变量使用前是否已声明
* 推导泛型方法的类型参数
* 检查类型匹配性
* 进行常量折叠

```java
public class CompilerTransformationDemo {
  private static final String NAME = "DEMO";
  private String instanceName = NAME + "ins" + 0;
}

/*
标注前:
JCBinary: tag: 69 (+)
  - JCBinary(lhs): tag: 69 (+)
    - JCIdent(lhs)
      - Name(name): NAME
    - JCLiteral(rhs): value: ins
  - JCLiteral(rhs): value: 0

标注后:
JCBinary: type.value: DEMOins0
  - JCBinary(lhs): tag: 69 (+)
    - JCIdent(lhs)
      - Name(name): NAME
    - OperatorSymbol(operator): +(String, String)
    - JCLiteral: value: ins
  - OperatorSymbol(operator): +(String, int)
  - JCLiteral(rhs): value : 0
*/
```

## 10. 数据流分析(Flow)
### 10.1 使用工具
com.sun.tools.javac.comp.Flow

### 10.2 功能: 语义分析的一个步骤
* 检查所有语句都可到达
* 检查所有checked exception都被捕获或抛出
* 检查变量的确定性赋值
  * 所有局部变量在使用前必须赋值
  * 有返回值的方法必须有确定性返回值
* 检查变量的确定性不重复赋值
  * 保证final语义


## 11. 转换类型(TransTypes)
### 11.1 使用工具
com.sun.tools.javac.comp.TransTypes

### 11.2 功能
解除语法糖的一个步骤, 将泛型Java转换为普通Java(同时插入必要的类型转换)

```java
/* 泛型转换前 */ 
public void desugarGenericToRawAndCheckcastDemo() {
  List<Integer> list = Arrays.asList(1, 2, 3);
  list.add(4);
  int i = list.get(0);
}

/* 泛型转换后 */
public void desugarGenericToRawAndCheckcastDemo() {
  List list = Arrays.asList(1, 2, 3);   /* 去除泛型 */
  list.add(4);
  int i = (Integer)list.get(0);  /* 添加类型转换 */
}
```


## 12. 解除语法糖(Lower)
### 12.1 使用工具
com.sun.tools.javac.comp.Lower

### 12.2 功能
* 削除`if(false){...}`形式的无用代码
* 满足下列所有条件的代码则为条件编译的无用代码
  * if语句的条件表达式为Java语言规范定义的常量表达式
  * 常量表达式的值为false, 后续代码则为无用代码. 否则else后为无用代码
* 将含有语法糖的语法树改为含有简单语言结构的语法树
  * 具有内部类/匿名类/类字面量
  * 断言(assertion)
  * 自动装箱/拆箱
  * foreach循环
  * eunm类型的switch
  * String类型的switch(Java 7)
  * 等等

```java
/* Lower之前 */
public class CompilerTransformationDemo {
  public CompilerTransformationDemo() {
    super();
  }
  public void desugarDemo() {
    Integer[] array = {1, 2, 3};
    for (int i : array) {
      System.out.println(i);
    }
    assert array[0] == 1;
  }
}

/* Lower之后 */
public class CompilerTransformationDemo {
  static final boolean $assertionsDisabled = !CompilerTransformationDemo.class.desiredAssertionStatus();
  
  public CompilerTransformationDemo() {
    super();
  }

  public void desugarDemo() {
    Integer[] array = {Integer.valueOf(1), Integer.valueOf(2), Integer.valueOf(3)};
    for (Integer[] arr$ = array, len$ = arr$.length, i$ = 0; i$ < len$; ++i$) {
      int i = arr$[i$].intValue();
      {
        System.out.println(i);
      }
    }
    if (!$assertionsDisabled && !(array[0].intValue() == 1))
      throw new AssertionError();
  }
}
```


## 13. 生成Class文件(Gen)
### 13.1 使用工具
com.sun.tools.javac.jvm.Gen

### 13.2 功能: 
* 将实例成员初始化器收集到构造器中, 成为<init>()
* 将静态成员初始化, 成为<clinit>()
* 从抽象语法树生成字节码
  * 后序遍历语法树
  * 进行最后的少量代码转换, 例如:
    * String的+操作转换为StringBuilder的+
    * x++/x--在条件允许下转换为++x/--x
    * 等等
* 从符号表中生成Class文件
  * 生成Class文件的结构信息
  * 生成元数据(包括常量池)


## 14. Class文件所记录的信息
### 14.1 结构信息
* Class文件格式的版本号
* 各部分的数量与大小

### 14.2 元数据
* 类/继承的超类/实现的接口的声明信息
* 域和方法声明
* 常量池
* 用户自定义的, RetenttionPolicy为Class或Runtime的注解

### 14.3 方法信息
* 字节码
* 异常处理表
* 操作数栈与局部变量区大小
* 操作数栈的类型记录(Java 6后使用StackMapTable)
* 调试用符号信息(如LineNumberTable和LocalVariableTable)

```java
/* Java源码 */
import java.io.Serializable;
public class Foo implements Serializable{
  public void bar() {
    int i = 31;
    if (i > 0) {
      int j = 42;
    }
  }
}

/* 编译后的Class文件结构 */
/*
1. 类声明
public class Foo extends java.lang.Object implements java.io.Serializable

2. 源文件名
SourceFile: "Foo.java"

3. Class文件结构信息
minor version: 0
major version: 50

4. 常量池
const #1 = Method #3.#19; // java/lang/Object."<init>":()V
const #2 = class #20; // Foo
const #3 = class #21; // java/lang/Object
const #4 = class #22; // java/io/Serializable
const #5 = Asciz <init>;
const #6 = Asciz ()V;
const #7 = Asciz Code;
const #8 = Asciz LineNumberTable;
const #9 = Asciz LocalVariableTable;
const #10 = Asciz this;
const #11 = Asciz LFoo;;
const #12 = Asciz bar;
const #13 = Asciz j;
const #14 = Asciz I;
const #15 = Asciz i;
const #16 = Asciz StackMapTable;
const #17 = Asciz SourceFile;
const #18 = Asciz Foo.java;
const #19 = NameAndType #5:#6;// "<init>":()V
const #20 = Asciz Foo;
const #21 = Asciz java/lang/Object;
const #22 = Asciz java/io/Serializable;

5. 方法元数据
public Foo();
  Signature: ()V
  LineNumberTable:
  line 2: 0

  LocalVariableTable:
  Start Length Slot Name Signature
  0     5      0    this LFoo;

  Code:
  Stack=1, Locals=1, Args_size=1

6. 字节码
0: aload_0
1: invokespecial #1; //Method java/lang/Object."<init>":()V
4: return
*/
```
