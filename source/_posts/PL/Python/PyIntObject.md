---
title: PyIntObject
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: d2e9
date: 2017-02-26 22:02:13
---

## 1. PyIntObject对象的基本认知
Python的对象可以分为两种:可变对象和不可变对象, `PyIntObject`属于不可变对象. 也就是说, `PyIntObject`的值在创建后就无法修改.
Python中的整数使用十分频繁, 如果每个整数对象都要申请内存创建并在结束后释放内存, 那么运行效率将会大大降低. 为解决该问题, Python使用**整数对象池**.
```c
typedef struct {
  PyObject_HEAD;
  long ob_ival;
} PyIntObject;
```

`PyIntObject`实际上是C中原生类型long的包装. Python中的对象的元信息都是保存在对象的类型对象中, `PyIntObject`的类型对象是`PyInt_Type`:
```c
PyTypeObject PyInt_Type = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,
  "int",
  sizeof(PyIntObject),
  0,
  (destructor)int_dealloc,  /* tp_dealloc */
  (printfunc)int_print,     /* tp_print */
  0,                        /* tp_getattr */
  0,                        /* tp_setattr */
  (cmpfunc)int_compare,     /* tp_compare */
  (reprfunc)int_repr,       /* tp_repr */
  &int_as_number,           /* tp_as_number */
  0,                        /* tp_as_sequence */
  0,                        /* tp_as_mapping */
  (hashfunc)int_hash,       /* tp_hash */
  0,                        /* tp_call */
  (reprfunc)int_repr,       /* tp_str */
  PyObject_GenericGetAttr,  /* tp_getattro */
  0,                        /* tp_setattro */
  0,                        /* tp_as_buffer */
  Py_TPFLAGS_DEFAULT |      /* tp_flags */
  Py_TPFLAGS_CHECKTYPES |
  Py_TPFLAGS_BASETYPE,		
  int_doc,                  /* tp_doc */
  0,                        /* tp_traverse */
  0,                        /* tp_clear */
  0,                        /* tp_richcompare */
  0,                        /* tp_weaklistoffset */
  0,                        /* tp_iter */
  0,                        /* tp_iternext */
  int_methods,              /* tp_methods */
  0,                        /* tp_members */
  0,                        /* tp_getset */
  0,                        /* tp_base */
  0,                        /* tp_dict */
  0,                        /* tp_descr_get */
  0,                        /* tp_descr_set */
  0,                        /* tp_dictoffset */
  0,                        /* tp_init */
  0,                        /* tp_alloc */
  int_new,                  /* tp_new */
  (freefunc)int_free,       /* tp_free */
};
```

下面是`PyIntObject`所支持的操作:
| 函数 | 描述 |
| :----: | :----: |
| int_dealloc | PyIntObject对象的析构操作 |
| int_free | PyIntObject对象的释放操作 |
| int_repr | 转化为PyStringObject对象 |
| int_hash | 获得HASH值 |
| int_print | 打印PyIntObject对象 |
| int_compare | 比较操作 |
| int_as_number | 数值操作集合 |
| int_methods | 成员函数集合 |

下面可以看到两个整数对象如何对比大小:
```c
static int int_compare(PyIntObject* v, PyIntObject* w)
{
  register long i = v->ob_ival;
  register long j = w->ob_ival;
  return (i < j) ? -1 : (i > j) ? 1 : 0;
}
```

下面是`int_as_number`:
```c
stati PyNumberMethods int_as_number = (
  (binaryfunc)int_add,  /*nb_add*/
  (binaryfunc)int_sub,  /*nb_subtract*/
  ......
  (binaryfunc)int_div,  /*nb_floor_divide*/
  int_true_divide,      /*nb_true_divide*/
  0,                    /*nb_inplace_floor_divide*/
  0,                    /*nb_inplace_true_divide*/
)
```

