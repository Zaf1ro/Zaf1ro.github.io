---
title: Interprocess Communication
category:
  - UNIX
  - APUE
tags:
  - UNIX
abbrlink: 4cb2
date: 2019-10-07 09:13:30
keywords:
description:
---

## 1. Pipes
Pipes(管道)作为UNIX中时间最长的IPC工具, 有两个缺陷:
1. Pipes为half-duplex(半双工, 数据只能向一个方便传递). 虽然已经有系统支持full-duplex pipes, 但为了系统兼容性, 还是应将pipes默认为half-duplex
2. Pipes的使用有一个前提: 两个进程有共同的祖先, 一般用于parent process和child process之间的通信
3. 被创建的pipe没有名字
4. Pipe的buffer空间有限

尽管pipes有诸多缺陷, 但仍是最被常用的IPC工具. 调用pipe()可创建一个pipe:
```c
#include <unistd.h>

/**
 * @brief create a pipe that can be used for IPC
 * @param fd: return two file descriptors referring to the 
 *        ends of the pipe
 *        1. fd[0]: the read end of the pipe
 *        2. fd[1]: the write end of the pipe
 * @return 0 on success; -1 on error and errno is set
 */
int pipe(int fd[2]);

/**
 * @brief same as pipe()
 * @param flags: shall be one of the following values:
 *        1. O_CLOEXEC: Set the close-on-exec (FD_CLOEXEC) 
 *           flag on the two new file descriptors
 *        2. O_DIRECT: Each write to the pipe is dealt with 
 *           as a separate packet, and read from the pipe 
 *           will read one packet at a time
 *        3. O_NONBLOCK: Set the O_NONBLOCK file status flag 
 *           on the two file descriptions
 */
int pipe2(int fd[2], int flags);
```
但单个进程中的pipe没有意义, 通常进程会先调用pipe(), 然后调用fork(), 结果如下:
![Half-duplex pipe after a fork](/images/UNIX/ipc-1.png)

这时parent process和child process都可以向pipe读取或写入数据. 若想要让child process读取来自parent process的数据, 则关闭parent process中的fd[0]和child process中的fd[1]:
![Pipe from parent to child](/images/UNIX/ipc-2.png)

当用户关闭pipe的一端时:
1. 当write端被关闭后, read端尝试读取会返回0
2. 当read端被关闭后, write端尝试写入会产生SIGPIPE signal; 若无视该信号, 则返回-1并将errno设为EPIPE

Kernel中的PIPE_BUF表示pipe的buffer size, POSIX.1规定当进程写入的数据小于PIPE_BUF时, 写入操作必须是原子的; 但若写入数据大于PIPE_BUF, 操作结果有以下几种结果:
1. O_NONBLOCK disabled: 以非原子地形式与其他进程交错写入; write()会被阻塞, 直到写入全部数据
2. O_NONBLOCK enabled: 若pipe buffer已满, 则write()直接返回-1并将errno设置为EAGAIN; 否则写入部分数据, write()返回还没写入的字节数



## 2. popen and pclose Functions
```c
#include <stdio.h>

/**
 * @brief open a process by creating a pipe, forking, and 
 *        executing the cmdstring
 * @param cmdstring: a pointer to a null-terminated string 
 *        containing a shell command line. This command is 
 *        passed to /bin/sh using the -c flag; interpretation
 * @param type: a pointer to a null-terminated string which 
 *        contains either 'r' for reading or 'w' for writing
 * @return a standard I/O stream on success; NULL on error
 */
FILE *popen(const char *cmdstring, const char *type);

/**
 * @brief close the standard I/O stream and wait for the 
 *        command to terminate
 * @return the exit status of the command on success; -1 on 
 *         error
 */
int pclose(FILE *fp);
```
以下是调用popen()时type为"r"和"w"的结果:
![Result of popen(cmdstring, "r") and  popen(cmdstring, "w")](/images/UNIX/ipc-3.png)

注意: popen()不应用于设置了set-user-ID或set-group-ID的程序中. set-ID会提高用户权限, 可能导致shell执行的命令具有破坏性



