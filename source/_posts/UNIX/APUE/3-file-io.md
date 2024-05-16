---
title: File I/O
tags:
  - Unix
category:
  - Unix
abbrlink: aabf
date: 2019-07-29 17:39:17
---

## 1. File Descriptors
* 所有正在使用的文件都有一个或多个file descriptor
* File descriptor为正整数
* File descriptor的数量由系统决定(整数的内存大小)

### 1.1 open and openat
```c
#include <fcntl.h>

/** 
 * @brief Opens the file specified by pathname, if file does 
 *        not exist, it may optionally be created (if O_CREAT 
 *        in flags).
 * @return A file descriptor, a nonnegative integer used for 
 *         other system call. On error, -1 is returned and 
 *         errno is set.
 */
int open(const char *pathname, int flags);
int open(const char *pathname, int flags, mode_t mode);

/**
 * @brief Same as open(). If the pathname given in pathname is 
 *        relative, then it is interpreted relative to the 
 *        directory referred to by the file descriptor `dirfd`
 * @return Same as open().
 */
int openat(int dirfd, const char *pathname, int flags);
int openat(int dirfd, const char *pathname, int flags, mode_t mode);
```
flags全称为**File Status Flag**(文件状态标志), 可由一个或多个常量通过**或操作**(OR)组成, 分为以下三类:
* File Access mode: 
  * O_RDONLY: 打开文件以进行读取
  * O_WRONLY: 打开文件以进行写入
  * O_RDWR: 打开文件以进行读取和写入
  * O_PATH: 获得文件的file descriptor, 但不打开文件以读取或写入
  * O_ACCMODE: file access mode的mask, 对flag使用mask可获取对应的file access mode
* Open-Time Flags: 指定`open()`的行为方式
  * O_CREAT: 若path指定的文件不存在, 则创建新文件
  * O_EXEC: 与O_CREAT共用, 表示创建的文件不能重名, 否则创建失败
  * O_DIRECTORY: 若已设置O_CREAT, 则报错. 用于确保path为一个文件夹, 而不是文件
  * O_NOFOLLOW: 若path指向一个symbolic link(也称为soft link), 则报错
  * O_TMPFILE: 创建一个无名的临时文件
  * O_NOCTTY: 若path指向一个terminal device, 则不会让该文件成为当前进程的controlling terminal(控制终端)
  * O_IGNORE_CTTY: 不将目标文件作为controlling terminal
  * O_NOLINK: 若目标文件为symbolic link, 则打开link本身, 不打开其指向的文件
  * O_NOTRANS: 不对目标文件进行translate
  * O_TRUNC: 若文件存在, 允许写入, 且不为FIFO或terminal device, 则文件长度会被截断为零
  * O_SHLOCK: 自动为目标文件获取shared lock
  * O_EXLOCK: 自动为目标文件获取exclusive lock
* I/O Operating Modes: 如何输入和输出
  * O_APPEND: 将file offset移至文件最后
  * O_NONBLOCK: 以非阻塞模式打开文件
  * O_ASYNC: 启动异步输入模式
  * O_FSYNC: 启动同步写入模式, 确保`write()`将数据刷入磁盘中
  * O_SYNC: 与`O_SYNC`相同
  * O_NOATIME: `read()`不会更新文件的access times

需要注意的是, POSIX中**Synchronized I/O**还定义了`O_RSYNC` flag, 但通常不会实现该flag.

mode作为`open()`和`openat()`的参数, 表示创建新文件时的文件权限:
* S_IRWXU: 00700, user(file owner)拥有read, write, and execute权限
* S_IRUSR: 00400, user拥有read权限
* S_IWUSR: 00200, user拥有write权限
* S_IXUSR: 00100, user拥有execute权限
* S_IRWXG: 00070, group拥有read, write, execute权限
* S_IRGRP: 00040, group拥有read权限
* S_IWGRP: 00020, group拥有write权限
* S_IXGRP: 00010, group拥有execute权限
* S_IRWXO: 00007, others拥有read, write, execute权限
* S_IROTH: 00004, others拥有read权限
* S_IWOTH: 00002, others拥有write权限
* S_IXOTH: 00001, others拥有execute权限

### 1.2 creat
```c
#include <fcntl.h>

/**
 * @brief Create a new file or rewrite an existing one.
 */
int creat(const char *path, mode_t mode);
```
`creat()`与以下函数拥有同样功能:
```c
/* Write-Only */
open(path, O_WRONLY | O_CREAT | O_TRUNC, mode);

/* Read-and-Write */
open(path, O_RDWR | O_CREAT | O_TRUNC, mode);
```