`PyNumberMethods`共有39个函数指针, 但并非所有操作都要实现. 作为一个数值操作的例子, 下面是`PyIntObject`的加法操作:
```c
#define PyInt_AS_LONG(op) (((PyIntObject*)(op))->ob_ival)

#define CONVERT_TO_LONG(obj, lng) \
  if (PyInt_Check(obj)) {         \
    lng = PyInt_AS_LONG(obj);     \
  }                               \
  else {                          \
    Py_INCREF(Py_NotImplemented); \
    return Py_NotImplemented;     \
  }

static PyObject* int_add(PyIntObject *v, PyIntObject *w)
{
  register long a, b, x;
  CONVERT_TO_LONG(v, a);
  CONVERT_TO_LONG(w, b);
  x = a + b;
  if ((x^a) >= 0 || (x^b) >= 0)
    return PyInt_FromLong(x);
  return PyLong_Type.tp_as_number->nb_add((PyObject *)v, (PyObject *)w);
}
```
上述代码中`PyInt_AS_LONG`是一个macro, 节省了一次函数调用; 但该宏没有类型检查, 牺牲了类型安全. 并且`PyIntObject`的add操作并没有改变任何一个对象, 而是生成了一个全新的`PyIntObject`对象. 若加法溢出, 则返回一个`PyLongObject`对象.


## 2. PyIntObject对象创建的3种途径
```c
PyObject* PyInt_FromLong(long ival)

PyObject* PyInt_FromString(char* s, char** pend, int base)

#ifdef Py_USING_UNICODE
  PyObject* PyInt_FromUnicode(Py_UNICODE* s, int length, int base)
#endif
```
`PyInt_FromLong`根据long值生成`PyIntObject`对象, `PyInt_FromString`和`PyInt_FromUnicode`根据string和`Py_UNICODE`生成浮点数, 然后再调用`PyInt_FromFloat`
```c
PyObject* PyInt_FromString(char *s, char **pend, int base)
{
  char *end;
  long x;
  Py_ssize_t slen;
  PyObject *sobj, *srepr;

  if ((base != 0 && base < 2) || base > 36) {
    PyErr_SetString(PyExc_ValueError,
      "int() base must be >= 2 and <= 36");
    return NULL;
  }

  while (*s && isspace(Py_CHARMASK(*s)))
    s++;
  errno = 0;
  if (base == 0 && s[0] == '0') {
    x = (long) PyOS_strtoul(s, &end, base);
    if (x < 0)
      return PyLong_FromString(s, pend, base);
  }
  else
    x = PyOS_strtol(s, &end, base);
  if (end == s || !isalnum(Py_CHARMASK(end[-1])))
    goto bad;
  while (*end && isspace(Py_CHARMASK(*end)))
    end++;
  if (*end != '\0') {
  bad:
    slen = strlen(s) < 200 ? strlen(s) : 200;
    sobj = PyString_FromStringAndSize(s, slen);
    if (sobj == NULL)
      return NULL;
    srepr = PyObject_Repr(sobj);
    Py_DECREF(sobj);
    if (srepr == NULL)
      return NULL;
    PyErr_Format(PyExc_ValueError,
           "invalid literal for int() with base %d: %s",
           base, PyString_AS_STRING(srepr));
    Py_DECREF(srepr);
    return NULL;
  }
  else if (errno != 0)
    return PyLong_FromString(s, pend, base);
  if (pend)
    *pend = end;
  return PyInt_FromLong(x);
}
```


## 3. 小整数对象
实际编程中, 数值较小的整数会频繁使用. 若将所有对象都存储在堆中, 将会频繁申请并释放小整数对象, 导致运行效率降低. Python对小整数对象使用对象池技术, 小整数池的范围如下:
```c
#ifndef NSMALLPOSINTS
  #define NSMALLPOSINTS   257
#endif

#ifndef NSMALLNEGINTS
  #define NSMALLNEGINTS   5
#endif
```
Python2.5的小整数池范围是`[-5, 256]`, 你也可以修改来实现程序运行速度的提升. 对于其他整数, Python会提供一块内存空间, 由这些大整数轮流使用.


## 4. 大整数对象
Python由`PyIntBlock`实现单向列表:
```c
#define BLOCK_SIZE  1000  /* 1K less typical malloc overhead */
#define BHEAD_SIZE  8     /* Enough for a 64-bit pointer */
#define N_INTOBJECTS ((BLOCK_SIZE - BHEAD_SIZE) / sizeof(PyIntObject))

struct _intblock {
  struct _intblock *next;
  PyIntObject objects[N_INTOBJECTS];
};

typedef struct _intblock PyIntBlock;

static PyIntBlock *block_list = NULL;
static PyIntObject *free_list = NULL;
```


