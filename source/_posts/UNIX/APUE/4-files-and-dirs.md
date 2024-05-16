---
title: Files and Directories
tags:
  - Unix
category:
  - Unix
abbrlink: 49f7
date: 2019-08-05 16:30:42
---

## 1. stat, fstat, fstatat, lstat
```c
/**
 * @brief retrieve information about the file pointed to by 
 *        pathname to buf. It returns information of file 
 *        pointed by pathname if pathname is a symbolic link.
 */
int stat(const char* pathname, struct stat* buf);

/**
 * @brief same as stat(), except the file about which information
 *        is to be retrieved is specified by file descriptor.
 */
int fstat(int fd, struct stat* buf);

/**
 * @brief same as stat(), except returns the information of itself 
 *        if pathname is a symbolic link.
 */
int lstat(const char* pathname, struct stat* buf);

/**
 * @brief provide a general interface for accessing file
 *        information which can still provide the function of 
 *        stat(), lstat() and fstat().
 * @param flag can be either 0, or include one of the followings:
 *        1. AT_EMPTY_PATH: If pathname is an empty string, operate
 *           on the file referred by dirfd.
 *        2. AT_SYMLINK_NOFOLLOW: Same as lstat(), returns the 
 *           information of symbolic link instead the file referred 
 *           by the link.
 */
int fstatat(int dirfd, const char* pathname, struct stat* buf, int flag);
```
参数`buf`是为指向stat结构体的指针, stat的定义如下:
```c
struct stat {
  mode_t st_mode;          /* file type & mode (permissions) */
  ino_t st_ino;            /* i-node number (serial number) */
  dev_t st_dev;            /* major device number */
  dev_t st_rdev;           /* minor device number */
  nlink_t st_nlink;        /* number of hard links */
  uid_t st_uid;            /* user ID of owner */
  gid_t st_gid;            /* group ID of owner */
  dev_t st_rdev;           /* device ID (if special file) */
  off_t st_size;           /* total size in bytes */
  struct timespec st_atim; /* time of last access */
  struct timespec st_mtim; /* time of last modification */
  struct timespec st_ctim; /* time of last file status change */
  blksize_t st_blksize;    /* preferred block size for filesystem I/O */
  blkcnt_t st_blocks;      /* number of 512-byte blocks allocated */
};
```
timespec的定义如下:
```c
struct timespec {
  time_t tv_sec; /* second */
  long tv_nsec;  /* nanosecond */ 
}
```


## 2. File Types
以下是UNIX的文件类型:
* Regular File(`S_IFREG`): 最常见的文件类型, 该文件类型负责保存数据, 无论二进制还是文本数据, 应用程序读取或更新该文件.
* Directory File(`S_IFDIR`): 该文件可包含一些文件的名字或指向文件的指针, 可读取directory file, 但程序只能调用kernel function通过kernel向directory file写入文件
* Special File: 也称为**device file**, 其意义在于将device呈现为文件系统中的一个file, 开发者可以像操作**传统文件系统中的文件**一样操作**hardware device**, 读写该类文件时, 请求会转交给device driver, 而不是由文件系统处理. 根据**操作模式**两种special file:
  * Block Special File(`S_IFBLK`): 该设备上的数据会被持久化, 反复读取, 且每次访问取出一块连续数据的block, 因此称为**block device**, 如`/dev/disk0`
  * Character Special File(`S_IFCHR`): 该设备上的数据只被读取一次, 顺序执行, 且每次访问只取1 byte, 因此称为**character device**, 如`/dev/stdin`
* FIFO(`S_IFIFO`): 也称为**pipe**. UNIX的一大优势为IPC(进程间通信), 当一个进程与其他进程通信时, 可创建pipe向其他进程发送数据
* Socket(`S_IFSOCK`): 可用于IPC, 但也可以通过网络传输数据
* Symbolic Link(`S_IFLNK`): 该文件类型是对另一个文件的引用, 存储了引用文件的路径

stat结构体的st_mode表示文件类型, 可用以下macro判断文件是什么类型(m表示`stat.st_mode`):
1. `S_ISREG(m)`: 是否为regular file
2. `S_ISDIR(m)`: 是否为directory file
3. `S_ISCHR(m)`: 是否为character special file
4. `S_ISBLK(m)`: 是否为block special file
5. `S_ISFIFO(m)`: 是否为FIFO
6. `S_ISLNK(m)`: 是否为symbolic link
7. `S_ISSOCK(m)`: 是否为socket