### 1.3 close
```c
#include <unistd.h>

/**
 * @brief Closes a file descriptor. Any record locks owned by 
 *        the process are removed.
 * @return 0 for success; -1 for error, and errno is set.
 */
int close(int fd);
```
1. 调用`close()`并不代表数据刷入磁盘, kernel一般会滞后flush操作, 只有调用`fsync()`才能确保数据被刷入磁盘. 
2. 调用`close()`时需确保当前进程下的其他线程没有使用该文件. 假设某进程拥有两个线程, 并进行如下操作:
  * 线程1被文件I/O系统调用阻塞, 例如, 调用`write()`时pipe已满, 或从socket读取数据
  * 线程2关闭文件, 有些操作系统会向线程1抛出异常, 有些则成功写入或读取数据
3. 进程退出时, 所关联的file descriptor会自动关闭, 因此并不需要显式调用`close()`

### 1.4 lseek
```c
#include <unistd.h>

/**
 * @brief reposition read/write file offset
 * @return resulting offset for success; -1 for error and 
 *         errno is set.
 */
off_t lseek(int fd, off_t offset, int whence);
```
whence决定了offset的方向, 有三个选项:
* SEEK_SET: 将文件的offset设置为`ofst`, `new ofst = ofst`
* SEEK_CUR: 文件原有offset加上`ofst`, `new ofst = old ofst + ofst`
* SEEK_END: 文件大小加上`ofst`, `new ofst = file size + ofst`
* SEEK_DATA: 若ofst指向的是非零数据, 则将offset设置为ofst; 若不是(hole), 则将offset设置为大于或等于ofst且数据非零的第一个地址.
* SEEK_HOLE: 与SEEK_DATA相反, 将offset设置为第一个数据为零的地址, 若ofst指向的数据为零, 则将offset设置为ofst

需要注意两点:
1. 由于lseek允许`offset > file size`, 所以写入时, 文件末尾和offset之间的用null byte(`\0`)填充.
2. 新的offset必须大于等于0, 否则不会覆盖文件原本的offset(除非fd为特定device).

### 1.5 read
```c
#include <unistd.h>

/**
 * @brief Reads up to nbytes bytes from file descriptor fd into
 *        the buffer starting at buf.
 * @return number of bytes read for success; 0 indicates end 
 *         of file; -1 for error and errno is set.
 */
ssize_t read(int fd, void *buf, size_t nbytes);
```
* `read()`会从offset的位置开始读取, 并将offset更新为`old offset + nbytes`. 若offset处于文件末尾, 则直接返回0.
* 若nbytes为0, 可能导致read()报错, 也可能返回0
* 若nbytes大于`SSIZE_MAX`, 结果以操作系统的实现为准.

### 1.6 write
```c
#include <unistd.h>

/** 
 * @brief Writes up to nbytes from the buffer start at buf to 
 *        the file referred to by the file decriptor fd.
 * @return The number of bytes written is returned for success. 
 *         -1 for error and errno is set.
 */
ssize_t write(int fd, const void *buf, size_t nbytes);
```
以下情况会导致`write()`返回值小于nbytes:
* 磁盘无法容纳nbytes
* 达到单个文件的最大容量`RLIMIT_FSIZE`
* 被signal handler终端

offset也会影响`write()`的写入结果:
* `write()`会从最新的offset写入数据, 写入后更新offset为`old offset + nbytes`
* 若以`O_APPEND`模式的打开文件, offset会设置为文件末尾, 写入数据会追加在文件末尾
* 修改offset和写入操作可视为一个原子操作


## 2. I/0 Efficiency
```c
#define BUFFSIZE 4096

int main(void)
{
  int n;
  char buf[BUFFSIZE];

  while ((n = read(STDIN_FILENO, buf, BUFFSIZE)) > 0)
  if (write(STDOUT_FILENO, buf, n) != n)
    err_sys("write error");

  if (n < 0)
    err_sys("read error");

  exit(0);
}
```
在不同的`BUFFSIZE`数值下, 读取速度也会变得不同:

