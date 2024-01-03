---
title: Virtual Memory Allocation And Paging
abbrlink: 1f7f
date: 2020-07-21 20:28:17
tags:
  - C/C++
category:
  - C/C++
keywords:
description:
---

## 1. Process Memory Concepts
在进程拥有的所有资源中, 内存是最重要的. 通常每个进程会有一个线性的**virtual address space**(虚拟地址空间), 地址从0开始依次递增. virual memory被分为多个**page**(分页), 通常每个page为4kb大小, 每个page由真实的memory(称为**frame**)或secondary storage(如disk)支持. 
内存上的一个frame可被用于多个进程的不同virtual page. 例如, GNU C library中的printf函数在memory中只有一份, 但却可以被映射到多个进程的virtual memeory中作为printf函数被调用. 为了让进程可以访问virtual page的任何一部分, page背后必须有frame作为支撑. 但由于virual memory的总和是可以大于真实的memory大小, 因此page的访问可以在memory和disk之间反复切换. 当进程需要访问该page时, 则将数据放置到memory中; 但进程不需要时, 则将数据放置在disk中. 以上操作称为**paging**(分页).
当进程访问的page并没有实际memory作为支撑时, 会发生**page fault**. 当page fault发生时, kernel会挂起进程并为page寻找合适的frame, 之后恢复进程. 从进程的角度来看, 所有的page都是位于真实的memory中, 只不过paging操作会大大加长程序执行的时间. 对于时间敏感的程序, 可使用**lock page**来避免paging.
对于每个virtual address space, 都需要一个叫做memory allocation的过程来追踪每个地址存放了什么数据. 进程的memery allocation有两种主要方式: **exec**和**编程**. fork也是一种方式, 但这里并不是重点. Exec是一种为进程创建virtual address space的操作, 它为程序文件申请一块空间, 读取程序文件并执行文件. 一旦程序开始执行, 剩余的memeory allocation就是通过代码实现. GNU C中有两种memeory allocation方式: automatic和dynamic.
**Memory-mapped I/O**是一种特殊的dynamic virtual memory allocation. 它会将内存映射到某个文件上, 依次保证内存中的数据和文件中的数据一模一样. 当程序修改内存中的数据时, 系统会将修改写入文件中. 
除了allocate memory, 程序也可以deallocate memory. 首先, exec创造的内存无法被free; 当程序退出或执行完毕时, 其所占用的内存会被free. 进程的virtual address space被分为多个segments, 每个segment表示一块连续的virtual address. 以下几个segment比较重要:
* text segment: 包含程序的instructions, literals和static constants. 通常由exec分配并保持不变.
* data segment: 由exec分配内存, 并可通过函数修改大小
* stack segment: 随着stack扩大而扩大, 不会缩小


## 2. Allocate Storage For Prgram Data
### 2.1 Memory Allocation in C Programs
C语言可使用variable(变量)来实现两种memory allocation:
1. Static allocation: 当声明static或global variable时, 程序会在启动时为这些变量申请一块内存空间
2. Automatic allocation: 当声明automatic variable(例如: function argument或local variable)时, 程序会在进入该变量的作用域时会自动申请内存空间, 并在变量离开作用域时自动free.
除了上述两种memory allocation, GNU C Library还提供了另一种方法: dynamic allocation. Dynamic allocation可让程序来决定内存申请和释放的时间, 并且可以决定内存申请的大小. 程序员必须明确地调用GNU C Library的函数来allocate或free内存, 但由于dynamic allocation需要更多计算时间, 所以只有在automatic allocation不能满足要求时才使用dynamic allocation. 使用dynamic allocation时不能用variable来声明d, 只能使用一个指针来指向该内存, 例如:
```c
struct foobar *ptr = (struct foobar *) malloc(sizeof(struct foobar));
ptr->name = x;
ptr->next = current_foobar;
current_foobar = ptr;
```

### 2.2 The GNU Allocator
GNU C Library中的malloc函数是从ptmalloc(pthreads malloc)派生而来, 以下是malloc中一些名词的解释:
1. Arena: 被多个thread共享使用的结构, 可包含一个或多个heap.
2. Heap: 一块连续的内存, 包含一个或多个chunk, 每个heap都属于一个arena.
3. Chunk: 可被程序申请, 可被glibc释放, 可与相邻chunk合并的一小块内存. Chunk是程序申请内存的一个wrapper, 每一个chunk都属于一个heap, 也属于一个arena.

