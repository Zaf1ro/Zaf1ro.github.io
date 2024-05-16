---
title: PyStringObject
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: aaab
date: 2017-03-02 10:41:27
---

## 1. PyStringObject与PyString_Type
由于"Hi"和"Python"是两个不同的`PyStringObject`对象, 其内存是不同的, 且字符串创建后不可改变, 这一特性使得`PyStringObject`可以作为dict的键值, 但字符串操作则大大降低, 例如: 多个字符串的连接操作.
```c
typedef struct {
  PyObject_VAR_HEAD
  long ob_shash;
  int ob_sstate;
  char ob_sval[1];
} PyStringObject;
```
* `ob_size`: 可变对象内存的大小, 例如"Python", 其ob_size为6
* `ob_sval`: 一个字符指针, 指向一段内存, 存储着对应的字符串
* `ob_shash`: 该对象的hash值, 避免每次都要计算hash值; 若还未计算, 则为-1:

```c
static long string_hash(PyStringObject *a)
{
  register Py_ssize_t len;
  register unsigned char *p;
  register long x;

  if (a->ob_shash != -1)
    return a->ob_shash;
  len = a->ob_size;
  p = (unsigned char *) a->ob_sval;
  x = *p << 7;
  while (--len >= 0)
    x = (1000003*x) ^ *p++;
  x ^= a->ob_size;
  if (x == -1)
    x = -2;
  a->ob_shash = x;
  return x;
}
```
`ob_sstate`表示该对象是否经过intern机制的处理, intern机制使得Python虚拟机效率提高了20%. 以下是`PyString_Type`:
```c
PyTypeObject PyString_Type = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,
  "str",
  sizeof(PyStringObject),
  sizeof(char),
  string_dealloc,           /* tp_dealloc */
  (printfunc)string_print,  /* tp_print */
  0,                        /* tp_getattr */
  0,                        /* tp_setattr */
  0,                        /* tp_compare */
  string_repr,              /* tp_repr */
  &string_as_number,        /* tp_as_number */
  &string_as_sequence,      /* tp_as_sequence */
  &string_as_mapping,       /* tp_as_mapping */
  (hashfunc)string_hash,    /* tp_hash */
  0,                        /* tp_call */
  string_str,               /* tp_str */
  PyObject_GenericGetAttr,  /* tp_getattro */
  0,                        /* tp_setattro */
  &string_as_buffer,        /* tp_as_buffer */
  Py_TPFLAGS_DEFAULT |      /* tp_flags */
  Py_TPFLAGS_CHECKTYPES |
  Py_TPFLAGS_BASETYPE,		
  string_doc,               /* tp_doc */
  0,                        /* tp_traverse */
  0,                        /* tp_clear */
  (richcmpfunc)string_richcompare,  /* tp_richcompare */
  0,                        /* tp_weaklistoffset */
  0,                        /* tp_iter */
  0,                        /* tp_iternext */
  string_methods,           /* tp_methods */
  0,                        /* tp_members */
  0,                        /* tp_getset */
  &PyBaseString_Type,       /* tp_base */
  0,                        /* tp_dict */
  0,                        /* tp_descr_get */
  0,                        /* tp_descr_set */
  0,                        /* tp_dictoffset */
  0,                        /* tp_init */
  0,                        /* tp_alloc */
  string_new,               /* tp_new */
  PyObject_Del,             /* tp_free */
};
```
Python中的变长对象都有`tp_itemsize`, 表示单个元素的单位长度, PyStringObject的`tp_itemsize`为`sizeof(char)`


