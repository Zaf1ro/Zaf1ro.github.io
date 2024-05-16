---
title: Class Method
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: bbe1
date: 2015-12-10 13:38:49
---

## 1. 构造和初始化
每个人都知道`__init__`函数, 我们可以通过这个函数来初始化(initialize)一个对象, 但当我们调用`x = SomeClass()`时, `__init__`并不是第一个被调用的函数. 实际上, Python先调用`__new__`创建一个实例(instance), 并将参数传给`__init__`. 在对象生命结束时调用`__del__`清理. 

### 1.1 `__new__(cls, [...)`
`__new__`第一个调用, 用于实例化对象, 参数`cls`为class, 并将参数传给`__init__`. `__new__`用的地方很少, 但当你将一个不可变类型变为子类时, 就需要使用该函数: 
```python
class inch(float):
 '''Convert from inch to meter'''
 def __new__(cls, arg=0.0):
   return float.__new__(cls, arg*0.0254)

>>> print inch(12)
```
float是一个不可变类, 可在`__new__`内修改数值

### 1.2 `__init__(self, [...)`
类的初始化器, 其参数为类参数, 如`x = SomeClass(10, 'foo')`, `__init__`会将10和'foo'作为参数. 是Python中最常用的定义. 

### 1.3 `__del__(self)`
类的析构器. 当使用`del x`时不会调用`x.__del__()`, 等垃圾收集时才调用该函数. 清理实例时该函数很有用, 可用于关闭I/O文件, 如socket和file. 但是要注意, 解释器退出时不能保证对象是否存在, 所以不能保证是够执行`__del__`, 因此最好不要重载这个方法（在某些复杂的环境下, `__del__`可能不会被用到, 谨慎使用. `__init__`和`__del__`可结合使用: 
```py
import os
 
class FileObject:
  def __init__(self, filepath='~', filename='sample.txt'):
    # 以可读可写的形式打开一个文件
    self.file = open(os.path.join(filepath, filename), 'r+')
  
  '''重写__del__以确保对象被删除时文件能够关闭'''
  def __del__(self):
    self.file.close()
    del self.file
```


## 2. 让运算符可以操作在类上
Python类方法的其中的一个优点就是使得对象行为更像一个内置类型. 这意味着你可以避免丑陋的, 反直觉的, 且不标准的写法. 某些语言中可以这么写:
```python
if instance.equals(other_instance):
  # do something
```
你也可以在Python中这么写, 但会让人迷惑, 且让代码变得冗长. 为实现相同功能, 不同的库使用不同的名字, 让使用者每次都要翻文档. 因此可以定义一个方法(`__eq__`)来实现上述功能: 
```python
if instance == other_instance:
  #do something
```
这只是类方法的部分威力, 它们允许我们自己定义操作符的实现, 从而让我们像使用内置类型一样使用类. 

### 2.1 比较方法
Python有大量方法来让对象之间的对比使用更加直观的运算符, 而不是丑陋的方法调用. 它们还提供重写Python行为的方法, 来实现对象间的对比. 下面是一个方法清单: 
* `__cmp__(self, other)`: `__cmp__`是最基本的对比方法. 他实现了对比操作符的所有行为(<,==,!=等), 但其实现方法和你想的并不一定一致: 若`self < other`, 则`__cmp__`返回负数; `0`代表`self == other`, 正数代表`self > other`.
* `__eq__(self, other)`: 定义`==`运算符
* `__ne__(self, other)`: 定义`!=`运算符
* `__lt__(self, other)`: 定义`<`运算符 
* `__gt__(self, other)`: 定义`>`运算符
* `__le__(self, other)`: 定义`<=`运算符
* `__ge__(self, other)`: 定义`>=`运算符

