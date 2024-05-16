---
title: PyObject
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: 1c3f
date: 2017-02-23 23:21:23
---

## 1. PyObject
PyObject定义在object.h
```c
typedef struct _object{
  PyObject_HEAD
} PyObject;
```

PyObject_HEAD定义在object.h中
```c
#define PyObject_HEAD			\
  Py_ssize_t ob_refcnt;		\
  struct _typeobject *ob_type;
```

* ob_refcnt为引用计数器, 若某个`PyObject*`指向该对象, 则`ob_refcnt + 1`; 若某个`PyObject*`被删除, 则`ob_refcnt - 1`; 若`ob_refcnt == 0`, 则将该对象从堆中删除.
* `_typeobject`为结构体, 内部装有该对象类型的信息, ob_type为结构体指针

PyObject仅仅是Python各个对象的父类.
```c
typedef struct{
  PyObject_HEAD
  long ob_ival,
} PyIntObject;
```
PyIntObject不仅具有PyObject的所有参数, 还多了一个long类型的数值, 数值就存储于此


## 2. 不定长变量
如果是int类型的变量, 很容易通过`ob_ival`存储数据, 但如果需要保存string类型变量, 则Python无法知道用户输入的string会有多少char类型变量, 这时就需要不定长变量的对象
```c
#define PyObject_VAR_HEAD		\
  PyObject_HEAD			\
  Py_ssize_t ob_size;

typedef struct {
  PyObject_VAR_HEAD
} PyVarObject;
```
`ob_size`表示该对象所具有的元素个数, 所以`PyVarObject`可以表示变长对象. 假设list有5个元素, 则ob_size为5.


## 3. 类型对象
`_typeobject`结构体如下:
```c
typedef struct _typeobject {
  PyObject_VAR_HEAD
  const char *tp_name; /* 类型名, 可以显示为"<module>.<name>" */
  Py_ssize_t tp_basicsize, tp_itemsize; /* 单个元素大小和元素个数 */

  /* 标准操作函数 */
  destructor tp_dealloc;
  printfunc tp_print;
  getattrfunc tp_getattr;
  setattrfunc tp_setattr;
  cmpfunc tp_compare;
  reprfunc tp_repr;

  /* Method suites for standard classes */
  PyNumberMethods *tp_as_number;
  PySequenceMethods *tp_as_sequence;
  PyMappingMethods *tp_as_mapping;

  /* More standard operations (here for binary compatibility) */
  hashfunc tp_hash;
  ternaryfunc tp_call;
  reprfunc tp_str;
  getattrofunc tp_getattro;
  setattrofunc tp_setattro;

  /* Functions to access object as input/output buffer */
  PyBufferProcs *tp_as_buffer;

  /* Flags to define presence of optional/expanded features */
  long tp_flags;

  const char *tp_doc; /* Documentation string */

  /* Assigned meaning in release 2.0 */
  /* call function for all accessible objects */
  traverseproc tp_traverse;

  /* delete references to contained objects */
  inquiry tp_clear;

  /* Assigned meaning in release 2.1 */
  /* rich comparisons */
  richcmpfunc tp_richcompare;

  /* weak reference enabler */
  Py_ssize_t tp_weaklistoffset;

  /* Added in release 2.2 */
  /* Iterators */
  getiterfunc tp_iter;
  iternextfunc tp_iternext;

  /* Attribute descriptor and subclassing stuff */
  struct PyMethodDef *tp_methods;
  struct PyMemberDef *tp_members;
  struct PyGetSetDef *tp_getset;
  struct _typeobject *tp_base;
  PyObject *tp_dict;
  descrgetfunc tp_descr_get;
  descrsetfunc tp_descr_set;
  Py_ssize_t tp_dictoffset;
  initproc tp_init;
  allocfunc tp_alloc;
  newfunc tp_new;
  freefunc tp_free; /* Low-level free-memory routine */
  inquiry tp_is_gc; /* For PyObject_IS_GC */
  PyObject *tp_bases;
  PyObject *tp_mro; /* method resolution order */
  PyObject *tp_cache;
  PyObject *tp_subclasses;
  PyObject *tp_weaklist;
  destructor tp_del;

#ifdef COUNT_ALLOCS
  /* these must be last and never explicitly initialized */
  Py_ssize_t tp_allocs;
  Py_ssize_t tp_frees;
  Py_ssize_t tp_maxalloc;
  struct _typeobject *tp_prev;
  struct _typeobject *tp_next;
#endif
} PyTypeObject;
```


## 4. 对象的创建
Python有两种方式创建一个整数对象
* 通过AOL(Abstract Object Layer)创建
  ```c
  PyObject* intObj = PyObject_New(PyObject, &PyInt_Type);
  ```
* 通过COL(Concrete Object Layer)创建
  这种API只能作用于某一类型的对象, 对于int对象, 可以使用一下表达式:
  ```c
  PyObject* intObj = PyInt_FromLong(10);
  ```

下面是a=int(10)的实现流程:
1. 调用`PyInt_Type`中的tp_new
2. 如果`PyInt_Type`中的tp_new为null, 则通过`tp_base`指定的基类调用基类的`tp_new`
3. 通过`tp_new`为对象申请内存, 并转向`PyInt_Type`的`tp_init`
4. 通过`tp_init`完成初始化对象


