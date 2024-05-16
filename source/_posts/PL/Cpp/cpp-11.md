---
title: C++ 11
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: 2c50cec5
date: 2018-07-01 08:19:31
---

## 1. __cpluscplus
在C++11中, `__cpluscplus`宏定义的值不同于之前的值.


## 2. lvalue, rvalue, xvalue
1. 左值(lvalue): 可取地址, 有名字的对象
2. 右值(rvalue): C98中定义为临时变量值
3. 纯右值(pvalue): C++11引入的新语义, 包括字面值和不具名的临时对象(例如: 1, false, ++i, a+b, a==b等)
4. 将亡值(xvalue): C++11随引入右值引用而引入的新语义, 一个生命周期即将结束的对象都可以称为将亡值

C++11之前有引用(reference), C++11将引用拆分为两种:
1. 左值引用(lvalue reference): 与之前的引用定义相同, 为具名变量值的别名(alias)
2. 右值引用(rvalue reference): 右值的引用, 右值不存在名称, 所以只能通过其引用查找(匿名变量值的别名)

```cpp
int a1 = 1;
int& b1 = a1;     // lvalue reference
const int& c = 2;   // rvalue reference, 必须为const
const int a2 = 2;
const int& b2 = a2; // lvalue reference, 必须为const
```

左值不能直接绑定到右值引用上, 必须使用std::move()将左值转换为右值
```cpp
int a = 1;
int&& b = std::move(a); // rvalue reference, 不需要const, 因为是左值转换的右值
b = 2; // 将a的值改为2
```

以下是引用绑定的规则:

reference type |  non-const lvalue | const lvalue | non-const rvalue | const rvalue
----- | ---- | ---- | ---- | ---- 
non-const lvalue reference | Y | N | Y | Y 
const lvalue reference | Y | Y | Y | Y 
non-const rvalue reference | N | N | Y | N
const rvalue reference | N | N | Y | Y


## 3. decltype
用于查看实例或表达式的类型, decltype不会计算表达式的结果, 只会返回表达式结果的类型. 
1. 如果e是一个没有括号的标记符表达式(id-expression)或类成员访问式(class member access expression), 则decltype(e)就是e所命名的的类型(id-expression: 除去关键字和字面量等编译器所需的标记外, 程序员定义的标记)
```cpp
int a = 1;
int arr[5] = {0};
int* p = arr;
struct S{double d;}s;

decltype(p) x;    // x的类型为int*
decltype(a) y;    // y的类型为int
decltype(arr) z;  // z的类型为int
decltype(s.d) m;  // m的类型为double
```
2. 否则, 假设e的类型为T, 若e为将亡值, 则decltype(e)为T&&
```cpp
int&& Func();
decltype(Func()) x = 1; // x的类型为rvalue reference(int&&)
```
3. 否则, 假设e的类型为T, 若e为左值, 则decltype(e)为T&
```cpp
int a = 1;
decltype((a)) x = a; // x的类型为non-const lvalue reference(int&)
```
4. 否则, 假设e的类型为T, 则decltype(e)为T
```cpp
int i = 1;
bool Func();
decltype(1) x = 1; // 1为pvalue, 所以x的类型为int
decltype(i++) y = 1; // i++为pvalue, 所以y的类型为int
decltype(Func()) z = true; // Func()为pvalue, 所以z的类型为bool
```


## 4. auto
功能上与decltype相同, 通过表达式来推断数据类型.

