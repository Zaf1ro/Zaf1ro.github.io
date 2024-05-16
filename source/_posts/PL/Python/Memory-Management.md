---
title: Memory Management
category:
  - Programming Language
  - Python
tag:
  - Programming Language
abbrlink: 9a67
date: 2017-04-02 12:03:47
---

## 1. 内存管理架构
Python有两套内存管理机制, 一套负责debug, 一套负责正常的内存管理, 由`PYMALLOC_DEBUG`控制. 当`PYMALLOC_DEBUG`未定义时, 则使用正常的内存管理.
Python中的内存管理机制可抽象为四层:
![Python内存管理机制的层次结构](/images/Python/memory-management-1.png)

### 1.1 第0层
由操作系统提供的内存管理接口, 例如C运行时所提供的malloc和free. 除这一层之外往上三层都是Python维护的, Python无权干涉该层.

### 1.2 第1层
基于第0层包装而成的内存接口. 由于不同操作系统的内存特殊操作有不同解释, 例如`malloc(0)`, 有的会返回NULL, 有的会提示内存申请失败, 有的会返回一个正常指针. 为了可移植性, Python必须保证相同的语义表达相同的行为.
```c
PyAPI_FUNC(void *) PyMem_Malloc(size_t);
PyAPI_FUNC(void *) PyMem_Realloc(void *, size_t);
PyAPI_FUNC(void) PyMem_Free(void *);

void* PyMem_Malloc(size_t nbytes)
{
  return PyMem_MALLOC(nbytes);
}

void* PyMem_Realloc(void *p, size_t nbytes)
{
  return PyMem_REALLOC(p, nbytes);
}

void PyMem_Free(void *p)
{
  PyMem_FREE(p);
}
```
Python提供了函数和宏两套接口, 因为宏可以提高执行效率. 但使用C来编写Python拓展模式时, 由于Python的内存管理不断改变, 宏的代码也在不断改变, 所以使用宏生成的二进制可能不兼容.
除了malloc, realloc, free的相同语义接口, 还有面向Python中类型的内存分配器:
```c
#define PyMem_New(type, n) \
  ( (type *) PyMem_Malloc((n) * sizeof(type)) ) )
#define PyMem_NEW(type, n) \
  ( (type *) PyMem_MALLOC((n) * sizeof(type)) ) )

#define PyMem_Resize(p, type, n) \
  (type *) PyMem_Realloc((p), (n) * sizeof(type)) )
#define PyMem_RESIZE(p, type, n) \
  (type *) PyMem_REALLOC((p), (n) * sizeof(type)) )

#define PyMem_Del  PyMem_Free
#define PyMem_DEL  PyMem_FREE
```
PyMem_MALLOC中需要提供申请空间的大小, PyMem_New已经不需要提供空间大小, 只需要类型

### 1.3 第2层及往上
对于一些Python的常用对象构造内存管理策略, 例如整数对象, 字符串对象等. 


## 2. 小块空间的内存池
Python中很多时候都是申请的小块内存, 这些小块内存被申请后很快就被释放. 由于频繁地执行malloc和free操作使得操作系统在用户态和内核态频繁切换, 十分影响Python的执行效率. 为了提高执行效率, Python引入了`Pymalloc`内存池机制, 用于申请和释放小块内存.
整个内存池都可当做一个层次结构, 分为四层:
* block
* pool
* arena
* 内存池

block, pool, arena都有代码的实体, 内存池并没有实体, 只是一个概念上的东西

### 2.1 Block
block是一个确定大小的内存块, 这个内存大小的值为size class. 为了在32位和64位平台上都有最佳性能, 所有的block都是8字节对齐的.
```c
#define ALIGNMENT         8  /* must be 2^N */
#define ALIGNMENT_SHIFT   3
#define ALIGNMENT_MASK    (ALIGNMENT - 1)
```
block的大小也有上限, 当申请的内存大于这个上限时, 不能使用block存储, 只能调用Python的第1层内存管理机制来处理请求, 即`PyMem`函数族
```c
#define SMALL_REQUEST_THRESHOLD 256
#define NB_SMALL_SIZE_CLASSES   (SMALL_REQUEST_THRESHOLD / ALIGNMENT)
```
根据`SMALL_REQUEST_THRESHOLD`和`ALIGNMENT`的限定, 我们可以得到不用的block的size class, 每一个size class对应一个class index