## 5. 对象的行为
`PyTypeObject`中有很多函数指针, 这些函数指针指向某个函数或是null. 例如:
1. `tp_hash`指明该类型对象所能生成的hash值
2. `tp_as_number`指向`PyNumberMethods`, 定义了一个数值对象支持的操作
3. `tp_as_sequence`指向`PySequenceMethods`, 定义了一个list对象支持的操作
4. `tp_as_mapping`指向`PyMappingMethods`, 定义了一个dict对象支持的操作


## 6. 类型的类型
Python的类型其实是一个对象, 那么这个类型对象的类型就是`PyType_Type`:
```c
PyTypeObject PyType_Type = {
  PyObject_HEAD_INIT(&PyType_Type)
  0,                                    /* ob_size */
  "type",                               /* tp_name */
  sizeof(PyHeapTypeObject),             /* tp_basicsize */
  sizeof(PyMemberDef),                  /* tp_itemsize */
  (destructor)type_dealloc,             /* tp_dealloc */
  0,                                    /* tp_print */
  0,                                    /* tp_getattr */
  0,                                    /* tp_setattr */
  type_compare,                         /* tp_compare */
  (reprfunc)type_repr,                  /* tp_repr */
  0,                                    /* tp_as_number */
  0,                                    /* tp_as_sequence */
  0,                                    /* tp_as_mapping */
  (hashfunc)_Py_HashPointer,            /* tp_hash */
  (ternaryfunc)type_call,               /* tp_call */
  0,                                    /* tp_str */
  (getattrofunc)type_getattro,          /* tp_getattro */
  (setattrofunc)type_setattro,          /* tp_setattro */
  0,                                    /* tp_as_buffer */
  Py_TPFLAGS_DEFAULT |                  /* tp_flags */
  Py_TPFLAGS_HAVE_GC |
  Py_TPFLAGS_BASETYPE,		
  type_doc,                             /* tp_doc */
  (traverseproc)type_traverse,          /* tp_traverse */
  (inquiry)type_clear,                  /* tp_clear */
  0,                                    /* tp_richcompare */
  offsetof(PyTypeObject, tp_weaklist),  /* tp_weaklistoffset */
  0,                                    /* tp_iter */
  0,                                    /* tp_iternext */
  type_methods,                         /* tp_methods */
  type_members,                         /* tp_members */
  type_getsets,                         /* tp_getset */
  0,                                    /* tp_base */
  0,                                    /* tp_dict */
  0,                                    /* tp_descr_get */
  0,                                    /* tp_descr_set */
  offsetof(PyTypeObject, tp_dict),      /* tp_dictoffset */
  0,                                    /* tp_init */
  0,                                    /* tp_alloc */
  type_new,                             /* tp_new */
  PyObject_GC_Del,                      /* tp_free */
  (inquiry)type_is_gc,                  /* tp_is_gc */
};
```

所有`PyTypeObject`对象都是通过`PyType_Type`创建, 以下是`PyType_Object`和`PyType_Type`的关系:
```py
>>> int.__class__
<type 'type'>
>>> type.__class__
<type 'type'>
```

上述代码中的'type'指的就是`PyType_Type`, 也就是Python中的metaclass. 以下是`PyInt_Type`和`PyType_Type`之间的关系:
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

以下是宏定义`PyObject_HEAD_INIT`:
```c
#ifdef Py_TRACE_REFS
  #define _PyObject_EXTRA_INIT 0, 0,
#else
  #define _PyObject_EXTRA_INIT
#endif

#define PyObject_HEAD_INIT(type)	\
  _PyObject_EXTRA_INIT		\
  1, type,
```


## 7. Python对象的多态性
虽然Python有很多类型对象, 但是函数之间传递使用的都是`PyObject*`. Python可以通过对象的ob_type来判定该对象的具体操作, 例如:
```c
long PyObject_Hash(PyObject* v)
{
  PyTypeObject* tp = v->ob_type;
  if(tp->tp_hash!=null)
    return (*tp->tp_hash)(v);
  ......
}
```


## 8. 引用计数
Python通过`ob_refcnt`来实现垃圾回收机制, 通过`Py_INCREF(op)`和`Py_DECREF(op)`两个宏来增加和减少一个对象的引用计数. 当一个对象的引用计数减少到0后, `Py_DECREF`将调用该对象的析构函数来释放内存和资源.
`ob_refcnt`是一个32位的整数变量, 所以一个对象的引用个数是有限的. 另外, 类型对象不受引用计数影响, 即永远不会被析构. 以下是有关引用计数的宏:
```c
#define _Py_NewReference(op) ((op)->ob_refcnt = 1)
#define _Py_Dealloc(op) ((*(op)->ob_type->tp_dealloc)((PyObject*)(op))
#define Py_INCREF(op) ((op)->ob_refcnt++)
#define Py_DECREF(op)				\
  if (--op->ob_refcnt != 0)		 \
    ;		\
  else			\
    _Py_Dealloc((PyObject*)(op))
```


## 9. Python对象的分类
Python的对象从概念上分为5类:
* Fundamental对象: 类型对象(type)
* Numeric对象: 数值对象(int, float, bool)
* Sequence对象: 容纳其他对象的序列集合对象(string, list, tuple)
* Mapping对象: 类似于C++中的map的关联对象(dict)
* Internal对象: Python虚拟机在运行时内部使用的对象(function, code, frame, module, method)