### 4.1 auto与decltype的不同之处
1. 基本类型
```cpp
int i = 1, &l = i;
auto x = 1;   // x的类型为int
auto y = i;   // y的类型为int
```
2. const, volatile和reference都不能自动推导, 必须显式声明
```cpp
int i = 1, &l = i;
auto t1 = l;    // t1的类型为int
auto& t2 = i;   // t2的类型为i的lvalue reference
auto p1 = &i;   // p1的类型为int
auto* p2 = &i;  // p2的类型为pointer to i
auto&& r1 = i;  // r1的类型为i的lvalue reference
auto&& r2 = std::move(i);  // r2为i的rvalue reference
// auto m = 1, n = 2.0;    // error, m和n类型不同
```
3. 顶层const和底层const
```cpp
const int i = 1;
auto a = i;       // a的类型为int, 摘除了顶端const
const auto b = i; // b的类型为const int, 需要指出顶层const
auto* c = &i;     // c的类型为const int*, 顶层const不被摘除
```
4. 数组会自动推导为指针
```cpp
int i[10];
auto p1 = i;  // p1的类型为int*
auto& p2 = i; // p2的类型为int[10]
```

### 4.2 auto的主要用途
1. 用于代替冗长复杂的变量声明
```cpp
std::vector<std::string> vs;
// 使用auto代替std::vector<std::string>::iterator
for (auto i = vs.begin(); i != vs.end(); i++)
{
  //..
}
```
2. 定义模板函数时，用于声明依赖模板参数的变量类型
```cpp
template <typename T1, typename T2>
void Multiply(T1 x, T2 y)
{
  auto v = x * y; // 如果不用auto, 很难定义v的类型
}
```
3. 模板函数依赖于模板参数的返回值
```cpp
// auto在这里只是一个占位符, 真正的返回值类型定义在decltype
template <typename T1, typename T2>
auto multiply(T1 x, T2 y) -> decltype(x * y)
{
  return x * y;
}
/*
 * 之所以不定义为: 
 * template <typename T1, typename T2>
 * decltype(x * y) multiply(T1 x, T2 y)
 * {
 *   return x * y;
 * }
 * 是因为decltype中的x和y还没定义, 会报编译错误
 */
```


## 5. Control of member function
C++有四种特殊的成员函数(member function):
1. default constructor(默认构造函数)
2. copy constructor(拷贝构造函数)
3. copy assignment operator(拷贝赋值运算符)
4. destructor(析构函数)

如果没有显式声明这些函数, 编译器会生成默认的对应成员函数. C++11通过添加两个specifier来控制这四个成员函数:
1. =default
2. =delete

```cpp
template<class T>
class Handle {
private:
  T* p;
public:
  Handle(T* pp): p(pp) {}
  ~Handle() = default;  // default destructor semantics

  Handle(const Handle& h) = delete; // disable copying
  Handle(Handle&& h): p(h.p) {  // allow moving    
    std::cout << "move constructor" << std::endl;
    h.p = nullptr;
  }

  Handle& operator=(Handle&) = delete;  // disable copying
  Handle& operator=(Handle&& h) {  // allow moving
    std::cout << "move assignment" << std::endl;
    delete p;
    p = h.p;
    h.p = nullptr;
    return *this;
  }
};

int main() {
  int* p1 = new int(1);
  Handle<int> h1(p1);
  Handle<int> h2(std::move(h1));  // move constructor
  // Handle<int> h3(h1);  // error, no default copy constructor

  int* p2 = new int(2);
  Handle<int> h4(p2);
  h4 = std::move(h1);  // move assignment
  // Handle<int> h5 = h1; // error, no default copy assignment   
}
```