通常情况下. GNU C Library为了多线程程序的效率, 会在heap上维护多个arena. 但与其他不同的是, 无论申请的内存大小, malloc都不会将chunk的大小保持在2的倍数. 当调用free来释放chunk时, 会自动与相邻的chunk合并, 这样可降低因fragmentation导致的内存浪费. 多个arena可保证多个thread同时申请内存, 依次提高性能. 当申请的内存过大时(例如: 申请的内存大于一个page), glibc会使用**mmap**来申请内存. mmap的好处在于, mmap会跳过arean, 直接向系统申请一个chunk, 因此当free该内存时, chunk可立刻返还给系统. 

### 2.3 Unconstrained Allocation
#### 2.3.1 Basic Memory Allocation
```c
/**
 * @brief return a pointer to a newly allocated block size bytes long, or a null 
 *        pointer if the block could not be allocated
 */
void *malloc (size t size);
```
malloc申请的内存被没有任何初始化, 返回的指针类型为void, 虽然ISO C会自动将void*转换为其他类型, 但如果想继续使用traditional C, 则需要手动转换类型. 如果想初始化该内存, 可使用memset:
```c
struct foo *ptr;
ptr = (struct foo *) malloc(sizeof(struct foo));
if (ptr == 0)
  abort();
memset(ptr, 0, sizeof(struct foo));
```

#### 2.3.2 Examples of malloc
当内存空间不足时, malloc会返回null pointer, 因此程序需要手动检查每一次malloc的返回值. 一种有效的解决方案就是为malloc创建一个wrapper function:
```c
void *xmalloc (size_t size)
{
  void *value = malloc (size);
  if (value == 0)
    fatal ("virtual memory exhausted");
  return value;
}
```
当为字符串申请内存时需注意: 申请的内存大小应为字符串长度+1, 为字符串的结尾null character留出一个字符的空间.
```c
char *savestring (const char *ptr, size_t len)
{
  char *value = (char *) xmalloc (len + 1);
  value[len] = '\0';
  return (char *) memcpy (value, ptr, len);
}
```
malloc返回的内存是已经对齐过的, 在32-bit系统上, 地址以8的倍数对齐; 在64-bit系统上, 地址以16的倍数对齐. 

#### 2.3.3 Free Memory Allocated with malloc
当不再需要malloc申请的内存后, 可调用free函数来回收该内存:
```c
/**
 * @brief deallocate the block of memory pointed at by ptr
 */
void free (void *ptr);
```
free内存会直接修改内存里的数据, 因此不应在free后再去访问该内存的数据. 以下是一种free所有block的方法:
```c
struct chain
{
  struct chain *next;
  char *name;
}
void free_chain (struct chain *chain)
{
  while (chain != 0)
  {
    struct chain *next = chain->next;
    free (chain->name);
    free (chain);
    chain = next;
  }
}
```
通常情况下, free()不会将内存归还给系统, 而是作为malloc()的下次使用, malloc会用一个free-list连接起所有空闲内存块. 当程序运行结束时不需要释放内存, 因为进程结束后, 所有进程资源会自动归还给系统, 其中包括内存.

#### 2.3.4 Change the Size of a Block
```c
/**
 * @brief change the size of the block whose address is ptr to be newsize.
 * @return the new address of the block
 */
void * realloc (void *ptr, size t newsize);
```
若ptr指向的相邻内存后仍有空间, 则扩展空间; 若ptr指向的相邻内存已被使用, 则将内存复制到其他地址. 当ptr为null时, realloc()会直接申请一块新的内存, 与malloc(newsize)相同操作.
```c
/**
 * @brief changes the size of the block whose address is ptr to be long 
 *        enough to contain a vector of nmemb elements, each of size size. 
 */
void *reallocarray (void *ptr, size t nmemb, size t size)
```

#### 2.3.5 Allocate Cleared Space
```c
/**
 * @brief allocate a block long enough to contain a vector of count elements,
 *        each of size eltsize
 */
void *calloc (size t count, size t eltsize);
```

