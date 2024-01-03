---
title: Virtual File System
category:
  - UNIX
  - Linux
tags:
  - UNIX
abbrlink: '4850'
date: 2023-02-20 10:30:52
keywords:
description:
---

## 1. Everything is a file 
Unix及其衍生的操作系统贯彻一条理念: 万物皆文件. 该理念用于处理资源的输入和输出, 如文档, 硬盘, modem, 键盘, 打印机, 进程间通信; 该概念的优点在于, 用户可使用相同的API操作不同类型的资源. 但也存在一些例外, 如shared memory(共享内存), semaphores(信息量), symbolic link(符号链接), process(进程), 上述资源并不作为文件形式呈现.


## 2. File descriptor
打开一个文件时, UNIX会为其创建对应的file descriptor(简称fd). Fd作为文件的唯一标识符, 进程对文件的一切操作都需要fd作为接口, 因此也称为**Everything is a file descriptor**. 
UNIX会为每个进程分配一个**file descriptor table**, 该table包含进程打开的所有文件, 每个entry包含以下信息:
* Controlling flags: 进程调用`open()`时附加的file creation flag和file status flag, 如`O_APPEND`, `O_ASYNC`, `O_CLOEXEC`, `O_CREAT`
* 指向file table一条entry的指针

其中, **file table**是系统层面的一个数据结构, 每一条entry代表一个打开的文件:
* File offset
* File status flags: 控制进程操作文件的行为, 如文件为只读或只写, 向文件追加或覆盖数据
* File access mode: 文件权限
* File position: 进程读写文件的位置
* 指向inode的指针

**inode table**是系统层面的一个数据结构, 包含以下信息:
* File type(普通文件, FIFO, socket等)
* File permission
* File properties(文件大小, 时间戳等)

![Mount Namespaces](/images/Linux/virtual-filesystem/1-1.png)

需要注意的是, file descriptor table中的多个entry可指向file table的同一entry(调用`dup()`), file table中的多个entry可指向inode table中的同一entry(同一文件被打开多次). 
Linux中, 可通过`/proc/PID/fd/`查看一个进程拥有的所有file descriptor, 其中`/proc/PID/fd/0`为stdin, `/proc/PID/fd/1`为stdout, `/proc/PID/fd/2`为stderr.
Kernel可使用file descriptor以及上述table跟踪进程打开的文件, 并记录文件的相关信息, 如inode number, file mode, file position等.


## 3. File System
File system作为操作系统中重要的一环, 用于管理数据的分段及其命名. 若没有file system, 存储设备中的数据只是一团二进制, 无法分辨一段数据的开始和结束位置. 将数据分为多段, 并为每段数据分配名字, 便诞生出**file**的概念. File system会以不同标准分为不同实现:
* 不同操作系统: `FAT`(DOS和Windows), `ext`(Linux), `UFS`(Solaris和BSD)
* 内置checksum和冗余备份: Btrfs
* 专门为固态设备优化: APFS, exFAT
* 分布式file system: Amazon S3
* peer-to-peer file system: Cleversafe
* 加密文件: eCryptfs

除了保存在存储设备上的文件, 还有一些文件只存在于内存中, 这类文件的file system称为**pseudo file system**(伪文件系统), 如`procfs`, 该file system以文件的形式展示系统内的进程信息, 用户可通过读取对应文件来获取进程信息.
UNIX支持在一个系统内使用多个file system, 也因此引入一个问题: 如何让用户随时访问不同file system中的文件. UNIX的方案为**virtual file system**(简称为VFS), VFS将不同file system中的文件放入一个统一的hierarchy, 也就是说, 系统中只有一个root directory, 且所有file system的文件都在其中. 虽然UNIX会为每个存储设备一个名称, 但访问设备中的文件并不需要设备名, 只需知道文件在directory tree中的位置.

 
## 4. Virtual File System
VFS作为file system之上的一层抽象层, 为用户提供了一套统一的访问不同类型file system的方式. VFS制定了一套kernel与file system的接口, 因此, 只要新的file system符合接口标准, 就可加入kernel.

