---
title: C++ Basic (2)
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: d4cf
date: 2017-09-09 14:41:09
---

## 1. delete[]
```cpp
A *pA = new A[5];
delete pA;      // 应写作delete []pA
```
上述代码调用了5次构造函数, 一次析构函数. 因为delete只会析构一个元素, 也就是数组第一个元素. 所以应调用`delete[]`来删除数组中的所有对象


## 2. for loop
`for`有两种语法:
* `for (init-statement condition; iteration-expression)`
* `for (declaration-or-expression; declaration-or-expression; expression)`

上述所有expression和statement都是可选的, 也就是说, 特定情况下我们可选择不填写, 如下:
```cpp
for(expression1 ; ; expression2)
```
相当于
```cpp
for(expression1 ; 1 ; expression2)
```
等同`while(true)`.


## 3. preprocessor
1. preprocessor directives
用于简化源程序在不同的执行环境中的更改和编译
```cpp
/*
 * #include, #using, #import, #error
 * #define, #undef  
 * #if, #else, #ifdef, #ifndef, #elif, #endif
 * #line, #pragma
 */
```

2. preprocessor operators
    1. 字符串化运算符(`#`)
    2. 字符化运算符(`#@`)
    3. 标记粘贴运算符(`##`)
    4. 自定义的运算符
3. preprocessor macros
    1. `__DATE__`: 当前的编译日期
    2. `__FILE__`: 当前源文件名
    3. `__LINE__`: 当前源代码行号
    4. `__STDC__`: 当要求程序严格遵循ANSI C标准时该标识被赋值为1
    5. `__STDCPP_THREADS__`: 多个线程的执行且为C++编译时赋值为1
    6. `__TIME__`: 当前编译时间
4. pragmas: 设定编译器的状态或指示编译器做某些特定动作, 支持多种参数


## 4. Static Binding
对于非虚成员函数, C++采用静态绑定.
```cpp
class B
{
  void Do();
  virtual void vfun();
}

class D : public B
{
  void Do();
  virtual void vfun();
}

D *pD = new D();  // pD的静态类型为D*, 动态类型也为D*
B *pB = pD;       // pB的静态类型为B*, 动态类型为D*
```
* `pD->Do()`和`pB->Do()`调用的是各自的函数, 因为绑定的静态类型不同
* 虚函数使用**dynamic binding**(动态绑定)确定调用哪个函数, 所以`pD->vfun()`和`pB->vfun()`相同, 都是调用的`D::vfun()`


## 5. printf
```cpp
float k = 0.8567;
/* 0代表非零数字用0填充, 6代表最少占6位, 1代表小数点后保留1位 */
printf("%06.1f%", k * 100);
// output: 0085.7%
```


## 6. Integral Promotion
执行表达式计算时(包括比较运算和算术运算等), 比int类型小的类型(char, signed char, unsigned char, short, unsigned short等)首先要提升为int类型, 再执行运算. 根据原始类型进行位扩展(如果原始类型为unsigned char, 进行零扩展, 如果原始类型为signed char, 进行符号位扩展)到32位
```cpp
signed char a = 0xe0;
unsigned int b = a;   // b = 0xffffffe0
short i = 65537;      // i = 0000 0000 0000 0001, 高两位字节丢失
int j = i + 1;        // j = 1+1 = 2
```
a为signed char, a在内存中的位储存形式是0xe0, 把a赋值给b, 所以b在内存中的位储存形式也是0xe0. 然后把a提升到int类型, 提升后会变成0xffffffe0(符号位扩展)


## 7. Type Size in 32-bit and 64-bit
32位和64位系统中字节数相同的类型:
1. char: 1个字节
2. short int: 2个字节
3. int: 4个字节
4. unsigned int: 4个字节
5. float: 4个字节
6. double: 8个字节
7. long long: 8个字节

32位和64位系统中字节数不同的类型:
1. pointer: 32位-4字节 64位-8字节
2. long: 32位-4字节, 64位-8字节
3. unsigned long: 32位-4字节, 64位-8字节