#### 2.3.6 Allocate Aligned Memory Blocks
```c
/**
 * @brief allocate a block of size bytes whose address is a multiple of alignment
 * @return a null pointer on error and set errno to one of the following values:
 *         ENOMEN: insufficient memiry available to satisfy the request
 *         EINVAL: alignment is not a power of two
 */
void *aligned_alloc (size t alignment, size t size);

/**
 * @brief allocate a block of size bytes whose address is a multiple of boundary
 */
void *memalign (size t boundary, size t size);

/**
 * @brief allocates size bytes and places the address of the allocated memory 
 *        in *memptr. The address of the allocated memory will be a multiple of alignment
 * @param alignment must be a power of two and a multiple of sizeof(void *)
 */
int posix_memalign (void **memptr, size t alignment, size t size);

/**
 * @brief allocate size bytes and return a pointer to the allocated memory.
 *        The memory address will be a multiple of the page size.
 */
void * valloc (size t size);
```

#### 2.3.7 Malloc TUnable Parameters
```c
/**
 * @brief adjust some parameters for dynamic memory allocation
 * @param param specify the parameter to be set as follow:
 *        1. M_MMAP_MAX: The maximum number of chunks to allocate with mmap, 
 *        zero disables all use of mmap
 *        2. M_MMAP_THRESHOLD: All chunks larger than this value are allocated 
 *        outside the normal heap, using the mmap system call
 *        3. M_PERTURB: If non-zero, the least significant byte is filled with 
 *        the complement of value when allocation
 *        4. M_TOP_PAD: the amount of extra memory to obtain from the system 
 *        when an arena needs to be exteneded
 *        5. M_TRIM_THRESHOLD: when the amount of contiguous free memory at the 
 *        top of the heap is large than the value, free this memory block back 
 *        to system
 *        6. M_ARENA_TEST: specify the number of arena that can be created. The 
 *        value is ignored if M_ARENA_MAX is set
 *        7. M_ARENA_MAX: set the number of arenas regardless of the number of 
 *        cores in systems
 */
int mallopt (int param, int value);
```

#### 2.3.8 Heap Consistency Checking
```c
/**
 * @brief check the consistency of dynamic memeory
 * @param abortfn the function to call when consistency checks
 */
int mcheck (void (*abortfn) (enum mcheck_status status));
```

#### 2.3.9 Memory Allocation Hooks
GNU C Library提供了一些hook方便在dynamic memory allocation中debug:
1. __malloc_hook: 当该函数指针不为NULL时, 调用malloc时会触发这个hook, 函数原型如下:
  ```c
  /**
   * @param size same as `size` of malloc()
   * @param caller the address of malloc function
   */
  void *function (size_t size, const void *caller)
  ```
2. __realloc_hook: 当该函数指针不为NULL时, 调用realloc时会触发这个hook, 函数原型如下:
  ```c
  /**
   * @param ptr same as `ptr` of realloc()
   * @param size same as `same` of realloc()
   * @param caller the address of realloc function
   */
  void *function (void *ptr, size_t size, const void *caller);
  ```
3. __free_hook: 当该函数指针不为NULL时, 调用free时会触发这个hook, 函数原型如下:
  ```c
  /**
   * @param ptr same as `ptr` of free()
   * @param caller the address of free function
   */
  void function (void *ptr, const void *caller);
  ```
4. __memalign_hook: 当该函数指针不为NULL时, 调用aligned_alloc, memalign或posix_memalign时会触发这个hook, 函数原型如下:
  ```c
  /**
   * @param alignment same as `alignment` of memalign()
   * @param size same as `size` of memalign()
   * @param caller the address of memalign function
   */
  void *function (size_t alignment, size_t size, const void *caller);
  ```