## 3. Coprocesses
Filter作为一种程序, 用于处理或产生stream. UNIX中的filter从standard input中获取数据, 经过处理后将数据写入standard output, 常见的UNIX filter: awk, cat, comm, cut, expand, compress, fold, grep, head, less, more, nl, perl, paste, pr, sed, sh, sort, split, strings, tail, tac, tee, tr, uniq, wc, zcat. 可用Shell的pipe operator ("|")来连接一个或多个filter, Filter的输入和输出也可以重定向为某个文件或其他设备.
Coprocess借鉴filter的思路: 当某个进程既产生filter的输入, 又从filter获取数据时, 该filter就成为这个进程的coprocess. 通常情况下coprocess会创建两个pipe, 一个用于读取其他进程的数据, 另一个用于输出处理过的数据. 相对于popen的单向pipe, coprocess提供了双向数据流.



## 4. FIFOs
FIFO也被称为named pipes, 因为FIFO以文件形式存放在文件系统中. 即使两个进程不存在共同祖先, 仍可以使用FIFO进行通信.
```c
#include <sys/stat.h>

/**
 * @brief make a FIFO file with name pathname
 */
int mkfifo(const char *path, mode_t mode);

/**
 * @brief same as mkfifo()
 * @param path, fd: there are three cases
 *        1. If the path specifies an absolute pathname, then
 *           the fd is ignored and mkfifo() behaves like 
 *           mkfifo()
 *        2. If the path specifies a relative pathname and 
 *           the fd is valid file descriptor for an directory,
 *           the pathname is relative to this directory
 *        3. If the path specifies a relative pathname and 
 *           the fd has value AT_FDCWD, the pathname is 
 *           starting in the current directory
 */
int mkfifoat(int fd, const char *path, mode_t mode);
```
FIFO的使用与pipe并无太大区别, 但使用前需调用open()打开指定FIFO文件. 打开FIFO文件时, O_NONBLOCK flag对open()有以下影响:
* O_NONBLOCK disabled: 对于只读block, open()会等待其他进程写入数据; 对于只写block, open()会等待其他进程读取
* O_NONBLOCK enabled: 对于只读block, 若没有进程读取数据, open()会立即返回; 对于只写block, 若没有进程写入数据吗, open()会返回-1并设置errno为ENXIO

如同pipe, 当向没有reader的FIFO写入数据时会产生SIGPIPE; 当writer关闭FIFO时, reader会得到EOF. FIFO主要有两种用途:
1. Shell command使用FIFOs在shell pipeline之间传递数据
2. 用于client和server传递数据



## 5. XSI IPC
XSI IPC定义了三个IPC structure: message queue, semaphones, shared memory. 这三种IPC structure虽然存在一定的差异, 但也有很多相似之处.

### 5.1 Identifiers and Keys
三种IPC结构体在kernel中都用一个非负整数表示, 作为其identifier. 每创建一个IPC structure, 分配的IPC identifer都加一; 达到最大值后再从0循环使用.
但IPC identifier只在IPC structure内部使用, 进程想要调用IPC structure需要使用IPC structure对应的key. 当创建IPC structure, 进程必须为其指定一个key. Key的类型为key_t, 通常为long integer, kernel会将key转换为IPC identifier. 以下是client和server使用同一个IPC structure的方法:
1. Server创建IPC structure时指定key为IPC_PRIVATE, 获得IPC identifier后将其保存在某个文件中方便client获取. IPC_PRIVATE保证server创建的IPC structure是全新的, 而不是绑定在其他IPC structure上; 缺点是需要I/O操作将IPC identifier写入文件, 并让client读取该文件获取IPC identifier. IPC_PRIVATE通常用于parent-child relationship: parent process创建IPC structure后调用fork(), 其child process由于继承IPC identifier, 因此也可以使用该IPC structure且不需要I/O操作
2. Server和client事先准备一个key, sever使用该key创建IPC structure. 问题在于, key可能被其他IPC structure使用并在创建时返回错误, 这时server必须删除现有IPC structure并再次尝试创建新的IPC structure
3. Server和client可事先准备一个pathname和project ID(character value betweeen 0 and 255)来调用ftok()获取相应的key
  ```c
  #include <sys/ipc.h>

  /**
   * @brief use the identity of the file named by path and
   *        the least 8 bits of id to generate a key_t type 
   *        key. When two processes use the same path and id,
   *        they shall get the same value of key
   * @return the generated key_t value on success; -1 on 
   *         error and errno is set
   */
  key_t ftok(const char *path, int id);
  ```

