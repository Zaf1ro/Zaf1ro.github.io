---
title: C++ Basic (3)
category:
  - Programming Language
  - C/C++
tag:
  - Programming Language
abbrlink: 44ce
date: 2017-09-15 14:50:17
---

## 1. Scope and Lifespan of Variable
* 全局变量: 所有源代码, 程序运行结束时销毁
* 全局静态变量: 单个源文件, 程序运行结束时销毁
* 局部变量: 所在函数, 函数运行完毕时销毁
* 静态局部变量: 所在函数, 但会在调用函数前初始化, 程序运行结束时销毁
* 静态成员变量: 所在class内, 所有对象共享该成员, 因此该成员会在生成对象前初始化, 程序运行结束时销毁


## 2. const and #define
相比于define, 使用const有以下好处: 
1. const会检查数据类型, define不会
2. const效率更高. const定义的常量不会保存在内存中, 而是在符号表(symbol table)中, 每次访问const数据不必从内存中读取和存储, 因此效率高


## 3. struct in C++
C++的struct与C的struct完全不同, C++中的struct十分接近class, 其具备继承(inheritance)和多态(polymorphism), 但无法设置访问权限.
```cpp
struct A {
  int a;
  A(int x);
  void func(void);
  void default_func(void);
};

A::A(int x) {
  a = x;
  cout << "A()" << endl;
}

void A::default_func(void) {
  cout << "default function" << endl;
}

void A::func(void) {
  cout << "function A" << endl;
}

struct B: A {  // 默认为public继承
  int b = 1;
  void func(void);
  B(int x, int y);
};

B::B(int x, int y): A(x) {
  b = y;
  cout << "B()" << endl;
}

void B::func(void) {
  cout << "function B" << endl;
}

int main()
{
  A a(1);           // A()
  a.func();         // function A
  B b(1, 2);        // A()
                    // B()
  b.func();         // function B
  b.default_func(); // default function
  return 0;
}
```


## 4. SOLID Principles in OOP
1. SRP(Single-Resposibility Principle, 单一职责原则): 每个模块, 类, 或函数只承担一个职责, 并且封装实现.
2. OCP(Open-Close Principle, 开放封闭原则): 实体应该对拓展开放, 对修改封闭.
3. LSP(Liskov Substituion Principle, 里式替换原则): 子类应能够替换它的基类. 例如, class B是class A的子类, 以class A为参数的函数也能接受class B的对象, 且不会导致任何异常, 这么做能保证子类继承了父类的一切.
4. ISP(Interface Segregation Principle, 接口隔离原则): 保持接口的独立, 也就是说, 很多个客户端特定的接口, 优于一个多用途的接口.
5. DIP(Dependecy Inversion Principle, 依赖倒置原则): class应依赖接口和抽象类, 而不是具体的class或函数. 


## 5. Class Inheritance
```cpp
class A {
public:
  virtual void display() { cout << "A::display" << endl; }
};

class B: public A {
public:
  void display() { cout << "B::display" << endl; }
};

void fun(A ptr) { // 不是用的地址传递, 所以直接转化为基类对象, 所以只调用基类成员函数
  ptr.display();
}

int main()
{
  A a;
  B b;
  fun(a); // A::display
  fun(b); // A::display

  B* b2 = new B();
  A* a2 = (A*)b2;
  a2->display();  // B::display 地址转换, 所以保留多态特性
}
```


## 6. Initialization List
使用初始化列表可少调用一次default constructor,从而提高效率, 减少错误. 以下三种情况必须使用初始化列表:
1. 成员所在的类没有默认构造函数
2. const修饰的类成员或引用成员数据
3. 子类初始化父类的私有成员

static成员变量不属于某个对象, 所以不能在constructor内初始化


## 7. Function Pointer
函数指针有两种方法: `pf=f1`和`pf=&f1`, 但必须保证参数类型和返回值类型匹配.
```cpp
int f1(float);
int f2(char);
int (*pf)(float);

pf=f1;  // OK
pf=&f1; // OK
pf=f2;  // error, 参数类型不匹配
```


## 8. Object on the stack/heap
调用`Class obj`不能保证类对象分配到栈中, 因为C++遵循**自动存储**(automatic storage), 会根据context决定存储位置.
1. Object obj存储在栈中
  ```c
  void func(void){
    Object obj; // 在函数中创建类对象会直接分配到栈中
  }
  ```
2. Object obj存储在堆中
  ```cpp
  class Object2 {
    Object obj;     
  }
  Object2 *pObj2 = new Object2(); // 由于pObj2所指向的对象在堆上分配空间, 所以obj也在堆上分配空间
  ```