注意: 在hook中, 只有恢复原来的hook后才能调用内存函数, 否则会造成无限循环. 以下是__malloc_hook和__free_hook的例子:
```c
#include <malloc.h>

static void *my_malloc_hook (size_t, const void *);
static void my_free_hook (void*, const void *);

static void my_init (void)
{
  old_malloc_hook = __malloc_hook;
  old_free_hook = __free_hook;
  __malloc_hook = my_malloc_hook;
  __free_hook = my_free_hook;
}

static void *my_malloc_hook (size_t size, const void *caller)
{
  void *result;
  /* Restore all old hooks */
  __malloc_hook = old_malloc_hook;
  __free_hook = old_free_hook;

  /* Call recursively */
  result = malloc (size);

  /* Save underlying hooks */
  old_malloc_hook = __malloc_hook;
  old_free_hook = __free_hook;

  /* printf might call malloc, so protect it too. */
  printf ("malloc (%u) returns %p\n", (unsigned int) size, result);

  /* Restore our own hooks */
  __malloc_hook = my_malloc_hook;
  __free_hook = my_free_hook;
  return result;
}

static void my_free_hook (void *ptr, const void *caller)
{
  /* Restore all old hooks */
  __malloc_hook = old_malloc_hook;
  __free_hook = old_free_hook;

  /* Call recursively */
  free (ptr);

  /* Save underlying hooks */
  old_malloc_hook = __malloc_hook;
  old_free_hook = __free_hook;

  /* printf might call free, so protect it too. */
  printf ("freed pointer %p\n", ptr);

  /* Restore our own hooks */
  __malloc_hook = my_malloc_hook;
  __free_hook = my_free_hook;
}

main ()
{
  my_init ();
}
```

#### 2.3.10 Statistics for Memory Allocation with malloc
通过mallinfo()函数可获得dynamic memory allocation的信息, 函数原型如下:
```c
struct mallinfo mallinfo (void);
```
struct mallinfo包含以下成员:
1. int arena: malloc中调用sbrk申请的内存大小, 单位为byte
2. int ordblks: 未使用的chunk数量
3. int smblks: unused
4. int hblks: 使用mmap申请的chunk数量
5. int hblkhd: 使用mmp申请的内存大小, 单位为byte
6. int usmblks: unused
7. int uordblks: allocator中已使用的内存大小, 单位为byte
8. int fordblks: allocator中未被使用的内存大小, 单位为byte
9. int keepcost: heap顶端可释放的内存大小


## 3. Obstacks
Obstack是一个内存池, obstack中必须第一个释放最后一个申请的对象. 除了释放对象的顺序限制, obstack和其他的内存池相同.

### 3.1 Create Obstacks
Obstack用结构体`struct obstack`来表示, 该结构体拥有固定的内存大小, 并记录了obstack的各种状态和其拥有的对象. 程序不应直接访问该结构体, 而应该调用obstack函数. Obstack中的所有对象都会被包装进一个名为chunks的内存块中, `struct obstac`会指向一个链表来表示所拥有的的chunks. 当申请的对象比当前chunk还要大时, 会自动申请新的chunk. 虽然不必手动管理chunk, 但还是需要为obstack提供一个申请chunk的函数, 一般会直接使用malloc.

### 3.2 Prepare for Using Obstacks
当程序中需要调用obstack函数时, 需在header中添加`obstack.h`; 当源文件中使用了`macro obstack_ini`时, 还需要定义两个函数或macro:
```c
#define obstack_chunk_alloc xmalloc
#define obstack_chunk_free free
```
`obstack_chunk_alloc`用于为chunk申请内存, `obstack_chunk_free`用于释放chunk的内存. 虽然obstack也是通过调用malloc来获取内存, 但实际中obstack会比程序自己调用malloc要快, 因为obstack会尽量少的调用obstack_chunk_alloc. 在使用`struct obstack`前, 需先调用obstack_init()来初始化该obstack:
```c
/**
 * @brief initialize obstack for allocation of objects
 * @param ptr pointer to obstack
 * @return always return 1, call obstack_failed_handler if fails
 */
int obstack_init (struct obstack *ptr);
```
obstack_failed_handler为函数指针, 函数原型如下:
```c
void *function (void);
```
以下是初始化obstack的例子:
```c
void my_obstack_alloc_failed (void);
obstack_alloc_failed_handler = &my_obstack_alloc_failed;

/* static variable */
static struct obstack ptr1;
obstack_init (&ptr1);

/* dynamically allocated */
struct obstack *ptr2 = (struct obstack *) xmalloc (sizeof (struct obstack));
obstack_init (ptr2);
```