## 3. User ID and Group ID
当用户使用计算机时, 需登录一个username, 通常来说, 一个username对应一个**user ID**. User通过group分类, 每个user可属于多个group, 同一group内的user可共享资源. 每个group有一个group name和**group ID**.
用户无法直接访问资源, 而是通过process(进程), POSIX standard为process规定了三种user ID:
* Real User ID(RUID): 创建当前process的用户的user id, 表示当前进程属于哪个用户
* Effective User ID(EUID): 系统用EUID判断当前process是否有权限访问资源, 创建进程时为RUID, 可通过`seteuid`将EUID改为执行文件所有者的user id.
* Saved User ID(SUID): 当privileged process(EUID为root)降低自身权限时, 会先将EUID保存在SUID, 执行完毕后, 将EUID改回SUID.

POSIX Standard还为process规定了三种group ID:
* Real Group ID(RGID): 创建当前process的用户所在的group的group id
* Effective Group ID(EGID): 系统用EGID判断当前process是否有权限访问资源, 创建进程时维RGID, 可通过`setegid`将EGID改为执行文件所有者的group id
* Saved Group ID(SGID): 当privileged process(EGID为root)降低自身权限时, 会先将EGID保存在SGID, 执行完毕后, 将EGID改回SGID

## 4. File Access Permissions
UNIX中的每一个文件都有权限设置, 由9个bit组成, 如`rwxrwxrwx`, 并分为三类:
* owner: 第一组`rwx`, 文件所有者的权限
* group: 第二组`rwx`, 文件所属组的权限
* other: 第三组`rwx`, 其他人的权限

每组权限包含三种权限:
* r: 查看文件内容, 或查看文件夹内的文件列表
* w: 修改或删除文件, 或从文件夹中添加或删除文件
* x: 运行可执行文件, 或搜索文件夹内文件, 但不能读取文件夹内的文件列表

有时文件的拥有者并不想其他进程修改或读取文件内容, 但需要其他进程执行该文件. 因此UNIX还增加三种额外的权限模式:
* setuid(SUID): 进程执行该文件期间, 当前进程的EUID改为文件所有者的user id, 如`rwsrwxrwx`
* setgid(SGID): 进程执行该文件期间, 当前进程的EGID改为文件所有者的group id, 如`rwxrwsrwx`
* sticky(SBIT): 对于可执行文件, 即使进程运行结束, kernel也会将text segment保留在内存中, 但目前只有极少数UNIX系统应用; 对于文件夹, 即使进程拥有写入权限, 如果不是文件夹拥有者或root, 则不能重命名, 移动或删除里面的文件.

调用`open`或`chmod`时, 可通过以下mode设置文件权限, 多个mode可通过**OR**(或运算)相连:

| mode | mask | class | permission |
| :-----: | :-----: | :-----: | :-----: |
| S_IRWXU | 00700 | user | read, write, execute |
| S_IRUSR | 00400 | user | read |
| S_IWUSR | 00200 | user | write |
| S_IXUSR | 00100 | user | execute |
| S_IRWXG | 00070 | group | read, write, execute |
| S_IRGRP | 00040 | read | read |
| S_IWGRP | 00020 | group | write |
| S_IXGRP | 00010 | group | execute |
| S_IRWXO | 00007 | other | read, write, execute |
| S_IROTH | 00004 | other | read |
| S_IWOTH | 00002 | other | write |
| S_IXOTH | 00001 | other | execute |
| S_ISUID | 0004000 | user | set-user-ID |
| S_ISGID | 0002000 | group | set-group-ID |
| S_ISVTX | 0001000 | other | sticky bit |

Kernel以一套规则来判断当前进程是否有权限来对文件进行操作:
1. 若EUID为0, 则当前进程为root, 允许操作
2. 若当前进程的EUID与文件所有者的user ID相同, 则使用文件owner的权限模式
3. 若当前进程的EGID与文件所有者的group ID相同, 则使用文件group的权限模式
4. 使用other的权限模式