![Mount Namespaces](/images/Linux/virtual-filesystem/layered-arch-of-VFS.gif)

### 4.1 Directory Entry Cache
对于`open()`, `stat()`, `chmod()`等系统调用, **directory entry cache**(简称为`dentry cache`)可帮助VFS通过`pathname`参数快速找到对应文件, 因此, dentry cache是一种连接pathname和inode的机制. 若VFS访问文件时, 该文件未被缓存到dentry cache中, 则VFS会为其分配`dentry object`(简称为`dentry`). 假设查询路径为`/home/user/name`, VFS会生成四个`dentry`: `/`, `home`, `name`和`user`.
```c
struct dentry {
  atomic_t                 d_count;   /* 当前dentry的使用次数  */
  struct inode             *d_inode;  /* 指向inode */
  struct qstr              d_name;    /* 文件名 */
  struct dentry            *d_parent; /* 指向parent dentry */
  struct list_head         d_child;   /* 指向child dentry链表的头部 */
  struct list_head         d_subdirs; /* 指向subdirectories链表的头部 */
  struct dentry_operations *d_op;     /* dentry operations table */
  struct super_block       *d_sb;     /* superblock of file */
  struct list_head         d_lru;     /* 指向LRU链表的头部, 方便将当前dentry移至LRU链表头部 */
  struct hlist_node        d_hash;    /* 链接到dentry cache的hash链表 */
  // ... 
};
```
Dentry通过`d_parent`和`d_subdirs`实现了文件系统的层级结构, 整个系统存在一个root dentry, 且root dentry不存在`d_parent`; 其他dentry则必须拥有一个`d_parent`.
一个dentry存在三种状态:
* used: `d_inode`指向一个inode, 且`d_count > 0`, 表示该dentry正在被VFS使用
* unused: `d_inode`指向一个inode, 且`d_count = 0`, 表示该dentry未被VFS使用, 但未来可能使用
* negative: `d_inode`为NULL, 因为文件被删除或路径不正确, 保留该dentry只是为了以后快速查找

除了dentry object, dentry cache还包含以下部分:
* LRU链表: 包含unused和negative状态dentry的双向链表, 该链表使用insertion sort(插入排序算法)插入dentry, 因此dentry越靠近头部, 说明该dentry最近被使用. 当kernel需要回收内存时, 根据局部性原理, 会从链表尾部移除dentry.
* `struct list_head dentry_hashtable[D_HASHSIZE];`: 数组坐标表示dentry的hash值, 每个数组元素是一个dentry组成的链表, 且链表内dentry的hash值相同. 该hashtable可让VFS根据pathname快速找到对应的dentry.

出于查询性能考虑, dentry只保存在内存中, 不会存入磁盘.

### 4.2 Inode
inode提供了kernel所需的所有关于file的信息. 对于block device filesystem, inode保存在磁盘中, 需要时加载到内存, 修改时写回磁盘; 对于pseudo filesystem, inode保存在内存中. 多个dentry可指向同一inode.
```c
struct inode {
  struct hlist_node       i_hash;              /* hash list */
  struct list_head        i_list;              /* list of inodes */
  struct list_head        i_dentry;            /* list of dentries */
  unsigned long           i_ino;               /* inode number */
  atomic_t                i_count;             /* reference counter */
  umode_t                 i_mode;              /* access permissions */
  unsigned int            i_nlink;             /* number of hard links */
  uid_t                   i_uid;               /* user id of owner */
  gid_t                   i_gid;               /* group id of owner */
  kdev_t                  i_rdev;              /* real device node */
  loff_t                  i_size;              /* file size in bytes */
  struct timespec         i_atime;             /* last access time */
  struct timespec         i_mtime;             /* last modify time */
  struct timespec         i_ctime;             /* last change time */
  unsigned int            i_blkbits;           /* block size in bits */
  unsigned long           i_blksize;           /* block size in bytes */
  unsigned long           i_version;           /* version number */
  unsigned long           i_blocks;            /* file size in blocks */
  unsigned short          i_bytes;             /* bytes consumed */
  spinlock_t              i_lock;              /* spinlock */
  struct rw_semaphore     i_alloc_sem;         /* nests inside of i_sem */
  struct semaphore        i_sem;               /* inode semaphore */
  struct inode_operations *i_op;               /* inode ops table */
  struct super_block      *i_sb;               /* associated superblock */
  struct file_lock        *i_flock;            /* file lock list */
  struct address_space    *i_mapping;          /* associated mapping */
  struct address_space    i_data;              /* mapping for device */
  struct dquot            *i_dquot[MAXQUOTAS]; /* disk quotas for inode */
  unsigned long           i_state;             /* state flags */
  unsigned long           dirtied_when;        /* first dirtying time */
  unsigned int            i_flags;             /* filesystem flags */
  atomic_t                i_writecount;        /* count of writers */
  // ...
};
```