## 2. 创建PyStringObject对象
Python中有两种方式创建`PyStringObject`对象, 第一种为`PyString_FromString`:
```c
PyObject* PyString_FromString(const char *str)
{
  register size_t size;
  register PyStringObject *op;

  assert(str != NULL);

  // 判断字符串是否超长
  size = strlen(str);
  if (size > PY_SSIZE_T_MAX - sizeof(PyStringObject)) {
    PyErr_SetString(PyExc_OverflowError,
      "string is too long for a Python string");
    return NULL;
  }

  // 处理null string
  if (size == 0 && (op = nullstring) != NULL) {
    Py_INCREF(op);
    return (PyObject *)op;
  }

  // 处理单个字符
  if (size == 1 && (op = characters[*str & UCHAR_MAX]) != NULL) {
    Py_INCREF(op);
    return (PyObject *)op;
  }

  // 创建新的PyStringObject对象, 并初始化
  /* Inline PyObject_NewVar */
  op = (PyStringObject *)PyObject_MALLOC(sizeof(PyStringObject) + size);
  if (op == NULL)
    return PyErr_NoMemory();
  PyObject_INIT_VAR(op, &PyString_Type, size);
  op->ob_shash = -1;
  op->ob_sstate = SSTATE_NOT_INTERNED;
  Py_MEMCPY(op->ob_sval, str, size+1);
  /* share short strings */
  if (size == 0) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    nullstring = op;
    Py_INCREF(op);
  } else if (size == 1) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    characters[*str & UCHAR_MAX] = op;
    Py_INCREF(op);
  }
  return (PyObject *) op;
}
```
`PY_SSIZE_T_MAX`表示单个字符串的最大长度, 默认为2GB.
并不是每个空字符串传入Python都需要创建对象, Python运行时有一个`PyStringObject`对象指针**nullstring**专门负责空字符串. 由于nullstring初始化为NULL, 因此Python会为nullstring创建一个`PyStringObject`对象, 将这个对象通过intern机制共享, 并将nullstring指向这个被共享的对象. 若需要创建一个空字符串的`PyStringObject`对象, 且nullstring已经存在, 则直接返回nullstring的引用.
除了空字符串和单个字符, 剩下的就是创建新的`PyStringObject`对象: 申请内存, 将hash值设为-1, 将intern设为`SSTATE_NOT_INTERNED`, 并将字符拷贝到`PyStringObject`所维护的空间中. 以下是内存的状态图:
![PyStringObject内存状态](/images/Python/PyStringObject-1.png)

另一种创建`PyStringObject`对象的方式为`PyString_FromStringAndSize`:
```c
PyObject* PyString_FromStringAndSize(const char *str, Py_ssize_t size)
{
  register PyStringObject *op;
  if (size < 0) {
    PyErr_SetString(PyExc_SystemError,
      "Negative size passed to PyString_FromStringAndSize");
    return NULL;
  }
  
  if (size == 0 && (op = nullstring) != NULL) {
    Py_INCREF(op);
    return (PyObject *)op;
  }

  if (size == 1 && str != NULL &&
    (op = characters[*str & UCHAR_MAX]) != NULL) {
    Py_INCREF(op);
    return (PyObject *)op;
  }

  if (size > PY_SSIZE_T_MAX - sizeof(PyStringObject)) {
    PyErr_SetString(PyExc_OverflowError, "string is too large");
    return NULL;
  }

  /* Inline PyObject_NewVar */
  op = (PyStringObject *)PyObject_MALLOC(sizeof(PyStringObject) + size);

  if (op == NULL)
    return PyErr_NoMemory();

  PyObject_INIT_VAR(op, &PyString_Type, size);
  op->ob_shash = -1;
  op->ob_sstate = SSTATE_NOT_INTERNED;

  if (str != NULL)
    Py_MEMCPY(op->ob_sval, str, size);
  op->ob_sval[size] = '\0';

  /* share short strings */
  if (size == 0) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    nullstring = op;
    Py_INCREF(op);
  } else if (size == 1 && str != NULL) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    characters[*str & UCHAR_MAX] = op;
    Py_INCREF(op);
  }
  return (PyObject *) op;
}
```
`PyString_FromString`要求传入的字符串必须以`\0`结尾; `PyString_FromStringAndSize`则没有这样的要求, 因为size参数可以确定字符个数.