### 3.3 Allocation in an Obstack
在obstack中申请对象最直接方式就是调用`obstack_alloc`, 函数如下:
```c
/**
 * @brief allocate an uninitialized block of `size` bytes in an obstack and 
 *        return its address
 * @param ptr the address of struct obstack object which represents the obstack
 */
void *obstack_alloc (struct obstack *ptr, int size)
```
以下是在obstack中申请一个字符串`str`拷贝的例子:
```c
struct obstack string_obstack;

char *copystring (char *string)
{
  size_t len = strlen (string) + 1;
  char *s = (char *) obstack_alloc (&string_obstack, len);
  memcpy (s, string, len);
  return s;
}
```
如果想初始化obstack申请的内存, 可调用`obstack_copy`函数, 函数如下:
```c
/**
 * @brief allocate and initialize it by copying `size` bytes of data starting 
 *        at `address`
 */
void * obstack_copy (struct obstack *ptr, void *address, int size);
```

### 3.4 Free Objects in an Obstack
由于obstack是栈结构, 因此可以释放一个或多个对象. 
```c
/**
 * @brief If `object` is a null pointer, everthing allocated in the obstack is 
 *        freed; Otherwise, every object since `object` will be freed 
 */
void obstack_free (struct obstack *ptr, void *object);
```
若参数object为null, 则obstack会变为未初始状态; 若参数为第一个申请的对象的指针, 则obstack会释放所有对象, 但还可以用于申请内存.

### 3.5 Grow Objects
由于obstack中的chunk都是连续的, 因此已经申请内存的object无法改变内存大小. 但obstack提供了一种可拓展object的方式, 称为`growing objects`. 该方法可在obstack的末端不断扩充内存, 直到调用`obstack_finish`才返回新object的地址. 当正在生成growing object时, obstack不能调用其他allocation函数.
```c
/**
 * @brief add an uninitializing space to the growing object
 */
void obstack_blank (struct obstack *ptr, int size);

/**
 * @brief add a block of initialized space to the growing object
 */
void obstack_grow (struct obstack *ptr, void *data, int size);

/**
 * @brief finish the growing object and return its address
 */
void * obstack_finish (struct obstack *ptr);

/**
 * @brief return the current size of the growing object in bytes. Must be called before obstack_finish()
 */
int obstack_object_size (struct obstack *ptr);
```

### 3.7 Status of an Obstack
以下函数可提供某个obstack的当前状态:
```c
/**
 * @brief return the tentative address of the beginning of the currently growing obejct
 */
void * obstack_base (struct obstack *ptr);

/**
 * @brief return the address of the first free byte in the current chunk
 */
void * obstack_next_free (struct obstack *ptr);

/**
 * @brief return the size in bytes of the currently growing object
 *        equal to obstack_next_free(ptr) - obstack_base(ptr)
 */
int obstack_object_size (struct obstack *ptr);
```

### 3.8 Alignment of Data in Obstacks
每个obstack都有一个alignment boundary. 申请object时, obstack会从alignment boundary的倍数开始. Obstack提供了一个macro来获取或修改alignment boundary:
```c
int obstack_alignment_mask (struct obstack *ptr);
```

### 3.9 Obstack Chunks
obstack会申请一个chunk来放置一个或多个对象. Chunk默认大小为4096 bytes, 包含8 bytes的额外开销. Obstack提供了一个macro来获取或修改chunk size:
```c
int obstack_chunk_size (struct obstack *ptr);
```
chunk size应为2的倍数, 且不应比4096小.


## 4. Resize the Data Segment
通常来说, 程序不需要直接调用这一节的函数, 只为GNC C Library memory allocator自用, 也可以当做system call的接口.
```c
/**
 * @brief change the space allocated for the calling process by setting the
 *        process' break value to `addr`
 * @return zero on success, -1 on failure and errno is set
 */
int brk (void *addr);

/**
 * @brief change the space allocated for the calling process by adding `delta` 
 *        bytes to the process' break value
 */
void *sbrk (ptrdiff_t delta);
```
sbrk(0)会返回当前data segment的地址.


## 5. Memory Protection
当pageyo由mmap分配时, 可使用以下protection flag来设置memory;
1. PROT_WRITE: memory可写入
2. PROT_READ: memory可读, 也表示memory可执行(除非明确设置PROT_EXEC flag)
3. PROT_EXEC: memory内的instruction可执行
4. PROT_NONE: memory不可读, 写或执行

