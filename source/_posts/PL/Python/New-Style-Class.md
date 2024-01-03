---
title: New Style Class
category:
  - Python
  - Source Code
tag:
  - Python
abbrlink: 3f85
date: 2017-03-16 10:52:39
---

## 1. Python中的对象模型
Python2.2之前内置的type(例如int, dict)与定义的class并不完全相同. Python在2.2版本之后弥补了这个鸿沟, 使得两者能在概念上实现了一致, 该机制称作**new style class**机制.
Python2.2前有三种对象:
* type: Python内置类型
* class: 程序员创建的类型
* instance: 由class创建的实例

Python2.2后只有两种对象:
* class对象: 内置类型和程序员创建的类型
* instance对象: 由class创建的实例

### 1.1 对象间的关系
Python的对象间存在两种关系:
* is-kind-of: 父类与子类之间的关系
* is-instance-of: 类与实例之间的关系

例如:
```python
class A(object):
  pass

a = A()
```
这其中包含三个对象:
* `object`(class对象)
* `A`(class对象)
* `a`(instance对象)

其中, object和A之间为is-kind-of关系, A和object之间为is-instance-of关系.
Python提供了两种内置方法`issubclass`和`isinstanceof`来判断两个对象间是否存在is-kind-of和is-instance-of关系.
```python
>>> a.__class__
<class '__main__.A'>
>>> type(a)
<class '__main__.A'>

>>> A.__class__
<type 'type'>
>>> type(A)
<type 'type'>

>>> object.__class__
<type 'type'>
>>> type(object)
<type 'type'>

>>> A.__bases__
(<type 'object'>,)
>>> object.__bases__
()
>>> a.__bases__

Traceback (most recent call last):
File "<pyshell#5>", line 1, in <module>
  a.__bases__
AttributeError: 'A' object has no attribute '__bases__'
```

可以看到, 并不是所有对象都有is-kind-of关系, 只有class对象之间才存在is-kind-of关系. 下图更能说明三者的关系:
![对象关系图](/images/Python/new-style-class-1.png)

### 1.2 `<type 'type'>`和`<type 'object'>`
上图之所以将object和A放在一起, 因为他们都属于`<type 'type'>`. `<type 'type'>`是一种特殊的class, 其可作为其他class对象的type, 因此也称为**metaclass**.
Python中还有一个特殊的class: `<type 'object'>`, 任何class都必须直接或间接继承该class. 下面是`<type 'type'>`和`<type 'object'>`的关系:
```python
>>> object.__class__
<type 'type'>
>>> type.__class__
<type 'type'>
>>> type.__bases__
(<type 'object'>,)

>>> int.__class__
<type 'type'>
>>> int.__bases__
(<type 'object'>,)
>>> dict.__class__
<type 'type'>
>>> dict.__bases__
(<type 'object'>,)
```

![对象之间的关系](/images/Python/new-style-class-2.png)

中间的一列既可作为class又可作为instance, 因为它既可创建新的instance, 也可作为一个instance.


## 2. 从type到class
```python
class MyInt(int):
    def __add__(self, other):
        return int.__add__(self, other) + 10

a = MyInt(1)
b = MyInt(2)
print a + b
```

上述代码从int类型继承并生成一个新的整数类型, 做加法时会在原有的和上再加10. 调用`int.__add__`时, 需要`PyInt_Type`完成加法操作. 但Python虚拟机如何从`int.__add__`知道要调用`PyInt_Type.tp_as_number.nb_add`呢? 由于Python2.2之前的内置类型没有寻找某个属性的机制, 所以不能继承内置类型.
调用`int.__add__`时, 会通过`PyInt_Type`中`tp_dict`所指向的dict对象中查找`__add__`所对应的函数, 并调用该函数. 如下图:
![粗略的<type 'int'>示例图](/images/Python/new-style-class-3.png)

Python中有一个非常重要的概念: **可调用性**. 只要对象实现了`__call__`, 则该对象就会成为一个可调用对象. "调用"就是执行`tp_call`操作:
```python
>>> class A(object):
      def __call__(self):
        print "Hello Python"

>>> a = A()
>>> a()
Hello Python
```