Request in bytes | Size of allocated block | Size class index
-----|-----|-----
1-8 | 8 | 0
9-16 | 16 | 1
17-24 | 24 | 2
25-32 | 32 | 3
33-40 | 40 | 4
41-48 | 48 | 5
49-56 | 56 | 6
57-64 | 64 | 7
65-72 | 72 | 8
... | ... | ...
241-248 | 248 | 30
249-256 | 256 | 31

size class与size class index的转换:
```c
// 从size class index转换到size class
#define INDEX2SIZE(I) (((uint)(I) + 1) << ALIGNMENT_SHIFT)

// 从size class转换到size class index
size = (uint)(nbytes - 1) >> ALIGNMENT_SHIFT;
```

### 2.2 Pool
一组block可集合成为一个pool,一个pool管理着一堆有固定大小的内存块. 一个pool的大小通常为一个系统内存页, 4KB.
```c
#define SYSTEM_PAGE_SIZE      (4 * 1024)
#define SYSTEM_PAGE_SIZE_MASK (SYSTEM_PAGE_SIZE - 1)

#define POOL_SIZE             SYSTEM_PAGE_SIZE  /* must be 2^N */
#define POOL_SIZE_MASK        SYSTEM_PAGE_SIZE_MASK
```
以下是pool的header:
```c
typedef uchar block;

/* pool的header */
struct pool_header {
  union { 
    block *_padding;
    uint count; 
  } ref;	/* block的个数   */
  block *freeblock;
  struct pool_header *nextpool;
  struct pool_header *prevpool;
  uint arenaindex;
  uint szidx;
  uint nextoffset;
  uint maxnextoffset;
};
```

每一个pool中的block大小都相同, 以下是生成pool的过程:
```c
#define ROUNDUP(x)    (((x) + ALIGNMENT_MASK) & ~ALIGNMENT_MASK)
#define POOL_OVERHEAD ROUNDUP(sizeof(struct pool_header))
#define struct        pool_header *poolp;
#define unchar        block

poolp pool;
block* bp;

pool->ref.count = 1;
pool->szidx = size;  // 设置pool的size class index
size = INDEX2SIZE(size);  // 将size class index转换为size
bp = (block*)pool + POOL_OVERHEAD;  // 跳过header进行对齐
pool->nextoffset = POOL_OVERHEAD + (size << 1);
pool->maxnextoffset = POOL_SIZE - size;
pool->freeblock = bp + size;
*(block**)(pool->freeblock) = NULL;
return (void*)bp;
```
返回的bp为pool中的第一块block指针, 该block可使用的内存区间为`[bp, bp+size]`
![Pool结构图](/images/Python/memory-management-2.png)

下面是连续申请5块28字节内存时发生的情况:
```c
if (pool != pool->nextpool) {
  ++pool->ref.count;
  bp = pool->freeblock;

  /* ...... */

  /* 有足够的空间 */
  if (pool->nextoffset <= pool->maxnextoffset) {
    pool->freeblock = (block*)pool + pool->nextoffset;
    pool->nextoffset += INDEX2SIZE(size);
    *(block **)(pool->freeblock) = NULL;
    return (void *)bp;
  }
}
```

freeblock指向下一个可用block空间, freeblock向后推进需要nextoffset, maxnextoffset指明了pool最后一个block的位置, 相当于pool的边界. 当pool中释放了部分block, 会出现大量离散自由的block, 这时需要链接起这些空闲的block
```c
#define POOL_ADDR(P) ((poolp)((uptr)(P) & ~(uptr)POOL_SIZE_MASK))

void PyObject_Free(void *p)
{
  poolp pool;
  block *lastfree;
  poolp next, prev;
  uint size;

  pool = POOL_ADDR(p);
  if (Py_ADDRESS_IN_RANGE(p, pool)) {
    *(block **)p = lastfree = pool->freeblock;  // [1]
    pool->freeblock = (block *)p;               // [2]

    /* ...... */
  }
}
```

