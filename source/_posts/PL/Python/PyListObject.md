---
title: PyListObject
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: f5e5
date: 2017-03-02 21:42:40
---

## 1. PyListObject对象
`PyListObject`对象可以插入, 添加, 删除元素, 存放的都是`PyObject*`指针, 因此`PyListObject`是一个变长对象. 但和`PyStringObject`不同, `PyListObject`支持插入删除, 并动态的调整内存和元素.
```c
typedef struct {
  PyObject_VAR_HEAD
  /* Vector of pointers to list elements.  list[0] is ob_item[0], etc. */
  PyObject **ob_item;

  // allocated表示PyListObject对象分配了多少个元素
  // ob_size表示PyListObject对象里占用了多少元素
  // 以下是ob_size和allocated的关系:
  // 1. 0 <= ob_size <= allocated
  // 2. len(list) == ob_size
  // 3. ob_item == NULL 意味着 ob_size == allocated == 0

  Py_ssize_t allocated;
} PyListObject;
```


## 2. PyListObject对象的创建与维护
### 2.1 创建对象
`PyListObject`只提供了一种创建对象的方式: `PyList_New`, 参数size指定了元素的个数
```c
PyObject* PyList_New(Py_ssize_t size)
{
  PyListObject *op;
  size_t nbytes;

  if (size < 0) {
    PyErr_BadInternalCall();
    return NULL;
  }

  // 计算内存大小, 溢出检查
  nbytes = size * sizeof(PyObject *);
  if (size > PY_SIZE_MAX / sizeof(PyObject *))
    return PyErr_NoMemory();

  // 为PyListObject对象申请空间
  if (num_free_lists) {
    // 缓冲池可用
    num_free_lists--;
    op = free_lists[num_free_lists];
    _Py_NewReference((PyObject *)op);
  } else {
    // 缓冲池不可用
    op = PyObject_GC_New(PyListObject, &PyList_Type);
    if (op == NULL)
      return NULL;
  }

  // 为PyListObject对象中维护的元素列表申请空间
  if (size <= 0)
    op->ob_item = NULL;
  else {
    op->ob_item = (PyObject **) PyMem_MALLOC(nbytes);
    if (op->ob_item == NULL) {
      Py_DECREF(op);
      return PyErr_NoMemory();
    }
    memset(op->ob_item, 0, nbytes);
  }
  op->ob_size = size;
  op->allocated = size;
  _PyObject_GC_TRACK(op);
  return (PyObject *) op;
}
```
`PyList_New`仅仅指定元素的个数, 而不是元素实际占用的内存空间. 创建过程中, 先为`PyListObject`申请空间, 再为维护的元素列表申请内存, 通过`ob_item`建立联系.
创建`PyListObject`对象时, 先检查缓冲池`free_lists`中是否有可用对象. 如果有, 则直接使用该对象; 若都不可用, 则通过`PyObject_GC_New`在系统堆中申请内存. 默认情况下, `free_lists`会维护80个`PyListObject`对象:
```c
#define MAXFREELISTS 80
static PyListObject* free_lists[MAXFREELISTS];
static int num_free_lists = 0;
```

### 2.2 设置元素
创建第一个`PyListObject`时, `num_free_lists`为0, 所以会绕过对象缓冲池而调用`PyObject_GC_New`, 在系统堆上创建一个新的`PyListObject`对象. 假设我们创建的`PyListObject`包含了6个元素, 也就是`PyList_New(6)`, 创建完毕后的状态如下:
![新建的PyListObject对象](/images/Python/PyListObject-1.png)

运行`list[3]=100`时会调用`PyList_SetItem`:
```c
int PyList_SetItem(register PyObject *op, register Py_ssize_t i,
               register PyObject *newitem)
{
  register PyObject* olditem;
  register PyObject** p;
  if (!PyList_Check(op)) {
    Py_XDECREF(newitem);
    PyErr_BadInternalCall();
    return -1;
  }

  // 索引检查
  if (i < 0 || i >= ((PyListObject *)op) -> ob_size) {
    Py_XDECREF(newitem);
    PyErr_SetString(PyExc_IndexError, "list assignment index out of range");
    return -1;
  }

  // 设置元素
  p = ((PyListObject *)op) -> ob_item + i;
  olditem = *p;
  *p = newitem;
  Py_XDECREF(olditem);
  return 0;
}
```

将新的元素指针移到list中后, 需将原来存放的对象的引用计数-1. 由于`olditem`可能为NULL, 所以应先调用`Py_XDECREF`, 完毕后的状态如下:
![在PyListObject对象中设置元素](/images/Python/PyListObject-2.png)