### 4.2 Inode Operations
```c
struct inode_operations {
  /* open(), creat(): create a new inode associated with the dentry
     `dentry` in a parent inode directory `dir` with given mode */
  int create(struct inode *dir, struct dentry *dentry, int mode);

  /* search an inode in a parent inode directory `dir`. The name to
     look for is in the dentry `dentry`. If target inode does not
     exist, a NULL inode should be inserted into the dentry(called
     a negative dentry) */
  struct dentry* lookup(struct inode *dir, struct dentry *dentry);

  /* link(): create a hard link of the file `old` in the directory
     `dir` with the new filename `dentry` */
  int link(struct dentry *old_dentry, struct inode *dir, struct dentry *dentry);
  /* unlink(): remove the inode specified by the dentry `dentry`
     from the directory `dir` */
  int unlink(struct inode *dir, struct dentry *dentry);
  /* symlink(): create a symbolic link named `symname` of the file
     `dentry` in the directory `dir` */
  int symlink(struct inode *dir, struct dentry *dentry, const char *symname);

  /* mkdir(): create a new directory with the given initial mode */
  int mkdir(struct inode *dir, struct dentry *dentry, int mode);
  /* rmdir(): remove the directory referenced by `dentry` from the
     directory `dir` */
  int rmdir(struct inode *dir, struct dentry *dentry);

  /* mknod(): create a special file (device, pipe or socket). The
     file is referenced by the device ID `rdev` and dentry `dentry` 
     in the directory `dir`. Initial permissions are given via `mode`. */
  int mknod(struct inode *dir, struct dentry *dentry, int mode, dev_t rdev);

  /* rename(): move the file specified by `old_dentry` from `old_dir`
     directory to `new_dir` directory. Filename specified by `new_dentry` */
  int rename(struct inode *old_dir, struct dentry *old_dentry, 
             struct inode *new_dir, struct dentry *new_dentry);
  
  /* copy at most `buflen` bytes of the full path associated with the
     symbolic link specified by `dentry` into the specified buffer */
  int readlink(struct dentry *dentry, char *buffer, int buflen);

  /* translate a symbolic link to the inode to which it points.
     The link pointed at by `dentry` is translated and the result
     is stored in the nameidata structure pointed at by `nd` */
  int follow_link(struct dentry *dentry, struct nameidata *nd);
  /* clean up after a call to follow_link() */
  int put_link(struct dentry *dentry, struct nameidata *nd);

  /* modify the size of the given file referenced by inode `inode`.
     The new size of file should be set in `i_size` field */
  void truncate(struct inode *inode);

  /* check whether the specified access mode `mask` is allowed for
     the file referenced by inode `inode` */
  int permission(struct inode *inode, int mask);

  int setattr(struct dentry *dentry, struct iattr *attr);
  int getattr(struct vfsmount *mnt, struct dentry *dentry, struct kstat *stat);
  int setxattr(struct dentry *dentry, const char *name, const void *value, 
               size_t size, int flags);
  ssize_t getxattr(struct dentry *dentry, const char *name,
                   void *value, size_t size);
  ssize_t listxattr(struct dentry *dentry, char *list, size_t size);
  int removexattr(struct dentry *dentry, const char *name)
};
```