C++中可通过**重载**来实现Functor. Python则通过调用`PyObject_Call`函数来对a进行操作, 从而调用`__call__`, 实现可调用性. 若对象不可调用, 则抛出异常:
```python
>>> def f():
      i = 1
      i()

>>> f()

Traceback (most recent call last):
File "<pyshell#4>", line 1, in <module>
  f()
File "<pyshell#3>", line 3, in f
  i()
TypeError: 'int' object is not callable
```

上述代码编译成功, 但是运行时抛出异常, 说明可调用性不是编译期间决定的, 而是运行时决定的. 从Python2.2开始, 每次启动Python都会对对象系统进行初始化, 并动态地向`PyTypeObject`中填充一些东西(如果忘了什么是PyTypeObject, 可以参考[Python的PyObject](http://zaf1ro.github.io/p/1c3f), PyObject中的`_typeobject`就是`PyTypeObject`, 其中也包括`tp_dict`), 从而完成从type对象到class对象的转变, 这一系列初始化的操作从`_Py_ReadyTypes`开始. 

### 2.1 处理父类和type信息
```c
int PyType_Ready(PyTypeObject *type)
{
  PyObject *dict, *bases;
  PyTypeObject *base;
  Py_ssize_t i, n;

  if (type->tp_flags & Py_TPFLAGS_READY) {
    assert(type->tp_dict != NULL);
    return 0;
  }
  assert((type->tp_flags & Py_TPFLAGS_READYING) == 0);

  type->tp_flags |= Py_TPFLAGS_READYING;

  /* 尝试获得type的tp_base中指定父类 */
  base = type->tp_base;
  if (base == NULL && type != &PyBaseObject_Type) {
    base = type->tp_base = &PyBaseObject_Type;
    Py_INCREF(base);
  }

  /* Now the only way base can still be NULL is if type is
    * &PyBaseObject_Type.
    */

  /* 初始化父类 */
  if (base && base->tp_dict == NULL) {
    if (PyType_Ready(base) < 0)
      goto error;
  }

  /* 设置type信息 */
  if (type->ob_type == NULL && base != NULL)
    type->ob_type = base->ob_type;

    /* ...... */
}
```

Python会首先尝试获得该类型的父类, 这个信息在`PyTypeObject.tp_base`中指定, 下列是内置class对象的`tp_base`信息:

class对象 | 父类信息
-----|-----
PyType_Type | NULL
PyInt_Type | NULL
PyBool_Type | &PyInt_Type

如果tp_base内置了class对象, 则用指定的父类; 如果没有, 则使用默认父类: `PyBaseObject_Type`, 也就是`<type 'object'>`. 所以Python所有class对象都直接或间接以`<type 'object'>`作为父类, 由于`PyType_Type`也以`<type 'object'>`作为父类.
之后Python会判断父类是否初始化, 通过判断base->tp_dict是否为NULL.
最后设置对象的`ob_type,` 也就是metaclass. Python直接将父类的metaclass作为子类的metaclass. `PyType_Type`的metaclass为`<type 'object'>`的metaclass, 而`PyBaseObject_Type`的`ob_type`为`PyType_Type`, 所以`PyType_Type`的metaclass为其自身.

### 2.2 处理父类列表
由于Python支持多重继承, 所以每个class对象都有一个父类列表:
```c
int PyType_Ready(PyTypeObject *type)
{
  PyObject *dict, *bases;
  PyTypeObject *base;
  Py_ssize_t i, n;

  /* ...... */

  base = type->tp_base;
  if (base == NULL && type != &PyBaseObject_Type) {
    base = type->tp_base = &PyBaseObject_Type;
    Py_INCREF(base);
  }

  /* ...... */

  bases = type->tp_bases;
  if (bases == NULL) {
    if (base == NULL)
      bases = PyTuple_New(0);
    else
      bases = PyTuple_Pack(1, base);
    if (bases == NULL)
      goto error;
    type->tp_bases = bases;
  }

    /* ...... */
}
```

对于`PyBaseObject_Type`, `tp_base`为NULL, `base`也为NULL, 所以父类列表为空tuple.
对于`PyType_Type`和其他类型, 例如`PyInt_Type`, 虽然`tp_bases`为NULL, 但`base`为`&PyBaseObject_Type`. 所以它们的父类不为NULL, 而是包含一个`PyBaseObject_Type`.

### 2.3 填充tp_dict
```c
int PyType_Ready(PyTypeObject *type)
{
  PyObject *dict, *bases;
  PyTypeObject *base;
  Py_ssize_t i, n;

  /* ...... */

  /* 初始化tp_dict */
  dict = type->tp_dict;
  if (dict == NULL) {
    dict = PyDict_New();
    if (dict == NULL)
      goto error;
    type->tp_dict = dict;
  }

  /* 将类型相关的descriptor加入到tp_dict中 */
  if (add_operators(type) < 0)
    goto error;
  if (type->tp_methods != NULL) {
    if (add_methods(type, type->tp_methods) < 0)
      goto error;
  }
  if (type->tp_members != NULL) {
    if (add_members(type, type->tp_members) < 0)
      goto error;
  }
  if (type->tp_getset != NULL) {
    if (add_getset(type, type->tp_getset) < 0)
      goto error;
  }

  /* ...... */
}
```

该阶段将各种操作,属性等加入到`PyTypeObject`中. 但Python又是如何将`__add__`和`nb_add`关联起来的: Python其实将这种关联放在了`slotdefs`的全局数组中

#### 2.3.1 slot与操作排序
Python中用slot来表示`PyTypeObject`中的操作, 一个操作对应一个slot. slot中不仅仅是函数指针, 还包括其他信息.
```c
typedef struct wrapperbase slotdef;

struct wrapperbase {
  char* name;
  int offset;
  void* function;
  wrapperfunc wrapper;
  char* doc;
  int flags;
  PyObject* name_strobj;
};
```

slot中name是操作对应的名称, 例如`__add__`; offset表示函数地址在`PyHeapTypeObject`中的偏移量; function指向名为slot的函数.
Python提供了多个宏来定义slot, 最基本的是`TPSLOT`和`ETSLOT`
```c
#define TPSLOT(NAME, SLOT, FUNCTION, WRAPPER, DOC) \
  {NAME, offsetof(PyTypeObject, SLOT), (void *)(FUNCTION), WRAPPER, PyDoc_STR(DOC)}

#define ETSLOT(NAME, SLOT, FUNCTION, WRAPPER, DOC) \
  {NAME, offsetof(PyHeapTypeObject, SLOT), (void *)(FUNCTION), WRAPPER, PyDoc_STR(DOC)}

#define offsetof(type, member)((int) & ((type*)0)->member)
```

TPSLOT中的offset是`PyTypeObject`的偏移量, ETSLOT计算的是`PyHeapTypeObject`的偏移量. 由于`PyHeapTypeObject`的第一个域为`PyTypeObject`, 所以TPSLOT计算的offset也是`PyHeapTypeObject`的offset.
对于`nb_add`来说, 函数指针放在`PyNumberMethods`中, 而`PyTypeObject`却通过`tp_as_number`指向另一个`PyNumberMethods`结构. 所以offset根本没法用于`PyTypeObject`中偏移量的计算, 只能计算`PyHeapObject`中的偏移量.
```c
typedef struct _heaptypeobject {
  PyTypeObject ht_type;
  PyNumberMethods as_number;
  PyMappingMethods as_mapping;
  PySequenceMethods as_sequence; 
  PyBufferProcs as_buffer;
  PyObject *ht_name, *ht_slots;
} PyHeapTypeObject;
```

然后`PyInt_Type`是一个`PyTypeObject`, 而offset针对的是`PyHeadTypeObject`, 无论如何都不能从`PyHeapTypeObject`中偏移到`PyTypeObject`.
offset主要为操作进行排序, 先看slotdefs:
```c
#define SQSLOT(NAME, SLOT, FUNCTION, WRAPPER, DOC) \
  ETSLOT(NAME, as_sequence.SLOT, FUNCTION, WRAPPER, DOC)

static slotdef slotdefs[] = {
  /* ...... */

  BINSLOT("__add__", nb_add, slot_nb_add,
    "+"),
  RBINSLOT("__radd__", nb_add, slot_nb_add,
     "+"),

  SQSLOT("__getitem__", sq_item, slot_sq_item, wrap_sq_item,
    "x.__getitem__(y) <==> x[y]"),
  MPSLOT("__getitem__", mp_subscript, slot_mp_subscript,
    wrap_binaryfunc, 
    "x.__getitem__(y) <==> x[y]"),

  /* ...... */
}
```

BINSLOT, SQSLOT都是对ETSLOT的一个简单包装, 而且操作名(例如`__add__`)和操作函数并不是一一对应, 因为多个操作可能对应着同一个操作名. 
当某个类型调用某个操作时, 就需要决定调用哪个操作函数. 例如:
```python
>>> class A(list):
      pass

>>> a = A()
>>> a.append(1)
>>> print a[0]
```

上述代码中A的`__getitem__`对应`PyList_Type`中的`mp_subscript`和`sq_item`, 最后选择的是`list_subscript`. 其中某个操作函数被调用就涉及操作优先级的问题, 这时就需要offset来区分优先级. 这个例子中, `offset(mp_subscript) < offset(sq_item)`
整个slotdefs的排序在`init_slotdefs`中完成:
```c
static void init_slotdefs(void)
{
  slotdef *p;
  static int initialized = 0;

  if (initialized)	// 只会初始化一次
    return;

  for (p = slotdefs; p->name; p++) {
    // 填充slotdef中的name_strobj
    p->name_strobj = PyString_InternFromString(p->name);
    if (!p->name_strobj)
      Py_FatalError("Out of memory interning slotdef names");
  }
  // 
  qsort(
    (void *)slotdefs, (size_t)(p-slotdefs), sizeof(slotdef), slotdef_cmp
  );
  initialized = 1;
}

static int slotdef_cmp(const void *aa, const void *bb)
{
  const slotdef *a = (const slotdef *)aa, *b = (const slotdef *)bb;
  int c = a->offset - b->offset;
  if (c != 0)
    return c;
  else
    /* Cannot use a-b, as this gives off_t, 
     * which may lose precision when converted to int.
     */
    return (a > b) ? 1 : (a < b) ? -1 : 0;
}
```

#### 2.3.2 从slot到descriptor
tp_dict作为一个字典, 与`__getitem__`相关联的一定不是一个slot, 因为slot不是一个PyObject, 无法作为字典的键值. 并且slot由于不是一个PyObject, 所以也无法被调用.
所以就需要一个PyObject来包装slot, 这样才能和`__getitem__`关联起来, 并将这个PyObject称之为descriptor.
Python内部含有多个decriptor, 与`PyTypeObject`对应的是`PyWrapperDescrObject`. 一个descriptor包含一个slot, 下面是descriptor的创建函数`PyDescr_NewWrapper`:
```c
#define PyDescr_COMMON \
  PyObject_HEAD \
  PyTypeObject *d_type; \
  PyObject *d_name

typedef struct {
  PyDescr_COMMON;
  struct wrapperbase *d_base;
  void *d_wrapped; /* 存放函数指针, 完成映射 */
} PyWrapperDescrObject;


static PyDescrObject* descr_new(PyTypeObject *descrtype, PyTypeObject *type, const char *name)
{
  PyDescrObject *descr;

  descr = (PyDescrObject *)PyType_GenericAlloc(descrtype, 0);
  if (descr != NULL) {
    Py_XINCREF(type);
    descr->d_type = type;
    descr->d_name = PyString_InternFromString(name);
    if (descr->d_name == NULL) {
      Py_DECREF(descr);
      descr = NULL;
    }
  }
  return descr;
}


PyObject* PyDescr_NewWrapper(PyTypeObject *type, struct wrapperbase *base, void *wrapped)
{
  PyWrapperDescrObject *descr;

  descr = (PyWrapperDescrObject *)descr_new(&PyWrapperDescr_Type,
            type, base->name);
  if (descr != NULL) {
    descr->d_base = base;
    descr->d_wrapped = wrapped;
  }
  return (PyObject *)descr;
}
```

`PyDescr_COMMON`作为每一种descriptor的基础部分, `d_type`作为参数type(`PyWrapperDescrObject`的type为`PyWrapperDescr_Type`), `d_wrapped`作为函数指针. 对于`PyList_Type`来说, `tp_dict["__getitem__"].d_wrapped`为`&mp_subscript`, slot存放在`d_base`中.

#### 2.3.3 建立联系
函数排序的结果仍放在slotdefs中, 但Python会从头到尾扫描slotdefs并为每一个slotdef创建一个descriptor, 然后为每一个操作名创建与descriptor的关联, 整个创建过程如下:
```c
static int add_operators(PyTypeObject *type)
{
  PyObject *dict = type->tp_dict;
  slotdef *p;
  PyObject *descr;
  void **ptr;

  init_slotdefs();  // 函数排序
  for (p = slotdefs; p->name; p++) {
    if (p->wrapper == NULL)
      continue;
    ptr = slotptr(type, p->offset); // 获得函数指针

    // 函数不存在
    if (!ptr || !*ptr)  
      continue;

    // tp_dict中该操作名已有对应的函数
    if (PyDict_GetItem(dict, p->name_strobj))  
      continue;

    // 为该slot创建descriptor
    descr = PyDescr_NewWrapper(type, p, *ptr);
    if (descr == NULL)
      return -1;

    // 绑定函数名和descriptor
    if (PyDict_SetItem(dict, p->name_strobj, descr) < 0)
      return -1;
    Py_DECREF(descr);
  }
  return 0;
}
```
上述代码的功能的难点在于slotptr函数, 它通过slot中的offset将type中的函数指针找出来. 但问题在于: offset是相对于PyHeapTypeObject, PyHeapTypeObject中包含了PyNumberMethods结构体, 但PyTypeObject中只包含了`PyNumberMethods*`. 所以offset对于PyTypeObject不可用, 必须经过转换.
举个例子来说, 假如调用`slotptr(&PyList_Type, offset(PyHeapTypeObject, mp_subscript))`, 首先由于`mp_subscript`的offset大于`as_mapping`的offset, 所以应先找到`as_mapping`指针, 然后从`as_mapping`指针开始进行偏移, 偏移量delta为:
```c
delta = offset(PyHeapTypeObject, mp_subscript) - offset(PyHeapTypeObject, as_mapping)
```

slotptr的完整实现如下:
```c
static void** slotptr(PyTypeObject *type, int ioffset)
{
  char *ptr;
  long offset = ioffset;

  assert(offset >= 0);

  // 从PySequenceMethods开始判断
  assert((size_t)offset < offsetof(PyHeapTypeObject, as_buffer));

  if ((size_t)offset >= offsetof(PyHeapTypeObject, as_sequence)) {
    ptr = (char *)type->tp_as_sequence;
    offset -= offsetof(PyHeapTypeObject, as_sequence);
  } else if ((size_t)offset >= offsetof(PyHeapTypeObject, as_mapping)) {
    ptr = (char *)type->tp_as_mapping;
    offset -= offsetof(PyHeapTypeObject, as_mapping);
  } else if ((size_t)offset >= offsetof(PyHeapTypeObject, as_number)) {
    ptr = (char *)type->tp_as_number;
    offset -= offsetof(PyHeapTypeObject, as_number);
  } else {
    ptr = (char *)type;
  }

  if (ptr != NULL)
    ptr += offset;
  return (void **)ptr;
}
```

之所以先从PySequenceMethods开始判断, 是因为PySequenceMethods更靠后; 如果先从靠前的位置开始判断, 那么就会错过靠后的位置, 从而导致偏移量计算错误.
![add_operators完成后的PyList_Type](/images/Python/new-style-class-4.png)
从`tp_as_mapping`延伸出去的`list_as_mapping`编译时就定义好了, 但`tp_dict`是运行时再创建. 通过`add_operators`为`PyType_Type`添加一些operators后, 还会通过`add_methods`, `add_members`和`add_getsets`添加`tp_methods`, `tp_members`和`tp_getset`函数集. 
虽然和`add_operators`类似, 但添加的descriptor不是PyWrapperDescrObject, 而分别是PyMethodDescrObject, PyMemberDescrObject和PyGetSetDescrObject.

#### 2.3.4 确定MRO
MRO(Method Resolve Order)是一个class对象的属性解析顺序, 由于Python支持多重继承, 所以必须设置如何顺序解析属性
```python
class A(list):
  def show(self):
    print "A::show"

class B(list):
  def show(value):
    print "B::show"

class C(A):
  pass

class D(C, B):
  pass

d = D()
d.show()
```

由于D的父类A和B中都实现了show, 那么调用`d.show()`时, 该调用谁的`show()`. Python在`PyType_Ready`中通过`mro_internal`函数完成了对一个类型的mro顺序的建立. Python通过创建一个tuple对象来依次存储一组class对象, class对象的顺序就是Python解析属性时的mro顺序. 最终这个tuple被保存在`PyTypeObject.tp_mro`中.
Python在内部创建一个list, 根据D的声明顺序放入D和D的父类:
![D建立mro列表时Python内部的辅助list](/images/Python/new-style-class-5.png)

list的最后一项包含D的所有直接父类. Python从左向右遍历该list, 当访问到list钟任一个父类时, 如果父类存在mro列表, 则会访问父类的mro列表. 以下是遍历list的整个过程:
* 获得D, D的mro列表(tp_mro)中没有D, 放入D
* 获得C, D的mro列表没有C, 所以放入C, 由于C也有mro列表, 所以开始访问C的mro列表
  * 获得A, D的mro列表没有A, 放入A
  * 获得A的list, 但由于后面B的mro列表也有list, 那么A的list将被推迟
  * 获得object, 并将object的处理推迟
* 获得B, D的mro没有B, 所以放入B, 转而访问B的mro列表:
  * 获得list, 将list放入D的mro列表
  * 获得object, 将object放入D的mro列表

遍历结束后D的mro列表就完成了tuple的创建: `(D, C, A, B, list, object)`
```python
>>> print D.__mro__
(<class '__main__.D'>, <class '__main__.C'>, <class '__main__.A'>, <class '__main__.B'>, <type 'list'>, <type 'object'>)
```

通过改变D的父类列表, 可以确定mro列表的顺序:
![不同顺序下的mro列表](/images/Python/new-style-class-6.png)

#### 2.3.5 继承父类操作
Python确定了mro后会遍历mro列表(`tp_mro`), 并将class对象没有而父类有的操作拷贝到class对象中, 从而完成对父类操作的继承动作. 继承操作在`inherit_slots`中:
```c
int PyType_Ready(PyTypeObject *type)
{
  /* ...... */
  
  bases = type->tp_mro;
  n = PyTuple_GET_SIZE(bases);
  for (i = 1; i < n; i++) {
    PyObject *b = PyTuple_GET_ITEM(bases, i);
    if (PyType_Check(b))
      inherit_slots(type, (PyTypeObject *)b);
  }

  /* ...... */
}
```

`inherit_slots`会进行很多拷贝操作, 这里以`nb_add`为例:
```c
static void inherit_slots(PyTypeObject *type, PyTypeObject *base)
{
  PyTypeObject *basebase;

#define SLOTDEFINED(SLOT) \
  (base->SLOT != 0 && (basebase == NULL || base->SLOT != basebase->SLOT))

#define COPYSLOT(SLOT) \
  if (!type->SLOT && SLOTDEFINED(SLOT)) type->SLOT = base->SLOT

#define COPYNUM(SLOT) COPYSLOT(tp_as_number->SLOT)

  if (type->tp_as_number != NULL && base->tp_as_number != NULL) {
    basebase = base->tp_base;
    if (basebase->tp_as_number == NULL)
      basebase = NULL;
    COPYNUM(nb_add);
    /* ...... */
  }

  /* ...... */
}
```

#### 2.3.6 填充父类中的子类列表
最后一步是设置子类列表, 在每一个PyTypeObject中有一个`tp_subclasses`. 通过调用`add_subclass`向`tp_subclasses`中填充子类对象:
```c
int PyType_Ready(PyTypeObject *type)
{
  PyObject *dict, *bases;
  PyTypeObject *base;
  Py_ssize_t i, n;

  /* ...... */

  bases = type->tp_bases;
  n = PyTuple_GET_SIZE(bases);
  for (i = 0; i < n; i++) {
    PyObject *b = PyTuple_GET_ITEM(bases, i);
    if (PyType_Check(b) && add_subclass((PyTypeObject *)b, type) < 0)
      goto error;
  }

  /* ...... */
}
```

我们可以验证这个子类列表的存在:
```python
>>> int.__subclasses__()
[<type 'bool'>]

>>> dict.__subclasses__()
[<type 'collections.defaultdict'>, <class 'collections.OrderedDict'>, <class 'collections.Counter'>, <type 'StgDict'>]
```

以下是`PyType_Ready`的工作流程:
* 设置类型信息, 父类和父类列表
* 填充`tp_dict`
* 确定mro列表
* 基于mro列表从父类继承操作
* 设置父类的子类列表