## 6. Uniform initialization
### 6.1 诞生原因
1. 在C++03中, 只有类成员变量才能用Member initializer lists(成员初始化列表)进行初始化, C++11扩大了初始化列表的适用范围, 并支持列表初始化方法:
```cpp
int v1 = 0;   
int v2(1);    // ()和=本质上没有区别
int v3{3};    // list initializer, 列表初始化
int v4 = {4}; // 同上
```
2. 对于某些特殊类型, 不能使用某种方式来初始化
  1. C++11引进了atomic原子类型, 这种类型的变量无法使用=来初始化
  ```cpp
  std::atomic<int> v1{1};
  std::atomic<double> v2(2.0);
  // std::atomic<float> v3 = 3.0f;  // error
  ```
  2. 对于类中的非静态成员变量, 设置默认值不能使用()
  ```cpp
  class C1 {
  private:
    int v1 = 1;
    int v2{2};
    // int v3(3);  // error
  };
  ```
  3. 调用自定义类的无参数构造函数时, 会被编译器解释为函数声明
  ```cpp
  C1 c1();   // empty parentheses interpreted as a function declaration
  // c1.v = 2; // error: expression is not assignable
  C1 c2{};
  c2.v = 2;
  ```
  4. 初始化容器时会产生歧义
  ```cpp
  std::vector<int> v1{10};  // the size of v1 is 1
  std::vector<int> v2(10);  // the size of v2 is 10
  ```
  5. 如果存在类型收窄的情况, 则编译器不会报错. 而列表初始化可以避免这个问题
  ```cpp
  double d = 3.1415926;
  int i1(d);      // i1为3
  int i2 = d;     // i2为3
  // int i3{d};   // error, type 'double' cannot be narrowed to 'int'
  // int i4 = {d};// error, type 'double' cannot be narrowed to 'int'
  ```

由此可见, 列表初始化**{}**成为适用面最广的初始化方法, 并且在某些方面优于=和(), 从而被称为统一初始化(Uniform initialization)

### 6.2 存在的问题
列表初始化在绝大多数情况下都能很好的运行, 但当遇到initializer_list时会产生很多问题: 当使用{}调用构造函数时, 会优先调用initializer_list为参数类型的构造函数(无参数构造函数除外)
```cpp
class C1
{
public:
  C1();
  C1(bool, int);
  C1(std::initializer_list<bool>);
};

C1 c1{};            // call C1()
C1 c2{true, 1};     // call C1(std::initializer_list<bool>), convert 1 to true
C1 c3{true, 0};     // call C1(std::initializer_list<bool>), convert 0 to false
// C1 c4{true, 2};  // error, call C1(std::initializer_list<bool>), cannot narrow 2 to bool
```


## 7. Initializer lists
### 7.1 诞生原因
C++03继承了C语言的initializer-list特性, 只含有POD(Plain Old Data)的class和struct都可以通过initializer-list来初始化
```cpp
class C1
{
private:
  float f;
  int i;

public:
  C1(float f, int i)
  {
    this->i = i;
  }
};

struct S1
{
  float f;
  int i;
};

C1 c1 = {1.0, 2};
S1 s1 = {1.0, 2};
```
C++11扩大了initializer-list的适用范围: 所有class都可以使用initializer-list初始化(包括standard container)
```cpp
std::vector<std::string> v1{"123", "456"};
std::vector<int> v2 = {1, 2, 3};
std::vector<double> v3({1.0, 2.0, 3.0});
```


## 8. long long int
在C++03中最大的整型为**long int**, long int的长度范围为[32, 64], 所以每个编译器的实现都不同. C++11中引入了**long long int**, 其长度不会低于64位.


## 9. constexpr
C++一直就有常量的概念, 例如const. 但const的意义在于不可修改, 而没有强调常量的另一个特点: 可在编译期计算并获得结果. C++11引入了constexpr来描述一个可在编译期评估的variable, function和constructor

### 9.1 constexpr varible的条件
1. 数据类型必须为LiteralType
2. 必须被立即初始化
3. 初始化表达式(initialization expression)必须为常量表达式(constant expression)

```cpp
constexpr int v1 = 1;
constexpr double v2{1.0};
constexpr int v3;         // error, not initialized
int i = 0;
constexpr int v4 = i + 1; // error, i isn't a constant expression
```

### 9.2 constexpr function的条件
1. return type和parameter type必须是LiteralType
2. 只包含一个return语句(非error, warning)
3. function body可以包含其他的语句，但是这些语句不能在运行期起作用
4. function body不能包含一些语句, 例如: goto, try-catch, asm之类的语句
5. 可以是内部递归调用(recursive)
6. 不能为virtual function

```cpp
// constexpr function默认为inline function
constexpr int f(int x)
{
  return x == 1 ? 1 : 0;
}
```