三种不同的IPC structure(message queue, semaphore, shared memeory)都有对应的创建IPC structure的方法: msgget(), semget(), shmget(). 这三个函数都需要key和flag参数, 以下两种情况会创建一个新的IPC structure:
1. key为IPC_PRIVATE
2. key没有与现有的IPC structure关联, 且flag设置了IPC_CREAT

若想要使用已被创建的IPC structure, 则需要指定一个已经关联的key, 且不能在flag中设置IPC_CREAT. 

### 5.2 Permission Structure
每个IPC structure都有一个关联的ipc_perm structure. 该structure定义了权限和owner ID:
```c
struct ipc_perm {
  uid_t uid;   /* owner’s effective user ID */
  gid_t gid;   /* owner’s effective group ID */
  uid_t cuid;  /* creator’s effective user ID */
  gid_t cgid;  /* creator’s effective group ID */
  mode_t mode; /* access modes */
  /* ... */
};
```
ipc_perm structure中的变量都可以通过IPC structure对应的msgctl(), semctl()或shmctl()修改. mode的表示如下:

| Permission | Bit | 
| :-----: | :-----: |
| user-read | 0400 |
| user-write(alter) | 0200 |
| group-read | 0040 |
| group-write(alter) | 0020 |
| other-read | 0004 |
| other-write(alter) | 0002 |

### 5.3 Configuration Limits
每个IPC structure都有其limit. 以下是各系统查看IPC-related limits的command:
1. Linux: **ipcs -l**
2. FreeBSD and Mac OS X: **ipcs -T**
3. Solaris: **sysdef -i**

### 5.4 Advantages and Disadvantages
IPC structure的生存周期与系统生存周期相同. 以message queue为例, 进程的终止并不会让message queue被删除, message queue中的内容也会一直保留, 直到其他进程调用msgrcv(), msgctl(), ipcrm()或系统重启. 相比之下, pipe会在最后一个进程退出时会被自动删除; FIFO虽然不会被自动删除, 但FIFO中的数据会在进程退出时被删除.
IPC structure无法被file system获知, 因为IPC structure没有提供file descriptor. XSI IPC通过提供新的system calls(msgget, semop, shmat等)使得进程可以操作IPC structure; 但这也导致IPC无法使用很多I/O functions(例如: select, poll).
IPC structure也提供了很多pipe和FIFO不具备的特性:

| IPC type | Connectionless? | Reliable? | Flow control? | Record? | Message types or priorities | 
| :-----: | :-----: | :-----: | :-----: | :-----: | :-----: |
| message queues | no | yes | yes | yes | yes |
| STREAMS | no | yes | yes | yes | yes |
| UNIX domain stream socket | no | yes | yes | no | no |
| UNIX domain datagram socket | yes | yes | no | yes | no |
| FIFOs | no | yes | yes | no | no |