## 3. 字符串对象的intern机制
在字符串对象创建的过程中, 有一个函数: `PyString_InternInPlace`. 这就是intern机制:
```c
PyObject* PyString_FromString(const char *str)
{
  register size_t size;
  register PyStringObject *op;

  /* ... */

  if (size == 0) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    nullstring = op;
    Py_INCREF(op);
  } else if (size == 1) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    characters[*str & UCHAR_MAX] = op;
    Py_INCREF(op);
  }
  return (PyObject *) op;
}
```
由于很多字符会被多次使用, 若每次使用字符串都重新创建对象并分配空间, 则会浪费很多内存空间. 若`PyStringObject`对象使用intern机制, 那么创建相同字符串时, 会先通过intern机制来查找是否存在相同的`PyStringObject`对象, 如果有, 则返回该对象的引用.
```c
void PyString_InternInPlace(PyObject **p)
{
  register PyStringObject *s = (PyStringObject *)(*p);
  PyObject *t;
  if (s == NULL || !PyString_Check(s))
    Py_FatalError("PyString_InternInPlace: strings only please!");
    /* If it's a string subclass, we don't really know what putting
     it in the interned dict might do. */
  
  // 对PyStringObject进行类型和状态检查
  if (!PyString_CheckExact(s))
    return;
  if (PyString_CHECK_INTERNED(s))
    return;
  
  // 创建interned的dict
  if (interned == NULL) {
    interned = PyDict_New();
    if (interned == NULL) {
      PyErr_Clear(); /* Don't leave an exception */
      return;
    }
  }

  // 检查intern的dict, 查看是否有对应的PyStringObject对象
  t = PyDict_GetItem(interned, (PyObject *)s);
  if (t) {
    Py_INCREF(t);
    Py_DECREF(*p);
    *p = t;
    return;
  }

  // interned的dict中没有该对象, 在dict中创建新的PyStringObject对象
  if (PyDict_SetItem(interned, (PyObject *)s, (PyObject *)s) < 0) {
    PyErr_Clear();
    return;
  }
  /* The two references in interned are not counted by refcnt.
     The string deallocator will take care of this */
  s->ob_refcnt -= 2;

  // 调整interned中该PyStringObject的状态
  PyString_CHECK_INTERNED(s) = SSTATE_INTERNED_MORTAL;
}
```

intern机制的关键在于`interned`的dict, 类似于C++的map, 即`map<PyObject*, PyObject*>`. 以下是`PyStringObject`对象未能在interned中找到相同对象时的操作:
![未在interned中找到相同对象](/images/Python/PyStringObject-2.png)

以下是PyStringObject在interned中找到相同对象的情况:
![在interned中找到相同对象](/images/Python/PyStringObject-3.png)

在进行`PyDict_SetItem`函数操作中, a的引用会进行两次+1, 所以退出intern机制之前必须减去这两个引用, 才能保证a会被删除. 当a的引用个数降为0时, 将会从interned中删除a该对象:
```c
static void string_dealloc(PyObject *op)
{
  switch (PyString_CHECK_INTERNED(op)) {
    case SSTATE_NOT_INTERNED:
      break;

    case SSTATE_INTERNED_MORTAL:
      /* revive dead object temporarily for DelItem */
      op->ob_refcnt = 3;
      if (PyDict_DelItem(interned, op) != 0)
        Py_FatalError("deletion of interned string failed");
      break;

    case SSTATE_INTERNED_IMMORTAL:
      Py_FatalError("Immortal interned string died.");

    default:
      Py_FatalError("Inconsistent interned string state.");
  }
  op->ob_type->tp_free(op);
}
```
可以看出, 虽然intern机制节约了空间, 但还是会有临时的`PyStringObject`对象被创建. 在`PyDict_GetItem`函数中, 一旦找到相同的字符串, 就会调用`Py_DECREF()`来销毁这个临时对象.
被intern机制处理过的`PyStringObject`对象有两种状态:
* SSTATE_INTERNED_IMMORTAL: 永远不会被销毁
* SSTATE_INTERNED_MORTAL: 可被销毁


## 4. 字符缓冲池
`PyStringObject`与`PyIntObject`相同, 也为单字符的`PyStringObject`对象提供了对象池`characters`:
```c
static PyStringObject* characters[UCHAR_MAX + 1];
```
`UCHAR_MAX`是系统头文件中定义的常量, Win32平台下:
```c
#define UCHAR_MAX 0xff /* maximum unsigned char value */
```
Python初始化完成后, characters的所有`PyStringObject`指针都为空. 当创建的`PyStringObject`对象为单字符时:
```c
PyObject* PyString_FromStringAndSize(const char *str, Py_ssize_t size)
{
  /* ...... */
  } else if (size == 1 && str != NULL) {
    PyObject *t = (PyObject *)op;
    PyString_InternInPlace(&t);
    op = (PyStringObject *)t;
    characters[*str & UCHAR_MAX] = op;
    Py_INCREF(op);
  }
  return (PyObject *) op;
}
```
先进行intern操作, 再将intern的结果缓存到characters中:
![characters缓存区操作](/images/Python/PyStringObject-4.png)

下次创建单个字符的对象时, 会先从characters缓存找出相同对象并返回该对象
```c
PyObject* PyString_FromStringAndSize(const char *str, Py_ssize_t size)
{
  register PyStringObject *op;

  /* ...... */

  if (size == 1 && str != NULL &&
      (op = characters[*str & UCHAR_MAX]) != NULL) {
    Py_INCREF(op);
    return (PyObject *)op;
  }

  /* ...... */
}
```