### 9.3 constexpr constructor 
1. constructor的参数类型为LiteralType
2. class不能有虚基类(virtual base class)
3. constructor不能含有try-block
4. constructor可包含以下语句: 空语句, static_assert, typedef, using
5. 对于constructor所在的class, 其对象必须初始化


## 10. nullptr
### 10.1 诞生原因
首先我们必须知道, C和C++中的NULL并不相同:
```cpp
#ifndef NULL
  #ifdef __cplusplus
    #define NULL  0
  #else  /* __cplusplus */
    #define NULL  ((void *)0)
  #endif  /* __cplusplus */
#endif  /* NULL */
```
C中将NULL定义为((void*)0), 而C++将NULL定义为0. C++之所以将NULL修改为0, 是因为void*的隐式转换属性: 既可以指向任意类型指针, 又可转换为int类型
```c
#include <stdio.h>

void f1(int *p){};
void f2(int i){};

f1(NULL); // void*可指向任何类型的指针
f2(NULL); // void*也可转换为int类型
```
C++支持函数重载, 而void*会导致歧义, 所以就改用了0来表示NULL. 但由于NULL仍然没有类型, 所以还是会导致很多问题:
```cpp
void f(char *);
void f(int);

f(NULL); // 可能编译失败, 也可能调用f(int)
```

### 10.2 nullptr的属性
C++11正式引入nullptr, 并为nullptr赋予了一个独有的类型: nullptr_t. 其可以转换为其他指针类型和bool类型(为了兼容指针作为if判断的条件)
```cpp
int *p1 = nullptr;
char *p2 = nullptr;
bool b = nullptr; // 会转换为false
int i = nullptr;  // error, cannot convert nullptr_t to int
```
正因为有了类型, 空指针也可以用来捕获异常
```cpp
#include <iostream>
#include <cstddef>

int main()
{
  try
  {
    throw nullptr;
  }
  catch (std::nullptr_t p)
  {
  }
}
```


## 11. Delegating constructors
### 11.1 诞生原因
C++一直没有提供构造函数的委托机制(delegating constructor), 这导致不提供使用缺省参数, 也使得程序员必须维护多个构造函数, 且构造函数之间的代码大量冗余.
```cpp
class X
{
private:
  int i_;

public:
  X()
  {
    // dosomethingelse
  }

  X(int i) : i_(i) // 编译不报错, 为undefined behavior
  {
    X();
  } 
};
```

### 11.2 delegating constructors
C++11引入委托构造函数, 这样类内的其中一个构造函数(称为委托构造函数, delegating constructor)能在初始化列表(initializer list)中调用另一个构造函数(称为目标构造函数, target constructor). 当然, 委托构造函数也可被其他构造函数调用.
```cpp
class X
{
private:
  int i_;

public:
  X(int i): i_(i) {}  // target constructor
  X(): X(42) {}       // delegating constructor
};
```

### 11.3 需要注意的问题
1. delegating constructor最多只能调用一个target constructor, 且不能在调用target constructor时进行成员初始化
```cpp
class X
{
private:
  int i_;

public:
  X(int i) : X(), i_(i) {} // error, an initializer for a delegating constructor must appear alone
  X() {}
};
```
2. delegating constructor的递归调用是undefined behavior
```cpp
class X
{
public:
  X(int i): X() {} // 可能报错, 也可能不报错
  X(): X(42) {}
};
```
3. target constructor中的语句执行完才会执行delegating constructor中的语句; target constructor中的临时变量不会作用到delegating constructor中
4. C++03中一个object声明周期开始的标志为constructor执行完毕, C++11修改了这一规定: object生命周期开始的标志为其中一个constructor执行完毕. 因为C++03中并没有委托机制, 所以整个初始化只有一个constructor在执行; 而C++11中引入了委托机制, 所以初始化过程中不止一个constructor执行. 这样保证一旦初始化抛出异常, 会自动调用析构函数.
5. template delegating constructor的类型推导不变
```cpp
class X
{
private:
  template <typename T>
  X(T begin, T end) : l_(begin, end) {}
  std::list<int> l_;

public:
  X(std::vector<char> &);
  X(std::deque<int> &);
};

X::X(std::vector<char> &v): X(v.begin(), v.end()) {}
X::X(std::deque<int> &d): X(d.begin(), d.end()) {}

int main()
{
  std::vector<char> v{'a', 'b', 'c'};
  std::deque<int> d{1, 2, 3};
  X x1{v};
  X x2{d};
}
```