### 4.3 Superblock
Superblock表示一个挂载的file system, 其中包含file system所需的metadata. 若file system的superblock损坏, 则VFS无法挂载该file system, 因此file system会有多个superblock备份.
```c
struct super_block {
  struct list_head        s_list;            /* list of all superblocks */
  dev_t                   s_dev;             /* identifier */
  unsigned long           s_blocksize;       /* block size in bytes */
  unsigned long           s_old_blocksize;   /* old block size in bytes */
  unsigned char           s_blocksize_bits;  /* block size in bits */
  unsigned char           s_dirt;            /* dirty flag */
  unsigned long long      s_maxbytes;        /* max file size */
  struct file_system_type s_type;            /* filesystem type */
  struct super_operations s_op;              /* superblock methods */
  struct dquot_operations *dq_op;            /* quota methods */
  struct quotactl_ops     *s_qcop;           /* quota control methods */
  struct export_operations *s_export_op;     /* export methods */
  unsigned long            s_flags;          /* mount flags */
  unsigned long            s_magic;          /* filesystem's magic number */
  struct dentry            *s_root;          /* directory mount point */
  struct rw_semaphore      s_umount;         /* unmount semaphore */
  struct semaphore         s_lock;           /* superblock semaphore */
  int                      s_count;          /* superblock ref count */
  int                      s_syncing;        /* filesystem syncing flag */
  int                      s_need_sync_fs;   /* not-yet-synced flag */
  atomic_t                 s_active;         /* active reference count */
  void                     *s_security;      /* security module */
  struct list_head         s_dirty;          /* list of dirty inodes */
  struct list_head         s_io;             /* list of writebacks */
  struct hlist_head        s_anon;           /* anonymous dentries */
  struct list_head         s_files;          /* list of assigned files */
  struct block_device      *s_bdev;          /* associated block device */
  struct list_head         s_instances;      /* instances of this fs */
  struct quota_info        s_dquot;          /* quota-specific options */
  char                     s_id[32];         /* text name */
  void                     *s_fs_info;       /* filesystem-specific info */
  struct semaphore         s_vfs_rename_sem; /* rename semaphore */
};
```
superblock中最重要的成员为`s_op`, 其中包含file syste对inode的所有操作.
```c
/* create and initialize a new inode object under
   the given superblock */
struct inode* alloc_inode(struct super_block *sb)

/* deallocates the given inode pointed to by `inode` */
void destroy_inode(struct inode *inode)

/* reads the inode specified by inode->i_ino from disk
   and fills in the rest of the inode structure */
void read_inode(struct inode *inode)

/* invoked by VFS when an inode is dirtied(modified) */
void dirty_inode(struct inode *inode)

/* write the given inode to disk, `wait` parameter specifies
   whether the operation should be synchronous */
void write_inode(struct inode *inode, int wait)

/* release the given inode */
void put_inode(struct inode *inode)

/* invoked by VFS when the last reference to the inode is dropped */
void drop_inode(struct inode *inode)

/* delete the given inode from the disk */
void delete_inode(struct inode *inode)

/* invoked by VFS when free the superblock(unmount) */
void put_super(struct super_block *sb)

/* update the on-disk superblock with the specified superblock */
void write_super(struct super_block *sb)

/* synchronize filesystem metadata with the on-disk filesystem */
int sync_fs(struct super_block *sb, int wait)

/* obtain filesystem statistic */
int statfs(struct super_block *sb, struct statfs *statfs)

/* invoked by VFS when the filesystem is remounted with
   new mount options */
int remount_fs(struct super_block *sb, int *flags, char *data)

/* invoked by VFS to release the inode and clear any pages
   containing related data */
void clear_inode(struct inode *);

/* invoked by VFS to interrupt a mount operation */
void umount_begin(struct super_block *sb)
```