## 6. Message Queues
Message queue是kernel中的linked list, 并用identifier(也称作queue ID)标示. 进程调用msgget()创建一个新的message queue, 可调用msgsnd()将新信息加入到queue尾部; 调用msgrcv()从queue中取出信息. 每个queue都有一个msqid_ds structure关联:
```c
struct msqid_ds {
  struct ipc_perm msg_perm; /* see 5.2 */
  msgqnum_t msg_qnum;       /* number of messages on queue */
  msglen_t msg_qbytes;      /* max number of bytes on queue */
  pid_t msg_lspid;          /* pid of last msgsnd() */
  pid_t msg_lrpid;          /* pid of last msgrcv() */
  time_t msg_stime;         /* last-msgsnd() time */
  time_t msg_rtime;         /* last-msgrcv() time */
  time_t msg_ctime;         /* last-change time */
  /* ... */
};
```
以下是message queue常用函数:
```c
#include <sys/msg.h>

/**
 * @brief open an existing queue or create a new queue. If a 
 *        new message queue is created, then its msqid_ds 
 *        structure is initialized as follows:
 *        1. msg_perm.cuid, msg_perm.uid are set to the 
 *           effective user ID of the calling process.
 *        2. msg_perm.cgid, msg_perm.gid are set to the 
 *           effective group ID of the calling process.
 *        3. msg_qnum, msg_lspid, msg_lrpid, msg_stime, and 
 *           msg_rtime are set to 0.
 *        4. msg_perm.mode is set to the flag.
 *        5. msg_ctime is set to the current time.
 *        6. msg_qbytes is set to the system limit MSGMNB
 * @param key: shall be the following values:
 *        1. IPC_CREAT: create the queue if it doesn't exist 
 *           in kernel
 *        2. IPC_EXCL: fail when IPC_CREAT is set and queue 
 *           already exists
 */
int msgget(key_t key, int flag);

/**
 * @brief perform various operations on a message queue
 * @param cmd: shall be the following values:
 *        1. IPC_STAT: Fetch the msqid_ds structure for this 
 *           queue
 *        2. IPC_SET: Copy msg_perm.uid, msg_perm.gid, 
 *           msg_perm.mode, and msg_qbytes pointed to by buf 
 *           to this queue
 *        3. IPC_RMID: Remove the message queue from kernel
 */
int msgctl(int msqid, int cmd, struct msqid_ds *buf);

/**
 * @brief send a message to the queue associated with the 
 *        message queue identifier specified by msqid
 * @param ptr: points to a user-defined buffer that contains 
 *        1. a field of type long specifying the type of the 
 *           message
 *        2. a data portion that holds the data bytes of the 
 *           message
 *           struct mymsg {
 *             long   mtype;
 *             char   mtext[1];
 *           }
 * @param bytes: the length of mtext
 * @param flag: if IPC_NOWAIT is specified and message queue 
 *        is full, msgsnd() shall return immediately with an 
 *        error of EAFAIN. Or it shall be blocked until 
 *        there is room for message.
 * @return 0 on success; -1 on failure and errno is set
 */
int msgsnd(int msqid, const void *ptr, size_t nbytes, int flag);

/**
 * @brief read a message from the queue associated with 
 *        identifier specified by msqid and store it in the 
 *        buffer pointed to by ptr
 * @param nbytes: the size in bytes of mtext
 * @param type: specify the type of message as follows:
 *        1. 0: fetch the first message on the queue
 *        2. > 0: fetch the first message of 'type'
 *        3. < 0: fetch the first message of the lowest type 
 *           that less or equal to the absolute value of `type`
 */
ssize_t msgrcv(int msqid, void *ptr, size_t nbytes, 
               long type, int flag);
```



## 7. Semaphores
Semaphore作为一个counter用于控制多个进程访问一个共享资源, 争夺资源的过程如下:
1. 获取semaphore
2. semaphore > 0: 说明进程可以获取资源, 并将semaphore减一
3. semaphore = 0: 说明当前没有资源, 进程进入休眠并等待被唤醒

由于会有多个进程同时操作semaphore, 必须保证semaphore的操作为atomic operation. 最常用的semaphore为binary semaphore(只拥有一个资源, 初始值为1). 但XSI semaphore其包含一些不必要的特性:
1. Semaphore并不简单地只是一个非负整数, 而是一个或多个semaphore value的集合. 当创建XSI semaphore时, 必须说明集合中有几个semaphore value.
2. 创建semaphore和初始化semaphore分别由两个函数完成: semget()和semctl(). 这导致进程无法原子地创建并初始化semaphore
3. 由于XSI IPC都没有自我销毁功能, 必须由进程主动释放