## 12. Explicit virtual overrides
### 12.1 诞生原因
C++中的重写存在两个问题:
1. C++中重写(override, 子类重写父类相同函数名和参数的virtual function)和重定义(redefine, 子类重定义父类相同函数名的non-virtual function)比较相似, 且编译器不会提醒你是否在重写/重定义.
```cpp
class Base
{
  virtual void func(int)
  {
  }
};

class Derived: public Base
{
  void func() // 本想重写, 结果变成了重定义
  {
  }
};
```
2. 当修改base class的virtual function的函数名或参数时, 程序员可能忘记修改derived class中的override function
```cpp
class Base
{
public:
  virtual void func(double) // func(int) -> func(double)
  {
  }
};

class Derived: public Base
{
public:
  void func(int) // 忘记修改子类中func的参数类型
  {
  }
};
```

### 12.2 override关键字
C++11引入override关键字保证derived class中函数能够成功地重写base class中拥有相同签名的虚函数(相同的函数名和参数列表), 否则编译错误.
```cpp
class Base
{
public:
  virtual int func() const
  {
    return 0;
  }
};

class Derived: public Base
{
public:
  void func() override // error, doesn't override any member functions
  {
  }

  int func() const override
  {
    return 1;
  }
};
```


## 13. Final specifier
### 13.1 诞生原因
override关键字解决了明确表示函数重写的问题, 但这也诞生了一个新的问题: 如何避免子类重写父类的函数
```cpp
class AbstractLibrary
{
private:
  virtual int func() = 0;
};

class Library: public AbstractLibrary
{
private:
  int func() override // Library不想让用户重写该函数
  {
  }
};

class User: public Library
{
private:
  int func() override // User成功重写了Library中的函数
  {
  }
};
```

### 13.2 final关键字
C++11引入final关键字来让防止父类的函数被子类重写
```cpp
class AbstractLibrary
{
private:
  virtual int func() = 0;
};

class Library: public AbstractLibrary
{
private:
  int func() override final
  {
  }
};

class User: public Library
{
private:
  int func() override // error, cannot overrides a 'final' function
  {
  }
};
```


## 14. extern template
### 14.1 分离式编译
C++支持分离式编译(分别编译项目中的各个源文件, 生成目标文件, 最后链接成可执行文件, 这种编译方式更适合模块化开发, 且编译速度更快). 但分离式编译并不适用于template, 原因如下:
1. 分离式编译之所以能实现, 是因为每个编译单元(translation unit)中的非模板类和函数在编译阶段都会生成二进制码
```cpp
/********** test.cpp **********/
#include <iostream>
int f()
{
  return 1;
}

/********** main.cpp **********/
#include <iostream>

extern int f();

int main()
{
  int i = f();
}
```
2. 一个template要想具现成二进制码, 不仅需要template的声明, 更需要其中函数定义的实现. 所以C++不支持通过template声明来隐式实例化一个template
```cpp
/********** test.cpp **********/
template <typename T>
class C
{
  public:
  T f(T);
};

/********** test.cpp **********/
#include "test.h"

template <typename T>
T C<T>::f(T x)
{
  return x;
};


/********** main.cpp **********/
#include "test.h" // test.h中没有template中函数的实现

int main()
{
  C<int> *pc = new C<int>(); // 编译器无法具现一个类型为int的template, 链接时报错
  int i = pc->f(1);
}
```
有两种解决方法: 将template的声明和实现放在一起, 或**显示实例化**(explicit instantation)一个类型为int的template, 这样编译器才会具现化其二进制码.
```cpp
/********** test.cpp **********/
#include "test.h" // test.h中的内容不变

template <typename T>
T C<T>::f(T x)
{
  return x;
};

template class C<int>; // explicit instantation

/********** main.cpp **********/
#include "test.h" // test.h所链接的test.cpp已经有一个类型为int的template实例

int main()
{
  C<int> *pc = new C<int>();
  int i = pc->f(1);
}
```