## 5. PyStringObject效率问题
Python的字符串连接效率很低, 因为当使用"+"连接两个字符串时, 由于`PyStringObject`是不可变对象, 必须先创建一个新的`PyStringObject`对象. 如果要连接N个字符串, 那么需要N-1次内存申请, 每次调用`string_concat`函数:
```c
static PyObject *string_concat(register PyStringObject *a, register PyObject *bb)
{
  register Py_ssize_t size;
  register PyStringObject *op;

  /* ...... */
  
  // 计算字符串连接后的长度size
  size = a->ob_size + b->ob_size;

  // 检查a和b的字符串长度
  if (a->ob_size < 0 || b->ob_size < 0 ||
      a->ob_size > PY_SSIZE_T_MAX - b->ob_size) {
    PyErr_SetString(PyExc_OverflowError, "strings are too large to concat");
    return NULL;
  }
    
  // 检查字符串长度
  if (size > PY_SSIZE_T_MAX - sizeof(PyStringObject)) {
    PyErr_SetString(PyExc_OverflowError, "strings are too large to concat");
    return NULL;
  }
  // 创建新的PyStringObject对象, 维护的内存长度为size
  op = (PyStringObject *)PyObject_MALLOC(sizeof(PyStringObject) + size);
  if (op == NULL)
    return PyErr_NoMemory();
  PyObject_INIT_VAR(op, &PyString_Type, size);
  op->ob_shash = -1;
  op->ob_sstate = SSTATE_NOT_INTERNED;

  // 将a和b的字符拷贝到新的PyStringObject中
  Py_MEMCPY(op->ob_sval, a->ob_sval, a->ob_size);
  Py_MEMCPY(op->ob_sval + a->ob_size, b->ob_sval, b->ob_size);
  op->ob_sval[size] = '\0';
  return (PyObject *) op;
}
```

Python官方推荐使用`join()`来实现`PyStringObject`对象连接:
```c
static PyObject* string_join(PyStringObject *self, PyObject *orig)
{
  char *sep = PyString_AS_STRING(self);

  // 假设调用"abc".join(list), 参数self就是"abc", 参数list是orig
  const Py_ssize_t seplen = PyString_GET_SIZE(self);
  PyObject *res = NULL;
  char *p;
  Py_ssize_t seqlen = 0;
  size_t sz = 0;
  Py_ssize_t i;
  PyObject *seq, *item;

  // 将list中每个PyStringObject对象的个数保存在seqlen中
  /* ...... */

  // 遍历list中的每个字符串, 并获得整个字符串长度
  for (i = 0; i < seqlen; i++) {
    const size_t old_sz = sz;
    item = PySequence_Fast_GET_ITEM(seq, i);
    if (!PyString_Check(item)){
      PyErr_Format(PyExc_TypeError,
             "sequence item %zd: expected string,"
             " %.80s found",
             i, item->ob_type->tp_name);
      Py_DECREF(seq);
      return NULL;
    }
    sz += PyString_GET_SIZE(item);
    if (i != 0)
      sz += seplen;
    if (sz < old_sz || sz > PY_SSIZE_T_MAX) {
      PyErr_SetString(PyExc_OverflowError, "join() result is too long for a Python string");
      Py_DECREF(seq);
      return NULL;
    }
  }

  /* 为新的PyStringObject对象分配空间 */
  res = PyString_FromStringAndSize((char*)NULL, sz);
  if (res == NULL) {
    Py_DECREF(seq);
    return NULL;
  }

  /* 将list中的字符全部拷贝到新的PyStringObject对象中 */
  p = PyString_AS_STRING(res);
  for (i = 0; i < seqlen; ++i) {
    size_t n;
    item = PySequence_Fast_GET_ITEM(seq, i);
    n = PyString_GET_SIZE(item);
    Py_MEMCPY(p, PyString_AS_STRING(item), n);
    p += n;
    if (i < seqlen - 1) {
      Py_MEMCPY(p, sep, seplen);
      p += seplen;
    }
  }

  Py_DECREF(seq);
  return res;
}
```
`join()`会统计list中所有`PyStringObject`对象的长度和个数, 并一次性申请内存. 所以, list中`PyStringObject`对象的个数越多, 效率提高的越明显.