## 5. access and faccessat
```c
/*
 * @brief check whether the calling process can access the file. 
 *        If pathname is a symbolic link, it is deferenced.
 * @param mode: specifies the accessibility of file. 
 *        * F_OK: the existence of the file
 *        * R_OK: whether the file has read permission
 *        * W_OK: whether the file has write permission
 *        * X_OK: whether the file has execute permission
 * @return zero is returned as all requested permissions granted; 
 *         -1 is returned as error and errno is set.
 */
int access(const char* pathname, int mode);

/**
 * @brief same as access(), but if the pathname is relative, it is
 *        interpreted relative to the directory referred to by dirfd.
 * @param dirfd interpreted relative to the directory referred to by 
          dirfd if it is file descriptor; interpreted relative to the 
          current working directory of the calling process if dirfd is
          the special value AT_FDCWD
 * @param flag constructed by OR together zero or more of the
 *        following value:
 *        * AT_EACCESS: perform access checks using the effective 
 *          user and group ID.
 *        * AT_SYMLINK_NOFOLLOW: If pathname is a symbolic link, 
 *          do not deference it.
 */
int faccessat(int dirfd, const char* pathname, int mode, int flag);
```


## 6. umask
```c
/**
 * @brief set the calling process's file mode creation to `mask` & 0777,
 *        used by open(), mkdir() and other system call.
 * @return the previous value of the mask.
 */
mode_t umask(mode_t mask); 
```


## 7. chmod, fchmod, fchmodat
```c
/**
 * @brief changes the mode of the file specified whose pathname
 *        is given in pathname (include file permission bits, 
 *        set-user-ID, set-group-ID, and sticky bits)
 */
int chmod(const char* pathname, mode_t mode);

/**
 * @brief change the mode of the file referred to by the open file 
 *        descriptor `fd` 
 */
int fchmod(int fd, mode_t mode);

/**
 * @brief same as chmod(), but pathname can be relative path 
 *        relative to directory referred to by dirfd.
 * @param flag same as flag in faccessat()
 */
int fchmodat(int dirfd, const char* pathname, mode_t mode, int flag);
```
* `chmod`不会更改symbolic link的权限, 因为从不使用symbolic link的权限设置, 但`chmod`会更改symbolic link指向的文件的权限, 也会无视循环指向的symbolic link.
* 只有当前进程的EUID与文件所有者的UID相同, 或为root权限时, 才能修改目标文件的mode.
* 当前进程没有root权限, 且EGID不匹配文件的group id, 则无视`S_ISGID` 并返回错误
* 一些UNIX系统只允许拥有root权限的用户在文件上设置sticky bit, 且拥有特殊意义


## 8. chown, fchown, fchownat, lchown
```c
/**
 * @brief change owner and group of a file specified by `pathname`, 
 *        dereferenced if it is a symbolic link
 */
int chown(const char* pathname, uid_t owner, gid_t group);

/** 
 * @brief changes the ownership of the file referred to by the open file
 *        descriptor `fd`
 */
int fchown(int fd, uid_t owner, gid_t group);

/**
 * @brief same as chown()
 * @param flags a bit mask created by ORing of the following values:
 *        * AT_EMPTY_PATH: If `pathname` is an empty string, operate on the 
 *          file referred to by `dirfd`
 *        * AT_SYMLINK_NOFOLLOW: If `pathname` is a symbolic link, do not 
 *          dereference it.
 */
int fchownat(int dirfd, const char* pathname, uid_t owner, gid_t group, int flag);

/**
 * @brief same as chown(), but does not deference symbolic links
 */
int lchown(const char* pathname, uid_t owner, gid_t group);
```
* 只有privileged process才能更改文件的owner; 文件的owner和privileged process都更改文件所属的group
* 若`chown`的参数`owner`或`group`为-1, 则不作任何更改
* 若目标文件为可执行文件, 且当前进程为privileged process, 则目标文件的`S_ISUID`和`S_ISGID`会被清除


## 9. File Size
若文件为regular file, directory或symbolic link, stat的`st_size`表示文件占多少byte. 以下是一些特殊情况:
* 若文件为regular file, `st_size`可为0, 文件的唯一字符为EOF.
* 若文件为directory, 则`st_size`无法告知文件夹内的文件总大小, 只能通过递归不断查看每个文件的大小
* 若文件为symbolic link, `st_size`表示pathname的长度