举个例子, 我们想要按字典序来对比字符, 就像string默认的对比方法一样, 但我们还需要基于其他标准进行比较, 例如长度和音节的个数. 在本例中, 我们使用长度来比较: 
```python
'''word类, 定义了基于字符长度比较的运算符'''
class Word(str):
    def __new__(cls, word):
        # 注意到我们使用了__new__, 因为str是不可变类型, 所以我们可以自定义初始化它
        if ' ' in word:
            print "字符中包含空格, 只取第一段空格前的字符串"
            word = word[:word.index(' ')] # 现在字符串中已没有空格
        return str.__new__(cls, word)
 
    def __gt__(self, other):
        return len(self) > len(other)
    def __lt__(self, other):
        return len(self) < len(other)
    def __ge__(self, other):
        return len(self) >= len(other)
    def __le__(self, other):
        return len(self) <= len(other)
```
幸运的是你不需要为了得到一个丰富的比较方法而定义一堆比较符方法, 标准库中提供了functools模块来让我们使用类装饰器(class decorator), 这让我们只定义`__eq__`和其他某一个方法(`__lt__()`, `__le__()`, `__gt__()`, 或`__ge__()`)就可使用所有比较方法. 前提是在类的头部加上`@total_ordering`装饰器: 
```python
@total_ordering
class Student:
  '''
  只定义了__eq__和__lt__方法, 但实现了全部的对比方法
  '''
  def __eq__(self, other):
    return ((self.lastname.lower(), self.firstname.lower()) ==
      (other.lastname.lower(), other.firstname.lower()))
  def __lt__(self, other):
    return ((self.lastname.lower(), self.firstname.lower()) <
      (other.lastname.lower(), other.firstname.lower()))
```

### 2.2 数值方法
就像使用**比较运算符**来对比类实例一样, Python中也可以定义**算术运算符**. 算术方法分为五类: 
* 一元运算符
* 正常的算术运算符
* 镜像算术运算符(reflected arithmetic operators)
* 增强型功能
* 类型转换

#### 2.2.1 一元运算符函数
一元运算符和函数只有一个操作数, 例如取负和求绝对值:
* `__pos__(self)`: 一元取正(`+`)
* `__neg__(self)`: 一元取负(`-`)
* `__abs__(self)`: `abs()`方法
* `__invert__(self)`: 取反(`~`). 具体解释可以参看"按位取反"
* `__round__(self, n)`: `round(n)`方法, n为小数点后四舍五入的位数
* `__floor__(self)`: `math.floor()`方法, 四舍五入成最接近的整数
* `__ceil__(self)`: `math.ceil()`方法, 四舍五入成最接近的整数
* `__trunc__(self)`: `math.trunc()`方法, 直接截断成整数

#### 2.2.2 二元运算符函数
* `__add__(self, other)`: 加法
* `__sub__(self, other)`: 减法
* `__mul__(self, other)`: 乘法
* `__floordiv__(self, other)`: 实现了整数除法, 使用`//`运算符
* `__div__(self, other)`: 实现了除法, 使用`/`运算符
* `__truediv__(self, other)`: 实现了真正的除法, 只有调用`from __future__ import division`时可用
* `__mod__(self, other)`: 求模运算, 使用`%`运算符
* `__divmod__(self, other)`: 重载了divmod()方法. divmod()方法返回一个tuple, 第一个参数为商, 第二个是余数
```sh
>>> divmod(9,2)
(4, 1)
```
* `__pow__(self, other)`: 实现了指数功能, 使用`**`运算符
* `__lshift__(self, other)`: 实现了按位左移, 使用`<<`运算符
* `__rshift__(self, other)`: 实现了按位右移, 使用`>>`运算符
* `__and__(self, other)`: 实现了按位与, 使用`&`运算符
* `__or__(self, other)`: 实现了按位或, 使用`|`运算符
* `__xor__(self, other)`: 实现了按位异或, 使用`^`运算符

#### 2.2.3 镜像算术运算符
普通的算术运算是这样的: 
```py
self + other
```
而镜像算术运算为`other + self`. 大部分情况下, 镜像算术和正常的表达式一样, 例如`__add__`和`__radd__`. `__radd__`只会在other没有定义`__add__`才会被调用. 