Semaphore在kernel中以semid_ds结构体的形式存在:
```c
struct semid_ds {
  struct ipc_perm sem_perm; /* see 5.2 */
  unsigned short sem_nsems; /* number of semaphores */
  time_t sem_otime;         /* last semop time */
  time_t sem_ctime;         /* last change time */
  struct sem *sem_base;     /* ptr to first semaphore */
  struct wait_queue *eventn;
  struct wait_queue *eventz;
  struct sem_undo  *undo;   /* undo requests on this array */  
};

/* One semaphore structure for each semaphore in the system. */
struct sem {
  ushort  semval;  /* semaphore value, always >= 0 */
  short   sempid;  /* pid of last operation */
  ushort  semncnt; /* num procs awaiting increase in semval */
  ushort  semzcnt; /* num procs awaiting semval = 0 */
};
```
以下是XSI semaphore的常用函数:
```c
#include <sys/sem.h>

/** 
 * @brief return the semaphore identifier associated with key.
 *        When a new set is created, the semid_ds is 
 *        initialized:
 *        1. ipc_perm is initialized, mode is set to flag
 *        2. sem_otime is set to 0
 *        3. sem_ctime is set to the current time
 *        4. sem_nsems is set to nsems
 * @param key: if key is one of the following value, a new 
 *        semaphore shall be created:
 *        1. key is equal to IPC_PRIVATE
 *        2. key is not assiociated with any existing 
 *           semaphore identifier
 * @param nsems: if reference an existing set, nsems can be 0
 */
int semget(key_t key, int nsems, int flag);

union semun {
  int val; /* for SETVAL */
  struct semid_ds *buf; /* for IPC_STAT and IPC_SET */
  unsigned short *array; /* for GETALL and SETALL */
};

/**
 * @brief provide semaphore control operations as specified 
 *        by cmd. The fourth argument is optional. If 
 *        required, it is of type 'union semun'
 * @param semnum: no. of semaphore value, [0, nsems-1]
 * @param cmd: shall be one of the following values:
 *        1. GETVAL: return the value of semval
 *        2. SETVAL: set the value of semval to arg.val
 *        3. GETPID: return the value of sempid
 *        4. GETNCNT: return the value of semncnt
 *        5. GETZCNT: return the value of semzcnt
 *        6. GETALL: return the value of semval for each 
 *           semaphore in the semaphore set and place into 
 *           the array pointed to by arg.array
 *        7. SETALL: set the value of semval for each 
 *           semaphore in the semaphore set according to the 
 *           array pointed to by arg array
 */
int semctl(int semid, int semnum, int cmd, ... /* union semun arg */ );

struct sembuf {
  unsigned short sem_num; /* no. in set [0, nsems-1] */
  short sem_op; /* operation (negative, 0, or positive) */
  short sem_flg; /* IPC_NOWAIT, SEM_UNDO */
};

/**
 * @brief perform an array of operations on a semaphore set
 * @param nops: the length of semoparray
 */
int semop(int semid, struct sembuf semoparray[], size_t nops);
```



## 8. Shared Memory
Shared memory允许多个进程使用同一块内存. Kernel中会给shared memory维持一个structure:
```c
struct shmid_ds {
  struct ipc_perm shm_perm; /* see 5.2 */
  size_t shm_segsz;         /* size of segment in bytes */
  pid_t shm_lpid;           /* pid of last shmop() */
  pid_t shm_cpid;           /* pid of creator */
  shmatt_t shm_nattch;      /* number of current attaches */
  time_t shm_atime;         /* last-attach time */
  time_t shm_dtime;         /* last-detach time */
  time_t shm_ctime;         /* last-change time */
  /* ... */
};
```
以下是shared memory的常用函数:
```c
#include <sys/shm.h>

/**
 * @brief obtain a shared memory identifier. When a new 
 *        segment is created, the shmid_ds structure are 
 *        initialized:
 *        1. The ipc_perm structure is initialized
 *        2. shm_lpid, shm_nattch, shm_atime, shm_dtime are 
 *           set to 0
 *        3. shm_ctime is set to the current time
 *        4. shm_segsz is set to the size requested
 * @param key: same as key in semget()
 * @param size: the size of shared memory segment. If 
 *        reference an existing segment, size can be 0
 */
int shmget(key_t key, size_t size, int flag);

/**
 * @brief operate shared memory control operations
 * @param cmd: shall be one of the following commands:
 *        1. IPC_STAT: fetch and store shmid_ds structure in 
 *           the structure pointed to by buf
 *        2. IPC_SET: set shm_perm.uid, shm_perm.gid, and 
 *           shm_perm.mode from the structure pointed to by buf 
 *        3. IPC_RMID: Remove the shared memory segment set 
 *           from the system
 */
int shmctl(int shmid, int cmd, struct shmid_ds *buf);

/**
 * @brief attach the shared memory segment associated with 
 *        shmid to the address space of the calling process
 * @param addr: the segment is attached at the address 
 *        specified by one of the following criteria:
 *        1. addr = 0: the segment is attached at the first 
 *           available address selected by the kernel
 *        2. addr != 0 and SHM_RND is not specified: the 
 *           segment is attached at the address given by addr
 *        3. addr != 0 and SHM_RND is specified, the segment 
 *           is attached at the address given by 
 *           (addr − (addr modulus SHMLBA))
 */
void *shmat(int shmid, const void *addr, int flag);

/**
 * @brief detach the shared memory segment located at addr 
 *        from the address space of the calling process
 */
int shmdt(const void *addr);
```