## 10. File Truction
```c
/**
 * @brief shrink or extend the size of a file to the specified 
 *        size. If the file previously was shorter, extended part
 *        reads as null bytes. If the file previously was larger 
 *        than this size, the extra data lost.
 * @return zero is returned on success; -1 is returned on error
 *         and errno is set.
 */
int truncate(const char *pathname, off_t length);
int ftruncate(int fd, off_t length);
```


## 11. File System
File System(FS)负责数据存储和检索, 并通过device file提供对外部资源的访问(如打印机, 鼠标等). UNIX File System(UFS)受Berkley Fast File System启发, 是操作系统的核心组件, 
UFS中, 每个device类型有一个固定的**major device number**, 每个device类型下的每个device都有一个**minor device number**. 以RAM为例, 其major device number为1, device类别为block, 第一个RAM的minor device number为0, 第二个为1, 其次递归.
Kernel通过**block device switch table**和**character device switch table**与device driver沟通, 每个device类型占一项, 里面包含系统调用(如open)对应的device driver接口(如软盘driver的open). 调用device driver时, kernel需将minor device number作为参数传给driver, 保证driver使用正确的device.
UFS中, 物理磁盘被拆分为多个逻辑磁盘, 称为**partition**, 每个partition都是一个独立的FS, 因此当我们讨论FS时, 指代的是单个partition. 
讨论文件存储前, 需先了解磁盘: 磁盘的最小存储单元为**sector**(扇区, 通常为512kb). 由于磁盘读取操作是一个费时操作, 因此UNIX不会一次只读取一个sector, 而是读取多个sector, 称为**block**, 通常block包含8个sector, 也就是4KB. 但UNIX需要一种方法来跟踪每个文件对应的block, 也就是**inode**. 以下是UFS中文件存储结构图:
![Disk drive, partitions, and a file system](/images/UNIX/APUE/4-11-unix-file-system.jpg)

* Boot Block: FS的第一个block, 其中包含bootstrap程序, 负责系统启动
* Super Block:
  * inode数量, block总数, 空闲block数量, 空闲inode数量
  * 第一个block, block大小
  * cylinder group的data block数量
  * mount时长, write时长
  * 兼容性, volume信息
  * FS状态
* cylinder group: 一个disk slice(磁盘片)拆为多个cylinder group, 一个cylinder group包含一个或多个连续disk cylinder(磁盘柱面). 一个cylinder group由以下组成:
  * superblock的copy
  * inode map: 指向每个inode的位置表
  * 可用block的bitmap
  * inode列表
  * data block略表: 包含文件的具体内容
* inode: 包含一个文件的所有信息, 除了文件名(包含在文件夹内, 文件夹内的filename其实是指向inode的hard link), 每个inode占128字节.
  * 文件类型, 文件权限
  * UID, GID
  * 文件大小(byte)
  * 访问时间, 创建时间, 修改时间, 删除时间
  * Hard Link数量: 当该值为0, 文件将被删除
  * Flags

inode包含15个block pointer, 分别指向不同的data block. 前12个block为**direct block pointer**, 也就是说, 地址直接指向包含文件数据的block, 总共48KB; 若文件大于48KB, 则使用**indirect block pointer**:
* 第13个block pointer: **indirect block pointer**, 该pointer指向的block只有direct block pointer, 总共`4KB/4B*4KB = 4MB`数据.
* 第14个block pointer: **double indirect block pointer**, 该pointer指向的block只有**indirect block pointer**, 二级pointer指向含有数据的block, 总共`(4KB/4B)*(4KB/4B)*4KB = 4GB`数据.
* 第15个block pointer: **triple indirect block pointer**, 该pointer指向的block只有**double indirect block pointer**, 三级pointer指向含有数据的block, 总共`(4KB/4B)*(4KB/4B)*(4KB/4B)*4KB = 4TB`数据

![An inode with indirect and double indirect data blocks](/images/UNIX/APUE/4-11-inode-indirect-block-pointer.png)

Data block: inode指向data block, 分为以下三种:
* Plain data block: 包含文件的数据
* Symbolic-link data block: 包含路径名的symbolic link
* Directory data block: 包含一组文件名和对应的inode

![Cylinder group’s i-nodes and data blocks in more detail](/images/UNIX/APUE/4-11-inode-data-block.jpg)