* `__radd__(self, other)`: 镜像加法
* `__rsub__(self, other)`: 镜像减法
* `__rmul__(self, other)`: 镜像乘法
* `__rfloordiv__(self, other)`: 镜像整数除法(`//`)
* `__rdiv__(self, other)`: 镜像除法(`/`)
* `__rtruediv__(self, other)`: 镜像除法, 只有调用`from __future__ import division`时才有效
* `__rmod__(self, other)`: 镜像取模(`%`)
* `__rdivmod__(self, other)`: 内建的`dimod()`函数, 只有调用`divmod(other, self)`时可用
* `__rpow__(self, other)`: 镜像指数(`**`)
* `__rlshift__(self, other)`: 镜像按位左移(`<<`)
* `__rrshift__(self, other)`: 镜像按位右移(`>>`)
* `__rand__(self, other)`: 镜像按位与(`&`)
* `__ror__(self, other)`: 镜像按位或(`|`)
* `__rxor__(self, other)`: 镜像按位异或(`^`)

#### 2.2.4 增强型功能
Python还提供了一系列方法让我们自定义来实现增强功能. 下面是一个例子: 
```python
x = 5
x += 1  # 也就是x = x + 1
```
这些方法没有返回值, 只会改变运算符左边对象的状态.
* `__iadd__(self, other)`: 自加
* `__isub__(self, other)`: 自减
* `__imul__(self, other)`: 自乘
* `__ifloordiv__(self, other)`: 整数除法(`//=`)
* `__idiv__(self, other)`: 自除(`/=`)
* `__itruediv__(self, other)`: 真正的除法, 只有调用`from __future__ import division`时可用
* `__imod__(self, other)`: 取模(`%=`)
* `__ipow__(self, other)`: 指数运算(`**=`)
* `__ilshift__(self, other)`: 镜像按位左移(`<<=`)
* `__irshift__(self, other)`: 镜像按位右移(`>>=`)
* `__iand__(self, other)`: 镜像按位与(`&=`)
* `__ior__(self, other)`: 镜像按位或(`|=`)
* `__ixor__(self, other)`: 镜像按位异或(`^=`)


## 3. 类型转换方法
Python提供了一系列方法让你重载**类型转换**.
* `__int__(self)`: `int()`
* `__long__(self)`: `long()`
* `__float__(self)`: `float()`
* `__complex__(self)`: `complex()`
* `__oct__(self)`: `oct()`
* `__hex__(self)`: `hex()`
* `__index__(self)`: 当对象用于一个切片表达式时会将对象变为一个int, 例: 
  ```python
  class Thing(object):
    def __index__(self):
      print '__index__ called!'
      return 1

  thing = Thing()
  _list_ = ['abc', 'def', 'ghi']
  print _list_[thing]  # __index__被调用, 因为_list是一个切片表示的类型
  # __index__ called!
  # 'def'

  dict_ = {1: 'potato'}
  # print dict_[thing]  # error, dict不是一个切片表示的类型, 所以并没有调用__index__
  # Traceback (most recent call last):
  #   File "<stdin>", line 1, in <module>
  # KeyError: <__main__.Thing object at 0x01ACFC70>
  ```
* `__trunc__(self)`: `math.trunc()`, 返回被截断的整数
* `__coerce__(self, other)`: 用来实现混合模式的算术运算. 若无法进行类型转换, 则__coerce__返回None. 否则, 返回一个包含self和other的tuple, 统一使用一种类型. coerce()的转换规则: 
  * 如果有一个操作数是复数,  另一个操作数被转换为复数.  
  * 否则, 如果有一个操作数是浮点数,  另一个操作数被转换为浮点数.  
  * 否则, 如果有一个操作数是长整数, 则另一个操作数被转换为长整数； 
  * 否则, 两者必然都是普通整数, 无须类型转换