## 8. Private Destructor
为类对象分配栈空间时, 会先检查析构函数的访问性. 如果类的析构函数是private, 则编译器不会在栈空间上为类对象分配内存. 因此将析构函数设为私有, 类对象就无法建立在栈上(直接创建对象), 只能在堆上(new Class)分配类对象
```cpp
class A {
private:
  ~A() {};
};

A a1;             // error
A* a2 = new A();  // compile success
```


## 9. const reference
* 非const引用只能绑定到该引用同类型的对象
* const引用可绑定到不同但相关的对象

```cpp
int a1 = 1;
int& a2 = a1;          // 非const同类型
const float& a3 = a1;  // const非同类型
float& a4 = a1;        // error - 非const非同类型
```


## 10. const and decltype
```cpp
int x = 1;
const int y = 2;
int* p = &x;

// decltype保留const关键字
decltype(x) a;	    // a为int类型
decltype(y) b = 3;  // b为const int类型

// 双括号将类型变为引用, 保留const
decltype((x)) c = x;	// c为int&类型
decltype((y)) d = b;	// d为const int&类型

// p指针是解引用操作, 所以变为引用类型
decltype(*p) e = x;   // e为int&类型

// auto不保留const关键字
auto n = x;   // n为int类型
auto m = y;   // m为int类型
```


## 11. pointer of array
```cpp
const char str1[] = "abc";
const char str2[] = "abc";
const char *p1 = "abc";
const char *p2 = "abc";

printf("%x\n", str1); // f7c48a20
printf("%x\n", str2); // f7c48a30
printf("%x\n", p1);   // 68cb6948
printf("%x\n", p2);   // 68cb6948
```
str1和str2都是数组指针, 存在常量区, 所以指针地址不同. p1和p2存在栈中, 虽然p1和p2的值不同, 但指向的都是同一块静态存储区.


## 12. constructor, destructor, and virtual function
对于constructor:
1. constructor不能声明为virtual function: virtual function需在调用constructor时创建vtable来实现动态绑定; 若constructor为virtual function时, 调用constructor时没有vtable根据类对象类型调用, 因此无法通过编译.
2. base class的constructor中不能调用virtual function: 当创建derived class的对象时, 若base class的constructor中使用virtual function, 由于derived class的构constructor的constructor还未执行完毕, 因此virtual function可能会操作还未初始化的成员.
```cpp
class A {
public:
  virtual void func() {
    cout << "virtual A" << endl;
  }

  A() {
    func();   // 调用A::func()
    cout<<"A()"<<endl;
  }
};

class B: public A {
public:
    virtual void func() { cout << "virtual B" << endl; }
    B() { cout << "B()" << endl; }
};


A *b = new B(); /* virtual A
                 * A()
                 * B()
                 */
b->func();  /* virtual B */
```

对于destructor:
1. base class的destructor中不能调用virtual function: destructor的执行顺序和constructor相反. C++会先销毁derived class, 再销毁base class. 当调用base class的virtual function时, 会先调用derived class的绑定函数, 但由于dervied class已被销毁, 因此会导致不可控结果
2. base class的destructor应声明为virtual function: 当base class的destructor声明为virtual function时, 若指向base class的指针调用`delete`, 会先销毁derived class, 再销毁base class. 当base class的destructor不为virtual function时, 若指向base class的指针调用`delete`, 只会销毁base class, 不会销毁derived class.


## 13. reference parameter
实参可以是任何类型(常量, 变量或表达式), 形参不能是表达式
```cpp
void get1(char *p) {        // p的地址并不与str相同, 但都指向NULL
  p = (char *)malloc(100);  // p拥有内存地址(str地址不变, 仍为0x0), 指向一个新空间
  strcpy(p, "hello world");
}

void get2(char*& p) {       // p的地址与str相同, 也指向NULL
  p = (char *)malloc(100);  // p拥有内存地址(str地址也变为p的地址), 指向一个新空间
  strcpy(p, "hello world");
}

int main() {
  char* str = NULL; // 赋值为NULL的str地址为0x0, 没有分配内存地址
  get1(str);        // str地址未变
  get2(str);        // str地址改变
  return 0;
}
```