## 12. link, linkat, unlink, unlinkat, remove
```c
/**
 * @brief create a new link(hard link) to an existing file
 * @param oldpath pathname referred to an existing file
 * @param newpath pathname referred to a new path. If `newpath` exists, 
 *        it will not be overwritten
 * @return 0 for success; -1 for error and errno is set
 */
int link(const char* oldpath, const char* newpath);

/**
 * @brief same as link()
 * @param oldpath if it is relative, it is interpreted relative to the
 *        directory referred to by the file descriptor `olddirfd`
 * @param flag the following values can be bitwise ORed:
 *        * AT_EMPTY_PATH: If `oldpath` is an empty string, create a 
 *          link to the file referenced by `olddirfd`
 *        * AT_SYMLINK_FOLLOW: dereferenced `oldpath` if it is a 
 *          symbolic link
 * @return 0 for success; -1 for error and errno is set.
 */
int linkat(int olddirfd, const char* oldpath, int newdirfd, 
           const char* newpath, int flag);

/**
 * @brief delete a hard link from the filesystem. If it is the last 
 *        link to a file and no process have the file open, the file 
 *        is deleted and the space is made available for reuse
 * @param pathname If `pathname` refer to a symbolic link, the link is
 *        removed; If `pathname` refer to a socket, FIFO, or device, 
 *        the link is removed but processes which opened the file still
 *        continue to use it.
 */
int unlink(const char* pathname);

/**
 * @brief same as unlink()
 * @param pathname if `pathname` is relative, then it is interpreted 
 *        relative to the directory referred to by `dirfd`
 * @param flag a bit mask that can either be specified as 0. Currently,
 *             only one flag is defined:
 *             * AT_REMOVEDIR: perform the equivalent of rmdir() on 
 *               `pathname`
 */
int unlinkat(int fd, const char* pathname, int flag);

/**
 * @brief if `pathname` is a file, same as unlink(); if `pathname` is 
 *        a directory, same as rmdir().
 */
int remove(const char*pathname);
```
* 若系统允许创建hard link, 只有root权限用户才能创建, 因为hard link可能导致循环访问. 
* 有些系统不支持对directory使用`unlink`, 需使用`rmdir`


## 13. rename, renameat
```c
/**
 * @brief rename a file, moving it between directories if required. Other 
 *        hard links to the file(created using link()) are unaffected
 * @param old: points to the pathname of file to be changed
 * @param new: points to the new pathname of the file
 */
int rename(const char* oldpath, const char* newpath);

/**
 * @brief change the name or location of a file
 */
int renameat(int olddirfd, const char *oldpath, int newdirfd, const char *newpath);
```


## 14. Symbolic Links
Symbolic link也称为**soft link**, 以下是其与hard link的不同之处:
* hard link指向inode, 删除文件, 重命名文件, 或移动文件都不会影响inode, 因此不会影响hard link
* symbolic link只包含pathname

```c
/**
 * @brief creates a symbolic link named `linkpath` which contains
 *        the string `target`
 * @param linkpath if it exists, it will not be overwritten
 * @return 0 on success, -1 on error and errno is set
 */
int symlink(const char* target, const char* linkpath);

/**
 * @brief same way as symlink(), but if `linkpath` is relative, it is
 *        intrepreted relative to the directory referred to by the file
 *        `dirfd`
 * @param dirfd if it is AT_FDCWD, and `linkpath` is relative, `linkpath`
 *        is interpreted relative to the current working directory of 
 *        the calling process
 */
int symlinkat(const char* target, int dirfd, const char* linkpath);

/**
 * @brief place the content of the symbolic link `pathname` in the buffer
 *        `buf`, which has size `bufsize`.
 */
ssize_t readlink(const char* pathname, char* buf, size_t bufsize);
/**
 * @brief same way as readlink(). If `pathname` is relative, it is 
 *        interpreted relative to the directory referred to by `dirfd`
 * @param dirfd if it is AT_FDCWD, and `pathname is relative`, `pathname`
 *        is interpreted relative to the current working directory of 
 *        the calling process
 */
ssize_t readlinkat(int dirfd, const char *pathname, char *buf, size_t bufsize);
```
* 系统解析symbolic link时, 会将symbolic link里的内容当做path, 用于搜索文件或路径. 若symbolic link包含`..`, 则该path为symbolic link所在的文件夹的相对路径.
* `readlink()`不会在`buf`中追加空字符(`\0`), 若`pathname`的内容长度超出`bufsize`, 会自动截断.