## 4. 表示你的类
类实例的string表现形式很有用, 在Python中, 你可在类定义中定义一些方法来定制化你的类的表现形式: 
* `__str__(self)`: 调用`str()`时调用该函数:
  ```python
  class C(object):
    def __str__(self):
      # 如果希望输出一个类实例能用print语句输出可以使用__str__()
      # 默认被print调用
      return "use str"

  c = C()
  print c  # use str
  print C()  # use str
  ```
* `__repr__(self)`: 调用`repr()`时调用该函数. `str()`和`repr()`的区别在于: `repr()`返回机器可读的结果, `str()`返回人可读的结果.
* `__unicode__(self)`: 调用`unicode()`时调用该函数. `unicode()`返回一个unicode字符串. 若调用`str()`时, 类只定义了`__unicode__`, 不会调用该函数, 而尝试调用`__repr__`. 所以应该先在类中定义`__str__`. 
* `__format__(self, formatstr)`: `format()`, formatstr是格式限定符, `"{:abc}".format(a)`等同于`a.__format__("abc")`, 这样可自己定义数值和字符串的特殊格式. 
* `__hash__(self)`: 调用`hash()`调用该函数, 返回一个整数. 当两个对象拥有同样的哈希值时, 两个对象就是相同的, 通常会结合对象中的多个属性来计算其哈希值. 当一个类没有定义`__cmp__`或`__eq__`时, 也就无需定义`__hash__`.
* `__nonzero__(self)`: 调用`bool()`时调用该函数, 返回`True`或`False`, 这里需要定义含义, 指明何种情况下类实例是True或False
* `__dir__(self)`: 调用`dir()`时调用该函数. 该函数应为用户返回一系列实例的属性. 通常情况下无需定义`__dir__`, 但如果重定义了`__getattr__`或`__getattribute__`, 那么定义该函数对交互式使用你的类至关重要. 
* `__sizeof__(self)`: 调用`sys.getsizeof()`时调用该函数. 该函数应返回对象所占内存的字节数. 当Python类使用到C拓展时, 该函数显得更为重要. 


## 5. 属性访问控制
许多学过别的语言的人来学Python时会抱怨Python缺乏类的封装, 但这是不对的: Python只不过通过一系列方法进行封装, 而不是通过固有的方法或修饰符.
* `__getattr__(self, name)`: 当用户访问一个不存在的属性时, 可调用该函数. 该函数可重定向或捕获拼写错误. 给出用户正在使用已弃用的属性的警告, 或给出AttributeError的错误信息. 该函数只有在一个不存在的属性被访问时才被调用, 所以这不能算是一个封装的方案. 
* `__setattr__(self, name, value)`: 该函数是一个封装的解决方案. 不管这个属性存在否, 该函数都允许你给属性赋值, 这意味着你可以为属性值的变化自定义规则. 然而你还是要小心地使用该函数.
* `__delattr__(self, name)`: 像`__setattr__`一样, 但用于删除属性而不是设置属性. 但像__setattr__一样要小心无限回溯. 
* `__getattribute__(self, name)`: `__getattribute__`就像`__setattr__`, `__delattr__`一样. 但并不推荐使用该函数, `__getattribute__`只能在New-Style Class中使用, 它会因为`__setattr__`和`__delattr__`的无限回溯而导致自身也陷入无限回溯中(可调用基类的`__getattribute__`防止无限回溯).

