---
title: C++ vs. Java
category:
  - Programming Language
  - Java
tag:
  - Programming Language
abbrlink: 9f80
date: 2017-10-22 14:40:40
---

## 1. main函数
1. Java中main函数必须是public和static, 并且不需要返回值
2. C++不需要main函数在类中定义为public或static, 但需要返回值


## 2. 类型大小
1. Java的int整型大小与目标机器或操作系统无关. int为4字节, short为2字节, float为4字节, double为8字节
2. C++的int大小与目标机器或操作系统有关, 但int必须大于或等于short大小(>=4字节)


## 3. bool类型的隐式转换
1. Java中不允许其他类型转换为boolean值
```java
boolean x=true;
if(x==0){   /* error, cannot convert int to boolean */
  // ...
}
```
2. C++中允许整数类型转为bool值


## 4. 未初始化操作
1. Java中不区分变量的声明与定义, 所以一个未初始化的变量不能输出或作为右值
2. C++中区分声明与定义, 可以输出或赋值未初始化的变量


## 5. >>操作
1. Java中>>使用符号位填充高位(算数移位)
2. C++中>>不确定为算数移位(符号位填充高位)还是逻辑移位(0填充高位)


## 6. 逗号运算符
1. Java不支持逗号运算符
2. C++的逗号运算符可支持多表达式顺序执行, 运算优先级最低


## 7. String
1. Java将String定义为不可变对象, 这样就可使得多个相同内容的字符串共享一个对象, 但代价就是修改字符串操作变得复杂. String并没有重载==操作符, 所以判断两个String是否相等要通过equals函数实现.
2. C++的std::string为可变字符串, 支持修改. 两个std::string可用==判断是否相等, 因为std::string已经重载了==操作符.


## 8. 嵌套定义
1. Java中不可在嵌套块中重定义一个变量
2. C++允许在嵌套块中重定义一个变量


## 9. 运算符重载
1. Java重载了部分类型的运算符(例如String), 但没有给程序员重载运算符的权利
2. C++给程序员重载运算符的权利


## 10. 命令行参数
1. Java只保存了运行文件后的所有参数
2. C++在第一位(args[0])保存了运行文件的名称, 和之后的参数


## 11. new
1. Java中所有类对象只能在堆上生成(也就是说, 只能通过new来生成对象)
2. C++可在堆和栈上生成类对象, 例如:
```cpp
Object x(1);        // Java无法这样创建一个类对象
Object x = new Object(1);
```


## 12. 函数定义
1. Java不能在类外定义函数体, 函数是否inline取决于JVM的决定
2. C++可在类外定义函数体, 且如果在类内定义函数, 则直接视为inline函数


## 13. 方法参数
1. Java的方法传递的都是参数
2. C++可用值传递或引用传递


## 14. 类继承
1. Java使用extends来表示继承关系, 且只有公有继承
2. C++使用:表示继承关系, 且有三种继承方式(public, protected, private)


## 15. 调用父类/超类的关键字
1. Java使用"super"来调用超类的成员
2. C++使用"父类名+::"的方式来调用父类的成员(调用父类的构造函数除外)


## 16. 虚函数
1. Java没有vitrual关键字, 每个类成员函数都具有多态性, 运行时会自动地调用类方法
2. C++使用virtual来指明那些成员函数具有多态性


## 17. 多继承
1. Java不支持多继承(因此不需要virtual继承), 单可使用final关键字阻止子类覆盖父类
2. C++支持多继承, 但没有机制来实现子类覆盖父类


## 18. 抽象函数/抽象类
1. Java支持抽象类, 只要在class和function处声明abstract关键字
```java
abstract class Person{
  publi abstract String getDescription();
}
```
2. C++支持抽象类, 但不需要在class上声明, 只需要在虚函数尾部用**=0**标记
```cpp
class Person{
public:
  virtual string getDescription()=0;
}
```


## 19. protected
1. Java中受保护部分为本包和所有子类, 安全性更差
2. C++中受保护部分为本类和所有子类


## 20. Vector
1. Java中的ArrayList, 但ArrayList没有重载**[]**, 并且进行赋值操作时传递的是引用 (两个ArrayList指向的是同一个实体)
2. C++中vector重载了**[]**, 但赋值操作时进行的是值传递 (两个vector互不影响)


## 21. getClass()
getClass()返回当前运行时的类对象的Class, getSuperclass返回父类的Class
```java
package test;
import java.util.*; 

public class SuperTest extends Date{ 
  private static final long serialVersionUID = 1L; 
  private void test(){ 
    System.out.println(super.getClass().getName());     // test.SuperTest
    System.out.println(this.getClass().getName());      // test.SuperTest
    System.out.println(super.getClass().getSuperclass());   // class java.util.Date
  }

  public static void main(String[] args){ 
    new SuperTest().test(); 
  } 
}
```


## 22. 二维数组申请
C++固定[]必须在数组变量名后, 且第二个[]必须写明数字
```cpp
// int a[3][] = {1,2,3,4,5,6};  // error
int a[][3] = {1,2,3,4,5,6};
```
Java不规定[]的位置, 但第一个[]必须有数字
```java
float f[][] = new float[6][6];
float []f[] = new float[6][6];
float [][]f = new float[6][6];
float [][]f = new float[6][];
```


## 23. 数组长度
1. C++中声明数组时必须说明数组长度
```cpp
int a[50];
// int a[]; // error
```
2. Java中声明数组不能说明数组长度, 只有实例化对象时才能给定数组长度
```java
String a[];
// String a[50];    // error
```


## 24. 函数重载
C++和Java的重载定义相同:
* 方法名称相同, 参数个数, 次序或类型不同
* 返回值类型与重载无关