protection flag由以下函数执行:
```c
/**
 * @brief change the protection flag of at least `length` bytes of memory
 * @param address must be aligned to the page size for the mapping
 * @param length round up to the next multiple of the system page size
 */
int mprotect (void *address, size_t length, int protection);
```
以下是mprotect()的例子:
```c
#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <malloc.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/mman.h>

#define handle_error(msg) do { perror(msg); exit(EXIT_FAILURE); } while (0)

static char *buffer;

static void handler(int sig, siginfo_t *si, void *unused)
{
  printf("Got SIGSEGV at address: 0x%lx\n", (long) si->si_addr);
  exit(EXIT_FAILURE);
}

int main(int argc, char *argv[])
{
  char *p;
  int pagesize;
  struct sigaction sa;

  sa.sa_flags = SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = handler;
  if (sigaction(SIGSEGV, &sa, NULL) == -1)
    handle_error("sigaction");

  pagesize = sysconf(_SC_PAGE_SIZE);
  if (pagesize == -1)
    handle_error("sysconf");

  /* Allocate a buffer aligned on a page boundary; 
     initial protection is PROT_READ | PROT_WRITE */

  buffer = memalign(pagesize, 4 * pagesize);
  if (buffer == NULL)
    handle_error("memalign");

  printf("Start of region: 0x%lx\n", (long) buffer);

  if (mprotect(buffer + pagesize * 2, pagesize, PROT_READ) == -1)
    handle_error("mprotect");

  for (p = buffer ; ; )
    *(p++) = 'a';

  printf("Loop completed\n"); /* Should never happen */
  exit(EXIT_SUCCESS);
}
```

## 6. Locking Pages
Local page可让virtual memory page和page frame一直保持关联, 从而让page frame不会被page-out(移出内存), 这样就不会产生page fault.

### 6.1 Why Lock Pages
以下是使用lock page的理由:
1. Speed: 虽然page fault对于进程来说是不可察觉的, 但对于时间敏感性的进程, page fault所造成了执行速度降低是不能容忍的
2. Privacy: 如果需要将某些secret放置在virtual memory中, 可使用lock memory来防止secret被写入到disk swap space中, 从而可以增强隐私性

需要注意的是, lock的内存越多, 就有越少的page frame可以用于支持virtual memory page, 从而导致更频繁的page fault

### 6.2 Lock Memory Details
* Memory lock和virtual page关联, 并不和page frame关联. 当lock绑定了某个virtual page后, virtual page对应的page frame不会被page-out.
* Memory lock不能叠加, 每个virtual memory page只能添加一个memory lock, virtual memory page只有被锁和未被锁两种状态.
* 只有进程释放memory lock, memory lock才会被消除.(进程结束也会导致memory lock消失)
* 在UNIX中, fork()产生的child process获得一份parent process的virtual memory space的复制品, 因此它们共享同一块page frame. 由于child process和parent process使用相同的memory page, 因此memory lock也会继承
* 进程只能为自己的page添加memory lock, 不可为其他进程的page添加memory lock
* kernel会限制每个进程的memory lock大小 
* 在Linux中, 即使两个virtual page并不是shared memory, 只要它们含有相同的数据, kernel也会用一个page frame来支持这两个virtual memory page(即使其中一个或两个virtual page拥有memory lock). 因此当某个进程试图修改其中一个virtual page时, kernel会重新分配一个frame并填充新的数据, 这也称为**copy-on-write page fault**. 
* 为了确保不会出现**page fault**, 不要只是为page上锁. 最好的方法是: 申请一个足够大的**C automatic variable**(例如array)并写入, 写入什么东西并不是关键, 但这种`假`写入可以确保virtual page被映射到page gram上, 从而避免**copy-on-write page fault**.

### 6.3 Functions to Lock And Unlock Pages
```c
/**
 * @brief lock a range of the calling process's virtual pages
 * @return zero if succeeds; -1 if error and errno is set
 */
int mlock (const void *addr, size_t len);

/**
 * @brief unlock a range of the calling process's virtual pages
 */
int munlock (const void *addr, size_t len);

/**
 * @brief lock all the pages in a process' virtual memory address space
 * @param flag a string of single bit flags represented by the following macros
 *        MCL_CURRENT: Lock all pages which currently exist in the calling process' virtual address space
 *        MCL_FUTURE: any pages added to the process' virtual address space in the future will be locked
 */
int mlockall (int flags);

/**
 * @brief unlock every page in the calling process' virtual address space 
 *        and turns off MCL_FUTURE future locking mode
 */
int munlockall (void);
```