在属性访问控制中, 你定义的方法很容易造成问题, 如下:
```python
def __setattr__(self, name, value):
  self.name = value
  # 每一次一个属性被设置, __setattr__()都会被调用, 这就一个递归
  # 上述表达式的真实含义是self.__setattr__('name',value), 这又调用了__setattr__
  # 不停地调用该函数形成死循环, 最终崩溃
 
def __setattr__(self, name, value):
  self.__dict__[name] = value 
  # 这里给__dict__赋值, 调用的是__dict__的__setattr__(), 所以不会造成死循环
```
Python的方法拥有巨大能力, 但也伴随着更大的责任, 懂得如何正确使用这些方法而不至于让程序崩溃十分重要. 
所以我们从Python的属性访问控制中学到了什么? 使用它们是很难的, 因为它是异常强大且反直觉的. 那为什么这些方法要存在: 因为Python不想做坏事, 但这会使得它们变难. 下面是一些属性访问方法的特殊例子: 
```python
'''类中有一个值, 并有一个访问计数器. 每一次数值的改变都会使计数器自增'''
class AccessCounter(object):
  def __init__(self, val):
    super(AccessCounter, self).__setattr__('counter', 0)
    super(AccessCounter, self).__setattr__('value', val)
 
  def __setattr__(self, name, value):
    if name == 'value':
      super(AccessCounter, self).__setattr__('counter', self.counter + 1)
    # 如果你不想让其他属性被设置, 可以raise AttributeError
    super(AccessCounter, self).__setattr__(name, value)
 
  def __delattr__(self, name):
    if name == 'value':
      super(AccessCounter, self).__setattr__('counter', self.counter + 1)
    super(AccessCounter, self).__delattr__(name)
```


## 6. 创造自定义序列
有一系列方法能让你的Python类操作起来像序列(sequence)一样(dict, tuple, list, string等). Python赐予了它们惊人的控制程度, 并且使你的类实例可以漂亮地工作. 在详细描述之前, 需要先理清一下需求.

### 6.1 需求
在讨论一下在Python中创建自己的序列之前, 需先讨论一下"协议"(Protocols). 其它语言会给你一系列方法并让你定义, 因此协议在某种程度上与接口相似; 但Python的协议是通俗的, 不需要显式声明. 他们更像是指南. 
为什么我们要讨论协议, 因为在Python中使用定制的容器(container)类型需使用到协议. 首先, 有一些协议可以用来定义不可变容器(immutable container): 为了做一个不可变容器, 你只需要定义`__len__`和`__getitem__`; 可变容器协议需要添加`__setitem__`和`__delitem__`; 若想让对象可迭代, 则需遵循迭代器协议, 因此需定义`__iter__`和`next`方法. 

### 6.2 容器的方法
* `__len__(self)`: 返回容器长度, 可变和不可变容器都需定义该方法. 
* `__getitem__(self, key)`: 访问item需要的方法, 如`self[key]`. 这也是可变和不可变容器协议的一部分. 若key的类型错误, 则引起TypeError异常; 若key没有对应的value, 则引起KeyError异常. 
* `__setitem__(self, key, value)`: 分配item时需要的方法, 如`self[key]=value`. 不可变容器协议的一部分. 也应在适当时刻引起KeyError和TypeError异常. 
* `__delitem__(self, key)`: 删除item时需要的方法. 该函数是可变容器协议的一部分, key不存在时抛出异常.
* `__iter__(self)`: 返回一个迭代器. 可使用`iter()`, 也可使用`for x in container`. 如果对象已经是一个迭代器, 则`__iter__`应返回self.
* `__reversed__(self)`: 调用`reversed()`时调用该方法, 返回该序列的逆序. 只有序列类才能使用这个方法, 例如list和tuple. 
* `__contains__(self, item)`: 用于成员测试, 如`in`和`not in`. 但该函数不是必需的, 若未定义`__contains__`, Python会遍历序列, 如果寻找到指定item就返回True
* `__missing__(self, key)`: 该方法应用于dict的子类, 表示访问的key找不到的情况时应作何行为. 例如, 存在一个字典d, 访问`d['george']`时, "george"并不在d中存在, 从而调用`d.__missing__("george"))`