### 14.2 模板分离式编译导致的问题
当多个源文件使用同一个类型的同一template时, 编译时会隐式实例化每个源文件中的template, 并生成该类型template的二进制码, 而在链接时又会移除多余的实例化二进制码. 因此C++11引进了extern template来防止编译器生成冗余的二进制码, 从而加快编译和链接速度
```cpp
/********** test.cpp **********/
template <typename T>
class C
{
public:
  T f(T x)
  {
    return x;
  };
};

/********** use1.cpp **********/
#include "test.cpp"
C<int> *p1 = new C<int>(); // 隐式实例化, 生成一个可用的template实例

/********** use2.cpp **********/
#include "test.cpp"
extern template class C<int>; // 其他源文件已经生成了int类型的template实例, 告诉编译器不需要实例化
C<int> *p2 = new C<int>();
```


## 15. Range-based for loop
C++11对for语句进行了扩展， 使得程序员能更简单的遍历list和container
```cpp
int arr[5] = { 1, 2, 3, 4, 5 };
for (auto& x: arr) {
  std::cout << x << std::endl;
}
```
C风格的array， initializer list和STL中的container都可以使用range-based for来遍历元素. 其他还有begin()和end()的类型也可以使用range-based for.


## 16. Lambda functions and expressions
C++11提供了匿名函数的创建方法， 也称为lambda funtion(或lambda expression)
```text
[Capture Clause](Parameter List) mutable throw() -> return_type { Function Body }
```
lambda expression有以下几个部分组成:
1. Capture Clause
Lambda支持使用cpture clause从当前范围内导入变量, 引入的方式可使用值传递和引用传递
  1. []: Capture nothing
  2. [&]: Capture any referenced variable by reference
  3. [=]: Capture any referenced variable by value
  4. [=, &foo]: Capture any referenced variable by value except **foo**
  5. [bar]: Capture bar by value and don't caputure anyone
  6. [this]: Capture the pointer of the enclosing class
2. Parameter List
除了从外部引入变量, 还可以接受输入的参数. 参数也可使用值传递和引用传递
```cpp
int total = 0;
std::vector<int> vec = {1, 2, 3, 4, 5};
std::for_each(std::begin(vec), std::end(vec), [&total](int& x) {
  total += x;
});
```
3. mutable关键字
当lambda使用值传递时, 默认会有const限制. 可用mutable取消限制
```cpp
int i = 0;
auto f1 = [i]() { return ++i; }; // error, **total** is read-only variable
auto f2 = [i]() mutable { return ++i; }; // it works
```
4. Throw
Lambda支持异常处理
```cpp
[]()throw () { /* code that you don't expect to throw an exception*/ }
```
5. Return Value
  1. 若无返回值, 则默认返回类型为void
  ```cpp
  []{ std::cout << "Hello, World"; }; // 返回类型为void
  ```
  2. 若有返回值, 编译器会通过return statement的类型推到返回类型; 但如果编译器无法推导出返回类型, 则会默认返回类型为void
  ```cpp
  auto f1 = [](int x, int y) { return x + y; }; // 返回类型为int
  // auto f2 = []() { return { 1, 2 }; }; // error, deduce return type from braced-list is not valid
  auto f3 = []() -> std::initializer_list<int> { return { 1, 2 }; };
  ```