3. Object Obj在静态存储区
  ```cpp
  Object obj; // 将obj存为全局变量
  ```

Stack与Heap上创建对象的区别:
1. 性能
  * heap上分配对象的时间为常量
  * stack上分配对象的时间不定, 因为操作系统需追踪内存的可用区域
2. 生存周期
  * heap上对象的生存周期与上下文有关
  * stack上的对象拥有更长的生存周期


## 9. private member in inheritance
父类的私有变量仍在子类的内存中, 但由于编译器的限制所以无法访问.
```cpp
class A{
private:
  int a;

public:
  int b;
  A():a(1),b(2){}
};

class B: public A{};

int main()
{
  B b;
  cout << *(int*)&b << endl;      // 1
  cout << *((int*)&b+1) << endl;  // 2
  return 0;
}
```


## 10. default value in arrray
```cpp
int a[2][2] = {{1},{1,2}};
int b[10] = {2,3};
char c[2] = {'a'};
float d[2] = {1.0};
cout << a[0][1] << endl;   // 0
cout << b[2] << endl;      // 0
cout << (int)c[1] << endl; // 0, char类型默认为'\0'
cout << d[1] << endl;      // 0
```


## 11. clone and fork
* `fork()`: 复制父进程的所有资源, 因此无需携带参数.
* `clone()`: 复制父进程的部分资源, 复制哪些资源可通过参数设定, 所以`clone()`携带参数, 没有复制的资源可以通过指针共享给子进程


## 12. abs()
* 输入为非负整数, 返回非负整数
* 输入为负数, 且不为最小负数, 返回其绝对值
* 输入为最小负数(`INT_MIN`), 还是返回最小负数


## 13. malloc and new
```cpp
A *p1 = new A;                 // 调用了构造函数
A *p2 = (A*)malloc(sizeof(A)); // 没有调用构造函数, 只是分配了一块A类大小的内存
```


## 14. Polymorphism
* 编译时多态性(override): 通过静态联编完成, 例如函数重载, 运算符重载
* 运行时多态性(overload): 通过动态联编完成, 主要通过虚函数来实现；



## 15. convert pointer to const
允许`int*`转为`const int*`, 但不允许转换多级指针(如`int**`转为`const int**`)
```cpp
int x = 1;
int *a = &x;
const int *b = &x;
const int **p = &a; // error: invalid conversion from 'int**' to 'const int**'
const int **q = &b;
```


## 16. Value Assignment in For Loop
```cpp
for (int i = 1; i = 0; ++i) {}; // 由于i为0, 逻辑为假, 不进入循环
for (int i = 1; i = 1; ++i) {}; // 由于i一直为1, 逻辑为真, 陷入死循环
```


## 17. Functions in Empty Class
以下是空类含有的函数:
* copy constructor
* copy assignment operator
* destructor
* default constructor

以上函数都是public且inline的


## 18. Initialize Two Dimensional Array
```cpp
a[2][3] = {1, 2, 3};  // OK, a[2][3]={{1,2,3},{0,0,0}}
a[][2] = {1, 2, 3};   // OK, a[][2]={{1,2},{3,0}}
a[2][3] = {{1, 2}, {3, 4}, {5}}; // error, 等号右边为3个元素的数组, a为两个元素的数组
```


## 19. Zero Argument Constructor
无参构造函数创建对象时, 不应该在对象名后加括号
```cpp
A a();  // error, 这样会声明一个名为a的函数
A a;    // OK
```


## 20. Sequence Point
```cpp
int a = (0, 1);
cout << a << endl;  // 1
```
逗号表达式是一组由逗号分隔的表达式, 从左向右计算, 结果为表达式最右边的值; 若最后边的操作数是左值, 则逗号表达式的值也是左值. 此类表达式通常用于for循环.


## 21. Order of Execution of Destructor
```cpp
class A {
public:  
  A() {}  
  ~A() { cout << "~A" << endl; }  
};  
   
class B: public A {  
private:  
  A _a;  

public:  
  B(A &a):_a(a) {}  
  ~B() { cout << "~B" << endl; }  
};  
       
int main(void) {  
  A a; 
  B b(a);
  // 先调用b所在的子类B的析构函数 '~B'
  // 再调用b的成员变量_a的析构函数, '~A'
  // 接着调用b的父类析构函数, '~A'
  // 最后调用a的析构函数, '~A'
}
```


## 22. cin >> unsigned integer
* `%u`/`%o`/`%x`代表10/8/16进制的无符号数
* `%n`接受一个uint数, 代表到`%n`之前所输入的字符数