### 6.3 举个例子
让我们来看一下一个list使用了哪些功能结构, 你可能在其他语言中使用过.
```python
'''类覆盖了一些list的额外功能, 比如head, tail, init, last, drop和take'''
class FunctionalList:
  def __init__(self, values=None):
    if values is None:
      self.values = []
    else:
      self.values = values

  def __len__(self):
    return len(self.values)
 
  def __getitem__(self, key):
    return self.values[key] # 如果key是不合法的类型或数值, 那么list会引起异常
 
  def __setitem__(self, key, value):
    self.values[key] = value
 
  def __delitem__(self, key):
    del self.values[key]
 
  def __iter__(self):
    return iter(self.values)
 
  def __reversed__(self):
    return FunctionalList(reversed(self.values))
 
  def append(self, value):
    self.values.append(value)

  def head(self):
    return self.values[0] # 获得第一个元素

  def tail(self):
    return self.values[1:] # 获得除第一个之外的所有元素

  def init(self):
    return self.values[:-1] # 获得除最后一个之外的所有元素

  def last(self):
    return self.values[-1] # 获得最后一个元素

  def drop(self, n):
    return self.values[n:] # 获得除前n个元素之外的所有元素

  def take(self, n):
    return self.values[:n] # 获得前n个元素
```
现在你知道了怎么样实现你的序列, 定制序列有很多用处, 很多已存在于Python的标准库中, 如Counter, OrderedDict, 或NameTuple.


## 7. 反射
可通过定义内建函数`isinstance()`和`isubclass()`来控制反射, 如下：
* `__instancecheck__(self, instance)`: 判断instance是否为类的一个实例
* `__subclasscheck__(self, subclass)`: 检查subclass是否为类的一个子类

上述两种方法的使用范围较小, 但他们反应了Python的**编程思想**: 这些方法可能看上去不是很有用, 但一旦你需要他们, 就会觉得他们太重要了. 


## 8. 可调用对象
Python中, 函数(function)是第一类对象, 这意味着你可将一些参数传给函数, 而函数与类在某种程度上是等价. 这是一个十分强大的特性, Python中一个特殊方法可使你的类实例变得像函数一样操作.
`__call__(self, [args...])`: 允许类实例可以像函数一样被调用, 这意味着`x()`等同于`x.__call__()`, 注意`__call__`可以传入很多参数, 意味着你可以像函数一样操作`__call__`, 传递多少参数都无所谓. `__call__`可在类实例转换状态时使用, **调用实例**是一种符合直觉且优雅的方式改变对象状态. 下面是一个表示实体在平面上位置的类：
```python
class Entity:
  '''类来描述实体, 调用用来更新实体的位置'''
 
  def __init__(self, size, x, y):
    self.x, self.y = x, y
    self.size = size
 
  def __call__(self, x, y):
    '''修改实体的位置'''
    self.x, self.y = x, y
 
  # skip...
```


## 9. 上下文管理器
Python2.5引入了一个新名词实现**代码重用**: with表达式. 上下文管理器的概念在Python中已经不新鲜, 但直到PEP343, 它才作为第一类语言架构被接受. 你可能早就见过with表达式:
```python
with open('foo.txt') as bar:
  # 用bar来做一些操作
```
当代码被with表达式包裹起来时, 上下文管理器的行为被两个方法决定：
* `__enter__(self)`: 进入with表达式时上下文管理器的行为. 注意, `__enter__`的返回值与with表达式声明的目标绑定在一起, 或是as后面的名称. 
* `__exit__(self, exception_type, exception_value, traceback)`: 退出with表达式时上下文管理器的行为. 可用于处理异常, 清理工作等. 若工作顺利执行, 则`exception_type`, `exception_value`和`traceback`为空. 换句话说, 我们可以选择异常处理方式, 或让用户处理: 若选择自己处理异常, 那么要确保`__exit__`返回True; 若不想让上下文管理器处理异常, 则让其报错. 