## 5. 添加和删除
下面是`PyInt_FromLong`创建`PyIntObject`的流程:
```c
PyObject* PyInt_FromLong(long ival)
{
  register PyIntObject *v;
  // 尝试使用小整数池
#if NSMALLNEGINTS + NSMALLPOSINTS > 0
  if (-NSMALLNEGINTS <= ival && ival < NSMALLPOSINTS) {
    v = small_ints[ival + NSMALLNEGINTS];
    Py_INCREF(v);
#ifdef COUNT_ALLOCS
    if (ival >= 0)
      quick_int_allocs++;
    else
      quick_neg_int_allocs++;
#endif
    return (PyObject *) v;
  }
#endif
  // 如果不能用小整数对象池, 使用通用对象池
  if (free_list == NULL) {
    if ((free_list = fill_free_list()) == NULL)
      return NULL;
  }
  /* Inline PyObject_New */
  v = free_list;
  free_list = (PyIntObject *)v->ob_type;
  PyObject_INIT(v, &PyInt_Type);
  v->ob_ival = ival;
  return (PyObject *) v;
}
```

当首次调用`PyInt_FromLong`时, `free_list`为NULL, 从而调用`fill_free_list`创建新的block
```c
static PyIntObject* fill_free_list(void)
{
  PyIntObject *p, *q;
  // 申请大小为sizeof(PyIntObject)的空间, 并链接到已有的block list中
  p = (PyIntObject *) PyMem_MALLOC(sizeof(PyIntBlock));
  if (p == NULL)
    return (PyIntObject *) PyErr_NoMemory();
  ((PyIntBlock *)p)->next = block_list;
  block_list = (PyIntBlock *)p;
  // 将PyIntBlock中的PyIntObject数组(objects)转变成单向链表
  p = &((PyIntBlock *)p)->objects[0];
  q = p + N_INTOBJECTS;
  while (--q > p)
    q->ob_type = (struct _typeobject *)(q-1);
  q->ob_type = NULL;
  return p + N_INTOBJECTS - 1;
}
```
objects被转换成单向链表, 其中next指针使用`ob_type`, 这样也因此牺牲了类型安全. 以下为程序运行后的结果
![单次fill_free_list运行结果](/images/Python/PyIntObject-1.png)

当block中的内存都被占满时, fill_free_list会再次申请新的空间, 如下图:
![多次fill_free_list运行结果](/images/Python/PyIntObject-2.png)

当`fill_free_list`分配完空间后, Python会从`free_list`中划出一块并创建`PyIntObject`对象, 同时完成`PyIntObject`的初始化工作.
多次`fill_free_list`后, 每个`PyIntBlock`的`PyIntObject`中的objects都是分离的. 假设现在有两个`PyIntBlock`, PyIntBlock1的objects已经完全填满, PyIntBlock2的objects还未填满, 那么`free_list`会指向PyIntBlock2中objects的空闲内存块. 当PyIntBlock1中的某个PyIntObject被删除, 下次调用`PyInt_FromLong`会将新的对象添加到PyIntBlock1的空闲位置. Python销毁`PyIntObject`时会调整`free_list`, 以避免内存泄漏.
```c
static void int_dealloc(PyIntObject *v)
{
  if (PyInt_CheckExact(v)) {
    v->ob_type = (struct _typeobject *)free_list;
    free_list = v;
  }
  else
    v->ob_type->tp_free((PyObject *)v);
}
```
`int_dealloc`完成的只是指针维护. 如果删除的是一个整数的派生类对象, 需调用`tp_free`彻底销毁对象.
![int_dealloc运行结果](/images/Python/PyIntObject-3.png)

可以发现, `int_dealloc`没有向系统返还内存, 只是将内存放回内存链表中. 理论上, 整数对象可将系统的内存用光, 但1GB能容乃89478486个整数对象, 所以还是很安全的.


## 6. 小整数对象池的初始化
`small_ints`维护的只是`PyIntObject`的指针, 那么小整数对象在什么时候被创建和初始化? 答案是`_PyInt_Init`
```c
int _PyInt_Init(void)
{
  PyIntObject *v;
  int ival;
#if NSMALLNEGINTS + NSMALLPOSINTS > 0
  for (ival = -NSMALLNEGINTS; ival < NSMALLPOSINTS; ival++) {
    if (!free_list && (free_list = fill_free_list()) == NULL)
      return 0;
    /* PyObject_New is inlined */
    v = free_list;
    free_list = (PyIntObject *)v->ob_type;
    PyObject_INIT(v, &PyInt_Type);
    v->ob_ival = ival;
    small_ints[ival + NSMALLNEGINTS] = v;
  }
#endif
  return 1;
}
```
Python初始化时调用`_PyInt_Init`, 申请内存, 并创建小整数对象.