| BUFFSIZE | User CPU (sec) | System CPU (sec) | Clock time (sec) | loops |
| :-----: | :-----: | :-----: | :-----: | :-----: |
| 1 | 124.89 | 161.65 | 288.64 | 103,316,352 |
| 2 | 63.10 | 80.96 | 145.81 | 51,658,176 |
| 4 | 31.84 | 40.00 | 72.75 | 25,829,088 |
| 8 | 15.17 | 21.01 | 36.85 | 12,914,544 |
| 16 | 7.86 | 10.27 | 18.76 | 6,457,272 |
| 32 | 4.13 | 5.01 | 9.76 | 3,228,636 |
| 64 | 2.11 | 2.48 | 6.76 | 1,614,318 |
| 128 | 1.01 | 1.27 | 6.82 | 807,159 |
| 256 | 0.56 | 0.62 | 6.80 | 403,579 |
| 512 | 0.27 | 0.41 | 7.03 | 201,789 |
| 1,024 | 0.17 | 0.23 | 7.84 | 100,894 |
| 2,048 | 0.05 | 0.19 | 6.82 | 50,447 |
| 4,096 | 0.03 | 0.16 | 6.86 | 25,223 |
| 8,192 | 0.01 | 0.18 | 6.67 | 12,611 |
| 16,384 | 0.02 | 0.18 | 6.87 | 6,305 |
| 32,768 | 0.00 | 0.16 | 6.70 | 3,152 |
| 65,536 | 0.02 | 0.19 | 6.92 | 1,576 |
| 131,072 | 0.00 | 0.16 | 6.84 | 788 |
| 262,144 | 0.01 | 0.25 | 7.30 | 394 |
| 524,288 | 0.00 | 0.22 | 7.35 | 198 |

可以发现:
* $\text{BUFFSIZE} \lt \text{4096 bytes}$: 读取速度与BUFFSIZE成正比
* $\text{BUFFSIZE} \gt \text{4096 bytes}$: 读取速度没有明显提升, 因为ext4的文件系统中, 一个inode为256字节, 一个block为4096字节


## 3. File Sharing
UNIX支持多个进程操作不同或相同的文件.
![All Installation Items](/images/UNIX/APUE/3-3-process-table-entry.png)

进程操作文件时涉及以下几个结构体:
1. Process table: kernel为每个进程创造一个process table, 里面除了进程的pid外, 还以`<key, value>`的形式存放进程操作的所有file decriptor以及对应的file table
2. File table: kernel将为每一个进程正在使用的文件创造一个table, 其中包含三个entry:
  * File Status Flags
  * Current file offset
  * Pointer to the v-node table
3. v-node table: kenerl为每一个打开的文件创建一个table, 其中包含文件类型, 操作文件的函数指针, 指向i-node的指针, 以及指向该table的file table数量.

总结一下, 一个进程只有一个process table, 但可以有多个file table; 一个被打开的文件只有一个v-node table, 但可以有多个file table指向同一个v-node table. 因此:
* 一个进程可打开多个文件
* 两个进程可打开同一文件, 且拥有不同的offset
* 同一文件可存在多个file table, 但都指向同一个v-node table


## 4. Atomic Operations
由于旧版本UNIX不支持`O_APPEND`选项, 所以追加文件时, 需先调用`lseek`, 再调用`write`, 导致追加文件成为一个非原子操作, 可能导致数据丢失. 只有使用`O_APPEND`后写入时才能保证并发安全.
UNIX提供了两个函数, 保证进程可以原子地指定offset并进行I/O操作.
```c
#include <unistd.h>

/**
 * @brief Reads from a file descriptor at a given offset
 * @return Number of bytes read for success; -1 for error and
 *         errno is set.
 */
ssize_t pread(int fd, void *buf, size_t nbytes, off_t offset);

/**
 * @brief Write to a file descriptor at a given offset
 * @return Number of bytes for written for success; -1 for 
 *         error and errno is set.
 */
ssize_t pwrite(int fd, const void *buf, size_t nbytes, off_t offset);
```


## 5. dup and dup2
```c
#include <unistd.h>

/**
 * @brief Creates a copy of the file descriptor oldfd, using 
 *        the lowest-numbered unused file descriptor
 * @return The new file descriptor for success; -1 for error 
 *         and errno is set.
 */
int dup(int oldfd);

/**
 * @brief Creates a copy of the file descriptor oldfd, using 
 *        the file descriptor number specified in newfd
 * @return Same as dup()
 */
int dup2(int oldfd, int newfd);
```
* `dup()`的返回值一定是数值最小且当前进程中未使用的file descriptor
* 假设`dup()`返回的file descriptor为newfd, 则newfd与oldfd共享offset和file status flag. 因此, `lseek()`修改newfd的offset时, oldfd的offset也会被修改
* `dup2()`不会使用数值最小的file descriptor, 而是使用newfd
* 若newfd之前被打开过, `dup2()`会在重用newfd前自动关闭该文件, 并且, **关闭**和**重用**是一个原子操作, 可避免race condition