如果能很好地定义`__enter__`和`__exit__`, 则对特殊类很有用. 你可以用这些方法来创建一个泛型上下文管理器来包裹其他对象, 下面是一个例子：
```python
'''一个上下文管理器可以在with表达式中通过close方法自动地关闭一个对象'''
class Closer:
  def __init__(self, obj):
    self.obj = obj
 
  def __enter__(self):
    return self.obj # bound to target
 
  def __exit__(self, exception_type, exception_val, trace):
    try:
      self.obj.close()
    except AttributeError: # 对象是不可关闭的
      print 'Not closable.'
      return True # 异常被成功地捕获并处理
```
下面是一个Closer的例子, 使用FTP连接来证明:
```sh
>>> from magicmethods import Closer
>>> from ftplib import FTP
>>> with Closer(FTP('ftp.somesite.com')) as conn:
...   conn.dir()
...
# 简介的展示输出
output omitted for brevity
>>> conn.dir()
# 引发AttributeError错误信息, 使用的连接不能关闭
>>> with Closer(int(5)) as i:
...   i += 1
...
Not closable.
>>> i
6
```
可以看出, with表达式优雅地处理所有正确和不正确的使用, 这就是上下文管理器的威力. 需要注意的是, Python标准库包含contextlib模块, 其也包含一个上下文管理器, `contextlib.closing()`可实现相同功能. (对于对象没有close方法的不会进行任何处理)



## 10. 抽象基础类
见 http://docs.python.org/2/library/abc.html



## 11. 构建描述符对象
描述符是一些能通过访问getting, setting和deleting来改变其他对象的类. 描述符不是独立存在的, 它需要一个所有者(owner)对象的支撑. 当建造的面向对象数据库或类的属性值依赖于其他数据库或类时, 描述符就很有用了；当表示不同计量单元下的属性或表示计算的属性时, 描述符也很有用. 
为了创建一个描述符, 类中必须由__get__, __set__和__delete__的定义. 
* `__get__(self, instance, owner)`: 定义获取描述符的值时的行为, instance是所有者对象的实例, owner是所有者类本身
* `__set__(self, instance, value)`: 定义描述符的值被修改时的行为, instance是所有者类的实例, value是修改值
* `__delete__(self, instance)`: 定义描述符的值被删除时的卫星, instance是所有者类的实例

下面是一个实例：
```python
class Meter(object):
  def __init__(self, value=0.0):
    self.value = float(value)

  def __get__(self, instance, owner):
    return self.value

  def __set__(self, instance, value):
    self.value = float(value)
 
class Foot(object):
  def __get__(self, instance, owner):
    return instance.meter * 3.2808

  def __set__(self, instance, value):
    instance.meter = float(value) / 3.2808
 
class Distance(object):
  meter = Meter()
  foot = Foot()
```


## 12. 复制
有时处理可变对象时, 需要复制一个对象且不对源对象产生任何副作用, 这时就需要使用Python的copy, 因此我们需要告诉Python如何复制一些东西. 
* `__copy__(self)`: 调用`copy.copy()`时调用该方法, 它返回对象的浅拷贝, 意味着所有的数据都是引用的, 对新复制的对象的修改会作用到源对象
* `__deepcopy__(self, memodict={})`: 调用`copy.deepcopy()`时调用该方法, 返回对象的深拷贝, 意味着所有数据都需拷贝. memodict是一个被拷贝对象的缓存池, 它能优化拷贝行为, 并防止拷贝递归数据结构时引起的无限递归. 当深拷贝一个独立属性时, 可调用`copy.deepcopy()`, 并将memodict作为第一个参数.
 
那么上述方法有什么应用? 通常情况下, 颗粒化管理总比默认的好. 举个例子, 如果你想复制一个在缓存中以字典形式存储的对象, 但直接拷贝缓存是不可能的; 而如果缓存可以在两个实例之间以内存形式存储, 那么就是可行的. 


## 13. Pickling你的对象
如果你跟其他Python使用者接触一段时间, 你至少听说过pickling. Pickling是一个将Python数据结构序列化的过程, 当你需要存储一个对象并在稍后取出时, Pickling十分有用, 但也有很多让人疑惑和忧虑的地方. 
Pickling十分重要, 以至于其不仅有自己的模块(pickle), 还有自己的协议和方法.