## 15. File Times
| Field | Description | Example | ls option |
| :-----: | :-----: | :-----: | :-----: |
| st_atim | last-access time of file data | read | -u |
| st_mtim | last-modification time of file data | write | default |
| st_ctim | last-change time of i-node status | chmod, chown | -c |

* `st_ctim`: 修改权限, UID, 添加或删除Hard Link等操作都会更新`st_ctim`
* `access()`和`stat()`只访问inode, 不访问文件内的数据, 因此不更新`st_atim`


## 16. futimens, utimenset and utimes
```c
struct timespec {
  time_t tv_sec;  /* seconds */
  long   tv_nsec; /* nanoseconds */
}

/**
 * @brief set file access and modification time with nanosecond precision
 * @param times access time and modification time. There are four ways of 
 *        times argument:
 *        * null: both timestamps are set to current time
 *        * array of two timespec: If either tv_nsec is set to UTIME_NOW,
 *          the corresponding timestamp is set to current time.
 *        * array of two timespec: If either tv_nsec is set to UTIME_OMIT,
 *          the corresponding timestamp is unchanged
 *        * array of two timespec: tv_nsec field has a value other than
 *          UTIME_OMIT or UTIME_NOW, the corresponding timestamp is set to
 *          the value specified by the tc_sec and tv_nsec 
 *          
 */
int futimens(int fd, const struct timespec times[2]);

/**
 * @brief same as futimens. 
 * @param flag: follow or not symbolic link
 */
int utimensat(int dirfd, const char *path, const struct timespec times[2], 
              int flag);

int utimes(const char* pathname, const struct timeval times[2]);
```


## 17. mkdir, mkdirat, rmdir
```c
/**
 * @brief create a directory named `pathname`
 * @param mode file permission bits
 * @return 0 on success, -1 on error and errno is set
 */
int mkdir(const char* pathname, mode_t mode);

/**
 * @brief same way as mkdir(). If `pathname` is relative, it it interpreted
 *        relative to the directory referred to by `dirfd`. If `pathname` 
 *        is relative and `dirfd` is AT_FDCWD, `pathname` is interpreted 
 *        relative to the current working directory of the calling process
 */
int mkdirat(int dirfd, const char* pathname, mode_t mode);
```
新建文件夹的UID为当前进程的EUID. 若`mode`设置了`set-group-ID`, 则新建文件夹的GID为父文件夹的owner, 否则为当前进程的EGID.


## 18. Reading Directories
```c
/**
 * @brief open a directory with name pathname.
 * @return a pointer to the directory stream
 */
DIR* opendir(const char* pathname);
DIR* fdopendir(int fd);

/**
 * @brief read a directory
 * @return a pointer to a dirent structure representing the next
 *         directory entry 
 */
struct dirent *readdir(DIR *dp);

/**
 * @brief reset the position of the directory stream dp to the
 *        beginning of the directory
 */
void rewinddir(DIR *dp);

/**
 * @brief closes the directory stream associated with dp
 * @return return 0 on success, -1 on error and errno is set
 */
int closedir(DIR *dp);

/**
 * @brief return the current location associated with the 
 *        directory stream dp
 * @return the current location in the directory stream on 
 *         success, -1 on error and errno is set
 */
long telldir(DIR *dp);

/**
 * @brief set the position of the next readdir() call
 */
void seekdir(DIR *dp, long loc);

struct dirent {
  ino_t d_ino;             /* inode number */
  off_t d_off;             /* current location in the directory */
  unsigned short d_reclen; /* length of this record */
  unsigned char  d_type;   /* file type */
  char d_name[256];        /* null terminated filename */
};
```


## 19. chdir, fchdir, getcwd
每个进程都有一个当前操作的文件夹. 可通过以下函数来查看或更改当前进程所在的文件夹.
```c
/**
 * @brief change current working directory of the calling process to the 
 *        directory specified in `path`
 * @return 0 on success, -1 on error and errno is set
 */
int chdir(const char* path);
int fchdir(int fd);

/**
 * @brief copy an absolute pathname of the current working directory to 
 *        the array pointed to by `buf`.
 *        If the length of the pathname of current working directory, 
 *        including the terminating null byte, exceeds size bytes, NULL is 
 *        returned.
 * @return a pointer to a string containing the pathname of current
 *         working directory on success; NULL on error and errno is set.
 */
char* getcwd(char* buf, size_t size);
```