## 14. char*
```cpp
char *s1;        // s1未初始化, 所以地址不确定(野指针), 会导致错误
char *s2 = NULL; // s2初始化过, 赋值为NULL, 所以指向0x0
```


## 15. volatile
多线程中, 当多个线程修改和访问同一变量时, 会导致线程读取的变量可能已经被其他线程修改. 这主要是因为多线程中, 每个CPU会将变量装入CPU register中. 这样导致某个线程修改了变量后, 另一个线程由于没有去内存中同步变量, 而是直接从CPU register中读取, 从而使得线程不安全(因为从register直接读取会加快指令的执行速度).
volatile关键字让编译器取消优化, 每次读取变量都会从内存重新读取到CPU register中, 而不是使用register中的原来值, 从而使得线程安全.


## 16. Unary Operator
由于`++`和`--`有前缀和后缀两种形式, 后缀形式需添加一个int参数:
```cpp
#include <iostream>
#include <string.h>
using namespace std;

class A {
public:
  A(int b): a(b) {}
  int operator++() { // 前置一元运算符
    a++;
  }
  int operator++(int) { // 后置一元运算符
    a--;
  }

private:
  int a = 0;
};
```
`operator++(int)`中的`int`是个哑元(dummy), 是永远用不上的, 它只是用来判断运算符是prefix还是postfix. 


## 17. math.round
```cpp
public static long round(double a); // 返回值为long
```
math.round遵守四舍五入. 可以把int数值想象成数轴
1. `< 0.5`: 变为0, 趋向于原点
2. `>= 0.5`: 变为1/-1, 远离原点

```cpp
cout << round(0.4) << endl;   // 10
cout << round(0.5) << endl;   // 11
cout << round(-0.4) << endl;  // 0
cout << round(-0.5) << endl;  // -1
```


## 18. scanf
space(空格), newline(换行)和tab(制表符)都可以用来分割(也可以是连续的空格, 换行或制表符). 逗号不能分割


## 19. Virtual method table
虚函数表的指针位置取决于编译器, C++标准中并没有明确规定. 但对于绝大多数编译器来说, 都会放在类的头部.
```cpp
class Test {
public:
  int a;
  int b;
  virtual void fun() {}       // 在类的头部放置一个4字节的虚函数表指针
  Test(int temp1 = 0, int temp2 = 0) {
    a = temp1 ;
    b = temp2 ;
  }
};
 
int main()
{
  Test obj(5, 10);
  int *pInt = (int*)&obj;
  *(pInt+0) = 100;  // 修改了虚函数表的指针值
  *(pInt+1) = 200;  // 修改了类成员变量a的值
  cout << obj.a;    // 200
  cout << obj.b;    // 10
}
```


## 20. bool
C语言中没有bool类型, 可用int代替. C++才有bool类型


## 21. Preprocessor Directive
编译预处理与函数调用无关, 所在的位置决定作用域. main函数之后的预处理不会影响到main函数, main函数前定义的预处理会作用到main函数
```cpp
#define a 10

void foo();
int main()
{
  cout << a << endl;  // 10
  foo();
  cout << a << endl;  // 10
  return 0;
}

void foo(){
#undef a
#define a 50
}
```
上述代码中foo()函数没有影响a的值
```cpp
#define a 10

void foo(){
#undef a
#define a 50
}

int main()
{
  cout << a << endl;      // 50
  foo();
  cout << a << endl;      // 50
  return 0;
}
```
上述代码中foo()函数在没有调用前就改变了a的值


## 22. constructor, copy constructor, and copy assignment operator
```cpp
class A {
public:
  A() {
    cout << "Constructor is called..." << endl;
  }

  A(const A& rhs)
  {
    cout << "Copy Constructor is called..." << endl;
  }

  A& operator=(const A& rhs)
  {
    cout << "Copy Assignment Operator is called..." <<endl;
    return *this;
  }
};

int main()
{
  A* a;
  A* b = NULL;
  A* c = new A(); // 'Constructor is called...'
  A d;            // 'Constructor is called...'

  A e(d);  // 'Copy Constructor is called...'
  d = e;   // 'Copy Assignment Operator is called...'

  return 0;
}
```