### 13.1 Pickling
假设你有一个字典想要先存起来等会儿提取出来. 你可以将它的内容写到文件里, 注意要确保你的语法正确, 使用exec()来剥离或将处理文件输入. 如果你将重要信息存在纯文本中, 任何形式的改变或崩溃都会使得程序崩溃或运行恶意代码. 
```python
import pickle

data = {'foo': [1, 2, 3],
        'bar': ('Hello', 'world!'),
        'baz': True}
jar = open('data.pkl', 'wb')
pickle.dump(data, jar) # 将pickle处理过的数据放入文件jar中
jar.close()
```

几个小时后我们想拿回数据, 这时就需要unpickle
```python
import pickle
 
pkl_file = open('data.pkl', 'rb') # 连接到pickle数据
data = pickle.load(pkl_file) # 将数据加载到data变量中
pkl_file.close()
```
注意, pickling并不是完美的, Pickle文件很容易由于意外而崩溃. Pickle可能比纯文本文件更加安全, 但它也可能用于运行恶意代码. 并且不同版本的Python也不一定兼容, 所以不想期望将pickle对象发送给别人后别人能打开它们. 但它可以作为一种缓存的工具或其他序列化任务. 

### 13.2 Pickle你的对象
Pickle不仅作用于内建类型, 任何类都遵循pickle协议. pickle协议有四个可选项方法来定制化它们的操作. 
* `__getinitargs__(self)`: 如果你不希望你在unpickle时调用`__init__`, 你可以定义该函数, 它会返回你希望返回的参数, 放在一个tuple中. 注意, 该方法只作用在old-style class中. 
* `__getnewargs__(self)`: 对于new-style class, 你可以决定哪些参数传给`__new__`. 该方法也会返回一个tuple给__new__, 里面全是参数. 
* `__getstate__(self)`: 当对象被pickle时, 你可以返回一个定制的状态, 而不是使用`__dict__`的方法. 当对象被unpickle时, 你会在`__setstate__`中用到这个状态值. 
* `__setstate__(self, state)`: 当对象被unpickle时, 如果已经定义了`__setstatue__`, 对象的状态值将会被传入该函数, 而不是直接应用于对象的`__dict__`. 该函数必须和`__getstatue__`一同使用：当两个方法都定义时, 你可表示对象被pickle的任何过程. 
* `__reduce__(self`): 当定义额外类型时, 如果你要pickle它们时, 你必须告诉Python如果pickle它们. 当对象定义他本身如何被pickle时, 就需要调用`__reduce__()`, 它可以返回一个字符串的全局名称或tuple, 这样Python可以查看并pickletuple包括2到5个元素：一个可调用对象来重建对象；一个包含参数的tuple, 服务于可调用对象；状态值传递给`__setstatue__`；用于生成list项的迭代器, 他将被pickle；一个用来生成字典项的迭代, 他也将被pickle. 
* `__reduce_ex__(self)`: 该函数为兼容性存在, 如果该函数被定义, 它将会在pickle时覆盖`__reduce__`. 将会在pickle API为旧版本时调用`__reduce__`, 而不会调用`__reduce_ex__`. 

举个例子：
```python
import time
 
'''
用于存储字符串和更改日志, 并且在pickle时丢弃它们
'''
class Slate:
  def __init__(self, value):
    self.value = value
    self.last_change = time.asctime()
    self.history = {}
 
  def change(self, new_value):
    # 更改数值, 将上一次值添加到history中
    self.history[self.last_change] = self.value
    self.value = new_value
    self.last_change = time.asctime()
 
  def print_changes(self):
    print 'Changelog for Slate object:'
    for k, v in self.history.items():
        print '%s\t %s' % (k, v)
 
  def __getstate__(self):
    # 不要反悔self.value或self.last_change
    # 我们想在unpickle时得到一个"black slate"
    return self.history
 
  def __setstate__(self, state):
    # 将self.history = state, 并将last_change和value设为空
    self.history = state
    self.value, self.last_change = None, None
```
