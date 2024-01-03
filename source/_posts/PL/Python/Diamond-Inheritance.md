---
title: Diamond Inheritance
category:
  - Python
  - Basic
tag:
  - Python
abbrlink: 599f
date: 2016-06-06 21:23:50
---

## 1. 多继承
继承的概念已经融入了面向对象编程理念之中, 所有面向对象的编程语言都希望程序员灵活运用类和继承. 但多继承却被很多现代编程语言所禁止, 如Java, C#, Ruby, 这不是没有缘由的, 因为多继承会增加程序的复杂性和含糊性
即便有这么多缺陷, 但还是有一些编程语言允许程序员进行多继承, 如C++和Python.
本文主要讲解多继承中的钻石问题(diamond inheritance).


## 2. C++钻石问题
![C++ Diamond Inheritance](/images/Python/cpp-diamond-inheritance.jpg)

### 2.1 错误示例
```cpp
class Base
{
  private:
    int p = 100;

  public:
    int getParam() { return p; };
};

class A: public Base
{ };

class B: public Base
{ };

class AB: public A, public B
{ };

int main()
{
  AB ab;
  int p = ab.getParam();  // 编译错误, 因为不能确定使用Tiger或Lion中的getWeight()函数
}
```
从代码中我们可以清楚的看出问题: 当我们实例化AB类时, 所调用的函数getParam()是模糊的, 不确定调用A还是B的函数. 针对这个问题, C++给出了解决方案: 使用virtual(虚基类)

### 2.2 正确示例
```c++
class Base
{
  private:
    int p = 100;

  public:
    int getParam() { return p; };
};

class A: virtual public Base
{ };

class B: virtual public Base
{ };

class AB: public A, public B
{ };

int main()
{
  AB ab;
  int p = ab.getParam(); // 编译成功, virtual能保证只有一个Animal子类被创建
}
```



## 3. Python钻石问题
### 3.1 错误示例
```python
class Base(object):
  def __init__(self):
    print 'Base'
    self.p = 100

  def getParam(self):
    print self.p


class A(Base):
  def __init__(self):
    Base.__init__(self)
    print 'A'


class B(Base):
  def __init__(self):
    Base.__init__(self)
    print 'B'


class AB(A, B):
  def __init__(self):
    A.__init__(self)
    B.__init__(self)
    print 'AB'

ab = AB()
print AB.mro()
ab.getParam()

# 如下为输出, 可以发现, Base类初始化了两次
# Base
# A
# Base
# B
# AB
# [<class '__main__.AB'>, <class '__main__.A'>, <class '__main__.B'>, <class '__main__.Base'>, <type 'object'>]
# 100

# Python将多继承的图结构转化成list的顺序结构
```
从代码结果我们可以发现, Base的初始化函数运行了两遍, 这可能会引起程序的错误.
Pyhton给出的结果方案是使用super来避开初始Base两次.

### 3.2 正确示例
```python
class Base(object):
  def __init__(self):
    print 'Base'


class A(Base):
  def __init__(self):
    super(A, self).__init__()
    print 'A'


class B(Base):
  def __init__(self):
    super(B, self).__init__()
    print 'B'


class AB(A, B):
  def __init__(self):
    super(AB, self).__init__() 
    print 'AB'

ab = AB()
print AB.mro()

# Base
# B
# A
# AB
# [<class '__main__.AB'>, <class '__main__.A'>, <class '__main__.B'>, <class '__main__.Base'>, <type 'object'>]
```
当我们在运行`super(AB, self).__init__()`时, 首先获取self的mro并从左往右开始依次寻找`__init__`, 找到A并将A的`__init__`绑定到self对象中. 而A的`__init__`又是Base的`__init__`. 
当初始化B类时, 不会再初始化Base, 因为super中的mro只会运行一次.