## 23 order of struct member in memory
对于struct, 每个成员的内存从低到高依次排序.
```cpp
struct mybitfields {
  unsigned short a: 4;
  unsigned short b: 5;
  unsigned short c: 7;
} test
 
void main(void)
{
  int i;
  test.a = 2; // 0010
  test.b = 3; // 0 0011
  test.c = 0; // 000 0000

  i = *((short *)&test);
  printf("%d\n", i); // 0000 0000 0011 0010 => 2+16+32=50
}
```
对于class, 若没有交叉的access specifier(如private和public交叉使用), 则成员变量在内存上从低到高依次排序; 若存在交叉的access specifier, 则依据不同compiler的实现而定.


## 24. Initialization of Character Array
```cpp
char s1[] = "abc";
char s2[] = {'a', 'b', 'c', '\0'};
char s3[] = {97, 98, 99, 0};
char s4[] = {"abc"};

char* s5 = NULL;
s5 = "abc";
char* s6 = NULL;
s6 = {"abc"};
```


## 25. Implicit Type Conversion
如果表达式中同时存在signed int和unsigned int, 会将signed int转换为unsigned int
```cpp
int i = -1;
unsigned j = 1;
if (j > i)          // i转换为unsigned类型
  printf(" (j>i)成立\n");
else
  printf(" (j>i)不成立\n");
```


## 26. Double Free and Bitwise Copy
默认copy constructor使用bitwise copy, 
```cpp
class A {
  int i;
};

class B {
  A *p;
public:
  B() { p = new A; }
  ~B() { delete p; cout << "~B"; }
};

void sayHello(B b) {} // call default constructor, and call destructor at the end

int main() { // 程序一共输出两次~B()
   B b;
   sayHello(b); // 输出~B()
   // 最后会再调用一次~B()
}
```


## 27. Stack Memory Allocation
* `void* malloc(unsigned int size)`
  * 在stack中分配一段长度为size的连续空间
  * 成功时返回首地址, 失败时返回NULL
  * 不会初始化内存
* `void* calloc(unsigned int num, unsigned int size)`
  * 根据数据个数和数据类型所占字节数, 分配size*num大小的连续空间
  * 成功时返回首地址, 失败时返回NULL
  * 会自动初始化内存为0
* `void* realloc(void *ptr, unsigned int size)`
  * 分配一段长为size的内存空间, 并把内存空间的首地址赋值给ptr
  * 内存分配失败则返回NULL
  * 不会初始化内存
* `void* operator new (std::size_t size)`
  * 自动计算需要分配的内存空间大小, 并调用类的构造函数
  * 成功时返回首地址, 失败时抛出bad_alloc异常
  * 不对类中的内置类型变量进行初始化


## 28. Formatting String
```cpp
printf("%s , %5.3s\n","computer","computer");
// %m.ns输出占m列, 但只取字符串中左端n个字符. 这n个字符输出在m列的右侧, 左补空格
```


## 29. Base class pointer pointing to derived class object
```cpp
class Base {
public:
  Base() { echo(); }
  virtual void echo() { cout << "Base" << endl; }
};

class Derived: public Base {
public:
  Derived() { echo(); }
  virtual void echo() { cout << "Derived" << endl; }
};

int main() {
  // 执行Derived的构造函数时, 先调用父类Base的构造函数, 此时还没有动态绑定, 输出Base
  // 之后再调用子类Derived的构造函数, 输出Derived
  // 最后完成dynamic binding
  Base *base = new Derived(); 
  
  base->echo(); // 由于完成了动态绑定, 所以调用Derived的echo, 输出Derived
}
```


## 30. condition of switch
`switch`的condition应为integral(整数), enumeration(枚举), 或可以隐式转换为整数或整数的class. 整数有以下几种:
* short
* char
* int
* long
* bool

非整数类型包含float和double


## 31. Copy Constructor
声明copy constructor时需注意以下几点:
* 返回值的类型是否应为类型引用(否则无法连续赋值)
* 传入参数的类型是否应为引用(否则导致递归调用)
* 是否释放内存空间
* 是否判断传入参数和当前实例为同一实例

```cpp
class A {
private:
  char* data;

public:
  A& operator=(const A& objA) {
    if(this == &objA) 
      return *this;

    delete[] this->data;
    int len = strlen(data);
    this->data = new char[len + 1];
    strcpy(this->data, objA.data);

    return *this;
  }
};
```


## 32. Access Specifiers
* member declarations
    * public: 
        * 类内: public和protected成员可访问
        * 类外: 可在类外访问
    * protected:
        * 类内: public和protected成员可访问
        * 类外: 不可访问
    * private:
        * 类内: public和protected成员可访问
        * 类外: 不可访问
* base-specifier
    * public: base class中public和protected的访问权限不变
    * protected: base class中public变为protected, protected变为private
    * private: base class中public和protected变为private