## 17. Strongly typed enumerations
### 17.1 诞生原因
C语言已经存在枚举类型(enum), C++为了兼容C自然也引入了枚举. 枚举提供了一种生成多个#define常量的功能, 并且相对于#define来说作用域更小.
```c
#define Right 1
#define Left 2
/* equal to */
enum E1
{
  Right = 1,
  Left
};
```
但枚举存在以下问题:
1. enum中枚举量(enumerator)暴露在外层作用域中, 因此一个作用域下的不同枚举不能有相同的枚举量
```cpp
enum E1
{
  Right = -1
};

enum E2
{
  Right = 1 // error, redefinition of enumerator 'Right'
};
```
2. 无法确定enum的大小, 虽然C++允许编译器使用任意整型类型来表示枚举量, 且没有规定是否有符号(signedness)
```cpp
enum Selection
{
  Multiple = 0xFFFF0000U // 根据编译器不同得出不同结果
};
```
3. enum中的枚举量为整型常量, 所以可以进行各种隐式转换(implicit conversion):
```cpp
enum E1
{
  Right = 1,
  Left
};

enum E2
{
  Right_ = 1,
  Left_
};

if (Right); // 隐式转换为boolean
double i = Right; // 隐式转换为double
if (E1::Right == E2::Right_); // 与其他enum的枚举量对比
```

### 17.2 强类型枚举
Strongly-typed enumeration含有以下属性:
1. 若不声明类型, 则默认为int类型; 也可声明类型, 但必须为整形类型(bool, char, short, int, long), 且不限有无符号(signed, unsigned)
```cpp
enum class E1
{
  Right = -1
};
size_t size1 = sizeof(E1); // E1的大小为4

enum class E2 : long long int
{
  Right = -1
};
size_t size2 = sizeof(E1); // E2的大小为8
```
2. enum中的枚举量必须在其命名空间(namespace)内使用, 不可直接作用于外部作用域
```cpp
enum class E1
{
  Right
};
E1 r1 = Right; // error, undeclared identifier
E1 r2 = E1::Right;
```
3. enum中的枚举量不能隐式转换为POD(Plain Old Data), 但可以使用static_cast或强制转换为POD. 也不能与其他enum中的枚举量对比
```cpp
enum class E1
{
  Right
};

enum class E2
{
  Right
};

int r1 = E1::Right; // error, E1 cannot be converted to int
int r2 = static_cast<int>(E1::Right);

if (E1::Right == E2::Right); // error
if ((int)E1::Right == (int)E2::Right);
```


## 18. Unrestricted unions
C++03允许union中包含non-static类对象, 但其class中不能有自定义的non-trivial special emmeber functions(包括constructor, destructor, copy constructor, copy-assignment operator)
```cpp
class C1
{
  private:
  int _x;

  public:
  C1() = default;
  C1(const C1 &c) = default;
  C1 &operator=(const C1 &) = default;
  ~C1() = default;
};

union U1 {
  C1 c; // it works
};

int main()
{
}
```
C++11中移除了这个限制, 但依然不允许union中包含类对象的引用
```cpp
class C1
{
  private:
  int _x;

  public:
  C1()
  {
    _x = 1;
  }
};

union U1 {
  C1 c; // it works
};

union U2 {
  C1 &c; // error, union memeber has reference type
};
```


## 19. Template aliases
C++可以用typedef关键字来为类型和函数定义别名(alias), 但并不支持为template起别名. C++11中支持了template alias(模板别名)
```cpp
#include <iostream>

template <typename T>
class C1 {};

using C2 = C1<int> *; // C2为C1<int>*类型的别名

int main()
{
  C2 p = new C1<int>();
}
```


## 20. New string literals
C++03中提供了两种string literal(字符串字面量)来表示宽字符: **wchar_t**和**L**
```cpp
const wchar_t c = L'a'; // wchar_t为2字节长度
```
C++11中引入了两种字符类型来表示16位和32位长度的字符: **char16_t**和**char32_t**, 还引入了三种字符串前缀标志来表示UTF-8, UTF-16和UTF-32: **u8**, **u**, **U**
```cpp
const char *s1 = u8"abc";
const char16_t *s2 = u"abc";
const char32_t *s3 = U"abc";
```
