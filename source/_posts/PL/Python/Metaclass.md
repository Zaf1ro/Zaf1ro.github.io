---
title: Metaclass
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: 617f
date: 2015-12-16 15:47:03
---

## 1. 类即为对象
**类同样也是一种对象**. 只要你使用关键字class, Python解释器在执行的时候就会创建一个对象. 下面的代码段:
```python
class C(object):
  pass
```
C既是一个类, 它可以创建对象；同时C也是一个对象, 可以当做参数进行传递, 也可以被赋值, 被拷贝.


## 2. 动态地创建类
由于类也是对象, 所以可以在运行时动态创建类, 就像任何时刻都可以创建对象一样. 
```python
def choose_class(name):
  if name == '1':
    class C1(object):
      pass
    return C1
  else:
    class C2(object):
      pass
    return C2

C = choose_class('1')
print C()  # <__main__.C1 object at 0x0000000001F97630>
```
上述例子中依然需要提前写好自己需要的类代码, 为了实现动态的生成类代码, 我们需要用到内建函数`type()`


## 3. type()函数
`type()`函数最基本的功能就是让你知道个对象的类型, 例如: 
```python
print type(1)         # <type 'int'>
print type("123")     # <type 'str'>
print type(type(1))   # <type 'type'>

class C(object):
  pass

print type(C)       # <type 'type'>
print type(C())     # <class '__main__.C'>
```

但`type()`还有一种完全不同的应用: 动态地创建类. `type()`可接受一个类的描述并返回一个类: `
type(类名, 父类的元组, 包含属性或函数的字典)`. 例如: 
```python
class C1(object):
  pass

C2 = type('C2', (), {})  # 和C1相同的效果

print C1  # <class '__main__.C1'>
print C2  # <class '__main__.C2'>
```

也可以定义类属性: 
```python
class C1(object):
  a = 1

C2 = type('C2', (), {'a': 2})  # 通过字典的方式定义属性

c1 = C1
c2 = C2

print c1.a  # 1
print c2.a  # 2
```

还可以使用`type()`定义类函数: 
```python
class C1(object):
  def func(self):
    print self.name
    
  def __init__(self, name):
    self.name = name

def func(self):
  print self.name

def __init__(self, name):
  self.name = name

C2 = type('C2', (), {'__init__': __init__, 'func': func})

c1 = C1('1')
c2 = C2('2')

c1.func()  # 1
c2.func()  # 2
```


## 4. 元类概念
类是对象, 但类对象由谁实例化的呢? **metaclass**(元类)负责实例化每一个类, 也就是类的类:
```python
Class = MetaClass()
Intance = Class()
```

上一节我们介绍了使用`type()`动态地创建类, 其实**type就是一个元类**. 由此推出, `str`是所有字符串对象的类, int是所有整数的类, 它们的元类都是Python的内建元类type: 
```python
print type(1)           # <type 'int'>
print type("123")       # <type 'str'>
print type(str)         # <type 'type'>
print type(int)         # <type 'type'>
```

也可以使用`__class`__`查看自己属于哪个类:
```python
a1 = 1
a2 = '1'
print a1.__class__   # <type 'int'>
print a2.__class__   # <type 'str'>
print int.__class__  # <type 'type'>
print str.__class__  # <type 'type'>
```


## 5. 如何使用元类
由于type是元类, 所以可以用来创建子类:
```python
class ChildType(type):
  def __new__(cls, name, bases, dct):
    print "Allocate memory for class", name
    return type.__new__(cls, name, bases, dct)

  def __init__(cls, name, bases, dct):
    print "Init class ", name
    super(ChildType, cls).__init__(name, bases, dct)

X = ChildType('X', (), {'foo': lambda self: 'foo'})  # foo为匿名函数
# Allocating memory for class X
# Init'ing (configuring) class X

print X, X().foo()
# <class '__main__.X'> foo
```

也可以将类方法放在生成的类上: 
```python
class Printable(type):
  def whoami(cls): print "I am a", cls.__name__

Foo = Printable('Foo', (), {})
Foo.whoami()  # 自定义类本身的方法
# I am a Foo

Printable.whoami()  
# unbound method whoami() must be called with Printable instance as first argument
```

还可以通过设置`__metaclass__`类属性来定制元类创建类, 但必须在类定义时设置`__metaclass__`属性, 如果在创建类对象之后再设置该属性, 就不会使用元类: 
```python
class ChildType(type):
  def typemethod(cls):
    return cls.__name__

class C:
  __metaclass__ = ChildType

  def classmethod(self):
    return 'class'

print C.typemethod()
print C().classmethod()
```


## 6. 元类解决的问题
通常会使用元类去做一些晦涩的事情. 就元类本身而言, 其实是很简单的: 
1. 拦截类的创建
2. 修改类
3. 返回修改之后的类

需要注意以下几点: 
* 元类中, `type`的调用才会真正创建类, 所以可以自由地改变属性字典(以及名称和元组形式的基类序列). 
* 一些Python ORM(Object Relational Mappers, 对象关系影射)实现了面向对象编程语言里不同类型系统的数据之间的转换. 
* 由于元类是继承的, 所以你能够提供一个使用了你的元类的基类, 而继承自它的子类就无需显式声明它了. 

下面是一个例子: 
```python
class UpperAttrMetaclass(type):
  # __new__ 是在__init__之前被调用的特殊方法
  def __new__(cls, name, bases, dct):
    # 排除以'__'开头的属性
    attrs = ((name, value) for name, value in dct.items() if not name.startswith('__'))

    # 将属性名都变为大写
    uppercase_attr = dict((name.upper(), value) for name, value in attrs)

    return super(UpperAttrMetaclass, cls).__new__(cls, name, bases, uppercase_attr)


class Foo(object):
  # 我们也可以只在这里定义__metaclass__, 这样就只会作用于这个类中
  __metaclass__ = UpperAttrMetaclass
  bar = 'bip'


f = Foo()
print f.BAR
# bip

print f.bar
# AttributeError: 'Foo' object has no attribute 'bar'
```