## 6. sync, fsync, fdatasync
UNIX会在kernel中创建一个cache, 用于存放I/O操作的修改内容. 写入数据时, 数据并不会直接写入磁盘, 而是保存在cache中, 等待kernel将其写入磁盘. 为防止数据滞留在buffer中, 可使用sync函数:
```c
#include <unistd.h>

/**
 * @brief Flush all modified data specified by the file
 *        descriptor fd to disk. The writing is complete
 *        when the fsync() call returns.
 */
int fsync(int fd);

/**
 * @brief Same as fsync(), but does not flush modified metadata 
 *        unless that metadata is needed in order to allow a 
 *        subsequent data retrieval to be correctly handled.
 */
int fdatasync(int fd);

/**
 * @brief Schedule all modified data for writing to disk. The 
 *        writing is not necessarily complete when the sync() 
 *        call returns.
 */
void sync(void);
```


## 7. fcntl
```c
#include <fcntl.h>

/**
 * @brief Change the properties of a file that is opened.
 */
int fcntl(int fd, int cmd, ... /* int arg */ );
```
fctnl可修改file descriptor, 其必须接收两个参数: file descriptor, cmd, 第三个参数arg为可选项, 取决于cmd是否需要, 若不需要, 则为void. 以下是fctnl的参数(`F_XXX`表示cmd, 括号内表示arg).

### 7.1 Duplicate a file descriptor
* F_DUPFD(int): 复制file descriptor, 返回一个大于等于`arg`且可用的file descriptor
* F_DUPFD_CLOEXEC(int): 功能与F_DUPFD相同, 但会在复制的file descriptor上添加`close-on-exec` flag(成功执行exec后自动关闭文件)

### 7.2 File Descriptor Flags
* F_GETFD(void): 返回file descriptor flags
* F_SETFD(int): 将file descriptor flags设置为arg

需要注意的是, 当前file descriptor flag只有一个参数: `FD_CLOEXEC`

### 7.2 File Status Flags
* F_GETFL(void): 返回file status flags
* F_SETFL(int): 将file status flags设置为arg

### 7.3 Advisory Record Lock
该类别下的cmd可为文件中的一段区域添加锁, 因此arg需为一个lock pointer, lock的定义如下:
```c
struct flock {
  /* ... */
  short l_type;   /* Type of lock: F_RDLCK, F_WRLCK, F_UNLCK */
  short l_whence; /* How to interpret l_start: SEEK_SET, SEEK_CUR, SEEK_END */
  off_t l_start;  /* Starting offset for lock */
  off_t l_len;    /* Number of bytes to lock */
  pid_t l_pid;    /* PID of process blocking our lock (set by F_GETLK and F_OFD_GETLK) */
  /* ... */
}
```
* F_GETLK(`struct flock *`): 尝试为目标文件上锁, 但不会真正上锁. 若可以上锁, 则返回`F_UNLCK`; 若不能, 则返回冲突的锁的详细信息.
* F_SETLK(`struct flock *`): 为目标文件获取(`l_type`为`F_RDLCK`或`F_WRLCK`)或释放(`l_type`为`F_UNLCK`)锁; 若与其他进程发送锁冲突, 返回-1.
* F_SETLKW(`struct flock *`): 功能与`F_SETLK`相同, 但若目标文件存在冲突锁, 则阻塞并等待冲突锁释放.

### 7.4 Open File Description Locks
Advisory Record Lock由进程拥有, 因此不同进程可拥有同一文件中不同区域锁, 但存在一个问题: 同一进程的多个线程会共享lock, 一个线程无法阻塞其他线程访问同一文件, 因此UNIX引入了Open File Description Lock, 该类锁不与进程挂钩, 只与文件关联.
* F_OFD_SETLK(`struct flock *`): 获取或释放一个open file description lock
* F_OFD_SETLKW(`struct flock *`): 与`F_OFD_SETLK`相同, 但若目标文件存在冲突锁, 则阻塞并等待冲突锁释放
* F_OFD_GETLK(`struct flock *`): 尝试为目标文件上锁, 但不会真正上锁

### 7.5 Manage signals
* F_GETOWN(void): 在目标文件上执行IO操作时, 会产生SIGIO信号, 该cmd接收到信号的进程ID
* F_SETOWN(int): 为了接收到目标文件执行IO操作产生的SIGIO信号, 该cmd会将信号转交给arg对应的进程


## 8. ioctl
```c
#include <unistd.h>
#include <sys/ioctl.h>

/**
 * @brief Anything that couldn’t be expressed using one of the 
 *        other functions in this chapter usually ended up being
 *        specified with this function.
 */
int ioctl(int fd, int request, ...);
```
一种获得设备信息和向设备发送控制参数的方法.