## 23. Multiple Inheritance
```cpp
class A {
public:
  void f() {
    cout << "A::f()";
  }
};

class B {
public:
  void f() { cout << "B::f()"; }
  void g() { cout << "B::g()"; }
};

class C : public A, public B {
public:
  void g() { cout << "C::g()"; }  // 覆盖B::g()
  void h() {
    cout << "C::h()";
    f();  // 多继承导致f()产生了二义性, error
  }
};
```


## 24. Pointer Arithmetic and array indexing
```cpp
class A {
public:
  int a;
};

class B : public A {
public:
  int b;
};

void seta(A* data, int idx) {
  data[idx].a = 2;  // 由于传入的单位为A*, 所以data的长度为4, 而不是8
}

int main() {
  B data[4];  // data中单个元素的长度为8字节
  for (int i = 0; i < 4; ++i) {
    data[i].a = 1;
    data[i].b = 1;
    seta(data, i);
  }
  for (int i = 0; i < 4; ++i) {
    std::cout << data[i].a << data[i].b;       // 22221111
  }
}
```
第一个for循环的执行如下:
1. 赋值: [0]a=1, [0]b=1, seta(): [0]a=2
2. 赋值: [1]a=1, [1]b=1, seta(): [0]b=2
3. 赋值: [2]a=1, [2]b=1, seta(): [1]a=2
4. 赋值: [3]a=1, [3]b=1, seta(): [1]b=2


## 25. Heap Segment
```cpp
long long a = 1, b = 2, c = 3; 
printf("%d %d %d\n", a, b, c);  // 1 0 2
```
a, b, c各占8个字节, 但读取a,b,c时每个元素只读取四字节, 所以先读了a低字节的32位(1), b读取的是a的高字节32位(0), c读取的是b的低字节32位(2).
![25.1](/images/C/Basic/c-cpp-2-1.png)


## 26. Operator Overloading
1. 单目运算符最好重载为类的成员函数, 双目运算符则最好重载为类的友元函数
2. =、()、[]、->、new、delete, 这些操作符必须为成员函数


## 27. strcat
`strcat()`要求第一个参数类型为`char*`, 且有足够的空间容纳两个字符串. 常量字符串虽然可以隐式转换为`char*`, 但字符串的内存大小固定, 无法扩充
```cpp
char* p1 = "123", p2 = "456";
strcat(p1, p2);
```


## 28. cast
1. const_cast: 去除或添加指针或引用上的const或volatile关键字
```cpp
const int *a = new int(1);    // *a为1
int *b = const_cast<int*>(a); // 将const int*转换为int*
*b = 2;  // *a为2
```
2. static_cast: 执行一次显式类型转换, 可将基类指针转换为子类指针, 也可将enums转换为数值类型. 由于编译器会在运行static_cast时检查兼容性, 所以会保证类型转换是安全的
```cpp
int a = 0x0001;
int* b = static_cast<int*>(a);  // compile error
```
3. dynamic_cast: 只能用于多态中类的转换, 但不能用于钻石继承中的类转换, 或虚继承的类转换
```cpp
class A{
  virtual void func() {};
};

class B: public A {};

int main() {
  A* aa = new A();
  B* b = dynamic_cast<B*>(aa);

  B* bb = new B();
  A* a = dynamic_cast<A*>(bb);
}
```
4. reinterpret_cast
    1. 任意指针或引用类型之间的转换
    2. 指针与足够大的整数类型之间的转换
    3. 从整数类型(包括枚举类型)到指针类型的转换



## 29. strcmp return:
* `< 0`: 第一个string小
* `> 0`: 第二个string小
* `0`: 两个string相等


## 30. static binding of default parameter
virtual function是动态绑定, 但缺省参数值是静态绑定
```cpp
class A
{
public:
  virtual void func(int val = 1) { 
    cout << "A->" << val << endl;
  }
  virtual void test() { 
    func();
  }
};

class B : public A
{
public:
  void func(int val = 0) { // 虽然重写了缺省参数值, 但并不会动态绑定
    cout << "B->" << val << endl;
  }
};

int main()
{
  B *p = new B;
  p->test();  // 输出"B->1"
  return 0;
}
```