在释放的过程中, freeblock指向了被释放的block, 被释放的block中的内容指向了未分配的block, 而未分配的block中的内容为NULL
![释放block后自由block链表](/images/Python/memory-management-3.png)

这样在allocate block时就可以通过block中的内容是否为NULL来判断该block是否曾被释放过
```c
if (pool != pool->nextpool) {
  ++pool->ref.count;
  bp = pool->freeblock;

  // 判断是否为曾被释放的block
  if ((pool->freeblock = *(block **)bp) != NULL) {
    return (void *)bp;
  }

  if (pool->nextoffset <= pool->maxnextoffset) {
    /* ...... */
  }
}
```

### 2.3 Arena
多个pool组成一个arena, 单个arena的大小为256KB, 所以单个arena能存储的pool个数为64个
```c
#define ARENA_SIZE		(256 << 10)	/* 256KB */
```
以下是arena结构体:
```c
typedef uchar block;

struct arena_object {
  uptr address;
  block* pool_address;
  uint nfreepools;
  uint ntotalpools;
  struct pool_header* freepools;

  struct arena_object* nextarena;
  struct arena_object* prevarena;
};
```
一个arena包括一个arena_object和所管理的pool集合. 一个pool包含一个`pool_header`和所管理的block集合

#### 2.3.1 "未使用"的arena和"可用"的arena
多个arena组成一个小块内存的内存池, 但`arena_object`中的`nextarena`和`prevarena`用来链接多个arena, 多个arena实际存储在数组中.
![Pool和Arena的区别](/images/Python/memory-management-4.png)

由于arena初始化时并不一定有pool, 所以arena有两个状态: "未使用"和"可用"
当arena没有和pool集合链接时, 处于"未使用"状态; 一旦建立联系, 就切换到"可用状态". "未使用"的arena的链接表头为`unused_arena_objects`, arena和arena之间使用`nextarena`连接, 是一个单向链表; "可用"的arena的链表表头为`usable_arenas`, arena和arena之间通过`nextarena`和`prevarena`连接, 是一个双向链表.
![arena中的某种状态](/images/Python/memory-management-5.png)

#### 2.3.2 申请arena
Python使用`new_arena`来创建一个arena
```c
// arena的集合
static struct arena_object* arenas = NULL;
// 当前arenas中arena的数量
static uint maxarenas = 0;
// "未使用"arena的链表
static struct arena_object* unused_arena_objects = NULL;
// "可用"arena的链表
static struct arena_object* usable_arenas = NULL;

// 初始化时需要申请的arena_object个数
#define INITIAL_ARENA_OBJECTS 16

static struct arena_object* new_arena(void)
{
  struct arena_object* arenaobj;
  uint excess;	/* number of bytes above pool alignment */

  // 判断是否需要扩充"未使用"arena链表
  if (unused_arena_objects == NULL) {
    uint i;
    uint numarenas;
    size_t nbytes;

    // 将maxarena增加一倍
    numarenas = maxarenas ? maxarenas << 1 : INITIAL_ARENA_OBJECTS;

    if (numarenas <= maxarenas)
      return NULL;	/* 溢出 */
    if (numarenas > PY_SIZE_MAX / sizeof(*arenas))
      return NULL;	/* 溢出 */

    nbytes = numarenas * sizeof(*arenas);
    arenaobj = (struct arena_object *)realloc(arenas, nbytes);
    if (arenaobj == NULL)
      return NULL;
    arenas = arenaobj;

    // 初始化新申请的arena_object, 并将其放入unused_arena_objects链表中
    for (i = maxarenas; i < numarenas; ++i) {
      arenas[i].address = 0;	/* mark as unassociated */
      arenas[i].nextarena = i < numarenas - 1 ?
                 &arenas[i+1] : NULL;
    }
    unused_arena_objects = &arenas[maxarenas];
    maxarenas = numarenas;
  }

  /* 从unused_arena_objects链表中取出一个"未使用"的arena,
   * 将抽出的arena与unused_arena_objects链表分离开来
   */
  arenaobj = unused_arena_objects;
  unused_arena_objects = arenaobj->nextarena;
  assert(arenaobj->address == 0);

  /* 申请arena_object管理的内存(pool的存储空间), 256KB */
  arenaobj->address = (uptr)malloc(ARENA_SIZE);
  ++narenas_currently_allocated;

  // 设置pool集合的相关信息
  arenaobj->freepools = NULL;
  arenaobj->pool_address = (block*)arenaobj->address;
  arenaobj->nfreepools = ARENA_SIZE / POOL_SIZE;

  // 将pool的起始地址调整为系统页的边界
  excess = (uint)(arenaobj->address & POOL_SIZE_MASK);
  if (excess != 0) {
    --arenaobj->nfreepools;
    arenaobj->pool_address += POOL_SIZE - excess;
  }
  arenaobj->ntotalpools = arenaobj->nfreepools;

  return arenaobj;
}
```

