---
title: Low-Level Input/Output
tags:
  - C/C++
category:
  - C/C++
abbrlink: '7950'
date: 2020-10-01 11:20:29
keywords:
description:
---

## 1. Open and Close Files
```c
/**
 * @brief create and return a new file descriptor for thr file named by filename
 *        this function is a cancellation point in multi-threaded program
 *        this function is the underlying primitive for the fopen() and freopen()
 * @param falgs control how the file is to be opened
 * @param mode used only when a file is created
 */
int open(const char *filename, int flags[, mode_t mode]);

/**
 * @brief equivalent to open(filename, O_WRONLY | O_CREAT | O_TRUNC, mode)
 */
int creat(const char *filename, mode_t mode);

/**
 * @brief close the file descriptor filedes by the following consequences:
 *        1. the file descriptor is deallocated
 *        2. any record locks owned by the process on the file are unlocked
 *        3. when all file descriptors associated with a pipe or FIFO have been closed
 *        this function is a cancellation point in multi-threaded program
 *        this function is the underlying file 
 */
int close(int filedes);
```


## 2. Input and Output Primitives
```c
/**
 * @brief read up to `size` bytes from the file with descriptor `filedes`, storing the result in the `buffer`
 * @return number of bytes read, might less than `size` since there aren't many bytes left in the file
 *         -1 in case of an error and errno is set
 */
ssize_t read(int filedes, void *buffer, size_t size);

/**
 * @brief similar to the read function, but data block is not read from the current postion of file descriptor.
 *        Instead the data is read from the file starting at position `offset` 
 */
ssize_t pread(int filedes, void *buffer, size_t size, off_t offset);

/**
 * @brief write up to `size` bytes from `buffer` to the file with descriptor `filedes`. Once the function returns, 
 *        the data is enqueued to be written, but not necessarily written out to permanent storage immediately.
 *        You can use `fsync` when you need to be sure the data has been permanently stored; Or set `O_FSYNC` flag
 *        on open mode to make `write` always store the data to disk before return.
 * @return the number of bytes actually written
 */
ssize_t write(int filedes, const void *buffer, size_t size);

/**
 * @brief similar to write function. The data block is not written to the current position of file descriptor.
 *        Instead the data is written to the file starting at position `offset`
 *        On Linux, if a file is opened with O_APPEND, pwrite appends data to the end of file, regardless of the value of offset
 */
ssize_t pwrite(int filedes, const void *buffer, size_t size, off_t offset);
```


## 3. Set the File Position of a Descriptor
stream中可使用fseek()设置一个stream的file position, file descriptor则需要使用lseek()来设置file position. 
```c
/**
 * @brief change the file position of the file with descriptor `fieldes`
 * @param offset specifies how the offset should be interpreted, must be one of following value:
 *        1. SEEK_SET: offset is a count of characters from the beginning of the file
 *        2. SEEK_CUR: offset is a count of characters from the current file position
 *        3. SEEK_END: offset is a count of characters from the end of file. If you specifies a postion
 *                     past the end of file, the file will be extended with zeros up to that position
 */
off_t lseek (int filedes, off_t offset, int whence);
```
使用lseek()将当前file position超出文件末尾时, 该操作并不会扩展文件, lseek()也不会修改文件内容; 但后续的write操作会扩展文件, 文件末尾和file position之间用零填充. stream中的fseek(), fseeko(), ftell()和rewind()都以lseek()为基础.


## 4. Descriptors and Streams
```c
/**
 * @brief return a new stream for the file descriptor `filedes`
 * @param opentype same as the opentype in fopen()
 * @return the new stream. If the stream cannot be created, a null pointer is returned instead
 */
FILE * fdopen (int filedes, const char *opentype);

/**
 * @brief return the file descriptor associated with the `stream`.
 * @return return -1 if stream does not do I/O
 */
int fileno (FILE *stream);

/**
 * @brief equivalent to the fileno function except that it does not lock the stream
 */
int fileno_unlocked (FILE *stream);
```


## 5. Dangers of Mixing Streams and Descriptors
程序中可能会出现多个file descriptor和stream指向同一个文件, 并存在两种情况: 
1. file descriptor和stream共享同一个file position
2. file descriptor和stream拥有各自的file position

应尽量避免在程序中使用file descriptor和stream指向同一个文件, 除非都用于input(读取). 以下我们将file descriptor和stream都称为channel.

### 5.1 Linked Channels
若指向同一文件的多个channel共享一个file position, 则称之为**linked channels**. 以下是几种导致linked channels的情况:
1. fdopen(): 通过一个file descriptor来创建一个stream
2. fileno(): 通过一个stream获取一个file descriptor
3. dup()/dup2(): 复制一个file descriptor

当你已经拥有一个stream, 又需要另一个linked channel(stream或file descriptor)时, 需要先调用fflush()将之前的stream清空. 终止一个进程, 或在进程中执行新的程序, 这两个操作都会将当前进程的所有stream关闭; 若stream被关闭, 其他进程中关联的file descriptor的file position会变成undefined, 因此在stream被关闭前需调用fflush()清空stream.

### 5.2 Independent Channels
当在一个seekable file开启一个channel(stream或file descriptor)时, 每个channel都拥有各自的file position, 被称为independent channels.
大部分情况下, independent channel之间不会有冲突, 但还是需要注意一下几点:
* 在做任何读取或写入之前, 需要清空output stream
* 在读取任何被修改的数据前, 需要先清空input stream