### 2.3 插入元素
设置元素不能改变`PyListObject`对象的内存, 但插入元素可以改变`ob_item`指向的内存.
```c
int PyList_Insert(PyObject *op, Py_ssize_t where, PyObject *newitem)
{
  // 类型检查
  if (!PyList_Check(op)) {
    PyErr_BadInternalCall();
    return -1;
  }
  return ins1((PyListObject *)op, where, newitem);
}

static int ins1(PyListObject *self, Py_ssize_t where, PyObject *v)
{
  Py_ssize_t i, n = self->ob_size;
  PyObject **items;
  if (v == NULL) {
    PyErr_BadInternalCall();
    return -1;
  }
  if (n == PY_SSIZE_T_MAX) {
    PyErr_SetString(PyExc_OverflowError, "cannot add more objects to list");
    return -1;
  }

  // 调整列表容量
  if (list_resize(self, n+1) == -1)
    return -1;

  // 确定插入点
  if (where < 0) {
    where += n;
    if (where < 0)
      where = 0;
  }
  if (where > n)
    where = n;
  
  // 插入元素, 后移元素
  items = self->ob_item;
  for (i = n; --i >= where; )
    items[i+1] = items[i];
  Py_INCREF(v);
  items[where] = v;
  return 0;
}
```

下面是`PyListObject`对象扩充容量的方法:
```c
static int list_resize(PyListObject *self, Py_ssize_t newsize)
{
  PyObject **items;
  size_t new_allocated;
  Py_ssize_t allocated = self->allocated;

  /* Bypass realloc() when a previous overallocation is large enough
   * to accommodate the newsize.  If the newsize falls lower than half
   * the allocated size, then proceed with the realloc() to shrink the list.
   */

  // 不需要重新分配内存
  if (allocated >= newsize && newsize >= (allocated >> 1)) {
    assert(self->ob_item != NULL || newsize == 0);
    self->ob_size = newsize;
    return 0;
  }

  /* 分配多余内存使得list可以无限扩张
   * 增长规律:  0, 4, 8, 16, 25, 35, 46, 58, 72, 88, ...
   */

  // 计算重新申请的内存大小
  new_allocated = (newsize >> 3) + (newsize < 9 ? 3 : 6);

  // 检查内存溢出
  if (new_allocated > PY_SIZE_MAX - newsize) {
    PyErr_NoMemory();
    return -1;
  } else {
    new_allocated += newsize;
  }

  if (newsize == 0)
    new_allocated = 0;
  items = self->ob_item;
  if (new_allocated <= ((~(size_t)0) / sizeof(PyObject *)))
    PyMem_RESIZE(items, PyObject *, new_allocated);
  else
    items = NULL;
  if (items == NULL) {
    PyErr_NoMemory();
    return -1;
  }

  // 扩展列表
  self->ob_item = items;
  self->ob_size = newsize;
  self->allocated = new_allocated;
  return 0;
}
```
`list.insert(3, 99)`运行的步骤图如下:
![insert元素流程](/images/Python/PyListObject-3.png)

`PyListObject`对象还提供了append操作, 该操作与insert类似, 但只能在list的末尾插入. `list.append(101)`的运行结果如下:
![append元素结果](/images/Python/PyListObject-4.png)

### 2.4 删除元素
以下为删除元素:
```py
>>> lst = [1,2,3,4]
>>> lst
[1, 2, 3, 4]
>>> lst.remove(3)
>>> lst
[1, 2, 4]
```
`remove()`会调用`listmove()`:
```c
static PyObject* listremove(PyListObject *self, PyObject *v)
{
  Py_ssize_t i;

  for (i = 0; i < self->ob_size; i++) {
    int cmp = PyObject_RichCompareBool(self->ob_item[i], v, Py_EQ);
    if (cmp > 0) {
      if (list_ass_slice(self, i, i+1, (PyObject *)NULL) == 0)
        Py_RETURN_NONE;
      return NULL;
    }
    else if (cmp < 0)
      return NULL;
  }
  PyErr_SetString(PyExc_ValueError, "list.remove(x): x not in list");
  return NULL;
}
```
`PyObject_RichCompareBool`负责对比元素, `list_ass_slice`负责删除该元素. `list.remove(100)`的运行如下:
![remove元素流程](/images/Python/PyListObject-5.png)


## 3. PyListObject对象缓存池
以下是`PyListObject`被销毁的过程:
```c
static void list_dealloc(PyListObject *op)
{
  Py_ssize_t i;
  PyObject_GC_UnTrack(op);
  Py_TRASHCAN_SAFE_BEGIN(op)

  // 销毁PyListObject对象维护的元素列表
  if (op->ob_item != NULL) {
    i = op->ob_size;
    while (--i >= 0) {
      Py_XDECREF(op->ob_item[i]);
    }
    PyMem_FREE(op->ob_item);
  }

  // 释放PyListObject自身
  if (num_free_lists < MAXFREELISTS && PyList_CheckExact(op))
    free_lists[num_free_lists++] = op;
  else
    op->ob_type->tp_free((PyObject *)op);
  Py_TRASHCAN_SAFE_END(op)
}
```
这里我们可以看到, 释放`PyListObject`对象中所有元素后, 会试图将空的`PyListObject`加入到`free_lists`中. 下一次创建新的list时, 可使用该PyListObject对象, 并重新分配空间, 避免了再次初始化.