### 2.4 内存池
#### 2.4.1 userpools
Python只规定了block的空间上限, 但并没有提及到arena的个数限制. Python提供了一个编译符号来控制是否限制内存池的大小. 当Python在`WITH_MEMORY_LIMITS`编译符号打开的情况下进行编译时, 也就限制了整个内存池的大小. 默认情况下并不限制大小.
```c
#ifdef WITH_MEMORY_LIMITS
  #ifndef SMALL_MEMORY_LIMIT
    #define SMALL_MEMORY_LIMIT (64 * 1024 * 1024) /* 64MB */
  #endif
#endif

#ifdef WITH_MEMORY_LIMITS
#define MAX_ARENAS (SMALL_MEMORY_LIMIT / ARENA_SIZE)
#endif
```
由于一个arena的pool集合所管理的block大小并非不变, 所以可能导致一个arena中的pool集合并不有相同的block大小. 例如: 一个arena中的pool集合有一些在管理32字节的block, 有一些在管理64字节的block.
pool在任何时刻总处于三个状态中之一:
* used: pool中至少有一个block被使用, 且至少有一个block未被使用. 这种状态的pool被userpools数组维护.
* full: pool中的所有block都被使用. 这时pool在arena中, 但不在arena的freepools中.
* empty: pool中所有block都未被使用. 这时pool通过`pool_header`中的`nextpool`构成单向链表, 位于arena_object中的freepools
![某一时刻arena中pool集合的状态](/images/Python/memory-management-6.png)

所有处于used状态下的pool都位于usedpools的控制下, Python通过usedpools寻找一块可用的block. 但usedpools下的pools中的block大小并不相同, 这就需要一种机制来寻找合适的pool:
```c
typedef uchar block;

#define PTA(x) (
  (poolp)(
    (uchar *)&(usedpools[2*(x)]) - 2*sizeof(block *)
  )
)
#define PT(x)	PTA(x), PTA(x)

static poolp usedpools[2 * ((NB_SMALL_SIZE_CLASSES + 7) / 8) * 8] = {
  PT(0), PT(1), PT(2), PT(3), PT(4), PT(5), PT(6), PT(7)
#if NB_SMALL_SIZE_CLASSES > 8
  , PT(8), PT(9), PT(10), PT(11), PT(12), PT(13), PT(14), PT(15)
  /* ...... */
#endif /* NB_SMALL_SIZE_CLASSES >  8 */
};
```
当申请一个32字节的pool时, 需要将这个pool放入usedpools. 先找到他的size class index, 也就是3. 然后进行`usedpools[3+3]->nextpool = pool`即可. `PyObject_Malloc`中利用了这个技巧来判断某个class size index对应的pool是否存在于usedpools中.
```c
void* PyObject_Malloc(size_t nbytes)
{
  block *bp;
  poolp pool;
  poolp next;
  uint size;

  if ((nbytes - 1) < SMALL_REQUEST_THRESHOLD) {
    LOCK();

    /* 获得size class index */
    size = (uint)(nbytes - 1) >> ALIGNMENT_SHIFT;
    pool = usedpools[size + size];
        
    /* usedpools中有可用的pool */
    if (pool != pool->nextpool) {
      /* ...... */
    }

    /* usedpools中没有可用的pool, 尝试获得空的pool */
  }
}
```

#### 2.4.2 Pool的初始化
Python启动时并没有分配内存, 而采用了延迟分配的策略. 当我们申请小块内存时, Python才会建立内存池. 当申请28字节的内存时, Python将申请32字节的内存, 并在usedpools中的对应位置查找. 如果没有找到可用的pool, Python会从usable_arenas链表中第一个可用arena中获得一个pool.
当从一个"可用"的arena中取出一个pool后, 下一次即使请求分配的pool的size class不同, 也可以从该arena中申请pool.
```c
void* PyObject_Malloc(size_t nbytes)
{
  block *bp;
  poolp pool;
  poolp next;
  uint size;

  if ((nbytes - 1) < SMALL_REQUEST_THRESHOLD) {
    LOCK();
    size = (uint)(nbytes - 1) >> ALIGNMENT_SHIFT;
    pool = usedpools[size + size];
    if (pool != pool->nextpool) {
      /* ...... */
    }

    /* 如果usable_arenas链表为空, 则创建新表 */
    if (usable_arenas == NULL) {
      /* 申请新的arena_object, 并放入usable_arenas链表 */
      usable_arenas = new_arena();
      usable_arenas->nextarena = usable_arenas->prevarena = NULL;
    }

    /* 从usable_arenas链表中第一个arena的freepools中抽取一个可用的pool */
    pool = usable_arenas->freepools;
    if (pool != NULL) {
      usable_arenas->freepools = pool->nextpool;

      /* 调整usable_arenas链表中第一个arena的可用pool数量 */
      --usable_arenas->nfreepools;

      /* 如果数量为0, 则将该arena从usable_arenas链表中移除 */
      if (usable_arenas->nfreepools == 0) {
        usable_arenas = usable_arenas->nextarena;
        if (usable_arenas != NULL) {
          usable_arenas->prevarena = NULL;
        }
      }

      init_pool:
        /* ...... */
    }
  }
}
```
现在我们有了一块用于32字节内存分配的pool, 为了提高内存分配的效率, 需要将pool放入到usedpools中, 这一步叫作init pool:
```c
#define ROUNDUP(x)		(((x) + ALIGNMENT_MASK) & ~ALIGNMENT_MASK)
#define POOL_OVERHEAD		ROUNDUP(sizeof(struct pool_header))

void* PyObject_Malloc(size_t nbytes)
{
  /* ...... */

  init_pool:
    /* 将pool放入usedpools中 */
    next = usedpools[size + size]; /* == prev */
    pool->nextpool = next;
    pool->prevpool = next;
    next->nextpool = pool;
    next->prevpool = pool;
    pool->ref.count = 1;

    /* [1] 如果pool有正确的size结构, 则直接返回一个block */
    if (pool->szidx == size) {
        bp = pool->freeblock;
        pool->freeblock = *(block **)bp;
        UNLOCK();
        return (void *)bp;
    }
    
    /* [2] 初始化pool_header, 将freeblock指向第二个block, 返回第一个block */
    pool->szidx = size;
    size = INDEX2SIZE(size);
    bp = (block *)pool + POOL_OVERHEAD;
    pool->nextoffset = POOL_OVERHEAD + (size << 1);
    pool->maxnextoffset = POOL_SIZE - size;
    pool->freeblock = bp + size;
    *(block **)(pool->freeblock) = NULL;
    UNLOCK();
    return (void *)bp;

  /* ...... */
}
```

当一个从未被使用的pool, 其szidx为0xFFFF. 所以init pool时会执行`[2]`. 只有当pool从一个empty重新转为used状态时, 才会执行`[1]`. 
以下是`new_arena`中取出新的arena后的初始化过程:
```c
#define DUMMY_SIZE_IDX 0xffff /* size class of newly cached pools */

void* PyObject_Malloc(size_t nbytes)
{
  block *bp;
  poolp pool;
  poolp next;
  uint size;

  /* ...... */

  /* 从arena中取出一个新的pool */
  pool = (poolp)usable_arenas->pool_address;
  pool->arenaindex = usable_arenas - arenas;
  pool->szidx = DUMMY_SIZE_IDX;
  usable_arenas->pool_address += POOL_SIZE;
  --usable_arenas->nfreepools;

  if (usable_arenas->nfreepools == 0) {
    usable_arenas = usable_arenas->nextarena;
    if (usable_arenas != NULL)
      usable_arenas->prevarena = NULL;
  }
  goto init_pool;

  /* ...... */
}
```
